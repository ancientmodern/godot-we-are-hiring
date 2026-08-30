class_name NightInteractionState
extends RefCounted

## Saveable, presentation-agnostic interaction state for the two authored night
## shifts. The UI owns movement and prose; this class only accepts explicit
## interactions after the player has actually performed them.

const SAVE_VERSION := 1

const NIGHT_ONE_OBJECTS: Array[String] = [
	"corridor", "whiteboard", "fridge", "pothos", "mug",
]
const NIGHT_TWO_OBJECTS: Array[String] = [
	"pothos", "window_desk", "meeting_room_d", "terminal",
]
const NIGHT_ONE_SINGLE_INSPECT: Array[String] = [
	"whiteboard", "fridge", "pothos", "mug",
]

var night_id := ""
var active_object_id := ""
var definition_errors: Array[String] = []

var _content_id := ""
var _object_ids: Array[String] = []
var _object_states: Dictionary = {}
var _seen: Dictionary = {}


func _init(initial_night_id: String = "", content: Dictionary = {}) -> void:
	if not initial_night_id.is_empty():
		initialize(initial_night_id, content)


func initialize(initial_night_id: String, content: Dictionary = {}) -> void:
	night_id = _canonical_night_id(initial_night_id)
	active_object_id = ""
	definition_errors.clear()
	_content_id = str(content.get("id", ""))
	_object_ids = _canonical_object_ids(night_id)
	_object_states.clear()
	_seen.clear()

	if _object_ids.is_empty():
		definition_errors.append("unsupported_night_id")
		return

	var supplied_objects: Dictionary = Dictionary(content.get("objects", {}))
	if not supplied_objects.is_empty():
		for object_id in _object_ids:
			if not supplied_objects.has(object_id):
				definition_errors.append("missing_object:%s" % object_id)

	for object_id in _object_ids:
		_object_states[object_id] = _initial_state(object_id)


func is_valid() -> bool:
	return not night_id.is_empty() and definition_errors.is_empty()


func object_ids() -> Array[String]:
	return _object_ids.duplicate()


func activate_object(object_id: String) -> Dictionary:
	if not _object_states.has(object_id):
		return _rejected(object_id, "unknown_object")

	active_object_id = object_id
	var state: Dictionary = _state(object_id)
	var previous_phase := str(state.get("phase", ""))
	if night_id == "2" and object_id == "terminal" and previous_phase == "not_arrived":
		state["phase"] = "arrived"
		_object_states[object_id] = state
	return _accepted(object_id, previous_phase, str(state.get("phase", "")))


func advance_object(object_id: String, action: String, details: Dictionary = {}) -> Dictionary:
	if not _object_states.has(object_id):
		return _rejected(object_id, "unknown_object")
	if active_object_id != object_id:
		return _rejected(object_id, "object_not_active")
	if is_object_complete(object_id):
		return _rejected(object_id, "already_complete")

	if night_id == "1":
		if object_id == "corridor":
			return _advance_corridor(action)
		if NIGHT_ONE_SINGLE_INSPECT.has(object_id):
			return _advance_single_inspection(object_id, action)
	elif night_id == "2":
		match object_id:
			"pothos":
				return _advance_single_inspection(object_id, action)
			"window_desk":
				return _advance_window_desk(action, details)
			"meeting_room_d":
				return _advance_meeting_room_d(action, details)
			"terminal":
				return _advance_terminal(action)

	return _rejected(object_id, "unsupported_transition")


func handle_ctrl_c(ctrl_pressed: bool = true, key: String = "C") -> Dictionary:
	const OBJECT_ID := "terminal"
	if night_id != "2":
		return _rejected(OBJECT_ID, "terminal_not_available")
	if active_object_id != OBJECT_ID:
		return _rejected(OBJECT_ID, "terminal_not_active")
	var state := _state(OBJECT_ID)
	if bool(state.get("complete", false)):
		return _rejected(OBJECT_ID, "already_complete")
	if str(state.get("phase", "")) != "focused":
		return _rejected(OBJECT_ID, "terminal_not_focused")
	if not ctrl_pressed or key != "C":
		return _rejected(OBJECT_ID, "exact_ctrl_c_required")

	var previous_phase := str(state.get("phase", ""))
	state["phase"] = "interrupted"
	state["complete"] = true
	_object_states[OBJECT_ID] = state
	_mark_seen(OBJECT_ID)
	var result := _accepted(OBJECT_ID, previous_phase, "interrupted")
	# Ctrl+C deliberately produces no new dialogue: it interrupts nothing.
	result["emit_dialogue"] = false
	result["dialogue"] = []
	return result


