#!/usr/bin/env python3
"""Qualify frozen project inputs through both public documentation commands."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = '/-! The fixed dependency proposition. -/\ntheorem dependency : True := True.intro\n'
FENCE = 'import Lean\nimport Example\n{}theorem fenceClaim : True := dependency\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-read-only", action="store_true")
    options = parser.parse_args()
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
            if binary == "axiomGate":
                (project / "Example.lean").unlink()
                output = project / "setup-missing.json"
                run = subprocess.run(
                    [str(ROOT / ".lake/build/bin" / binary), "--project", str(project),
                     *flags, "--json-out", str(output)],
                    cwd=project, env=env, text=True, capture_output=True, timeout=90)
                result = json.loads(output.read_text())
                assert run.returncode != 0 and result["status"] == "incomplete", result
                assert [d["id"] for d in result["diagnostics"]] == ["SL2001"], result
                (project / "Example.lean").write_text(SOURCE)
                print("documentation axiomGate/initial-source-missing: PASS", flush=True)
            phases = [("positive", "", "")]
            for label, path, operation, reason in (
                ("source-change", "Example.lean", "append", "producer-source: source snapshot changed: Example"),
                ("source-missing", "Example.lean", "remove", "producer-source: source snapshot unavailable: Example"),
                ("source-unreadable", "Example.lean", "directory", "producer-source: source snapshot unavailable: Example"),
                ("configuration-unreadable", "foundation_manifest.json", "directory", "producer-source: configuration snapshot unavailable:"),
                ("configuration-change", "foundation_manifest.json", "append", "producer-source: configuration snapshot changed"),
                ("configuration-missing", "foundation_manifest.json", "remove", "producer-source: configuration snapshot changed"),
            ):
                if options.source_read_only and label not in ("source-missing", "source-unreadable", "configuration-unreadable"):
                    continue
                action = {
                    "append": 'IO.FS.writeFile path ((← IO.FS.readFile path) ++ "\\n")',
                    "remove": "IO.FS.removeFile path",
                    "directory": "IO.FS.removeFile path\n  IO.FS.createDirAll path",
                }[operation]
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
                    if phase in ("source-missing", "source-unreadable", "configuration-unreadable"):
                        io_reason = ("no such file or directory" if phase == "source-missing"
                                     else "is a directory")
                        expected_path = "foundation_manifest.json" if phase == "configuration-unreadable" else "Example.lean"
                        assert io_reason in transcript.lower() and expected_path in transcript, (binary, phase, transcript)
                else:
                    assert run.returncode == 0, (binary, phase, transcript)
                    assert "conforming-positive-pass=1/1" in transcript, (binary, phase, transcript)
                if binary == "axiomGate":
                    result = json.loads(output.read_text())
                    assert result["status"] == ("incomplete" if mutation else "completed"), result
                    expected_ids = ["SL2005"] if mutation else []
                    assert [d["id"] for d in result["diagnostics"]] == expected_ids, result
                print(f"documentation {binary}/{phase}: PASS", flush=True)

        if options.source_read_only:
            for stage in ("file", "build"):
                target = project / ("Standalone.lean" if stage == "file" else "Example.lean")
                phases = ["positive", "source-missing", "restored", "source-unreadable", "restored"]
                if stage == "file":
                    phases.insert(0, "initial-missing")
                else:
                    phases[1:1] = ["source-change", "restored"]
                for index, phase in enumerate(phases):
                    if target.is_dir():
                        target.rmdir()
                    if phase == "initial-missing":
                        target.unlink(missing_ok=True)
                    else:
                        action = {
                            "source-missing": "IO.FS.removeFile path",
                            "source-unreadable": "IO.FS.removeFile path\n  IO.FS.createDirAll path",
                            "source-change": 'IO.FS.writeFile path ((← IO.FS.readFile path) ++ "\\n")',
                        }.get(phase)
                        location = (f"let path : System.FilePath := {json.dumps(str(target))}"
                                    if stage == "file" else "let path ← Lean.getFileName")
                        mutation = f"run_cmd do\n  {location}\n  {action}\n" if action else ""
                        target.write_text("import Lean\n" + SOURCE + mutation)
                    flags = (["--file", target.name, "--claim", "kernel-only"]
                             if stage == "file" else ["--with-docs"])
                    output = project / f"{stage}-{index}.json"
                    run = subprocess.run(
                        [str(ROOT / ".lake/build/bin/axiomGate"), "--project", str(project),
                         *flags, "--json-out", str(output)],
                        cwd=project, env=env, text=True, capture_output=True, timeout=90)
                    result = json.loads(output.read_text())
                    failed = phase.startswith("source-") or phase == "initial-missing"
                    assert (run.returncode != 0) == failed, (stage, phase, run.stdout, run.stderr)
                    expected_ids = (["SL2001" if phase == "initial-missing" else "SL2005"]
                                    if failed else [])
                    assert result["status"] == ("incomplete" if failed else "completed"), result
                    assert [d["id"] for d in result["diagnostics"]] == expected_ids, result
                    if phase.startswith("source-"):
                        detail = result["diagnostics"][0]["arguments"]["detail"]
                        reason = ("source snapshot changed" if phase == "source-change"
                                  else "source snapshot unavailable")
                        assert "producer-source: " + reason in detail, result
                        if phase != "source-change":
                            io_reason = ("no such file or directory" if phase == "source-missing"
                                         else "is a directory")
                            assert io_reason in detail.lower() and target.name in detail, result
                    print(f"source boundary {stage}/{phase}: PASS", flush=True)


if __name__ == "__main__":
    main()
