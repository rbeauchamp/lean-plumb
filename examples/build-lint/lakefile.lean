import Lake
open Lake DSL

package build_lint_adopter where
  -- `lake lint` runs the Plumb driver over every manifested surface.
  lintDriver := "plumb/lint"

require plumb from "../.."

lean_lib Widget where
  globs := #[.andSubmodules `Widget]

/-- The sole default target: build the tool, then build and inspect every
manifested surface. The job deliberately has no cached success artifact. -/
@[default_target]
target policy pkg : Unit := do
  let some checkerPackage ← findPackageByName? `plumb
    | error "build policy: missing plumb dependency"
  let some checker := checkerPackage.findLeanExe? `axiomGate
    | error "build policy: missing axiomGate executable"
  let binary ← checker.fetch
  binary.mapM fun path => do
    let result ← IO.Process.output {
      cmd := path.toString
      args := #["--build-lint", "--project", pkg.dir.toString]
      cwd := some pkg.dir }
    if result.exitCode != 0 then error s!"{result.stdout}{result.stderr}"
    logInfo result.stdout
