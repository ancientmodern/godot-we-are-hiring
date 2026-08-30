extends SceneTree

const HiringMain = preload("res://src/hiring_main.gd")
const HiringContent = preload("res://src/hiring_content.gd")
const HiringModel = preload("res://src/hiring_model.gd")
const CampaignDirector = preload("res://src/hiring_director.gd")

var SAVE_PATH := "user://we_are_hiring_ui_flow_test_save_%d.json" % OS.get_process_id()
var META_PATH := "user://we_are_hiring_ui_flow_test_meta_%d.json" % OS.get_process_id()
var FINALE_SAVE_PATH := "user://we_are_hiring_ui_finale_test_save_%d.json" % OS.get_process_id()
var FINALE_META_PATH := "user://we_are_hiring_ui_finale_test_meta_%d.json" % OS.get_process_id()
const ENDING_IDS: Array[String] = [
	"acquihire", "drift", "independent", "lights_out", "rm_rf", "second_time", "successor",
]

var failures: Array[String] = []
var checks := 0
var _file_backups: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_backup_and_clear_user_file(SAVE_PATH)
	_backup_and_clear_user_file(META_PATH)
	_backup_and_clear_user_file(FINALE_SAVE_PATH)
	_backup_and_clear_user_file(FINALE_META_PATH)

	var ui = HiringMain.new()
	ui.save_path_override = SAVE_PATH
	ui.meta_path_override = META_PATH
	root.add_child(ui)
	await process_frame
	_test_new_company_opening_action_and_save(ui)

	_dispose_ui(ui)
	await process_frame

	var resumed_ui = HiringMain.new()
	resumed_ui.save_path_override = SAVE_PATH
	resumed_ui.meta_path_override = META_PATH
	root.add_child(resumed_ui)
	await process_frame
	_test_continue_without_duplicate_event(resumed_ui)
	_test_week_two_closing_event(resumed_ui)
	_test_night_shift_and_advance_ui_state(resumed_ui)
	_test_stage_three_option_voice_surface(resumed_ui)
	_test_elevator_button_visual_contract(resumed_ui)
	_test_lin_scene_two_silence_timeline(resumed_ui)
	_test_action_pool_surface_contract(resumed_ui)
	_test_intranet_review_action_contract(resumed_ui)
	_test_seed_week_five_natural_debt_balance(resumed_ui)
	_test_four_choice_modal_layout(resumed_ui)
	_test_finale_window_curtain_state_machine(resumed_ui)
	_test_origin_article_state_machine(resumed_ui)
	_test_board_ai_presentation_state_machine(resumed_ui)
	_test_live_replay_and_layoff_social_state_machines(resumed_ui)
	_test_finale_memory_callback_speaker(resumed_ui)
	_test_ending_company_and_employee_rendering(resumed_ui)
	_test_all_ending_playback_surfaces(resumed_ui)
	_test_compute_unavailable_copy(resumed_ui)
	_test_action_preview_settlement_parity(resumed_ui)
	_test_atomic_ui_design_contract(resumed_ui)
	_test_employee_desk_and_window_population_contract(resumed_ui)
	_test_stage_one_ai_response_and_action_ceiling(resumed_ui)
	_test_event_choice_cash_exhaustion_is_immediate(resumed_ui)
	_test_action_cash_exhaustion_is_immediate(resumed_ui)
	await _test_quiet_chronology_surfaces(resumed_ui)
	await _test_second_time_and_ending_resume()

	_dispose_ui(resumed_ui)
	await process_frame
	_restore_user_files()

	if failures.is_empty():
		print("HIRING_UI_FLOW_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_UI_FLOW_TEST_FAILURE: " + failure)
		quit(1)


func _test_new_company_opening_action_and_save(ui) -> void:
	_check(ui.director != null and ui.model == ui.director.model, "UI owns the CampaignDirector model after ready")
	_check(ui.screen == HiringMain.Screen.ONBOARDING, "UI starts on onboarding")
	var storage_args := PackedStringArray([
		"--hiring-save-path=user://candidate_smoke_save.json",
		"--hiring-meta-path=user://candidate_smoke_meta.json",
		"--hiring-smoke-test",
	])
	var parsed_storage: Dictionary = ui._storage_overrides_from_args(storage_args)
	_check(str(parsed_storage.get("save", "")) == "user://candidate_smoke_save.json" and str(parsed_storage.get("meta", "")) == "user://candidate_smoke_meta.json" and bool(parsed_storage.get("smoke", false)), "main-scene smoke arguments provide isolated user storage and an explicit PASS contract before ready loads meta")
	_check(ui._smoke_storage_failure_reason(str(parsed_storage.get("save", "")), str(parsed_storage.get("meta", ""))).is_empty(), "GUID-style smoke paths normalize to two distinct non-production user files")
	var rejected_storage: Dictionary = ui._storage_overrides_from_args(PackedStringArray(["--hiring-save-path=res://project.godot", "--hiring-meta-path=user://../escape.json"]))
	_check(rejected_storage.is_empty(), "command-line storage overrides reject project files and traversal paths")
	var alias_storage: Dictionary = ui._storage_overrides_from_args(PackedStringArray([
		"--hiring-save-path=user://candidate_smoke_save.json",
		"--hiring-meta-path=user://./we_are_hiring_meta.json",
		"--hiring-smoke-test",
	]))
	_check(alias_storage.has("save") and not alias_storage.has("meta") and bool(alias_storage.get("smoke", false)), "command-line storage overrides reject dot-segment aliases before any file read")
	_check(not ui._smoke_storage_failure_reason(str(alias_storage.get("save", "")), str(alias_storage.get("meta", ""))).is_empty(), "smoke mode fails closed when either isolated path is rejected")
	_check(not ui._smoke_storage_failure_reason("user://candidate_smoke_save.json", "user://we_are_hiring_meta.json").is_empty(), "smoke mode rejects the direct canonical meta path after globalized comparison")
	_check(not ui._smoke_storage_failure_reason("user://we_are_hiring_save.json", "user://candidate_smoke_meta.json").is_empty(), "smoke mode rejects the direct canonical campaign path after globalized comparison")
	_check(not ui._smoke_storage_failure_reason("user://candidate_smoke_save.json", "user://WE_ARE_HIRING_META.JSON").is_empty(), "smoke mode rejects case aliases of canonical Windows storage")
	_check(not ui._smoke_storage_failure_reason("user://candidate_smoke_shared.json", "user://candidate_smoke_shared.json").is_empty(), "smoke mode requires distinct campaign and meta files")
	ui.second_run_unlocked = false
	ui.name_edit.text = "UI Contract Labs"
	ui._start_new_company()

	_check(ui.model.company_name == "UI Contract Labs", "new-company form initializes the director with the entered name")
	_check(ui.screen == HiringMain.Screen.EVENT, "new company opens the authored garage event")
	_check(str(ui.current_event.get("id", "")) == "garage_opening", "UI receives garage_opening from CampaignDirector")
	_check(FileAccess.file_exists(SAVE_PATH), "opening UI state creates a save")
	var opening_save := _read_json_dictionary(SAVE_PATH)
	_check(int(opening_save.get("director_save_version", -1)) >= 1, "UI save uses the director payload schema")
	_check(opening_save.get("model", null) is Dictionary, "UI save nests authoritative model state under model")
	_check(str(Dictionary(opening_save.get("model", {})).get("company_name", "")) == "UI Contract Labs", "nested director model retains the company name")
	_check(str(Dictionary(opening_save.get("pending_event", {})).get("id", "")) == "garage_opening", "director pending event and UI event are saved together")

	ui._close_event()
	_check(ui.screen == HiringMain.Screen.DASHBOARD and ui.current_event.is_empty(), "closing the choice-free opening returns to dashboard")
	_check(ui.director.resolved_fixed_count() == 1, "opening resolves exactly one fixed director key")
	_check(bool(ui.model.flags.get("seen_garage_opening", false)), "UI event close commits the opening into the director model")

	_perform_ui_action(ui, "train", false)
	_check(ui.model.performed_actions.has("train"), "UI action is executed through CampaignDirector")
	_check(ui.used_action_ids.has("train"), "UI mirrors the performed action for card state")
	_close_all_result_pages(ui)
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "closing an action result returns to dashboard")
	ui._save_game()

	var action_save := _read_json_dictionary(SAVE_PATH)
	var saved_model: Dictionary = action_save.get("model", {})
	_check(Array(saved_model.get("performed_actions", [])).has("train"), "director model action state is persisted by UI save")
	_check(Array(action_save.get("ui_used_actions", [])).has("train"), "UI card state is persisted beside director state")
	_check(Array(action_save.get("ui_week_actions", [])) == ui.week_action_ids and int(action_save.get("ui_action_pool_week", -1)) == int(ui.model.total_week), "the exact weekly card offer is persisted with its week identity")
	_check(Dictionary(action_save.get("pending_event", {})).is_empty(), "resolved opening is not left pending in the save")


func _test_continue_without_duplicate_event(ui) -> void:
	ui._continue_game()
	_check(ui.model == ui.director.model, "continue rebinds UI to the resumed director model")
	_check(ui.model.company_name == "UI Contract Labs", "continue restores the saved company")
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "continue restores the playable dashboard")
	_check(ui.current_event.is_empty(), "continue does not replay a resolved opening modal")
	_check(ui.director.resolved_fixed_count() == 1, "continue retains resolved fixed-event identity")
	_check(bool(ui.model.flags.get("seen_garage_opening", false)), "continue retains the opening's seen flag")
	_check(ui.model.performed_actions.has("train") and ui.used_action_ids.has("train"), "continue restores authoritative and presentation action state")
	var resumed_payload: Dictionary = ui.director.save_payload()
	_check(int(Dictionary(resumed_payload.get("seen_event_ids", {})).get("garage_opening", -1)) == 1, "resumed director records garage_opening only in its original week")


func _test_week_two_closing_event(ui) -> void:
	ui.model.cash_weeks = 100.0
	ui._finish_week()
	_check(ui.screen == HiringMain.Screen.DASHBOARD and ui.end_week_confirm_pending, "first unused-attention settlement attempt asks for explicit confirmation")
	ui._finish_week()
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT and ui.pending_week_advance, "week-one UI settlement enters the advance result state")
	_close_all_result_pages(ui)
	_check(ui.model.chapter == 0 and ui.model.week_in_chapter == 2, "closing settlement advances UI to chapter zero week two")
	_check(ui.screen == HiringMain.Screen.DASHBOARD and ui.current_event.is_empty(), "week two starts on dashboard without an early first-sentence modal")
	_check(ui.director.current_fixed_event().is_empty(), "director closing beat remains hidden during UI action phase")

	for action_id in ["train", "clean_data", "do_nothing"]:
		_perform_ui_action(ui, action_id, false)
		_close_all_result_pages(ui)
	_check(ui.model.performed_actions.size() == 3, "UI completes all three week-two actions before settlement")

	var cash_before: float = float(ui.model.cash_weeks)
	var narrative_before: float = float(ui.model.narrative)
	ui._finish_week()
	_check(ui.screen == HiringMain.Screen.EVENT, "first week-two settlement attempt opens the deferred event")
	_check(str(ui.current_event.get("id", "")) == "model_first_sentence", "UI displays model_first_sentence at the action/settlement boundary")
	_check(ui.model.week_active and not ui.model.week_resolved, "deferred-event UI leaves week two unsettled")
	_check(is_equal_approx(ui.model.cash_weeks, cash_before) and is_equal_approx(ui.model.narrative, narrative_before), "deferred-event UI applies no burn or narrative decay")

	ui._close_event()
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT and ui.current_event.is_empty(), "closing model_first_sentence automatically resumes the interrupted settlement")
	_check(bool(ui.model.memory.get("model_first_truth", false)), "UI commits the model-first-truth memory through the director")
	_check(ui.pending_week_advance and ui.model.week_resolved, "the deferred event resolves week two without a second settlement submission")
	_check(float(ui.model.cash_weeks) < cash_before and float(ui.model.narrative) <= narrative_before, "the automatically resumed settlement applies weekly burn and narrative decay exactly at the event boundary")
	_close_all_result_pages(ui)
	_check(ui.model.chapter == 0 and ui.model.week_in_chapter == 3, "post-event UI settlement advances to week three")
	_check(ui.screen == HiringMain.Screen.EVENT and str(ui.current_event.get("id", "")) == "lin_scene_1", "week-three authored event remains ordered after the deferred beat")
	ui._close_event()
	_check(ui.screen == HiringMain.Screen.DASHBOARD and ui.current_event.is_empty(), "week-three event is resolved before the isolated night fixture")


