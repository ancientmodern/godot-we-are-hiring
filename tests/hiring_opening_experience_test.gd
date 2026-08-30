extends SceneTree

const HiringMain = preload("res://src/hiring_main.gd")

var failures: Array[String] = []
var checks := 0
var primary_save := "user://hiring_opening_experience_%d.json" % OS.get_process_id()
var primary_meta := "user://hiring_opening_experience_meta_%d.json" % OS.get_process_id()
var skip_save := "user://hiring_opening_skip_%d.json" % OS.get_process_id()
var skip_meta := "user://hiring_opening_skip_meta_%d.json" % OS.get_process_id()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_clear_paths([primary_save, primary_meta, skip_save, skip_meta])
	var ui = await _new_ui(primary_save, primary_meta)
	_test_authored_relationship_opening(ui)
	_dispose_ui(ui)
	await process_frame

	var resumed = await _new_ui(primary_save, primary_meta)
	resumed._continue_game()
	_check(resumed.screen == HiringMain.Screen.DASHBOARD, "the completed prologue resumes at the playable first-week dashboard")
	var resumed_relationship: Dictionary = resumed.model.memory.get("lin_relationship", {})
	_check(str(resumed_relationship.get("history", "")) == "university_exchange_314", "the university-exchange relationship seed survives save and resume")
	_check(int(resumed_relationship.get("chemistry", 0)) >= 3 and int(resumed_relationship.get("shared_values", 0)) >= 3, "the player's flirt and mission responses survive save and resume independently")
	_dispose_ui(resumed)
	await process_frame

	var skipped = await _new_ui(skip_save, skip_meta)
	_test_confirmed_skip_is_neutral(skipped)
	_dispose_ui(skipped)
	await process_frame
	_clear_paths([primary_save, primary_meta, skip_save, skip_meta])

	if failures.is_empty():
		print("HIRING_OPENING_EXPERIENCE_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_OPENING_EXPERIENCE_TEST_FAILURE: " + failure)
		quit(1)


