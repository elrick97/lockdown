## 1. Fader

- [x] 1.1 `scene_wipe.gdshader` (fog-noise dissolve, plain fade mode)
- [x] 1.2 `SceneFader` autoload: cover/swap/reveal, input blocked, reduced motion, `instant`
- [x] 1.3 Call sites in RunCoordinator, start, throw screens

## 2. Verification

- [x] 2.1 Tests: cover blocks input, reveal releases it, shared noise, plain fade under reduced motion
- [x] 2.2 GUT green; playthrough transition scenario + screenshot; harness uses instant swaps elsewhere
