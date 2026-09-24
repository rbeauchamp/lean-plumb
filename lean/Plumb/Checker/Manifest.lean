import Plumb.Checker.PolicyCodec
import Plumb.Checker.Common
import Plumb.Checker.Policy
import PlumbPolicy.Guards
import PlumbCore.Assembly
import Lean.Elab.Command

/-! Strict surface-manifest parsing. Unknowns and omissions fail closed. The pure `parse` is
the executed parser. `parse_sound` proves what every accepted manifest satisfies;
`parse_input` proves it has the allowed keys and schema version and that each entry is, in
order, the decoding of its JSON element, including the `execution` field;
`parse_emptyExclusions` proves empty exclusion arrays are accepted whenever the surfaces are.
The refusal-class theorems prove the message of malformed JSON, an unknown top-level or surface
key, a non-2 schema version, empty surfaces and a bad surface `execution`, each given an
otherwise accepted prefix. `load` adds only file IO. -/

namespace Plumb.Checker.Manifest

open Lean System
open Plumb.Checker.Policy PlumbPolicy.Guards

def defaultPath (repo : FilePath) : FilePath :=
  repo / "foundation_manifest.json"

def libraries (manifest : Manifest) : Array String :=
  manifest.surfaces.map (·.library) ++ manifest.excludedLibraries.map (·.library)

def executables (manifest : Manifest) : Array String :=
  manifest.surfaces.flatMap (·.executables)
    ++ manifest.excludedExecutables.map (·.executable)

/-- A well-formed target name: nonempty, no surrounding or inner whitespace, no comma. -/
def TargetName (value : String) : Prop :=
  value ≠ "" ∧ value.trimAscii.toString = value ∧ ∀ c ∈ value.toList, ¬c.isWhitespace ∧ c ≠ ','

private def objectWithKeys (value : Json) (allowed : Array String) (location : String) :
    Except String Unit := do
  let object ← value.getObj?
  let unknown := object.keysArray.filter (!allowed.contains ·)
  unless unknown.isEmpty do
    throw s!"manifest-schema: {location} has unknown key(s): {repr unknown.toList}"

/-- The JSON object's keys are all allowed. -/
def KeysAllowed (value : Json) (allowed : Array String) : Prop :=
  ∃ object, value.getObj? = .ok object ∧ ∀ key ∈ object.keysArray, key ∈ allowed

theorem objectWithKeys_sound {value : Json} {allowed : Array String} {location : String} {u : Unit}
    (h : objectWithKeys value allowed location = .ok u) : KeysAllowed value allowed := by
  unfold objectWithKeys at h
  simp only [bind_eq_ok] at h
  obtain ⟨object, hobj, h⟩ := h
  refine ⟨object, hobj, fun key hkey => ?_⟩
  split at h
  · rename_i hempty
    have hnil := Array.isEmpty_iff.mp hempty
    by_cases hk : key ∈ allowed
    · exact hk
    · have hmem : key ∈ object.keysArray.filter (fun x => !allowed.contains x) := by
        rw [Array.mem_filter]
        exact ⟨hkey, by simpa [Array.contains_iff_mem] using hk⟩
      rw [hnil] at hmem
      simp at hmem
  · simp [throw, throwThe, MonadExceptOf.throw] at h

theorem objectWithKeys_complete {value : Json} {allowed : Array String} {location : String}
    (h : KeysAllowed value allowed) : objectWithKeys value allowed location = .ok () := by
  obtain ⟨object, hobj, hkeys⟩ := h
  simpa [objectWithKeys, hobj, bind, Except.bind, pure, Except.pure] using hkeys

private def stringField (value : Json) (key location : String) : Except String String := do
  match ← value.getObjVal? key with
  | .str text => return text
  | _ => throw s!"manifest-schema: {location}.{key} must be a string"

theorem stringField_ok {value : Json} {key location text : String}
    (h : stringField value key location = .ok text) : value.getObjVal? key = .ok (.str text) := by
  unfold stringField at h
  simp only [bind_eq_ok] at h
  obtain ⟨field, hfield, h⟩ := h
  split at h
  · simp only [pure_eq_ok] at h
    exact h ▸ hfield
  · simp [throw, throwThe, MonadExceptOf.throw] at h

def targetName (kind value location : String) : Except String String := do
  if value.isEmpty || value.trimAscii.toString != value
      || value.toList.any (fun c => c.isWhitespace || c == ',') then
    throw s!"manifest-incomplete: {location} must be a nonempty {kind} name"
  return value

def rationale (value location : String) : Except String String := do
  if value.trimAscii.isEmpty then
    throw s!"manifest-incomplete: {location}.rationale is required"
  return value

theorem targetName_sound {kind value location name : String}
    (h : targetName kind value location = .ok name) : name = value ∧ TargetName value := by
  unfold targetName at h
  split at h
  · simp [throw, throwThe, MonadExceptOf.throw, Functor.map, Except.map] at h
  · rename_i hc
    simp only [pure_eq_ok] at h
    simp only [Bool.or_eq_true, beq_iff_eq, bne_iff_ne, ne_eq, List.any_eq_true, not_or,
      not_exists, not_and, String.isEmpty_iff] at hc
    refine ⟨h.symm, hc.1.1, by simpa using hc.1.2, fun c hc' => ?_⟩
    have := hc.2 c hc'
    simpa using this


/-- Record each executable once, refusing a malformed or repeated name. -/
def addExecutables (location : String) : Array String → List String → Except String (Array String)
  | seen, [] => pure seen
  | seen, exe :: rest => do
    let _ ← targetName "executable" exe s!"{location}.executables"
    if seen.contains exe then throw s!"manifest-schema: duplicate executable '{exe}'"
    addExecutables location (seen.push exe) rest

theorem push_nodup {xs : Array String} {x : String} (h : xs.toList.Nodup) (hx : xs.contains x = false) :
    (xs.push x).toList.Nodup := by
  simp only [Array.toList_push]
  rw [List.nodup_append]
  refine ⟨h, List.nodup_cons.mpr ⟨by simp, List.nodup_nil⟩, ?_⟩
  intro a ha b hb
  simp at hb
  subst hb
  intro heq
  subst heq
  simp at hx
  exact hx (by simpa using ha)

theorem addExecutables_sound {location : String} :
    ∀ {seen out : Array String} {names : List String}, seen.toList.Nodup →
      addExecutables location seen names = .ok out →
      out = seen ++ names.toArray ∧ out.toList.Nodup ∧ ∀ n ∈ names, TargetName n
  | seen, out, [], hn, h => by
    simp only [addExecutables, pure_eq_ok] at h
    subst h
    simp [hn]
  | seen, out, exe :: rest, hn, h => by
    simp only [addExecutables, bind_eq_ok] at h
    obtain ⟨name, hname, h⟩ := h
    split at h
    · simp [throw, throwThe, MonadExceptOf.throw] at h
    · rename_i hc
      have hc : seen.contains exe = false := by simpa using hc
      obtain ⟨hout, hnd, hnames⟩ := addExecutables_sound (push_nodup hn hc) h
      refine ⟨by simp [hout], hnd, ?_⟩
      intro n hmem
      simp only [List.mem_cons] at hmem
      rcases hmem with rfl | hmem
      · exact (targetName_sound hname).2
      · exact hnames n hmem


