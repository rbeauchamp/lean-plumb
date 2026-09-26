import RegulaCore.Site
import RegulaCore.Guide

/-! # Rule-reference page sources

Pure construction of the Verso source of every generated page of the rule reference. The
operational builder (`Regula.Site.Build`) supplies the checked example evidence and resolved
clause links; it writes exactly the strings returned here.

## Main declarations

- `Identity`: the exact build identity every page states (commit, toolchain, linter version).
- `Example`, `FindingView`, `ChangedFile`, `ShownFile`: the display form of one rule's
  admitted rule-example records.
- `ruleSections`, `ruleSections_headings`: every rule page has exactly the required sections,
  in order, by construction.
- `rulePage`: the Verso module of one rule page. Data enters raw HTML only through `escape`
  (`escape_safe`) and raw HTML enters Verso only through `htmlBlock` (`htmlBlock_ok`).
- `indexHtml`: the no-JavaScript rule catalogue with CSS-only filters whose no-match notice is
  emitted for exactly `emptySelections` (`mem_emptySelections`).

## Boundaries

These functions define page text. That Verso renders it, that browsers apply the CSS filters
as specified and that the output is served are observations recorded by the builder and in
`docs/guides/website.md`, not consequences of these definitions.
-/

namespace Regula.Site

open Regula.Checker.Account (Residual Trusted)

/-- Exact identity of one site build. -/
structure Identity where
  revision : Commit
  /-- The build used uncommitted changes on top of `revision` (local previews only). -/
  dirty : Bool
  toolchain : String
  producerVersion : String
  versoRevision : String

/-- A displayed input file: its workspace-relative path, the repository fixture with
byte-identical content if there is one, and its exact text. -/
structure ShownFile where
  path : String
  fixture : Option String
  text : String

/-- An input whose content differs between the violating and corrected runs. `none` means
the file is absent in that run. -/
structure ChangedFile where
  path : String
  violation : Option ShownFile
  fixed : Option ShownFile

/-- Display form of one checked finding of the violating run. -/
structure FindingView where
  rule : RuleId
  severity : String
  impact : String
  mode : String
  claim : Option String
  /-- What the finding is about (`Declaration`, `Execution root`, `Subject`) and its name. -/
  subjectKind : String
  subject : String
  detail : String
  location : String

/-- Display form of one rule's two admitted rule-example records. -/
structure Example where
  kind : String
  request : String
  violationStatus : String
  fixedStatus : String
  changed : List ChangedFile
  context : List ShownFile
  findings : List FindingView

/-- Resolved normative clause: its registry text and its URL at the build revision. -/
structure Clause where
  label : String
  url : String

/-! ## Links -/

def shortRevision (c : Commit) : String := String.ofList (c.val.toList.take 12)

def blobUrl (ident : Identity) (path : String) : String :=
  repository ++ "/blob/" ++ ident.revision.val ++ "/" ++ path

def treeUrl (ident : Identity) : String := repository ++ "/tree/" ++ ident.revision.val

/-- Resolve the `@repo/` link token of guide prose to the build revision. -/
def resolveProse (ident : Identity) (text : String) : String :=
  text.replace "(@repo/" ("(" ++ repository ++ "/blob/" ++ ident.revision.val ++ "/")

/-- Repository paths linked by `@repo/` tokens in a prose string. -/
def proseLinks (text : String) : List String :=
  ((text.splitOn "(@repo/").drop 1).map fun rest => ((rest.splitOn ")").headD "").splitOn "#" |>.headD ""

/-- Every repository path a guide links or cites. -/
def Guide.repositoryPaths (g : Guide) : List String :=
  g.sources ++ ([g.problem, g.action, g.correction] ++ g.trigger ++ g.rationale ++ g.fixes ++
    g.proofShape ++ g.established ++ g.notEstablished ++ g.configuration ++ g.limitations).flatMap proseLinks

/-! ## HTML fragments (all data escaped) -/

private def code (s : String) : String := "<code>" ++ escape s ++ "</code>"

private def link (url text : String) : String :=
  "<a href=\"" ++ escape url ++ "\">" ++ text ++ "</a>"

/-- Target of the page-level links Verso emits (`route/#tag`); Verso gives the page heading no `id`. -/
def pageAnchor (tag : String) : String := "<span id=\"" ++ escape tag ++ "\"></span>"

