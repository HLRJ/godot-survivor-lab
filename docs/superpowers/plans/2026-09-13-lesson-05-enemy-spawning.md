# Lesson 05 不断刷怪 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 `Timer + PackedScene.instantiate()` 周期性生成 Enemy，让场景从“一个固定敌人”升级成持续刷怪。

**Architecture:** 新建 `EnemySpawner.tscn`，根节点负责生成，子节点 `Timer` 负责节拍。Spawner 每次实例化 `Enemy.tscn` 后把 Enemy 添加到 Main，而不是添加到 Spawner 自己下面，从而继续满足 Lesson 04 中 Enemy 使用 `../Player` 获取 Player 的层级约束。

**Tech Stack:** Godot 4.7.2 stable、GDScript、Git + GitHub、Windows first。

**Spec:** `docs/superpowers/specs/2026-09-13-learning-first-course-design.md`

## Global Constraints

- 本课最多引入 3 个核心概念：`PackedScene`、`instantiate()`、`Timer`。
- 不提前加入对象池、波次系统、难度曲线、随机权重、导航或伤害。
- 必须有肉眼可见结果：Enemy 数量会随时间持续增加。
- 默认刷怪间隔 `1.5` 秒。
- 学习者必须亲手把 Spawn Interval 从 `1.5` 改成 `0.5`，观察后恢复 `1.5`。
- 中文为主；Godot Node/API、GDScript 标识和 Git 命令保留官方英文名称。

---

## File Map
- Create: `scenes/enemies/EnemySpawner.tscn` — 刷怪器 Scene，包含 Timer。
- Create: `scripts/enemies/enemy_spawner.gd` — 周期实例化 Enemy 并添加到 Main。
- Modify: `scenes/main/Main.tscn` — 移除固定 Enemy，实例化 EnemySpawner。
- Create: `tests/lesson_05_enemy_spawning_test.gd` — 验证周期刷怪和层级关系。
- Create: `docs/concepts/packedscene-instantiate-timer.md` — 三个核心概念的最小心智模型。
- Create: `docs/lessons/05-enemy-spawning.md` — 中文课程与亲手实验。
- Modify: `README.md` — 增加 Lesson 05 入口和当前进度。

---

### Task 1: RED — 证明当前还不会持续刷怪

**Files:**
- Create: `tests/lesson_05_enemy_spawning_test.gd`

**Interfaces:**
- Consumes: `Main.tscn`、`Enemy.tscn`、Lesson 04 的追踪逻辑。
- Produces: 一个能验证 Enemy 数量随时间增加、且生成层级正确的 headless 测试。

- [ ] **Step 1: 写失败测试**

测试必须验证：
- Main 存在 `EnemySpawner`；
- Spawner 有 `Timer`；
- 默认 `spawn_interval` 为 `1.5`；
- 等待约 3.2 秒后至少出现 3 个 Enemy；
- 所有 Enemy 都直接挂在 Main 下，并能拿到同一个 Player 引用。
- [ ] **Step 2: 运行并确认 RED**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --script res://tests/lesson_05_enemy_spawning_test.gd
```

Expected: exit 1，失败原因包含 `Main must contain EnemySpawner`。

---

### Task 2: GREEN — 创建最小刷怪器

**Files:**
- Create: `scenes/enemies/EnemySpawner.tscn`
- Create: `scripts/enemies/enemy_spawner.gd`
- Modify: `scenes/main/Main.tscn`

**Interfaces:**
- Exported property: `@export var enemy_scene: PackedScene`
- Exported property: `@export var spawn_interval: float = 1.5`
- Timer node: `$Timer`
- Generated Enemy parent: Main

- [ ] **Step 1: 写 `enemy_spawner.gd`**

Spawner 在 `_ready()` 设置 Timer 间隔并立即生成第一个 Enemy；Timer 每次 timeout 再生成一个。

生成位置按固定数组循环，避免这一课同时引入随机数。
- [ ] **Step 2: 创建 `EnemySpawner.tscn`**

Scene tree：

```text
EnemySpawner (Node)
└── Timer
```

`enemy_scene` 指向 `res://scenes/enemies/Enemy.tscn`，Timer 不 autostart，由脚本在 `_ready()` 中启动。

- [ ] **Step 3: 修改 Main**

移除 Lesson 04 的固定 `Enemy` 实例，改为：

```text
Main
├── Player
├── TrainingWall
└── EnemySpawner
```

Spawner 生成 Enemy 时使用 `get_parent().add_child(enemy)`，因此生成结果仍然是 Main 的直接子节点，Lesson 04 的 `../Player` 路径继续有效。

- [ ] **Step 4: 跑 GREEN**

Expected: `PASS: Lesson 05 enemy spawning`，exit 0。

---

### Task 3: 教学层与亲手实验
**Files:**
- Create: `docs/concepts/packedscene-instantiate-timer.md`
- Create: `docs/lessons/05-enemy-spawning.md`
- Modify: `README.md`

**Interfaces:**
- 教程只解释 `PackedScene`、`instantiate()`、`Timer`。
- 不正式展开 Signal；只把 Timer timeout 当作“计时结束时触发一次”。

- [ ] **Step 1: 写概念页**

必须解释：
- `PackedScene` 可以先理解为“还没放进场景树的 Scene 模板”；
- `instantiate()` 会从模板创建一个新的 Node 实例；
- 同一个 `PackedScene` 可以反复 instantiate，得到多个独立 Enemy；
- Timer 负责节拍，而不是负责生成逻辑本身。

- [ ] **Step 2: 写 Lesson 05**

亲手实验固定为：
1. 运行并观察 Enemy 数量持续增加；
2. 选中 `EnemySpawner`，把 `Spawn Interval` 从 `1.5` 改为 `0.5`；
3. 预测并观察刷怪频率；
4. 恢复 `1.5` 并保存。

- [ ] **Step 3: 更新 README**

增加 Lesson 05 入口，并把当前进度更新为“EnemySpawner 已能持续生成 Enemy，下一步 Lesson 06：自动攻击”。
---

### Task 4: 最终验证与 Checkpoint

**Files:**
- All Lesson 05 files above

- [ ] **Step 1: 自动测试**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --script res://tests/lesson_05_enemy_spawning_test.gd
```

Expected: PASS，exit 0。

- [ ] **Step 2: 主场景运行**

```powershell
<GODOT_EXE> --headless --path <WORKTREE> --quit-after 4
```

Expected: exit 0。

- [ ] **Step 3: 静态检查**

`git diff --check` 必须 exit 0；无临时文件、凭据、本机绝对路径。

- [ ] **Step 4: 学习者亲手实验**

只有学习者实际完成 `Spawn Interval 1.5 → 0.5 → 1.5` 后，才允许创建 Checkpoint。

- [ ] **Step 5: 提交并打 Tag**

提交信息：`feat: add lesson 05 enemy spawning`

Tag：`lesson-05-enemy-spawning`
