extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _find_child_from_scene(parent: Node, scene_path: String) -> Node:
    for child in parent.get_children():
        if child.scene_file_path == scene_path:
            return child
    return null

func _stop_timer(parent: Node, timer_name: StringName) -> void:
    var timer := parent.get_node_or_null(NodePath(timer_name)) as Timer
    if timer != null:
        timer.stop()

func _run() -> void:
    var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
    var gem_scene := load("res://scenes/pickups/ExperienceGem.tscn") as PackedScene
    var projectile_scene := load("res://scenes/weapons/Projectile.tscn") as PackedScene
    _expect(main_scene != null, "Main.tscn could not be loaded")
    _expect(gem_scene != null, "ExperienceGem.tscn must exist")
    _expect(projectile_scene != null, "Projectile.tscn must exist")

    if gem_scene != null:
        var gem_preview := gem_scene.instantiate()
        var gem_sprite := gem_preview.get_node_or_null("Sprite2D") as Sprite2D
        _expect(gem_sprite != null and gem_sprite.scale == Vector2(2.0, 2.0), "ExperienceGem Sprite2D scale must be 2.0")
        gem_preview.free()

    if projectile_scene != null:
        var projectile_preview := projectile_scene.instantiate()
        var projectile_sprite := projectile_preview.get_node_or_null("Sprite2D") as Sprite2D
        _expect(projectile_sprite != null and projectile_sprite.scale == Vector2(2.0, 2.0), "Projectile Sprite2D scale must be 2.0")
        projectile_preview.free()

    if main_scene == null:
        quit(1)
        return

    var main := main_scene.instantiate()
    root.add_child(main)
    current_scene = main

    var player := main.get_node_or_null("Player") as CharacterBody2D
    var spawner := main.get_node_or_null("EnemySpawner")
    _expect(player != null, "Main must contain Player")
    _expect(spawner != null, "Main must contain EnemySpawner")

    if player != null:
        var weapon := player.get_node_or_null("Weapon")
        if weapon != null:
            _stop_timer(weapon, "Timer")

    if spawner != null:
        _stop_timer(spawner, "Timer")
        _expect(spawner.get("experience_scene") != null, "EnemySpawner must reference ExperienceGem.tscn")
        spawner.call("_spawn_enemy")

    await process_frame

    var enemy := _find_child_from_scene(main, "res://scenes/enemies/Enemy.tscn") as CharacterBody2D
    _expect(enemy != null, "Spawner must create an Enemy")
    if enemy != null:
        _expect(enemy.has_signal("died"), "Enemy must declare a custom died signal")
        enemy.set("speed", 0.0)
        enemy.set("health", 1)
        var death_position := enemy.global_position
        enemy.call("take_damage", 1)
        await process_frame

        _expect(not is_instance_valid(enemy) or enemy.get_parent() == null, "Enemy must leave the Scene Tree after death")

        var gem := _find_child_from_scene(main, "res://scenes/pickups/ExperienceGem.tscn") as Node2D
        _expect(gem != null, "Enemy death must create an ExperienceGem")
        if gem != null:
            _expect(gem.global_position.distance_to(death_position) < 1.0, "ExperienceGem must appear at the Enemy death position")

    main.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 08 xp drop")
        quit(0)
    else:
        print("FAIL: Lesson 08 xp drop (%d failures)" % failures)
        quit(1)
