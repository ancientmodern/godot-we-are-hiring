extends SceneTree

## Executable integration contract for wiring NightInteractionState into the
## production HiringMain UI. This test intentionally stays red until the main
## scene owns the core and routes real UI arrivals/actions through it.

const HiringMain = preload("res://src/hiring_main.gd")
const HiringContent = preload("res://src/hiring_content.gd")

var SAVE_PATH := "user://we_are_hiring_night_ui_test_save_%d.json" % OS.get_process_id()
var META_PATH := "user://we_are_hiring_night_ui_test_meta_%d.json" % OS.get_process_id()

const CORE_PROPERTY := "night_interaction"
const TARGET_PROPERTY := "night_pending_object_id"
const ARRIVAL_METHOD := "_complete_night_object_arrival"
const CTRL_C_METHOD := "_handle_night_ctrl_c"

var failures: Array[String] = []
var checks := 0
var _file_backups: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_backup_and_clear_user_file(SAVE_PATH)
	_backup_and_clear_user_file(META_PATH)

	var ui = HiringMain.new()
	ui.save_path_override = SAVE_PATH
	ui.meta_path_override = META_PATH
	root.add_child(ui)
	await process_frame
	_test_required_main_api(ui)
	_test_keyboard_and_gamepad_navigation(ui)
	_test_open_click_arrival_and_night_one(ui)
	_test_night_two_sequences_through_main(ui)
	_test_authored_night_visual_states(ui)
	_test_night_tone_fixture_contract(ui)
	_test_terminal_input_and_rm_rf_focus_gate(ui)
	_dispose_ui(ui)
	await process_frame

	await _test_ui_save_round_trip()
	_restore_user_files()

	if failures.is_empty():
		print("HIRING_NIGHT_UI_INTEGRATION_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_NIGHT_UI_INTEGRATION_EXPECTED_FAILURE: " + failure)
		print("HIRING_NIGHT_UI_INTEGRATION_RED: %d failures across %d checks" % [failures.size(), checks])
		quit(1)


func _test_required_main_api(ui) -> void:
	_check(_has_property(ui, CORE_PROPERTY), "HiringMain must own `night_interaction`")
	_check(_has_property(ui, TARGET_PROPERTY), "HiringMain must remember `night_pending_object_id` between click and arrival")
	_check(ui.has_method("_queue_night_object_visit"), "HiringMain must route hotspot clicks through `_queue_night_object_visit()`")
	_check(ui.has_method(ARRIVAL_METHOD), "HiringMain must expose `_complete_night_object_arrival()` for movement completion")
	_check(ui.has_method(CTRL_C_METHOD), "HiringMain must route exact Ctrl+C through `_handle_night_ctrl_c()`")
	_check(ui.has_method("_night_visual_state"), "HiringMain exposes the semantic state used by authored night visuals")
	_check(ui.has_method("_night_tone_fixture_contract"), "HiringMain exposes the authored late-office fixture contract")
	_check(ui.has_method("_night_intro_surface_lines"), "HiringMain exposes the restrained night-opening copy that is actually drawn")
	_check(_has_property(ui, "night_focused_object_index"), "HiringMain owns a persistent night focus index for keyboard and gamepad navigation")
	_check(ui.has_method("_handle_night_navigation_action") and ui.has_method("_activate_focused_night_object"), "HiringMain exposes the shared keyboard/gamepad night navigation route")
	_check(ui.has_method("_night_modal_close_rect"), "HiringMain exposes a standard 44-pixel NightInspector close control")


