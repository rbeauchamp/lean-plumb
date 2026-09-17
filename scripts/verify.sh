#!/bin/bash
# Only bootstrap/root selection and the external, no-grace process-group deadline.
set -euo pipefail
if command -v gtimeout >/dev/null 2>&1; then
  timeout_command=gtimeout
elif command -v timeout >/dev/null 2>&1; then
  timeout_command=timeout
else
  echo "verification requires GNU coreutils timeout" >&2
  exit 127
fi
if [[ $("$timeout_command" --version) != *"GNU coreutils"* ]]; then
  echo "verification requires GNU coreutils timeout" >&2
  exit 127
fi
cd "$(dirname "$0")/.."
exec "$timeout_command" --signal=KILL 420s \
  lean --run lean/StrictLeanVerification.lean "$@"
