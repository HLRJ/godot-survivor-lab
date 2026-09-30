# Lesson 11：升级数据化设计

## 1. 背景与目标

Lesson 10 已经完成完整升级闭环：

```text
经验达到阈值
→ Player.level_up
→ Main 暂停战斗
→ LevelUpPanel 三选一
→ Main 根据 upgrade id 路由
→ Player / Weapon 得到真实强化
→ 恢复战斗
```

当前三个强化已经真正生效，但“升级定义数据”仍散落在 UI 与行为代码中：

```text
LevelUpPanel：
"移动速度 +40"
"攻击间隔 -0.1 秒"
"子弹伤害 +1"

Player / Weapon：
speed += 40
attack_interval -= 0.1
projectile_damage += 1
```

这使显示值与真实行为值存在漂移风险。

Lesson 11 的目标不是再做一次“升级生效”，而是把 Lesson 10 的硬编码升级重构成 Godot Resource 驱动的数据化升级，让：

```text
升级是什么
显示什么
数值是多少
```

集中在同一份 Resource 数据中，而 Player / Weapon 只保留行为。

## 2. 可见学习成果

完成本课后，玩法仍然是固定三个升级按钮，但数据来源改变：

```text
UpgradeData .tres
    ├── id
    ├── label
    └── amount
          │
          ▼
LevelUpPanel
    ├── 从 label 设置按钮文字
    └── 点击时 emit 整个 UpgradeData
          │
          ▼
Main
    ├── 根据 id 路由
    └── 把 amount 传给目标对象
          │
          ├── Player
          └── Weapon
```

最终必须完成一个肉眼可见的因果实验：

```text
不改任何 .gd
只把 move_speed.tres：
label  = "移动速度 +40" → "移动速度 +80"
amount = 40 → 80

F5
→ Button 自动显示 +80
→ 实际 Player.speed 也增加 80
```

这证明升级系统真正由 Resource 数据驱动，而不是只把配置文件当装饰。

## 3. 核心架构

采用“数据 Resource + 现有行为对象”方案。

### 3.1 UpgradeData

新增：

```text
scripts/upgrades/upgrade_data.gd
resources/upgrades/
```

定义：

```gdscript
class_name UpgradeData
extends Resource

@export var id: StringName
@export var label: String
@export var amount: float
```

职责仅为描述一项升级：

- `id`：稳定的业务标识，用于 Main 路由；
- `label`：玩家看到的按钮文字；
- `amount`：这一次升级的数值。

UpgradeData 不保存本局玩家已经选择几次，也不在运行时修改自身。

### 3.2 三个具体 Resource

创建：

```text
resources/upgrades/move_speed.tres
resources/upgrades/attack_speed.tres
resources/upgrades/projectile_damage.tres
```

初始数据：

```text
move_speed
id     = "move_speed"
label  = "移动速度 +40"
amount = 40.0

attack_speed
id     = "attack_speed"
label  = "攻击间隔 -0.1 秒"
amount = 0.1

projectile_damage
id     = "projectile_damage"
label  = "子弹伤害 +1"
amount = 1.0
```

### 3.3 LevelUpPanel

Lesson 10 中 UI 自己硬编码显示文本，并发出字符串 id。

Lesson 11 改为显式依赖三个 UpgradeData：

```gdscript
@export var move_speed_upgrade: UpgradeData
@export var attack_speed_upgrade: UpgradeData
@export var projectile_damage_upgrade: UpgradeData
```

Scene 通过 Inspector / TSCN 引用三个 .tres。

`_ready()` 从 Resource 设置 Button 文本：

```gdscript
move_speed_button.text = move_speed_upgrade.label
attack_speed_button.text = attack_speed_upgrade.label
damage_button.text = projectile_damage_upgrade.label
```

Signal 改为：

```gdscript
signal upgrade_selected(upgrade: UpgradeData)
```

按钮 callback 发出对应 Resource：

```gdscript
upgrade_selected.emit(move_speed_upgrade)
```

LevelUpPanel 仍然不知道 Player / Weapon 的内部属性。

### 3.4 Player / Weapon

行为方法不再保存平衡数值。

Player：

```gdscript
func upgrade_move_speed(amount: float) -> void:
    speed += amount
```

