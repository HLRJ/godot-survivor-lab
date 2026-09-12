# Godot Survivor Lab — Learning-First Course Design v1

## 1. Purpose and Priority

Godot Survivor Lab is first a personal rapid-learning project, and second an open-source teaching project.

Priority is strict:

1. **Primary:** help the maintainer learn Godot 4 quickly by building a visible, playable Survivor-like game.
2. **Secondary:** package that same path so another beginner can follow it with minimal friction.
3. **Never:** add teaching ceremony, community features, or documentation work that slows the primary learning loop without clear payoff.

A design decision is accepted only if it improves one or both of these goals without materially slowing the first.

## 2. Target Learner

The primary learner profile is:

- Has little or no Godot experience.
- May know some programming, but the course must not assume game-engine knowledge.
- Learns better by making visible things than by reading theory first.
- Wants a fast path to a small playable game rather than a complete survey of the engine.
- Uses Windows desktop and Godot 4.7.2 stable for the first path.

The public teaching audience is intentionally the same profile. This avoids maintaining two different learning experiences.

## 3. Learning Philosophy

The course uses **result-first, concept-second** learning.

Each lesson follows this loop:

1. Start with a visible gameplay goal.
2. Introduce only the Godot concepts required for that goal.
3. Build the smallest working version.
4. Run it immediately.
5. Change one parameter or behavior to create intuition.
6. Explain why the code and nodes work.
7. Record a checkpoint so the learner can recover from mistakes.

The course does **not** teach GDScript syntax as a standalone prerequisite. Syntax is introduced only when a gameplay need makes it useful.

## 4. Core Learning Constraints

Every mainline lesson must satisfy all of the following:

- Target duration: **20–45 minutes** for the primary learner.
- Maximum new core concepts: **3** per lesson whenever practical.
- Must produce a visible or audible result by the end.
- Must end in a runnable Godot project state.
- Must have a recovery checkpoint.
- Must include at least one tiny experiment where the learner changes a value and predicts the result.
- Must not require external asset hunting; required assets are already present in the repository.
- Must not require optional tooling to continue the main path.

If a lesson cannot fit those constraints, it should be split.

## 5. Product Scope

The first complete learning product is a minimal 2D Survivor-like with:

- WASD / arrow-key movement.
- Enemy spawning and pursuit.
- Automatic attacks.
- Damage, health, and death.
- XP drops and pickup.
- Level-up choices.
- A small weapon/data system using `Resource` only after the need becomes obvious.
- HUD and game timer.
- Game-over and restart loop.
- Basic game feel: hit feedback, sound, simple effects.
- Windows export.
- Basic Git/GitHub workflow.
- Basic GitHub Actions validation after the game is already playable.

The first learning product explicitly excludes:

- Multiplayer.
- Mobile export.
- Steam integration.
- Save systems.
- ECS.
- Complex state machines.
- Plugin architecture.
- C# track.
- Full commercial art pipeline.
- Large skill trees.
- GitHub Pages documentation site.
- English localization of the course.

These may be future extensions, but none may block v1 learning completion.

## 6. Teaching Architecture

The repository has three documentation layers.

### 6.1 Mainline lessons

Path: `docs/lessons/`

Purpose: the only path a beginner must follow from start to finish.

A learner should be able to ignore every other documentation folder and still complete the game.

### 6.2 Concept notes

Path: `docs/concepts/`

Purpose: deeper explanations of Godot concepts encountered in lessons, for example:

- Scene and Node.
- `_process` vs `_physics_process`.
- Input actions.
- Collision layers and masks.
- Signals.
- PackedScene and `instantiate()`.
- Timer.
- Resource.
- Autoload.

Mainline lessons link here only as optional depth. A concept note must never become a prerequisite unless the lesson explicitly says so.

### 6.3 Troubleshooting notes

Path: `docs/troubleshooting/`

Purpose: solve common beginner blockers with symptom-first navigation.

Examples:

- Player does not move.
- Input action is missing.
- Collision does not trigger.
- Area2D signal does not fire.
- Spawned scene is invisible.
- `null instance` errors.
- Pixel art looks blurry.
- Scene path cannot be loaded.

Troubleshooting pages should start from what the learner sees, not from engine terminology they may not know yet.

## 7. Standard Lesson Contract

Every lesson file uses the same structure:

1. **本课目标** — one sentence describing the visible result.
2. **完成效果** — what the learner should see or hear.
3. **本课只学这些** — normally no more than three core concepts.
4. **开始前检查** — exact prior checkpoint and required files.
5. **动手做** — editor actions and minimal code in small steps.
6. **代码说人话** — explain intent before terminology.
7. **运行检查** — exact observable success criteria.
8. **如果失败** — 3–5 likely beginner mistakes with links to troubleshooting pages.
9. **小实验** — change one value/behavior and predict the result.
10. **学习检查** — 3–5 short questions the learner should answer in their own words.
11. **可选挑战** — optional, never required by the next lesson.
12. **Checkpoint** — exact Git tag and what it represents.

