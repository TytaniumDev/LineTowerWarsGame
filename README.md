# Line Tower Wars

A 2.5D tower defense game for Steam (Windows, Steam Deck, macOS) that mixes Line Tower Wars
mazing and creep sends with async battles against other players' saved builds.

- Spec: [docs/PRD.md](docs/PRD.md)
- Contributor guide and conventions: [CLAUDE.md](CLAUDE.md)

## Getting started

1. Install [Godot 4.7.2](https://godotengine.org/download) and Git LFS (`git lfs install`).
2. Open `project.godot` in Godot and press Play.
3. Run the tests from the gdUnit4 panel in the editor, or see the commands in `CLAUDE.md`.

## Controls

| Action | Keyboard / mouse | Controller |
| --- | --- | --- |
| Move the build cursor | Arrows / WASD / mouse | D-pad / left stick |
| Place the chosen tower | Space / left click | A |
| Sell the tower under the cursor | X / right click | X |
| Upgrade the tower under the cursor | U, or click an upgrade in the panel | B, then pick a branch with A |
| Previous / next tower type | Q / E | LB / RB |
| Switch between maze and side panel | Tab | Y |
| Ready for battle | Enter | Start |
| Open the pause menu (pauses battles) | Esc / P | Back |
| Change battle speed (×1, ×2, ×4) | F | Right stick click |

All of these are Godot input actions (Project Settings → Input Map), so they can be rebound.
