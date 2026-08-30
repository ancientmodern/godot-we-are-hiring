extends SceneTree

const HiringContentScript = preload("res://src/hiring_content.gd")

const OUTPUT_DIR := "res://artifacts/screenshots"
const NON_MANIFEST_ARCHIVE_DIR := "res://artifacts/screenshots/archive/non_manifest"
var CAPTURE_SAVE_PATH := "user://we_are_hiring_visual_capture_save_%d.json" % OS.get_process_id()
var CAPTURE_META_PATH := "user://we_are_hiring_visual_capture_meta_%d.json" % OS.get_process_id()
var SAVE_FILES: Array[String] = [CAPTURE_SAVE_PATH, CAPTURE_META_PATH]
const CAPTURE_STEMS: Array[String] = [
	"action_large_train_compute_blocked",
	"announcements",
	"announcements_finale_page_2",
	"announcements_hiring_metrics_hidden",
	"announcements_hiring_metrics_released",
	"announcements_phantom_employee",
	"board_ai_aftermath",
	"board_ai_org_chart",
	"board_ai_page_change",
	"calendar",
	"calendar_extra_floor_contract",
	"calendar_supernatural_resources",
	"ending_acquihire",
	"ending_drift",
	"ending_independent",
	"ending_lights_out",
	"ending_rm_rf",
	"ending_second_time",
	"ending_successor",
	"event_first_investor_meeting_assistant_voice",
	"event_first_investor_meeting_cafe",
	"intranet_phantom_weekly_report",
	"intranet_phantom_weekly_report_page_2",
	"layoff_social_liked",
	"layoff_social_liked_transition",
	"layoff_social_post",
	"layoff_social_process_promised",
	"layoff_social_reliked",
	"layoff_social_reliked_transition",
	"layoff_social_unliked",
	"layoff_social_unliked_transition",
	"lin_scene_2_first_silence",
	"live_replay_aftermath",
	"live_replay_body_voice",
	"live_replay_client_signed",
	"live_replay_return_client_signed",
	"live_replay_second_viewing",
	"live_replay_we_pause",
	"ng_plus_cup_held",
	"ng_plus_cup_present",
	"ng_plus_cup_window_desk",
	"ng_plus_lin_answered",
	"ng_plus_lin_question",
	"night_1_corridor_first_crossing",
	"night_1_corridor_third_crossing",
	"night_1_opening",
	"night_1_plant_debt_clear",
	"night_1_plant_debt_high",
	"night_1_plant_debt_mid",
	"night_1_whiteboard_scarf_dog",
	"night_2_desk_cup_held",
	"night_2_desk_cup_replaced",
	"night_2_opening",
	"night_2_room_d_light_off",
	"night_2_room_d_projection",
	"night_2_room_d_two_steps_away",
	"night_2_terminal_ctrl_c",
	"night_2_terminal_focused",
	"night_2_terminal_unsent_dialogue",
	"office_debt_clear",
	"office_debt_high",
	"office_debt_mid",
	"onboarding",
	"onboarding_company",
	"onboarding_origin_serial",
	"opening_event",
	"origin_article_second_read",
	"origin_article_third_read_editor",
	"origin_article_unchanged",
	"prologue_bigco_align",
	"prologue_bigco_exit",
	"prologue_funded_money",
	"prologue_serial_postmortem",
	"signature_complete",
	"settings_overlay",
	"settings_reduced_motion",
	"team",
	"team_after_chen_departed",
	"team_before_chen_cups",
	"team_chen_three_cups_active",
	"team_finale_curtain_closed",
	"team_finale_roster_last_page",
	"team_finale_window_open",
	"team_finale_window_reopened",
	"team_phantom_employee",
	"terminal",
	"week_01_dashboard",
]
const EXPECTED_CAPTURE_COUNT := 87
const ENDING_CAPTURE_COMPANY := "第七码头研究所"
const CAMPAIGN_ENDING_IDS: Array[String] = [
	"acquihire", "drift", "independent", "lights_out", "rm_rf", "successor",
]

var capture_failed := false
var capture_count := 0
var captured_stems: Dictionary = {}
var save_backups: Dictionary = {}