/-- The version notice every generated page carries. Absolute links remain valid in both
byte-identical copies (`dev/` and `rev/<commit>/`). -/
def editionHtml (ident : Identity) (route : String) : String :=
  let rev := ident.revision.val
  "<aside class=\"regula-edition\" aria-label=\"Documentation version\"><p><strong>Development documentation</strong> generated from " ++
  (if ident.dirty then "uncommitted local changes on top of commit " else "commit ") ++
  link (treeUrl ident) (code (shortRevision ident.revision)) ++ " with Lean " ++ escape ident.toolchain ++
  "; linter version " ++ code ident.producerVersion ++ " (no released package). Moving route: " ++
  link (basePath ++ "dev/" ++ route) (code (basePath ++ "dev/" ++ route)) ++
  (if ident.dirty then ". This local preview has no snapshot route. See " else
  ". Snapshot route for this commit: " ++ link (basePath ++ "rev/" ++ rev ++ "/" ++ route) (code (basePath ++ "rev/" ++ shortRevision ident.revision ++ "…/" ++ route)) ++
  ". Once this commit is published, its snapshot is kept by every later deployment. See ") ++ link (basePath ++ "dev/versions/") "versions and evidence" ++ ".</p></aside>"

private def row (header value : String) : String :=
  "<tr><th scope=\"row\">" ++ header ++ "</th><td>" ++ value ++ "</td></tr>"

private def joinComma (xs : List String) : String := String.intercalate ", " xs

def lifecycleText {id : RuleId} : Lifecycle id → String
  | .active introduced => "Active since " ++ introduced
  | .retired introduced version replacement =>
      "Retired in " ++ version ++ " (introduced " ++ introduced ++ ")" ++
      (match replacement with | some r => "; replaced by " ++ r.val.spelling | none => "")

/-- The rule's facts: identity and metadata projected from `descriptor id`, the resolved clause
links, the checklist rows of its explanation, and the strict-impact statement shared by every rule. -/
def factsHtml (id : RuleId) (clauses : List Clause) (checklist : List String) : String :=
  let d := descriptor id
  "<table class=\"regula-facts\"><caption>Rule facts from the registry</caption><tbody>" ++
  row "Rule" (code id.spelling) ++
  row "Category" (escape d.category.label) ++
  row "Scope" (escape d.scope.label) ++
  row "Subreason" (code d.applicability) ++
  row "Strict impact" ("Error in every project and documentation audit where the rule applies. An established violation makes the result FAIL; missing or unsupported evidence makes it INCOMPLETE. Neither is accepted." ++
    (if .documentationExample ∈ d.evidenceModes && d.evidenceModes.length == 1 then "" else
      " Under " ++ code "lake lint" ++ " a FAIL exits 1 and an INCOMPLETE exits 3" ++
      (if id == .configuration then "; a FAIL whose findings are all this rule exits 2 (INVALID CONFIGURATION)" else "") ++ ".") ++
    (if .editorSnapshot ∈ d.evidenceModes then " The editor shows its local findings as warnings (errors under " ++ code "warningAsError" ++ "); they are not project results." else " The editor does not report this rule.")) ++
  row "Evidence modes" (escape (joinComma (d.evidenceModes.map modeLabel))) ++
  row "Availability" (escape d.availability.label) ++
  row "Lifecycle" (escape (lifecycleText d.lifecycle)) ++
  row "Message form" (code d.messageTemplate) ++
  row "Normative clauses" (joinComma (clauses.map fun c => link c.url (escape c.label))) ++
  row "Checklist rows" (escape (joinComma checklist)) ++
  row "Help URL" (code (devUrl id)) ++
  "</tbody></table>"

private def lines (text : String) : List String :=
  let ls := text.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

private def preHtml (text : String) : String :=
  "<pre class=\"regula-code\"><code>" ++ escape text ++ "</code></pre>"

private def fileCaption (ident : Identity) (f : ShownFile) : String :=
  code f.path ++ (match f.fixture with
    | some p => " — source " ++ link (blobUrl ident p) (code p)
    | none => " — written by the qualification runner")

