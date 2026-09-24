module

@[expose] public section

/-! Presence of a labelled Intent section in a registered material declaration's
docstring (standard §5.2; rules PL5002 and PL5003).

A docstring is read as its line-feed-separated lines (`docLines`). An *Intent section*
is a Markdown ATX heading line whose text is exactly `Intent`, followed by the lines
before the next heading line (of any level) or the end of the docstring. The section
is *nonempty* when one of those lines contains a non-whitespace character.

Heading lines follow CommonMark's ATX form without a closing sequence: at most three
spaces of indentation, one to six `#`, then a space or tab (or the end of the line);
the heading text is the remainder with surrounding whitespace removed. Fenced code
blocks are not tracked, so a heading-shaped line inside a fence still counts as a
heading. The recognition is case-sensitive.

This is presence and linkage only. The docstring is linked to its declaration by
Lean's `findDocString?`; nothing here judges whether the intent is adequate, whether
it matches the explanation or the elaborated declaration, or whether registration is
complete. Those comparisons remain the R-INTENT and R-DOC semantic-review obligations. -/
namespace PlumbPolicy.Intent

/-- Whitespace that surrounds heading text and makes a line blank. -/
def isSpace (c : Char) : Bool := c.isWhitespace

/-- Remove leading and trailing whitespace from one line. -/
def trim (line : List Char) : List Char :=
  ((line.dropWhile isSpace).reverse.dropWhile isSpace).reverse

/-- Remove at most `n` leading spaces (CommonMark permits three before a heading). -/
def dropIndent : Nat → List Char → List Char
  | n + 1, ' ' :: rest => dropIndent n rest
  | _, line => line

/-- The text of an ATX heading line, or `none` when the line is not a heading. -/
def headingText? (line : List Char) : Option (List Char) :=
  let body := dropIndent 3 line
  let level := (body.takeWhile (· == '#')).length
  if 1 ≤ level ∧ level ≤ 6 then
    match body.dropWhile (· == '#') with
    | [] => some []
    | c :: text => if c == ' ' || c == '\t' then some (trim text) else none
  else none

/-- A heading line of any level; it ends the preceding section. -/
def isHeading (line : List Char) : Bool := (headingText? line).isSome

/-- A heading line labelled exactly `Intent`. -/
def isIntentHeading (line : List Char) : Bool := headingText? line == some "Intent".toList

/-- A line with at least one non-whitespace character. -/
def isContent (line : List Char) : Bool := line.any (!isSpace ·)
/-- Split at every line feed: the current (first) line and the lines after it. -/
def splitLinesAux : List Char → List Char × List (List Char)
  | [] => ([], [])
  | c :: rest =>
    let (line, lines) := splitLinesAux rest
    if c == '\n' then ([], line :: lines) else (c :: line, lines)

/-- Split characters at every line feed; a trailing line feed yields a final empty line.
A carriage return before it stays in the line and counts as whitespace. -/
def splitLines (cs : List Char) : List (List Char) :=
  (splitLinesAux cs).1 :: (splitLinesAux cs).2

/-- The docstring's lines, as characters. -/
def docLines (doc : String) : List (List Char) := splitLines doc.toList

/-- The specification: some Intent heading is followed, before any further heading,
by a content line. `body` is an initial run of the section's lines. -/
def IntentSection (lines : List (List Char)) : Prop :=
  ∃ before heading body after, lines = before ++ heading :: (body ++ after) ∧
    isIntentHeading heading = true ∧ (∀ line ∈ body, isHeading line = false) ∧
    ∃ line ∈ body, isContent line = true

/-- Scan a section: content occurs before the next heading. -/
def sectionHasContent : List (List Char) → Bool
  | [] => false
  | line :: rest => !isHeading line && (isContent line || sectionHasContent rest)

/-- Scan every line for an Intent heading whose section has content. -/
def hasIntentLines : List (List Char) → Bool
  | [] => false
  | line :: rest => (isIntentHeading line && sectionHasContent rest) || hasIntentLines rest

/-- The executed decision for one docstring. -/
def hasIntentSection (doc : String) : Bool := hasIntentLines (docLines doc)

