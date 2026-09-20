# Lesson 10：升级三选一

## 本课目标

在 Lesson 09 已完成“Enemy 死亡 → ExperienceGem 掉落 → Player 拾取 → XP 增加”的基础上，把 Survivor-like 最核心的一段循环真正跑通：

```text
拾取经验
→ 达到升级阈值
→ Player 升级
→ 暂停战斗
→ 显示三选一
→ 选择一个真实强化
→ 恢复战斗
```

本课最终实现三个可以重复叠加的强化：

- 移动速度 +40；
- 攻击间隔 -0.1 秒，最低 0.2 秒；
- Projectile 伤害 +1。

这节课表面上是在做“升级 UI”，实际上真正要学透的是四件事：

1. 运行时状态应该由谁持有；
2. Signal 的完整发布/订阅模型；
3. Timer 如何驱动自动攻击；
4. SceneTree 暂停以后，为什么升级 UI 还能继续工作。

## 先把前面的课接起来

Lesson 09 的 Player 已经有：

```gdscript
var experience: int = 0

func add_experience(amount: int) -> void:
    experience += amount
```

所以 Lesson 10 不是重做经验系统，而是在这条链后面继续：

```text
ExperienceGem
→ Player.add_experience()
→ experience 增加
→ 达到阈值
→ level_up
→ Main
→ LevelUpPanel
→ Player / Weapon 得到强化
```

本课采用四个职责明确的对象：

```text
Player
负责 XP / Level / 移动速度

Weapon
负责攻击间隔 / 未来 Projectile 的伤害

LevelUpPanel
负责显示三选一，并告诉外界“玩家选了什么”

Main
负责把上面三个对象协调起来
```

Main 是协调者，不是所有状态的仓库。

## 第一步：Player 保存 Level 和升级阈值

Player 新增：

```gdscript
signal level_up(new_level: int)

@export var speed: float = 220.0
var experience: int = 0
var level: int = 1
var experience_to_next_level: int = 5
```

第一版采用简单线性阈值：

```text
Lv1 → Lv2：5 XP
Lv2 → Lv3：8 XP
Lv3 → Lv4：11 XP
Lv4 → Lv5：14 XP
...
```

每次升级以后：

```gdscript
experience_to_next_level += 3
```

### 为什么 XP 不能升级后直接清零

假设：

```text
当前：Lv1，4 / 5 XP
一次获得：3 XP
```

真实结果应该是：

```text
4 + 3 = 7
7 - 5 = 2

最终：
Lv2
2 / 8 XP
```

如果升级后直接：

```gdscript
experience = 0
```

就等于吞掉玩家多获得的 2 XP。

因此我们写：

```gdscript
func add_experience(amount: int) -> void:
    if amount <= 0:
        return

    experience += amount

    while experience >= experience_to_next_level:
        experience -= experience_to_next_level
        level += 1
        experience_to_next_level += 3
        level_up.emit(level)
```

`amount <= 0` 时直接返回，是明确规定“获得经验”不能反向减少 XP。

## 为什么这里必须是 while，而不是 if

假设一次获得 14 XP。

如果只有：

```gdscript
if experience >= experience_to_next_level:
```

它最多只会处理一次升级。

但真实计算是：

```text
开始：
Lv1
0 / 5

得到 14 XP
↓
14 >= 5
14 - 5 = 9
Lv2
下一阈值 = 8
emit(2)

还有 9 XP
↓
9 >= 8
9 - 8 = 1
Lv3
下一阈值 = 11
emit(3)

最终：
Lv3
1 / 11
```

所以这里真正表达的是：

> 只要当前剩余 XP 仍然足够升级，就继续处理。

因此使用：

```gdscript
while experience >= experience_to_next_level:
```

## Signal：connect 不是“接收一次”，而是建立订阅

这是本课最容易混淆、也最重要的概念之一。

可以先记住：

