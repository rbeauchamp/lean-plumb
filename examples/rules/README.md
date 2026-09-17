# Rule source fixtures

These files are the source of truth for checked rule examples. They are intentionally
outside every positive Lake library. `Violation.lean` may compile successfully: the actual
registered detector must establish its advertised result.

Currently SL5001 and SL5002 have fresh-project fixed/violation/fresh-restored controls through
`lean/StrictLean/Qualification/Producer.lean`. Both retain the same universally quantified reflexivity claim;
the fix adds only documentation. See [producer evidence](../../docs/guides/engine-producers.md)
for exact commands, exported evidence, scope and remaining twenty-rule corpus work.
