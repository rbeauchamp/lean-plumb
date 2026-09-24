import PlumbCore.SitePage

/-! # Rule-reference manual structure

Pure construction of the generated Verso manual around the rule pages: the home page, the
rule index part that includes every rule page, the versions-and-evidence page and the
credits page.

## Main declarations

- `ruleModule`, `ruleModules`, `ruleModules_nodup`: the generated Verso module of each rule,
  one per registry entry.
- `homePage`, `indexPage`, `versionsPage`, `creditsPage`: the remaining generated modules.
- `EvidenceSummary`: the per-rule evidence line shown on the versions page.

## Boundaries

Links to repository documents point at the build revision on GitHub; whether GitHub serves
them is outside this module. The version policy text describes the publishing workflow in
`.github/workflows/ci.yml`; that the workflow behaves so is an operational observation.
-/

namespace Plumb.Site

/-- Generated Verso module name of a rule page. -/
def ruleModule (id : RuleId) : String := "Generated.Rules." ++ id.spelling

theorem ruleModule_injective {a b : RuleId} (h : ruleModule a = ruleModule b) : a = b :=
  RuleId.spelling_injective ((String.append_right_inj _).mp h)

def ruleModules : List String := RuleId.all.map ruleModule

/-- One generated module per rule and no duplicate module. -/
theorem ruleModules_nodup : ruleModules.Nodup :=
  List.Pairwise.map ruleModule (fun _ _ h eq => h (ruleModule_injective eq)) RuleId.all_nodup

private def header (imports : List String) (title tag : String) (file : Option String) (split : Bool := true) : String :=
  "import VersoManual\nimport PlumbSite\n" ++ String.join (imports.map fun m => "import " ++ m ++ "\n") ++
  "open Verso.Genre Manual PlumbSite\n\n#doc (Manual) \"" ++ title ++ "\" =>\n%%%\ntag := \"" ++ tag ++ "\"\n" ++
  (match file with | some f => "file := \"" ++ f ++ "\"\n" | none => "") ++ "number := false\n" ++ (if split then "" else "htmlSplit := .never\n") ++ "%%%\n\n"

/-- The site's home page (the edition root). -/
def homePage (ident : Identity) : Except String String := do
  let notice ← htmlBlock (pageAnchor "plumb" ++ editionHtml ident "")
  let doc (path text : String) := "[" ++ text ++ "](" ++ blobUrl ident path ++ ")"
  return header ["Generated.Rules", "Generated.Versions", "Generated.Credits"] "Plumb for Lean rule reference" "plumb" none ++
    notice ++ "\n" ++
    "Plumb for Lean is a strict linter for Lean 4 projects. This reference explains every diagnostic it reports: what triggers it, why it matters, how to fix it, a checked example produced by the real checker, and exactly what a passing result does and does not establish.\n\n" ++
    "**If you followed a diagnostic link.** Every Plumb diagnostic carries a stable rule ID such as `PL1001` (editor code `Plumb.PL1001`) and ends with its explanation URL, for example `" ++ devUrl .projectAxiom ++ "`. In VS Code the infoview's *View explanation* link opens the same page. The page's ID is the diagnostic's ID.\n\n" ++
    "**Reading a result.** A finding's impact is either a violation, which makes the result FAIL, or incomplete, which means required evidence is missing and the result is INCOMPLETE. Neither is accepted. A passing result is mechanical: every rule page lists the review obligations it leaves open.\n\n" ++
    "**Find a rule.** The [rule index](rules/) lists all " ++ toString RuleId.all.length ++ " rules with filters by category, evidence mode and availability; it needs no JavaScript. The search box searches rule IDs, titles and page text.\n\n" ++
    "**Adopt and learn.** " ++ doc "docs/guides/adoption.md" "Adoption guide" ++ " (installation, `lake lint`, editor feedback and CI); " ++
    doc "docs/standard/README.md" "the standard" ++ "; " ++ doc "docs/standard/9-compliance-audit.md" "compliance checklist" ++ "; " ++
    doc "docs/guides/rule-coverage.md" "rule coverage and residual obligations" ++ "; " ++
    doc "docs/guides/website.md" "how this site is built and published" ++ ".\n\n" ++
    "**Versions.** This is development documentation; no package has been released. See [versions and evidence](versions/) for the exact build identity and the route policy.\n\n" ++
    "{include Generated.Rules}\n\n{include Generated.Versions}\n\n{include Generated.Credits}\n"