func _init() -> void:
	call_deferred("_capture_sequence")


func _advance_prologue_to(game, phase_id: String) -> void:
	for _step in 12:
		if str(Dictionary(game.call("_first_day_phase")).get("id", "")) == phase_id:
			return
		game.event_page_elapsed = 999.0
		var choices: Array = game.call("_first_day_choices")
		if choices.is_empty():
			game.call("_advance_first_day_prologue", false)
		else:
			game.call("_choose_first_day_option", 0)
	game.queue_redraw()


func _capture_origin_prologue(game, origin_id: String, phase_id: String, stem: String) -> void:
	# Each prologue is captured from the same entry point the player uses, so a
	# broken origin can never quietly fall back to another origin's scene.
	game.selected_origin = int(HiringContentScript.ORIGIN_ORDER.find(origin_id))
	game.model.origin_id = origin_id
	game.call("_open_origin_prologue", HiringContentScript.origin_prologue(origin_id))
	await _settle_frames(10)
	_advance_prologue_to(game, phase_id)
	game.event_page_elapsed = 999.0
	await _settle_frames(8)
	_capture(stem)

func _capture_sequence() -> void:
	_backup_user_files()
	_validate_capture_manifest()
	_archive_non_manifest_pngs("before capture")
	if capture_failed:
		_restore_user_files()
		push_error("HIRING_VISUAL_CAPTURE_FAILED: capture preflight could not be prepared")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var game = preload("res://hiring_main.tscn").instantiate()
	game.save_path_override = CAPTURE_SAVE_PATH
	game.meta_path_override = CAPTURE_META_PATH
	root.add_child(game)
	await _settle_frames(48)
	_capture("onboarding")

	# Origins: the index sheet with a different file under the finger, then the
	# company sheet the chosen file leads to.
	game.call("_set_selected_origin", 1)
	await _settle_frames(10)
	_capture("onboarding_origin_serial")
	game.call("_set_selected_origin", 0)
	game.call("_confirm_origin_step")
	await _settle_frames(14)
	_capture("onboarding_company")

	# One prologue beat per origin: an opening question, a hinge, and a choice
	# that only exists because of where that founder came from.
	game.call("_start_new_company")
	await _settle_frames(12)
	game.event_page_elapsed = 999.0
	await _settle_frames(6)
	_capture("prologue_bigco_align")
	_advance_prologue_to(game, "badge")
	game.event_page_elapsed = 999.0
	await _settle_frames(8)
	_capture("prologue_bigco_exit")
	await _capture_origin_prologue(game, "serial", "postmortem", "prologue_serial_postmortem")
	await _capture_origin_prologue(game, "funded", "money", "prologue_funded_money")

	game.call("_complete_first_day_prologue", true)
	await _settle_frames(28)
	_capture("opening_event")

	game.call("_close_event")
	await _settle_frames(32)
	_capture("week_01_dashboard")
	game.call("_open_settings")
	await _settle_frames(16)
	_capture("settings_overlay")
	game.reduced_motion = true
	game.queue_redraw()
	await _settle_frames(2)
	_capture("settings_reduced_motion")
	game.reduced_motion = false
	game.call("_close_settings")
	await _settle_frames(8)

	game.call("_change_screen", game.Screen.TEAM)
	await _settle_frames(28)
	_capture("team")

	game.call("_change_screen", game.Screen.CALENDAR)
	await _settle_frames(28)
	game.set_process(false)
	game.model.flags.erase("extra_elevator_floor")
	game.queue_redraw()
	await _settle_frames(2)
	_capture("calendar")
	game.model.flags["extra_elevator_floor"] = true
	game.queue_redraw()
	await _settle_frames(2)
	_capture("calendar_extra_floor_contract")
	game.model.flags.erase("extra_elevator_floor")
	game.set_process(true)

	game.call("_change_screen", game.Screen.ANNOUNCEMENTS)
	await _settle_frames(28)
	_capture("announcements")
	game.call("_change_screen", game.Screen.TERMINAL)
	await _settle_frames(28)
	_capture("terminal")

	# Ordinary off-site scenes remain written and rendered inside the same
	# software-shell event modal; the camera never leaves the leased office UI.
	game.call("_open_event", game.content.get_fixed_event(1, 4))
	await _settle_frames(28)
	game.set_process(false)
	game.model.flags.erase("options_in_assistant_voice")
	game.queue_redraw()
	await _settle_frames(2)
	_capture("event_first_investor_meeting_cafe")
	game.model.flags["options_in_assistant_voice"] = true
	game.queue_redraw()
	await _settle_frames(2)
	_capture("event_first_investor_meeting_assistant_voice")
	game.model.flags.erase("options_in_assistant_voice")
	game.set_process(true)
	game.current_event.clear()

	# LIN-002 preserves the two authored two-minute silences in content. The
	# playable UI exposes a humane ten-second continue gate, while tests prove
	# both the authored holds and the two independent UI checkpoints.
	game.current_event = game.content.get_fixed_event(1, 7)
	game.current_event_page = 1
	game.event_page_elapsed = 60.0
	game.call("_change_screen", game.Screen.EVENT)
	await _settle_frames(28)
	_capture("lin_scene_2_first_silence")
	game.current_event.clear()
	game.event_page_elapsed = 0.0

	# Employee-specific desk signals must follow the actual active roster.
	var roster_before_chen: Array = game.model.employees.duplicate(true)
	game.call("_change_screen", game.Screen.TEAM)
	await _settle_frames(20)
	_capture("team_before_chen_cups")
	game.director.call("_add_content_employee", "chen_xiaoyu")
	await _settle_frames(20)
	_capture("team_chen_three_cups_active")
	game.model.call("_remove_employee_by_id", "chen_xiaoyu", "visual_fixture")
	await _settle_frames(20)
	_capture("team_after_chen_departed")
	game.model.employees.clear()
	for employee_value in roster_before_chen:
		game.model.employees.append(Dictionary(employee_value).duplicate(true))

	# Disabled capability actions state the exact resource boundary in the card.
	game.model.chapter = 2
	game.model.week_in_chapter = 2
	game.model.week_active = true
	game.model.week_resolved = false
	game.model.campaign_complete = false
	game.model.attention = 3
	game.model.compute = 7.0
	game.model.performed_actions.clear()
	game.model.flags.erase("training_blocked_this_week")
	game.model.flags.erase("ai_used_this_week")
	game.used_action_ids.clear()
	game.week_action_ids.assign(["train", "eval", "large_train", "buy_compute", "do_nothing"])
	game.selected_action = 2
	game.call("_change_screen", game.Screen.DASHBOARD)
	await _settle_frames(28)
	_capture("action_large_train_compute_blocked")

	# The chapter-two hiring numbers stay absent until their silent week-eight flag.
	game.model.flags.erase("seen_hiring_page_traffic")
	game.call("_change_screen", game.Screen.ANNOUNCEMENTS)
	await _settle_frames(20)
	_capture("announcements_hiring_metrics_hidden")
	game.model.flags["seen_hiring_page_traffic"] = true
	await _settle_frames(20)
	_capture("announcements_hiring_metrics_released")

	# Required interface-native anomalies: the new floor and Room D must use the
	# same ordinary controls as their neighbours, while Shen Yan stays the same
	# administrative identity across team, announcements, and intranet.
	game.model.chapter = 3
	game.model.week_in_chapter = 8
	game.model.total_week = 31
	game.model.flags["extra_elevator_floor"] = true
	game.model.flags["meeting_room_d_available"] = true
	game.director.call("_add_content_employee", "shen_yan")
	game.model.call("_scale_team_to_chapter_target")
	game.call("_change_screen", game.Screen.CALENDAR)
	await _settle_frames(32)
	_capture("calendar_supernatural_resources")
	game.call("_change_screen", game.Screen.TEAM)
	await _settle_frames(32)
	_capture("team_phantom_employee")
	game.call("_change_screen", game.Screen.ANNOUNCEMENTS)
	await _settle_frames(28)
	_capture("announcements_phantom_employee")

	game.model.chapter = 4
	game.model.week_in_chapter = 5
	game.model.total_week = 42
	game.call("_select_intranet_document", "weekly_report_91")
	game.call("_change_screen", game.Screen.INTRANET)
	await _settle_frames(32)
	_capture("intranet_phantom_weekly_report")
	var weekly_report_pages: Array = game.call("_selected_document_pages")
	if weekly_report_pages.size() < 2:
		capture_failed = true
		push_error("Weekly report visual fixture did not produce a second document page")
	else:
		game.document_page = 1
		game.queue_redraw()
		await _settle_frames(8)
		_capture("intranet_phantom_weekly_report_page_2")
		game.document_page = 0

	# Hidden debt is communicated only through the ordinary office vignette.
	# Capture three exact tiers so visual QA can compare the natural progression
	# without exposing the underlying value in release UI.
	game.call("_change_screen", game.Screen.DASHBOARD)
	for debt_fixture in [
		{"value": 0.0, "stem": "office_debt_clear"},
		{"value": 25.0, "stem": "office_debt_mid"},
		{"value": 70.0, "stem": "office_debt_high"},
	]:
		game.model.debt = float(debt_fixture["value"])
		game.queue_redraw()
		await _settle_frames(18)
		_capture(str(debt_fixture["stem"]))
	game.model.debt = 0.0

	# Direct presentation fixtures for late-game screens. The production model
	# still creates the same 37-person roster at the Chapter 4 boundary.
	game.model.chapter = 4
	game.model.week_in_chapter = 5
	game.model.total_week = 42
	game.model.author_weight = 94.0
	for key in ["window_curtain_open", "window_curtain_closed", "window_curtain_pending_reopen", "window_curtain_reopened", "window_curtain_interaction_complete"]:
		game.model.flags.erase(key)
	game.model.flags["window_desks"] = true
	game.model.flags["window_curtain_interaction_required"] = true
	game.model.memory.erase("window_interface_visits")
	game.model.memory.erase("window_curtain_close_count")
	game.model.memory.erase("window_curtain_reopen_count")
	game.model.call("_scale_team_to_chapter_target")
	game.call("_refresh_week_actions")
	game.call("_change_screen", game.Screen.TEAM)
	await _settle_frames(42)
	_capture("team_finale_window_open")
	game.team_page = maxi(0, int(game.call("_team_page_count")) - 1)
	game.queue_redraw()
	await _settle_frames(8)
	_capture("team_finale_roster_last_page")
	game.team_page = 0

	game.call("_close_window_curtain")
	await _settle_frames(20)
	_capture("team_finale_curtain_closed")

	game.call("_change_screen", game.Screen.DASHBOARD)
	await _settle_frames(12)
	game.call("_change_screen", game.Screen.TEAM)
	await _settle_frames(28)
	_capture("team_finale_window_reopened")

	# The third deliberate read opens the authored, non-editable realization.
	for key in ["origin_attribution_realized", "origin_editor_open", "origin_editor_closed_without_change", "origin_article_unchanged", "origin_article_interaction_complete"]:
		game.model.flags.erase(key)
	game.model.flags["origin_article_interaction_required"] = true
	game.model.memory.erase("origin_read_count")
	game.model.memory.erase("origin_editor_close_count")
	game.call("_select_intranet_document", "our_origin")
	game.call("_change_screen", game.Screen.INTRANET)
	game.call("_mark_selected_document_read")
	await _settle_frames(20)
	_capture("origin_article_second_read")
	game.call("_mark_selected_document_read")
	await _settle_frames(28)
	_capture("origin_article_third_read_editor")
	game.call("_close_origin_editor_without_change")
	await _settle_frames(18)
	_capture("origin_article_unchanged")

	# The delegated board answer now takes over the physical deck instead of
	# collapsing into the generic workspace-result modal.
	game.model.chapter = 4
	game.model.week_in_chapter = 6
	game.call("_open_event", game.content.get_fixed_event(4, 6))
	game.call("_choose_event_option", 2)
	await _settle_frames(8)
	_capture("board_ai_page_change")
	game.call("_advance_board_presentation")
	await _settle_frames(18)
	_capture("board_ai_org_chart")
	game.call("_advance_board_presentation")
	await _settle_frames(20)
	_capture("board_ai_aftermath")
	game.call("_advance_board_presentation")
	await _settle_frames(8)

	# This is the first naturally reachable point at which the finale archive has
	# enough authored items to exercise its second page: the board decision is now
	# part of history, alongside the investor, hiring, and Shen Yan beats.
	game.call("_change_screen", game.Screen.ANNOUNCEMENTS)
	var finale_announcement_pages := int(game.call("_announcement_page_count"))
	if finale_announcement_pages < 2:
		capture_failed = true
		push_error("Post-board announcement visual fixture did not produce a second page")
	else:
		game.announcement_page = 1
		game.queue_redraw()
		await _settle_frames(12)
		_capture("announcements_finale_page_2")

	game.result_lines.assign(["客户签了。", "你讲得比视频里还清楚。"])
	game.call("_start_live_replay")
	await _settle_frames(20)
	_capture("live_replay_client_signed")
	game.screen_time = game.call("_live_replay_min_phase_seconds")
	game.call("_advance_live_replay")
	game.screen_time = 0.9
	game.queue_redraw()
	await _settle_frames(16)
	_capture("live_replay_body_voice")
	game.screen_time = game.LIVE_REPLAY_MIN_PLAY_SECONDS
	game.call("_advance_live_replay")
	await _settle_frames(16)
	_capture("live_replay_we_pause")
	game.screen_time = game.call("_live_replay_min_phase_seconds")
	game.call("_advance_live_replay")
	game.screen_time = 0.9
	game.queue_redraw()
	await _settle_frames(16)
	_capture("live_replay_second_viewing")
	game.screen_time = game.LIVE_REPLAY_MIN_PLAY_SECONDS
	game.call("_advance_live_replay")
	await _settle_frames(16)
	_capture("live_replay_aftermath")
	game.model.flags["live_replay_active"] = false
	game.model.flags["live_replay_complete"] = true
	game.result_lines.assign(["它接管了现场说明、等待时的停顿和客户的追问。", "客户签了。这条路线不再检查能力门槛。"])
	game.call("_start_live_replay", "live_demo_return")
	await _settle_frames(20)
	_capture("live_replay_return_client_signed")
	game.model.flags["live_replay_active"] = false
	game.model.flags["live_replay_complete"] = true

	game.result_lines.assign([
		"> 通知流程已完成。",
		"> 我按照你在第 24 周全员会上的原则处理了。",
		"> 你当时说，如果这一天真的来了，你希望是当面说。",
		"> 我安排了当面。六场，都在会议室 C，间隔二十分钟。",
		"> 我用了你的语气。",
		"> 他们都以为是你写的。",
		"> 这对他们来说更好。",
	])
	game.call("_start_layoff_social")
	game.screen_time = game.call("_layoff_social_min_phase_seconds")
	game.queue_redraw()
	await _settle_frames(2)
	_capture("layoff_social_process_promised")
	game.call("_advance_layoff_social")
	await _settle_frames(16)
	_capture("layoff_social_post")
	# Pin every transition and settled state to an exact production phase time.
	# SceneTree frames still render queued redraws while HiringMain's _process is
	# disabled, so a slow renderer cannot collapse midpoint and final evidence.
	game.set_process(false)
	game.screen_time = game.call("_layoff_social_min_phase_seconds")
	game.call("_advance_layoff_social")
	game.screen_time = game.LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS * 0.5
	game.queue_redraw()
	await _settle_frames(2)
	_capture("layoff_social_liked_transition")
	game.screen_time = game.call("_layoff_social_min_phase_seconds")
	game.queue_redraw()
	await _settle_frames(2)
	_capture("layoff_social_liked")
	game.call("_advance_layoff_social")
	game.screen_time = game.LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS * 0.5
	game.queue_redraw()
	await _settle_frames(2)
	_capture("layoff_social_unliked_transition")
	game.screen_time = game.call("_layoff_social_min_phase_seconds")
	game.queue_redraw()
	await _settle_frames(2)
	_capture("layoff_social_unliked")
	game.call("_advance_layoff_social")
	game.screen_time = game.LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS * 0.5
	game.queue_redraw()
	await _settle_frames(2)
	_capture("layoff_social_reliked_transition")
	game.screen_time = game.call("_layoff_social_min_phase_seconds")
	game.queue_redraw()
	await _settle_frames(2)
	_capture("layoff_social_reliked")
	game.set_process(true)
	game.model.flags["layoff_social_active"] = false
	game.model.flags["layoff_social_complete"] = true

	game.call("_change_screen", game.Screen.SIGNATURE)
	# Pin the capture beyond the authored stroke/hint timeline so a fast renderer
	# cannot snapshot the approval card one frame before its completed state.
	game.screen_time = 1.6
	game.queue_redraw()
	await _settle_frames(8)
	_capture("signature_complete")

	game.model.debt = 0.0
	game.pending_night_id = "1"
	game.call("_open_night_shift", game.content.get_night_shift("1"))
	await _settle_frames(36)
	_capture("night_1_opening")
	_capture("night_1_plant_debt_clear")
	game.model.debt = 40.0
	game.queue_redraw()
	await _settle_frames(18)
	_capture("night_1_plant_debt_mid")
	game.model.debt = 80.0
	game.queue_redraw()
	await _settle_frames(18)
	_capture("night_1_plant_debt_high")
	_arrive_at_night_object(game, "whiteboard")
	await _settle_frames(18)
	_capture("night_1_whiteboard_scarf_dog")
	game.result_lines.clear()
	_arrive_at_night_object(game, "corridor")
	await _settle_frames(20)
	_capture("night_1_corridor_first_crossing")
	game.result_lines.clear()
	_arrive_at_night_object(game, "corridor")
	game.result_lines.clear()
	_arrive_at_night_object(game, "corridor")
	await _settle_frames(22)
	_capture("night_1_corridor_third_crossing")

	game.pending_night_id = "2"
	game.call("_open_night_shift", game.content.get_night_shift("2"))
	await _settle_frames(30)
	_capture("night_2_opening")

	_arrive_at_night_object(game, "window_desk")
	game.result_lines.clear()
	_arrive_at_night_object(game, "window_desk")
	await _settle_frames(20)
	_capture("night_2_desk_cup_held")
	game.result_lines.clear()
	_arrive_at_night_object(game, "window_desk")
	await _settle_frames(20)
	_capture("night_2_desk_cup_replaced")

	game.result_lines.clear()
	_arrive_at_night_object(game, "meeting_room_d")
	await _settle_frames(20)
	_capture("night_2_room_d_projection")
	game.result_lines.clear()
	_arrive_at_night_object(game, "meeting_room_d")
	game.result_lines.clear()
	_arrive_at_night_object(game, "meeting_room_d")
	game.result_lines.clear()
	_arrive_at_night_object(game, "meeting_room_d")
	await _settle_frames(18)
	_capture("night_2_room_d_two_steps_away")
	game.result_lines.clear()
	_arrive_at_night_object(game, "meeting_room_d")
	game.result_lines.clear()
	_arrive_at_night_object(game, "meeting_room_d")
	await _settle_frames(18)
	_capture("night_2_room_d_light_off")

	game.result_lines.clear()
	_arrive_at_night_object(game, "terminal")
	await _settle_frames(22)
	_capture("night_2_terminal_unsent_dialogue")
	game.result_lines.clear()
	_arrive_at_night_object(game, "terminal")
	await _settle_frames(18)
	_capture("night_2_terminal_focused")
	game.call("_handle_night_ctrl_c")
	await _settle_frames(18)
	_capture("night_2_terminal_ctrl_c")

	# Second Time is a physical, resumable interaction rather than pre-narrated
	# prose: pickup/view, replacement and Lin's question, then final placement.
	var second_started: Dictionary = game.director.start_company(ENDING_CAPTURE_COMPANY, true)
	game.model = game.director.model
	game.call("_open_event", Dictionary(second_started.get("event", {})))
	await _settle_frames(24)
	_capture("ng_plus_cup_present")
	game.call("_advance_second_time_interaction")
	await _settle_frames(20)
	_capture("ng_plus_cup_held")
	game.call("_advance_second_time_interaction")
	await _settle_frames(20)
	_capture("ng_plus_lin_question")
	game.call("_choose_event_option", 0)
	await _settle_frames(20)
	_capture("ng_plus_lin_answered")
	game.call("_advance_second_time_interaction")
	await _settle_frames(20)
	_capture("ng_plus_cup_window_desk")
	# Second Time is the seventh ending registry entry, but its production
	# playback is this phased interaction rather than a generic prose screen.
	_capture("ending_second_time")

	# One first-page proof for each conventional ending. The custom company name
	# in the common header proves that every surface renders recovered save data.
	for ending_id in CAMPAIGN_ENDING_IDS:
		game.current_ending_id = ending_id
		game.current_ending = game.director.ending_for_id(ending_id)
		game.ending_page = 0
		game.call("_change_screen", game.Screen.ENDING)
		await _settle_frames(30)
		_capture("ending_" + ending_id)

	# Both ambience and UI feedback own generated WAV resources. Release every
	# player in the complete scene tree, then leave the audio server enough mix
	# callbacks on a desktop renderer to retire its playback references.
	_release_audio_players(game)
	await _settle_frames(30)
	game.queue_free()
	# queue_free() removes the node hierarchy on the next idle frame, while the
	# audio/render servers retire their ObjectDB handles over subsequent frames.
	await _settle_frames(60)
	_restore_user_files()
	_archive_non_manifest_pngs("after capture")
	_verify_root_capture_manifest()
	if capture_count != EXPECTED_CAPTURE_COUNT:
		capture_failed = true
		push_error("Visual harness saved %d captures; expected %d" % [capture_count, EXPECTED_CAPTURE_COUNT])
	if captured_stems.size() != EXPECTED_CAPTURE_COUNT:
		capture_failed = true
		push_error("Visual harness saved %d unique paths; expected %d" % [captured_stems.size(), EXPECTED_CAPTURE_COUNT])
	for expected_stem in CAPTURE_STEMS:
		if not captured_stems.has(expected_stem):
			capture_failed = true
			push_error("Visual harness did not capture manifest stem: " + expected_stem)
	if capture_failed:
		push_error("HIRING_VISUAL_CAPTURE_FAILED")
		quit(1)
	else:
		print("HIRING_VISUAL_CAPTURE_PASS: %d captures" % capture_count)
		quit(0)


