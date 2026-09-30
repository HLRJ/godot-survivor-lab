extends SceneTree

var failures: int = 0
var emitted_upgrades: Array = []
var upgrade_script: Script

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _make_upgrade(id: StringName, label: String, amount: float) -> Resource:
    var upgrade: Resource = upgrade_script.new()
    upgrade.set("id", id)
    upgrade.set("label", label)
    upgrade.set("amount", amount)
    return upgrade

func _on_upgrade_selected(upgrade) -> void:
    emitted_upgrades.append(upgrade)
func _run() -> void:
    upgrade_script = load("res://scripts/upgrades/upgrade_data.gd")
    var panel_scene := load("res://scenes/ui/LevelUpPanel.tscn") as PackedScene

    _expect(upgrade_script != null, "UpgradeData script must load")
    _expect(panel_scene != null, "LevelUpPanel.tscn must load")
    if upgrade_script == null or panel_scene == null:
        quit(1)
        return

    var preview := panel_scene.instantiate()
    _expect(preview.get("move_speed_upgrade") != null, "Scene must bind move_speed UpgradeData")
    _expect(preview.get("attack_speed_upgrade") != null, "Scene must bind attack_speed UpgradeData")
    _expect(preview.get("projectile_damage_upgrade") != null, "Scene must bind projectile_damage UpgradeData")
    preview.free()

    var move_upgrade := _make_upgrade(&"move_speed", "测试移动 +73", 73.0)
    var attack_upgrade := _make_upgrade(&"attack_speed", "测试攻速 -0.23", 0.23)
    var damage_upgrade := _make_upgrade(&"projectile_damage", "测试伤害 +4", 4.0)

    var panel := panel_scene.instantiate() as CanvasLayer
    panel.set("move_speed_upgrade", move_upgrade)
    panel.set("attack_speed_upgrade", attack_upgrade)
    panel.set("projectile_damage_upgrade", damage_upgrade)
    root.add_child(panel)

    var move_button := panel.get_node_or_null("Overlay/PanelContainer/VBoxContainer/MoveSpeedButton") as Button
    var attack_button := panel.get_node_or_null("Overlay/PanelContainer/VBoxContainer/AttackSpeedButton") as Button
    var damage_button := panel.get_node_or_null("Overlay/PanelContainer/VBoxContainer/DamageButton") as Button

    _expect(move_button != null, "MoveSpeedButton must exist")
    _expect(attack_button != null, "AttackSpeedButton must exist")
    _expect(damage_button != null, "DamageButton must exist")

    if move_button != null:
        _expect(move_button.text == "测试移动 +73", "Move button text must come from Resource.label")
    if attack_button != null:
        _expect(attack_button.text == "测试攻速 -0.23", "Attack button text must come from Resource.label")
    if damage_button != null:
        _expect(damage_button.text == "测试伤害 +4", "Damage button text must come from Resource.label")
    var can_test_signal := (
        panel.has_signal("upgrade_selected")
        and move_button != null
        and attack_button != null
        and damage_button != null
    )

    if can_test_signal:
        panel.connect("upgrade_selected", _on_upgrade_selected)
        paused = true

        move_button.pressed.emit()
        attack_button.pressed.emit()
        damage_button.pressed.emit()

        _expect(emitted_upgrades.size() == 3, "Three buttons must emit three upgrades")
        if emitted_upgrades.size() == 3:
            _expect(is_same(emitted_upgrades[0], move_upgrade), "Move button must emit the move UpgradeData object")
            _expect(is_same(emitted_upgrades[1], attack_upgrade), "Attack button must emit the attack UpgradeData object")
            _expect(is_same(emitted_upgrades[2], damage_upgrade), "Damage button must emit the damage UpgradeData object")

    paused = false
    panel.queue_free()
    await process_frame
    if failures == 0:
        print("PASS: Lesson 11 level up panel resources")
        quit(0)
    else:
        print("FAIL: Lesson 11 level up panel resources (%d failures)" % failures)
        quit(1)
