# Corpus slots share immutable dependency roots, 2026-09-22

Delivery remains **INCOMPLETE**. This contract change replaces the physically
separate per-slot copies of Lake dependency packages (introduced in `f56a011`) with
shared original dependency roots and a fail-closed content-level no-writer check.
Firstmate authorized it (msgs 189 and 190) after the retained evidence below showed that
per-slot copies could not fit the hosted runner. It needs independent re-review. The
hosted route for the rule-examples step is still undecided. No full corpus campaign, no
no-mistakes run and no CI change was made.

## Why

- Each slot copied the root package and every dependency build tree: 7.61 GiB measured,
  about 135k files, mostly Mathlib's 6.6 G.
- Locally, APFS clones hid the byte cost but not the time: preparation took 77 s and
  slot cleanup 22.6 s in the passing `1c7304b` corpus run.
- On the hosted `ubuntu-24.04` runner, `cp -c` is not a clone, so five slots would
  need about 38 GiB of real copies against a documented 14 GB SSD.

## Change

- **`Slot.prepareSlot`** still makes a private writable copy of the ROOT package:
  sources and configuration are compared byte-exactly, and `.lake/build` and
  materialized Git are copied.
  - The ROOT manifest is relocated so every package entry names its captured
    canonical dependency root (`DependencyObservation.root`).
  - A manifest package without a captured dependency refuses.
  - Each dependency's captured revision is rechecked with `git rev-parse HEAD` in
    its shared root.
  - Dependencies are recorded in slot provenance as `shared`.
- **`Slot.checkContainment`** still requires the Git resolution to stay inside the
  slot. It admits a manifest `dir` only if it lies inside the slot or resolves
  exactly to a captured shared root.
- **`Slot.sharedIdentity`** walks every entry under every shared root with
  `symlinkMetadata`, without following symlinks. It records:
  - the relative path and kind;
  - for regular files, the exact byte length and the pinned native
    `ByteArray.hash` of the full contents;
  - for symlinks, their resolution.
  Entries are sorted by path. Reads run in eight chunks, and every task joins before
  the first error surfaces.
- **`RuleExamples.check`** captures that identity after slot preparation and before
  any producer starts. After every producer, admission, terminal qualifier, raw
  validation and checker-source equality has completed, it recaptures the identity
  and requires equality before slot cleanup, parent cleanup and PASS. A difference
  refuses the run, naming the first differing path.
- Unchanged:
  - all 65 productions, 79 admissions and 72 raw validations;
  - job order and refusal order;
  - the INCOMPLETE baseline;
  - both cleanups before PASS;
  - the hard 420 s limit;
  - the separate producer and history gates;
  - cold ordinary acceptance.

## Writers during the window, derived from pinned Lake v4.34.0 source

- `Lake/Load/Lean/Elab.lean` `importConfigFile` stores configuration oleans, traces
  and locks under `LoadConfig.configDir = wsDir/.lake/config/<pkgIdx>`
  (`Lake/Load/Config.lean`). That is the fixture workspace in scratch, not the
  dependency.
- Path-class manifest entries materialize in place, with no fetch.
- Producer children run with `GIT_OPTIONAL_LOCKS=0` and `LAKE_CACHE_DIR=''`.
- Rule examples import only `Init`, `Lean`, the vendored fixture dependency and
  `StrictLean.*`. Those are built in the private ROOT copy.
- A stale dependency trace would make Lake write under a shared root. The identity
  check detects that; it does not prevent it.

This source argument is supporting evidence. The executed identity equality is the
guard.

## Trust boundary (explicit)

The check detects writes; it does not prevent them. A portable read-only view would
need one of two things:

- mutating the caller's dependency permissions, which a deadline SIGKILL could leave
  behind; or
- platform-specific sandboxing that would change the recorded producer command.

So neither is used. The following remain trusted:

- **Concurrent writers outside the run.** An external writer that changes a shared
  root and restores it within the window is not observed.
- **Filesystem honesty.**
- **The digest's strength.** A 64-bit non-cryptographic hash plus exact length
  detects accidental changes, not adversarial collisions.

A write by a producer that is later reverted before the second capture is also not
observed.

## Focused local evidence at worktree over `a6d3547`

- `lake build qualify` passed (169 jobs; `warningAsError`).
- One `gtimeout --signal=KILL 180s env GIT_OPTIONAL_LOCKS=0 lake exe qualify
  prep-measure` run passed in 19.84 s wall (`tmp/prep-measure-optionA.log`):
  - five-slot preparation took 1,249 ms, against about 77 s before;
  - one shared identity capture took 6,873 ms over 149,621 entries;
  - a second capture with no writer in between was equal;
  - scratch removal was verified.
- The adversarial probe `lake env lean --run tmp/SharedIdentityProbe.lean` passed on
  an owned scratch tree:
  - the identity was stable across widths 1 and 3;
  - it detected a same-length content rewrite, an addition, a removal, an empty
    directory, a symlink retarget and a file-to-directory retype;
  - every restoration compared equal again.

These are scoped observations, not a full corpus result, a deadline claim or hosted
evidence. Lean 4.34.0 and Mathlib `5ed2965256430c3649e86755f9576b54eca72435` remain
pinned.
