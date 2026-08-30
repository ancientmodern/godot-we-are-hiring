extends SceneTree

const HiringMain = preload("res://src/hiring_main.gd")
const HiringContent = preload("res://src/hiring_content.gd")

var save_path := "user://hiring_gamepad_contract_save_%d.json" % OS.get_process_id()
var meta_path := "user://hiring_gamepad_contract_meta_%d.json" % OS.get_process_id()
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_clear_test_storage()
	_test_input_map()

	var ui = HiringMain.new()
	ui.save_path_override = save_path
	ui.meta_path_override = meta_path
	root.add_child(ui)
	await process_frame

	_test_router_boot_contract(ui)
	_test_start_and_pause_contract(ui)
	_test_onboarding_and_dashboard_contract(ui)
	_test_event_focus_and_cancel_contract(ui)
	_test_workspace_navigation_and_settings_contract(ui)
	_test_irreversible_cancel_contract(ui)
	_test_event_pause_clock_contract(ui)
	_test_night_two_terminal_gamepad_contract(ui)

	_dispose_ui(ui)
	await process_frame
	_clear_test_storage()
	if failures.is_empty():
		print("HIRING_GAMEPAD_CONTRACT_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_GAMEPAD_CONTRACT_TEST_FAILURE: " + failure)
		quit(1)


func _test_input_map() -> void:
	var expected := {
		"interact": JOY_BUTTON_A,
		"ui_cancel": JOY_BUTTON_B,
		"delegate": JOY_BUTTON_X,
		"end_week": JOY_BUTTON_Y,
		"tab_left": JOY_BUTTON_LEFT_SHOULDER,
		"tab_right": JOY_BUTTON_RIGHT_SHOULDER,
		"pause": JOY_BUTTON_START,
		"move_up": JOY_BUTTON_DPAD_UP,
		"move_down": JOY_BUTTON_DPAD_DOWN,
		"move_left": JOY_BUTTON_DPAD_LEFT,
		"move_right": JOY_BUTTON_DPAD_RIGHT,
	}
	for action_name in expected:
		_check(InputMap.has_action(action_name), "InputMap defines `%s`" % action_name)
		_check(_action_has_joy_button(action_name, int(expected[action_name])), "`%s` owns the intended gamepad button" % action_name)


func _test_router_boot_contract(ui) -> void:
	_check(ui.focus_router != null, "HiringMain creates the shared focus router during ready")
	_check(str(ui.focus_router.section) == "onboarding" and ui.focus_router.item_count == 1, "fresh onboarding exposes one safe default focus")
	_check(ui._focus_is("onboarding", 0) == false, "focus ring stays quiet until directional input is used")


func _test_start_and_pause_contract(ui) -> void:
	ui._unhandled_input(_joy_event(JOY_BUTTON_START))
	_check(ui.settings_open, "Start opens settings from onboarding")
	_check(ui.gamepad_focus_visible and str(ui.focus_router.section) == "settings", "Start switches to the visible settings focus section")
	var screen_before: float = ui.screen_time
	var event_before: float = ui.event_page_elapsed
	ui._process(0.75)
	_check(is_equal_approx(ui.screen_time, screen_before), "PAUSED freezes the authored screen clock")
	_check(is_equal_approx(ui.event_page_elapsed, event_before), "PAUSED freezes the event hold clock")
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(not ui.settings_open, "B closes settings without touching campaign state")


func _test_onboarding_and_dashboard_contract(ui) -> void:
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))
	_check(ui.screen == HiringMain.Screen.EVENT and str(ui.current_event.get("id", "")) == "garage_opening", "A completes fresh onboarding with the default company name")
	for _page in 8:
		if ui.screen != HiringMain.Screen.EVENT:
			break
		ui.event_page_elapsed = 999.0
		ui._unhandled_input(_joy_event(JOY_BUTTON_A))
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "A advances and selects the default responses in the opening before entering the playable dashboard")
	_check(str(ui.focus_router.section) == "dashboard_actions" and ui.focus_router.item_count == ui.week_action_ids.size(), "dashboard focus count follows the offered action list")

	var action_before: int = ui.selected_action
	ui._unhandled_input(_joy_event(JOY_BUTTON_DPAD_DOWN))
	_check(ui.selected_action == mini(action_before + 1, ui.week_action_ids.size() - 1), "D-pad moves the dashboard action focus")
	_check(ui._focus_is("dashboard_actions", ui.selected_action), "dashboard exposes one visible focused action after D-pad input")

	var manual_index: int = int(ui.week_action_ids.find("train"))
	if manual_index < 0:
		manual_index = 0
	ui._set_selected_action(manual_index)
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT, "A performs the highlighted action personally")
	var result_page_before: int = ui.result_page
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT and ui.result_page == result_page_before, "B cannot consume or close an action result")
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "A closes an ordinary action receipt")

	var delegated_index := _first_unused_action_index(ui)
	_check(delegated_index >= 0, "dashboard keeps an unused action available for the X contract")
	if delegated_index >= 0:
		ui._set_selected_action(delegated_index)
		var delegation_before: int = int(ui.model.delegation_count)
		ui._unhandled_input(_joy_event(JOY_BUTTON_X))
		_check(ui.screen == HiringMain.Screen.ACTION_RESULT, "X delegates the highlighted dashboard action")
		_check(int(ui.model.delegation_count) > delegation_before, "X reaches the authoritative delegation path")
		ui._unhandled_input(_joy_event(JOY_BUTTON_A))

	ui._unhandled_input(_joy_event(JOY_BUTTON_Y))
	_check(ui.screen == HiringMain.Screen.DASHBOARD and ui.end_week_confirm_pending, "Y requests explicit confirmation before discarding unused attention")
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(ui.screen == HiringMain.Screen.DASHBOARD and not ui.end_week_confirm_pending, "B cancels the reversible end-week confirmation")


