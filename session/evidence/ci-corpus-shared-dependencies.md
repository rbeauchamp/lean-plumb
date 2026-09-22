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

This section describes `86d417a`. The capture-once delta below adds write protection.

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

## Capture once (captain decision msg 192), on top of `86d417a`

Independent review cleared the `a6d3547..86d417a` delta. This delta folds in its P3
item (stale slot comments). The captain chose "capture once".

### Change

- **Write protection.** `Slot.protectShared` first saves an owned ledger
  (`tmp/rule-examples-shared-protection.json`). The ledger lists every non-symlink
  entry that already lacked user write permission. Then `chmod -R u-w` runs on each
  shared root, and the run fails if any non-symlink entry is still user-writable.
  - `Slot.unprotectShared` runs `chmod -R u+w`, then re-applies `u-w` to exactly the
    ledger's entries.
  - Before removing the ledger, it requires the restored exception set to equal the
    ledger's exactly.
  - It runs on every exit of the campaign action: after slot cleanup, before parent
    cleanup and PASS.
  - A ledger left by SIGKILL is restored at the next campaign start.
- **One capture.** Inside the protected window the runner makes one complete
  `Snapshot.dependenciesCaptures`. The captured roots must equal the captured
  dependency roots.
  - The runner saves only the Git facts (`Snapshot.GitFacts`: package, canonical root,
    ordered source/configuration paths, revision, dirty) to the owned scratch file
    `injected-git-facts.json`.
  - Then it takes the content identity, and only then starts the producers.
- **Internal entry.** Producers run `ruleExamples --injected-git-facts FACTS
  [axiomGate] ARGS`.
  - `axiomGate`'s old `main` body is now `AxiomGate.entry`. The user-facing executable
    root `AxiomGateMain` calls only that and never installs facts.
  - `ruleExamples` installs the facts (a malformed, empty or repeated table refuses
    with exit 2), then runs `AxiomGate.entry` or its own modes unchanged.
- **Detector capture.** `Snapshot.captureDependency` always reads every source and
  configuration byte.
  - It uses an injected pair only when `GitFacts.answers` matches the exact request.
    Otherwise it observes Git itself.
  - Processes with an empty table print nothing new.
- **Run-end recheck.** After producers, admissions, qualifier, raw validation and
  checker-source equality, the runner reruns the product's
  `Snapshot.inputsUnchanged inventory` on the once-captured value: fresh Lake
  inventory, fresh reads, fresh Git, legacy `terminalBeq`. Then it requires the
  content identity to be equal.

### Equality argument

- `Snapshot.assemble_facts_eq` holds by `rw`: the same request and fresh reads plus
  equal Git facts give the identical `DependencyCaptures`.
- `stateOfCore_congruence` then gives the identical request state, and therefore
  identical request and report bytes.
- The premise that the injected facts equal what the producer would observe itself is
  the no-writer invariant, not a theorem about Git:
  - same-user writes are refused (write protection);
  - any content change fails the run (identity equality);
  - the facts are re-observed at run end.
- Git's own configuration outside the shared roots (global or system config, excludes)
  is external state, trusted as unchanged during the window.

### Focused evidence (worktree over `86d417a`)

- **Build:** `lake build axiomGate ruleExamples ruleExampleQualification qualify`
  passed (182 jobs).
- **Scoped campaign:** `gtimeout --signal=KILL 420s lake exe qualify rule-examples
  --evidence tmp/ci-capture-once-scoped.json --rules SL1001 SL1002 SL1003 SL1005
  SL4001` gave **PASS**, exit 0, 95.72 s (`tmp/ci-capture-once-scoped.log`, latest
  raw attempt).
  - It covers file/project, policy-negative, a vendored fixture dependency, the SL1005
    specials and documentation modes.
  - Every capturing producer reused the facts for all 9 shared dependencies and observed
    its private `strict_lean` copy.
  - The ledger was removed. The exception set matches the original 102 entries.
- **Earlier attempt:** the first attempt of that command failed only because
  `ruleExampleQualification` was not built. Restoration still ran on that failure path.
- **Same 17 productions, old run versus new:**

  | Measure | Before (`1c7304b`) | After | Change |
  | --- | --- | --- | --- |
  | Detector wall | 317.8 s | 205.2 s | −35.4% |
  | Dependency-snapshot capture | 149.5 s | 32.0 s | −79% |

  Other detector phases are unchanged.
- **Fixed window costs, local:**

  | Step | Time |
  | --- | --- |
  | Protection | 5.2 s |
  | Identity before | 4.9 s |
  | Terminal recheck | 4.8 s |
  | Identity after | 5.5 s |
  | Restoration | about 5 s |

- **Protection probe** (`lake env lean --run`, owned scratch):
  - These were refused with EACCES: overwrite, create file, create directory, remove,
    write through a symlink, and a second protection while a ledger is active.
  - Recovery restored writability exactly and kept an original read-only file
    read-only.
  - A corrupt ledger naming a missing entry refused restoration and kept the ledger.
- **User-facing refusal:** `axiomGate --injected-git-facts …` exits 1 with "unknown or
  incomplete argument". `ruleExamples` refuses a malformed or empty facts table with
  exit 2.

### Hosted bound on paper (msg 192, item 5)

- **Ratios:** per-phase hosted/local, as recorded in Firstmate's
  `option-a-hosted-bounds.md`. Central value 1.44; whole-command value 1.72.
- **Detectors:** the dependency-snapshot phase scales by 32.0 / 149.5. That gives
  hosted detector work of about 1155 CPU-s at 1.44, or about 1292 at 1.72 applied to
  751 local s.
- **Non-detector work:** protection and restoration, two identity passes, the
  once-capture and terminal recheck, preparation, consumer parse/digest (41 s local),
  raw validation and prerequisites. That is about 85 s local, or about 145 s hosted,
  plus about 28 s of hosted startup.
- **Totals:**

  | Ratio | Total | Against 4 × 420 = 1680 |
  | --- | --- | --- |
  | 1.44 | ≈ 1330 CPU-s | 21% margin |
  | 1.72 | ≈ 1465 CPU-s | 13% margin |

- **Wall estimate:** about 84 s of serial phases run at one core, plus the remaining
  work over 4 vCPU. That is about 390 s, a 7% margin against 420.
- **Open hosted risks:**
  - Two identity passes read all 7.6 GB of the shared trees. Hosted disk throughput and
    page-cache residency are unmeasured, and cold reads could add tens of seconds.
  - If 4 vCPU means 2 SMT cores, effective capacity is about 1090 and the bound fails.
- These are paper estimates from retained receipts, not hosted evidence.
