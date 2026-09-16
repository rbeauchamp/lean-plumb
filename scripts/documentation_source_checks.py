#!/usr/bin/env python3
"""Qualify frozen project inputs through both public documentation commands."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = '/-! The fixed dependency proposition. -/\ntheorem dependency : True := True.intro\n'
FENCE = 'import Lean\nimport Example\n{}theorem fenceClaim : True := dependency\n'


def main():
    env = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}
    (ROOT / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="documentation-source-", dir=ROOT / "tmp") as raw:
        project = Path(raw)
        (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (project / "lakefile.toml").write_text(
            'name = "documentation_adopter"\n[[lean_lib]]\nname = "Example"\n')
        lock = json.loads((ROOT / "lake-manifest.json").read_text())
        lock.update(packages=[], name="documentation_adopter")
        (project / "lake-manifest.json").write_text(json.dumps(lock))
        (project / "foundation_manifest.json").write_text(json.dumps({
            "schema-version": 2,
            "surfaces": [{"library": "Example", "claim": "kernel-only",
                          "rationale": "The same proposition and proof in every phase."}],
            "excluded-libraries": [], "excluded-executables": []}))
        (project / "Example.lean").write_text(SOURCE)
        (project / "docs").mkdir()
        for binary, flags in (("docFenceAudit", ["--jobs", "1", "--verbose"]),
                              ("axiomGate", ["--with-docs"])):
            phases = [("positive", "", "")]
            for label, path, operation, reason in (
                ("source-change", "Example.lean", "append", "producer-source: source snapshot changed: Example"),
                ("source-missing", "Example.lean", "remove", "Example.lean"),
                ("configuration-change", "foundation_manifest.json", "append", "producer-source: configuration snapshot changed"),
                ("configuration-missing", "foundation_manifest.json", "remove", "producer-source: configuration snapshot changed"),
            ):
                action = ('IO.FS.writeFile path ((← IO.FS.readFile path) ++ "\\n")'
                          if operation == "append" else 'IO.FS.removeFile path')
                mutation = f'run_cmd do\n  let path := (← IO.currentDir) / "{path}"\n  {action}\n'
                phases.extend([(label, mutation, reason), (f"{label}-restored", "", "")])
            for index, (phase, mutation, reason) in enumerate(phases):
                (project / "docs/control.md").write_text("```lean\n" + FENCE.format(mutation) + "```\n")
                output = project / f"{binary}-{index}.json"
                args = [str(ROOT / ".lake/build/bin" / binary), "--project", str(project), *flags]
                if binary == "axiomGate":
                    args += ["--json-out", str(output)]
                run = subprocess.run(args, cwd=project, env=env, text=True,
                                     capture_output=True, timeout=90)
                transcript = run.stdout + run.stderr
                if mutation:
                    assert run.returncode != 0 and reason in transcript, (binary, phase, transcript)
                    assert "fence compilation: " in transcript, (binary, phase, transcript)
                    if phase == "source-missing":
                        assert "no such file or directory" in transcript, (binary, phase, transcript)
                else:
                    assert run.returncode == 0, (binary, phase, transcript)
                    assert "conforming-positive-pass=1/1" in transcript, (binary, phase, transcript)
                if binary == "axiomGate":
                    result = json.loads(output.read_text())
                    assert result["status"] == ("incomplete" if mutation else "completed"), result
                    expected_ids = (["SL2001" if phase == "source-missing" else "SL2005"]
                                    if mutation else [])
                    assert [d["id"] for d in result["diagnostics"]] == expected_ids, result
                print(f"documentation {binary}/{phase}: PASS", flush=True)


if __name__ == "__main__":
    main()
