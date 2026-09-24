# Issue 15 rule-reference website: delivery evidence

Branch `fm/strict-lean-15-site` from `main` `3a9bb58309ed19283aea84c675040fdd3ff89637`.
Lean `v4.34.0` (`293d5d0c`), Mathlib `5ed2965256430c3649e86755f9576b54eca72435`, Verso
`cad4b633e75ea769b851f12f9ca3b4f0dfcc625f`; macOS 27.0, Apple M4 Pro (14 cores).
Labels: **proved** (kernel-checked in the build), **observed** (a run on this machine),
**assumed** (a trusted boundary), **outstanding** (not yet done).

## Delivered

- `PlumbCore.Site`, `PlumbCore.SitePage`, `PlumbCore.SiteDocs` (claimed): routes, editions,
  escaping, raw-HTML admission, filters, diffs, link checking and page construction.
- `PlumbCore.Guide` (claimed): the explanation of every rule, one exhaustive definition.
- `Plumb.Site.Build`, `Plumb.Site.Artifact`, `Plumb.Site.Main` (`lake exe site`): evidence
  admission, generation, Verso rendering, assembly and artifact check.
  `Plumb.Site.Deployment`: toolchain-only live-site comparison.
- `website/`: pinned Verso package (lock copied from the retired prototype) with the
  `PlumbSite` raw-HTML block and stylesheet; `website/Generated/` is generated and ignored.
- `./scripts/verify.sh site` (new `PlumbVerification` mode); CI jobs `rule-examples` (moved
  from the diagnostics workflow), `site`, `deploy`, `verify-deployment`.
- Retired: `examples/rule-reference-prototype/` and `PlumbQualification.Website` (see the
  replacement map in the PR description).
- GitHub Pages enabled for `rbeauchamp/lean-plumb` with source **GitHub Actions**
  (`build_type = workflow`, HTTPS enforced); the `github-pages` environment allows `main` only.
  No custom domain, release or visibility change.

## Proved (kernel-checked by `lake build` / ordinary acceptance)

| Claim | Declaration |
| --- | --- |
| One page route per rule per edition, no duplicates, every rule present | `Plumb.Site.pageFiles_nodup`, `mem_pageFiles`, `Edition.pagePath_injective` |
| One generated Verso module per rule, no duplicates | `ruleModules_nodup` |
| Emitted help URL = development page route | `Plumb.Site.Build.helpUrl_dev` (`rfl`; in the excluded `Plumb` library, kernel-checked when `lake exe site` is built, not by ordinary acceptance) |
| Escaped text contains no `<`, `>`, `"`, `'` or backtick | `escape_safe`, `escape_no_backtick` |
| Raw HTML enters Verso only fenced and backtick-free | `htmlBlock_ok` |
| No-match notice exactly for empty filter states | `mem_emptySelections` |
| Link check empty iff every scanned link resolves | `linkErrors_nil_iff`, `checkedLinkErrors` |
| Every rule page has the nine required sections in order | `ruleSections_headings` (`rfl`) |
| Every rule explanation's required fields are nonempty strings or lists | `guide_wellFormed` (`decide +kernel` over all 21 rules) |

Apart from `helpUrl_dev`, their exact axiom sets are checked by ordinary acceptance under the
Standard-Logical claim of `PlumbCore`. The link check's tokenizer controls (including the review
counterexamples below) are evaluated `#guard` observations of the compiled function, not proofs. They do not cover Verso rendering, the tokenizer's completeness, browsers,
GitHub Pages or the network.

## Observed locally

| Command | Result | Time |
| --- | --- | --- |
| `./scripts/verify.sh diagnostics rule-examples 1/2` | PASS (12 rules) | 79 s |
| `./scripts/verify.sh diagnostics rule-examples 2/2` | PASS (9 rules) | 72 s |
| `./scripts/verify.sh site` (tooling and Verso already built) | PASS: 21 pages per edition, 190 files, 0 unresolved links, `--validate-site` accepted | 14 s |
| `./scripts/verify.sh` (warm dependency and root build state) | PASS: 6 claimed libraries, 56 owned modules, 7756 owned declarations | 123 s |
| `./scripts/verify.sh docs` | PASS | 87 s |

The worktree had uncommitted changes, so the local artifact is a labelled preview without a
`rev/` edition. Cold CI timings are recorded by the PR's exact-head CI run.

## Browser observations (bounded, not proofs)

