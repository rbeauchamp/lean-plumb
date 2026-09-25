Read `session/session-context.md` from your own verified worktree. Refresh current
`origin/main`, the live GitHub Project 8 board and the issue you are working on
(https://github.com/rbeauchamp/lean-plumb/issues), including its comments and native blockers.

The core Project 8 product (issues #11–#15, #25, #43 foundation) is delivered; issue #10
qualified it end to end ([product qualification](../docs/guides/product-qualification.md)).
Optional #8 (con-leche export research) and conditional #9 (adapter) remain separate and do not
gate core work. Separately tracked follow-ups (for example #69) keep their own issues.

Acceptance is exactly `./scripts/verify.sh` then `./scripts/verify.sh docs`, each under its own
hard 420-second deadline (AGENTS.md). Rule, explanation, example or site changes also need both
corpus shards and `./scripts/verify.sh site` at the same commit. Firstmate owns protected merge,
issue reconciliation, merged-main CI observation and owned cleanup.
