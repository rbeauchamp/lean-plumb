#!/usr/bin/env python3
"""Bounded PRODUCT-01 probe. Attribution and evidence limits: README.md."""
import hashlib
import html
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = HERE / 'generated'
OUT.mkdir(exist_ok=True)
ENV = os.environ.copy()
ENV.pop('LEAN_SRC_PATH', None)
ENV['LEAN_PATH'] = os.pathsep.join([str(OUT), str(ROOT / '.lake/build/lib/lean')])
START = time.monotonic()

def run(args, *, cwd=ROOT, expected=0, env=None):
    remaining = 600 - (time.monotonic() - START)
    if remaining <= 0:
        raise RuntimeError('600-second prototype budget exhausted')
    result = subprocess.run(args, cwd=cwd, env=env or ENV, text=True,
                            capture_output=True, timeout=remaining)
    if result.returncode != expected:
        raise RuntimeError(f'{args}: expected {expected}, got {result.returncode}\n'
                           + result.stdout + result.stderr)
    return result.stdout

# Dependencies must be provisioned first; this is not ordinary repository acceptance.
assert '4.33.1' in run(['lake', 'env', 'lean', '--version'])
for name in ['Rule', 'Probe']:
    run(['lake', 'env', 'lean', '-o', str(OUT / f'{name}.olean'), str(HERE / f'{name}.lean')])
metadata = json.loads(run(['lake', 'env', 'lean', '--run', str(HERE / 'Export.lean')]))
assert metadata['id'] == 'SL1001' and metadata['reason'] == 'project-axiom'
(OUT / 'rule.json').write_text(json.dumps(metadata, indent=2) + '\n')
results = {}
for name, exit_code in [('Fixed', 0), ('Violation', 1), ('Fixed', 0)]:
    source = HERE / 'fixtures' / f'{name}.lean'
    run(['lake', 'env', 'lean', '-o', str(OUT / f'{name}.olean'), str(source)])
    client = OUT / 'Client.lean'
    client.write_text(f'import Probe\nimport {name}\n#strict_probe {name} {json.dumps(str(source))}\n')
    raw = run(['lake', 'env', 'lean', '--json', str(client)], expected=exit_code)
    messages = [json.loads(line) for line in raw.splitlines() if line.strip()]
    if exit_code:
        assert len(messages) == 1
        diagnostic = messages[0]
        assert diagnostic['severity'] == 'error'
        assert diagnostic['kind'] == 'StrictLean.SL1001._namedError'
        assert diagnostic['pos'] == {'line': 2, 'column': 6}
        assert diagnostic['endPos'] == {'line': 2, 'column': 17}
        assert diagnostic['fileName'] == str(source)
        assert metadata['title'] in diagnostic['data']
        assert diagnostic['data'].endswith('/strict-lean/dev/' + metadata['path'])
    else:
        assert not messages
    results[name] = {'source': source.read_text(), 'messages': messages}

# Exercise the actual public checker and Lake's dependency lint-driver dispatch.
# The driver builds only Widget, not the root repository's mathematical examples.
adopter = OUT / 'adopter'
adopter.mkdir(exist_ok=True)
(adopter / 'lean-toolchain').write_text((ROOT / 'lean-toolchain').read_text())
(adopter / 'lakefile.toml').write_text('''name = "rule_probe_adopter"
lintDriver = "strict_lean/axiomGate"
lintDriverArgs = ["--build-lint"]
[[require]]
name = "strict_lean"
path = "../../../.."
[[lean_lib]]
name = "Widget"
''')
(adopter / 'foundation_manifest.json').write_text(json.dumps({
    'schema-version': 2,
    'surfaces': [{'library': 'Widget', 'claim': 'standard-logical', 'rationale': 'Isolated prototype control.'}],
    'excluded-libraries': [], 'excluded-executables': []}, indent=2) + '\n')
clean_env = os.environ.copy()
clean_env.pop('LEAN_PATH', None)
clean_env.pop('LEAN_SRC_PATH', None)
# Use existing locked dependency artifacts. No update against moving dependency branches.
(adopter / '.lake').mkdir(exist_ok=True)
packages = adopter / '.lake/packages'
if not packages.exists():
    packages.symlink_to(ROOT / '.lake/packages', target_is_directory=True)
manifest = json.loads((ROOT / 'lake-manifest.json').read_text())
manifest['name'] = 'rule_probe_adopter'
for package in manifest['packages']:
    package['inherited'] = True
manifest['packages'].append({'type':'path','name':'strict_lean','dir':'../../../..',
    'manifestFile':'lake-manifest.json','inherited':False,'configFile':'lakefile.lean'})
