#!/bin/bash
# Only bootstrap/root selection, failure-only stale-verdict invalidation, and the
# external, no-grace process-group deadline.
set -euo pipefail
cd "$(dirname "$0")/.."
# Failure-only invalidation with the driver's unconditional setup marker. This
# constant INCOMPLETE cannot create a PASS and decides no policy; it only keeps a
# stale earlier verdict from reading as current when prerequisites are missing.
invalidate_stale_verdict() {
  mkdir -p tmp
  printf '{"outcome":"INCOMPLETE","phase":"setup"}\n' > tmp/rule-examples.json
}
if command -v gtimeout >/dev/null 2>&1; then
  timeout_command=gtimeout
elif command -v timeout >/dev/null 2>&1; then
  timeout_command=timeout
else
  echo "verification requires GNU coreutils timeout" >&2
  invalidate_stale_verdict
  exit 127
fi
if [[ $("$timeout_command" --version) != *"GNU coreutils"* ]]; then
  echo "verification requires GNU coreutils timeout" >&2
  invalidate_stale_verdict
  exit 127
fi
exec "$timeout_command" --signal=KILL 420s \
  lean --run lean/StrictLeanVerification.lean "$@"
