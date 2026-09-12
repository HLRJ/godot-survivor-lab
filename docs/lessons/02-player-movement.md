# Lesson 02：让 Player 用 WASD 动起来

## 本课目标

让 Lesson 01 的静态像素角色支持 **WASD / 方向键八方向移动**。

你不会在这一课顺便学碰撞、动画或相机。先把“输入 → 方向 → 速度 → 移动”这条链真正跑通。

## 完成效果

按 `F5` 运行项目后：

- `W / ↑`：向上；
- `S / ↓`：向下；
- `A / ←`：向左；
- `D / →`：向右；
- 同时按两个方向键可以斜向移动。

顶部状态文字会显示：

```text
Lesson 02 - WASD 玩家移动
```

## 本课只学三个东西

1. `CharacterBody2D`：适合由我们控制移动的 2D 角色。
2. Input Map + `Input.get_vector()`：把具体按键转换成游戏里的“移动意图”。
3. `_physics_process()` + `velocity` + `move_and_slide()`：每个物理帧真正移动角色。
## 先看 Player 发生了什么变化

打开：

```text
scenes/player/Player.tscn
```

Lesson 01 时根节点是：

```text
Player (Node2D)
```

现在变成：

```text
Player (CharacterBody2D)
└── Sprite2D
```

为什么换？因为我们现在真的遇到了“角色要移动”的需求。

`CharacterBody2D` 提供了角色移动常用的 `velocity` 和 `move_and_slide()`。碰撞形状暂时不加，下一课再解决。

### 为什么 Speed 放在 Player，而不是 Sprite2D

因为 `speed` 描述的是**整个玩家怎么移动**，不是图片怎么显示。

```text
Player (CharacterBody2D) = 玩家实体、位置、移动、以后还会负责碰撞
└── Sprite2D             = 只负责把角色外观画出来
```

`player.gd` 挂在 Player 根节点上，所以 `@export var speed` 会出现在 Player 的 Inspector 中。移动时真正改变的是 Player 根节点的位置，Sprite2D 作为子节点会跟着一起移动。

如果只移动 Sprite2D，以后加入 `CollisionShape2D`、武器挂点或受伤区域时，就可能出现“图片已经跑走，但碰撞体还在原地”的错位。

先记一句就够：**Player 管行为和物理，Sprite2D 管外观。**

## 看一下 Input Map

在 Godot 顶部菜单进入：

```text
Project → Project Settings → Input Map
```

你应该能找到四个动作：

```text
move_left
move_right
move_up
move_down
```

它们分别绑定了 WASD 和方向键。

这里有一个很重要的思想：**游戏脚本关心的是“向左移动”，而不是死盯着 A 键。**
## 现在看移动脚本

打开：

```text
scripts/player/player.gd
```

完整代码只有几行：

```gdscript
extends CharacterBody2D

@export var speed: float = 220.0

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()
```

先别急着背语法，按执行顺序看。

### 第一步：读取方向

```gdscript
var direction := Input.get_vector(...)
```

它把四个移动动作合成一个二维方向。

只按 D 时，方向大致是：

```text
(1, 0)
```

同时按 W + D 时，方向大致是：

```text
(0.707, -0.707)
```

对角线被归一化，所以斜着走不会比横着走更快。
### 第二步：把方向变成速度

```gdscript
velocity = direction * speed
```

`speed = 220.0` 在当前 2D 项目里可以近似理解成 **220 像素/秒**。

它不是“每一帧移动 220 像素”。如果是那样，游戏会快到飞出去。

### 第三步：真正移动

```gdscript
move_and_slide()
```

这一步让 `CharacterBody2D` 按当前 `velocity` 移动。

这里有一个容易写错的点：

```gdscript
velocity = direction * speed
```

后面不要再乘一次 `delta`。`move_and_slide()` 会按物理帧正确处理这个速度。

## 为什么函数叫 _physics_process

```gdscript
func _physics_process(_delta: float) -> void:
```

Godot 会按照固定物理节奏反复调用它，所以移动、碰撞之类的物理逻辑通常放这里。

本课没有直接用 `_delta`，所以变量名前加了下划线，表示“这个参数存在，但当前暂时不用”。
## 运行检查

按 `F5` 运行项目。

你应该能看到角色从屏幕中央开始，并且：

- WASD 有响应；
- 方向键也有响应；
- 松开按键后角色停止；
- W+D、W+A、S+D、S+A 都可以斜向移动；
- 没有 Parse Error 或 missing Input Action。

这一课暂时没有边界限制，所以你可以把角色走出画面。这不是 Bug，后续再处理世界和相机。

## 如果没有移动

优先按这个顺序查：

1. `Player` 根节点是不是 `CharacterBody2D`；
2. `Player` 是否挂载了 `scripts/player/player.gd`；
3. Project Settings → Input Map 中是否存在四个 `move_*` 动作；
4. 脚本中的动作名字是否和 Input Map 完全一致；
5. `speed` 是否大于 0。

不要为了排错一次改十处。一次只确认一个环节。

## 你的亲手实验

这一步不要交给自动化。

先预测：

> 如果把 `Speed` 从 `220` 改成 `440`，角色会发生什么？斜向移动也会一起加快吗？
然后：

1. 打开 `scenes/player/Player.tscn`；
2. 选中根节点 `Player`；
3. 在 Inspector 找到脚本导出的 `Speed`；
4. 把 `220` 改成 `440`；
5. 按 `F5` 再跑一次，对比手感；
6. 最后把 `Speed` 恢复成 `220`，`Ctrl+S` 保存。

如果你感觉速度大约翻倍，说明你已经把“方向”和“速度大小”区分开了。

## 学习检查

不用背定义，能用自己的话回答就行：

1. 为什么脚本写 `move_right`，而不是直接写“D 键”？
2. `CharacterBody2D` 相比 Lesson 01 的 `Node2D`，这节课多解决了什么问题？
3. `velocity = direction * speed` 分别在表达什么？
4. 为什么 W+D 不会比只按 D 跑得更快？
5. 为什么这里不写 `velocity = direction * speed * delta`？

## 想再多懂一点

可以看：

[CharacterBody2D 和移动：先建立一个够用的模型](../concepts/characterbody2d-and-movement.md)

不是下一课的强制前置。

## Checkpoint

完成本课并把 `Speed` 恢复成 `220` 后，对应 Git Tag：

```text
lesson-02-player-movement
```

下一课：**Lesson 03：碰撞——让 Player 不再只是一个会移动的图片。**
