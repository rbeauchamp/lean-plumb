#!/usr/bin/env python3
"""Focused controls for frozen root and Markdown inventories."""
import argparse
import json
import os
from pathlib import Path
import shutil
import tempfile
from documentation_dependency_checks import run

ROOT = Path(__file__).resolve().parents[1]
WRAPPER = '''#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys
mode = os.environ.get("INVENTORY_FAULT", "")
record = pathlib.Path(os.environ["INVENTORY_RECORD"])
active = sys.argv[1:2] == ["build"] and not record.exists()
if active:
    if mode == "root-add":
        target = pathlib.Path.cwd() / "Example/New.lean"
        target.parent.mkdir(exist_ok=True)
        target.write_text("/-! Added after root discovery. -/\\naxiom escaped : False\\n")
    elif mode.startswith("docs-"):
        target = pathlib.Path(os.environ["INVENTORY_DOC"])
        if mode == "docs-remove": target.unlink()
        else: target.write_text("```lean\\nexample : True := True.intro\\n```\\n")
code = subprocess.run([os.environ["INVENTORY_LAKE"], *sys.argv[1:]]).returncode
if active:
    record.write_text(json.dumps({"buildExit": code,
        "addedBuilt": pathlib.Path(".lake/build/lib/lean/Example/New.olean").exists()}))
sys.exit(code)
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bin-dir', type=Path, default=ROOT / '.lake/build/bin')
    options = parser.parse_args()
    binaries = options.bin_dir.resolve()
    env = {k: v for k, v in os.environ.items() if k not in ('LEAN_PATH', 'LEAN_SRC_PATH')}
    (ROOT / 'tmp').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='input-inventory-', dir=ROOT / 'tmp') as raw:
        scratch = Path(raw)
        project = scratch / 'project'
        project.mkdir()
        (project / 'Example').mkdir()
        (project / 'Example.lean').write_text('/-! Empty declared surface. -/\n')
        (project / 'lean-toolchain').write_bytes((ROOT / 'lean-toolchain').read_bytes())
        (project / 'lakefile.lean').write_text('import Lake\nopen Lake DSL\npackage inventory_control\n'
            'lean_lib Example where\n  globs := #[.andSubmodules `Example]\n')
        (project / 'foundation_manifest.json').write_text(json.dumps({'schema-version': 2,
            'surfaces': [{'library': 'Example', 'claim': 'kernel-only', 'rationale': 'Frozen inventory.'}],
            'excluded-libraries': [], 'excluded-executables': []}))
        setup = run(['lake', 'update'], project, env)
        assert setup.returncode == 0, setup.stdout
        tools = scratch / 'tools'
        tools.mkdir()
        wrapper = tools / 'lake'
        wrapper.write_text(WRAPPER)
        wrapper.chmod(0o755)
        record = scratch / 'build.json'
        env.update(INVENTORY_LAKE=shutil.which('lake'), INVENTORY_RECORD=str(record),
                   PATH=str(tools) + os.pathsep + env['PATH'])
        for mode in ('--incremental', '--build-lint'):
            for phase in ('positive', 'root-add', 'restored'):
                (project / 'Example/New.lean').unlink(missing_ok=True)
                record.unlink(missing_ok=True)
                env['INVENTORY_FAULT'] = phase
                output = scratch / 'root-result.json'
                result = run([str(binaries / 'axiomGate'), '--project', str(project), mode,
                              '--json-out', str(output)], project, env)
                packet = json.loads(output.read_text())
                if phase == 'root-add':
                    observation = json.loads(record.read_text())
                    assert observation == {'buildExit': 0, 'addedBuilt': True}, observation
                    assert result.returncode != 0 and 'root inventory changed:' in result.stdout, result.stdout
                    assert packet['status'] == 'incomplete' and 'acceptance' not in packet, packet
                else:
                    assert result.returncode == 0 and packet['status'] == 'completed', result.stdout
                print(f'root inventory {mode}/{phase}: PASS', flush=True)
        docs = project / 'docs'
        docs.mkdir()
        (docs / 'control.md').write_text('```lean\nexample : True := True.intro\n```\n')
        target = docs / 'target.md'
        env['INVENTORY_DOC'] = str(target)
        for route in ('docFenceAudit', 'ruleExamples'):
            for phase in ('positive', 'docs-edit', 'restored', 'docs-remove', 'restored'):
                record.unlink(missing_ok=True)
                env['INVENTORY_FAULT'] = phase
                failing = phase.startswith('docs-')
                target.write_text('```lean\nexample : False := True.intro\n```\n' if failing else
                                  '```lean\nexample : True := True.intro\n```\n')
                output = scratch / 'docs-result.json'
                output.unlink(missing_ok=True)
                command = ([str(binaries / route), '--project', str(project), '--jobs', '1']
                    if route == 'docFenceAudit' else [str(binaries / route), '--documentation',
                        str(project), str(docs), str(output)])
                result = run(command, project, env)
                if failing:
                    assert json.loads(record.read_text())['buildExit'] == 0
                    reason = 'documentation inventory changed' if phase == 'docs-remove' else 'documentation source changed'
                    assert result.returncode != 0 and reason in result.stdout, result.stdout
                    assert 'accepted ' not in result.stdout, result.stdout
                    if output.exists(): assert 'acceptance' not in json.loads(output.read_text())
                else:
                    assert result.returncode == 0, result.stdout
                print(f'Markdown inventory {route}/{phase}: PASS', flush=True)


if __name__ == '__main__':
    main()
