# Signal 的完整事件流：connect、emit 与回调

> 学习来源：Lesson 07 的内置 `Area2D.body_entered`，Lesson 08 的自定义 `Enemy.died`，Lesson 10 的 `Player.level_up`，Lesson 11 的 `LevelUpPanel.upgrade_selected`。

## 一个完整 Signal 包含五步

```text
定义事件 signal
        ↓
接收者用 connect() 订阅
        ↓
事件源 emit(...) 通知
        ↓
Godot 将 emit 参数传给 callback
        ↓
callback 执行对应行为
```

例如 Lesson 11：

```gdscript
# LevelUpPanel.gd：声明
signal upgrade_selected(upgrade: UpgradeData)

# Main.gd：订阅一次
level_up_panel.connect("upgrade_selected", _on_upgrade_selected)

# LevelUpPanel.gd：用户点击后发生事件
upgrade_selected.emit(move_speed_upgrade)

# Main.gd：收到该对象
func _on_upgrade_selected(upgrade: UpgradeData) -> void:
    # 继续处理升级
    pass
```

**`connect()` 本身不会触发 callback；`emit()` 才代表一次实际事件。**

## connect 是持续订阅，不是一次性接收

`_ready()` 里 connect 一次后，只要连接仍有效，每次 emit 都会调用对应 callback；无需每次升级重新 connect。

同一个 Signal 可以连接多个不同 callback：

```gdscript
player.level_up.connect(_show_choices)
player.level_up.connect(_play_level_up_sound)
```

每次 `player.level_up.emit(level)`，两个接收者都会得到这次事件（只要连接有效且对象存在）。

注意连接重复是否被 Godot 拒绝、是否需要断开，要看实际连接对象与生命周期，不能把 connect 当成每次点击都应该做的动作。

## 回调参数到底从哪来？

```gdscript
signal died(dead_enemy: Node2D)
died.emit(self)
```

连接：

```gdscript
spawned_enemy.died.connect(_on_enemy_died)
```

接收：

```gdscript
func _on_enemy_died(dead_enemy: Node2D) -> void:
    pass
```

`dead_enemy` 的值来自 `emit(self)`，而不是 `connect()` 传入。对 Lesson 11 的 `upgrade_selected` 也是同样规则——传过来的是完整 Resource 对象。

如果 callback 不使用某个参数，可以写成 `_new_level`，表示“有这个形参，但暂时不读它”。

## 内置 Signal 和自定义 Signal

`Area2D.body_entered(body)`、`Timer.timeout` 由 Godot 引擎定义；`Player.level_up(new_level)`、`Enemy.died(dead_enemy)`、`LevelUpPanel.upgrade_selected(upgrade)` 是项目自定义的。

`Timer.timeout` 没有传出额外参数，因此可以直接连接无参数的 `_attack()`：

```gdscript
timer.timeout.connect(_attack)
```

这和自定义信号的底层思路一致，差别只在声明者及参数。

## 为什么有的写 .timeout.connect，有的写 .connect("name", ...)？

```gdscript
@onready var timer: Timer = $Timer
timer.timeout.connect(_attack)

@onready var player: CharacterBody2D = $Player
player.connect("level_up", _on_player_level_up)
```

编译器知道 `Timer` 自带 `timeout`，但 `CharacterBody2D` 的静态类型未声明我们写在 `player.gd` 中的自定义 `level_up`。因此本项目采用动态字符串形式来 connect。

如果将来定义 `class_name Player` 并把变量声明为 `Player`，就可以让静态类型系统知道该信号，使用更直接的点语法。

类似地，`player.call("upgrade_move_speed", ...)` 通过运行时方法查找，不像已知类型的直接调用那样提前检查自定义方法的参数个数。

## 为什么 Signal 而不是直接函数调用？

- **直接调用：** 已知对象和明确动作，例如 Main 命令 Player 修改速度。简单、容易跟踪、通常更适合“我要你做这件事”。
- **Signal：** 对事件源而言，只需报告“有事发生”，不知道谁要作出反应。例如 Enemy 死亡后掉落经验球，也可能以后还有音效、任务统计等多个订阅者。

`Enemy` 不应该为了发一个「死亡事件」就直接引用并修改所有这些系统。

**但不要把每一行代码都改成 Signal。** 当调用者明确知道负责动作的对象时，直接方法调用通常更清楚。过量信号会使事件链过长、难以定位。

## 如果错了，会发生什么？

1. 漏 connect：emit 了但没有任何接收者，升级菜单可能永远不出现。
2. 漏 emit：connect 虽在，但事件源没有通知；callback 不会执行。
3. 参数个数/类型不匹配：可能产生运行时调用错误。
4. 同步调用链被误判：普通 Signal 的发出与回调通常在当前调用链同步执行；不要假设 emit 一定延迟一帧。
5. 只发字符串、接收者需要 Resource：例如 Lesson 11 改接口时，Main 仍要求 `String`，会出现 Object 无法转换为 String 的错误。

## 四层思考总结

- **怎么做：** 声明 → connect → emit → callback。
- **为什么：** 事件源与接收者解耦，允许多个响应方。
- **做错会怎样：** 漏订阅、漏发出、签名不匹配和调用时序问题。
- **还能怎么做：** 明确目标对象时直接函数调用更简单；不应盲目全用 Signal。

**练习：** 解释为什么 `get_tree().paused = true` 也不会立即中断当前 `add_experience()` 的 `while` 中继续 `emit(level)`。答案涉及同步回调与当前调用栈，参见 [SceneTree 暂停](scene-tree-pause.md)。