func _test_event_focus_and_cancel_contract(ui) -> void:
	ui.current_event = _contract_event("grid_four", 4)
	ui.current_event_page = 0
	ui.focused_event_choice = 0
	ui._change_screen(HiringMain.Screen.EVENT)
	ui._unhandled_input(_joy_event(JOY_BUTTON_DPAD_RIGHT))
	ui._unhandled_input(_joy_event(JOY_BUTTON_DPAD_DOWN))
	_check(ui.focused_event_choice == 3, "D-pad preserves columns across a 2x2 event choice grid")
	_check(ui._focus_is("event_choices:", 3), "2x2 event focus is unique and visible")
	var event_before: Dictionary = ui.current_event.duplicate(true)
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(ui.screen == HiringMain.Screen.EVENT and ui.current_event == event_before, "B never chooses or closes an event")
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT and ui.result_lines == ["resolved 3"], "A commits exactly the focused 2x2 event choice")
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))

	ui.current_event = _contract_event("linear_three", 3)
	ui.current_event_page = 0
	ui.focused_event_choice = 0
	ui._change_screen(HiringMain.Screen.EVENT)
	ui._unhandled_input(_joy_event(JOY_BUTTON_DPAD_DOWN))
	_check(ui.focused_event_choice == 1 and ui.focus_router.columns == 1, "three-choice events use a one-column D-pad route")
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT and ui.result_lines == ["resolved 1"], "A commits the focused one-column event choice")
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))


func _test_workspace_navigation_and_settings_contract(ui) -> void:
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	ui._unhandled_input(_joy_event(JOY_BUTTON_RIGHT_SHOULDER))
	_check(ui.screen == HiringMain.Screen.TEAM, "RB advances to the next workspace folio")
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "B returns from a utility folio to overview")
	ui._unhandled_input(_joy_event(JOY_BUTTON_LEFT_SHOULDER))
	_check(ui.screen == HiringMain.Screen.INTRANET, "LB wraps from overview to the previous workspace folio")
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "B also returns from intranet when no authored lock is active")

	ui._unhandled_input(_joy_event(JOY_BUTTON_START))
	_check(ui.settings_open and ui.focused_settings_row == 0, "Start opens settings on its first row")
	ui._unhandled_input(_joy_event(JOY_BUTTON_DPAD_DOWN))
	_check(ui.focused_settings_row == 1 and ui._focus_is("settings", 1), "D-pad moves a single visible settings focus")
	var muted_before: bool = bool(ui.office_audio.muted)
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))
	_check(bool(ui.office_audio.muted) != muted_before, "A toggles the focused settings row")
	ui._unhandled_input(_joy_event(JOY_BUTTON_A))
	_check(bool(ui.office_audio.muted) == muted_before, "the focused settings toggle is reversible")
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(not ui.settings_open and ui.screen == HiringMain.Screen.DASHBOARD, "B closes settings back to the same screen")


func _test_irreversible_cancel_contract(ui) -> void:
	ui.screen = HiringMain.Screen.ENDING
	ui.current_ending_id = "gamepad_contract"
	ui.current_ending = {"body": ["第一页", "第二页"]}
	ui.ending_page = 0
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(ui.screen == HiringMain.Screen.ENDING and ui.ending_page == 0, "B cannot consume an ending page")

	ui.screen = HiringMain.Screen.SIGNATURE
	ui.screen_time = 10.0
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(ui.screen == HiringMain.Screen.SIGNATURE, "B cannot complete a signature")

	ui.screen = HiringMain.Screen.BOARD_PRESENTATION
	ui.model.flags["board_presentation_active"] = true
	ui.model.memory["board_presentation_phase"] = "chart"
	var board_phase := str(ui.model.memory["board_presentation_phase"])
	ui._unhandled_input(_joy_event(JOY_BUTTON_B))
	_check(ui.screen == HiringMain.Screen.BOARD_PRESENTATION and str(ui.model.memory["board_presentation_phase"]) == board_phase, "B cannot advance the board sequence")
	ui.model.flags.erase("board_presentation_active")
	ui._change_screen(HiringMain.Screen.DASHBOARD)


