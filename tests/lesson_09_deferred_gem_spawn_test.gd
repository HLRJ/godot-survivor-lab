extends SceneTree

var failures: int = 0
const GEM_SCENE_PATH := "res://scenes/pickups/ExperienceGem.tscn"

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _find_gem(parent: Node) -> Node2D:
    for child in parent.get_children():
        if child.scene_file_path == GEM_SCENE_PATH:
            return child as Node2D
    return null

func _run() -> void:
    var spawner_scene := load("res://scenes/enemies/EnemySpawner.tscn") as PackedScene
    _expect(spawner_scene != null, "EnemySpawner.tscn could not be loaded")
    if spawner_scene == null:
        quit(1)
        return
    var world := Node2D.new()
    world.name = "TestWorld"
    root.add_child(world)

    var spawner := spawner_scene.instantiate()
    world.add_child(spawner)
    var timer := spawner.get_node_or_null("Timer") as Timer
    if timer != null:
        timer.stop()

    var dead_enemy := Node2D.new()
    dead_enemy.global_position = Vector2(321.0, 234.0)
    world.add_child(dead_enemy)

    spawner.call("_on_enemy_died", dead_enemy)

    _expect(_find_gem(world) == null, "ExperienceGem spawn must be deferred, not added synchronously")

    await process_frame

    var gem := _find_gem(world)
    _expect(gem != null, "Deferred ExperienceGem must appear on the next frame")
    if gem != null:
        _expect(gem.global_position.distance_to(dead_enemy.global_position) < 1.0, "Deferred ExperienceGem must preserve death position")

    world.queue_free()
    await process_frame
    if failures == 0:
        print("PASS: Lesson 09 deferred gem spawn")
        quit(0)
    else:
        print("FAIL: Lesson 09 deferred gem spawn (%d failures)" % failures)
        quit(1)