theorem sectionHasContent_iff (lines : List (List Char)) :
    sectionHasContent lines = true ↔ ∃ body after, lines = body ++ after ∧
      (∀ line ∈ body, isHeading line = false) ∧ ∃ line ∈ body, isContent line = true := by
  induction lines with
  | nil => simp [sectionHasContent]
  | cons line rest ih =>
    simp only [sectionHasContent, Bool.and_eq_true, Bool.not_eq_true', Bool.or_eq_true, ih]
    constructor
    · rintro ⟨heading, content | ⟨body, after, split, headings, found⟩⟩
      · exact ⟨[line], rest, rfl, by simpa using heading, line, by simp, content⟩
      · refine ⟨line :: body, after, by simp [split], ?_, ?_⟩
        · intro l hl
          rcases List.mem_cons.mp hl with rfl | hl
          · exact heading
          · exact headings l hl
        · obtain ⟨l, hl, hc⟩ := found
          exact ⟨l, List.mem_cons_of_mem _ hl, hc⟩
    · rintro ⟨body, after, split, headings, l, hl, hc⟩
      cases body with
      | nil => simp at hl
      | cons first body =>
        simp only [List.cons_append, List.cons.injEq] at split
        obtain ⟨rfl, rfl⟩ := split
        refine ⟨headings line (by simp), ?_⟩
        rcases List.mem_cons.mp hl with rfl | hl
        · exact Or.inl hc
        · exact Or.inr ⟨body, after, rfl, fun m hm => headings m (List.mem_cons_of_mem _ hm),
            l, hl, hc⟩

/-- The line scanner decides exactly `IntentSection`. -/
theorem hasIntentLines_iff (lines : List (List Char)) :
    hasIntentLines lines = true ↔ IntentSection lines := by
  induction lines with
  | nil => simp [hasIntentLines, IntentSection]
  | cons line rest ih =>
    simp only [hasIntentLines, Bool.or_eq_true, Bool.and_eq_true, sectionHasContent_iff, ih,
      IntentSection]
    constructor
    · rintro (⟨heading, body, after, split, headings, found⟩ | ⟨before, h, body, after, split, rest'⟩)
      · exact ⟨[], line, body, after, by simp [split], heading, headings, found⟩
      · exact ⟨line :: before, h, body, after, by simp [split], rest'⟩
    · rintro ⟨before, h, body, after, split, heading, headings, found⟩
      cases before with
      | nil =>
        simp only [List.nil_append, List.cons.injEq] at split
        obtain ⟨rfl, rfl⟩ := split
        exact Or.inl ⟨heading, body, after, rfl, headings, found⟩
      | cons first before =>
        simp only [List.cons_append, List.cons.injEq] at split
        obtain ⟨rfl, rfl⟩ := split
        exact Or.inr ⟨before, h, body, after, rfl, heading, headings, found⟩

/-- The executed docstring decision accepts exactly the docstrings with a nonempty
labelled Intent section. -/
theorem hasIntentSection_iff (doc : String) :
    hasIntentSection doc = true ↔ IntentSection (docLines doc) :=
  hasIntentLines_iff _

instance (lines : List (List Char)) : Decidable (IntentSection lines) :=
  decidable_of_iff _ (hasIntentLines_iff lines)

/-- Splitting loses no character and invents none: rejoining the lines with line feeds
restores the docstring's characters. -/
theorem splitLines_intercalate (cs : List Char) : ['\n'].intercalate (splitLines cs) = cs := by
  induction cs with
  | nil => rfl
  | cons c rest ih =>
    unfold splitLines at ih ⊢
    simp only [splitLinesAux]
    generalize splitLinesAux rest = p at ih ⊢
    obtain ⟨line, lines⟩ := p
    by_cases hc : c = '\n'
    · subst hc
      simp only [beq_self_eq_true, ↓reduceIte]
      rw [List.intercalate_cons_cons, ih]
      rfl
    · simp only [beq_iff_eq, hc, ↓reduceIte]
      cases lines with
      | nil => simpa [List.intercalate] using ih
      | cons l ls =>
        rw [List.intercalate_cons_cons] at ih ⊢
        rw [← ih]
        rfl

/-- No line contains a line feed. -/
theorem newline_not_mem_splitLines (cs : List Char) : ∀ line ∈ splitLines cs, '\n' ∉ line := by
  induction cs with
  | nil => simp [splitLines, splitLinesAux]
  | cons c rest ih =>
    unfold splitLines at ih ⊢
    simp only [splitLinesAux]
    generalize splitLinesAux rest = p at ih ⊢
    obtain ⟨line, lines⟩ := p
    by_cases hc : c = '\n'
    · subst hc
      simp only [beq_self_eq_true, ↓reduceIte]
      intro l hl
      rcases List.mem_cons.mp hl with rfl | hl
      · simp
      · exact ih l hl
    · simp only [beq_iff_eq, hc, ↓reduceIte]
      intro l hl
      rcases List.mem_cons.mp hl with rfl | hl
      · simp only [List.mem_cons, not_or]
        exact ⟨fun h => hc h.symm, ih _ (by simp)⟩
      · exact ih l (List.mem_cons_of_mem _ hl)

/-- Non-vacuity: a docstring with an Intent section is accepted. -/
theorem intentSection_example :
    IntentSection (docLines "Claim.\n\n## Intent\nWhy the claim is required.") :=
  (hasIntentSection_iff _).mp (by decide)

/-- An Intent heading followed directly by another heading has an empty section. -/
theorem empty_intentSection_refused :
    ¬ IntentSection (docLines "Claim.\n\n## Intent\n\n## Notes\nOther text.") :=
  fun h => absurd ((hasIntentSection_iff _).mpr h) (by decide)

end PlumbPolicy.Intent

namespace PlumbPolicy
open Intent

/-- The documentation obligations a registered public material declaration can fail. -/
inductive MaterialDocumentationFailure where
  /-- No docstring is attached (PL5002). -/
  | missingDocstring
  /-- A docstring is attached, but it has no nonempty Intent section (PL5003). -/
  | missingIntent
  deriving Repr, DecidableEq

/-- A registered public material declaration has a docstring carrying a nonempty
labelled Intent section. Adequacy of either text remains semantic review. -/
def MaterialDocumentationOK (docstring : Option String) : Prop :=
  ∃ doc, docstring = some doc ∧ IntentSection (docLines doc)

/-- The executed classification of one observed docstring. -/
def materialDocumentationFailure : Option String → Option MaterialDocumentationFailure
  | none => some .missingDocstring
  | some doc => if hasIntentSection doc then none else some .missingIntent

/-- No failure is reported exactly when the obligation holds. -/
theorem materialDocumentationFailure_eq_none_iff (docstring : Option String) :
    materialDocumentationFailure docstring = none ↔ MaterialDocumentationOK docstring := by
  cases docstring with
  | none => simp [materialDocumentationFailure, MaterialDocumentationOK]
  | some doc =>
    by_cases h : hasIntentSection doc = true
    · simp [materialDocumentationFailure, MaterialDocumentationOK, h, ← hasIntentSection_iff]
    · simp [materialDocumentationFailure, MaterialDocumentationOK, h, ← hasIntentSection_iff]

/-- PL5002 is reported exactly for a missing docstring. -/
theorem materialDocumentationFailure_eq_missingDocstring_iff (docstring : Option String) :
    materialDocumentationFailure docstring = some .missingDocstring ↔ docstring = none := by
  cases docstring with
  | none => simp [materialDocumentationFailure]
  | some doc =>
    by_cases h : hasIntentSection doc = true <;> simp [materialDocumentationFailure, h]

/-- PL5003 is reported exactly for a present docstring without a nonempty Intent section. -/
theorem materialDocumentationFailure_eq_missingIntent_iff (docstring : Option String) :
    materialDocumentationFailure docstring = some .missingIntent ↔
      ∃ doc, docstring = some doc ∧ ¬ IntentSection (docLines doc) := by
  cases docstring with
  | none => simp [materialDocumentationFailure]
  | some doc =>
    by_cases h : hasIntentSection doc = true
    · simp [materialDocumentationFailure, h, ← hasIntentSection_iff]
    · simp [materialDocumentationFailure, h, ← hasIntentSection_iff]

instance (docstring : Option String) : Decidable (MaterialDocumentationOK docstring) :=
  decidable_of_iff _ (materialDocumentationFailure_eq_none_iff docstring)

end PlumbPolicy
