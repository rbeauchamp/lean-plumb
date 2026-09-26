# Session context: Plumb for Lean

*Renamed Regula on 2026-09-26 (repository `rbeauchamp/regula`, package `regula`, namespace `Regula`, rule IDs `RG####`, site `/regula/`); the dated notes below keep the former names.*

**Updated:** 2026-09-24, issue #10 (integrated qualification), from main
`a52bf1f0e2c7854c45ab6694b35b697b5e900fc8`. Refresh live state before resuming; this file is a
pointer, not an authority.

## Product state

- Repository `rbeauchamp/lean-plumb`, Lake package `plumb`, namespace `Plumb`, rule IDs
  PL1001–PL5003 (twenty-one, `PlumbCore.RuleId`), lint driver `plumb/lint`, editor import
  `Plumb.Linter`, rule reference https://rbeauchamp.github.io/lean-plumb/dev/rules/.
- Maintained accounts: [product qualification](../docs/guides/product-qualification.md)
  (per-rule evidence, routes, journeys, website, limits), [adoption](../docs/guides/adoption.md),
  [website](../docs/guides/website.md), [rule coverage](../docs/guides/rule-coverage.md),
  [foundation status](../docs/guides/foundation-status.md).
- Issue evidence records live in [`session/evidence/`](evidence/); the issue #10 record is
  [issue-10-qualification.md](evidence/issue-10-qualification.md). Records of earlier issues
  are historical: they describe their own revisions and names (including the pre-rename
  Strict Lean identifiers) and are not current-change evidence.

## Open work outside core delivery

- [#8](https://github.com/rbeauchamp/regula/issues/8) optional con-leche export research:
  no-go, recorded in [con-leche research](../docs/guides/con-leche-research.md).
  [#9](https://github.com/rbeauchamp/regula/issues/9) adapter: not planned.
- Operator settings (not code): require `site` and the corpus shards as status checks; protect
  `site-archive-regula` against force-push and deletion
  ([retention](../docs/guides/website.md#retention)).