```text
connect() = 建立长期订阅关系
emit()    = 某一次事件真的发生
callback  = 事件发生后被调用的函数
```

例如 Main 在 `_ready()` 中：

```gdscript
player.connect("level_up", _on_player_level_up)
```

不是“现在接收一次升级”。

它是在登记：

```text
以后只要这个 Player 发出 level_up
→ 就调用 _on_player_level_up
```

这条连接建立一次以后，可以连续接收后续很多次 `emit()`。

## 一个 Signal 能不能有多个接收者

可以。

例如理论上可以同时写：

```gdscript
player.connect("level_up", _on_player_level_up)
player.connect("level_up", _play_level_up_sound)
player.connect("level_up", _record_level_statistics)
```

那么一次：

```gdscript
level_up.emit(2)
```

可以通知多个监听者：

```text
                 level_up.emit(2)
                         │
             ┌───────────┼───────────┐
             ▼           ▼           ▼
           Main        Audio     Statistics
```

这就是 Signal 解耦的价值：

Player 只负责宣布：

> “我升级了。”

Player 不需要知道到底有几个系统正在监听。

## Signal 也可以连续 emit

Player 的：

```gdscript
while experience >= experience_to_next_level:
    ...
    level_up.emit(level)
```

如果一次跨两级，就真的会发出两次 Signal：

```text
emit(2)
→ Main callback 执行一次
→ 返回 Player

继续 while

emit(3)
→ Main callback 再执行一次
→ 返回 Player
```

所以 Main 的：

```gdscript
pending_level_ups += 1
```

会执行两次，最终变成 2。

不是 Signal 自动知道“升了两级”，而是发生了两次“升一级事件”。

## 两种 connect() 写法为什么不一样

我们已经见过：

```gdscript
timer.timeout.connect(_attack)
```

也见过：

```gdscript
player.connect("level_up", _on_player_level_up)
```

本质都是：

```text
Signal
→ connect
→ Callable
```

区别来自静态类型。

Weapon 中：

```gdscript
@onready var timer: Timer = $Timer
```

Godot 静态类型系统知道 `Timer` 内置类本来就有：

```text
timeout
```

所以可以直接：

```gdscript
timer.timeout.connect(_attack)
```

但 Main 中：

```gdscript
@onready var player: CharacterBody2D = $Player
```

静态类型只知道它是 `CharacterBody2D`。

`CharacterBody2D` 官方类型定义并不知道我们在 `player.gd` 里自定义了：

```gdscript
signal level_up(new_level: int)
```

所以当前课程使用动态连接：

```gdscript
player.connect("level_up", _on_player_level_up)
```

运行时具体的 Player 实例挂着 `player.gd`，所以确实存在这个 Signal。

以后如果正式引入：

```gdscript
class_name Player
extends CharacterBody2D
```

并让变量类型变成：

```gdscript
@onready var player: Player = $Player
```

类型系统就认识自定义 Player，届时可以更自然地写：

```gdscript
player.level_up.connect(_on_player_level_up)
```

当前课程暂时不提前引入 `class_name`。

## emit 里的参数到底去了哪里

定义：

```gdscript
signal level_up(new_level: int)
```

发出：

```gdscript
level_up.emit(level)
```

如果当前：

```text
level = 3
```

就相当于：

```text
emit(3)
```

连接的 callback：

```gdscript
func _on_player_level_up(_new_level: int) -> void:
```

收到的就是：

```text
_new_level = 3
```

### 为什么 _new_level 传进来了却没有用

当前 Main 只关心：

> “发生了一次升级。”

它暂时不关心具体升到了第几级。

因此：

```gdscript
func _on_player_level_up(_new_level: int) -> void:
    pending_level_ups += 1
```

参数名前面的下划线表达：

> 这个参数按照接口会传进来，但当前函数有意不使用。

以后 UI 可能会显示：

```text
LEVEL 5!
```

那时就可以真的使用：

