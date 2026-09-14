# Session context: Strict Lean Project 8

**Date:** 2026-09-14
**Starting basis:** public `main`, `6e3c68c2b93bfa874b5deb9e956befd366a2de0a` (PRODUCT-01 merge).
**Persistence / resume authority:** this handoff is committed and pushed through a separate PR. Resume from the resulting public `main` after that PR merges; the starting basis above is not the eventual handoff HEAD.
**Working root:** `/Users/richard/Developer/github/strict-lean`.
**Repository:** `origin` is now `https://github.com/rbeauchamp/strict-lean.git`.
**Active focus:** next project-order unit is [#4 policy contract](https://github.com/rbeauchamp/strict-lean/issues/4), a source-grounded research/design deliverable, not implementation of all later policy proofs.

## Plan and completed work

[Project 8](https://github.com/users/rbeauchamp/projects/8) and the full bodies of its open issues are the active plan. Native dependencies govern prerequisites; execution order selects #4 next. #12 is independently ready and optional #8 is unblocked, but neither replaces the immediate unit. Project overview and successor bodies were reconciled before #11 closed. No separate local planning system is needed.

[#11](https://github.com/rbeauchamp/strict-lean/issues/11) was completed by [PR #16](https://github.com/rbeauchamp/strict-lean/pull/16), reviewed source `e5bc6267fa44d03a174c10ba3711e9c32545dff2`, squash merge equal to the starting basis. Issue is Closed and project item Done. Project stays open. At handoff cold review, live #4 is In Progress (changed since the earlier Todo snapshot); no #4 implementation or completion is claimed by this session. Preserve that status and check current task/worktree ownership before resuming, rather than assuming work is unstarted. All 17 native dependency edges were verified. Nine successor bodies (#4–#7, #10, #12–#15) contain the complete selected architecture, 20-rule inventory, nine residual obligations, commands and evidence. Optional #8/#9 scope is unchanged.

Maintained sources of technical decisions:

- [Linter architecture](../docs/guides/linter-architecture.md): typed registry/diagnostics, native integration, modes, trust boundaries, versioned links, selected Verso stack and delivery phases.
- [Rule coverage](../docs/guides/rule-coverage.md): all 20 selected diagnostics, nine residual obligations and reconciliation of all 53 compliance rows.
- [Prototype instructions](../examples/rule-reference-prototype/README.md): actual commands, pinned dependencies, bounded experiment, evidence and limitations.
- [Original research archive, issue #3](https://github.com/rbeauchamp/strict-lean/issues/3): full original con-leche/con-ron report, retained as historical reference with current scope overriding obsolete recommendations.

PRODUCT-01 evidence: two independent fresh-context scoped reviews clean; focused successor handoff review clean after adding missing reproduction commands/evidence. Local ordinary acceptance passed within the enforced 420-second deadline (12 owned modules, 510 declarations, Audit/AuditApp Standard-Logical profiles, 70 positive examples, 23 intended negative failures, one trusted classification). Tool/fixture exclusions remain explicit. One-rule prototype and exact-head CI passed. This is scoped evidence, not full-linter completion or universal metaprogram correctness. No implementation changes occurred after the reviewed head before merge.

## Consolidation and local preservation

The root previously pointed to `strict-lean-preparation` at `9671c9678b724f2214400ca9d3122d601beb6957`. The public delivery lived in `tmp/issue11-delivery`. All tracked delivery docs/code were already integrated in public main, so switching root to public main brought them in without manual copying.

Preparation PR #1 remains open remotely; it was not closed, merged or deleted during consolidation. Its head `b35921dc587869c4baae36afdd0b3b3dde1fca3f` and old main are preserved in local `archive/preparation-pr-1` / `archive/preparation-main` branches and a verified complete `.local-state/session-2026-09-14/preparation.bundle`. Comparison found no unique Lean implementation or scripts to port from that PR (only later public additions, documentation and CI changes).

The clean delivery, Verso and Verso-template temporary clones were removed after preserving evidence. Root `.lake/packages` was the shared dependency target and was retained; the documentation dependency cache was moved into the root prototype's ignored site cache. Generated outputs and former build caches are not new verification evidence for changed inputs.

Local-only `.local-state/session-2026-09-14/` contains copied issue/project snapshots, acceptance log, prototype evidence/rendered output, review record, preparation bundle and a snapshot of `.lavish/`. Original `.lavish/con-leche-con-ron.md`, HTML, sources and project JSON remain at root. Original `tmp/axiom-report.json` and `tmp/detailed-report.json` were preserved. These local archives are not required to implement #4; its full live issue and maintained repository guides are authoritative. No unrelated artifacts belong in the handoff commit. Local research/archives are excluded using `.git/info/exclude`, not deleted or published.

## Ruled out and still unresolved

- Con-ron is excluded by the user; no Rust/Aeneas/Charon integration or automatic later phase.
- The product must be an actual Lean-native strict linter and linked website, not only prose and examples. Do not duplicate already-correct detectors or build a separate Lean parser.
- GitHub Pages from this repository and pinned Verso were selected. The bounded experiment succeeded; Docusaurus fallback is unnecessary, and no GitHub Wiki/manual site catalog should be introduced.
- Documentation Lean 4.33.0 and checker/example Lean 4.33.1 are deliberately separate. Exact checked fixture source is initially rendered as text; rendering does not recheck examples under the documentation semantics.
- `Probe.ownedConstants` inventories imported modules, not live current-document declarations. Production collection/scheduling remains #13. The retained prototype uses an explicit imported-module trigger.
- Lean's built-in named-error widget hardcodes Lean manual URLs; unsupported LSP `codeDescription` is not an available shortcut. The package widget compiles/registers and the textual URL is verified. Actual VS Code infoview interaction remains #14. Browser keyboard activation succeeded; Chrome CLI bridge startup and hidden-tab mouse actions failed. Browser evidence must not be relabeled editor evidence.
- No public rule website was deployed. Production Pages integration remains #15, integrated adopter experience #10. Optional con-leche external checking (#8/#9) does not gate core delivery.

## Standing user constraints

- “Preserve public repository’s 420 seconds.” This overrides stale supplied 360-second instructions for ordinary `./scripts/verify.sh`; no overrides, partitioning or grace periods. Website checks have a separate named budget.
- “all issues and deliverabes MUST appropriately cite and credit con-leche.” Cite the actual influences, distinguish inspiration from copied code and upstream proof guarantees, and preserve applicable notices. The architecture credits [con-leche's proof-bearing checks](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean) and [canonical representation](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean).
- “as you proceed through the project, update its status and the issue statuses and dependencies as needed.” Keep successor bodies self-contained; copy newly settled requirements before unblocking successors. Done requires integrated acceptance, not a plan or partial PR.
- “An ounce of math is worth a pound of computation.” Prefer invariant-preserving types/construction and proofs about executing definitions. Distinguish mathematical, machine-checked, observed, assumed and unresolved claims. Do not replace admission/qualification controls without accounting for their purpose.
- Standing authorization permits requested PR publication and merge after applicable checks/review and exact-head CI, without repeated approval. Preserve unrelated work and protections. No software release, visibility change, custom domain, paid service, or Lean fork is authorized by this handoff.

## Immediate next action and evidence gate

1. From this root, check clean status, origin and current main; fetch current target main and read the full live #4 body plus its native blockers. Confirm #11 remains closed. Read AGENTS.md, the architecture and coverage guides. Check whether an existing task/worktree already owns #4, which is currently In Progress; coordinate or resume that work rather than duplicating it. Use a `codex/` branch.
2. Execute #4's first task: inventory actual data/call flow through discovery, classification, fresh admission, ownership, generated-role authentication, execution closure, workers/JSON, fence/file/build modes, and final acceptance branches. Establish independently specified policy/completeness predicates and their linkage to actual runtime call sites. Resolve unknown/empty/duplicate identities and pure-core import boundaries. Do not mistake string categories for a demonstrated end-to-end bypass.
3. Deliver the maintained source-grounded policy/acceptance design and migration contract required by #4; keep unproved obligations explicit. Update affected successor bodies with exact decisions. Follow the local review skill, proportionate compiler/proof checks and applicable acceptance/qualification, exact-head CI, merge and status reconciliation. Stop this immediate unit after #4 is complete unless the user expands scope.

**Mission-leverage card:** N/A; no separate card or active goal object is used.