(adopter / 'lake-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
for name, exit_code in [('Fixed', 0), ('Violation', 1), ('Fixed', 0)]:
    shutil.rmtree(adopter / '.lake/build', ignore_errors=True)
    (adopter / 'Widget.lean').write_text(results[name]['source'])
    output = run(['lake', 'lint'], cwd=adopter, expected=exit_code, env=clean_env)
    if exit_code:
        assert '[project-axiom]' in output and 'unsupported' in output
    else:
        assert 'PASS' in output
    results[name]['publicChecker'] = output

# Generate text code blocks from exact checked files, never re-elaborate with Verso's compiler.
# This deliberately small adapter avoids imposing SubVerso on the checker package.
def block(source):
    assert '```' not in source
    return '```\n' + source.rstrip('\n') + '\n```\n'
page = '''import VersoManual
open Verso.Genre Manual
#doc (Manual) "''' + metadata['id'] + ': ' + metadata['title'] + '''" =>
%%%
tag := "SL1001"
%%%
This architecture prototype executes the checker and fixtures with Lean 4.33.1.
Verso renders the checked source as text using Lean 4.33.0; it does not recheck it.

# Cause
An owned logical axiom supplies an assumption without a checked body.
The policy rejects even an unused axiom. A body-bearing opaque definition is different.

# Violation
''' + block(results['Violation']['source']) + '''
# Diagnostic
''' + block(results['Violation']['messages'][0]['data']) + '''
# Fix
State a conditional theorem with its assumption as a hypothesis, or supply a checked proof.
The correction below proves only its conditional proposition, not False unconditionally.
''' + block(results['Fixed']['source']) + '''
# Configuration and limits
This rule is required on positive surfaces under every logical foundation profile.
There is no local suppression that makes a project axiom conforming.
The prototype's explicit command inspects imported modules; immediate editor scheduling,
complete registry coverage and whole-project conformance remain later deliverables.

# Sources and credit
[Normative requirement](https://github.com/rbeauchamp/strict-lean/blob/main/''' + metadata['normative'] + ''').
Canonical metadata and proof-bearing acceptance design are informed by
[con-leche](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean).
The linter and widget interfaces are Lean APIs. Static rendering uses Verso;
the [Verso templates](https://github.com/leanprover/verso-templates/tree/76c9edf5a70f14d272af0f0f354ec833ac22c350)
inform the separate documentation toolchain.
[Microsoft CA1416](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/ca1416)
informs the explanation structure. Con-ron is excluded.
'''
(HERE / 'site/Docs.lean').write_text(page)
run(['lake', 'build', 'site'], cwd=HERE / 'site', env=clean_env)
run(['lake', 'exe', 'site'], cwd=HERE / 'site', env=clean_env)
site_root = OUT / 'public'
route = site_root / 'strict-lean/dev' / metadata['path']
shutil.rmtree(site_root, ignore_errors=True)
shutil.copytree(HERE / 'site/_out/html-single', route)
assert (route / 'index.html').is_file()
rendered = (route / 'index.html').read_text()
assert metadata['id'] in rendered and 'unsupported' in rendered and 'conditional' in rendered
(site_root / 'index.html').write_text('<!doctype html><title>Diagnostic link probe</title>'
    '<p>' + html.escape(results['Violation']['messages'][0]['data']) + '</p>'
    '<a href="/strict-lean/dev/' + metadata['path'] + '">Explain ' + metadata['id'] + '</a>')
# Check reproducible generator output at identical inputs, without rerunning Lean checks.
first = {str(f.relative_to(route)): hashlib.sha256(f.read_bytes()).hexdigest()
         for f in route.rglob('*') if f.is_file()}
run(['lake', 'exe', 'site'], cwd=HERE / 'site', env=clean_env)
second_root = HERE / 'site/_out/html-single'
second = {str(f.relative_to(second_root)): hashlib.sha256(f.read_bytes()).hexdigest()
          for f in second_root.rglob('*') if f.is_file()}
assert first == second, 'static output changed for identical inputs'
(OUT / 'evidence.json').write_text(json.dumps({'rule': metadata, 'results': results,
    'reproducibleFiles': len(first), 'elapsedSeconds': round(time.monotonic()-START, 2),
    'editorInteraction': 'NOT RUN; required in ADOPTION-01'}, indent=2) + '\n')
print('Prototype PASS: actual policy, native diagnostic, Lake dependency driver, fixture correction, Verso output.')
print('Serve generated/public and open /; editor interaction remains unverified.')