func _test_keyboard_and_gamepad_navigation(ui) -> void:
	var core = _open_night(ui, "1")
	if core == null or ui.night_objects.is_empty():
		return
	var initial_focus: int = ui.night_focused_object_index
	ui.call("_handle_night_navigation_action", "move_right")
	_check(ui.night_focused_object_index == posmod(initial_focus + 1, ui.night_objects.size()), "keyboard-style navigation advances the focused night object")
	ui.call("_handle_night_navigation_action", "move_left")
	_check(ui.night_focused_object_index == initial_focus, "keyboard-style navigation reverses without losing focus")

	var dpad_right := InputEventJoypadButton.new()
	dpad_right.button_index = JOY_BUTTON_DPAD_RIGHT
	dpad_right.pressed = true
	ui._unhandled_input(dpad_right)
	_check(ui.night_focused_object_index == posmod(initial_focus + 1, ui.night_objects.size()), "D-pad right reaches the shared focus-navigation path")

	var whiteboard_index := -1
	for object_index in ui.night_objects.size():
		if str(ui.night_objects[object_index].get("id", "")) == "whiteboard":
			whiteboard_index = object_index
			break
	_check(whiteboard_index >= 0, "night-one keyboard fixture finds the whiteboard focus target")
	if whiteboard_index < 0:
		return
	ui.night_focused_object_index = whiteboard_index
	var gamepad_a := InputEventJoypadButton.new()
	gamepad_a.button_index = JOY_BUTTON_A
	gamepad_a.pressed = true
	ui._unhandled_input(gamepad_a)
	_check(str(ui.night_pending_object_id) == "whiteboard" and ui.night_arrival_armed, "gamepad A activates the focused hotspot instead of requiring a mouse")
	ui.night_player_position = ui.night_player_target
	ui.night_arrival_armed = false
	ui.call(ARRIVAL_METHOD)
	_check(str(core.call("object_phase", "whiteboard")) == "inspected" and not ui.result_lines.is_empty(), "gamepad-focused arrival completes the same authored object route")
	var inspector_copy: Array[String] = ui.result_lines.duplicate()
	ui.call("_handle_night_click", Vector2(12, 12))
	_check(ui.result_lines == inspector_copy, "NightInspector ignores stray clicks outside its explicit footer action")
	ui.call("_handle_night_click", Rect2(ui.call("_night_modal_close_rect")).get_center())
	_check(ui.result_lines.is_empty(), "NightInspector closes from its explicit 44-pixel footer control")

	core = _open_night(ui, "1")
	whiteboard_index = -1
	for object_index in ui.night_objects.size():
		if str(ui.night_objects[object_index].get("id", "")) == "whiteboard":
			whiteboard_index = object_index
			break
	ui.result_lines.clear()
	ui.night_focused_object_index = whiteboard_index
	_send_night_key(ui, false, KEY_ENTER)
	var enter_queued_or_arrived := str(ui.night_pending_object_id) == "whiteboard" or str(core.call("object_phase", "whiteboard")) == "inspected"
	_check(enter_queued_or_arrived, "Enter activates the focused night object")
	if not str(ui.night_pending_object_id).is_empty():
		ui.night_player_position = ui.night_player_target
		ui.night_arrival_armed = false
		ui.call(ARRIVAL_METHOD)
	_send_night_key(ui, false, KEY_ENTER)
	_check(ui.result_lines.is_empty(), "Enter closes the completed NightInspector without a mouse")


func _test_night_tone_fixture_contract(ui) -> void:
	var fixtures: Dictionary = ui.call("_night_tone_fixture_contract")
	_check(fixtures.has("microwave") and fixtures.has("abandoned_monitor") and str(fixtures.get("plant_object_id", "")) == "pothos", "night art contains the required microwave, left-on monitor line, and dying pothos")
	var microwave: Dictionary = fixtures.get("microwave", {})
	var monitor: Dictionary = fixtures.get("abandoned_monitor", {})
	_check(str(microwave.get("clock", "")) == "--:--" and not bool(microwave.get("interactive", true)), "the unset microwave stays ordinary and cannot contradict either night scene's visible time")
	_check(str(microwave.get("sound", "unexpected")) == "none", "the microwave adds no beep, stinger, or threat cue")
	_check(not str(monitor.get("line", "")).is_empty() and not bool(monitor.get("interactive", true)), "the forgotten monitor sentence remains ambient office detail rather than an anomaly objective")


