extends SceneTree

const HiringMain = preload("res://src/hiring_main.gd")
const OfficeAudio = preload("res://src/office_audio.gd")
const HiringStorage = preload("res://src/hiring_storage.gd")

var save_path := "user://hiring_audio_integration_save_%d.json" % OS.get_process_id()
var meta_path := "user://hiring_audio_integration_meta_%d.json" % OS.get_process_id()
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_clear_test_storage()
	var ui = HiringMain.new()
	ui.save_path_override = save_path
	ui.meta_path_override = meta_path
	root.add_child(ui)
	await process_frame

	_test_runtime_audio_graph(ui)
	var context_foley_count := int(ui.office_audio._foley_play_count)
	_test_scene_context_mapping(ui)
	_test_anomaly_silence_contract(ui)
	_test_silent_shortcuts_and_locked_navigation(ui)
	_check(
		int(ui.office_audio._foley_play_count) == context_foley_count,
		"scene/context updates never manufacture a foley cue"
	)
	_test_direct_action_foley(ui)
	_test_visible_page_persistence(ui)

	_dispose_ui(ui)
	await process_frame
	_clear_test_storage()
	if failures.is_empty():
		print("HIRING_AUDIO_INTEGRATION_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_AUDIO_INTEGRATION_TEST_FAILURE: " + failure)
		quit(1)


func _test_runtime_audio_graph(ui) -> void:
	_check(ui.office_audio != null and ui.office_audio.get_parent() == ui, "HiringMain owns one live OfficeAudio graph")
	_check(AudioServer.get_bus_index(&"Ambience") >= 0, "project bus layout exposes Ambience")
	_check(AudioServer.get_bus_index(&"Music") >= 0, "project bus layout exposes Music")
	_check(AudioServer.get_bus_index(&"Foley") >= 0, "project bus layout exposes Foley")


