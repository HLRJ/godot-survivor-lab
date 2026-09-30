extends SceneTree

var failures := 0

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

func _check_resource(path: String, expected_id: StringName, expected_label: String, expected_amount: float) -> void:
    var resource := load(path)
    _expect(resource != null, "%s must load" % path)
    if resource == null:
        return

    _expect(resource is Resource, "%s must be a Resource" % path)
    _expect(_has_property(resource, &"id"), "%s must expose id" % path)
    _expect(_has_property(resource, &"label"), "%s must expose label" % path)
    _expect(_has_property(resource, &"amount"), "%s must expose amount" % path)

    if _has_property(resource, &"id"):
        _expect(StringName(resource.get("id")) == expected_id, "%s id mismatch" % path)
    if _has_property(resource, &"label"):
        _expect(String(resource.get("label")) == expected_label, "%s label mismatch" % path)
    if _has_property(resource, &"amount"):
        _expect(abs(float(resource.get("amount")) - expected_amount) < 0.001, "%s amount mismatch" % path)

func _run() -> void:
    var script := load("res://scripts/upgrades/upgrade_data.gd")
    _expect(script != null, "upgrade_data.gd must exist")
    if script != null:
        var sample: Object = script.new()
        _expect(sample is Resource, "UpgradeData must extend Resource")
        _expect(_has_property(sample, &"id"), "UpgradeData must export id")
        _expect(_has_property(sample, &"label"), "UpgradeData must export label")
        _expect(_has_property(sample, &"amount"), "UpgradeData must export amount")

    _check_resource(
        "res://resources/upgrades/move_speed.tres",
        &"move_speed",
        "移动速度 +40",
        40.0
    )
    _check_resource(
        "res://resources/upgrades/attack_speed.tres",
        &"attack_speed",
        "攻击间隔 -0.1 秒",
        0.1
    )
    _check_resource(
        "res://resources/upgrades/projectile_damage.tres",
        &"projectile_damage",
        "子弹伤害 +1",
        1.0
    )

    if failures == 0:
        print("PASS: Lesson 11 upgrade data")
        quit(0)
    else:
        print("FAIL: Lesson 11 upgrade data (%d failures)" % failures)
        quit(1)
