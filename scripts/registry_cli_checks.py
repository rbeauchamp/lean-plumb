#!/usr/bin/env python3
"""Focused process/output admission controls; no policy inference lives here.

The typed registry and canonical construction credit con-leche; see
 docs/guides/rule-registry.md. Each malformed invocation must fail and invalidate
its recognizable absolute destination. Ten seconds bounds a regressed invocation;
its owned process group is terminated if it unexpectedly starts an audit.
"""
import json
import os
from pathlib import Path
import signal
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
EXE = ROOT / '.lake/build/bin/axiomGate'


def run(args):
    with subprocess.Popen([str(EXE), *args], cwd=ROOT, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True, start_new_session=True) as proc:
        try:
            stdout, stderr = proc.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            proc.communicate()
            raise
        return proc.returncode, stdout, stderr


def main():
    (ROOT / 'tmp').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='registry-cli-', dir=ROOT / 'tmp') as temporary:
        output = Path(temporary) / 'result.json'
        missing_project = Path(temporary) / 'missing-project'
        cases = [
            ['--claim', 'unknown'], ['--unknown'],
            ['--file', 'x.lean', '--incremental'],
            ['--project', str(missing_project)],
            ['--project', str(ROOT), '--project', str(ROOT)],
            ['--json-out', str(output)],
            ['--legacy-json-out', str(Path(temporary) / 'legacy.json')],
        ]
        for arguments in cases:
            output.write_text(json.dumps({'status': 'completed', 'old': True}))
            code, stdout, stderr = run(['--json-out', str(output), *arguments])
            assert code != 0, (arguments, stdout, stderr)
            result = json.loads(output.read_text())
            assert result['status'] == 'incomplete' and 'old' not in result, (arguments, result)
    print('registry CLI qualification: PASS (configuration failures invalidate current output)')


if __name__ == '__main__':
    main()
