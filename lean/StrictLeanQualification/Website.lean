import StrictLeanQualification.Checks
import Init.Data.List.Sublist

/-! Pure text-block adapter for the one-rule prototype. The list-based fence decision
reuses Core's executable substring test and its proof. Checked source is rendered as
text, never elaborated by the separate Verso compiler. No browser/IO claim is made. -/
namespace StrictLeanQualification.Website

/-- Strip only trailing LF characters, matching the old generator's block convention. -/
def trimLF (source : String) : String :=
  String.ofList (source.toList.reverse.dropWhile (· == '\n')).reverse

/-- Computable contiguous-fence decision with a Core correctness theorem. -/
def hasFence (source : String) : Bool :=
  ['`', '`', '`'].isInfixOf_internal source.toList

/-- A detected fence is exactly three consecutive backticks in the input characters. -/
theorem hasFence_exact (source : String) :
    hasFence source = true ↔ List.IsInfix ['`', '`', '`'] source.toList :=
  List.isInfixOf_internal_iff_isInfix

/-- Refuse an embedded fence; otherwise surround the LF-normalized input text. -/
def block (source : String) : Except String String :=
  if hasFence source then .error "source contains a code fence"
  else .ok ("```\n" ++ trimLF source ++ "\n```\n")

/-- Exact success and refusal behavior of the actual presentation adapter. -/
theorem checkedBlock : StrictLean.ExecutableContract block
    (fun run => ∀ source, run source =
      if hasFence source then .error "source contains a code fence"
      else .ok ("```\n" ++ trimLF source ++ "\n```\n")) := ⟨fun _ => rfl⟩

/-- Non-vacuity: a trailing newline does not add a blank source line. -/
theorem positive_control : block "x\n" = .ok "```\nx\n```\n" := by
  have h : hasFence "x\n" = false := by decide +kernel
  simp only [block, h, Bool.false_eq_true, ite_false]
  rfl

/-- An embedded fence is refused instead of interpreted as generated documentation. -/
theorem negative_control : block "```" = .error "source contains a code fence" := rfl

/-- Exact metadata and checked-source inputs; obtaining these values from files and
registry JSON is an operational boundary, not a claim of this pure renderer. -/
structure PageInput where
  id : String
  title : String
  normativePath : String
  violation : String
  diagnostic : String
  fixed : String

/-- All three inserted text blocks must be free of embedded fences. -/
def FenceFree (input : PageInput) : Prop :=
  hasFence input.violation = false ∧ hasFence input.diagnostic = false ∧ hasFence input.fixed = false

instance (input : PageInput) : Decidable (FenceFree input) :=
  inferInstanceAs (Decidable (_ ∧ _ ∧ _))

private def wrapped (source : String) := "```\n" ++ trimLF source ++ "\n```\n"

/-- Canonical document bytes. The title is quoted using Lean's JSON-string renderer;
source and diagnostic sections use the exact LF-normalized input strings, not fresh
elaboration by Verso. This template is the presentation specification, not policy. -/
def pageText (input : PageInput) : String :=
  "import VersoManual\nopen Verso.Genre Manual\n#doc (Manual) " ++
  (Lean.toJson (input.id ++ ": " ++ input.title)).compress ++ " =>\n%%%\ntag := \"SL1001\"\n%%%\n" ++
  "This architecture prototype executes the checker and fixtures with Lean 4.34.0.\nVerso renders the checked source as text using Lean 4.34.0; it does not recheck it.\n\n# Cause\nAn owned logical axiom supplies an assumption without a checked body.\nThe policy rejects even an unused axiom. A body-bearing opaque definition is different.\n\n# Violation\n" ++
  wrapped input.violation ++ "\n# Diagnostic\n" ++ wrapped input.diagnostic ++
  "\n# Fix\nState a conditional theorem with its assumption as a hypothesis, or supply a checked proof.\nThe correction below proves only its conditional proposition, not False unconditionally.\n" ++ wrapped input.fixed ++
  "\n# Configuration and limits\nThis rule is required on positive surfaces under every logical foundation profile.\nThere is no local suppression that makes a project axiom conforming.\nThe prototype's explicit command inspects imported modules; immediate editor scheduling,\ncomplete registry coverage and whole-project conformance remain later deliverables.\n\n# Sources and credit\n[Normative requirement](https://github.com/rbeauchamp/strict-lean/blob/main/" ++ input.normativePath ++ ").\nCanonical metadata and proof-bearing acceptance design are informed by\n[con-leche](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean).\nThe linter interfaces are Lean APIs. Static rendering uses Verso;\nthe [Verso templates](https://github.com/leanprover/verso-templates/tree/76c9edf5a70f14d272af0f0f354ec833ac22c350)\ninform the separate documentation toolchain.\n[Microsoft CA1416](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/ca1416)\ninforms the explanation structure. Con-ron is excluded.\n"

