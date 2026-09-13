# Lesson 06 自动攻击 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Player 自动朝最近的 Enemy 发射 Projectile，并让学习者亲手体验 Projectile Speed 对飞行速度的影响。

**Architecture:** 新建 `Weapon.tscn` 作为 Player 的子 Scene，用 Timer 控制攻击节奏；Weapon 每次攻击从 Main 的直接子节点中寻找最近的 `Enemy.tscn` 实例，再实例化 `Projectile.tscn`。Projectile 本课先保持为 `Node2D`，只负责沿给定方向飞行；碰撞、伤害和死亡留到 Lesson 07。

**Tech Stack:** Godot 4.7.2 stable、GDScript、Git + GitHub、Windows first。

**Spec:** `docs/superpowers/specs/2026-09-13-learning-first-course-design.md`

## Global Constraints

- 本课最多引入 3 个核心概念：Projectile Scene、攻击 Timer、方向驱动的 Projectile 飞行。
- 复用 Lesson 05 已学过的 `PackedScene + instantiate()`，不把它当新概念重复展开。
- 不提前加入 Area2D、伤害、生命值、Signal、Group、对象池或武器升级系统。
- 必须有肉眼可见结果：Enemy 出现后，Player 会自动持续发射 Projectile。
- 默认攻击间隔 `0.8` 秒；Projectile 默认速度 `520.0`。
- 学习者必须亲手把 Projectile `Speed` 从 `520` 改成 `900`，观察后恢复 `520`。
- 中文为主；Godot Node/API、GDScript 标识和 Git 命令保留官方英文名称。

---
## File Map

- Create: `scenes/weapons/Weapon.tscn` — Player 的自动攻击组件，包含 Timer。
- Create: `scripts/weapons/weapon.gd` — 找最近 Enemy、创建 Projectile、设置方向。
- Create: `scenes/weapons/Projectile.tscn` — 可复用 Projectile Scene，本课根节点为 Node2D。
- Create: `scripts/weapons/projectile.gd` — 按 `direction * speed * delta` 飞行并在离开屏幕后回收。
- Modify: `scenes/player/Player.tscn` — 实例化 Weapon。
- Modify: `scenes/main/Main.tscn` — 更新 Lesson 06 状态文字。
- Create: `tests/lesson_06_auto_attack_test.gd` — 验证自动生成 Projectile 与真实飞行行为。
- Create: `docs/concepts/projectile-and-auto-attack.md` — 自动攻击最小心智模型。
- Create: `docs/lessons/06-auto-attack.md` — 中文课程与亲手实验。
- Modify: `README.md` — 增加 Lesson 06 入口和当前进度。

### 临时目标选择规则

本课不提前引入 Group。Weapon 只扫描 Main 的直接子节点，并用：

```gdscript
child.scene_file_path == "res://scenes/enemies/Enemy.tscn"
```

识别 Enemy。这个规则依赖 Lesson 05 已固定的“Enemy 直接挂在 Main 下”结构，简单但不是最终敌人管理方案；后续出现真实需求时再重构。

---
### Task 1: RED — 证明当前还不会自动攻击

**Files:**
- Create: `tests/lesson_06_auto_attack_test.gd`

**Interfaces:**
- Consumes: `Main.tscn`、Lesson 05 的 `EnemySpawner`。
- Produces: 一个在 Weapon / Projectile 缺失时失败、实现后验证真实自动发射与飞行的 headless 测试。

- [ ] **Step 1: 写失败测试**

测试必须验证：
- Player 存在 `Weapon` 子节点；
- Weapon 存在 `Timer`；
- Weapon 默认 `attack_interval == 0.8`；
- Weapon 引用 `Projectile.tscn`；
- 测试中临时加速 EnemySpawner 与 Weapon Timer；
- Enemy 出现后，Main 下会出现至少 1 个 `Projectile.tscn` 实例；
- Projectile 默认 `speed == 520.0`；
- Projectile 的 `direction` 长度约为 1；
- 等待若干 physics frame 后，Projectile 的位置明显变化。

- [ ] **Step 2: 运行并确认 RED**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --script res://tests/lesson_06_auto_attack_test.gd
```

Expected: exit 1，失败原因包含 `Player must contain Weapon`。

---
### Task 2: GREEN — 创建 Projectile 与 Weapon

**Files:**
- Create: `scenes/weapons/Projectile.tscn`
- Create: `scripts/weapons/projectile.gd`
- Create: `scenes/weapons/Weapon.tscn`
- Create: `scripts/weapons/weapon.gd`
- Modify: `scenes/player/Player.tscn`
- Modify: `scenes/main/Main.tscn`

**Interfaces:**
- Projectile exported property: `@export var speed: float = 520.0`
- Projectile runtime property: `var direction: Vector2 = Vector2.RIGHT`
- Weapon exported property: `@export var projectile_scene: PackedScene`
- Weapon exported property: `@export var attack_interval: float = 0.8`
- Weapon Timer node: `$Timer`

- [ ] **Step 1: 创建 `projectile.gd`**

```gdscript
extends Node2D