/-- Parsing state: the manifest so far plus every library and executable name seen. -/
structure Acc where
  surfaces : Array Surface := #[]
  excludedLibraries : Array ExcludedLibrary := #[]
  excludedExecutables : Array ExcludedExecutable := #[]
  seen : Array String := #[]
  seenExes : Array String := #[]

def Acc.manifest (acc : Acc) : Manifest := ⟨acc.surfaces, acc.excludedLibraries, acc.excludedExecutables⟩

/-- A surface names a well-formed library and executables, a conforming claim and a rationale. -/
def SurfaceOK (s : Surface) : Prop :=
  TargetName s.library ∧ (∀ e ∈ s.executables, TargetName e) ∧
    s.claim ≠ .compilerTrusting ∧ s.rationale.trimAscii.isEmpty = false

def Acc.Inv (acc : Acc) : Prop :=
  acc.seen = libraries acc.manifest ∧ acc.seen.toList.Nodup ∧
  acc.seenExes = executables acc.manifest ∧ acc.seenExes.toList.Nodup ∧
  (∀ s ∈ acc.surfaces, SurfaceOK s) ∧
  (∀ l ∈ acc.excludedLibraries, TargetName l.library ∧ l.rationale.trimAscii.isEmpty = false) ∧
  (∀ e ∈ acc.excludedExecutables, TargetName e.executable ∧ e.rationale.trimAscii.isEmpty = false)

theorem rationale_sound {value location r : String} (h : rationale value location = .ok r) :
    r = value ∧ value.trimAscii.isEmpty = false := by
  unfold rationale at h
  split at h
  · simp [throw, throwThe, MonadExceptOf.throw, Functor.map, Except.map] at h
  · rename_i hc
    simp only [pure_eq_ok] at h
    exact ⟨h.symm, by simpa using hc⟩

/-- Refuse a name already recorded. -/
def fresh (seen : Array String) (name message : String) : Except String Unit :=
  if seen.contains name then throw message else pure ()

theorem fresh_sound {seen : Array String} {name message : String} {u : Unit}
    (h : fresh seen name message = .ok u) : seen.contains name = false := by
  unfold fresh at h
  split at h
  · simp [throw, throwThe, MonadExceptOf.throw] at h
  · rename_i hc
    simpa using hc

