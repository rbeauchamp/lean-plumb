Model `jev-1.13.0`, split `dev`: 0 requests sent, 37 answered from cache, 0 input tokens billed.

### coverage

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 7 / 16 | 2/7 (0.286) | 0/16 (0.000) | 1/7 (0.143) | 0/16 (0.000) | 1/7 (0.143) | 1/16 (0.063) | 212/224 (0.946) |
| full, stale explanation | 7 / 16 | 2/7 (0.286) | 0/16 (0.000) | 1/7 (0.143) | 1/16 (0.063) | 1/7 (0.143) | 3/16 (0.188) | 218/224 (0.973) |
| statement | 7 / 16 | 3/7 (0.429) | 0/16 (0.000) | 0/7 (0.000) | 0/16 (0.000) | 0/7 (0.000) | 0/16 (0.000) | 224/224 (1.000) |
| explanation, faithful explanation | 7 / 16 | 5/7 (0.714) | 0/16 (0.000) | 1/7 (0.143) | 0/16 (0.000) | 0/7 (0.000) | 1/16 (0.063) | 224/224 (1.000) |
| explanation, stale explanation | 7 / 16 | 7/7 (1.000) | 0/16 (0.000) | 7/7 (1.000) | 0/16 (0.000) | 7/7 (1.000) | 0/16 (0.000) | 86/224 (0.384) |

### strength

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 5 / 4 | 3/5 (0.600) | 0/4 (0.000) | 1/5 (0.200) | 0/4 (0.000) | 1/5 (0.200) | 0/4 (0.000) | 40/40 (1.000) |
| full, stale explanation | 5 / 4 | 2/5 (0.400) | 0/4 (0.000) | 0/5 (0.000) | 0/4 (0.000) | 0/5 (0.000) | 0/4 (0.000) | 40/40 (1.000) |
| statement | 5 / 4 | 2/5 (0.400) | 0/4 (0.000) | 0/5 (0.000) | 0/4 (0.000) | 0/5 (0.000) | 0/4 (0.000) | 40/40 (1.000) |
| explanation, faithful explanation | 5 / 4 | 3/5 (0.600) | 0/4 (0.000) | 2/5 (0.400) | 0/4 (0.000) | 2/5 (0.400) | 0/4 (0.000) | 40/40 (1.000) |
| explanation, stale explanation | 5 / 4 | 5/5 (1.000) | 0/4 (0.000) | 5/5 (1.000) | 0/4 (0.000) | 5/5 (1.000) | 0/4 (0.000) | 13/40 (0.325) |

### quantifier-order

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 0 / 9 | n/a | 0/9 (0.000) | n/a | 0/9 (0.000) | n/a | 0/9 (0.000) | n/a |
| full, stale explanation | 0 / 9 | n/a | 0/9 (0.000) | n/a | 1/9 (0.111) | n/a | 1/9 (0.111) | n/a |
| statement | 0 / 9 | n/a | 0/9 (0.000) | n/a | 0/9 (0.000) | n/a | 0/9 (0.000) | n/a |
| explanation, faithful explanation | 0 / 9 | n/a | 0/9 (0.000) | n/a | 0/9 (0.000) | n/a | 1/9 (0.111) | n/a |
| explanation, stale explanation | 0 / 9 | n/a | 0/9 (0.000) | n/a | 0/9 (0.000) | n/a | 0/9 (0.000) | n/a |

### totalization

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 1 / 8 | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 16/16 (1.000) |
| full, stale explanation | 1 / 8 | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 16/16 (1.000) |
| statement | 1 / 8 | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 16/16 (1.000) |
| explanation, faithful explanation | 1 / 8 | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 16/16 (1.000) |
| explanation, stale explanation | 1 / 8 | 1/1 (1.000) | 0/8 (0.000) | 1/1 (1.000) | 0/8 (0.000) | 1/1 (1.000) | 0/8 (0.000) | 12/16 (0.750) |

### exclusions

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 1 / 8 | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 1/8 (0.125) | 0/1 (0.000) | 1/8 (0.125) | 16/16 (1.000) |
| full, stale explanation | 1 / 8 | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 1/8 (0.125) | 0/1 (0.000) | 1/8 (0.125) | 16/16 (1.000) |
| statement | 1 / 8 | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 1/8 (0.125) | 0/1 (0.000) | 1/8 (0.125) | 16/16 (1.000) |
| explanation, faithful explanation | 1 / 8 | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 0/8 (0.000) | 0/1 (0.000) | 2/8 (0.250) | 16/16 (1.000) |
| explanation, stale explanation | 1 / 8 | 1/1 (1.000) | 0/8 (0.000) | 1/1 (1.000) | 0/8 (0.000) | 1/1 (1.000) | 0/8 (0.000) | 4/16 (0.250) |

Strength exact option agreement (full state, both explanations): 12/14 (0.857)

### Decisions (pre-registered rules)

- coverage: calibrated thresholds (error 0.2, warning 0.5) — full/faithful: C1 pass, C2 pass, C3 pass; full/stale: C1 pass, C2 pass, C3 pass
- strength: no calibrated thresholds — full/faithful: C1 pass, C2 pass, C3 fail; full/stale: C1 pass, C2 pass, C3 fail
- quantifier-order: no calibrated thresholds — full/faithful: C1 pass, C2 pass, C3 fail; full/stale: C1 pass, C2 pass, C3 fail
- totalization: no calibrated thresholds — full/faithful: C1 pass, C2 pass, C3 fail; full/stale: C1 pass, C2 pass, C3 fail
- exclusions: no calibrated thresholds — full/faithful: C1 pass, C2 pass, C3 fail; full/stale: C1 pass, C2 pass, C3 fail
- default state: `statement` (mean coverage and strength AUC in thousandths: full 979, statement 1000, explanation 677; ties keep full)
- coverage reads the Lean statement: true (statement-only AUC 1000, full-state stale-explanation AUC 973; rule: both at least 800)
- strength reads the Lean statement: true (statement-only AUC 1000, full-state stale-explanation AUC 1000; rule: both at least 800)
