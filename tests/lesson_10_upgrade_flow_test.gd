extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _has_property(object: Object, property_name: StringName) -> bool:
    for property in object.get_property_list():
        if property.name == property_name:
            return true
    return false

func _stop_timer(parent: Node, timer_path: String) -> void:
    var timer := parent.get_node_or_null(timer_path) as Timer
    if timer != null:
        timer.stop()

func _run() -> void:
    var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
    _expect(main_scene != null, "Main.tscn could not be loaded")
    if main_scene == null:
        quit(1)
        return

    var main := main_scene.instantiate() as Node2D
    root.add_child(main)
    current_scene = main

    _stop_timer(main, "EnemySpawner/Timer")
    _stop_timer(main, "Player/Weapon/Timer")

    var has_main_script := main.get_script() != null
    var has_pending := _has_property(main, &"pending_level_ups")
    var panel := main.get_node_or_null("LevelUpPanel")
    var player := main.get_node_or_null("Player")
    var weapon := main.get_node_or_null("Player/Weapon")

    _expect(has_main_script, "Main must have coordinator script")
    _expect(has_pending, "Main must track pending level-ups")
    _expect(panel != null, "Main must instance LevelUpPanel")
    _expect(player != null, "Main must contain Player")
    _expect(weapon != null, "Player must contain Weapon")

    var can_test_flow := (
        has_main_script
        and has_pending
        and panel != null
        and player != null
        and weapon != null
        and panel.has_signal("upgrade_selected")
    )

    if can_test_flow:
        player.call("add_experience", 13)

        _expect(int(main.get("pending_level_ups")) == 2, "13 XP must queue two upgrade choices")
        _expect(paused, "First pending upgrade must pause gameplay")
        _expect(panel.visible, "Level-up panel must be visible while paused")

        var starting_speed := float(player.get("speed"))
        panel.emit_signal("upgrade_selected", "move_speed")

        _expect(float(player.get("speed")) == starting_speed + 40.0, "Move choice must upgrade Player speed")
        _expect(int(main.get("pending_level_ups")) == 1, "First choice must consume exactly one pending upgrade")
        _expect(paused, "Gameplay must remain paused while one upgrade is still pending")
        _expect(panel.visible, "Panel must remain visible for the second pending choice")

        var starting_damage := int(weapon.get("projectile_damage"))
        panel.emit_signal("upgrade_selected", "projectile_damage")

        _expect(int(weapon.get("projectile_damage")) == starting_damage + 1, "Damage choice must upgrade Weapon")
        _expect(int(main.get("pending_level_ups")) == 0, "Second choice must drain pending queue")
        _expect(not paused, "Gameplay must resume after final choice")
        _expect(not panel.visible, "Panel must hide after final choice")

        player.call("add_experience", 11)
        _expect(int(main.get("pending_level_ups")) == 1, "One more level must queue one upgrade")
        panel.emit_signal("upgrade_selected", "invalid_upgrade")
        _expect(int(main.get("pending_level_ups")) == 1, "Invalid upgrade must not consume a pending choice")
        _expect(paused, "Invalid upgrade must not resume gameplay")

        panel.emit_signal("upgrade_selected", "attack_speed")
        _expect(int(main.get("pending_level_ups")) == 0, "Valid choice must clear remaining pending upgrade")
        _expect(not paused, "Gameplay must resume after valid fallback choice")

    paused = false
    main.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 10 upgrade flow")
        quit(0)
    else:
        print("FAIL: Lesson 10 upgrade flow (%d failures)" % failures)
        quit(1)
