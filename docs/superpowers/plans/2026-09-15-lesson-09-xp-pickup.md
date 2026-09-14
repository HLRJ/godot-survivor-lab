# Lesson 09 XP Pickup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Player 身体接触 ExperienceGem 时获得经验值，经验球随后消失，并把这一流程做成一节可亲手学习的 Godot 课程。

**Architecture:** `ExperienceGem` 从纯 `Node2D` 升级为 `Area2D`，自己监听 `body_entered`；Player 通过 `player` Group 被识别，并持有最小 `experience` 状态及 `add_experience(amount)`。不引入 HUD、GameManager、拾取半径或升级逻辑。

**Tech Stack:** Godot 4.7.2 stable, GDScript, Git worktree, headless Godot tests

**Spec:** `docs/superpowers/specs/2026-09-15-lesson-09-xp-pickup-design.md`

## Global Constraints

- 中文教学为主，Godot API / Node / GDScript 标识保留英文。
- 每课新增概念尽量不超过 3 个。
- Lesson 09 只做身体接触拾取，不做吸附、拾取半径、HUD、升级三选一或 GameManager。
- 核心 GDScript 由学习者亲手完成；AI 只负责测试、Scene 脚手架、文档与 Git。
- 继续使用 `lesson-09-xp-pickup` 作为课程 Checkpoint Tag。

---### Task 1: Lesson 09 RED 测试与 Scene 脚手架

**Files:**
- Create: `tests/lesson_09_xp_pickup_test.gd`
- Modify: `scenes/pickups/ExperienceGem.tscn`
- Create: `scripts/pickups/experience_gem.gd`

**Interfaces:**
- Consumes: `Player.tscn`, existing ExperienceGem visual, Godot `Area2D.body_entered`.
- Produces: `ExperienceGem` as `Area2D` with `CollisionShape2D` and attached script; failing assertions for Player group / XP API / pickup behavior.

- [ ] **Step 1: Write the failing test**

Test must assert that ExperienceGem root is `Area2D`, has `CollisionShape2D`, Player belongs to `player`, Player exposes `experience` and `add_experience(amount)`, and simulated overlap increases XP then frees the gem.

- [ ] **Step 2: Run Lesson 09 test to verify RED**

Run:
```powershell
& $godot --headless --path $wt --script res://tests/lesson_09_xp_pickup_test.gd
```
Expected: non-zero exit because Player group / XP API / pickup callback do not yet exist.

- [ ] **Step 3: Add only non-conceptual Scene scaffolding**

Convert ExperienceGem root to `Area2D`, preserve existing Sprite2D scale `Vector2(2, 2)`, add a small `CollisionShape2D`, and attach `scripts/pickups/experience_gem.gd`. Do not write the pickup callback body for the learner.

- [ ] **Step 4: Re-run RED**

Expected: Scene structure assertions improve, but Lesson 09 remains red until learner writes Player XP state and pickup logic.
### Task 2: Learner implements Player XP state

**Files:**
- Modify: `scripts/player/player.gd`
- Modify: `scenes/player/Player.tscn`

**Interfaces:**
- Consumes: existing Player movement code.
- Produces: Player in group `player`, `var experience: int = 0`, and `func add_experience(amount: int) -> void`.

- [ ] **Step 1: Teaching gate — explain only the delta**

Show the learner that movement code remains unchanged. New data flow is only:
```gdscript
var experience: int = 0

func add_experience(amount: int) -> void:
    experience += amount
```
Explain caller, parameter source, and state mutation before editing.

- [ ] **Step 2: Learner personally writes Player XP code**

Do not write these core lines for the learner. Ask them to add the state and method, then add Player to the `player` Group in the editor.

- [ ] **Step 3: Inspect actual saved files**

Verify `player.gd` and `Player.tscn`; do not proceed from a verbal “done” alone.

- [ ] **Step 4: Re-run Lesson 09 test**

Expected: Player-related assertions pass; pickup behavior still fails until Task 3.
### Task 3: Learner completes ExperienceGem pickup chain

**Files:**
- Modify: `scripts/pickups/experience_gem.gd`

**Interfaces:**
- Consumes: built-in `body_entered(body)`, Player group `player`, Player method `add_experience(amount)`.
- Produces: touching Player grants `1` XP and queues the gem for deletion.

- [ ] **Step 1: Teaching gate — predict callback flow**

Before code, ask the learner to predict this chain:
```text
Player enters ExperienceGem Area2D
→ body_entered emits Player
→ callback receives body
→ Group check accepts only player
→ body.add_experience(1)
→ ExperienceGem.queue_free()
```

- [ ] **Step 2: Learner writes the core GDScript**

Target implementation:
```gdscript
extends Area2D

@export var experience_value: int = 1

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return
    body.call("add_experience", experience_value)
    queue_free()
```
Do not type this into the file on the learner's behalf; use it only as the acceptance target.

- [ ] **Step 3: Inspect saved script and run Lesson 09 test**

Expected: `PASS: Lesson 09 xp pickup` and exit code `0`.

- [ ] **Step 4: F5 prediction / observation**

Learner predicts: walking onto a gem removes it and increments Player XP. Since there is no HUD yet, temporarily use Output or debugger inspection only if needed; do not add UI.
### Task 4: Lesson 09 docs, regression verification, checkpoint

**Files:**
- Create: `docs/lessons/09-xp-pickup.md`
- Modify: `README.md`
- Modify: `scenes/main/Main.tscn`

**Interfaces:**
- Consumes: final working pickup flow from Tasks 2–3.
- Produces: public lesson documentation, Main status text for Lesson 09, README progress, Git checkpoint.

- [ ] **Step 1: Write the lesson from the actual learning path**

Document continuity from Lesson 07 `body_entered`, Lesson 08 custom Signal and ExperienceGem spawning, then Lesson 09 Group + Player XP state. Explicitly explain where `body` comes from and why the gem owns its own `queue_free()`.

- [ ] **Step 2: Update visible course state**

Set Main status to `Lesson 09 - 拾取经验`; add Lesson 09 navigation/progress to README. Do not add HUD.

- [ ] **Step 3: Run complete regression suite**

Run Godot import, Lesson 02 through Lesson 09 tests, Main headless, and `git diff --check`. All exits must be `0`; inspect stderr for `SCRIPT ERROR` even if process exit is `0`.

- [ ] **Step 4: Commit implementation/docs**

Use focused commits such as:
```bash
git commit -m "feat: add lesson 09 xp pickup"
git commit -m "docs: finalize lesson 09 learning state"
```

- [ ] **Step 5: Create checkpoint and integrate through PR**

Create annotated tag `lesson-09-xp-pickup`. Push branch + tag, create PR into `main`, use a normal merge commit (no squash/rebase), then verify the merged `main` again before cleaning the worktree and feature branch.
