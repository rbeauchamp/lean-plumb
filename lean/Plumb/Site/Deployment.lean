import Lean

/-! # Deployed rule-reference verification

Compares the live GitHub Pages site with the exact artifact the site workflow validated and
uploaded. It imports only Lean's core so the deployment job can run it with the pinned
toolchain alone:

```text
lean --run lean/Plumb/Site/Deployment.lean ARTIFACT_DIR PAGE_URL
```

It requires `PAGE_URL` to be the artifact's recorded site, the live `build.json` to equal the
artifact's bytes (retrying while the deployment propagates), every rule page of every edition
listed in `build.json` to be served with the artifact's exact bytes, and an unpublished route
to be answered with HTTP 404 and the artifact's `404.html`.

## Boundaries

This is an observation of the live site at one time through `curl`, not a proof: GitHub
Pages, its CDN and the network are external. Requests carry a query string so that a cached
copy of an earlier deployment cannot satisfy the comparison.
-/

namespace Plumb.Site.Deployment
open Lean System

private def fail (message : String) : IO α := throw <| IO.userError s!"deployment verification: {message}"

/-- Fetch `url` into `path`; returns the HTTP status (0 when no response). -/
def fetch (url : String) (path : FilePath) : IO Nat := do
  let out ← IO.Process.output { cmd := "curl", args := #["--silent", "--show-error", "--max-time", "60",
    "--output", path.toString, "--write-out", "%{http_code}", url] }
  return out.stdout.trimAscii.toString.toNat?.getD 0

private def field (j : Json) (key : String) : IO Json := IO.ofExcept (j.getObjVal? key)
private def str (j : Json) (key : String) : IO String := do IO.ofExcept (← field j key).getStr?

def run (artifact : FilePath) (pageUrl : String) : IO Unit := do
  let recorded ← IO.FS.readBinFile (artifact / "build.json")
  let build ← IO.ofExcept (Json.parse (← IO.FS.readFile (artifact / "build.json")))
  let site ← str build "site"
  let revision ← str build "revision"
  let pageUrl := if pageUrl.endsWith "/" then pageUrl else pageUrl ++ "/"
  unless pageUrl == site do fail s!"deployed at {pageUrl}, but the artifact is for {site}"
  unless (← field build "dirty") == .bool false do fail "the artifact was built from uncommitted changes"
  let scratch := artifact.parent.getD "." / "deployment-check"
  IO.FS.createDirAll scratch
  let probe := s!"?plumb-deployment={revision}"
  -- The deployment is atomic; wait until the live identity is this artifact's.
  let mut matched := false
  for attempt in [1:21] do
    let status ← fetch (site ++ "build.json" ++ probe) (scratch / "build.json")
    if status == 200 && (← IO.FS.readBinFile (scratch / "build.json")) == recorded then
      matched := true
      break
    IO.println s!"attempt {attempt}: live build.json is not this artifact yet (HTTP {status}); waiting"
    IO.sleep 15000
  unless matched do fail s!"the live site does not serve the artifact of {revision}"
  let editions ← IO.ofExcept ((← field build "editions").getArr?)
  let rules ← IO.ofExcept ((← field build "rules").getArr?)
  let mut checked := 0
  for edition in editions do
    let edition ← IO.ofExcept edition.getStr?
    for rule in rules do
      let route ← str rule "route"
      let file := edition ++ route ++ "index.html"
      let status ← fetch (site ++ edition ++ route ++ probe) (scratch / "page.html")
      unless status == 200 do fail s!"{file}: HTTP {status}"
      unless (← IO.FS.readBinFile (scratch / "page.html")) == (← IO.FS.readBinFile (artifact / file)) do
        fail s!"{file}: live bytes differ from the validated artifact"
      checked := checked + 1
  let status ← fetch (site ++ "v/0.0.0-unpublished/rules/PL1001/" ++ probe) (scratch / "missing.html")
  unless status == 404 do fail s!"unpublished route answered HTTP {status}, expected 404"
  unless (← IO.FS.readBinFile (scratch / "missing.html")) == (← IO.FS.readBinFile (artifact / "404.html")) do
    fail "unpublished route did not serve the artifact's not-available page"
  IO.FS.removeDirAll scratch
  IO.println s!"deployment verification: PASS ({site} serves the artifact of {revision}: build.json, {checked} rule pages, not-available page); an observation at this time, not a guarantee of availability"

end Plumb.Site.Deployment

def main (args : List String) : IO UInt32 := do
  match args with
  | [artifact, pageUrl] => Plumb.Site.Deployment.run artifact pageUrl; return 0
  | _ => IO.eprintln "usage: lean --run lean/Plumb/Site/Deployment.lean ARTIFACT_DIR PAGE_URL"; return 2