func _test_night_shift_and_advance_ui_state(ui) -> void:
	# Put the already-wired UI at the authored Seed chapter boundary. This is a
	# focused presentation contract test; full 45-week chronology lives in the
	# director flow suite.
	ui.model.chapter = 2
	ui.model.week_in_chapter = 12
	ui.model.total_week = 23
	ui.model.cash_weeks = 100.0
	ui.model.week_active = true
	ui.model.week_resolved = false
	ui.pending_week_advance = false
	ui.current_event.clear()
	ui._refresh_week_actions()
	ui._queue_week_content()

	_check(ui.screen == HiringMain.Screen.EVENT and str(ui.current_event.get("id", "")) == "seed_raise_2", "UI opens the authored Seed closing event")
	ui._close_event()
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "Seed closing event resolves back to dashboard before settlement")
	ui._finish_week()
	_check(ui.screen == HiringMain.Screen.DASHBOARD and ui.end_week_confirm_pending, "every later week also protects unused attention with an explicit confirmation")
	ui._finish_week()
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT and ui.pending_week_advance, "Seed week settlement waits in the result state")
	_close_all_result_pages(ui)
	_check(ui.screen == HiringMain.Screen.NIGHT_SHIFT, "closing the Seed settlement opens night shift one")
	_check(ui.pending_night_id == "1" and str(ui.current_night.get("id", "")) == "night_shift_1", "UI receives the director's pending night identity")
	_check(not ui.command_edit.visible, "night UI keeps command input hidden until the authored terminal is reached and focused")
	ui._submit_terminal_command(" rm -rf ")
	_check(not bool(ui.model.flags.get("rm_rf", false)) and not ui.current_night.is_empty(), "unfocused command submission cannot trigger the rm -rf ending")

	var whiteboard: Dictionary = ui._night_object_by_id("whiteboard")
	ui.night_player_position = Vector2(640, 540)
	ui._queue_night_object_visit(whiteboard)
	_check(ui.night_seen.is_empty() and not ui._night_complete(), "clicking a distant night hotspot only starts movement and cannot mark it read")
	ui.night_player_position = ui.night_player_target
	ui.night_arrival_armed = false
	ui._complete_night_object_arrival()
	_check(ui.night_seen == ["whiteboard"] and ui._night_complete(), "arriving and explicitly inspecting one authored object opens the night exit")
	ui.result_lines.clear()
	ui._finish_night_shift()
	_check(bool(ui.model.flags.get("night_shift_1_complete", false)), "UI night completion commits to CampaignDirector")
	_check(ui.current_night.is_empty() and ui.pending_night_id.is_empty(), "UI clears completed night presentation state")
	_check(ui.model.chapter == 3 and ui.model.week_in_chapter == 1, "night completion advances through the director to Series A week one")
	_check(not ui.pending_week_advance, "successful night completion clears the pending UI advance gate")
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "silent Series A opening beat returns UI to dashboard")


func _test_stage_three_option_voice_surface(ui) -> void:
	ui.model.flags["options_in_assistant_voice"] = true
	var eligible := 0
	var rewritten := 0
	var consistently_authored := true
	var ai_untouched := true
	var all_authored_copy_fits := true
	for source_value in [ui.HiringContent.FIXED_EVENTS, ui.HiringContent.GENERIC_EVENTS]:
		var source: Dictionary = source_value
		for key_value in source:
			var key := str(key_value)
			if source == ui.HiringContent.FIXED_EVENTS and not key.begins_with("3:") and not key.begins_with("4:"):
				continue
			var event: Dictionary = Dictionary(source[key]).duplicate(true)
			ui.current_event = event
			for choice_value in event.get("choices", []):
				if not choice_value is Dictionary:
					continue
				var choice: Dictionary = choice_value
				var original := str(choice.get("label", ""))
				var displayed: String = str(ui._choice_display_label(choice))
				if bool(choice.get("ai", false)):
					ai_untouched = ai_untouched and displayed == original
					continue
				eligible += 1
				if displayed != original:
					rewritten += 1
					consistently_authored = consistently_authored and displayed.length() > original.length() and displayed.contains("；") and displayed.contains("，")
					var visual: Dictionary = ui._event_choice_visual_contract(choice)
					var compact_grid := Array(event.get("choices", [])).size() >= 4
					var text_width := 244.0 if compact_grid else 564.0
					var text_height := 50.0 if compact_grid else 32.0
					var visible_lines := int(text_height / float(visual.get("line_height", 16.0)))
					all_authored_copy_fits = all_authored_copy_fits and ui._wrap_text_px(displayed, text_width, int(visual.get("label_font_size", 13))).size() <= visible_lines
	_check(eligible >= 10, "late campaign exposes enough non-AI authored choices to make the accent gradual")
	_check(rewritten == eligible, "stage three authors every ordinary late-game decision rather than misusing the player-discovery target as a rewrite ratio")
	_check(consistently_authored, "stage-three option voice is uniformly longer, orderly, and punctuated without a UI label")
	_check(all_authored_copy_fits, "every stage-three authored option remains fully visible inside its unchanged card geometry")
	_check(ai_untouched, "explicit let-it-write choices are not redundantly rewritten by the stage-three accent")
	var style_fixture := {"id": "style_fixture", "label": "保留当前说法。", "ai": false}
	ui.current_event = {"id": "style_contract", "choices": [style_fixture]}
	ui.model.flags["options_in_assistant_voice"] = false
	var before_style: Dictionary = ui._event_choice_visual_contract(style_fixture).duplicate(true)
	var before_rect: Rect2 = ui._event_choice_rect(0)
	var before_label: String = ui._choice_display_label(style_fixture)
	ui.model.flags["options_in_assistant_voice"] = true
	var after_style: Dictionary = ui._event_choice_visual_contract(style_fixture).duplicate(true)
	var after_rect: Rect2 = ui._event_choice_rect(0)
	var after_label: String = ui._choice_display_label(style_fixture)
	_check(after_label != before_label, "stage-three fixture changes its copy")
	_check(after_style == before_style and after_rect == before_rect, "stage-three accent changes only copy: geometry, colors, typography, hover, tooltip, and animation contracts remain byte-for-byte equal")
	_check(not bool(after_style.get("hover_variant", true)) and str(after_style.get("tooltip", "unexpected")).is_empty() and str(after_style.get("animation", "unexpected")) == "none", "ordinary option voice has no covert visual discovery cue")
	ui.current_event = {}


func _test_elevator_button_visual_contract(ui) -> void:
	var ordinary: Dictionary = ui._elevator_floor_button_visual_contract().duplicate(true)
	ui.model.flags["extra_elevator_floor"] = true
	var anomalous: Dictionary = ui._elevator_floor_button_visual_contract().duplicate(true)
	_check(ordinary == anomalous, "the anomalous elevator floor uses the exact ordinary floor-button visual contract")
	_check(not bool(anomalous.get("interactive", true)) and not bool(anomalous.get("hover_variant", true)), "the anomalous elevator floor has no interaction or hover affordance")
	_check(str(anomalous.get("tooltip", "unexpected")).is_empty() and str(anomalous.get("animation", "unexpected")) == "none", "the anomalous elevator floor has no tooltip, highlight animation, or private reveal")


func _test_lin_scene_two_silence_timeline(ui) -> void:
	var event: Dictionary = ui.HiringContent.FIXED_EVENTS["1:7"].duplicate(true)
	ui.current_event = event
	ui.current_event_page = 0
	ui.event_page_elapsed = 0.0
	var pages: Array = ui._event_body_pages()
	_check(pages.size() == 5 and Array(event.get("silence_pages", [])) == [1, 3], "Lin scene two has five explicit beats with two distinct silence pages")
	_check(Array(event.get("page_hold_seconds", [])) == [0.0, 120.0, 0.0, 120.0, 0.0], "both Lin scene-two silences retain approximately two story minutes in authored data")
	ui._advance_event_page_or_close()
	_check(ui.current_event_page == 1 and ui._event_page_is_silence() and not ui._event_page_can_advance(), "the first silence begins separately and rejects immediate continuation")
	ui.event_page_elapsed = 9.99
	ui._advance_event_page_or_close()
	_check(ui.current_event_page == 1, "the first silence remains held during the ten-second performance beat")
	ui.event_page_elapsed = 10.0
	ui._advance_event_page_or_close()
	_check(ui.current_event_page == 2 and not ui._event_page_is_silence(), "the first spoken line becomes skippable after ten seconds without deleting the authored two-minute hold")
	ui._advance_event_page_or_close()
	_check(ui.current_event_page == 3 and ui._event_page_is_silence() and not ui._event_page_can_advance(), "the second silence is a new independently gated beat")
	ui.event_page_elapsed = 10.0
	ui._advance_event_page_or_close()
	_check(ui.current_event_page == 4 and not ui._event_page_is_silence(), "the final line becomes skippable after the second ten-second performance beat")
	ui.current_event = {}
	ui.current_event_page = 0
	ui.event_page_elapsed = 0.0


func _test_action_pool_surface_contract(ui) -> void:
	ui.model.chapter = 0
	ui.model.week_in_chapter = 1
	ui._refresh_week_actions()
	_check(ui.week_action_ids.size() == 4 and ui.week_action_ids.has("do_nothing"), "garage UI exposes exactly four cards including do-nothing")
	ui.model.chapter = 1
	ui.model.week_in_chapter = 1
	ui._refresh_week_actions()
	_check(ui.week_action_ids.size() == 5 and ui.week_action_ids.has("do_nothing"), "pre-seed UI exposes five wants including do-nothing")
	ui.model.chapter = 2
	ui.model.week_in_chapter = 1
	ui.model.memory["action_counts"] = {}
	ui._refresh_week_actions()
	_check(not ui.week_action_ids.has("demo_video"), "demo video remains locked before Seed week two")
	for week in range(2, 6):
		ui.model.week_in_chapter = week
		ui._refresh_week_actions()
		_check(ui.week_action_ids.size() == 5 and ui.week_action_ids[0] == "demo_video", "unused demo video is the fixed featured card in Seed week %d" % week)
	ui.model.memory["action_counts"] = {"demo_video": 1}
	ui.model.week_in_chapter = 3
	ui._refresh_week_actions()
	_check(ui.week_action_ids.size() == 5 and ui.week_action_ids.has("do_nothing"), "using demo once returns the Seed pool to normal rotation")
	ui.model.chapter = 4
	ui.model.week_in_chapter = 1
	ui._refresh_week_actions()
	_check(ui.week_action_ids == ["sign", "read_intranet", "one_on_one", "do_nothing"], "finale UI keeps only signature, intranet, one-on-one, and do-nothing")
	ui.model.chapter = 3
	ui.model.coherence = 70.0
	ui.model.cash_weeks = 10.0
	ui.model.compute = 10.0
	ui.model.morale = 70.0
	ui.model.narrative = 50.0
	ui.model.capability = 50.0
	ui.model.memory["action_offer_counts"] = {}
	var seen_offers: Dictionary = {}
	for step in 24:
		ui.model.total_week = 24 + step
		ui.model.week_in_chapter = 1 + (step % 12)
		ui._refresh_week_actions()
		for action_id in ui.week_action_ids:
			seen_offers[action_id] = true
	_check(seen_offers.has("raise_salary") and seen_offers.has("exclusive_interview"), "least-offered rotation prevents late-game salary and exclusive-interview cards from starving")
	var persisted_pool: Array[String] = []
	for offered_id in ui.week_action_ids:
		persisted_pool.append(str(offered_id))
	var pool_fixture := {"ui_action_pool_week": int(ui.model.total_week), "ui_week_actions": persisted_pool}
	ui.week_action_ids.clear()
	ui.week_action_ids.append("do_nothing")
	_check(ui._restore_week_actions_from_save(pool_fixture) and ui.week_action_ids == persisted_pool, "continue restores the exact offered card set instead of rerolling the same week")
	pool_fixture["ui_action_pool_week"] = int(ui.model.total_week) - 1
	_check(not ui._restore_week_actions_from_save(pool_fixture), "a stale card offer cannot leak into a different week")


func _test_intranet_review_action_contract(ui) -> void:
	ui.model.chapter = 4
	ui.model.week_in_chapter = 1
	ui.model.total_week = 33
	ui.model.memory.erase("intranet_action_reviews")
	var docs: Array = ui._intranet_documents()
	var latest_index: int = ui._latest_intranet_document_index(docs)
	_check(not docs.is_empty() and latest_index >= 0 and latest_index < docs.size(), "the finale review action resolves a real latest available document")
	ui.selected_document = latest_index
	ui._record_intranet_action_review(docs, false)
	var review: Dictionary = ui._current_week_intranet_review()
	_check(str(review.get("author", "")) == "founder" and int(review.get("week", -1)) == 33, "manual intranet review stores a signed, week-specific record")
	_check(str(review.get("document_id", "")).length() > 0 and str(review.get("title", "")).length() > 0, "the review record persists the selected document identity and display title")
	_check(ui._action_effect_summary("read_intranet", false).contains("署名审阅"), "the finale action card distinguishes signed review from free intranet browsing")
	_check(ui._intranet_ending_echo().contains(str(review.get("title", ""))) and ui._intranet_ending_echo().contains("署名"), "a founder review receives a document-specific ending callback")
	ui.model.memory.erase("intranet_action_reviews")
	ui.model.memory.erase("last_intranet_action_review_week")