```gdscript
func _on_player_level_up(new_level: int) -> void:
    level_up_panel.set_level(new_level)
```

保留 `new_level`，让 Signal 的语义仍然完整。

## 第二步：重新理解 Weapon 和 Projectile

Lesson 06 已经有：

```text
Weapon
→ instantiate()
→ Projectile
```

到了升级系统以后，一个重要问题出现了：

> “子弹伤害 +1”到底应该改谁？

如果直接修改某一颗 Projectile：

```gdscript
projectile.damage += 1
```

只会改变这一颗临时实例。

而 Projectile 一直在：

```text
创建
→ 飞行
→ 命中
→ queue_free()
→ 下一颗重新 instantiate()
```

所以真正需要持久保存的是：

```gdscript
var projectile_damage: int = 1
```

它属于 Weapon。

可以把 Weapon 更准确地理解成：

> **持续存在的武器状态拥有者 + Projectile 工厂/控制器。**

而 Projectile 是一次性的执行对象。

因此：

```text
Weapon.projectile_damage = 2
        ↓
以后每次 instantiate()
        ↓
新 Projectile.damage = 2
```

实际代码在创建 Projectile 时写入：

```gdscript
projectile.set("damage", projectile_damage)
```

这再次强化了一个前面已经学过的区别：

```text
PackedScene / Projectile.tscn
= 模板

instantiate() 后的 Projectile
= 某一个运行时实例

Weapon 上保存的属性
= 这一局持续存在的武器状态
```

## Timer：自动攻击为什么会一直发生

Weapon 中：

```gdscript
@export var attack_interval: float = 0.8
@onready var timer: Timer = $Timer

func _ready() -> void:
    timer.wait_time = attack_interval
    timer.timeout.connect(_attack)
    timer.start()
```

这三行可以翻译成：

```text
设置闹钟周期
↓
告诉闹钟“响的时候调用谁”
↓
启动闹钟
```

### @onready var timer

```gdscript
@onready var timer: Timer = $Timer
```

不是创建 Timer。

真正的 Timer 已经是 Scene Tree 中的子节点：

```text
Player
└── Weapon
    └── Timer
```

这行代码只是等节点进入 Scene Tree、子节点可用后，找到 `$Timer` 并把引用保存到变量 `timer`。

### wait_time

```gdscript
timer.wait_time = attack_interval
```

当前：

```text
attack_interval = 0.8
```

所以 Timer 每轮周期是 0.8 秒。

可以区分：

```text
wait_time
= 每一轮应该倒计时多久

time_left
= 当前这一轮还剩多久
```

### timeout.connect(_attack)

```gdscript
timer.timeout.connect(_attack)
```

不是立即调用 `_attack()`。

它是在登记：

```text
以后 Timer 发出 timeout
→ 调用 _attack
```

因此传进去的是函数引用：

```gdscript
_attack
```

而不是立即执行：

```gdscript
_attack()
```

`Timer.timeout` 本身没有参数，因此：

```gdscript
func _attack() -> void:
```

也不需要 Signal 参数。

对比：

```text
body_entered(body)
→ callback 收到 body

level_up(level)
→ callback 收到 level

timeout()
→ callback 没有额外参数
```

### start()

```gdscript
timer.start()
```

正式启动倒计时。

默认不是 one-shot 时，运行效果就是：

```text
0.8 秒
→ timeout
→ _attack()

0.8 秒
→ timeout
→ _attack()

0.8 秒
→ timeout
→ _attack()
...
```

而 `_attack()` 自己负责判断这次有没有目标：

```text
Timer
只负责“什么时候尝试攻击”

_attack()
负责“这一次是否真的有目标可以攻击”
```

## 为什么升级攻速要同时改 Timer.wait_time

我们写：

```gdscript
func upgrade_attack_speed() -> void:
    attack_interval = maxf(0.2, attack_interval - 0.1)
    timer.wait_time = attack_interval
```

只修改：

```gdscript
attack_interval -= 0.1
```

