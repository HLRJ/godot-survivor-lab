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

func _stop_timer(parent: Node, timer_name: StringName) -> void:
    var timer := parent.get_node_or_null(NodePath(timer_name)) as Timer
    if timer != null:
        timer.stop()

func _run() -> void:
    var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
    var enemy_scene := load("res://scenes/enemies/Enemy.tscn") as PackedScene
    var projectile_scene := load("res://scenes/weapons/Projectile.tscn") as PackedScene
    _expect(main_scene != null, "Main.tscn could not be loaded")
    _expect(enemy_scene != null, "Enemy.tscn could not be loaded")
    _expect(projectile_scene != null, "Projectile.tscn could not be loaded")
    if main_scene == null or enemy_scene == null or projectile_scene == null:
        quit(1)
        return

    var main := main_scene.instantiate()
    root.add_child(main)
    current_scene = main

    var player := main.get_node_or_null("Player") as CharacterBody2D
    var spawner := main.get_node_or_null("EnemySpawner")
    _expect(player != null, "Main must contain Player")
    _expect(spawner != null, "Main must contain EnemySpawner")
    if player == null:
        main.queue_free()
        await process_frame
        quit(1)
        return

    if spawner != null:
        _stop_timer(spawner, "Timer")
    var weapon := player.get_node_or_null("Weapon")
    if weapon != null:
        _stop_timer(weapon, "Timer")

    var enemy := enemy_scene.instantiate() as CharacterBody2D
    _expect(enemy != null, "Enemy scene root must be CharacterBody2D")
    if enemy == null:
        main.queue_free()
        await process_frame
        quit(1)
        return

    enemy.set("speed", 0.0)
    enemy.global_position = player.global_position + Vector2(140.0, 0.0)
    main.add_child(enemy)
    await process_frame

    var has_max_health := _has_property(enemy, &"max_health")
    var has_health := _has_property(enemy, &"health")
    _expect(has_max_health, "Enemy must expose max_health")
    _expect(has_health, "Enemy must expose runtime health")
    _expect(enemy.has_method("take_damage"), "Enemy must implement take_damage(amount)")
    if has_max_health:
        _expect(int(enemy.get("max_health")) == 3, "Enemy default max_health must be 3")
    if has_health:
        _expect(int(enemy.get("health")) == 3, "Enemy runtime health must start at 3")

    var projectile_node := projectile_scene.instantiate()
    _expect(projectile_node is Area2D, "Projectile root must be Area2D")
    _expect(projectile_node.get_node_or_null("CollisionShape2D") != null, "Projectile must contain CollisionShape2D")
    var has_damage := _has_property(projectile_node, &"damage")
    _expect(has_damage, "Projectile must expose damage")
    if has_damage:
        _expect(int(projectile_node.get("damage")) == 1, "Projectile default damage must be 1")
    var can_test_hit := projectile_node is Area2D and has_damage and has_health and enemy.has_method("take_damage")
    if can_test_hit:
        var projectile := projectile_node as Area2D
        projectile.set("direction", Vector2.RIGHT)
        projectile.global_position = player.global_position + Vector2(20.0, 0.0)
        main.add_child(projectile)

        for _i in range(30):
            await physics_frame
            if not is_instance_valid(projectile) or not projectile.is_inside_tree():
                break

        _expect(int(enemy.get("health")) == 2, "First projectile hit must reduce Enemy health from 3 to 2")
        _expect(not is_instance_valid(projectile) or not projectile.is_inside_tree(), "Projectile must be freed after hitting Enemy")

        enemy.call("take_damage", 2)
        await process_frame
        _expect(not is_instance_valid(enemy) or not enemy.is_inside_tree(), "Enemy must die when health reaches 0")
    else:
        projectile_node.queue_free()

    main.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 07 damage and death")
        quit(0)
    else:
        print("FAIL: Lesson 07 damage and death (%d failures)" % failures)
        quit(1)
