# We're Hiring

[简体中文](README.zh-CN.md)

*We're Hiring* is a single-player narrative management game built with Godot 4. You run a Bay Area AI startup, balancing cash, compute, fundraising, hiring, and the growing temptation to delegate your work to an increasingly capable internal model.

The model makes each week easier. It may also become the real author of the company.

## Highlights

- Three origins, each with its own prologue: why you ended up at that garage door
- A complete five-chapter campaign spanning 45 in-game weeks
- Interlocking systems for fundraising, hiring, equity, offices, and SaaS
- Fixed and dynamic narrative events with branching outcomes
- Playable night-shift scenes beyond the management dashboard
- Multiple endings, autosave, and a New Game Plus opening
- Full mouse, keyboard, and gamepad support
- Original Chinese-language writing and artwork

## Run the game

Godot 4.7 is recommended. A compatible Godot 4.x desktop build may also work.

1. Clone the repository with Git LFS installed:

   ```bash
   git lfs install
   git clone git@github.com:ancientmodern/godot-we-are-hiring.git
   cd godot-we-are-hiring
   git lfs pull
   ```

2. Import `project.godot` in the Godot project manager.
3. Press **F5** to run the main scene.

On Windows, `run_game.bat` can locate Godot through `GODOT_EXE`, common Steam paths, or `PATH`.

## Controls

- **Mouse:** select and interact
- **Keyboard:** arrow keys or `W`/`S` to navigate, `Enter`/`Space` to confirm, `E` to advance
- **Shortcuts:** `T` team, `C` calendar, `A` announcements, `I` intranet, `` ` `` terminal
- **Gamepad:** D-pad to navigate, `A` to confirm, `B` to return
- **Settings:** `F1` or gamepad `Start`; `F11` toggles fullscreen

## Development

The repository includes automated tests for campaign flow, business systems, content integrity, saving, input, UI contracts, audio, and asset verification. Detailed commands and spoiler-heavy implementation notes are kept in [`docs/development-readme.zh-CN.md`](docs/development-readme.zh-CN.md).

## Status and license

This is a development build. The complete campaign is implemented, but formal player-experience validation is still pending.

The bundled Noto fonts are distributed under the SIL Open Font License 1.1. No license has yet been granted for the project's original code, writing, or artwork; public availability does not imply permission to copy, modify, or redistribute them.
