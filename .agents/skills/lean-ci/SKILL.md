---
name: lean-ci
description: Diagnose and reduce slow Lean 4 CI or verification runs while preserving their proof, admission, and coverage contracts.
---

# Lean CI

Make the required verification finish efficiently without changing what its success
establishes. Read the repository's actual acceptance command, pins and cold-build/cache
rules; this skill supplies no universal deadline, runner choice or worker count.

## Locate the work before changing it

Bind the failure to its commit, command, environment and completed stages. Distinguish
toolchain/dependency provisioning, root compilation, source elaboration, imports, kernel
admission, policy evaluation, serialization and downstream qualification. Trace the timer's
start and stop in its owner: a line labelled “detector” may include a fresh Lake build and
several child processes while excluding a subsequent receipt qualifier. Native editor
snapshot latency and a pure predicate's cost are different measurements.

A deadline kill identifies unfinished work, not its physical cause. Preflight free memory
and CPU count do not establish utilization or peak memory during the run. Use existing
phase evidence first; if attribution remains material, choose a bounded observation that
can distinguish the candidate causes. Do not keep rerunning the whole suite hoping for a
faster sample.

## Remove repeated work with an explicit preservation argument

- For an expensive decision procedure, look for a cheaper decision of the **same
  proposition**. Connect its proof to the executed admission callers. Replacing repeated
  membership scans with lawful indices, or normalization equality with an equivalent
  order check, must retain missing-element, duplicate and ordering refusals.
- Check repeated compiler startup, source elaboration and broad imports. A stable receipt
  qualifier can be a Lake-built executable of the same entrypoint rather than `lean --run`
  for every record. Preserve initialization, interpreter/dynamic-evaluation requirements,
  target classification, source identity and all positive/refusal controls. Compilation
  does not prove the compiler or binary correct.
- Repeated `lake env` calls can reload an unchanged workspace. If reusing its actual
  environment within one invocation, bind reuse to the parent environment and fixed
  workspace/pins. Preserve executable resolution, arguments, cwd, separate compiler
  children, timeouts and changed import paths; never reconstruct paths or reuse verdicts.
  Compare all original controls under both launchers on the supported host. Keep inherited
  environment values out of logs, and do not transfer measured speedups across platforms.
- Compare configured concurrency with the actual queues and inner caps. Increase useful
  parallelism only where environment/scratch ownership, result association and lifetimes
  permit it; account for simultaneous memory demand. Sharing immutable imported regions
  is different from sharing mutable environments or an executable's ownership closure.
- Hoist immutable source-derived work out of per-record loops: coordinate checks can
  share one source-line split per transcript. Prove equality to the original executed
  predicate, and inspect generated code to confirm the compiler retains the sharing.
  A `let` inside a proposition may disappear during `Decidable` synthesis; put shared
  computation in the executable decision and transfer it by definitional equality or proof.
- Trace growing-prefix serialization and repeated hashing/import setup. Reuse data only
  within its valid identity and lifetime. Moving output to a terminal boundary must retain
  required evidence on normal, typed-refusal and exceptional exits; an interrupted or
  partial run must not leave a current successful receipt.

For concrete precedents and their limits, read [the evidence notes](references/evidence.md)
only when one of these changes is relevant. They are examples, not a prescribed itinerary.

## Preserve the acceptance boundary

Cache artifacts under the identities the project requires, such as toolchain, dependency
lock, platform and architecture. Dependency provisioning outside a cold-root gate does
not permit root-output or accepted-verdict reuse. Do not remove forced reconfiguration
unless the remaining source/toolchain/configuration validation justifies that reuse.

When sharing a prerequisite build across audit stages, freeze its required source,
configuration and dependency observations before the build, carry those same observations
to every consumer, and recheck their inventories as well as bytes before acceptance, including zero-item
branches. Review this as a finite entrypoint-by-input-class table when several adapters
share the build. A post-build capture cannot bind
earlier artifacts to their inputs. Use Lake-resolved source domains rather than Git's
tracked/untracked lists alone: ignored generated inputs and inventory changes still matter.

Keep ownership, standalone roots, source freshness, warning handling, admission and exact
negative reasons intact. Qualification observations complement implementation-linked
proofs; samples do not replace them. Retain controls until their purpose and replacement
coverage are accounted for.

After a repair, run the affected checks and the repository's complete required gate on the
reviewed head. Reuse unchanged evidence with its original identity and a stated relevant-input
argument; rerun invalidated claims. Report local and hosted outcomes separately, including
failed attempts and unavailable stages. A faster isolated phase, larger timeout or a
different runner is not evidence that the original whole-run requirement passed. Follow
the repository's review and delivery rules; this skill adds no publication authority.
For merged delivery, also reconcile the main push workflow for the actual merge SHA.
A passing PR-head or synthetic-merge run does not establish that post-merge execution
passed, even for identical trees. Report failed, skipped or unfinished main stages as
unresolved; do not infer a physical slowdown cause from the deadline kill alone.
