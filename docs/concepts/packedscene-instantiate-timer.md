# PackedScene、instantiate 和 Timer：为什么能不断刷怪

Lesson 05 第一次让同一个 Enemy Scene 被反复创建。

这次只建立三个够用的心智模型：`PackedScene`、`instantiate()`、`Timer`。

## 1. PackedScene 可以先理解成“Scene 模板”

`Enemy.tscn` 已经定义好了一个 Enemy 应该长什么样、挂什么脚本、有什么碰撞体。

但一个 `.tscn` 文件本身不是正在游戏里跑的 Enemy。

当它被加载成 `PackedScene` 时，可以先理解为：

> 一个还没有放进 Scene Tree 的 Enemy 模板。

```gdscript
@export var enemy_scene: PackedScene
```

这里保存的不是某一个 Enemy，而是“怎么制造 Enemy”的模板。

## 2. instantiate() 才真正创建一个实例

```gdscript
var enemy := enemy_scene.instantiate()
```

可以读成：

> 按这个 Enemy 模板，做出一个新的 Enemy Node。

同一个 `PackedScene` 可以反复 `instantiate()`：

```text
Enemy 模板
├── instantiate() -> Enemy A
├── instantiate() -> Enemy B
└── instantiate() -> Enemy C
```

这些实例使用同一份 Scene 定义，但它们是独立 Node，各自有自己的位置和运行状态。

## 3. 创建以后还要放进 Scene Tree

仅仅 `instantiate()` 还不够。

新的 Enemy 必须被 `add_child()` 放进正在运行的节点树，Godot 才会处理它的 `_ready()`、`_physics_process()`、碰撞和显示。

本课使用：

```gdscript
get_parent().add_child(enemy)
```

Spawner 的父节点就是 Main，所以新 Enemy 会成为 Main 的直接子节点。

这不是随便选的层级。Lesson 04 的 Enemy 仍然用：

```gdscript
get_node("../Player")
```

因此 Enemy 必须先回到 Main，才能找到同级的 Player。

## 4. Timer 只负责“什么时候再做一次”

Spawner 里有一个 `Timer`：

```text
EnemySpawner
└── Timer
```

脚本把它设置成默认每 `1.5` 秒触发一次：

```gdscript
timer.wait_time = spawn_interval
timer.start()
```

Timer 到点以后调用 `_spawn_enemy()`。

你现在不需要正式学习 Signal，只要先把 timeout 理解成：

> 计时结束了，现在执行一次刷怪动作。

因此职责很清楚：

```text
PackedScene  -> 提供 Enemy 模板
instantiate  -> 创建一个 Enemy
Timer        -> 决定什么时候再创建一个
Spawner      -> 把这些步骤组织起来
```

以后会出现随机出生点、波次、对象池等问题，但都不是本课问题。先把“同一 Scene 可以反复实例化”这件事吃透。
