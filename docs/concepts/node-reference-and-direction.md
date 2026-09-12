# Node 引用与方向：Enemy 为什么知道 Player 在哪

Lesson 04 第一次让一个游戏对象主动追踪另一个对象。

这次只建立一个够用的模型：Enemy 需要先找到 Player，然后每个 physics frame 重新计算方向。

## 1. `get_node("../Player")` 在找什么

Enemy 和 Player 现在都是 Main 的直接子节点：

```text
Main
├── Player
├── Enemy
└── TrainingWall
```

Enemy 脚本里写：

```gdscript
@onready var player: Node2D = get_node("../Player")
```

这里的 `..` 表示“父节点”。

所以这条路径可以读成：

```text
Enemy -> 回到 Main -> 找到 Player
```
## 2. 为什么用 `@onready`

Scene 实例化时，节点树需要先准备好。

`@onready` 表示等这个 Enemy 已经进入节点树、兄弟节点也能找到以后，再执行这次引用查找。

这不是“全局搜索 Player”，而是沿着明确的 Scene 路径找节点。

因此当前写法简单、容易看懂，但也有一个限制：Enemy 必须和 Player 保持现在这种层级关系。

这是本课刻意接受的约束。等后面出现刷怪器、容器或更复杂结构时，我们再根据真实需求重构。

## 3. `direction_to()` 返回什么

```gdscript
var direction := global_position.direction_to(player.global_position)
```

可以把它读成：

> 从 Enemy 当前世界坐标，算一个指向 Player 世界坐标的方向。

返回的是一个归一化 `Vector2`，长度大约为 1。

例如 Player 在 Enemy 右边，方向可能接近：

```text
(1, 0)
```

Player 在左上方，方向可能类似：

```text
(-0.7, -0.7)
```
## 4. 追踪其实还是 Lesson 02 那套移动

Enemy 后半段代码：

```gdscript
velocity = direction * speed
move_and_slide()
```

和 Player 的移动思路完全一样：

```text
方向 × 速度 = velocity
velocity -> move_and_slide()
```

区别只在“方向从哪里来”：

- Player：方向来自键盘输入；
- Enemy：方向来自 Player 的当前位置。

所以 Enemy 追踪不是一种神秘的新移动系统，而是在复用你已经学过的 `CharacterBody2D` 移动模型。

## 5. 为什么 Enemy 会实时转向

`_physics_process()` 每个 physics frame 都重新执行：

```gdscript
var direction := global_position.direction_to(player.global_position)
```

因此你移动 Player 后，下一帧 Enemy 就会基于 Player 的新位置重新算方向。

这就是“持续追踪”的最小原理。

本课先不引入导航、寻路、状态机。Enemy 遇到复杂障碍物时还不聪明，这是后续问题，不是当前问题。
