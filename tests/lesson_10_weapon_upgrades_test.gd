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

func _find_projectile(parent: Node) -> Node:
    for child in parent.get_children():
        if child.scene_file_path == "res://scenes/weapons/Projectile.tscn":
            return child
    return null

func _run() -> void:
    var player_scene := load("res://scenes/player/Player.tscn") as PackedScene
    var enemy_scene := load("res://scenes/enemies/Enemy.tscn") as PackedScene
    _expect(player_scene != null, "Player.tscn could not be loaded")
    _expect(enemy_scene != null, "Enemy.tscn could not be loaded")
    if player_scene == null or enemy_scene == null:
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
    if timer != null:
        timer.stop()

    _expect(weapon != null, "Player must contain Weapon")
    if weapon == null:
        world.queue_free()
        await process_frame
        quit(1)
        return

    var has_damage_state := _has_property(weapon, &"projectile_damage")
    var has_attack_upgrade := weapon.has_method("upgrade_attack_speed")
    var has_damage_upgrade := weapon.has_method("upgrade_projectile_damage")

    _expect(has_damage_state, "Weapon must expose projectile_damage")
    _expect(has_attack_upgrade, "Weapon must implement upgrade_attack_speed()")
    _expect(has_damage_upgrade, "Weapon must implement upgrade_projectile_damage()")
    _expect(abs(float(weapon.get("attack_interval")) - 0.8) < 0.001, "Attack interval must start at 0.8")
    if has_damage_state:
        _expect(int(weapon.get("projectile_damage")) == 1, "Projectile damage must start at 1")

    if has_attack_upgrade and timer != null:
        weapon.call("upgrade_attack_speed")
        _expect(abs(float(weapon.get("attack_interval")) - 0.7) < 0.001, "Attack interval must drop by 0.1")
        _expect(abs(timer.wait_time - 0.7) < 0.001, "Timer.wait_time must follow attack_interval")

        for _i in range(20):
            weapon.call("upgrade_attack_speed")

        _expect(abs(float(weapon.get("attack_interval")) - 0.2) < 0.001, "Attack interval must stop at 0.2")
        _expect(abs(timer.wait_time - 0.2) < 0.001, "Timer floor must also be 0.2")

    if has_damage_state and has_damage_upgrade:
        weapon.call("upgrade_projectile_damage")
        _expect(int(weapon.get("projectile_damage")) == 2, "Damage upgrade must persist on Weapon")

        var enemy := enemy_scene.instantiate() as CharacterBody2D
        enemy.position = Vector2(800, 360)
        world.add_child(enemy)
        enemy.set_physics_process(false)

        weapon.call("_attack")
        var projectile := _find_projectile(world)
        _expect(projectile != null, "Weapon must spawn a projectile")
        if projectile != null:
            projectile.set_physics_process(false)
            _expect(int(projectile.get("damage")) == 2, "New projectile must receive upgraded damage")

    world.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 10 weapon upgrades")
        quit(0)
    else:
        print("FAIL: Lesson 10 weapon upgrades (%d failures)" % failures)
        quit(1)