func _settle_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _arrive_at_night_object(game, object_id: String) -> void:
	var object: Dictionary = game.call("_night_object_by_id", object_id)
	if object.is_empty():
		capture_failed = true
		push_error("Night fixture could not find object " + object_id)
		return
	game.call("_queue_night_object_visit", object)
	# The production loop normally completes this after the player physically
	# reaches the hotspot. Snap only the capture fixture, then use the same
	# arrival handler and state machine as live play.
	if not str(game.night_pending_object_id).is_empty():
		game.night_player_position = game.night_player_target
		game.night_arrival_armed = false
		game.call("_complete_night_object_arrival")


func _release_audio_players(node: Node) -> void:
	for child in node.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
		_release_audio_players(child)


func _capture(file_stem: String) -> void:
	if not CAPTURE_STEMS.has(file_stem):
		capture_failed = true
		push_error("Visual harness attempted non-manifest capture path: " + file_stem)
		return
	if captured_stems.has(file_stem):
		capture_failed = true
		push_error("Visual harness attempted duplicate capture path: " + file_stem)
		return
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_absolute)
	var image := root.get_texture().get_image()
	if image == null:
		capture_failed = true
		push_error("Renderer did not expose a viewport image for " + file_stem)
		return
	var output_path := "%s/%s.png" % [output_absolute, file_stem]
	var error := image.save_png(output_path)
	if error != OK:
		capture_failed = true
		push_error("Could not save visual capture %s: %s" % [output_path, error_string(error)])
		return
	captured_stems[file_stem] = true
	capture_count += 1
	print("CAPTURED: " + output_path)


