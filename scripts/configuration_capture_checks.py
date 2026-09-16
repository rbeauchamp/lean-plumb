#!/usr/bin/env python3
"""Qualify initial configuration IO failure through the public checker result protocol."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    env = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}
    (ROOT / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="configuration-capture-", dir=ROOT / "tmp") as raw:
        project = Path(raw)
        (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (project / "lakefile.toml").write_text('name = "configuration_adopter"\n[[lean_lib]]\nname = "Example"\n')
        lock = json.loads((ROOT / "lake-manifest.json").read_text())
        lock.update(packages=[], name="configuration_adopter")
        (project / "lake-manifest.json").write_text(json.dumps(lock))
        source = '/-! Fixed proposition. -/\ntheorem valid : True := True.intro\n'
        (project / "Example.lean").write_text(source)
        manifest = project / "foundation_manifest.json"
        good = json.dumps({"schema-version": 2,
            "surfaces": [{"library": "Example", "claim": "kernel-only", "rationale": "Fixed proposition."}],
            "excluded-libraries": [], "excluded-executables": []})
        manifest.write_text(good)
        output = project / "result.json"
        for mode, flags in (("freshProject", []), ("freshFile", ["--file", str(project / "Example.lean"), "--claim", "kernel-only"])):
            for phase in ("positive", "directory", "restored"):
                if phase == "directory":
                    manifest.unlink()
                    manifest.mkdir()
                elif phase == "restored":
                    manifest.rmdir()
                    manifest.write_text(good)
                shutil.rmtree(project / ".lake/build", ignore_errors=True)
                command = [str(ROOT / ".lake/build/bin/axiomGate"), "--project", str(project),
                    "--manifest", str(manifest), "--json-out", str(output), *flags]
                run = subprocess.run(command, cwd=project, env=env, text=True, capture_output=True, timeout=90)
                result = json.loads(output.read_text())
                context = (mode, phase, run.stdout, run.stderr,
                    {key: result.get(key) for key in ("mode", "status", "diagnostics", "unresolved", "sourceAccount")})
                assert result["mode"] == mode, context
                if phase == "directory":
                    assert run.returncode != 0 and result["status"] == "incomplete", context
                    assert len(result["diagnostics"]) == 1, context
                    diagnostic = result["diagnostics"][0]
                    assert diagnostic["id"] == "SL2001" and diagnostic["impact"] == "incomplete", context
                    assert diagnostic["location"] == {"kind": "project", "identity": str(project)}, context
                    detail = diagnostic["arguments"]["detail"]
                    assert "is a directory" in detail and detail in run.stderr, context
                    assert result["unresolved"] == [detail], context
                    assert result["sourceAccount"] == [], context
                    assert "request" not in result and "effective" not in result, context
                else:
                    assert run.returncode == 0 and result["status"] == "completed", context
                    assert result["diagnostics"] == [], context
                    assert any(item["path"] == str(Path(result["effective"]["root"]) / "Example.lean") and item["content"] == source
                        for item in result["sourceAccount"]), context
                print(f"configuration capture {mode} {phase}: PASS", flush=True)


if __name__ == "__main__":
    main()
