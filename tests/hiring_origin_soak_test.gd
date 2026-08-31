extends SceneTree

## A campaign per origin, driven through the real UI rather than the model, from
## the origin sheet to an ending. Every other test in this repo checks one
## surface; this one checks that the surfaces still compose — that no screen an
## origin can reach raises, and that all three origins can actually finish.

const HiringMain = preload("res://src/hiring_main.gd")
const HiringContent = preload("res://src/hiring_content.gd")

var failures: Array[String] = []
var checks := 0
var errors_seen := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for origin_index in HiringContent.ORIGIN_ORDER.size():
		var origin_id := str(HiringContent.ORIGIN_ORDER[origin_index])
		await _play_one(origin_id, origin_index)

	if failures.is_empty():
		print("HIRING_ORIGIN_SOAK_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_ORIGIN_SOAK_FAILURE: " + failure)
		quit(1)


func _play_one(origin_id: String, origin_index: int) -> void:
	var save_path := "user://origin_soak_%s_%d.json" % [origin_id, OS.get_process_id()]
	var meta_path := "user://origin_soak_meta_%s_%d.json" % [origin_id, OS.get_process_id()]
	for path in [save_path, meta_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var ui = HiringMain.new()
	ui.save_path_override = save_path
	ui.meta_path_override = meta_path
	ui.reduced_motion = true
	root.add_child(ui)
	await process_frame

	ui.selected_origin = origin_index
	ui.call("_confirm_origin_step")
	ui.name_edit.text = "Soak %s" % origin_id
	ui.call("_start_new_company")
	_check(str(ui.model.origin_id) == origin_id, "%s: the chosen origin reaches the model" % origin_id)
	_check(ui.call("_is_origin_prologue"), "%s: the campaign opens on its own prologue" % origin_id)

	# Walk both authored openings beat by beat, taking the first response wherever
	# one is offered, exactly as a player pressing Enter would.
	var opening_guard := 0
	while ui.screen == HiringMain.Screen.EVENT and ui.call("_is_first_day_prologue") and opening_guard < 40:
		opening_guard += 1
		ui.event_page_elapsed = 999.0
		var choices: Array = ui.call("_first_day_choices")
		if choices.is_empty():
			ui.call("_advance_first_day_prologue", false)
		else:
			ui.call("_choose_first_day_option", 0)
	_check(opening_guard < 40, "%s: the two openings terminate" % origin_id)
	if not ui.current_event.is_empty():
		ui.call("_close_event")
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "%s: the openings hand over a playable dashboard" % origin_id)

	# Now play weeks. Every week: read every workspace screen, act on the first
	# available card, then settle. The point is coverage, not skill.
	var weeks := 0
	var guard := 0
	var refused: Dictionary = {}
	while ui.screen != HiringMain.Screen.ENDING and guard < 2400:
		guard += 1
		if ui.screen == HiringMain.Screen.DASHBOARD:
			if weeks % 7 == 0:
				for target in [HiringMain.Screen.TEAM, HiringMain.Screen.TERMINAL, HiringMain.Screen.CALENDAR, HiringMain.Screen.ANNOUNCEMENTS, HiringMain.Screen.INTRANET]:
					ui.call("_navigate_to_screen", target)
					ui.queue_redraw()
					await process_frame
				ui.call("_navigate_to_screen", HiringMain.Screen.DASHBOARD)
			var acted := false
			# Play badly but not suicidally: raise when the runway gets short, so a
			# campaign actually reaches its later chapters instead of closing in
			# chapter one every time.
			var runway: int = int(ui.model.public_state().get("runway_weeks", 99))
			var order: Array[int] = []
			var expensive := ["buy_compute", "raise_salary", "team_building", "recruit_expert", "large_train"]
			for index in ui.week_action_ids.size():
				var candidate := str(ui.week_action_ids[index])
				if candidate == "fundraising":
					order.push_front(index)
				elif runway <= 6 and candidate in expensive:
					continue
				else:
					order.append(index)
			for index in order:
				var action_id := str(ui.week_action_ids[index])
				if ui.used_action_ids.has(action_id) or refused.has(action_id):
					continue
				# Alternate authorship so both routes are exercised, and ask about
				# the route actually being taken rather than about a different one.
				var use_ai := weeks % 3 == 2
				if not bool(ui.model.can_act(action_id, use_ai)):
					if not bool(ui.model.can_act(action_id, false)):
						continue
					use_ai = false
				ui.call("_set_selected_action", index)
				var before: int = ui.used_action_ids.size()
				ui.call("_take_selected_action", use_ai)
				if ui.used_action_ids.size() == before:
					# can_act() said yes and the director still said no. Record it
					# rather than spinning: a card the dashboard offers and then
					# refuses is a dead end a player can walk into too.
					refused[action_id] = int(ui.model.total_week)
					continue
				acted = true
				break
			if not acted:
				weeks += 1
				ui.call("_finish_week")
				if ui.end_week_confirm_pending:
					ui.call("_finish_week")
			ui.queue_redraw()
		elif ui.screen == HiringMain.Screen.ACTION_RESULT:
			ui.call("_close_result")
		elif ui.screen == HiringMain.Screen.EVENT:
			ui.event_page_elapsed = 999.0
			ui.queue_redraw()
			var event_choices: Array = ui.current_event.get("choices", [])
			if ui.call("_is_first_day_prologue"):
				ui.call("_advance_first_day_prologue", false)
			elif not event_choices.is_empty() and bool(ui.call("_event_choices_visible")):
				ui.call("_choose_event_option", 0)
			else:
				ui.call("_advance_event_page_or_close")
		elif ui.screen == HiringMain.Screen.NIGHT_SHIFT:
			ui.queue_redraw()
			if not ui.result_lines.is_empty():
				ui.result_lines.clear()
			elif bool(ui.call("_night_complete")):
				ui.call("_finish_night_shift")
			else:
				for object_index in ui.night_objects.size():
					ui.night_focused_object_index = object_index
					ui.call("_activate_focused_night_object")
					ui.night_player_position = ui.night_player_target
					ui.night_arrival_armed = false
					ui.call("_complete_night_object_arrival")
					break
		elif ui.screen == HiringMain.Screen.SIGNATURE:
			ui.queue_redraw()
			ui.call("_close_signature")
		elif ui.screen == HiringMain.Screen.BOARD_PRESENTATION:
			ui.queue_redraw()
			ui.call("_advance_board_presentation")
		elif ui.screen == HiringMain.Screen.LIVE_REPLAY:
			ui.screen_time = 999.0
			ui.queue_redraw()
			ui.call("_advance_live_replay")
		elif ui.screen == HiringMain.Screen.LAYOFF_SOCIAL:
			ui.screen_time = 999.0
			ui.queue_redraw()
			ui.call("_advance_layoff_social")
		elif ui.screen == HiringMain.Screen.TEAM or ui.screen == HiringMain.Screen.INTRANET:
			# Two screens may hold the player until an authored interaction is
			# finished. Both must have a way out; a missing one shows up here as
			# a hang rather than as a bug report from a player.
			ui.queue_redraw()
			if bool(ui.call("_window_interaction_required")):
				ui.call("_close_window_curtain")
			elif bool(ui.call("_origin_interaction_required")):
				ui.call("_select_intranet_document", "our_origin")
				ui.call("_mark_selected_document_read")
			else:
				ui.call("_navigate_to_screen", HiringMain.Screen.DASHBOARD)
		else:
			ui.queue_redraw()
		# Let the engine actually run the draw pass every so often, so the soak
		# exercises the real rendering path instead of only the state machine.
		if guard % 12 == 0:
			await process_frame

	if guard >= 2400:
		print("SOAK_STALL %s: screen=%d event=%s result_lines=%d week=%d pending_night=%s" % [origin_id, int(ui.screen), str(ui.current_event.get("id", "")), ui.result_lines.size(), int(ui.model.total_week), str(ui.pending_night_id)])
	_check(guard < 2400, "%s: the campaign reaches a conclusion without stalling (%d steps)" % [origin_id, guard])
	_check(ui.screen == HiringMain.Screen.ENDING, "%s: the campaign ends on an ending" % origin_id)
	_check(not str(ui.current_ending_id).is_empty(), "%s: the ending has an identity (%s)" % [origin_id, str(ui.current_ending_id)])
	var ending_body := "\n".join(PackedStringArray(ui.call("_render_ending_body", ui.current_ending.get("text", []))))
	_check(not ending_body.is_empty(), "%s: the ending renders text" % origin_id)
	_check(not ending_body.contains("{{"), "%s: every ending placeholder is interpolated" % origin_id)
	_check(int(ui.model.chapter) >= 1, "%s: the campaign gets past the garage before it ends (chapter %d)" % [origin_id, int(ui.model.chapter)])
	print("SOAK %s: weeks=%d chapter=%d ending=%s refused=%s" % [origin_id, weeks, int(ui.model.chapter), str(ui.current_ending_id), str(refused.keys())])

	ui.queue_free()
	await process_frame
	for path in [save_path, meta_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
