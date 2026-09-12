# 碰撞、Layer 和 Mask：先建立一个够用的模型

Lesson 03 第一次让“看得见的图片”拥有真正的物理身体。

## 1. Sprite2D 不等于碰撞体

`Sprite2D` 只负责把图片画出来。

Godot 不会因为屏幕上有一张人物图片，就自动知道哪里能撞、哪里不能撞。

所以 Player 现在变成：

```text
Player (CharacterBody2D)
├── Sprite2D
└── CollisionShape2D
```

`Sprite2D` 是外观，`CollisionShape2D` 才是物理世界真正使用的形状。

## 2. StaticBody2D 是什么

训练墙使用：

```text
TrainingWall (StaticBody2D)
├── Visual
└── CollisionShape2D
```

`StaticBody2D` 可以先理解为“不会主动移动的物理实体”，很适合墙、地面、岩石等障碍物。

## 3. Layer 和 Mask 怎么记

先不要背位运算，只记两句话：

> **Layer：我是谁。**
>
> **Mask：我关心谁。**

当前 Player 和 TrainingWall 都使用第 1 层：

```text
collision_layer = 1
collision_mask = 1
```

意思可以先粗略理解成：

```text
Player：我是第 1 类物体，也检查第 1 类物体
Wall：   我是第 1 类物体，也检查第 1 类物体
```

所以二者会发生碰撞。

如果把 Player 的 Mask 关掉：

```text
collision_mask = 0
```

Player 仍然“属于某一层”，但它不再检查任何碰撞层，于是就能直接穿过训练墙。

以后敌人、子弹、经验球出现后，我们才会真的需要多层，例如：

```text
1 Player
2 Enemy
3 Projectile
4 Pickup
```

现在先全部放在第 1 层，避免为了“完整”提前增加复杂度。

## 4. 为什么 move_and_slide() 现在才显出价值

Lesson 02 时 Player 没有碰撞形状，所以 `move_and_slide()` 看起来只是让角色移动。

Lesson 03 加上 CollisionShape2D 后，同一行代码开始自动处理“撞到墙以后不要继续穿过去”。

这就是我们延迟学习概念的原因：先遇到真实问题，再理解这个 API 为什么存在。