The lesson must show complete code when the learner needs a full file, but avoid unexplained large code dumps.

## 8. Code Architecture for Learning

The codebase intentionally starts simple and evolves only when a real pain point appears.

Initial gameplay units:

- `Player`
- `Enemy`
- `EnemySpawner`
- `Projectile`
- `ExperienceGem`
- `HUD`
- `GameManager`

Rules:

- Prefer one clear responsibility per scene/script.
- Avoid abstract base classes until duplication is visible and worth discussing.
- Avoid global event buses early.
- Introduce `Resource` only when weapon/upgrade data needs to be separated from behavior.
- Introduce Autoload only when a persistent/global responsibility is clearly useful.
- Refactoring itself can become a lesson when it teaches why the new structure exists.

This means early code is allowed to be simpler than a production architecture, as long as it is readable and does not create a dead end.

## 9. Git as a Teaching Mechanism

`main` represents the latest complete course state and must remain runnable.

Development uses short-lived feature branches, for example:

- `feat/player-movement`
- `feat/enemy-chase`
- `feat/auto-attack`

Each lesson ends with a permanent annotated checkpoint tag:

- `lesson-00-environment`
- `lesson-01-first-scene`
- `lesson-02-player-movement`
- ...
- `lesson-18-ci`

Release milestones use semantic-like tags such as:

- `v0.1-movement`
- `v0.5-game-loop`
- `v1.0-first-playable`

The course will teach three recovery patterns:

```bash
git switch --detach lesson-04-enemy-chase
```

Use a known-good checkpoint.

```bash
git diff lesson-03-collision..lesson-04-enemy-chase
```

See exactly what changed during a lesson.

```bash
git switch main
```

Return to the latest course state.

Git is therefore both version control and a learning aid.

## 10. Curriculum Map

### Phase A — Learn Godot by Making Things Move

| Lesson | Visible result | Core concepts | Target time | Checkpoint |
| --- | --- | --- | --- | --- |
| 00 Environment | Project opens and runs locally | project.godot, editor, run project | 20 min | `lesson-00-environment` |
| 01 First Scene | A visible character appears on screen | Scene, Node, Sprite2D | 25 min | `lesson-01-first-scene` |
| 02 Player Movement | Character moves with WASD | CharacterBody2D, Input, velocity | 35 min | `lesson-02-player-movement` |
| 03 Collision | Player collides with a wall | CollisionShape2D, layer, mask | 35 min | `lesson-03-collision` |
| 04 Enemy Chase | One enemy follows the player | Vector2 direction, script reference, physics movement | 35 min | `lesson-04-enemy-chase` |
| 05 Enemy Spawning | Enemies appear repeatedly | PackedScene, instantiate, Timer | 40 min | `lesson-05-enemy-spawning` |

### Phase B — Build the Core Survivor Loop

| Lesson | Visible result | Core concepts | Target time | Checkpoint |
| --- | --- | --- | --- | --- |
| 06 Auto Attack | Player fires automatically | Timer, projectile scene, direction | 40 min | `lesson-06-auto-attack` |
| 07 Damage and Death | Enemies take damage and disappear | Area2D, signal, health | 40 min | `lesson-07-damage-death` |
| 08 XP Drops | Dead enemies drop XP gems | scene composition, signal flow, spawn-on-death | 35 min | `lesson-08-xp-drop` |
| 09 XP Pickup | Player collects XP | Area2D, groups, counters | 35 min | `lesson-09-xp-pickup` |
| 10 Level Up | Level-up pauses action and shows choices | UI Control, pause, signal | 45 min | `lesson-10-level-up` |
| 11 Upgrade Data | A chosen upgrade changes combat | Resource, exported data, separation of data/behavior | 45 min | `lesson-11-upgrade-data` |

### Phase C — Make It Feel Like a Game

| Lesson | Visible result | Core concepts | Target time | Checkpoint |
| --- | --- | --- | --- | --- |
| 12 HUD | HP, level, XP, and timer are visible | Control, ProgressBar, labels | 40 min | `lesson-12-hud` |
| 13 Game Manager | Round state is coordinated cleanly | Autoload, responsibility, signals | 40 min | `lesson-13-game-manager` |
| 14 Death and Restart | Player can lose and immediately retry | game state, reload scene, UI flow | 35 min | `lesson-14-restart-loop` |
| 15 Game Feel | Hits feel responsive | audio, hit flash, simple screen feedback | 45 min | `lesson-15-game-feel` |

### Phase D — Learn to Ship

| Lesson | Visible result | Core concepts | Target time | Checkpoint |
| --- | --- | --- | --- | --- |
| 16 Export | A standalone Windows build runs | export preset, build output, sanity check | 30 min | `lesson-16-windows-export` |
| 17 Git/GitHub | Learner can branch, commit, diff, and recover | branch, commit, tag, diff | 35 min | `lesson-17-git-workflow` |
| 18 CI | GitHub validates the Godot project automatically | Actions, headless check, workflow result | 40 min | `lesson-18-ci` |