def shownHtml (ident : Identity) (f : ShownFile) : String :=
  "<figure class=\"regula-file\"><figcaption>" ++ fileCaption ident f ++ "</figcaption>" ++ preHtml f.text ++ "</figure>"

/-- Split a diff into maximal runs of unchanged lines and single changed lines. -/
def diffRuns : List DiffLine → List (List String ⊕ DiffLine)
  | [] => []
  | .keep l :: rest => match diffRuns rest with
    | .inl ls :: runs => .inl (l :: ls) :: runs
    | runs => .inl [l] :: runs
  | line :: rest => .inr line :: diffRuns rest

private def keepHtml (l : String) : String := "<span class=\"regula-keep\">  " ++ escape l ++ "</span>\n"

private def foldHtml (n : Nat) : String := "<span class=\"regula-keep\">  ⋯ " ++ toString n ++ " unchanged lines</span>\n"

/-- Show at most `context` unchanged lines around each change; longer runs are summarized. -/
def keepRunHtml (context : Nat) (first last : Bool) (ls : List String) : String :=
  let n := ls.length
  let head := if first then 0 else context
  let tail := if last then 0 else context
  if n ≤ head + tail + 1 then String.join (ls.map keepHtml)
  else String.join ((ls.take head).map keepHtml) ++ foldHtml (n - head - tail) ++ String.join ((ls.drop (n - tail)).map keepHtml)

/-- An admitted diff with `+`/`-` markers, so status never depends on colour. Unchanged runs
far from a change are summarized; the full texts are shown separately or recorded in the
evidence. -/
def diffHtml (d : List DiffLine) : String :=
  let runs := diffRuns d
  "<pre class=\"regula-diff\"><code>" ++ String.join ((List.range runs.length).zip runs |>.map fun (i, run) =>
    match run with
    | .inl ls => keepRunHtml 3 (i == 0) (i + 1 == runs.length) ls
    | .inr (.remove l) => "<del class=\"regula-remove\">- " ++ escape l ++ "</del>\n"
    | .inr (.add l) => "<ins class=\"regula-add\">+ " ++ escape l ++ "</ins>\n"
    | .inr (.keep l) => keepHtml l) ++ "</code></pre>"

def findingHtml (f : FindingView) : String :=
  "<div class=\"regula-finding\"><p>" ++ code f.rule.spelling ++ " <span class=\"regula-badge\">" ++ escape f.severity ++
  "</span> <span class=\"regula-badge regula-impact-" ++ escape f.impact ++ "\">" ++ escape f.impact ++ "</span> " ++
  escape (modeLabelOf f.mode) ++ (match f.claim with | some c => ", claim " ++ code c | none => "") ++ "</p>" ++
  "<p>" ++ escape f.subjectKind ++ " " ++ code f.subject ++ " at " ++ escape f.location ++ "</p>" ++ preHtml f.detail ++ "</div>"
where
  modeLabelOf (m : String) : String :=
    match modes.find? (fun mode => mode.spelling == m) with
    | some mode => modeLabel mode
    | none => m

private def changedViolation (ident : Identity) (c : ChangedFile) : String :=
  match c.violation with
  | some f => if f.fixture.isSome then shownHtml ident f else
      "<p>" ++ code c.path ++ " (written by the qualification runner) differs; its change is shown under Correction.</p>"
  | none => "<p>" ++ code c.path ++ " is absent in the violating run.</p>"

private def changedFix (ident : Identity) (c : ChangedFile) : Except String String := do
  let before := (c.violation.map (lines ·.text)).getD []
  let after := (c.fixed.map (lines ·.text)).getD []
  let d ← admitDiff before after
  let full := match c.fixed with
    | some f => if f.fixture.isSome then shownHtml ident f else ""
    | none => "<p>" ++ code c.path ++ " is removed by the correction.</p>"
  let terminator := if c.violation.isSome && c.fixed.isSome && before == after &&
      c.violation.map (·.text) != c.fixed.map (·.text) then
      "<p>Only the final line terminator differs.</p>" else ""
  return "<p>Change to " ++ code c.path ++ ":</p>" ++ diffHtml d.val ++ terminator ++ full