func _test_scene_context_mapping(ui) -> void:
	# The title is alive before the first click: rain and music establish the world,
	# while office machinery stays out until the cold open begins.
	ui.settings_open = false
	ui.screen = HiringMain.Screen.ONBOARDING
	ui.current_event.clear()
	_apply_main_audio_context(ui)
	var context: Dictionary = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "title", "onboarding maps to the authored title sound field")
	_check(str(context.get("silence_mode", "")) == "normal", "onboarding requests the normal restrained title mix")
	_check(str(ui.office_audio._scene_context.get("screen", "")) == "title", "HiringMain pushes title context into OfficeAudio")
	_check(float(ui.office_audio._target_rain) > OfficeAudio.SILENT_DB and float(ui.office_audio._target_score_human) > OfficeAudio.SILENT_DB, "title context makes rain and the human theme audible")
	_check(is_equal_approx(float(ui.office_audio._target_server_fan), OfficeAudio.SILENT_DB), "title context keeps office machinery outside the frame")

	# The first-day cold open uses fan loss and recovery as an audible story beat.
	ui.screen = HiringMain.Screen.EVENT
	ui.current_event = {
		"id": "garage_opening",
		"opening_phases": [
			{"id": "arrival"},
			{"id": "power"},
			{"id": "handoff"},
		],
		"choices": [],
	}
	ui.current_event_page = 0
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "opening" and str(context.get("phase", "")) == "arrival", "garage arrival maps to the authored opening phase")
	_check(float(ui.office_audio._target_rain) > OfficeAudio.SILENT_DB and float(ui.office_audio._target_score_human) > OfficeAudio.SILENT_DB, "garage arrival retains rain and restrained music")
	_check(is_equal_approx(float(ui.office_audio._target_server_fan), -18.0), "garage arrival starts with a live server fan")
	ui.current_event_page = 1
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("phase", "")) == "power", "power-failure page maps its stable opening phase id")
	_check(is_equal_approx(float(ui.office_audio._target_server_fan), OfficeAudio.SILENT_DB), "power failure cuts the server fan without silencing the whole scene")
	_check(float(ui.office_audio._target_rain) > OfficeAudio.SILENT_DB and float(ui.office_audio._target_score_human) > OfficeAudio.SILENT_DB, "power failure keeps rain and music alive")
	ui.current_event_page = 2
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("phase", "")) == "handoff", "handoff page maps its stable opening phase id")
	_check(is_equal_approx(float(ui.office_audio._target_server_fan), -14.0), "handoff restores the fan above its arrival level")

	# Explicit full silence remains a hard safety boundary even after the lively open.
	ui.office_audio.set_scene_context({"screen": "opening", "full_silence": true})
	_check(_all_runtime_targets_silent(ui.office_audio), "explicit full_silence still suppresses rain, room, and both score stems")

	# Ordinary office state carries the actual campaign values used by the mix.
	ui.model.chapter = 2
	ui.model.week_in_chapter = 5
	ui.model.author_weight = 63.0
	ui.model.employees.clear()
	ui.model.employees.append({"id": "audio_a"})
	ui.model.employees.append({"id": "audio_b"})
	ui.screen = HiringMain.Screen.DASHBOARD
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "office" and str(context.get("silence_mode", "")) == "normal", "dashboard maps to the normal office field")
	_check(int(context.get("chapter", -1)) == 2 and int(context.get("week_in_chapter", -1)) == 5, "office context carries chapter and intra-chapter week")
	_check(is_equal_approx(float(context.get("author_weight", -1.0)), 63.0), "office context carries hidden authorship weight")
	_check(int(context.get("team_size", -1)) == 3, "office context derives team size from founder plus employees")

	# Endgame withdrawal is weekly rather than a hard chapter cut.
	ui.model.chapter = 4
	ui.model.author_weight = 100.0
	ui.model.week_in_chapter = 1
	_apply_main_audio_context(ui)
	var week_one_air := float(ui.office_audio._target_air)
	ui.model.week_in_chapter = 8
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(int(context.get("chapter", -1)) == 4 and int(context.get("week_in_chapter", -1)) == 8, "chapter four keeps its real week in the runtime audio context")
	_check(week_one_air > OfficeAudio.SILENT_DB and is_equal_approx(float(ui.office_audio._target_air), OfficeAudio.SILENT_DB), "chapter-four air withdraws from week one to silence in week eight")
	_check(is_equal_approx(float(ui.office_audio._target_keys_sync), -14.0), "week eight leaves the authored synchronized keyboard ambience")
	_check(float(ui.office_audio._target_score_system) > OfficeAudio.SILENT_DB and float(ui.office_audio._target_score_system) <= -8.0, "week-eight system score remains audible with headroom")

	# The investor and Lin scenes use authored locations, not generic modals.
	ui.screen = HiringMain.Screen.EVENT
	ui.current_event = {"id": "first_investor_meeting", "kicker": "雨夜咖啡馆", "body": ["会面。"], "choices": []}
	ui.current_event_page = 0
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "cafe", "first investor meeting maps to the cafe field")
	_check(str(context.get("event_id", "")) == "first_investor_meeting", "cafe context preserves the authored event identity")
	_check(str(context.get("silence_mode", "")) == "duck_music", "investor dialogue ducks rather than cuts the score")

	ui.current_event = {"id": "lin_scene_4", "kicker": "楼下", "body": ["她在楼下。"], "choices": []}
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "downstairs", "Lin scene four maps to the downstairs field")
	_check(str(context.get("event_id", "")) == "lin_scene_4", "downstairs context preserves Lin's authored event identity")
	_check(str(context.get("silence_mode", "")) == "duck_music", "Lin dialogue uses restrained music ducking")

	# A silence page takes precedence over location and leaves only physical room tone.
	ui.current_event = {
		"id": "lin_scene_4",
		"kicker": "楼下",
		"pages": [["……"], ["继续。"]],
		"choices": [],
		"silence_pages": [0],
		"page_hold_seconds": [120.0, 0.0],
	}
	ui.current_event_page = 0
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("silence_mode", "")) == "room_tone_only", "authored silence page maps to room tone only")
	_check(is_equal_approx(float(ui.office_audio._target_air), -21.0) and is_equal_approx(float(ui.office_audio._target_server_fan), -31.0), "silence page retains only restrained air and server beds")
	_check(is_equal_approx(float(ui.office_audio._target_rain), OfficeAudio.SILENT_DB), "silence page removes exterior rain")
	_check(is_equal_approx(float(ui.office_audio._target_score_human), OfficeAudio.SILENT_DB) and is_equal_approx(float(ui.office_audio._target_score_system), OfficeAudio.SILENT_DB), "silence page removes both score stems")

	# Each playable night carries its canonical identity into its distinct room mix.
	ui.screen = HiringMain.Screen.NIGHT_SHIFT
	ui.pending_night_id = "1"
	ui.current_night = {"id": "night_shift_1"}
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "night" and str(context.get("night_id", "")) == "1", "night one maps with canonical id 1")
	_check(float(ui.office_audio._target_air) > OfficeAudio.SILENT_DB and is_equal_approx(float(ui.office_audio._target_server_fan), OfficeAudio.SILENT_DB), "night one leaves HVAC as its sole audible room layer")

	ui.pending_night_id = "2"
	ui.current_night = {"id": "night_shift_2"}
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "night" and str(context.get("night_id", "")) == "2", "night two maps with canonical id 2")
	_check(float(ui.office_audio._target_server_fan) > OfficeAudio.SILENT_DB and float(ui.office_audio._target_voices) > OfficeAudio.SILENT_DB, "night two restores its authored server and distant-voice layers")

	# Endings distinguish an archive from the destructive shutdown beat.
	ui.screen = HiringMain.Screen.ENDING
	ui.current_ending_id = "independent"
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "ending" and str(context.get("ending_id", "")) == "independent", "ordinary ending maps its stable ending identity")
	_check(str(context.get("phase", "")) == "archive", "ordinary ending uses the archive phase")

	ui.current_ending_id = "rm_rf"
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("ending_id", "")) == "rm_rf" and str(context.get("phase", "")) == "shutdown", "rm-rf ending maps to the shutdown phase")
	_check(is_equal_approx(float(ui.office_audio._target_server_fan), OfficeAudio.SILENT_DB), "rm-rf shutdown removes the server bed")

	ui.screen = HiringMain.Screen.BOARD_PRESENTATION
	ui.current_ending_id = ""
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("screen", "")) == "board", "board presentation maps to the projector-room field")
	_check(is_equal_approx(float(ui.office_audio._target_score_human), OfficeAudio.SILENT_DB), "board presentation removes the human theme")
	_check(float(ui.office_audio._target_score_system) > OfficeAudio.SILENT_DB and float(ui.office_audio._target_score_system) <= -12.0, "board presentation carries a restrained system motif")

	# Settings pauses authored clocks while ducking only the non-diegetic score.
	ui.screen = HiringMain.Screen.DASHBOARD
	ui.model.chapter = 2
	ui.model.week_in_chapter = 4
	ui.model.author_weight = 63.0
	ui.settings_open = false
	_apply_main_audio_context(ui)
	var normal_human_score := float(ui.office_audio._target_score_human)
	ui.settings_open = true
	_apply_main_audio_context(ui)
	context = ui._audio_scene_context()
	_check(str(context.get("silence_mode", "")) == "duck_music", "settings sheet maps a normal office to music ducking")
	_check(is_equal_approx(float(ui.office_audio._target_score_human), normal_human_score - 6.0), "settings sheet ducks the score by the authored 6 dB")
	ui.settings_open = false


