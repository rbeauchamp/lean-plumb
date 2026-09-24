# Issue 14 editor journeys (observed, 2026-09-24)

These are observations of the actual supported client, not proofs. They qualify the
native linter's link, range, code and lifecycle behavior through VS Code and the Lean
infoview on this machine. They do not establish latency, other clients or the published site.

## Setup

- Base `origin/main` `39fc631` (the Plumb rename, after #43) plus the issue 14 branch changes
  (`Plumb.Linter` help widget, editor decisions through `PlumbCore.EditorPolicy`, `lint`),
  Lean `v4.34.0`, macOS arm64.
- VS Code 1.139.0 (`2242ebbb54efeeb0129e08e919e7e8d43033cd83`, arm64), extension
  `leanprover.lean4` 0.0.240, fresh isolated user-data directory, workspace trust disabled.
- Adopter: a disposable copy of `examples/lake-lint-toml` (absolute path dependency on this
  checkout, shared pinned `.lake/packages`), opened at `Gadget/Double.lean`, which imports
  `Plumb.Linter`. `lake build` and `lake lint` of the copy passed first (`plumb lint: PASS —
  incremental project acceptance over existing build state, not a fresh-source audit`).
- Driving: keyboard input and accessibility snapshots over the workbench's DevTools
  protocol. The infoview webview's DOM was read over the same protocol, and the link was
  clicked with trusted `Input.dispatchMouseEvent` events at its rendered position.

## Journey A: unfinished proof (PL1002) to explanation to fix

1. Added `theorem double_add (a b : Nat) : double (a + b) = double a + double b := by sorry`
   at line 13.
2. The infoview listed two messages at `Double.lean:13:8`: Lean's `declaration uses 'sorry'`
   and `PL1002 [violation; editorSnapshot; …]: Gadget.double_add: hole` with the text URL
   `https://rbeauchamp.github.io/lean-plumb/dev/rules/PL1002/`, followed by Lean's
   error-code widget: `Error code: Plumb.PL1002` and a **View explanation** link.
3. The infoview DOM contained exactly one anchor with an `href`:
   `https://rbeauchamp.github.io/lean-plumb/dev/rules/PL1002/`, `target=_blank`,
   `rel="noreferrer noopener"`. No Lean-manual link was present for either message.
4. A trusted click on **View explanation** opened the default system browser (Firefox),
   which became frontmost with the window title `Site not found · GitHub Pages`: the
   development route is correct but not yet deployed (`curl`: 404). #15 publishes the site;
   #10 verifies the live route.
5. Problems panel: `PL1002 … | Lean 4 | Plumb.PL1002 | [Ln 13, Col 9] | <URL>`. This is the
   no-widget fallback, and it shows that `code` is serialized.
6. Replaced the proof with `by unfold double; omega`. The infoview then showed only `Goals
   accomplished!` and the Problems panel was empty. No stale PL1002 remained.

## Journey B: Unicode, CRLF, recovery and CLI parity (PL1001)

1. Typed `/- 𝔡𝔡 -/ axiom unicodeAssumption : True` at line 14 (two non-BMP characters).
2. One PL1001 appeared: Problems panel `[Ln 14, Col 18]`, infoview `Double.lean:14:17`, both
   UTF-16 positions (the codepoint column is 15). The rendered squiggle spans exactly the
   pixel extent of `unicodeAssumption` (left 106 px, width 123 px; the text range measured
   105.9 px and 122.8 px).
3. Changed the buffer to CRLF (`Change End of Line Sequence`). The marker position and the
   squiggle were unchanged.
4. Saved (`file`: CRLF line terminators) and ran `lake lint -- --json-out tmp/r.json`:
   exit 3, `plumb lint: INCOMPLETE (exit 3)`. The build log preserved
   `warning: Gadget/Double.lean:14:15: PL1001 [violation; editorSnapshot; …]` (Lean's
   codepoint column) with the same URL. The 14 KB result has status `incomplete` with
   PL2003 build-failed: a live finding is a warning, so the warning-free build check stops
   the audit first. Observed at `1153e48`, where this matched the documented exit class.
   **Superseded:**
   `lake lint` now builds with `linter.plumb` off (`Lake.auditLeanOptions`), so the same
   declaration is the audit's PL1001 `VIOLATION` (exit 1); see the `toml/live-finding`
   control in [issue-14-verification.md](issue-14-verification.md). The editor observations
   in this journey are unchanged.
5. Deleted the line: the status bar read `No Problems`.

## Stale and cancelled snapshots

Without waiting between keystrokes, three `axiom rapidN : True` lines were typed and deleted,
then `theorem rapidHole : True := by sorry` was added. After elaboration, only the sorry
warning and one PL1002 for `rapidHole` were present, with no PL1001 for any `rapidN`.
Deleting that line left no problems.

## Journey C: configuration, module-level and pending evidence (PL2002, PL1005, PL5001, PL2005)

1. With the module doc removed, `set_option plumb.localFoundation "bogus"` produced PL2002
   `unsupported local foundation request: bogus` on each following nonterminal command
   snapshot (lines 3, 4, 6, 9, 11, 12), the documented per-snapshot refusal.
   `"compiler-trusting"` was refused the same way: the editor request domain excludes
   teaching (`editor_request_sound`).
2. `"kernel-only"` was accepted and produced PL1005 `label-exceeds-claim` for `double_add`
   (its `omega` proof uses `propext`), plus PL5001 for the missing module doc.
3. After removing the option, only PL5001 `module-documentation` remained, at the end of the
   file (`[Ln 12, Col 1]`), with module scope and no invented declaration. Restoring a module
   doc cleared it.
4. `axiom pendingRole._native.native_decide.ax_1 : True` produced one PL2005 `[incomplete;
   editorSnapshot]` finding: `fresh generated-role evidence remains required for
   #[pendingRole._native.native_decide.ax_1]; run \`lake lint\` for the project check`, at the
   end of the file. Deleting the line cleared it.

## Not observed here

- A deployed rule page. The link target is the development route and currently returns
  GitHub Pages' 404.
- An infoview with widgets disabled. The fallback was observed through the Problems panel
  and the `lake lint` transcript, which carry the same text URL.
- Other clients, Mathlib adopters and latency distributions.
