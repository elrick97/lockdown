## 1. Overlay

- [x] 1.1 Fog shader (domain-warped seamless noise, edge/bottom mask, warm smoke, vignette kept); grain removed
- [x] 1.2 Shared fixed-seed NoiseTexture2D in `SmokeOverlay`

## 2. Verification

- [x] 2.1 Test: overlay has the noise texture, no grain uniform, still ignores input; consecutive frames differ by < a small threshold at the edge
- [x] 2.2 GUT green; playthrough + screenshots reviewed; web build checked
