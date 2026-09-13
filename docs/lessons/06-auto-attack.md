# Lesson 06：让 Player 自动攻击

## 本课目标

把 Lesson 05 的“Enemy 会不断刷出来”升级成：Player 会自动寻找最近的 Enemy，并周期性发射 Projectile。

完成后你会看到黄色 Projectile 从 Player 附近飞向 Enemy。

## 本课只学三个东西

1. `Weapon`：负责攻击节奏和选择目标；
2. `Projectile`：独立 Scene，负责出生后的飞行；
3. 方向驱动移动：`direction * speed * delta`。

这课暂时不做伤害和死亡。

## Player 现在的结构

```text
Player
├── Sprite2D
├── CollisionShape2D
└── Weapon
    └── Timer
```

Weapon 是 Player 的子节点，所以 Player 移动时 Weapon 会一起移动。
## Weapon 做了什么

Weapon 默认：

```text
Attack Interval = 0.8 秒
```

每次 Timer 到点后，Weapon 会：

1. 扫描 Main 的直接子节点；
2. 找到距离 Player 最近的 Enemy；
3. 从 `Projectile.tscn` 创建一个新实例；
4. 把 Projectile 放到 Main；
5. 计算 Player 指向目标 Enemy 的方向。

核心方向计算仍然是熟悉的：

```gdscript
global_position.direction_to(target.global_position)
```

Lesson 04 是 Enemy 用它追 Player；现在换成 Projectile 用它朝 Enemy 飞。

## Projectile 自己负责飞

Projectile 的核心代码很短：

```gdscript
position += direction * speed * delta
```
默认：

```text
Projectile Speed = 520
```

可以把它理解成大约每秒移动 520 个 2D 单位；在我们当前没有相机缩放的场景里，可以近似理解成像素/秒。

## 运行检查

按 `F5` 运行项目。

你应该看到：

- 一开始仍然只有 Player 和训练墙；
- EnemySpawner 开始生成 Enemy；
- Player 不需要按攻击键；
- 当场上有 Enemy 后，Player 会周期性发射黄色 Projectile；
- Projectile 会朝当次选择的 Enemy 方向直线飞行；
- Projectile 现在会直接穿过 Enemy，因为本课还没有做命中检测。

如果屏幕上还没有 Enemy，Weapon 本次攻击会直接跳过，不会朝空气乱发射。

## 为什么攻击频率和子弹速度要分开

```text
Weapon Attack Interval -> 多久发一发
Projectile Speed       -> 每一发飞多快
```

这两个参数控制的是完全不同的东西。
## 你的亲手实验

这一步不要交给自动化。

1. 先运行，等待 Enemy 出现，观察自动发射；
2. 停止运行，打开 `scenes/weapons/Projectile.tscn`；
3. 选中根节点 `Projectile`；
4. Inspector 找到 `Speed = 520`；
5. 先改成 `200`，运行并观察明显的慢速飞行；
6. **先预测**：再改成 `1000` 后，攻击频率会不会变？Projectile 会怎样变化？
7. 改成 `1000`，再运行一会，对比快慢差异；
8. 观察 Projectile 飞行速度改变，但 Weapon 仍按原来的节奏发射；
9. 最后恢复成 `520`，保存。

## 学习检查

能用自己的话回答即可：

1. Weapon 和 Projectile 为什么不写成一个节点？
2. `direction_to()` 在 Lesson 04 和 Lesson 06 分别是谁在使用？
3. `speed` 和 `attack_interval` 分别控制什么？
4. 为什么 Projectile 要作为独立 Scene？
5. 为什么现在的 Projectile 会穿过 Enemy？

## 想再多懂一点

见：

[Projectile 与自动攻击：谁负责发射，谁负责飞](../concepts/projectile-and-auto-attack.md)
## Checkpoint

完成实验并把 Projectile Speed 恢复为 `520` 后，对应 Git Tag：

```text
lesson-06-auto-attack
```

下一课：**Lesson 07：伤害与死亡。**