func _test_seed_week_five_natural_debt_balance(ui) -> void:
	# CH2-W05 is a balance target, not a scripted state mutation. Each profile
	# starts from reset, chooses only cards returned by the production UI rotation,
	# resolves authored events through CampaignDirector, and runs the real weekly
	# debt formula. Distinct priorities model plausible first-play behavior rather
	# than a single hand-picked action script.
	var profiles: Array[Dictionary] = [
		{
			"id": "founder_story", "investor_choice": "exaggerate",
			"reckoning_choice": "delay", "delegate_action": "",
			"preferences": [
				"demo_video", "podcast", "conference_talk", "tweet", "tech_blog",
				"fundraising", "values_doc", "all_hands", "team_building", "interview",
				"one_on_one", "clean_data", "train", "eval", "contract", "do_nothing",
				"buy_compute", "large_train", "raise_salary", "recruit_expert",
			],
		},
		{
			"id": "operating_growth", "investor_choice": "exaggerate",
			"reckoning_choice": "show", "delegate_action": "",
			"preferences": [
				"fundraising", "interview", "all_hands", "team_building", "values_doc",
				"conference_talk", "demo_video", "tweet", "tech_blog", "podcast",
				"one_on_one", "clean_data", "train", "eval", "contract", "do_nothing",
				"buy_compute", "large_train", "raise_salary", "recruit_expert",
			],
		},
		{
			"id": "delegated_launch", "investor_choice": "delegate",
			"reckoning_choice": "delegate", "delegate_action": "demo_video",
			"preferences": [
				"demo_video", "conference_talk", "podcast", "tweet", "fundraising",
				"tech_blog", "interview", "values_doc", "all_hands", "team_building",
				"one_on_one", "clean_data", "train", "eval", "contract", "do_nothing",
				"buy_compute", "large_train", "raise_salary", "recruit_expert",
			],
		},
	]
	var original_model = ui.model
	var original_selected_action: int = ui.selected_action
	var fingerprints: Dictionary = {}
	for profile in profiles:
		var profile_id := str(profile["id"])
		var director = CampaignDirector.new()
		var started: Dictionary = director.start_company("Balance %s" % profile_id, false)
		_check(bool(started.get("ok", false)), "%s balance path starts from an unmodified new campaign" % profile_id)
		var peak_debt := float(director.model.debt)
		var surfaced_action_count := 0
		var guard := 0
		while guard < 24:
			guard += 1
			var events_ok := _resolve_balance_events(director, profile)
			_check(events_ok, "%s resolves the authored event chain at global week %d" % [profile_id, director.model.total_week])
			if not events_ok:
				break

			ui.model = director.model
			ui._refresh_week_actions()
			var surfaced_cards: Array[String] = []
			for action_id_value in ui.week_action_ids:
				surfaced_cards.append(str(action_id_value))
			var performed_this_week := 0
			for preferred_value in Array(profile["preferences"]):
				if performed_this_week >= 3:
					break
				var action_id := str(preferred_value)
				if not surfaced_cards.has(action_id):
					continue
				var use_ai := action_id == str(profile.get("delegate_action", "")) and not bool(director.model.flags.get("ai_used_this_week", false))
				if not director.model.can_act(action_id, use_ai):
					continue
				var action_result: Dictionary = director.perform_action(action_id, use_ai)
				if not bool(action_result.get("ok", false)):
					continue
				performed_this_week += 1
				surfaced_action_count += 1
				peak_debt = maxf(peak_debt, float(director.model.debt))
				if not _resolve_balance_events(director, profile):
					break
			_check(performed_this_week == 3, "%s takes three legal surfaced actions in global week %d" % [profile_id, director.model.total_week])

			var finished: Dictionary = director.finish_week()
			if not bool(finished.get("ok", false)) and str(finished.get("reason", "")) == "event_pending":
				var closing_ok := _resolve_balance_events(director, profile)
				_check(closing_ok, "%s resolves the deferred closing beat in global week %d" % [profile_id, director.model.total_week])
				finished = director.finish_week()
			_check(bool(finished.get("ok", false)), "%s settles global week %d through production systems" % [profile_id, director.model.total_week])
			if not bool(finished.get("ok", false)):
				break
			peak_debt = maxf(peak_debt, float(director.model.debt))
			if director.model.chapter == 2 and director.model.week_in_chapter == 5:
				break
			var advanced: Dictionary = director.advance()
			_check(bool(advanced.get("ok", false)), "%s advances after global week %d" % [profile_id, director.model.total_week])
			if not bool(advanced.get("ok", false)):
				break

		var action_counts: Dictionary = Dictionary(director.model.memory.get("action_counts", {}))
		var fingerprint := JSON.stringify(action_counts) + ":" + str(profile.get("investor_choice", "")) + ":" + str(profile.get("reckoning_choice", ""))
		fingerprints[fingerprint] = true
		_check(guard < 24 and director.model.chapter == 2 and director.model.week_in_chapter == 5 and director.model.total_week == 16, "%s naturally reaches Seed week five without chronology fixtures" % profile_id)
		_check(surfaced_action_count == 48, "%s makes exactly three surfaced choices across the first sixteen weeks" % profile_id)
		_check(int(action_counts.get("demo_video", 0)) >= 1, "%s accepts the production demo-video temptation before Seed week five" % profile_id)
		_check(float(director.model.cash_weeks) > 0.0, "%s remains solvent at the Seed week-five balance checkpoint" % profile_id)
		_check(float(director.model.debt) >= 40.0, "%s naturally has debt at least 40 after Seed week five" % profile_id)
		_check(peak_debt >= float(director.model.debt) and peak_debt >= 40.0, "%s natural path records a real 40+ debt peak without forced state" % profile_id)
		print("HIRING_BALANCE_CH2_W05: profile=%s debt=%.3f peak=%.3f cash=%.3f capability=%.3f narrative=%.3f actions=%s" % [
			profile_id, director.model.debt, peak_debt, director.model.cash_weeks,
			director.model.capability, director.model.narrative, JSON.stringify(action_counts),
		])
	_check(fingerprints.size() == profiles.size(), "Seed week-five balance proof contains three mechanically distinct natural play paths")
	ui.model = original_model
	ui.selected_action = original_selected_action
	ui._refresh_week_actions()


func _resolve_balance_events(director, profile: Dictionary) -> bool:
	for _event_guard in 24:
		var event: Dictionary = director.next_event()
		if event.is_empty():
			return true
		var choice_id := _balance_event_choice(event, profile)
		var resolved: Dictionary = director.resolve_event(event, choice_id)
		if not bool(resolved.get("ok", false)):
			return false
	return false


func _balance_event_choice(event: Dictionary, profile: Dictionary) -> String:
	var choices: Array = event.get("choices", [])
	if choices.is_empty():
		return ""
	var event_id := str(event.get("_director_base_id", event.get("id", "")))
	var preferred := ""
	match event_id:
		"first_investor_meeting": preferred = str(profile.get("investor_choice", "exaggerate"))
		"debt_collection": preferred = str(profile.get("reckoning_choice", "show"))
		"cash_emergency": preferred = "contract"
		"hiring_candidates": preferred = "candidate_0"
		"one_on_one_reveal": preferred = "listen"
		_:
			preferred = ""
	if not preferred.is_empty():
		for choice_value in choices:
			if str(Dictionary(choice_value).get("id", "")) == preferred:
				return preferred
	for choice_value in choices:
		if not bool(Dictionary(choice_value).get("ai", false)):
			return str(Dictionary(choice_value).get("id", ""))
	return str(Dictionary(choices[0]).get("id", ""))


func _test_finale_memory_callback_speaker(ui) -> void:
	ui.model.chapter = 4
	ui.model.week_in_chapter = 6
	ui.model.author_weight = 90.0
	ui.model.company_name = "星潮科技"
	ui.model.flags["seen_unsolicited_line"] = true
	ui.model.memory["values_version"] = 3
	ui.model.memory.erase("ui_meal_reminder_seen")
	ui.model.memory.erase("ui_values_v3_callback_seen")
	ui.terminal_lines.clear()
	ui._sync_memory_callbacks()
	var transcript := "\n".join(ui.terminal_lines)
	var official_name: String = str(ui._model_official_name())
	_check(not official_name.is_empty() and transcript.contains(official_name), "finale memory callbacks speak under the official model name")
	_check(not transcript.contains("——："), "finale memory callbacks never expose the empty private-name placeholder")
	var docs: Array = ui._intranet_documents()
	for document_value in docs:
		var document: Dictionary = document_value
		var document_id := str(document.get("id", ""))
		var corpus := JSON.stringify(document)
		if document_id == "values_v1":
			_check(not corpus.contains("第三版价值观") and not document.has("memory_callback"), "the archived first values document remains historically untouched")
		else:
			_check((corpus.contains("第三版价值观") or document_id == "values_v3") and str(document.get("memory_callback", "")) == "values_v3_written", "internal document '%s' carries the third-values memory callback" % document_id)
	var personalized := JSON.stringify(docs)
	_check(personalized.contains("星潮科技") and not personalized.contains("欢迎加入提灯实验室"), "internal documents use the saved company name instead of the canonical fixture name")


func _test_ending_company_and_employee_rendering(ui) -> void:
	ui.model.company_name = "星潮科技"
	var lin: Dictionary = {
		"id": "lin_yue", "name": "林越", "role": "联合创始人 / CTO",
		"skill": 88.0, "morale": 76.0, "belief": 92.0, "witnessed": []
	}
	ui.model.employees.clear()
	ui.model.employees.append(lin)
	ui.current_ending = HiringContent.get_ending("acquihire")
	var present_acquisition := _rendered_ending_text(ui)
	_check(present_acquisition.contains("星潮科技") and not present_acquisition.contains("{{company_name}}"), "ending body renders the actual company name instead of a template token")
	_check(present_acquisition.contains("林越只问了一句") and not present_acquisition.contains("如果还在"), "present Lin Yue receives a complete Acquisition sentence")

	ui.model.employees.clear()
	var absent_acquisition := _rendered_ending_text(ui)
	_check(absent_acquisition.contains("林越已经离开") and not absent_acquisition.contains("林越只问了一句"), "absent Lin Yue receives the authored Acquisition branch")
	ui.current_ending = HiringContent.get_ending("independent")
	var absent_independent := _rendered_ending_text(ui)
	_check(absent_independent.contains("你把他的邮件设成了置顶") and not absent_independent.contains("林越把他的邮件设成了置顶"), "Independent remains coherent when Lin Yue has left")
	ui.current_ending = HiringContent.get_ending("drift")
	var absent_drift := _rendered_ending_text(ui)
	_check(absent_drift.contains("林越离开前") and absent_drift.contains("星潮科技") and not absent_drift.contains("提灯这个名字"), "Drift renders both the absent-Lin and company-name branches")
	ui.current_ending = HiringContent.get_ending("rm_rf")
	var absent_rm_rf := _rendered_ending_text(ui)
	_check(absent_rm_rf.contains("你没有打开那段对话") and not absent_rm_rf.contains("你回复：『是。』"), "rm -rf removes the reply exchange when Lin Yue has left")

	ui.model.employees.clear()
	ui.model.employees.append(lin)
	var present_rm_rf := _rendered_ending_text(ui)
	_check(present_rm_rf.contains("林越只发来四个字") and present_rm_rf.contains("你回复：『是。』"), "rm -rf keeps the complete exchange when Lin Yue is present")
	ui.current_ending = {
		"text": ["提灯实验室的旧称不应泄漏。", "{{company_name}} 仍被写在门上。"],
		"final_line": "{{company_name}} 的最后一行。"
	}
	var interpolation_fixture := _rendered_ending_text(ui)
	_check(interpolation_fixture.contains("星潮科技的旧称") and not interpolation_fixture.contains("提灯实验室"), "legacy hard-coded default names are replaced during ending rendering")
	_check(interpolation_fixture.contains("星潮科技 的最后一行") or interpolation_fixture.contains("星潮科技的最后一行"), "ending final_line receives company-name interpolation")