只是把我们保存的数值改了。

真正工作的 Timer 仍然需要知道新的周期。

所以同步：

```gdscript
timer.wait_time = attack_interval
```

之后：

```text
0.8 秒
→ 0.7
→ 0.6
→ ...
→ 最低 0.2
```

`maxf(0.2, ...)` 保证攻击间隔不会继续降成 0 或负数。

本课升级时没有重新调用 `timer.start()`，因为我们只想修改后续周期，不需要强行把当前正在进行的一轮倒计时重置。

## 第三步：LevelUpPanel 把“按钮点击”翻译成“升级 ID”

LevelUpPanel Scene：

```text
LevelUpPanel
└── Overlay
    ├── DimBackground
    └── PanelContainer
        └── VBoxContainer
            ├── TitleLabel
            ├── MoveSpeedButton
            ├── AttackSpeedButton
            └── DamageButton
```

脚本中：

```gdscript
@onready var move_speed_button: Button = $Overlay/PanelContainer/VBoxContainer/MoveSpeedButton
```

这里没有 `move_speed_button.gd`。

`MoveSpeedButton` 是 Scene Tree 中真正存在的内置 Button 节点；`move_speed_button` 只是保存这个 Button 引用的变量。

## _on_move_speed_pressed 是自动生成的吗

不是。

真正建立关系的是：

```gdscript
move_speed_button.pressed.connect(_on_move_speed_pressed)
```

`_on_move_speed_pressed` 只是我们自己采用的清晰命名。

理论上可以写：

```gdscript
func potato() -> void:
    upgrade_selected.emit("move_speed")

move_speed_button.pressed.connect(potato)
```

一样能工作，只是可读性很差。

Godot 编辑器通过 Node / Signals 面板连接 Signal 时，经常会按照：

```text
_on_<node>_<signal>
```

这样的约定自动建议或生成 callback 名称。

但本课是在代码里手动 `connect()`，不是变量名自动绑定函数名。

## 两层 Signal 传导

LevelUpPanel 里实际存在两层事件：

第一层是 Godot Button 自带 Signal：

```text
玩家点击
→ Button.pressed
→ _on_move_speed_pressed()
```

第二层是我们自定义的业务 Signal：

```text
_on_move_speed_pressed()
→ upgrade_selected.emit("move_speed")
→ Main
```

完整链：

```text
鼠标点击
→ Button.pressed
→ callback
→ upgrade_selected("move_speed")
→ Main
→ Player.upgrade_move_speed()
```

LevelUpPanel 不需要知道 `Player.speed` 在哪里，也不需要知道 Weapon 怎么工作。

它只负责表达：

> 玩家选择了升级 ID：`move_speed`。

## 第四步：Main 作为协调者

Main 保存：

```gdscript
var pending_level_ups: int = 0
var level_up_choice_open: bool = false
```

并拿到三个对象：

```gdscript
@onready var player: CharacterBody2D = $Player
@onready var weapon: Node2D = $Player/Weapon
@onready var level_up_panel: CanvasLayer = $LevelUpPanel
```

在 `_ready()` 中建立两条长期 Signal 连接：

```gdscript
func _ready() -> void:
    player.connect("level_up", _on_player_level_up)
    level_up_panel.connect("upgrade_selected", _on_upgrade_selected)
```

可以把它们看成两个相反方向：

```text
游戏逻辑 → UI

Player.level_up
→ Main
→ 暂停 + 显示 LevelUpPanel


UI → 游戏逻辑

LevelUpPanel.upgrade_selected
→ Main
→ Player / Weapon
```

Main 没有替 Player 保存 XP，也没有替 Weapon 保存伤害。

它只负责“谁应该通知谁”。

## get_tree().paused = true 到底是什么

升级时：

```gdscript
level_up_panel.call("show_choices")
get_tree().paused = true
```

`get_tree()` 拿到当前整个 SceneTree。

把：

