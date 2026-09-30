extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _make_upgrade(id: StringName, amount: float) -> Resource:
    var script: Script = load("res://scripts/upgrades/upgrade_data.gd")
    var upgrade: Resource = script.new()
    upgrade.set("id", id)
    upgrade.set("label", "test")
    upgrade.set("amount", amount)
    return upgrade

func _stop_timer(parent: Node, timer_path: String) -> void:
    var timer := parent.get_node_or_null(timer_path) as Timer
    if timer != null:
        timer.stop()

func _run() -> void:
    var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
    _expect(main_scene != null, "Main scene must load")
    if main_scene == null:
        quit(1)
        return

    var main := main_scene.instantiate() as Node2D
    root.add_child(main)
    current_scene = main

    _stop_timer(main, "EnemySpawner/Timer")
    _stop_timer(main, "Player/Weapon/Timer")

    var player := main.get_node_or_null("Player")
    var weapon := main.get_node_or_null("Player/Weapon")
    var panel := main.get_node_or_null("LevelUpPanel")
    _expect(player != null, "Main must contain Player")
    _expect(weapon != null, "Main must contain Weapon")
    _expect(panel != null, "Main must contain LevelUpPanel")

    if player != null and weapon != null and panel != null:
        player.call("add_experience", 13)
        _expect(int(main.get("pending_level_ups")) == 2, "13 XP queues two upgrades")
        _expect(paused, "Main pauses while choices are pending")
        _expect(panel.visible, "Panel must display while paused")

        var starting_speed := float(player.get("speed"))
        panel.emit_signal("upgrade_selected", _make_upgrade(&"move_speed", 73.0))
        _expect(abs(float(player.get("speed")) - starting_speed - 73.0) < 0.001,
            "Resource amount 73 must change move speed by exactly 73")
        _expect(int(main.get("pending_level_ups")) == 1, "One valid choice consumes one pending")
        _expect(paused and panel.visible, "First choice must keep game paused")

        var starting_damage := int(weapon.get("projectile_damage"))
        panel.emit_signal("upgrade_selected", _make_upgrade(&"projectile_damage", 4.0))
        _expect(int(weapon.get("projectile_damage")) == starting_damage + 4,
            "Resource amount 4 must change projectile damage by exactly 4")
        _expect(int(main.get("pending_level_ups")) == 0, "Second choice drains pending queue")
        _expect(not paused and not panel.visible, "Last choice resumes and hides panel")

        player.call("add_experience", 11)
        _expect(int(main.get("pending_level_ups")) == 1, "Another level queues one choice")
        _expect(paused, "Next choice pauses again")

        panel.emit_signal("upgrade_selected", _make_upgrade(&"invalid_upgrade", 999.0))
        _expect(int(main.get("pending_level_ups")) == 1,
            "Unknown upgrade id must not consume pending choice")
        _expect(paused and panel.visible, "Unknown upgrade must not resume gameplay")

        var starting_interval := float(weapon.get("attack_interval"))
        panel.emit_signal("upgrade_selected", _make_upgrade(&"attack_speed", 0.23))
        _expect(abs(float(weapon.get("attack_interval")) - (starting_interval - 0.23)) < 0.001,
            "Resource amount 0.23 must reduce attack interval by exactly 0.23")
        _expect(int(main.get("pending_level_ups")) == 0, "Valid attack choice drains queue")
        _expect(not paused and not panel.visible, "Valid choice resumes gameplay")

    paused = false
    main.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 11 upgrade flow")
        quit(0)
    else:
        print("FAIL: Lesson 11 upgrade flow (%d failures)" % failures)
        quit(1)