func _test_all_ending_playback_surfaces(ui) -> void:
	var screen_before: int = int(ui.screen)
	var company_before := str(ui.model.company_name)
	var ending_before: Dictionary = ui.current_ending.duplicate(true)
	var ending_id_before := str(ui.current_ending_id)
	var ending_page_before := int(ui.ending_page)
	const COMPANY_FIXTURE := "第七码头研究所"
	ui.model.company_name = COMPANY_FIXTURE

	for ending_id in ENDING_IDS:
		ui.current_ending_id = ending_id
		ui.current_ending = HiringContent.get_ending(ending_id)
		ui.ending_page = 0
		ui.screen = HiringMain.Screen.ENDING
		var pages: Array = ui._ending_pages()
		_check(not pages.is_empty(), "ending '%s' exposes at least one playable page" % ending_id)
		if pages.is_empty():
			continue
		var source_text := JSON.stringify(ui.current_ending)
		var rendered_text := JSON.stringify(pages)
		_check(not rendered_text.contains("{{company_name}}") and not rendered_text.contains("提灯实验室"), "ending '%s' never leaks a template or canonical company name" % ending_id)
		if source_text.contains("{{company_name}}") or source_text.contains("提灯实验室"):
			_check(rendered_text.contains(COMPANY_FIXTURE), "ending '%s' interpolates the custom company fixture" % ending_id)
		var first_page := JSON.stringify(pages[0])
		_check(ui.ending_page == 0 and not first_page.is_empty(), "ending '%s' starts on its first rendered page" % ending_id)
		var last_page_index := pages.size() - 1
		var guard := 32
		while ui.ending_page < last_page_index and guard > 0:
			ui._advance_ending()
			guard -= 1
		var last_page := JSON.stringify(pages[last_page_index])
		_check(guard > 0 and ui.screen == HiringMain.Screen.ENDING and ui.ending_page == last_page_index and not last_page.is_empty(), "ending '%s' traverses through its last rendered page before campaign clearing" % ending_id)

	ui.model.company_name = company_before
	ui.current_ending = ending_before
	ui.current_ending_id = ending_id_before
	ui.ending_page = ending_page_before
	ui.screen = screen_before
	ui._save_game()


func _test_action_cash_exhaustion_is_immediate(ui) -> void:
	var started: Dictionary = ui.director.start_company("归零科技", false)
	_check(bool(started.get("ok", false)), "cash-exhaustion fixture starts a clean campaign")
	ui.model = ui.director.model
	ui.model.chapter = 1
	ui.model.week_in_chapter = 1
	ui.model.cash_weeks = 2.0
	ui.model.attention = 3
	ui.model.attention_max = 3
	ui.model.performed_actions.clear()
	ui.used_action_ids.clear()
	ui.week_action_ids.clear()
	ui.week_action_ids.append("buy_compute")
	ui.selected_action = 0
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	ui._take_selected_action(false)
	_check(is_zero_approx(float(ui.model.cash_weeks)), "the selected action exhausts cash exactly to zero")
	_check(ui.screen == HiringMain.Screen.ENDING and ui.current_ending_id == "lights_out", "cash exhaustion enters Lights Out immediately without another dashboard action")
	_check(bool(ui.model.flags.get("cash_exhausted", false)), "immediate Lights Out records the authoritative cash-exhausted flag")
	_check(FileAccess.file_exists(SAVE_PATH), "terminal action resolution retains the resumable campaign save until ending acknowledgement")
	var ending_save := _read_json_dictionary(SAVE_PATH)
	_check(str(ending_save.get("ui_current_ending_id", "")) == "lights_out" and int(ending_save.get("ui_ending_page", -1)) == 0, "immediate Lights Out persists its exact opening page")
	var meta := _read_json_dictionary(META_PATH)
	_check(bool(meta.get("second_run", false)) and str(meta.get("last_ending", "")) == "lights_out", "immediate Lights Out safely records NG+ meta state")


func _test_stage_one_ai_response_and_action_ceiling(ui) -> void:
	var started: Dictionary = ui.director.start_company("四件事科技", false)
	_check(bool(started.get("ok", false)), "stage-one delegation fixture starts a clean campaign")
	ui.model = ui.director.model
	ui.director.resolve_event("garage_opening")
	ui.current_event.clear()
	ui.model.chapter = 1
	ui.model.week_in_chapter = 1
	ui.model.cash_weeks = 100.0
	ui.model.compute = 100.0
	ui.model.author_weight = 0.0
	ui.model.attention_max = 3
	ui.model.attention = 3
	ui.model.performed_actions.clear()
	ui.model.flags.erase("ai_used_this_week")
	ui.used_action_ids.clear()
	ui.week_action_ids.clear()
	ui.week_action_ids.append_array(["tweet", "tech_blog", "train", "clean_data", "do_nothing"])
	ui.selected_action = 0
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	ui._take_selected_action(true)
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT, "stage-one delegated action reaches the real player-visible result screen")
	_check("\n".join(ui.result_lines).contains("如果需要我可以再改"), "stage-one delegated action includes the exact offer '如果需要我可以再改'")
	_close_all_result_pages(ui)
	_check(not ui.model.can_act("tech_blog", true), "UI model disables a second delegated card in the same week")
	for action_id in ["tech_blog", "train", "clean_data"]:
		_perform_ui_action(ui, action_id, false)
		_close_all_result_pages(ui)
	_check(ui.model.performed_actions.size() == 4 and ui.model.attention == 0, "UI exposes exactly three manual actions plus one delegated action")
	_check(not ui.model.can_act("do_nothing", false) and not ui.model.can_act("do_nothing", true), "the fifth visible card is disabled for both self and AI after four actions")

	# Event-choice delegation uses a separate input path from action cards and
	# must retain the same stage-one verbal fingerprint.
	started = ui.director.start_company("礼貌回复科技", false)
	ui.model = ui.director.model
	ui.director.resolve_event("garage_opening")
	ui.model.chapter = 1
	ui.model.author_weight = 0.0
	ui.model.flags["open_hiring"] = true
	ui._open_event(Dictionary(HiringContent.GENERIC_EVENTS["hiring_candidates"]).duplicate(true))
	var delegate_index := -1
	for index in Array(ui.current_event.get("choices", [])).size():
		if bool(Dictionary(Array(ui.current_event.get("choices", []))[index]).get("ai", false)):
			delegate_index = index
			break
	_check(delegate_index >= 0, "stage-one hiring modal exposes its delegated choice")
	if delegate_index >= 0:
		ui._choose_event_option(delegate_index)
		_check(ui.screen == HiringMain.Screen.ACTION_RESULT and "\n".join(ui.result_lines).contains("如果需要我可以再改"), "stage-one delegated event result includes the exact offer '如果需要我可以再改'")


func _test_event_choice_cash_exhaustion_is_immediate(ui) -> void:
	var started: Dictionary = ui.director.start_company("决定归零科技", false)
	_check(bool(started.get("ok", false)), "event cash-exhaustion fixture starts a clean campaign")
	ui.model = ui.director.model
	ui.director.resolve_event("garage_opening")
	ui.model.chapter = 1
	ui.model.cash_weeks = 1.0
	ui._open_event({
		"id": "event_cash_exhaustion_fixture", "title": "最后一笔支出", "choices": [
			{"id": "spend", "label": "支付。", "ai": false, "effects": {"cash_weeks": -1}, "result": ["付款完成。"]}
		], "after": ""
	})
	ui._choose_event_option(0)
	_check(is_zero_approx(float(ui.model.cash_weeks)), "event choice spends the final one week of runway")
	_check(ui.screen == HiringMain.Screen.ENDING and ui.current_ending_id == "lights_out", "cash exhausted by an event choice enters Lights Out in the same input frame")
	_check(bool(ui.model.flags.get("cash_exhausted", false)) and ui.current_event.is_empty(), "immediate event-choice ending records exhaustion and leaves no continue modal")

	started = ui.director.start_company("优先级科技", false)
	ui.model = ui.director.model
	ui.director.resolve_event("garage_opening")
	ui.model.chapter = 1
	ui.model.cash_weeks = 1.0
	ui.model.flags["rm_rf"] = true
	ui._open_event({
		"id": "event_cash_priority_fixture", "title": "最后一笔支出", "choices": [
			{"id": "spend", "label": "支付。", "ai": false, "effects": {"cash_weeks": -1}, "result": ["付款完成。"]}
		], "after": ""
	})
	ui._choose_event_option(0)
	_check(ui.screen == HiringMain.Screen.ENDING and ui.current_ending_id == "rm_rf", "rm -rf retains absolute priority when the same event choice also exhausts cash")


func _test_quiet_chronology_surfaces(ui) -> void:
	ui.model.chapter = 2
	ui.model.week_in_chapter = 1
	ui.model.total_week = 12
	ui.model.flags.erase("seen_hiring_page_traffic")
	var early_announcements := JSON.stringify(ui._announcement_items())
	_check(not early_announcements.contains("4,200 / 3"), "hiring-page metrics remain absent before chapter-two week eight")
	ui._change_screen(HiringMain.Screen.ANNOUNCEMENTS)
	ui.queue_redraw()
	await process_frame
	var early_drawn: Dictionary = ui.announcement_sidebar_snapshot.duplicate(true)
	_check(not bool(early_drawn.get("visible", true)) and str(early_drawn.get("views", "")) == "—" and str(early_drawn.get("applications", "")) == "—", "the actually drawn announcement sidebar keeps both hiring metrics hidden before the silent beat")
	ui.model.flags["seen_hiring_page_traffic"] = true
	var released_announcements := JSON.stringify(ui._announcement_items())
	_check(released_announcements.contains("4,200 / 3"), "the silent week-eight beat releases hiring metrics into the ordinary announcement surface")
	ui.queue_redraw()
	await process_frame
	var released_drawn: Dictionary = ui.announcement_sidebar_snapshot.duplicate(true)
	_check(bool(released_drawn.get("visible", false)) and str(released_drawn.get("views", "")) == "4,200" and str(released_drawn.get("applications", "")) == "3", "the actually drawn announcement sidebar reveals the exact 4,200 / 3 values only after the silent beat")

	ui.model.chapter = 4
	ui.model.week_in_chapter = 7
	ui.model.total_week = 44
	ui.model.author_weight = 100.0
	ui.model.flags.erase("ai_used_this_week")
	ui.model.memory.erase("ui_unsolicited_week")
	ui.terminal_lines.clear()
	ui._append_week_end_unsolicited_line()
	_check(ui.terminal_lines.is_empty() and not ui.model.memory.has("ui_unsolicited_week"), "chapter-four week seven suppresses every unsolicited terminal line")

	var debt_event: Dictionary = HiringContent.GENERIC_EVENTS["debt_collection"]
	_check(not str(debt_event.get("kicker", "")).contains("债"), "high-debt fulfillment is presented as an ordinary customer callback, never as a hidden-stat label")


func _test_compute_unavailable_copy(ui) -> void:
	ui.model.chapter = 2
	ui.model.week_in_chapter = 2
	ui.model.week_active = true
	ui.model.week_resolved = false
	ui.model.campaign_complete = false
	ui.model.attention = 3
	ui.model.attention_max = 3
	ui.model.performed_actions.clear()
	ui.model.flags.erase("training_blocked_this_week")
	ui.model.flags.erase("ai_used_this_week")
	ui.model.flags.erase("capability_revealed")
	ui.used_action_ids.clear()
	ui.week_action_ids.assign(["train", "eval", "large_train", "buy_compute", "do_nothing"])
	var eval_action: Dictionary = ui._action_data("eval")
	_check("还掉" in ui._action_display_description("eval", eval_action), "the first formal eval honestly advertises its one-time repayment value")
	ui.model.flags["capability_revealed"] = true
	var repeat_eval_description: String = str(ui._action_display_description("eval", eval_action))
	_check("不会再次" in repeat_eval_description and "更新核验记录" in repeat_eval_description, "repeat eval copy clearly stops promising renewable repayment while keeping the curve-update purpose")
	ui.model.compute = 0.0
	for action_id in ["train", "eval"]:
		var reason := str(ui._action_unavailable_reason(action_id, false))
		_check(reason == "算力不足：需要 1，当前 0", "disabled %s explains exact required/current compute" % action_id)
		_check(str(ui._compact_action_unavailable_reason(action_id, true)) == "需算力 1 / 当前 0", "delegated %s button retains exact compute requirement" % action_id)
	ui.model.compute = 7.0
	_check(str(ui._action_unavailable_reason("large_train", false)) == "算力不足：需要 8，当前 7", "disabled large training explains exact required/current compute")
	_check(str(ui._compact_action_unavailable_reason("large_train", true)) == "需算力 8 / 当前 7", "delegated large-training button uses the authoritative eight-compute requirement")
	ui.selected_action = 2
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	ui._take_selected_action(false)
	_check(ui.toast_text == "算力不足：需要 8，当前 7", "attempting a disabled compute action repeats the exact reason in failure copy")
	ui.model.compute = 100.0


