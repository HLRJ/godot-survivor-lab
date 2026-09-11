# Godot Survivor Lab Design

## Goal
Build a small 2D survivor game in Godot 4.7.2 as a fast learning project.
The first playable must be understandable by a beginner and improve in visible slices.

## First Playable Scope
1. WASD player movement.
2. Enemies spawn and chase the player.
3. Automatic attacks damage enemies.
4. Dead enemies drop XP pickups.
5. XP triggers a three-choice upgrade screen.
6. Player death supports restart.

## Learning Strategy
- Learn only what the current playable slice needs.
- Add one feature at a time instead of large AI-generated rewrites.
- Keep the main branch runnable.
- Finish every milestone with a visible result, Git commit, and learning note.
- Defer inventory, networking, saves, complex state machines, ECS, and C#.

## Technical Baseline
- Engine: Godot 4.7.2 stable.
- Language: GDScript.
- Platform: Windows desktop first.
- Presentation: 2D pixel art.
- Local path: `G:/AINmg/Codes/godot-survivor-lab`.
- GitHub repository: `HLRJ/godot-survivor-lab`, private.

## Asset Policy
- Use Kenney CC0 assets for the learning build.
- Keep third-party assets under `assets/third_party/`.
- Record source URL, pack name, license, and retrieval date in `LICENSES.md`.
- Art must never block gameplay implementation.

## Project Structure
- `scenes/`: reusable Godot scenes grouped by gameplay responsibility.
- `scripts/`: GDScript attached to scenes or global systems.
- `resources/`: data resources used by upgrades and later balancing.
- `assets/`: imported art and audio.
- `docs/learning-notes/`: short notes for each milestone.
- `docs/superpowers/`: design and implementation plans.

## Versioning
Milestones progress from v0.1 movement through v1.0 first playable.
Gameplay work uses short-lived feature branches and is merged only when runnable.