func _test_anomaly_silence_contract(ui) -> void:
	_check(not OfficeAudio.FOLEY_KINDS.has("anomaly"), "audio vocabulary declares no anomaly cue")
	var before := int(ui.office_audio._foley_play_count)
	_check(not ui._play_foley("anomaly"), "unknown anomaly foley is rejected by the live graph")
	_check(int(ui.office_audio._foley_play_count) == before, "rejected anomaly foley consumes no playback voice")
	ui.screen = HiringMain.Screen.EVENT
	ui.current_event = {"id": "phantom_employee", "body": ["异常只通过画面出现。"], "choices": []}
	_apply_main_audio_context(ui)


func _test_silent_shortcuts_and_locked_navigation(ui) -> void:
	ui.office_audio.muted = false
	ui.screen = HiringMain.Screen.EVENT
	ui.current_event = {
		"id": "lin_scene_4",
		"pages": [["……"], ["继续。"]],
		"choices": [],
		"silence_pages": [0],
		"page_hold_seconds": [120.0, 0.0],
	}
	ui.current_event_page = 0
	ui.settings_open = false
	_apply_main_audio_context(ui)
	var before := int(ui.office_audio._foley_play_count)
	ui._open_settings()
	_check(ui.settings_open and int(ui.office_audio._foley_play_count) == before, "opening settings cannot leak page foley into an authored silence")
	ui._set_reduced_motion(not ui.reduced_motion)
	_check(int(ui.office_audio._foley_play_count) == before, "accessibility switch remains silent during an authored silence")
	ui._toggle_fullscreen()
	_check(int(ui.office_audio._foley_play_count) == before, "fullscreen switch remains silent during an authored silence")
	ui._toggle_audio_setting()
	ui._toggle_audio_setting()
	_check(not ui.office_audio.muted and int(ui.office_audio._foley_play_count) == before, "mute round-trip remains silent during an authored silence")
	ui._close_settings()
	_check(not ui.settings_open and int(ui.office_audio._foley_play_count) == before, "closing settings cannot leak page foley into an authored silence")

	ui.screen = HiringMain.Screen.INTRANET
	ui.model.flags["origin_article_interaction_required"] = true
	ui.model.flags["origin_editor_closed_without_change"] = false
	before = _arm_foley(ui, "page")
	var navigated: bool = ui._navigate_to_screen(HiringMain.Screen.DASHBOARD)
	_check(not navigated and ui.screen == HiringMain.Screen.INTRANET, "required origin interaction blocks workspace navigation")
	_check(int(ui.office_audio._foley_play_count) == before, "blocked origin navigation emits no false page-success cue")
	ui.model.flags.erase("origin_article_interaction_required")

	ui.screen = HiringMain.Screen.TEAM
	ui.model.flags["window_curtain_interaction_required"] = true
	ui.model.flags["window_curtain_interaction_complete"] = false
	before = _arm_foley(ui, "page")
	navigated = ui._navigate_to_screen(HiringMain.Screen.DASHBOARD)
	_check(not navigated and ui.screen == HiringMain.Screen.TEAM, "required curtain interaction blocks workspace navigation")
	_check(int(ui.office_audio._foley_play_count) == before, "blocked curtain navigation emits no anomaly-adjacent cue")
	ui.model.flags.erase("window_curtain_interaction_required")


