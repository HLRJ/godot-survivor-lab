extends SceneTree

var failures: int = 0
var emitted_levels: Array[int] = []
var player_scene: PackedScene

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

func _on_level_up(new_level: int) -> void:
    emitted_levels.append(new_level)

func _new_player(world: Node2D) -> CharacterBody2D:
    var player := player_scene.instantiate() as CharacterBody2D
    world.add_child(player)
    var timer := player.get_node_or_null("Weapon/Timer") as Timer
    if timer != null:
        timer.stop()
    return player

func _run() -> void:
    player_scene = load("res://scenes/player/Player.tscn") as PackedScene
    _expect(player_scene != null, "Player.tscn could not be loaded")
    if player_scene == null:
        quit(1)
        return

    var preview := player_scene.instantiate()
    var has_level := _has_property(preview, &"level")
    var has_threshold := _has_property(preview, &"experience_to_next_level")
    var has_signal := preview.has_signal("level_up")
    var has_move_upgrade := preview.has_method("upgrade_move_speed")

    _expect(has_level, "Player must expose level")
    _expect(has_threshold, "Player must expose next-level XP threshold")
    _expect(has_signal, "Player must define level_up signal")
    _expect(has_move_upgrade, "Player must implement move-speed upgrade")

    if has_level:
        _expect(int(preview.get("level")) == 1, "Player level must start at 1")
    _expect(int(preview.get("experience")) == 0, "Player XP must start at 0")
    if has_threshold:
        _expect(int(preview.get("experience_to_next_level")) == 5, "First level threshold must be 5 XP")

    preview.free()

    var can_test_progression := has_level and has_threshold and has_signal
    var world := Node2D.new()
    world.name = "TestWorld"
    root.add_child(world)
    current_scene = world

    if can_test_progression:
        emitted_levels.clear()
        var exact := _new_player(world)
        exact.connect("level_up", _on_level_up)
        exact.call("add_experience", 5)
        _expect(int(exact.get("level")) == 2, "5 XP must raise level to 2")
        _expect(int(exact.get("experience")) == 0, "Exact threshold must leave 0 overflow XP")
        _expect(int(exact.get("experience_to_next_level")) == 8, "Next threshold must increase from 5 to 8")
        _expect(emitted_levels == [2], "Level 2 must emit exactly once")
        exact.queue_free()
        await process_frame

        emitted_levels.clear()
        var overflow := _new_player(world)
        overflow.connect("level_up", _on_level_up)
        overflow.call("add_experience", 7)
        _expect(int(overflow.get("level")) == 2, "7 XP must reach level 2")
        _expect(int(overflow.get("experience")) == 2, "7 XP must preserve 2 overflow XP")
        _expect(emitted_levels == [2], "Overflow upgrade must emit level 2 once")
        overflow.queue_free()
        await process_frame

        emitted_levels.clear()
        var invalid := _new_player(world)
        invalid.connect("level_up", _on_level_up)
        invalid.call("add_experience", 0)
        invalid.call("add_experience", -3)
        _expect(int(invalid.get("experience")) == 0, "Non-positive XP must be ignored")
        _expect(int(invalid.get("level")) == 1, "Non-positive XP must not change level")
        _expect(emitted_levels.is_empty(), "Non-positive XP must not emit level_up")
        invalid.queue_free()
        await process_frame

        emitted_levels.clear()
        var burst := _new_player(world)
        burst.connect("level_up", _on_level_up)
        burst.call("add_experience", 14)
        _expect(int(burst.get("level")) == 3, "14 XP must cross two levels")
        _expect(int(burst.get("experience")) == 1, "14 XP must preserve 1 overflow XP")
        _expect(int(burst.get("experience_to_next_level")) == 11, "Level 3 threshold must be 11")
        _expect(emitted_levels == [2, 3], "Multi-level gain must emit once per level")
        burst.queue_free()
        await process_frame

    world.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 10 level progression")
        quit(0)
    else:
        print("FAIL: Lesson 10 level progression (%d failures)" % failures)
        quit(1)