The order is intentional: Git is used throughout the project, but the formal Git lesson comes late so tooling theory does not delay early gameplay learning. Short Git commands needed earlier are taught just-in-time.

## 11. Lesson Progression Rules

Before adding a lesson, verify:

- It has one dominant visible outcome.
- It introduces no more theory than the outcome requires.
- The next lesson does not depend on optional challenges.
- The checkpoint project runs independently.
- Required assets already exist locally.
- The lesson can be completed without browsing external tutorials.

A lesson that violates these rules must be split or simplified.

## 12. Asset Policy

The learning build uses bundled, license-safe starter assets so art search never interrupts learning.

Current source:

- Kenney Roguelike Characters — CC0.
- Kenney Tiny Dungeon — CC0.
- Kenney Interface Sounds — CC0.

Third-party assets remain under `assets/third_party/` and retain their own license files.

Art direction may be improved later, but no lesson may be blocked by unfinished custom art.

## 13. Documentation Style

Chinese is the primary course language for v1.

Writing rules:

- Explain intent before jargon.
- Prefer short paragraphs and concrete examples.
- Use the exact Godot editor labels visible in version 4.7.2.
- When introducing terminology, immediately connect it to the gameplay result.
- Avoid pretending a simplified explanation is the full truth; mark deeper details as optional.
- Do not require a learner to copy more code than they can reasonably understand in that lesson.
- Prefer screenshots only when editor location or visual state is genuinely hard to describe in text.

## 14. Validation Strategy

Every lesson checkpoint must pass three levels of validation.

### Level 1 — Engine load

Godot 4.7.2 must load the project headlessly with exit code 0.

### Level 2 — Lesson-specific sanity check

The lesson defines an observable success condition, for example:

- player position changes after movement input,
- enemy scene instantiates,
- projectile collision emits the expected signal,
- restart returns to a clean game state.

Where practical, logic is extracted into small testable functions. The project will not add a heavy testing framework before it produces learning value.

### Level 3 — Human beginner check

The maintainer follows the lesson as written from the previous checkpoint. If instructions require unstated knowledge, missing files, or external searching, the lesson is not complete.

The primary learner's own experience is the first usability test before optimizing for strangers.

## 15. Error and Recovery Design

The project treats learner recovery as a first-class feature.

For each lesson:

- The previous checkpoint is named explicitly.
- The finished checkpoint is named explicitly.
- Common failure symptoms are documented.
- Broken local work can be compared with the finished checkpoint using Git.
- No lesson should require deleting the whole project and starting over.

Troubleshooting documentation is added when a real blocker appears during the primary learning path, then generalized for other beginners.

## 16. Open-Source Policy

The repository will become public only after the learning-first documentation baseline is coherent enough that a stranger can understand what the project is.

Planned licensing:

- Project source code: **MIT License**.
- Original teaching documentation: **CC BY 4.0**.
- Kenney assets: retain **CC0** terms from the bundled source licenses.

`LICENSES.md` will explain the boundary between code, original documentation, and third-party assets.

Community features such as issue templates, Discussions, Good First Issues, and GitHub Pages are deferred until the main learning path is usable.

## 17. Repository Structure Target

```text
godot-survivor-lab/
├── assets/
│   └── third_party/
├── scenes/
│   ├── main/
│   ├── player/
│   ├── enemies/
│   ├── weapons/
│   ├── pickups/
│   └── ui/
├── scripts/
├── resources/
├── docs/
│   ├── lessons/
│   ├── concepts/
│   ├── troubleshooting/
│   ├── learning-notes/
│   └── superpowers/
├── .github/
│   └── workflows/
├── README.md
├── LICENSE
├── LICENSES.md
└── project.godot
```

Directories are created only when their first real file is needed; empty architecture is avoided.

## 18. Definition of Success

### Primary success

The maintainer can move from current bootstrap state to `v1.0-first-playable` while:

- understanding why each major node/script exists,
- being able to modify small gameplay behaviors without asking for full rewrites,
- being able to diagnose basic Godot errors,
- using Git confidently enough to experiment without fear of breaking the project,
- producing a standalone playable Windows build.

### Secondary success

After the primary path has been completed and corrected from real experience, a fresh beginner can clone the repository, start at Lesson 00, and reach the same playable result without needing an external tutorial.

The secondary success metric must never cause the project to slow down the primary learning loop prematurely.

## 19. Implementation Order After Approval

Once this design is approved, implementation proceeds in this order:

1. Rework README into a learning-first course landing page.
2. Add license boundaries and contribution expectations.
3. Create `docs/lessons/00-environment.md` and its checkpoint.
4. Create `docs/lessons/01-first-scene.md` and its checkpoint.
5. Start Lesson 02 player movement as the first meaningful gameplay feature.
6. Continue one lesson at a time; after each lesson, run validation, write the lesson, tag the checkpoint, and only then move on.
7. Make the repository public after the initial learning path and licensing presentation are coherent enough for external readers.

This order deliberately prevents public-facing polish from delaying the maintainer's actual Godot learning.
