# Lesson 11：升级数据化——从硬编码走向 Resource

## 为什么现在学这一课

Lesson 10 已经实现「击杀 → 经验 → 升级三选一 → 战斗继续」，但有一个值得现在解决的真实问题：按钮写「移动速度 +40」，`player.gd` 又写 `speed += 40`。攻击速度和子弹伤害也重复保存了显示数字和行为数字。

只有三个强化时还勉强可维护；未来有几十种武器、技能、装备和 Buff 时，同一数值在多个文件里修改，容易出现 UI 宣称「+80」而实际只加 `40` 的错误。

**今天引入 Resource 是因为已有真实的数据重复，而不是因为 API 列表轮到了 Resource。** Lesson 01–09 还没出现这个需求，提前引入反而会干扰当时要学的核心概念。

## 以后做复杂游戏时会在哪里用到

- **武器与装备：** 武器伤害、攻击间隔、售价、稀有度等平衡数据放进可编辑资产。
- **技能与 Buff：** 增量、持续时间、冷却、名称、说明由配置提供，行为由游戏对象实现。
- **敌人与关卡：** 不同敌人的 HP、移动速度、刷新参数与关卡规则复用同一种思路。
- **掉落表与游戏平衡：** 大量调参时不用重复编辑行为代码。

这节课的重点是**数据与行为分离**，而不是发明一套复杂技能系统。

## 本课版本与 Checkpoint

- **最新教学文档：** `main / docs/lessons/11-upgrade-data.md`（本课 PR 合并后成为 main 的最新版）。
- **开始代码：** `lesson-10-level-up-choice`。
- **完成参考：** `lesson-11-upgrade-data`（本课完成并集成后发布）。
- 历史 Lesson Tag **不移动**。从上一课 Tag 创建自己的学习分支；教程始终以 `main` 最新文档为准。

## 本课目标和完成效果

这次不新增第四个升级按钮，也不改变暂停/排队规则，只把三个固定选项改成由 `UpgradeData` 提供 `id`、`label`、`amount`。

达标实验：**完全不改 `.gd`**，仅将 `move_speed.tres` 的显示文字及增量由 `+40` 调为 `+80`；重新 F5，按钮和实际增加的速度必须都变成 `+80`。然后恢复 `+40`。

## 本课复用的旧知识与新知识

| 已经学过 | 这次怎么复用 |
| --- | --- |
| Lesson 01：Scene / Node | `LevelUpPanel.tscn` 引用数据资产 |
| Lesson 05：PackedScene / instantiate | 用来对比 Resource 与场景实例 |
| Lesson 07–08：Signal / connect / emit | 从「传字符串」升级成「传对象」 |
| Lesson 09：运行时 Player XP | 对比配置数据与局内状态 |
| Lesson 10：Main 协调、Timer、SceneTree.pause | 保留原玩法并更换数据来源 |

**这课新增：** `Resource`、文本资源 `.tres`、`class_name`、`@export` 的 Resource 依赖、以及从配置到行为的参数传递。

## 第一步：写 UpgradeData 类型

创建 `scripts/upgrades/upgrade_data.gd`：

```gdscript
class_name UpgradeData
extends Resource

@export var id: StringName
@export var label: String
@export var amount: float
```

- `extends Resource`：对象的职责是保存/共享数据，**不是 SceneTree 里的 Node**。
- `class_name UpgradeData`：把脚本注册成 Godot 可识别的自定义类型，后面才能写 `@export var upgrade: UpgradeData` 与 `signal upgrade_selected(upgrade: UpgradeData)`。
- `@export`：把数据字段暴露给 Inspector 编辑，**不保证依赖一定被正确赋值**。
- `StringName`：适合比较固定名称；`String` 用于可显示、可能变化的文本。

**思考：** 如果把 `class_name` 去掉，脚本仍可能作为 Resource 脚本使用，但其他脚本不能再直接以 `UpgradeData` 作为已注册的全局类型。