func _test_open_click_arrival_and_night_one(ui) -> void:
	var core = _open_night(ui, "1")
	if core == null:
		return
	_check(str(core.get("night_id")) == "1", "opening night one initializes the core with canonical night id 1")
	var intro_surface: Dictionary = ui.call("_night_intro_surface_lines")
	_check("01:17" in str(intro_surface.get("subtitle", "")), "night one visibly establishes its late-hour timestamp")
	_check("空调还在响" in str(intro_surface.get("opening", "")), "night one visibly surfaces the restrained empty-office opening instead of leaving it as dead data")
	_check(core.call("completed_object_ids").is_empty(), "opening night one initializes an empty completed set")
	_check(not bool(ui.call("_night_complete")), "the untouched UI night cannot be left")

	# Legacy night_seen must not be authoritative once the core is present.
	ui.night_seen.append("whiteboard")
	_check(not bool(ui.call("_night_complete")), "`_night_complete()` delegates to the core instead of trusting a forged legacy night_seen entry")
	ui.night_seen.clear()

	var corridor_center := _night_object_center(ui, "corridor")
	_check(corridor_center != Vector2.ZERO, "night-one corridor has a reachable UI hotspot")
	ui.result_lines.clear()
	ui.night_player_position = Vector2(640, 540)
	var previous_target: Vector2 = ui.night_player_target
	ui.call("_handle_night_click", corridor_center)
	_check(not ui.night_player_target.is_equal_approx(previous_target), "corridor click assigns a physical crossing target")
	_check(ui.night_seen.is_empty() and core.call("completed_object_ids").is_empty(), "corridor click does not mark an object seen before arrival")
	if _has_property(ui, TARGET_PROPERTY):
		_check(str(ui.get(TARGET_PROPERTY)) == "corridor", "corridor click records the pending target object id")

	if not ui.has_method(ARRIVAL_METHOD):
		return
	ui.night_player_position = ui.night_player_target
	ui.night_arrival_armed = false
	ui.call(ARRIVAL_METHOD)
	_check(int(Dictionary(core.call("object_state", "corridor")).get("pass_count", 0)) == 1, "first physical corridor arrival records exactly pass one")
	_check(ui.night_seen.is_empty() and not bool(ui.call("_night_complete")), "one corridor pass is not enough to leave")

	for expected_pass in [2, 3]:
		_arrive_at(ui, "corridor")
		_check(int(Dictionary(core.call("object_state", "corridor")).get("pass_count", 0)) == expected_pass, "corridor UI arrival records pass %d exactly once" % expected_pass)
		if expected_pass < 3:
			_check(not ui.night_seen.has("corridor") and not bool(ui.call("_night_complete")), "corridor stays unseen before its third arrival")
	_check(ui.night_seen == ["corridor"], "third corridor arrival synchronizes the completed object into night_seen")
	_check(bool(ui.call("_night_complete")), "third corridor arrival opens the UI exit through the core predicate")

	core = _open_night(ui, "1")
	if core == null:
		return
	ui.result_lines.clear()
	var whiteboard_center := _night_object_center(ui, "whiteboard")
	ui.call("_handle_night_click", whiteboard_center)
	_check(ui.night_seen.is_empty(), "single-object click still waits for explicit arrival")
	ui.night_player_position = ui.night_player_target
	ui.night_arrival_armed = false
	ui.call(ARRIVAL_METHOD)
	_check(str(core.call("object_phase", "whiteboard")) == "inspected", "whiteboard arrival routes the explicit single inspection through the core")
	_check(ui.night_seen == ["whiteboard"] and bool(ui.call("_night_complete")), "single inspected object synchronizes seen and delegates the exit predicate")


