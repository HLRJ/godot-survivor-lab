# Lesson 03 碰撞 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给 Player 加上真实物理碰撞，并放置一个可见的 TrainingWall，让玩家能亲手体验 CollisionShape2D、StaticBody2D 与 Collision Layer/Mask。

**Architecture:** `Player.tscn` 继续作为玩家实体，只新增一个较小的 `CollisionShape2D`；新建 `TrainingWall.tscn`，根节点使用 `StaticBody2D`，视觉用 `Polygon2D`，物理形状用 `CollisionShape2D`。`Main.tscn` 只负责实例化 Player 与 TrainingWall，不把碰撞逻辑塞进主场景。

**Tech Stack:** Godot 4.7.2 stable、GDScript、Git + GitHub、Windows first。

**Spec:** `docs/superpowers/specs/2026-09-13-learning-first-course-design.md`

## Global Constraints

- 第一目标仍是维护者自己快速学会 Godot，教学包装不能拖慢学习。
- 本课最多引入 3 个核心概念：`CollisionShape2D`、`StaticBody2D`、Collision Layer/Mask。
- 不提前加入敌人、动画、相机、血量或复杂物理材质。
- 必须有肉眼可见结果：玩家向右移动时会被训练墙挡住。
- 必须保留亲手实验：关闭 Player 的 Mask Layer 1 后能穿墙，恢复后再次被挡住。
- 中文为主；Godot Node/API、GDScript 标识和 Git 命令保留官方英文名称。

---

## File Map
- Modify: `scenes/player/Player.tscn` — 给 Player 添加碰撞形状。
- Create: `scenes/world/TrainingWall.tscn` — 一个可复用的静态训练墙。
- Modify: `scenes/main/Main.tscn` — 实例化 TrainingWall 并更新状态文字。
- Create: `tests/lesson_03_collision_test.gd` — 验证结构、Layer/Mask 和实际阻挡行为。
- Create: `docs/concepts/collision-layer-mask.md` — 碰撞心智模型。
- Create: `docs/lessons/03-collision.md` — 本课中文教程与亲手实验。
- Modify: `README.md` — 增加 Lesson 03 入口并更新当前进度。

### Task 1: 先写会失败的碰撞行为测试

**Files:**
- Create: `tests/lesson_03_collision_test.gd`

**Interfaces:**
- Consumes: `Main.tscn`、`Player.tscn`、Lesson 02 的 `move_right` Input Action。
- Produces: 可重复验证“玩家存在碰撞形状、训练墙存在、向右撞墙后不能穿过去”的 Godot headless 测试。

- [ ] **Step 1: 创建失败测试**

测试必须加载 `Main.tscn`，检查：

```gdscript
var player := main.get_node_or_null("Player") as CharacterBody2D
var wall := main.get_node_or_null("TrainingWall") as StaticBody2D
```

并要求 Player 下存在 `CollisionShape2D`、Wall 下存在 `CollisionShape2D`。
- [ ] **Step 2: 验证测试先失败**

Run:

```powershell
<GODOT_EXE> --headless --path . -s res://tests/lesson_03_collision_test.gd
```

Expected：FAIL，至少包含“Player 缺少 CollisionShape2D”或“TrainingWall 不存在”。

- [ ] **Step 3: 测试实际阻挡行为**

测试中持续按住 `move_right` 约 120 个 physics frame：

```gdscript
Input.action_press("move_right")
for i in range(120):
    await physics_frame
Input.action_release("move_right")
```

Expected：实现前玩家会穿过未来训练墙位置，因此 RED；实现后 Player 的 X 坐标应停在墙左侧。

### Task 2: 实现最小碰撞场景

**Files:**
- Modify: `scenes/player/Player.tscn`
- Create: `scenes/world/TrainingWall.tscn`
- Modify: `scenes/main/Main.tscn`

**Interfaces:**
- Produces: `Player/CollisionShape2D`；`Main/TrainingWall`；两者都使用 Layer 1 / Mask 1。
- [ ] **Step 1: 给 Player 增加较小的矩形碰撞体**

在 `Player.tscn` 中新增：

```ini
[sub_resource type="RectangleShape2D" id="RectangleShape2D_player"]
size = Vector2(36, 44)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_player")
```

Player 继续使用 `CharacterBody2D`，并显式保持：

```ini
collision_layer = 1
collision_mask = 1
```

- [ ] **Step 2: 创建可见 TrainingWall**

`TrainingWall.tscn` 使用：

```text
TrainingWall (StaticBody2D)
├── Visual (Polygon2D)
└── CollisionShape2D
```

墙体碰撞形状大小固定为 `100 × 180`，视觉矩形与碰撞形状一致；Layer 1 / Mask 1。
- [ ] **Step 3: 在 Main 中放置训练墙**

实例化：

```ini
[node name="TrainingWall" parent="." instance=ExtResource("2_training_wall")]
position = Vector2(850, 360)
```

Player 仍从 `(640, 360)` 出发，所以持续按 D 会正面撞到墙。

状态文字更新为：

```text
Lesson 03 - 碰撞与 Layer / Mask
```

- [ ] **Step 4: 跑 GREEN 测试**

Run:

```powershell
<GODOT_EXE> --headless --path . --editor --quit
<GODOT_EXE> --headless --path . -s res://tests/lesson_03_collision_test.gd
```

Expected：Godot 首次扫描完成，测试 PASS；Player 最终 X 坐标小于 TrainingWall 中心 X，不能穿墙。

### Task 3: 写教程并保留亲手实验

**Files:**
- Create: `docs/concepts/collision-layer-mask.md`
- Create: `docs/lessons/03-collision.md`
- Modify: `README.md`
- [ ] **Step 1: 概念页只解释够用的碰撞模型**

必须说明：

- `CollisionShape2D` 决定“哪里算碰到”，不是负责画图。
- `CharacterBody2D` 是主动移动的角色；`StaticBody2D` 是不移动的墙、地形等静态物体。
- Layer 可以理解为“我在哪一层”，Mask 可以理解为“我关心哪些层”。

不提前讲 Area2D、RayCast、PhysicsMaterial。

- [ ] **Step 2: Lesson 03 保留真实实验**

用户先运行确认 Player 撞墙会停下，然后在 Player 根节点 Inspector 中：

```text
Collision → Mask → Layer 1: On → Off
```

再次运行并按 D。Expected：Player 可以穿过 TrainingWall。

然后恢复 Layer 1 Mask 为 On，保存场景并再次确认会被墙挡住。

- [ ] **Step 3: 更新 README**

新增 Lesson 03 入口，并将当前进度改为：

```text
Lesson 03 已完成：Player 已有真实碰撞体，并理解 CharacterBody2D、StaticBody2D 与 Layer / Mask。下一步 Lesson 04：敌人追踪。
```

- [ ] **Step 4: 最终验证与 Checkpoint**

依次执行完整 editor init、Lesson 02 回归测试、Lesson 03 测试、主场景 headless run、`git diff --check` 和公开安全扫描。

Checkpoint Tag：

```text
lesson-03-collision
```

合并继续使用普通 merge commit，不 squash Lesson 提交。
