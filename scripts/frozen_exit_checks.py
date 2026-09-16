#!/usr/bin/env python3
"""Exercise frozen-input refusal after import and failed build operations."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GOOD = 'import Lean\n/-! Unchanged proposition and proof. -/\ntheorem valid : True := True.intro\n'
IMPORT = '''import Lean
open Lean Elab Command in
run_cmd do
  let path ← getFileName
  elabCommand (← `(initialize do
    if {enabled} && (← IO.appPath).fileName == some "axiomGate" then
      let path : System.FilePath := $(quote path)
      {action}))
theorem valid : True := True.intro
'''


def main():
    env = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}
    (ROOT / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="frozen-exits-", dir=ROOT / "tmp") as raw:
        project = Path(raw)
        (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (project / "lakefile.toml").write_text('name = "frozen_adopter"\n[[lean_lib]]\nname = "Example"\n')
        lock = json.loads((ROOT / "lake-manifest.json").read_text())
        lock.update(packages=[], name="frozen_adopter")
        (project / "lake-manifest.json").write_text(json.dumps(lock))
        manifest = json.dumps({"schema-version": 2,
            "surfaces": [{"library": "Example", "claim": "standard-logical", "rationale": "Fixed proposition."}],
            "excluded-libraries": [], "excluded-executables": []})
        (project / "docs").mkdir()
        invocation = 0

        def run_case(label, source=GOOD, fence=GOOD, flags=(), binary="axiomGate", ids=(), reason="", file_source=GOOD, grouped=False):
            nonlocal invocation
            invocation += 1
            (project / "foundation_manifest.json").write_text(manifest)
            (project / "Example.lean").write_text(source)
            (project / "Standalone.lean").write_text(file_source)
            (project / "docs/control.md").write_text("```lean\n" + fence + "```\n")
            shutil.rmtree(project / ".lake/build", ignore_errors=True)
            output = project / f"result-{invocation}.json"
            args = [str(ROOT / ".lake/build/bin" / binary), "--project", str(project), *flags]
            if binary == "axiomGate":
                args += ["--json-out", str(output)]
            run = subprocess.run(args, cwd=project, env=env, text=True, capture_output=True, timeout=90)
            transcript = run.stdout + run.stderr
            assert (run.returncode != 0) == bool(ids), (label, transcript)
            assert reason in transcript, (label, transcript)
            if grouped:
                assert "inspection group 1/1: 1 fence(s)" in transcript, (label, transcript)
            for rule in ids:
                assert rule in transcript, (label, transcript)
            if "SL2005" not in ids:
                assert "SL2005" not in transcript, (label, transcript)
            if not ids:
                assert "PASS" in transcript, (label, transcript)
            if binary == "axiomGate":
                result = json.loads(output.read_text())
                assert [d["id"] for d in result["diagnostics"]] == list(ids), (label, result)
                assert result["status"] == ("incomplete" if ids else "completed"), (label, result)
                for diagnostic in result["diagnostics"]:
                    assert diagnostic["impact"] == "incomplete", (label, diagnostic)
                    if diagnostic["id"] == "SL2005":
                        assert reason in diagnostic["arguments"]["detail"], (label, diagnostic)
                        assert diagnostic["location"]["kind"] == "project", (label, diagnostic)
            print(f"frozen exits {label}: PASS", flush=True)

        for binary, flags in (("docFenceAudit", ["--jobs", "1", "--verbose"]), ("axiomGate", ["--with-docs"])):
            action = 'IO.FS.writeFile path ((← IO.FS.readFile path) ++ "\\n")'
            for phase in ("positive", "changed", "restored"):
                bad = phase == "changed"
                run_case(f"import/{binary}/{phase}", binary=binary, flags=flags,
                    fence=IMPORT.format(enabled="true" if bad else "false", action=action), grouped=True,
                    ids=("SL4002", "SL2005") if bad else (),
                    reason="producer-source: source snapshot changed: DocFence_1" if bad else "")
            action = 'IO.FS.removeFile path\n      let _ ← IO.FS.readFile path\n      pure ()'
            run_case(f"import/{binary}/missing-and-throw", binary=binary, flags=flags,
                fence=IMPORT.format(enabled="true", action=action), grouped=True,
                ids=("SL4002", "SL2005"), reason="producer-source: source snapshot unavailable: DocFence_1")
            run_case(f"import/{binary}/throw-restored", binary=binary, flags=flags,
                fence=IMPORT.format(enabled="false", action=action), grouped=True)

            unchanged_throw = 'let _ := path\n      throw <| IO.userError "producer-source: deliberate unchanged initializer failure"'
            run_case(f"import/{binary}/unchanged-exception", binary=binary, flags=flags,
                fence=IMPORT.format(enabled="true", action=unchanged_throw), grouped=True,
                ids=("SL4002",), reason="checker inspection failed")
            run_case(f"import/{binary}/exception-restored", binary=binary, flags=flags,
                fence=IMPORT.format(enabled="false", action=unchanged_throw), grouped=True)

        for label, binary, flags in (
            ("fresh", "axiomGate", []),
            ("incremental", "axiomGate", ["--incremental"]),
            ("file-dependency", "axiomGate", ["--file", "Standalone.lean", "--claim", "standard-logical"]),
            ("documentation-build", "docFenceAudit", ["--jobs", "1"]),
        ):
            for phase in ("positive", "missing", "restored", "ordinary-error", "ordinary-restored"):
                missing = phase == "missing"
                ordinary = phase == "ordinary-error"
                mutation = ('open Lean Elab Command in\nrun_cmd do\n  let path ← getFileName\n'
                            '  IO.FS.removeFile path\n  let _ ← IO.FS.readFile path\n  pure ()\n')
                run_case(f"build/{label}/{phase}", binary=binary, flags=flags,
                    source=GOOD + (mutation if missing else '\ndef bad : Nat := "wrong"\n' if ordinary else ''),
                    ids=("SL2005",) if missing else (("SL2003",) if binary == "axiomGate" else ("error",)) if ordinary else (),
                    reason="producer-source: source snapshot unavailable: Example" if missing else "")
        lost = ('open Lean Elab Command in\nrun_cmd do\n  let path ← getFileName\n'
                '  IO.FS.removeFile path\n  let _ ← IO.FS.readFile path\n  pure ()\n')
        for binary, flags in (("docFenceAudit", ["--jobs", "1"]), ("axiomGate", ["--with-docs"])):
            run_case(f"compile/{binary}/missing", binary=binary, flags=flags, fence=GOOD + lost,
                     ids=("SL4002", "SL2005"), reason="producer-source: source snapshot unavailable: DocFence_1")
            run_case(f"compile/{binary}/restored", binary=binary, flags=flags)
        flags = ["--file", "Standalone.lean", "--claim", "standard-logical"]
        mutation = ('open Lean Elab Command in\nrun_cmd do\n'
                    '  let path := (← IO.currentDir) / "Standalone.lean"\n'
                    '  IO.FS.removeFile path\n  let _ ← IO.FS.readFile path\n  pure ()\n')
        run_case("build/original-file-missing", source=GOOD + mutation, flags=flags,
                 ids=("SL2005",), reason="producer-source: source snapshot unavailable: AuditFile_")
        run_case("build/original-file-restored", flags=flags)
        run_case("compile/file/missing", flags=flags, file_source=GOOD + lost,
                 ids=("SL2005",), reason="producer-source: source snapshot unavailable: AuditFile_")
        run_case("compile/file/restored", flags=flags)
        changed_config = ('run_cmd do\n  let path := (← IO.currentDir) / "foundation_manifest.json"\n'
                          '  IO.FS.removeFile path\n  let _ ← IO.FS.readFile path\n  pure ()\n')
        run_case("build/configuration-missing", source=GOOD + changed_config,
                 ids=("SL2005",), reason="producer-source: configuration snapshot changed:")
        run_case("build/configuration-restored")


if __name__ == "__main__":
    main()