def exampleKindText : String → String
  | "policyRejection" => "Checked policy rejection: the violating input was completed by the checker and rejected with the findings below; the corrected input passed a completed positive check."
  | "diagnosticDemonstration" => "Diagnostic demonstration: the violating run is INCOMPLETE by design. It shows the exact diagnostic and is not accepted negative evidence. The corrected input passed a completed positive check."
  | other => other

/-- The checked example: violation inputs, exact findings, correction diff and corrected inputs. -/
def exampleHtml (ident : Identity) (ex : Example) : Except String String := do
  let fixes ← ex.changed.mapM (changedFix ident)
  return "<div class=\"regula-example\">" ++
    "<p class=\"regula-status\">" ++ escape (exampleKindText ex.kind) ++ "</p>" ++
    "<p>Invocation: " ++ escape ex.request ++ ". Violating run status: " ++ code ex.violationStatus ++
    "; corrected run status: " ++ code ex.fixedStatus ++ ".</p>" ++
    "<h3>Violating input</h3>" ++ String.join (ex.changed.map (changedViolation ident)) ++
    (if ex.context.isEmpty then "" else
      "<h3>Unchanged input</h3>" ++ String.join (ex.context.map (shownHtml ident))) ++
    "<h3>Findings of the violating run</h3>" ++ String.join (ex.findings.map findingHtml) ++
    "<h3>Correction</h3>" ++ String.join fixes ++ "</div>"

/-! ## Verso text -/

private def paragraphs (ident : Identity) (xs : List String) : String :=
  String.join (xs.map fun p => resolveProse ident p ++ "\n\n")

private def numbered (ident : Identity) (xs : List String) : String :=
  String.join ((List.range xs.length).zip xs |>.map fun (i, p) => s!"{i + 1}. " ++ resolveProse ident p ++ "\n") ++ "\n"

private def bullets (ident : Identity) (xs : List String) : String :=
  String.join (xs.map fun p => "* " ++ resolveProse ident p ++ "\n") ++ "\n"

/-- A generated section heading with a stable tag for deep links. -/
def sectionHead (id : RuleId) (suffix heading : String) : String :=
  "# " ++ heading ++ "\n%%%\ntag := \"" ++ id.spelling ++ "-" ++ suffix ++ "\"\nnumber := false\n%%%\n\n"

def residualText : Residual → String
  | .intent => "the proposition expresses the intended requirement, with its quantifiers, hypotheses and limits"
  | .invariant => "the intended invariants, write paths and callers are all covered by proof-bearing interfaces"
  | .laws => "the chosen structures and instances carry the intended laws"
  | .boundary => "the enforced abstraction boundary is the intended one"
  | .nonvacuity => "the claim is non-vacuous at the strength claimed"
  | .doc => "documentation is complete and faithful to the declarations and requirements"
  | .cost => "cost claims name their domain and rest on an argument or bounded observation"
  | .qualify => "the checker's detection is qualified for this invocation, toolchain and capability"
  | .graph => "a claimed serialized graph covers every selected root"