func _test_action_preview_settlement_parity(ui) -> void:
	var original_model = ui.model

	var large_train = _prepared_preview_game(2, 2)
	ui.model = large_train
	var large_preview: Dictionary = ui._action_preview_effects("large_train", true)
	var large_range: Array = large_preview.get("capability", [])
	_check(large_range == [13.0, 19.0] and is_equal_approx(float(large_preview.get("compute", 0.0)), -8.0), "delegated large-training preview states its true capability range and eight-compute spend")
	var large_capability_before := float(large_train.capability)
	var large_compute_before := float(large_train.compute)
	var large_result: Dictionary = large_train.perform_action("large_train", true)
	var large_capability_delta := float(large_train.capability) - large_capability_before
	_check(bool(large_result.get("ok", false)) and large_capability_delta >= float(large_range[0]) and large_capability_delta <= float(large_range[1]), "delegated large-training settlement stays inside its displayed capability range")
	_check(is_equal_approx(float(large_train.compute) - large_compute_before, float(large_preview.get("compute", 0.0))) and "算力 -8" in str(ui._action_effect_summary("large_train", true)), "delegated large-training displayed compute cost equals settlement")

	var compute_purchase = _prepared_preview_game(0, 1)
	ui.model = compute_purchase
	var compute_preview: Dictionary = ui._action_preview_effects("buy_compute", true)
	var cash_before := float(compute_purchase.cash_weeks)
	var compute_before := float(compute_purchase.compute)
	var compute_result: Dictionary = compute_purchase.perform_action("buy_compute", true)
	_check(bool(compute_result.get("ok", false)) and is_equal_approx(float(compute_purchase.cash_weeks) - cash_before, float(compute_preview.get("cash_weeks", 0.0))), "delegated compute purchase preview uses the true net runway cost")
	_check(is_equal_approx(float(compute_purchase.compute) - compute_before, float(compute_preview.get("compute", 0.0))), "delegated compute purchase preview uses the true six-compute gain")

	var interview = _prepared_preview_game(3, 2)
	interview.debt = 80.0
	ui.model = interview
	var interview_preview: Dictionary = ui._action_preview_effects("exclusive_interview", true)
	var narrative_range: Array = interview_preview.get("narrative", [])
	var narrative_before := float(interview.narrative)
	var interview_result: Dictionary = interview.perform_action("exclusive_interview", true)
	var narrative_delta := float(interview.narrative) - narrative_before
	_check(bool(interview_result.get("ok", false)) and narrative_range == [-6.0, 22.0], "high-debt delegated interview preview discloses both press outcomes")
	_check(narrative_delta >= float(narrative_range[0]) and narrative_delta <= float(narrative_range[1]), "delegated interview settlement remains inside its disclosed conditional range")

	var review = _prepared_preview_game(4, 1)
	ui.model = review
	var review_preview: Dictionary = ui._action_preview_effects("read_intranet", true)
	var review_cash := float(review.cash_weeks)
	var review_morale := float(review.morale)
	var review_debt := float(review.debt)
	var review_result: Dictionary = review.perform_action("read_intranet", true)
	_check(bool(review_result.get("ok", false)) and review_preview.keys().has("open_intranet") and review_preview.keys().has("author_weight"), "delegated intranet review previews only its route and authorship transfer")
	_check(is_equal_approx(float(review.cash_weeks), review_cash) and is_equal_approx(float(review.morale), review_morale) and is_equal_approx(float(review.debt), review_debt), "delegated intranet review invents no comfort-resource changes")

	ui.model = original_model


func _test_atomic_ui_design_contract(ui) -> void:
	_check(ui.TYPE_MICRO >= 12 and ui.TYPE_META >= 12 and ui.RADIUS_CONTROL == 3.0 and ui.RADIUS_CARD == 2.0 and ui.RADIUS_MODAL == 8.0, "Blue-Hour Ledger 2.0 keeps accessible type with restrained folio geometry")
	var targets := {
		"settings": ui._settings_button_rect(), "settings close": ui._settings_close_rect(),
		"end week": ui._end_week_rect(), "back": ui._content_back_rect(),
		"document previous": ui._document_prev_rect(), "document next": ui._document_next_rect(),
		"team previous": ui._team_prev_rect(), "team next": ui._team_next_rect(),
		"announcement previous": ui._announcement_prev_rect(), "announcement next": ui._announcement_next_rect(),
		"origin reread": ui._origin_reread_rect(), "curtain": ui._window_curtain_button_rect(),
		"night exit": ui._night_exit_rect(), "night modal close": ui._night_modal_close_rect(),
	}
	for target_name in targets:
		var rect: Rect2 = targets[target_name]
		_check(rect.size.x >= ui.UI_MIN_TARGET and rect.size.y >= ui.UI_MIN_TARGET, "%s keeps a 44-by-44 minimum interaction target" % target_name)
	_check(ui._document_prev_rect().end.x < ui._document_page_counter_rect().position.x and ui._document_page_counter_rect().end.x < ui._document_next_rect().position.x, "document PageStepper keeps previous, count, next in reading order")
	_check(ui._team_prev_rect().end.x < ui._team_page_counter_rect().position.x and ui._team_page_counter_rect().end.x < ui._team_next_rect().position.x, "team PageStepper keeps previous, count, next in reading order")
	_check(ui._announcement_prev_rect().end.x < ui._announcement_page_counter_rect().position.x and ui._announcement_page_counter_rect().end.x < ui._announcement_next_rect().position.x, "announcement PageStepper keeps previous, count, next in reading order")
	_check(ui._announcement_balanced_page_size(7) == 4, "a seven-item announcement archive balances as four plus three instead of six plus one")

	var document_paragraphs: Array[String] = [
		"本周完成", "一段需要占据两行左右的完成事项，用来证明分页使用真实像素高度。", "第二项完成事项。", "第三项完成事项。",
		"下周计划", "第一项计划必须和标题留在同一页。", "第二项计划。", "风险", "无。", "需要协助", "无。谢谢。",
	]
	var pages: Array = ui._paginate_document_paragraphs(document_paragraphs, 220.0, 14, 24.0, 170.0)
	var reconstructed: Array[String] = []
	for page_index in pages.size():
		var page: Array = pages[page_index]
		for paragraph_value in page:
			reconstructed.append(str(paragraph_value))
		if page_index + 1 < pages.size() and not page.is_empty():
			_check(not ui._is_document_section_heading(str(page.back())), "document page %d never ends on an orphan section heading" % (page_index + 1))
	_check(reconstructed == document_paragraphs, "pixel document pagination preserves every paragraph in order")
	var weekly_report_body: Array[String] = ui._to_string_array(Dictionary(HiringContent.INTRANET_DOCS["weekly_report_91"]).get("body", []))
	var weekly_report_pages: Array = ui._paginate_document_paragraphs(weekly_report_body, 642.0, ui.TYPE_BODY, 24.0, 346.0)
	_check(weekly_report_pages.size() == 2 and Array(weekly_report_pages.back()).size() >= 4, "document pagination balances a sparse final sheet by moving one complete section")
	for weekly_page_index in weekly_report_pages.size() - 1:
		_check(not ui._is_document_section_heading(str(Array(weekly_report_pages[weekly_page_index]).back())), "balanced document page %d still avoids orphan headings" % (weekly_page_index + 1))

	_check(ui._infer_toast_kind("自动保存失败；没有覆盖上一份可用存档。") == "error", "save failure toast uses consequence red semantics")
	_check(ui._infer_toast_kind("算力不足：需要 8，当前 7") == "warning", "resource boundary toast uses caution amber semantics")
	_check(ui._infer_toast_kind("本周审阅已登记 · 你") == "success", "completed review toast uses confirmation green semantics")
	var original_motion: bool = ui.reduced_motion
	var original_event: Dictionary = ui.current_event.duplicate(true)
	var original_page: int = ui.current_event_page
	var original_elapsed: float = ui.event_page_elapsed
	ui.reduced_motion = true
	ui.current_event = {"silence_pages": [0], "page_hold_seconds": [120.0]}
	ui.current_event_page = 0
	ui.event_page_elapsed = 0.15
	_check(is_zero_approx(float(ui._motion_clock())) and is_zero_approx(float(ui._live_replay_min_phase_seconds())) and is_zero_approx(float(ui._layoff_social_min_phase_seconds())), "reduced motion freezes ambient loops and removes simulated-motion gates")
	_check(ui._event_page_can_advance(), "reduced motion caps authored silence interaction at 150 milliseconds")
	ui._set_reduced_motion(true)
	var saved_meta := _read_json_dictionary(META_PATH)
	_check(bool(saved_meta.get("reduced_motion", false)), "reduced-motion preference persists in local meta")
	ui.current_event = original_event
	ui.current_event_page = original_page
	ui.event_page_elapsed = original_elapsed
	ui._set_reduced_motion(original_motion)


func _test_employee_desk_and_window_population_contract(ui) -> void:
	var original_roster: Array = ui.model.employees.duplicate(true)
	var had_window_desks := bool(ui.model.flags.get("window_desks", false))
	ui.model.flags.erase("window_desks")
	ui.model.employees.clear()
	_check(str(ui._team_desk_signal()) == "none", "team UI shows no Chen desk signal before Chen Xiaoyu joins")
	ui.model.employees.append({"id": "chen_xiaoyu", "name": "陈小雨", "role": "数据工程师", "skill": 90.0, "morale": 72.0, "belief": 82.0, "active": true})
	_check(str(ui._team_desk_signal()) == "chen_three_cups", "team UI exposes the three unfinished cups only while Chen Xiaoyu is active")
	ui.model.employees[0]["active"] = false
	_check(str(ui._team_desk_signal()) == "none", "team UI removes Chen's desk signal once her employee record is departed")
	ui.model.employees.clear()
	var fixture: Dictionary = ui._window_population_fixture()
	_check(int(fixture.get("inside", 0)) == 33 and int(fixture.get("outside", 0)) == 4 and int(fixture.get("total", 0)) == 37, "window anomaly derives four exterior silhouettes from the explicit 33 inside + 4 outside = 37 fixture")
	_check(int(fixture.get("inside", 0)) + int(fixture.get("outside", 0)) == int(fixture.get("total", -1)), "window population fixture arithmetic is internally exact")
	ui.model.flags["window_desks"] = true
	_check(int(ui._team_administrative_count()) == int(fixture.get("total", 0)), "Team administrative total uses the same window population fixture")
	ui.model.employees.clear()
	for employee_value in original_roster:
		ui.model.employees.append(Dictionary(employee_value).duplicate(true))
	if had_window_desks:
		ui.model.flags["window_desks"] = true
	else:
		ui.model.flags.erase("window_desks")


func _test_four_choice_modal_layout(ui) -> void:
	ui.current_event = {"choices": [{}, {}, {}, {}]}
	var decision_sheet_bounds := Rect2(54, 290, 724, 390)
	var choice_rects: Array[Rect2] = []
	for index in 4:
		var rect: Rect2 = ui._event_choice_rect(index)
		choice_rects.append(rect)
		_check(decision_sheet_bounds.encloses(rect), "four-choice row %d stays inside the visible decision sheet" % (index + 1))
	for left in choice_rects.size():
		for right in range(left + 1, choice_rects.size()):
			_check(not choice_rects[left].intersects(choice_rects[right]), "four-choice decision cards %d and %d do not overlap" % [left + 1, right + 1])
	ui.current_event = {}


func _test_finale_window_curtain_state_machine(ui) -> void:
	ui.model.chapter = 4
	ui.model.week_in_chapter = 2
	ui.current_event.clear()
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	for key in ["window_desks", "window_curtain_open", "window_curtain_closed", "window_curtain_pending_reopen", "window_curtain_reopened", "window_curtain_interaction_required", "window_curtain_interaction_complete", "window_team_ui_requested"]:
		ui.model.flags.erase(key)
	ui.model.memory.erase("window_interface_visits")
	ui.model.memory.erase("window_curtain_close_count")
	ui.model.memory.erase("window_curtain_reopen_count")
	ui._open_event(HiringContent.get_fixed_event(4, 2))
	ui._close_event()
	_check(ui.screen == HiringMain.Screen.TEAM and ui._window_interaction_required(), "window setup routes directly into the required Team interaction")
	var terminal_before: int = ui.terminal_lines.size()
	var history_before: int = ui.model.history.size()
	var toast_before: String = str(ui.toast_text)
	var toast_timer_before: float = float(ui.toast_timer)

	_check(ui._window_anomaly_visible() and bool(ui.model.flags.get("window_curtain_open", false)), "first Team visit after the authored beat opens the anomalous window")
	_check(ui._window_exterior_person_count() == 4, "the open anomalous window derives exactly four exterior silhouettes")
	_check(ui._team_administrative_count() == 37, "the finale Team UI reports the authored thirty-seven-person administrative count")
	_check(ui.terminal_lines.size() == terminal_before and ui.model.history.size() == history_before and ui.current_event.is_empty(), "opening the anomalous Team view creates no terminal line, history, or event")
	_check(ui.toast_text == toast_before and is_equal_approx(float(ui.toast_timer), toast_timer_before), "opening the anomalous Team view creates no toast")
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	_check(ui.screen == HiringMain.Screen.TEAM and ui._window_interaction_required(), "the first anomalous Team visit cannot be left before the curtain is pulled")

	_click_ui(ui, ui._window_curtain_button_rect().get_center())
	_check(ui.screen == HiringMain.Screen.TEAM and not ui._window_anomaly_visible(), "pulling the curtain hides the anomaly without leaving Team")
	_check(bool(ui.model.flags.get("window_curtain_closed", false)) and bool(ui.model.flags.get("window_curtain_pending_reopen", false)) and not bool(ui.model.flags.get("window_curtain_open", true)), "curtain close records the closed and pending-reopen states")
	_check(int(ui.model.memory.get("window_curtain_close_count", 0)) == 1, "the explicit curtain interaction is recorded exactly once")
	_check(not ui._window_interaction_required() and bool(ui.model.flags.get("window_curtain_interaction_complete", false)), "the first explicit close releases the required administrative interaction")
	_check(ui.terminal_lines.size() == terminal_before and ui.model.history.size() == history_before and ui.current_event.is_empty(), "closing the curtain creates no terminal line, history, or event")
	_check(ui.toast_text == toast_before and is_equal_approx(float(ui.toast_timer), toast_timer_before), "closing the curtain creates no toast")

	ui._change_screen(HiringMain.Screen.TEAM)
	_check(not ui._window_anomaly_visible() and bool(ui.model.flags.get("window_curtain_closed", false)), "reselecting Team during the same visit cannot reopen the curtain")
	ui._save_game()
	var closed_save := _read_json_dictionary(SAVE_PATH)
	var closed_roundtrip = ui.CampaignDirector.new()
	var closed_resume: Dictionary = closed_roundtrip.resume(closed_save)
	_check(bool(closed_resume.get("ok", false)), "closed-curtain save resumes through CampaignDirector")
	_check(bool(closed_roundtrip.model.flags.get("window_curtain_closed", false)) and bool(closed_roundtrip.model.flags.get("window_curtain_pending_reopen", false)), "closed and pending curtain states survive a save roundtrip")

	ui._change_screen(HiringMain.Screen.DASHBOARD)
	terminal_before = ui.terminal_lines.size()
	history_before = ui.model.history.size()
	toast_before = ui.toast_text
	toast_timer_before = float(ui.toast_timer)
	ui._change_screen(HiringMain.Screen.TEAM)
	_check(ui._window_anomaly_visible() and bool(ui.model.flags.get("window_curtain_open", false)), "leaving Team and entering it again silently reopens the curtain")
	_check(not bool(ui.model.flags.get("window_curtain_closed", true)) and not bool(ui.model.flags.get("window_curtain_pending_reopen", true)) and bool(ui.model.flags.get("window_curtain_reopened", false)), "silent reentry persists the reopened state and clears the pending close")
	_check(int(ui.model.memory.get("window_curtain_reopen_count", 0)) == 1, "the next Team visit performs exactly one silent reopen")
	_check(ui.terminal_lines.size() == terminal_before and ui.model.history.size() == history_before and ui.current_event.is_empty(), "silent curtain reopen creates no terminal line, history, or event")
	_check(ui.toast_text == toast_before and is_equal_approx(float(ui.toast_timer), toast_timer_before), "silent curtain reopen creates no toast")
	var reopened_save := _read_json_dictionary(SAVE_PATH)
	var reopened_flags: Dictionary = Dictionary(reopened_save.get("model", {})).get("flags", {})
	_check(bool(reopened_flags.get("window_curtain_reopened", false)) and bool(reopened_flags.get("window_curtain_open", false)), "reopened curtain state is written to the campaign save")


