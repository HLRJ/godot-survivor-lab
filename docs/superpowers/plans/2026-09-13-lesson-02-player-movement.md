# Lesson 02：玩家移动 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Lesson 01 的静态 Player 升级为可用 WASD / 方向键八方向移动的 `CharacterBody2D`，并让学习者理解移动所需的最小 Godot 心智模型。

**Architecture:** `Player.tscn` 只负责玩家节点结构与显示，`scripts/player/player.gd` 只负责读取输入并设置 `velocity` 后调用 `move_and_slide()`。输入动作统一配置为 `move_left/right/up/down`，避免把具体按键硬编码进脚本。

**Tech Stack:** Godot 4.7.2 stable、GDScript、Git、GitHub、Windows。

**Spec:** `docs/superpowers/specs/2026-09-13-learning-first-course-design.md`

## Global Constraints

- 第一目标是维护者本人快速学会 Godot，第二目标才是对外教学。
- 本课只引入三个核心概念：`CharacterBody2D`、Input Map / `Input.get_vector()`、`_physics_process + velocity + move_and_slide()`。
- 不加入碰撞体、动画、相机、冲刺、状态机或其他下一课内容。
- 每个新概念必须保留“运行 → 修改一个值 → 先预测再验证”的学习闭环。
- Lesson 完成后创建永久 Tag：`lesson-02-player-movement`。

---
### Task 1：先写一个会失败的移动行为测试

**Files:**
- Create: `tests/lesson_02_player_movement_test.gd`

**Interfaces:**
- Consumes: `res://scenes/player/Player.tscn`。
- Produces: 一个可用 Godot headless 直接运行的回归测试，验证输入动作、根节点类型和向右移动行为。

- [ ] **Step 1: 创建失败测试**

测试必须检查：

1. `move_left/right/up/down` 四个 Input Action 存在；
2. `Player.tscn` 根节点是 `CharacterBody2D`；
3. Player 持续按下 `move_right` 两个 physics frame 后，X 坐标增加且 Y 基本不变。

- [ ] **Step 2: 运行 RED**

```powershell
<GODOT_EXE> --headless --path . --script tests/lesson_02_player_movement_test.gd
```

Expected：退出码非 0，原因是 Lesson 02 尚未实现。

---
### Task 2：实现最小玩家移动

**Files:**
- Modify: `project.godot`
- Modify: `scenes/player/Player.tscn`
- Create: `scripts/player/player.gd`
- Test: `tests/lesson_02_player_movement_test.gd`

**Interfaces:**
- Produces: `Player` 根节点为 `CharacterBody2D`，导出 `speed: float = 220.0`，每个 physics frame 根据四个 Input Action 更新 `velocity` 并 `move_and_slide()`。

- [ ] **Step 1: 配置 Input Map**

建立 `move_left/right/up/down`，分别支持 A/左箭头、D/右箭头、W/上箭头、S/下箭头。

- [ ] **Step 2: 把 Player 根节点升级为 CharacterBody2D 并挂载脚本**

节点树仍保持最小：

```text
Player (CharacterBody2D)
└── Sprite2D
```

- [ ] **Step 3: 写最小 player.gd**

```gdscript
extends CharacterBody2D

@export var speed: float = 220.0

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()
```

本课故意不写 `velocity * delta`：`CharacterBody2D.move_and_slide()` 会按 physics frame 正确处理速度。

- [ ] **Step 4: 运行 GREEN**

重复 Task 1 的测试命令。Expected：退出码 `0`，打印 PASS。

---
### Task 3：写中文 Lesson 02，并保留亲手实验

**Files:**
- Create: `docs/lessons/02-player-movement.md`
- Create: `docs/concepts/characterbody2d-and-movement.md`
- Modify: `README.md`
- Modify: `scenes/main/Main.tscn`

**Interfaces:**
- Consumes: 已通过自动测试的 Player movement。
- Produces: 中文主线课程、最小概念页、README 入口和 Lesson 02 状态提示。

- [ ] **Step 1: Lesson 正文只围绕三个概念写**

固定结构：目标 → 最终效果 → 三个概念 → 看代码 → 运行 → 常见错误 → 小实验 → 学习检查 → Checkpoint。

- [ ] **Step 2: 解释两个易错点**

明确解释：

- `Input.get_vector()` 会把对角线方向归一化，因此同时按 W+D 不会比只按 D 跑得更快；
- `speed = 220.0` 可理解为约 220 像素/秒，而不是“每帧 220 像素”。

- [ ] **Step 3: 留给维护者的亲手实验**

先预测，再把 `Player` 的 `Speed` 从 `220` 改成 `440`，运行比较移动速度，最后恢复 `220` 并保存。

- [ ] **Step 4: 更新主场景提示和 README**

状态文字改为 `Lesson 02 - WASD 玩家移动`；README 当前进度改为 Lesson 02，下一步 Lesson 03：碰撞。

---
### Task 4：最终验证、提交、Tag 与 PR

**Files:**
- All Lesson 02 changed files.

- [ ] **Step 1: 运行完整验证**

```powershell
<GODOT_EXE> --headless --path . --script tests/lesson_02_player_movement_test.gd
<GODOT_EXE> --headless --path . --editor --quit
git diff --check
```

Expected：测试 PASS、editor exit 0、diff check 0。

- [ ] **Step 2: 等维护者完成 Speed 220 → 440 → 220 实验**

确认 `Player.tscn` / Inspector 最终恢复 `speed = 220.0`，且没有 Godot 编辑器噪音改动。

- [ ] **Step 3: 提交并创建永久 Checkpoint**

```bash
git add project.godot scenes/player/Player.tscn scenes/main/Main.tscn scripts/player/player.gd tests/lesson_02_player_movement_test.gd docs/lessons/02-player-movement.md docs/concepts/characterbody2d-and-movement.md README.md docs/superpowers/plans/2026-09-13-lesson-02-player-movement.md
git commit -m "feat: add lesson 02 player movement"
git tag -a lesson-02-player-movement -m "Lesson 02: player movement"
git push -u origin feat/lesson-02-player-movement
git push origin lesson-02-player-movement
```

- [ ] **Step 4: 创建 PR 到 main**

使用普通 merge commit，禁止 squash Lesson 提交。合并后在 `main` 上再次运行完整验证，再删除 feature branch/worktree。
