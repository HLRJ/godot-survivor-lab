# Resource 与数据驱动设计：数据放哪里，行为放哪里？

> 初次出现：Lesson 11。先完成 [Lesson 11：升级数据化](../lessons/11-upgrade-data.md)，再回来系统理解。

## 问题：为什么不能把所有数字写进脚本？

最开始只有三项升级：

```gdscript
speed += 40.0
```

当 UI 还写着「移动速度 +40」时，这不难维护。但几十项升级、装备、敌人出现后，UI 文字与真正平衡数值可能来自不同文件，更新时容易漏掉某一处。

**需要把“是什么、数值多少”从“执行动作”中分离。**

## 怎么做：一个类型，多个具体数据资产

```gdscript
class_name UpgradeData
extends Resource

@export var id: StringName
@export var label: String
@export var amount: float
```

`UpgradeData.gd` 决定字段结构；`move_speed.tres` 记录一份数据：

```text
id = move_speed
label = 移动速度 +40
amount = 40.0
```

LevelUpPanel 持有它：

```gdscript
@export var move_speed_upgrade: UpgradeData

func _ready() -> void:
    move_speed_button.text = move_speed_upgrade.label
```

选中时发送对象：

```gdscript
upgrade_selected.emit(move_speed_upgrade)
```

Main 根据 `upgrade.id` 找目标，传入 `upgrade.amount`；行为方法只接收参数：

```gdscript
func upgrade_move_speed(amount: float) -> void:
    speed += amount
```

## Resource、Node、Scene / PackedScene 区别

| 对象 | 代表什么 | 常见用途 |
| --- | --- | --- |
| `Resource` | 可保存、共享的**数据对象** | 武器数值、技能配置、主题、纹理 |
| `Node` | 场景树中的对象，拥有生命周期/处理能力 | Player、Enemy、Timer、按钮 |
| `PackedScene` | 已打包的场景模板，也是 Resource 的一种 | `instantiate()` 后生成 Node 树 |
| `.tres` | Godot 文本资源文件形式之一 | 保存 UpgradeData、Theme 等 |
| `.tscn` | 文本场景文件形式 | 保存 Node 的结构与属性 |

因此普通 UpgradeData 不通过 `add_child()` 进入 SceneTree，也不需要 `_process()`。

## 为什么使用 class_name 和 @export

`class_name UpgradeData` 把当前脚本注册成一个全局可命名的类型。可以写：

```gdscript
signal upgrade_selected(upgrade: UpgradeData)
@export var move_speed_upgrade: UpgradeData
```

这让编辑器知道期望哪种资源。`@export` 是**暴露可配置槽位**，不是“自动生成并绑定一份 UpgradeData”。

当槽位未绑定：

```gdscript
move_speed_upgrade == null
```

那么读取 `move_speed_upgrade.label` 就会发生 `Invalid access ... type 'Nil'`。这是真实的 Lesson 11 故障实验。

### 为什么 StringName 而不是 String？

```gdscript
var id: StringName = &"move_speed"
var label: String = "移动速度 +40"
```

`&"..."` 创建 `StringName` 字面量，适合稳定、经常被比较的方法名/升级 ID。`"..."` 产生 `String`，适合展示、拼接、变化的文本。两者并非只能在各自场景使用；本课强调**字段的用途和类型一致**。

## 为什么 Resource 不保存当前升级层数？

`amount=40` 是**升级定义**：这项升级每次增加多少。`Player.speed=300` 是**本局状态**：这局已经累计到多少。

同一份 Resource 可能被多个对象引用。若运行时写：

```gdscript
move_speed_upgrade.amount += 40.0
```

可能同时影响所有正在使用这份共享 Resource 的对象。若需要玩家已选次数，应放在 Player/RunState，而不是修改公共升级定义。

本课遵守“Resource 配置只读，Player / Weapon 状态可变”的纪律。

## 如果做错了，会发生什么？

1. **显示与逻辑仍然各写一份数值：** UI 更新了，实际效果可能没更新。用非默认值 73 测试是否真正参数化。
2. **导出槽为空：** 运行时访问 `Nil.label`。应验证场景绑定，必要时在初始化加入明确配置检查。
3. **游戏过程中修改 Resource.amount：** 共享引用可能互相污染，也使新的一局难以回到标准配置。
4. **把 `.tres` 当 Node：** 不存在通过 `add_child` 给它位置和物理更新的概念。
5. **新资源只改 label 没改 amount：** 这不一定是框架错误，而是配置字段彼此不一致。配置资产也需要自检。

## 还能怎么设计？为什么这课不选？

| 方案 | 适用情境 | 本课没选的原因 |
| --- | --- | --- |
| `Dictionary` | 临时/运行时动态结构 | Key 拼写错误更难发现，缺少同样直接的类型和 Inspector 体验 |
| JSON | Mod、外部服务配置、跨语言数据 | 需要加载、解析、校验、转换；纯 Godot 资产没必要 |
| Singleton / Autoload | 跨场景全局服务、运行状态 | 三个升级定义不是全局管理服务，提前使用会扩大耦合 |
| 行为型 Resource（`apply`） | 不同技能效果差异很大 | 现在三个都是简单数值修改，引入继承/多态为时过早 |
| 数据型 Resource（本课） | 可编辑的 Godot 内部配置 | 恰好解决 UI 和行为重复保存数字的实际问题 |

将来有火球、链式闪电、毒伤、召唤等完全不同的行为时，再考虑将行为抽象成策略对象/行为型 Resource，而不是永远用 Main 中的 `match`。

## 四层思考总结

- **怎么做：** `class_name` 定义数据类型，`.tres` 创建具体资产，Scene 用 `@export` 引用，Main 传参。
- **为什么：** 数值与显示的来源统一，调平衡更方便。
- **出错会怎样：** 未绑定导致 Nil；硬编码造成显示与行为漂移；运行时修改共享 Resource 导致状态污染。
- **替代方案：** Dictionary/JSON/Singleton/行为型 Resource 都有价值，但当前规模不值得额外复杂度。

**自测：** 不看代码，你能描述 `move_speed.tres.amount` 如何一路进入 `Player.upgrade_move_speed(amount)` 吗？
