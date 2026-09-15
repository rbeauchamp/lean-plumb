import StrictLean.Checker.Lake

/-!
Optional serialized-environment qualification. This is separate from ordinary
kernel elaboration and declaration-policy conformance.
-/

namespace StrictLean.Checker.FreshChecker

open Lean System
open StrictLean.Checker

structure ModuleSet where
  library : String
  modules : Array String
  deriving Repr

structure Coverage where
  root : String
  modules : Array String
  deriving Repr

structure Plan where
  moduleSets : Array ModuleSet
  modules : Array String
  roots : Array String
  coverage : Array Coverage
  deriving Repr

structure Check where
  root : String
  coveredModules : Array String
  exitCode : UInt32
  deriving Repr

structure Options where
  manifest : Option FilePath := none
  project : Option FilePath := none
  jsonOut : Option FilePath := none
  planOnly : Bool := false
  failFast : Bool := false
  verbose : Bool := false
  help : Bool := false

private def usage : String :=
  "usage: lake exe freshChecker -- [--project DIR] [--manifest PATH] [--json-out PATH] " ++
  "[--plan-only] [--fail-fast] [--verbose]"

private partial def parseArgs : List String → Options → IO Options
  | [], options => return options
  | "--" :: rest, options => parseArgs rest options
  | "--manifest" :: value :: rest, options =>
      parseArgs rest { options with manifest := some (FilePath.mk value) }
  | "--project" :: value :: rest, options =>
      parseArgs rest { options with project := some (FilePath.mk value) }
  | "--json-out" :: value :: rest, options =>
      parseArgs rest { options with jsonOut := some (FilePath.mk value) }
  | "--plan-only" :: rest, options => parseArgs rest { options with planOnly := true }
  | "--fail-fast" :: rest, options => parseArgs rest { options with failFast := true }
  | "--verbose" :: rest, options => parseArgs rest { options with verbose := true }
  | "--help" :: rest, options | "-h" :: rest, options =>
      parseArgs rest { options with help := true }
  | flag :: _, _ => throw <| IO.userError s!"unknown or incomplete argument: {flag}"

private def resolve (repo path : FilePath) : FilePath :=
  if path.isAbsolute then path else repo / path.toString

private def uniqueSorted (values : Array String) : Array String :=
  values.foldl (fun found value => if found.contains value then found else found.push value) #[]
    |>.qsort (· < ·)