func _test_direct_action_foley(ui) -> void:
	ui.office_audio.muted = false
	ui.settings_open = false
	ui.screen = HiringMain.Screen.DASHBOARD
	ui.week_action_ids.clear()
	ui.week_action_ids.append("do_nothing")
	ui.week_action_ids.append("buy_compute")
	ui.selected_action = 0

	var before := _arm_foley(ui, "page")
	ui._set_selected_action(1)
	_check(ui.selected_action == 1, "direct dashboard selection changes the highlighted action")
	_check(int(ui.office_audio._foley_play_count) == before + 1, "changing action selection plays one page-contact cue")
	_check(_last_foley_is(ui, "page"), "action selection routes the declared page foley stream")
	before = int(ui.office_audio._foley_play_count)
	ui._set_selected_action(1)
	_check(int(ui.office_audio._foley_play_count) == before, "reselecting the same action stays silent")

	before = _arm_foley(ui, "page")
	ui._open_settings()
	_check(ui.settings_open and int(ui.office_audio._foley_play_count) == before + 1, "opening settings plays one physical page cue")
	_check(_last_foley_is(ui, "page"), "settings open uses page rather than a generic UI beep")
	before = _arm_foley(ui, "switch")
	var reduced_before: bool = bool(ui.reduced_motion)
	ui._set_reduced_motion(not reduced_before)
	_check(bool(ui.reduced_motion) != reduced_before and int(ui.office_audio._foley_play_count) == before + 1, "motion setting uses one physical switch cue")
	_check(_last_foley_is(ui, "switch"), "motion setting routes the declared switch stream")
	before = _arm_foley(ui, "page")
	ui._close_settings()
	_check(not ui.settings_open and int(ui.office_audio._foley_play_count) == before + 1, "closing settings plays one page cue")

	before = _arm_foley(ui, "switch")
	ui._toggle_audio_setting()
	_check(ui.office_audio.muted and int(ui.office_audio._foley_play_count) == before + 1, "muting plays its switch before global audio closes")
	ui.office_audio._foley_last_played_ms.erase("switch")
	before = int(ui.office_audio._foley_play_count)
	ui._toggle_audio_setting()
	_check(not ui.office_audio.muted and int(ui.office_audio._foley_play_count) == before + 1, "unmuting restores audio before playing its switch")

	ui.screen = HiringMain.Screen.DASHBOARD
	before = _arm_foley(ui, "page")
	ui._cycle_workspace_navigation(1)
	_check(ui.screen == HiringMain.Screen.TEAM, "workspace navigation moves to the adjacent folio")
	_check(int(ui.office_audio._foley_play_count) == before + 1 and _last_foley_is(ui, "page"), "workspace navigation plays exactly one page cue")
	before = _arm_foley(ui, "page")
	var nav_handled: bool = ui._handle_nav_click(ui._nav_rect(4).get_center())
	_check(nav_handled and ui.screen == HiringMain.Screen.ANNOUNCEMENTS, "mouse navigation consumes the click and opens its target folio")
	_check(int(ui.office_audio._foley_play_count) == before + 1 and _last_foley_is(ui, "page"), "mouse navigation plays exactly one page cue")

	ui.document_page = 0
	before = _arm_foley(ui, "page")
	var page_changed: bool = ui._set_document_page(1, 3)
	_check(page_changed and ui.document_page == 1, "document pagination changes one persisted page")
	_check(int(ui.office_audio._foley_play_count) == before + 1 and _last_foley_is(ui, "page"), "document pagination plays its physical page cue")

	ui.current_event = {"id": "audio_pages", "pages": [["第一页"], ["第二页"]], "choices": []}
	ui.current_event_page = 0
	ui.event_page_elapsed = 1.0
	ui.screen = HiringMain.Screen.EVENT
	before = _arm_foley(ui, "page")
	ui._advance_event_page_or_close()
	_check(ui.current_event_page == 1, "ordinary event continue advances one page")
	_check(int(ui.office_audio._foley_play_count) == before + 1 and _last_foley_is(ui, "page"), "ordinary event continue plays one page cue")

	ui.current_event = {
		"id": "audio_silence_page",
		"pages": [["……"], ["继续。"]],
		"choices": [],
		"silence_pages": [0],
		"page_hold_seconds": [120.0, 0.0],
	}
	ui.current_event_page = 0
	ui.event_page_elapsed = 10.0
	before = int(ui.office_audio._foley_play_count)
	ui._advance_event_page_or_close()
	_check(ui.current_event_page == 1, "completed authored silence advances normally")
	_check(int(ui.office_audio._foley_play_count) == before, "advancing an authored silence emits no page or notification cue")

	var began: Dictionary = ui.director.start_company("Audio Integration", false)
	ui.model = ui.director.model
	_check(bool(began.get("ok", false)), "direct-action fixture starts an isolated playable company")
	ui.screen = HiringMain.Screen.DASHBOARD
	ui.week_action_ids.clear()
	ui.week_action_ids.append("do_nothing")
	ui.selected_action = 0
	ui.used_action_ids.clear()
	before = _arm_foley(ui, "confirm")
	ui._take_selected_action(false)
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT, "founder action reaches its physical result receipt")
	_check(int(ui.office_audio._foley_play_count) == before + 1 and _last_foley_is(ui, "confirm"), "founder action plays one restrained confirm cue")

	ui.screen = HiringMain.Screen.DASHBOARD
	ui.week_action_ids.clear()
	ui.week_action_ids.append("buy_compute")
	ui.selected_action = 0
	before = _arm_foley(ui, "terminal")
	ui._take_selected_action(true)
	_check(ui.screen == HiringMain.Screen.ACTION_RESULT, "delegated action reaches its physical result receipt")
	_check(int(ui.office_audio._foley_play_count) == before + 1 and _last_foley_is(ui, "terminal"), "delegated action plays one terminal contact cue")

	ui.screen = HiringMain.Screen.DASHBOARD
	ui.week_action_ids.clear()
	ui.week_action_ids.append("buy_compute")
	ui.selected_action = 0
	ui.used_action_ids.clear()
	ui.used_action_ids.append("buy_compute")
	before = _arm_foley(ui, "blocked")
	ui._take_selected_action(false)
	_check(ui.screen == HiringMain.Screen.DASHBOARD, "blocked action leaves the player on the dashboard")
	_check(int(ui.office_audio._foley_play_count) == before + 1 and _last_foley_is(ui, "blocked"), "blocked action plays the low physical refusal cue")