func _test_night_two_sequences_through_main(ui) -> void:
	var core = _open_night(ui, "2")
	if core == null or not ui.has_method(ARRIVAL_METHOD):
		return
	var intro_surface: Dictionary = ui.call("_night_intro_surface_lines")
	_check("02:43" in str(intro_surface.get("subtitle", "")) and "键盘" in str(intro_surface.get("opening", "")), "night two visibly begins with its late-hour office soundscape rather than hidden data")
	_check(str(ui.call("_night_object_progress_label", "window_desk")) == "0 / 3", "desk progress starts at zero completed steps")

	_arrive_at(ui, "window_desk")
	_check(str(core.call("object_phase", "window_desk")) == "inspect_screen_cup", "desk arrival routes screen-and-cup inspection through HiringMain")
	_check(str(ui.call("_night_object_progress_label", "window_desk")) == "1 / 3", "desk progress counts the completed inspection")
	_check(not ui.night_seen.has("window_desk"), "desk remains unseen after inspection alone")
	_arrive_at(ui, "window_desk")
	_check(str(core.call("object_phase", "window_desk")) == "cup_picked_up", "a second desk interaction routes the cup pick-up phase")
	_check(str(ui.call("_night_object_progress_label", "window_desk")) == "2 / 3", "desk progress counts the completed pick-up")
	_check(not ui.night_seen.has("window_desk"), "desk remains unseen while the cup is held")
	_arrive_at(ui, "window_desk")
	_check(str(core.call("object_phase", "window_desk")) == "cup_replaced", "a third desk interaction routes the exact two-centimetre replacement")
	_check(str(ui.call("_night_object_progress_label", "window_desk")) == "放回原处", "desk progress becomes complete only after replacement")
	_check(float(Dictionary(core.call("object_state", "window_desk")).get("distance_cm", 0.0)) == 2.0, "HiringMain supplies exactly two centimetres to the core")
	_check(ui.night_seen == ["window_desk"], "desk enters UI night_seen only at its terminal phase")

	core = _open_night(ui, "2")
	_arrive_at(ui, "meeting_room_d")
	_check(str(core.call("object_phase", "meeting_room_d")) == "projection_seen", "room D arrival routes entry, light-on, and projection through HiringMain")
	_check(not ui.night_seen.has("meeting_room_d"), "room D is not seen at entry")
	_arrive_at(ui, "meeting_room_d")
	_check(str(core.call("object_phase", "meeting_room_d")) == "door_closed", "a second room D interaction routes exit and door close")
	_arrive_at(ui, "meeting_room_d")
	_check(int(Dictionary(core.call("object_state", "meeting_room_d")).get("walked_steps", 0)) == 1, "a third room D interaction routes the first physical step away")
	_arrive_at(ui, "meeting_room_d")
	_check(int(Dictionary(core.call("object_state", "meeting_room_d")).get("walked_steps", 0)) == 2, "a fourth room D interaction routes the required second step away")
	_arrive_at(ui, "meeting_room_d")
	_check(str(core.call("object_phase", "meeting_room_d")) == "returned", "room D routes the return only after two steps")
	_check(not ui.night_seen.has("meeting_room_d"), "room D remains unseen until the light is switched off")
	_arrive_at(ui, "meeting_room_d")
	_check(str(core.call("object_phase", "meeting_room_d")) == "light_off", "the final room D interaction routes light-off")
	_check(ui.night_seen == ["meeting_room_d"], "room D enters UI night_seen only after its complete sequence")

	core = _open_night(ui, "2")
	_arrive_at(ui, "terminal")
	_check(str(core.call("object_phase", "terminal")) == "dialogue_inspected", "terminal arrival routes the authored unsent-dialogue inspection")
	_check(not ui.night_seen.has("terminal"), "terminal is unseen after dialogue inspection")
	_arrive_at(ui, "terminal")
	_check(str(core.call("object_phase", "terminal")) == "focused", "a second terminal interaction routes the separate focus phase")
	_check(bool(core.call("terminal_accepts_command")), "focused UI terminal exposes the core command-focus predicate")