func _test_event_pause_clock_contract(ui) -> void:
	ui.current_event = {"id": "pause_clock", "body": ["等待。"], "choices": []}
	ui.current_event_page = 0
	ui.event_page_elapsed = 2.25
	ui._change_screen(HiringMain.Screen.EVENT)
	ui.screen_time = 4.5
	ui._unhandled_input(_joy_event(JOY_BUTTON_START))
	var screen_before: float = ui.screen_time
	var event_before: float = ui.event_page_elapsed
	ui._process(1.0)
	_check(is_equal_approx(ui.screen_time, screen_before), "settings freezes special-scene time")
	_check(is_equal_approx(ui.event_page_elapsed, event_before), "settings freezes authored event hold time")
	ui._unhandled_input(_joy_event(JOY_BUTTON_START))
	ui.current_event.clear()
	ui._change_screen(HiringMain.Screen.DASHBOARD)


func _test_night_two_terminal_gamepad_contract(ui) -> void:
	var night: Dictionary = HiringContent.get_night_shift("2")
	night["_director_night_id"] = "2"
	ui.pending_night_id = "2"
	ui._open_night_shift(night)
	var terminal_index := _night_object_index(ui, "terminal")
	_check(terminal_index >= 0, "night two exposes its authored terminal hotspot")
	if terminal_index < 0:
		return
	ui.night_focused_object_index = terminal_index
	_gamepad_arrive_at_focused_object(ui)
	_check(str(ui.night_interaction.object_phase("terminal")) == "dialogue_inspected", "first gamepad terminal interaction reads the unsent dialogue")
	_gamepad_arrive_at_focused_object(ui)
	_check(str(ui.night_interaction.object_phase("terminal")) == "focused" and ui.night_interaction.terminal_accepts_command(), "second gamepad interaction focuses the terminal")
	_check(not ui.night_seen.has("terminal"), "terminal remains incomplete before the explicit X interrupt")

	var terminal_lines_before: Array[String] = ui.terminal_lines.duplicate()
	var result_lines_before: Array[String] = ui.result_lines.duplicate()
	var start_event := _joy_event(JOY_BUTTON_START)
	ui._on_night_command_gui_input(start_event)
	_check(ui.settings_open, "Start reaches settings while the night LineEdit owns focus")
	var position_before: Vector2 = ui.night_player_position
	ui.night_player_target += Vector2(180.0, 0.0)
	ui._process(0.75)
	_check(ui.night_player_position == position_before, "PAUSED freezes night movement and arrival")
	ui._unhandled_input(start_event)
	_check(not ui.settings_open and ui.command_edit.visible and ui.command_edit.has_focus(), "closing settings restores the focused night terminal")

	ui._on_night_command_gui_input(_joy_event(JOY_BUTTON_X))
	_check(str(ui.night_interaction.object_phase("terminal")) == "interrupted", "X invokes the same authored terminal interrupt as Ctrl+C")
	_check(ui.night_seen.has("terminal") and ui.night_interaction.completed_object_ids().has("terminal"), "X completes the terminal object without another command")
	_check(ui.terminal_lines == terminal_lines_before and ui.result_lines == result_lines_before, "X interrupt adds no dialogue, toast transcript, or fake command output")
	_check(ui.current_ending_id != "rm_rf" and not bool(ui.model.flags.get("rm_rf", false)), "X interrupt cannot trigger the rm-rf ending")


func _contract_event(event_id: String, count: int) -> Dictionary:
	var choices: Array = []
	for index in count:
		choices.append({
			"id": "choice_%d" % index,
			"label": "Choice %d" % index,
			"result_title": "Resolved %d" % index,
			"result": ["resolved %d" % index],
			"effects": {},
		})
	return {"id": event_id, "title": "Controller contract", "body": [], "choices": choices}


func _first_unused_action_index(ui) -> int:
	for index in ui.week_action_ids.size():
		var action_id := str(ui.week_action_ids[index])
		if not ui.used_action_ids.has(action_id) and bool(ui.model.can_act(action_id, true)):
			return index
	return -1


func _gamepad_arrive_at_focused_object(ui) -> void:
	ui.result_lines.clear()
	ui._handle_gamepad_action("interact")
	_check(ui.night_arrival_armed or ui.night_player_position.distance_to(ui.night_player_target) <= 2.5, "A arms movement toward the focused night object")
	ui.night_player_position = ui.night_player_target
	ui.night_arrival_armed = false
	ui._complete_night_object_arrival()
	ui.result_lines.clear()


func _night_object_index(ui, object_id: String) -> int:
	for index in ui.night_objects.size():
		if str(Dictionary(ui.night_objects[index]).get("id", "")) == object_id:
			return index
	return -1


func _action_has_joy_button(action_name: String, button_index: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true
	return false


func _joy_event(button_index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button_index
	event.pressed = true
	return event


func _dispose_ui(ui) -> void:
	if ui.office_audio != null:
		for child in ui.office_audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
	ui.queue_free()


func _clear_test_storage() -> void:
	for path in [save_path, save_path + ".bak", save_path + ".tmp", meta_path, meta_path + ".bak", meta_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
