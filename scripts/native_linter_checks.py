#!/usr/bin/env python3
"""Bounded qualification of Lean's actual collector/logger/metadata bridges.

The pure decision has universal Lean proofs. These controls instead check the
operational linkage: native callback scheduling, serialized diagnostic codes,
warning promotion, actual metadata lookup and current/imported ownership. They
are observations on the pinned compiler, not a proof of all elaborator behavior.
No intentionally nonconforming source is installed in a positive library.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BASE = '''import StrictLean.Linter
/-! Collector qualification control. -/
/-- A registered material claim. -/
@[strict_lean_material] theorem documented : True := .intro
private def privateValue : Nat := 1
inductive Branch where
  | node : List Branch → Branch
'''


class LeanLauncher:
    """Resolve Lake once per parent environment in this qualification invocation.

    The workspace configuration/pins stay fixed while the controls run. Only the
    imported-control search path changes; capture that actual Lake environment too.
    Reuse no compiler process, elaboration result, or qualification verdict.
    """

    def __init__(self) -> None:
        self.environments: dict[tuple[tuple[str, str], ...], tuple[dict[str, str], str]] = {}

    def environment(self) -> tuple[dict[str, str], str]:
        parent = dict(os.environ)
        key = tuple(sorted(parent.items()))
        if key not in self.environments:
            # Both supported hosts (Ubuntu/macOS) provide NUL-delimited env output.
            # Avoid parsing Lake's human-readable lines or changing the environment
            # through another language runtime's initialization.
            result = subprocess.run(
                ["lake", "env", "/usr/bin/env", "-0"],
                cwd=ROOT, env=parent, capture_output=True, check=True, timeout=30)
            if result.stderr:
                raise RuntimeError("Lake environment capture emitted stderr")
            if not result.stdout.endswith(b"\0"):
                raise RuntimeError("invalid Lake environment capture")
            env: dict[str, str] = {}
            for entry in result.stdout[:-1].split(b"\0"):
                name, separator, value = entry.partition(b"=")
                if not name or not separator or os.fsdecode(name) in env:
                    raise RuntimeError("invalid Lake environment entry")
                env[os.fsdecode(name)] = os.fsdecode(value)
            if "LEAN_PATH" not in env or "PATH" not in env:
                raise RuntimeError("Lake environment is missing required search paths")
            # Resolve relative PATH entries at the child's cwd, even if this script
            # was invoked elsewhere. The captured child environment stays untouched.
            lookup_path = os.pathsep.join(str(ROOT / part) for part in os.get_exec_path(env))
            executable = shutil.which("lean", path=lookup_path)
            if executable is None:
                raise RuntimeError("Lean executable absent from Lake environment")
            self.environments[key] = (env, str(ROOT / executable))
        return self.environments[key]

    def run(self, args: list[str]) -> subprocess.CompletedProcess[str]:
        env, executable = self.environment()
        return subprocess.run(["lean", *args], executable=executable, env=env,
                              cwd=ROOT, text=True, capture_output=True, timeout=30)

    def lean_path(self) -> str:
        # Preserve the original printenv(...).stdout.strip() consumption.
        return self.environment()[0]["LEAN_PATH"].strip()


def main(launcher: LeanLauncher | None = None) -> None:
    launcher = launcher if launcher is not None else LeanLauncher()
    count = 0
    with tempfile.TemporaryDirectory(prefix="native-controls-", dir=ROOT / "tmp") as raw:
        scratch = Path(raw)

        def check(label: str, source: str, expected: list[str], *, errors: bool = False,
                  options: tuple[str, ...] = (), output: bool = False,
                  compiler: tuple[tuple[str, str], ...] = (), detail: str | None = None,
                  native_severity: str | None = None) -> list[dict]:
            nonlocal count
            path = scratch / f"{label}.lean"
            path.write_text(source)
            args = ["--json", "--root", str(scratch), *options]
            if output:
                args += ["-o", str(path.with_suffix(".olean"))]
            result = launcher.run([*args, str(path)])
            messages = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]
            actual = [m for m in messages if m.get("kind", "").startswith("StrictLean.SL")]
            other = [m for m in messages if m not in actual]
            assert len(other) == len(compiler), (label, other, compiler)
            for message, (severity, text) in zip(other, compiler):
                assert message["severity"] == severity and text in message["data"], (label, message)
            if detail is not None:
                assert any(detail in m["data"] for m in actual), (label, detail, actual)
            ids = sorted(m["kind"].removeprefix("StrictLean.").removesuffix("._namedError") for m in actual)
            assert ids == sorted(expected), (label, ids, expected, result.stdout, result.stderr)
            assert bool(result.returncode) == errors, (label, result.returncode, result.stdout, result.stderr)
            assert not result.stderr, (label, result.stderr)
            for message in actual:
                assert message["fileName"] == str(path), (label, message)
                assert "lean-lang.org/doc/reference" not in message["data"], (label, message)
                assert "https://rbeauchamp.github.io/strict-lean/dev/rules/" in message["data"]
                severity = native_severity or ("error" if "-DwarningAsError=true" in options else "warning")
                assert message["severity"] == severity, (label, message)
            count += 1
            return messages

        check("Control", BASE, [], output=True)
        # The same detector observes an actual declaration added by the axiom command.
        axiom = BASE + "\naxiom forbidden : False\n"
        messages = check("Axiom", axiom, ["SL1001"])
        finding = next(m for m in messages if m.get("kind") == "StrictLean.SL1001._namedError")
        assert finding["pos"] == {"line": 9, "column": 6}, finding
        check("PromotedAxiom", axiom, ["SL1001"], errors=True,
              options=("-DwarningAsError=true",))
        missing = BASE.replace("/-! Collector qualification control. -/\n", "").replace(
            "/-- A registered material claim. -/\n", "")
        messages = check("Missing", missing, ["SL5001", "SL5002"], output=True)
        module = next(m for m in messages if m.get("kind") == "StrictLean.SL5001._namedError")
        assert module["pos"] == {"line": len(missing.splitlines()) + 1, "column": 0}, module
        check("PromotedMissing", missing, ["SL5001", "SL5002"], errors=True,
              options=("-DwarningAsError=true",))
        check("Disabled", BASE.replace("/-!", "set_option linter.strictLean false\n/-!", 1)
              + "axiom forbidden : False\n", [])
        check("Narrow", BASE + "set_option strictLean.localFoundation \"kernel-only\"\n"
              + "theorem classicalClaim (p : Prop) : p ∨ ¬p := Classical.em p\n", ["SL1005"])
        config = check("BadRequest", BASE + "set_option strictLean.localFoundation \"unsupported\"\n"
              + "def selected : Nat := 1\n", ["SL2002"] * 2)
        assert [m["pos"]["line"] for m in config] == [8, 9], config
        check("EmptyBadRequest", 'import StrictLean.Linter\n/-! Configuration control. -/\n'
              + 'set_option strictLean.localFoundation "unsupported"\n', ["SL2002"])
        check("TrailingBadRequest", BASE + 'set_option strictLean.localFoundation "unsupported"\n', ["SL2002"])
        check("InitialBadRequest", 'import StrictLean.Linter\n', ["SL2002"],
              options=("-DstrictLean.localFoundation=unsupported",))
        check("ScopedBadRequest", BASE + 'set_option strictLean.localFoundation "unsupported" in\n'
              + 'def selected : Nat := 1\n', ["SL2002"])
        check("ScopedNarrow", BASE + 'set_option strictLean.localFoundation "kernel-only" in\n'
              + 'theorem classicalClaim (p : Prop) : p ∨ ¬p := Classical.em p\n', ["SL1005"])
        check("ScopedDisabled", BASE + 'set_option linter.strictLean false in\naxiom forbidden : False\n', [])
        check("ScopedPromoted", BASE + 'set_option warningAsError true in\naxiom forbidden : False\n',
              ["SL1001"], errors=True, native_severity="error")
        # Completion of a hole observation is distinct from absence of analysis.
        check("Hole", BASE + "theorem unfinished : True := by sorry\n", ["SL1002"],
              compiler=(("warning", "declaration uses `sorry`"),))
        check("RecoveredError", BASE + "theorem broken : True := by exact missingProof\n",
              ["SL1002"], errors=True, compiler=(("error", "Unknown identifier `missingProof`"),))
        check("Synchronous", axiom, ["SL1001"], options=("-DElab.async=false",))
        check("UnknownAxiom", BASE + "private axiom assumed : False\ntheorem dependent : False := assumed\n",
              ["SL1001", "SL1003"])
        check("CompilerTrust", BASE + "theorem trustedCompiler : True := Lean.trustCompiler\n", ["SL1004"],
              compiler=(("warning", "`Lean.trustCompiler` has been deprecated: in-kernel native reduction is deprecated; assert native evaluations with axioms instead"),))
        check("Escape", BASE + "unsafe def escape : Nat := 0\n", ["SL1006"])
        check("Contract", BASE + "def implementation (n : Nat) : Nat := n\n"
              + "theorem unsupported (n : Nat) : StrictLean.ExecutableContract (implementation n) (fun value => value = n) := ⟨rfl⟩\n",
              ["SL1007"])
        check("Pending", BASE + "theorem nativeTruth : (2 + 2 : Nat) = 4 := by native_decide\n", ["SL2005"],
              detail="fresh generated-role evidence remains required")
        malformed = BASE + '''open Lean Elab Command in
elab "bad_range " name:ident : command => do
  elabCommand (← `(axiom $name:ident : False))
  let some ranges ← findDeclarationRangesCore? name.getId | throwError "missing control range"
  let invalid := { ranges.range with pos := ⟨9999, 0⟩, endPos := ⟨9999, 1⟩ }
  addDeclarationRanges name.getId { range := invalid, selectionRange := invalid }
bad_range corrupted
'''
        check("ValidRange", malformed.replace(
            "{ ranges.range with pos := ⟨9999, 0⟩, endPos := ⟨9999, 1⟩ }", "ranges.range"), ["SL1001"])
        check("InvalidRange", malformed, ["SL2005"],
              detail="reported source coordinates disagree with the snapshot")
        check("RestoredRange", malformed.replace(
            "{ ranges.range with pos := ⟨9999, 0⟩, endPos := ⟨9999, 1⟩ }", "ranges.range"), ["SL1001"])
        verso = BASE.replace("/-!", "set_option doc.verso true\nset_option doc.verso.module true\n/-!", 1)
        check("Verso", verso, [], output=True)
        inherited = BASE + '''/-- Reused documentation. -/
def parent : Nat := 1
@[inherit_doc parent, strict_lean_material] def child : Nat := 1
@[strict_lean_material] private def privateMaterial : Nat := 1
'''
        check("Inherited", inherited, [])
        module_style = BASE.replace("import StrictLean.Linter", "module\nimport StrictLean.Linter").replace(
            "@[strict_lean_material] theorem", "@[strict_lean_material] public theorem")
        check("ModuleSystem", module_style +
              "@[strict_lean_material] theorem privateMaterial : True := .intro\n", [])
        check("ModuleAxiom", module_style + "public axiom forbidden : False\n", ["SL1001"])
        check("ModuleMissing", module_style.replace("/-! Collector qualification control. -/\n", "").replace(
            "/-- A registered material claim. -/\n", ""), ["SL5001", "SL5002"])
        # No binder information is created for this metaprogram-added axiom. The
        # complete collector must nevertheless retain it; local policy is partial.
        inspect = BASE + '''run_cmd Lean.Elab.Command.liftCoreM <| Lean.addDecl (.axiomDecl {
  name := `hiddenAxiom, levelParams := [], type := Lean.mkSort .zero, isUnsafe := false })
run_cmd do
  let env ← Lean.getEnv
  let ds ← StrictLean.Collect.currentModule
  unless ds.any (fun d => d.name == `hiddenAxiom && d.kind == .«axiom») do
    throwError "binder-less declaration missing"
  unless ds.any (fun d => d.private) do throwError "private declaration missing"
  unless ds.any (fun d => d.name == `Branch.rec) do throwError "generated declaration missing"
  unless ds.all (fun d => d.module == env.mainModule) do throwError "wrong local ownership"
  let a ← StrictLean.Collect.declaration `documented .snapshot
  let b ← StrictLean.Collect.declaration `documented .replayCandidate
  unless a == b do throwError "stage changed ordinary canonical record"
  unless (StrictLean.Collect.moduleOf env `unknownDeclaration).toOption.isNone do
    throwError "invented unknown ownership"
  if env.header.modules.any (fun m => m.module.getRoot == `Mathlib) then
    throwError "public import required Mathlib"
'''
        check("Collect", inspect, [])
        # Native imports do not request a project build; a fresh import must
        # retain the same registration and both persisted documentation formats.
        observer = '''import Control
import Verso
/-! Imported observation control. -/
run_cmd do
  let env ← Lean.getEnv
  for moduleName in #[`Control, `Verso] do
    unless (StrictLean.Linter.Documentation.modulePresent env moduleName).toOption == some true do
      throwError "imported module documentation absent"
  unless StrictLean.Linter.Documentation.selected env `documented do
    throwError "imported registration missing"
  unless (← StrictLean.Linter.Documentation.declarationPresent env `documented) == true do
    throwError "imported declaration documentation mismatch"
  let d ← StrictLean.Collect.declaration `documented .snapshot
  unless d.module == `Control do throwError "wrong imported ownership"
  unless (StrictLean.Linter.Documentation.modulePresent env `Unknown).toOption.isNone do
    throwError "unknown module treated as absent"
'''
        # Control and Verso intentionally use the same declaration names, so
        # inspect separately rather than importing conflicting global names.
        observer = observer.replace("import Verso\n", "").replace("#[`Control, `Verso]", "#[`Control]")
        # Lake owns its normal search path; append only this isolated artifact dir.
        env_path = launcher.lean_path()
        old = os.environ.get("LEAN_PATH")
        os.environ["LEAN_PATH"] = env_path + os.pathsep + str(scratch)
        try:
            check("Imported", observer, [])
            check("ImportedVerso", observer.replace("Control", "Verso"), [])
            check("ImportedMissing", observer.replace("Control", "Missing").replace("== true", "== false").replace("some true", "some false"), [])
        finally:
            if old is None:
                os.environ.pop("LEAN_PATH", None)
            else:
                os.environ["LEAN_PATH"] = old
        check("Restored", BASE, [])
    print(f"native bridge qualification: PASS ({count} actual Lean source controls)")


if __name__ == "__main__":
    main()
