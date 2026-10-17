# Line Tower Wars Game — PRD

**Status:** v3, signed off by Tyler (2026-10-17) · **Owner:** Tyler · **Source:** `Line Tower Wars Game — Design Doc.md`

> This PRD turns the design doc into something buildable. Every decision is recorded in the decision log at the bottom. Items marked as playtest areas are starting points meant to change through play.

---

## 1. Summary

A 2.5D tower defense game for Steam (Windows, Steam Deck/Linux, macOS), built in Godot with statically typed GDScript. It combines **Line Tower Wars** mazing and creep sends with **Super Auto Pets / Backpack Battles**–style async battles: each round you build a maze and pick an army, then fight another real player's saved snapshot. No real-time netcode.

## 2. Goals and non-goals

**Goals**
- G1. Prove the core loop is fun with programmer art (the offline vertical slice, §9).
- G2. A deterministic simulation, so battles can be replayed, tested and later verified server-side.
- G3. Controller-first and Steam Deck–ready from day one.
- G4. A codebase that reads the same whether Tyler or Claude wrote it (typed, linted, tested, CI), favoring widely used Godot best practices, consistency, and small reusable components.
- G5. Content (towers, creeps, upgrades) is data, so balancing is cheap.
- G6. Playtest-driven design: rules Tyler is unsure about are built as swappable variants so they can be compared in play rather than decided on paper (§5.0).

**Non-goals (for now)**
- Real-time multiplayer.
- Online backend, accounts, Steam integration (deferred until the offline loop is fun).
- Mobile or web builds.
- Monetization: deliberately undecided until the game is proven fun (D20).

## 3. Target player and platforms

- **Player:** fans of tower defense / LTW mazing and short-session autobattlers.
- **Run length:** no target yet; round count and pacing are ruleset values tuned by playtesting the slice (D19).
- **Platforms:** Windows, Linux (Steam Deck), macOS. Steam Deck is the design reference: 1280×800, 16:10, gamepad.
- **Input:** gamepad first, mouse + keyboard fully supported, all through Godot input actions.

## 4. Core loop

```
Run start → [Round: Build phase → Battle phase → Result] × N → Run end
```

### 4.1 Build phase
- Place / sell / upgrade towers on your lane's grid. Towers are walls; creeps path around them.
- Selling (D16): full refund if sold in the same build phase it was placed, 50% after that. Refund rates live in the ruleset so they can be tuned.
- A placement that fully blocks the path is rejected, with live path preview.
- Choose creeps to send (spend resources).
- Your maze persists across rounds and grows each round, as in LTW (D6).
- Untimed: the game is async, so nobody waits on you (D14).

### 4.2 Battle phase
- The opponent is a stored snapshot of another player from the same point in their run.
- **Starting variant (D4): mirror duel.** Your army runs their maze while their army runs yours, simultaneously; whoever leaks fewer creeps wins. Expected to evolve into something more complex; this is a playtest area.
- Creeps unresolved when the ruleset's battle tick limit runs out count as leaks.
- The fight is fully simulated; the player only watches, with pause and speed-up controls (D18). Active abilities could be a later ruleset variant.

### 4.3 Result and run structure
- **Starting variant (D5): Super Auto Pets style.** About 5 lives, lose one per lost battle; the run ends at 10 wins or 0 lives. Numbers are tunable and this is a playtest area.
- Your own snapshot is saved at the end of each build phase so others can fight it.

## 5. Systems

### 5.0 Rule variants for playtesting
- Battle resolution and run structure are explicitly exploratory (D4, D5). The sim takes these as pluggable rules so variants can be swapped without rewriting the core.
- Each variant is a `RulesetDef` Resource (`.tres`); a debug menu picks one before a run starts (D10). Adding a variant means adding data plus, where needed, one small rule class.

### 5.1 Grid and lane
- Square logical grid; renderers project it (isometric 2D or orthographic 3D).
- Starting lane: long and narrow, 11×30 cells, spawn at the top edge, exit at the bottom (D11). Likely to change, so lane dimensions, spawn and exit live in a `LaneDef` Resource and nothing in code assumes a fixed size.

### 5.2 Pathing
- `AStarGrid2D` with consistent tie-breaking; recomputed on placement.
- All creeps share one path field per lane. Flying creeps that ignore the maze are deferred until after the slice (D17).