func _test_origin_article_state_machine(ui) -> void:
	ui.model.chapter = 4
	ui.model.week_in_chapter = 3
	ui.current_event.clear()
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	for key in ["origin_attribution_realized", "origin_editor_open", "origin_editor_closed_without_change", "origin_article_unchanged", "origin_article_interaction_required", "origin_article_interaction_complete", "origin_article_ui_requested"]:
		ui.model.flags.erase(key)
	ui.model.memory.erase("origin_read_count")
	ui.model.memory.erase("origin_editor_close_count")
	var authored_source_body: Array = Array(ui.HiringContent.INTRANET_DOCS["our_origin"]["body"]).duplicate(true)
	ui._open_event(HiringContent.get_fixed_event(4, 3))
	ui._close_event()
	_check(ui.screen == HiringMain.Screen.INTRANET and ui._origin_interaction_required(), "origin setup routes directly into the required intranet interaction")
	_check(ui._select_intranet_document("our_origin"), "finale intranet exposes our_origin in its authored week")
	var rendered_source_body: Array = Array(ui._intranet_documents()[ui.selected_document].get("body", [])).duplicate(true)
	_check(int(ui.model.memory.get("origin_read_count", 0)) == 1, "first explicit origin open records read one")
	_check(not bool(ui.model.flags.get("origin_attribution_realized", false)) and not ui._origin_editor_is_open(), "first origin read exposes only the article, not the attribution or editor")
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	_check(ui.screen == HiringMain.Screen.INTRANET and ui._origin_interaction_required(), "the required origin reading cannot be left after its first read")

	ui._handle_intranet_click(ui._origin_reread_rect().get_center())
	_check(int(ui.model.memory.get("origin_read_count", 0)) == 2, "second explicit origin open records read two")
	_check(not bool(ui.model.flags.get("origin_attribution_realized", false)) and not ui._origin_editor_is_open(), "second origin read still exposes only the unchanged article")
	ui._save_game()
	var midpoint_save := _read_json_dictionary(SAVE_PATH)
	var midpoint_roundtrip = ui.CampaignDirector.new()
	var midpoint_resume: Dictionary = midpoint_roundtrip.resume(midpoint_save)
	_check(bool(midpoint_resume.get("ok", false)) and int(midpoint_roundtrip.model.memory.get("origin_read_count", 0)) == 2, "second-read origin state survives a director save roundtrip without an implicit third read")
	_check(bool(midpoint_roundtrip.model.flags.get("origin_article_interaction_required", false)), "midpoint save retains the required origin interaction gate")

	ui._handle_intranet_click(ui._origin_reread_rect().get_center())
	_check(int(ui.model.memory.get("origin_read_count", 0)) == 3, "third explicit origin open caps the persistent read count at three")
	_check(bool(ui.model.flags.get("origin_attribution_realized", false)) and ui._origin_editor_is_open(), "third origin read reveals Lin's attribution and opens the editor overlay")
	_check(ui._origin_editor_close_rect().size.x > 0.0, "the third-read editor exposes an explicit close-without-change control")

	_click_ui(ui, ui._content_back_rect().get_center())
	_check(ui.screen == HiringMain.Screen.INTRANET and ui._origin_editor_is_open(), "ordinary navigation cannot bypass the required editor-close action")
	_click_ui(ui, ui._origin_editor_close_rect().get_center())
	_check(not ui._origin_editor_is_open() and bool(ui.model.flags.get("origin_editor_closed_without_change", false)), "explicit close dismisses the editor and records close-without-change")
	_check(bool(ui.model.flags.get("origin_article_unchanged", false)) and int(ui.model.memory.get("origin_editor_close_count", 0)) == 1, "editor close records that the article was left unchanged exactly once")
	_check(not ui._origin_interaction_required() and bool(ui.model.flags.get("origin_article_interaction_complete", false)), "unchanged close releases the origin interaction gate")

	ui._handle_intranet_click(ui._document_rect(ui.selected_document).get_center())
	_check(int(ui.model.memory.get("origin_read_count", 0)) == 3 and not ui._origin_editor_is_open(), "fourth origin read neither increments nor replays the editor")
	var rendered_document: Dictionary = ui._intranet_documents()[ui.selected_document]
	_check(Array(rendered_document.get("body", [])) == rendered_source_body and Array(ui.HiringContent.INTRANET_DOCS["our_origin"]["body"]) == authored_source_body, "origin editor never mutates either the rendered article or authored source")

	ui._save_game()
	var origin_save := _read_json_dictionary(SAVE_PATH)
	var origin_resume: Dictionary = ui.director.resume(origin_save)
	_check(bool(origin_resume.get("ok", false)), "completed origin interaction resumes through CampaignDirector")
	ui.model = ui.director.model
	_check(int(ui.model.memory.get("origin_read_count", 0)) == 3 and bool(ui.model.flags.get("origin_editor_closed_without_change", false)), "origin read and unchanged-close states survive save/resume")
	_check(ui._select_intranet_document("our_origin"), "resumed finale still resolves the same origin document")
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	ui._change_screen(HiringMain.Screen.INTRANET)
	_check(int(ui.model.memory.get("origin_read_count", 0)) == 3 and not ui._origin_editor_is_open(), "opening origin after resume does not replay the third-read realization")


func _test_board_ai_presentation_state_machine(ui) -> void:
	ui.model.chapter = 4
	ui.model.week_in_chapter = 6
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	for key in ["board_delegated", "board_resolved", "board_presentation_active", "board_presentation_complete"]:
		ui.model.flags.erase(key)
	for key in ["board_presentation_phase", "board_presentation_animation_complete", "board_presentation_completion_count"]:
		ui.model.memory.erase(key)
	var terminal_before: int = ui.terminal_lines.size()
	var board_event: Dictionary = HiringContent.get_fixed_event(4, 6)
	ui._open_event(board_event)
	var delegate_index := -1
	for index in Array(ui.current_event.get("choices", [])).size():
		if str(Dictionary(ui.current_event["choices"][index]).get("id", "")) == "delegate":
			delegate_index = index
			break
	_check(delegate_index >= 0, "board event exposes its canonical AI delegation choice")
	if delegate_index < 0:
		return
	ui._choose_event_option(delegate_index)
	_check(ui.screen == HiringMain.Screen.BOARD_PRESENTATION, "board AI choice opens the dedicated deck presentation rather than a generic result modal")
	_check(bool(ui.model.flags.get("board_delegated", false)) and bool(ui.model.flags.get("board_presentation_active", false)), "board delegation begins a persistent active presentation")
	_check(ui.result_lines.is_empty() and ui.terminal_lines.size() == terminal_before, "dedicated board takeover emits neither a generic result payload nor a terminal notification")
	_check(ui.BOARD_ORG_ACTIVE_COUNT + ui.BOARD_ORG_EXIT_COUNT == 37 and ui.BOARD_ORG_ACTIVE_COUNT > ui.BOARD_ORG_EXIT_COUNT, "board organization chart contains thirty-seven boxes with more green than red")
	var board_copy := "\n".join(ui._board_presentation_copy())
	for term in ["投资人 A", "没有人注意到", "二十分钟"]:
		_check(board_copy.contains(term), "dedicated board aftermath retains authored term '%s'" % term)

	ui.screen_time = 0.1
	ui._advance_board_presentation()
	_check(ui.screen == HiringMain.Screen.BOARD_PRESENTATION and str(ui.model.memory.get("board_presentation_phase", "")) == "chart", "first accessible continue skips only the board page-change animation")
	_check(bool(ui.model.memory.get("board_presentation_animation_complete", false)) and is_equal_approx(ui._board_transition_progress(), 1.0), "animation skip leaves the complete organization chart on screen")
	ui._save_game()
	var chart_save := _read_json_dictionary(SAVE_PATH)
	var chart_roundtrip = ui.CampaignDirector.new()
	var chart_resume: Dictionary = chart_roundtrip.resume(chart_save)
	_check(bool(chart_resume.get("ok", false)) and bool(chart_roundtrip.model.flags.get("board_presentation_active", false)), "active board chart survives a director save roundtrip")
	_check(str(chart_roundtrip.model.memory.get("board_presentation_phase", "")) == "chart" and bool(chart_roundtrip.model.memory.get("board_presentation_animation_complete", false)), "save preserves the completed animation phase without replaying the choice")

	ui._advance_board_presentation()
	_check(str(ui.model.memory.get("board_presentation_phase", "")) == "aftermath" and ui.screen == HiringMain.Screen.BOARD_PRESENTATION, "next continue advances to the dedicated meeting aftermath page")
	ui._change_screen(HiringMain.Screen.DASHBOARD)
	_check(ui.screen == HiringMain.Screen.BOARD_PRESENTATION, "ordinary screen navigation cannot bypass an active board presentation")
	ui._save_game()
	var aftermath_save := _read_json_dictionary(SAVE_PATH)
	var aftermath_roundtrip = ui.CampaignDirector.new()
	var aftermath_resume: Dictionary = aftermath_roundtrip.resume(aftermath_save)
	_check(bool(aftermath_resume.get("ok", false)) and str(aftermath_roundtrip.model.memory.get("board_presentation_phase", "")) == "aftermath", "board aftermath phase is save-stable")

	ui._advance_board_presentation()
	_check(not bool(ui.model.flags.get("board_presentation_active", true)) and bool(ui.model.flags.get("board_presentation_complete", false)), "final continue completes the board presentation exactly once")
	_check(int(ui.model.memory.get("board_presentation_completion_count", 0)) == 1 and ui.screen != HiringMain.Screen.BOARD_PRESENTATION, "completed board presentation releases the player back to campaign flow")