func _test_visible_page_persistence(ui) -> void:
	ui.office_audio.muted = false
	ui.screen = HiringMain.Screen.ACTION_RESULT
	ui.result_title = "分页回执"
	ui.result_return = "dashboard"
	ui.result_page = 0
	ui.result_lines.clear()
	for index in 18:
		ui.result_lines.append("第 %02d 条可见结算记录，需要在退出后保持页码。" % index)
	ui._save_game()
	ui.office_audio._foley_last_played_ms.erase("page")
	ui._close_result()
	var loaded: Dictionary = HiringStorage.load_dictionary(save_path)
	var payload: Dictionary = Dictionary(loaded.get("data", {}))
	_check(ui.result_page == 1, "visible result receipt advances to its second page")
	_check(bool(loaded.get("ok", false)) and int(payload.get("ui_result_page", -1)) == 1, "result receipt persists its visible page immediately")
	while ui.result_page + 1 < ui._result_pages().size():
		ui.office_audio._foley_last_played_ms.erase("page")
		ui._close_result()
	ui.office_audio._foley_last_played_ms.erase("page")
	ui._close_result()
	loaded = HiringStorage.load_dictionary(save_path)
	payload = Dictionary(loaded.get("data", {}))
	_check(ui.screen == HiringMain.Screen.DASHBOARD and ui.result_lines.is_empty(), "final result receipt dismissal returns to the dashboard")
	_check(str(payload.get("ui_screen_name", "")) == "dashboard" and _to_strings(payload.get("ui_result_lines", [])).is_empty(), "final result dismissal persists its target screen and cleared receipt")

	ui.screen = HiringMain.Screen.NIGHT_SHIFT
	ui.result_title = "夜班检查"
	ui.result_lines.clear()
	ui.result_lines.append("检查记录仍在桌面上。")
	ui._save_game()
	ui.office_audio._foley_last_played_ms.erase("page")
	var dismissed: bool = ui._dismiss_night_result()
	loaded = HiringStorage.load_dictionary(save_path)
	payload = Dictionary(loaded.get("data", {}))
	_check(dismissed and ui.result_lines.is_empty(), "night inspector closes through the persisted dismissal path")
	_check(_to_strings(payload.get("ui_result_lines", [])).is_empty(), "night inspector dismissal persists an empty result overlay")
	_check(str(payload.get("ui_screen_name", "")) == "night_shift", "night inspector dismissal preserves the underlying night screen")