func terminal_accepts_command() -> bool:
	if night_id != "2" or active_object_id != "terminal":
		return false
	var state := _state("terminal")
	return str(state.get("phase", "")) == "focused" and not bool(state.get("complete", false))


func object_phase(object_id: String) -> String:
	return str(_state(object_id).get("phase", ""))


func object_state(object_id: String) -> Dictionary:
	return _state(object_id).duplicate(true)


func is_object_complete(object_id: String) -> bool:
	return bool(_state(object_id).get("complete", false))


func completed_object_ids() -> Array[String]:
	var completed: Array[String] = []
	for object_id in _object_ids:
		if bool(_seen.get(object_id, false)) and is_object_complete(object_id):
			completed.append(object_id)
	return completed


func can_leave() -> bool:
	return not completed_object_ids().is_empty()


func to_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"night_id": night_id,
		"content_id": _content_id,
		"active_object_id": active_object_id,
		"object_states": _object_states.duplicate(true),
		"seen": completed_object_ids(),
	}


func load_save(payload: Dictionary) -> Dictionary:
	var saved_night_id := _canonical_night_id(str(payload.get("night_id", "")))
	if night_id.is_empty():
		initialize(saved_night_id)
	if saved_night_id != night_id or _object_ids.is_empty():
		return {"ok": false, "reason": "night_id_mismatch"}

	var saved_states: Dictionary = Dictionary(payload.get("object_states", {}))
	var restored_states: Dictionary = {}
	for object_id in _object_ids:
		var candidate: Dictionary = Dictionary(saved_states.get(object_id, {})).duplicate(true)
		if not _valid_saved_state(object_id, candidate):
			candidate = _initial_state(object_id)
		restored_states[object_id] = candidate
	_object_states = restored_states

	_seen.clear()
	for object_id in _object_ids:
		if is_object_complete(object_id):
			_seen[object_id] = true

	var saved_active := str(payload.get("active_object_id", ""))
	active_object_id = saved_active if _object_states.has(saved_active) else ""
	_content_id = str(payload.get("content_id", _content_id))
	return {"ok": true, "night_id": night_id, "completed": completed_object_ids()}


func _advance_corridor(action: String) -> Dictionary:
	const OBJECT_ID := "corridor"
	if action != "cross":
		return _rejected(OBJECT_ID, "crossing_required")
	var state := _state(OBJECT_ID)
	var previous_phase := str(state.get("phase", ""))
	var pass_count := int(state.get("pass_count", 0)) + 1
	state["pass_count"] = pass_count
	state["phase"] = "pass_%d" % pass_count
	if pass_count >= 3:
		state["phase"] = "three_passes_complete"
		state["complete"] = true
	_object_states[OBJECT_ID] = state
	if bool(state.get("complete", false)):
		_mark_seen(OBJECT_ID)
	return _accepted(OBJECT_ID, previous_phase, str(state.get("phase", "")))


func _advance_single_inspection(object_id: String, action: String) -> Dictionary:
	if action != "inspect":
		return _rejected(object_id, "inspection_required")
	var state := _state(object_id)
	var previous_phase := str(state.get("phase", ""))
	state["phase"] = "inspected"
	state["complete"] = true
	_object_states[object_id] = state
	_mark_seen(object_id)
	return _accepted(object_id, previous_phase, "inspected")