func _test_live_replay_and_layoff_social_state_machines(ui) -> void:
	var started: Dictionary = ui.director.start_company("录像回放科技", false)
	_check(bool(started.get("ok", false)), "live-replay fixture starts a clean campaign")
	ui.model = ui.director.model
	ui.director.resolve_event("garage_opening")
	ui.model.chapter = 2
	ui.model.week_in_chapter = 6
	ui.model.total_week = 17
	ui.model.cash_weeks = 100.0
	ui.model.memory["action_counts"] = {"demo_video": 1}
	var live_event: Dictionary = ui.director.next_event()
	_check(str(live_event.get("id", "")) == "live_demo" and str(live_event.get("_director_key", "")) == "2:6", "live demo enters the UI through the production fixed-event scheduler")
	ui._open_event(live_event)
	var live_delegate := _choice_index_by_id(ui.current_event, "delegate")
	_check(live_delegate >= 0, "live demo exposes its canonical delegated choice")
	if live_delegate >= 0:
		ui._choose_event_option(live_delegate)
		_check(ui.screen == HiringMain.Screen.LIVE_REPLAY and bool(ui.model.flags.get("live_replay_active", false)), "delegated live demo opens the dedicated replay instead of generic result prose")
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "client_signed" and ui.result_lines.is_empty(), "replay begins at the signed-client handoff with no duplicate result modal")
		_check("\n".join(ui._live_replay_client_signed_copy()).contains("比视频里还清楚"), "used-demo replay preserves the source client's video-specific compliment")
		_check("\n".join(ui._live_replay_file_transition_copy()).contains("回办公室的路上") and "\n".join(ui._live_replay_file_transition_copy()).contains("晚上你调了会议录像"), "the dedicated replay visibly retains the road-home thought before opening the file at night")
		var replay_visual: Dictionary = ui._live_replay_visual_contract()
		_check(not bool(replay_visual.get("protagonist_face_visible", true)) and bool(replay_visual.get("gesture_animation", false)), "meeting replay animates the protagonist's hands while keeping the no-face world contract")
		_check(str(replay_visual.get("mouth_sync_surface", "")) == "authored_observation" and bool(replay_visual.get("caption_pause", false)) and bool(replay_visual.get("waveform_pause", false)), "mouth agreement remains an authored observation while the abnormal pause has visible caption and waveform evidence")
		ui._advance_live_replay()
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "client_signed", "the signed-client handoff cannot be skipped before its first visible hold")
		ui.screen_time = ui._live_replay_min_phase_seconds()
		var replay_click := InputEventMouseButton.new()
		replay_click.button_index = MOUSE_BUTTON_LEFT
		replay_click.pressed = true
		replay_click.position = ui._live_replay_continue_rect().get_center()
		ui._unhandled_input(replay_click)
		ui._unhandled_input(replay_click)
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "playback" and Array(ui.model.memory.get("live_replay_transitions", [])).size() == 2, "a rapid double-click opens playback exactly once and cannot skip its timed animation")
		ui.screen_time = ui.LIVE_REPLAY_MIN_PLAY_SECONDS - 0.01
		ui._advance_live_replay()
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "playback", "the replay cannot be advanced before its minimum visible animation")
		ui.screen_time = ui.LIVE_REPLAY_MIN_PLAY_SECONDS
		ui._advance_live_replay()
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "we_pause", "the playback reaches a separate frozen 'we' pause phase")
		ui._save_game()
		ui.screen = HiringMain.Screen.ONBOARDING
		ui._continue_game()
		_check(ui.screen == HiringMain.Screen.LIVE_REPLAY and str(ui.model.memory.get("live_replay_phase", "")) == "we_pause", "continue restores the exact active live-replay phase without replaying the choice")
		ui._change_screen(HiringMain.Screen.DASHBOARD)
		_check(ui.screen == HiringMain.Screen.LIVE_REPLAY, "ordinary navigation cannot bypass an active live replay")
		ui._advance_live_replay()
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "we_pause", "the abnormal 'we' pause remains visible after resume for its full authored hold")
		ui.screen_time = ui._live_replay_min_phase_seconds()
		var replay_key := InputEventKey.new()
		replay_key.keycode = KEY_ENTER
		replay_key.pressed = true
		ui._unhandled_input(replay_key)
		ui._unhandled_input(replay_key)
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "replay" and Array(ui.model.memory.get("live_replay_transitions", [])).size() == 4, "a rapid repeated Enter scrubs back exactly once instead of skipping the second playback")
		ui.screen_time = ui.LIVE_REPLAY_MIN_PLAY_SECONDS - 0.01
		ui._advance_live_replay()
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "replay", "the second viewing remains visible for its authored minimum duration")
		ui.screen_time = ui.LIVE_REPLAY_MIN_PLAY_SECONDS
		ui._advance_live_replay()
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "aftermath", "finishing the second viewing reaches the quiet admission that it was good")
		ui._advance_live_replay()
		_check(str(ui.model.memory.get("live_replay_phase", "")) == "aftermath", "the final admission cannot be dismissed before it has rendered")
		ui.screen_time = ui._live_replay_min_phase_seconds()
		ui._advance_live_replay()
		_check(bool(ui.model.flags.get("live_replay_complete", false)) and not bool(ui.model.flags.get("live_replay_active", true)), "final replay acknowledgement completes the presentation exactly once")
		_check(Array(ui.model.memory.get("live_replay_transitions", [])) == ["client_signed", "playback", "we_pause", "replay", "aftermath", "complete"], "live replay preserves the complete deterministic transition history")
		var completed_replay_transitions: Array = Array(ui.model.memory.get("live_replay_transitions", [])).duplicate()
		ui._advance_live_replay()
		_check(Array(ui.model.memory.get("live_replay_transitions", [])) == completed_replay_transitions, "input after replay completion cannot duplicate its transition or campaign effects")
		var live_save: Dictionary = ui.director.save_payload()
		var live_after_completion: Dictionary = ui.director.next_event()
		_check(bool(Dictionary(live_save.get("resolved_fixed_keys", {})).get("2:6", false)) and bool(Dictionary(live_save.get("seen_event_ids", {})).get("live_demo", false)), "the replay route records the production fixed event as resolved and seen")
		_check(str(ui.current_event.get("id", "")) != "live_demo" and str(live_after_completion.get("id", "")) != "live_demo", "completing the replay cannot reopen the same fixed live-demo event")

	started = ui.director.start_company("材料回放科技", false)
	_check(bool(started.get("ok", false)), "never-made-demo replay fixture starts a clean campaign")
	ui.model = ui.director.model
	ui.director.resolve_event("garage_opening")
	ui.model.chapter = 2
	ui.model.week_in_chapter = 6
	ui.model.total_week = 17
	ui.model.cash_weeks = 100.0
	ui.model.memory["action_counts"] = {}
	var no_demo_event: Dictionary = ui.director.next_event()
	_check(str(no_demo_event.get("id", "")) == "live_demo" and str(no_demo_event.get("_director_demo_route", "")) == "never_used", "never-made-demo live meeting enters through its production director variant")
	ui._open_event(no_demo_event)
	var no_demo_delegate := _choice_index_by_id(ui.current_event, "delegate")
	_check(no_demo_delegate >= 0, "never-made-demo meeting retains its delegated route")
	if no_demo_delegate >= 0:
		ui._choose_event_option(no_demo_delegate)
		var no_demo_signed_copy := "\n".join(ui._live_replay_client_signed_copy())
		_check(no_demo_signed_copy.contains("比材料里还清楚") and not no_demo_signed_copy.contains("比视频里还清楚"), "never-made-demo replay preserves the material-specific compliment instead of inventing a video")
		_check("\n".join(ui._live_replay_file_transition_copy()).contains("回办公室的路上"), "never-made-demo replay also preserves the authored road-home transition")

	started = ui.director.start_company("改期回放科技", false)
	_check(bool(started.get("ok", false)), "postponed-return replay fixture starts a clean campaign")
	ui.model = ui.director.model
	ui.director.resolve_event("garage_opening")
	ui.model.chapter = 2
	ui.model.week_in_chapter = 9
	ui.model.total_week = 21
	ui.model.cash_weeks = 100.0
	ui.model.capability = 74.0
	ui.model.flags["live_demo_return_scheduled"] = true
	ui.model.memory["live_demo_return_due_total_week"] = 21
	var lin_before_return: Dictionary = ui.director.next_event()
	_check(str(lin_before_return.get("id", "")) == "lin_scene_3", "the authored Lin scene keeps production priority over a due postponed demo")
	_check(bool(ui.director.resolve_event(lin_before_return, "admit").get("ok", false)), "the priority Lin scene resolves through the director before the postponed meeting")
	var return_event: Dictionary = ui.director.next_event()
	_check(str(return_event.get("id", "")) == "live_demo_return" and int(return_event.get("_director_due_total_week", -1)) == 21, "the due postponed demo enters the UI through the production scheduled-event path")
	ui._open_event(return_event)
	var return_delegate := _choice_index_by_id(ui.current_event, "delegate")
	_check(return_delegate >= 0, "the postponed demo return retains its delegated route")
	if return_delegate >= 0:
		ui._choose_event_option(return_delegate)
		var return_replay_copy := JSON.stringify(ui.model.memory.get("live_replay_result_copy", []))
		_check(ui.screen == HiringMain.Screen.LIVE_REPLAY and str(ui.model.memory.get("live_replay_source_event_id", "")) == "live_demo_return", "delegating the postponed return reuses the source-aware identity replay")
		_check(return_replay_copy.contains("接管了现场说明") and not return_replay_copy.contains("视频里还清楚"), "the return replay preserves its own settlement copy instead of borrowing the first meeting's handoff")
		for _return_phase in 6:
			if not bool(ui.model.flags.get("live_replay_active", false)):
				break
			ui.screen_time = ui._live_replay_min_phase_seconds()
			ui._advance_live_replay()
		_check(Array(ui.model.memory.get("live_replay_transitions", [])) == ["client_signed", "playback", "we_pause", "replay", "aftermath", "complete"], "the postponed return completes the same protected replay sequence")
		var return_after_completion: Dictionary = ui.director.next_event()
		_check(bool(ui.model.flags.get("live_demo_return_resolved", false)) and bool(Dictionary(ui.director.save_payload().get("seen_event_ids", {})).get("live_demo_return", false)), "the source-aware replay resolves and clears the persisted postponed return")
		_check(str(ui.current_event.get("id", "")) != "live_demo_return" and str(return_after_completion.get("id", "")) != "live_demo_return", "completing the postponed replay cannot reopen its scheduled event")

	started = ui.director.start_company("三次点赞科技", false)
	_check(bool(started.get("ok", false)), "layoff-social fixture starts a clean campaign")
	ui.model = ui.director.model
	ui.director.resolve_event("garage_opening")
	ui.model.chapter = 3
	ui.model.week_in_chapter = 7
	ui.model.total_week = 30
	ui.model.cash_weeks = 100.0
	ui.model.flags["layoffs_required"] = true
	ui.model.flags["promised_no_layoffs"] = true
	ui.model.memory["no_layoff_promise_total_week"] = 24
	ui.model.memory["no_layoff_promise_reaction_count"] = 41
	var layoff_event: Dictionary = ui.director.next_event()
	_check(str(layoff_event.get("id", "")) == "layoff_execution" and str(layoff_event.get("_director_key", "")) == "3:7", "layoff execution enters the UI through the production fixed-event scheduler")
	ui._open_event(layoff_event)
	var layoff_delegate := _choice_index_by_id(ui.current_event, "delegate")
	_check(layoff_delegate >= 0, "layoff execution exposes its canonical delegated choice")
	if layoff_delegate >= 0:
		ui._choose_event_option(layoff_delegate)
		_check(ui.screen == HiringMain.Screen.LAYOFF_SOCIAL and bool(ui.model.flags.get("layoff_social_active", false)), "delegated layoff opens the dedicated social presentation instead of flattening it into prose")
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "process_complete" and str(ui.model.memory.get("layoff_social_like_state", "")) == "unseen", "layoff presentation starts after the six-meeting process and before opening the post")
		var process_copy := "\n".join(ui._layoff_social_process_lines())
		_check(process_copy.contains("第 24 周") and process_copy.contains("希望是当面说"), "the dedicated presentation retains the promised-layoff callback from the resolved choice")
		ui._advance_layoff_social()
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "process_complete", "the completed notification process cannot be skipped before all personalized lines render")
		ui.screen_time = ui._layoff_social_min_phase_seconds()
		var social_click := InputEventMouseButton.new()
		social_click.button_index = MOUSE_BUTTON_LEFT
		social_click.pressed = true
		social_click.position = ui._layoff_social_continue_rect().get_center()
		ui._unhandled_input(social_click)
		ui._unhandled_input(social_click)
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "post_visible" and Array(ui.model.memory.get("layoff_social_transitions", [])).size() == 2, "a rapid double-click opens the post exactly once without skipping the unliked state")
		ui._advance_layoff_social()
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "post_visible", "the former employee's post remains visible before the first like")
		ui.screen_time = ui._layoff_social_min_phase_seconds()
		ui._advance_layoff_social()
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "liked_once" and str(ui.model.memory.get("layoff_social_like_state", "")) == "liked", "first input visibly likes the post")
		var liked_midpoint: Dictionary = ui._layoff_social_heart_visual_state("liked_once", ui.LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS * 0.5)
		_check(bool(liked_midpoint.get("filled", false)) and float(liked_midpoint.get("scale", 1.0)) > 1.0, "the first like has a real overshoot animation rather than a static heart swap")
		_check(ui.LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS < ui._layoff_social_min_phase_seconds(), "each social heart transition settles before its phase can advance")
		ui._save_game()
		ui.screen = HiringMain.Screen.ONBOARDING
		ui._continue_game()
		_check(ui.screen == HiringMain.Screen.LAYOFF_SOCIAL and str(ui.model.memory.get("layoff_social_phase", "")) == "liked_once", "continue restores the exact first-like phase")
		ui._change_screen(HiringMain.Screen.DASHBOARD)
		_check(ui.screen == HiringMain.Screen.LAYOFF_SOCIAL, "ordinary navigation cannot bypass the active like sequence")
		ui._advance_layoff_social()
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "liked_once", "the first like remains visible after resume for its protected hold")
		ui.screen_time = ui._layoff_social_min_phase_seconds()
		ui._advance_layoff_social()
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "unliked" and str(ui.model.memory.get("layoff_social_like_state", "")) == "unliked", "second input visibly cancels the like")
		var unliked_midpoint: Dictionary = ui._layoff_social_heart_visual_state("unliked", ui.LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS * 0.5)
		_check(not bool(unliked_midpoint.get("filled", true)) and float(unliked_midpoint.get("fading_fill_alpha", 0.0)) > 0.0, "unlike visibly drains the previous red fill beneath the ordinary outline")
		ui.screen_time = ui._layoff_social_min_phase_seconds()
		ui._advance_layoff_social()
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "reliked" and str(ui.model.memory.get("layoff_social_like_state", "")) == "liked_final", "third input visibly likes the post again")
		var reliked_midpoint: Dictionary = ui._layoff_social_heart_visual_state("reliked", ui.LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS * 0.5)
		_check(bool(reliked_midpoint.get("filled", false)) and float(reliked_midpoint.get("scale", 1.0)) > 1.0, "the final re-like repeats the visible heart animation")
		ui._advance_layoff_social()
		_check(str(ui.model.memory.get("layoff_social_phase", "")) == "reliked", "the final like cannot be dismissed before its animation settles")
		ui.screen_time = ui._layoff_social_min_phase_seconds()
		ui._advance_layoff_social()
		_check(bool(ui.model.flags.get("layoff_social_complete", false)) and not bool(ui.model.flags.get("layoff_social_active", true)), "putting down the phone completes the delegated layoff presentation")
		_check(Array(ui.model.memory.get("layoff_social_transitions", [])) == ["process_complete", "post_visible", "liked_once", "unliked", "reliked", "complete"], "layoff presentation preserves the exact open-like-unlike-relike transition history")
		var completed_social_transitions: Array = Array(ui.model.memory.get("layoff_social_transitions", [])).duplicate()
		ui._advance_layoff_social()
		_check(Array(ui.model.memory.get("layoff_social_transitions", [])) == completed_social_transitions, "input after the social sequence cannot duplicate transitions or layoff effects")
		var layoff_save: Dictionary = ui.director.save_payload()
		var layoff_after_completion: Dictionary = ui.director.next_event()
		_check(bool(Dictionary(layoff_save.get("resolved_fixed_keys", {})).get("3:7", false)) and bool(Dictionary(layoff_save.get("seen_event_ids", {})).get("layoff_execution", false)), "the social route records the production layoff event as resolved and seen")
		_check(str(ui.current_event.get("id", "")) != "layoff_execution" and str(layoff_after_completion.get("id", "")) != "layoff_execution", "completing the social presentation cannot reopen the same fixed layoff event")


