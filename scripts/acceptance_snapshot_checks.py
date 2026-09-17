#!/usr/bin/env python3
"""Focused executable controls for dependency snapshots and project history refusals."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT_CONTROL = r'''
import StrictLean.Checker.Snapshot
open Lean System StrictLean.Checker

def main (args : List String) : IO Unit := do
  let [project, dependency] := args | throw <| IO.userError "expected project and dependency"
  let inventory ← Lake.surfaceInventory project
  let before ← Snapshot.dependencies inventory
  let some observed := before.find? (·.package == "dep")
    | throw <| IO.userError "dependency missing"
  unless observed.sourcePaths.any (·.1 == `Dep.Generated) do
    throw <| IO.userError "ignored imported module missing"
  unless observed.sourcePaths.any (·.1 == `Dep.Unimported) do
    throw <| IO.userError "buildable submodule missing"
  Snapshot.dependenciesUnchanged before
  let source := FilePath.mk dependency / "Dep/Generated.lean"
  let original ← IO.FS.readFile source
  IO.FS.writeFile source (original ++ "\ndef added : Nat := 9\n")
  let changed ← (Snapshot.dependenciesUnchanged before).toBaseIO
  IO.FS.writeFile source original
  match changed with
  | .ok _ => throw <| IO.userError "accepted changed ignored source"
  | .error e => unless e.toString.contains "dependency snapshot changed:" do throw e
  Snapshot.dependenciesUnchanged before
  let configuration := FilePath.mk dependency / "lean-toolchain"
  let original ← IO.FS.readFile configuration
  IO.FS.writeFile configuration (original ++ "\n")
  let changed ← (Snapshot.dependenciesUnchanged before).toBaseIO
  IO.FS.writeFile configuration original
  match changed with
  | .ok _ => throw <| IO.userError "accepted changed ignored configuration"
  | .error e => unless e.toString.contains "dependency snapshot changed:" do throw e
  Snapshot.dependenciesUnchanged before
  let generated := FilePath.mk dependency / "Dep/New.lean"
  IO.FS.writeFile generated "def newGenerated : Nat := 5\n"
  let changed ← (Snapshot.dependenciesUnchanged before).toBaseIO
  IO.FS.removeFile generated
  match changed with
  | .ok _ => throw <| IO.userError "accepted newly generated ignored source"
  | .error e => unless e.toString.contains "dependency snapshot changed:" do throw e
  Snapshot.dependenciesUnchanged before
  IO.println "dependency snapshot controls: PASS"
'''


def run(args: list[str], cwd: Path, **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(args, cwd=cwd, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, timeout=120, **kwargs)


def require_success(result: subprocess.CompletedProcess) -> None:
    if result.returncode:
        raise RuntimeError(result.stdout)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--checker", type=Path, default=ROOT / ".lake/build/bin/axiomGate")
    parser.add_argument("--group", choices=("all", "dependencies", "history"), default="all")
    args = parser.parse_args()
    checker = args.checker.resolve()
    (ROOT / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="snapshot-history-", dir=ROOT / "tmp") as raw:
        scratch = Path(raw)
        dep = scratch / "dependency"
        dep.mkdir()
        (dep / "Dep").mkdir()
        (dep / "lakefile.toml").write_text(
            'name = "dep"\n[[lean_lib]]\nname = "Dep"\nglobs = ["Dep"]\n')
        (dep / "Dep.lean").write_text('import Dep.Generated\n')
        (dep / "Dep/Generated.lean").write_text('def generated : Nat := 3\n')
        (dep / "Dep/Unimported.lean").write_text('def unimported : Nat := 4\n')
        (dep / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (dep / ".gitignore").write_text('Dep/Generated.lean\nDep/Unimported.lean\nDep/New.lean\nlean-toolchain\n.lake/\n')
        for command in (["git", "init", "-q"], ["git", "add", "."],
                        ["git", "-c", "user.name=Snapshot Control", "-c",
                         "user.email=snapshot@example.invalid", "-c", "commit.gpgsign=false",
                         "commit", "-qm", "dependency control"]):
            require_success(run(command, dep))
        project = scratch / "project"
        project.mkdir()
        (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (project / "lakefile.toml").write_text(
            'name = "snapshot_control"\n[[require]]\nname = "dep"\npath = "../dependency"\n'
            '[[lean_lib]]\nname = "Example"\n')
        (project / "Example.lean").write_text('import Dep\n/-! Snapshot control. -/\n')
        require_success(run(["lake", "update"], project))
        control = scratch / "SnapshotControl.lean"
        control.write_text(SNAPSHOT_CONTROL)
        env = dict(os.environ, LEAN_PATH=str(checker.parent.parent / "lib/lean"))
        if args.group != "history":
            require_success(run(["lean", "--run", str(control), str(project), str(dep)], ROOT, env=env))
            print("dependency snapshot controls: PASS", flush=True)
        if args.group == "dependencies":
            return
        (project / "lakefile.toml").write_text(
            'name = "history_control"\n[[lean_lib]]\nname = "Example"\n')
        (project / "lake-manifest.json").unlink()
        require_success(run(["lake", "update"], project))
        (project / "foundation_manifest.json").write_text(json.dumps({
            "schema-version": 2, "surfaces": [{"library": "Example", "claim": "standard-logical",
            "execution": "report", "rationale": "History diagnostic control."}],
            "excluded-libraries": [], "excluded-executables": []}))
        for mode in ([], ["--incremental"], ["--build-lint"]):
            for phase, fixture in (("positive", "Fixed.lean"), ("negative", "Violation.lean"),
                                   ("restored", "Fixed.lean")):
                (project / "Example.lean").write_bytes((ROOT / "examples/rules/SL3001" / fixture).read_bytes())
                output = scratch / "result.json"
                result = run([str(checker), "--project", str(project), "--json-out", str(output), *mode], ROOT)
                packet = json.loads(output.read_text())
                if phase == "negative":
                    assert result.returncode != 0, result.stdout
                    assert packet["status"] == "incomplete", packet
                    assert "acceptance" not in packet, packet
                    findings = packet["diagnostics"]
                    assert not any(f["id"] == "SL2001" for f in findings), findings
                    matches = [f for f in findings if f["id"] == "SL3001"]
                    assert matches, packet
                    assert any(f["arguments"]["root"] == [["str", "identity"]] for f in matches), matches
                    assert all(f["location"]["kind"] == "source" and
                               f["location"]["uri"].endswith("Example.lean") for f in matches), matches
                    assert "execution-unresolved" in result.stdout, result.stdout
                else:
                    require_success(result)
                    assert packet["status"] == "completed" and "acceptance" in packet, packet
                print(f"history {mode or ['fresh']} {phase}: PASS", flush=True)


if __name__ == "__main__":
    main()
