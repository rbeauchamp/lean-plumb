#!/usr/bin/env python3
"""Qualify pre-build dependency binding through public documentation audit routes."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DEPENDENCY = 'namespace Dep\ndef n : Nat := 1\nend Dep\n'
CHANGED = 'namespace Dep\ndef n : Nat := 2\nend Dep\n'
SOURCE = 'import Lean\nimport Dep\n/-! Documentation prerequisite. -/\ntheorem value : Dep.n = 1 := rfl\n'
FENCE = '```lean\nimport Dep\nexample : Dep.n = 1 := rfl\n```\n'


def run(command: list[str], cwd: Path, env: dict[str, str]) -> subprocess.CompletedProcess:
    with subprocess.Popen(command, cwd=cwd, env=env, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, start_new_session=True) as process:
        try:
            output, _ = process.communicate(timeout=120)
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate()
            raise
        return subprocess.CompletedProcess(command, process.returncode, output)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bin-dir', type=Path, default=ROOT / '.lake/build/bin')
    options = parser.parse_args()
    binaries = options.bin_dir.resolve()
    env = {k: v for k, v in os.environ.items() if k not in ('LEAN_PATH', 'LEAN_SRC_PATH')}
    (ROOT / 'tmp').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='documentation-dependency-', dir=ROOT / 'tmp') as raw:
        scratch = Path(raw)
        dependency = scratch / 'dependency'
        dependency.mkdir()
        (dependency / 'lakefile.toml').write_text('name = "dep"\n[[lean_lib]]\nname = "Dep"\n')
        dependency_source = dependency / 'Dep.lean'
        dependency_source.write_text(DEPENDENCY)
        (dependency / 'lean-toolchain').write_bytes((ROOT / 'lean-toolchain').read_bytes())
        project = scratch / 'project'
        project.mkdir()
        (project / 'docs').mkdir()
        (project / 'docs/control.md').write_text(FENCE)
        (project / 'lean-toolchain').write_bytes((ROOT / 'lean-toolchain').read_bytes())
        (project / 'lakefile.toml').write_text(
            'name = "documentation_dependency"\n[[require]]\nname = "dep"\npath = "../dependency"\n'
            '[[lean_lib]]\nname = "Example"\n')
        (project / 'foundation_manifest.json').write_text(json.dumps({
            'schema-version': 2, 'surfaces': [{'library': 'Example', 'claim': 'kernel-only',
                'rationale': 'Fixed dependency proposition across prerequisite and fence.'}],
            'excluded-libraries': [], 'excluded-executables': []}))
        (project / 'Example.lean').write_text(SOURCE)
        setup = run(['lake', 'update'], project, env)
        assert setup.returncode == 0, setup.stdout
        output = scratch / 'result.json'
        for route in ('docFenceAudit', 'ruleExamples'):
            for phase in ('positive', 'changed-during-build', 'restored'):
                dependency_source.write_text(DEPENDENCY)
                mutation = '' if phase != 'changed-during-build' else (
                    'run_cmd do\n  IO.FS.writeFile ' + json.dumps(str(dependency_source))
                    + ' ' + json.dumps(CHANGED) + '\n')
                (project / 'Example.lean').write_text(SOURCE + mutation)
                output.unlink(missing_ok=True)
                command = ([str(binaries / route), '--project', str(project), '--jobs', '1']
                           if route == 'docFenceAudit' else
                           [str(binaries / route), '--documentation', str(project),
                            str(project / 'docs'), str(output)])
                result = run(command, project, env)
                if mutation:
                    assert dependency_source.read_text() == CHANGED
                    assert result.returncode != 0, result.stdout
                    assert 'dependency snapshot changed:' in result.stdout, result.stdout
                    assert 'accepted ' not in result.stdout, result.stdout
                    if output.exists():
                        assert 'acceptance' not in json.loads(output.read_text())
                else:
                    assert result.returncode == 0, result.stdout
                    assert 'conforming-positive-pass=1/1' in result.stdout, result.stdout
                    if route == 'ruleExamples':
                        packet = json.loads(output.read_text())
                        assert packet['status'] == 'completed' and 'acceptance' in packet, packet
                print(f'documentation dependencies {route}/{phase}: PASS', flush=True)
        result = run([str(binaries / 'axiomGate'), '--project', str(project), '--with-docs',
                      '--json-out', str(output)], project, env)
        assert result.returncode == 0, result.stdout
        packet = json.loads(output.read_text())
        assert packet['status'] == 'completed', packet
        assert 'acceptance' in packet and 'documentationAcceptance' in packet, packet
        print('documentation dependencies combined/same-snapshot: PASS', flush=True)


if __name__ == '__main__':
    main()