Served `_site/` at `/lean-plumb/` with a local static server that answers missing paths with
`404.html` (as GitHub Pages does); Chrome 153 headless through `chrome-devtools-axi`.

- **Layouts.** Rule pages (PL1001, PL2001, PL5003), the index, home, versions and the
  not-available page inspected at 1280×1000 and 390×844. Problem and action lead each rule
  page; facts, examples, diffs (`+`/`-` markers, folded unchanged runs) and findings wrap or
  scroll inside their own boxes at narrow width.
- **Filters with JavaScript.** Execution + documentation example → PL1007; + serialized graph
  → no-match notice; Documentation + serialized graph → no-match; Documentation + editor
  snapshot → PL5001, PL5002, PL5003; Reset → all 21 rows.
- **Keyboard.** Tab order reaches the TOC, then each radio group once; arrow keys select and
  filter (Foundation → PL1001–PL1005, Declaration → PL1006); Enter on **Reset filters**
  restores 21 rows; the table region is focusable; Enter on a rule link opens
  `/lean-plumb/dev/rules/PL1001/`.
- **Without JavaScript** (`--blink-settings=scriptEnabled=false`): the complete catalogue, all
  filters and links render; the search box is absent; keyboard filtering works
  (Documentation → PL4001–PL5003; Admission → PL2005).
- **Direct URLs and deep links.** `…/dev/rules/PL1001/#PL1001-example` scrolls to the example;
  `…/v/1.0/rules/PL1001/` returns 404 with the not-available page.
- **Diagnostic-to-page journey.** Every `helpUrl` in the 21 violating records of the corpus
  exports (produced by the real checker) was fetched at the local server: all 200, each page's
  title begins with the diagnostic's rule ID.

The VS Code click-through against the deployed site is #10's verification (the #14 journey
reached the dev route while it returned 404 before deployment).

## Independent review and repairs

Three fresh-context reviews of `b48c30e` (proof and builder fidelity; CI and deployment;
explanation accuracy) reported no blocker. Repairs:

- Link resolution: RFC 3986 scheme detection (a relative link containing `://` was treated as
  external; `javascript://` escaped refusal), `<base href>` reduced to its directory, `>` inside
  quoted attributes; each counterexample is now a `#guard` control that must report an error.
- Deployment: an unprivileged `deploy-gate` job (Lean) and a dependency-free GitHub API
  re-check inside the privileged `deploy` job (which runs no checkout or provisioning) refuse a dirty artifact, another commit, or a revision no
  longer at the head of `main` (a manual re-run of an older run could otherwise republish it);
  hidden files are refused by the artifact check; the verifier retries only on HTTP 200, varies
  its query per attempt and takes the page URL from the environment. Nightly corpus shards
  restored in the diagnostics workflow.
- Builder: a failed check removes `_site/`; `verify.sh site` removes an earlier `_site/` first;
  the uncommitted-changes revision suffix is accepted only for a dirty build; `--validate-site`
  receives descriptor availability and the pages whose content was checked.
- Content: `lake exe axiomGate` is fresh by default; PL2003 project findings are INCOMPLETE
  and disabling a linter does hide the warning (so the page says not to); PL1003/PL1004 include
  the built-in `trustCompiler`/`ofReduceBool`/`ofReduceNat` family; PL1002 editor failure is
  PL2005; PL5003 fenced headings count; PL1006 unsafe-mode, dependency-package and elaborator
  wording; residual lists labelled as the rule-coverage mapping plus the all-residuals statement;
  strict-impact editor note; smaller established/checklist corrections.

Deployment controls observed locally with `Deployment.lean`: `gate` PASS for a clean artifact of
the current head of `main`, refusal for a moved `main`, another commit and a dirty artifact;
`verify` PASS against a local server serving a copy, refusal after one rule page was altered.

## Outstanding

- **Publication.** The live site is deployed by the first `main` run after merge; the
  `verify-deployment` job compares it with the artifact. Until that run passes, live-link
  acceptance is outstanding.
- **Required checks.** Only `verify` is a required status check; adding `site` and the corpus
  shards is an operator decision.
- Released-version (`v/`) pages need a release, which is not authorized. Published `rev/`
  snapshots are retained through the append-only `site-archive` branch (review round 2); that
  mechanism is unobserved until the first deployments to `main`, and a repository rule
  protecting `site-archive` from force pushes and deletion is an operator setting not yet made.
- Semantic accuracy of the 21 explanations is review (R-DOC, R-INTENT), not established by the build.
