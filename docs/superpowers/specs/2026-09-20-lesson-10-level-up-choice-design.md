# Lesson 10：升级三选一设计

## 目标

在 Lesson 09 已完成“经验掉落 → 拾取 → Player XP 增长”的基础上，补齐 Survivor-like 最核心的升级反馈：

```text
拾取经验
→ 达到升级阈值
→ Player 升级
→ 暂停战斗
→ 显示三选一
→ 选择一个真实强化
→ 恢复战斗
```

首版三个固定强化：

- 移动速度 +40；
- 攻击间隔 -0.1 秒，最低 0.2 秒；
- Projectile 伤害 +1。

三种强化都允许重复选择并继续叠加。

## 本课范围

本课实现完整可玩的升级闭环，但保持最小架构，不提前引入 Resource 技能池、随机稀有度、图标系统、复杂 HUD 或 GameManager。

## 核心职责划分

采用“Player + Main 协调 + LevelUpPanel”方案。

### Player

负责自身长期运行时状态：

- `experience`；
- `level`；
- `experience_to_next_level`；
- 移动速度 `speed`；
- XP 结转与升级判断；
- 发出 `level_up(new_level)` Signal。

Player 不负责打开 UI，也不负责暂停 SceneTree。

### Weapon

负责持续存在的武器状态：

- `attack_interval`；
- `projectile_damage`；
- 攻速升级；
- 生成 Projectile 时把当前伤害写入新实例。

Weapon 不负责 XP、Level 或 UI。

### LevelUpPanel

负责升级选择界面：

- 暂停期间仍能处理输入；
- 显示三个固定选项；
- 点击按钮后发出 `upgrade_selected(upgrade_id)`；
- 不直接修改 Player、Weapon 或 Projectile。

### Main

只作为协调者：

- 连接 Player 的 `level_up`；
- 管理待处理升级次数 `pending_level_ups`；
- 暂停/恢复 SceneTree；
- 显示/隐藏 LevelUpPanel；
- 接收 `upgrade_selected`；
- 把选择路由给 Player 或 Weapon。

Main 不持有 Player 的 XP，也不持有 Weapon 的攻击属性。

## Player 升级模型

初始状态：

```text
level = 1
experience = 0
experience_to_next_level = 5
```

阈值采用首版线性增长：

```text
Lv1 → Lv2：5 XP
Lv2 → Lv3：8 XP
Lv3 → Lv4：11 XP
Lv4 → Lv5：14 XP
...
```

每升一级：

```gdscript
experience_to_next_level += 3
```

XP 必须结转，不能升级后直接清零。例如：

```text
Lv1，4 / 5 XP
一次获得 3 XP
→ 总 XP = 7
→ 扣除 5
→ Lv2
→ 剩余 XP = 2
```

升级判断使用 `while`，而不是单次 `if`，以正确处理一次获得大量 XP 时连续跨级。

逻辑顺序：

```text
add_experience(amount)
→ experience += amount
→ while experience >= experience_to_next_level
    → experience -= 当前阈值
    → level += 1
    → experience_to_next_level += 3
    → level_up.emit(level)
```

Signal 在 Player 内同步发出；UI 是否正在显示不影响 Player 完成 XP 数学计算。

## 连续升级处理

一次获得大量 XP 可能在同一调用中触发多次 `level_up`。

Main 使用：

```gdscript
var pending_level_ups: int = 0
```

每收到一次 `level_up`：

```text
pending_level_ups += 1
```

若当前没有升级选择正在进行，则暂停游戏并显示 LevelUpPanel。

玩家选完一次强化后：

```text
pending_level_ups -= 1

如果 pending_level_ups > 0
→ 保持暂停
→ 再进行一次三选一

否则
→ 隐藏 LevelUpPanel
→ 恢复游戏
```

这样一次连升两级就会连续获得两次强化，而不是丢失升级或重叠打开 UI。

## LevelUpPanel Scene

建议结构：

```text
LevelUpPanel (CanvasLayer)
└── Overlay (Control)
    ├── DimBackground (ColorRect)
    └── PanelContainer
        └── VBoxContainer
            ├── TitleLabel
            ├── MoveSpeedButton
            ├── AttackSpeedButton
            └── DamageButton
```

按钮文字首版直接显示：