### 5.3 Towers
- Data-defined `TowerDef` Resources (`.tres`): cost, footprint (1×1 for MVP), range, damage, attack rate, targeting, projectile, upgrades.
- MVP: 3 towers (D12): **Arrow** (single target), **Cannon** (splash), **Frost** (slows).
- Upgrades branch (D15): at some level a tower splits into one of two paths (e.g. Arrow → Sniper or Rapid). `TowerDef` holds a list of upgrade options, each pointing to another `TowerDef`, so linear and branching trees use one format.

### 5.4 Creeps and sends
- Data-defined `CreepDef` Resources: HP, speed, armor, bounty, send cost, income bonus.
- MVP: 4 creeps (D13): **Grunt** (the normal baseline everything is balanced around), **Swarm** (many weak), **Tank** (slow, high HP), **Runner** (fast, low HP).

### 5.5 Economy
- LTW style (D7): gold each round plus income; sending creeps permanently raises your income, so sending trades off against building.

### 5.6 Matchmaking (offline first)
- Offline: opponent snapshots come from local JSON files bundled with the game.
- Opponent is a random snapshot from the same round number, preferring a similar win/loss record (D8).

## 6. Technical requirements

Carried over from the design doc as decided.

### 6.1 Stack
- Godot 4.7.2 (newest stable at scaffold time), statically typed GDScript (untyped declarations set to error), pinned in both the project and CI (D21, D27).

### 6.2 Architecture
- `GameSim`: plain typed GDScript classes (not Nodes) on a fixed 30 Hz tick (D26). Owns all rules and state.
- Inputs: player commands + snapshots + seed. Outputs: observable state / events.
- Renderers (`Renderer2D`, `Renderer3D`) only observe and draw; each implements `screen_to_cell(pos) -> Vector2i`.
- Live debug toggle swaps renderers against the same `GameSim` mid-battle.

### 6.3 Determinism rules
1. No physics engine for gameplay; grid math only.
2. Integer / fixed-point math for anything outcome-affecting.
3. Seeded RNG owned by the sim; no global randomness.
4. `AStarGrid2D` with deterministic tie-breaking.
- **Acceptance:** the same snapshot + seed produces an identical result hash on Windows, Linux and macOS (checked in CI).

### 6.4 Snapshot format (schema v1)
| Field | Contents |
| --- | --- |
| `schema_version` | int |
| `maze` | list of `{tower_id, cell, level}` |
| `army` | creeps sent, per round |
| `economy` | resources and income at snapshot time |
| `round` | round number |
| `meta` | player/build info, game version, seed |

Stored as JSON. Maze and army are separable.

### 6.5 Rendering
- Both renderers built for the slice; final choice after comparing. Current lean: 2D.

### 6.6 Repo conventions
- Git from commit one, Git LFS for binaries, small frequent commits.
- `gdtoolkit` (`gdformat`, `gdlint`) enforced in CI.
- Tests with gdUnit4 (D9), chosen for its scene runner so input flows can be tested later. If it causes friction early, switch to GUT before many tests exist.
- `CLAUDE.md` with architecture, naming and rules.
- CI: lint, tests, headless exports for Windows/Linux/macOS on every push (GitHub Actions).

## 7. Art and audio
- Programmer art for the slice. Art direction and sourcing are decided after the slice, once it proves fun and the 2D vs 3D renderer choice is made (D22).

## 8. Deferred (post-slice)
- Backend (Nakama / Firebase / Supabase / Steam UGC), GodotSteam, achievements, leaderboards, cloud saves, macOS signing/notarization, Steam Deck Verified pass.

## 9. Milestone 1: offline vertical slice

**Exit criterion:** the slice is fun with programmer art.

- [ ] Project scaffold: folder layout, `CLAUDE.md`, lint, format, tests, CI exports
- [ ] Sim core: fixed tick, seeded RNG, determinism test
- [ ] One lane, 3 towers, 4 creeps as Resources
- [ ] Mazing with live path validation
- [ ] Build phase → battle phase vs a local JSON snapshot
- [ ] Win/lose and lives
- [ ] `Renderer2D` and `Renderer3D` with a live debug toggle

## 10. Decision log

