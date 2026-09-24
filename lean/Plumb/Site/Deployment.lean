import Lean

/-! # Deployed rule-reference verification

Gates and verifies publication of the artifact the CI `site` job validated. It imports only
Lean's core so the deployment jobs can run it with the pinned toolchain alone:

```text
lean --run lean/Plumb/Site/Deployment.lean gate ARTIFACT_DIR     # before deploying
lean --run lean/Plumb/Site/Deployment.lean verify ARTIFACT_DIR   # after deploying
```

`gate` (in the unprivileged `deploy-gate` job) requires the artifact to be built from a clean
checkout of `GITHUB_SHA` and that commit to still be the head of `main` (`git ls-remote`), so a
re-run of an older run cannot publish over a newer revision; the privileged deploy job repeats
the head check without Lean. A newer push after the gate is still deployed later, because each run on `main`
cancels older ones and deployments are serialized. `verify` requires `PLUMB_PAGE_URL` to be the
artifact's recorded site, the live `build.json` to equal the artifact's bytes (retrying while the
deployment propagates), every rule page of every edition listed in `build.json` to be served with
the artifact's exact bytes, and an unpublished route to be answered with HTTP 404 and the
artifact's `404.html`. It compares only those files.

## Boundaries

These are observations at one time through `git` and `curl`, not proofs: GitHub, Pages, its
CDN and the network are external. Requests carry a per-attempt query string so that a cached
copy is unlikely to satisfy the comparison; whether the CDN keys on it is not established.
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

private def env (name : String) : IO String := do
  match ← IO.getEnv name with
  | some v => if v.isEmpty then fail s!"{name} is empty" else pure v
  | none => fail s!"{name} is not set"

/-- Refuse to publish unless the artifact is a clean build of `GITHUB_SHA` and that commit is
still the head of `main`. -/
def gate (artifact : FilePath) : IO Unit := do
  let build ← IO.ofExcept (Json.parse (← IO.FS.readFile (artifact / "build.json")))
  let sha ← env "GITHUB_SHA"
  unless (← field build "dirty") == .bool false do fail "the artifact was built from uncommitted changes"
  unless (← str build "revision") == sha do fail s!"the artifact is for {← str build "revision"}, not {sha}"
  let repository := (← env "GITHUB_SERVER_URL") ++ "/" ++ (← env "GITHUB_REPOSITORY")
  let out ← IO.Process.output { cmd := "git", args := #["ls-remote", repository, "refs/heads/main"] }
  unless out.exitCode == 0 do fail s!"cannot read the head of main: {out.stderr}"
  let head := ((out.stdout.splitOn "\t").headD "").trimAscii.toString
  unless head == sha do fail s!"main has moved to {head}; not publishing the older {sha}"
  IO.println s!"deployment gate: PASS (clean artifact of {sha}, the current head of main)"

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
    let status ← fetch (site ++ "build.json" ++ probe ++ s!"-{attempt}") (scratch / "build.json")
    if status == 200 then
      if (← IO.FS.readBinFile (scratch / "build.json")) == recorded then
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
  | ["gate", artifact] => Plumb.Site.Deployment.gate artifact; return 0
  | ["verify", artifact] =>
    let some pageUrl ← IO.getEnv "PLUMB_PAGE_URL" | IO.eprintln "PLUMB_PAGE_URL is not set"; return 2
    Plumb.Site.Deployment.run artifact pageUrl; return 0
  | _ => IO.eprintln "usage: lean --run lean/Plumb/Site/Deployment.lean (gate | verify) ARTIFACT_DIR"; return 2
