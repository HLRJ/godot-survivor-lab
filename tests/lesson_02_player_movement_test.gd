extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _stop_timer(parent: Node, timer_name: StringName) -> void:
    var timer := parent.get_node_or_null(NodePath(timer_name)) as Timer
    if timer != null:
        timer.stop()

func _run() -> void:
    var required_actions := ["move_left", "move_right", "move_up", "move_down"]
    for action in required_actions:
        _expect(InputMap.has_action(action), "Missing Input Action: %s" % action)

    var expected_keys := {
        "move_left": [KEY_A, KEY_LEFT],
        "move_right": [KEY_D, KEY_RIGHT],
        "move_up": [KEY_W, KEY_UP],
        "move_down": [KEY_S, KEY_DOWN],
    }
    for action in expected_keys:
        var bound_keys: Array[Key] = []
        for event in InputMap.action_get_events(action):
            if event is InputEventKey:
                bound_keys.append(event.physical_keycode)
        for expected_key in expected_keys[action]:
            _expect(expected_key in bound_keys, "%s is missing expected key %s" % [action, expected_key])

    var scene := load("res://scenes/player/Player.tscn") as PackedScene
    _expect(scene != null, "Player.tscn could not be loaded")
    if scene == null:
        quit(1)
        return

    var player := scene.instantiate()
    root.add_child(player)
    _expect(player is CharacterBody2D, "Player root must be CharacterBody2D")
    _expect(player.get_script() != null, "Player must have a movement script")

    var weapon := player.get_node_or_null("Weapon")
    if weapon != null:
        _stop_timer(weapon, "Timer")

    await physics_frame
    var start_position: Vector2 = player.position

    Input.action_press("move_right")
    await physics_frame
    await physics_frame
    Input.action_release("move_right")

    _expect(player.position.x > start_position.x, "Player should move right when move_right is pressed")
    _expect(absf(player.position.y - start_position.y) < 0.01, "Moving right should not change Y position")

    player.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 02 player movement")
        quit(0)
    else:
        print("FAIL: Lesson 02 player movement (%d failures)" % failures)
        quit(1)