```text
LEVEL UP!

移动速度 +40
攻击间隔 -0.1 秒
子弹伤害 +1
```

根节点或负责输入的 UI 节点设置为：

```gdscript
process_mode = Node.PROCESS_MODE_WHEN_PAUSED
```

升级界面出现时：

```gdscript
get_tree().paused = true
```

因此战斗对象、Timer 与物理过程暂停，但 LevelUpPanel 仍然能响应按钮输入。

LevelUpPanel 只发出：

```gdscript
signal upgrade_selected(upgrade_id: String)
```

固定 upgrade id：

```text
"move_speed"
"attack_speed"
"projectile_damage"
```

UI 不需要知道这些强化具体修改什么变量。

## 三种强化的真实落点

### 移动速度

由 Player 保存：

```text
220 → 260 → 300 → 340 ...
```

Player 提供最小升级方法，将 `speed` 增加 40。

### 攻击速度

由 Weapon 保存 `attack_interval`，升级时：

```text
0.8 → 0.7 → 0.6 → ...
最低 0.2 秒
```

修改 `attack_interval` 后必须同步当前正在工作的 `Timer.wait_time`，否则只是改了变量，实际射击节奏不会立即改变。

### Projectile 伤害

不能把持续升级状态放在某一颗 Projectile 实例上，因为 Projectile 命中后会 `queue_free()`。

Weapon 新增长期状态：

```gdscript
var projectile_damage: int = 1
```

每次 `instantiate()` Projectile 后，把当前 `projectile_damage` 写入新实例的 `damage`。

因此职责是：

```text
Weapon：决定以后生成的子弹应该有多少伤害
Projectile：保存并使用这一颗子弹自己的 damage
```

这也继续强化 PackedScene“模板”和运行时实例之间的区别。

## 完整运行时数据流

```text
ExperienceGem
→ Player.add_experience()
→ 达到阈值
→ level += 1
→ Player.level_up.emit(level)
→ Main 收到 level_up
→ pending_level_ups += 1
→ 暂停 SceneTree
→ 显示 LevelUpPanel
→ 玩家点击一个按钮
→ LevelUpPanel.upgrade_selected.emit(id)
→ Main 根据 id 路由
   ├─ move_speed → Player
   ├─ attack_speed → Weapon
   └─ projectile_damage → Weapon
→ pending_level_ups -= 1
→ 有剩余升级：继续三选一
→ 无剩余升级：隐藏 UI、恢复 SceneTree
```

## 教学方式

延续 Lesson 07–09 的学习优先原则。AI 可以完成 Scene 骨架、自动测试、重复样板、文档和 Git 操作，但核心概念代码由学习者亲手完成。

至少设置以下动手 Gate：

1. Player 的 `level`、阈值和 XP 结转升级循环；
2. Player 的 `level_up` Signal；
3. LevelUpPanel 的 `upgrade_selected` Signal 与按钮回调；
4. 至少一种升级方法的实际实现，并解释状态应该属于 Player、Weapon 还是 Projectile。

每个 Gate 都先解释运行时调用者、参数来源和数据流，再由学习者编写，保存后由自动测试验证。

## 测试策略

自动测试覆盖：

- 初始 Level/XP/阈值；
- 5 XP 正好升一级；
- 多余 XP 正确结转；
- 一次大量 XP 可以跨多级；
- 每次升级都发出对应次数的 `level_up`；
- 移速升级 +40；
- 攻速升级 -0.1，且不低于 0.2；
- Weapon 新生成的 Projectile 使用升级后的 damage；
- LevelUpPanel 可在暂停状态处理输入；
- Main 能正确管理 pending upgrades 并最终恢复游戏。

手动 F5 验证：

```text
捡够 5 XP
→ 战斗冻结
→ 三选一出现
→ 点击任意强化
→ UI 消失
→ 战斗继续
→ 强化可以在实际玩法中感受到
```

## 非目标

本课不实现：

- 随机技能池；
- Resource/Tres 技能数据；
- 技能图标与稀有度；
- 技能上限；
- reroll / banish；
- 完整 HUD 经验条；
- GameManager；
- 存档系统。

## 完成标准

Lesson 10 完成时，项目必须拥有从拾取经验到真实强化生效的完整升级三选一闭环，同时 Lesson 02–09 的历史回归测试继续通过。