```gdscript
paused = true
```

可以理解为：

> 从现在开始，整棵场景树进入暂停规则。

普通游戏节点会停止正常处理，例如：

```text
Player._physics_process()
Enemy._physics_process()
Projectile._physics_process()
Weapon Timer
EnemySpawner Timer
```

所以升级面板出现时，战斗被冻结。

### 那为什么按钮还能点

LevelUpPanel 被设置为：

```gdscript
process_mode = Node.PROCESS_MODE_WHEN_PAUSED
```

因此：

```text
SceneTree.paused = true

普通战斗节点
→ 停

LevelUpPanel
→ 暂停时仍处理
→ Button 仍可点击
```

这就是 Survivor-like 升级界面能够“冻结战场但继续操作 UI”的基础。

## paused = true 为什么没有把当前 while 立刻掐断

这是本课一个很容易产生误解的地方。

假设 Player 一次获得足够跨两级的 XP。

第一次：

```text
Player
→ level_up.emit(2)
→ Main._on_player_level_up(2)
→ paused = true
```

这并不意味着 CPU 会停在这一行。

当前同步调用栈仍然会正常返回 Player，然后 Player 当前这次 `add_experience()` 继续执行。

所以第二轮 while 仍然可以：

```text
→ level_up.emit(3)
→ Main._on_player_level_up(3)
```

`paused = true` 更准确的意义是：

> 后续 SceneTree 的正常帧处理、物理处理等遵守暂停规则。

它不会从中间强制终止当前正在执行的同步函数链。

因此我们的连续升级设计可以成立。

## pending_level_ups 为什么需要存在

Main 收到升级：

```gdscript
func _on_player_level_up(_new_level: int) -> void:
    pending_level_ups += 1

    if level_up_choice_open:
        return

    level_up_choice_open = true
    level_up_panel.call("show_choices")
    get_tree().paused = true
```

如果一次连升两级：

```text
第一次 level_up
→ pending = 1
→ 打开 Panel

第二次 level_up
→ pending = 2
→ level_up_choice_open 已经是 true
→ 不再重复打开 Panel
```

因此屏幕上只有一个升级界面，但系统知道玩家欠两次选择。

## 第五步：根据升级 ID 路由

Main：

```gdscript
func _apply_upgrade(upgrade_id: String) -> bool:
    match upgrade_id:
        "move_speed":
            player.call("upgrade_move_speed")
        "attack_speed":
            weapon.call("upgrade_attack_speed")
        "projectile_damage":
            weapon.call("upgrade_projectile_damage")
        _:
            return false

    return true
```

这里的：

```text
"move_speed"
"attack_speed"
"projectile_damage"
```

应该理解成“升级 ID”，不是 Godot 自动识别的属性名称。

Godot 不会因为字符串叫 `move_speed` 就自动找到 `Player.speed`。

真正建立映射的是上面的 `match`。

选择结束：

```gdscript
func _on_upgrade_selected(upgrade_id: String) -> void:
    if not level_up_choice_open:
        return

    if not _apply_upgrade(upgrade_id):
        return

    pending_level_ups -= 1

    if pending_level_ups > 0:
        return

    level_up_choice_open = false
    level_up_panel.call("hide_choices")
    get_tree().paused = false
```

如果还有待处理升级：

```text
pending: 2 → 1
→ 继续暂停
→ Panel 继续显示
```

最后一次：

```text
pending: 1 → 0
→ hide_choices()
→ paused = false
→ 恢复战斗
```

## 三种升级最终修改了什么

### 移动速度

Player：

```gdscript
func upgrade_move_speed() -> void:
    speed += 40.0
```

```text
220 → 260 → 300 → ...
```

### 攻击速度

Weapon：

```gdscript
func upgrade_attack_speed() -> void:
    attack_interval = maxf(0.2, attack_interval - 0.1)
    timer.wait_time = attack_interval
```

```text
0.8 → 0.7 → 0.6 → ... → 0.2
```