## 第二步：创建具体 .tres 数据资产

在 Godot 的 FileSystem 中进入 `res://resources/upgrades/`，右键 → New Resource → 选择 `UpgradeData` → 保存第一份 `move_speed.tres`。

三个资产最终为：

| .tres 文件 | id | label | amount |
| --- | --- | --- | ---: |
| `move_speed.tres` | `move_speed` | 移动速度 +40 | 40.0 |
| `attack_speed.tres` | `attack_speed` | 攻击间隔 -0.1 秒 | 0.1 |
| `projectile_damage.tres` | `projectile_damage` | 子弹伤害 +1 | 1.0 |

`UpgradeData.gd` **定义数据形状**；`move_speed.tres` **保存一份真实数据实例**。

不要把 `.tres` 当作 `.tscn`：`Projectile.tscn` 可以 `instantiate()` 成为 Node；`move_speed.tres` 被加载后是 Resource 对象，不通过 `add_child()` 加进 SceneTree。

## 第三步：Player 与 Weapon 只保留行为

对比 Lesson 10 → Lesson 11：

```gdscript
# Lesson 10：Player 把具体数值写死在行为里
func upgrade_move_speed() -> void:
    speed += 40.0

# Lesson 11：Player 只接收参数
func upgrade_move_speed(amount: float) -> void:
    speed += amount
```

Weapon 同理：

```gdscript
func upgrade_attack_speed(amount: float) -> void:
    attack_interval = maxf(0.2, attack_interval - amount)
    timer.wait_time = attack_interval

func upgrade_projectile_damage(amount: int) -> void:
    projectile_damage += amount
```

这里的 `0.2` 不是升级配置，而是 Weapon **攻击间隔不得低于 0.2 秒的行为约束**，因此仍在 Weapon 内。

**预测：** `speed=220`，调用 `upgrade_move_speed(73.0)`，必须变成 `293`。故意选 `73` 而不是 `40`，才能揭穿「表面上传了参数，实际仍然写死 40」的假数据驱动。

## 第四步：LevelUpPanel 引用 Resource，并发送 Resource

`scripts/ui/level_up_panel.gd` 的核心变化：

```gdscript
signal upgrade_selected(upgrade: UpgradeData)

@export var move_speed_upgrade: UpgradeData
@export var attack_speed_upgrade: UpgradeData
@export var projectile_damage_upgrade: UpgradeData

func _ready() -> void:
    move_speed_button.text = move_speed_upgrade.label
    attack_speed_button.text = attack_speed_upgrade.label
    damage_button.text = projectile_damage_upgrade.label
    # 原有三个 pressed.connect(...) 仍然保留
```

必须在 `scenes/ui/LevelUpPanel.tscn` 根节点的 Inspector 把三个 `.tres` 分别绑定到三个导出槽位。`.tscn` 里 Button 的文字只是编辑器占位，**实际运行时从 Resource.label 读取**。

以前：

```gdscript
upgrade_selected.emit("move_speed")
```

现在：

```gdscript
upgrade_selected.emit(move_speed_upgrade)
```

这次传的是 **UpgradeData 对象引用**，里面同时包含 `id`、`label`、`amount`。`LevelUpPanel` 仍然不负责直接修改 Player。

## 第五步：Main 用 id 找对象，用 amount 传数值

`scripts/main/main.gd`：

```gdscript
func _apply_upgrade(upgrade: UpgradeData) -> bool:
    match upgrade.id:
        &"move_speed":
            player.call("upgrade_move_speed", upgrade.amount)
        &"attack_speed":
            weapon.call("upgrade_attack_speed", upgrade.amount)
        &"projectile_damage":
            weapon.call("upgrade_projectile_damage", int(upgrade.amount))
        _:
            return false
    return true
```

**为什么 `&"move_speed"` 有 `&`？** `"move_speed"` 是 `String`，`&"move_speed"` 是 `StringName` 字面量。因为 `UpgradeData.id` 定义为 `StringName`，用它表达固定 ID 很清楚。但在这里普通字符串并非一定匹配失败；区别主要在类型语义。

