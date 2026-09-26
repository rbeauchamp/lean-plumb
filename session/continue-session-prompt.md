Read `session/session-context.md` from your own verified worktree. Refresh current
`origin/main`, the live GitHub Project 8 board and the issue you are working on
(https://github.com/rbeauchamp/regula/issues), including its comments and native blockers.

The core Project 8 deliveries (#11–#15, #25) and the foundation work behind #43 are merged; issue
#10's integrated qualification is recorded in
[product qualification](../docs/guides/product-qualification.md). #43 is closed (reconciled
against its acceptance criteria on 2026-09-24; delivery PR 64). Check each issue's live state.
Optional #8 (con-leche export research) ended in a no-go and #9 (adapter) is not planned; see
[con-leche research](../docs/guides/con-leche-research.md). Separately tracked follow-ups keep their own issues.

Acceptance is exactly `./scripts/verify.sh` then `./scripts/verify.sh docs`, each under its own
hard 420-second deadline (AGENTS.md). Rule, explanation, example or site changes also need both
corpus shards and `./scripts/verify.sh site` at the same commit. Firstmate owns protected merge,
issue reconciliation, merged-main CI observation and owned cleanup.
