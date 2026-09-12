extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _run() -> void:
    var scene := load("res://scenes/main/Main.tscn") as PackedScene
    _expect(scene != null, "Main.tscn could not be loaded")
    if scene == null:
        quit(1)
        return

    var main := scene.instantiate()
    root.add_child(main)

    var player := main.get_node_or_null("Player") as CharacterBody2D
    var enemy := main.get_node_or_null("Enemy") as CharacterBody2D
    _expect(player != null, "Main must contain Player")
    _expect(enemy != null, "Main must contain Enemy")
    if enemy != null:
        _expect(enemy.scene_file_path == "res://scenes/enemies/Enemy.tscn", "Enemy must come from reusable Enemy.tscn")
        _expect(enemy.get_node_or_null("CollisionShape2D") is CollisionShape2D, "Enemy must have CollisionShape2D")
        _expect(enemy.get_script() != null, "Enemy must have a chase script")
        _expect(is_equal_approx(float(enemy.get("speed")), 110.0), "Enemy default speed must be 110")

    if player != null and enemy != null:
        await physics_frame
        var start_distance := enemy.global_position.distance_to(player.global_position)
        for _i in range(60):
            await physics_frame
        var end_distance := enemy.global_position.distance_to(player.global_position)
        _expect(end_distance < start_distance - 50.0, "Enemy should move significantly closer to Player")

    main.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 04 enemy chase")
        quit(0)
    else:
        print("FAIL: Lesson 04 enemy chase (%d failures)" % failures)
        quit(1)