Weapon：

```gdscript
func upgrade_attack_speed(amount: float) -> void:
    attack_interval = maxf(0.2, attack_interval - amount)
    timer.wait_time = attack_interval

func upgrade_projectile_damage(amount: int) -> void:
    projectile_damage += amount
```

`0.2` 仍然属于 Weapon 的行为规则/安全下限，不属于某个升级定义，因此继续保留在 Weapon。

### 3.5 Main

Main 仍然负责行为路由，但不再知道具体平衡数值：

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

`_on_upgrade_selected` 的参数同步改为 `UpgradeData`。

职责边界保持：

```text
UpgradeData  = 配置数据
LevelUpPanel = 展示与选择
Main         = 路由
Player       = 玩家行为/运行时状态
Weapon       = 武器行为/运行时状态
```

## 4. Resource 从磁盘到运行时

`UpgradeData.gd` 定义“这种 Resource 有哪些字段”。

`.tres` 是具体 Resource 实例的文本资源文件。

关系：

```text
UpgradeData.gd
= 类型定义

move_speed.tres
= 一个具体 UpgradeData 数据资产
```

它与 PackedScene 的区别：

```text
Projectile.tscn
→ instantiate()
→ 创建 Node 并进入 SceneTree

move_speed.tres
→ load / Scene 引用
→ 得到 Resource 数据对象
→ 不进入 SceneTree
```

因此 UpgradeData 不使用 `add_child()`。

## 5. Resource 是共享引用，配置与运行时状态必须分开

多个对象引用同一个 `.tres` 时，通常使用的是同一份加载后的 Resource 对象。

因此本课明确规定：

```text
UpgradeData
= 只读配置

Player / Weapon
= 可变运行时状态
```

不允许：

```gdscript
move_speed_upgrade.amount += 10
move_speed_upgrade.current_level += 1
```

玩家本局已经选择几次升级，是未来独立的运行时状态问题，不放进 UpgradeData。

这样可以避免共享 Resource 被运行时修改后影响所有引用者。

## 6. class_name 的教学位置

Lesson 10 已经遇到：

```gdscript
@onready var player: CharacterBody2D = $Player
```

静态类型系统不知道 Player 自定义的 `level_up` Signal，因此使用：

```gdscript
player.connect("level_up", callback)
```

Lesson 11 第一次正式引入：

```gdscript
class_name UpgradeData
```

它让 Godot 把项目脚本注册为可命名类型，从而可以写：

```gdscript
@export var move_speed_upgrade: UpgradeData
signal upgrade_selected(upgrade: UpgradeData)
```

本课只用 `class_name` 解决 UpgradeData 的真实类型需求，不顺手把 Player / Weapon 全部改成自定义 class_name，避免无关重构。

## 7. 四层解释原则在本课的应用

### 7.1 为什么用 Resource

**怎么做**

用 `UpgradeData : Resource` + 三个 `.tres` 保存 id / label / amount。

**为什么**

Lesson 10 已经出现同一个升级数值在 UI 和行为代码重复出现的真实问题。Resource 让显示值和行为值共享同一个数据源，并且能在 Inspector 中编辑。

**如果错了会发生什么**

如果只把 label 放进 Resource，而行为仍然：

```gdscript
speed += 40.0
```

则 Resource 改成 73 后，UI 可能显示 73，实际仍然只增加 40，形成“假数据驱动”。

测试必须故意使用非默认值 73 / 0.23 / 4，证明行为读取的是参数。

**还能怎么设计**

- Dictionary：轻量但字段弱类型、key 拼写错误更隐蔽；
- JSON：适合外部交换/Mod/服务端配置，但当前需要额外解析和校验；
- Singleton：适合全局服务/运行时状态，不适合三个静态升级定义；
- 行为型 Resource：适合大量复杂异构技能，但当前会过早引入多态和 Strategy Pattern。

当前数据 Resource 是复杂度最低且正好解决真实问题的方案。

### 7.2 为什么继续由 Main 路由

**怎么做**

Main 使用 `upgrade.id` 决定调用 Player 还是 Weapon，并传入 `upgrade.amount`。

**为什么**

当前三个升级的行为归属已经稳定：移动属于 Player，攻击间隔和 Projectile Damage 属于 Weapon。Main 本来就是 Lesson 10 的协调层。

