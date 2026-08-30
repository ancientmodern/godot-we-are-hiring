extends SceneTree

const NightInteractionState = preload("res://src/night_interaction_state.gd")
const HiringContent = preload("res://src/hiring_content.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_registry_and_empty_gate()
	_test_night_one_single_inspections()
	_test_night_one_corridor_three_real_passes()
	_test_night_two_plant()
	_test_night_two_window_desk_sequence()
	_test_night_two_room_d_sequence()
	_test_night_two_terminal_sequence()
	_test_save_resume_every_meaningful_midpoint()
	_test_save_reconstructs_seen_from_terminal_phases()

	if failures.is_empty():
		print("NIGHT_INTERACTION_STATE_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("NIGHT_INTERACTION_STATE_TEST_FAILURE: " + failure)
		quit(1)


func _test_registry_and_empty_gate() -> void:
	var night_one = _new_state("1")
	_check(night_one.is_valid(), "night one accepts the authored content registry")
	_check(night_one.object_ids() == ["corridor", "whiteboard", "fridge", "pothos", "mug"], "night one exposes exactly its five authored interaction objects")
	_check(night_one.completed_object_ids().is_empty() and not night_one.can_leave(), "an untouched night one cannot be left")

	var night_two = _new_state("2")
	_check(night_two.is_valid(), "night two accepts the authored content registry")
	_check(night_two.object_ids() == ["pothos", "window_desk", "meeting_room_d", "terminal"], "night two state core exposes the four required authored sequences")
	_check(not night_two.object_ids().has("elevator"), "the legacy extra elevator hotspot is not mistaken for a required night-two sequence")
	_check(night_two.completed_object_ids().is_empty() and not night_two.can_leave(), "an untouched night two cannot be left")

	var unsupported = NightInteractionState.new("night_shift_3", {})
	_check(not unsupported.is_valid() and unsupported.object_ids().is_empty(), "unsupported night ids fail closed")


func _test_night_one_single_inspections() -> void:
	for object_id in ["whiteboard", "fridge", "pothos", "mug"]:
		var state = _new_state("1")
		var activation: Dictionary = state.activate_object(object_id)
		_check(bool(activation.get("ok", false)) and not state.can_leave(), "%s activation alone is not an inspection" % object_id)
		var wrong: Dictionary = state.advance_object(object_id, "cross")
		_check(not bool(wrong.get("ok", false)) and state.completed_object_ids().is_empty(), "%s rejects a non-inspection action" % object_id)
		var inspection: Dictionary = state.advance_object(object_id, "inspect")
		_check(bool(inspection.get("ok", false)) and bool(inspection.get("completed", false)), "%s completes on one explicit inspection" % object_id)
		_check(state.completed_object_ids() == [object_id] and state.can_leave(), "%s is seen only after its terminal inspection phase" % object_id)
		var duplicate: Dictionary = state.advance_object(object_id, "inspect")
		_check(not bool(duplicate.get("ok", false)) and str(duplicate.get("reason", "")) == "already_complete", "%s cannot be completed twice" % object_id)


func _test_night_one_corridor_three_real_passes() -> void:
	var state = _new_state("1")
	_check(not bool(state.advance_object("corridor", "cross").get("ok", false)), "the corridor cannot advance before the player activates it")
	state.activate_object("corridor")
	_check(not bool(state.advance_object("corridor", "inspect").get("ok", false)), "reading prose cannot substitute for a corridor crossing")
	for expected_pass in [1, 2]:
		var crossing: Dictionary = state.advance_object("corridor", "cross", {"crossings": 99})
		_check(bool(crossing.get("ok", false)) and int(state.object_state("corridor").get("pass_count", 0)) == expected_pass, "corridor call %d records exactly one physical pass" % expected_pass)
		_check(not state.is_object_complete("corridor") and not state.can_leave(), "corridor remains incomplete after pass %d" % expected_pass)
	var third: Dictionary = state.advance_object("corridor", "cross")
	_check(bool(third.get("ok", false)) and state.object_phase("corridor") == "three_passes_complete", "the third distinct crossing reaches the corridor terminal phase")
	_check(state.completed_object_ids() == ["corridor"] and state.can_leave(), "only the third corridor crossing marks it seen and opens the exit")
	_check(not bool(state.advance_object("corridor", "cross").get("ok", false)), "a completed corridor does not count a fourth pass")


func _test_night_two_plant() -> void:
	var state = _new_state("2")
	state.activate_object("pothos")
	_check(not state.can_leave(), "night-two plant activation is not an inspection")
	var result: Dictionary = state.advance_object("pothos", "inspect")
	_check(bool(result.get("ok", false)) and state.completed_object_ids() == ["pothos"] and state.can_leave(), "night-two plant completes with one explicit inspection")


func _test_night_two_window_desk_sequence() -> void:
	var state = _new_state("2")
	state.activate_object("window_desk")
	_check(not bool(state.advance_object("window_desk", "pick_up_cup").get("ok", false)), "desk cannot skip the screen-and-cup inspection")
	_check(state.object_phase("window_desk") == "awaiting_inspection" and not state.can_leave(), "rejected desk skip leaves the state untouched")

	var inspected: Dictionary = state.advance_object("window_desk", "inspect_screen_cup")
	_check(bool(inspected.get("ok", false)) and state.object_phase("window_desk") == "inspect_screen_cup", "desk first records the screen and cup inspection")
	_check(not bool(state.advance_object("window_desk", "replace_cup", {"distance_cm": 2}).get("ok", false)), "desk cannot replace a cup before picking it up")
	var picked_up: Dictionary = state.advance_object("window_desk", "pick_up_cup")
	_check(bool(picked_up.get("ok", false)) and state.object_phase("window_desk") == "cup_picked_up", "desk next records the cup being picked up")

	for wrong_distance in [1, 3, 2.01, "2"]:
		var wrong: Dictionary = state.advance_object("window_desk", "replace_cup", {"distance_cm": wrong_distance})
		_check(not bool(wrong.get("ok", false)) and state.object_phase("window_desk") == "cup_picked_up", "desk rejects non-exact two-centimetre replacement %s" % str(wrong_distance))
	var replaced: Dictionary = state.advance_object("window_desk", "replace_cup", {"distance_cm": 2})
	_check(bool(replaced.get("ok", false)) and state.object_phase("window_desk") == "cup_replaced", "exactly two centimetres reaches the desk terminal phase")
	_check(float(state.object_state("window_desk").get("distance_cm", 0.0)) == 2.0 and state.completed_object_ids() == ["window_desk"], "desk persists the exact displacement and only then becomes seen")


func _test_night_two_room_d_sequence() -> void:
	var state = _new_state("2")
	state.activate_object("meeting_room_d")
	_check(not bool(state.advance_object("meeting_room_d", "exit_and_close").get("ok", false)), "room D cannot be exited before it is entered")
	var entered: Dictionary = state.advance_object("meeting_room_d", "enter_room")
	_check(bool(entered.get("ok", false)) and state.object_phase("meeting_room_d") == "projection_seen", "entering room D turns on the light and reveals the projection")
	_check(bool(state.object_state("meeting_room_d").get("light_on", false)), "room D records its light as on after entry")
	_check(not bool(state.advance_object("meeting_room_d", "turn_light_off").get("ok", false)), "room D light cannot be switched off by skipping the exit and return")

	var closed: Dictionary = state.advance_object("meeting_room_d", "exit_and_close")
	_check(bool(closed.get("ok", false)) and state.object_phase("meeting_room_d") == "door_closed", "room D next requires exiting and closing its door")
	_check(not bool(state.advance_object("meeting_room_d", "return_to_room").get("ok", false)), "room D cannot be revisited before walking away")
	_check(not bool(state.advance_object("meeting_room_d", "walk_away", {"steps": 0}).get("ok", false)), "room D rejects a zero-step movement report")
	state.advance_object("meeting_room_d", "walk_away", {"steps": 1})
	_check(state.object_phase("meeting_room_d") == "walked_away" and int(state.object_state("meeting_room_d").get("walked_steps", 0)) == 1, "room D records the first real step away")
	_check(not bool(state.advance_object("meeting_room_d", "return_to_room").get("ok", false)), "one step is insufficient for room D's return")
	state.advance_object("meeting_room_d", "walk_away", {"steps": 1})
	_check(int(state.object_state("meeting_room_d").get("walked_steps", 0)) == 2, "room D accumulates the required second real step")
	var returned: Dictionary = state.advance_object("meeting_room_d", "return_to_room")
	_check(bool(returned.get("ok", false)) and state.object_phase("meeting_room_d") == "returned", "room D allows the return only after at least two steps")
	_check(not state.can_leave() and not state.is_object_complete("meeting_room_d"), "returning does not complete room D before the light is off")
	var light_off: Dictionary = state.advance_object("meeting_room_d", "turn_light_off")
	_check(bool(light_off.get("ok", false)) and state.object_phase("meeting_room_d") == "light_off", "switching off the light is room D's terminal phase")
	_check(not bool(state.object_state("meeting_room_d").get("light_on", true)) and state.completed_object_ids() == ["meeting_room_d"], "room D is seen only after the light-off completion")


func _test_night_two_terminal_sequence() -> void:
	var state = _new_state("2")
	_check(not bool(state.handle_ctrl_c().get("ok", false)), "Ctrl+C is rejected before the terminal is active")
	var arrived: Dictionary = state.activate_object("terminal")
	_check(bool(arrived.get("ok", false)) and state.object_phase("terminal") == "arrived", "terminal activation is the explicit arrival transition")
	_check(not bool(state.handle_ctrl_c().get("ok", false)), "focused Ctrl+C is rejected before the unsent dialogue is inspected")
	_check(not bool(state.handle_ctrl_c(false, "C").get("ok", false)), "ordinary C is rejected at the unfocused terminal")
	_check(not bool(state.advance_object("terminal", "focus_terminal").get("ok", false)), "terminal focus cannot skip the unsent dialogue")

	var inspected: Dictionary = state.advance_object("terminal", "inspect_unsent_dialogue")
	_check(bool(inspected.get("emit_dialogue", false)) and str(inspected.get("dialogue_event", "")) == "unsent_dialogue", "the inspection transition alone emits the authored unsent dialogue")
	_check(not state.can_leave() and state.completed_object_ids().is_empty(), "reading terminal dialogue is not yet completion")
	var focused: Dictionary = state.advance_object("terminal", "focus_terminal")
	_check(bool(focused.get("ok", false)) and state.terminal_accepts_command(), "terminal accepts input only after its separate focus transition")
	_check(not bool(state.handle_ctrl_c(false, "C").get("ok", false)), "ordinary C is rejected even while focused")
	_check(not bool(state.handle_ctrl_c(true, "X").get("ok", false)), "Ctrl with a different key is rejected while focused")
	_check(not bool(state.advance_object("terminal", "ctrl_c").get("ok", false)), "a string action cannot impersonate the exact Ctrl+C input")
	var interrupted: Dictionary = state.handle_ctrl_c()
	_check(bool(interrupted.get("ok", false)) and state.object_phase("terminal") == "interrupted", "exact focused Ctrl+C reaches the terminal phase")
	_check(not bool(interrupted.get("emit_dialogue", true)) and Array(interrupted.get("dialogue", ["unexpected"])).is_empty(), "Ctrl+C completion emits no dialogue")
	_check(state.completed_object_ids() == ["terminal"] and state.can_leave(), "terminal becomes seen only after exact Ctrl+C")
	_check(not state.terminal_accepts_command(), "an interrupted terminal no longer advertises command focus")


func _test_save_resume_every_meaningful_midpoint() -> void:
	var corridor = _new_state("1")
	corridor.activate_object("corridor")
	corridor = _round_trip(corridor, "night one corridor activation")
	for pass_number in [1, 2, 3]:
		corridor.advance_object("corridor", "cross")
		corridor = _round_trip(corridor, "night one corridor pass %d" % pass_number)

	for object_id in ["whiteboard", "fridge", "pothos", "mug"]:
		var single = _new_state("1")
		single.activate_object(object_id)
		single = _round_trip(single, "night one %s activation" % object_id)
		single.advance_object(object_id, "inspect")
		_round_trip(single, "night one %s terminal inspection" % object_id)

	var plant = _new_state("2")
	plant.activate_object("pothos")
	plant = _round_trip(plant, "night two plant activation")
	plant.advance_object("pothos", "inspect")
	_round_trip(plant, "night two plant terminal inspection")

	var desk = _new_state("2")
	desk.activate_object("window_desk")
	desk = _round_trip(desk, "desk activation")
	desk.advance_object("window_desk", "inspect_screen_cup")
	desk = _round_trip(desk, "desk inspected screen and cup")
	desk.advance_object("window_desk", "pick_up_cup")
	desk = _round_trip(desk, "desk cup picked up")
	desk.advance_object("window_desk", "replace_cup", {"distance_cm": 2})
	desk = _round_trip(desk, "desk cup replaced two centimetres")
	_check(desk.completed_object_ids() == ["window_desk"], "desk remains completable after every save midpoint")

	var room = _new_state("2")
	room.activate_object("meeting_room_d")
	room = _round_trip(room, "room D activation")
	room.advance_object("meeting_room_d", "enter_room")
	room = _round_trip(room, "room D projection")
	room.advance_object("meeting_room_d", "exit_and_close")
	room = _round_trip(room, "room D door closed")
	room.advance_object("meeting_room_d", "walk_away", {"steps": 1})
	room = _round_trip(room, "room D one step away")
	room.advance_object("meeting_room_d", "walk_away", {"steps": 1})
	room = _round_trip(room, "room D two steps away")
	room.advance_object("meeting_room_d", "return_to_room")
	room = _round_trip(room, "room D returned")
	room.advance_object("meeting_room_d", "turn_light_off")
	room = _round_trip(room, "room D light off")
	_check(room.completed_object_ids() == ["meeting_room_d"], "room D remains completable after every save midpoint")

	var terminal = _new_state("2")
	terminal.activate_object("terminal")
	terminal = _round_trip(terminal, "terminal arrived")
	terminal.advance_object("terminal", "inspect_unsent_dialogue")
	terminal = _round_trip(terminal, "terminal dialogue inspected")
	terminal.advance_object("terminal", "focus_terminal")
	terminal = _round_trip(terminal, "terminal focused")
	terminal.handle_ctrl_c()
	terminal = _round_trip(terminal, "terminal interrupted")
	_check(terminal.completed_object_ids() == ["terminal"], "terminal remains completable after every save midpoint")


func _test_save_reconstructs_seen_from_terminal_phases() -> void:
	var source = _new_state("1")
	source.activate_object("corridor")
	source.advance_object("corridor", "cross")
	var tampered: Dictionary = source.to_save()
	tampered["seen"] = ["corridor", "mug"]
	var restored = _new_state("1")
	var loaded: Dictionary = restored.load_save(tampered)
	_check(bool(loaded.get("ok", false)) and restored.completed_object_ids().is_empty(), "load ignores forged seen ids when terminal phases are incomplete")
	_check(not restored.can_leave(), "forged save metadata cannot open the night exit")

	var corrupted: Dictionary = source.to_save()
	var states: Dictionary = Dictionary(corrupted["object_states"])
	states["corridor"] = {"phase": "three_passes_complete", "pass_count": 1, "complete": true}
	corrupted["object_states"] = states
	restored = _new_state("1")
	restored.load_save(corrupted)
	_check(restored.object_phase("corridor") == "awaiting_passes" and not restored.can_leave(), "internally inconsistent saved phases reset instead of skipping interactions")

	var wrong_night = _new_state("2")
	_check(not bool(wrong_night.load_save(source.to_save()).get("ok", false)), "a night-one save cannot be loaded into night two")


func _new_state(night_id: String):
	return NightInteractionState.new(night_id, HiringContent.get_night_shift(night_id))


func _round_trip(source, label: String):
	var snapshot: Dictionary = source.to_save()
	var restored = _new_state(str(snapshot.get("night_id", "")))
	var result: Dictionary = restored.load_save(snapshot)
	_check(bool(result.get("ok", false)), "%s save loads successfully" % label)
	_check(restored.to_save() == snapshot, "%s preserves every state field across save/resume" % label)
	_check(restored.completed_object_ids() == source.completed_object_ids() and restored.can_leave() == source.can_leave(), "%s preserves completion predicates across save/resume" % label)
	return restored


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
