# Issue 5: typed policy domain verification

This is a delivery snapshot, not a new standard or an accepted-result certificate.
The source inputs for the observed census are identified in
[issue-5-inventory.json](issue-5-inventory.json). Its display names are legacy
observations, not structural evidence keys. Reproduce the current census with
`./scripts/verify.sh`; source changes invalidate affected observations.

## Scope and results

- Lean 4.33.1, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`;
  Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`.
- Ordinary acceptance passed within its hard 420-second deadline: 3 libraries,
  1 executable, 24 owned modules, 2,916 declarations. The new pure policy library
  contributes 12 modules and 2,406 declarations, including compiler-generated
  declarations and empty umbrella modules. Every observed axiom is among
  `propext`, `Quot.sound`, and `Classical.choice`; the JSON supplies each exact
  declaration's observed set and module totals.
- Documentation: 70/70 conforming positive, 23/23 negative, 1/1 teaching example.
- `./scripts/verify.sh diagnostics fixtures`: PASS in 110 seconds; all 60 fixtures,
  scanner/28 corpus controls and 11 execution-policy controls. This partition is
  scoped qualification, not an alternate acceptance command.
- `gtimeout --signal=KILL 420s .lake/build/bin/checkerSelftest --policy-domain-only`:
  PASS for actual external-adopter imports, forbidden Report/Probe imports,
  authored tagged recursion-helper forgery, runtime-modified genuine helper,
  positive-file warnings, and fresh restored controls. The final transport
  assertions were rerun separately after sharpening their intended error checks:
  `checkerSelftest --policy-transport-only`: PASS.
- Transport controls cover duplicate/escaped/nested JSON keys; unknown/missing/
  lookalike categories; malformed names; incompatible extra origin evidence;
  duplicate roots/boundary occurrences/results; unknown/missing/conflicting slots;
  producer/request/schema mismatch; and process-code overflow. These exercise
  actual operational adapters; universal category/name/collection/admission laws
  are compiled proofs over their stated domains.

The separate `python3 examples/rule-reference-prototype/run.py` integration also
passed after its remaining policy caller was migrated to an admitted scope.
It covers actual policy/native diagnostic, Lake dependency dispatch, corrected
fixture and Verso output; editor interaction remains unverified.

## Independent review

The repository-local review toolkit was used with separate fresh contexts for
pure domain/codec semantics, operational integration, and documentation. Focused
repair reviews closed discarded-evidence admission, temporary artifact-origin
handling, public-import isolation, recursive-helper coverage, and qualification
wrong-reason failures. Final scoped findings: CLEAN.

Reviewed chapter 9 concerns include applicable TYPE, THEOREM, FOUND, DECL and COMP rows,
plus SCOPE-02/03/05, DOC-02, DOGFOOD-03 and affected MUT-02 controls. This is scoped
issue delivery evidence; it does not assert a new full-repository semantic audit.
Exact-head hosted CI remains a separate PR merge gate recorded on GitHub.

## Limits and successor work

Representation/admission proofs do not authenticate compiler observations, JSON
text, files, processes or runtime behavior. Issue 6 owns independent semantic
relations/equivalence and acceptance soundness/completeness; issue 7 owns complete
census, fixed jobs and all success-boundary integration. The current fence-key
shape does not replace exact registry example expectations and source locations.
The optional serialized-graph and long structural/environment/build campaigns
were not run for this scoped claim and are not reported PASS.

No new normative rule, diagnostic ID or site page is introduced. Existing fixture
sources remain applicable and were rerun. CI already runs the ordinary script,
which now builds/audits the new library and type-checks the qualification module;
no separate CI workflow or review-skill change is needed. The stricter ingress and
warning behavior, neutral public imports, and legacy-output limits are documented
in [the migration guide](../../docs/guides/policy-domain.md).
