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
    var enemy_scene := load("res://scenes/enemies/Enemy.tscn") as PackedScene
    _expect(enemy_scene != null, "Enemy.tscn could not be loaded")
    if enemy_scene == null:
        quit(1)
        return

    var world := Node2D.new()
    world.name = "TestWorld"
    root.add_child(world)

    var player := Node2D.new()
    player.name = "Player"
    player.position = Vector2(640, 360)
    world.add_child(player)

    var enemy := enemy_scene.instantiate() as CharacterBody2D
    enemy.position = Vector2(160, 360)
    world.add_child(enemy)

    _expect(enemy.get_node_or_null("CollisionShape2D") is CollisionShape2D, "Enemy must have CollisionShape2D")
    _expect(enemy.get_script() != null, "Enemy must have a chase script")
    _expect(is_equal_approx(float(enemy.get("speed")), 110.0), "Enemy default speed must be 110")

    await physics_frame
    var start_distance := enemy.global_position.distance_to(player.global_position)
    for _i in range(60):
        await physics_frame
    var end_distance := enemy.global_position.distance_to(player.global_position)
    _expect(end_distance < start_distance - 50.0, "Enemy should move significantly closer to Player")

    world.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 04 enemy chase")
        quit(0)
    else:
        print("FAIL: Lesson 04 enemy chase (%d failures)" % failures)
        quit(1)
