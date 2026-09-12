# CharacterBody2D 和移动：先建立一个够用的模型

Lesson 02 第一次让角色真的动起来。你现在不需要系统学习 Godot 物理，只要先理解下面三件事。

## 1. 为什么从 Node2D 换成 CharacterBody2D

Lesson 01 的 `Node2D` 很适合表示“一个 2D 对象”，但它本身不提供角色移动和碰撞所需的专用能力。

`CharacterBody2D` 可以先理解成：

> 专门给“由我们控制移动的 2D 角色”准备的 Node。

它自带一个很重要的属性：

```gdscript
velocity
```

以及一个很重要的方法：

```gdscript
move_and_slide()
```

本课只用这两个能力。碰撞体会留到下一课再加。

## 2. velocity 是什么

`velocity` 表示速度向量，同时包含方向和速度大小。

例如：

```text
Vector2(220, 0)   -> 向右
Vector2(-220, 0)  -> 向左
Vector2(0, -220)  -> 向上
```
在当前 2D 项目里，`speed = 220.0` 可以近似理解成 **220 像素/秒**，不是“每帧走 220 像素”。

## 3. Input.get_vector() 为什么好用

我们没有直接问“W 有没有按下”，而是写：

```gdscript
var direction := Input.get_vector(
    "move_left",
    "move_right",
    "move_up",
    "move_down"
)
```

它把四个 Input Action 合成一个方向向量。

只按 D 时大致得到：

```text
(1, 0)
```

同时按 W + D 时大致得到：

```text
(0.707, -0.707)
```

为什么不是 `(1, -1)`？因为 Godot 会把对角线方向归一化到长度 1。这样斜着跑不会比横着跑更快。

## 4. 为什么这里没有乘 delta

你以后经常会看到这种写法：

```gdscript
position += direction * speed * delta
```

但这节课使用的是：

```gdscript
velocity = direction * speed
move_and_slide()
```

这里不要再自己乘 `delta`。`CharacterBody2D.move_and_slide()` 会按照 physics frame 正确处理 `velocity`。
## 现在先记住这条链

```text
按键
  ↓
Input Action
  ↓
Input.get_vector()
  ↓
direction
  ↓
velocity = direction * speed
  ↓
move_and_slide()
  ↓
角色移动
```

如果这条链你能说出来，Lesson 02 就够了。

下一课我们会遇到一个新问题：角色虽然会动，但目前没有真正的碰撞形状。到那时再引入 `CollisionShape2D`、Layer 和 Mask。
