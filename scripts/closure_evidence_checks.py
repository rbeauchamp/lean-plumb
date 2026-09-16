#!/usr/bin/env python3
"""Qualify reflexive csimp closure and typed owned source-range refusal."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CYCLE = '''import Lean
/-! Reflexive simplification and ordinary recursion have separate meanings. -/
def f (n : Nat) : Nat := n
def recursiveSum : List Nat → Nat
  | [] => 0
  | x :: xs => x + recursiveSum xs
{attribute}theorem same : f = f := rfl
'''
RANGE = '''import Lean
/-! The same proved proposition with supplied range metadata. -/
theorem rangeClaim : True := True.intro
open Lean Elab Command in
run_cmd do
  let some ranges ← findDeclarationRangesCore? ``rangeClaim
    | throwError "missing control range"
  let supplied := {range}
  addDeclarationRanges ``rangeClaim {{ range := supplied, selectionRange := supplied }}
'''


def name(value):
    return [["str", part] for part in value.split(".")]


def main():
    env = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}
    (ROOT / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="closure-evidence-", dir=ROOT / "tmp") as raw:
        project = Path(raw)
        (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (project / "lakefile.toml").write_text('name = "evidence_adopter"\n[[lean_lib]]\nname = "Example"\n')
        lock = json.loads((ROOT / "lake-manifest.json").read_text())
        lock.update(packages=[], name="evidence_adopter")
        (project / "lake-manifest.json").write_text(json.dumps(lock))
        (project / "foundation_manifest.json").write_text(json.dumps({
            "schema-version": 2,
            "surfaces": [{"library": "Example", "claim": "standard-logical",
                          "rationale": "Unchanged identity function and proved proposition."}],
            "excluded-libraries": [], "excluded-executables": []}))
        (project / "docs").mkdir()
        (project / "docs/control.md").write_text('```lean\nimport Example\ntheorem fenceClaim : True := True.intro\n```\n')
        invocations = (("project", [], "freshProject"),
                       ("incremental", ["--incremental"], "incrementalProject"),
                       ("file", ["--file", "Example.lean", "--claim", "standard-logical"], "freshFile"),
                       ("combined", ["--with-docs"], "freshProject"))
        for case in ("cycle", "range"):
            for invocation, flags, mode in invocations:
                if case == "cycle" and invocation in ("file", "combined"):
                    continue
                for phase in ("positive", "negative", "restored"):
                    bad = phase == "negative"
                    source = (CYCLE.format(attribute="@[csimp] " if bad else "") if case == "cycle"
                              else RANGE.format(range="{ ranges.range with pos := ⟨0, 0⟩, endPos := ⟨0, 1⟩ }"
                                                if bad else "ranges.range"))
                    (project / "Example.lean").write_text(source)
                    shutil.rmtree(project / ".lake/build", ignore_errors=True)
                    output = project / f"{case}-{invocation}-{phase}.json"
                    run = subprocess.run([str(ROOT / ".lake/build/bin/axiomGate"), "--project", str(project),
                                          *flags, "--json-out", str(output)], cwd=project, env=env,
                                         text=True, capture_output=True, timeout=90)
                    result = json.loads(output.read_text())
                    assert (run.returncode != 0) == bad, (case, invocation, phase, run.stdout, run.stderr)
                    assert result["mode"] == mode, result
                    assert result["status"] == ("incomplete" if bad else "completed"), result
                    expected = ["SL3001" if case == "cycle" else "SL2005"] if bad else []
                    assert [d["id"] for d in result["diagnostics"]] == expected, result
                    if bad:
                        diagnostic = result["diagnostics"][0]
                        assert diagnostic["impact"] == "incomplete", diagnostic
                        detail = diagnostic["arguments"]["detail"]
                        reason = ("replacement-only cycle" if case == "cycle"
                                  else "producer-source: source coverage or coordinates mismatch")
                        assert reason in detail, diagnostic
                        if case == "range":
                            assert diagnostic["location"]["kind"] == "project", diagnostic
                    if case == "cycle":
                        report = result["scope"]["surfaces"][0]["report"]
                        root = next(r for r in report["execution"] if r["name"] == name("f"))
                        edge = [name("f"), name("f")]
                        assert edge in root["closure"]["candidateEdges"], root
                        assert (edge in root["closure"]["activeSimplificationEdges"]) == bad, root
                        assert bool(root["unresolved"]) == bad, root
                        recursive = next(r for r in report["execution"] if r["name"] == name("recursiveSum"))
                        assert [name("recursiveSum"), name("recursiveSum")] in recursive["compilerEdges"], recursive
                        assert not recursive["unresolved"], recursive
                    print(f"closure evidence {case}/{invocation}/{phase}: PASS", flush=True)


if __name__ == "__main__":
    main()