/-- A fold whose every step appends the string of a JSON string item decodes exactly those items. -/
theorem foldlM_strings {f : Array String → Json → Except String (Array String)}
    (hf : ∀ r item r', f r item = .ok r' → ∃ t, item = .str t ∧ r' = r.push t) :
    ∀ (xs : List Json) (acc out : Array String), xs.foldlM f acc = .ok out →
      ∃ ys : List String, out.toList = acc.toList ++ ys ∧ xs = ys.map .str
  | [], acc, out, h => by
    simp only [List.foldlM_nil, pure_eq_ok] at h
    exact ⟨[], by simp [h], rfl⟩
  | x :: rest, acc, out, h => by
    simp only [List.foldlM_cons, bind_eq_ok] at h
    obtain ⟨mid, hmid, h⟩ := h
    obtain ⟨t, rfl, rfl⟩ := hf _ _ _ hmid
    obtain ⟨ys, hout, hrest⟩ := foldlM_strings hf rest _ _ h
    exact ⟨t :: ys, by simp [hout], by simp [hrest]⟩

/-- `stringArray` returns exactly the strings of the JSON array it accepts, in order. -/
theorem stringArray_items {what : String} {value : Json} {out : Array String}
    (h : stringArray what value = .ok out) : value = .arr (out.map .str) := by
  unfold stringArray at h
  split at h
  · rw [← Array.foldlM_toList] at h
    obtain ⟨ys, hout, hxs⟩ := foldlM_strings (fun r item r' hs => by
      split at hs
      · split at hs
        · simp [throw, throwThe, MonadExceptOf.throw, Functor.map, Except.map] at hs
        · simp only [pure_eq_ok] at hs
          exact ⟨_, rfl, hs.symm⟩
      · simp [throw, throwThe, MonadExceptOf.throw] at hs) _ _ _ h
    congr
    apply Array.toList_inj.mp
    simp [hxs, hout]
  · simp [throw, throwThe, MonadExceptOf.throw] at h

/-- A surface's optional executables, defaulting to none. -/
def surfaceExecutables (item : Json) (location : String) : Except String (Array String) :=
  match item.getObjVal? "executables" with
  | .error _ => pure #[]
  | .ok value => stringArray s!"{location}.executables" value

def surfaceClaim (item : Json) (location : String) : Except String Profile := do
  let claimText ← stringField item "claim" location
  let some claim := Profile.parse? claimText
    | throw <| s!"manifest-schema: {location}.claim must be one of " ++
        "kernel-only, choice-free, standard-logical"
  if claim = .compilerTrusting then
    throw <| s!"manifest-schema: {location}.claim must be one of " ++
      "kernel-only, choice-free, standard-logical"
  return claim

theorem surfaceClaim_sound {item : Json} {location : String} {claim : Profile}
    (h : surfaceClaim item location = .ok claim) : claim ≠ .compilerTrusting := by
  unfold surfaceClaim at h
  simp only [bind_eq_ok] at h
  obtain ⟨_, _, h⟩ := h
  split at h
  · rename_i c _
    cases c <;> simp [throw, throwThe, MonadExceptOf.throw, pure,
      Except.pure] at h <;> subst h <;> decide
  · simp [throw, throwThe, MonadExceptOf.throw] at h

def surfaceExecution (item : Json) (location : String) : Except String ExecutionClaim :=
  match item.getObjVal? "execution" with
  | .error _ => pure .report
  | .ok (.str text) => match ExecutionClaim.parse? text with
    | some mode => pure mode
    | none => throw s!"manifest-schema: {location}.execution must be \"report\" or \"checked\""
  | .ok _ => throw s!"manifest-schema: {location}.execution must be a string"

theorem surfaceExecutables_ok {item : Json} {location : String} {out : Array String}
    (h : surfaceExecutables item location = .ok out) :
    ((∃ e, item.getObjVal? "executables" = .error e) ∧ out = #[]) ∨
      item.getObjVal? "executables" = .ok (.arr (out.map .str)) := by
  unfold surfaceExecutables at h
  split at h
  · rename_i e he
    simp only [pure_eq_ok] at h
    exact .inl ⟨⟨e, he⟩, h.symm⟩
  · rename_i value hv
    exact .inr (hv.trans (congrArg _ (stringArray_items h)))

theorem surfaceClaim_ok {item : Json} {location : String} {claim : Profile}
    (h : surfaceClaim item location = .ok claim) :
    ∃ text, item.getObjVal? "claim" = .ok (.str text) ∧ Profile.parse? text = some claim := by
  unfold surfaceClaim at h
  simp only [bind_eq_ok] at h
  obtain ⟨text, htext, h⟩ := h
  split at h
  · rename_i c hc
    split at h
    · simp [throw, throwThe, MonadExceptOf.throw, Functor.map, Except.map] at h
    · simp only [pure_eq_ok] at h
      exact ⟨text, stringField_ok htext, h ▸ hc⟩
  · simp [throw, throwThe, MonadExceptOf.throw] at h

theorem surfaceExecution_ok {item : Json} {location : String} {execution : ExecutionClaim}
    (h : surfaceExecution item location = .ok execution) :
    ((∃ e, item.getObjVal? "execution" = .error e) ∧ execution = .report) ∨
      ∃ text, item.getObjVal? "execution" = .ok (.str text) ∧
        ExecutionClaim.parse? text = some execution := by
  unfold surfaceExecution at h
  split at h
  · rename_i e he
    simp only [pure_eq_ok] at h
    exact .inl ⟨⟨e, he⟩, h.symm⟩
  · rename_i text htext
    split at h
    · rename_i mode hmode
      simp only [pure_eq_ok] at h
      exact .inr ⟨text, htext, h ▸ hmode⟩
    · simp [throw, throwThe, MonadExceptOf.throw] at h
  · simp [throw, throwThe, MonadExceptOf.throw] at h

/-- `s` is the decoding of the JSON surface `item`: every field is its JSON value, an absent
`executables` is empty and an absent `execution` is `report`. -/
def SurfaceDecodes (item : Json) (s : Surface) : Prop :=
  item.getObjVal? "library" = .ok (.str s.library) ∧
  (((∃ e, item.getObjVal? "executables" = .error e) ∧ s.executables = #[]) ∨
    item.getObjVal? "executables" = .ok (.arr (s.executables.map .str))) ∧
  (∃ text, item.getObjVal? "claim" = .ok (.str text) ∧ Profile.parse? text = some s.claim) ∧
  (((∃ e, item.getObjVal? "execution" = .error e) ∧ s.execution = .report) ∨
    ∃ text, item.getObjVal? "execution" = .ok (.str text) ∧
      ExecutionClaim.parse? text = some s.execution) ∧
  item.getObjVal? "rationale" = .ok (.str s.rationale)

def ExcludedLibraryDecodes (item : Json) (l : ExcludedLibrary) : Prop :=
  item.getObjVal? "library" = .ok (.str l.library) ∧ item.getObjVal? "rationale" = .ok (.str l.rationale)

def ExcludedExecutableDecodes (item : Json) (e : ExcludedExecutable) : Prop :=
  item.getObjVal? "executable" = .ok (.str e.executable) ∧
    item.getObjVal? "rationale" = .ok (.str e.rationale)

def parseSurface (acc : Acc) (index : Nat) (item : Json) : Except String Acc := do
  let location := s!"surfaces[{index}]"
  objectWithKeys item #["library", "executables", "claim", "execution", "rationale"] location
  let library ← targetName "library" (← stringField item "library" location) s!"{location}.library"
  fresh acc.seen library s!"manifest-schema: duplicate library '{library}'"
  let executables ← surfaceExecutables item location
  let seenExes ← addExecutables location acc.seenExes executables.toList
  let claim ← surfaceClaim item location
  let execution ← surfaceExecution item location
  let why ← rationale (← stringField item "rationale" location) location
  let surface : Surface := ⟨library, executables, claim, execution, why⟩
  return { acc with seen := acc.seen.push library, seenExes, surfaces := acc.surfaces.push surface }

theorem parseSurface_inv {acc out : Acc} {index : Nat} {item : Json} (hi : acc.Inv)
    (hex : acc.excludedLibraries = #[] ∧ acc.excludedExecutables = #[])
    (h : parseSurface acc index item = .ok out) :
    out.Inv ∧ out.excludedLibraries = #[] ∧ out.excludedExecutables = #[] ∧
      out.surfaces.size = acc.surfaces.size + 1 := by
  unfold parseSurface at h
  simp only [bind_eq_ok, pure_eq_ok] at h
  obtain ⟨_, _, lt, _, library, hlib, ⟨⟩, hfresh, execs, _, seenExes, hadd, claim, hclaim,
    execution, _, rt, _, why, hwhy, rfl⟩ := h
  obtain ⟨hseen, hnd, hexes, hxnd, hs, hl, he⟩ := hi
  have hf := fresh_sound hfresh
  obtain ⟨rfl, hname⟩ := targetName_sound hlib
  obtain ⟨hout, hxnd', hnames⟩ := addExecutables_sound hxnd hadd
  obtain ⟨rfl, hr⟩ := rationale_sound hwhy
  refine ⟨⟨?_, push_nodup hnd hf, ?_, hxnd', ?_, hl, he⟩, hex.1, hex.2, by simp⟩
  · simp [hseen, libraries, Acc.manifest, hex.1]
  · simp [hout, hexes, executables, Acc.manifest, hex.2]
  · intro s hs'
    simp only [Array.mem_push] at hs'
    rcases hs' with hs' | rfl
    · exact hs s hs'
    · exact ⟨hname, fun e he' => hnames e (by simpa using he'), surfaceClaim_sound hclaim, hr⟩


def parseExcludedLibrary (acc : Acc) (index : Nat) (item : Json) : Except String Acc := do
  let location := s!"excluded-libraries[{index}]"
  objectWithKeys item #["library", "rationale"] location
  let library ← targetName "library" (← stringField item "library" location) s!"{location}.library"
  fresh acc.seen library s!"manifest-schema: duplicate library '{library}'"
  let why ← rationale (← stringField item "rationale" location) location
  let excluded : ExcludedLibrary := ⟨library, why⟩
  return { acc with seen := acc.seen.push library, excludedLibraries := acc.excludedLibraries.push excluded }

theorem parseExcludedLibrary_inv {acc out : Acc} {index : Nat} {item : Json} (hi : acc.Inv)
    (hex : acc.excludedExecutables = #[]) (h : parseExcludedLibrary acc index item = .ok out) :
    out.Inv ∧ out.excludedExecutables = #[] ∧ out.surfaces = acc.surfaces := by
  unfold parseExcludedLibrary at h
  simp only [bind_eq_ok, pure_eq_ok] at h
  obtain ⟨_, _, lt, _, library, hlib, ⟨⟩, hfresh, rt, _, why, hwhy, rfl⟩ := h
  obtain ⟨hseen, hnd, hexes, hxnd, hs, hl, he⟩ := hi
  obtain ⟨rfl, hname⟩ := targetName_sound hlib
  obtain ⟨rfl, hr⟩ := rationale_sound hwhy
  refine ⟨⟨?_, push_nodup hnd (fresh_sound hfresh), ?_, hxnd, hs, ?_, he⟩, hex, rfl⟩
  · simp [hseen, libraries, Acc.manifest]
  · simp [hexes, executables, Acc.manifest]
  · intro l hl'
    simp only [Array.mem_push] at hl'
    rcases hl' with hl' | rfl
    · exact hl l hl'
    · exact ⟨hname, hr⟩

def parseExcludedExecutable (acc : Acc) (index : Nat) (item : Json) : Except String Acc := do
  let location := s!"excluded-executables[{index}]"
  objectWithKeys item #["executable", "rationale"] location
  let executable ← targetName "executable" (← stringField item "executable" location) s!"{location}.executable"
  fresh acc.seenExes executable s!"manifest-schema: duplicate executable '{executable}'"
  let why ← rationale (← stringField item "rationale" location) location
  let excluded : ExcludedExecutable := ⟨executable, why⟩
  return { acc with seenExes := acc.seenExes.push executable, excludedExecutables := acc.excludedExecutables.push excluded }

theorem parseExcludedExecutable_inv {acc out : Acc} {index : Nat} {item : Json} (hi : acc.Inv)
    (h : parseExcludedExecutable acc index item = .ok out) :
    out.Inv ∧ out.surfaces = acc.surfaces := by
  unfold parseExcludedExecutable at h
  simp only [bind_eq_ok, pure_eq_ok] at h
  obtain ⟨_, _, lt, _, executable, hexe, ⟨⟩, hfresh, rt, _, why, hwhy, rfl⟩ := h
  obtain ⟨hseen, hnd, hexes, hxnd, hs, hl, he⟩ := hi
  obtain ⟨rfl, hname⟩ := targetName_sound hexe
  obtain ⟨rfl, hr⟩ := rationale_sound hwhy
  refine ⟨⟨?_, hnd, ?_, push_nodup hxnd (fresh_sound hfresh), hs, hl, ?_⟩, rfl⟩
  · simp [hseen, libraries, Acc.manifest]
  · simp [hexes, executables, Acc.manifest]
  · intro e he'
    simp only [Array.mem_push] at he'
    rcases he' with he' | rfl
    · exact he e he'
    · exact ⟨hname, hr⟩

/-- Fold one parsing step over an array with its indices, stopping at the first refusal. -/
def parseAll (step : Acc → Nat → Json → Except String Acc) :
    List Json → Nat → Acc → Except String Acc
  | [], _, acc => pure acc
  | item :: rest, index, acc => do parseAll step rest (index + 1) (← step acc index item)

theorem parseAll_inv (step : Acc → Nat → Json → Except String Acc) (P : Acc → Prop)
    (hstep : ∀ acc out index item, P acc → step acc index item = .ok out → P out) :
    ∀ {items : List Json} {index : Nat} {acc out : Acc}, P acc →
      parseAll step items index acc = .ok out → P out
  | [], _, acc, out, hp, h => by
    simp only [parseAll, pure_eq_ok] at h
    exact h ▸ hp
  | item :: rest, index, acc, out, hp, h => by
    simp only [parseAll, bind_eq_ok] at h
    obtain ⟨mid, hmid, h⟩ := h
    exact parseAll_inv step P hstep (hstep _ _ _ _ hp hmid) h


/-- Everything a successfully parsed manifest guarantees about its own contents. -/
def Manifest.Valid (m : Manifest) : Prop :=
  m.surfaces ≠ #[] ∧ (libraries m).toList.Nodup ∧ (executables m).toList.Nodup ∧
  (∀ s ∈ m.surfaces, SurfaceOK s) ∧
  (∀ l ∈ m.excludedLibraries, TargetName l.library ∧ l.rationale.trimAscii.isEmpty = false) ∧
  (∀ e ∈ m.excludedExecutables, TargetName e.executable ∧ e.rationale.trimAscii.isEmpty = false)

/-- The top-level object: exact keys, schema version 2, and three arrays with nonempty surfaces. -/
def topLevel (value : Json) : Except String (Array Json × Array Json × Array Json) := do
  objectWithKeys value #["schema-version", "surfaces", "excluded-libraries", "excluded-executables"]
    "top level"
  unless (← value.getObjVal? "schema-version") == Json.num 2 do
    throw "manifest-schema: schema-version must be exactly 2"
  let .arr surfaceValues ← value.getObjVal? "surfaces"
    | throw "manifest-schema: surfaces must be an array"
  let .arr excludedValues ← value.getObjVal? "excluded-libraries"
    | throw "manifest-schema: excluded-libraries must be an array"
  let .arr excludedExeValues ← value.getObjVal? "excluded-executables"
    | throw "manifest-schema: excluded-executables must be an array"
  if surfaceValues.isEmpty then
    throw "manifest-incomplete: surfaces must be a nonempty array"
  return (surfaceValues, excludedValues, excludedExeValues)

theorem topLevel_sound {value : Json} {s l e : Array Json} (h : topLevel value = .ok (s, l, e)) :
    KeysAllowed value #["schema-version", "surfaces", "excluded-libraries", "excluded-executables"] ∧
    (∃ schema, value.getObjVal? "schema-version" = .ok schema ∧ (schema == Json.num 2) = true) ∧
    value.getObjVal? "surfaces" = .ok (.arr s) ∧ value.getObjVal? "excluded-libraries" = .ok (.arr l) ∧
    value.getObjVal? "excluded-executables" = .ok (.arr e) ∧ s ≠ #[] := by
  unfold topLevel at h
  simp only [bind_eq_ok] at h
  obtain ⟨_, hkeys, schema, hschema, h⟩ := h
  split at h
  · rename_i hv
    simp only [bind_eq_ok] at h
    obtain ⟨sj, hsj, h⟩ := h
    split at h
    · rename_i sv
      simp only [bind_eq_ok] at h
      obtain ⟨lj, hlj, h⟩ := h
      split at h
      · rename_i lv
        simp only [bind_eq_ok] at h
        obtain ⟨ej, hej, h⟩ := h
        split at h
        · rename_i ev
          split at h
          · simp [throw, throwThe, MonadExceptOf.throw, Functor.map, Except.map] at h
          · rename_i hne
            simp only [pure_eq_ok, Prod.mk.injEq] at h
            obtain ⟨rfl, rfl, rfl⟩ := h
            exact ⟨objectWithKeys_sound hkeys, ⟨schema, hschema, by simpa using hv⟩, hsj, hlj, hej,
              by simpa using hne⟩
        · simp [throw, throwThe, MonadExceptOf.throw] at h
      · simp [throw, throwThe, MonadExceptOf.throw] at h
    · simp [throw, throwThe, MonadExceptOf.throw] at h
  · simp [throw, throwThe, MonadExceptOf.throw] at h

theorem empty_inv : ({} : Acc).Inv := by
  simp [Acc.Inv, libraries, executables, Acc.manifest]

def parse (path text : String) : Except String Manifest := do
  let value ← (Plumb.Checker.PolicyCodec.parse text).mapError
    (fun error => s!"manifest-malformed: {path}: {error}")
  let (surfaceValues, excludedValues, excludedExeValues) ← topLevel value
  let acc ← parseAll parseSurface surfaceValues.toList 0 {}
  let acc ← parseAll parseExcludedLibrary excludedValues.toList 0 acc
  let acc ← parseAll parseExcludedExecutable excludedExeValues.toList 0 acc
  return acc.manifest

theorem parse_sound {path text : String} {m : Manifest} (h : parse path text = .ok m) : m.Valid := by
  unfold parse at h
  simp only [bind_eq_ok, pure_eq_ok] at h
  obtain ⟨value, _, ⟨sv, lv, ev⟩, htop, a1, h1, a2, h2, a3, h3, rfl⟩ := h
  obtain ⟨-, -, -, -, -, hne⟩ := topLevel_sound htop
  -- Surfaces: at least one step runs, and every step keeps the invariant.
  have hs : a1.Inv ∧ a1.excludedLibraries = #[] ∧ a1.excludedExecutables = #[] ∧ a1.surfaces ≠ #[] := by
    obtain ⟨first, rest, hfr⟩ : ∃ first rest, sv.toList = first :: rest := by
      cases hsv : sv.toList with
      | nil => exact absurd (Array.toList_eq_nil_iff.mp hsv) hne
      | cons a r => exact ⟨a, r, rfl⟩
    rw [hfr] at h1
    simp only [parseAll, bind_eq_ok] at h1
    obtain ⟨mid, hmid, h1⟩ := h1
    obtain ⟨hinv, hl, he, hsize⟩ := parseSurface_inv empty_inv ⟨rfl, rfl⟩ hmid
    refine parseAll_inv parseSurface
      (fun acc => acc.Inv ∧ acc.excludedLibraries = #[] ∧ acc.excludedExecutables = #[] ∧
        acc.surfaces ≠ #[]) ?_ ⟨hinv, hl, he, ?_⟩ h1
    · intro acc out index item ⟨hi, hl, he, hn⟩ hstep
      obtain ⟨hi', hl', he', hsz⟩ := parseSurface_inv hi ⟨hl, he⟩ hstep
      exact ⟨hi', hl', he', by intro hemp; simp [hemp] at hsz⟩
    · intro hemp; simp [hemp] at hsize
  have hl : a2.Inv ∧ a2.excludedExecutables = #[] ∧ a2.surfaces ≠ #[] :=
    parseAll_inv parseExcludedLibrary
      (fun acc => acc.Inv ∧ acc.excludedExecutables = #[] ∧ acc.surfaces ≠ #[])
      (fun acc out index item ⟨hi, he, hn⟩ hstep => by
        obtain ⟨hi', he', hsurf⟩ := parseExcludedLibrary_inv hi he hstep
        exact ⟨hi', he', hsurf ▸ hn⟩)
      ⟨hs.1, hs.2.2.1, hs.2.2.2⟩ h2
  have he : a3.Inv ∧ a3.surfaces ≠ #[] :=
    parseAll_inv parseExcludedExecutable (fun acc => acc.Inv ∧ acc.surfaces ≠ #[])
      (fun acc out index item ⟨hi, hn⟩ hstep => by
        obtain ⟨hi', hsurf⟩ := parseExcludedExecutable_inv hi hstep
        exact ⟨hi', hsurf ▸ hn⟩)
      ⟨hl.1, hl.2.2⟩ h3
  obtain ⟨⟨hseen, hnd, hexes, hxnd, hsok, hlok, heok⟩, hsne⟩ := he
  exact ⟨hsne, hseen ▸ hnd, hexes ▸ hxnd, hsok, hlok, heok⟩


/-- Every item a successful fold consumed satisfies what one successful step establishes. -/
theorem parseAll_each (step : Acc → Nat → Json → Except String Acc) (Q : Json → Prop)
    (hstep : ∀ acc out index item, step acc index item = .ok out → Q item) :
    ∀ {items : List Json} {index : Nat} {acc out : Acc},
      parseAll step items index acc = .ok out → ∀ item ∈ items, Q item
  | [], _, _, _, _ => by simp
  | item :: rest, index, acc, out, h => by
    simp only [parseAll, bind_eq_ok] at h
    obtain ⟨mid, hmid, h⟩ := h
    intro x hx
    simp only [List.mem_cons] at hx
    rcases hx with rfl | hx
    · exact hstep _ _ _ _ hmid
    · exact parseAll_each step Q hstep h x hx

/-- `D` relates the two lists element by element, in order. -/
def Decodes {α : Type} (D : Json → α → Prop) (items : List Json) (ys : List α) : Prop :=
  items.length = ys.length ∧ ∀ p ∈ items.zip ys, D p.1 p.2

/-- A fold whose every step appends one decoding of its item to `f` pairs the items, in
order, with the appended entries. -/
theorem parseAll_decodes {α : Type} (step : Acc → Nat → Json → Except String Acc)
    (f : Acc → Array α) (D : Json → α → Prop)
    (hstep : ∀ acc out index item, step acc index item = .ok out →
      ∃ x, f out = (f acc).push x ∧ D item x) :
    ∀ {items : List Json} {index : Nat} {acc out : Acc}, parseAll step items index acc = .ok out →
      ∃ ys : List α, (f out).toList = (f acc).toList ++ ys ∧ Decodes D items ys
  | [], _, acc, out, h => by
    simp only [parseAll, pure_eq_ok] at h
    exact ⟨[], by simp [h], by simp [Decodes]⟩
  | item :: rest, index, acc, out, h => by
    simp only [parseAll, bind_eq_ok] at h
    obtain ⟨mid, hmid, h⟩ := h
    obtain ⟨x, hx, hd⟩ := hstep _ _ _ _ hmid
    obtain ⟨ys, hys, hall⟩ := parseAll_decodes step f D hstep h
    refine ⟨x :: ys, by simp [hys, hx], by simp [hall.1], ?_⟩
    intro p hp
    simp only [List.zip_cons_cons, List.mem_cons] at hp
    rcases hp with rfl | hp
    · exact hd
    · exact hall.2 p hp


theorem parseSurface_input {acc out : Acc} {index : Nat} {item : Json}
    (h : parseSurface acc index item = .ok out) :
    KeysAllowed item #["library", "executables", "claim", "execution", "rationale"] ∧
      (∃ s, out.surfaces = acc.surfaces.push s ∧ SurfaceDecodes item s) ∧
      out.excludedLibraries = acc.excludedLibraries ∧ out.excludedExecutables = acc.excludedExecutables := by
  unfold parseSurface at h
  simp only [bind_eq_ok, pure_eq_ok] at h
  obtain ⟨_, hkeys, _, hlt, _, hlib, _, _, _, hexecs, _, _, _, hclaim, _, hexec, _, hrt, _, hwhy,
    rfl⟩ := h
  obtain ⟨rfl, -⟩ := targetName_sound hlib
  obtain ⟨rfl, -⟩ := rationale_sound hwhy
  exact ⟨objectWithKeys_sound hkeys, ⟨_, rfl, stringField_ok hlt, surfaceExecutables_ok hexecs,
    surfaceClaim_ok hclaim, surfaceExecution_ok hexec, stringField_ok hrt⟩, rfl, rfl⟩

theorem parseExcludedLibrary_input {acc out : Acc} {index : Nat} {item : Json}
    (h : parseExcludedLibrary acc index item = .ok out) :
    KeysAllowed item #["library", "rationale"] ∧
      (∃ l, out.excludedLibraries = acc.excludedLibraries.push l ∧ ExcludedLibraryDecodes item l) ∧
      out.surfaces = acc.surfaces ∧ out.excludedExecutables = acc.excludedExecutables := by
  unfold parseExcludedLibrary at h
  simp only [bind_eq_ok, pure_eq_ok] at h
  obtain ⟨_, hkeys, _, hlt, _, hlib, _, _, _, hrt, _, hwhy, rfl⟩ := h
  obtain ⟨rfl, -⟩ := targetName_sound hlib
  obtain ⟨rfl, -⟩ := rationale_sound hwhy
  exact ⟨objectWithKeys_sound hkeys, ⟨_, rfl, stringField_ok hlt, stringField_ok hrt⟩, rfl, rfl⟩

theorem parseExcludedExecutable_input {acc out : Acc} {index : Nat} {item : Json}
    (h : parseExcludedExecutable acc index item = .ok out) :
    KeysAllowed item #["executable", "rationale"] ∧
      (∃ e, out.excludedExecutables = acc.excludedExecutables.push e ∧
        ExcludedExecutableDecodes item e) ∧
      out.surfaces = acc.surfaces ∧ out.excludedLibraries = acc.excludedLibraries := by
  unfold parseExcludedExecutable at h
  simp only [bind_eq_ok, pure_eq_ok] at h
  obtain ⟨_, hkeys, _, hlt, _, hexe, _, _, _, hrt, _, hwhy, rfl⟩ := h
  obtain ⟨rfl, -⟩ := targetName_sound hexe
  obtain ⟨rfl, -⟩ := rationale_sound hwhy
  exact ⟨objectWithKeys_sound hkeys, ⟨_, rfl, stringField_ok hlt, stringField_ok hrt⟩, rfl, rfl⟩


/-- Input fidelity: the parsed manifest comes from well-formed JSON with exactly the allowed
top-level and per-entry keys and schema version 2, and each of its three arrays is, element by
element in order, the decoding of the corresponding JSON array. -/
theorem parse_input {path text : String} {m : Manifest} (h : parse path text = .ok m) :
    ∃ value sv lv ev, Plumb.Checker.PolicyCodec.parse text = .ok value ∧
      KeysAllowed value #["schema-version", "surfaces", "excluded-libraries", "excluded-executables"] ∧
      (∃ schema, value.getObjVal? "schema-version" = .ok schema ∧ (schema == Json.num 2) = true) ∧
      value.getObjVal? "surfaces" = .ok (.arr sv) ∧ value.getObjVal? "excluded-libraries" = .ok (.arr lv) ∧
      value.getObjVal? "excluded-executables" = .ok (.arr ev) ∧
      Decodes SurfaceDecodes sv.toList m.surfaces.toList ∧
      Decodes ExcludedLibraryDecodes lv.toList m.excludedLibraries.toList ∧
      Decodes ExcludedExecutableDecodes ev.toList m.excludedExecutables.toList ∧
      (∀ item ∈ sv, KeysAllowed item #["library", "executables", "claim", "execution", "rationale"]) ∧
      (∀ item ∈ lv, KeysAllowed item #["library", "rationale"]) ∧
      (∀ item ∈ ev, KeysAllowed item #["executable", "rationale"]) := by
  unfold parse at h
  simp only [bind_eq_ok, pure_eq_ok] at h
  obtain ⟨value, hvalue, ⟨sv, lv, ev⟩, htop, a1, h1, a2, h2, a3, h3, rfl⟩ := h
  obtain ⟨hkeys, hschema, hs, hl, he, -⟩ := topLevel_sound htop
  obtain ⟨y1, e1, d1⟩ := parseAll_decodes parseSurface (·.surfaces) SurfaceDecodes
    (fun _ _ _ _ hs => (parseSurface_input hs).2.1) h1
  obtain ⟨y2, e2, d2⟩ := parseAll_decodes parseExcludedLibrary (·.excludedLibraries)
    ExcludedLibraryDecodes (fun _ _ _ _ hs => (parseExcludedLibrary_input hs).2.1) h2
  obtain ⟨y3, e3, d3⟩ := parseAll_decodes parseExcludedExecutable (·.excludedExecutables)
    ExcludedExecutableDecodes (fun _ _ _ _ hs => (parseExcludedExecutable_input hs).2.1) h3
  -- Later folds leave earlier arrays unchanged.
  have k2 := parseAll_inv parseExcludedLibrary (fun acc => acc.surfaces = a1.surfaces ∧
      acc.excludedExecutables = a1.excludedExecutables)
    (fun _ _ _ _ ⟨hs', he'⟩ hstep => by
      obtain ⟨-, -, hs'', he''⟩ := parseExcludedLibrary_input hstep
      exact ⟨hs''.trans hs', he''.trans he'⟩) ⟨rfl, rfl⟩ h2
  have k1 := parseAll_inv parseSurface (fun acc => acc.excludedLibraries = #[] ∧
      acc.excludedExecutables = #[])
    (fun _ _ _ _ ⟨hl', he'⟩ hstep => by
      obtain ⟨-, -, hl'', he''⟩ := parseSurface_input hstep
      exact ⟨hl''.trans hl', he''.trans he'⟩) ⟨rfl, rfl⟩ h1
  have k3 := parseAll_inv parseExcludedExecutable (fun acc => acc.surfaces = a2.surfaces ∧
      acc.excludedLibraries = a2.excludedLibraries)
    (fun _ _ _ _ ⟨hs', hl'⟩ hstep => by
      obtain ⟨-, -, hs'', hl''⟩ := parseExcludedExecutable_input hstep
      exact ⟨hs''.trans hs', hl''.trans hl'⟩) ⟨rfl, rfl⟩ h3
  refine ⟨value, sv, lv, ev, ?_, hkeys, hschema, hs, hl, he, ?_, ?_, ?_,
    fun item hi => parseAll_each parseSurface _ (fun _ _ _ _ hs => (parseSurface_input hs).1) h1 item
      (by simpa using hi),
    fun item hi => parseAll_each parseExcludedLibrary _
      (fun _ _ _ _ hs => (parseExcludedLibrary_input hs).1) h2 item (by simpa using hi),
    fun item hi => parseAll_each parseExcludedExecutable _
      (fun _ _ _ _ hs => (parseExcludedExecutable_input hs).1) h3 item (by simpa using hi)⟩
  · cases hp : Plumb.Checker.PolicyCodec.parse text <;> simp_all [Except.mapError]
  · simp only [Acc.manifest, k3.1, k2.1]; simp only at e1; simpa [e1] using d1
  · simp only [Acc.manifest, k3.2]; simp only [k1.1] at e2; simpa [e2] using d2
  · simp only [Acc.manifest]; simp only [k2.2, k1.2] at e3; simpa [e3] using d3

/-- `topLevel` accepts every value meeting the conditions `topLevel_sound` establishes. -/
theorem topLevel_complete {value : Json} {sv lv ev : Array Json}
    (hkeys : KeysAllowed value
      #["schema-version", "surfaces", "excluded-libraries", "excluded-executables"])
    (hschema : ∃ schema, value.getObjVal? "schema-version" = .ok schema ∧ (schema == Json.num 2) = true)
    (hs : value.getObjVal? "surfaces" = .ok (.arr sv))
    (hl : value.getObjVal? "excluded-libraries" = .ok (.arr lv))
    (he : value.getObjVal? "excluded-executables" = .ok (.arr ev)) (hne : sv ≠ #[]) :
    topLevel value = .ok (sv, lv, ev) := by
  obtain ⟨schema, hschema, hv⟩ := hschema
  have hne : sv.isEmpty = false := by simpa [Array.isEmpty_iff] using hne
  simp [topLevel, objectWithKeys_complete hkeys, hschema, hv, hs, hl, he, hne, bind, Except.bind,
    pure, Except.pure]

/-- Completeness for empty exclusions: well-formed top-level JSON whose exclusion arrays are
empty is accepted whenever its surfaces are, with exactly the parsed surfaces. -/
theorem parse_emptyExclusions {path text : String} {value : Json} {sv : Array Json} {acc : Acc}
    (hvalue : Plumb.Checker.PolicyCodec.parse text = .ok value)
    (hkeys : KeysAllowed value
      #["schema-version", "surfaces", "excluded-libraries", "excluded-executables"])
    (hschema : ∃ schema, value.getObjVal? "schema-version" = .ok schema ∧ (schema == Json.num 2) = true)
    (hs : value.getObjVal? "surfaces" = .ok (.arr sv))
    (hl : value.getObjVal? "excluded-libraries" = .ok (.arr #[]))
    (he : value.getObjVal? "excluded-executables" = .ok (.arr #[])) (hne : sv ≠ #[])
    (hsurfaces : parseAll parseSurface sv.toList 0 {} = .ok acc) :
    parse path text = .ok acc.manifest := by
  have htop := topLevel_complete hkeys hschema hs hl he hne
  simp [parse, hvalue, htop, hsurfaces, parseAll, Except.mapError, bind, Except.bind, pure,
    Except.pure]

/-! Refusal classes. Each isolated defect, after an otherwise accepted prefix, yields exactly
its documented `manifest-malformed`, `manifest-schema` or `manifest-incomplete` message. -/

/-- A step refusing an item after an accepted prefix is the fold's refusal. -/
theorem parseAll_refuses (step : Acc → Nat → Json → Except String Acc) {item : Json}
    {rest : List Json} {msg : String} :
    ∀ {pre : List Json} {index : Nat} {acc mid : Acc}, parseAll step pre index acc = .ok mid →
      step mid (index + pre.length) item = .error msg →
      parseAll step (pre ++ item :: rest) index acc = .error msg
  | [], index, acc, mid, hpre, h => by
    simp only [parseAll, pure_eq_ok] at hpre
    subst hpre
    simp only [List.length_nil, Nat.add_zero] at h
    rw [List.nil_append, parseAll, h]
    rfl
  | x :: pre, index, acc, mid, hpre, h => by
    simp only [parseAll, bind_eq_ok] at hpre
    obtain ⟨next, hnext, hpre⟩ := hpre
    have h' : step mid (index + 1 + pre.length) item = .error msg := by
      rw [show index + 1 + pre.length = index + (x :: pre).length by
        simp only [List.length_cons]; omega]
      exact h
    rw [List.cons_append, parseAll, hnext]
    exact parseAll_refuses step hpre h'

theorem objectWithKeys_unknown {value : Json} {allowed : Array String} {location : String}
    {object : Std.TreeMap.Raw String Json compare} (hobj : value.getObj? = .ok object)
    (hunknown : object.keysArray.filter (!allowed.contains ·) ≠ #[]) :
    objectWithKeys value allowed location = .error
      s!"manifest-schema: {location} has unknown key(s): {repr (object.keysArray.filter (!allowed.contains ·)).toList}" := by
  have hne : (object.keysArray.filter (!allowed.contains ·)).isEmpty = false := by
    simpa [Array.isEmpty_iff] using hunknown
  unfold objectWithKeys
  simp only [hobj, bind, Except.bind, hne, Bool.false_eq_true, ↓reduceIte]
  rfl

theorem parse_malformed {path text error : String}
    (h : Plumb.Checker.PolicyCodec.parse text = .error error) :
    parse path text = .error s!"manifest-malformed: {path}: {error}" := by
  simp [parse, h, Except.mapError, bind, Except.bind]

/-- A top-level refusal of well-formed JSON is the refusal of `parse`. -/
theorem parse_topLevel_refuses {path text msg : String} {value : Json}
    (hvalue : Plumb.Checker.PolicyCodec.parse text = .ok value) (h : topLevel value = .error msg) :
    parse path text = .error msg := by
  simp [parse, hvalue, h, Except.mapError, bind, Except.bind]

/-- An unknown top-level key yields the `objectWithKeys_unknown` message. -/
theorem topLevel_unknownKey {value : Json} {msg : String}
    (h : objectWithKeys value #["schema-version", "surfaces", "excluded-libraries",
      "excluded-executables"] "top level" = .error msg) :
    topLevel value = .error msg := by
  unfold topLevel
  simp only [bind, Except.bind, h]

theorem topLevel_schemaVersion {value schema : Json}
    (hkeys : KeysAllowed value
      #["schema-version", "surfaces", "excluded-libraries", "excluded-executables"])
    (hschema : value.getObjVal? "schema-version" = .ok schema) (hv : (schema == Json.num 2) = false) :
    topLevel value = .error "manifest-schema: schema-version must be exactly 2" := by
  simp [topLevel, objectWithKeys_complete hkeys, hschema, hv, bind, Except.bind,
    throw, throwThe, MonadExceptOf.throw]

theorem topLevel_emptySurfaces {value : Json} {lv ev : Array Json}
    (hkeys : KeysAllowed value
      #["schema-version", "surfaces", "excluded-libraries", "excluded-executables"])
    (hschema : ∃ schema, value.getObjVal? "schema-version" = .ok schema ∧ (schema == Json.num 2) = true)
    (hs : value.getObjVal? "surfaces" = .ok (.arr #[]))
    (hl : value.getObjVal? "excluded-libraries" = .ok (.arr lv))
    (he : value.getObjVal? "excluded-executables" = .ok (.arr ev)) :
    topLevel value = .error "manifest-incomplete: surfaces must be a nonempty array" := by
  obtain ⟨schema, hschema, hv⟩ := hschema
  simp [topLevel, objectWithKeys_complete hkeys, hschema, hv, hs, hl, he, bind, Except.bind,
    throw, throwThe, MonadExceptOf.throw]

/-- A refusal of one surface after accepted earlier surfaces is the refusal of `parse`. -/
theorem parse_surface_refuses {path text msg : String} {value : Json} {sv lv ev : Array Json}
    {pre rest : List Json} {item : Json} {acc : Acc}
    (hvalue : Plumb.Checker.PolicyCodec.parse text = .ok value)
    (htop : topLevel value = .ok (sv, lv, ev)) (hsv : sv.toList = pre ++ item :: rest)
    (hpre : parseAll parseSurface pre 0 {} = .ok acc)
    (h : parseSurface acc pre.length item = .error msg) : parse path text = .error msg := by
  have hall := parseAll_refuses parseSurface (rest := rest) hpre (by simpa using h)
  simp [parse, hvalue, htop, hsv, hall, Except.mapError, bind, Except.bind]

/-- An unknown surface key yields the `objectWithKeys_unknown` message. -/
theorem parseSurface_unknownKey {acc : Acc} {index : Nat} {item : Json} {msg : String}
    (h : objectWithKeys item #["library", "executables", "claim", "execution", "rationale"]
      s!"surfaces[{index}]" = .error msg) :
    parseSurface acc index item = .error msg := by
  unfold parseSurface
  simp only [bind, Except.bind, h]

/-- Every check `parseSurface` runs before decoding `execution` accepts the item. -/
def SurfacePrefixOK (acc : Acc) (index : Nat) (item : Json) : Prop :=
  let location := s!"surfaces[{index}]"
  objectWithKeys item #["library", "executables", "claim", "execution", "rationale"] location = .ok () ∧
  ∃ text library executables seenExes claim,
    stringField item "library" location = .ok text ∧
    targetName "library" text s!"{location}.library" = .ok library ∧
    acc.seen.contains library = false ∧
    surfaceExecutables item location = .ok executables ∧
    addExecutables location acc.seenExes executables.toList = .ok seenExes ∧
    surfaceClaim item location = .ok claim

theorem parseSurface_execution_refuses {acc : Acc} {index : Nat} {item : Json} {msg : String}
    (hp : SurfacePrefixOK acc index item)
    (h : surfaceExecution item s!"surfaces[{index}]" = .error msg) :
    parseSurface acc index item = .error msg := by
  obtain ⟨hkeys, text, library, executables, seenExes, claim, htext, hlib, hfresh, hexecs, hadd,
    hclaim⟩ := hp
  unfold parseSurface
  simp only [bind, Except.bind, hkeys, htext, hlib, fresh, hfresh, Bool.false_eq_true, ↓reduceIte,
    pure, Except.pure, hexecs, hadd, hclaim, h]

theorem surfaceExecution_unknown {item : Json} {location text : String}
    (hfield : item.getObjVal? "execution" = .ok (.str text)) (hparse : ExecutionClaim.parse? text = none) :
    surfaceExecution item location =
      .error s!"manifest-schema: {location}.execution must be \"report\" or \"checked\"" := by
  simp [surfaceExecution, hfield, hparse, throw, throwThe, MonadExceptOf.throw]

theorem surfaceExecution_nonString {item field : Json} {location : String}
    (hfield : item.getObjVal? "execution" = .ok field) (hnot : ∀ text, field ≠ .str text) :
    surfaceExecution item location = .error s!"manifest-schema: {location}.execution must be a string" := by
  unfold surfaceExecution
  split
  · rename_i e he; simp [hfield] at he
  · rename_i text htext; exact absurd (Except.ok.inj (hfield.symm.trans htext)) (hnot text)
  · simp [throw, throwThe, MonadExceptOf.throw]

def load (path : FilePath) : IO Manifest := do
  if !(← path.pathExists) then
    throw <| IO.userError s!"manifest-missing: {path}"
  IO.ofExcept (parse path.toString (← IO.FS.readFile path))

/-- The Lake targets a checker must build so every claimed module is
elaborated and resolvable: each claimed library and claimed executable. -/
def positiveTargets (manifest : Manifest) : Array String :=
  manifest.surfaces.foldl
    (fun targets surface => targets.push surface.library ++ surface.executables) #[]

/-- The actual manifest's `claimed` surfaces, with every other actual library and executable
excluded. Both name sets equal the actual manifest's by construction. -/
def structuralManifest (actual : Manifest) (claimed : Array String) : Manifest :=
  let surfaces := actual.surfaces.filter (claimed.contains ·.library)
  let claimedLibs := surfaces.map (·.library)
  let claimedExes := surfaces.flatMap (·.executables)
  { surfaces
    excludedLibraries := (libraries actual).filter (!claimedLibs.contains ·) |>.map
      fun library => ⟨library, "structural control: excluded"⟩
    excludedExecutables := (executables actual).filter (!claimedExes.contains ·) |>.map
      fun executable => ⟨executable, "structural control: excluded"⟩ }

private theorem filter_split {xs ys : Array String} (hsub : ∀ x ∈ xs, x ∈ ys) (x : String) :
    x ∈ xs ++ ys.filter (fun y => !xs.contains y) ↔ x ∈ ys := by
  simp only [Array.mem_append, Array.mem_filter, Bool.not_eq_true']
  constructor
  · rintro (h | ⟨h, -⟩)
    · exact hsub x h
    · exact h
  · intro h
    by_cases hx : x ∈ xs
    · exact Or.inl hx
    · exact Or.inr ⟨h, by simpa [Array.contains_iff_mem] using hx⟩

/-- Every actual library is classified in the copy, and the copy names no other library. -/
theorem structural_libraries (actual : Manifest) (claimed : Array String) (l : String) :
    l ∈ libraries (structuralManifest actual claimed) ↔ l ∈ libraries actual := by
  have hsub : ∀ x ∈ (actual.surfaces.filter (claimed.contains ·.library)).map (·.library),
      x ∈ libraries actual := by
    intro x hx
    simp only [Array.mem_map, Array.mem_filter] at hx
    obtain ⟨s, ⟨hs, -⟩, rfl⟩ := hx
    exact Array.mem_append_left _ (Array.mem_map_of_mem hs)
  have key : libraries (structuralManifest actual claimed) =
      (actual.surfaces.filter (claimed.contains ·.library)).map (·.library) ++
        (libraries actual).filter (fun y =>
          !((actual.surfaces.filter (claimed.contains ·.library)).map (·.library)).contains y) := by
    simp only [structuralManifest, libraries, Array.map_map]
    congr 1
    ext1 <;> simp [Function.comp_def]
  rw [key]
  exact filter_split hsub l

/-- Every actual executable is classified in the copy, and the copy names no other executable. -/
theorem structural_executables (actual : Manifest) (claimed : Array String) (e : String) :
    e ∈ executables (structuralManifest actual claimed) ↔ e ∈ executables actual := by
  have hsub : ∀ x ∈ (actual.surfaces.filter (claimed.contains ·.library)).flatMap (·.executables),
      x ∈ executables actual := by
    intro x hx
    simp only [Array.mem_flatMap, Array.mem_filter] at hx
    obtain ⟨s, ⟨hs, -⟩, hx⟩ := hx
    exact Array.mem_append_left _ (Array.mem_flatMap.mpr ⟨s, hs, hx⟩)
  have key : executables (structuralManifest actual claimed) =
      (actual.surfaces.filter (claimed.contains ·.library)).flatMap (·.executables) ++
        (executables actual).filter (fun y =>
          !((actual.surfaces.filter (claimed.contains ·.library)).flatMap (·.executables)).contains y) := by
    simp only [structuralManifest, executables, Array.map_map]
    congr 1
    ext1 <;> simp [Function.comp_def]
  rw [key]
  exact filter_split hsub e

/-- The manifest in the checker's own JSON schema; `parse` reads exactly these keys. -/
def toJson (m : Manifest) : Json :=
  Json.mkObj [
    ("schema-version", Json.num 2),
    ("surfaces", Json.arr (m.surfaces.map fun s => Json.mkObj [
      ("library", .str s.library), ("executables", Json.arr (s.executables.map .str)),
      ("claim", .str s.claim.toString), ("execution", .str (ExecutionClaim.toString s.execution)),
      ("rationale", .str s.rationale)])),
    ("excluded-libraries", Json.arr (m.excludedLibraries.map fun l =>
      Json.mkObj [("library", .str l.library), ("rationale", .str l.rationale)])),
    ("excluded-executables", Json.arr (m.excludedExecutables.map fun e =>
      Json.mkObj [("executable", .str e.executable), ("rationale", .str e.rationale)]))]

end Plumb.Checker.Manifest

-- Exact dependency ceiling for the manifest-parser guarantees: Standard-Logical.
run_cmd do
  for name in #[``Plumb.Checker.Manifest.parse_sound, ``Plumb.Checker.Manifest.parse_input,
      ``Plumb.Checker.Manifest.parse_emptyExclusions, ``Plumb.Checker.Manifest.parse_malformed,
      ``Plumb.Checker.Manifest.parse_topLevel_refuses, ``Plumb.Checker.Manifest.topLevel_unknownKey,
      ``Plumb.Checker.Manifest.objectWithKeys_unknown,
      ``Plumb.Checker.Manifest.topLevel_schemaVersion,
      ``Plumb.Checker.Manifest.topLevel_emptySurfaces,
      ``Plumb.Checker.Manifest.parse_surface_refuses,
      ``Plumb.Checker.Manifest.parseSurface_unknownKey,
      ``Plumb.Checker.Manifest.parseSurface_execution_refuses,
      ``Plumb.Checker.Manifest.surfaceExecution_unknown,
      ``Plumb.Checker.Manifest.surfaceExecution_nonString,
      ``Plumb.Checker.Manifest.structural_libraries,
      ``Plumb.Checker.Manifest.structural_executables] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun ax => #[`propext, `Quot.sound, `Classical.choice].contains ax) do
      throwError "manifest theorem {name} exceeds Standard-Logical: {axioms}"
