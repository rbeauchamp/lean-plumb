# Rule source fixtures

These files are the source of truth for all twenty rule-reference examples. They are
intentionally outside every positive Lake library. A violation can elaborate successfully;
the actual registered detector must produce its advertised result.

[`corpus.json`](corpus.json) fixes expected rule IDs, reasons, modes, subjects and locations.
The [rule-example guide](../../docs/guides/rule-examples.md) gives each source pair's exact
remediation and the invocation, export and trust contracts. The website consumes checked
source bytes directly rather than maintaining hand-copied snippets.

SL2001, SL2005 and SL3001 use separate **diagnostic demonstrations**. Their audit results
remain incomplete; these are neither conforming positives nor accepted rejection examples.
Corrections still require completed positive checks. Other cases use policy rejection,
preserving all findings (including SL4002's underlying SL1001 and native-proof parents).

Run the dedicated qualification after building its Lean adapter:

```sh
lake build ruleExamples +StrictLean.Checker.RuleExampleQualification:olean
python3 scripts/rule_example_checks.py --evidence tmp/rule-examples.json
```

Each fixed/violation/restored phase uses a fresh isolated Core-only adopter and unique output.
`--rules SL1001 SL1002` selects explicitly scoped evidence during development. The dedicated
campaign is not the ordinary 420-second acceptance run or a proof of universal detector
correctness. The existing SL5001/SL5002 producer campaign remains available unchanged.
