#!/bin/bash
# One complete local acceptance run, with a fixed seven-minute deadline.
set -euo pipefail
if command -v gtimeout >/dev/null 2>&1; then
  timeout_command=gtimeout
elif command -v timeout >/dev/null 2>&1; then
  timeout_command=timeout
else
  echo "verification requires GNU coreutils timeout (macOS: brew install coreutils)" >&2
  exit 127
fi
# shellcheck disable=SC2329
standard_verify_checks() {
  if [[ $("$2" --version) != *"GNU coreutils"* ]]; then
    echo "verification requires GNU coreutils timeout" >&2
    exit 127
  fi
  cd "$(dirname "$1")/.."
  shift 2
  git diff --check
  git diff --cached --check
  shellcheck scripts/verify.sh
  case "${1:-}" in
    "")
      if (( $# != 0 )); then echo "ordinary verification takes no arguments" >&2; exit 2; fi
      # Build the required executables and type-check diagnostic modules once.
      # Diagnostic native binaries are built by their lake exe invocation below.
      # The declaration gate owns fresh claimed-source elaboration.
      lake build StrictLeanPolicy axiomGate docFenceAudit \
        +StrictLean.Checker.CheckerSelftest:olean +StrictLean.Checker.FreshChecker:olean \
        +StrictLean.RegistryChecks:olean +StrictLean.Linter:olean \
        +StrictLean.Checker.ProducerQualification:olean +StrictLean.Checker.HistoryQualification:olean \
        +StrictLean.Checker.RuleExamples:olean +StrictLean.Checker.RuleExampleQualification:olean
      lake env lean --run lean/StrictLean/RegistryChecks.lean
      python3 scripts/registry_cli_checks.py
      python3 scripts/native_linter_checks.py
      lake exe axiomGate --with-docs --legacy-json-out tmp/axiom-report.json
      echo "local verification: PASS (complete ordinary conformance commands)"
      ;;
    serialized-graph)
      if (( $# != 1 )); then echo "serialized-graph takes no arguments" >&2; exit 2; fi
      lake exe freshChecker --verbose
      echo "serialized-graph diagnostic: PASS (not ordinary verification)"
      ;;
    diagnostics)
      shift
      if (( $# > 1 )); then echo "diagnostics accepts at most one partition" >&2; exit 2; fi
      case "${1:-}" in
        rule-examples)
          lake build axiomGate ruleExamples +StrictLean.Checker.RuleExampleQualification:olean
          python3 scripts/rule_example_checks.py --evidence tmp/rule-examples.json
          ;;
        producers)
          lake build axiomGate +StrictLean.Checker.ProducerQualification:olean +StrictLean.Checker.HistoryQualification:olean
          python3 scripts/producer_checks.py
          python3 scripts/history_checks.py
          ;;
        "") lake exe checkerSelftest --build-bound --jobs 4 ;;
        fixtures|structural|cli|environments|build-policy)
          lake exe checkerSelftest --build-bound --partition "$1" --jobs 4 ;;
        *) echo "unknown diagnostic partition: $1" >&2; exit 2 ;;
      esac
      echo "diagnostic qualification: PASS (selected scope only; not ordinary verification)"
      ;;
    *) echo "usage: scripts/verify.sh [serialized-graph | diagnostics [fixtures|structural|cli|environments|build-policy|producers|rule-examples]]" >&2; exit 2 ;;
  esac
}
export -f standard_verify_checks
# KILL the process group at 420 seconds: no override, foreground mode, or grace
# period. A killed/incomplete command cannot print the final PASS line.
exec "$timeout_command" --signal=KILL 420s \
  bash -c 'set -euo pipefail; standard_verify_checks "$@"' bash "$0" "$timeout_command" "$@"
