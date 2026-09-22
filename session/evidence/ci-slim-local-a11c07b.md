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