func _validate_capture_manifest() -> void:
	var unique_stems: Dictionary = {}
	for stem in CAPTURE_STEMS:
		if stem.is_empty() or stem.contains("/") or stem.contains("\\"):
			capture_failed = true
			push_error("Visual capture manifest has an invalid stem: " + stem)
			continue
		if unique_stems.has(stem):
			capture_failed = true
			push_error("Visual capture manifest has a duplicate stem: " + stem)
		unique_stems[stem] = true
	if unique_stems.size() != EXPECTED_CAPTURE_COUNT:
		capture_failed = true
		push_error("Visual capture manifest has %d unique stems; expected %d" % [unique_stems.size(), EXPECTED_CAPTURE_COUNT])


func _archive_non_manifest_pngs(phase: String) -> void:
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
	var archive_absolute := ProjectSettings.globalize_path(NON_MANIFEST_ARCHIVE_DIR)
	var output_error := DirAccess.make_dir_recursive_absolute(output_absolute)
	var archive_error := DirAccess.make_dir_recursive_absolute(archive_absolute)
	if output_error != OK or archive_error != OK:
		capture_failed = true
		push_error("Could not prepare visual capture/archive directories during %s: %s / %s" % [phase, error_string(output_error), error_string(archive_error)])
		return
	var directory := DirAccess.open(output_absolute)
	if directory == null:
		capture_failed = true
		push_error("Could not inspect visual capture directory during " + phase)
		return
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() != "png":
			continue
		var stem := file_name.get_basename()
		if CAPTURE_STEMS.has(stem):
			continue
		var source_path := output_absolute.path_join(file_name)
		var archive_path := _next_archive_path(archive_absolute, file_name)
		var rename_error := DirAccess.rename_absolute(source_path, archive_path)
		if rename_error != OK:
			capture_failed = true
			push_error("Could not archive non-manifest capture %s during %s: %s" % [source_path, phase, error_string(rename_error)])
			continue
		print("ARCHIVED_NON_MANIFEST_CAPTURE: %s -> %s" % [source_path, archive_path])