/-- An admitted page carries its exact input/output relationship and fence admission.
The prototype only renders SL1001; it does not silently relabel this fixed narrative. -/
abbrev Page (input : PageInput) :=
  { body : String // body = pageText input ∧ FenceFree input ∧ input.id = "SL1001" }

/-- Pure page admission: unsupported IDs and any unsafe source fence refuse. -/
def renderPage (input : PageInput) : Except String (Page input) :=
  if h : FenceFree input ∧ input.id = "SL1001" then
    .ok ⟨pageText input, rfl, h⟩
  else .error "prototype requires SL1001 and fence-free checked text"

/-- All and only supported fence-free inputs produce the exact specified document. -/
theorem renderPage_exact (input : PageInput) :
    (renderPage input).isOk = true ↔ FenceFree input ∧ input.id = "SL1001" := by
  simp only [renderPage]
  split <;> simp_all [Except.isOk, Except.toBool]

/-- The operational writer obtains its body from this proof-requiring renderer. -/
theorem checkedPage : StrictLean.ExecutableContract renderPage
    (fun run => ∀ input, (run input).isOk = true ↔ FenceFree input ∧ input.id = "SL1001") :=
  ⟨renderPage_exact⟩

/-- Non-vacuity of page admission with actual nonempty source sections. -/
theorem page_positive_control :
    (renderPage ⟨"SL1001", "Axiom", "docs/standard/8-tooling-and-machine-audit.md", "x", "d", "y"⟩).isOk = true := rfl

/-- A different rule cannot reuse the fixed SL1001 narrative. -/
theorem page_wrong_rule_control :
    (renderPage ⟨"SL5001", "Docs", "", "x", "d", "y"⟩).isOk = false := rfl

/-- Raw observed site inputs. Booleans are external observations, not attestations. -/
structure SiteInput where
  id : String
  route : String
  emitted : List String
  routeExists : Bool
  violationExists : Bool
  fixedEmpty : Bool

/-- Preserve required and observed IDs separately; never derive emitted IDs from the
required inventory. Checked-example status is the conjunction of the three observations. -/
def siteArtifact (input : SiteInput) : Lean.Json := Lean.Json.mkObj [
  ("required", Lean.toJson [input.id]), ("emitted", Lean.toJson input.emitted),
  ("pages", Lean.toJson [Lean.Json.mkObj [("id", .str input.id), ("route", .str input.route),
    ("checkedExample", .bool (input.routeExists && input.violationExists && input.fixedEmpty)),
    ("advertisedEnforced", .bool true)]])]

/-- Field-level inventory and page-observation preservation, independent of authenticity. -/
def ArtifactMatches (input : SiteInput) (artifact : Lean.Json) : Prop :=
  artifact.getObjVal? "required" = .ok (Lean.toJson [input.id]) ∧
  artifact.getObjVal? "emitted" = .ok (Lean.toJson input.emitted) ∧
  artifact.getObjVal? "pages" = .ok (Lean.toJson [Lean.Json.mkObj [
    ("id", .str input.id), ("route", .str input.route),
    ("checkedExample", .bool (input.routeExists && input.violationExists && input.fixedEmpty)),
    ("advertisedEnforced", .bool true)]])

/-- Required artifact fields retain exactly their respective inputs, including order
and multiplicity of emitted IDs, without turning incomplete observations into true. -/
theorem artifact_exact (input : SiteInput) : ArtifactMatches input (siteArtifact input) :=
  ⟨rfl, rfl, rfl⟩

/-- The prototype submits precisely this registered artifact transformation. -/
theorem checkedArtifact : StrictLean.ExecutableContract siteArtifact
    (fun run => ∀ input, ArtifactMatches input (run input)) := ⟨artifact_exact⟩

end StrictLeanQualification.Website
