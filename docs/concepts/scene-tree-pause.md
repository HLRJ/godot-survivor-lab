# SceneTree 暂停与 process_mode：为何游戏停了按钮还能点？

> 来自 Lesson 10：升级时冻结战斗，但 LevelUpPanel 的三个按钮仍能处理玩家点击。

## 怎么做

Main 在收到 `Player.level_up` 后执行：

```gdscript
func _on_player_level_up(_new_level: int) -> void:
    pending_level_ups += 1
    if level_up_choice_open:
        return

    level_up_choice_open = true
    level_up_panel.show_choices()
    get_tree().paused = true
```

`LevelUpPanel` 根节点是 CanvasLayer，`process_mode` 设置为 `Node.PROCESS_MODE_WHEN_PAUSED`。

最后一次有效选择时：

```gdscript
pending_level_ups -= 1
if pending_level_ups > 0:
    return

level_up_choice_open = false
level_up_panel.hide_choices()
get_tree().paused = false
```

## 为什么这个设计能工作

`get_tree().paused = true` 让 SceneTree 进入暂停状态。普通可暂停节点的 `_process()` / `_physics_process()`、受影响的 Timer 等会停止按正常游戏节奏工作；Godot 的物理模拟也会随 SceneTree 的暂停而停止（如有自定义处理模式，需要分别理解）。

LevelUpPanel 的处理模式特地选择 **WHEN_PAUSED**，因此它能继续接收/处理按钮输入，不会连同战斗一起冻结。

`level_up_choice_open` 不是引擎暂停的替代品：它是「是否已经打开选择流程」这一层**业务状态**；`SceneTree.paused` 是引擎层**运行状态**。

## 为什么暂停以后 while 还可能继续？

`add_experience()` 里可能有：

```gdscript
while experience >= experience_to_next_level:
    experience -= experience_to_next_level
    level += 1
    experience_to_next_level += 3
    level_up.emit(level)
```

在普通同步 Signal 中，`emit` 会立即调用已连接的回调。回调将 `paused` 改为 true，并**不会把当前正在执行的 `while` 调用栈直接终止**。如果这次一次拿到足够多经验，while 仍可能连续发出多个 `level_up`。

因此 Main 用 `pending_level_ups` 记录待处理选择次数：

```text
一次 XP 产生两次升级
        ↓
level_up emit 两次
        ↓
pending_level_ups = 2
        ↓
第一次选择：pending=1（保持暂停）
        ↓
第二次选择：pending=0（隐藏面板并恢复运行）
```

不能把「界面只弹一次」误解成「只升级一次」。

## 如果写错，会发生什么

1. Panel 未设 WHEN_PAUSED：整个游戏停了，按钮也不能交互，无法恢复。
2. 只有 `level_up_choice_open` 而不记录次数：一次跨多级时会丢掉待选强化。
3. 最后一次选择后忘记 `paused=false`：界面隐藏，战斗却一直不动。
4. 对错误的 ID 也减 `pending_level_ups`：无效请求会消耗升级机会。
5. 以为 `paused=true` 能中断已执行到一半的函数：对同步事件栈作出错误时序假设。

## 还能怎么设计？

可以维护一个全局 `game_paused` 布尔变量，让所有 Player、Enemy、Weapon、Timer 自己判断是否执行：

```gdscript
if game_paused:
    return
```

但每个系统都要遵守这个约定，容易漏掉碰撞和 Timer；本项目此时只需要一次整体暂停，因此直接使用 SceneTree 机制更合适。

以后若出现多个暂停原因（菜单、对话、剧情、战斗慢动作）、网络游戏或独立子系统，可以考虑专门的 RunState / 状态机与不同 process mode，但不是 Lesson 10 的前置需求。

## 四层思考

- **怎么做：** `get_tree().paused` + `PROCESS_MODE_WHEN_PAUSED` + 队列计数。
- **为什么：** 引擎负责暂停大部分游戏处理，而 UI 继续交互。
- **写错会怎样：** 面板冻结、漏升级、无法恢复、队列不一致。
- **其他方案：** 自行维护全局暂停标记/状态机，复杂度更高，等真需要再引入。

延伸阅读：[Signal 的同步事件流](signal-and-event-flow.md) · [Lesson 10](../lessons/10-level-up-choice.md)。