func _test_authored_night_visual_states(ui) -> void:
	var core = _open_night(ui, "1")
	if core == null:
		return
	var whiteboard: Dictionary = ui.call("_night_visual_state", "whiteboard")
	_check(str(whiteboard.get("kind", "")) == "scarf_dog_whiteboard" and bool(whiteboard.get("scarf_dog", false)), "night-one whiteboard visual is explicitly the scarf-dog drawing")
	ui.model.debt = 0.0
	var clear_plant: Dictionary = ui.call("_night_visual_state", "pothos")
	ui.model.debt = 80.0
	var indebted_plant: Dictionary = ui.call("_night_visual_state", "pothos")
	_check(int(clear_plant.get("yellow_leaves", -1)) == 0 and int(clear_plant.get("green_leaves", -1)) == 9, "night-one clear-debt plant begins fully green")
	_check(int(indebted_plant.get("yellow_leaves", 0)) > int(clear_plant.get("yellow_leaves", 0)) and str(indebted_plant.get("stage", "")).begins_with("debt_tier_"), "night-one plant visual yellowing is derived from the hidden debt tier")

	core = _open_night(ui, "2")
	var night_two_plant: Dictionary = ui.call("_night_visual_state", "pothos")
	_check(int(night_two_plant.get("yellow_leaves", 0)) == 6 and int(night_two_plant.get("green_leaves", 0)) == 3, "night-two plant visual locks the authored two-thirds yellow / one-third green ratio")
	var desk_initial: Dictionary = ui.call("_night_visual_state", "window_desk")
	_check(not bool(desk_initial.get("cup_held", true)) and not bool(desk_initial.get("cup_replaced", true)), "night-two desk visual starts with the cup at its original position")
	_arrive_at(ui, "window_desk")
	_arrive_at(ui, "window_desk")
	var desk_held: Dictionary = ui.call("_night_visual_state", "window_desk")
	_check(bool(desk_held.get("cup_held", false)) and not bool(desk_held.get("cup_replaced", true)), "night-two desk visual removes the mug from the desk and shows it held at the midpoint")
	_arrive_at(ui, "window_desk")
	var desk_replaced: Dictionary = ui.call("_night_visual_state", "window_desk")
	_check(bool(desk_replaced.get("cup_replaced", false)) and int(desk_replaced.get("cup_offset_px", 0)) > 0 and is_equal_approx(float(desk_replaced.get("distance_cm", 0.0)), 2.0), "night-two desk visual exposes a shifted replacement tied to the exact two-centimetre state")

	core = _open_night(ui, "2")
	_arrive_at(ui, "meeting_room_d")
	var room_lit: Dictionary = ui.call("_night_visual_state", "meeting_room_d")
	_check(bool(room_lit.get("light_on", false)) and bool(room_lit.get("projector_blue", false)) and not bool(room_lit.get("door_closed", true)), "entering Room D lights the room and its blue projector with the door open")
	_arrive_at(ui, "meeting_room_d")
	var room_closed: Dictionary = ui.call("_night_visual_state", "meeting_room_d")
	_check(bool(room_closed.get("door_closed", false)) and bool(room_closed.get("projector_blue", false)), "Room D visual closes the door while retaining the light and blue projection")
	_arrive_at(ui, "meeting_room_d")
	_arrive_at(ui, "meeting_room_d")
	_arrive_at(ui, "meeting_room_d")
	_arrive_at(ui, "meeting_room_d")
	var room_dark: Dictionary = ui.call("_night_visual_state", "meeting_room_d")
	_check(not bool(room_dark.get("light_on", true)) and not bool(room_dark.get("projector_blue", true)) and int(room_dark.get("walked_steps", 0)) == 2, "Room D visual reaches its dark final state only after the two-step return sequence")
	ui.model.debt = 0.0


func _test_terminal_input_and_rm_rf_focus_gate(ui) -> void:
	var core = _open_night(ui, "2")
	if core == null or not ui.has_method(ARRIVAL_METHOD) or not ui.has_method(CTRL_C_METHOD):
		return
	_arrive_at(ui, "terminal")
	_send_night_key(ui, true, KEY_C)
	_check(str(core.call("object_phase", "terminal")) == "dialogue_inspected" and not ui.night_seen.has("terminal"), "unfocused Ctrl+C is rejected through HiringMain")
	_send_night_key(ui, false, KEY_C)
	_check(str(core.call("object_phase", "terminal")) == "dialogue_inspected" and not ui.night_seen.has("terminal"), "ordinary unfocused C is rejected through HiringMain")
	_arrive_at(ui, "terminal")
	_check(str(core.call("object_phase", "terminal")) == "focused", "terminal reaches focus before keyboard boundary checks")
	_send_night_key(ui, false, KEY_C)
	_check(str(core.call("object_phase", "terminal")) == "focused" and not ui.night_seen.has("terminal"), "ordinary C remains rejected while the terminal is focused")
	var result_lines_before: Array[String] = ui.result_lines.duplicate()
	var terminal_lines_before: Array[String] = ui.terminal_lines.duplicate()
	_send_night_key(ui, true, KEY_C)
	_check(str(core.call("object_phase", "terminal")) == "interrupted", "exact focused Ctrl+C completes through HiringMain")
	_check(ui.result_lines == result_lines_before and ui.terminal_lines == terminal_lines_before, "exact Ctrl+C appends no extra UI dialogue")
	_check(ui.night_seen == ["terminal"], "terminal synchronizes into UI night_seen only after exact Ctrl+C")

	# `rm -rf` is a different deliberate input path. It must be denied until the
	# authored terminal has been inspected and focused, then end immediately.
	core = _open_pending_director_night_two(ui)
	if core == null:
		return
	var transcript_before: int = ui.terminal_lines.size()
	ui.call("_submit_terminal_command", "rm -rf")
	_check(ui.screen == HiringMain.Screen.NIGHT_SHIFT and ui.current_ending_id != "rm_rf", "exact rm -rf is rejected outside terminal focus")
	_check(ui.terminal_lines.size() == transcript_before, "unfocused rm -rf is ignored without entering terminal command history")
	_arrive_at(ui, "terminal")
	_arrive_at(ui, "terminal")
	_check(bool(core.call("terminal_accepts_command")), "rm -rf fixture reaches exact terminal focus before submission")
	ui.call("_submit_terminal_command", "rm -rf")
	_check(ui.screen == HiringMain.Screen.ENDING and ui.current_ending_id == "rm_rf", "exact rm -rf fires immediately only from focused night terminal")
	_check(bool(ui.model.flags.get("rm_rf", false)), "focused rm -rf records the authoritative ending flag")


