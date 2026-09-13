# Lesson 07 伤害与死亡 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Lesson 06 的 Projectile 真正命中 Enemy，造成伤害，并在生命值归零时让 Enemy 死亡。

**Architecture:** 把 `Projectile.tscn` 根节点从 `Node2D` 升级为 `Area2D`，增加 `CollisionShape2D`，通过 `body_entered` Signal 接收命中事件。Enemy 增加 `max_health / health / take_damage()`；Projectile 只识别 `Enemy.tscn` 实例，命中后造成伤害并销毁自己。

**Tech Stack:** Godot 4.7.2 stable、GDScript、Area2D、CollisionShape2D、Signal、headless tests、Git。

**Spec:** `docs/superpowers/specs/2026-09-13-learning-first-course-design.md`

## Global Constraints

- 本课 20–45 分钟，最多正式引入 3 个核心概念：Area2D、Signal、Health。
- 必须保持 Lesson 06 自动攻击与可见 Projectile 行为成立。
- 不提前做经验掉落、升级、HUD、对象池、Group 或复杂敌人管理。
- Projectile 默认伤害 `1`；Enemy 默认最大生命值 `3`。
- 用户实验固定为 Enemy `Max Health 3 → 1 → 3`。
- Checkpoint Tag：`lesson-07-damage-and-death`。

---
### Task 1: RED — 验证“命中、掉血、死亡”目前不存在

**Files:**
- Create: `tests/lesson_07_damage_and_death_test.gd`

**Interfaces:**
- Consumes: `Main.tscn`、`Enemy.tscn`、`Projectile.tscn`。
- Produces: 一个真实实例化 Enemy/Projectile 并验证碰撞伤害与死亡的 headless 测试。

- [ ] **Step 1: 写失败测试**

测试创建 Main，但停止 EnemySpawner 和 Weapon Timer；随后手工把一个 Enemy 放在 Player 右侧，并把 Enemy `speed` 设为 `0`。

测试必须先断言：
- Projectile 根节点是 `Area2D`；
- Projectile 有 `CollisionShape2D`；
- Enemy 默认 `max_health == 3`；
- Enemy 进入树后 `health == 3`；
- Projectile 默认 `damage == 1`。

然后创建一个朝右飞行的 Projectile，等待真实 physics frame，预期 Enemy `health` 从 `3` 变成 `2`，Projectile 被销毁。
- [ ] **Step 2: 验证 RED**

运行：

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --script res://tests/lesson_07_damage_and_death_test.gd
```

Expected: exit 1，失败原因至少包含 `Projectile root must be Area2D` 或 `Enemy must expose max_health`。

---

### Task 2: GREEN — 给 Enemy 加最小生命值

**Files:**
- Modify: `scripts/enemies/enemy.gd`

**Interfaces:**
- Exported property: `@export var max_health: int = 3`
- Runtime property: `var health: int`
- Public method: `func take_damage(amount: int) -> void`

- [ ] **Step 1: 写最小实现**

```gdscript
@export var max_health: int = 3
var health: int

func _ready() -> void:
    health = max_health
```
继续增加：

```gdscript
func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        queue_free()
```

保留 Lesson 04 的追踪逻辑不变。

- [ ] **Step 2: 只验证 Enemy Health 接口**

重新运行 Lesson 07 测试。Expected: 与 `max_health / health / take_damage()` 相关断言转绿，但 Projectile Area2D/命中仍保持 RED。

---

### Task 3: GREEN — Projectile 升级为 Area2D 并通过 Signal 造成伤害

**Files:**
- Modify: `scenes/weapons/Projectile.tscn`
- Modify: `scripts/weapons/projectile.gd`

**Interfaces:**
- Projectile root: `Area2D`
- Child: `CollisionShape2D`
- Exported property: `@export var damage: int = 1`
- Signal source: built-in `body_entered`
- [ ] **Step 1: 修改 `projectile.gd`**

```gdscript
extends Area2D

const ENEMY_SCENE_PATH := "res://scenes/enemies/Enemy.tscn"

@export var speed: float = 520.0
@export var damage: int = 1
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
    if position.x < -100.0 or position.x > 1380.0 or position.y < -100.0 or position.y > 820.0:
        queue_free()
```

- [ ] **Step 2: 增加命中处理**

```gdscript
func _on_body_entered(body: Node2D) -> void:
    if body.scene_file_path != ENEMY_SCENE_PATH:
        return
    if body.has_method("take_damage"):
        body.call("take_damage", damage)
    queue_free()
```
- [ ] **Step 3: 修改 `Projectile.tscn`**

Scene tree：

```text
Projectile (Area2D)
├── Sprite2D
└── CollisionShape2D
```

使用一个小 `RectangleShape2D`；Projectile `collision_layer = 0`、`collision_mask = 1`。Area2D 不阻挡物理移动，只监听进入它检测范围的 PhysicsBody；代码只对 Enemy Scene 路径响应，因此 Player/训练墙不会受到伤害。

- [ ] **Step 4: 跑 GREEN**

Expected: Lesson 07 测试确认第一次真实命中后 Enemy `health == 2`，Projectile 已释放。

- [ ] **Step 5: 验证死亡**

测试继续调用 `enemy.take_damage(2)`，等待一个 process frame 后断言 Enemy 已从 Scene Tree 移除。

Expected: `PASS: Lesson 07 damage and death`，exit 0。

---

### Task 4: 教学层与亲手实验

**Files:**
- Create: `docs/concepts/area2d-signal-health.md`
- Create: `docs/lessons/07-damage-and-death.md`
- Modify: `README.md`
**Interfaces:**
- 教程只正式讲 `Area2D`、built-in Signal `body_entered`、Health/伤害/死亡。
- 不提前讲经验掉落；死亡后“掉东西”留给 Lesson 08。

- [ ] **Step 1: 写概念页**

必须解释：
- `CharacterBody2D` 负责“有实体、会移动/阻挡”，`Area2D` 更适合“检测进入范围但不负责阻挡”；
- Signal 可以先理解成“某件事发生时发出的通知”；
- `body_entered` 是 Area2D 已经提供的 Signal；
- Health 是状态，Damage 是对状态的修改，Death 是 `health <= 0` 后的结果。

- [ ] **Step 2: 写 Lesson 07**

亲手实验：
1. 默认 `Max Health = 3`，观察 Enemy 通常需要多发 Projectile 才消失；
2. 打开 `Enemy.tscn`，选根节点 Enemy；
3. 把 `Max Health` 改为 `1`；
4. 先预测，再运行，观察 Enemy 被第一发命中后直接死亡；
5. 最后恢复 `3` 并保存。

- [ ] **Step 3: 更新 README 并最终验证**

运行 Lesson 05、06、07 tests 与主场景；执行 `git diff --check`、BOM/凭据/本机路径扫描。

完成后提交 Lesson 07，创建 Tag `lesson-07-damage-and-death`，走普通 PR merge。
