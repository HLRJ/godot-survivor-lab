# Lesson 04 Enemy 追踪 Player Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增一个 Enemy Scene，让敌人持续朝 Player 当前所在位置移动，并让学习者亲手体验追踪速度变化。

**Architecture:** `Enemy.tscn` 使用 `CharacterBody2D`，包含 Sprite2D、CollisionShape2D 与 `enemy.gd`。Enemy 作为 Main 的直接子节点，通过相对路径 `../Player` 获取 Player 引用；每个 physics frame 用 `global_position.direction_to(player.global_position)` 计算方向，再复用 `velocity + move_and_slide()`。

**Tech Stack:** Godot 4.7.2 stable、GDScript、Git + GitHub、Windows first。

**Spec:** `docs/superpowers/specs/2026-09-13-learning-first-course-design.md`

## Global Constraints

- 本课最多引入 3 个核心概念：Node 引用、`direction_to()`、复用 `CharacterBody2D` 移动模型。
- 不提前加入刷怪、伤害、状态机、导航网格、动画或 GameManager。
- 必须有肉眼可见结果：Enemy 会持续改变方向追踪移动中的 Player。
- Enemy 初始位置必须避开 TrainingWall，确保第一眼就能追到 Player。
- 中文为主；Godot Node/API、GDScript 标识和 Git 命令保留官方英文名称。
- 学习者必须亲手把 Enemy `Speed` 从 110 改成 220，观察后恢复 110。

---

## File Map

- Create: `scenes/enemies/Enemy.tscn` — 第一个可复用敌人 Scene。
- Create: `scripts/enemies/enemy.gd` — 获取 Player 引用并持续追踪。
- Modify: `scenes/main/Main.tscn` — 实例化 Enemy 并更新状态文字。
- Create: `tests/lesson_04_enemy_chase_test.gd` — 验证结构和真实追踪行为。
- Create: `docs/concepts/node-reference-and-direction.md` — Node 引用与方向向量的最小心智模型。
- Create: `docs/lessons/04-enemy-chase.md` — 中文课程与亲手实验。
- Modify: `README.md` — 增加 Lesson 04 入口和当前进度。

---
### Task 1: RED — 证明 Enemy 追踪功能还不存在

**Files:**
- Create: `tests/lesson_04_enemy_chase_test.gd`

**Interfaces:**
- Consumes: `Main.tscn` 中已有 `Player`。
- Produces: 一个在功能缺失时稳定失败、功能完成后稳定通过的 headless 测试。

- [ ] **Step 1: 写失败测试**

测试必须验证：
- Main 存在 `Enemy`；
- Enemy 是 `CharacterBody2D`；
- Enemy 有 `CollisionShape2D` 与脚本；
- Enemy 默认 `speed` 为 110；
- Player 静止时，等待 60 个 physics frame 后 Enemy 到 Player 的距离明显变小。

- [ ] **Step 2: 运行并确认 RED**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --script res://tests/lesson_04_enemy_chase_test.gd
```

Expected: exit 1，失败原因包含 `Main must contain Enemy`。

---

### Task 2: GREEN — 创建最小 Enemy 追踪实现

**Files:**
- Create: `scenes/enemies/Enemy.tscn`
- Create: `scripts/enemies/enemy.gd`
- Modify: `scenes/main/Main.tscn`

**Interfaces:**
- Enemy root: `CharacterBody2D`
- Exported property: `@export var speed: float = 110.0`
- Runtime player reference: `@onready var player: Node2D = get_node("../Player")`

- [ ] **Step 1: 创建 `enemy.gd`**

```gdscript
extends CharacterBody2D

@export var speed: float = 110.0
@onready var player: Node2D = get_node("../Player")

func _physics_process(_delta: float) -> void:
    var direction := global_position.direction_to(player.global_position)
    velocity = direction * speed
    move_and_slide()
```
- [ ] **Step 2: 创建 `Enemy.tscn`**

Scene tree：

```text
Enemy (CharacterBody2D)
├── Sprite2D
└── CollisionShape2D
```

要求：
- Sprite 继续复用 Kenney 角色图集，但使用不同 region 或明显 tint，避免和 Player 混淆；
- CollisionShape2D 使用简单 RectangleShape2D；
- Enemy 与 Player 暂时都保留默认第 1 层碰撞。

- [ ] **Step 3: 在 Main 中实例化 Enemy**

初始位置使用：

```text
Vector2(420, 520)
```

这样 Enemy 到 Player 的直线路径不会先撞到右侧 TrainingWall。

- [ ] **Step 4: 跑 GREEN**

Expected: `PASS: Lesson 04 enemy chase`，exit 0。

---
### Task 3: 教学层与亲手实验

**Files:**
- Create: `docs/concepts/node-reference-and-direction.md`
- Create: `docs/lessons/04-enemy-chase.md`
- Modify: `README.md`

**Interfaces:**
- 教程只解释本课真实使用的 Node 引用、`direction_to()`、速度链路。
- 不引入 Groups、NavigationAgent2D、状态机或寻路算法。

- [ ] **Step 1: 写概念页**

必须解释：
- `get_node("../Player")` 中 `..` 表示父节点；
- Enemy 和 Player 都是 Main 的直接子节点，因此从 Enemy 先回到 Main，再找到 Player；
- `direction_to()` 返回从 Enemy 指向 Player 的单位方向；
- `velocity = direction * speed` 和 Lesson 02 是同一个移动模型。

- [ ] **Step 2: 写 Lesson 04**

亲手实验固定为：
1. 先运行并移动 Player，观察 Enemy 实时转向；
2. 把 Enemy `Speed` 从 110 改成 220；
3. 预测并观察追赶速度；
4. 恢复 110 并保存。

- [ ] **Step 3: 更新 README**

增加 Lesson 04 入口，并把当前进度更新为“Enemy 已能持续追踪 Player，下一步 Lesson 05：不断刷怪”。

---

### Task 4: 最终验证与 Checkpoint

**Files:**
- All Lesson 04 files above

- [ ] **Step 1: 自动测试**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --script res://tests/lesson_04_enemy_chase_test.gd
```

Expected: PASS，exit 0。

- [ ] **Step 2: 主场景运行**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --quit-after 3
```

Expected: exit 0。

- [ ] **Step 3: 静态检查**

```bash
git diff --check
```

Expected: exit 0；无临时文件、凭据、本机绝对路径。
- [ ] **Step 4: 学习者亲手实验**

只有学习者实际完成“移动 Player 观察追踪 + Speed 110 → 220 → 110”后，才允许创建本课 Checkpoint。

- [ ] **Step 5: 提交并打 Tag**

```bash
git add README.md scenes/enemies/Enemy.tscn scenes/main/Main.tscn scripts/enemies/enemy.gd tests/lesson_04_enemy_chase_test.gd docs/concepts/node-reference-and-direction.md docs/lessons/04-enemy-chase.md
git commit -m "feat: add lesson 04 enemy chase"
git tag -a lesson-04-enemy-chase -m "Lesson 04: enemy chases player"
```

Tag 必须指向最终可运行、Speed 已恢复为 110 的 Lesson 04 提交。
