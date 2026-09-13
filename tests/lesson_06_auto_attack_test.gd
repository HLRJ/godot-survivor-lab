extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _find_projectiles(main: Node) -> Array[Node]:
    var projectiles: Array[Node] = []
    for child in main.get_children():
        if child.scene_file_path == "res://scenes/weapons/Projectile.tscn":
            projectiles.append(child)
    return projectiles

func _texture_has_visible_pixel(texture: Texture2D) -> bool:
    if texture == null:
        return false
    var image := texture.get_image()
    if image == null or image.is_empty():
        return false
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            if image.get_pixel(x, y).a > 0.0:
                return true
    return false

func _run() -> void:
    var scene := load("res://scenes/main/Main.tscn") as PackedScene
    _expect(scene != null, "Main.tscn could not be loaded")
    if scene == null:
        quit(1)
        return
    var main := scene.instantiate()
    root.add_child(main)
    current_scene = main
    var player := main.get_node_or_null("Player") as CharacterBody2D
    var spawner := main.get_node_or_null("EnemySpawner")
    _expect(player != null, "Main must contain Player")
    _expect(spawner != null, "Main must contain EnemySpawner")

    var weapon: Node = null
    if player != null:
        weapon = player.get_node_or_null("Weapon")
    _expect(weapon != null, "Player must contain Weapon")

    if spawner != null:
        var spawn_timer := spawner.get_node_or_null("Timer") as Timer
        if spawn_timer != null:
            spawn_timer.stop()
            spawn_timer.wait_time = 0.1
            spawn_timer.start()

    if weapon != null:
        var attack_timer := weapon.get_node_or_null("Timer") as Timer
        _expect(attack_timer != null, "Weapon must contain Timer")
        _expect(is_equal_approx(float(weapon.get("attack_interval")), 0.8), "Weapon default attack_interval must be 0.8")
        _expect(weapon.get("projectile_scene") != null, "Weapon must reference Projectile.tscn")
        if attack_timer != null:
            attack_timer.stop()
            attack_timer.wait_time = 0.12
            attack_timer.start()

    for _i in range(45):
        await physics_frame

    var projectiles := _find_projectiles(main)
    _expect(projectiles.size() >= 1, "Main should contain at least one Projectile after auto attack")

    if not projectiles.is_empty():
        var projectile := projectiles[0] as Node2D
        var sprite := projectile.get_node_or_null("Sprite2D") as Sprite2D
        _expect(sprite != null, "Projectile must contain Sprite2D")
        if sprite != null:
            _expect(_texture_has_visible_pixel(sprite.texture), "Projectile Sprite2D texture must contain visible pixels")
        _expect(is_equal_approx(float(projectile.get("speed")), 520.0), "Projectile default speed must be 520.0")
        var direction := projectile.get("direction") as Vector2
        _expect(is_equal_approx(direction.length(), 1.0), "Projectile direction must be normalized")
        var start_position := projectile.global_position
        for _i in range(5):
            await physics_frame
        _expect(projectile.global_position.distance_to(start_position) > 1.0, "Projectile must move across physics frames")

    main.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 06 auto attack")
        quit(0)
    else:
        print("FAIL: Lesson 06 auto attack (%d failures)" % failures)
        quit(1)
