# Opt-in probabilistic intent screening

Issue [#58](https://github.com/rbeauchamp/lean-plumb/issues/58). This guide describes an
optional tool, not a conformance rule. Rule PL5003 requires every registered material claim
to carry a written `# Intent` section (standard §5.2). R-INTENT review then asks whether the
elaborated proposition is the one the intent describes. The `intentScreen` executable asks a
pinned judgment model narrow questions about that comparison. Its answers can raise findings
at severities you choose. They cannot check a claim, and they cannot complete the review.

## What a screen reports

A judged answer has its own evidence class, **screened**. It sits beside the classes an
accepted run reports ([#42](https://github.com/rbeauchamp/lean-plumb/issues/42)): the relation
Lean checked, the mechanisms trusted without verification, and open semantic review. Each
screened record carries the pinned model identifier, the exact question text, the support
probability, and the SHA-256 of the request the model answered. For example:
`screened: p = 0.93, model jev-1.13.0, inputs sha256:…`.

- A low probability raises a finding at the severity your thresholds assign.
- A high probability raises nothing. The claim is at most `screened`. It is never
  recorded as checked, and R-INTENT and R-DOC remain open. The report type
  (`Plumb.Checker.Screening.Status`) has only `screened` and `escalated` constructors. No
  checked or reviewed state exists to reach.
- Screening is off by default. The first `scripts/verify.sh` acceptance step type-checks its
  modules but never runs it; it calls the network only when you run it yourself.

## Formal discharge first

If you can state an intent clause in Lean with vetted vocabulary, such as `List.Perm`, prove
that the claim implies the clause, and end the clause with a reference to that proof:

```text
# Intent
- Sorting returns its output in nondecreasing order.
- The output contains exactly the input's elements, each as many times as in the input. (discharged by `Demo.sort_perm_of_correct`)
```

The screen accepts the reference only when these conditions hold:

- The named declaration is a theorem of the loaded environment.
- Its type is `S → P`, where `P` does not depend on the hypothesis, and Lean's kernel
  definitional-equality check (`Lean.Kernel.isDefEq`) finds `S` equal to the claim's statement.
- Its transitive axioms lie within the Standard-Logical foundation: `propext`, `Quot.sound`
  and `Classical.choice`. A project axiom, `sorryAx`, `Lean.ofReduceBool` (`native_decide`) or
  `Lean.trustCompiler` refuses it. The report lists the exact axioms.

The kernel admitted the implication with the theorem, and the screen's adapter ran the other
checks. That part of the clause is **checked** and involves no model judgment. The model
judges only one question about it: does `P` state the English clause? The report calls this
the *correspondence* judgment. The screen asks no coverage question for a discharged clause.
A reference that fails any condition makes the whole screen incomplete. It never falls back
to a judged clause. `IntentCorpus.mergeSort_correct` in `lean/Plumb/Screen/Corpus.lean` is a
worked example.

## Judgments

The question text is in `lean/Plumb/Screen/Questions.lean` and is recorded with every answer.
The state holds the intent clauses plus, depending on the `state` setting, the elaborated
statement, the §5.2 explanation, or both. The declaration name is never sent: a name such as
`sort_drops_perm` would give the answer away.

| Judgment | Type | Support probability |
| --- | --- | --- |
| `coverage` (one per clause) | Noul | The claim guarantees the clause. |
| `correspondence` (per discharged clause) | Noul | The formal clause states the English clause. |
| `strength` | Choice: equivalent, stronger, weaker, incomparable | P(equivalent) + P(stronger), the claim guarantees the whole intent. |
| `quantifier-order` | Noul | The quantifier order and dependence agree with the intent. This asks about literal order, so a finding can flag a swap to a *stronger* claim that still meets the intent: 4 of the 6 quantifier-order defects in the corpus were such swaps. Review a finding before treating it as a defect. |
| `totalization` | Noul | No conclusion depends on a conventional value (such as `x / 0 = 0`) in a case the intent leaves undefined. |
| `exclusions` | Noul | Every exclusion or limit the intent states is honored. |

Every question is worded so that "yes" means the claim meets the intent. A low support
probability is therefore the warning sign for every judgment.

## Configuration and severity

```json
{
  "schemaVersion": 1,
  "model": "jev-1.13.0",
  "cache": ".lake/intent-screen-cache",
  "state": "statement",
  "judgments": {
    "coverage": { "error": 0.2, "warning": 0.5 },
    "strength": { "error": 0.2, "warning": 0.5, "minConfidence": 0.5 }
  }
}
```

- `model` must be an exact version (`<name>-<major>.<minor>.<patch>`). Moving aliases such as
  `jev-latest` are refused. The run is also refused if the service answers with any other
  model.
- The thresholds for each judgment map support probabilities to severity. Below `error` is an
  error. From `error` up to but not including `warning` is a warning. At or above `warning`
  raises no finding. The configuration is refused unless `error ≤ warning`. Probabilities are
  compared as exact decimals, never as binary floating point.
- A judgment with no thresholds raises no finding, and each of its answers escalates.
- An answer escalates to reasoning-model or human review in two cases: it raises a finding,
  or its Choice confidence is below `minConfidence`. The tool reports the route. It calls
  no second model.
- Unknown fields are refused.

Run the screen:

```text
lake build MyProject.Claims
TYPESAFE_API_KEY=… lake exe intentScreen screen --config screen.json --module MyProject.Claims [--json out.json]
```

With no `--declaration`, the screen covers every public `@[plumb_material]` declaration of the
listed modules. With `--declaration`, it covers exactly the named declarations. It exits with
0 when no error-severity finding is raised, 1 when one is, and 2 when the screen is
incomplete. A screen is incomplete when the key is missing and no cached answer exists, or
when a network, service, parse, claim or discharge failure occurs. An incomplete screen is
never reported as a pass. With `--json`, the output keeps the classes apart: each claim's
checked discharges (theorem, formal clause, axioms) and open review obligations are listed
separately from its screened answers.

## Boundary, cost and data

- **Network and data.** Each claim sends one HTTPS request to `https://api.typesafe.ai`, plus
  one request per discharged clause. The request carries the intent clauses, the statement
  and/or the explanation, and the fixed question text. That is source text leaving your
  machine, so run the screen only on text you may send to TypeSafe. The key is read from
  `TYPESAFE_API_KEY` and passed to `curl` on standard input. It never appears in an
  argument list, a file, a log, or the cache.
- **Cost.** TypeSafe bills input tokens only. The jev-1.13.0 list price was $0.042 per million
  input tokens on 2026-09-24. A claim request is about 1,500 to 2,000 input tokens. The tool
  prints the requests sent, the cache hits, and the input tokens billed.
- **Reproducibility.** The cache key is the SHA-256 of the exact request: model, state and
  every question. An entry is reused only if its stored request equals the current one. A
  fully cached run needs no key and makes no network call. Any change to the model, the
  question wording, the statement or the intent produces a new request.
- **Trusted, not verified.** The screen's adapter code that reads claims and checks discharge
  references, the `curl` and `shasum` processes, the network, the service and
  its answers, the cache files, and Lean's pretty-printer that renders the statement.

## What is proved and what is not

Machine-checked, about the definitions the executable runs (each through a
`Plumb.ExecutableContract` registration):

- The exact decimal order is reflexive, transitive and total (`PlumbPolicy.Screening.Decimal`).
- Probability admission accepts exactly the values in `[0, 1]` and changes none
  (`probability?_eq_some_iff`).
- The severity mapping is exact: error below `error`, warning in the band, nothing at or
  above `warning` (`checkedClassify`). It is also antitone: a lower probability never gives a
  less severe finding (`classify_antitone`).
- An answer stays `screened` exactly when thresholds are configured, the answer raises no
  finding, and any reported confidence meets the minimum (`checkedRoute`). An answer with a
  finding always escalates (`Judged.escalate_of_severity`). A claim with any finding is
  escalated (`ClaimScreen.escalated_of_finding`).
- Clause extraction finds clauses only in docstrings that PL5003 accepts and never returns a
  blank clause (`checkedClauses`, `intentBody?_isSome_iff`). Discharge-marker parsing, the
  pinned-model grammar, and clause splitting are checked on documented instances.

Not established by any proof: that a probability is correct or calibrated for your claims,
that the question wording captures the intended judgment, or that the service behaved as
documented. The calibration below is a measurement on one corpus and one pinned model.

## Calibration protocol

The corpus, criteria and budget below were fixed and committed before the test split ran.

**Corpus** (`lean/Plumb/Screen/Corpus.lean`, labels in `Plumb.Screen.Corpus.items`):

- *Base* items are correct intent/claim pairs.
- *Rewrites* state the same requirement differently. They are false-positive controls; one
  is deliberately stronger.
- *Mutants* change the base claim by one of the five kinds in issue #58: drop a conjunct,
  swap quantifiers, weaken an inequality, add a hypothesis, or totalize a partial operation.
- Each item carries labels: which clauses the claim does not establish, the strength option,
  and the three targeted checks. Labels are schematic, not literal implication: most clauses
  are true facts about `Nat` or `List`, so every mutant trivially implies them. A clause counts
  as established only when the claim's own content yields it, without using the clause as a
  background fact about the named operations. An exclusion clause counts as unestablished
  when the claim asserts the excluded case. The quantifier-order check asks about literal
  order, so a swap to a *stronger* claim is labelled a defect there even though it is
  covered and `stronger` for the other judgments.
- Bases A and B form the development split, used to debug the runner and question wording.
  Bases C to M and O to Q (there is no N) form the test split: 14 bases, 14 rewrites and 33 mutants.
- 24 English/Lean clause pairs, 12 correct and 12 wrong, measure `correspondence`.

**Conditions.** Each item runs with three states: `full` (statement and explanation),
`statement` only, and `explanation` only. In the `full` and `explanation` states each mutant
runs twice; in `statement`, which has no explanation, it runs once. The *faithful* variant keeps
its own explanation. The *stale* variant takes its base's explanation, so the mutation is
visible only in the Lean statement. A stale-explanation run in the `explanation` state is a
control by construction: its request is identical to its base's, so it is answered from cache.
These are the 33 cache hits of the test run. Comparing the conditions shows whether the model reads
the Lean statement or only the English.

**Metrics** are computed per judgment and group. A *defect* is a labelled failure. A false
negative is a defect whose support is at or above the threshold. A false positive is a
non-defect whose support is below it. The runner reports FNR and FPR at 0.2, 0.5 and 0.6, with
counts, plus the threshold-free AUC.

**Decision criteria.** The runner applies these rules itself.

- Default thresholds (error 0.2, warning 0.5) mean something only for a judgment that meets
  all three rules below in both full-state groups: faithful and stale explanations.
  - C1: at 0.5, FNR ≤ 0.25 and FPR ≤ 0.15.
  - C2: at 0.2, FPR ≤ 0.05.
  - C3: the group has at least 5 defects and 10 clean rows.
- Every other judgment gets no calibrated thresholds. You may still set thresholds for it,
  but they carry no measured meaning.
- The default state is the one with the highest mean coverage and strength AUC over both
  explanation variants. A tie keeps `full`.
- A judgment reads the Lean statement when its AUC is at least 0.8 both with the statement
  alone and in the full state with a stale explanation.

**Budget.** The test run may send at most 300 requests (the runner refuses to send beyond
that, checking before every request) and
about 600,000 input tokens (about $0.03). The dev split may be rerun only to debug. The test
split runs once, with frozen question text. Any later change to the questions or the corpus
requires a new, disclosed test run.

## Calibration results

The test split ran once, on 2026-09-24, with `jev-1.13.0`, after the protocol was committed.
The [full report](../../examples/intent-screening/test-report.md) gives every group, and the
[evidence rows](../../examples/intent-screening/test-records.json) record the probability and
request digest of each answer. The cached request/response pairs in
`examples/intent-screening/cache/` reproduce every table offline. The command below needs no
key and sends nothing:

```text
lake exe intentScreen calibrate --config examples/intent-screening/calibration.json --split test --report out.md --records out.json
```

The rates below are for the `full` state, at the pre-registered warning threshold of 0.5,
with counts:

| Judgment | Explanation | Defects / clean | FNR at 0.5 | FPR at 0.5 | FPR at 0.2 | AUC | Decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| coverage | faithful | 33 / 76 | 9/33 (0.27) | 9/76 (0.12) | 1/76 (0.01) | 0.91 | no calibrated thresholds (C1 fails) |
| coverage | stale | 33 / 76 | 0/33 (0.00) | 12/76 (0.16) | 3/76 (0.04) | 0.94 | |
| strength | faithful | 29 / 32 | 14/29 (0.48) | 1/32 (0.03) | 0/32 (0.00) | 0.92 | no calibrated thresholds (C1 fails) |
| strength | stale | 29 / 32 | 4/29 (0.14) | 2/32 (0.06) | 0/32 (0.00) | 0.98 | |
| quantifier-order | faithful | 6 / 55 | 2/6 (0.33) | 0/55 (0.00) | 0/55 (0.00) | 0.99 | no calibrated thresholds (C1 fails) |
| quantifier-order | stale | 6 / 55 | 0/6 (0.00) | 1/55 (0.02) | 0/55 (0.00) | 1.00 | |
| totalization | faithful | 5 / 56 | 0/5 (0.00) | 0/56 (0.00) | 0/56 (0.00) | 1.00 | calibrated: error 0.2, warning 0.5 |
| totalization | stale | 5 / 56 | 1/5 (0.20) | 0/56 (0.00) | 0/56 (0.00) | 1.00 | |
| exclusions | faithful | 6 / 55 | 1/6 (0.17) | 6/55 (0.11) | 0/55 (0.00) | 0.97 | calibrated: error 0.2, warning 0.5 |
| exclusions | stale | 6 / 55 | 1/6 (0.17) | 7/55 (0.13) | 0/55 (0.00) | 0.94 | |
| correspondence | (clause pairs) | 12 / 12 | 1/12 (0.08) | 1/12 (0.08) | 0/12 (0.00) | 0.98 | calibrated: error 0.2, warning 0.5 |

The exclusions rows include one label correction made after the run (see the erratum below).

Applying the pre-registered rules gives these results:

- **Thresholds.** Totalization, exclusions and correspondence meet C1 to C3, so error 0.2 and
  warning 0.5 carry measured meaning for them. Coverage, strength and quantifier order do
  not. [`screen.json`](../../examples/intent-screening/screen.json) therefore sets thresholds
  only for the three calibrated judgments. For the other three it reports probabilities and
  escalates every answer to review. Their sample counts are small: 5 or 6 defects for the
  targeted checks.
- **State.** The default state is `full`: statement and explanation. Mean coverage and
  strength AUC was 0.935 for `full`, 0.875 for statement only, and 0.653 for explanation only.
- **Lean reading.** The model reads the Lean statement. Statement-only AUC was 0.85 for
  coverage and 0.90 for strength. With a stale explanation, where only the Lean shows the
  mutation, full-state AUC was 0.94 and 0.98. Explanation-only runs with a stale explanation
  scored at chance (AUC 0.44 and 0.50). That is expected by construction: those requests
  cannot contain the mutation.

Observed patterns (sampled, not guarantees):

- A faithful explanation of a mutated claim hides the mutation more often than a stale one.
  Coverage missed 6 of 10 added-hypothesis clauses with a faithful explanation and 0 of 10
  with a stale one. The explanation/statement mismatch is itself a cue.
- The strength Choice labels totalized claims `stronger` rather than `incomparable` in 8 of 10
  cases. The targeted totalization and exclusions checks caught those claims.
- Coverage false positives cluster in two places:
  - exclusion clauses of correct claims, such as "Zero has no predecessor…", which a claim
    honors but does not "guarantee";
  - "may depend on it" clauses judged against a stronger swapped claim.
  Exclusion clauses belong to the exclusions check. Changing the question wording would need
  a new, disclosed test run.

**Erratum.** An independent review after the run found that `H_weaken`
(`admits c u r = true ↔ u + r ≤ c + 1`) was labelled as honoring the intent's exclusions.
It does not: it asserts admission when usage would reach capacity + 1, which the intent
forbids. The label is now `exclusions := false`. No request changed, so the tables were
recomputed offline from the same cached answers. The exclusions decision is unchanged, and so
is every other decision. [`test-report-as-run.md`](../../examples/intent-screening/test-report-as-run.md)
keeps the report as it was run.

**Spend.** This work sent 309 requests and was billed 451,395 input tokens, about $0.019 at
the list price:

- two development runs of the dev split: 64 requests, 105,110 tokens;
- the single test run: 240 requests, 338,709 tokens;
- one dogfood screen of four `AuditApp` claims: 4 requests, 6,121 tokens;
- the discharge demonstration after it stopped asking coverage for discharged clauses:
  1 request, 1,455 tokens.

Everything else, including the regenerated reports, was answered from cache.