/-- The rule index part, which includes every rule page. -/
def indexPage (ident : Identity) (exampleKind : RuleId → String) : Except String String := do
  let notice ← htmlBlock (pageAnchor "rules" ++ editionHtml ident "rules/")
  let table ← htmlBlock (indexHtml exampleKind)
  return header ruleModules "Rule index" "rules" (some "rules") ++ notice ++ "\n" ++
    "Every rule the linter can emit, generated from its typed registry. Filter by category, evidence mode or availability; the filters work without JavaScript, and **Reset filters** restores the full catalogue. Rows link to each rule's explanation. Search rule IDs, titles and messages with the search box above, or with your browser's find-in-page on this table.\n\n" ++
    table ++ "\n" ++ String.join (ruleModules.map fun m => "{include " ++ m ++ "}\n\n")

/-- One rule's evidence line on the versions page. -/
structure EvidenceSummary where
  rule : RuleId
  kind : String
  violationStatus : String
  fixedStatus : String
  emitted : List RuleId
  shard : String

private def evidenceRow (e : EvidenceSummary) : String :=
  "<tr><th scope=\"row\"><a href=\"" ++ e.rule.route ++ "\"><code>" ++ e.rule.spelling ++ "</code></a></th><td>" ++
  escape e.kind ++ "</td><td><code>" ++ escape e.violationStatus ++ "</code></td><td><code>" ++ escape e.fixedStatus ++
  "</code></td><td>" ++ escape (String.intercalate ", " (e.emitted.map RuleId.spelling)) ++ "</td><td>" ++ escape e.shard ++ "</td></tr>"

/-- The versions-and-evidence page. -/
def versionsPage (ident : Identity) (evidence : List EvidenceSummary) : Except String String := do
  let notice ← htmlBlock (pageAnchor "versions" ++ editionHtml ident "versions/")
  let identity ← htmlBlock ("<table class=\"plumb-facts\"><caption>Build identity</caption><tbody>" ++
    "<tr><th scope=\"row\">Commit</th><td><a href=\"" ++ escape (treeUrl ident) ++ "\"><code>" ++ escape ident.revision.val ++ "</code></a></td></tr>" ++
    "<tr><th scope=\"row\">Lean toolchain (linter and examples)</th><td><code>" ++ escape ident.toolchain ++ "</code></td></tr>" ++
    "<tr><th scope=\"row\">Linter version</th><td><code>" ++ escape ident.producerVersion ++ "</code> (no released package)</td></tr>" ++
    "<tr><th scope=\"row\">Verso revision</th><td><code>" ++ escape ident.versoRevision ++ "</code></td></tr>" ++
    "<tr><th scope=\"row\">Rules</th><td>" ++ toString RuleId.all.length ++ " registered, " ++ toString evidence.length ++ " with checked examples</td></tr>" ++
    "</tbody></table>")
  let table ← htmlBlock ("<div class=\"plumb-scroll\" role=\"region\" aria-label=\"Checked rule examples\" tabindex=\"0\"><table class=\"plumb-rules\"><caption>Checked rule examples of this build</caption><thead><tr>" ++
    "<th scope=\"col\">Rule</th><th scope=\"col\">Example kind</th><th scope=\"col\">Violating run</th><th scope=\"col\">Corrected run</th>" ++
    "<th scope=\"col\">Emitted rule IDs</th><th scope=\"col\">Corpus shard</th></tr></thead><tbody>" ++
    String.join (evidence.map evidenceRow) ++ "</tbody></table></div>")
  return header [] "Versions and evidence" "versions" (some "versions") (split := false) ++ notice ++ "\n" ++ identity ++ "\n" ++
    "# Routes\n%%%\ntag := \"versions-routes\"\nnumber := false\n%%%\n\n" ++
    "* `" ++ siteBase ++ "dev/rules/<ID>/` is the development explanation. It always shows the most recent successfully deployed revision of `main`; the linter's diagnostics link here.\n" ++
    "* `" ++ siteBase ++ "rev/<commit>/rules/<ID>/` is the snapshot of one published commit. Each deployment publishes the snapshot of its own commit and every earlier published snapshot, byte for byte: a snapshot is archived before it is deployed, the archive is append-only, and a deployment must contain every archived snapshot.\n" ++
    "* `" ++ siteBase ++ "v/<version>/rules/<ID>/` is reserved for immutable pages of released packages. No package has been released, so no such page exists.\n\n" ++
    "A route that is not published shows the site's not-available page, which names the source of every revision on GitHub. It never redirects to the latest rules: an old link cannot silently acquire changed semantics. Rule IDs are never reused for a changed rule; a retired rule keeps a page that says so.\n\n" ++
    "# Evidence\n%%%\ntag := \"versions-evidence\"\nnumber := false\n%%%\n\n" ++
    "Every example on this site was produced for this exact commit by the rule-example corpus campaign, admitted by the rule-example qualifier (whose admission relations are proved; capture and process authenticity are trusted), and checked against the commit's checker, corpus and configuration sources before the site was generated. The site build refuses stale, incomplete or partial evidence.\n\n" ++
    table ++ "\n" ++
    "A diagnostic demonstration shows an INCOMPLETE result by design; it is not accepted negative evidence. The corpus campaign is scoped qualification of the detectors for these inputs, not a proof that the detectors are correct for every input.\n\n" ++
    "# Hosting limits\n%%%\ntag := \"versions-hosting\"\nnumber := false\n%%%\n\n" ++
    "The site is a static GitHub Pages project site. It uses no cookies, accounts or analytics. Search and the page table of contents use Verso's bundled JavaScript; every explanation, link and the rule catalogue work without it. A deployment can lag `main` while checks run or after they fail; each page states the commit it was built from. Every published snapshot is kept, so the site grows with each deployment; the build refuses an artifact larger than " ++ toString (artifactBudget / 1000000) ++ " MB, below GitHub Pages' 1 GB limit on a published site. Removing snapshots would change what their routes mean and needs a separate decision.\n"

