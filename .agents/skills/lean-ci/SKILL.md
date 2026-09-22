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
When timing pure work lifted into IO, suspend it with `IO.lazyPure`: an eager
`IO.ofExcept expensiveResult` can compute the result before the timer starts.
Inspect generated calls to confirm the measured work remains inside the timed action.

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
  Pairwise distinctness can use set cardinality only after proving equivalence to
  the original predicate. Deduplicating input alone would silently accept duplicates;
  lawful hash-set equality must still distinguish colliding keys.
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
- A prebuild does not make later Lake invocations read-only. Before parallelizing
  fixture roots, inspect shared module outputs, trace/hash sidecars, artifact caches and
  Git metadata as well as workspace configuration. Separate scratch directories with
  shared dependency symlinks do not prove disjoint writes; distinguish a possible write
  from an observed race. Killing a direct child does not establish descendant compiler
  quiescence before scratch deletion. Keep deadline ownership and process containment
  explicit; after outer SIGKILL, user-space cleanup cannot run.
- Hoist immutable source-derived work out of per-record loops: coordinate checks can
  share one source-line split per transcript. Prove equality to the original executed
  predicate, and inspect generated code to confirm the compiler retains the sharing.
  A `let` inside a proposition may disappear during `Decidable` synthesis; put shared
  computation in the executable decision and transfer it by definitional equality or proof.
- Before instantiating large natural powers, inspect the elaborated `Pow`/`NPow`
  instances in the helper bound, auxiliary proof **and final implementation goal**.
  Different instance paths can force expensive ground reduction during matching.
  Prove their correspondence at a symbolic exponent first; keep positivity, regrouping
  and quotient bounds parameterized until that bridge exists. In a checked Acorn
  arithmetic development the symbolic bridge was reflexive; this does not establish
  equality of arbitrary instances, execution reachability, liveness or runtime benefit.
  Raising reduction limits or changing domains is not a substitute for the bridge.
- Trace growing-prefix serialization and repeated hashing/import setup. Reuse data only
  within its valid identity and lifetime. Moving output to a terminal boundary must retain
  required evidence on normal, typed-refusal and exceptional exits; an interrupted or
  partial run must not leave a current successful receipt.
  For large machine-consumed JSON, profile pretty-print layout separately from collection
  and parsing. If only parsed JSON values are contractual, the pinned compact serializer
  avoids that layout work. Qualify parsed-value and protocol equivalence, including exact
  source strings; smaller output alone does not establish correctness.

For concrete precedents and their limits, read [the evidence notes](references/evidence.md)
only when one of these changes is relevant. They are examples, not a prescribed itinerary.

## Preserve the acceptance boundary

Cache artifacts under the identities the project requires, such as toolchain, dependency
lock, platform and architecture. Dependency provisioning outside a cold-root gate does
not permit root-output or accepted-verdict reuse. Do not remove forced reconfiguration
unless the remaining source/toolchain/configuration validation justifies that reuse.

Treat elaboration-captured provenance as a build input: Git HEAD/dirty state, generated
configuration and other embedded identity can change the request even when source bytes
match. Record the identity actually compiled and rebuild when it changes. Code-byte
correspondence permits only the evidence reuse justified by that claim; it does not make
an old Accepted artifact evidence for a new request or a dirty run an exact published-head run.

When sharing a prerequisite build across audit stages, freeze its required source,
configuration and dependency observations before the build, carry those same observations
to every consumer, and recheck their inventories as well as bytes before acceptance, including zero-item
branches. Review this as a finite entrypoint-by-input-class table when several adapters
share the build. A post-build capture cannot bind
earlier artifacts to their inputs. Use Lake-resolved source domains rather than Git's
tracked/untracked lists alone: ignored generated inputs and inventory changes still matter.

When concurrent workers share an immutable input tree instead of private copies, state its
no-writer requirement and enforce it at the write boundary where a portable mechanism
exists. Otherwise take a content-level identity (every entry's path, `lstat` kind, length
and full-content digest; no mtimes or listings alone) before any worker starts, and require
equality after every worker has been joined. State what remains trusted: concurrent external
writers, filesystem honesty and digest strength. Size private copies against hosted disk,
memory and vCPU before relying on local copy-on-write or page-cache behavior.

Keep ownership, standalone roots, source freshness, warning handling, admission and exact
negative reasons intact. Qualification observations complement implementation-linked
proofs; samples do not replace them. Retain controls until their purpose and replacement
coverage are accounted for.

After a repair, run the affected checks and the repository's complete required gate on the
reviewed head. Reuse unchanged evidence with its original identity and a stated relevant-input
argument; rerun invalidated claims. Report local and hosted outcomes separately, including
failed attempts and unavailable stages. A sub-suite PASS inside an unfinished aggregate
is only scoped evidence. An explicitly approved split into separate diagnostic budgets changes the resource contract while
retaining coverage; it does not establish the old aggregate passed.
A faster isolated phase, larger timeout or a
different runner is not evidence that the original whole-run requirement passed. Follow
the repository's review and delivery rules; this skill adds no publication authority.
For merged delivery, also reconcile the main push workflow for the actual merge SHA.
A passing PR-head or synthetic-merge run does not establish that post-merge execution
passed, even for identical trees. Report failed, skipped or unfinished main stages as
unresolved; do not infer a physical slowdown cause from the deadline kill alone.
