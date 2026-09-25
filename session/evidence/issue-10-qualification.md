# Issue 10 qualification evidence (observed, 2026-09-24)

Observations of real runs on macOS arm64 (14 cores, shared host), Lean 4.34.0
(`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`), Mathlib `5ed2965256430c3649e86755f9576b54eca72435`.
They are bounded observations, not proofs. The maintained account is
[product-qualification.md](../../docs/guides/product-qualification.md).

## Baseline

- Base: `origin/main` `a52bf1f0e2c7854c45ab6694b35b697b5e900fc8` (#76, WEBSITE-01), all
  `main` workflows green (CI, Diagnostics, Lint driver, CodeQL; CI run 36075732502 deployed and
  verified the site).
- Native blockers of #10: #7, #14, #15, #25 closed; #43's delivery (PR 64) is merged while the
  issue itself was still open when this record was made.

## Fresh-adopter CLI journey

A new project under `tmp/issue10-adopter` (removed afterwards) with `lakefile.toml`:
`require plumb` by Git from `https://github.com/rbeauchamp/lean-plumb` at `a52bf1f…`,
`lintDriver = "plumb/lint"`, library `Tally` claimed `choice-free`/`report`, module
`Tally/Count.lean` importing `Plumb.Linter`. `MATHLIB_NO_CACHE_ON_UPDATE=1 lake update`
cloned Plumb and its pinned transitive dependencies (52 s); `lake build` built 26 jobs.

| Step | Command | Exit | Output (abridged) |
| --- | --- | --- | --- |
| Clean | `lake lint` | 0 | `plumb lint: PASS — incremental project acceptance over existing build state, not a fresh-source audit`; 11 policy jobs; account lists the trusted mechanisms and open R-* obligations |
| `theorem … := by sorry` | `lake lint -- --json-out` | 3 | `PL2003 [incomplete; …]: … FAIL[build-failed]` with Lean's `declaration uses 'sorry'` warning and the PL2003 URL; JSON `status: incomplete` |
| `axiom count_decides …` | `lake lint -- --json-out` | 1 | `PL1001 [violation; incrementalProject; claim=choice-free; …/Tally/Count.lean]: Tally.count_decides: … -> unknown-axiom` and `…/dev/rules/PL1001/`; JSON diagnostic with `helpUrl`, byte range and LSP range of the declaration |
| Proof via `Classical.byCases` | `lake lint` | 1 | `PL1005 … -> standard-logical` and the PL1005 URL |
| Fix: `Nat.eq_zero_or_pos _` | `lake lint` | 0 | PASS |
| Add unclassified `[[lean_lib]] Scratch` | `lake lint` | 2 | `PL2002 … manifest-incomplete: unclassified root Lean libraries ["Scratch"]`, `INVALID CONFIGURATION (exit 2)` |
| Fix: `excluded-libraries` entry | `lake lint` | 0 | PASS |
| Clean | `lake lint -- --fresh --json-out` | 0 | `PASS — fresh whole-project acceptance of the claimed Lake surfaces`; JSON `status: completed`, `acceptance.account.coverage: freshWholeProject` (9 s) |
| — | `lake lint -- --explain-config` | 2 | Read-only configuration, stages and modules; "no audit was run" |
| Module docstring removed | `lake lint` | 1 | `PL5001 [violation; …; module Tally.Count]` and its URL |
| `set_option linter.plumb false` + `axiom hidden` | `lake lint` | 1 | PL1001 for `Tally.hidden` |
| Unused `let` and parameter | `lake lint` | 3 | PL2003 with Lean's two unused-variable warnings |
| Mathlib library `TallyMath` (`import Mathlib.Algebra.Group.Basic`, Standard-Logical) | `lake lint`; `lake lint -- --fresh` | 0; 0 | PASS (2 claimed libraries, 3 owned modules, 6 declarations); fresh PASS in 10 s |

Mathlib's dependency build artifacts were provisioned by APFS clone of this checkout's build of
the identical pinned revisions (setup, equivalent to `lake exe cache get`).

## Editor journey (VS Code)

VS Code 1.139.0 (`2242ebbb54efeeb0129e08e919e7e8d43033cd83`, arm64), `leanprover.lean4`
0.0.240, isolated user-data directory, workspace trust off, driven over the workbench's DevTools
protocol with trusted input events.

1. Typed `theorem count_nil (p : α → Bool) : count p [] = 0 := by sorry` into `Tally/Count.lean`.
2. The infoview at `Count.lean:27:9` listed `declaration uses 'sorry'` and
   `PL1002 [violation; editorSnapshot; claim=classification-only; …/Tally/Count.lean]:
   Tally.count_nil: hole`, the URL `https://rbeauchamp.github.io/lean-plumb/dev/rules/PL1002/`,
   `Error code: Plumb.PL1002` and **View explanation**. The infoview had exactly one anchor with an
   `href`: that URL, `target=_blank`, `rel="noreferrer noopener"`; no Lean-manual link.
3. A VS Code onboarding overlay first intercepted the synthetic click (no event reached the
   anchor); after closing it, a trusted click reached the anchor (`isTrusted: true`, recorded by a
   capture listener). With `workbench.externalBrowser` set to Safari in the isolated profile,
   Safari (not running before) started immediately after the click: VS Code handed the link to
   the external browser. macOS privacy controls in this environment blocked reading the
   browser's window title or history, so the page shown was not observed there; the same URL
   served the PL1002 page generated from `a52bf1f0e2c7` (HTTP 200, below). An AppleScript query to
   Safari timed out, possibly leaving an automation-permission prompt on the host.
4. Fix on disk (`:= rfl`): the status bar went from 0 errors / 2 warnings to 0 / 0 and the
   infoview's message list emptied. `lake lint` then exited 0 (incremental and `--fresh`).

## Live website (https://rbeauchamp.github.io/lean-plumb/, deployed `a52bf1f`)

- `build.json` names Verso `cad4b633…`, toolchain 4.34.0 and 21 rules, each `violationStatus:
  rejected`/`fixedStatus: completed` or its demonstration kind, with `helpUrl` equal to the dev route.
- All 21 `dev/rules/<ID>/` and `rev/a52bf1f0e2c7854c45ab6694b35b697b5e900fc8/rules/<ID>/` routes
  returned 200 with the rule's title; `dev/`, `dev/rules/`, `dev/versions/`, `dev/credits/` 200;
  `dev/rules/PL9999/`, `v/0.1.0/rules/PL1001/`, `rev/0000000/rules/PL1001/` 404 (not-available
  page, no redirect).
- Headless Chrome (chrome-devtools-axi): search for `PL1006` listed the PL1006 page first;
  keyboard Tab order reached the search box, table of contents and rule links with visible
  focus; the rule index table has 21 rows.
- At 390 × 844 (mobile emulation) every rule page's document was 410 px wide: an inline `code`
  element holding the con-leche commit hash in the attribution did not wrap (PL3001 and PL5003
  also a long path or name). Injecting the #10 rule `main :not(pre) > code { overflow-wrap:
  anywhere; }` into the live PL5003 page reduced the width to 390 px. The index and home pages
  did not overflow.

## Commands and results for the #10 change

Recorded after the runs on the committed change; see below.
