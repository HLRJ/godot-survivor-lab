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
    var wall := main.get_node_or_null("TrainingWall") as StaticBody2D
    _expect(player != null, "Main must contain Player")
    _expect(wall != null, "Main must contain TrainingWall")
    if player != null:
        _expect(player.get_node_or_null("CollisionShape2D") is CollisionShape2D, "Player must have CollisionShape2D")
        _expect(player.collision_layer == 1, "Player collision_layer must be 1")
        _expect(player.collision_mask == 1, "Player collision_mask must be 1")

    if wall != null:
        _expect(wall.get_node_or_null("CollisionShape2D") is CollisionShape2D, "TrainingWall must have CollisionShape2D")
        _expect(wall.collision_layer == 1, "TrainingWall collision_layer must be 1")
        _expect(wall.collision_mask == 1, "TrainingWall collision_mask must be 1")

    if player != null and wall != null:
        var start_x := player.global_position.x
        Input.action_press("move_right")
        for _i in range(120):
            await physics_frame
        Input.action_release("move_right")

        _expect(player.global_position.x < wall.global_position.x, "Player should remain on the left side of TrainingWall")
        _expect(player.global_position.x < start_x + 190.0, "Player should be blocked before moving through the wall")

    main.queue_free()
    await process_frame
    if failures == 0:
        print("PASS: Lesson 03 collision")
        quit(0)
    else:
        print("FAIL: Lesson 03 collision (%d failures)" % failures)
        quit(1)
