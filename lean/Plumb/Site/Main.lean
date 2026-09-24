import Plumb.Site.Artifact

/-! Command-line entrypoint of the rule-reference site builder (`lake exe site`). -/

open System

/-- `site build --out DIR --evidence SHARD...` builds and checks the Pages artifact. -/
def main (args : List String) : IO UInt32 := do
  match args with
  | "build" :: "--out" :: out :: "--evidence" :: evidence@(_ :: _) =>
    Plumb.Site.Build.build (evidence.map FilePath.mk) out
    return 0
  | _ =>
    IO.eprintln "usage: lake exe site build --out DIR --evidence SHARD.json [SHARD.json ...]"
    return 2
