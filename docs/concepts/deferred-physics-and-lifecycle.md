# 物理回调中的延迟操作：call_deferred、queue_free 与生命周期

> 来自 Lesson 09 的真实问题：Enemy 死亡时掉落 ExperienceGem，运行时曾出现物理查询刷新（physics flushing）相关报错。

## 怎么做：把不安全的场景树修改延迟执行

本项目 Enemy 死亡：

```gdscript
signal died(dead_enemy: Node2D)

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        died.emit(self)
        queue_free()
```

Spawner 负责生成经验球：

```gdscript
func _on_enemy_died(dead_enemy: Node2D) -> void:
    call_deferred("_spawn_experience", dead_enemy.global_position)

func _spawn_experience(spawn_position: Vector2) -> void:
    var experience := experience_scene.instantiate() as Node2D
    get_parent().add_child(experience)
    experience.global_position = spawn_position
```

重点不只是 `call_deferred` 本身，还包括 **先保存一个稳定的 `Vector2` 坐标，而不是把马上要销毁的 Enemy 对象引用传进未来的操作**。

## 为什么需要延迟

这条同步链可能发生在物理检测回调中：

```text
Projectile / Area2D 检测命中
          ↓
Enemy.take_damage()
          ↓
Enemy.died.emit(self)
          ↓（同一调用链立刻调用订阅者）
EnemySpawner._on_enemy_died(enemy)
          ↓
如果立即 add_child(ExperienceGem Area2D)
          ↓
可能在物理系统刷新/查询过程中修改碰撞对象
          ↓
physics flushing 相关错误
```

`call_deferred` 将 `_spawn_experience` 的执行推迟到 Godot 安全处理延迟调用的时机，避免在当前物理查询期间直接加入新的碰撞区域。

**`queue_free()` 与 `free()` 不一样。** 它请求对象在安全时机释放，而不是当前行就立即消失。不过这个 Enemy 已经安排释放了，后续不要继续把它当作永久有效引用。

## 为什么取出 dead_enemy.global_position

正确做法：

```gdscript
call_deferred("_spawn_experience", dead_enemy.global_position)
```

函数调用时就求值 `dead_enemy.global_position`，形成独立的 `Vector2` 值；即使未来 Enemy 已删除，坐标仍存在。

风险设计：

```gdscript
call_deferred("_spawn_experience_from_enemy", dead_enemy)
```

如果延迟方法里才读取 `dead_enemy.global_position`，届时对象可能已失效。这是**对象引用的生命周期**与**值数据的生命周期**不同所导致的风险。

## 如果写错会怎样

- 在 physics flushing 阶段立刻向树中添加新 `Area2D`，可能触发 Godot 引擎错误/警告，掉落物也可能不能正确进入物理空间。
- 使用 `free()` 代替 `queue_free()`，可能在仍有事件、物理回调或迭代依赖该对象时产生危险的时序问题。
- 把将要销毁的 Enemy 引用传给延迟调用，稍后访问时可能是已经释放的实例。
- 无脑给所有操作加 `call_deferred`，则可能引入额外时序复杂性，使你难以判断什么时候对象已经创建。

发生问题时先定位：**是不是正在物理回调/Signal 同步调用栈里修改场景树中的碰撞相关对象？**

## 还能怎么设计？为什么目前不用

| 方案 | 适用情况 | 本课选择 |
| --- | --- | --- |
| `call_deferred` | 简单的「等物理步骤结束再加节点」 | 当前只涉及经验球掉落，最直接 |
| 统一事件队列 | 数十种掉落/复杂事件需要统一消费、调度 | 现在没有足够复杂度 |
| 游戏独立状态机管理生成 | 生成涉及长流程、多个阶段/系统 | 太早引入 |
| 不在死亡回调里生成物理对象 | 重新安排事件触发时机 | 可行，但当前方案已经简单稳定 |

## 四层思考

1. **怎么做：** 先取稳定位置值，再 `call_deferred` 做场景树添加。
2. **为什么：** 物理刷新期间不适合随意修改碰撞空间。
3. **错了会怎样：** 产生 physics flushing 错误、无效对象引用或掉落失败。
4. **还能怎么设计：** 事件队列/统一调度更适合规模扩张后再引入。

延伸阅读：[Signal 事件流](signal-and-event-flow.md) · [Lesson 09](../lessons/09-xp-pickup.md)。