func _test_authored_relationship_opening(ui) -> void:
	ui.name_edit.text = "提灯实验室"
	ui._start_new_company()
	_check(ui.screen == HiringMain.Screen.EVENT and ui._is_first_day_prologue(), "a first run enters the dedicated first-day conversation")
	_check(ui._first_day_phases().size() == 7, "the first day has seven resumable dramatic beats")
	_check(str(ui._first_day_phase().get("id", "")) == "arrival", "the player first meets Lin outside the broken glass door")
	var hydrated: Dictionary = ui._current_first_day_event({"id": "garage_opening", "body": ["legacy"], "_director_source": "fixed", "_director_key": "0:1"})
	_check(Array(hydrated.get("opening_phases", [])).size() == 7, "a legacy serialized opening hydrates to the current seven-beat schema")
	_check(str(hydrated.get("_director_source", "")) == "fixed" and str(hydrated.get("_director_key", "")) == "0:1", "opening hydration preserves Director provenance")

	_ready_phase(ui)
	ui._advance_first_day_prologue()
	_check(str(ui._first_day_phase().get("id", "")) == "name_question" and ui._first_day_choices().size() == 3, "the company-name beat offers three authored responses")
	_ready_phase(ui)
	ui._choose_first_day_option(2)
	_check(str(ui.model.memory.get("garage_name_choice", "")) == "warm", "the familiar flirt response is recorded as the player's choice")
	var name_reply := "\n".join(ui._first_day_phase_body())
	_check(name_reply.contains("人也还行") and name_reply.contains("314 教室") and name_reply.contains("路口"), "Lin's reply combines restrained flirt with their specific shared history")
	var relationship: Dictionary = ui.model.memory.get("lin_relationship", {})
	_check(int(relationship.get("warmth", 0)) == 3 and int(relationship.get("chemistry", 0)) == 3, "the flirt response changes warmth and chemistry without a visible affection meter")
	_check(not ui.model.public_state().has("lin_relationship"), "relationship dimensions remain outside the public management HUD")

	_ready_phase(ui)
	ui._advance_first_day_prologue()
	_check(str(ui._first_day_phase().get("id", "")) == "mission_question", "the shared past leads into a concrete founder-purpose question")
	_ready_phase(ui)
	ui._choose_first_day_option(0)
	relationship = ui.model.memory.get("lin_relationship", {})
	_check(str(ui.model.memory.get("lin_founder_contract", "")) == "listen", "the mission response becomes the cofounder contract memory")
	_check(int(relationship.get("shared_values", 0)) == 3 and int(relationship.get("warmth", 0)) == 4, "mission alignment is tracked separately from chemistry")

	_ready_phase(ui)
	ui._advance_first_day_prologue()
	_check(str(ui._first_day_phase().get("id", "")) == "power", "the conversation turns into a small physical problem the player can solve")
	_ready_phase(ui)
	ui._advance_first_day_prologue()
	_check(str(ui._first_day_phase().get("id", "")) == "handoff", "restoring power produces an audible, concrete payoff before the tutorial")
	_ready_phase(ui)
	ui._advance_first_day_prologue()
	_check(ui.screen == HiringMain.Screen.DASHBOARD and ui.current_event.is_empty(), "completing the final beat enters the playable first week")
	_check(bool(ui.model.memory.get("first_day_prologue_completed", false)) and bool(ui.model.flags.get("tutorial_actions_seen", false)), "prologue completion and tutorial handoff are persisted")
	_check(ui.director.resolved_fixed_count() == 1, "the interactive prologue resolves its fixed event exactly once")

	var train_index: int = ui.week_action_ids.find("train")
	_check(train_index >= 0, "the first playable week includes training")
	if train_index >= 0:
		ui._set_selected_action(train_index)
		ui._take_selected_action(false)
		_check(ui.screen == HiringMain.Screen.ACTION_RESULT, "the first management choice produces a concrete result receipt")
		_check("\n".join(ui.result_lines).contains("林越") and bool(ui.model.memory.get("first_week_lin_reaction_seen", false)), "the first action receives a specific Lin reaction instead of a generic stat toast")
		for _guard in 8:
			if ui.screen != HiringMain.Screen.ACTION_RESULT:
				break
			ui._close_result()


func _test_confirmed_skip_is_neutral(ui) -> void:
	ui._start_new_company()
	ui._request_first_day_skip()
	_check(ui.screen == HiringMain.Screen.EVENT and ui.opening_skip_confirm_pending, "the first skip gesture only arms a visible confirmation")
	_check(not bool(ui.model.flags.get("first_day_prologue_skipped", false)), "an accidental first skip gesture changes no story state")
	ui._request_first_day_skip()
	_check(ui.screen == HiringMain.Screen.DASHBOARD and bool(ui.model.flags.get("first_day_prologue_skipped", false)), "the repeated skip gesture exits safely to the first week")
	_check(str(ui.model.memory.get("garage_name_choice", "")) == "skipped" and str(ui.model.memory.get("garage_mission_choice", "")) == "unspoken", "skipping records unspoken answers instead of fabricating player choices")
	var relationship: Dictionary = ui.model.memory.get("lin_relationship", {})
	_check(int(relationship.get("trust", 0)) == 1 and int(relationship.get("chemistry", 0)) == 1 and int(relationship.get("shared_values", 0)) == 1, "skipping leaves every relationship dimension at its neutral seed")


func _new_ui(save_path: String, meta_path: String):
	var ui = HiringMain.new()
	ui.save_path_override = save_path
	ui.meta_path_override = meta_path
	root.add_child(ui)
	await process_frame
	return ui


func _ready_phase(ui) -> void:
	ui.event_page_elapsed = 999.0


func _dispose_ui(ui) -> void:
	if ui.office_audio != null:
		for child in ui.office_audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
	ui.queue_free()


func _clear_paths(paths: Array) -> void:
	for path_value in paths:
		var path := str(path_value)
		for candidate in [path, path + ".bak", path + ".tmp"]:
			if FileAccess.file_exists(candidate):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
