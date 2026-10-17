# CLAUDE.md

Guidance for anyone (Claude or human) changing this repo. The product spec is
[docs/PRD.md](docs/PRD.md); its decision log is the source of truth for design choices.

## Stack

- Godot **4.7.2** with statically typed GDScript. Untyped declarations are errors.
- Tests: **gdUnit4 6.2.2**, vendored in `addons/gdUnit4/`.
- Lint and format: **gdtoolkit 4.5.0** (`gdlint`, `gdformat`), enforced in CI.
- CI: `.github/workflows/ci.yml` runs lint, tests, then Windows/Linux/macOS exports in the
  `barichello/godot-ci` image. Bump the Godot version in CI, `project.godot` and here together.

## Layout (organized by feature)

| Folder | Contents |
| --- | --- |
| `sim/` | The game rules. Plain typed classes (`RefCounted`/`Resource`), never `Node`s. No rendering, input or engine singletons. |
| `content/` | Data-only `.tres` Resources: towers, creeps, lanes, rulesets. |
| `render/render_2d/`, `render/render_3d/` | Renderers that observe the sim and draw it. |
| `ui/` | Menus, HUD and debug menus. |
| `game/` | Entry scene and app flow that wires sim, renderer and UI together. `SimRunner` drives the sim's fixed tick from frame time. |
| `test/` | gdUnit4 suites, mirroring the source path (`sim/foo.gd` → `test/sim/foo_test.gd`). |

Folders are created when their first file lands. Scenes live next to their scripts.

## Architecture rules

- The sim runs on a fixed tick (`SimConfig.TICKS_PER_SECOND`, 30). Renderers read sim state and
  interpolate; they never change it. Player actions reach the sim as commands.
- If something only works in one renderer, logic has leaked out of the sim.
- Determinism, from day one:
  1. No physics engine for gameplay; grid math only.
  2. Integers for anything that affects outcomes; no floats in `sim/`. Distances and speeds
     are milli-cells (`SimConfig.UNITS_PER_CELL` = 1000).
  3. Randomness only from `GameSim.rng` (`SimRng`), never `randi()`/`randf()` or global state.
     If the golden-sequence test fails after a Godot upgrade, stored snapshots won't replay.
  4. Pathing via `AStarGrid2D` with deterministic tie-breaking.
- Tunable numbers live in content Resources, not code. Rules Tyler wants to playtest are
  swappable `RulesetDef` variants, not hardcoded branches.
- Input goes through Godot input actions, controller first. No hardcoded keys.
- UI must stay readable at 1280×800 (Steam Deck).

## Style

- Follow the official GDScript style guide: `snake_case` files, functions and variables,
  `PascalCase` `class_name`s, `CONSTANT_CASE` constants, tabs for indentation.
- Type everything, including return types (`-> void`).
- Small, single-purpose scripts and scenes; compose components rather than growing one script.
- Doc comments (`##`) on public classes and on anything non-obvious.

## Commands

```sh
gdformat .          # format
gdformat --check .  # what CI checks
gdlint .
export GODOT_BIN=/path/to/godot
./addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://test
```

`--ignoreHeadlessMode` is fine for sim tests. Tests that simulate input events need a real
display (e.g. `xvfb-run` in CI), since Godot drops input events in headless mode.

## Workflow

- Small PRs into `main`; every PR must pass CI.
- Tyler wants to be asked whenever there's a real choice to make; don't silently pick defaults.
- Review every AI change like a PR: anything that can't be explained gets simplified.
- Binary assets go through Git LFS (see `.gitattributes`); run `git lfs install` once per clone.
