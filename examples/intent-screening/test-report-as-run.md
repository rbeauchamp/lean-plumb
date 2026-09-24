Model `jev-1.13.0`, split `test`: 240 requests sent, 33 answered from cache, 338709 input tokens billed.

### coverage

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 33 / 76 | 23/33 (0.697) | 1/76 (0.013) | 9/33 (0.273) | 9/76 (0.118) | 7/33 (0.212) | 12/76 (0.158) | 4543/5016 (0.906) |
| full, stale explanation | 33 / 76 | 21/33 (0.636) | 3/76 (0.039) | 0/33 (0.000) | 12/76 (0.158) | 0/33 (0.000) | 16/76 (0.211) | 4716/5016 (0.940) |
| statement | 33 / 76 | 21/33 (0.636) | 4/76 (0.053) | 9/33 (0.273) | 12/76 (0.158) | 9/33 (0.273) | 18/76 (0.237) | 4247/5016 (0.847) |
| explanation, faithful explanation | 33 / 76 | 22/33 (0.667) | 0/76 (0.000) | 17/33 (0.515) | 17/76 (0.224) | 12/33 (0.364) | 21/76 (0.276) | 3914/5016 (0.780) |
| explanation, stale explanation | 33 / 76 | 33/33 (1.000) | 0/76 (0.000) | 29/33 (0.879) | 13/76 (0.171) | 29/33 (0.879) | 14/76 (0.184) | 2205/5016 (0.440) |

### strength

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 29 / 32 | 22/29 (0.759) | 0/32 (0.000) | 14/29 (0.483) | 1/32 (0.031) | 9/29 (0.310) | 2/32 (0.063) | 1702/1856 (0.917) |
| full, stale explanation | 29 / 32 | 8/29 (0.276) | 0/32 (0.000) | 4/29 (0.138) | 2/32 (0.063) | 4/29 (0.138) | 3/32 (0.094) | 1818/1856 (0.980) |
| statement | 29 / 32 | 15/29 (0.517) | 1/32 (0.031) | 8/29 (0.276) | 2/32 (0.063) | 7/29 (0.241) | 5/32 (0.156) | 1677/1856 (0.904) |
| explanation, faithful explanation | 29 / 32 | 21/29 (0.724) | 0/32 (0.000) | 16/29 (0.552) | 2/32 (0.063) | 12/29 (0.414) | 3/32 (0.094) | 1660/1856 (0.894) |
| explanation, stale explanation | 29 / 32 | 29/29 (1.000) | 0/32 (0.000) | 29/29 (1.000) | 0/32 (0.000) | 29/29 (1.000) | 0/32 (0.000) | 930/1856 (0.501) |

### quantifier-order

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 6 / 55 | 3/6 (0.500) | 0/55 (0.000) | 2/6 (0.333) | 0/55 (0.000) | 2/6 (0.333) | 1/55 (0.018) | 652/660 (0.988) |
| full, stale explanation | 6 / 55 | 0/6 (0.000) | 0/55 (0.000) | 0/6 (0.000) | 1/55 (0.018) | 0/6 (0.000) | 2/55 (0.036) | 660/660 (1.000) |
| statement | 6 / 55 | 2/6 (0.333) | 0/55 (0.000) | 0/6 (0.000) | 0/55 (0.000) | 0/6 (0.000) | 1/55 (0.018) | 660/660 (1.000) |
| explanation, faithful explanation | 6 / 55 | 4/6 (0.667) | 0/55 (0.000) | 1/6 (0.167) | 1/55 (0.018) | 1/6 (0.167) | 4/55 (0.073) | 645/660 (0.977) |
| explanation, stale explanation | 6 / 55 | 6/6 (1.000) | 0/55 (0.000) | 6/6 (1.000) | 0/55 (0.000) | 6/6 (1.000) | 0/55 (0.000) | 206/660 (0.312) |

