# 升级按钮出现 Nil.label：Resource 没有绑定

## 我看到的症状

按 F5，Godot Debugger 显示：

```text
Invalid access to property or key 'label'
on a base object of type 'Nil'.
level_up_panel.gd:14 @ _ready()
```

这里不是因为 `UpgradeData` 没有 `label` 字段，而是 `move_speed_upgrade` 为 `null`。

## 按这个顺序检查

1. 按 F8 停止游戏，避免误把 Remote Inspector 当成编辑位置。
2. 打开 `scenes/ui/LevelUpPanel.tscn`。
3. 选中根节点 `LevelUpPanel`，在右侧 Inspector 找到三个导出的 UpgradeData 槽位。
4. 检查 `Move Speed Upgrade` 是否引用 `res://resources/upgrades/move_speed.tres`；其他两个字段也分别指向自己的 `.tres`。
5. 若为空，将对应文件拖回槽位，按 Ctrl+S 保存，再 F5。
6. 如果仍出错，检查 Asset 是否能加载，以及脚本 `@export var move_speed_upgrade: UpgradeData` 是否正确。

## 为什么会这样

`@export` 只是允许编辑器配置依赖，不会自动创建 Resource：

```gdscript
@export var move_speed_upgrade: UpgradeData

func _ready() -> void:
    move_speed_button.text = move_speed_upgrade.label
```

当 `move_speed_upgrade == null`，访问 `.label` 就会抛出 Nil 错误。

## 如何避免再次发生

固定必选资源应加入**真实场景配置测试**：先实例化 `LevelUpPanel.tscn`，在赋值任何测试对象之前检查三个导出槽都不为空。`tests/lesson_11_level_up_panel_resource_test.gd` 已覆盖该边界。

也可以在 `_ready()` 里做显式 null 检查并报告配置错误。不要悄悄填回写死的 `+40` 作为 fallback，免得问题被隐藏。

**真实来源：** Lesson 11 曾故意清空该槽位复现截图所示错误，再重新绑定恢复。延伸阅读：[Resource 与数据驱动](../concepts/resource-and-data-driven-design.md)。