func _test_ui_save_round_trip() -> void:
	var ui = HiringMain.new()
	ui.save_path_override = SAVE_PATH
	ui.meta_path_override = META_PATH
	root.add_child(ui)
	await process_frame
	# The earlier rm-rf contract deliberately unlocks NG+. Keep this save fixture
	# on a fresh run so an unrelated second-time opening cannot outrank the night.
	ui.second_run_unlocked = false
	ui.name_edit.text = "Night State Save Contract"
	ui.call("_start_new_company")
	# The origin prologue and the garage are two authored scenes; step past both.
	for _scene in 3:
		if ui.current_event.is_empty():
			break
		ui.call("_close_event")
	var core = _open_night(ui, "2")
	if core != null and ui.has_method(ARRIVAL_METHOD):
		_arrive_at(ui, "window_desk")
		_arrive_at(ui, "window_desk")
	ui.night_focused_object_index = mini(1, maxi(0, ui.night_objects.size() - 1))
	ui.call("_save_game")

	var payload := _read_json_dictionary(SAVE_PATH)
	_check(payload.get("ui_night_interaction", null) is Dictionary, "UI save payload contains `ui_night_interaction`")
	var saved_core: Dictionary = Dictionary(payload.get("ui_night_interaction", {}))
	_check(str(saved_core.get("night_id", "")) == "2", "UI save records the canonical night id")
	_check(str(saved_core.get("active_object_id", "")) == "window_desk", "UI save records the active night object")
	_check(str(Dictionary(Dictionary(saved_core.get("object_states", {})).get("window_desk", {})).get("phase", "")) == "cup_picked_up", "UI save records the desk's exact midpoint phase")
	_check(int(payload.get("ui_night_focus_index", -1)) == ui.night_focused_object_index, "UI save records the keyboard/gamepad night focus index")
	_dispose_ui(ui)
	await process_frame

	var resumed = HiringMain.new()
	resumed.save_path_override = SAVE_PATH
	resumed.meta_path_override = META_PATH
	root.add_child(resumed)
	await process_frame
	resumed.call("_continue_game")
	_check(resumed.screen == HiringMain.Screen.NIGHT_SHIFT, "continue restores the pending night presentation")
	var resumed_core = _core_or_null(resumed)
	if resumed_core != null:
		_check(str(resumed_core.call("object_phase", "window_desk")) == "cup_picked_up", "continue restores the exact desk interaction phase")
		_check(str(resumed_core.get("active_object_id")) == "window_desk", "continue restores the active object needed to resume the sequence")
		_check(resumed.night_seen == Array(resumed_core.call("completed_object_ids")), "continue derives night_seen from restored terminal phases")
		_check(resumed.night_focused_object_index == int(payload.get("ui_night_focus_index", -1)), "continue restores the keyboard/gamepad night focus index")
	_dispose_ui(resumed)
	await process_frame


