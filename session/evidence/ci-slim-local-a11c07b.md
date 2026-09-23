# Local acceptance at the verification-slimming head, 2026-09-22

This covers exact signed head `a11c07b882cb5772dc45e2d63ac1b5a1f9a180cc`, which was squash-merged as `12a704502f78d578ccfd81ec7c93bc0dd88af757`. The worktree was clean, and the local compiler allocation was held exclusively.

- **Cold `./scripts/verify.sh`: PASS in 148.70 s, exit 0.**
  - The entire root `.lake/build` was moved to `tmp/cold-a11c07b-root-build-preserved` first. Only the pinned dependency artifacts stayed provisioned.
  - The run ended at 2026-09-22T23:11:12Z.
- **`./scripts/verify.sh docs`: PASS in 88.77 s, exit 0**, immediately afterwards. It ended at 23:12:40Z, and every `docs/` Lean fence was audited with inputs equal to the accepted ordinary inputs.
- **Inputs:** all tracked inputs had identical SHA256 before and after (`tmp/cold-a11c07b-inputs.sha256`). The receipt is `tmp/cold-a11c07b.receipt`, and the logs are `tmp/cold-a11c07b.log` and `tmp/cold-a11c07b-docs.log`.
- **Hosted exact-head CI at the same head:**

  | Check | Time |
  | --- | --- |
  | Ordinary | 266 s |
  | Docs | 116 s |
  | Verso/linter | 66 s |
  | Producers | 291 s |
  | History | 299 s |
  | Rule-examples 1/2 | 298 s |
  | Rule-examples 2/2 | 279 s |

- **Environment:** Lean 4.34.0 (`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`), Mathlib `5ed2965256430c3649e86755f9576b54eca72435`, arm64 macOS.

These are observed completions, not runtime bounds. They do not cover the follow-up changes committed after this note.

## Follow-up review repair at `d1e76fd9ebff7e5239d568352ea273269bcb3d3a`

This head is the stale-build producer controls, the 8.8 wording, the SL5001/SL5002 shard pair with its proved shard coverage, and the trust and wording clauses. All four runs used a clean tree at that exact signed head, one after another, 2026-09-23 UTC. Load averages are the 1/5/15-minute values at start and end.

| Command | Result | Wall | Window (UTC) | Load at start → end |
| --- | --- | --- | --- | --- |
| `./scripts/verify.sh diagnostics producers` | PASS, exit 0 | 223.22 s | 00:12:55–00:16:39 | 5.50/6.26/9.50 → 4.34/5.24/8.31 |
| `./scripts/verify.sh diagnostics rule-examples 2/2` | PASS, exit 0 (9 rules) | 88.53 s | 00:16:39–00:18:07 | → 6.00/5.61/8.14 |
| Cold `./scripts/verify.sh` | PASS, exit 0 | 148.90 s | 00:18:13–00:20:42 | 5.60/5.53/8.09 → 12.19/8.61/8.97 |
| `./scripts/verify.sh docs` | PASS, exit 0 | 99.55 s | 00:20:47–00:22:27 | 12.82/8.80/9.03 → 11.82/9.44/9.25 |

- **Producers:** the 12 source-owned controls ran, with Violation over the prior Fixed build and a restored Fixed from a cleared build, plus the transport and standalone controls.
- **Cold ordinary:** root `.lake/build` was moved to `tmp/cold-d1e76fd-root-build-preserved` first. Tracked inputs were unchanged.
- **Docs:** inputs equal the accepted ordinary inputs.
- **Rule-examples 1/2:** the pipeline test agent passed it at this head in 118 s, running the SL5001/SL5002 fresh-project producer checks.
- **Receipts:** `tmp/followup-d1e76fd-producers.*`, `tmp/followup-d1e76fd-rule-examples-2-2.*`, `tmp/cold-d1e76fd.*` and `tmp/cold-d1e76fd-docs.log`.

These are observed completions, not runtime bounds.