func _next_archive_path(archive_absolute: String, file_name: String) -> String:
	var candidate := archive_absolute.path_join(file_name)
	var base_name := file_name.get_basename()
	var extension := file_name.get_extension()
	var suffix := 1
	while FileAccess.file_exists(candidate):
		candidate = archive_absolute.path_join("%s__%03d.%s" % [base_name, suffix, extension])
		suffix += 1
	return candidate


func _verify_root_capture_manifest() -> void:
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
	var directory := DirAccess.open(output_absolute)
	if directory == null:
		capture_failed = true
		push_error("Could not verify visual capture directory")
		return
	var actual_stems: Dictionary = {}
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() == "png":
			actual_stems[file_name.get_basename()] = true
	var missing: Array[String] = []
	var extra: Array[String] = []
	for expected_stem in CAPTURE_STEMS:
		if not actual_stems.has(expected_stem):
			missing.append(expected_stem)
	for actual_stem in actual_stems:
		if not CAPTURE_STEMS.has(str(actual_stem)):
			extra.append(str(actual_stem))
	missing.sort()
	extra.sort()
	if not missing.is_empty() or not extra.is_empty() or actual_stems.size() != EXPECTED_CAPTURE_COUNT:
		capture_failed = true
		push_error("Visual capture root does not match the %d-stem manifest; missing=%s extra=%s actual=%d" % [EXPECTED_CAPTURE_COUNT, missing, extra, actual_stems.size()])
		return
	print("CAPTURE_MANIFEST_VERIFIED: %d root PNGs" % actual_stems.size())


func _backup_user_files() -> void:
	for path in SAVE_FILES:
		if not FileAccess.file_exists(path):
			save_backups[path] = null
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			capture_failed = true
			push_error("Could not back up isolated visual-capture storage: " + path)
			continue
		save_backups[path] = file.get_buffer(file.get_length())
		file = null
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if remove_error != OK:
			capture_failed = true
			push_error("Could not clear isolated visual-capture storage %s: %s" % [path, error_string(remove_error)])


func _restore_user_files() -> void:
	for path in SAVE_FILES:
		var absolute := ProjectSettings.globalize_path(path)
		if save_backups.get(path, null) == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(absolute)
			continue
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(save_backups[path])