func _advance_window_desk(action: String, details: Dictionary) -> Dictionary:
	const OBJECT_ID := "window_desk"
	var state := _state(OBJECT_ID)
	var phase := str(state.get("phase", ""))
	match phase:
		"awaiting_inspection":
			if action != "inspect_screen_cup":
				return _rejected(OBJECT_ID, "inspect_screen_cup_required")
			state["phase"] = "inspect_screen_cup"
		"inspect_screen_cup":
			if action != "pick_up_cup":
				return _rejected(OBJECT_ID, "pick_up_cup_required")
			state["phase"] = "cup_picked_up"
		"cup_picked_up":
			if action != "replace_cup":
				return _rejected(OBJECT_ID, "replace_cup_required")
			var distance_value: Variant = details.get("distance_cm", null)
			if not (distance_value is int or distance_value is float) or float(distance_value) != 2.0:
				return _rejected(OBJECT_ID, "exact_two_cm_required")
			state["distance_cm"] = 2.0
			state["phase"] = "cup_replaced"
			state["complete"] = true
		_:
			return _rejected(OBJECT_ID, "invalid_desk_phase")

	_object_states[OBJECT_ID] = state
	if bool(state.get("complete", false)):
		_mark_seen(OBJECT_ID)
	return _accepted(OBJECT_ID, phase, str(state.get("phase", "")))


func _advance_meeting_room_d(action: String, details: Dictionary) -> Dictionary:
	const OBJECT_ID := "meeting_room_d"
	var state := _state(OBJECT_ID)
	var phase := str(state.get("phase", ""))
	if action == "return_to_room":
		if phase != "walked_away" or int(state.get("walked_steps", 0)) < 2:
			return _rejected(OBJECT_ID, "two_steps_required")
		state["phase"] = "returned"
		_object_states[OBJECT_ID] = state
		return _accepted(OBJECT_ID, phase, "returned")
	match phase:
		"outside":
			if action != "enter_room":
				return _rejected(OBJECT_ID, "enter_room_required")
			state["phase"] = "projection_seen"
			state["light_on"] = true
			state["door_closed"] = false
		"projection_seen":
			if action != "exit_and_close":
				return _rejected(OBJECT_ID, "exit_and_close_required")
			state["phase"] = "door_closed"
			state["door_closed"] = true
		"door_closed", "walked_away":
			if action != "walk_away":
				return _rejected(OBJECT_ID, "walk_away_required")
			var step_value: Variant = details.get("steps", null)
			if not (step_value is int) or int(step_value) <= 0:
				return _rejected(OBJECT_ID, "positive_steps_required")
			state["walked_steps"] = int(state.get("walked_steps", 0)) + int(step_value)
			state["phase"] = "walked_away"
		"returned":
			if action != "turn_light_off":
				return _rejected(OBJECT_ID, "turn_light_off_required")
			state["phase"] = "light_off"
			state["light_on"] = false
			state["complete"] = true
		_:
			return _rejected(OBJECT_ID, "invalid_room_phase")

	_object_states[OBJECT_ID] = state
	if bool(state.get("complete", false)):
		_mark_seen(OBJECT_ID)
	return _accepted(OBJECT_ID, phase, str(state.get("phase", "")))


func _advance_terminal(action: String) -> Dictionary:
	const OBJECT_ID := "terminal"
	var state := _state(OBJECT_ID)
	var phase := str(state.get("phase", ""))
	match phase:
		"not_arrived":
			return _rejected(OBJECT_ID, "activate_terminal_first")
		"arrived":
			if action != "inspect_unsent_dialogue":
				return _rejected(OBJECT_ID, "inspect_unsent_dialogue_required")
			state["phase"] = "dialogue_inspected"
		"dialogue_inspected":
			if action != "focus_terminal":
				return _rejected(OBJECT_ID, "focus_terminal_required")
			state["phase"] = "focused"
		"focused":
			return _rejected(OBJECT_ID, "exact_ctrl_c_required")
		_:
			return _rejected(OBJECT_ID, "invalid_terminal_phase")

	_object_states[OBJECT_ID] = state
	var result := _accepted(OBJECT_ID, phase, str(state.get("phase", "")))
	if str(state.get("phase", "")) == "dialogue_inspected":
		result["emit_dialogue"] = true
		result["dialogue_event"] = "unsent_dialogue"
	return result