private def coverageFor (root : String) (imports modules : Array String) : Array String :=
  uniqueSorted <| (#[root] ++ imports).filter modules.contains

def buildPlan (repo manifestPath : FilePath) : IO Plan := do
  let manifest ← Manifest.load manifestPath
  let inventory ← Lake.surfaceInventory repo
  let mut moduleSets : Array ModuleSet := #[]
  for surface in manifest.surfaces do
    let some library := inventory.libraries.find? (·.library == surface.library)
      | throw <| IO.userError s!"lake-query-malformed: auditPlan omitted {surface.library}"
    let mut modules := library.modules
    for exeName in surface.executables do
      let some exe := inventory.executables.find? (·.executable == exeName)
        | throw <| IO.userError s!"lake-query-malformed: auditPlan omitted {exeName}"
      modules := modules.push exe.root
    moduleSets := moduleSets.push {
      library := surface.library
      modules := modules.map (·.toString)
    }
  let modules := uniqueSorted <| moduleSets.foldl (fun all item => all ++ item.modules) #[]
  let mut importSets : Array (String × Array String) := #[]
  for moduleName in modules do
    importSets := importSets.push (moduleName, ← Lake.transitiveImports repo moduleName)
  let mut roots : Array String := #[]
  for moduleName in modules do
    let importedByAnother := importSets.any fun (other, imports) =>
      other != moduleName && imports.contains moduleName
    if !importedByAnother then roots := roots.push moduleName
  roots := roots.qsort fun left right =>
    let leftImports := (importSets.find? (·.1 == left)).map (·.2) |>.getD #[]
    let rightImports := (importSets.find? (·.1 == right)).map (·.2) |>.getD #[]
    let leftSize := (coverageFor left leftImports modules).size
    let rightSize := (coverageFor right rightImports modules).size
    leftSize < rightSize || (leftSize == rightSize && left < right)
  let mut coverage : Array Coverage := #[]
  for root in roots do
    let imports := (importSets.find? (·.1 == root)).map (·.2) |>.getD #[]
    coverage := coverage.push { root, modules := coverageFor root imports modules }
  let covered := uniqueSorted <| coverage.foldl (fun all item => all ++ item.modules) #[]
  if covered != modules then
    let missing := modules.filter fun moduleName => !covered.contains moduleName
    throw <| IO.userError s!"fresh-coverage-incomplete: no selected root covers {repr missing.toList}"
  return { moduleSets, modules, roots, coverage }

private def planJson (plan : Plan) (checks : Array Check) : Json :=
  Json.mkObj [
    ("moduleSets", Json.mkObj <| plan.moduleSets.toList.map fun item =>
      (item.library, Json.arr <| item.modules.map Json.str)),
    ("modules", Json.arr <| plan.modules.map Json.str),
    ("roots", Json.arr <| plan.roots.map Json.str),
    ("coverage", Json.mkObj <| plan.coverage.toList.map fun item =>
      (item.root, Json.arr <| item.modules.map Json.str)),
    ("checks", Json.arr <| checks.map fun check => Json.mkObj [
      ("root", Json.str check.root),
      ("coveredModules", Json.arr <| check.coveredModules.map Json.str),
      ("exitCode", Json.num check.exitCode.toNat)
    ])
  ]

unsafe def run (args : List String) : IO UInt32 := do
  let options ← parseArgs args {}
  if options.help then IO.println usage; return 0
  let repo ← match options.project with
    | some dir => findRepoRoot dir
    | none => repoRoot
  let manifestPath := options.manifest.map (resolve repo) |>.getD (Manifest.defaultPath repo)
  let plan ← buildPlan repo manifestPath
  let mut checks : Array Check := #[]
  let mut failures : Array String := #[]
  if !options.planOnly then
    let manifest ← Manifest.load manifestPath
    if let some lines ← Lake.buildChecked repo (Manifest.positiveTargets manifest) "incrementally" then
      for line in lines do IO.println s!"    {line}"
      return 1
    for root in plan.roots do
      let covered := (plan.coverage.find? (·.root == root)).map (·.modules) |>.getD #[]
      if options.verbose then
        IO.println s!"fresh root {root}: covers {", ".intercalate covered.toList}"
      let result ← runProcess repo "lake" #["env", "leanchecker", "--fresh", root]
      checks := checks.push { root, coveredModules := covered, exitCode := result.exitCode }
      if !result.succeeded then
        let tail := "\n".intercalate (takeLast 20 (outputLines result.output)).toList
        failures := failures.push s!"fresh-check-failed: {root}: {tail}"
        if options.failFast then break
  if let some path := options.jsonOut then
    writeJson (resolve repo path) (planJson plan checks)
  IO.println s!"Lake modules: {plan.modules.size}   fresh roots: {", ".intercalate plan.roots.toList}"
  if !failures.isEmpty then
    IO.println s!"FAIL: {failures.size} fresh-check violation(s)"
    for failure in failures do IO.println s!"  {failure}"
    return 1
  if options.planOnly then
    IO.println "fresh checker plan: PASS — exact Lake coverage reconciled"
  else
    IO.println <| "fresh checker: PASS — leanchecker covered exactly " ++
      s!"{plan.modules.size}/{plan.modules.size} claimed modules"
  return 0

end StrictLean.Checker.FreshChecker

unsafe def main (args : List String) : IO UInt32 := do
  try
    StrictLean.Checker.initializeLeanSearchPath
    StrictLean.Checker.FreshChecker.run args
  catch error =>
    IO.eprintln s!"FAIL: {error}"
    return 1