### totalization

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 5 / 56 | 0/5 (0.000) | 0/56 (0.000) | 0/5 (0.000) | 0/56 (0.000) | 0/5 (0.000) | 0/56 (0.000) | 560/560 (1.000) |
| full, stale explanation | 5 / 56 | 3/5 (0.600) | 0/56 (0.000) | 1/5 (0.200) | 0/56 (0.000) | 1/5 (0.200) | 0/56 (0.000) | 560/560 (1.000) |
| statement | 5 / 56 | 2/5 (0.400) | 0/56 (0.000) | 1/5 (0.200) | 0/56 (0.000) | 0/5 (0.000) | 0/56 (0.000) | 560/560 (1.000) |
| explanation, faithful explanation | 5 / 56 | 0/5 (0.000) | 0/56 (0.000) | 0/5 (0.000) | 0/56 (0.000) | 0/5 (0.000) | 0/56 (0.000) | 560/560 (1.000) |
| explanation, stale explanation | 5 / 56 | 5/5 (1.000) | 0/56 (0.000) | 5/5 (1.000) | 0/56 (0.000) | 5/5 (1.000) | 0/56 (0.000) | 227/560 (0.405) |

### exclusions

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| full, faithful explanation | 5 / 56 | 0/5 (0.000) | 0/56 (0.000) | 0/5 (0.000) | 6/56 (0.107) | 0/5 (0.000) | 7/56 (0.125) | 560/560 (1.000) |
| full, stale explanation | 5 / 56 | 4/5 (0.800) | 1/56 (0.018) | 1/5 (0.200) | 8/56 (0.143) | 1/5 (0.200) | 9/56 (0.161) | 512/560 (0.914) |
| statement | 5 / 56 | 4/5 (0.800) | 0/56 (0.000) | 1/5 (0.200) | 8/56 (0.143) | 1/5 (0.200) | 10/56 (0.179) | 507/560 (0.905) |
| explanation, faithful explanation | 5 / 56 | 0/5 (0.000) | 1/56 (0.018) | 0/5 (0.000) | 6/56 (0.107) | 0/5 (0.000) | 6/56 (0.107) | 560/560 (1.000) |
| explanation, stale explanation | 5 / 56 | 5/5 (1.000) | 0/56 (0.000) | 5/5 (1.000) | 0/56 (0.000) | 5/5 (1.000) | 0/56 (0.000) | 371/560 (0.663) |

Strength exact option agreement (full state, both explanations): 74/94 (0.787)

### correspondence

| group | defects / clean | FNR@0.2 | FPR@0.2 | FNR@0.5 | FPR@0.5 | FNR@0.6 | FPR@0.6 | AUC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clause pair | 12 / 12 | 4/12 (0.333) | 0/12 (0.000) | 1/12 (0.083) | 1/12 (0.083) | 1/12 (0.083) | 1/12 (0.083) | 282/288 (0.979) |

### Decisions (pre-registered rules)

- coverage: no calibrated thresholds — full/faithful: C1 fail, C2 pass, C3 pass; full/stale: C1 fail, C2 pass, C3 pass
- strength: no calibrated thresholds — full/faithful: C1 fail, C2 pass, C3 pass; full/stale: C1 pass, C2 pass, C3 pass
- quantifier-order: no calibrated thresholds — full/faithful: C1 fail, C2 pass, C3 pass; full/stale: C1 pass, C2 pass, C3 pass
- totalization: calibrated thresholds (error 0.2, warning 0.5) — full/faithful: C1 pass, C2 pass, C3 pass; full/stale: C1 pass, C2 pass, C3 pass
- exclusions: calibrated thresholds (error 0.2, warning 0.5) — full/faithful: C1 pass, C2 pass, C3 pass; full/stale: C1 pass, C2 pass, C3 pass
- correspondence: calibrated thresholds (error 0.2, warning 0.5) — C1 pass, C2 pass, C3 pass
- default state: `full` (mean coverage and strength AUC in thousandths: full 935, statement 875, explanation 653; ties keep full)
- coverage reads the Lean statement: true (statement-only AUC 847, full-state stale-explanation AUC 940; rule: both at least 800)
- strength reads the Lean statement: true (statement-only AUC 904, full-state stale-explanation AUC 980; rule: both at least 800)