@export var speed: float = 520.0
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
    if position.x < -100.0 or position.x > 1380.0 or position.y < -100.0 or position.y > 820.0:
        queue_free()
```

Projectile 本课不包含碰撞节点；Lesson 07 再升级为 Area2D。
- [ ] **Step 2: 创建 `Projectile.tscn`**

Scene tree：

```text
Projectile (Node2D)
└── Sprite2D
```

Sprite 复用现有 Kenney 角色图集中的一个小 region，并缩小、改成亮黄色，确保肉眼能区分 Player / Enemy / Projectile。只复用已学过的 Sprite2D，不引入新可视节点类型。

- [ ] **Step 3: 创建 `weapon.gd`**

Weapon 每次 timeout：
1. 扫描 Main 的直接子节点；
2. 找 `scene_file_path == res://scenes/enemies/Enemy.tscn` 的最近 Enemy；
3. 没有 Enemy 时本次不攻击；
4. 实例化 Projectile；
5. 用 `global_position.direction_to(target.global_position)` 设置方向；
6. 把 Projectile 加到 Main。

最小实现：

```gdscript
extends Node2D

const ENEMY_SCENE_PATH := "res://scenes/enemies/Enemy.tscn"

@export var projectile_scene: PackedScene
@export var attack_interval: float = 0.8
@onready var timer: Timer = $Timer

func _ready() -> void:
    timer.wait_time = attack_interval
    timer.timeout.connect(_attack)
    timer.start()

func _attack() -> void:
    var target := _find_nearest_enemy()
    if target == null or projectile_scene == null:
        return
    var projectile := projectile_scene.instantiate() as Node2D
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = global_position
    projectile.set("direction", global_position.direction_to(target.global_position))

func _find_nearest_enemy() -> Node2D:
    var nearest: Node2D = null
    var nearest_distance := INF
    for child in get_tree().current_scene.get_children():
        if not child is Node2D:
            continue
        var candidate := child as Node2D
        if candidate.scene_file_path != ENEMY_SCENE_PATH:
            continue
        var distance := global_position.distance_squared_to(candidate.global_position)
        if distance < nearest_distance:
            nearest = candidate
            nearest_distance = distance
    return nearest
```

- [ ] **Step 4: 创建 `Weapon.tscn` 并挂到 Player**

```text
Player
├── Sprite2D
├── CollisionShape2D
└── Weapon (Node2D)
    └── Timer
```

Weapon 的 `projectile_scene` 指向 `Projectile.tscn`，Timer 由脚本启动。

- [ ] **Step 5: 跑 GREEN**

Expected: `PASS: Lesson 06 auto attack`，exit 0。

---
### Task 3: 教学层与亲手实验

**Files:**
- Create: `docs/concepts/projectile-and-auto-attack.md`
- Create: `docs/lessons/06-auto-attack.md`
- Modify: `README.md`

**Interfaces:**
- 教程只正式讲 Projectile Scene、攻击 Timer、方向驱动飞行。
- 最近 Enemy 的扫描代码只作为当前最小目标选择策略说明，不扩展成敌人管理系统。

- [ ] **Step 1: 写概念页**

必须解释：
- Weapon 和 Projectile 是两个不同职责：Weapon 决定“什么时候、朝谁发射”，Projectile 决定“出生以后怎么飞”；
- `direction_to()` 在这里和 Enemy 追踪完全是同一个方向计算，只是使用者从 Enemy 变成 Projectile；
- `position += direction * speed * delta` 中 `delta` 让飞行速度不依赖帧率；
- Projectile 是独立 Scene，因此每次攻击都会得到独立实例。

- [ ] **Step 2: 写 Lesson 06**

亲手实验固定为：
1. 运行并等待 Enemy 出现，观察 Player 自动发射黄色 Projectile；
2. 打开 `Projectile.tscn`，选根节点 Projectile；
3. 把 `Speed` 从 `520` 改成 `900`；
4. 先预测，再观察 Projectile 飞得更快但攻击频率不变；
5. 恢复 `520` 并保存。

- [ ] **Step 3: 更新 README**

增加 Lesson 06 入口；当前进度更新为“Player 已能自动朝最近 Enemy 发射 Projectile，下一步 Lesson 07：伤害与死亡”。

---
### Task 4: 最终验证与 Checkpoint

**Files:**
- All Lesson 06 files above

- [ ] **Step 1: 自动测试**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --script res://tests/lesson_06_auto_attack_test.gd
```

Expected: PASS，exit 0。

- [ ] **Step 2: 主场景运行**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --quit-after 5
```

Expected: exit 0。

- [ ] **Step 3: 静态与公开卫生检查**

`git diff --check` 必须 exit 0；本课新增/修改文本不得包含凭据、本机绝对路径、BOM 或临时脚本。

- [ ] **Step 4: 学习者亲手实验**

只有学习者实际完成 `Projectile Speed 520 → 900 → 520` 后，才允许创建本课 Checkpoint。

- [ ] **Step 5: 提交并打 Tag**

提交信息：`feat: add lesson 06 auto attack`

Tag：`lesson-06-auto-attack`
