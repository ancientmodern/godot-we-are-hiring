extends SceneTree

const HiringFocusRouter = preload("res://src/hiring_focus_router.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	var router = HiringFocusRouter.new()
	_test_linear_focus(router)
	_test_grid_focus(router)
	_test_restore_and_clamp(router)
	if failures.is_empty():
		print("HIRING_FOCUS_ROUTER_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_FOCUS_ROUTER_TEST_FAILURE: " + failure)
		quit(1)


func _test_linear_focus(router) -> void:
	_check(router.configure("dashboard", 5, 1, 0) == 0, "dashboard starts at its requested action")
	_check(router.has_focus(), "a nonempty dashboard exposes exactly one focus index")
	_check(router.move(Vector2i.DOWN) == 1, "down advances a linear action list")
	_check(router.move(Vector2i.UP) == 0, "up reverses a linear action list")
	_check(router.move(Vector2i.UP) == 0, "linear focus clamps at the first item")
	_check(router.set_index(4) == 4, "linear focus can select the final action")
	_check(router.move(Vector2i.DOWN, true) == 0, "optional wrapping returns from final to first")


func _test_grid_focus(router) -> void:
	_check(router.configure("event_four_choices", 4, 2, 0) == 0, "four-choice event starts at the first decision")
	_check(router.move(Vector2i.RIGHT) == 1, "right moves within a 2x2 decision row")
	_check(router.move(Vector2i.DOWN) == 3, "down preserves the decision column")
	_check(router.move(Vector2i.LEFT) == 2, "left moves within the second decision row")
	_check(router.move(Vector2i.UP) == 0, "up returns to the geometrically matching choice")
	_check(router.configure("event_three_choices", 3, 2, 1) == 1, "ragged decision grid accepts a preferred focus")
	_check(router.move(Vector2i.DOWN) == 2, "ragged final row selects its closest real choice")


func _test_restore_and_clamp(router) -> void:
	router.configure("records", 7, 1, 0)
	router.set_index(5)
	router.configure("settings", 4, 1, 2)
	_check(router.index == 2, "settings receives an explicit initial focus")
	router.configure("records", 7)
	_check(router.index == 5, "returning to a section restores its last unique focus")
	_check(router.configure("records", 2) == 1, "restored focus clamps when a list shrinks")
	_check(router.configure("empty", 0) == 0 and not router.has_focus(), "an empty section exposes no active focus")
	_check(router.set_index(99) == 0, "empty-section focus remains safely clamped")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