**如果错了会发生什么**

如果 LevelUpPanel 直接修改 Player / Weapon，会让 UI 知道战斗内部结构；未来替换 UI 时底层逻辑也被牵连。

如果 Resource 自己直接修改目标对象，则会把本课同时升级成“行为 Resource”，增加额外概念。

**还能怎么设计**

以后技能行为差异明显时，可以让 Upgrade Effect / Strategy 自己 `apply(target)`；但 Lesson 11 只做数据与行为分离，暂不引入。

### 7.3 为什么 Resource 不保存当前强化层数

**怎么做**

Resource 只保存定义；Player / Weapon 保存本局状态。

**为什么**

升级定义是静态配置，而“这一局已经拿了几层”是玩家实例状态，两者生命周期不同。

**如果错了会发生什么**

共享 Resource 的运行时修改可能让多个消费者互相污染，并让重新开始一局时状态难以重置。

**还能怎么设计**

未来可以增加独立 RunState / UpgradeState 保存选择次数；当前没有真实需求，不提前实现。

## 8. 教学 Gate

Lesson 11 保持学习者亲手完成核心概念，AI 处理重复样板、测试、文档和 Git。

### Gate 1：亲手定义 UpgradeData

学习者亲手写：

```gdscript
class_name UpgradeData
extends Resource

@export var id: StringName
@export var label: String
@export var amount: float
```

必须能解释：

- Resource 与 Node 的区别；
- `class_name` 为什么让 `UpgradeData` 成为静态类型；
- `@export` 为什么使字段可在 Inspector 编辑。

### Gate 2：亲手创建第一份 .tres

学习者在 Godot 中创建 `move_speed.tres`，填写：

```text
id = move_speed
label = 移动速度 +40
amount = 40
```

AI 可创建另外两份重复 Resource。

### Gate 3：亲手去除一个魔法数字

学习者把：

```gdscript
func upgrade_move_speed() -> void:
    speed += 40.0
```

改为：

```gdscript
func upgrade_move_speed(amount: float) -> void:
    speed += amount
```

随后用 73 做自动测试，证明不是硬编码。

### Gate 4：亲手让 Signal 传 Resource

学习者修改：

```gdscript
signal upgrade_selected(upgrade: UpgradeData)
```

并让一个 Button callback：

```gdscript
upgrade_selected.emit(move_speed_upgrade)
```

必须解释 Signal 参数传递的是对象引用。

### Gate 5：亲手完成 Main 的一条 Resource 路由

学习者至少亲手把 `move_speed` 分支改为使用：

```gdscript
player.call("upgrade_move_speed", upgrade.amount)
```

其余重复分支可由 AI 补齐。

## 9. 因果实验

### 实验 A：只改 .tres，不改 GDScript

把 move speed Resource：

```text
label  +40 → +80
amount 40  → 80
```

预测后 F5。

必须同时观察：

- Button 文本变成 +80；
- Player 实际速度一次增加 80。

如果只有一边变化，说明仍有硬编码。

### 实验 B：缺失 Resource 引用

临时清空 LevelUpPanel 的一个 UpgradeData slot，预测运行结果。

用于理解：

```text
@export
= 暴露依赖槽位
≠ 自动保证依赖已经配置
```

实验后恢复正确 Resource。

### 实验 C：Resource 与运行时状态

只修改 Player / Weapon 状态，不修改 Resource.amount；观察下一次同类升级仍然读取固定配置 amount。

用于强化“配置定义”和“运行时状态”生命周期不同。

## 10. 自动测试策略

新增测试至少覆盖：

### UpgradeData / .tres

- `UpgradeData` 是 Resource 子类；
- 三个 `.tres` 可以加载；
- 三份数据的 id / label / amount 正确；
- LevelUpPanel 三个 Resource slot 非空。

### 反硬编码行为测试

使用非默认值：

```text
move speed amount = 73
attack speed amount = 0.23
damage amount = 4
```

验证：

- Player speed 真正 +73；
- Weapon attack interval 真正减少 0.23，同时仍不低于 0.2；
- Weapon projectile damage 真正 +4。

### UI 数据源

使用测试 UpgradeData：