func _initial_state(object_id: String) -> Dictionary:
	if night_id == "1":
		if object_id == "corridor":
			return {"phase": "awaiting_passes", "pass_count": 0, "complete": false}
		return {"phase": "awaiting_inspection", "complete": false}
	if night_id == "2":
		match object_id:
			"pothos":
				return {"phase": "awaiting_inspection", "complete": false}
			"window_desk":
				return {"phase": "awaiting_inspection", "distance_cm": 0.0, "complete": false}
			"meeting_room_d":
				return {
					"phase": "outside", "light_on": false, "door_closed": false,
					"walked_steps": 0, "complete": false,
				}
			"terminal":
				return {"phase": "not_arrived", "complete": false}
	return {"phase": "unsupported", "complete": false}


func _valid_saved_state(object_id: String, candidate: Dictionary) -> bool:
	if not candidate.has("phase") or not candidate.has("complete"):
		return false
	var phase := str(candidate.get("phase", ""))
	var complete := bool(candidate.get("complete", false))
	if night_id == "1":
		if object_id == "corridor":
			var count := int(candidate.get("pass_count", -1))
			return (
				(count == 0 and phase == "awaiting_passes" and not complete)
				or (count == 1 and phase == "pass_1" and not complete)
				or (count == 2 and phase == "pass_2" and not complete)
				or (count == 3 and phase == "three_passes_complete" and complete)
			)
		return (phase == "awaiting_inspection" and not complete) or (phase == "inspected" and complete)

	match object_id:
		"pothos":
			return (phase == "awaiting_inspection" and not complete) or (phase == "inspected" and complete)
		"window_desk":
			if phase == "awaiting_inspection" and not complete:
				return true
			if phase in ["inspect_screen_cup", "cup_picked_up"] and not complete:
				return true
			return phase == "cup_replaced" and complete and float(candidate.get("distance_cm", 0.0)) == 2.0
		"meeting_room_d":
			var steps := int(candidate.get("walked_steps", -1))
			if steps < 0:
				return false
			if phase == "outside" and not complete:
				return not bool(candidate.get("light_on", false)) and steps == 0
			if phase == "projection_seen" and not complete:
				return bool(candidate.get("light_on", false)) and not bool(candidate.get("door_closed", false)) and steps == 0
			if phase == "door_closed" and not complete:
				return bool(candidate.get("light_on", false)) and bool(candidate.get("door_closed", false)) and steps == 0
			if phase == "walked_away" and not complete:
				return bool(candidate.get("light_on", false)) and bool(candidate.get("door_closed", false)) and steps > 0
			if phase == "returned" and not complete:
				return bool(candidate.get("light_on", false)) and bool(candidate.get("door_closed", false)) and steps >= 2
			return phase == "light_off" and complete and not bool(candidate.get("light_on", true)) and steps >= 2
		"terminal":
			return (
				(phase in ["not_arrived", "arrived", "dialogue_inspected", "focused"] and not complete)
				or (phase == "interrupted" and complete)
			)
	return false


func _accepted(object_id: String, previous_phase: String, phase: String) -> Dictionary:
	return {
		"ok": true,
		"object_id": object_id,
		"from_phase": previous_phase,
		"phase": phase,
		"completed": is_object_complete(object_id),
		"seen": completed_object_ids(),
	}


func _rejected(object_id: String, reason: String) -> Dictionary:
	return {
		"ok": false,
		"object_id": object_id,
		"reason": reason,
		"phase": object_phase(object_id),
		"completed": is_object_complete(object_id),
		"seen": completed_object_ids(),
	}


func _mark_seen(object_id: String) -> void:
	if is_object_complete(object_id):
		_seen[object_id] = true


func _state(object_id: String) -> Dictionary:
	return Dictionary(_object_states.get(object_id, {}))


func _canonical_night_id(value: String) -> String:
	var normalized := value.strip_edges()
	if normalized == "1" or normalized.ends_with("_1"):
		return "1"
	if normalized == "2" or normalized.ends_with("_2"):
		return "2"
	return ""


func _canonical_object_ids(for_night_id: String) -> Array[String]:
	if for_night_id == "1":
		return NIGHT_ONE_OBJECTS.duplicate()
	if for_night_id == "2":
		return NIGHT_TWO_OBJECTS.duplicate()
	return []