/-- The sections of a rule page, in order: heading, stable tag suffix and Verso body. -/
def ruleSections (ident : Identity) (id : RuleId) (g : Guide) (ex : String)
    (clauses : List Clause) : List (String × String × String) := [
  ("What triggers it", "trigger", paragraphs ident g.trigger),
  ("Why it matters", "rationale", paragraphs ident g.rationale),
  ("How to fix it", "fix", numbered ident g.fixes),
  ("Checked example", "example", ex ++ "\n" ++ resolveProse ident g.correction ++ "\n\n"),
  ("Required proof shape", "proof-shape", paragraphs ident g.proofShape),
  ("What a passing result establishes", "established",
    paragraphs ident g.established ++ "It does not establish:\n\n" ++ bullets ident g.notEstablished ++
    "Review obligations the rule-coverage map associates with this rule (identifiers of the checker's `Residual` account):\n\n" ++
    String.join (g.residuals.map fun r => "* `" ++ r.spelling ++ "`: " ++ residualText r ++ "\n") ++ "\n" ++
    "Every accepted result lists all residual obligations as open, whatever rules it checked: " ++
      String.intercalate ", " ((Residual.all.filter (· != .graph)).map fun r => "`" ++ r.spelling ++ "`") ++
      " (and `R-GRAPH` for a serialized-graph claim). A listed identifier is an open obligation, never a completed review.\n\n" ++
    "Every accepted result also relies on these trusted mechanisms (the checker's `Trusted` account), which no rule verifies:\n\n" ++
    String.join (Trusted.all.map fun t => "* `" ++ t.spelling ++ "`: " ++ t.detail ++ "\n") ++ "\n"),
  ("Configuration and exceptions", "configuration", paragraphs ident g.configuration),
  ("Limitations and unsupported cases", "limitations", paragraphs ident g.limitations),
  ("Sources and credit", "sources",
    "Normative text: " ++ String.intercalate ", " (clauses.map fun c => "[" ++ c.label ++ "](" ++ c.url ++ ")") ++ ".\n\n" ++
    "Detector, policy and proof sources at this revision: " ++
      String.intercalate ", " (g.sources.map fun p => "[`" ++ p ++ "`](" ++ blobUrl ident p ++ ")") ++ ".\n\n" ++
    "The rule's typed identity and canonical metadata follow the canonical-representation design of [con-leche](" ++
      (descriptor id).attribution.url ++ ") (" ++ (descriptor id).attribution.authors ++ ", revision `" ++
      (descriptor id).attribution.revision ++ "`); no con-leche code or proof is used. The explanation is original; its structure follows [Microsoft's CA1416 rule page](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/ca1416) as one illustrative reference. See [credits](credits/).\n\n")]

/-- The required headings of every rule page, in order. -/
def requiredHeadings : List String :=
  ["What triggers it", "Why it matters", "How to fix it", "Checked example", "Required proof shape",
    "What a passing result establishes", "Configuration and exceptions",
    "Limitations and unsupported cases", "Sources and credit"]

/-- Every rule page has exactly the required sections in order, for every input. -/
theorem ruleSections_headings (ident : Identity) (id : RuleId) (g : Guide) (ex : String)
    (clauses : List Clause) : (ruleSections ident id g ex clauses).map (·.1) = requiredHeadings := rfl

/-- A title usable in a Lean string literal and a Verso heading without escaping. -/
def plainTitle (s : String) : Bool :=
  s.toList.all fun c => c.isAlphanum || c == ' ' || c == ':' || c == '-' || c == ',' || c == '.'

/-- Complete Verso module of one rule page. -/
def rulePage (ident : Identity) (id : RuleId) (clauses : List Clause) (ex : Example) :
    Except String String := do
  let d := descriptor id
  let g := guide id
  let title := id.spelling ++ ": " ++ d.title
  unless plainTitle title do throw s!"{id.spelling}: title needs escaping"
  let notice ← htmlBlock (pageAnchor id.spelling ++ editionHtml ident id.route)
  let facts ← htmlBlock (factsHtml id clauses g.checklist)
  let exampleBlock ← htmlBlock (← exampleHtml ident ex)
  let sections := ruleSections ident id g exampleBlock clauses
  return "import VersoManual\nimport RegulaSite\nopen Verso.Genre Manual RegulaSite\n\n#doc (Manual) \"" ++ title ++
    "\" =>\n%%%\ntag := \"" ++ id.spelling ++ "\"\nfile := \"" ++ id.spelling ++ "\"\nshortTitle := \"" ++ id.spelling ++
    "\"\nnumber := false\n%%%\n\n" ++ notice ++ "\n" ++
    "**Problem.** " ++ resolveProse ident g.problem ++ "\n\n**Action.** " ++ resolveProse ident g.action ++ "\n\n" ++
    facts ++ "\n" ++
    String.join (sections.map fun (heading, suffix, body) => sectionHead id suffix heading ++ body)

/-! ## Rule index -/

private def radioId (dimension value : String) : String := "f-" ++ dimension ++ "-" ++ value

private def radios (dimension legend : String) (values : List (String × String)) : String :=
  "<fieldset><legend>" ++ legend ++ "</legend>" ++
  String.join ((("all", "All") :: values).map fun (value, label) =>
    "<span class=\"regula-choice\"><input type=\"radio\" name=\"" ++ dimension ++ "\" id=\"" ++ radioId dimension value ++
    "\" value=\"" ++ value ++ "\"" ++ (if value == "all" then " checked" else "") ++ "><label for=\"" ++
    radioId dimension value ++ "\">" ++ escape label ++ "</label></span>") ++ "</fieldset>"