```text
label = "测试移动 +73"
```

验证 Button.text 来自 Resource.label，而不是 TSCN 硬编码。

点击 Button 后，`upgrade_selected` 发出的对象必须就是对应 UpgradeData。

### Main 集成

Panel 发出 UpgradeData 后：

- Main 根据 `upgrade.id` 路由；
- Main 使用 `upgrade.amount`；
- pending level-up 语义保持 Lesson 10 不变；
- 非法 id 不消费 pending upgrade；
- 最终正常恢复 SceneTree。

### 回归

Lesson 02–10 所有既有测试继续通过。

## 11. 非目标

Lesson 11 不实现：

- 随机三选一；
- 动态创建 Button；
- UpgradePool；
- 稀有度、图标、描述、等级上限；
- 行为型 Resource / Strategy Pattern；
- Dictionary/JSON 配置替代实现；
- Singleton / Autoload；
- GameManager；
- 当前强化层数；
- 存档；
- HUD。

这些能力只有在后续真实需求出现时再引入。

## 12. 文档体系同步收敛

从本课开始，权威文档结构固定为：

```text
docs/
├── lessons/          主线课程，必须跟课程推进
├── concepts/         可复用概念，按需更新
├── troubleshooting/ 真实踩坑后按症状沉淀
└── superpowers/      设计 spec / implementation plan
```

`docs/learning-notes/` 不再作为活跃课程体系维护。

旧 `00-bootstrap.md` 在确认其独有信息已经被 Lesson 00 / Lesson 01 / concepts 覆盖后可以删除；不为了保留历史目录继续创建重复 learning note。

每次 Lesson 设计增加 Concept 检查：

```text
是否出现：
1. 后续会反复复用的概念？
2. 主线讲太深会打断节奏的知识？
3. 真实踩过、值得独立解释的机制？

有 → 新建或更新 docs/concepts/
无 → 不机械新增
```

## 13. 本课文档债清理

Lesson 11 实施阶段由 AI 负责补齐 Lesson 08–10 已经真实学过、值得长期复用的 Concept，不占用学习者核心编码时间：

```text
docs/concepts/signal-and-event-flow.md
docs/concepts/deferred-physics-and-lifecycle.md
docs/concepts/scene-tree-pause.md
docs/concepts/resource-and-data-driven-design.md
```

其中前三篇整理已学内容；第四篇是 Lesson 11 新概念。

这些 Concept 必须遵守四层解释原则，但不复制整篇 Lesson。

同时修正课程地图中 Lesson 10 checkpoint：

```text
lesson-10-level-up
→ lesson-10-level-up-choice
```

## 14. 完整运行时数据流

```text
磁盘：
move_speed.tres
id="move_speed"
label="移动速度 +40"
amount=40
        │
        ▼
LevelUpPanel Scene 引用 Resource
        │
        ├── _ready() → Button.text = label
        │
        └── Button pressed
                ↓
upgrade_selected.emit(UpgradeData)
                ↓
Main._on_upgrade_selected(upgrade)
                ↓
Main._apply_upgrade(upgrade)
                ↓
match upgrade.id
                ↓
Player.upgrade_move_speed(upgrade.amount)
                ↓
speed += amount
```

攻击速度和 Projectile Damage 使用同一模式，只是行为对象不同。

## 15. 完成标准

Lesson 11 完成时必须同时满足：

1. 三个升级均由 UpgradeData `.tres` 提供 id / label / amount；
2. LevelUpPanel 的显示文本来自 Resource；
3. Signal 传递 UpgradeData 对象而不是裸字符串；
4. Main 使用 Resource id 路由、Resource amount 传参；
5. Player / Weapon 不再硬编码三个升级增量；
6. 修改 `.tres` 即可同时改变 UI 与实际强化数值；
7. Resource 不承载玩家本局可变状态；
8. Lesson 02–10 历史行为无回归；
9. 新增 Resource / UI / Main 测试通过；
10. Lesson 11 主线文档和 Resource Concept 完成；
11. Lesson 08–10 的 Concept 文档债补齐；
12. 权威课程设计明确四目录文档职责，并停止扩展 learning-notes；
13. 创建 checkpoint tag：`lesson-11-upgrade-data`。