func _apply_main_audio_context(ui) -> void:
	# Call the same per-frame bridge used by the real scene rather than bypassing
	# HiringMain and testing OfficeAudio in isolation.
	ui._process(0.0)


func _arm_foley(ui, kind: String) -> int:
	ui.office_audio._foley_last_played_ms.erase(kind)
	return int(ui.office_audio._foley_play_count)


func _last_foley_is(ui, kind: String) -> bool:
	if ui.office_audio._foley_pool.is_empty() or not ui.office_audio._foley_streams.has(kind):
		return false
	var index := posmod(int(ui.office_audio._foley_cursor) - 1, ui.office_audio._foley_pool.size())
	var player: AudioStreamPlayer = ui.office_audio._foley_pool[index] as AudioStreamPlayer
	return player != null and player.stream == ui.office_audio._foley_streams[kind]


func _dispose_ui(ui) -> void:
	if ui.office_audio != null:
		for child in ui.office_audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
		ui.office_audio._foley_streams.clear()
		ui.office_audio._foley_pool.clear()
	ui.queue_free()


func _clear_test_storage() -> void:
	for path in [
		save_path, save_path + ".bak", save_path + ".tmp", save_path + ".bak.tmp",
		meta_path, meta_path + ".bak", meta_path + ".tmp", meta_path + ".bak.tmp",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _to_strings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _all_runtime_targets_silent(audio) -> bool:
	return (
		is_equal_approx(float(audio._target_air), OfficeAudio.SILENT_DB)
		and is_equal_approx(float(audio._target_rain), OfficeAudio.SILENT_DB)
		and is_equal_approx(float(audio._target_server_fan), OfficeAudio.SILENT_DB)
		and is_equal_approx(float(audio._target_voices), OfficeAudio.SILENT_DB)
		and is_equal_approx(float(audio._target_keys_loose), OfficeAudio.SILENT_DB)
		and is_equal_approx(float(audio._target_keys_sync), OfficeAudio.SILENT_DB)
		and is_equal_approx(float(audio._target_score_human), OfficeAudio.SILENT_DB)
		and is_equal_approx(float(audio._target_score_system), OfficeAudio.SILENT_DB)
	)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
