import StrictLean.Checker.Common
import StrictLean.Checker.Policy

/-! Strict surface-manifest parsing. Unknowns and omissions fail closed. -/

namespace StrictLean.Checker.Manifest

open Lean System
open StrictLean.Checker.Policy

structure Surface where
  library : String
  executables : Array String
  claim : Profile
  execution : ExecutionClaim
  rationale : String
  deriving Repr

structure ExcludedLibrary where
  library : String
  rationale : String
  deriving Repr

structure ExcludedExecutable where
  executable : String
  rationale : String
  deriving Repr

structure Manifest where
  surfaces : Array Surface
  excludedLibraries : Array ExcludedLibrary
  excludedExecutables : Array ExcludedExecutable
  deriving Repr

def defaultPath (repo : FilePath) : FilePath :=
  repo / "foundation_manifest.json"

private def objectWithKeys (value : Json) (allowed : Array String)
    (location : String) : IO (Std.TreeMap.Raw String Json compare) := do
  let object ← IO.ofExcept value.getObj?
  let unknown := object.keysArray.filter (!allowed.contains ·)
  if !unknown.isEmpty then
    throw <| IO.userError s!"manifest-schema: {location} has unknown key(s): {repr unknown.toList}"
  return object

private def required (value : Json) (key : String) : IO Json :=
  IO.ofExcept <| value.getObjVal? key

private def stringField (value : Json) (key location : String) : IO String := do
  let field ← required value key
  match field with
  | .str text => return text
  | _ => throw <| IO.userError s!"manifest-schema: {location}.{key} must be a string"

private def targetName (kind value location : String) : IO String := do
  if value.isEmpty || value.trimAscii.toString != value
      || value.toList.any (fun c => c.isWhitespace || c == ',') then
    throw <| IO.userError s!"manifest-incomplete: {location} must be a nonempty {kind} name"
  return value

private def rationale (value location : String) : IO String := do
  if value.trimAscii.isEmpty then
    throw <| IO.userError s!"manifest-incomplete: {location}.rationale is required"
  return value

def load (path : FilePath) : IO Manifest := do
  if !(← path.pathExists) then
    throw <| IO.userError s!"manifest-missing: {path}"
  let text ← IO.FS.readFile path
  let value ← match Json.parse text with
    | .ok value => pure value
    | .error error => throw <| IO.userError s!"manifest-malformed: {path}: {error}"
  let _ ← objectWithKeys value
    #["schema-version", "surfaces", "excluded-libraries", "excluded-executables"]
    "top level"
  let schema ← required value "schema-version"
  if schema != Json.num 2 then
    throw <| IO.userError "manifest-schema: schema-version must be exactly 2"
  let .arr surfaceValues ← required value "surfaces"
    | throw <| IO.userError "manifest-schema: surfaces must be an array"
  let .arr excludedValues ← required value "excluded-libraries"
    | throw <| IO.userError "manifest-schema: excluded-libraries must be an array"
  let .arr excludedExeValues ← required value "excluded-executables"
    | throw <| IO.userError "manifest-schema: excluded-executables must be an array"
  if surfaceValues.isEmpty then
    throw <| IO.userError "manifest-incomplete: surfaces must be a nonempty array"
  let mut seen : Array String := #[]
  let mut seenExes : Array String := #[]
  let mut surfaces : Array Surface := #[]
  for index in [:surfaceValues.size] do
    let item := surfaceValues[index]!
    let location := s!"surfaces[{index}]"
    let _ ← objectWithKeys item #["library", "executables", "claim", "execution", "rationale"] location
    let library ← targetName "library" (← stringField item "library" location) s!"{location}.library"
    if seen.contains library then
      throw <| IO.userError s!"manifest-schema: duplicate library '{library}'"
    let executables ← match item.getObjVal? "executables" with
      | .error _ => pure #[]
      | .ok value => jsonStringArray s!"{location}.executables" value
    for exe in executables do
      let _ ← targetName "executable" exe s!"{location}.executables"
      if seenExes.contains exe then
        throw <| IO.userError s!"manifest-schema: duplicate executable '{exe}'"
      seenExes := seenExes.push exe
    let claimText ← stringField item "claim" location
    let some claim := Profile.parse? claimText
      | throw <| IO.userError <| s!"manifest-schema: {location}.claim must be one of " ++
          "kernel-only, choice-free, standard-logical"
    if claim == .compilerTrusting then
      throw <| IO.userError <| s!"manifest-schema: {location}.claim must be one of " ++
        "kernel-only, choice-free, standard-logical"
    let execution ← match item.getObjVal? "execution" with
      | .error _ => pure ExecutionClaim.report
      | .ok (.str text) => match ExecutionClaim.parse? text with
        | some mode => pure mode
        | none => throw <| IO.userError <|
            s!"manifest-schema: {location}.execution must be \"report\" or \"checked\""
      | .ok _ => throw <| IO.userError <|
          s!"manifest-schema: {location}.execution must be a string"
    let why ← rationale (← stringField item "rationale" location) location
    seen := seen.push library
    surfaces := surfaces.push { library, executables, claim, execution, rationale := why }
  let mut excludedLibraries : Array ExcludedLibrary := #[]
  for index in [:excludedValues.size] do
    let item := excludedValues[index]!
    let location := s!"excluded-libraries[{index}]"
    let _ ← objectWithKeys item #["library", "rationale"] location
    let library ← targetName "library" (← stringField item "library" location) s!"{location}.library"
    if seen.contains library then
      throw <| IO.userError s!"manifest-schema: duplicate library '{library}'"
    let why ← rationale (← stringField item "rationale" location) location
    seen := seen.push library
    excludedLibraries := excludedLibraries.push { library, rationale := why }
  let mut excludedExecutables : Array ExcludedExecutable := #[]
  for index in [:excludedExeValues.size] do
    let item := excludedExeValues[index]!
    let location := s!"excluded-executables[{index}]"
    let _ ← objectWithKeys item #["executable", "rationale"] location
    let executable ← targetName "executable" (← stringField item "executable" location)
      s!"{location}.executable"
    if seenExes.contains executable then
      throw <| IO.userError s!"manifest-schema: duplicate executable '{executable}'"
    let why ← rationale (← stringField item "rationale" location) location
    seenExes := seenExes.push executable
    excludedExecutables := excludedExecutables.push { executable, rationale := why }
  return { surfaces, excludedLibraries, excludedExecutables }

def libraries (manifest : Manifest) : Array String :=
  manifest.surfaces.map (·.library) ++ manifest.excludedLibraries.map (·.library)

def executables (manifest : Manifest) : Array String :=
  manifest.surfaces.foldl (fun found surface => found ++ surface.executables) #[]
    ++ manifest.excludedExecutables.map (·.executable)

/-- The Lake targets a checker must build so every claimed module is
elaborated and resolvable: each claimed library and claimed executable. -/
def positiveTargets (manifest : Manifest) : Array String :=
  manifest.surfaces.foldl
    (fun targets surface => targets.push surface.library ++ surface.executables) #[]

end StrictLean.Checker.Manifest