private def optionSlug {α : Type} (slug : α → String) : Option α → String
  | none => "all"
  | some v => slug v

private def selectionSelector (s : Selection) : String :=
  ".regula-index:has(#" ++ radioId "category" (optionSlug RuleCategory.slug s.category) ++ ":checked):has(#" ++
  radioId "mode" (optionSlug EvidenceMode.spelling s.mode) ++ ":checked):has(#" ++
  radioId "availability" (optionSlug Availability.slug s.availability) ++ ":checked)"

/-- Filter CSS: one hiding rule per restricted value, and the no-match notice for exactly the
selections in `emptySelections`. -/
def filterCss : String :=
  String.join (categories.map fun c => ".regula-index:has(#" ++ radioId "category" c.slug ++
    ":checked) tr.regula-rule:not(.category-" ++ c.slug ++ "){display:none}\n") ++
  String.join (modes.map fun m => ".regula-index:has(#" ++ radioId "mode" m.spelling ++
    ":checked) tr.regula-rule:not(.mode-" ++ m.spelling ++ "){display:none}\n") ++
  String.join (availabilities.map fun a => ".regula-index:has(#" ++ radioId "availability" a.slug ++
    ":checked) tr.regula-rule:not(.availability-" ++ a.slug ++ "){display:none}\n") ++
  String.join (emptySelections.map fun s => selectionSelector s ++ " tr.regula-no-match{display:table-row}\n")

private def ruleRow (id : RuleId) (exampleKind : String) : String :=
  let d := descriptor id
  "<tr class=\"regula-rule category-" ++ d.category.slug ++ " availability-" ++ d.availability.slug ++
  String.join (d.evidenceModes.map fun m => " mode-" ++ m.spelling) ++ "\">" ++
  "<th scope=\"row\"><a href=\"" ++ id.route ++ "\">" ++ code id.spelling ++ "</a></th>" ++
  "<td><a href=\"" ++ id.route ++ "\">" ++ escape d.title ++ "</a><br><span class=\"regula-muted\">subreason " ++
  code d.applicability ++ "</span></td>" ++
  "<td>" ++ escape d.category.label ++ "<br><span class=\"regula-muted\">" ++ escape d.scope.label ++ "</span></td>" ++
  "<td>" ++ escape (joinComma (d.evidenceModes.map modeLabel)) ++ "</td>" ++
  "<td>" ++ escape d.availability.label ++ "<br><span class=\"regula-muted\">" ++ escape (lifecycleText d.lifecycle) ++
  "; " ++ escape exampleKind ++ "</span></td></tr>"

/-- The complete catalogue, derived from the registry, with CSS-only filters. `exampleKind`
labels each rule's checked example. -/
def indexHtml (exampleKind : RuleId → String) : String :=
  "<div class=\"regula-index\"><form class=\"regula-filters\" aria-label=\"Filter rules\" action=\"#\">" ++
  radios "category" "Category" (categories.map fun c => (c.slug, c.label)) ++
  radios "mode" "Evidence mode" (modes.map fun m => (m.spelling, modeLabel m)) ++
  radios "availability" "Availability" (availabilities.map fun a => (a.slug, a.label)) ++
  "<p><input type=\"reset\" value=\"Reset filters\"></p></form>" ++
  "<div class=\"regula-scroll\" role=\"region\" aria-label=\"Rule catalogue\" tabindex=\"0\"><table class=\"regula-rules\"><caption>All " ++ toString RuleId.all.length ++ " registered rules</caption><thead><tr>" ++
  "<th scope=\"col\">ID</th><th scope=\"col\">Rule and subreason</th><th scope=\"col\">Category and scope</th>" ++
  "<th scope=\"col\">Evidence modes</th><th scope=\"col\">Status and checked example</th></tr></thead><tbody>" ++
  String.join (RuleId.all.map fun id => ruleRow id (exampleKind id)) ++
  "<tr class=\"regula-no-match\"><td colspan=\"5\">No registered rule matches the selected filters. Use <strong>Reset filters</strong> to show every rule.</td></tr>" ++
  "</tbody></table></div><style>" ++ filterCss ++ "</style></div>"


end Regula.Site