### Projectile 伤害

Weapon：

```gdscript
func upgrade_projectile_damage() -> void:
    projectile_damage += 1
```

新 Projectile 创建时：

```gdscript
projectile.set("damage", projectile_damage)
```

因此：

```text
Weapon 保存长期伤害状态
→ 每颗新 Projectile 得到当前伤害快照
```

## 完整运行时数据流

```text
Enemy 死亡
→ ExperienceGem

Player 碰到 Gem
→ Player.add_experience(1)

经验达到阈值
→ level += 1
→ level_up.emit(level)

Main 收到 level_up
→ pending_level_ups += 1
→ 显示 LevelUpPanel
→ SceneTree paused

玩家点击按钮
→ Button.pressed
→ LevelUpPanel callback
→ upgrade_selected.emit(upgrade_id)

Main 收到 upgrade_selected
→ 根据 id 调 Player / Weapon 升级方法
→ pending_level_ups -= 1

还有待处理升级
→ 保持暂停、继续选

没有待处理升级
→ 隐藏 Panel
→ SceneTree paused = false
→ 战斗继续
```

## 本课真实运行检查

本课实际使用 F5 验证过完整闭环：

- Enemy 正常死亡并掉落经验；
- Player 拾取经验正常；
- 达到升级阈值后战斗冻结；
- `LEVEL UP!` 三选一正常出现；
- 暂停状态下按钮仍然可以点击；
- 选择后对应强化生效；
- Panel 隐藏；
- 战斗恢复；
- 后续升级仍然可以继续选择并叠加。

自动测试同时覆盖：

- XP 阈值与溢出结转；
- 一次获得大量 XP 连升多级；
- 非正数 XP 不产生升级；
- `level_up` 发出次数；
- 攻速下限 0.2；
- Timer 与 attack interval 同步；
- 新 Projectile 继承 Weapon 当前伤害；
- 暂停状态下 LevelUpPanel 仍可处理按钮；
- 多次 pending upgrade 必须逐次消费；
- 非法 upgrade id 不会错误消费升级次数。

## 学习检查

能用自己的话回答即可：

1. `connect()` 和 `emit()` 分别发生在什么时候？为什么通常只需要 connect 一次，却可以 emit 很多次？
2. 一个 Signal 能不能同时连接多个 callback？这样做为什么能降低对象之间的耦合？
3. `level_up.emit(3)` 中的 `3` 最终去了哪里？
4. 为什么当前 Main 用 `player.connect("level_up", ...)`，而 Timer 可以写 `timer.timeout.connect(...)`？
5. `_new_level` 为什么现在没有使用？前面的下划线表达什么？
6. 为什么连续跨两级时 `pending_level_ups` 会变成 2？
7. 为什么 `get_tree().paused = true` 不会把当前正在执行的 `while` 从中间强制停止？
8. 为什么升级 UI 在 SceneTree 暂停后仍然可以点击？
9. 为什么 Projectile Damage 的长期状态属于 Weapon，而不是某一颗 Projectile？
10. 为什么修改 `attack_interval` 后还要同步修改 `timer.wait_time`？
11. `_on_move_speed_pressed` 这个名字是 Godot 自动根据变量名绑定的吗？真正建立关系的是哪一行？
12. `"move_speed"` 是 Player 属性名，还是我们自己约定的升级 ID？它最终在哪里被解释？

## Checkpoint

完成本课后，对应 Git Tag：

```text
lesson-10-level-up-choice
```

至此，First Playable 已经拥有一条真正可以玩的核心循环：

```text
移动
→ 敌人追踪
→ 自动攻击
→ 敌人死亡
→ 经验掉落
→ 拾取经验
→ 升级三选一
→ 获得真实强化
→ 回到战斗
```

下一阶段可以开始让这个循环更像一个完整游戏，例如 HUD、玩家死亡与重新开始，而不是继续把升级系统一次性做复杂。
