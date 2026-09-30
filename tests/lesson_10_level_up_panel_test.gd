extends SceneTree

var failures: int = 0
var emitted_upgrades: Array[UpgradeData] = []

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _on_upgrade_selected(upgrade: UpgradeData) -> void:
    emitted_upgrades.append(upgrade)

func _run() -> void:
    var panel_scene := load("res://scenes/ui/LevelUpPanel.tscn") as PackedScene
    _expect(panel_scene != null, "LevelUpPanel.tscn could not be loaded")
    if panel_scene == null:
        quit(1)
        return

    var panel := panel_scene.instantiate() as CanvasLayer
    root.add_child(panel)

    _expect(panel != null, "LevelUpPanel root must be CanvasLayer")
    if panel == null:
        quit(1)
        return

    _expect(panel.process_mode == Node.PROCESS_MODE_WHEN_PAUSED, "LevelUpPanel must process while paused")
    _expect(panel.has_signal("upgrade_selected"), "LevelUpPanel must define upgrade_selected")
    _expect(panel.has_method("show_choices"), "LevelUpPanel must expose show_choices()")
    _expect(panel.has_method("hide_choices"), "LevelUpPanel must expose hide_choices()")
    _expect(not panel.visible, "LevelUpPanel must start hidden")

    var move_button := panel.get_node_or_null("Overlay/PanelContainer/VBoxContainer/MoveSpeedButton") as Button
    var attack_button := panel.get_node_or_null("Overlay/PanelContainer/VBoxContainer/AttackSpeedButton") as Button
    var damage_button := panel.get_node_or_null("Overlay/PanelContainer/VBoxContainer/DamageButton") as Button

    _expect(move_button != null, "MoveSpeedButton must exist")
    _expect(attack_button != null, "AttackSpeedButton must exist")
    _expect(damage_button != null, "DamageButton must exist")

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

        _expect(emitted_upgrades.size() == 3, "Paused buttons must emit three upgrades")
        if emitted_upgrades.size() == 3:
            _expect(emitted_upgrades[0].id == &"move_speed", "First choice must be move speed")
            _expect(emitted_upgrades[1].id == &"attack_speed", "Second choice must be attack speed")
            _expect(emitted_upgrades[2].id == &"projectile_damage", "Third choice must be projectile damage")

    paused = false
    panel.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 10 level up panel")
        quit(0)
    else:
        print("FAIL: Lesson 10 level up panel (%d failures)" % failures)
        quit(1)