| # | Decision | Answer | Date |
| --- | --- | --- | --- |
| D1 | Engine | Godot + typed GDScript (from design doc) | 2026-10-16 |
| D2 | Multiplayer model | Async snapshots, no real-time netcode (from design doc) | 2026-10-16 |
| D3 | Code location | GitHub repo `TytaniumDev/LineTowerWarsGame` (exists, empty) | 2026-10-16 |
| D4 | Battle resolution | Start with mirror duel (fewest leaks wins); exploration area, likely more complex after playtesting | 2026-10-16 |
| D5 | Run structure | Start with SAP style (lives, win target); exploration area | 2026-10-16 |
| D6 | Maze persistence | Persists and grows each round | 2026-10-16 |
| D7 | Economy | LTW style income; sends raise income | 2026-10-16 |
| D8 | Matchmaking | Same round number, similar record | 2026-10-16 |
| D9 | Test framework | gdUnit4; switch to GUT early if it doesn't work out | 2026-10-16 |
| D10 | Variant selection | `RulesetDef` Resources picked from a debug menu | 2026-10-16 |
| D11 | Lane shape | 11×30, data-driven so it's easy to change | 2026-10-16 |
| D12 | Starter towers | Arrow, Cannon, Frost | 2026-10-16 |
| D13 | Starter creeps | Grunt (baseline), Swarm, Tank, Runner | 2026-10-16 |
| D14 | Build timer | Untimed | 2026-10-16 |
| D15 | Tower upgrades | Branching paths | 2026-10-16 |
| D16 | Sell refund | 100% same build phase, 50% after | 2026-10-16 |
| D17 | Flying creeps | Post-slice | 2026-10-16 |
| D18 | Battle interaction | Watch only (pause, speed-up) | 2026-10-16 |
| D19 | Run length | No target; set by playtesting | 2026-10-16 |
| D20 | Monetization | Decide later | 2026-10-16 |
| D21 | Godot version | Latest stable 4.x at scaffold time, pinned | 2026-10-16 |
| D22 | Art direction | Decide after the slice | 2026-10-16 |
| D23 | PRD location | Committed to the repo as `docs/PRD.md` after sign-off, linked from `CLAUDE.md`, changed by PR | 2026-10-17 |
| D24 | Folder layout | By feature: `sim/`, `content/`, `render/`, `ui/`, `game/`, `test/` | 2026-10-17 |
| D25 | CI Godot setup | `barichello/godot-ci` Docker image | 2026-10-17 |
| D26 | Sim tick rate | 30 ticks per second | 2026-10-17 |
| D27 | Pinned versions | Godot 4.7.2, gdUnit4 6.2.2, gdtoolkit 4.5.0 | 2026-10-17 |
| D28 | Sim number format | Integer milli-cells (1000 units = 1 cell) | 2026-10-17 |
| D29 | Sim RNG | Godot's RandomNumberGenerator, wrapped in `SimRng` (integer-only), with a golden-sequence test to catch engine changes | 2026-10-17 |
| D30 | Armor | Flat armor subtracted per hit, minimum 1 damage | 2026-10-17 |
| D31 | Tower targeting | Set per tower type (First, Closest, Strongest, Unslowed) | 2026-10-17 |
| D32 | Battle contents | A standard neutral wave each round plus the opponent's sends | 2026-10-17 |
| D33 | Send order | Sent creeps enter in the order bought, evenly spaced | 2026-10-17 |
| D34 | Tower shots | Homing shots with a scheduled hit tick: no physics, never miss, visuals land with the damage | 2026-10-17 |
| D35 | Overkill | Towers count damage in flight and skip creeps already doomed | 2026-10-17 |
| D36 | Duel ties | Equal leaks is a draw: no life lost, no win | 2026-10-17 |
| D37 | Offline opponents | Your own past rounds, saved locally, plus a few hand-made seeds for an empty pool | 2026-10-17 |
| D38 | Send timing | Sends enter interleaved with the neutral wave (ruleset `send_timing`, also supports after or before the wave) | 2026-10-17 |
| D39 | Bounty | Kills pay their bounty to the defender after the battle (ruleset `bounty_percent`, default 100) | 2026-10-17 |
| D40 | Seed opponents | Generated by a simple build bot (`tools/generate_seed_snapshots.gd`) into editable JSON in `content/snapshots/`, refining D37 | 2026-10-17 |
