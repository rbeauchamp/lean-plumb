#!/usr/bin/env python3
"""Qualify typed evidence refusals originating inside positive Markdown fences."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

from closure_evidence_checks import RANGE
from history_checks import UNCHECKED

ROOT = Path(__file__).resolve().parents[1]
POSITIVE = RANGE.format(range="ranges.range")


def main():
    env = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}
    (ROOT / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="fence-evidence-", dir=ROOT / "tmp") as raw:
        project = Path(raw)
        (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (project / "lakefile.toml").write_text('name = "fence_adopter"\n[[lean_lib]]\nname = "Example"\n')
        lock = json.loads((ROOT / "lake-manifest.json").read_text())
        lock.update(packages=[], name="fence_adopter")
        (project / "lake-manifest.json").write_text(json.dumps(lock))
        (project / "foundation_manifest.json").write_text(json.dumps({
            "schema-version": 2,
            "surfaces": [{"library": "Example", "claim": "standard-logical",
                          "rationale": "The fixed project theorem remains valid."}],
            "excluded-libraries": [], "excluded-executables": []}))
        (project / "Example.lean").write_text('/-! Fixed project control. -/\ntheorem projectClaim : True := True.intro\n')
        (project / "docs").mkdir()
        phases = [("positive", POSITIVE, [], "")]
        for label, source, ids, reason in (
            ("range", RANGE.format(range="{ ranges.range with pos := ⟨0, 0⟩, endPos := ⟨0, 1⟩ }"),
             ["SL4002", "SL2005"], "producer-source: source coverage or coordinates mismatch"),
            ("replay", "import Lean\n" + UNCHECKED,
             ["SL4002", "SL2005"], "kernel-admission"),
            ("policy", "axiom forbidden : True\n", ["SL4002", "SL1001"], "project-axiom"),
            ("compiler", 'def bad : Nat := "wrong"\n', ["SL4002"], ""),
        ):
            phases.extend([(label, source, ids, reason), (label + "-restored", POSITIVE, [], "")])
        for binary, flags in (("docFenceAudit", ["--jobs", "1", "--verbose"]),
                              ("axiomGate", ["--with-docs"])):
            for phase, source, ids, reason in phases:
                (project / "docs/control.md").write_text("```lean\n" + source + "```\n")
                shutil.rmtree(project / ".lake/build", ignore_errors=True)
                output = project / f"{binary}-{phase}.json"
                args = [str(ROOT / ".lake/build/bin" / binary), "--project", str(project), *flags]
                if binary == "axiomGate":
                    args += ["--json-out", str(output)]
                run = subprocess.run(args, cwd=project, env=env, text=True, capture_output=True, timeout=90)
                transcript = run.stdout + run.stderr
                assert (run.returncode != 0) == bool(ids), (binary, phase, transcript)
                if phase != "compiler":
                    assert "inspection group 1/1: 1 fence(s)" in transcript, (binary, phase, transcript)
                assert reason in transcript, (binary, phase, transcript)
                if not ids:
                    assert "conforming-positive-pass=1/1" in transcript, (binary, phase, transcript)
                for rule in ids:
                    assert rule in transcript, (binary, phase, transcript)
                if "SL2005" not in ids:
                    assert "SL2005" not in transcript, (binary, phase, transcript)
                if binary == "axiomGate":
                    result = json.loads(output.read_text())
                    incomplete = "SL2005" in ids
                    assert result["mode"] == "freshProject", result
                    assert result["status"] == ("incomplete" if incomplete else "rejected" if ids else "completed"), result
                    assert [d["id"] for d in result["diagnostics"]] == ids, result
                    for diagnostic in result["diagnostics"]:
                        assert diagnostic["mode"] == "documentationExample", diagnostic
                        assert diagnostic["impact"] == ("incomplete" if incomplete else "violation"), diagnostic
                        if diagnostic["id"] == "SL2005":
                            assert reason in diagnostic["arguments"]["detail"], diagnostic
                            assert diagnostic["location"]["kind"] == "project", diagnostic
                            assert diagnostic["arguments"]["subject"] == "control.md:1", diagnostic
                            if phase == "replay":
                                assert "admissionFalse" in diagnostic["arguments"]["detail"], diagnostic
                print(f"fence evidence {binary}/{phase}: PASS", flush=True)


if __name__ == "__main__":
    main()
