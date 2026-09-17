// Temporary allocation083 adapter: the runner supplies cache-service credentials
// to a JavaScript action. Keep BOTH pinned cache restores and all setup under one
// GNU process-group timeout. Never log credentials or the inherited environment.
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const base = path.resolve('tmp/root-build-diagnostic');
const receipts = path.join(base, 'receipts');
function run(command, args, env = process.env) {
  const result = spawnSync(command, args, { env, stdio: 'inherit' });
  if (result.error || result.status !== 0) throw new Error(`${command} failed (${result.status}, ${result.signal})`);
}
try {
  if (process.argv[2] !== 'bounded') {
    fs.mkdirSync(receipts, { recursive: true });
    fs.writeFileSync(path.join(receipts, 'status.json'), '{"status":"INCOMPLETE","phase":"setup"}\n');
    fs.writeFileSync(path.join(base, 'setup-start'), String(Date.now() / 1000));
    run('timeout', ['--signal=KILL', '300s', process.execPath, __filename, 'bounded']);
  } else {
    const engine = path.join(base, 'cache-restore.cjs');
    // Same immutable cache action as ordinary CI; its bundled restore entrypoint.
    run('curl', ['--fail', '--location', '--silent', '--show-error',
      'https://raw.githubusercontent.com/actions/cache/55cc8345863c7cc4c66a329aec7e433d2d1c52a9/dist/restore-only/index.js',
      '-o', engine]);
    for (const [kind, cachePath] of [['toolchain', '~/.elan/toolchains'], ['dependencies', '.lake/packages']]) {
      const output = path.join(base, `${kind}-cache-output`);
      fs.writeFileSync(output, '');
      run(process.execPath, [engine], {
        ...process.env,
        INPUT_PATH: cachePath,
        INPUT_KEY: process.env[`INPUT_${kind.toUpperCase()}-KEY`],
        'INPUT_RESTORE-KEYS': '',
        'INPUT_FAIL-ON-CACHE-MISS': 'true',
        'INPUT_LOOKUP-ONLY': 'false',
        INPUT_ENABLECROSSOSARCHIVE: 'false',
        GITHUB_OUTPUT: output,
      });
      // GITHUB_OUTPUT is the action's emitted protocol, not implementation text.
      // @actions/core writes multi-line records with a per-record delimiter.
      const lines = fs.readFileSync(output, 'utf8').split(/\r?\n/);
      const hits = [];
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('cache-hit<<')) {
          const delimiter = lines[i].slice('cache-hit<<'.length);
          if (lines[i + 2] !== delimiter) throw new Error('invalid cache-hit output');
          hits.push(lines[i + 1]);
        } else if (lines[i].startsWith('cache-hit=')) hits.push(lines[i].slice(10));
      }
      if (hits.length !== 1 || hits[0] !== 'true') throw new Error(`${kind}: exact cache hit required`);
    }
    run('python3', ['diagnostic-source/scripts/root_build_diagnostic.py', 'setup']);
  }
} catch (error) {
  // Parent survives group timeout and retains INCOMPLETE alongside partial receipts.
  fs.writeFileSync(path.join(receipts, 'status.json'), JSON.stringify({ status: 'INCOMPLETE', phase: 'setup', reason: error.message }) + '\n');
  process.exitCode = 1;
}
