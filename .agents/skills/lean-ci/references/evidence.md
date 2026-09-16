# Lean CI precedents and limits

These records explain why a technique was useful, not a latency promise for another
project. Strict Lean's current policy is owned by [AGENTS.md](../../../../AGENTS.md)
and [verify.sh](../../../../scripts/verify.sh). Consult their current contents rather
than copying a historical budget from this file.

## Strict Lean: distinguish decisions, scheduling and orchestration

The [issue-13 CI and responsiveness record](../../../../session/evidence/issue-13-corpus-ci-responsiveness.md)
binds the following observations to their exact revisions and commands.

1. **Equivalent canonical-set decisions.** `StrictLeanPolicy/Collections.lean` proves
   adjacent strict ordering equivalent to the existing normalization equality under its
   comparator hypotheses. `Domain.lean` installs those decisions for actual name/edge
   admission conditions. This removes sorting/deduplication from that decision without
   changing its proposition. The structural bound is at most `max(n-1,0)` comparisons;
   comparing structured names still has input-dependent cost. Compiled caller inspection
   and focused duplicate/order controls qualified execution; the proofs do not verify
   machine code. This change alone did not bring hosted acceptance within its deadline.
2. **An inner worker cap.** Ordinary documentation checking passed `jobs=4`, but inspection
   imposed `min jobs 2`. Removing that extra cap retained isolated child environments,
   unique scratch and results associated with their original indices. It reduced one local
   inspection observation from 63.301s to 43.627s. Whole hosted ordinary acceptance then
   completed, but a downstream corpus campaign still timed out. Neither the speedup nor
   sufficient memory is universal.
3. **Repeated qualifier elaboration.** The corpus called `lake env lean --run
   RuleExampleQualification.lean` after each produced receipt. A native executable of
   that unchanged entrypoint removed repeated elaboration; its Lake target, tooling
   classification and build instructions changed together. On the same complete export,
   interpreted and native invocations returned identical successful output in 17.18s and
   1.22s respectively. The final hosted run completed all required stages; this is not a
   proof that arbitrary native/interpreted programs are equivalent.
4. **Terminal source-account output.** The producer retains captured sources in memory
   and serializes at terminal boundaries instead of repeatedly serializing every growing
   prefix. Every required terminal path still carries its captured evidence, including
   failure paths. See [engine producers](../../../../docs/guides/engine-producers.md).
   Before/after equality does not authenticate the process or exclude change-and-restore.

The corpus's displayed `detectorSeconds` brackets the fresh checker subprocess, including
nested builds, fence compilation/import/admission and result serialization as applicable.
Fixture setup, Python export and the subsequent qualifier are outside that timer.
For example, SL4001's orphan-marker fixture also has a valid Lean fence: the documentation
driver checks that fence before emitting its structural finding. Seconds for that complete
invocation do not measure the scanner alone. The separate native-editor observations
use already-live snapshots and provisioned imports, not fresh project admission.

## Strict Lean: invocation-local Lake environment capture

The [launcher repair record](../../../../session/evidence/main-ci-launcher-repair.md)
separates a post-merge420s failure from an observed local overhead reduction. Repeated
`lake env lean` calls loaded an unchanged workspace for each of36 controls. Capturing
the actual environment for each parent-environment state retained individual compiler
children and exact control outcomes. The bounded paired diagnostic compares sources,
arguments, effective environments/executables and outputs; it does not certify fresh
root inputs or isolate all timing effects. The record marks platform-specific observations
and remaining delivery gates explicitly. Follow the actual post-merge main workflow:
identical trees and green synthetic-merge checks did not establish main CI success.

## Public Acorn: reusable work still needs exact ownership

Public source: [delivered change](https://github.com/rbeauchamp/acorn/pull/4), integrated
at [6d3e95bf](https://github.com/rbeauchamp/acorn/commit/6d3e95bf2dc267436d4b34508d2afd48e1ab11c8).
The [run at 6d3e95bf](https://github.com/rbeauchamp/acorn/actions/runs/35098724752/job/104802455043)
completed its required cold verification in approximately 239s on Ubuntu 24.04.
Logged stage observations were build166.986s, compiled boundary15.057s,
native admission26.100s and combined ownership/axiom/corpus12.403s, plus other overhead.
These are observations of the combined delivered change, not isolated causal estimates.

- [36701b25](https://github.com/rbeauchamp/acorn/commit/36701b255339aea25574209c590383bfcff70638)
  removed forced Lake reconfiguration while retaining validated traces and uncached project
  artifacts, and batched hashing while checking count, digest shape and filename association.
- [e74975d5](https://github.com/rbeauchamp/acorn/commit/e74975d55545e3cd9d2439226b468e2e50949ca3)
  narrowed broad imports and changed target scheduling so independent work could proceed.
  Required preflight still preceded application compilation.
- [48f3c8b0](https://github.com/rbeauchamp/acorn/commit/48f3c8b034c5ece4948c9077d542a41cbdd5d178)
  reused compiler-loaded dependency regions across isolated executable environments and
  combined related audits in one environment. Each executable retained its own main;
  IR owners had to belong to that entry's serialized import closure, and shared regions
  had to outlive their consumers. This is not permission to merge Strict Lean fence
  environments or weaken their ownership checks.
- [4a727ace](https://github.com/rbeauchamp/acorn/commit/4a727ace81496a1acb417f6355e78de9760a1168)
  used standard Ubuntu x64 and separated pinned dependency provisioning from the cold
  project gate. Platform/toolchain/lock identities scoped artifact reuse; project outputs
  and acceptance remained uncached.

The public delivery record says macOS missed both its former 300s budget and its explicitly
authorized 360s budget. Those statements are delivery-record claims; the 239s run at 6d3e95bf
Ubuntu result was independently read from job metadata and logs. A deadline increase
changes policy, not throughput. Neither Acorn's budget nor its runner choice overrides
another repository's requirements. No private Acorn source is required for this guidance.

## Skill authoring

This skill follows the system `skill-creator` guidance and OpenAI's
[Rethinking skills and prompts for GPT-6 Astra](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra):
use a narrow discovery description, expose details when relevant, and retain decision-bearing
constraints instead of prescribing a long fixed itinerary. Repository rules remain authoritative.
