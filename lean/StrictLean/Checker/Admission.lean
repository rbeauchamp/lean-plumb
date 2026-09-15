import Lean.Replay
import StrictLean.Probe

/-!
Checked logical admission before report construction. The replay base contains
only imported modules outside the owned inventory. Unsafe and partial entries
remain subject to generated-role policy; they cannot supply logical evidence.
-/

namespace StrictLean.Checker.Admission

open Lean

/-- Replay the completed owned logical declarations against trusted imports.
The original environment is retained for compiler metadata only after replay
succeeds. This is not a fresh replay of the imported dependency graph. -/
unsafe def validate (env : Environment) (ownedModules : Array Name) : IO Unit := do
  let mut replayModules := ownedModules
  -- The force-loaded reporter now depends on the positive policy library.
  -- Replay these exact checker implementation modules too; importing them into
  -- the base would reintroduce unchecked owned policy declarations. They do not
  -- become claimed surfaces, and arbitrary reverse imports remain forbidden.
  let reporterModules := #[`StrictLean.Probe, `StrictLean.Report,
    `StrictLean.Checker.PolicyCodec, `StrictLean.StructuralName]
  for _ in [:reporterModules.size] do
    for (name, data) in env.header.moduleNames.zip env.header.moduleData do
      if reporterModules.contains name && !replayModules.contains name &&
          data.imports.any (fun imp => replayModules.contains imp.module) then
        replayModules := replayModules.push name
  let owned := replayModules.foldl (fun names name => names.insert name) ({} : NameSet)
  let mut declarations : Std.HashMap Name ConstantInfo := {}
  for (name, info) in StrictLean.Probe.ownedConstants env replayModules.toList do
    declarations := declarations.insert name info
  let mut imports : Array Import := #[]
  for (name, data) in env.header.moduleNames.zip env.header.moduleData do
    if owned.contains name then continue
    -- Importing such a module would put unchecked owned declarations back in
    -- the trusted base. Ownership must be expanded or the claim rejected.
    if data.imports.any (fun imp => owned.contains imp.module) then
      throw <| IO.userError s!"[VIOLATION[kernel-admission]] unowned module {name} imports an owned module"
    imports := imports.push { module := name, importAll := true }
  let base ← importModules imports {} 0 (loadExts := false) (level := .private)
  try
    for (name, _) in declarations do
      if (base.toKernelEnv.find? name).isSome then
        throw <| IO.userError s!"owned declaration {name} already exists in replay base"
    let checked ← base.replay declarations
    for (name, info) in declarations do
      if !info.isUnsafe && !info.isPartial && (checked.toKernelEnv.find? name).isNone then
        throw <| IO.userError s!"missing replayed declaration {name}"
  catch error =>
    throw <| IO.userError s!"[VIOLATION[kernel-admission]] {error}"
  finally
    -- No replay environment escapes this function. Release its separately
    -- imported regions, as Lean's bundled replay checker does.
    base.freeRegions

end StrictLean.Checker.Admission