/-- The credits and licenses page. -/
def creditsPage (ident : Identity) : Except String String := do
  let notice ← htmlBlock (pageAnchor "credits" ++ editionHtml ident "credits/")
  return header [] "Credits and licenses" "credits" (some "credits") (split := false) ++ notice ++ "\n" ++
    "Plumb for Lean and this site's generated content are released under the [MIT license](" ++ blobUrl ident "LICENSE" ++ "). The rule explanations are original.\n\n" ++
    "**Lean and Lake.** The linter, its editor messages and its Lake integration are built on Lean 4 and Lake by the Lean FRO and contributors (Apache 2.0), used through the pinned toolchain as dependencies. The editor's *View explanation* link is Lean's own error-description widget.\n\n" ++
    "**Verso.** This site is generated with [Verso](https://github.com/leanprover/verso) by the Lean FRO and contributors (Apache 2.0), pinned at revision `" ++ ident.versoRevision ++ "`. The separation of documentation and example toolchains follows David Thrane Christiansen's [package-docs template](https://github.com/leanprover/verso-templates/tree/76c9edf5a70f14d272af0f0f354ec833ac22c350/package-docs); no template text is copied. Verso bundles the JavaScript components listed below with their licenses.\n\n" ++
    "**con-leche.** The closed typed rule registry, its canonical metadata and the complete, request-indexed acceptance design follow ideas from [con-leche](https://github.com/leanprover/con-leche/tree/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0) by Joachim Breitner and contributors (Lean FRO), in particular `Kernel/PropWhen.lean` and `Cached/Installed.lean`. No con-leche code or proof is copied, and con-leche's theorems are not claimed for Plumb. con-leche did not design this site.\n\n" ++
    "**Rule-page structure.** The page layout of cause, rationale, fix, configuration, examples and limitations follows [Microsoft's CA1416 code-analysis rule page](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/ca1416) as one illustrative reference; no .NET content is used. Other linters' references (Clippy, ESLint, Ruff, HLint) informed the design as documented in the " ++
    "[ecosystem study](" ++ blobUrl ident "docs/guides/ecosystem-design.md" ++ ").\n\n" ++
    "**Mathlib.** The checker repository's audit surface depends on [Mathlib](https://github.com/leanprover-community/mathlib4) (Apache 2.0); the linter itself imports only Lean's core libraries.\n\n" ++
    "The complete attribution account is in the " ++ "[design-influences guide](" ++ blobUrl ident "docs/guides/design-influences.md" ++ ").\n\n" ++
    "{licenseInfo}\n"

end Plumb.Site