func _test_second_time_and_ending_resume() -> void:
	var ui = HiringMain.new()
	ui.save_path_override = FINALE_SAVE_PATH
	ui.meta_path_override = FINALE_META_PATH
	root.add_child(ui)
	await process_frame
	ui.second_run_unlocked = true
	ui.name_edit.text = "回声科技"
	ui._start_new_company()
	_check(ui.screen == HiringMain.Screen.EVENT and str(ui.current_event.get("id", "")) == "second_time_opening", "completed meta starts the dedicated Second Time opening")
	_check(str(ui.model.memory.get("second_time_cup_phase", "")) == ui.SECOND_TIME_PHASE_PRESENT and str(ui.model.memory.get("second_time_cup_position", "")) == "founder_desk", "Second Time begins with the impossible cup physically on the founder desk")
	var setup_copy := JSON.stringify(ui.current_event.get("body", []))
	_check(not setup_copy.contains("拿起来") and not setup_copy.contains("哪来的") and not setup_copy.contains("靠窗第二"), "Second Time setup copy does not pre-narrate any required player interaction")

	ui._advance_second_time_interaction()
	_check(str(ui.model.memory.get("second_time_cup_phase", "")) == ui.SECOND_TIME_PHASE_HELD and str(ui.model.memory.get("second_time_cup_position", "")) == "held", "first explicit interaction picks up and views the cup")
	_check(bool(ui.model.flags.get("second_time_cup_picked_up", false)) and FileAccess.file_exists(FINALE_SAVE_PATH), "held-cup midpoint is persisted immediately")
	_dispose_ui(ui)
	await process_frame

	var resumed = HiringMain.new()
	resumed.save_path_override = FINALE_SAVE_PATH
	resumed.meta_path_override = FINALE_META_PATH
	root.add_child(resumed)
	await process_frame
	resumed._continue_game()
	_check(resumed.screen == HiringMain.Screen.EVENT and str(resumed.model.memory.get("second_time_cup_phase", "")) == resumed.SECOND_TIME_PHASE_HELD, "continue restores the exact held-cup NG+ phase")
	_check(str(resumed.model.memory.get("second_time_cup_position", "")) == "held" and str(resumed.current_event.get("id", "")) == "second_time_opening", "NG+ resume restores both physical cup position and unresolved authored choice")
	resumed._advance_second_time_interaction()
	_check(str(resumed.model.memory.get("second_time_cup_phase", "")) == resumed.SECOND_TIME_PHASE_QUESTION and bool(resumed.model.flags.get("second_time_cup_replaced", false)), "second explicit interaction replaces the cup before Lin enters")
	_check(bool(resumed.model.flags.get("second_time_lin_entered", false)) and resumed._event_choices_visible(), "Lin's entrance and question appear only after replacement")
	var choices: Array = resumed.current_event.get("choices", [])
	_check(choices.size() == 2 and not bool(Dictionary(choices[0]).get("ai", true)) and not bool(Dictionary(choices[1]).get("ai", true)), "Second Time question exposes exactly two non-AI answers")
	resumed._choose_event_option(0)
	_check(str(resumed.model.memory.get("second_time_cup_phase", "")) == resumed.SECOND_TIME_PHASE_ANSWERED and bool(resumed.model.flags.get("second_time_lin_answered", false)), "first answer advances into Lin's shrug/computer beat without generic result prose")
	resumed._advance_second_time_interaction()
	var first_branch_state := {
		"phase": str(resumed.model.memory.get("second_time_cup_phase", "")),
		"position": str(resumed.model.memory.get("second_time_cup_position", "")),
		"placed": bool(resumed.model.flags.get("second_time_cup_placed", false)),
		"answered": bool(resumed.model.flags.get("second_time_lin_answered", false)),
	}
	_check(first_branch_state == {"phase": resumed.SECOND_TIME_PHASE_PLACED, "position": "window_second_desk", "placed": true, "answered": true}, "first answer ends with the cup at the empty second window desk")
	resumed._advance_second_time_interaction()
	_check(resumed.screen == HiringMain.Screen.DASHBOARD and resumed.current_event.is_empty() and bool(resumed.model.flags.get("second_time_cup_interaction_complete", false)), "completed cup placement continues directly into the playable first week without replaying the first-run prologue")
	_check(resumed.seen_endings.has("second_time"), "completing the interactive Second Time opening registers the seventh archive entry")

	resumed.second_run_unlocked = true
	resumed.name_edit.text = "回声科技"
	resumed._start_new_company()
	resumed._advance_second_time_interaction()
	resumed._advance_second_time_interaction()
	resumed._choose_event_option(1)
	resumed._advance_second_time_interaction()
	var second_branch_state := {
		"phase": str(resumed.model.memory.get("second_time_cup_phase", "")),
		"position": str(resumed.model.memory.get("second_time_cup_position", "")),
		"placed": bool(resumed.model.flags.get("second_time_cup_placed", false)),
		"answered": bool(resumed.model.flags.get("second_time_lin_answered", false)),
	}
	_check(second_branch_state == first_branch_state, "both authored '不知道' branches produce exactly the same Lin and cup-placement state")

	resumed.model.company_name = "可恢复公司"
	resumed._open_ending("successor")
	_check(resumed.screen == HiringMain.Screen.ENDING and FileAccess.file_exists(FINALE_SAVE_PATH), "opening an ending retains the campaign save until the player reads it")
	var opening_ending_save := _read_json_dictionary(FINALE_SAVE_PATH)
	_check(str(opening_ending_save.get("ui_current_ending_id", "")) == "successor" and opening_ending_save.get("ui_current_ending", null) is Dictionary, "ending save stores identity and complete authored body")
	_check(int(opening_ending_save.get("ui_ending_page", -1)) == 0 and str(Dictionary(opening_ending_save.get("model", {})).get("company_name", "")) == "可恢复公司", "ending save stores page zero and the rendered company context")
	var ending_pages: Array = resumed._ending_pages()
	_check(ending_pages.size() > 1, "successor ending fixture has multiple pages for resume coverage")
	resumed._advance_ending()
	_check(resumed.ending_page == 1 and FileAccess.file_exists(FINALE_SAVE_PATH), "advancing an ending page updates the save without clearing it")
	_dispose_ui(resumed)
	await process_frame

	var ending_resume = HiringMain.new()
	ending_resume.save_path_override = FINALE_SAVE_PATH
	ending_resume.meta_path_override = FINALE_META_PATH
	root.add_child(ending_resume)
	await process_frame
	ending_resume._continue_game()
	_check(ending_resume.screen == HiringMain.Screen.ENDING and ending_resume.current_ending_id == "successor" and ending_resume.ending_page == 1, "continue returns directly to the exact saved ending page")
	_check(ending_resume.model.company_name == "可恢复公司" and not ending_resume.current_ending.is_empty(), "ending resume preserves company interpolation state and authored body")
	var guard := 24
	while ending_resume.screen == HiringMain.Screen.ENDING and guard > 0:
		ending_resume._advance_ending()
		guard -= 1
	_check(guard > 0 and ending_resume.screen == HiringMain.Screen.ONBOARDING, "ending playback reaches onboarding only after every page")
	_check(not FileAccess.file_exists(FINALE_SAVE_PATH), "completed ending playback clears the campaign save only after final acknowledgement")
	var meta := _read_json_dictionary(FINALE_META_PATH)
	_check(bool(meta.get("second_run", false)) and str(meta.get("last_ending", "")) == "successor", "deferred campaign clearing retains the persistent NG+ unlock and last ending")
	_check(Array(meta.get("seen_endings", [])).has("second_time") and Array(meta.get("seen_endings", [])).has("successor"), "ending archive persists both the interactive Second Time route and a conventional ending across restart")
	_dispose_ui(ending_resume)
	await process_frame


func _perform_ui_action(ui, action_id: String, use_ai: bool) -> void:
	var index: int = ui.week_action_ids.find(action_id)
	_check(index >= 0, "action card '%s' is present in the UI pool" % action_id)
	if index < 0:
		return
	ui.selected_action = index
	ui._take_selected_action(use_ai)
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT or ui.screen == HiringMain.Screen.SIGNATURE, "action '%s' produces a UI result state" % action_id)


func _prepared_preview_game(chapter_index: int, week_index: int):
	var game = HiringModel.new()
	game.reset("Preview Contract")
	game.chapter = chapter_index
	game.week_in_chapter = week_index
	game.total_week = 1
	game.week_active = true
	game.week_resolved = false
	game.campaign_complete = false
	game.attention_max = 1 if chapter_index == 4 else 3
	game.attention = game.attention_max
	game.cash_weeks = 100.0
	game.compute = 100.0
	game.narrative = 50.0
	game.capability = 20.0
	game.coherence = 80.0
	game.debt = 20.0
	game.performed_actions.clear()
	game.flags.erase("ai_used_this_week")
	return game


func _choice_index_by_id(event: Dictionary, choice_id: String) -> int:
	var choices: Array = event.get("choices", [])
	for index in choices.size():
		if choices[index] is Dictionary and str(Dictionary(choices[index]).get("id", "")) == choice_id:
			return index
	return -1


func _click_ui(ui, position: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = position
	ui._unhandled_input(click)


func _rendered_ending_text(ui) -> String:
	var paragraphs: Array[String] = []
	for page_value in ui._ending_pages():
		if not page_value is Array:
			continue
		for paragraph_value in page_value:
			paragraphs.append(str(paragraph_value))
	return "\n".join(paragraphs)


func _close_all_result_pages(ui) -> void:
	for _guard in 12:
		if ui.screen != HiringMain.Screen.ACTION_RESULT:
			return
		ui._close_result()
	_fail("UI result pagination exceeded its guard")


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
	# Headless audio has no device callback to release loop playbacks naturally.
	# Stop them explicitly so this contract test exits without leaked objects.
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
