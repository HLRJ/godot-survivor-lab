extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _method_arg_count(object: Object, method_name: StringName) -> int:
    for method in object.get_method_list():
        if method.name == method_name:
            return method.args.size()
    return -1
func _run() -> void:
    var player_scene := load("res://scenes/player/Player.tscn") as PackedScene
    _expect(player_scene != null, "Player.tscn could not be loaded")
    if player_scene == null:
        quit(1)
        return

    var world := Node2D.new()
    world.name = "TestWorld"
    root.add_child(world)
    current_scene = world

    var player := player_scene.instantiate() as CharacterBody2D
    world.add_child(player)
    var weapon := player.get_node_or_null("Weapon")
    var timer := player.get_node_or_null("Weapon/Timer") as Timer

    _expect(weapon != null, "Player must contain Weapon")
    _expect(timer != null, "Weapon must contain Timer")
    if weapon == null or timer == null:
        world.queue_free()
        await process_frame
        quit(1)
        return

    timer.stop()
    var move_arg_count := _method_arg_count(player, &"upgrade_move_speed")
    var attack_arg_count := _method_arg_count(weapon, &"upgrade_attack_speed")
    var damage_arg_count := _method_arg_count(weapon, &"upgrade_projectile_damage")

    _expect(move_arg_count == 1, "upgrade_move_speed must accept one amount parameter")
    _expect(attack_arg_count == 1, "upgrade_attack_speed must accept one amount parameter")
    _expect(damage_arg_count == 1, "upgrade_projectile_damage must accept one amount parameter")

    if move_arg_count == 1:
        var starting_speed := float(player.get("speed"))
        player.call("upgrade_move_speed", 73.0)
        _expect(
            abs(float(player.get("speed")) - (starting_speed + 73.0)) < 0.001,
            "Move speed upgrade must use the provided 73 amount"
        )

    if attack_arg_count == 1:
        var starting_interval := float(weapon.get("attack_interval"))
        weapon.call("upgrade_attack_speed", 0.23)
        _expect(
            abs(float(weapon.get("attack_interval")) - (starting_interval - 0.23)) < 0.001,
            "Attack speed upgrade must use the provided 0.23 amount"
        )
        _expect(
            abs(timer.wait_time - float(weapon.get("attack_interval"))) < 0.001,
            "Timer.wait_time must follow parameterized attack interval"
        )

    if damage_arg_count == 1:
        var starting_damage := int(weapon.get("projectile_damage"))
        weapon.call("upgrade_projectile_damage", 4)
        _expect(
            int(weapon.get("projectile_damage")) == starting_damage + 4,
            "Projectile damage upgrade must use the provided 4 amount"
        )

    var move_data := load("res://resources/upgrades/move_speed.tres")
    _expect(move_data != null, "move_speed.tres must load")
    if move_data != null and move_arg_count == 1:
        var configured_amount := float(move_data.get("amount"))
        player.call("upgrade_move_speed", configured_amount)
        player.call("upgrade_move_speed", configured_amount)
        _expect(
            abs(float(move_data.get("amount")) - configured_amount) < 0.001,
            "Applying upgrades must not mutate UpgradeData.amount"
        )

    if attack_arg_count == 1:
        for _i in range(20):
            weapon.call("upgrade_attack_speed", 0.23)

        _expect(
            abs(float(weapon.get("attack_interval")) - 0.2) < 0.001,
            "Parameterized attack speed must keep the 0.2 floor"
        )
        _expect(
            abs(timer.wait_time - 0.2) < 0.001,
            "Timer floor must remain 0.2"
        )

    world.queue_free()
    await process_frame
    if failures == 0:
        print("PASS: Lesson 11 parameterized upgrades")
        quit(0)
    else:
        print("FAIL: Lesson 11 parameterized upgrades (%d failures)" % failures)
        quit(1)