func _open_night(ui, night_id: String):
	var night: Dictionary = HiringContent.get_night_shift(night_id)
	night["_director_night_id"] = night_id
	ui.pending_night_id = night_id
	ui.call("_open_night_shift", night)
	var core = _core_or_null(ui)
	if core != null:
		_check(str(core.get("night_id")) == night_id, "opening night %s binds the matching core id" % night_id)
	return core


func _open_pending_director_night_two(ui):
	var started: Dictionary = ui.director.start_company("Focused Terminal Contract", false)
	ui.model = ui.director.model
	var opening_value = started.get("event", {})
	var opening: Dictionary = opening_value if opening_value is Dictionary else {}
	if not opening.is_empty():
		ui.director.resolve_event(opening, "")
	ui.model.chapter = 3
	ui.model.week_in_chapter = 14
	ui.model.total_week = 37
	ui.model.cash_weeks = 100.0
	ui.model.week_active = true
	ui.model.week_resolved = true
	ui.current_ending_id = ""
	ui.director.apply_declarative_after({"id": "night_ui_contract", "after": "night_shift:2"})
	var pending: Dictionary = ui.director.pending_night_shift()
	_check(not pending.is_empty(), "focused rm-rf fixture opens an authoritative pending night two")
	if pending.is_empty():
		return null
	ui.call("_open_night_shift", pending)
	return _core_or_null(ui)


func _arrive_at(ui, object_id: String) -> void:
	ui.result_lines.clear()
	ui.night_player_position = Vector2(640, 540)
	var center := _night_object_center(ui, object_id)
	ui.call("_handle_night_click", center)
	# A hotspot click only arms movement. Arrival is an explicit, separate step.
	ui.night_player_position = ui.night_player_target
	if ui.has_method(ARRIVAL_METHOD):
		ui.night_arrival_armed = false
		ui.call(ARRIVAL_METHOD)


func _send_night_key(ui, ctrl_pressed: bool, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.ctrl_pressed = ctrl_pressed
	event.keycode = keycode
	ui.call("_handle_night_key", event)


func _core_or_null(ui):
	if not _has_property(ui, CORE_PROPERTY):
		_fail("HiringMain has no `%s` property after opening a night" % CORE_PROPERTY)
		return null
	var core = ui.get(CORE_PROPERTY)
	if core == null:
		_fail("HiringMain leaves `%s` null after opening a night" % CORE_PROPERTY)
		return null
	for method_name in ["object_phase", "object_state", "completed_object_ids", "can_leave", "terminal_accepts_command", "to_save", "load_save"]:
		if not core.has_method(method_name):
			_fail("HiringMain night core is missing `%s()`" % method_name)
			return null
	return core


func _night_object_center(ui, object_id: String) -> Vector2:
	for object_value in ui.night_objects:
		var object: Dictionary = object_value
		if str(object.get("id", "")) == object_id:
			return Rect2(object.get("rect", Rect2())).get_center()
	_fail("night UI has no hotspot `%s`" % object_id)
	return Vector2.ZERO


func _has_property(object: Object, property_name: String) -> bool:
	for property_value in object.get_property_list():
		var property: Dictionary = property_value
		if str(property.get("name", "")) == property_name:
			return true
	return false


func _read_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var root_payload := Dictionary(parsed)
	if root_payload.has("schema_version") and root_payload.get("data") is Dictionary:
		return Dictionary(root_payload.get("data", {}))
	return root_payload


func _dispose_ui(ui) -> void:
	if ui.office_audio != null:
		for child in ui.office_audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
	ui.queue_free()


func _backup_and_clear_user_file(path: String) -> void:
	var backup := {"existed": false, "text": ""}
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		backup["existed"] = true
		backup["text"] = file.get_as_text() if file != null else ""
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_file_backups[path] = backup


func _restore_user_files() -> void:
	for path_value in _file_backups:
		var path := str(path_value)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		var backup: Dictionary = _file_backups[path]
		if not bool(backup.get("existed", false)):
			continue
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(str(backup.get("text", "")))


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func _fail(label: String) -> void:
	checks += 1
	failures.append(label)
