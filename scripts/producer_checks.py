#!/usr/bin/env python3
"""Fresh-project qualification of census/replay/doc producers and real source-owned fixtures.

This exercises IO, imported Lean metadata and actual JSON admission, which pure policy
proofs do not authenticate. Sources are copied verbatim; every mutation has a fresh
restored control. Optional evidence retains the exact sources and emitted diagnostics.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", type=Path)
    args = parser.parse_args()
    env = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}
    records = []
    with tempfile.TemporaryDirectory(prefix="producer-controls-", dir=ROOT / "tmp") as raw:
        project = Path(raw)
        (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (project / "lakefile.lean").write_text(
            "import Lake\nopen Lake DSL\npackage producer_adopter\nrequire strict_lean from "
            + json.dumps(str(ROOT)) + "\n@[default_target] lean_lib Example\n")
        (project / "foundation_manifest.json").write_text(json.dumps({
            "schema-version": 2,
            "surfaces": [{"library": "Example", "claim": "kernel-only", "execution": "checked",
                          "rationale": "The unchanged reflexivity proposition and exact doc presence."}],
            "excluded-libraries": [], "excluded-executables": []}))
        manifest = json.loads((ROOT / "lake-manifest.json").read_text())
        for package in manifest["packages"]:
            package["inherited"] = True
        manifest["packages"].append({"name": "strict_lean", "scope": "", "type": "path",
            "dir": str(ROOT), "configFile": "lakefile.lean", "manifestFile": "lake-manifest.json",
            "inherited": False})
        (project / "lake-manifest.json").write_text(json.dumps(manifest))
        (project / ".lake").mkdir()
        (project / ".lake/packages").symlink_to(ROOT / ".lake/packages", target_is_directory=True)
        theorem_type = None
        for invocation, flags, mode in (("fresh", [], "freshProject"),
                ("incremental", ["--incremental"], "incrementalProject"),
                ("build-lint", ["--build-lint"], "incrementalProject")):
            for rule in ("SL5001", "SL5002"):
                for kind in ("Fixed", "Violation", "Fixed"):
                    path = ROOT / "examples/rules" / rule / f"{kind}.lean"
                    source = path.read_bytes()
                    (project / "Example.lean").write_bytes(source)
                    output = project / f"result-{len(records)}.json"
                    assert not output.exists()
                    if kind == "Fixed":
                        shutil.rmtree(project / ".lake/build", ignore_errors=True)
                    result = subprocess.run([str(ROOT / ".lake/build/bin/axiomGate"),
                        "--project", str(project), *flags, "--json-out", str(output)],
                        cwd=project, env=env, text=True, capture_output=True, timeout=60)
                    assert output.is_file(), (rule, kind, result.stdout, result.stderr)
                    observed = json.loads(output.read_text())
                    expected = [rule] if kind == "Violation" else []
                    assert [d["id"] for d in observed["diagnostics"]] == expected, (rule, kind, observed, result.stderr)
                    assert result.returncode == bool(expected), (rule, kind, result.stdout, result.stderr)
                    assert observed["status"] == ("rejected" if expected else "completed"), observed
                    assert (project / "Example.lean").read_bytes() == source
                    report = observed["scope"]["surfaces"][0]["report"]
                    assert report["admission"]["required"] == report["admission"]["admitted"]
                    assert observed["mode"] == mode and observed["unresolved"] == [], observed
                    key = [[["str", "Example"]], [["str", "reflexive"]]]
                    assert report["census"] == {"modules": [key[0]], "declarations": [key], "executionRoots": []}, report["census"]
                    assert key in report["admission"]["required"], report["admission"]
                    snapshots = observed["scope"]["sources"]
                    assert len(snapshots) == 1 and snapshots[0]["module"] == key[0], snapshots
                    assert snapshots[0]["source"].encode() == source and Path(snapshots[0]["path"]).name == "Example.lean", snapshots
                    documentation = report["documentation"]
                    assert documentation["modules"] == [[key[0], rule == "SL5002" or kind == "Fixed"]], documentation
                    material = [key] if rule == "SL5002" else []
                    assert documentation["materialDeclarations"] == material, documentation
                    doc = "Every natural number equals itself, without additional hypotheses. " if kind == "Fixed" else None
                    assert documentation["declarations"] == ([[key, doc]] if material else []), documentation
                    assert len(report["declarations"]) == 1, report["declarations"]
                    declaration = report["declarations"][0]
                    assert declaration["axioms"] == [] and not declaration["isUnsafe"] and not declaration["isPartial"], declaration
                    if theorem_type is None:
                        theorem_type = declaration["type"]
                    assert declaration["type"] == theorem_type, declaration
                    if expected:
                        finding = observed["diagnostics"][0]
                        assert finding["impact"] == "violation", finding
                        assert finding["location"]["kind"] == ("module" if rule == "SL5001" else "source"), finding
                        assert finding["related"] == [] and finding["mode"] == mode, finding
                        assert finding["claim"] == "kernel-only" and finding["severity"] == "error", finding
                        if rule == "SL5001":
                            assert finding["location"] == {"kind": "module", "name": [["str", "Example"]]}, finding
                            assert finding["arguments"] == {"subject": "Example", "detail":
                                "module-documentation: add a module doc comment describing this module"}, finding
                        else:
                            assert finding["arguments"] == {"declaration": [["str", "reflexive"]], "detail":
                                "material-documentation: document the claim, assumptions and evidence at this declaration"}, finding
                            location = finding["location"]
                            assert location["source"].encode() == source and Path(location["uri"]).name == "Example.lean", finding
                            start = source.index(b"reflexive", source.index(b"theorem"))
                            assert location["selectionRange"] == {"startByte": start, "endByte": start + len(b"reflexive")}, finding
                            assert location["range"] == {"startByte": source.index(b"@["), "endByte": len(source) - 1}, finding
                    records.append({"rule": rule, "case": kind, "invocation": invocation, "path": str(path.relative_to(ROOT)),
                                    "source": source.decode(), "result": observed})
                    print(f"{invocation} project {rule}/{kind}: PASS", flush=True)
        # The final actual SL5002 control supplies a nonempty selected-declaration census.
        checked = subprocess.run(["lake", "env", "lean", "--run",
            "lean/StrictLean/Checker/ProducerQualification.lean", str(output)],
            cwd=ROOT, env=env, text=True, capture_output=True, timeout=30)
        assert checked.returncode == 0, (checked.stdout, checked.stderr)
        print(checked.stdout, end="", flush=True)
        # The same documented standalone source used by the older structural control:
        # a claimed executable is a module even when the library imports nothing from it.
        config = project / "lakefile.lean"
        config.write_text(config.read_text() + "\nlean_exe sampleTool where\n  root := `SelftestMain\n")
        manifest_path = project / "foundation_manifest.json"
        scope_manifest = json.loads(manifest_path.read_text())
        scope_manifest["surfaces"][0]["executables"] = ["sampleTool"]
        manifest_path.write_text(json.dumps(scope_manifest))
        main_source = "/-! Standalone no-effect IO entrypoint. -/\ndef main : IO Unit := pure ()\n"
        for phase in ("positive", "axiom", "restored"):
            source = main_source + ("axiom ownedAssumption : True\n" if phase == "axiom" else "")
            (project / "SelftestMain.lean").write_text(source)
            shutil.rmtree(project / ".lake/build", ignore_errors=True)
            output = project / f"standalone-{phase}.json"
            result = subprocess.run([str(ROOT / ".lake/build/bin/axiomGate"), "--project", str(project),
                "--json-out", str(output)], cwd=project, env=env, text=True, capture_output=True, timeout=60)
            assert output.is_file(), (phase, result.stdout, result.stderr)
            observed = json.loads(output.read_text())
            expected = ["SL1001"] if phase == "axiom" else []
            assert result.returncode == bool(expected) and [d["id"] for d in observed["diagnostics"]] == expected, observed
            assert observed["status"] == ("rejected" if expected else "completed"), observed
            account = observed["scope"]["surfaces"][0]["report"]
            main_name = [["str", "SelftestMain"]]
            assert [main_name, True] in account["documentation"]["modules"], account["documentation"]
            assert [main_name, [["str", "main"]]] in account["census"]["executionRoots"], account["census"]
            print(f"standalone executable {phase}: PASS", flush=True)
    if args.evidence:
        args.evidence.parent.mkdir(parents=True, exist_ok=True)
        args.evidence.write_text(json.dumps({"schemaVersion": 1, "examples": records}, indent=2) + "\n")
    print("producer qualification: PASS (scoped operational evidence)", flush=True)


if __name__ == "__main__":
    main()