**谁把 `.tres.amount` 交给 Player？** Resource 不主动执行代码：Panel 发出 Resource → Main 收到 → Main 读取 `upgrade.amount` → `player.call(...)` 将数值传给 Player 的 `amount` 形参。

**如果 `call()` 漏掉 `upgrade.amount` 呢？** 因为 `player` 在 Main 中声明为 `CharacterBody2D`，`call("upgrade_move_speed", ...)` 使用运行时动态方法查找，静态分析不会检查这个自定义方法的参数个数。直到执行这行才报 `Expected 1 argument(s)`。将来可以把 Player 声明为自定义 `class_name Player` 类型并直接调用，使 IDE/静态分析提前发现一些错误；本课不为了这点额外重构 Player。

伤害强制转换 `int(upgrade.amount)`，因为数据字段统一为 `float`，而 `upgrade_projectile_damage(amount: int)` 要求整数。

## 把整条运行时数据流串起来

```text
磁盘 move_speed.tres
  ├─ id = move_speed
  ├─ label = 移动速度 +40
  └─ amount = 40
       ↓ Scene 引用
LevelUpPanel._ready() → Button.text = label
       ↓ 玩家点击
Button.pressed → _on_move_speed_pressed()
       ↓
upgrade_selected.emit(move_speed_upgrade)
       ↓ Signal 已经在 Main._ready() 中 connect
Main._on_upgrade_selected(upgrade)
       ↓
_apply_upgrade(upgrade) / match upgrade.id
       ↓
player.call("upgrade_move_speed", upgrade.amount)
       ↓
Player.upgrade_move_speed(amount)
       ↓
speed += amount
       ↓
Main 消耗一个 pending_level_ups；全部选完后恢复游戏
```

这里 `connect` 是事先建立持续订阅，`emit` 才是这次事件真正发生。与 Lesson 10 完全同一个 Signal 模型，只是携带的参数从 String 变成 Resource。

## 实验 A：不改代码，仅改配置

先 F5，完成移动速度升级，在 **Remote Inspector** 里选中运行时 Player：

- 初始 `speed=220`。
- 选择一次「移动速度 +40」后应为 `260`。
- 连续两次则为 `300`。

F8 停止游戏。仅将 `move_speed.tres` 改为：

```text
id = move_speed
label = 移动速度 +80
amount = 80.0
```

保存再 F5：

- 按钮应显示「移动速度 +80」。
- 一次升级后 Player.speed 应变成 `300`。
- 连续两次应是 `380`。

如果只变按钮不变实际速度，说明行为还有硬编码；如果只变实际速度不变按钮，说明 UI 还在硬编码。**两者同时变化才算成功。**

实验后恢复 `label = 移动速度 +40`、`amount = 40.0`。

## 实验 B：缺少 Resource 会怎样

F8 停止游戏，在 `LevelUpPanel.tscn` 根节点 Inspector 中临时清空 `Move Speed Upgrade`，再 F5：

```text
Invalid access to property or key 'label'
on a base object of type 'Nil'.
level_up_panel.gd / _ready()
```

含义：`move_speed_upgrade == null`，而 `_ready()` 试图读取 `move_speed_upgrade.label`。

这是**真实发生过的配置错误实验**。`@export` 只声明依赖槽位，不保证场景把它填好了。试验后务必重新绑定 `move_speed.tres` 并保存，不要提交坏场景。

## 四层解释：为什么选 Resource

| 问题 | 答案 |
| --- | --- |
| 怎么做？ | 定义 `UpgradeData : Resource`，创建 `.tres`，Panel 传对象，Main 读取参数，Player/Weapon 执行行为。 |
| 为什么？ | 显示与实际数值来自同一份资产，调参不需要多处改代码。 |
| 错了会怎样？ | 未绑定出现 `Nil`；只改 label 不改行为会产生数据漂移；运行时修改共享 Resource 可能污染其他引用者。 |
| 还能怎么设计？ | `Dictionary` 更轻但弱类型；JSON 适合外部交换/Mod；Autoload 适合全局状态；行为型 Resource 适合复杂技能策略。本课三个简单数值强化暂时不需要那些复杂度。 |

### Resource 配置与本局状态不要混用

`move_speed.tres.amount` 是「每次选这个升级加多少」，不是「这一局已加了多少」；后者保存在 `Player.speed` 中。

Resource 往往以**共享引用**形式被多个对象持有。不要在局内写 `move_speed_upgrade.amount += 10` 来记录已选次数。以后如需叠加层数，另建玩家/RunState 里的状态。

## 概念与排错延伸

本课相关独立手册：[Resource 与数据驱动设计](../concepts/resource-and-data-driven-design.md) · [Signal 完整事件流](../concepts/signal-and-event-flow.md) · [缺失 Resource 造成 Nil.label 的排错指南](../troubleshooting/resource-nil-reference.md)。这些页面解释通用机制，主线 Lesson 仍可单独完成。

## 自动检查与常见故障

本课包括新测试：

- `lesson_11_upgrade_data_test.gd`：三份数据可加载，字段正确。
- `lesson_11_parameterized_upgrades_test.gd`：非默认的 `73 / 0.23 / 4` 真正生效，攻击下限与 Timer 同步，Resource 配置不被行为修改。
- `lesson_11_level_up_panel_resource_test.gd`：三个场景引用非空，标签来自 Resource，点击发出对应 Resource 对象。
- `lesson_11_upgrade_flow_test.gd`：Main 使用 `id` 和 `amount`，保留暂停、升级排队和错误 ID 的边界。
- 历史 Lesson 02–10 测试：保留旧**玩法语义**，对已演进的接口同步更新测试输入。

新手常见故障：

1. `UpgradeData` 在 New Resource 列表里找不到：检查 `class_name` 并等待 Godot 导入。
2. 运行时报 `Nil.label`：检查 `LevelUpPanel.tscn` 的三个 Resource 导出槽。
3. `Expected 1 argument(s)`：检查 Main 是否在 `call()` 中传了 `upgrade.amount`。
4. 显示 +80、实际 +40：检查 Player 是否还写死 `speed += 40`。
5. 修改 `.tres` 后显示没变：检查是否保存、改的是不是 Panel 当前引用的那一份文件。
6. 攻击间隔变成小于 `0.2`：检查 Weapon 是否保留 `maxf(0.2, ...)`。

## 学习检查

1. `UpgradeData.gd` 和 `move_speed.tres` 分别负责什么？
2. Resource 与 Node、PackedScene 的最重要区别是什么？
3. 如果没有 `@export` 的 Inspector 绑定，`move_speed_upgrade.label` 会怎样？
4. `upgrade.id` 和 `upgrade.amount` 各负责什么？你能复述从 Button 到 Player 的每次传参吗？
5. 为什么 `StringName` 使用 `&"..."`，但不是 UI 文本都要改成 StringName？
6. 为什么省略 `call()` 参数可能在运行时才报错？什么情况下可以提前检查？
7. 为什么玩家已经选过两次移动升级，也不应该改 `move_speed.tres.amount`？
8. 为什么现在不引入随机技能池、Singleton 或行为型 Resource？

**可选挑战（不影响下一课）：** 新建一份显示「移动速度 +73」的临时 UpgradeData，让测试按钮显示和 Player 增量跟着变化；实验后还原正式资产。

## 本课 Checkpoint

本课完成参考 Tag：`lesson-11-upgrade-data`。它代表「升级配置三项 Resource 化、按钮从数据读取、Main 转发 amount、Player/Weapon 参数化、固定三选一玩法及暂停队列保持不变」。

**下一课（Lesson 12）** 会在已有运行时 HP/XP/Level 状态基础上做 HUD，让玩家不必进入 Remote Inspector 才能看到这些数据。
