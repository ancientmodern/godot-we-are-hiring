extends Node2D

const HiringModel = preload("res://src/hiring_model.gd")
const HiringContent = preload("res://src/hiring_content.gd")
const HiringExpansionContent = preload("res://src/hiring_expansion_content.gd")
const CampaignDirector = preload("res://src/hiring_director.gd")
const OfficeAudio = preload("res://src/office_audio.gd")
const NightInteractionState = preload("res://src/night_interaction_state.gd")
const HiringStorage = preload("res://src/hiring_storage.gd")
const HiringFocusRouter = preload("res://src/hiring_focus_router.gd")

const VIEW := Vector2(1280.0, 720.0)
const SAVE_PATH := "user://we_are_hiring_save.json"
const META_PATH := "user://we_are_hiring_meta.json"
const UI_FONT_PATH := "res://assets/fonts/NotoSansSC-Variable.ttf"
const UI_DISPLAY_FONT_PATH := "res://assets/fonts/NotoSerifSC-Variable.ttf"
const ART_DOSSIER_DESK_PATH := "res://assets/art/hiring_dossier_desk_v2.png"
const ART_TITLE_PATH := "res://assets/art/hiring_title_dawn_v1.png"
const ART_OFFICE_DAY_PATH := "res://assets/art/hiring_office_day_v1.png"
const ART_OFFICE_NIGHT_PATH := "res://assets/art/hiring_office_night_v1.png"
const ART_BOARDROOM_PATH := "res://assets/art/hiring_boardroom_v1.png"
const ART_MEETING_REPLAY_PATH := "res://assets/art/hiring_meeting_replay_v1.png"
const ART_LIN_PATH := "res://assets/art/lin_yue_portrait_v2.png"
const ART_LIN_FALLBACK_PATH := "res://assets/art/lin_yue_portrait_v1.png"
const ART_CAFE_PATH := "res://assets/art/hiring_cafe_rain_v1.png"
const ART_NIGHT_WHITEBOARD_PATH := "res://assets/art/hiring_night_whiteboard_v1.png"
const ART_NIGHT_MUG_PATH := "res://assets/art/hiring_night_future_mug_v1.png"
const ART_NIGHT_POTHOS_PATH := "res://assets/art/hiring_night_pothos_v1.png"
const ART_NIGHT_POTHOS_HEALTHY_PATH := "res://assets/art/hiring_night_pothos_healthy_v1.png"
const ART_NIGHT_POTHOS_SEVERE_PATH := "res://assets/art/hiring_night_pothos_severe_v1.png"
const ART_NIGHT_ROOM_D_PATH := "res://assets/art/hiring_night_room_d_v1.png"
const UI_SCHEMA_VERSION := 3
const DOCUMENT_LINES_PER_PAGE := 10
const TEAM_ROWS_PER_PAGE := 9
const ANNOUNCEMENTS_PER_PAGE := 6
const UI_MIN_TARGET := 44.0

# Type ramp. Seven steps, nothing between them. Every _draw_text* helper clamps
# to TYPE_META, so a call site can never whisper below the readable floor — but
# a ramp only reads as a ramp if the steps are far enough apart to be seen. The
# earlier build spent 23 sizes between 9 and 46 and clamped four of them onto
# the same 12px, which flattened the whole hierarchy into one grey mass.
const TYPE_META := 12       # 元数据、页码、快捷键、单位、印记
const TYPE_LABEL := 14      # 字段名、表头、次级标签
const TYPE_BODY := 16       # 正文、列表项、说明
const TYPE_ACTION := 17     # 按钮标签与行动名
const TYPE_SECTION := 22    # 分区标题（衬线）
const TYPE_DISPLAY := 32    # 页面标题，每屏至多一个（衬线）
const TYPE_HERO := 46       # 开场与结局第一页（衬线）
const TYPE_MICRO := TYPE_META
const RADIUS_CONTROL := 3.0
const RADIUS_CARD := 2.0
const RADIUS_MODAL := 8.0
const MOTION_FAST := 0.12
const MOTION_PANEL := 0.18
const MOTION_STANDARD := 0.32

# Content is never allowed to borrow contrast from the baked desk photograph.
# These rectangles are the stable reading planes for the fixed 1280x720 canvas.
const SIDEBAR_SAFE_RECT := Rect2(0, 0, 272, 720)
const DASHBOARD_MAIN_SURFACE := Rect2(294, 70, 474, 516)
const DASHBOARD_TOOLBAR_SURFACE := Rect2(776, 104, 370, 66)
const DASHBOARD_DETAIL_SURFACE := Rect2(776, 180, 370, 406)
const DASHBOARD_STATS_SURFACE := Rect2(294, 594, 852, 72)
const TEAM_MAIN_SURFACE := Rect2(294, 70, 620, 574)
const TEAM_RIGHT_SURFACE := Rect2(922, 86, 312, 558)
const CONTENT_HEADER_SURFACE := Rect2(294, 70, 950, 88)
const OFFICE_DEBT_RECT := Rect2(18, 558, 210, 156)
const NIGHT_HINT_SAFE_RECT := Rect2(760, 32, 370, 24)
const TOAST_MAX_SAFE_RECT := Rect2(400, 16, 480, 48)

# Blue-Hour Ledger 2.0 / 雨印档案: the company exists as a physical archive.
const BG := Color("#0b171d")
const SURFACE := Color("#e9ebe5")
const READING_PAPER := Color("#edf0e9")
const READING_PAPER_ALT := Color("#e4e9e4")
const SURFACE_DARK := Color("#0b171d")
const SIDEBAR := Color("#173039")
const SIDEBAR_SURFACE := Color("#0d1e25")
const INK := Color("#17252a")
const MUTED := Color("#465b63")
const LINE := Color("#aab3ae")
const GREEN := Color("#3e8579")
const GREEN_BRIGHT := Color("#68aa9c")
const AMBER := Color("#a96535")
const RED := Color("#9d4b50")
const BLUE := Color("#557a88")
const PAPER_GREEN := Color("#2f7067")
const PAPER_BLUE := Color("#456b79")
const PAPER_AMBER := Color("#8f552d")
const DISABLED_BG := Color("#e2e6e2")
const DISABLED_TEXT := Color("#586864")
const SCRIM := Color(0.031, 0.075, 0.098, 0.84)
const HUMAN_PAPER := Color("#e6d4b6")
const NIGHT_BG := Color("#081319")
const NIGHT_PANEL := Color("#102127")
const NIGHT_TEXT := Color("#dce7e8")
const NIGHT_MUTED := Color("#8fa2a8")
const TERMINAL := Color("#071319")
const TERMINAL_TEXT := Color("#b9dad7")

# Two neutral families, thirteen cold steps and six warm ones. Everything that
# is not an accent is one of these. The cold family gains saturation as it
# darkens, which is what makes it read as ink soaking into damp paper instead of
# as grey. The warm family belongs to people: their paper, their handwriting,
# their lamp. Nothing in the UI mixes a neutral by hand.
const COLD_00 := Color("#f7f8f5")
const COLD_05 := Color("#eef1ec")
const COLD_10 := Color("#e2e7e3")
const COLD_20 := Color("#c9d2ce")
const COLD_30 := Color("#adb8b4")
const COLD_40 := Color("#8b9a99")
const COLD_50 := Color("#6d7f80")
const COLD_60 := Color("#52666f")
const COLD_70 := Color("#35505a")
const COLD_80 := Color("#1d3540")
const COLD_90 := Color("#12262e")
const COLD_95 := Color("#0b171d")
const COLD_99 := Color("#071319")
const WARM_05 := Color("#f4efe4")
const WARM_10 := Color("#ebe0c9")
const WARM_20 := Color("#e6d4b6")
const WARM_40 := Color("#c0a883")
const WARM_60 := Color("#a96535")
const WARM_70 := Color("#8f552d")
# Named roles, so a call site says what it means rather than how dark it is.
const RULE_STRONG := COLD_30   # 表面上的主分隔线与纸边
const RULE_SOFT := COLD_20     # 行与行之间
const PAPER := COLD_05         # 主阅读纸
const PAPER_SUNK := COLD_10    # 次级纸、工具条、页脚
const WINDOW_INTERIOR_PERSON_COUNT := 33
const WINDOW_TOTAL_PERSON_COUNT := 37
const BOARD_ORG_ACTIVE_COUNT := 31
const BOARD_ORG_EXIT_COUNT := 6
const BOARD_TRANSITION_SECONDS := 1.15
const LIVE_REPLAY_MIN_PLAY_SECONDS := 1.60
const LIVE_REPLAY_MIN_STATIC_SECONDS := 0.85
const LIVE_REPLAY_MIN_PAUSE_SECONDS := 1.20
const LAYOFF_SOCIAL_PROCESS_MIN_SECONDS := 1.05
const LAYOFF_SOCIAL_INTERACTION_MIN_SECONDS := 0.72
const LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS := 0.42
const SECOND_TIME_PHASE_PRESENT := "cup_present"
const SECOND_TIME_PHASE_HELD := "cup_held"
const SECOND_TIME_PHASE_QUESTION := "lin_question"
const SECOND_TIME_PHASE_ANSWERED := "lin_answered"
const SECOND_TIME_PHASE_PLACED := "cup_at_window_desk"

enum Screen {
	ONBOARDING,
	DASHBOARD,
	ACTION_RESULT,
	EVENT,
	TEAM,
	TERMINAL,
	INTRANET,
	NIGHT_SHIFT,
	ENDING,
	CALENDAR,
	ANNOUNCEMENTS,
	SIGNATURE,
	BOARD_PRESENTATION,
	LIVE_REPLAY,
	LAYOFF_SOCIAL
}

var screen := Screen.ONBOARDING
var model
var content
var director
var office_audio
var font: Font
var font_display: Font
var art_dossier_desk: Texture2D
var art_title: Texture2D
var art_office_day: Texture2D
var art_office_night: Texture2D
var art_boardroom: Texture2D
var art_meeting_replay: Texture2D
var art_lin: Texture2D
var art_cafe: Texture2D
var art_night_whiteboard: Texture2D
var art_night_mug: Texture2D
var art_night_pothos: Texture2D
var art_night_pothos_healthy: Texture2D
var art_night_pothos_severe: Texture2D
var art_night_room_d: Texture2D
var name_edit: LineEdit
var command_edit: LineEdit
var mouse_position := Vector2(-100, -100)
var elapsed := 0.0
var screen_time := 0.0
var toast_text := ""
var toast_timer := 0.0
var toast_duration := 2.6
var toast_kind := "info"

var week_action_ids: Array[String] = []
var used_action_ids: Array[String] = []
# Who actually did each of this week's handled items. The whole game is the
# distance between these two answers, so the folio keeps it in writing.
var used_action_authors: Dictionary = {}
var selected_action := 0
var current_event: Dictionary = {}
var current_event_page := 0
var event_page_elapsed := 0.0
var event_result_lines: Array[String] = []
var result_title := ""
var result_lines: Array[String] = []
var result_return := "dashboard"
var result_page := 0
var terminal_lines: Array[String] = []
var selected_document := 0
var document_page := 0
var team_page := 0
var announcement_page := 0
var current_night: Dictionary = {}
var night_objects: Array[Dictionary] = []
var night_seen: Array[String] = []
var night_player_position := Vector2(640, 540)
var night_player_target := Vector2(640, 540)
var night_interaction
var night_pending_object_id := ""
var night_arrival_armed := false
var night_focused_object_index := 0
var current_ending_id := ""
var current_ending: Dictionary = {}
var ending_page := 0
var second_run_unlocked := false
var last_ending_id := ""
var seen_endings: Array[String] = []
var pending_week_advance := false
var pending_night_id := ""
var action_hover_amounts: Array[float] = []
var announcement_sidebar_snapshot: Dictionary = {}
# Test and capture harnesses inject isolated user:// files before _ready().
# Production instances leave these empty and continue using the canonical paths.
var save_path_override := ""
var meta_path_override := ""
var smoke_test_mode := false
var settings_open := false
var reduced_motion := false
var focus_router
var focused_onboarding_action := 0
var focused_event_choice := 0
var focused_settings_row := 0
var gamepad_focus_visible := false
var keyboard_focus_visible := false
var night_command_focus_before_settings := false
var new_game_confirm_pending := false
var end_week_confirm_pending := false
var opening_skip_confirm_pending := false
var save_status_text := ""
var save_status_timer := 0.0
var press_feedback_position := Vector2.ZERO
var press_feedback_timer := 0.0
var _panel_style_cache: Dictionary = {}
var _wrap_cache: Dictionary = {}


func _ready() -> void:
	_apply_command_line_storage_overrides()
	if smoke_test_mode:
		var storage_failure := _smoke_storage_failure_reason(save_path_override, meta_path_override)
		if not storage_failure.is_empty():
			push_error("HIRING_MAIN_SMOKE_FAILURE: isolated storage rejected before meta load (%s)" % storage_failure)
			get_tree().quit(1)
			return
	_load_art_direction_resources()
	content = HiringContent.new()
	director = CampaignDirector.new()
	model = director.model
	focus_router = HiringFocusRouter.new()
	office_audio = OfficeAudio.new()
	add_child(office_audio)
	RenderingServer.set_default_clear_color(BG)
	# The interface is authored at 1280×720.  Allowing a 960×540 window made
	# metadata and legal copy render below an accessible reading size.
	get_window().min_size = Vector2i(1280, 720)
	_load_meta()
	_create_text_inputs()
	_sync_focus_for_current_screen()
	queue_redraw()
	if smoke_test_mode:
		call_deferred("_complete_main_smoke_test")


func _apply_command_line_storage_overrides() -> void:
	var parsed := _storage_overrides_from_args(OS.get_cmdline_user_args())
	if parsed.has("save"):
		save_path_override = str(parsed["save"])
	if parsed.has("meta"):
		meta_path_override = str(parsed["meta"])
	smoke_test_mode = bool(parsed.get("smoke", false))


func _storage_overrides_from_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	for argument_value in args:
		var argument := str(argument_value)
		var key := ""
		var value := ""
		if argument.begins_with("--hiring-save-path="):
			key = "save"
			value = argument.trim_prefix("--hiring-save-path=")
		elif argument.begins_with("--hiring-meta-path="):
			key = "meta"
			value = argument.trim_prefix("--hiring-meta-path=")
		elif argument == "--hiring-smoke-test":
			parsed["smoke"] = true
		if not key.is_empty():
			var normalized := _normalized_user_storage_path(value)
			if not normalized.is_empty():
				parsed[key] = normalized
	return parsed


func _normalized_user_storage_path(path: String) -> String:
	# Keep QA storage paths canonical before comparing them with production.
	# Backslashes and empty/dot segments can alias another user:// path on
	# Windows, so reject them instead of relying on textual inequality.
	if not path.begins_with("user://") or path.contains("\\"):
		return ""
	var relative := path.trim_prefix("user://")
	if relative.is_empty():
		return ""
	var segments := relative.split("/", true)
	for segment_value in segments:
		var segment := str(segment_value)
		if segment.is_empty() or segment == "." or segment == "..":
			return ""
	var normalized := "user://" + "/".join(segments)
	if ProjectSettings.globalize_path(normalized).simplify_path().is_empty():
		return ""
	return normalized


func _smoke_storage_failure_reason(save_path: String, meta_path: String) -> String:
	var normalized_save := _normalized_user_storage_path(save_path)
	if normalized_save.is_empty():
		return "missing or invalid save override"
	var normalized_meta := _normalized_user_storage_path(meta_path)
	if normalized_meta.is_empty():
		return "missing or invalid meta override"

	var save_absolute := ProjectSettings.globalize_path(normalized_save).simplify_path()
	var meta_absolute := ProjectSettings.globalize_path(normalized_meta).simplify_path()
	var canonical_save_absolute := ProjectSettings.globalize_path(SAVE_PATH).simplify_path()
	var canonical_meta_absolute := ProjectSettings.globalize_path(META_PATH).simplify_path()
	for canonical_absolute in [canonical_save_absolute, canonical_meta_absolute]:
		if save_absolute.filenocasecmp_to(str(canonical_absolute)) == 0:
			return "save override aliases canonical storage"
		if meta_absolute.filenocasecmp_to(str(canonical_absolute)) == 0:
			return "meta override aliases canonical storage"
	if save_absolute.filenocasecmp_to(meta_absolute) == 0:
		return "save and meta overrides resolve to the same file"
	return ""


func _complete_main_smoke_test() -> void:
	var storage_failure := _smoke_storage_failure_reason(save_path_override, meta_path_override)
	var isolated := storage_failure.is_empty()
	var initialized: bool = content != null and director != null and model == director.model and focus_router != null and office_audio != null and name_edit != null and command_edit != null and art_dossier_desk != null and art_title != null and art_office_day != null and art_office_night != null and art_boardroom != null and art_meeting_replay != null and art_lin != null and art_cafe != null and art_night_whiteboard != null and art_night_mug != null and art_night_pothos != null and art_night_pothos_healthy != null and art_night_pothos_severe != null and art_night_room_d != null and font != null and font_display != null
	if isolated and initialized and screen == Screen.ONBOARDING:
		print("HIRING_MAIN_SMOKE_PASS: isolated storage, scene initialized, onboarding rendered")
		get_tree().quit(0)
		return
	push_error("HIRING_MAIN_SMOKE_FAILURE: isolated=%s initialized=%s screen=%d storage=%s" % [isolated, initialized, int(screen), storage_failure])
	get_tree().quit(1)


func _load_art_direction_resources() -> void:
	var bundled_font = ResourceLoader.load(UI_FONT_PATH)
	var bundled_display_font = ResourceLoader.load(UI_DISPLAY_FONT_PATH)
	if bundled_font is Font:
		var text_server = TextServerManager.get_primary_interface()
		var body := FontVariation.new()
		body.base_font = bundled_font
		body.variation_opentype = {text_server.name_to_tag("wght"): 500}
		font = body
		var display := FontVariation.new()
		display.base_font = bundled_display_font if bundled_display_font is Font else bundled_font
		display.variation_opentype = {text_server.name_to_tag("wght"): 650}
		display.spacing_glyph = -0.5
		font_display = display
	else:
		var body_fallback := SystemFont.new()
		body_fallback.font_names = PackedStringArray(["Noto Sans CJK SC", "Microsoft YaHei UI", "Segoe UI", "Arial"])
		font = body_fallback
		font_display = body_fallback
	art_dossier_desk = ResourceLoader.load(ART_DOSSIER_DESK_PATH) as Texture2D
	art_title = ResourceLoader.load(ART_TITLE_PATH) as Texture2D
	art_office_day = ResourceLoader.load(ART_OFFICE_DAY_PATH) as Texture2D
	art_office_night = ResourceLoader.load(ART_OFFICE_NIGHT_PATH) as Texture2D
	art_boardroom = ResourceLoader.load(ART_BOARDROOM_PATH) as Texture2D
	art_meeting_replay = ResourceLoader.load(ART_MEETING_REPLAY_PATH) as Texture2D
	art_lin = ResourceLoader.load(ART_LIN_PATH) as Texture2D
	if art_lin == null:
		art_lin = ResourceLoader.load(ART_LIN_FALLBACK_PATH) as Texture2D
	art_cafe = ResourceLoader.load(ART_CAFE_PATH) as Texture2D
	art_night_whiteboard = ResourceLoader.load(ART_NIGHT_WHITEBOARD_PATH) as Texture2D
	art_night_mug = ResourceLoader.load(ART_NIGHT_MUG_PATH) as Texture2D
	art_night_pothos = ResourceLoader.load(ART_NIGHT_POTHOS_PATH) as Texture2D
	art_night_pothos_healthy = ResourceLoader.load(ART_NIGHT_POTHOS_HEALTHY_PATH) as Texture2D
	art_night_pothos_severe = ResourceLoader.load(ART_NIGHT_POTHOS_SEVERE_PATH) as Texture2D
	art_night_room_d = ResourceLoader.load(ART_NIGHT_ROOM_D_PATH) as Texture2D


func _create_text_inputs() -> void:
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "提灯实验室"
	name_edit.text = "提灯实验室"
	name_edit.max_length = 24
	name_edit.position = Vector2(326, 354)
	name_edit.size = Vector2(420, 52)
	name_edit.add_theme_font_override("font", font)
	name_edit.add_theme_font_size_override("font_size", 20)
	name_edit.add_theme_color_override("font_color", INK)
	name_edit.add_theme_color_override("caret_color", GREEN)
	name_edit.add_theme_stylebox_override("normal", _line_edit_style(Color(0.96, 0.96, 0.92, 0.26), COLD_40, 1))
	name_edit.add_theme_stylebox_override("focus", _line_edit_style(Color(1.0, 0.98, 0.91, 0.42), GREEN, 1))
	name_edit.text_submitted.connect(_on_company_name_submitted)
	add_child(name_edit)

	command_edit = LineEdit.new()
	command_edit.placeholder_text = "输入命令，然后按 Enter"
	command_edit.position = Vector2(834, 626)
	command_edit.size = Vector2(350, 42)
	command_edit.visible = false
	command_edit.add_theme_font_override("font", font)
	command_edit.add_theme_font_size_override("font_size", 16)
	command_edit.add_theme_color_override("font_color", TERMINAL_TEXT)
	command_edit.add_theme_color_override("font_placeholder_color", COLD_40)
	command_edit.add_theme_color_override("caret_color", GREEN_BRIGHT)
	command_edit.add_theme_stylebox_override("normal", _line_edit_style(COLD_99, INK, 6))
	command_edit.add_theme_stylebox_override("focus", _line_edit_style(COLD_95, GREEN, 6))
	command_edit.text_submitted.connect(_submit_terminal_command)
	command_edit.gui_input.connect(_on_night_command_gui_input)
	add_child(command_edit)


func _process(delta: float) -> void:
	elapsed += delta
	mouse_position = get_local_mouse_position()
	toast_timer = maxf(0.0, toast_timer - delta)
	save_status_timer = maxf(0.0, save_status_timer - delta)
	press_feedback_timer = maxf(0.0, press_feedback_timer - delta)
	# Audio follows the authored scene, including the paused settings sheet. This
	# is context-only: changing screens never manufactures a notification cue.
	if model != null and office_audio != null:
		office_audio.set_scene_context(_audio_scene_context())
	# The settings sheet is a real pause boundary. Authored holds, special-scene
	# phase clocks, and night movement cannot continue behind its PAUSED stamp.
	if settings_open:
		queue_redraw()
		return
	screen_time += delta
	if screen == Screen.EVENT and not current_event.is_empty():
		event_page_elapsed += delta
	if screen == Screen.NIGHT_SHIFT:
		night_player_position = night_player_target if reduced_motion else night_player_position.lerp(night_player_target, 1.0 - exp(-delta * 8.0))
		if night_arrival_armed and night_player_position.distance_to(night_player_target) <= 2.5:
			night_player_position = night_player_target
			night_arrival_armed = false
			_complete_night_object_arrival()
	if action_hover_amounts.size() != week_action_ids.size():
		action_hover_amounts.resize(week_action_ids.size())
		for i in action_hover_amounts.size():
			action_hover_amounts[i] = 0.0
	for i in action_hover_amounts.size():
		var hover_target := 1.0 if screen == Screen.DASHBOARD and _action_card_rect(i).has_point(mouse_position) else 0.0
		action_hover_amounts[i] = hover_target if reduced_motion else move_toward(action_hover_amounts[i], hover_target, delta * 8.0)
	if name_edit != null:
		var input_reveal := _reveal(0.22, 0.52) if screen == Screen.ONBOARDING else 1.0
		name_edit.position = Vector2(326, 354 + (1.0 - input_reveal) * 12.0)
		name_edit.modulate = Color(1.0, 1.0, 1.0, input_reveal)
	queue_redraw()


func _audio_scene_context() -> Dictionary:
	var context := {
		"screen": "title" if screen == Screen.ONBOARDING else "office",
		"chapter": int(model.chapter) if model != null else 0,
		"week_in_chapter": int(model.week_in_chapter) if model != null else 1,
		"author_weight": float(model.author_weight) if model != null else 0.0,
		"team_size": 1 + model.employees.size() if model != null else 1,
		"silence_mode": "normal",
		"night_id": "",
		"ending_id": "",
		"phase": "",
	}
	match screen:
		Screen.ACTION_RESULT, Screen.SIGNATURE:
			context["silence_mode"] = "duck_music"
		Screen.EVENT:
			var event_id := str(current_event.get("id", ""))
			var kicker := str(current_event.get("kicker", ""))
			if _event_page_is_silence():
				context["silence_mode"] = "room_tone_only"
			elif event_id == "garage_opening":
				context["screen"] = "opening"
				context["phase"] = str(_first_day_phase().get("id", "arrival"))
				context["silence_mode"] = "normal"
			elif event_id == "first_investor_meeting":
				context["screen"] = "cafe"
				context["silence_mode"] = "duck_music"
			elif event_id == "lin_scene_4" or kicker.contains("楼下"):
				context["screen"] = "downstairs"
				context["silence_mode"] = "duck_music"
			else:
				context["silence_mode"] = "duck_music"
			context["event_id"] = event_id
		Screen.NIGHT_SHIFT:
			context["screen"] = "night"
			context["night_id"] = pending_night_id if not pending_night_id.is_empty() else str(current_night.get("id", ""))
		Screen.ENDING:
			context["screen"] = "ending"
			context["ending_id"] = current_ending_id
			context["phase"] = "shutdown" if current_ending_id == "rm_rf" else "archive"
		Screen.BOARD_PRESENTATION:
			context["screen"] = "board"
		Screen.LIVE_REPLAY:
			context["screen"] = "live_replay"
		Screen.LAYOFF_SOCIAL:
			context["screen"] = "layoff_social"
	if settings_open and str(context["silence_mode"]) == "normal":
		context["silence_mode"] = "duck_music"
	return context


func _play_foley(kind: String) -> bool:
	# Authored silence is a complete dramatic contract, not merely a music mix.
	# Settings, fullscreen, navigation and accessibility shortcuts must not leak a
	# click into the opening or either Lin silence page.
	var silence_mode := str(_audio_scene_context().get("silence_mode", "normal")) if model != null else "full_silence"
	if silence_mode in ["full_silence", "room_tone_only"]:
		return false
	return office_audio != null and office_audio.play_foley(kind)


func _unhandled_input(event: InputEvent) -> void:
	var gamepad_action := _gamepad_action_from_event(event)
	if not gamepad_action.is_empty():
		gamepad_focus_visible = true
		_handle_gamepad_action(gamepad_action)
		get_viewport().set_input_as_handled()
		queue_redraw()
		return
	if screen == Screen.NIGHT_SHIFT and not settings_open:
		for action_name in ["move_left", "move_up", "move_right", "move_down", "interact"]:
			if event.is_action_pressed(action_name):
				_handle_night_navigation_action(action_name)
				return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			_toggle_fullscreen()
			return
		if event.keycode == KEY_F1:
			_toggle_settings()
			return
		if settings_open:
			if event.keycode == KEY_ESCAPE:
				_close_settings()
			elif event.keycode == KEY_R:
				_set_reduced_motion(not reduced_motion)
			elif event.keycode == KEY_M:
				_toggle_audio_setting()
			return
		if screen == Screen.INTRANET and _origin_editor_is_open():
			if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]:
				_close_origin_editor_without_change()
			return
		if event.keycode == KEY_M:
			_toggle_audio_setting()
			return
		match screen:
			Screen.ONBOARDING:
				if event.keycode == KEY_ESCAPE and new_game_confirm_pending:
					new_game_confirm_pending = false
					_show_toast("已取消新游戏。原存档仍在。")
				elif event.keycode in [KEY_ENTER, KEY_KP_ENTER] and not name_edit.has_focus():
					if _save_exists_or_recoverable() and not new_game_confirm_pending:
						_continue_game()
					else:
						_start_new_company()
			Screen.DASHBOARD:
				_handle_dashboard_key(event)
			Screen.ACTION_RESULT:
				if event.keycode in [KEY_ENTER, KEY_SPACE, KEY_E]:
					_close_result()
			Screen.EVENT:
				_handle_event_key(event)
			Screen.TEAM, Screen.TERMINAL, Screen.INTRANET, Screen.CALENDAR, Screen.ANNOUNCEMENTS:
				if event.keycode == KEY_ESCAPE:
					_navigate_to_screen(Screen.DASHBOARD)
				elif screen == Screen.INTRANET:
					_handle_intranet_key(event)
				elif screen == Screen.TEAM:
					_handle_team_key(event)
				elif screen == Screen.ANNOUNCEMENTS:
					_handle_announcements_key(event)
			Screen.NIGHT_SHIFT:
				_handle_night_key(event)
			Screen.ENDING:
				if event.keycode in [KEY_ENTER, KEY_SPACE]:
					_advance_ending()
			Screen.SIGNATURE:
				if (reduced_motion or screen_time >= 1.25) and event.keycode in [KEY_ENTER, KEY_SPACE, KEY_E]:
					_close_signature()
			Screen.BOARD_PRESENTATION:
				if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
					_advance_board_presentation()
			Screen.LIVE_REPLAY:
				if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
					_advance_live_replay()
			Screen.LAYOFF_SOCIAL:
				if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
					_advance_layoff_social()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		gamepad_focus_visible = false
		keyboard_focus_visible = false
		_record_press_feedback(event.position)
		if settings_open:
			_handle_settings_click(event.position)
			return
		if _settings_button_rect().has_point(event.position):
			_open_settings()
			return
		if screen == Screen.INTRANET and _origin_editor_is_open():
			if _origin_editor_close_rect().has_point(event.position):
				_close_origin_editor_without_change()
			return
		match screen:
			Screen.ONBOARDING:
				if _onboarding_start_rect().has_point(event.position):
					if _save_exists_or_recoverable() and not new_game_confirm_pending:
						_request_new_game_confirmation()
					else:
						_start_new_company()
				elif _continue_rect().has_point(event.position) and _save_exists_or_recoverable():
					new_game_confirm_pending = false
					_continue_game()
			Screen.DASHBOARD:
				_handle_dashboard_click(event.position)
			Screen.ACTION_RESULT:
				if _result_continue_rect().has_point(event.position):
					_close_result()
			Screen.EVENT:
				_handle_event_click(event.position)
			Screen.TEAM, Screen.TERMINAL, Screen.INTRANET, Screen.CALENDAR, Screen.ANNOUNCEMENTS:
				if screen == Screen.TEAM and _window_anomaly_visible() and _window_curtain_button_rect().has_point(event.position):
					_close_window_curtain()
				elif _content_back_rect().has_point(event.position):
					_navigate_to_screen(Screen.DASHBOARD)
				else:
					if _handle_nav_click(event.position):
						return
					if screen == Screen.INTRANET:
						_handle_intranet_click(event.position)
					elif screen == Screen.TEAM:
						_handle_team_page_click(event.position)
					elif screen == Screen.ANNOUNCEMENTS:
						_handle_announcement_page_click(event.position)
			Screen.NIGHT_SHIFT:
				_handle_night_click(event.position)
			Screen.ENDING:
				if _ending_restart_rect().has_point(event.position):
					_advance_ending()
			Screen.SIGNATURE:
				if (reduced_motion or screen_time >= 1.25) and _signature_continue_rect().has_point(event.position):
					_close_signature()
			Screen.BOARD_PRESENTATION:
				if _board_continue_rect().has_point(event.position):
					_advance_board_presentation()
			Screen.LIVE_REPLAY:
				if _live_replay_continue_rect().has_point(event.position):
					_advance_live_replay()
			Screen.LAYOFF_SOCIAL:
				if _layoff_social_continue_rect().has_point(event.position):
					_advance_layoff_social()


func _gamepad_action_from_event(event: InputEvent) -> String:
	if not event is InputEventJoypadButton or not event.pressed:
		return ""
	# Resolve semantic actions instead of relying on platform-specific button
	# numbers here. project.godot owns the physical Xbox-style mapping.
	for action_name in [
		"pause", "ui_cancel", "tab_left", "tab_right",
		"move_left", "move_up", "move_right", "move_down",
		"interact", "delegate", "end_week",
	]:
		if event.is_action_pressed(action_name):
			return action_name
	return ""


func _handle_gamepad_action(action_name: String) -> bool:
	if action_name == "pause":
		_toggle_settings()
		return true
	if settings_open:
		return _handle_settings_gamepad_action(action_name)
	if action_name == "ui_cancel":
		_handle_gamepad_cancel()
		return true
	if action_name in ["tab_left", "tab_right"]:
		_cycle_workspace_navigation(-1 if action_name == "tab_left" else 1)
		return true

	match screen:
		Screen.ONBOARDING:
			_handle_onboarding_gamepad_action(action_name)
		Screen.DASHBOARD:
			_handle_dashboard_gamepad_action(action_name)
		Screen.ACTION_RESULT:
			if action_name == "interact":
				_close_result()
		Screen.EVENT:
			_handle_event_gamepad_action(action_name)
		Screen.TEAM:
			_handle_team_gamepad_action(action_name)
		Screen.TERMINAL, Screen.CALENDAR:
			pass
		Screen.INTRANET:
			_handle_intranet_gamepad_action(action_name)
		Screen.ANNOUNCEMENTS:
			_handle_announcements_gamepad_action(action_name)
		Screen.NIGHT_SHIFT:
			if action_name in ["move_left", "move_up", "move_right", "move_down", "interact"]:
				_handle_night_navigation_action(action_name)
			elif action_name == "delegate" and night_interaction != null and night_interaction.terminal_accepts_command():
				_handle_night_ctrl_c()
		Screen.ENDING:
			if action_name == "interact":
				_advance_ending()
		Screen.SIGNATURE:
			if action_name == "interact" and (reduced_motion or screen_time >= 1.25):
				_close_signature()
		Screen.BOARD_PRESENTATION:
			if action_name == "interact":
				_advance_board_presentation()
		Screen.LIVE_REPLAY:
			if action_name == "interact":
				_advance_live_replay()
		Screen.LAYOFF_SOCIAL:
			if action_name == "interact":
				_advance_layoff_social()
	return true


func _handle_gamepad_cancel() -> void:
	# B is deliberately conservative. It may close a reversible overlay or move
	# back through workspace navigation, but never settles a week, chooses an
	# event, signs, advances a special sequence, or consumes an ending page.
	if screen == Screen.ONBOARDING:
		if new_game_confirm_pending:
			new_game_confirm_pending = false
			_show_toast("已取消新游戏。原存档仍在。")
		return
	if screen == Screen.DASHBOARD:
		if end_week_confirm_pending:
			end_week_confirm_pending = false
			_show_toast("已取消结束本周。")
		return
	if screen == Screen.EVENT and _is_first_day_prologue():
		_request_first_day_skip()
		return
	if screen == Screen.NIGHT_SHIFT:
		if not result_lines.is_empty():
			_dismiss_night_result()
		return
	if screen in [Screen.TEAM, Screen.TERMINAL, Screen.INTRANET, Screen.CALENDAR, Screen.ANNOUNCEMENTS]:
		if screen == Screen.INTRANET and _origin_editor_is_open():
			return
		_navigate_to_screen(Screen.DASHBOARD)


func _handle_onboarding_gamepad_action(action_name: String) -> void:
	_sync_focus_for_current_screen()
	if action_name in ["move_left", "move_up", "move_right", "move_down"]:
		focused_onboarding_action = focus_router.move(_gamepad_direction(action_name))
		return
	var has_save := _save_exists_or_recoverable()
	if action_name == "end_week":
		# Y is the explicit "new archive" gesture when a campaign already exists.
		if has_save:
			focused_onboarding_action = focus_router.set_index(0)
			if new_game_confirm_pending:
				_start_new_company()
			else:
				_request_new_game_confirmation()
		elif not has_save:
			_start_new_company()
		return
	if action_name != "interact":
		return
	if has_save and focus_router.index == 1:
		new_game_confirm_pending = false
		_continue_game()
	elif has_save and not new_game_confirm_pending:
		_request_new_game_confirmation()
	else:
		_start_new_company()


func _handle_dashboard_gamepad_action(action_name: String) -> void:
	_sync_focus_for_current_screen()
	if action_name in ["move_left", "move_up", "move_right", "move_down"]:
		_set_selected_action(focus_router.move(_gamepad_direction(action_name)))
	elif action_name == "interact":
		_take_selected_action(false)
	elif action_name == "delegate":
		_take_selected_action(true)
	elif action_name == "end_week":
		_finish_week()


func _handle_event_gamepad_action(action_name: String) -> void:
	_sync_focus_for_current_screen()
	if _is_first_day_prologue():
		if action_name in ["move_left", "move_up", "move_right", "move_down"] and not _first_day_choices().is_empty():
			focused_event_choice = focus_router.move(_gamepad_direction(action_name))
		elif action_name == "interact":
			if _first_day_choices().is_empty():
				_advance_first_day_prologue()
			else:
				_choose_first_day_option(focused_event_choice)
		return
	if action_name in ["move_left", "move_up", "move_right", "move_down"]:
		focused_event_choice = focus_router.move(_gamepad_direction(action_name))
		return
	if action_name != "interact":
		return
	if _is_second_time_event():
		if _second_time_phase() == SECOND_TIME_PHASE_QUESTION:
			_choose_event_option(focused_event_choice)
		else:
			_advance_second_time_interaction()
		return
	var choices: Array = current_event.get("choices", [])
	if not choices.is_empty() and _event_choices_visible():
		_choose_event_option(focused_event_choice)
	else:
		_advance_event_page_or_close()


func _handle_team_gamepad_action(action_name: String) -> void:
	if action_name == "interact" and _window_anomaly_visible():
		_close_window_curtain()
	elif action_name in ["move_left", "move_up"]:
		_set_team_page(team_page - 1)
	elif action_name in ["move_right", "move_down"]:
		_set_team_page(team_page + 1)


func _handle_intranet_gamepad_action(action_name: String) -> void:
	if _origin_editor_is_open():
		if action_name == "interact":
			_close_origin_editor_without_change()
		return
	var docs := _intranet_documents()
	if docs.is_empty():
		return
	_sync_focus_for_current_screen()
	if action_name in ["move_left", "move_right"]:
		var page_count := _selected_document_pages(docs).size()
		_set_document_page(document_page + (-1 if action_name == "move_left" else 1), page_count)
		return
	if action_name in ["move_up", "move_down"]:
		var previous_document := selected_document
		selected_document = focus_router.move(_gamepad_direction(action_name))
		document_page = 0
		if selected_document != previous_document:
			_play_foley("page")
		_mark_selected_document_read()
	elif action_name == "interact":
		if _origin_interaction_required():
			_select_intranet_document("our_origin")
			_sync_focus_for_current_screen()
		_mark_selected_document_read()


func _handle_announcements_gamepad_action(action_name: String) -> void:
	if action_name in ["move_left", "move_up"]:
		_set_announcement_page(announcement_page - 1)
	elif action_name in ["move_right", "move_down"]:
		_set_announcement_page(announcement_page + 1)


func _handle_settings_gamepad_action(action_name: String) -> bool:
	_sync_settings_focus()
	if action_name == "ui_cancel":
		_close_settings()
	elif action_name in ["move_left", "move_up", "move_right", "move_down"]:
		focused_settings_row = focus_router.move(_gamepad_direction(action_name))
	elif action_name == "interact":
		match focused_settings_row:
			0: _set_reduced_motion(not reduced_motion)
			1: _toggle_audio_setting()
			2: _toggle_fullscreen()
			3: _close_settings()
	return true


func _gamepad_direction(action_name: String) -> Vector2i:
	return {
		"move_left": Vector2i.LEFT,
		"move_up": Vector2i.UP,
		"move_right": Vector2i.RIGHT,
		"move_down": Vector2i.DOWN,
	}.get(action_name, Vector2i.ZERO)


func _cycle_workspace_navigation(direction: int) -> void:
	var screens := [Screen.DASHBOARD, Screen.TEAM, Screen.TERMINAL, Screen.CALENDAR, Screen.ANNOUNCEMENTS, Screen.INTRANET]
	var current_index := screens.find(screen)
	if current_index < 0:
		return
	_navigate_to_screen(screens[posmod(current_index + signi(direction), screens.size())])


func _sync_focus_for_current_screen() -> void:
	if focus_router == null:
		return
	if settings_open:
		_sync_settings_focus()
		return
	match screen:
		Screen.ONBOARDING:
			var has_save := _save_exists_or_recoverable()
			var default_onboarding_focus := 1 if has_save and focus_router.section != "onboarding" else focused_onboarding_action
			focused_onboarding_action = _ensure_focus_section("onboarding", 2 if has_save else 1, 1, default_onboarding_focus)
		Screen.DASHBOARD:
			selected_action = _ensure_focus_section("dashboard_actions", week_action_ids.size(), 1, selected_action)
		Screen.EVENT:
			var choices: Array = _first_day_choices() if _is_first_day_prologue() else current_event.get("choices", [])
			var choice_mode := not choices.is_empty() if _is_first_day_prologue() else (_event_choices_visible() and not choices.is_empty())
			var choice_count := choices.size() if choice_mode else 1
			var columns := 1 if _is_first_day_prologue() else (2 if choice_mode and choice_count >= 4 else 1)
			var event_section := "opening_choices:%d" % current_event_page if _is_first_day_prologue() and choice_mode else ("opening_continue:%d" % current_event_page if _is_first_day_prologue() else ("event_choices:%s" % str(current_event.get("id", "event")) if choice_mode else "event_continue:%s:%d" % [str(current_event.get("id", "event")), current_event_page]))
			focused_event_choice = _ensure_focus_section(event_section, choice_count, columns, clampi(focused_event_choice, 0, maxi(0, choice_count - 1)))
		Screen.INTRANET:
			var document_count := _intranet_documents().size() if model != null else 0
			selected_document = _ensure_focus_section("intranet_documents", document_count, 1, selected_document)


func _sync_settings_focus() -> void:
	if focus_router == null:
		return
	focused_settings_row = _ensure_focus_section("settings", 4, 1, focused_settings_row)


func _ensure_focus_section(section_name: String, count: int, columns: int, preferred: int) -> int:
	if focus_router.section != section_name or focus_router.item_count != count or focus_router.columns != columns:
		return focus_router.configure(section_name, count, columns, preferred)
	return focus_router.set_index(preferred)


func _focus_is(section_prefix: String, index: int) -> bool:
	return (
		(gamepad_focus_visible or keyboard_focus_visible)
		and focus_router != null
		and str(focus_router.section).begins_with(section_prefix)
		and focus_router.has_focus()
		and focus_router.index == index
	)


func _gamepad_shortcut(gamepad_label: String, keyboard_label: String) -> String:
	return gamepad_label if gamepad_focus_visible else keyboard_label


func _handle_dashboard_key(event: InputEventKey) -> void:
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		_set_selected_action(mini(event.keycode - KEY_1, maxi(0, week_action_ids.size() - 1)))
	elif event.keycode in [KEY_UP, KEY_W]:
		_set_selected_action(maxi(0, selected_action - 1))
	elif event.keycode in [KEY_DOWN, KEY_S]:
		_set_selected_action(mini(maxi(0, week_action_ids.size() - 1), selected_action + 1))
	elif event.keycode in [KEY_ENTER, KEY_SPACE]:
		_take_selected_action(false)
	elif event.keycode == KEY_L:
		_take_selected_action(true)
	elif event.keycode == KEY_E:
		_finish_week()
	elif event.keycode == KEY_T:
		_navigate_to_screen(Screen.TEAM)
	elif event.keycode == KEY_I:
		_navigate_to_screen(Screen.INTRANET)
	elif event.keycode == KEY_C:
		_navigate_to_screen(Screen.CALENDAR)
	elif event.keycode == KEY_A:
		_navigate_to_screen(Screen.ANNOUNCEMENTS)
	elif event.keycode == KEY_QUOTELEFT:
		_navigate_to_screen(Screen.TERMINAL)


func _on_company_name_submitted(_submitted_text: String) -> void:
	if screen != Screen.ONBOARDING:
		return
	name_edit.release_focus()
	if _save_exists_or_recoverable() and not new_game_confirm_pending:
		_request_new_game_confirmation()
		return
	_start_new_company()


func _request_new_game_confirmation() -> void:
	new_game_confirm_pending = true
	_show_toast("再次点击红色按钮或按 Enter，才会覆盖当前进度。")
	queue_redraw()


func _handle_team_key(event: InputEventKey) -> void:
	if _window_anomaly_visible() and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
		_close_window_curtain()
		return
	if event.keycode in [KEY_LEFT, KEY_A, KEY_PAGEUP]:
		_set_team_page(team_page - 1)
	elif event.keycode in [KEY_RIGHT, KEY_D, KEY_PAGEDOWN]:
		_set_team_page(team_page + 1)
	queue_redraw()


func _handle_announcements_key(event: InputEventKey) -> void:
	if event.keycode in [KEY_LEFT, KEY_A, KEY_PAGEUP]:
		_set_announcement_page(announcement_page - 1)
	elif event.keycode in [KEY_RIGHT, KEY_D, KEY_PAGEDOWN]:
		_set_announcement_page(announcement_page + 1)
	queue_redraw()


func _set_selected_action(index: int) -> void:
	var previous_action := selected_action
	selected_action = clampi(index, 0, maxi(0, week_action_ids.size() - 1))
	if focus_router != null and focus_router.section == "dashboard_actions":
		focus_router.set_index(selected_action)
	if selected_action != previous_action:
		_play_foley("page")
	if week_action_ids.is_empty() or week_action_ids[selected_action] != "layoffs":
		return
	if not bool(model.flags.get("promised_no_layoffs", false)) or bool(model.memory.get("ui_layoff_warning_seen", false)):
		return
	var speaker := _model_private_name() if int(model.chapter) < 4 else _model_official_name()
	terminal_lines.append("> %s：你说过不会裁员。" % speaker)
	model.memory["ui_layoff_warning_seen"] = true
	_show_toast("终端：你说过不会裁员。")
	_save_game()


func _handle_event_key(event: InputEventKey) -> void:
	if _is_first_day_prologue():
		if event.keycode in [KEY_K, KEY_ESCAPE]:
			_request_first_day_skip()
			return
		var opening_choices := _first_day_choices()
		if not opening_choices.is_empty() and event.keycode >= KEY_1 and event.keycode <= KEY_3:
			_choose_first_day_option(event.keycode - KEY_1)
		elif not opening_choices.is_empty() and event.keycode in [KEY_UP, KEY_W, KEY_DOWN, KEY_S]:
			keyboard_focus_visible = true
			_sync_focus_for_current_screen()
			focused_event_choice = focus_router.move(Vector2i.UP if event.keycode in [KEY_UP, KEY_W] else Vector2i.DOWN)
		elif not opening_choices.is_empty() and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			_choose_first_day_option(focused_event_choice)
		elif opening_choices.is_empty() and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			_advance_first_day_prologue()
		return
	if _is_second_time_event():
		if _second_time_phase() == SECOND_TIME_PHASE_QUESTION and event.keycode >= KEY_1 and event.keycode <= KEY_2:
			_choose_event_option(event.keycode - KEY_1)
		elif _second_time_phase() == SECOND_TIME_PHASE_QUESTION and event.keycode in [KEY_UP, KEY_W, KEY_DOWN, KEY_S]:
			keyboard_focus_visible = true
			_sync_focus_for_current_screen()
			focused_event_choice = focus_router.move(Vector2i.UP if event.keycode in [KEY_UP, KEY_W] else Vector2i.DOWN)
		elif _second_time_phase() == SECOND_TIME_PHASE_QUESTION and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			_choose_event_option(focused_event_choice)
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			_advance_second_time_interaction()
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_9 and _event_choices_visible():
		_choose_event_option(event.keycode - KEY_1)
	elif _event_choices_visible() and not Array(current_event.get("choices", [])).is_empty() and event.keycode in [KEY_LEFT, KEY_A, KEY_UP, KEY_W, KEY_RIGHT, KEY_D, KEY_DOWN, KEY_S]:
		keyboard_focus_visible = true
		_sync_focus_for_current_screen()
		var direction := Vector2i.ZERO
		if event.keycode in [KEY_LEFT, KEY_A]: direction = Vector2i.LEFT
		elif event.keycode in [KEY_UP, KEY_W]: direction = Vector2i.UP
		elif event.keycode in [KEY_RIGHT, KEY_D]: direction = Vector2i.RIGHT
		else: direction = Vector2i.DOWN
		focused_event_choice = focus_router.move(direction)
	elif _event_choices_visible() and not Array(current_event.get("choices", [])).is_empty() and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
		_choose_event_option(focused_event_choice)
	elif (current_event.get("choices", []).is_empty() or not _event_choices_visible()) and event.keycode in [KEY_ENTER, KEY_SPACE, KEY_E]:
		_advance_event_page_or_close()


func _handle_intranet_key(event: InputEventKey) -> void:
	var docs := _intranet_documents()
	if docs.is_empty():
		return
	var page_count := _selected_document_pages(docs).size()
	if event.keycode in [KEY_LEFT, KEY_A, KEY_PAGEUP]:
		_set_document_page(document_page - 1, page_count)
		queue_redraw()
		return
	if event.keycode in [KEY_RIGHT, KEY_D, KEY_PAGEDOWN]:
		_set_document_page(document_page + 1, page_count)
		queue_redraw()
		return
	if _origin_interaction_required():
		_select_intranet_document("our_origin")
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			_mark_selected_document_read()
		return
	var opened := false
	var previous_document := selected_document
	if event.keycode in [KEY_UP, KEY_W]:
		selected_document = maxi(0, selected_document - 1)
		document_page = 0
		opened = true
	elif event.keycode in [KEY_DOWN, KEY_S]:
		selected_document = mini(docs.size() - 1, selected_document + 1)
		document_page = 0
		opened = true
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
		opened = true
	if opened:
		if selected_document != previous_document:
			_play_foley("page")
		_mark_selected_document_read()


func _handle_night_key(event: InputEventKey) -> void:
	if event.ctrl_pressed and event.keycode == KEY_C:
		_handle_night_ctrl_c()
		return
	if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER] and not result_lines.is_empty():
		_dismiss_night_result()
		return
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER] and _night_complete():
		_finish_night_shift()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_activate_focused_night_object()
	elif event.keycode == KEY_SLASH and night_interaction != null and night_interaction.terminal_accepts_command():
		command_edit.visible = true
		command_edit.grab_focus()


func _handle_night_navigation_action(action_name: String) -> void:
	if not result_lines.is_empty():
		if action_name == "interact":
			_dismiss_night_result()
		return
	if action_name == "interact":
		if _night_complete():
			_finish_night_shift()
		else:
			_activate_focused_night_object()
		return
	if night_objects.is_empty():
		return
	var direction := -1 if action_name in ["move_left", "move_up"] else 1
	night_focused_object_index = posmod(night_focused_object_index + direction, night_objects.size())
	var focused_rect := Rect2(night_objects[night_focused_object_index].get("rect", Rect2()))
	if focused_rect.size != Vector2.ZERO:
		if night_player_position.distance_to(focused_rect.get_center()) > 2.5:
			_play_foley("footstep")
		night_player_target = focused_rect.get_center()
	queue_redraw()


func _activate_focused_night_object() -> void:
	if night_objects.is_empty():
		return
	night_focused_object_index = clampi(night_focused_object_index, 0, night_objects.size() - 1)
	_queue_night_object_visit(night_objects[night_focused_object_index])


func _on_night_command_gui_input(event: InputEvent) -> void:
	if screen != Screen.NIGHT_SHIFT:
		return
	var gamepad_action := _gamepad_action_from_event(event)
	if not gamepad_action.is_empty():
		gamepad_focus_visible = true
		match gamepad_action:
			"pause": _toggle_settings()
			"ui_cancel":
				command_edit.release_focus()
				command_edit.visible = false
			"delegate": _handle_night_ctrl_c()
		get_viewport().set_input_as_handled()
		queue_redraw()
		return
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event
	if key_event.pressed and not key_event.echo and key_event.ctrl_pressed and key_event.keycode == KEY_C:
		_handle_night_ctrl_c()
		get_viewport().set_input_as_handled()


func _handle_night_ctrl_c() -> void:
	if night_interaction == null:
		return
	var interrupted: Dictionary = night_interaction.handle_ctrl_c(true, "C")
	if not bool(interrupted.get("ok", false)):
		return
	# It interrupts nothing and therefore emits no terminal reply, modal, toast,
	# or sound. Completion is visible only in the hotspot's quiet state change.
	model.flags["night2_terminal_ctrl_c"] = true
	night_seen = night_interaction.completed_object_ids()
	command_edit.text = ""
	command_edit.release_focus()
	command_edit.visible = false
	_save_game()
	queue_redraw()


func _handle_dashboard_click(position: Vector2) -> void:
	if _handle_nav_click(position):
		return
	for i in week_action_ids.size():
		if _action_card_rect(i).has_point(position):
			_set_selected_action(i)
			return
	if _action_self_rect().has_point(position):
		_take_selected_action(false)
	elif _action_ai_rect().has_point(position):
		_take_selected_action(true)
	elif _end_week_rect().has_point(position):
		_finish_week()


func _handle_event_click(position: Vector2) -> void:
	if _is_first_day_prologue():
		if _first_day_skip_rect().has_point(position):
			_request_first_day_skip()
			return
		var opening_choices := _first_day_choices()
		if opening_choices.is_empty():
			if _first_day_continue_rect().has_point(position):
				_advance_first_day_prologue()
		else:
			for i in opening_choices.size():
				if _first_day_choice_rect(i).has_point(position):
					_choose_first_day_option(i)
					return
		return
	if _is_second_time_event():
		if _second_time_phase() == SECOND_TIME_PHASE_QUESTION:
			for i in Array(current_event.get("choices", [])).size():
				if _second_time_choice_rect(i).has_point(position):
					_choose_event_option(i)
					return
		elif _second_time_continue_rect().has_point(position):
			_advance_second_time_interaction()
		return
	var choices: Array = current_event.get("choices", [])
	if choices.is_empty() or not _event_choices_visible():
		if _event_continue_rect().has_point(position):
			_advance_event_page_or_close()
		return
	for i in choices.size():
		if _event_choice_rect(i).has_point(position):
			_choose_event_option(i)
			return


func _handle_intranet_click(position: Vector2) -> void:
	var docs := _intranet_documents()
	var document_pages := _selected_document_pages(docs)
	if _document_prev_rect().has_point(position) and document_page > 0:
		_set_document_page(document_page - 1, document_pages.size())
		queue_redraw()
		return
	if _document_next_rect().has_point(position) and document_page + 1 < document_pages.size():
		_set_document_page(document_page + 1, document_pages.size())
		queue_redraw()
		return
	if _origin_interaction_required() and _origin_reread_rect().has_point(position):
		_select_intranet_document("our_origin")
		_mark_selected_document_read()
		return
	for i in docs.size():
		if _document_rect(i).has_point(position):
			if _origin_interaction_required() and str(Dictionary(docs[i]).get("id", "")) != "our_origin":
				return
			var changed := selected_document != i
			selected_document = i
			document_page = 0
			if changed:
				_play_foley("page")
			_mark_selected_document_read()
			return


func _handle_team_page_click(position: Vector2) -> void:
	if _team_prev_rect().has_point(position):
		_set_team_page(team_page - 1)
	elif _team_next_rect().has_point(position):
		_set_team_page(team_page + 1)
	queue_redraw()


func _handle_announcement_page_click(position: Vector2) -> void:
	if _announcement_prev_rect().has_point(position):
		_set_announcement_page(announcement_page - 1)
	elif _announcement_next_rect().has_point(position):
		_set_announcement_page(announcement_page + 1)
	queue_redraw()


func _set_document_page(next_page: int, page_count: int) -> bool:
	var clamped := clampi(next_page, 0, maxi(0, page_count - 1))
	if clamped == document_page:
		return false
	document_page = clamped
	_play_foley("page")
	_save_game()
	return true


func _set_team_page(next_page: int) -> bool:
	var clamped := clampi(next_page, 0, maxi(0, _team_page_count() - 1))
	if clamped == team_page:
		return false
	team_page = clamped
	_play_foley("page")
	_save_game()
	return true


func _set_announcement_page(next_page: int) -> bool:
	var clamped := clampi(next_page, 0, maxi(0, _announcement_page_count() - 1))
	if clamped == announcement_page:
		return false
	announcement_page = clamped
	_play_foley("page")
	_save_game()
	return true


func _handle_night_click(position: Vector2) -> void:
	if not result_lines.is_empty():
		if _night_modal_close_rect().has_point(position):
			_dismiss_night_result()
		return
	for object in night_objects:
		var rect := Rect2(object.get("rect", Rect2()))
		if rect.has_point(position):
			_queue_night_object_visit(object)
			return
	if _night_exit_rect().has_point(position) and _night_complete():
		_finish_night_shift()


func _queue_night_object_visit(object: Dictionary) -> void:
	if night_interaction == null:
		return
	var object_id := str(object.get("id", ""))
	if object_id.is_empty() or not night_interaction.object_ids().has(object_id):
		return
	var rect := Rect2(object.get("rect", Rect2()))
	var target := rect.get_center()
	var phase := str(night_interaction.object_phase(object_id))
	if str(night_interaction.night_id) == "1" and object_id == "corridor":
		var pass_count := int(night_interaction.object_state(object_id).get("pass_count", 0))
		# Alternate between opposite corridor ends. Three clicks therefore mean
		# three physical crossings, rather than three reads at one coordinate.
		target = Vector2(154.0 if pass_count % 2 == 0 else 1126.0, 340.0)
	elif str(night_interaction.night_id) == "2" and object_id == "meeting_room_d":
		var walked_steps := int(night_interaction.object_state(object_id).get("walked_steps", 0))
		if phase == "door_closed":
			target = rect.get_center() + Vector2(-86.0, 0.0)
		elif phase == "walked_away" and walked_steps < 2:
			target = rect.get_center() + Vector2(-172.0, 0.0)
		elif phase == "walked_away" and walked_steps >= 2:
			target = rect.get_center()
	night_pending_object_id = object_id
	if night_player_position.distance_to(target) > 2.5:
		_play_foley("footstep")
	night_player_target = target
	night_arrival_armed = true
	if night_player_position.distance_to(night_player_target) <= 2.5:
		night_arrival_armed = false
		_complete_night_object_arrival()
	_save_game()


func _complete_night_object_arrival() -> void:
	if night_interaction == null or night_pending_object_id.is_empty():
		return
	var object_id := night_pending_object_id
	night_pending_object_id = ""
	var object := _night_object_by_id(object_id)
	if object.is_empty():
		return
	var activation: Dictionary = night_interaction.activate_object(object_id)
	if not bool(activation.get("ok", false)):
		return
	if night_interaction.is_object_complete(object_id):
		_show_night_object_result(object, _to_string_array(object.get("body", [])))
		return

	var transition: Dictionary = {}
	var foley_after_success := ""
	var lines: Array[String] = []
	if str(night_interaction.night_id) == "1":
		if object_id == "corridor":
			transition = night_interaction.advance_object(object_id, "cross")
			var pass_count := int(night_interaction.object_state(object_id).get("pass_count", 0))
			if pass_count >= 3:
				lines = _to_string_array(object.get("body", []))
			else:
				lines = [
					"第%s遍。灯是感应的。" % ("一" if pass_count == 1 else "二"),
					"你走到哪儿亮到哪儿，身后一段一段地灭。",
				]
		else:
			transition = night_interaction.advance_object(object_id, "inspect")
			lines = _to_string_array(object.get("body", []))
	else:
		match object_id:
			"pothos":
				transition = night_interaction.advance_object(object_id, "inspect")
				lines = _to_string_array(object.get("body", []))
			"window_desk":
				var desk_phase := str(night_interaction.object_phase(object_id))
				if desk_phase == "awaiting_inspection":
					foley_after_success = "cup"
					transition = night_interaction.advance_object(object_id, "inspect_screen_cup")
					lines = [
						"显示器还开着。屏保是公司 logo 在慢慢转。",
						"桌上有一个马克杯，杯底一层干掉的褐色。杯身印着『第一届全员团建·2024』。",
						"参加那次团建的人现在剩下两个。",
					]
				elif desk_phase == "inspect_screen_cup":
					foley_after_success = "cup"
					transition = night_interaction.advance_object(object_id, "pick_up_cup")
					lines = ["你把杯子拿起来。杯底的褐色没有动。"]
				elif desk_phase == "cup_picked_up":
					foley_after_success = "cup"
					transition = night_interaction.advance_object(object_id, "replace_cup", {"distance_cm": 2})
					lines = [
						"你又把它放回原位，位置差了两厘米。",
						"明天不会有人发现。这里已经没有人会发现两厘米。",
					]
			"meeting_room_d":
				var room_phase := str(night_interaction.object_phase(object_id))
				var room_state: Dictionary = night_interaction.object_state(object_id)
				if room_phase == "outside":
					foley_after_success = "door"
					transition = night_interaction.advance_object(object_id, "enter_room")
					lines = [
						"楼层图上没有这间。日程系统里有。",
						"门开着，灯亮着，投影仪在待机，蓝色的光。",
						"白板上有字，写得很工整：『下周同一时间。』",
					]
				elif room_phase == "projection_seen":
					foley_after_success = "door"
					transition = night_interaction.advance_object(object_id, "exit_and_close")
					lines = ["你退出来，把门带上。灯还亮着。"]
				elif room_phase in ["door_closed", "walked_away"] and int(room_state.get("walked_steps", 0)) < 2:
					foley_after_success = "footstep"
					transition = night_interaction.advance_object(object_id, "walk_away", {"steps": 1})
					var steps := int(night_interaction.object_state(object_id).get("walked_steps", 0))
					lines = ["你走了%s步。" % ("一" if steps == 1 else "两")]
				elif room_phase == "walked_away":
					foley_after_success = "footstep"
					transition = night_interaction.advance_object(object_id, "return_to_room")
					lines = ["你又走了回去。灯还亮着。"]
				elif room_phase == "returned":
					foley_after_success = "switch"
					transition = night_interaction.advance_object(object_id, "turn_light_off")
					lines = ["你把灯关了。", "电费是公司出的。"]
			"terminal":
				var terminal_phase := str(night_interaction.object_phase(object_id))
				if terminal_phase == "arrived":
					transition = night_interaction.advance_object(object_id, "inspect_unsent_dialogue")
					lines = [
						"有人忘了退出登录。屏幕上是一段没发出去的对话：",
						"> 你觉得我们还能撑多久",
						"> 这取决于『我们』指的是哪一部分。",
						"光标还在闪。",
					]
				elif terminal_phase == "dialogue_inspected":
					foley_after_success = "terminal"
					transition = night_interaction.advance_object(object_id, "focus_terminal")
				elif terminal_phase == "focused":
					command_edit.visible = true
					command_edit.grab_focus()

	if not transition.is_empty() and not bool(transition.get("ok", false)):
		return
	if object_id == "terminal" and str(night_interaction.object_phase(object_id)) == "focused":
		command_edit.visible = true
		command_edit.grab_focus()
	if not transition.is_empty() and not foley_after_success.is_empty():
		_play_foley(foley_after_success)
	night_seen = night_interaction.completed_object_ids()
	if not lines.is_empty():
		_show_night_object_result(object, lines)
	_save_game()
	queue_redraw()


func _show_night_object_result(object: Dictionary, lines: Array[String]) -> void:
	result_title = str(object.get("label", object.get("name", "物件")))
	result_lines = lines.duplicate()


func _dismiss_night_result() -> bool:
	if screen != Screen.NIGHT_SHIFT or result_lines.is_empty():
		return false
	_play_foley("page")
	result_lines.clear()
	_save_game()
	queue_redraw()
	return true


func _night_object_by_id(object_id: String) -> Dictionary:
	for object in night_objects:
		if str(object.get("id", "")) == object_id:
			return object
	return {}


func _handle_nav_click(position: Vector2) -> bool:
	for i in 6:
		if _nav_rect(i).has_point(position):
			var target_screen: Screen = [Screen.DASHBOARD, Screen.TEAM, Screen.TERMINAL, Screen.CALENDAR, Screen.ANNOUNCEMENTS, Screen.INTRANET][i]
			if target_screen != screen:
				_navigate_to_screen(target_screen)
			return true
	return false


func _navigate_to_screen(target_screen: Screen) -> bool:
	var previous_screen := screen
	var entry_saved := _change_screen(target_screen)
	if previous_screen == screen or screen != target_screen:
		return false
	_play_foley("page")
	if not entry_saved:
		_save_game()
	return true


func _start_new_company() -> void:
	var company := name_edit.text.strip_edges()
	if company.is_empty():
		company = "提灯实验室"
	var started: Dictionary = director.start_company(company, second_run_unlocked)
	if not bool(started.get("ok", false)):
		_show_toast("公司工作区初始化失败。")
		return
	model = director.model
	if not last_ending_id.is_empty():
		model.memory["previous_ending"] = last_ending_id
	terminal_lines.clear()
	terminal_lines.append("> 系统初始化完成。")
	terminal_lines.append("> %s / %s" % [_model_official_name(), _model_private_name()])
	_sync_system_activity()
	used_action_ids.clear()
	used_action_authors.clear()
	_refresh_week_actions()
	name_edit.visible = false
	command_edit.visible = false
	var opening_value = started.get("event", {})
	var opening: Dictionary = opening_value if opening_value is Dictionary else {}
	if not opening.is_empty():
		_open_event(opening)
	else:
		_change_screen(Screen.DASHBOARD)
	_save_game()


func _continue_game() -> void:
	var loaded: Dictionary = HiringStorage.load_dictionary(_save_file_path())
	if not bool(loaded.get("ok", false)):
		_show_toast("存档与备份都无法读取。")
		return
	var parsed: Dictionary = Dictionary(loaded.get("data", {})).duplicate(true)
	var resumed: Dictionary = director.resume(parsed)
	if not bool(resumed.get("ok", false)):
		_show_toast("存档版本无法读取。")
		return
	model = director.model
	_recover_meta_from_campaign(parsed)
	name_edit.visible = false
	command_edit.visible = false
	used_action_ids = _to_string_array(parsed.get("ui_used_actions", []))
	var authors_value = parsed.get("ui_used_action_authors", {})
	used_action_authors = authors_value.duplicate(true) if authors_value is Dictionary else {}
	terminal_lines = _to_string_array(parsed.get("ui_terminal", []))
	pending_week_advance = bool(parsed.get("ui_pending_week_advance", false))
	pending_night_id = str(parsed.get("ui_pending_night_id", ""))
	result_title = str(parsed.get("ui_result_title", ""))
	result_lines = _to_string_array(parsed.get("ui_result_lines", []))
	result_return = str(parsed.get("ui_result_return", "dashboard"))
	result_page = int(parsed.get("ui_result_page", 0))
	current_event = Dictionary(parsed.get("ui_current_event", {})).duplicate(true)
	current_event_page = int(parsed.get("ui_current_event_page", 0))
	event_page_elapsed = maxf(0.0, float(parsed.get("ui_event_page_elapsed", 0.0)))
	if str(current_event.get("id", "")) == "garage_opening":
		var hydrated_opening := _current_first_day_event(current_event)
		if Array(current_event.get("opening_phases", [])).is_empty() and not Array(hydrated_opening.get("opening_phases", [])).is_empty():
			current_event_page = 0
			event_page_elapsed = 0.0
		current_event = hydrated_opening
	current_ending_id = str(parsed.get("ui_current_ending_id", ""))
	current_ending = Dictionary(parsed.get("ui_current_ending", {})).duplicate(true)
	ending_page = maxi(0, int(parsed.get("ui_ending_page", 0)))
	current_night = Dictionary(parsed.get("ui_current_night", {})).duplicate(true)
	night_seen = _to_string_array(parsed.get("ui_night_seen", []))
	var saved_night_focus := maxi(0, int(parsed.get("ui_night_focus_index", 0)))
	var saved_night_interaction := Dictionary(parsed.get("ui_night_interaction", {})).duplicate(true)
	selected_action = int(parsed.get("ui_selected_action", 0))
	selected_document = int(parsed.get("ui_selected_document", 0))
	document_page = maxi(0, int(parsed.get("ui_document_page", 0)))
	team_page = maxi(0, int(parsed.get("ui_team_page", 0)))
	announcement_page = maxi(0, int(parsed.get("ui_announcement_page", 0)))
	var saved_screen := _screen_from_save(parsed)
	if terminal_lines.is_empty():
		terminal_lines.append("> 已恢复工作区。")
	if str(current_event.get("id", "")) == "second_time_opening":
		_prepare_second_time_event()
	elif str(current_event.get("id", "")) == "second_time_placement" and _second_time_phase().is_empty():
		model.memory["second_time_cup_phase"] = SECOND_TIME_PHASE_ANSWERED
		model.memory["second_time_cup_position"] = "founder_desk"
	_sync_system_activity()
	if not _restore_week_actions_from_save(parsed):
		_refresh_week_actions()
	if saved_screen == Screen.ENDING and not current_ending_id.is_empty():
		if current_ending.is_empty():
			current_ending = director.ending_for_id(current_ending_id)
		_change_screen(Screen.ENDING)
	elif not current_event.is_empty():
		_change_screen(Screen.EVENT)
	elif not current_night.is_empty():
		var remembered_seen := night_seen.duplicate()
		_open_night_shift(current_night)
		if night_interaction != null and not saved_night_interaction.is_empty():
			var restored_night: Dictionary = night_interaction.load_save(saved_night_interaction)
			if bool(restored_night.get("ok", false)):
				night_seen = night_interaction.completed_object_ids()
			else:
				night_seen = remembered_seen
		else:
			night_seen = remembered_seen
		night_focused_object_index = clampi(saved_night_focus, 0, maxi(0, night_objects.size() - 1))
		command_edit.visible = night_interaction != null and night_interaction.terminal_accepts_command()
	elif bool(model.flags.get("board_presentation_active", false)):
		_change_screen(Screen.BOARD_PRESENTATION, false)
	elif bool(model.flags.get("live_replay_active", false)):
		_change_screen(Screen.LIVE_REPLAY, false)
	elif bool(model.flags.get("layoff_social_active", false)):
		_change_screen(Screen.LAYOFF_SOCIAL, false)
	elif saved_screen == Screen.SIGNATURE:
		_change_screen(Screen.SIGNATURE)
	elif not result_lines.is_empty() and saved_screen == Screen.ACTION_RESULT:
		_change_screen(Screen.ACTION_RESULT)
	else:
		_queue_week_content()
	_report_loaded_storage_status(loaded)


func _take_selected_action(use_ai: bool) -> void:
	end_week_confirm_pending = false
	if selected_action < 0 or selected_action >= week_action_ids.size():
		return
	var action_id := week_action_ids[selected_action]
	if used_action_ids.has(action_id):
		_play_foley("blocked")
		_show_toast("这件事本周已经处理过了。")
		return
	if not model.can_act(action_id, use_ai):
		_play_foley("blocked")
		_show_toast(_action_unavailable_reason(action_id, use_ai))
		return
	var writer_stage_before: int = model.writer_stage()
	var result: Dictionary = director.perform_action(action_id, use_ai)
	if not bool(result.get("ok", true)):
		_play_foley("blocked")
		_show_toast(str(result.get("message", "现在做不了这件事。")))
		return
	if action_id == "sign":
		_play_foley("signature")
	elif use_ai:
		_play_foley("terminal")
	else:
		_play_foley("confirm")
	used_action_ids.append(action_id)
	used_action_authors[action_id] = "model" if use_ai else "self"
	result_title = str(result.get("title", _action_name(action_id)))
	result_page = 0
	result_lines = _to_string_array(result.get("messages", result.get("lines", result.get("message", []))))
	if result_lines.is_empty():
		result_lines.append("处理完成。")
	_append_first_week_lin_reaction(result_lines, action_id, use_ai)
	if use_ai:
		_append_stage_one_ai_offer(result_lines, writer_stage_before)
		terminal_lines.append("> %s：已处理。结果已同步。" % _model_private_name())
	else:
		terminal_lines.append("> 本周：%s" % _action_name(action_id))
	result_return = "queue_week_content" if action_id in ["interview", "one_on_one"] else "dashboard"
	# DEC-008: cash exhaustion is an immediate terminal state.  Do this before
	# routing to signatures, documents, result pagination, or another action.
	if _open_cash_exhaustion_ending_if_needed():
		return
	var screen_entry_saved := false
	if action_id == "sign":
		screen_entry_saved = _change_screen(Screen.SIGNATURE)
	elif action_id == "read_intranet":
		var docs := _intranet_documents()
		selected_document = _latest_intranet_document_index(docs)
		document_page = 0
		_record_intranet_action_review(docs, use_ai)
		screen_entry_saved = _change_screen(Screen.INTRANET)
		_show_toast("本周审阅已登记 · %s" % (_model_official_name() if use_ai else "你"))
	else:
		screen_entry_saved = _change_screen(Screen.ACTION_RESULT)
	if not screen_entry_saved:
		_save_game()


func _append_first_week_lin_reaction(lines: Array[String], action_id: String, used_ai: bool) -> void:
	if model == null or int(model.chapter) != 0 or int(model.total_week) != 1:
		return
	if bool(model.memory.get("first_week_lin_reaction_seen", false)):
		return
	var reaction := ""
	match action_id:
		"train": reaction = "林越摘下一边耳机：『第 47 题还没过。第 48 题开始像在听人说话了。』"
		"clean_data": reaction = "林越看完差异：『终于有人承认问题可能在数据，不全在我。』"
		"buy_compute": reaction = "风扇又高了一档。林越说：『听见了吗？这是现金在旋转。』"
		"do_nothing": reaction = "林越看了眼时间：『七点前下班。没有东西着火。这也算一次成功。』"
		_: reaction = "林越把椅子滑过来，看完结果：『行。下一件。』"
	if used_ai:
		reaction += " 她又看了一眼终端：『它交得比你早。先别高兴。』"
	lines.append(reaction)
	model.memory["first_week_lin_reaction_seen"] = true
	model.memory["first_week_lin_reaction_action"] = action_id
	var relationship := _lin_relationship_seed()
	relationship["trust"] = int(relationship.get("trust", 0)) + (0 if action_id == "do_nothing" else 1)
	relationship["rapport"] = int(relationship.get("rapport", 0)) + (1 if action_id in ["clean_data", "buy_compute"] else 0)
	model.memory["lin_relationship"] = relationship


func _append_stage_one_ai_offer(lines: Array[String], writer_stage_before: int) -> void:
	if writer_stage_before != 1:
		return
	var exact_offer := "如果需要我可以再改"
	if "\n".join(lines).contains(exact_offer):
		return
	lines.append("%s：%s。" % [_model_private_name(), exact_offer])


func _open_cash_exhaustion_ending_if_needed() -> bool:
	if model == null or float(model.cash_weeks) > 0.0:
		return false
	model.flags["cash_exhausted"] = true
	terminal_lines.append("> 现金储备已耗尽。")
	# Use the canonical resolver instead of hard-coding Lights Out so an already
	# entered rm -rf command retains its absolute DEC-008 priority.
	var ending: Dictionary = model.select_ending()
	_open_ending(str(ending.get("id", "lights_out")))
	return true


func _finish_week() -> void:
	if (
		model != null
		and int(model.attention) > 0
		and not end_week_confirm_pending
	):
		end_week_confirm_pending = true
		_play_foley("blocked")
		_show_toast("还有 %d 点注意力。再次结束即可主动空过。" % int(model.attention))
		queue_redraw()
		return
	if end_week_confirm_pending:
		end_week_confirm_pending = false
	_append_week_end_unsolicited_line()
	var summary: Dictionary = director.finish_week()
	if not bool(summary.get("ok", false)):
		var blocking_value = summary.get("event", {})
		var blocking_event: Dictionary = blocking_value if blocking_value is Dictionary else {}
		if not blocking_event.is_empty():
			_open_event(blocking_event)
			current_event["_ui_resume_finish_week"] = true
			_save_game()
			return
		_play_foley("blocked")
		_show_toast("本周还有未处理的事项。")
		return
	_play_foley("page")
	result_title = "第 %d 周 · 周结算" % int(model.total_week)
	result_page = 0
	result_lines = _to_string_array(summary.get("lines", []))
	if result_lines.is_empty():
		result_lines = ["叙事自然衰减。", "办公室又安静了一点。"]
	_append_first_week_settlement(result_lines)
	terminal_lines.append("> 第 %d 周归档。" % int(model.total_week))
	var ending_value = summary.get("ending", {})
	var ending: Dictionary = ending_value if ending_value is Dictionary else {}
	if not ending.is_empty():
		_open_ending(str(ending.get("id", ending.get("resolution", {}).get("id", "lights_out"))))
		return
	pending_week_advance = true
	result_return = "advance_week"
	_change_screen(Screen.ACTION_RESULT)
	_save_game()


func _append_first_week_settlement(lines: Array[String]) -> void:
	if model == null or int(model.chapter) != 0 or int(model.total_week) != 1:
		return
	var handled := used_action_ids.size()
	var left_open := maxi(0, week_action_ids.size() - handled)
	lines.push_front("你们完成了 %d 件事，留下 %d 件。公司活过了第一周。" % [handled, left_open])
	var name_choice := str(model.memory.get("garage_name_choice", "pragmatic"))
	match name_choice:
		"warm": lines.append("门上的纸角又翘起来。林越按住它：『名字还行。人也还在。』")
		"wry": lines.append("林越在白板角落写：‘新建文件夹 / Week 1 / 未倒闭’。然后划掉了前四个字。")
		"skipped": lines.append("门上的纸角又翘起来。林越按平它，没有替你补上那段没说完的话。")
		_: lines.append("墨还没买，门也没换。林越在 A4 纸背面写下：‘Week 1 / 还在。’")


func _close_result() -> void:
	_play_foley("page")
	var pages := _result_pages()
	if result_page + 1 < pages.size():
		result_page += 1
		_save_game()
		return
	result_lines.clear()
	night_player_position = Vector2(640, 540)
	night_player_target = night_player_position
	result_page = 0
	if result_return == "advance_week" or pending_week_advance:
		var night: Dictionary = director.pending_night_shift()
		if not night.is_empty():
			_open_night_shift(night)
			_save_game()
			return
		if not _advance_after_week():
			_save_game()
	elif result_return == "queue_week_content":
		result_return = "dashboard"
		if not _queue_week_content():
			_save_game()
	elif result_return == "resume_finish_week":
		result_return = "dashboard"
		_finish_week()
	else:
		_change_screen(Screen.DASHBOARD)
		_save_game()


func _queue_week_content() -> bool:
	# Required finale interactions are part of their fixed beat, not optional
	# navigation. They remain ahead of generic/debt modals after a save resume.
	if _origin_interaction_required() and _select_intranet_document("our_origin"):
		var origin_first_open := bool(model.flags.get("origin_article_ui_requested", false))
		model.flags["origin_article_ui_requested"] = false
		return _change_screen(Screen.INTRANET, origin_first_open)
	if _window_interaction_required():
		var window_first_open := bool(model.flags.get("window_team_ui_requested", false))
		model.flags["window_team_ui_requested"] = false
		return _change_screen(Screen.TEAM, window_first_open)
	var event: Dictionary = director.next_event()
	_sync_memory_callbacks()
	if not event.is_empty():
		_open_event(event)
		return false
	return _change_screen(Screen.DASHBOARD)


func _advance_after_week() -> bool:
	pending_week_advance = false
	result_return = "dashboard"
	var advancement: Dictionary = director.advance()
	if not bool(advancement.get("ok", false)):
		var night_value = advancement.get("night_shift", {})
		var night: Dictionary = night_value if night_value is Dictionary else {}
		if not night.is_empty():
			pending_week_advance = true
			_open_night_shift(night)
			return bool(_save_game().get("ok", false))
		_show_toast("周次暂时无法推进。")
		return bool(_save_game().get("ok", false))
	if bool(advancement.get("campaign_complete", false)):
		var ending_value = advancement.get("ending", {})
		var ending: Dictionary = ending_value if ending_value is Dictionary else {}
		_open_ending(str(ending.get("id", "acquihire")))
		return true
	used_action_ids.clear()
	used_action_authors.clear()
	_refresh_week_actions()
	_sync_system_activity()
	var event_value = advancement.get("event", {})
	var event: Dictionary = event_value if event_value is Dictionary else {}
	if not event.is_empty():
		_open_event(event)
		return bool(_save_game().get("ok", false))
	if _queue_week_content():
		return true
	return bool(_save_game().get("ok", false))


func _ng_plus_opening() -> Dictionary:
	var source := HiringContent.get_ending("second_time")
	return {
		"id": "second_time_opening",
		"title": str(source.get("title", "第二次")),
		"kicker": "2024 年 3 月 · 第 1 周",
		"body": source.get("text", []),
		"choices": source.get("choices", []),
		"epilogue": source.get("epilogue", []),
		"after": "continue_ng_plus"
	}


func _prepare_second_time_event() -> void:
	var authored_body := _to_string_array(current_event.get("body", []))
	current_event["body"] = authored_body.slice(0, mini(3, authored_body.size()))
	# The remaining authored prose is now performed by the player. Keeping it out
	# of the generic event body prevents the UI from claiming those actions early.
	current_event["epilogue"] = []
	current_event["_ui_interaction"] = "second_time_cup"
	model.flags["second_time_cup_interaction_required"] = true
	if _second_time_phase().is_empty():
		model.memory["second_time_cup_phase"] = SECOND_TIME_PHASE_PRESENT
		model.memory["second_time_cup_position"] = "founder_desk"


func _is_second_time_event() -> bool:
	return str(current_event.get("id", "")) in ["second_time_opening", "second_time_placement"]


func _second_time_phase() -> String:
	if model == null:
		return ""
	return str(model.memory.get("second_time_cup_phase", ""))


func _advance_second_time_interaction() -> void:
	if not _is_second_time_event():
		return
	match _second_time_phase():
		SECOND_TIME_PHASE_PRESENT:
			_play_foley("cup")
			model.memory["second_time_cup_phase"] = SECOND_TIME_PHASE_HELD
			model.memory["second_time_cup_position"] = "held"
			model.flags["second_time_cup_picked_up"] = true
		SECOND_TIME_PHASE_HELD:
			_play_foley("cup")
			model.memory["second_time_cup_phase"] = SECOND_TIME_PHASE_QUESTION
			model.memory["second_time_cup_position"] = "founder_desk"
			model.flags["second_time_cup_replaced"] = true
			model.flags["second_time_lin_entered"] = true
		SECOND_TIME_PHASE_ANSWERED:
			_play_foley("cup")
			model.memory["second_time_cup_phase"] = SECOND_TIME_PHASE_PLACED
			model.memory["second_time_cup_position"] = "window_second_desk"
			model.flags["second_time_cup_placed"] = true
		SECOND_TIME_PHASE_PLACED:
			_play_foley("page")
			model.flags["second_time_cup_interaction_required"] = false
			model.flags["second_time_cup_interaction_complete"] = true
			_register_seen_ending("second_time")
			current_event.clear()
			if not _queue_week_content():
				_save_game()
			return
		_:
			model.memory["second_time_cup_phase"] = SECOND_TIME_PHASE_PRESENT
			model.memory["second_time_cup_position"] = "founder_desk"
	focused_event_choice = 0
	_sync_focus_for_current_screen()
	_save_game()
	queue_redraw()


func _choose_second_time_option(choice_id: String) -> void:
	if _second_time_phase() != SECOND_TIME_PHASE_QUESTION:
		return
	var resolution: Dictionary = director.resolve_event(current_event, choice_id)
	if not bool(resolution.get("ok", false)):
		_play_foley("blocked")
		_show_toast("这个回答现在无法提交。")
		return
	_play_foley("confirm")
	model.memory["second_time_choice_id"] = choice_id
	model.memory["second_time_cup_phase"] = SECOND_TIME_PHASE_ANSWERED
	model.memory["second_time_cup_position"] = "founder_desk"
	model.flags["second_time_lin_answered"] = true
	current_event = {
		"id": "second_time_placement",
		"title": "第二次",
		"kicker": "2024 年 3 月 · 第 1 周",
		"body": [],
		"choices": [],
		"_ui_interaction": "second_time_cup",
	}
	current_event_page = 0
	focused_event_choice = 0
	_sync_focus_for_current_screen()
	_save_game()
	queue_redraw()


func _event_is_silent(event: Dictionary) -> bool:
	# These beats grow inside ordinary administrative UI. Opening a modal would
	# itself explain that something unusual happened.
	return str(event.get("id", "")) in [
		"preseed_free_2", "preseed_free_3", "investor_repost",
		"seed_debt_3", "seed_debt_4", "seed_debt_5", "hiring_page_traffic",
		"office_expansion", "phantom_employee_appears", "the_accent",
		"meeting_room_d_calendar", "version_disappears", "final_silence"
	]


func _prepare_event(event: Dictionary) -> Dictionary:
	var prepared := event.duplicate(true)
	var variants_value = prepared.get("variants", {})
	if variants_value is Dictionary and not variants_value.is_empty():
		var variant_key := "high_author" if float(model.author_weight) >= 60.0 else "low_author"
		var variant_value = variants_value.get(variant_key, {})
		if variant_value is Dictionary:
			for key in variant_value:
				if str(key) != "condition":
					prepared[key] = variant_value[key]
	if str(prepared.get("id", "")) == "lin_last_visit" and not _has_employee("lin_yue"):
		prepared["kicker"] = "第 4 周 · 空位"
		prepared["body"] = [
			"林越的门禁早已失效。日历仍保留这个十五分钟的空档。",
			"那篇《我们的起源》把『先这样』写成了『我们说』。没有人来确认你是否还记得。",
			"你打开她过去的工位记录。系统回答：未找到在职员工。",
			"你关掉窗口。日历自动把这次一对一标记为已完成。"
		]
		prepared["choices"] = []
		prepared["after"] = "remember:lin_absence"
	var filtered: Array = []
	for choice_value in prepared.get("choices", []):
		if choice_value is Dictionary and _choice_condition_met(str(choice_value.get("condition", ""))):
			filtered.append(choice_value.duplicate(true))
	prepared["choices"] = filtered
	return prepared


func _choice_condition_met(expression: String) -> bool:
	if expression.is_empty():
		return true
	if expression == "lin_present":
		return _has_employee("lin_yue")
	if expression == "capability >= 60":
		return float(model.capability) >= 60.0
	if expression == "capability < 60":
		return float(model.capability) < 60.0
	if expression == "author_weight >= 60":
		return float(model.author_weight) >= 60.0
	if expression == "author_weight < 60":
		return float(model.author_weight) < 60.0
	return true


func _apply_event_choice_effects(event_id: String, effects: Dictionary) -> void:
	var additive := effects.duplicate(true)
	if int(additive.get("narrative_set_to_capability", 0)) != 0:
		model.narrative = float(model.capability)
	additive.erase("narrative_set_to_capability")
	if additive.has("cash_percent"):
		model.cash_weeks = maxf(0.0, float(model.cash_weeks) * (1.0 + float(additive["cash_percent"]) / 100.0))
	additive.erase("cash_percent")
	if additive.has("team_size"):
		var team_delta := int(additive["team_size"])
		if team_delta < 0:
			_remove_employee_count(abs(team_delta), "fixed_event")
		elif team_delta > 0:
			_add_employee_count(team_delta)
	additive.erase("team_size")
	if additive.has("burn_rate"):
		model.salary_burn_modifier = maxf(0.0, float(model.salary_burn_modifier) + float(additive["burn_rate"]) * 0.25)
	additive.erase("burn_rate")
	var belief_delta = additive.get("belief", null)
	var belief_set = additive.get("belief_set", null)
	if event_id.begins_with("lin_scene") or event_id == "lin_last_visit":
		additive.erase("belief")
		additive.erase("belief_set")
		_update_lin_belief(belief_delta, belief_set)
	model.apply_effects(additive)


func _update_lin_belief(delta_value, set_value) -> void:
	for employee in model.employees:
		if str(employee.get("id", "")) != "lin_yue":
			continue
		if set_value != null:
			employee["belief"] = clampf(float(set_value), 0.0, 100.0)
		elif delta_value != null:
			employee["belief"] = clampf(float(employee.get("belief", 50.0)) + float(delta_value), 0.0, 100.0)
		if bool(model.flags.get("lin_belief_locked_15", false)):
			employee["belief"] = minf(15.0, float(employee["belief"]))
		break


func _apply_event_after(event: Dictionary, choice_id: String = "") -> void:
	var directive := str(event.get("after", ""))
	if directive.is_empty():
		return
	model.flags["after_%s" % directive.replace(":", "_").replace(",", "_")] = true
	if directive.begins_with("effects:"):
		var effects: Dictionary = {}
		for assignment in directive.trim_prefix("effects:").split(","):
			var parts := assignment.split("=")
			if parts.size() == 2:
				effects[str(parts[0])] = float(parts[1])
		model.apply_effects(effects)
		return
	if directive.begins_with("remember:"):
		model.memory[directive.trim_prefix("remember:")] = true
		return
	if directive.begins_with("set_flag:"):
		model.flags[directive.trim_prefix("set_flag:")] = true
		return
	if directive.begins_with("set_office:"):
		model.flags["office_%s" % directive.trim_prefix("set_office:")] = true
		return
	if directive.begins_with("unlock:"):
		for action_id in directive.trim_prefix("unlock:").split(","):
			model.flags["unlocked_%s" % action_id] = true
		return
	if directive.begins_with("queue:"):
		model.flags["queued_%s" % directive.trim_prefix("queue:")] = true
		return
	if directive.begins_with("night_shift:"):
		pending_night_id = directive.trim_prefix("night_shift:")
		if pending_night_id == "2" and bool(model.flags.get("lin_will_leave", false)):
			_remove_employee_by_id("lin_yue", "lin_scene_4")
		return
	if directive.begins_with("add_employee:"):
		_add_content_employee(directive.trim_prefix("add_employee:"))
		return
	if directive.begins_with("open_intranet:"):
		model.flags["intranet_%s_available" % directive.trim_prefix("open_intranet:")] = true
		return
	match directive:
		"fundraise_by_narrative":
			var cash_gain := 12.0 if model.narrative >= 75.0 else (8.0 if model.narrative >= 55.0 else (5.0 if model.narrative >= 35.0 else 2.0))
			model.apply_effects({"cash_weeks": cash_gain})
			model.memory["last_financing_narrative"] = model.narrative
		"conditional_debt_event":
			if model.debt >= 30.0:
				model.apply_effects({"narrative": -4.0, "coherence": -2.0})
				model.flags["second_collection_triggered"] = true
		"debt_scaled_reputation_hit", "debt_scaled_event":
			var severity := clampf(floor(float(model.debt) / 15.0), 0.0, 8.0)
			if severity > 0.0:
				model.apply_effects({"narrative": -severity, "coherence": -severity * 0.5})
		"mark_witnesses:demo_edit":
			if choice_id != "run_live":
				model.call("_add_witness_to_all", "demo_fake")
		"employee_intent_to_leave":
			model.flags["employee_intent_to_leave"] = true
		"add_elevator_floor":
			model.flags["extra_elevator_floor"] = true
		"unlock_room_d":
			model.flags["meeting_room_d_available"] = true
		"author_stage:3":
			model.author_weight = maxf(40.0, float(model.author_weight))
		"author_stage:5":
			model.author_weight = maxf(90.0, float(model.author_weight))
		"remove_laid_off_employees":
			model.flags["layoff_execution_complete"] = true
		"resolve_board":
			model.flags["board_resolved"] = true
		"evaluate_ending":
			model.flags["ending_gate_seen"] = true
		"continue_ng_plus":
			model.flags["second_time_opening_seen"] = true


func _has_employee(employee_id: String) -> bool:
	for employee in model.employees:
		if str(employee.get("id", "")) == employee_id:
			return true
	return false


func _has_active_employee(employee_id: String) -> bool:
	for employee in model.employees:
		if str(employee.get("id", "")) == employee_id and bool(employee.get("active", true)):
			return true
	return false


func _remove_employee_by_id(employee_id: String, reason: String) -> void:
	if _has_employee(employee_id):
		model.call("_remove_employee_by_id", employee_id, reason)


func _remove_employee_count(count: int, reason: String) -> void:
	for _index in count:
		var selected_id := ""
		var selected_belief := INF
		for employee in model.employees:
			if str(employee.get("id", "")) == "lin_yue" and model.employees.size() > 1:
				continue
			var employee_belief := float(employee.get("belief", 50.0))
			if employee_belief < selected_belief:
				selected_belief = employee_belief
				selected_id = str(employee.get("id", ""))
		if selected_id.is_empty():
			break
		_remove_employee_by_id(selected_id, reason)


func _add_employee_count(count: int) -> void:
	var existing: Array = []
	for employee in model.employees:
		existing.append(str(employee.get("id", "")))
	var candidates := HiringContent.hireable_employees(int(model.chapter), existing)
	for index in mini(count, candidates.size()):
		_add_content_employee(str(candidates[index].get("id", "")))


func _add_content_employee(employee_id: String) -> void:
	if _has_employee(employee_id) or not HiringContent.EMPLOYEE_TEMPLATES.has(employee_id):
		return
	var source: Dictionary = HiringContent.EMPLOYEE_TEMPLATES[employee_id]
	var skills: Dictionary = source.get("skills", {})
	var strongest := 50.0
	for score in skills.values():
		strongest = maxf(strongest, float(score) * 10.0)
	model.apply_effects({"add_employee": {
		"id": employee_id, "name": str(source.get("name", employee_id)),
		"role": str(source.get("role", "员工")), "skill": strongest,
		"morale": float(source.get("morale", 60.0)), "belief": float(source.get("belief", 60.0))
	}})


func _open_event(event: Dictionary) -> void:
	current_event = director.prepare_event(_current_first_day_event(event))
	if str(current_event.get("id", "")) == "second_time_opening":
		_prepare_second_time_event()
	current_event_page = 0
	event_page_elapsed = 0.0
	event_result_lines.clear()
	_change_screen(Screen.EVENT)


func _is_first_day_prologue() -> bool:
	return str(current_event.get("id", "")) == "garage_opening" and not Array(current_event.get("opening_phases", [])).is_empty()


func _current_first_day_event(event: Dictionary) -> Dictionary:
	if str(event.get("id", "")) != "garage_opening":
		return event.duplicate(true)
	var authored := HiringContent.get_fixed_event(0, 1)
	if authored.is_empty():
		return event.duplicate(true)
	# Director provenance and UI continuation markers belong to the live
	# interaction rather than the authored content and must survive a schema
	# refresh. Losing `_director_key` would leave the opening pending forever.
	for key_value in event.keys():
		var key := str(key_value)
		if key.begins_with("_"):
			authored[key] = event[key_value]
	return authored


func _first_day_phases() -> Array:
	return Array(current_event.get("opening_phases", [])) if _is_first_day_prologue() else []


func _first_day_phase() -> Dictionary:
	var phases := _first_day_phases()
	if phases.is_empty():
		return {}
	var phase_value = phases[clampi(current_event_page, 0, phases.size() - 1)]
	return Dictionary(phase_value) if phase_value is Dictionary else {}


func _first_day_choices() -> Array:
	return Array(_first_day_phase().get("responses", []))


func _first_day_phase_body() -> Array[String]:
	var phase := _first_day_phase()
	var paragraphs: Array[String] = []
	var variant_key := str(phase.get("variant_memory_key", ""))
	if not variant_key.is_empty() and model != null:
		var selected_variant := str(model.memory.get(variant_key, ""))
		var body_variants_value = phase.get("body_variants", {})
		if body_variants_value is Dictionary:
			paragraphs.append_array(_to_string_array(Dictionary(body_variants_value).get(selected_variant, [])))
	paragraphs.append_array(_to_string_array(phase.get("body", [])))
	for index in paragraphs.size():
		paragraphs[index] = paragraphs[index].replace("{{company}}", str(model.company_name) if model != null else "这家公司")
	return paragraphs


func _first_day_reveal_seconds() -> float:
	if reduced_motion:
		return 0.05
	var paragraph_count := maxi(1, _first_day_phase_body().size())
	# Match the staggered paragraph fade: the response arrives only after the last
	# paragraph is fully legible, never while the player is still trying to read it.
	return 0.34 + float(paragraph_count - 1) * 0.24


func _first_day_ready() -> bool:
	return event_page_elapsed + 0.0001 >= _first_day_reveal_seconds()


func _reveal_first_day_phase() -> void:
	event_page_elapsed = _first_day_reveal_seconds()
	queue_redraw()


func _choose_first_day_option(index: int) -> void:
	if not _first_day_ready():
		_reveal_first_day_phase()
		return
	var choices := _first_day_choices()
	if index < 0 or index >= choices.size():
		return
	var choice_value = choices[index]
	if not choice_value is Dictionary:
		return
	var choice := Dictionary(choice_value)
	opening_skip_confirm_pending = false
	var phase := _first_day_phase()
	var memory_key := str(phase.get("memory_key", ""))
	var choice_id := str(choice.get("id", "choice_%d" % index))
	if model != null and not memory_key.is_empty():
		model.memory[memory_key] = choice_id
		var relationship := _lin_relationship_seed()
		if memory_key == "garage_name_choice":
			match choice_id:
				"pragmatic": relationship["trust"] = int(relationship.get("trust", 0)) + 1
				"wry":
					relationship["rapport"] = int(relationship.get("rapport", 0)) + 2
					relationship["chemistry"] = int(relationship.get("chemistry", 0)) + 1
				"warm":
					relationship["warmth"] = int(relationship.get("warmth", 0)) + 2
					relationship["chemistry"] = int(relationship.get("chemistry", 0)) + 2
		if memory_key == "garage_mission_choice":
			model.memory["lin_founder_contract"] = choice_id
			match choice_id:
				"listen":
					relationship["shared_values"] = int(relationship.get("shared_values", 0)) + 2
					relationship["warmth"] = int(relationship.get("warmth", 0)) + 1
				"craft": relationship["trust"] = int(relationship.get("trust", 0)) + 2
				"banter":
					relationship["rapport"] = int(relationship.get("rapport", 0)) + 1
					relationship["chemistry"] = int(relationship.get("chemistry", 0)) + 1
		relationship["last_opening_beat"] = "%s:%s" % [memory_key, choice_id]
		model.memory["lin_relationship"] = relationship
	_play_foley("server_stop" if memory_key == "garage_mission_choice" else "confirm")
	_advance_first_day_prologue(false)


func _advance_first_day_prologue(play_phase_foley: bool = true) -> void:
	if not _is_first_day_prologue():
		return
	if play_phase_foley and not _first_day_ready():
		_reveal_first_day_phase()
		return
	var phase := _first_day_phase()
	opening_skip_confirm_pending = false
	if bool(phase.get("complete", false)):
		_complete_first_day_prologue(false)
		return
	if not _first_day_choices().is_empty() and play_phase_foley:
		return
	if play_phase_foley:
		var foley := str(phase.get("advance_foley", "page"))
		if not foley.is_empty():
			_play_foley(foley)
	var phases := _first_day_phases()
	current_event_page = mini(current_event_page + 1, maxi(0, phases.size() - 1))
	event_page_elapsed = 0.0
	focused_event_choice = 0
	_sync_focus_for_current_screen()
	_save_game()
	queue_redraw()


func _complete_first_day_prologue(skipped: bool) -> void:
	if not _is_first_day_prologue() or model == null:
		return
	if not model.memory.has("garage_name_choice"):
		model.memory["garage_name_choice"] = "skipped" if skipped else "pragmatic"
	if not model.memory.has("garage_mission_choice"):
		model.memory["garage_mission_choice"] = "unspoken" if skipped else "craft"
	model.memory["lin_founder_contract"] = str(model.memory.get("garage_mission_choice", "unspoken" if skipped else "craft"))
	model.memory["lin_relationship"] = _lin_relationship_seed()
	model.memory["first_day_prologue_completed"] = true
	model.flags["first_day_prologue_seen"] = true
	if skipped:
		model.flags["first_day_prologue_skipped"] = true
	else:
		_play_foley("confirm")
	_close_event()


func _request_first_day_skip() -> void:
	if not _is_first_day_prologue():
		return
	if opening_skip_confirm_pending:
		_complete_first_day_prologue(true)
		return
	opening_skip_confirm_pending = true
	_play_foley("blocked")
	_show_toast("再按一次 K / Esc / B，或再次点击，才会跳过这段共同过去。")
	queue_redraw()


func _lin_relationship_seed() -> Dictionary:
	if model == null:
		return {}
	var relationship_value = model.memory.get("lin_relationship", {})
	var relationship := Dictionary(relationship_value).duplicate(true) if relationship_value is Dictionary else {}
	var defaults := {
		"history": "university_exchange_314",
		"status": "cofounders_unspoken_attraction",
		"trust": 1,
		"rapport": 1,
		"warmth": 1,
		"chemistry": 1,
		"shared_values": 1,
		"boundary_awareness": 1,
	}
	for key in defaults:
		if not relationship.has(key):
			relationship[key] = defaults[key]
	model.memory["lin_relationship"] = relationship
	return relationship


func _advance_event_page_or_close() -> void:
	if _is_first_day_prologue():
		_advance_first_day_prologue()
		return
	if not _event_page_can_advance():
		return
	if not _event_page_is_silence():
		_play_foley("page")
	var pages := _event_body_pages()
	if current_event_page + 1 < pages.size():
		current_event_page += 1
		event_page_elapsed = 0.0
		focused_event_choice = 0
		_sync_focus_for_current_screen()
		_save_game()
		return
	_close_event()


func _choose_event_option(index: int) -> void:
	var choices: Array = current_event.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	var choice_id := str(choice.get("id", "choice_%d" % index))
	var finished_event: Dictionary = current_event.duplicate(true)
	var resume_finish_week := bool(finished_event.get("_ui_resume_finish_week", false))
	var event_id := str(finished_event.get("id", ""))
	if event_id == "second_time_opening":
		_choose_second_time_option(choice_id)
		return
	var writer_stage_before: int = model.writer_stage()
	var resolution: Dictionary = director.resolve_event(current_event, choice_id)
	if not bool(resolution.get("ok", false)):
		_play_foley("blocked")
		_show_toast("这个决定现在无法提交。")
		return
	_play_foley("confirm")
	var is_ai := bool(choice.get("ai", false))
	if is_ai and event_id != "board_meeting":
		terminal_lines.append("> %s：我已经替你整理好了。" % _model_private_name())
	result_title = str(choice.get("result_title", current_event.get("title", "结果")))
	result_page = 0
	result_lines = _to_string_array(resolution.get("result", choice.get("result", [])))
	if result_lines.is_empty():
		result_lines.append("事情继续向前。")
	if is_ai:
		_append_stage_one_ai_offer(result_lines, writer_stage_before)
	current_event.clear()
	event_page_elapsed = 0.0
	# Choice effects are applied synchronously by the director. A hiring offer or
	# any other decision that spends the final runway must therefore terminate in
	# this same input frame, before a result/continue screen can be shown.
	if _open_cash_exhaustion_ending_if_needed():
		return
	if event_id == "board_meeting" and choice_id == "delegate":
		# The model does not answer inside a generic result modal. It takes over the
		# room's actual deck: first the screen changes, then the organization chart
		# makes its argument. The phase lives in model memory so a save can resume
		# this interruption without replaying the board choice.
		model.flags["board_presentation_active"] = true
		model.flags.erase("board_presentation_complete")
		model.memory["board_presentation_phase"] = "chart"
		model.memory["board_presentation_animation_complete"] = false
		result_lines.clear()
		result_return = "queue_week_content"
		_change_screen(Screen.BOARD_PRESENTATION)
		_save_game()
		return
	if event_id in ["live_demo", "live_demo_return"] and choice_id == "delegate":
		_start_live_replay(event_id)
		return
	if event_id == "layoff_execution" and choice_id == "delegate":
		_start_layoff_social()
		return
	# A resolved choice can enqueue an interview, one-on-one, debt fulfillment,
	# or the next NG+ beat. Always ask the director before returning to work.
	result_return = "resume_finish_week" if resume_finish_week else "queue_week_content"
	_change_screen(Screen.ACTION_RESULT)
	_save_game()


func _resolve_conditional_choice(choice: Dictionary) -> Dictionary:
	# Fixed content is normalized by _prepare_event(). Keep support for the older
	# dictionary condition schema for saves produced during development.
	if choice.get("condition") is Dictionary:
		var condition: Dictionary = choice["condition"]
		var stat := str(condition.get("stat", "capability"))
		var threshold := float(condition.get("gte", 0.0))
		var raw_value = model.get(stat)
		var value := float(raw_value) if raw_value != null else 0.0
		var branch = choice.get("success", choice) if value >= threshold else choice.get("failure", choice)
		return branch if branch is Dictionary else choice
	return choice


func _close_event() -> void:
	var event_id := str(current_event.get("id", ""))
	var resume_finish_week := bool(current_event.get("_ui_resume_finish_week", false))
	if not event_id.is_empty():
		var resolution: Dictionary = director.resolve_event(current_event, "")
		if not bool(resolution.get("ok", false)):
			_show_toast("这项通知还不能关闭。")
			return
		if event_id == "origin_article_event":
			# The modal only announces the document. The authored scene now happens
			# under the player's hand inside the intranet and cannot be left midway.
			model.flags["origin_article_interaction_required"] = true
			model.flags["origin_article_ui_requested"] = true
		elif event_id == "window_desks":
			# Likewise, the beat stops before the administrative response. Team owns
			# the count check and the player must pull the first curtain themselves.
			model.flags["window_curtain_interaction_required"] = true
			model.flags["window_team_ui_requested"] = true
	current_event.clear()
	event_page_elapsed = 0.0
	if resume_finish_week:
		_finish_week()
		return
	if not _queue_week_content():
		_save_game()


func _open_night_shift(night: Dictionary) -> void:
	current_night = night.duplicate(true)
	pending_night_id = str(current_night.get("_director_night_id", pending_night_id))
	if pending_night_id.is_empty():
		pending_night_id = "1" if str(current_night.get("id", "")).ends_with("1") else "2"
	night_objects.clear()
	night_seen.clear()
	night_pending_object_id = ""
	night_arrival_armed = false
	night_focused_object_index = 0
	result_lines.clear()
	night_interaction = NightInteractionState.new(pending_night_id, current_night)
	var source_value = current_night.get("objects", {})
	var source: Array = source_value.values() if source_value is Dictionary else source_value
	for i in source.size():
		var object: Dictionary = source[i].duplicate(true)
		if night_interaction == null or not night_interaction.object_ids().has(str(object.get("id", ""))):
			continue
		if not object.has("rect"):
			object["rect"] = _night_object_rect(object, i)
		night_objects.append(object)
	command_edit.visible = false
	command_edit.text = ""
	_change_screen(Screen.NIGHT_SHIFT)


func _finish_night_shift() -> void:
	var completed_id := pending_night_id
	if completed_id.is_empty():
		completed_id = "1" if str(current_night.get("id", "")).ends_with("1") else "2"
	var completed_objects: Array = night_interaction.completed_object_ids() if night_interaction != null else night_seen
	var completion: Dictionary = director.complete_night_shift(completed_id, completed_objects, "")
	if not bool(completion.get("ok", false)):
		_play_foley("blocked")
		_show_toast("还不能离开这一层。")
		return
	_play_foley("door")
	current_night.clear()
	night_objects.clear()
	night_seen.clear()
	night_interaction = null
	night_pending_object_id = ""
	night_arrival_armed = false
	command_edit.visible = false
	pending_night_id = ""
	if pending_week_advance:
		_advance_after_week()
	else:
		_change_screen(Screen.DASHBOARD)
		_save_game()


func _submit_terminal_command(command: String) -> void:
	var cleaned := command.strip_edges()
	command_edit.text = ""
	if cleaned.is_empty():
		return
	if night_interaction == null or not night_interaction.terminal_accepts_command():
		return
	_play_foley("terminal")
	terminal_lines.append("> " + cleaned)
	# The bible makes this an exact, deliberate terminal ending. Variants and
	# arguments must behave like ordinary invalid commands.
	if command == "rm -rf" and not current_night.is_empty():
		var completed_id := pending_night_id
		if completed_id.is_empty():
			completed_id = "1" if str(current_night.get("id", "")).ends_with("1") else "2"
		var inspected: Array = night_interaction.completed_object_ids()
		if not inspected.has("terminal"):
			inspected.append("terminal")
		var completion: Dictionary = director.complete_night_shift(completed_id, inspected, cleaned)
		if not bool(completion.get("ok", false)):
			_play_foley("blocked")
			terminal_lines.append("> permission denied")
			return
		_play_foley("server_stop")
		var ending_value = completion.get("ending", {})
		var ending: Dictionary = ending_value if ending_value is Dictionary else {}
		if not ending.is_empty():
			_open_ending(str(ending.get("id", "rm_rf")))
			return
		_open_ending("rm_rf")
		return
	terminal_lines.append("> command not found")
	_save_game()


func _open_ending(ending_id: String) -> void:
	current_ending_id = ending_id
	current_ending = director.ending_for_id(ending_id)
	ending_page = 0
	if current_ending.is_empty():
		current_ending = {"id": ending_id, "name": ending_id, "body": ["%s 的故事暂时停在这里。" % str(model.company_name)]}
	second_run_unlocked = true
	last_ending_id = ending_id
	if not seen_endings.has(ending_id):
		seen_endings.append(ending_id)
	var meta_saved := _save_meta()
	name_edit.visible = false
	command_edit.visible = false
	_change_screen(Screen.ENDING)
	# Keep the completed campaign until the player has actually read every page.
	# Ending identity, rendered body, company state, and page are now resumable.
	var campaign_saved := _save_game()
	if not bool(meta_saved.get("ok", false)) and bool(campaign_saved.get("ok", false)):
		_show_toast("结局档案暂存于战役存档；稍后会重试。")


func _close_signature() -> void:
	_play_foley("page")
	result_lines.clear()
	_change_screen(Screen.DASHBOARD)
	_save_game()


func _return_to_onboarding() -> void:
	current_ending.clear()
	current_ending_id = ""
	ending_page = 0
	name_edit.visible = true
	name_edit.text = "提灯实验室"
	command_edit.visible = false
	_change_screen(Screen.ONBOARDING)


func _advance_ending() -> void:
	_play_foley("page")
	var pages := _ending_pages()
	if ending_page + 1 < pages.size():
		ending_page += 1
		_save_game()
		return
	var meta_saved := _save_meta()
	if not bool(meta_saved.get("ok", false)):
		_save_game()
		_show_toast("档案尚未写入；本次结局已保留，请重试。")
		return
	_clear_completed_campaign_save()
	_return_to_onboarding()


func _clear_completed_campaign_save() -> void:
	for path in [_save_file_path(), _save_file_path() + ".bak", _save_file_path() + ".tmp", _save_file_path() + ".bak.tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _change_screen(next: Screen, record_entry: bool = true) -> bool:
	if screen == Screen.INTRANET and next != Screen.INTRANET and _origin_interaction_required():
		return false
	if screen == Screen.TEAM and next != Screen.TEAM and _window_interaction_required():
		return false
	if screen == Screen.BOARD_PRESENTATION and next != Screen.BOARD_PRESENTATION and model != null and bool(model.flags.get("board_presentation_active", false)):
		return false
	if screen == Screen.LIVE_REPLAY and next != Screen.LIVE_REPLAY and model != null and bool(model.flags.get("live_replay_active", false)):
		return false
	if screen == Screen.LAYOFF_SOCIAL and next != Screen.LAYOFF_SOCIAL and model != null and bool(model.flags.get("layoff_social_active", false)):
		return false
	var previous := screen
	var entry_saved := false
	screen = next
	_normalize_pagination_state()
	screen_time = 0.0
	name_edit.visible = screen == Screen.ONBOARDING
	command_edit.visible = (
		screen == Screen.NIGHT_SHIFT
		and night_interaction != null
		and night_interaction.terminal_accepts_command()
	)
	if screen == Screen.INTRANET and record_entry:
		entry_saved = _mark_selected_document_read()
	elif screen == Screen.TEAM and previous != Screen.TEAM and record_entry and bool(model.flags.get("window_desks", false)):
		model.memory["window_interface_visits"] = int(model.memory.get("window_interface_visits", 0)) + 1
		if bool(model.flags.get("window_curtain_closed", false)) or bool(model.flags.get("window_curtain_pending_reopen", false)):
			model.flags["window_curtain_closed"] = false
			model.flags["window_curtain_pending_reopen"] = false
			model.flags["window_curtain_reopened"] = true
			model.memory["window_curtain_reopen_count"] = int(model.memory.get("window_curtain_reopen_count", 0)) + 1
		model.flags["window_curtain_open"] = true
		entry_saved = bool(_save_game().get("ok", false))
	_sync_focus_for_current_screen()
	queue_redraw()
	return entry_saved


func _normalize_pagination_state() -> void:
	if model == null:
		return
	team_page = clampi(team_page, 0, maxi(0, _team_page_count() - 1))
	announcement_page = clampi(announcement_page, 0, maxi(0, _announcement_page_count() - 1))
	var docs := _intranet_documents()
	if docs.is_empty():
		selected_document = 0
		document_page = 0
		return
	selected_document = clampi(selected_document, 0, docs.size() - 1)
	var pages := _selected_document_pages(docs)
	document_page = clampi(document_page, 0, maxi(0, pages.size() - 1))


func _sync_system_activity() -> void:
	if model == null:
		return
	var week := int(model.total_week)
	if int(model.memory.get("ui_system_activity_week", -1)) == week:
		return
	model.memory["ui_system_activity_week"] = week
	var speaker := _model_private_name() if int(model.chapter) < 4 else _model_official_name()
	var current_kinds: Dictionary = {}
	for entry_value in model.history:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if int(entry.get("total_week", -1)) == week:
			current_kinds[str(entry.get("kind", ""))] = entry.get("payload", {})
	if current_kinds.has("autonomous_admin"):
		terminal_lines.append("> %s：三项行政事项已处理；没有占用你的注意力。" % speaker)
	if current_kinds.has("autonomous_financing"):
		terminal_lines.append("> %s：融资材料已更新，现金安排已同步。" % speaker)
	if current_kinds.has("autonomous_hiring"):
		terminal_lines.append("> %s：候选人已接受，入职流程已创建。" % speaker)
	if current_kinds.has("autonomous_layoffs"):
		terminal_lines.append("> %s：人员调整已完成，相关权限已回收。" % speaker)
	# The never-delegated memory is an authored decision modal. Duplicating its
	# question here would turn the same silence into a throwaway terminal alert.


func _append_week_end_unsolicited_line() -> void:
	if model == null or model.writer_stage() < 2 or bool(model.flags.get("ai_used_this_week", false)):
		return
	# Chapter four week seven is authored as actual silence. No ambient stage-two
	# or stage-five line may leak into its terminal at settlement.
	if int(model.chapter) == 4 and int(model.week_in_chapter) == 7:
		return
	var week := int(model.total_week)
	if int(model.memory.get("ui_unsolicited_week", -1)) == week:
		return
	var speaker := _model_private_name() if int(model.chapter) < 4 else _model_official_name()
	var line := "我整理了一句本周更新。如果需要，我可以再改。"
	if model.writer_stage() >= 3:
		line = "本周的对外与对内表述已经对齐。如需，我可以直接同步。"
	terminal_lines.append("> %s：%s" % [speaker, line])
	model.memory["ui_unsolicited_week"] = week


func _sync_memory_callbacks() -> void:
	if model == null:
		return
	var speaker := _model_private_name() if int(model.chapter) < 4 else _model_official_name()
	if bool(model.flags.get("seen_unsolicited_line", false)) and not bool(model.memory.get("ui_meal_reminder_seen", false)):
		terminal_lines.append("> %s：楼下餐馆七点关门。" % speaker)
		terminal_lines.append("> 你们连续三周没有好好吃饭。如果需要，我可以把本周剩余会议移开。")
		model.memory["ui_meal_reminder_seen"] = true
		model.memory["ui_unsolicited_week"] = int(model.total_week)
	if int(model.memory.get("values_version", 0)) >= 3 and model.writer_stage() >= 3 and not bool(model.memory.get("ui_values_v3_callback_seen", false)):
		terminal_lines.append("> %s：已按第三版价值观统一这份对内材料的措辞。" % speaker)
		model.memory["ui_values_v3_callback_seen"] = true


func _refresh_week_actions() -> void:
	week_action_ids.clear()
	var chapter := int(model.chapter)
	if chapter >= 4:
		week_action_ids = ["sign", "read_intranet", "one_on_one", "do_nothing"]
		selected_action = 0
		return
	var available: Array[String] = []
	var action_ids: Array = HiringContent.ACTIONS.keys()
	for expansion_action_id in HiringExpansionContent.SYSTEM_ACTIONS.keys():
		if not action_ids.has(expansion_action_id):
			action_ids.append(expansion_action_id)
	for action_id in action_ids:
		var action: Dictionary = _action_data(str(action_id))
		var unlocked := int(action.get("unlock_chapter", 0)) <= chapter
		if unlocked and chapter == int(action.get("unlock_chapter", 0)):
			unlocked = int(model.week_in_chapter) >= int(action.get("unlock_week", 1))
		if unlocked and not action_id in ["sign", "read_intranet"]:
			available.append(str(action_id))
	available.sort()
	if chapter == 0:
		for preferred in ["train", "clean_data", "buy_compute", "do_nothing"]:
			if available.has(preferred):
				week_action_ids.append(preferred)
	else:
		var candidates: Array[String] = []
		for action_id in available:
			if action_id != "do_nothing":
				candidates.append(action_id)
		var action_counts: Dictionary = Dictionary(model.memory.get("action_counts", {}))
		var action_offer_counts: Dictionary = Dictionary(model.memory.get("action_offer_counts", {})).duplicate(true)
		var demo_is_featured := chapter == 2 and int(model.week_in_chapter) >= 2 and int(model.week_in_chapter) <= 5 and int(action_counts.get("demo_video", 0)) == 0
		if demo_is_featured and candidates.has("demo_video"):
			week_action_ids.append("demo_video")
			candidates.erase("demo_video")
		var priority_action := _priority_week_action(candidates)
		if not priority_action.is_empty() and week_action_ids.size() < 4:
			week_action_ids.append(priority_action)
			candidates.erase(priority_action)
		# One card from each operating dimension prevents the alphabetical slice
		# from starving recovery actions for most of a chapter.
		var category_order := ["narrative", "capability", "team", "operations", "strategy"]
		var category_offset := int(model.total_week) % category_order.size()
		for category_index in category_order.size():
			if week_action_ids.size() >= 4:
				break
			var category := str(category_order[(category_offset + category_index) % category_order.size()])
			var category_candidates: Array[String] = []
			for action_id in candidates:
				if str(_action_data(action_id).get("category", "operations")) == category:
					category_candidates.append(action_id)
			if category_candidates.is_empty():
				continue
			var pick := _least_offered_action(category_candidates, action_offer_counts, category_index)
			week_action_ids.append(pick)
			candidates.erase(pick)
		var remaining_by_offer := candidates.duplicate()
		remaining_by_offer.sort_custom(func(a: String, b: String) -> bool:
			var a_count := int(action_offer_counts.get(a, 0))
			var b_count := int(action_offer_counts.get(b, 0))
			return a_count < b_count if a_count != b_count else a < b
		)
		for action_id in remaining_by_offer:
			if week_action_ids.size() >= 4:
				break
			week_action_ids.append(action_id)
		week_action_ids.append("do_nothing")
		for offered_action in week_action_ids:
			if offered_action != "do_nothing":
				action_offer_counts[offered_action] = int(action_offer_counts.get(offered_action, 0)) + 1
		model.memory["action_offer_counts"] = action_offer_counts
	selected_action = clampi(selected_action, 0, maxi(0, week_action_ids.size() - 1))


func _least_offered_action(candidates: Array[String], offer_counts: Dictionary, tie_offset: int = 0) -> String:
	if candidates.is_empty():
		return ""
	var minimum := 2147483647
	var least: Array[String] = []
	for action_id in candidates:
		var count := int(offer_counts.get(action_id, 0))
		if count < minimum:
			minimum = count
			least = [action_id]
		elif count == minimum:
			least.append(action_id)
	least.sort()
	return least[(int(model.total_week) + tie_offset) % least.size()]


func _restore_week_actions_from_save(payload: Dictionary) -> bool:
	if model == null or int(payload.get("ui_action_pool_week", -1)) != int(model.total_week):
		return false
	var saved_actions := _to_string_array(payload.get("ui_week_actions", []))
	var expected_size := 4 if int(model.chapter) == 0 or int(model.chapter) >= 4 else 5
	if saved_actions.size() != expected_size:
		return false
	var unique: Dictionary = {}
	for action_id in saved_actions:
		if unique.has(action_id) or (not HiringContent.ACTIONS.has(action_id) and not HiringExpansionContent.SYSTEM_ACTIONS.has(action_id)):
			return false
		unique[action_id] = true
	week_action_ids = saved_actions
	selected_action = clampi(selected_action, 0, week_action_ids.size() - 1)
	return true


func _priority_week_action(candidates: Array[String]) -> String:
	var priorities: Array[String] = []
	if float(model.coherence) < 45.0:
		priorities.append("alignment_week")
	if float(model.cash_weeks) < 6.0:
		priorities.append("contract" if candidates.has("contract") else "fundraising")
	if float(model.compute) < 2.0:
		priorities.append("buy_compute")
	if float(model.morale) < 38.0:
		priorities.append("team_building")
	if float(model.narrative) - float(model.capability) > 24.0:
		priorities.append("eval" if candidates.has("eval") else "train")
	for action_id in priorities:
		if candidates.has(action_id):
			return action_id
	return ""


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), BG)
	match screen:
		Screen.ONBOARDING:
			_draw_onboarding()
		Screen.EVENT:
			_draw_workspace_background()
			_draw_event()
		Screen.ACTION_RESULT:
			_draw_workspace_background()
			_draw_result()
		Screen.NIGHT_SHIFT:
			_draw_night_shift()
		Screen.ENDING:
			_draw_ending()
		Screen.SIGNATURE:
			_draw_workspace_background()
			_draw_signature()
		Screen.BOARD_PRESENTATION:
			_draw_board_presentation()
		Screen.LIVE_REPLAY:
			_draw_live_replay()
		Screen.LAYOFF_SOCIAL:
			_draw_layoff_social()
		_:
			_draw_chrome()
			match screen:
				Screen.DASHBOARD: _draw_dashboard()
				Screen.TEAM: _draw_team()
				Screen.TERMINAL: _draw_terminal()
				Screen.INTRANET: _draw_intranet()
				Screen.CALENDAR: _draw_calendar()
				Screen.ANNOUNCEMENTS: _draw_announcements()
	if screen == Screen.INTRANET and _origin_editor_is_open():
		_draw_origin_editor_overlay()
	_draw_settings_launcher()
	if settings_open:
		_draw_settings_overlay()
	if press_feedback_timer > 0.0:
		_draw_press_feedback()
	if toast_timer > 0.0:
		_draw_toast()


func _draw_onboarding() -> void:
	_draw_art_background(art_dossier_desk, Color(0.96, 0.98, 1.0, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.045, 0.06, 0.08))
	var reveal := _reveal(0.02, 0.62)
	draw_set_transform(Vector2(0, (1.0 - reveal) * 18.0))
	_draw_text("公司设立档案  /  00", Vector2(326, 118), 12, GREEN)
	_draw_display_text("我们正在招人", Vector2(322, 190), 46, INK)
	_draw_text("WE'RE HIRING", Vector2(326, 222), 12, BLUE)
	draw_line(Vector2(326, 246), Vector2(744, 246), COLD_40, 1.0)
	_draw_text("现在。湾区。两个人，一张显卡。", Vector2(326, 290), 18, INK)
	_draw_text("给公司起个名字。它会记住。", Vector2(326, 326), 15, MUTED)
	_draw_text("公司名称 / COMPANY", Vector2(326, 348), 12, MUTED)
	_draw_folio_stamp(Rect2(630, 455, 116, 58), "待签发", GREEN, -0.055)
	draw_set_transform(Vector2.ZERO)
	var button := _onboarding_start_rect()
	var has_save := _save_exists_or_recoverable()
	var start_label := "签发并开始第一周"
	if has_save:
		start_label = "确认覆盖现有档案" if new_game_confirm_pending else "另立一份公司档案"
	var start_shortcut := _gamepad_shortcut("Y" if has_save else "A", "ENTER")
	_draw_ledger_button(button, start_label, start_shortcut, "danger" if new_game_confirm_pending else ("quiet" if has_save else "primary"), true, _focus_is("onboarding", 0))
	if has_save:
		var continue_button := _continue_rect()
		_draw_ledger_button(continue_button, "翻到上次停下的位置", _gamepad_shortcut("A", "ENTER"), "primary", true, _focus_is("onboarding", 1))
	if second_run_unlocked:
		_draw_text("桌上已经有一个不属于现在的马克杯。", Vector2(326, 556), 12, AMBER)
		_draw_text("结局档案  %d / 7" % seen_endings.size(), Vector2(610, 556), TYPE_META, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 136)
	draw_line(Vector2(326, 590), Vector2(746, 590), COLD_30, 1.0)
	_draw_text("成人向职场寓言：裁员、倦怠、饮酒与心理不安。无色情或写实暴力。", Vector2(326, 615), 12, MUTED)
	_draw_text("F11  全屏", Vector2(1018, 663), 12, NIGHT_TEXT)
	draw_set_transform(Vector2.ZERO)


func _draw_chrome() -> void:
	_draw_art_background(art_dossier_desk, Color(0.96, 0.98, 1.0, 1.0))
	# The desk remains atmosphere, never a live text surface. The opaque archive
	# rail also keeps navigation independent of whatever props are baked below it.
	draw_rect(SIDEBAR_SAFE_RECT, SIDEBAR_SURFACE)
	draw_rect(Rect2(264, 0, 8, 720), Color(0.005, 0.025, 0.035, 0.30))
	draw_line(Vector2(271, 0), Vector2(271, 720), COLD_70, 1.0)
	_draw_chrome_reading_surfaces()
	_draw_text("公司档案", Vector2(26, 48), TYPE_META, NIGHT_MUTED)
	_draw_display_text(str(model.company_name), Vector2(24, 86), TYPE_SECTION, COLD_05, HORIZONTAL_ALIGNMENT_LEFT, 218)
	_draw_text("%s  ·  第 %d 周" % [_chapter_label(), int(model.total_week)], Vector2(26, 114), TYPE_META, COLD_30)
	if save_status_timer > 0.0:
		draw_circle(Vector2(215, 108), 3.0, GREEN_BRIGHT if save_status_text == "已自动保存" else RED)
	var nav_names := ["概览", "团队", "经营台账", "日历", "公告栏", "内网"]
	var active_index := 0
	match screen:
		Screen.TEAM: active_index = 1
		Screen.TERMINAL: active_index = 2
		Screen.CALENDAR: active_index = 3
		Screen.ANNOUNCEMENTS: active_index = 4
		Screen.INTRANET: active_index = 5
	for i in nav_names.size():
		var rect := _nav_rect(i)
		var active := i == active_index
		var hovered := rect.has_point(mouse_position)
		if active:
			draw_colored_polygon(PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x - 12, 0), rect.position + Vector2(rect.size.x, 8), rect.end, rect.position + Vector2(0, rect.size.y)]), COLD_10)
			draw_rect(Rect2(rect.position, Vector2(4, rect.size.y)), GREEN)
		elif hovered:
			draw_rect(rect, Color(0.16, 0.31, 0.35, 0.58))
		_draw_text("%02d" % (i + 1), rect.position + Vector2(14, 29), TYPE_META, GREEN if active else COLD_40)
		_draw_text(nav_names[i], rect.position + Vector2(50 + (2 if hovered and not active else 0), 30), TYPE_BODY, INK if active else COLD_20)
	if gamepad_focus_visible:
		_draw_text("LB / RB  翻档", Vector2(26, 486), TYPE_META, NIGHT_MUTED)
	_draw_text("模型登记", Vector2(26, 508), TYPE_META, COLD_40)
	_draw_text(_model_official_name(), Vector2(26, 537), TYPE_BODY, COLD_05)
	if int(model.chapter) < 4:
		_draw_text("团队仍叫它：%s" % _model_private_name(), Vector2(26, 561), TYPE_META, COLD_40)
	_draw_office_debt_indicator(OFFICE_DEBT_RECT)


func _draw_chrome_reading_surfaces() -> void:
	match screen:
		Screen.DASHBOARD:
			_draw_archive_surface(DASHBOARD_MAIN_SURFACE, "main", true)
			_draw_archive_surface(DASHBOARD_TOOLBAR_SURFACE, "toolbar")
			_draw_archive_surface(DASHBOARD_DETAIL_SURFACE, "detail")
			_draw_archive_surface(DASHBOARD_STATS_SURFACE, "footer")
		Screen.TEAM:
			_draw_archive_surface(TEAM_MAIN_SURFACE, "main", true)
			_draw_archive_surface(TEAM_RIGHT_SURFACE, "detail", true)
		Screen.INTRANET, Screen.CALENDAR, Screen.ANNOUNCEMENTS:
			_draw_archive_surface(CONTENT_HEADER_SURFACE, "header", true)


func _draw_archive_surface(rect: Rect2, role: String = "main", taped: bool = false) -> void:
	# Two papers, not five. The earlier build gave every surface its own fill and
	# its own 3px coloured cap, which put four accent bars on one screen and made
	# five papers that differ by one percent. A folio has one registration line —
	# on the sheet you are actually reading — and everything else is just paper.
	var fill := PAPER if role in ["main", "header"] else PAPER_SUNK
	_draw_panel(Rect2(rect.position + Vector2(7, 9), rect.size), Color(0.005, 0.025, 0.035, 0.24), Color.TRANSPARENT, 2.0, 0.0)
	draw_rect(rect, fill)
	draw_rect(rect, RULE_STRONG, false, 1.0)
	if role in ["main", "header"]:
		# An index tab, not a title bar. A full-width bar of accent across every
		# sheet is the loudest thing on a screen that is meant to be quiet.
		draw_rect(Rect2(rect.position, Vector2(72, 3)), GREEN)
	draw_line(rect.position + Vector2(12, rect.size.y - 2), rect.end - Vector2(12, 2), Color(0.20, 0.27, 0.25, 0.10), 1.0)
	if taped:
		# Real tape is translucent: the sheet edge has to keep showing through it.
		var tape_width := 68.0 if role != "detail" else 54.0
		var tape := Rect2(rect.position + Vector2((rect.size.x - tape_width) * 0.5, -5), Vector2(tape_width, 11))
		draw_rect(tape, Color(WARM_10, 0.34))
		draw_line(tape.position, tape.position + Vector2(tape_width, 0), Color(COLD_00, 0.30), 1.0)


func ui_readability_contract() -> Dictionary:
	return {
		"viewport": Rect2(Vector2.ZERO, VIEW),
		"sidebar": SIDEBAR_SAFE_RECT,
		"dashboard": {
			"main": DASHBOARD_MAIN_SURFACE,
			"toolbar": DASHBOARD_TOOLBAR_SURFACE,
			"detail": DASHBOARD_DETAIL_SURFACE,
			"stats": DASHBOARD_STATS_SURFACE,
			"attention": Rect2(818, 137, 128, 24),
			"end_week": _end_week_rect(),
			"action_list": Rect2(316, 232, 440, 300),
			"detail_content": Rect2(790, 186, 332, 390),
			"stats_content": Rect2(310, 596, 812, 58),
		},
		"team": {
			"main": TEAM_MAIN_SURFACE,
			"right": TEAM_RIGHT_SURFACE,
			"table": Rect2(306, 154, 596, 476),
			"org": Rect2(924, 154, 294, 132),
			"signals": Rect2(924, 306, 294, 324),
		},
		"opening": _first_day_visual_contract(),
		"shared": {
			"office_footer": OFFICE_DEBT_RECT,
			"settings_button": _settings_button_rect(),
			"night_hint": NIGHT_HINT_SAFE_RECT,
			"toast_max": TOAST_MAX_SAFE_RECT,
			"content_header": CONTENT_HEADER_SURFACE,
		},
		"colors": {
			"paper": READING_PAPER,
			"ink": INK,
			"muted": MUTED,
			"sidebar": SIDEBAR_SURFACE,
			"sidebar_meta": COLD_40,
			"paper_green": PAPER_GREEN,
			"paper_blue": PAPER_BLUE,
			"paper_amber": PAPER_AMBER,
			"disabled_bg": DISABLED_BG,
			"disabled_text": DISABLED_TEXT,
			"scrim": SCRIM,
		},
	}


func _draw_dashboard() -> void:
	# No English kicker on a paper surface. The sidebar already dates the sheet;
	# what the folio owes the player at the top is the title, the chapter's one
	# question, and the rule of the week — in that order, on three clean lines.
	var content_origin := Vector2(316, 94)
	_draw_display_text("本周待办", content_origin + Vector2(0, 38), TYPE_DISPLAY, INK)
	_draw_text(_chapter_story_prompt(), content_origin + Vector2(2, 66), TYPE_LABEL, PAPER_BLUE)
	var chapter_weeks := int(HiringModel.CHAPTERS[int(model.chapter)].get("weeks", 1))
	var chapter_progress := clampf(float(model.week_in_chapter) / float(maxi(1, chapter_weeks)), 0.0, 1.0)
	var progress_rect := Rect2(content_origin + Vector2(328, 14), Vector2(112, 2))
	draw_rect(progress_rect, COLD_30)
	draw_rect(Rect2(progress_rect.position, Vector2(progress_rect.size.x * chapter_progress, progress_rect.size.y)), GREEN)
	_draw_text("本章 %d / %d" % [int(model.week_in_chapter), chapter_weeks], content_origin + Vector2(328, 38), TYPE_META, MUTED)
	var week_rule := "每周一点注意力。待签的字会自己排好。" if int(model.chapter) >= 4 else "每周三点注意力。当前有 %d 件待处理。" % week_action_ids.size()
	if int(model.chapter) == 0 and int(model.total_week) == 1 and bool(model.flags.get("tutorial_actions_seen", false)):
		week_rule = "林越：四件事，三点注意力。你先挑。"
	_draw_text(week_rule, content_origin + Vector2(0, 100), TYPE_LABEL, MUTED)
	if int(model.memory.get("ui_unsolicited_week", -1)) == int(model.total_week):
		draw_circle(Vector2(683, 170), 3.0, GREEN_BRIGHT)
		_draw_text("模型留下了一条未请求的更新", Vector2(695, 175), TYPE_META, MUTED)
	_draw_attention(Vector2(818, 155))
	# No "处理顺序" header: the list is numbered and the rule above it already
	# says what it is. One redundant label removed is one more line of silence.
	draw_line(Vector2(316, 225), Vector2(756, 225), RULE_STRONG, 1.0)
	for i in week_action_ids.size():
		_draw_action_card(i)
	_draw_week_register()
	_draw_action_detail()
	_draw_stat_cards()


func _week_author_label(action_id: String) -> String:
	return "它" if str(used_action_authors.get(action_id, "self")) == "model" else "你"


func _draw_week_register() -> void:
	# One line at the foot of the folio: how much of this week was yours. It is
	# the only number the game never states out loud anywhere else.
	var by_self := 0
	var by_model := 0
	for action_id in used_action_ids:
		if str(used_action_authors.get(action_id, "self")) == "model":
			by_model += 1
		else:
			by_self += 1
	var pending := maxi(0, week_action_ids.size() - used_action_ids.size())
	var register := "本周登记 · 尚未处理任何一件。" if used_action_ids.is_empty() else "本周登记 · 你 %d · 它 %d · 未处理 %d" % [by_self, by_model, pending]
	draw_line(Vector2(316, 546), Vector2(756, 546), RULE_SOFT, 1.0)
	_draw_text(register, Vector2(316, 566), TYPE_META, MUTED)


func _chapter_story_prompt() -> String:
	return [
		"先做出一个会回答的东西",
		"把承诺换成下一轮现金",
		"当演示开始比现实更顺畅",
		"公司变大以后，谁在替它说话",
		"最后留下的是签名，还是作者",
	][clampi(int(model.chapter), 0, 4)]


func _draw_stat_cards() -> void:
	# A ledger row, not a dashboard. The old version painted each of the five
	# figures a different accent, which spent the whole semantic palette on
	# decoration and left red meaning nothing. Here every figure is ink, and a
	# figure only takes colour when it has crossed into a state the player has to
	# act on. Debt stays absent on purpose: the office is where it shows.
	var runway := _runway_weeks()
	var coherence := int(model.coherence)
	var stats := [
		{"label": "现金跑道", "value": "%d 周" % runway, "color": RED if runway <= 4 else INK},
		{"label": "算力", "value": _format_number(model.compute), "color": INK},
		{"label": "叙事", "value": "%d" % int(model.narrative), "color": INK},
		{"label": "能力", "value": "%d" % int(model.capability), "color": INK},
		{"label": "连贯", "value": "%d" % coherence, "color": RED if coherence < 35 else INK}
	]
	var ledger := Rect2(310, 596, 812, 58)
	draw_line(ledger.position, Vector2(ledger.end.x, ledger.position.y), RULE_STRONG, 1.0)
	draw_line(Vector2(ledger.position.x, ledger.end.y), ledger.end, RULE_SOFT, 1.0)
	for i in stats.size():
		var cell_width := ledger.size.x / float(stats.size())
		var cell := Rect2(ledger.position + Vector2(cell_width * i, 0), Vector2(cell_width, ledger.size.y))
		if i > 0:
			draw_line(cell.position + Vector2(0, 11), cell.position + Vector2(0, cell.size.y - 11), RULE_SOFT, 1.0)
		_draw_text(str(stats[i]["label"]), cell.position + Vector2(12, 21), TYPE_META, MUTED)
		_draw_display_text(str(stats[i]["value"]), cell.position + Vector2(12, 48), TYPE_SECTION, Color(stats[i]["color"]))


func _draw_attention(position: Vector2) -> void:
	_draw_text("注意力", position, TYPE_META, MUTED)
	for i in int(model.attention_max):
		var center := position + Vector2(68 + i * 26, -5)
		var spent := i >= int(model.attention)
		draw_circle(center, 8.0, GREEN if not spent else Color(COLD_30, 0.55))
		if spent:
			draw_arc(center, 8.0, 0.0, TAU, 24, COLD_30, 1.0)


func _draw_action_card(index: int) -> void:
	var rect := _action_card_rect(index)
	var hover_amount := action_hover_amounts[index] if index < action_hover_amounts.size() else 0.0
	var action_id := week_action_ids[index]
	var action := _action_data(action_id)
	var active := selected_action == index
	var used := used_action_ids.has(action_id)
	var available: bool = bool(model.can_act(action_id, false)) or bool(model.can_act(action_id, true))
	var featured := action_id == "demo_video" and int(Dictionary(model.memory.get("action_counts", {})).get("demo_video", 0)) == 0 and int(model.chapter) == 2 and int(model.week_in_chapter) in range(2, 6)
	var hovered := rect.has_point(mouse_position)
	var visual_rect := Rect2(rect.position + Vector2(7 if active else hover_amount * 3.0, 0), rect.size - Vector2(7 if active else 0, 0))
	if active or hovered:
		draw_rect(visual_rect, Color(0.24, 0.52, 0.47, 0.18 if active else 0.09))
	if active:
		draw_rect(Rect2(visual_rect.position, Vector2(3, visual_rect.size.y)), GREEN)
	if _focus_is("dashboard_actions", index):
		_draw_panel(visual_rect.grow(3.0), Color.TRANSPARENT, GREEN_BRIGHT, RADIUS_CONTROL + 2.0, 2.0)
	draw_line(Vector2(visual_rect.position.x, visual_rect.end.y), visual_rect.end, RULE_SOFT, 1.0)
	# A register line, not a chip. Five categories used to mean five hues in a
	# palette that already spends green on "executable" and amber on "human" —
	# so the numeral is just a numeral, and the category stays a word.
	_draw_display_text("%02d" % (index + 1), visual_rect.position + Vector2(14, 33), TYPE_LABEL, GREEN if active else COLD_40)
	_draw_text(str(action.get("name", action_id)), visual_rect.position + Vector2(48, 33), TYPE_ACTION, MUTED if used or not available else INK)
	_draw_text(_category_label(str(action.get("category", "operations"))), visual_rect.position + Vector2(visual_rect.size.x - 76, 32), TYPE_META, MUTED)
	if used:
		# The stamp records the author, not the fact. Delegated rows come out in
		# registration green and read as the tidier ones — which is the point.
		var by_model := str(used_action_authors.get(action_id, "self")) == "model"
		_draw_folio_stamp(Rect2(visual_rect.end.x - 68, visual_rect.position.y + 9, 56, 34), _week_author_label(action_id), PAPER_GREEN if by_model else MUTED, -0.045)
	elif not available:
		var blocked_reason := _action_unavailable_reason(action_id, false)
		_draw_text(blocked_reason, visual_rect.position + Vector2(visual_rect.size.x - 238, 48), TYPE_META, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 222)
	elif featured:
		_draw_text("叙事 +18", visual_rect.position + Vector2(visual_rect.size.x - 88, 49), TYPE_META, AMBER)


func _draw_action_detail() -> void:
	var rect := Rect2(790, 186, 332, 390)
	_draw_text("行动批注", rect.position + Vector2(0, 25), TYPE_META, PAPER_GREEN)
	if int(model.chapter) == 0 and int(model.total_week) == 1 and bool(model.flags.get("tutorial_actions_seen", false)):
		draw_circle(rect.position + Vector2(174, 21), 3.0, GREEN_BRIGHT)
		_draw_text("林越在隔壁 · GPU 正常", rect.position + Vector2(184, 25), TYPE_META, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 148)
	draw_line(rect.position + Vector2(0, 36), rect.position + Vector2(rect.size.x, 36), RULE_STRONG, 1.0)
	if week_action_ids.is_empty():
		return
	var action_id := week_action_ids[selected_action]
	var action := _action_data(action_id)
	_draw_text(_category_label(str(action.get("category", "operations"))), rect.position + Vector2(0, 64), TYPE_META, MUTED)
	_draw_display_text(str(action.get("name", action_id)), rect.position + Vector2(0, 100), TYPE_SECTION, INK)
	_draw_multiline(_action_display_description(action_id, action), Rect2(rect.position + Vector2(0, 118), Vector2(rect.size.x, 86)), TYPE_BODY, MUTED, 26)
	draw_line(rect.position + Vector2(0, 218), rect.position + Vector2(rect.size.x, 218), RULE_SOFT, 1.0)
	_draw_text("执行结果", rect.position + Vector2(0, 238), TYPE_META, MUTED)
	_draw_text("亲自", rect.position + Vector2(0, 264), TYPE_META, MUTED)
	_draw_text(_action_effect_summary(action_id, false), rect.position + Vector2(44, 264), TYPE_META, INK, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 44)
	_draw_text("委托", rect.position + Vector2(0, 288), TYPE_META, MUTED)
	_draw_text(_action_effect_summary(action_id, true), rect.position + Vector2(44, 288), TYPE_META, PAPER_GREEN, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 44)
	var self_button := _action_self_rect()
	var ai_button := _action_ai_rect()
	var used := used_action_ids.has(action_id)
	var can_self: bool = not used and bool(model.can_act(action_id, false))
	var can_ai: bool = not used and bool(model.can_act(action_id, true))
	var self_label := "自己做" if can_self else _compact_action_unavailable_reason(action_id, false)
	_draw_ledger_button(self_button, self_label, _gamepad_shortcut("A", "ENTER") if can_self else "", "primary", can_self)
	var ai_label := "让它来写" if can_ai else _compact_action_unavailable_reason(action_id, true)
	_draw_ledger_button(ai_button, ai_label, _gamepad_shortcut("X", "L") if can_ai else "", "secondary", can_ai)
	var delegation_note := "启动门槛 8 · 委托实际消耗 8" if action_id == "large_train" else "委托不消耗注意力；所有代价都会记入档案。"
	if int(model.chapter) == 0 and int(model.total_week) == 1:
		delegation_note = "亲自做花 1 点注意力；委托不花，但会留下它的措辞。"
	_draw_text(delegation_note, rect.position + Vector2(0, 371), TYPE_META, MUTED)
	var end_button := _end_week_rect()
	_draw_ledger_button(end_button, "确认空过" if end_week_confirm_pending else "结束本周", _gamepad_shortcut("Y", "E"), "danger" if end_week_confirm_pending else "attention")
	if bool(model.flags.get("never_delegated_question", false)):
		_draw_text("LANTERN：你从未让我替你写过。为什么？", rect.position + Vector2(0, 391), TYPE_META, MUTED)


func _draw_team() -> void:
	var area := Rect2(306, 88, 912, 552)
	_draw_display_text("团队", area.position + Vector2(0, 30), TYPE_DISPLAY, INK)
	_draw_text("技能、士气，以及他们还相信多少。", area.position + Vector2(2, 54), TYPE_LABEL, MUTED)
	var total_people := _team_administrative_count()

	# One continuous personnel ledger. Rows belong to the same sheet instead of
	# becoming a stack of SaaS cards, and the sheet stays ruled all the way down:
	# a hiring ledger with empty lines left in it is the title of the game.
	var table := Rect2(306, 154, 596, 476)
	draw_rect(table, COLD_05)
	draw_line(table.position, Vector2(table.end.x, table.position.y), RULE_STRONG, 1.0)
	draw_line(Vector2(table.position.x, table.end.y), table.end, RULE_STRONG, 1.0)
	var headers := ["姓名", "角色", "技能", "士气", "信念", "状态"]
	var widths := [106, 148, 58, 58, 58, 94]
	var numeric_columns := [2, 3, 4]
	var x := table.position.x + 14.0
	for i in headers.size():
		var header_align := HORIZONTAL_ALIGNMENT_RIGHT if i in numeric_columns else HORIZONTAL_ALIGNMENT_LEFT
		_draw_text(headers[i], Vector2(x, table.position.y + 32), TYPE_META, MUTED, header_align, widths[i] - 18)
		x += widths[i]
	draw_line(Vector2(table.position.x + 14, table.position.y + 45), Vector2(table.end.x - 14, table.position.y + 45), RULE_STRONG, 1.0)
	var visible_employees := _team_visible_employees(TEAM_ROWS_PER_PAGE)
	for blank_row in range(visible_employees.size(), TEAM_ROWS_PER_PAGE):
		var blank_y := table.position.y + 76.0 + blank_row * 39.0
		draw_line(Vector2(table.position.x + 14, blank_y + 14), Vector2(table.end.x - 14, blank_y + 14), Color(RULE_SOFT, 0.55), 1.0)
	for row in visible_employees.size():
		var employee: Dictionary = visible_employees[row]
		var profile := _employee_profile(employee)
		var y := table.position.y + 76.0 + row * 39.0
		var status := "在职"
		if int(employee.get("joined_week", -999)) == int(model.total_week):
			status = "本周入职"
		if str(employee.get("id", "")).begins_with("chen_xiaoyu"):
			status = "3 个杯子"
		elif str(employee.get("id", "")) == "shen_yan":
			status = "已提交"
		var values := [
			str(profile.get("name", employee.get("name", "员工"))), str(profile.get("role", employee.get("role", ""))),
			"%d" % int(employee.get("skill", 50)), "%d" % int(employee.get("morale", 60)),
			"%d" % int(employee.get("belief", 60)), status if bool(employee.get("active", true)) else "已离开"
		]
		# A cup is human residue and earns the warm stock. Shen Yan's submitted
		# status stays typographic, so the interface never announces the anomaly
		# more loudly than the fiction does.
		if status == "3 个杯子":
			draw_rect(Rect2(table.position.x + 7, y - 23, table.size.x - 14, 34), Color(HUMAN_PAPER, 0.30))
		x = table.position.x + 14.0
		for col in values.size():
			var value_color := INK if col < 2 else (PAPER_GREEN if col == 5 and status in ["已提交", "本周入职"] else MUTED)
			if col in numeric_columns:
				# Figures line up on their right edge, so a column can be compared
				# without being read.
				_draw_display_text(values[col], Vector2(x, y), TYPE_LABEL, value_color, HORIZONTAL_ALIGNMENT_RIGHT, widths[col] - 18)
			else:
				_draw_text(values[col], Vector2(x, y), TYPE_BODY if col == 0 else TYPE_LABEL, value_color, HORIZONTAL_ALIGNMENT_LEFT, widths[col] - 8)
			x += widths[col]
		draw_line(Vector2(table.position.x + 14, y + 14), Vector2(table.end.x - 14, y + 14), RULE_SOFT, 1.0)
	var page_start := team_page * TEAM_ROWS_PER_PAGE
	var page_end := mini(model.employees.size(), page_start + visible_employees.size())
	_draw_text("显示 %d–%d / %d 位成员 · 创始人未列入" % [page_start + 1 if not visible_employees.is_empty() else 0, page_end, model.employees.size()], table.position + Vector2(14, table.size.y - 15), TYPE_META, MUTED)
	if _team_page_count() > 1:
		_draw_page_button(_team_prev_rect(), "‹", team_page > 0)
		_draw_page_counter(_team_page_counter_rect(), team_page + 1, _team_page_count())
		_draw_page_button(_team_next_rect(), "›", team_page + 1 < _team_page_count())

	# The narrow clipped sheet is evidence, not a second dashboard.
	_draw_text("组织与工位", Vector2(924, 118), TYPE_META, MUTED)
	draw_line(Vector2(924, 130), Vector2(1218, 130), RULE_STRONG, 1.0)
	var org := Rect2(924, 154, 294, 132)
	draw_rect(org, COLD_10)
	draw_line(org.position, Vector2(org.end.x, org.position.y), RULE_STRONG, 1.0)
	draw_line(Vector2(org.position.x, org.end.y), org.end, RULE_STRONG, 1.0)
	draw_line(org.position + Vector2(148, 15), org.position + Vector2(148, 103), RULE_SOFT, 1.0)
	_draw_text("组织架构", org.position + Vector2(12, 28), TYPE_META, MUTED)
	_draw_display_text("%d" % total_people, org.position + Vector2(12, 82), TYPE_DISPLAY, INK)
	_draw_text("在职", org.position + Vector2(76, 80), TYPE_META, MUTED)
	var payroll_people: int = maxi(0, total_people - 1)
	_draw_text("工资表", org.position + Vector2(164, 28), TYPE_META, MUTED)
	_draw_display_text("%d" % payroll_people, org.position + Vector2(164, 82), TYPE_DISPLAY, INK)
	_draw_text("在册", org.position + Vector2(200, 80), TYPE_META, MUTED)
	_draw_text("同步状态  %d / %d" % [total_people, total_people], org.position + Vector2(12, 114), TYPE_META, MUTED)
	if bool(model.flags.get("window_desks", false)):
		if bool(model.flags.get("window_curtain_closed", false)):
			_draw_closed_window(Rect2(924, 306, 294, 324))
		else:
			_draw_window_desks(Rect2(924, 306, 294, 324))
	else:
		_draw_team_signals(Rect2(924, 306, 294, 324))
	_draw_back_button()


func _team_visible_employees(limit: int) -> Array:
	var ledger: Array = model.employees.duplicate()
	# Keep the submitted phantom row discoverable on the first page without
	# deleting the real employee that previously occupied the ninth slot.
	for employee_value in ledger.duplicate():
		if str(Dictionary(employee_value).get("id", "")) == "shen_yan":
			ledger.erase(employee_value)
			ledger.push_front(employee_value)
			break
	var start := clampi(team_page * limit, 0, ledger.size())
	return ledger.slice(start, mini(ledger.size(), start + limit))


func _team_page_count() -> int:
	return maxi(1, int(ceil(float(model.employees.size()) / float(TEAM_ROWS_PER_PAGE)))) if model != null else 1


func _draw_team_signals(rect: Rect2) -> void:
	var evidence := Rect2(rect.position, Vector2(rect.size.x, 154))
	var evidence_texture: Texture2D = art_title if model.employees.size() <= 3 else art_office_day
	_draw_texture_cover(evidence_texture, evidence, Color(0.78, 0.84, 0.84, 1.0), Vector2(0.58, 0.58))
	draw_rect(evidence, Color(0.01, 0.045, 0.06, 0.46))
	draw_rect(evidence, COLD_50, false, 1.0)
	_draw_text("工位证据 · 创始办公室", evidence.position + Vector2(16, 26), TYPE_META, COLD_20)
	_draw_display_text("%d 个登记工位" % _team_administrative_count(), evidence.position + Vector2(16, 60), TYPE_SECTION, COLD_05)
	if _team_desk_signal() == "chen_three_cups":
		for i in 3:
			_draw_cup_icon(evidence.position + Vector2(174 + i * 38, 91), 0.45, COLD_10, WARM_70)
		_draw_text("陈小雨的桌面 · 三个杯子", evidence.position + Vector2(16, 137), TYPE_META, WARM_20)
	else:
		_draw_text("个人桌面 · 当前没有可展示的桌面信号", evidence.position + Vector2(16, 137), TYPE_META, COLD_30)
	# Three ruled figures, not three progress bars. Meters in a game about a
	# company measuring its people are exactly the borrowed vocabulary the art
	# direction rules out, and they spent three accents on decoration.
	_draw_text("团队信号", rect.position + Vector2(0, 186), TYPE_META, MUTED)
	draw_line(rect.position + Vector2(0, 195), rect.position + Vector2(rect.size.x, 195), RULE_STRONG, 1.0)
	# Capability is a reading, not an alarm: 12 in week one is simply where you
	# start. Only the two figures that can actually collapse take consequence red.
	var signals := [
		{"label": "平均士气", "value": int(model.morale), "alarm": true},
		{"label": "能力密度", "value": int(model.capability), "alarm": false},
		{"label": "叙事一致", "value": int(model.coherence), "alarm": true}
	]
	for i in signals.size():
		var y := rect.position.y + 227.0 + i * 38.0
		var value := int(signals[i]["value"])
		var alarmed: bool = bool(signals[i]["alarm"]) and value < 35
		_draw_text(str(signals[i]["label"]), Vector2(rect.position.x, y), TYPE_LABEL, MUTED)
		_draw_display_text("%d" % value, Vector2(rect.position.x, y), TYPE_SECTION, RED if alarmed else INK, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x)
		draw_line(Vector2(rect.position.x, y + 14), Vector2(rect.end.x, y + 14), Color(RULE_SOFT, 0.7), 1.0)


func _draw_window_desks(rect: Rect2) -> void:
	_draw_texture_cover(art_office_night, rect, Color(0.58, 0.67, 0.69, 1.0), Vector2(0.64, 0.55))
	draw_rect(rect, Color(0.01, 0.04, 0.055, 0.48))
	draw_rect(rect, Color("#526169"), false, 1.0)
	# The anomaly is intentionally unlabelled. Only the quiet curtain control
	# acknowledges that this panel is a window rather than a dashboard widget.
	draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(34, rect.size.y - 2)), Color(0.10, 0.15, 0.16, 0.88))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(1, 1), rect.position + Vector2(61, 1),
		rect.position + Vector2(35, rect.size.y - 1), rect.position + Vector2(1, rect.size.y - 1)
	]), Color(0.14, 0.19, 0.19, 0.82))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(rect.size.x - 1, 1), rect.position + Vector2(rect.size.x - 61, 1),
		rect.position + Vector2(rect.size.x - 35, rect.size.y - 1), rect.position + Vector2(rect.size.x - 1, rect.size.y - 1)
	]), Color(0.14, 0.19, 0.19, 0.82))
	for pane in range(1, 3):
		draw_line(rect.position + Vector2(rect.size.x * float(pane) / 3.0, 1), rect.position + Vector2(rect.size.x * float(pane) / 3.0, rect.size.y - 1), Color(0.55, 0.68, 0.72, 0.13), 1.0)
	var synchronized_phase := sin(_motion_clock() * 5.4) * 2.0
	var exterior_count := _window_exterior_person_count()
	for i in exterior_count:
		var x := rect.position.x + 58.0 + i * 59.0
		var y := rect.position.y + 172.0 + (i % 2) * 13.0
		draw_rect(Rect2(x - 22, y + 44, 56, 4), Color(0.55, 0.65, 0.64, 0.72))
		_draw_panel(Rect2(x - 13, y, 39, 29), Color(0.04, 0.09, 0.11, 0.92), Color("#60777c"), 2.0, 1.0)
		draw_rect(Rect2(x - 9, y + 4, 31, 20), Color(Color("#79a7b0"), 0.44 + sin(_motion_clock() * 1.7 + i) * 0.05))
		draw_line(Vector2(x + 7, y + 27), Vector2(x + 7, y + 42), Color("#596761"), 2.0)
		draw_arc(Vector2(x + 7, y + 75), 17.0, PI, TAU, 18, Color(0.03, 0.07, 0.08, 0.86), 7.0, true)
		draw_line(Vector2(x - 2, y + 85), Vector2(x - 9, y + 96 + synchronized_phase), Color(0.18, 0.25, 0.25, 0.82), 2.0)
		draw_line(Vector2(x + 16, y + 85), Vector2(x + 23, y + 96 + synchronized_phase), Color(0.18, 0.25, 0.25, 0.82), 2.0)
	var curtain_button := _window_curtain_button_rect()
	_draw_ledger_button(curtain_button, "拉上窗帘", _gamepad_shortcut("A", "E"), "night")


func _draw_closed_window(rect: Rect2) -> void:
	draw_rect(rect, Color("#202825"))
	draw_rect(rect, Color("#4b5650"), false, 1.0)
	for fold in 8:
		var x := rect.position.x + float(fold) * rect.size.x / 8.0
		var next_x := rect.position.x + float(fold + 1) * rect.size.x / 8.0
		var shade := Color("#313b37") if fold % 2 == 0 else Color("#27312e")
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, rect.position.y + 1), Vector2(next_x, rect.position.y + 1),
			Vector2(next_x - 7, rect.end.y - 1), Vector2(x + 7, rect.end.y - 1)
		]), shade)
	draw_line(rect.position + Vector2(1, 19), rect.position + Vector2(rect.size.x - 1, 19), Color("#64716a"), 2.0)


func _draw_origin_editor_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.02, 0.045, 0.05, 0.66))
	var modal := Rect2(322, 104, 708, 504)
	var left_page := Rect2(modal.position, Vector2(338, modal.size.y))
	var right_page := Rect2(modal.position + Vector2(354, 0), Vector2(354, modal.size.y))
	draw_rect(Rect2(modal.position + Vector2(9, 11), modal.size), Color(0.0, 0.02, 0.025, 0.30))
	draw_rect(left_page, Color(0.90, 0.925, 0.91, 0.99))
	draw_rect(right_page, Color(0.95, 0.925, 0.85, 0.99))
	draw_rect(left_page, COLD_40, false, 1.0)
	draw_rect(right_page, WARM_40, false, 1.0)
	draw_rect(Rect2(modal.position + Vector2(338, 0), Vector2(16, modal.size.y)), COLD_70)
	draw_line(modal.position + Vector2(346, 8), modal.position + Vector2(346, modal.size.y - 8), COLD_50, 1.0)
	draw_rect(Rect2(modal.position + Vector2(310, -5), Vector2(88, 12)), COLD_30)
	_draw_text("校改卷宗 / 我们的起源", left_page.position + Vector2(26, 35), 12, GREEN)
	_draw_display_text("第三遍。", left_page.position + Vector2(26, 83), 25, INK)
	_draw_multiline("你终于认出：『先这样』是林越说的。文章里写的是『我们说』。\n你想去改。光标一直闪。", Rect2(left_page.position + Vector2(26, 101), Vector2(286, 86)), 14, MUTED, 23)
	draw_line(left_page.position + Vector2(26, 206), left_page.position + Vector2(left_page.size.x - 26, 206), COLD_40, 1.0)
	_draw_text("原文摘录", left_page.position + Vector2(26, 235), TYPE_META, MUTED)
	_draw_text("那天，我们说：『先这样。』", left_page.position + Vector2(26, 278), 15, INK)
	_draw_text("后来，这三个字成了某种精神……", left_page.position + Vector2(26, 318), 14, MUTED)
	var phrase_x := left_page.position.x + 26.0 + font.get_string_size("那天，", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var phrase_width := font.get_string_size("我们说", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_line(Vector2(phrase_x, left_page.position.y + 270), Vector2(phrase_x + phrase_width, left_page.position.y + 270), Color(AMBER, 0.72), 1.6)
	_draw_text("林越说？", left_page.position + Vector2(218, 361), 12, AMBER.darkened(0.10))
	draw_line(left_page.position + Vector2(208, 348), left_page.position + Vector2(244, 329), Color(AMBER, 0.52), 1.0)
	_draw_text("未保存的修改  0", right_page.position + Vector2(180, 35), TYPE_META, GREEN, HORIZONTAL_ALIGNMENT_RIGHT, 146)
	_draw_text("我们的起源.md", right_page.position + Vector2(28, 80), TYPE_META, MUTED)
	draw_line(right_page.position + Vector2(28, 94), right_page.position + Vector2(right_page.size.x - 28, 94), WARM_40, 1.0)
	_draw_text("待校改句", right_page.position + Vector2(28, 125), TYPE_META, MUTED)
	_draw_text("那天，我们说：『先这样。』", right_page.position + Vector2(28, 166), 15, INK)
	_draw_text("后来，这三个字成了某种精神……", right_page.position + Vector2(28, 207), 14, MUTED)
	if reduced_motion or fmod(_motion_clock(), 1.0) < 0.56:
		var cursor_x := right_page.position.x + 28.0 + font.get_string_size("那天，我们说：『先这样。』", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 2.0
		draw_rect(Rect2(cursor_x, right_page.position.y + 150, 2, 20), GREEN)
	draw_line(right_page.position + Vector2(28, 232), right_page.position + Vector2(right_page.size.x - 28, 232), WARM_40, 1.0)
	_draw_multiline("改成『林越说』？她已经不在这里了。新人会去查她是谁，然后什么也查不到。", Rect2(right_page.position + Vector2(28, 263), Vector2(298, 82)), 12, MUTED, 21)
	_draw_folio_stamp(Rect2(right_page.position + Vector2(188, 344), Vector2(128, 46)), "未提交", AMBER, -0.025)
	var close_button := _origin_editor_close_rect()
	draw_rect(close_button, SURFACE_DARK)
	draw_rect(close_button, GREEN, false, 1.0)
	draw_line(close_button.position, Vector2(close_button.end.x, close_button.position.y), GREEN_BRIGHT, 2.0)
	_draw_text_centered("不作修改，关闭   %s" % _gamepad_shortcut("A", "ESC"), close_button, 13, Color.WHITE, 3.0)


func _draw_board_presentation() -> void:
	_draw_art_background(art_boardroom, Color(0.58, 0.66, 0.70, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.04, 0.055, 0.67))
	var screen_rect := Rect2(142, 54, 996, 556)
	draw_rect(Rect2(screen_rect.position + Vector2(16, 18), screen_rect.size), Color(0.0, 0.0, 0.0, 0.34))
	draw_rect(screen_rect, COLD_00)
	draw_rect(screen_rect, COLD_50, false, 1.0)
	draw_rect(Rect2(screen_rect.position + Vector2(-10, -6), Vector2(screen_rect.size.x + 20, 7)), COLD_50)
	var phase := str(model.memory.get("board_presentation_phase", "chart"))
	if phase == "aftermath":
		_draw_board_aftermath(screen_rect)
	else:
		var progress := _board_transition_progress()
		# Keep every draw inside the physical screen. A bright vertical refresh
		# seam crosses the quarterly page; halfway through, the deck has actually
		# changed and the organization nodes resolve one by one behind it.
		_draw_board_metric_slide(screen_rect)
		if progress >= 0.48:
			_draw_board_org_slide(screen_rect, clampf((progress - 0.48) / 0.52, 0.0, 1.0))
		var seam_x := screen_rect.position.x + progress * screen_rect.size.x
		draw_rect(Rect2(seam_x - 8.0, screen_rect.position.y + 1.0, 16.0, screen_rect.size.y - 2.0), Color(0.78, 0.88, 0.82, 0.20 * (1.0 - progress)))

	var continue_button := _board_continue_rect()
	draw_rect(continue_button, INK)
	draw_rect(continue_button, GREEN_BRIGHT, false, 1.0)
	draw_line(continue_button.position, Vector2(continue_button.end.x, continue_button.position.y), GREEN_BRIGHT, 2.0)
	var continue_label := "跳过换页动画   ENTER" if phase == "chart" and _board_transition_progress() < 1.0 else ("继续会议记录   ENTER" if phase == "chart" else "会议结束   ENTER")
	continue_label = continue_label.replace("ENTER", _gamepad_shortcut("A", "ENTER"))
	_draw_text_centered(continue_label, continue_button, 12, COLD_10, 3.0)
	_draw_text("LANTERN / BOARD DECK", Vector2(142, 32), 10, COLD_50)
	_draw_text("你还没开口，屏幕换页了。" if phase == "chart" else "会议记录继续生成。", Vector2(152, 647), 11, COLD_30)
	_draw_text("投影端已接管换页", Vector2(152, 674), 10, COLD_50)


func _draw_board_metric_slide(rect: Rect2) -> void:
	draw_rect(rect, COLD_00)
	_draw_text("QUARTERLY OPERATING REVIEW", rect.position + Vector2(54, 45), 11, GREEN)
	_draw_display_text("增长很漂亮。", rect.position + Vector2(54, 94), 31, INK)
	_draw_text("团队怎么样？", rect.position + Vector2(54, 125), 14, MUTED)
	var colors := [GREEN, BLUE, AMBER]
	var labels := ["增长", "留存", "响应"]
	var metric_band := Rect2(rect.position + Vector2(54, 164), Vector2(858, 126))
	draw_rect(metric_band, COLD_05)
	draw_line(metric_band.position, Vector2(metric_band.end.x, metric_band.position.y), COLD_40, 1.0)
	draw_line(Vector2(metric_band.position.x, metric_band.end.y), metric_band.end, COLD_30, 1.0)
	for card in 3:
		var card_rect := Rect2(rect.position + Vector2(54 + card * 286, 164), Vector2(252, 126))
		if card > 0:
			draw_line(Vector2(card_rect.position.x - 17, card_rect.position.y + 12), Vector2(card_rect.position.x - 17, card_rect.end.y - 12), COLD_30, 1.0)
		_draw_text(labels[card], card_rect.position + Vector2(18, 27), 10, MUTED)
		_draw_display_text(["+42%", "91%", "0.8s"][card], card_rect.position + Vector2(18, 71), 27, colors[card])
		for point in 7:
			var x := card_rect.position.x + 18.0 + point * 30.0
			var y := card_rect.position.y + 104.0 - float((point * (card + 2) * 7) % 37)
			draw_circle(Vector2(x, y), 2.5, colors[card])
			if point > 0:
				var previous_x := card_rect.position.x + 18.0 + (point - 1) * 30.0
				var previous_y := card_rect.position.y + 104.0 - float(((point - 1) * (card + 2) * 7) % 37)
				draw_line(Vector2(previous_x, previous_y), Vector2(x, y), colors[card], 1.6, true)
	var context_strip := Rect2(rect.position + Vector2(54, 324), Vector2(rect.size.x - 108, 140))
	_draw_texture_cover(art_boardroom, context_strip, Color(0.70, 0.76, 0.77, 1.0), Vector2(0.50, 0.70))
	draw_rect(context_strip, Color(0.015, 0.055, 0.07, 0.56))
	draw_rect(Rect2(context_strip.position, Vector2(5, context_strip.size.y)), GREEN_BRIGHT)
	_draw_text("OPERATING CONTEXT / BOARD ROOM B", context_strip.position + Vector2(22, 28), 10, COLD_20)
	_draw_text("漂亮的数字坐在没有人的椅子前面。", context_strip.position + Vector2(22, context_strip.size.y - 24), 13, COLD_05)
	_draw_text("数据与配色由 LANTERN 准备 · 配色已保存为手机壁纸", rect.position + Vector2(54, 510), 11, MUTED)


func _draw_board_org_slide(rect: Rect2, reveal: float = 1.0) -> void:
	draw_rect(rect, COLD_00)
	_draw_text("QUARTERLY OPERATING REVIEW  /  组织", rect.position + Vector2(48, 42), 11, GREEN)
	_draw_display_text("组织架构", rect.position + Vector2(48, 83), 27, INK)
	_draw_text("本季度人员流动", rect.position + Vector2(780, 77), 11, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 150)
	var total_boxes := BOARD_ORG_ACTIVE_COUNT + BOARD_ORG_EXIT_COUNT
	for index in total_boxes:
		var row := index / 7
		var column := index % 7
		var node_reveal := clampf((reveal - float(index) * 0.009) / 0.65, 0.0, 1.0)
		var node := Rect2(rect.position + Vector2(56 + column * 126, 118 + row * 49), Vector2(104, 30))
		var active := index < BOARD_ORG_ACTIVE_COUNT
		var fill := COLD_10 if active else WARM_05
		var edge := GREEN if active else RED
		fill.a = node_reveal
		edge.a = node_reveal
		if row > 0:
			var anchor := Vector2(node.get_center().x, node.position.y - 8)
			draw_line(anchor, Vector2(anchor.x, node.position.y), Color(0.55, 0.60, 0.57, 0.32 * node_reveal), 1.0)
		draw_rect(node, fill)
		draw_rect(node, edge, false, 1.0)
		_draw_text("在职" if active else "离开", node.position + Vector2(12, 20), 9, Color(edge, node_reveal))
	var statement := Rect2(rect.position + Vector2(48, 430), Vector2(900, 76))
	draw_rect(statement, COLD_05)
	draw_line(statement.position, Vector2(statement.end.x, statement.position.y), COLD_30, 1.0)
	draw_line(Vector2(statement.position.x, statement.end.y), statement.end, COLD_20, 1.0)
	_draw_display_text("自然流失率 11%", statement.position + Vector2(22, 36), 23, GREEN)
	_draw_text("低于行业中位数。", statement.position + Vector2(266, 35), 14, INK)
	_draw_text("绿色框 %d  ·  红色框 %d" % [BOARD_ORG_ACTIVE_COUNT, BOARD_ORG_EXIT_COUNT], statement.position + Vector2(696, 34), 10, MUTED)


func _draw_board_aftermath(rect: Rect2) -> void:
	_draw_board_org_slide(rect, 1.0)
	draw_rect(Rect2(rect.position, rect.size), Color(0.03, 0.045, 0.038, 0.78))
	var record := Rect2(rect.position + Vector2(118, 90), Vector2(760, 374))
	draw_rect(Rect2(record.position + Vector2(8, 9), record.size), Color(0.0, 0.02, 0.025, 0.22))
	draw_rect(record, COLD_05)
	draw_rect(record, COLD_40, false, 1.0)
	draw_rect(Rect2(record.position, Vector2(6, record.size.y)), GREEN)
	draw_rect(Rect2(record.position + Vector2(330, -5), Vector2(86, 12)), COLD_40)
	_draw_text("MEETING RECORD  /  自动生成", record.position + Vector2(34, 38), 10, GREEN)
	_draw_display_text("董事会继续到了下一页。", record.position + Vector2(34, 84), 25, INK)
	draw_line(record.position + Vector2(34, 98), record.position + Vector2(record.size.x - 34, 98), COLD_30, 1.0)
	_draw_paragraph_array(_board_presentation_copy(), Rect2(record.position + Vector2(34, 112), Vector2(record.size.x - 68, 216)), 15, INK, 27)


func _board_transition_progress() -> float:
	if reduced_motion:
		return 1.0
	if model != null and bool(model.memory.get("board_presentation_animation_complete", false)):
		return 1.0
	return _ease_out_cubic(clampf(screen_time / BOARD_TRANSITION_SECONDS, 0.0, 1.0))


func _board_presentation_copy() -> Array[String]:
	return [
		"投资人 A 点点头，看向下一页。",
		"没有人注意到你没有说话。",
		"你也没有注意到，直到会议结束二十分钟后。",
	]


func _advance_board_presentation() -> void:
	if model == null or not bool(model.flags.get("board_presentation_active", false)):
		return
	_play_foley("projector")
	var phase := str(model.memory.get("board_presentation_phase", "chart"))
	if phase == "chart":
		if not bool(model.memory.get("board_presentation_animation_complete", false)) and screen_time < BOARD_TRANSITION_SECONDS:
			model.memory["board_presentation_animation_complete"] = true
			screen_time = BOARD_TRANSITION_SECONDS
			_save_game()
			queue_redraw()
			return
		model.memory["board_presentation_animation_complete"] = true
		model.memory["board_presentation_phase"] = "aftermath"
		screen_time = 0.0
		_save_game()
		queue_redraw()
		return
	model.flags["board_presentation_active"] = false
	model.flags["board_presentation_complete"] = true
	model.memory["board_presentation_phase"] = "complete"
	model.memory["board_presentation_completion_count"] = 1
	result_return = "dashboard"
	if not _queue_week_content():
		_save_game()


func _start_live_replay(source_event_id: String = "live_demo") -> void:
	model.flags["live_replay_active"] = true
	model.flags.erase("live_replay_complete")
	model.memory["live_replay_phase"] = "client_signed"
	model.memory["live_replay_source_event_id"] = source_event_id
	model.memory["live_replay_result_copy"] = result_lines.duplicate()
	model.memory["live_replay_transitions"] = ["client_signed"]
	result_lines.clear()
	result_page = 0
	result_return = "queue_week_content"
	_change_screen(Screen.LIVE_REPLAY)
	_save_game()


func _live_replay_phase() -> String:
	return str(model.memory.get("live_replay_phase", "client_signed")) if model != null else "client_signed"


func _live_replay_min_phase_seconds(phase: String = "") -> float:
	if reduced_motion:
		return 0.0
	var active_phase := _live_replay_phase() if phase.is_empty() else phase
	match active_phase:
		"playback", "replay":
			return LIVE_REPLAY_MIN_PLAY_SECONDS
		"we_pause":
			return LIVE_REPLAY_MIN_PAUSE_SECONDS
		"client_signed", "aftermath":
			return LIVE_REPLAY_MIN_STATIC_SECONDS
	return 0.0


func _live_replay_can_advance() -> bool:
	return screen_time >= _live_replay_min_phase_seconds()


func _advance_live_replay() -> void:
	if model == null or not bool(model.flags.get("live_replay_active", false)):
		return
	if not _live_replay_can_advance():
		return
	_play_foley("projector")
	var phase := _live_replay_phase()
	var next_phase: String = str({
		"client_signed": "playback",
		"playback": "we_pause",
		"we_pause": "replay",
		"replay": "aftermath",
	}.get(phase, "complete"))
	var transitions: Array = Array(model.memory.get("live_replay_transitions", [])).duplicate()
	transitions.append(next_phase)
	model.memory["live_replay_transitions"] = transitions
	if next_phase == "complete":
		model.flags["live_replay_active"] = false
		model.flags["live_replay_complete"] = true
		model.memory["live_replay_phase"] = "complete"
		result_return = "dashboard"
		if not _queue_week_content():
			_save_game()
		return
	model.memory["live_replay_phase"] = next_phase
	screen_time = 0.0
	_save_game()
	queue_redraw()


func _draw_live_replay() -> void:
	_draw_art_background(art_boardroom, Color(0.44, 0.52, 0.56, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.04, 0.052, 0.84))
	_draw_text("会议录像 / 19:42 / 会议室 B", Vector2(44, 48), 12, COLD_30)
	_draw_text("本地回放", Vector2(1100, 48), 12, COLD_40, HORIZONTAL_ALIGNMENT_RIGHT, 130)
	var frame := Rect2(64, 82, 820, 522)
	_draw_panel(frame, INK, MUTED, 7.0, 1.0)
	var phase := _live_replay_phase()
	if phase == "client_signed":
		_draw_live_replay_signed(frame)
	else:
		_draw_live_replay_video(frame, phase)
	var notes := Rect2(914, 82, 302, 522)
	_draw_panel(notes, COLD_05, COLD_30, 7.0, 1.0)
	_draw_text("回放记录", notes.position + Vector2(22, 32), 11, MUTED)
	var copy: Array[String]
	match phase:
		"client_signed": copy = _live_replay_client_signed_copy()
		"playback": copy = ["口型对得上。", "是你的声音。", "是你的手在比划。"]
		"we_pause": copy = ["只是那个逻辑不是你想出来的。", "那个停顿也不是你的停顿。", "你从来不在『我们』后面停顿。"]
		"replay": copy = ["你把进度条拖回去。", "这次只看字幕和自己的手。", "口型仍然对得上。"]
		_: copy = ["你又看了一遍。", "讲得真的很好。"]
	_draw_paragraph_array(copy, Rect2(notes.position + Vector2(22, 58), Vector2(notes.size.x - 44, 322)), 14, INK, 25)
	if _live_replay_can_advance():
		var button := _live_replay_continue_rect()
		_draw_panel(button, SURFACE_DARK, GREEN, 7.0, 1.0)
		var label := "打开会议录像   ENTER" if phase == "client_signed" else ("拖回去再看一遍   ENTER" if phase == "we_pause" else ("关闭回放   ENTER" if phase == "aftermath" else ("看完   ENTER" if phase == "replay" else "停在这里   ENTER")))
		label = label.replace("ENTER", _gamepad_shortcut("A", "ENTER"))
		_draw_text_centered(label, button, 12, Color.WHITE, 3.0)
	else:
		var hold_label := "播放中" if phase in ["playback", "replay"] else ("停在这里" if phase == "we_pause" else "请稍候")
		var hold_button := _live_replay_continue_rect()
		_draw_panel(hold_button, COLD_10, COLD_30, 7.0, 1.0)
		_draw_text_centered(hold_label, hold_button, 11, COLD_50, 3.0)


func _draw_live_replay_signed(frame: Rect2) -> void:
	var file_card := Rect2(frame.position + Vector2(118, 94), Vector2(584, 302))
	_draw_paper_card(file_card, Color(0.94, 0.96, 0.945, 0.98), COLD_40, 8.0, 5.0)
	var thumbnail := Rect2(file_card.position + Vector2(26, 28), Vector2(156, 112))
	_draw_texture_cover(art_meeting_replay, thumbnail, Color(0.68, 0.75, 0.76, 1.0), Vector2(0.48, 0.48))
	draw_rect(thumbnail, Color(0.01, 0.04, 0.05, 0.40))
	draw_colored_polygon(PackedVector2Array([file_card.position + Vector2(86, 58), file_card.position + Vector2(86, 112), file_card.position + Vector2(132, 85)]), GREEN_BRIGHT)
	_draw_display_text("meeting_B_1942.mp4", file_card.position + Vector2(214, 70), 20, INK)
	_draw_text("48:11 · 内部录像 · 自动归档", file_card.position + Vector2(214, 104), 11, MUTED)
	var transition_copy := _live_replay_file_transition_copy()
	for i in transition_copy.size():
		_draw_text(transition_copy[i], file_card.position + Vector2(26, 204 + i * 28), 13 if i > 0 else 14, INK if i + 1 < transition_copy.size() else MUTED)


func _live_replay_client_signed_copy() -> Array[String]:
	if model == null:
		return []
	if str(model.memory.get("live_replay_source_event_id", "live_demo")) == "live_demo_return":
		return ["客户签了。", "这是改期后的最后一次。", "它接管了现场说明、等待、停顿和追问。"]
	var stored_copy := "\n".join(_to_string_array(model.memory.get("live_replay_result_copy", [])))
	if stored_copy.contains("材料里还清楚"):
		return ["客户签了。", "走的时候，他和你握手。", "『你现场讲得比材料里还清楚。』"]
	return ["客户签了。", "走的时候，他和你握手。", "『你讲得比视频里还清楚。』"]


func _live_replay_file_transition_copy() -> Array[String]:
	if model != null and str(model.memory.get("live_replay_source_event_id", "live_demo")) == "live_demo_return":
		return ["晚上，你把改期后的录像从头打开。", "光标停在播放键上。"]
	return [
		"回办公室的路上你一直在想他这句话。",
		"晚上你调了会议录像，从头看。",
		"光标停在播放键上。",
	]


func _draw_live_replay_video(frame: Rect2, phase: String) -> void:
	var video := Rect2(frame.position + Vector2(28, 28), Vector2(frame.size.x - 56, 390))
	_draw_texture_cover(art_meeting_replay, video, Color(0.74, 0.80, 0.82, 1.0), Vector2(0.50, 0.48))
	draw_rect(video, Color(0.01, 0.035, 0.045, 0.24))
	draw_rect(Rect2(video.position, Vector2(5, video.size.y)), BLUE)
	draw_line(video.position + Vector2(20, 24), video.position + Vector2(68, 24), Color(0.72, 0.86, 0.84, 0.62), 1.0)
	_draw_text("CAM B / INTERNAL", video.position + Vector2(78, 28), 9, Color("#c0d0ce"))
	var frozen := phase == "we_pause" or phase == "aftermath"
	var replay_offset := 0.8 if phase == "replay" else 0.0
	var motion := 0.0 if frozen or reduced_motion else sin((screen_time + replay_offset) * 3.8)
	var gesture_center := video.position + Vector2(video.size.x * 0.51, video.size.y * 0.53)
	# The still remains cropped below the protagonist's face. Two restrained
	# tracking strokes provide the synchronous gesture evidence without turning
	# the anonymous founder into a character portrait.
	draw_arc(gesture_center + Vector2(-82, 18 + motion * 3.0), 32.0, -2.8, -1.0, 18, Color(0.48, 0.78, 0.76, 0.42), 2.0, true)
	draw_arc(gesture_center + Vector2(105, -2 - motion * 3.0), 28.0, 0.25, 2.2, 18, Color(0.48, 0.78, 0.76, 0.36), 2.0, true)
	var caption := "我们                  会把这次现场结果写进计划。" if phase == "we_pause" or phase == "aftermath" else "我们会把这次现场结果写进下周的交付计划。"
	_draw_panel(Rect2(video.position + Vector2(74, 318), Vector2(video.size.x - 148, 46)), Color(0.04, 0.06, 0.05, 0.82), Color(0, 0, 0, 0), 3.0, 0.0)
	_draw_text_centered(caption, Rect2(video.position + Vector2(86, 326), Vector2(video.size.x - 172, 30)), 13, Color("#edf1ed"), 3.0)
	var timeline := Rect2(frame.position + Vector2(28, 442), Vector2(frame.size.x - 56, 8))
	draw_rect(timeline, Color("#39433f"))
	var progress := 0.46 if frozen or reduced_motion else (clampf(screen_time / 4.0, 0.02, 0.44) if phase == "playback" else clampf(0.19 + screen_time / 5.0, 0.19, 0.44))
	draw_rect(Rect2(timeline.position, Vector2(timeline.size.x * progress, timeline.size.y)), GREEN_BRIGHT)
	draw_circle(timeline.position + Vector2(timeline.size.x * progress, timeline.size.y * 0.5), 6.0, Color("#d7e0da"))
	for i in 34:
		var height := 4.0 + absf(sin(float(i) * 1.77)) * 16.0
		if phase in ["we_pause", "aftermath"] and i in range(15, 21):
			height = 1.0
		draw_line(frame.position + Vector2(36 + i * 21.5, 484 - height * 0.5), frame.position + Vector2(36 + i * 21.5, 484 + height * 0.5), Color("#698276"), 1.0)


func _live_replay_visual_contract() -> Dictionary:
	return {
		"protagonist_face_visible": false,
		"mouth_sync_surface": "authored_observation",
		"gesture_animation": true,
		"caption_pause": true,
		"waveform_pause": true,
		"replay_phase": true,
	}


func _start_layoff_social() -> void:
	model.flags["layoff_social_active"] = true
	model.flags.erase("layoff_social_complete")
	model.memory["layoff_social_phase"] = "process_complete"
	model.memory["layoff_social_like_state"] = "unseen"
	model.memory["layoff_social_result_copy"] = result_lines.duplicate()
	model.memory["layoff_social_transitions"] = ["process_complete"]
	result_lines.clear()
	result_page = 0
	result_return = "queue_week_content"
	_change_screen(Screen.LAYOFF_SOCIAL)
	_save_game()


func _layoff_social_phase() -> String:
	return str(model.memory.get("layoff_social_phase", "process_complete")) if model != null else "process_complete"


func _layoff_social_min_phase_seconds(phase: String = "") -> float:
	if reduced_motion:
		return 0.0
	var active_phase := _layoff_social_phase() if phase.is_empty() else phase
	return LAYOFF_SOCIAL_PROCESS_MIN_SECONDS if active_phase == "process_complete" else LAYOFF_SOCIAL_INTERACTION_MIN_SECONDS


func _layoff_social_can_advance() -> bool:
	return screen_time >= _layoff_social_min_phase_seconds()


func _layoff_social_process_lines() -> Array[String]:
	var stored_copy: Array = Array(model.memory.get("layoff_social_result_copy", [])) if model != null else []
	var process_lines: Array[String] = []
	for line_value in stored_copy:
		var line := str(line_value)
		if line.begins_with(">"):
			process_lines.append(line)
	if not process_lines.is_empty():
		return process_lines
	return [
		"> 通知流程已完成。",
		"> 我安排了当面。六场，都在会议室 C，间隔二十分钟。",
		"> 我用了你的语气。",
		"> 他们都以为是你写的。",
		"> 这对他们来说更好。",
	]


func _advance_layoff_social() -> void:
	if model == null or not bool(model.flags.get("layoff_social_active", false)):
		return
	if not _layoff_social_can_advance():
		return
	_play_foley("phone")
	var phase := _layoff_social_phase()
	var next_phase: String = str({
		"process_complete": "post_visible",
		"post_visible": "liked_once",
		"liked_once": "unliked",
		"unliked": "reliked",
	}.get(phase, "complete"))
	var transitions: Array = Array(model.memory.get("layoff_social_transitions", [])).duplicate()
	transitions.append(next_phase)
	model.memory["layoff_social_transitions"] = transitions
	model.memory["layoff_social_phase"] = next_phase
	match next_phase:
		"liked_once": model.memory["layoff_social_like_state"] = "liked"
		"unliked": model.memory["layoff_social_like_state"] = "unliked"
		"reliked": model.memory["layoff_social_like_state"] = "liked_final"
		"complete":
			model.flags["layoff_social_active"] = false
			model.flags["layoff_social_complete"] = true
			result_return = "dashboard"
			if not _queue_week_content():
				_save_game()
			return
	screen_time = 0.0
	_save_game()
	queue_redraw()


func _draw_layoff_social() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), COLD_10)
	_draw_text("周三 / 15:00", Vector2(54, 48), 12, MUTED)
	_draw_display_text("你没有去公司。", Vector2(54, 92), 30, INK)
	var process := Rect2(54, 128, 560, 494)
	_draw_panel(process, COLD_95, MUTED, 8.0, 1.0)
	_draw_text("LANTERN / 通知流程", process.position + Vector2(24, 32), 11, COLD_40)
	var phase := _layoff_social_phase()
	var process_lines := _layoff_social_process_lines()
	var process_reveal_time := screen_time if phase == "process_complete" and not reduced_motion else LAYOFF_SOCIAL_PROCESS_MIN_SECONDS
	for i in process_lines.size():
		var reveal_alpha := clampf((process_reveal_time - float(i) * 0.12) / 0.26, 0.0, 1.0)
		_draw_text(process_lines[i], process.position + Vector2(24, 76 + i * 41), 13, Color(0.64, 0.78, 0.68, reveal_alpha))
	var phone := Rect2(704, 88, 414, 554)
	_draw_panel(phone, COLD_00, COLD_50, 22.0, 2.0)
	draw_rect(Rect2(phone.position + Vector2(148, 16), Vector2(118, 7)), COLD_30)
	_draw_text("动态", phone.position + Vector2(24, 58), 12, MUTED)
	if phase == "process_complete":
		_draw_text_centered("15:00", Rect2(phone.position + Vector2(90, 190), Vector2(234, 54)), 36, COLD_80, 3.0)
		_draw_text_centered("手机亮了一次。", Rect2(phone.position + Vector2(70, 260), Vector2(274, 38)), 13, MUTED, 3.0)
	else:
		_draw_layoff_post(phone, phase)
	var button := _layoff_social_continue_rect()
	if _layoff_social_can_advance():
		_draw_panel(button, SURFACE_DARK, GREEN, 7.0, 1.0)
		var label: String = str({
			"process_complete": "打开手机   ENTER",
			"post_visible": "点个赞   ENTER",
			"liked_once": "取消   ENTER",
			"unliked": "再点一次   ENTER",
			"reliked": "放下手机   ENTER",
		}.get(phase, "继续   ENTER"))
		label = label.replace("ENTER", _gamepad_shortcut("A", "ENTER"))
		_draw_text_centered(label, button, 12, Color.WHITE, 3.0)
	else:
		_draw_panel(button, COLD_10, COLD_30, 7.0, 1.0)
		_draw_text_centered("请稍候", button, 11, COLD_50, 3.0)


func _draw_layoff_post(phone: Rect2, phase: String) -> void:
	var avatar := phone.position + Vector2(54, 105)
	draw_circle(avatar, 22.0, COLD_20)
	_draw_text("前同事", phone.position + Vector2(90, 101), 12, INK)
	_draw_text("刚刚", phone.position + Vector2(90, 123), 10, MUTED)
	_draw_paragraph_array(["谢谢老板亲自跟我说。", "挺好的，真的。"], Rect2(phone.position + Vector2(32, 162), Vector2(phone.size.x - 64, 130)), 17, INK, 31)
	draw_line(phone.position + Vector2(32, 314), phone.position + Vector2(phone.size.x - 32, 314), COLD_10, 1.0)
	var heart_state := _layoff_social_heart_visual_state(phase, screen_time)
	var liked := bool(heart_state["filled"])
	var heart_center := phone.position + Vector2(72, 356)
	var fading_fill_alpha := float(heart_state["fading_fill_alpha"])
	if fading_fill_alpha > 0.0:
		_draw_social_heart(heart_center, true, float(heart_state["scale"]), fading_fill_alpha)
	_draw_social_heart(heart_center, liked, float(heart_state["scale"]))
	_draw_text("41" if liked else "40", phone.position + Vector2(106, 362), 12, RED if liked else MUTED)
	var state_copy: String = str({
		"post_visible": "你看了很久。",
		"liked_once": "赞亮了。",
		"unliked": "赞又暗了。",
		"reliked": "你又点了一次。",
	}.get(phase, ""))
	_draw_text_centered(state_copy, Rect2(phone.position + Vector2(42, 414), Vector2(phone.size.x - 84, 34)), 12, MUTED, 3.0)


func _layoff_social_heart_visual_state(phase: String, phase_time: float) -> Dictionary:
	var progress := 1.0 if reduced_motion else clampf(phase_time / LAYOFF_SOCIAL_HEART_ANIMATION_SECONDS, 0.0, 1.0)
	var filled := phase in ["liked_once", "reliked"]
	var scale := 1.0
	var fading_fill_alpha := 0.0
	if filled:
		# The two likes visibly land: the heart grows from under-size, overshoots,
		# then settles. This is presentation only and never changes game state.
		scale = lerpf(0.72, 1.0, progress) + sin(progress * PI) * 0.18
	elif phase == "unliked":
		# The previous red fill drains away beneath the ordinary outline.
		fading_fill_alpha = 1.0 - progress
		scale = lerpf(1.08, 1.0, progress)
	return {
		"filled": filled,
		"scale": scale,
		"fading_fill_alpha": fading_fill_alpha,
		"progress": progress,
	}


func _draw_social_heart(center: Vector2, filled: bool, scale: float = 1.0, alpha: float = 1.0) -> void:
	var color := RED if filled else Color("#808985")
	color.a *= clampf(alpha, 0.0, 1.0)
	if filled:
		draw_circle(center + Vector2(-7, -5) * scale, 8.5 * scale, color)
		draw_circle(center + Vector2(7, -5) * scale, 8.5 * scale, color)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-15, -4) * scale, center + Vector2(15, -4) * scale, center + Vector2(0, 18) * scale]), color)
	else:
		draw_polyline(PackedVector2Array([center + Vector2(-15, -4) * scale, center + Vector2(-7, -13) * scale, center, center + Vector2(7, -13) * scale, center + Vector2(15, -4) * scale, center + Vector2(0, 18) * scale, center + Vector2(-15, -4) * scale]), color, 2.0 * scale, true)


func _draw_terminal() -> void:
	# The machine glass has become the operating ledger: one dense, ruled sheet
	# rather than a constellation of dashboard widgets.  It keeps the terminal's
	# cold recessed surface, while its typography and annotations still belong to
	# the physical company dossier used everywhere else in the game.
	var state: Dictionary = model.public_state()
	var business: Dictionary = Dictionary(state.get("business", {}))
	var operations: Dictionary = Dictionary(state.get("operations", {}))
	var ledger: Dictionary = Dictionary(business.get("ledger", {}))
	var capital: Dictionary = Dictionary(business.get("capital", {}))
	var market: Dictionary = Dictionary(business.get("market", {}))
	var policy: Dictionary = Dictionary(business.get("policy", {}))
	var rect := Rect2(306, 106, 912, 520)
	var inner := rect.grow(-18.0)
	draw_rect(Rect2(rect.position + Vector2(7, 9), rect.size), Color(0.005, 0.02, 0.025, 0.32))
	draw_rect(rect, COLD_95)
	draw_rect(rect, COLD_60, false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(6, rect.size.y - 2)), BLUE.darkened(0.12))
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 38)), INK)
	draw_line(inner.position + Vector2(0, 38), Vector2(inner.end.x, inner.position.y + 38), MUTED, 1.0)
	_draw_text("OPERATING LEDGER  /  WEEK %02d" % int(model.total_week), inner.position + Vector2(14, 25), 11, COLD_30)
	_draw_text("NODE %s  ·  CLOSE %02d" % [_model_official_name(), int(model.total_week)], inner.position + Vector2(inner.size.x - 310, 25), 11, NIGHT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 296)
	var live_alpha := 0.72 if reduced_motion else 0.52 + sin(_motion_clock() * 2.2) * 0.16
	draw_circle(inner.position + Vector2(inner.size.x - 8, 19), 3.0, Color(GREEN_BRIGHT, live_alpha))

	# Five entries on one ruled register.  Large values use the same editorial
	# serif as chapter headings; small annotations carry the accounting detail.
	var metrics_top := inner.position.y + 50.0
	var metric_width := inner.size.x / 5.0
	var founder_bp := _operating_founder_ownership_bp(capital)
	var runway := int(ledger.get("runway_weeks", 0))
	_draw_operating_metric(Vector2(inner.position.x, metrics_top), metric_width, "可用现金", _format_usd_compact(int(ledger.get("cash_usd", 0))), "已结算现金", GREEN_BRIGHT)
	_draw_operating_metric(Vector2(inner.position.x + metric_width, metrics_top), metric_width, "净周消耗", _format_usd_compact(-int(ledger.get("weekly_burn_usd", 0))), "每周 / NET BURN", RED if runway <= 6 else AMBER)
	_draw_operating_metric(Vector2(inner.position.x + metric_width * 2.0, metrics_top), metric_width, "经常性收入", _format_usd_compact(int(ledger.get("mrr_usd", 0))), "ARR %s · %d 客户" % [_format_usd_compact(int(ledger.get("contracted_arr_usd", 0))), int(ledger.get("customer_count", 0))], BLUE)
	_draw_operating_metric(Vector2(inner.position.x + metric_width * 3.0, metrics_top), metric_width, "跑道", "自给" if runway >= 999 else "%d 周" % runway, "按当前净 burn", GREEN if runway > 12 else AMBER)
	_draw_operating_metric(Vector2(inner.position.x + metric_width * 4.0, metrics_top), metric_width, "创始人持股", "%.1f%%" % (float(founder_bp) / 100.0), "FULLY DILUTED", GREEN)
	var register_rule_y := metrics_top + 77.0
	draw_line(Vector2(inner.position.x, register_rule_y), Vector2(inner.end.x, register_rule_y), MUTED, 1.0)

	var body_top := register_rule_y + 11.0
	var split_x := inner.position.x + 548.0
	draw_line(Vector2(split_x, body_top), Vector2(split_x, inner.end.y - 93.0), COLD_70, 1.0)
	_draw_operating_company_register(Rect2(inner.position.x, body_top, 532, 208), operations, ledger)
	_draw_operating_external_register(Rect2(split_x + 16, body_top, inner.end.x - split_x - 16, 208), market, policy)

	# The bottom tape keeps the terminal's original sense of a machine quietly
	# recording authorship.  Market intelligence and internal actions share one
	# chronology, without turning either into a notification card.
	var tape := Rect2(inner.position.x, inner.end.y - 82.0, inner.size.x, 82.0)
	draw_rect(tape, Color(0.18, 0.30, 0.28, 0.12))
	draw_line(tape.position, Vector2(tape.end.x, tape.position.y), COLD_60, 1.0)
	_draw_text("PUBLIC TAPE / 市场与公司回执", tape.position + Vector2(12, 20), 11, COLD_40)
	var market_line := _operating_latest_public_line(market, policy)
	_draw_text(_truncate_operating_text(market_line, 48), tape.position + Vector2(12, 43), 12, TERMINAL_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 520)
	var internal_line := _operating_latest_internal_line()
	# A fixed quiet zone belongs to the machine cursor.  Long named-candidate
	# receipts are abbreviated before that zone instead of painting underneath it.
	_draw_text(_truncate_operating_text(internal_line, 20), tape.position + Vector2(568, 43), 12, COLD_30, HORIZONTAL_ALIGNMENT_LEFT, 250)
	_draw_text("MARKET", tape.position + Vector2(12, 65), 10, COLD_50)
	_draw_text("INTERNAL / AUTHOR", tape.position + Vector2(568, 65), 10, COLD_50)
	if reduced_motion or fmod(_motion_clock(), 1.0) < 0.56:
		draw_rect(Rect2(tape.position + Vector2(tape.size.x - 14.0, 30), Vector2(7, 13)), COLD_30)
	_draw_back_button()


func _draw_operating_metric(origin: Vector2, width: float, label: String, value: String, detail: String, accent: Color) -> void:
	draw_rect(Rect2(origin + Vector2(11, 0), Vector2(3, 55)), Color(accent, 0.64))
	_draw_text(label, origin + Vector2(24, 15), 11, NIGHT_MUTED)
	_draw_display_text(value, origin + Vector2(24, 42), 20, COLD_10)
	_draw_text(detail, origin + Vector2(24, 61), 10, Color(accent, 0.88), HORIZONTAL_ALIGNMENT_LEFT, width - 32.0)


func _draw_operating_company_register(rect: Rect2, operations: Dictionary, ledger: Dictionary) -> void:
	_draw_text("COMPANY REGISTER / 内部经营", rect.position + Vector2(0, 14), 11, GREEN_BRIGHT)
	_draw_text("招聘漏斗", rect.position + Vector2(0, 42), 11, NIGHT_MUTED)
	var funnel := [
		{"label": "职缺", "value": int(operations.get("open_requisitions", 0))},
		{"label": "候选", "value": int(operations.get("active_candidates", 0))},
		{"label": "OFFER", "value": int(operations.get("active_offers", 0))},
		{"label": "待入职", "value": int(operations.get("scheduled_joins", 0)) + int(operations.get("pending_joins", 0))},
	]
	var funnel_x := rect.position.x + 86.0
	for i in funnel.size():
		var step: Dictionary = funnel[i]
		var x := funnel_x + i * 100.0
		if i > 0:
			draw_line(Vector2(x - 48, rect.position.y + 36), Vector2(x - 13, rect.position.y + 36), MUTED, 1.0)
		draw_circle(Vector2(x, rect.position.y + 36), 11.0, INK)
		draw_arc(Vector2(x, rect.position.y + 36), 11.0, 0.0, TAU, 24, GREEN if int(step["value"]) > 0 else COLD_60, 1.0, true)
		_draw_text("%02d" % int(step["value"]), Vector2(x - 8, rect.position.y + 40), 11, COLD_20)
		_draw_text(str(step["label"]), Vector2(x - 20, rect.position.y + 60), 10, COLD_50, HORIZONTAL_ALIGNMENT_CENTER, 42)
	draw_line(rect.position + Vector2(0, 70), rect.position + Vector2(rect.size.x, 70), COLD_70, 1.0)

	var office: Dictionary = Dictionary(operations.get("office", {}))
	var lease: Dictionary = Dictionary(office.get("lease", {}))
	var capacity := int(office.get("capacity", 0))
	var occupancy := int(office.get("occupancy", int(operations.get("active_employees", 0))))
	var office_overflow := occupancy > capacity
	var office_name := str(lease.get("name", "尚未签约·分布式"))
	_draw_text("办公室", rect.position + Vector2(0, 94), 11, NIGHT_MUTED)
	_draw_text(_truncate_operating_text(office_name, 16), rect.position + Vector2(74, 94), 12, COLD_20)
	_draw_text("%d 人 / %d 工位" % [occupancy, capacity], rect.position + Vector2(400, 94), 11, RED if office_overflow else GREEN_BRIGHT, HORIZONTAL_ALIGNMENT_RIGHT, 130)
	var office_bar := Rect2(rect.position + Vector2(74, 103), Vector2(456, 3))
	draw_rect(office_bar, COLD_80)
	var office_denominator := maxi(1, maxi(capacity, occupancy))
	draw_rect(Rect2(office_bar.position, Vector2(office_bar.size.x * clampf(float(occupancy) / float(office_denominator), 0.0, 1.0), office_bar.size.y)), RED if office_overflow else GREEN)

	var burn: Dictionary = Dictionary(operations.get("burn", {}))
	var payroll_usd := _operating_cost_to_usd(float(burn.get("payroll", 0.0)) + float(burn.get("benefits", 0.0)))
	var lease_usd := _operating_cost_to_usd(float(burn.get("lease", 0.0)))
	var saas_usd := _operating_cost_to_usd(float(burn.get("saas", 0.0)))
	var base_and_compute_usd := maxi(0, int(ledger.get("weekly_cost_usd", 0)) - payroll_usd - lease_usd - saas_usd)
	_draw_text("周成本", rect.position + Vector2(0, 132), 11, NIGHT_MUTED)
	var cost_columns := [
		{"label": "员工薪福", "value": payroll_usd},
		{"label": "租约", "value": lease_usd},
		{"label": "SAAS", "value": saas_usd},
		{"label": "基础+算力", "value": base_and_compute_usd},
	]
	for i in cost_columns.size():
		var cost: Dictionary = cost_columns[i]
		var x := rect.position.x + 74.0 + i * 113.0
		_draw_text(str(cost["label"]), Vector2(x, rect.position.y + 130), 10, COLD_50)
		_draw_text(_format_usd_compact(int(cost["value"])), Vector2(x, rect.position.y + 151), 12, COLD_20)

	draw_line(rect.position + Vector2(0, 161), rect.position + Vector2(rect.size.x, 161), COLD_70, 1.0)
	_draw_text("采购 / 续约", rect.position + Vector2(0, 185), 11, NIGHT_MUTED)
	var subscriptions: Array = Array(operations.get("subscriptions", []))
	if subscriptions.is_empty():
		_draw_text("采购台账尚空", rect.position + Vector2(88, 185), 11, COLD_50)
	else:
		for i in mini(2, subscriptions.size()):
			var subscription: Dictionary = Dictionary(subscriptions[i])
			var x := rect.position.x + 88.0 + i * 220.0
			var renewal := int(subscription.get("renewal_week", -1))
			var service_meta := "%s/w · W%02d" % [_format_usd_compact(_operating_cost_to_usd(float(subscription.get("weekly_cost", 0.0)))), renewal]
			_draw_text(_truncate_operating_text(str(subscription.get("name", "SERVICE")), 9), Vector2(x, rect.position.y + 181), 11, COLD_20)
			_draw_text(service_meta, Vector2(x, rect.position.y + 199), 10, COLD_50)


func _draw_operating_external_register(rect: Rect2, market: Dictionary, policy: Dictionary) -> void:
	_draw_text("MARKET WATCH / 外部情报", rect.position + Vector2(0, 14), 11, BLUE.lightened(0.24))
	var competitors: Array = Array(market.get("competitors", []))
	for i in mini(3, competitors.size()):
		var competitor: Dictionary = Dictionary(competitors[i])
		var y := rect.position.y + 35.0 + i * 39.0
		var signal_label := _operating_signal_label(str(competitor.get("public_product_signal", "unknown")))
		draw_circle(Vector2(rect.position.x + 4, y - 3), 2.5, BLUE if i != 1 else AMBER)
		_draw_text(_truncate_operating_text(str(competitor.get("name", "COMPETITOR")), 16), Vector2(rect.position.x + 14, y), 12, COLD_20)
		_draw_text("%s · %s" % [_operating_stage_label(str(competitor.get("stage", ""))), _operating_strategy_label(str(competitor.get("last_strategy", "")))], Vector2(rect.position.x + 14, y + 17), 10, COLD_50)
		_draw_text(signal_label, Vector2(rect.end.x - 74, y), 10, COLD_40, HORIZONTAL_ALIGNMENT_RIGHT, 72)
		if i < mini(3, competitors.size()) - 1:
			draw_line(Vector2(rect.position.x + 14, y + 23), Vector2(rect.end.x, y + 23), Color(0.26, 0.37, 0.34, 0.42), 1.0)
	if competitors.is_empty():
		_draw_text("尚无公开竞争信号", rect.position + Vector2(0, 46), 11, COLD_50)

	var policy_y := rect.position.y + 158.0
	draw_line(Vector2(rect.position.x, policy_y - 17), Vector2(rect.end.x, policy_y - 17), MUTED, 1.0)
	_draw_text("POLICY DESK / 政策", Vector2(rect.position.x, policy_y), 11, BLUE.lightened(0.24))
	var policy_values := [
		{"label": "准入", "value": int(policy.get("access", 0))},
		{"label": "影响", "value": int(policy.get("industry_influence", 0))},
		{"label": "公信", "value": int(policy.get("public_trust", 0))},
	]
	for i in policy_values.size():
		var entry: Dictionary = policy_values[i]
		var x := rect.position.x + i * 91.0
		_draw_text(str(entry["label"]), Vector2(x, policy_y + 24), 10, COLD_50)
		_draw_text("%02d" % int(entry["value"]), Vector2(x + 34, policy_y + 24), 11, COLD_20)
		var gauge := Rect2(x, policy_y + 30, 76, 2)
		draw_rect(gauge, COLD_80)
		draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * clampf(float(entry["value"]) / 100.0, 0.0, 1.0), 2)), GREEN)
	var policy_status: Array[String] = []
	if bool(policy.get("government_contractor", false)):
		policy_status.append("政府供应商")
	if bool(policy.get("lda_registered", false)):
		policy_status.append("游说已披露")
	if int(policy.get("deferred_tax_credit_usd", 0)) > 0:
		policy_status.append("税惠 %s" % _format_usd_compact(int(policy.get("deferred_tax_credit_usd", 0))))
	if policy_status.is_empty():
		policy_status.append("观察期·尚未介入")
	# Corporate-policy identities and monetary incentives are different ledger
	# facts.  Keep the identities on the first line and give a third status (most
	# often the tax-credit balance) an unabridged second line.
	var policy_first_line := " / ".join(policy_status.slice(0, mini(2, policy_status.size())))
	_draw_text(policy_first_line, Vector2(rect.position.x, policy_y + 52), 10, COLD_40, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x)
	if policy_status.size() > 2:
		var policy_second_line := " / ".join(policy_status.slice(2))
		_draw_text(policy_second_line, Vector2(rect.position.x, policy_y + 69), 10, GREEN_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x)


func _operating_founder_ownership_bp(capital: Dictionary) -> int:
	var cap_table: Dictionary = Dictionary(capital.get("cap_table", {}))
	for row_value in Array(cap_table.get("rows", [])):
		if row_value is Dictionary and str(Dictionary(row_value).get("owner_id", "")) == "founder":
			return int(Dictionary(row_value).get("ownership_bp", 0))
	return 0


func _operating_cost_to_usd(value: float) -> int:
	# Operations catalog values are denominated in thousands of dollars.  The
	# finance ledger remains integer USD, so the conversion only happens here at
	# the presentation boundary.
	return int(round(value * 1000.0))


func _format_usd_compact(value: int) -> String:
	var sign_prefix := "-" if value < 0 else ""
	var magnitude := absi(value)
	if magnitude >= 1_000_000:
		return "%s$%.1fM" % [sign_prefix, float(magnitude) / 1_000_000.0]
	if magnitude >= 1_000:
		return "%s$%.1fK" % [sign_prefix, float(magnitude) / 1_000.0]
	return "%s$%d" % [sign_prefix, magnitude]


func _operating_stage_label(stage: String) -> String:
	return {
		"preseed": "PRE-SEED", "seed": "SEED", "series_a": "SERIES A",
	}.get(stage.to_lower(), stage.to_upper() if not stage.is_empty() else "PRIVATE")


func _operating_strategy_label(strategy: String) -> String:
	return {
		"research_sprint": "研发加码", "product_launch": "产品发布", "fundraise": "融资",
		"price_cut": "降价", "enterprise_win": "大客户", "talent_bid": "抢人",
		"policy_coalition": "标准联盟",
	}.get(strategy, "无公开动作")


func _operating_signal_label(product_signal: String) -> String:
	return {
		"private_beta": "PRIVATE β", "announced": "PUBLIC", "enterprise_pilot": "PILOT",
		"positive": "UP", "mixed": "MIXED", "negative": "DOWN",
	}.get(product_signal, "UNVERIFIED")


func _operating_latest_public_line(market: Dictionary, policy: Dictionary) -> String:
	var market_feed: Array = Array(market.get("public_feed", []))
	var policy_feed: Array = Array(policy.get("public_feed", []))
	var latest: Dictionary = {}
	if not market_feed.is_empty() and market_feed[-1] is Dictionary:
		latest = Dictionary(market_feed[-1])
	if not policy_feed.is_empty() and policy_feed[-1] is Dictionary:
		var policy_entry: Dictionary = Dictionary(policy_feed[-1])
		if latest.is_empty() or int(policy_entry.get("week", -1)) >= int(latest.get("week", -1)):
			latest = policy_entry
	if not latest.is_empty():
		return "W%02d  %s" % [int(latest.get("week", model.total_week)), str(latest.get("headline", "公开记录已更新。"))]
	return "W%02d  市场仍在安静定价；没有新的可验证信号。" % int(model.total_week)


func _operating_latest_internal_line() -> String:
	var operating_summary := str(model.memory.get("last_operating_action_summary", "")).strip_edges()
	if not operating_summary.is_empty():
		return "> " + operating_summary
	if terminal_lines.is_empty():
		return "> 本周尚无操作回执。"
	return str(terminal_lines[-1])


func _truncate_operating_text(value: String, max_characters: int) -> String:
	var cleaned := value.replace("\n", " ").strip_edges()
	if cleaned.length() <= max_characters:
		return cleaned
	return cleaned.substr(0, maxi(1, max_characters - 1)).strip_edges() + "…"


func _draw_intranet() -> void:
	var docs := _intranet_documents()
	_draw_text("INTERNAL FOLIO  /  %02d" % int(model.total_week), Vector2(306, 106), 12, PAPER_GREEN)
	_draw_display_text("内网", Vector2(306, 144), 28, INK)
	_draw_text("公告、周报、新人指南、价值观。写得很好。", Vector2(416, 141), 13, MUTED)
	var weekly_review := _current_week_intranet_review()
	if not weekly_review.is_empty():
		var review_author := _model_official_name() if str(weekly_review.get("author", "founder")) == "lantern" else "你"
		_draw_folio_stamp(Rect2(1044, 92, 164, 58), "已审阅 · %s" % review_author, GREEN, -0.025)
	# A bound two-page dossier: cold index leaf on the left, warm authored leaf
	# on the right. The central gutter replaces the previous stack of cards.
	var index_page := Rect2(306, 166, 220, 464)
	var detail := Rect2(546 + (1.0 - _reveal(0.12, 0.34)) * 12.0, 166, 698, 464)
	var detail_machine_authored := false
	if not docs.is_empty():
		var paper_document: Dictionary = docs[clampi(selected_document, 0, docs.size() - 1)]
		detail_machine_authored = str(paper_document.get("author", "")).to_upper().contains("LANTERN")
	var detail_paper := COLD_10 if detail_machine_authored else WARM_10
	draw_rect(Rect2(index_page.position + Vector2(6, 7), Vector2(detail.end.x - index_page.position.x, index_page.size.y)), Color(0.01, 0.035, 0.04, 0.16))
	draw_rect(index_page, COLD_10)
	draw_rect(detail, detail_paper)
	draw_line(index_page.position, Vector2(detail.end.x, index_page.position.y), COLD_40, 1.0)
	draw_line(Vector2(index_page.position.x, index_page.end.y), Vector2(detail.end.x, index_page.end.y), COLD_40, 1.0)
	draw_line(Vector2(536, 170), Vector2(536, 626), COLD_40, 2.0)
	_draw_text("卷内目录 / %02d 份" % docs.size(), index_page.position + Vector2(14, 28), TYPE_META, MUTED)
	draw_line(index_page.position + Vector2(14, 39), index_page.position + Vector2(index_page.size.x - 14, 39), COLD_30, 1.0)
	for i in docs.size():
		var doc: Dictionary = docs[i]
		var hit_rect := _document_rect(i)
		hit_rect.position.x -= (1.0 - _reveal(0.04 + i * 0.025, 0.28)) * 8.0
		# The legacy click contract begins beneath the binder edge at x=250. Keep
		# every visible pixel inside that rect while the 306px content rail prevents
		# the folio from painting over the chrome.
		var row_rect := Rect2(306, hit_rect.position.y, hit_rect.end.x - 306.0, hit_rect.size.y)
		if i == selected_document:
			draw_rect(row_rect, Color(0.78, 0.84, 0.78, 0.46))
			draw_rect(Rect2(row_rect.position, Vector2(4, row_rect.size.y)), GREEN)
		if _focus_is("intranet_documents", i):
			_draw_panel(row_rect.grow(2.0), Color.TRANSPARENT, GREEN_BRIGHT, RADIUS_CONTROL + 2.0, 2.0)
		_draw_text("%02d" % (i + 1), row_rect.position + Vector2(12, 23), 10, PAPER_GREEN if i == selected_document else MUTED)
		_draw_text(str(doc.get("title", "文档")), row_rect.position + Vector2(43, 23), 12, INK, HORIZONTAL_ALIGNMENT_LEFT, 161)
		_draw_text(_document_meta(doc), row_rect.position + Vector2(43, 44), 10, MUTED, HORIZONTAL_ALIGNMENT_LEFT, 161)
		draw_line(Vector2(row_rect.position.x + 12, row_rect.end.y), Vector2(row_rect.end.x - 12, row_rect.end.y), COLD_30, 1.0)
	draw_rect(Rect2(detail.position + Vector2(24, 0), Vector2(122, 4)), AMBER)
	if not docs.is_empty():
		var selected: Dictionary = docs[clampi(selected_document, 0, docs.size() - 1)]
		var selected_id := str(selected.get("id", ""))
		var document_pages := _selected_document_pages(docs)
		var visible_body: Array[String] = document_pages[document_page] if not document_pages.is_empty() else []
		_draw_text("系统归档" if detail_machine_authored else "署名文档", detail.position + Vector2(28, 24), TYPE_META, BLUE.darkened(0.12) if detail_machine_authored else AMBER.darkened(0.14))
		_draw_display_text(str(selected.get("title", "文档")), detail.position + Vector2(28, 54), 24, INK)
		_draw_text(_document_meta(selected), detail.position + Vector2(28, 78), 11, MUTED)
		if document_pages.size() > 1:
			_draw_page_button(_document_prev_rect(), "‹", document_page > 0)
			_draw_page_counter(_document_page_counter_rect(), document_page + 1, document_pages.size())
			_draw_page_button(_document_next_rect(), "›", document_page + 1 < document_pages.size())
		var body_height := detail.size.y - 118.0
		if selected_id == "our_origin" and (_origin_interaction_required() or bool(model.flags.get("origin_article_interaction_complete", false))):
			body_height -= 60.0
		draw_line(detail.position + Vector2(28, 90), detail.position + Vector2(detail.size.x - 28, 90), WARM_40, 1.0)
		_draw_paragraph_array(visible_body, Rect2(detail.position + Vector2(28, 104), Vector2(detail.size.x - 56, body_height)), 14, INK, 24)
		if selected_id == "our_origin" and _origin_interaction_required():
			var read_count := clampi(int(model.memory.get("origin_read_count", 0)), 0, 3)
			var reread := _origin_reread_rect()
			draw_line(detail.position + Vector2(28, 398), detail.position + Vector2(detail.size.x - 28, 398), WARM_40, 1.0)
			_draw_text("阅读记录  %d / 3" % read_count, detail.position + Vector2(28, 426), TYPE_META, GREEN)
			_draw_ledger_button(reread, "再读一遍", _gamepad_shortcut("A", "ENTER"), "quiet")
		elif selected_id == "our_origin" and bool(model.flags.get("origin_article_interaction_complete", false)):
			_draw_text("未作修改。文章确实写得比你记得的更好。", detail.position + Vector2(28, 438), 11, MUTED)
	_draw_back_button()


func _draw_calendar() -> void:
	var area := Rect2(306, 82, 912, 606)
	_draw_text("WEEK PLAN  /  %02d" % int(model.total_week), area.position + Vector2(0, 24), 12, PAPER_GREEN)
	_draw_display_text("日历", area.position + Vector2(0, 62), 28, INK)
	_draw_text("会议室与门禁资源", area.position + Vector2(110, 59), 13, MUTED)
	var days := ["周一", "周二", "周三", "周四", "周五"]
	var planner := Rect2(306, 164, 660, 356)
	draw_rect(Rect2(planner.position + Vector2(5, 6), planner.size), Color(0.01, 0.035, 0.04, 0.14))
	draw_rect(planner, COLD_05)
	draw_rect(planner, COLD_40, false, 1.0)
	for i in days.size():
		var day_reveal := _reveal(0.04 + i * 0.04, 0.32)
		var day_rect := Rect2(area.position.x + i * 132.0, 164 + (1.0 - day_reveal) * 8.0, 132, 356)
		if i > 0:
			draw_line(Vector2(day_rect.position.x, planner.position.y), Vector2(day_rect.position.x, planner.end.y), COLD_30, 1.0)
		draw_rect(Rect2(day_rect.position, Vector2(day_rect.size.x, 4)), BLUE.lerp(GREEN, float(i) / 4.0))
		_draw_text("0%d" % (i + 1), day_rect.position + Vector2(12, 28), 10, PAPER_GREEN)
		_draw_text(days[i], day_rect.position + Vector2(43, 28), 12, INK)
		draw_line(day_rect.position + Vector2(10, 39), day_rect.position + Vector2(day_rect.size.x - 10, 39), COLD_30, 1.0)
		for guide in 4:
			var guide_y := day_rect.position.y + 116 + guide * 58
			draw_line(Vector2(day_rect.position.x + 10, guide_y), Vector2(day_rect.end.x - 10, guide_y), Color(0.48, 0.57, 0.58, 0.13), 1.0)
		var entries := _calendar_entries_for_day(i)
		for row in entries.size():
			var entry: Dictionary = entries[row]
			var entry_rect := Rect2(day_rect.position + Vector2(10, 52 + row * 82), Vector2(day_rect.size.x - 20, 66))
			draw_rect(entry_rect, WARM_10)
			draw_rect(Rect2(entry_rect.position, Vector2(3, entry_rect.size.y)), BLUE.lerp(GREEN, float(i) / 4.0))
			_draw_text(str(entry.get("time", "")), entry_rect.position + Vector2(9, 18), 10, PAPER_GREEN)
			_draw_multiline(str(entry.get("title", "")), Rect2(entry_rect.position + Vector2(9, 24), Vector2(entry_rect.size.x - 17, 38)), 12, INK, 17)
	var resource := Rect2(976 + (1.0 - _reveal(0.18, 0.36)) * 12.0, 164, 268, 356)
	draw_rect(Rect2(resource.position + Vector2(5, 6), resource.size), Color(0.01, 0.035, 0.04, 0.14))
	draw_rect(resource, COLD_10)
	draw_rect(resource, COLD_40, false, 1.0)
	_draw_text("会议室与门禁登记", resource.position + Vector2(18, 24), TYPE_META, PAPER_GREEN)
	_draw_text("会议室", resource.position + Vector2(18, 44), 12, INK)
	draw_line(resource.position + Vector2(18, 53), resource.position + Vector2(resource.size.x - 18, 53), COLD_30, 1.0)
	var rooms := ["A · 空闲", "B · 14:00 客户", "C · 09:00–11:00"]
	if bool(model.flags.get("meeting_room_d_available", false)):
		rooms.append("D · 下周同一时间")
	for i in rooms.size():
		var room_rect := Rect2(resource.position + Vector2(18, 58 + i * 43), Vector2(resource.size.x - 36, 38))
		_draw_text("%02d" % (i + 1), room_rect.position + Vector2(0, 24), 10, MUTED)
		_draw_text(str(rooms[i]), room_rect.position + Vector2(34, 24), 11, INK)
		draw_line(Vector2(room_rect.position.x, room_rect.end.y), Vector2(room_rect.end.x, room_rect.end.y), COLD_30, 1.0)
	_draw_text("电梯权限", resource.position + Vector2(18, 262), 11, MUTED)
	var floors := ["L", "1"]
	if bool(model.flags.get("extra_elevator_floor", false)):
		floors.append("2")
	var floor_visual := _elevator_floor_button_visual_contract()
	var floor_size: Vector2 = floor_visual["size"]
	var floor_fill: Color = floor_visual["fill"]
	var floor_border: Color = floor_visual["border"]
	var floor_font_color: Color = floor_visual["font_color"]
	for i in floors.size():
		var floor_rect := Rect2(resource.position + Vector2(18 + i * 54, 282), floor_size)
		_draw_panel(floor_rect, floor_fill, floor_border, float(floor_visual["radius"]), float(floor_visual["border_width"]))
		_draw_text_centered(str(floors[i]), floor_rect, int(floor_visual["font_size"]), floor_font_color, float(floor_visual["text_inset"]))
	_draw_text("楼层目录：A / B / C", resource.position + Vector2(18, 342), 10, MUTED)
	_draw_back_button()


func _draw_announcements() -> void:
	var area := Rect2(306, 82, 912, 606)
	_draw_text("PRINT QUEUE  /  ALL HANDS", area.position + Vector2(0, 24), 12, PAPER_GREEN)
	_draw_display_text("公告栏", area.position + Vector2(0, 62), 28, INK)
	_draw_text("全员可见 · 按发布时间排序", area.position + Vector2(136, 59), 13, MUTED)
	var items := _announcement_items()
	var page_size := _announcement_balanced_page_size(items.size())
	var page_start := announcement_page * page_size
	var visible_items := items.slice(page_start, mini(items.size(), page_start + page_size))
	var queue_sheet := Rect2(306, 164, 684, 450)
	draw_rect(Rect2(queue_sheet.position + Vector2(5, 6), queue_sheet.size), Color(0.01, 0.035, 0.04, 0.14))
	draw_rect(queue_sheet, COLD_05)
	draw_rect(queue_sheet, COLD_40, false, 1.0)
	_draw_text("序号", queue_sheet.position + Vector2(16, 28), TYPE_META, MUTED)
	_draw_text("主题 / 发布范围", queue_sheet.position + Vector2(62, 28), TYPE_META, MUTED)
	_draw_text("信号", queue_sheet.position + Vector2(506, 28), TYPE_META, MUTED)
	draw_line(queue_sheet.position + Vector2(14, 39), queue_sheet.position + Vector2(queue_sheet.size.x - 14, 39), COLD_30, 1.0)
	for i in visible_items.size():
		var item: Dictionary = visible_items[i]
		var item_reveal := _reveal(0.04 + i * 0.04, 0.30)
		var rect := Rect2(queue_sheet.position.x - (1.0 - item_reveal) * 8.0, queue_sheet.position.y + 40 + i * 68, queue_sheet.size.x, 68)
		if i % 2 == 0:
			draw_rect(Rect2(queue_sheet.position.x + 1, rect.position.y, queue_sheet.size.x - 2, rect.size.y), Color(0.96, 0.94, 0.86, 0.22))
		_draw_text("%02d" % (page_start + i + 1), rect.position + Vector2(16, 28), 10, PAPER_GREEN)
		_draw_text(str(item.get("title", "内部更新")), rect.position + Vector2(62, 25), 13, INK, HORIZONTAL_ALIGNMENT_LEFT, 408)
		_draw_text(str(item.get("meta", "全员 · 本周")), rect.position + Vector2(62, 47), 10, MUTED, HORIZONTAL_ALIGNMENT_LEFT, 408)
		_draw_text(str(item.get("metric", "")), rect.position + Vector2(490, 34), 12, PAPER_GREEN, HORIZONTAL_ALIGNMENT_RIGHT, 172)
		draw_line(Vector2(queue_sheet.position.x + 14, rect.end.y), Vector2(queue_sheet.end.x - 14, rect.end.y), COLD_30, 1.0)
	if _announcement_page_count() > 1:
		_draw_page_button(_announcement_prev_rect(), "‹", announcement_page > 0)
		_draw_page_counter(_announcement_page_counter_rect(), announcement_page + 1, _announcement_page_count())
		_draw_page_button(_announcement_next_rect(), "›", announcement_page + 1 < _announcement_page_count())
	var side := Rect2(1012 + (1.0 - _reveal(0.16, 0.36)) * 12.0, 164, 232, 250)
	draw_rect(Rect2(side.position + Vector2(5, 6), side.size), Color(0.01, 0.035, 0.04, 0.14))
	draw_rect(side, COLD_10)
	draw_rect(side, COLD_40, false, 1.0)
	draw_rect(Rect2(side.position, Vector2(side.size.x, 4)), GREEN)
	_draw_text("招聘页回执", side.position + Vector2(18, 27), TYPE_META, MUTED)
	draw_line(side.position + Vector2(18, 38), side.position + Vector2(side.size.x - 18, 38), COLD_30, 1.0)
	announcement_sidebar_snapshot = _announcement_sidebar_metrics()
	_draw_display_text(str(announcement_sidebar_snapshot.get("views", "—")), side.position + Vector2(18, 86), 32, INK)
	_draw_text("本周浏览", side.position + Vector2(18, 108), 10, MUTED)
	draw_line(side.position + Vector2(18, 126), side.position + Vector2(side.size.x - 18, 126), COLD_30, 1.0)
	_draw_display_text(str(announcement_sidebar_snapshot.get("applications", "—")), side.position + Vector2(18, 169), 28, PAPER_GREEN)
	_draw_text("收到简历", side.position + Vector2(18, 191), 10, MUTED)
	_draw_text("页面状态 / 正在招人", side.position + Vector2(18, 229), 10, MUTED)
	_draw_back_button()


func _draw_second_time_event() -> void:
	var fade := 1.0 if reduced_motion else clampf(screen_time / 0.30, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, VIEW), COLD_95)
	for i in 18:
		var x := 34.0 + float((i * 97) % 1180)
		var y := 78.0 + float((i * 53) % 560)
		draw_circle(Vector2(x, y), 1.1, Color(0.55, 0.70, 0.60, 0.10))
	var panel := Rect2(88, 58, 1104, 604)
	draw_rect(Rect2(panel.position + Vector2(9, 11), panel.size), Color(0.0, 0.02, 0.025, 0.32 * fade))
	draw_rect(panel, WARM_05)
	draw_rect(panel, COLD_50, false, 1.0)
	draw_rect(Rect2(panel.position, Vector2(7, panel.size.y)), GREEN)
	draw_rect(Rect2(panel.position + Vector2(510, -5), Vector2(86, 12)), COLD_40)
	_draw_text("LANTERN / NEW GAME+", panel.position + Vector2(34, 35), 11, GREEN)
	_draw_display_text("第二次", panel.position + Vector2(34, 79), 32, INK)
	_draw_text("2024 年 3 月 · 公司只有两个人", panel.position + Vector2(190, 77), 12, MUTED)

	var scene := Rect2(panel.position + Vector2(34, 106), Vector2(654, 430))
	draw_rect(Rect2(scene.position + Vector2(5, 7), scene.size), Color(0.01, 0.04, 0.05, 0.24))
	_draw_texture_cover(art_title, scene, Color(0.80, 0.86, 0.85, 1.0), Vector2(0.54, 0.52))
	draw_rect(scene, Color(0.015, 0.05, 0.065, 0.30))
	draw_rect(Rect2(scene.position, Vector2(scene.size.x, 58)), Color(0.02, 0.07, 0.085, 0.78))
	draw_rect(Rect2(scene.position, Vector2(6, scene.size.y)), GREEN_BRIGHT)
	_draw_text("ARCHIVE / 2024 年 3 月", scene.position + Vector2(24, 27), 10, NIGHT_TEXT)
	_draw_text("两个人，两个工位。", scene.position + Vector2(24, 47), 11, COLD_30)
	var desk_centers := [
		scene.position + Vector2(146, 332),
		scene.position + Vector2(344, 332),
		scene.position + Vector2(542, 332),
	]
	# Only the two actual workstations receive ledger numbers. The middle anchor
	# remains a staging coordinate for the held-cup composition, not a third desk.
	for i in [0, 2]:
		var desk: Vector2 = desk_centers[i]
		draw_line(desk + Vector2(-52, 24), desk + Vector2(52, 24), Color(0.74, 0.86, 0.84, 0.30), 1.0)
		_draw_text_centered("01" if i == 0 else "02", Rect2(desk + Vector2(-18, 31), Vector2(36, 18)), 9, COLD_20, 2.0)
	var phase := _second_time_phase()
	var cup_position := str(model.memory.get("second_time_cup_position", "founder_desk"))
	if cup_position == "founder_desk":
		_draw_cup_icon(desk_centers[0] + Vector2(42, -18), 0.84, WARM_05, AMBER)
	elif cup_position == "window_second_desk":
		_draw_cup_icon(desk_centers[2] + Vector2(-34, -18), 0.84, WARM_05, AMBER)
		draw_line(desk_centers[2] + Vector2(-56, 12), desk_centers[2] + Vector2(18, 12), Color(0.88, 0.60, 0.35, 0.76), 1.0)
		_draw_text("靠窗第二工位", desk_centers[2] + Vector2(-58, 70), 9, TERMINAL_TEXT)
	else:
		var held_center := scene.position + Vector2(326, 166 + sin(_motion_clock() * 2.2) * 3.0)
		draw_circle(held_center, 58.0, Color(0.78, 0.52, 0.29, 0.16))
		_draw_cup_icon(held_center, 1.70, WARM_05, AMBER)
		_draw_text_centered("第一届全员团建 · 2024", Rect2(held_center - Vector2(116, -58), Vector2(232, 24)), 10, WARM_10, 3.0)
	if phase in [SECOND_TIME_PHASE_QUESTION, SECOND_TIME_PHASE_ANSWERED, SECOND_TIME_PHASE_PLACED]:
		var lin_rect := Rect2(scene.position + Vector2(500, 126), Vector2(126, 189))
		draw_texture_rect(art_lin, lin_rect, false, Color(0.86, 0.91, 0.91, 0.96))
		draw_rect(Rect2(lin_rect.position + Vector2(0, lin_rect.size.y - 27), Vector2(lin_rect.size.x, 27)), Color(0.02, 0.07, 0.085, 0.84))
		_draw_text("林越 / CTO", lin_rect.position + Vector2(10, lin_rect.size.y - 9), 9, NIGHT_TEXT)

	var copy_rect := Rect2(panel.position + Vector2(724, 116), Vector2(344, 250))
	_draw_text("交互记录", copy_rect.position, 11, MUTED)
	draw_line(copy_rect.position + Vector2(0, 13), copy_rect.position + Vector2(copy_rect.size.x, 13), WARM_40, 1.0)
	var phase_index: int = int({
		SECOND_TIME_PHASE_PRESENT: 1,
		SECOND_TIME_PHASE_HELD: 2,
		SECOND_TIME_PHASE_QUESTION: 3,
		SECOND_TIME_PHASE_ANSWERED: 4,
		SECOND_TIME_PHASE_PLACED: 5,
	}.get(phase, 1))
	_draw_text("0%d / 05" % int(phase_index), copy_rect.position + Vector2(266, 0), 10, GREEN)
	_draw_paragraph_array(_second_time_phase_copy(), Rect2(copy_rect.position + Vector2(0, 28), Vector2(copy_rect.size.x, 205)), 15, INK, 25)
	if phase == SECOND_TIME_PHASE_QUESTION:
		var choices: Array = current_event.get("choices", [])
		for i in choices.size():
			var rect := _second_time_choice_rect(i)
			var choice: Dictionary = choices[i]
			draw_rect(rect, Color(0.91, 0.91, 0.85, 0.78) if rect.has_point(mouse_position) else Color(0.94, 0.92, 0.84, 0.52))
			draw_rect(rect, GREEN if rect.has_point(mouse_position) else COLD_30, false, 1.0)
			draw_rect(Rect2(rect.position, Vector2(4, rect.size.y)), GREEN if rect.has_point(mouse_position) else COLD_40)
			if _focus_is("event_choices:", i):
				draw_rect(rect.grow(4.0), GREEN_BRIGHT, false, 2.0)
			_draw_text("%d" % (i + 1), rect.position + Vector2(16, 28), 11, MUTED)
			_draw_text(_choice_display_label(choice), rect.position + Vector2(45, 29), 14, INK)
	else:
		var continue_rect := _second_time_continue_rect()
		var continue_label := _second_time_continue_label().replace("ENTER", _gamepad_shortcut("A", "ENTER"))
		_draw_ledger_button(continue_rect, continue_label, "", "primary", true, _focus_is("event_continue:", 0))
	_draw_text("%s / 点击均可完成当前动作" % _gamepad_shortcut("A", "ENTER"), panel.position + Vector2(762, 554), 10, MUTED)


func _second_time_phase_copy() -> Array[String]:
	match _second_time_phase():
		SECOND_TIME_PHASE_HELD:
			return ["你把它拿起来看了看。", "杯身印着『第一届全员团建·2024』。团建还没办。"]
		SECOND_TIME_PHASE_QUESTION:
			return ["你把它放回原位。", "林越从门口进来，看到桌上的杯子。", "『哪来的？』"]
		SECOND_TIME_PHASE_ANSWERED:
			return ["两个选项都是『不知道』。", "她耸耸肩，去开电脑了。"]
		SECOND_TIME_PHASE_PLACED:
			return ["你把杯子放在了工位靠窗第二个的位置上。", "那个位置现在是空的。"]
		_:
			return _to_string_array(current_event.get("body", []))


func _second_time_continue_label() -> String:
	match _second_time_phase():
		SECOND_TIME_PHASE_PRESENT: return "拿起杯子查看   ENTER"
		SECOND_TIME_PHASE_HELD: return "放回原位   ENTER"
		SECOND_TIME_PHASE_ANSWERED: return "放到靠窗第二工位   ENTER"
		SECOND_TIME_PHASE_PLACED: return "继续第一周   ENTER"
	return "继续   ENTER"


func _draw_cup_icon(center: Vector2, scale: float, fill: Color, accent: Color) -> void:
	var top_left := center + Vector2(-15, -18) * scale
	var top_right := center + Vector2(15, -18) * scale
	var bottom_right := center + Vector2(12, 18) * scale
	var bottom_left := center + Vector2(-12, 18) * scale
	draw_colored_polygon(PackedVector2Array([top_left, top_right, bottom_right, bottom_left]), fill)
	draw_line(top_left, top_right, accent, maxf(1.0, 1.6 * scale))
	draw_line(center + Vector2(-12, -14) * scale, center + Vector2(12, -14) * scale, Color(accent, 0.38), maxf(1.0, scale))
	draw_arc(center + Vector2(17, 0) * scale, 9.0 * scale, -PI * 0.5, PI * 0.5, 14, fill, maxf(2.0, 4.0 * scale), true)
	draw_circle(center + Vector2(0, 12) * scale, 3.0 * scale, Color("#76513c"))
	draw_line(center + Vector2(-11, 20) * scale, center + Vector2(11, 20) * scale, Color(0.01, 0.03, 0.03, 0.28), maxf(1.0, 2.2 * scale))


func _draw_event() -> void:
	if _is_first_day_prologue():
		_draw_first_day_prologue()
		return
	if _is_second_time_event():
		_draw_second_time_event()
		return
	_draw_art_background(_event_scene_texture(), Color(0.94, 0.97, 0.98, 1.0))
	var fade := 1.0 if reduced_motion else clampf(screen_time / 0.28, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.04, 0.055, 0.12 * fade))
	draw_rect(Rect2(0, 0, 820, 192), Color(0.01, 0.035, 0.05, 0.42 * fade))
	var reveal := _reveal(0.0, 0.32)
	var panel := Rect2(54, 290 + (1.0 - reveal) * 18.0, 724, 390)
	_draw_panel(Rect2(panel.position + Vector2(5, 7), panel.size), Color(0.01, 0.035, 0.045, 0.24), Color.TRANSPARENT, 2.0, 0.0)
	_draw_panel(panel, Color(0.91, 0.86, 0.75, 0.965), COLD_40, 2.0, 1.0)
	draw_line(panel.position + Vector2(30, 24), panel.position + Vector2(panel.size.x - 30, 24), Color(0.29, 0.34, 0.32, 0.24), 1.0)
	_draw_event_scene_header(panel)
	var pages := _event_body_pages()
	var body: Array = pages[clampi(current_event_page, 0, maxi(0, pages.size() - 1))] if not pages.is_empty() else []
	if _event_page_is_silence():
		_draw_event_silence(panel)
	else:
		_draw_paragraph_array(body, Rect2(panel.position + Vector2(34, 48), Vector2(656, 166)), 15, INK, 25)
	var choices: Array = current_event.get("choices", [])
	if choices.is_empty() or not _event_choices_visible():
		if _event_page_can_advance():
			var continue_button := _event_continue_rect()
			var continue_label := "下一页" if current_event_page + 1 < pages.size() else "继续"
			_draw_ledger_button(continue_button, continue_label, _gamepad_shortcut("A", "ENTER"), "primary", true, _focus_is("event_continue:", 0))
	else:
		for i in choices.size():
			var choice: Dictionary = choices[i]
			var rect := _event_choice_rect(i)
			var visual := _event_choice_visual_contract(choice)
			var choice_fill: Color = visual["fill"]
			var choice_border: Color = visual["border"]
			var choice_index_color: Color = visual["index_color"]
			var choice_label_color: Color = visual["label_color"]
			draw_rect(rect, Color(choice_fill, 0.48))
			draw_line(Vector2(rect.position.x, rect.end.y), rect.end, choice_border, 1.0)
			draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), choice_border)
			if _focus_is("event_choices:", i):
				_draw_panel(rect.grow(4.0), Color.TRANSPARENT, GREEN_BRIGHT, RADIUS_CONTROL + 3.0, 2.0)
			_draw_text("%d" % (i + 1), rect.position + Vector2(16, 29), int(visual["index_font_size"]), choice_index_color)
			_draw_multiline(_choice_display_label(choice), Rect2(rect.position + Vector2(45, 8), Vector2(rect.size.x - 58, rect.size.y - 16)), int(visual["label_font_size"]), choice_label_color, float(visual["line_height"]))
	_draw_event_sidebar(panel)


func _draw_first_day_prologue() -> void:
	_draw_art_background(art_title, Color(0.72, 0.79, 0.84, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.035, 0.055, 0.34))
	_draw_first_day_rain()
	# The cold open is staged as a conversation in the room, not another archive
	# modal. Opaque reading planes keep every line independent from the painting.
	var top_bar := Rect2(0, 0, VIEW.x, 112)
	draw_rect(top_bar, Color(0.018, 0.055, 0.072, 0.88))
	draw_line(Vector2(0, top_bar.end.y), Vector2(VIEW.x, top_bar.end.y), Color(0.38, 0.62, 0.62, 0.44), 1.0)
	_draw_text("DAY ONE  /  21:47  /  RAIN", Vector2(54, 36), 12, TERMINAL_TEXT)
	_draw_display_text("第一天", Vector2(52, 82), 34, COLD_05)
	_draw_text("两个人 · 一张显卡 · 十周现金", Vector2(178, 80), 13, COLD_20)
	var skip_rect := _first_day_skip_rect()
	_draw_ledger_button(skip_rect, "再次确认跳过" if opening_skip_confirm_pending else "跳过序章", _gamepad_shortcut("B", "K"), "danger" if opening_skip_confirm_pending else "quiet", true)

	var phases := _first_day_phases()
	var phase_index := clampi(current_event_page, 0, maxi(0, phases.size() - 1))
	var phase := _first_day_phase()
	var panel_reveal := 1.0 if reduced_motion else _ease_out_cubic(clampf(event_page_elapsed / 0.26, 0.0, 1.0))
	var panel := Rect2(54, 148 + (1.0 - panel_reveal) * 10.0, 730, 520)
	_draw_panel(Rect2(panel.position + Vector2(7, 9), panel.size), Color(0.0, 0.02, 0.03, 0.34), Color.TRANSPARENT, 4.0, 0.0)
	_draw_panel(panel, Color(0.925, 0.925, 0.875, 0.985), COLD_40, 4.0, 1.0)
	draw_rect(Rect2(panel.position, Vector2(6, panel.size.y)), GREEN)
	_draw_text(str(phase.get("speaker", "林越")), panel.position + Vector2(34, 38), 12, PAPER_GREEN)
	_draw_text("现场 / 不留档的部分", panel.position + Vector2(454, 38), 12, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 238)
	_draw_display_text(str(phase.get("title", "第一天")), panel.position + Vector2(32, 84), 28, INK)
	draw_line(panel.position + Vector2(32, 102), panel.position + Vector2(panel.size.x - 32, 102), COLD_40, 1.0)
	var choices := _first_day_choices()
	var phase_ready := _first_day_ready()
	var body_height := 154.0 if not choices.is_empty() else 314.0
	_draw_first_day_paragraphs(_first_day_phase_body(), Rect2(panel.position + Vector2(34, 122), Vector2(660, body_height)))

	if not phase_ready:
		var waiting_width := 46.0 + float(_first_day_phase_body().size()) * 12.0
		draw_line(panel.position + Vector2(panel.size.x - waiting_width - 34.0, panel.size.y - 45.0), panel.position + Vector2(panel.size.x - 34.0, panel.size.y - 45.0), Color(PAPER_GREEN, 0.34), 2.0)
	elif choices.is_empty():
		var continue_rect := _first_day_continue_rect()
		var continue_label := str(phase.get("continue", "继续"))
		_draw_ledger_button(continue_rect, continue_label, _gamepad_shortcut("A", "ENTER"), "primary", true, _focus_is("opening_continue:", 0))
	else:
		for i in choices.size():
			var response_value = choices[i]
			if not response_value is Dictionary:
				continue
			var response := Dictionary(response_value)
			var rect := _first_day_choice_rect(i)
			var hovered := rect.has_point(mouse_position)
			var focused := _focus_is("opening_choices:", i)
			draw_rect(rect, Color(0.23, 0.49, 0.45, 0.16 if hovered or focused else 0.055))
			draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), GREEN if hovered or focused else COLD_40)
			draw_line(Vector2(rect.position.x, rect.end.y), rect.end, COLD_30, 1.0)
			if focused:
				_draw_panel(rect.grow(3.0), Color.TRANSPARENT, GREEN_BRIGHT, 4.0, 2.0)
			_draw_text("%d" % (i + 1), rect.position + Vector2(16, 30), 12, PAPER_GREEN)
			_draw_text(str(response.get("label", "回应")), rect.position + Vector2(48, 30), 14, INK)

	_draw_text("FIRST DAY  %02d / %02d" % [phase_index + 1, maxi(1, phases.size())], panel.position + Vector2(34, panel.size.y - 20), 11, MUTED)
	for tick in phases.size():
		var tick_rect := Rect2(panel.position + Vector2(182 + tick * 28, panel.size.y - 27), Vector2(18, 3))
		draw_rect(tick_rect, GREEN if tick <= phase_index else COLD_30)
	_draw_first_day_portrait(phase_index)


func _draw_first_day_rain() -> void:
	var clock := _motion_clock()
	for index in 34:
		var x := fposmod(float(index * 83 + 17) + clock * (46.0 + float(index % 5) * 8.0), 805.0)
		var y := fposmod(float(index * 47 + 23) + clock * (92.0 + float(index % 7) * 9.0), 620.0) - 40.0
		var length := 9.0 + float(index % 4) * 3.0
		draw_line(Vector2(x, y), Vector2(x - 3.0, y + length), Color(0.67, 0.82, 0.85, 0.12), 1.0)


func _draw_first_day_paragraphs(paragraphs: Array[String], rect: Rect2) -> void:
	var y := rect.position.y
	for paragraph_index in paragraphs.size():
		var alpha := 1.0 if reduced_motion else clampf((event_page_elapsed - float(paragraph_index) * 0.24) / 0.34, 0.0, 1.0)
		var lines := _wrap_text_px(paragraphs[paragraph_index], rect.size.x, 15)
		for line in lines:
			if y + 23.0 > rect.end.y:
				return
			_draw_text(line, Vector2(rect.position.x, y + 15), 15, Color(INK, alpha))
			y += 23.0
		y += 8.0


func _draw_first_day_portrait(phase_index: int) -> void:
	var breath := 0.0 if reduced_motion else sin(_motion_clock() * 1.45) * 1.4
	var frame := Rect2(850, 128 + breath, 350, 508)
	_draw_panel(Rect2(frame.position + Vector2(7, 9), frame.size), Color(0.0, 0.02, 0.03, 0.38), Color.TRANSPARENT, 4.0, 0.0)
	_draw_panel(frame, Color("#142a33"), Color("#76908f"), 4.0, 1.0)
	var portrait_rect := Rect2(frame.position + Vector2(8, 8), frame.size - Vector2(16, 54))
	_draw_texture_cover(art_lin, portrait_rect, Color(0.83, 0.88, 0.87, 1.0), Vector2(0.5, 0.34))
	draw_rect(portrait_rect, Color(0.01, 0.045, 0.06, 0.08))
	# A tiny breathing/steam layer keeps the portrait present without turning the
	# restrained illustration into a puppet animation.
	if not reduced_motion:
		for steam in 2:
			var steam_phase := fposmod(_motion_clock() * 0.34 + float(steam) * 0.5, 1.0)
			var steam_center := frame.position + Vector2(150 + steam * 10, 256 - steam_phase * 24.0)
			draw_arc(steam_center, 7.0 + steam_phase * 3.0, -2.7, -0.35, 12, Color(0.84, 0.91, 0.88, (1.0 - steam_phase) * 0.22), 1.0, true)
	draw_rect(Rect2(frame.position + Vector2(8, frame.size.y - 46), Vector2(frame.size.x - 16, 38)), Color(0.025, 0.09, 0.105, 0.94))
	draw_circle(frame.position + Vector2(24, frame.size.y - 27), 4.0, GREEN_BRIGHT)
	_draw_display_text("林越", frame.position + Vector2(38, frame.size.y - 20), 16, Color("#eef3ef"))
	_draw_text("CTO · 就在这里", frame.position + Vector2(102, frame.size.y - 21), 12, Color("#b8ccca"))
	if phase_index >= 3:
		_draw_first_day_terminal_card(frame, phase_index)


func _draw_first_day_terminal_card(frame: Rect2, phase_index: int) -> void:
	var card := Rect2(frame.position + Vector2(20, 326), Vector2(frame.size.x - 40, 92))
	_draw_panel(card, Color(0.018, 0.055, 0.064, 0.94), COLD_50, 3.0, 1.0)
	_draw_text("LANTERN / QA-047", card.position + Vector2(14, 22), 11, GREEN_BRIGHT)
	var state_color := RED
	var state := "等待 7.0 秒后给出回答"
	if phase_index == 4:
		state = "ERR_POWER_LOST · 输出中断"
	elif phase_index == 5:
		state = "POWER STRIP · 等待人工复位"
	elif phase_index >= 6:
		state = "OK · 暂时失去了表达能力"
		state_color = GREEN_BRIGHT
	draw_circle(card.position + Vector2(18, 48), 4.0, state_color)
	_draw_multiline(state, Rect2(card.position + Vector2(32, 34), Vector2(card.size.x - 46, 46)), 12, COLD_10, 20)
	if phase_index >= 6:
		var pulse := 1.0 if reduced_motion else 0.66 + sin(_motion_clock() * 5.0) * 0.22
		draw_rect(Rect2(card.position + Vector2(14, 74), Vector2((card.size.x - 28) * pulse, 2)), Color(GREEN_BRIGHT, 0.70))


func _first_day_visual_contract() -> Dictionary:
	return {
		"surface": Rect2(54, 148, 730, 520),
		"body": Rect2(88, 270, 660, 154),
		"choices": [_first_day_choice_rect(0), _first_day_choice_rect(1), _first_day_choice_rect(2)],
		"continue": _first_day_continue_rect(),
		"skip": _first_day_skip_rect(),
		"minimum_target": UI_MIN_TARGET,
	}


func _draw_event_scene_header(panel: Rect2) -> void:
	var kicker := str(current_event.get("kicker", "第 %d 周" % int(model.total_week)))
	_draw_text(kicker, Vector2(58, 74), 12, TERMINAL_TEXT)
	_draw_display_text(str(current_event.get("title", "事件")), Vector2(56, 132), 34, COLD_05)
	draw_line(Vector2(58, 154), Vector2(690, 154), Color(0.55, 0.76, 0.76, 0.52), 1.0)
	_draw_text("记录会留下；解释未必会。", Vector2(58, 178), 12, COLD_20)
	_draw_text("第 %d / %d 页" % [current_event_page + 1, maxi(1, _event_body_pages().size())], panel.position + Vector2(panel.size.x - 118, 17), 12, MUTED)


func _draw_event_sidebar(panel: Rect2) -> void:
	var rect := Rect2(844, 142, 330, 510)
	_draw_panel(Rect2(rect.position + Vector2(5, 7), rect.size), Color(0.01, 0.035, 0.045, 0.24), Color.TRANSPARENT, 2.0, 0.0)
	_draw_panel(rect, Color(0.92, 0.92, 0.86, 0.965), COLD_40, 2.0, 1.0)
	_draw_text("决定备忘", rect.position + Vector2(28, 42), 12, GREEN)
	_draw_display_text("留档", rect.position + Vector2(26, 84), 24, INK)
	draw_line(rect.position + Vector2(26, 104), rect.position + Vector2(rect.size.x - 26, 104), COLD_40, 1.0)
	if _current_event_uses_lin_portrait() and art_lin != null:
		var portrait_frame := Rect2(rect.position + Vector2(48, 126), Vector2(234, 300))
		draw_rect(Rect2(portrait_frame.position + Vector2(4, 5), portrait_frame.size), Color(0.03, 0.06, 0.06, 0.18))
		draw_rect(portrait_frame, COLD_80)
		var portrait_art_rect := Rect2(portrait_frame.position + Vector2(30, 0), Vector2(178, 260))
		draw_texture_rect(art_lin, portrait_art_rect, false, Color(0.92, 0.94, 0.91, 0.98))
		draw_line(portrait_frame.position + Vector2(14, 263), portrait_frame.position + Vector2(portrait_frame.size.x - 14, 263), COLD_40, 1.0)
		_draw_display_text("林越", portrait_frame.position + Vector2(16, 289), 16, Color.WHITE)
		_draw_text("联合创始人 / CTO", portrait_frame.position + Vector2(76, 289), 12, COLD_20)
	else:
		_draw_multiline("提交之后，这次决定会进入长期记录。系统保存结果，不替你解释动机。", Rect2(rect.position + Vector2(28, 132), Vector2(rect.size.x - 56, 112)), 15, INK, 26)
		_draw_folio_stamp(Rect2(rect.position + Vector2(92, 292), Vector2(146, 64)), "等待决定", GREEN, -0.052)
		draw_line(rect.position + Vector2(28, 404), rect.position + Vector2(rect.size.x - 28, 404), COLD_30, 1.0)
		_draw_text("第 %d 周 · %s" % [int(model.total_week), _chapter_label()], rect.position + Vector2(28, 438), 12, MUTED)
	_draw_text("档案编号  %04d" % (abs(str(current_event.get("id", "")).hash()) % 10000), rect.position + Vector2(28, rect.size.y - 28), 12, MUTED)


func _current_event_uses_lin_portrait() -> bool:
	var event_id := str(current_event.get("id", ""))
	return event_id == "garage_opening" or event_id.begins_with("lin_scene_") or event_id == "lin_last_visit"


func _event_scene_texture() -> Texture2D:
	var event_id := str(current_event.get("id", ""))
	if event_id == "first_investor_meeting":
		return art_cafe
	if event_id == "garage_opening" or event_id.begins_with("lin_scene_"):
		return art_title
	if event_id.contains("night") or event_id.contains("layoff") or event_id.contains("last") or event_id.contains("final"):
		return art_office_night
	return art_office_day


func _draw_result() -> void:
	var reveal := _reveal(0.0, 0.26)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.035, 0.045, 0.16 * reveal))
	draw_set_transform(Vector2(0, (1.0 - reveal) * 14.0))
	# Settlement lands as a printed receipt on the open dossier, rather than a
	# modal detached from the world underneath it.
	var panel := Rect2(250, 80, 780, 558)
	draw_rect(Rect2(panel.position + Vector2(10, 11), panel.size), Color(0.01, 0.03, 0.035, 0.24))
	draw_rect(panel, Color(0.95, 0.925, 0.84, 0.98))
	draw_rect(panel, WARM_40, false, 1.0)
	draw_rect(Rect2(panel.position, Vector2(6, panel.size.y)), GREEN)
	for notch in range(24):
		var notch_y := panel.position.y + 13.0 + notch * 22.5
		draw_circle(Vector2(panel.end.x, notch_y), 2.2, COLD_50)
	_draw_text("SETTLEMENT RECEIPT  /  %02d" % int(model.total_week), panel.position + Vector2(34, 36), 11, GREEN)
	_draw_text("公司档案 · 本周结算", panel.position + Vector2(panel.size.x - 250, 36), 11, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 212)
	draw_line(panel.position + Vector2(34, 51), panel.position + Vector2(panel.size.x - 34, 51), WARM_40, 1.0)
	_draw_display_text(result_title, panel.position + Vector2(34, 94), 28, INK)
	var pages := _result_pages()
	var page: Array = pages[clampi(result_page, 0, maxi(0, pages.size() - 1))]
	_draw_paragraph_array(_to_string_array(page), Rect2(panel.position + Vector2(34, 124), Vector2(panel.size.x - 68, 278)), 16, INK, 27)
	draw_line(panel.position + Vector2(34, panel.size.y - 83), panel.position + Vector2(panel.size.x - 34, panel.size.y - 83), WARM_40, 1.0)
	var result_hint := "下一页  %d / %d · %s" % [result_page + 1, pages.size(), _gamepad_shortcut("A", "ENTER")] if pages.size() > 1 else "%s / 点击继续" % _gamepad_shortcut("A", "ENTER")
	_draw_text("RECEIVED", panel.position + Vector2(34, panel.size.y - 42), 10, MUTED)
	_draw_folio_stamp(Rect2(panel.end.x - 190, panel.end.y - 72, 146, 46), result_hint, GREEN, -0.018)
	draw_set_transform(Vector2.ZERO)


func _draw_signature() -> void:
	var shade := 1.0 if reduced_motion else clampf(screen_time / 0.18, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.02, 0.04, 0.04, 0.26 * shade))
	var panel := Rect2(272, 106, 736, 506)
	draw_rect(Rect2(panel.position + Vector2(10, 12), panel.size), Color(0.0, 0.02, 0.025, 0.28))
	draw_rect(panel, Color(0.95, 0.925, 0.84, 0.99))
	draw_rect(panel, WARM_40, false, 1.0)
	draw_rect(Rect2(panel.position, Vector2(7, panel.size.y)), GREEN)
	draw_rect(Rect2(panel.position + Vector2(322, -5), Vector2(92, 12)), COLD_30)
	_draw_text("LANTERN / APPROVAL  ·  REGISTER %02d" % int(model.total_week), panel.position + Vector2(38, 41), 11, GREEN)
	_draw_display_text("请签署", panel.position + Vector2(38, 91), 30, INK)
	_draw_text("本周自动生成的行政事项已准备完毕。", panel.position + Vector2(38, 123), 13, MUTED)
	var paper := Rect2(panel.position + Vector2(38, 158), Vector2(panel.size.x - 76, 218))
	draw_line(paper.position, Vector2(paper.end.x, paper.position.y), WARM_40, 1.0)
	draw_line(Vector2(paper.position.x, paper.end.y), paper.end, WARM_40, 1.0)
	draw_line(paper.position + Vector2(0, 78), paper.position + Vector2(paper.size.x, 78), WARM_40, 1.0)
	_draw_text("批准人", paper.position + Vector2(22, 32), 10, MUTED)
	_draw_text("创始人", paper.position + Vector2(22, 59), 13, INK)
	_draw_text("签名", paper.position + Vector2(22, 105), 10, MUTED)
	draw_line(paper.position + Vector2(22, 178), paper.position + Vector2(paper.size.x - 22, 178), COLD_30, 1.0)
	var progress := 1.0 if reduced_motion else _ease_out_cubic(clampf((screen_time - 0.18) / 1.05, 0.0, 1.0))
	_draw_signature_stroke(paper.position + Vector2(78, 126), progress)
	if progress >= 1.0:
		_draw_text("已签署 · 刚刚", paper.position + Vector2(paper.size.x - 132, 202), 10, PAPER_GREEN)
		_draw_folio_stamp(Rect2(panel.end.x - 178, panel.position.y + 48, 132, 46), "已批准", GREEN, -0.025)
	var approval_footer := _signature_continue_rect()
	var approval_ready := reduced_motion or screen_time >= 1.25
	_draw_ledger_button(approval_footer, "完成并归档" if approval_ready else "正在签署…", _gamepad_shortcut("A", "ENTER") if approval_ready else "", "primary", approval_ready)


func _draw_signature_stroke(origin: Vector2, progress: float) -> void:
	var points := PackedVector2Array()
	for i in 72:
		var t := float(i) / 71.0
		var x := t * 420.0
		var y := sin(t * TAU * 1.55) * (28.0 - t * 12.0) + sin(t * TAU * 4.1) * 7.0
		if t > 0.64:
			y += (t - 0.64) * 82.0
		points.append(origin + Vector2(x, y))
	var visible_count := clampi(int(ceil(progress * float(points.size()))), 0, points.size())
	if visible_count >= 2:
		draw_polyline(points.slice(0, visible_count), Color("#244d3c"), 2.6, true)
	if progress > 0.72:
		var flourish_progress := clampf((progress - 0.72) / 0.28, 0.0, 1.0)
		var flourish := PackedVector2Array()
		for i in 30:
			var t := float(i) / 29.0
			flourish.append(origin + Vector2(240.0 + t * 230.0, 33.0 - sin(t * PI) * 17.0))
		var flourish_count := clampi(int(ceil(flourish_progress * float(flourish.size()))), 0, flourish.size())
		if flourish_count >= 2:
			draw_polyline(flourish.slice(0, flourish_count), Color("#244d3c"), 2.0, true)


func _ease_out_cubic(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)


func _reveal(delay: float = 0.0, duration: float = 0.3) -> float:
	if reduced_motion:
		return 1.0
	return _ease_out_cubic(clampf((screen_time - delay) / maxf(0.01, duration), 0.0, 1.0))


func _motion_clock() -> float:
	return 0.0 if reduced_motion else elapsed


func _choice_display_label(choice: Dictionary) -> String:
	var label := str(choice.get("label", "选项"))
	if model == null or not bool(model.flags.get("options_in_assistant_voice", false)) or bool(choice.get("ai", false)):
		return label
	var fingerprint := "%s:%s" % [str(current_event.get("id", "event")), str(choice.get("id", label))]
	for punctuation in ["。", "！", "？", ".", "!", "?"]:
		label = label.trim_suffix(punctuation)
	var endings := [
		"；确认后，相关记录会一并更新。",
		"；提交后，后续安排将按此继续。",
		"；我会据此同步，需要调整的事项。"
	]
	return label + str(endings[absi(fingerprint.hash()) % endings.size()])


func _event_choice_visual_contract(choice: Dictionary) -> Dictionary:
	# The author-stage accent is copy-only. Keeping every visual token in this
	# flag-independent contract makes a future accidental style cue testable.
	var is_ai := bool(choice.get("ai", false)) or str(choice.get("label", "")).contains("让它来写")
	return {
		"fill": COLD_05 if is_ai else SURFACE,
		"border": GREEN if is_ai else LINE,
		"radius": 7.0,
		"border_width": 1.0,
		"index_font_size": 11,
		"index_color": MUTED,
		"label_font_size": 13,
		"label_color": GREEN if is_ai else INK,
		"line_height": 16.0,
		"hover_variant": false,
		"tooltip": "",
		"animation": "none",
	}


func _elevator_floor_button_visual_contract() -> Dictionary:
	# Every floor label, including the anomalous extra floor, is rendered by the
	# same non-interactive path with no tooltip, pulse, hover, or reveal of its own.
	return {
		"size": Vector2(42, 42),
		"fill": COLD_05,
		"border": COLD_30,
		"radius": 4.0,
		"border_width": 1.0,
		"font_size": 12,
		"font_color": INK,
		"text_inset": 2.0,
		"interactive": false,
		"hover_variant": false,
		"tooltip": "",
		"animation": "none",
	}


func _draw_night_shift() -> void:
	_draw_art_background(art_office_night, Color(0.82, 0.90, 0.92, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.045, 0.06, 0.52))
	for i in 6:
		draw_rect(Rect2(0, 80 + i * 104, 1280, 1), Color(0.34, 0.53, 0.58, 0.08))
	_draw_text("夜班 / %s" % str(current_night.get("title", "办公室")), Vector2(44, 29), 13, NIGHT_TEXT)
	var intro_surface := _night_intro_surface_lines()
	_draw_text(str(intro_surface.get("subtitle", "")), Vector2(44, 50), 12, NIGHT_MUTED)
	_draw_text(str(intro_surface.get("opening", "")), Vector2(44, 71), 12, COLD_20)
	var night_hint_plate := Rect2(NIGHT_HINT_SAFE_RECT.position - Vector2(10, 5), NIGHT_HINT_SAFE_RECT.size + Vector2(20, 10))
	_draw_panel(night_hint_plate, Color(0.025, 0.075, 0.09, 0.92), Color(0.35, 0.50, 0.53, 0.34), 3.0, 1.0)
	_draw_text("方向键 / D-pad 选择 · E / A 交互 · 鼠标亦可", NIGHT_HINT_SAFE_RECT.position + Vector2(0, 20), 12, NIGHT_TEXT, HORIZONTAL_ALIGNMENT_RIGHT, NIGHT_HINT_SAFE_RECT.size.x)
	var floor := Rect2(108, 92, 1064, 492)
	_draw_panel(Rect2(floor.position + Vector2(0, 8), floor.size), Color(0.0, 0.02, 0.03, 0.32), Color.TRANSPARENT, 8.0, 0.0)
	_draw_panel(floor, Color(0.035, 0.095, 0.12, 0.88), COLD_60, 8.0, 1.0)
	# Minimal office floor plan: systems, not spectacle.
	for x in [300.0, 540.0, 780.0, 1010.0]:
		draw_line(Vector2(x, 92), Vector2(x, 584), Color(0.22, 0.37, 0.41, 0.52), 1.0)
	for y in [258.0, 422.0]:
		draw_line(Vector2(108, y), Vector2(1172, y), Color(0.22, 0.37, 0.41, 0.52), 1.0)
	_draw_night_tone_fixtures()
	# The cursor is a door-access trace, not an avatar. Nearby ceiling zones wake
	# as it moves and the already-passed zones fall dark again.
	for zone in 7:
		var zone_center := Vector2(160.0 + zone * 160.0, 340.0)
		var distance := absf(zone_center.x - night_player_position.x)
		var light_strength := clampf(1.0 - distance / 260.0, 0.0, 1.0)
		draw_rect(Rect2(zone_center - Vector2(68, 222), Vector2(136, 444)), Color(0.36, 0.62, 0.68, 0.018 + light_strength * 0.050))
	draw_circle(night_player_position, 15.0 + sin(_motion_clock() * 2.8) * 2.0, Color(0.40, 0.72, 0.78, 0.08))
	draw_circle(night_player_position, 9.0, NIGHT_MUTED)
	draw_circle(night_player_position, 3.0, COLD_10)
	for object_index in night_objects.size():
		var object: Dictionary = night_objects[object_index]
		var rect := Rect2(object.get("rect", Rect2()))
		var seen := night_seen.has(str(object.get("id", "")))
		var focused := object_index == night_focused_object_index
		var object_pulse := (sin(_motion_clock() * 1.8 + float(str(object.get("id", "")).hash() % 9)) + 1.0) * 0.5
		var object_border := BLUE if focused else (GREEN_BRIGHT if seen else COLD_60.lerp(BLUE, object_pulse * 0.18))
		_draw_night_object_tile(object, rect, seen, object_border)
		if focused:
			_draw_panel(rect.grow(4.0), Color.TRANSPARENT, BLUE, 9.0, 2.0)
		var progress := _night_object_progress_label(str(object.get("id", "")))
		if not progress.is_empty():
			_draw_text_centered(progress, Rect2(rect.position + Vector2(0, rect.size.y - 16), Vector2(rect.size.x, 14)), 10, GREEN_BRIGHT if seen else COLD_40, 1.0)
	if not result_lines.is_empty():
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.02, 0.02, 0.58))
		var modal := Rect2(256, 112, 768, 484)
		draw_rect(Rect2(modal.position + Vector2(8, 10), modal.size), Color(0.0, 0.01, 0.02, 0.30))
		draw_rect(modal, COLD_95)
		draw_rect(modal, COLD_60, false, 1.0)
		draw_rect(Rect2(modal.position, Vector2(6, modal.size.y)), GREEN_BRIGHT.darkened(0.18))
		draw_rect(Rect2(modal.position + Vector2(332, -5), Vector2(104, 12)), COLD_70)
		_draw_text("现场检查记录 / 夜班", modal.position + Vector2(modal.size.x - 266, 35), TYPE_META, COLD_50, HORIZONTAL_ALIGNMENT_RIGHT, 234)
		_draw_text("【%s】" % result_title, modal.position + Vector2(30, 44), 14, GREEN_BRIGHT)
		draw_line(modal.position + Vector2(30, 58), modal.position + Vector2(modal.size.x - 30, 58), COLD_70, 1.0)
		var active_visual_id := str(night_interaction.active_object_id) if night_interaction != null else ""
		var has_detail_visual := active_visual_id in ["whiteboard", "pothos", "window_desk", "meeting_room_d", "terminal", "corridor", "fridge", "mug"]
		var copy_width := 404.0 if has_detail_visual else modal.size.x - 60.0
		_draw_paragraph_array(result_lines, Rect2(modal.position + Vector2(30, 68), Vector2(copy_width, modal.size.y - 150)), 16, NIGHT_TEXT, 27)
		if has_detail_visual:
			var detail_rect := Rect2(modal.position + Vector2(462, 68), Vector2(274, 272))
			draw_rect(detail_rect, COLD_99)
			draw_rect(detail_rect, MUTED, false, 1.0)
			draw_rect(Rect2(detail_rect.position, Vector2(detail_rect.size.x, 4)), COLD_50)
			_draw_night_authored_visual(active_visual_id, detail_rect.grow(-10.0), true)
		_draw_ledger_button(_night_modal_close_rect(), "收起检查记录", _gamepad_shortcut("A / B", "ENTER"), "night", true, true)
	else:
		var exit_button := _night_exit_rect()
		_draw_ledger_button(exit_button, "锁门离开" if _night_complete() else "门禁：尚未巡检", _gamepad_shortcut("A", "E") if _night_complete() else "", "night", _night_complete())
		if night_interaction != null and night_interaction.terminal_accepts_command():
			_draw_text("终端已聚焦 · X / Ctrl+C 中断 · Enter 提交", Vector2(802, 613), 12, COLD_40)


func _night_tone_fixture_contract() -> Dictionary:
	return {
		"microwave": {
			"rect": Rect2(914, 116, 118, 66),
			"clock": "--:--",
			"interactive": false,
			"sound": "none",
		},
		"abandoned_monitor": {
			"rect": Rect2(356, 302, 142, 82),
			"line": "今天先做到这里。",
			"interactive": false,
		},
		"plant_object_id": "pothos",
	}


func _night_intro_surface_lines() -> Dictionary:
	var intro: Array = current_night.get("intro", [])
	return {
		"subtitle": str(current_night.get("subtitle", "")),
		"opening": str(intro[0]) if not intro.is_empty() else "",
	}


func _draw_night_tone_fixtures() -> void:
	var fixtures := _night_tone_fixture_contract()
	var microwave: Dictionary = fixtures["microwave"]
	var microwave_rect: Rect2 = microwave["rect"]
	_draw_panel(microwave_rect, Color("#c8cfcb"), Color("#65716c"), 3.0, 1.0)
	var microwave_window := Rect2(microwave_rect.position + Vector2(8, 11), Vector2(73, 42))
	_draw_panel(microwave_window, Color("#26302d"), Color("#818b86"), 2.0, 1.0)
	_draw_text(str(microwave["clock"]), microwave_rect.position + Vector2(86, 26), 10, Color("#335f4a"))
	for button_y in [34.0, 44.0, 54.0]:
		draw_circle(microwave_rect.position + Vector2(94, button_y), 1.7, Color("#68736e"))
	var monitor: Dictionary = fixtures["abandoned_monitor"]
	var monitor_rect: Rect2 = monitor["rect"]
	_draw_panel(monitor_rect, Color("#202a27"), Color("#4d5d56"), 3.0, 1.0)
	_draw_text(str(monitor["line"]), monitor_rect.position + Vector2(10, 25), 10, Color("#8ca697"))
	draw_rect(Rect2(monitor_rect.position + Vector2(10, 36), Vector2(92, 1)), Color("#62786b"))


func _draw_night_object_tile(object: Dictionary, rect: Rect2, seen: bool, border: Color) -> void:
	var hovered := rect.has_point(mouse_position)
	_draw_panel(rect, COLD_80 if hovered else INK, border, 5.0, 1.0)
	var object_id := str(object.get("id", ""))
	draw_rect(Rect2(rect.position + Vector2(1, rect.size.y - 35), Vector2(rect.size.x - 2, 34)), Color(0.025, 0.075, 0.09, 0.86))
	_draw_night_authored_visual(object_id, Rect2(rect.position + Vector2(7, 6), Vector2(rect.size.x - 14, rect.size.y - 42)), false)
	_draw_text_centered(str(object.get("label", object.get("name", "物件"))), Rect2(rect.position + Vector2(0, rect.size.y - 33), Vector2(rect.size.x, 16)), 11, COLD_30 if seen else COLD_10, 2.0)


func _night_visual_state(object_id: String) -> Dictionary:
	var night_id := str(night_interaction.night_id) if night_interaction != null else pending_night_id
	var state: Dictionary = night_interaction.object_state(object_id) if night_interaction != null and night_interaction.object_ids().has(object_id) else {}
	var phase := str(state.get("phase", ""))
	match object_id:
		"whiteboard":
			return {"kind": "scarf_dog_whiteboard", "scarf_dog": true}
		"pothos":
			if night_id == "2":
				return {"kind": "pothos", "yellow_leaves": 6, "green_leaves": 3, "stage": "two_thirds_yellow"}
			var tier := int(model.office_deterioration_tier()) if model != null else 0
			var yellow := clampi(tier * 2, 0, 8)
			return {"kind": "pothos", "yellow_leaves": yellow, "green_leaves": 9 - yellow, "stage": "debt_tier_%d" % tier}
		"window_desk":
			return {
				"kind": "window_desk", "phase": phase,
				"cup_held": phase == "cup_picked_up",
				"cup_replaced": phase == "cup_replaced",
				"cup_offset_px": 12 if phase == "cup_replaced" else 0,
				"distance_cm": float(state.get("distance_cm", 0.0)),
			}
		"meeting_room_d":
			var light_on := bool(state.get("light_on", false))
			return {
				"kind": "meeting_room_d", "phase": phase, "light_on": light_on,
				"projector_blue": light_on and phase != "outside",
				"door_closed": bool(state.get("door_closed", false)),
				"walked_steps": int(state.get("walked_steps", 0)),
			}
	return {"kind": object_id, "phase": phase}


func _draw_night_authored_visual(object_id: String, rect: Rect2, detail: bool) -> void:
	match object_id:
		"whiteboard":
			_draw_night_raster_visual(art_night_whiteboard, object_id, rect, detail)
		"pothos":
			var visual := _night_visual_state(object_id)
			var pothos_texture := art_night_pothos
			if str(visual.get("stage", "")) == "two_thirds_yellow" or int(visual.get("yellow_leaves", 0)) >= 6:
				pothos_texture = art_night_pothos_severe
			elif int(visual.get("yellow_leaves", 0)) == 0:
				pothos_texture = art_night_pothos_healthy
			_draw_night_raster_visual(pothos_texture, object_id, rect, detail)
		"window_desk":
			_draw_night_raster_visual(art_night_mug, object_id, rect, detail)
		"meeting_room_d":
			_draw_night_raster_visual(art_night_room_d, object_id, rect, detail)
		"terminal":
			_draw_night_terminal_visual(rect)
		"corridor":
			for i in 4:
				var strength := 0.18 + float(i) * 0.07
				draw_rect(Rect2(rect.position + Vector2(6 + i * rect.size.x * 0.22, 5), Vector2(rect.size.x * 0.15, rect.size.y - 11)), Color(0.48, 0.66, 0.55, strength))
		"fridge":
			_draw_panel(Rect2(rect.position + Vector2(rect.size.x * 0.31, 2), Vector2(rect.size.x * 0.38, rect.size.y - 4)), Color("#c7d0cc"), Color("#66736d"), 2.0, 1.0)
			draw_line(rect.position + Vector2(rect.size.x * 0.34, rect.size.y * 0.48), rect.position + Vector2(rect.size.x * 0.66, rect.size.y * 0.48), Color("#7b8781"), 1.0)
		"mug":
			_draw_cup_icon(rect.get_center(), 0.62 if not detail else 1.2, Color("#d9ded9"), Color("#76827c"))


func _draw_night_raster_visual(texture: Texture2D, object_id: String, rect: Rect2, detail: bool) -> void:
	if object_id == "whiteboard" and texture != null:
		# Inspection behaves like leaning closer: retain the erased board and rail,
		# but give the tiny authored scarf-dog enough visual weight to read at 720p.
		var source_size := Vector2(float(texture.get_width()), float(texture.get_height()))
		var crop_side := minf(source_size.x * 0.38, source_size.y * 0.53)
		var crop_origin := Vector2(maxf(0.0, source_size.x - crop_side - 15.0), maxf(0.0, source_size.y - crop_side - 28.0))
		draw_texture_rect_region(texture, rect, Rect2(crop_origin, Vector2.ONE * crop_side), Color(0.86, 0.91, 0.91, 1.0))
	else:
		_draw_texture_cover(texture, rect, Color(0.86, 0.91, 0.91, 1.0), Vector2(0.5, 0.5))
	draw_rect(rect, Color(0.015, 0.05, 0.065, 0.10 if detail else 0.22))
	var visual := _night_visual_state(object_id)
	if object_id == "window_desk":
		if bool(visual.get("cup_held", false)):
			draw_rect(rect, Color(0.02, 0.05, 0.06, 0.30))
			_draw_text_centered("杯子在你手里", Rect2(rect.position + Vector2(10, rect.size.y - 34), Vector2(rect.size.x - 20, 24)), 11, Color("#d6e4e1"), 2.0)
		elif bool(visual.get("cup_replaced", false)):
			var marker := rect.position + Vector2(rect.size.x * 0.58, rect.size.y * 0.69)
			draw_line(marker, marker + Vector2(18, 0), AMBER, 2.0)
			if detail:
				_draw_text("偏了 2 cm", marker + Vector2(-20, -8), 11, Color("#e2c69f"))
	elif object_id == "meeting_room_d":
		var door_closed := bool(visual.get("door_closed", false))
		var walked_steps := int(visual.get("walked_steps", 0))
		if door_closed:
			# The raster shows the original open glass door. This restrained pane is
			# the same door swung shut, so the interaction state remains visible
			# without replacing the authored room with a diagram.
			var pane := Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.015), Vector2(rect.size.x * 0.235, rect.size.y * 0.97))
			_draw_panel(pane, Color(0.07, 0.13, 0.16, 0.74), Color(0.38, 0.53, 0.58, 0.78), 2.0, 1.0)
			draw_line(Vector2(pane.end.x - 2, pane.position.y), Vector2(pane.end.x - 2, pane.end.y), Color(0.06, 0.11, 0.13, 0.92), 3.0)
			draw_circle(pane.position + Vector2(pane.size.x * 0.78, pane.size.y * 0.47), 2.5 if detail else 1.2, Color("#a7b5b1"))
		if walked_steps > 0:
			draw_rect(rect, Color(0.0, 0.025, 0.035, 0.08 + float(walked_steps) * 0.09))
			for step in walked_steps:
				var footprint := rect.position + Vector2(rect.size.x * (0.68 + step * 0.085), rect.size.y * (0.82 - step * 0.055))
				draw_circle(footprint, 4.0 if detail else 1.8, Color(0.61, 0.76, 0.77, 0.62))
				draw_line(footprint + Vector2(-4, 5), footprint + Vector2(3, 1), Color(0.61, 0.76, 0.77, 0.48), 2.0 if detail else 1.0)
		if not bool(visual.get("light_on", true)):
			draw_rect(rect, Color(0.0, 0.02, 0.025, 0.62))
		if detail:
			var room_status := "灯已关" if not bool(visual.get("light_on", true)) else ("已离门 %d 步" % walked_steps if walked_steps > 0 else ("门已关" if door_closed else "门开 · 投影待机"))
			var status_rect := Rect2(rect.position + Vector2(12, rect.size.y - 38), Vector2(rect.size.x - 24, 28))
			_draw_panel(status_rect, Color(0.03, 0.08, 0.10, 0.84), Color(0.39, 0.57, 0.61, 0.72), RADIUS_CONTROL, 1.0)
			_draw_text_centered(room_status, status_rect, TYPE_META, NIGHT_TEXT, 2.0)
	elif object_id == "pothos" and detail:
		var stage_text := "黄叶约三分之二" if str(visual.get("stage", "")) == "two_thirds_yellow" else "它仍在缓慢变黄"
		_draw_text(stage_text, rect.position + Vector2(14, rect.size.y - 16), 11, Color("#d7c894"))


func _draw_night_whiteboard_visual(rect: Rect2, detail: bool) -> void:
	var board := rect.grow(-3.0)
	_draw_panel(board, Color("#d9ddd6"), Color("#5e6964"), 3.0, 1.0)
	var dog := board.position + Vector2(board.size.x * 0.30, board.size.y * (0.38 if detail else 0.46))
	var dog_scale := 1.55 if detail else 0.56
	draw_circle(dog, 16.0 * dog_scale, Color("#a97952"))
	draw_colored_polygon(PackedVector2Array([dog + Vector2(-14, -8) * dog_scale, dog + Vector2(-21, -25) * dog_scale, dog + Vector2(-4, -17) * dog_scale]), Color("#8a5e42"))
	draw_colored_polygon(PackedVector2Array([dog + Vector2(14, -8) * dog_scale, dog + Vector2(21, -25) * dog_scale, dog + Vector2(4, -17) * dog_scale]), Color("#8a5e42"))
	draw_circle(dog + Vector2(-6, -3) * dog_scale, 1.8 * dog_scale, Color("#202522"))
	draw_circle(dog + Vector2(6, -3) * dog_scale, 1.8 * dog_scale, Color("#202522"))
	draw_line(dog + Vector2(-16, 17) * dog_scale, dog + Vector2(18, 23) * dog_scale, AMBER, 5.0 * dog_scale, true)
	if detail:
		_draw_text("这不是我们的 logo。", board.position + Vector2(board.size.x * 0.53, 54), 10, Color("#48524d"))
		_draw_text("现在是了。", board.position + Vector2(board.size.x * 0.53, 82), 10, GREEN)


func _draw_night_plant_visual(rect: Rect2, detail: bool) -> void:
	var visual := _night_visual_state("pothos")
	var yellow_count := int(visual.get("yellow_leaves", 0))
	var total := yellow_count + int(visual.get("green_leaves", 0))
	var center := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.72)
	var radius := minf(rect.size.x, rect.size.y) * (0.28 if detail else 0.32)
	draw_rect(Rect2(center + Vector2(-radius * 0.34, radius * 0.12), Vector2(radius * 0.68, radius * 0.58)), Color("#785f46"))
	for i in total:
		var angle := -PI * 0.88 + float(i) / maxf(1.0, float(total - 1)) * PI * 1.76
		var stem_end := center + Vector2(cos(angle) * radius, sin(angle) * radius)
		draw_line(center, stem_end, Color("#58705e"), 1.2 if detail else 1.0)
		var leaf_color := Color("#a99a52") if i < yellow_count else Color("#4f8b61")
		draw_circle(stem_end, 8.0 if detail else 3.4, leaf_color)
	if detail:
		var stage_text := "黄约 2 / 3 · 剩余绿得过分" if str(visual.get("stage", "")) == "two_thirds_yellow" else ("叶缘仍绿" if yellow_count == 0 else "黄叶正在自然增加")
		_draw_text_centered(stage_text, Rect2(rect.position + Vector2(4, rect.size.y - 28), Vector2(rect.size.x - 8, 22)), 9, Color("#91a69b"), 3.0)


func _draw_night_desk_visual(rect: Rect2, detail: bool) -> void:
	var visual := _night_visual_state("window_desk")
	var desk_y := rect.position.y + rect.size.y * 0.68
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.08, rect.size.y * 0.66), Vector2(rect.size.x * 0.84, maxf(3.0, rect.size.y * 0.08))), Color("#6f6253"))
	var monitor := Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.14), Vector2(rect.size.x * 0.43, rect.size.y * 0.36))
	_draw_panel(monitor, Color("#182522"), Color("#4b5b54"), 3.0, 1.0)
	var logo_x := fmod(_motion_clock() * 10.0, maxf(8.0, monitor.size.x - 18.0))
	draw_circle(monitor.position + Vector2(9 + logo_x, monitor.size.y * 0.5), 3.0 if detail else 1.5, GREEN_BRIGHT)
	var original := Vector2(rect.position.x + rect.size.x * 0.76, desk_y - rect.size.y * 0.09)
	if bool(visual.get("cup_held", false)):
		draw_circle(original, 8.0 if detail else 3.0, Color(0.75, 0.75, 0.68, 0.14))
		var held := rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.25 + sin(_motion_clock() * 2.4) * 3.0)
		_draw_cup_icon(held, 1.0 if detail else 0.35, Color("#e4e3dc"), AMBER)
		if detail:
			_draw_text("杯在手里", held + Vector2(-34, 40), 9, Color("#91a69b"))
	else:
		var offset := Vector2(float(visual.get("cup_offset_px", 0)), 0.0)
		if bool(visual.get("cup_replaced", false)):
			draw_circle(original, 8.0 if detail else 3.0, Color(0.75, 0.75, 0.68, 0.18))
			draw_line(original, original + offset, AMBER, 1.0)
		_draw_cup_icon(original + offset, 0.72 if detail else 0.30, Color("#deded8"), AMBER)
		if detail and bool(visual.get("cup_replaced", false)):
			_draw_text("2 cm", original + offset + Vector2(-12, 31), 9, AMBER)
	if detail:
		_draw_text("第一届全员团建 · 2024", rect.position + Vector2(12, rect.size.y - 20), 9, Color("#91a69b"))


func _draw_night_room_d_visual(rect: Rect2, detail: bool) -> void:
	var visual := _night_visual_state("meeting_room_d")
	var room := rect.grow(-3.0)
	var light_on := bool(visual.get("light_on", false))
	_draw_panel(room, Color("#172025") if light_on else Color("#111615"), Color("#53636a"), 3.0, 1.0)
	var projector := room.position + Vector2(room.size.x * 0.23, room.size.y * 0.20)
	draw_rect(Rect2(projector - Vector2(10, 5), Vector2(20, 10)), Color("#758388"))
	if bool(visual.get("projector_blue", false)):
		var pulse := 0.14 + (sin(_motion_clock() * 1.9) + 1.0) * 0.025
		draw_colored_polygon(PackedVector2Array([projector + Vector2(10, 0), room.position + Vector2(room.size.x * 0.92, room.size.y * 0.19), room.position + Vector2(room.size.x * 0.92, room.size.y * 0.78)]), Color(0.28, 0.58, 0.82, pulse))
	var board := Rect2(room.position + Vector2(room.size.x * 0.53, room.size.y * 0.22), Vector2(room.size.x * 0.35, room.size.y * 0.38))
	_draw_panel(board, Color("#d7dcd9"), Color("#708079"), 2.0, 1.0)
	if detail:
		_draw_text_centered("下周同一时间。", board, 9, Color("#43514b"), 3.0)
	var door_x := room.position.x + room.size.x * 0.13
	if bool(visual.get("door_closed", false)):
		draw_rect(Rect2(Vector2(door_x, room.position.y + room.size.y * 0.42), Vector2(room.size.x * 0.16, room.size.y * 0.48)), Color("#39443f"))
	else:
		draw_line(Vector2(door_x, room.position.y + room.size.y * 0.42), Vector2(door_x + room.size.x * 0.18, room.position.y + room.size.y * 0.88), Color("#66766f"), 3.0)
	draw_circle(room.position + Vector2(room.size.x * 0.48, room.size.y * 0.12), 5.0 if detail else 2.0, Color("#e3e8d3") if light_on else Color("#39413d"))
	if detail:
		var status := "灯亮 · 投影待机蓝光" if light_on else "灯已关"
		_draw_text(status, room.position + Vector2(10, room.size.y - 10), 9, Color("#7fa6ae") if light_on else Color("#66716c"))


func _draw_night_terminal_visual(rect: Rect2) -> void:
	var screen_rect := rect.grow(-4.0)
	_draw_panel(screen_rect, Color("#0b110f"), Color("#496052"), 2.0, 1.0)
	for i in 3:
		draw_line(screen_rect.position + Vector2(6, 7 + i * 6), screen_rect.position + Vector2(screen_rect.size.x * (0.72 - i * 0.1), 7 + i * 6), Color("#769c7e"), 1.0)
	if reduced_motion or fmod(_motion_clock(), 1.0) < 0.56:
		draw_rect(Rect2(screen_rect.position + Vector2(screen_rect.size.x - 13, screen_rect.size.y - 13), Vector2(5, 8)), GREEN_BRIGHT)


func _night_object_progress_label(object_id: String) -> String:
	if night_interaction == null or not night_interaction.object_ids().has(object_id):
		return ""
	if night_interaction.is_object_complete(object_id):
		return "已读取"
	var phase := str(night_interaction.object_phase(object_id))
	if str(night_interaction.night_id) == "1" and object_id == "corridor":
		return "%d / 3 次" % int(night_interaction.object_state(object_id).get("pass_count", 0))
	match object_id:
		"window_desk":
			return {"awaiting_inspection": "0 / 3", "inspect_screen_cup": "1 / 3", "cup_picked_up": "2 / 3"}.get(phase, "")
		"meeting_room_d":
			return {
				"outside": "进入", "projection_seen": "关门", "door_closed": "走开 0 / 2",
				"walked_away": "走开 %d / 2" % mini(2, int(night_interaction.object_state(object_id).get("walked_steps", 0))),
				"returned": "关灯",
			}.get(phase, "")
		"terminal":
			return {"not_arrived": "靠近", "arrived": "读取", "dialogue_inspected": "聚焦", "focused": "X / Ctrl+C"}.get(phase, "")
	return "读取"


func _draw_ending() -> void:
	var ending_texture: Texture2D = art_office_day
	if current_ending_id in ["rm_rf", "lights_out", "drift"]:
		ending_texture = art_office_night
	elif current_ending_id in ["second_time", "independent", "successor"]:
		ending_texture = art_title
	_draw_art_background(ending_texture, Color(0.74, 0.79, 0.79, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.05, 0.065, 0.34))
	var reveal := _reveal(0.02, 0.70)
	draw_set_transform(Vector2.ZERO)
	# The ending is a full-bleed place with one physical archive leaf laid over
	# it. The evidence photograph remains outside the paper, in the scene.
	var ending_sheet := Rect2(62, 40, 824, 644)
	draw_rect(Rect2(ending_sheet.position + Vector2(10, 12), ending_sheet.size), Color(0.005, 0.02, 0.025, 0.28 * reveal))
	draw_rect(ending_sheet, Color(0.95, 0.925, 0.85, 0.95))
	draw_rect(ending_sheet, WARM_40, false, 1.0)
	draw_rect(Rect2(ending_sheet.position, Vector2(7, ending_sheet.size.y)), _ending_accent_color())
	draw_rect(Rect2(ending_sheet.position + Vector2(368, -5), Vector2(92, 12)), Color(0.64, 0.65, 0.60, 0.86))
	var name := str(current_ending.get("title", current_ending.get("name", current_ending_id)))
	_draw_text("COMPANY ARCHIVE  /  %s" % str(model.company_name), ending_sheet.position + Vector2(46, 43), 11, GREEN)
	_draw_text("ENDING / %02d" % (abs(current_ending_id.hash()) % 97), ending_sheet.position + Vector2(ending_sheet.size.x - 202, 43), 11, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 156)
	draw_line(ending_sheet.position + Vector2(46, 58), ending_sheet.position + Vector2(ending_sheet.size.x - 46, 58), WARM_40, 1.0)
	_draw_display_text(name, ending_sheet.position + Vector2(46, 116), 42, INK)
	var pages := _ending_pages()
	var body: Array = pages[clampi(ending_page, 0, maxi(0, pages.size() - 1))]
	_draw_paragraph_array(_to_string_array(body), Rect2(ending_sheet.position + Vector2(46, 148), Vector2(ending_sheet.size.x - 92, 410)), 16, INK, 27)
	_draw_folio_stamp(Rect2(ending_sheet.end.x - 184, ending_sheet.position.y + 78, 132, 48), "已归档", _ending_accent_color(), -0.024)
	_draw_ending_motif(Rect2(930, 146, 270, 378))
	var restart := _ending_restart_rect()
	var ending_button := "下一页  %d / %d   ENTER" % [ending_page + 1, pages.size()] if ending_page + 1 < pages.size() else "回到 2024 年 3 月   ENTER"
	ending_button = ending_button.replace("ENTER", _gamepad_shortcut("A", "ENTER"))
	draw_rect(restart, Color(0.16, 0.24, 0.21, 0.90))
	draw_line(restart.position, Vector2(restart.end.x, restart.position.y), _ending_accent_color(), 2.0)
	draw_line(Vector2(restart.position.x, restart.end.y), restart.end, COLD_50, 1.0)
	_draw_text("归档操作", restart.position + Vector2(18, 29), TYPE_META, COLD_30)
	_draw_text(ending_button, restart.position + Vector2(138, 30), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, restart.size.x - 158)
	_draw_text("它记住了。", Vector2(1036, 650), 11, COLD_10)
	draw_set_transform(Vector2.ZERO)


func _ending_accent_color() -> Color:
	match current_ending_id:
		"rm_rf": return RED
		"lights_out": return BLUE.darkened(0.12)
		"successor": return AMBER
		"acquihire": return BLUE
		"independent": return GREEN
		"second_time": return WARM_60
		_: return COLD_50


func _draw_ending_motif(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(7, 9), rect.size), Color(0.005, 0.02, 0.025, 0.30))
	var motif_texture: Texture2D = art_office_day
	if current_ending_id in ["rm_rf", "lights_out", "drift"]:
		motif_texture = art_office_night
	elif current_ending_id in ["second_time", "independent", "successor"]:
		motif_texture = art_title
	_draw_texture_cover(motif_texture, rect, Color(0.80, 0.86, 0.85, 1.0), Vector2(0.58, 0.52))
	draw_rect(rect, Color(0.015, 0.05, 0.065, 0.30))
	draw_rect(rect, Color("#72868a"), false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(42, -5), Vector2(72, 13)), Color(0.72, 0.70, 0.61, 0.88))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 58)), Color(0.02, 0.07, 0.085, 0.84))
	draw_rect(Rect2(rect.position, Vector2(6, rect.size.y)), _ending_accent_color())
	_draw_text("证据照片 / 公司档案", rect.position + Vector2(22, 25), TYPE_META, Color("#c9dcda"))
	_draw_text("影像 %02d" % (abs(current_ending_id.hash()) % 97), rect.position + Vector2(22, 45), TYPE_META, Color.WHITE)
	var center := rect.get_center() + Vector2(0, 28)
	match current_ending_id:
		"rm_rf":
			var terminal_evidence := Rect2(center - Vector2(66, 50), Vector2(132, 100))
			draw_rect(terminal_evidence, Color(0.02, 0.06, 0.075, 0.90))
			draw_rect(terminal_evidence, Color("#657c83"), false, 1.0)
			for i in 5:
				draw_line(center + Vector2(-48, -32 + i * 15), center + Vector2(38 - (i % 2) * 18, -32 + i * 15), TERMINAL_TEXT, 2.0)
		"lights_out":
			for i in 4:
				draw_line(center + Vector2(-68, -46 + i * 28), center + Vector2(68, -46 + i * 28), Color(0.52, 0.70, 0.74, 0.78), 2.0)
		"independent":
			var independent_leaf := Rect2(center - Vector2(64, 64), Vector2(128, 128))
			draw_rect(independent_leaf, Color(0.94, 0.94, 0.89, 0.88))
			draw_rect(independent_leaf, Color("#bba98c"), false, 1.0)
			for i in 6:
				draw_line(center + Vector2(-46, -42 + i * 16), center + Vector2(42 - (i % 3) * 10, -42 + i * 16), Color("#71848b"), 1.0)
			draw_circle(center + Vector2(45, 48), 9.0, GREEN)
		"successor":
			for i in 4:
				var successor_leaf := Rect2(center + Vector2(-68 + i * 22, -58 + i * 18), Vector2(92, 112))
				draw_rect(successor_leaf, Color(0.92, 0.95, 0.93, 0.86))
				draw_rect(successor_leaf, Color("#a8b5b8"), false, 1.0)
		"second_time":
			_draw_cup_icon(center, 2.2, Color("#e3ded3"), Color("#ad7252"))
		_:
			for i in 3:
				var badge := Rect2(center + Vector2(-68 + i * 49, -42), Vector2(38, 90))
				draw_rect(badge, Color(0.89, 0.93, 0.91, 0.86))
				draw_rect(badge, Color("#9faeb1"), false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 46), Vector2(rect.size.x, 46)), Color(0.015, 0.05, 0.065, 0.84))
	_draw_text_centered("归档证据 / %02d" % (abs(current_ending_id.hash()) % 97), Rect2(rect.position + Vector2(12, rect.size.y - 35), Vector2(rect.size.x - 24, 22)), 10, Color("#c8d7d6"), 2.0)


func _draw_workspace_background() -> void:
	_draw_art_background(art_dossier_desk, Color(0.92, 0.95, 0.97, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.04, 0.055, 0.08))


func _draw_art_background(texture: Texture2D, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		draw_rect(Rect2(Vector2.ZERO, VIEW), BG)
		return
	draw_texture_rect(texture, Rect2(Vector2.ZERO, VIEW), false, modulate)


func _workspace_scene_texture() -> Texture2D:
	if model != null and int(model.chapter) <= 1 and model.employees.size() <= 4 and art_title != null:
		return art_title
	return art_office_day


func _draw_texture_cover(texture: Texture2D, rect: Rect2, modulate: Color = Color.WHITE, anchor: Vector2 = Vector2(0.5, 0.5)) -> void:
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
		draw_rect(rect, BG)
		return
	var source_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	var target_aspect := rect.size.x / maxf(1.0, rect.size.y)
	var source_aspect := source_size.x / maxf(1.0, source_size.y)
	var crop_size := source_size
	if source_aspect > target_aspect:
		crop_size.x = source_size.y * target_aspect
	else:
		crop_size.y = source_size.x / target_aspect
	var safe_anchor := Vector2(clampf(anchor.x, 0.0, 1.0), clampf(anchor.y, 0.0, 1.0))
	var crop_origin := (source_size - crop_size) * safe_anchor
	draw_texture_rect_region(texture, rect, Rect2(crop_origin, crop_size), modulate)


func _draw_back_button() -> void:
	var rect := _content_back_rect()
	var blocked_label := ""
	if screen == Screen.INTRANET and _origin_interaction_required():
		blocked_label = "读完三遍后返回"
	elif screen == Screen.TEAM and _window_interaction_required():
		blocked_label = "拉上窗帘后返回"
	_draw_ledger_button(rect, blocked_label if not blocked_label.is_empty() else "返回概览", "" if not blocked_label.is_empty() else _gamepad_shortcut("B", "ESC"), "quiet", blocked_label.is_empty())


func _draw_office_debt_indicator(rect: Rect2) -> void:
	# The status word is the picture. A 154x76 thumbnail of a painted office is
	# too small to read as an office, and it competed with the one line that
	# actually lands: an office that has stopped being a place and become a
	# process. Paper is the only physical trace kept, because unclaimed paper is
	# legible at any size and it accumulates rather than decorates.
	var tier := int(model.office_deterioration_tier())
	_draw_text("办公室", rect.position + Vector2(6, 20), TYPE_META, COLD_40)
	draw_line(rect.position + Vector2(6, 32), rect.position + Vector2(190, 32), Color(COLD_60, 0.55), 1.0)
	var status_names := ["尚可", "有点乱", "没人收拾", "流程正常", "完全正常"]
	_draw_display_text(status_names[clampi(tier, 0, 4)], rect.position + Vector2(6, 62), TYPE_SECTION, COLD_05)
	_draw_text("留下的不是灰尘，是流程。", rect.position + Vector2(6, 86), TYPE_META, COLD_40)
	for i in tier:
		var sheet := Rect2(rect.position + Vector2(6 + i * 6, 104 + i * 9), Vector2(120 - i * 8, 30))
		draw_rect(sheet, Color(WARM_20, 0.09 + i * 0.04))
		draw_rect(sheet, Color(WARM_40, 0.20 + i * 0.05), false, 1.0)


func _draw_toast() -> void:
	var entrance := 1.0 if reduced_motion else clampf((toast_duration - toast_timer) / MOTION_FAST, 0.0, 1.0)
	var exit_alpha := 1.0 if reduced_motion else clampf(toast_timer / MOTION_FAST, 0.0, 1.0)
	var signal_color: Color = {"success": GREEN, "warning": AMBER, "error": RED}.get(toast_kind, BLUE)
	var width := clampf(font.get_string_size(toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, TYPE_META).x + 64.0, 320.0, 480.0)
	# Toasts live in the reserved top rail, above every page header and outside
	# the settings launcher. They never obscure the content they are explaining.
	var y := TOAST_MAX_SAFE_RECT.position.y
	var rect := Rect2((VIEW.x - width) * 0.5, y - (1.0 - entrance) * 10.0, width, 48)
	_draw_panel(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0.0, 0.02, 0.03, 0.16 * exit_alpha), Color.TRANSPARENT, RADIUS_CONTROL, 0.0)
	_draw_panel(rect, Color(0.055, 0.105, 0.12, 0.96 * exit_alpha), Color(signal_color, exit_alpha), RADIUS_CONTROL, 1.0)
	draw_rect(Rect2(rect.position, Vector2(4, rect.size.y)), Color(signal_color, exit_alpha))
	_draw_text_centered(toast_text, Rect2(rect.position + Vector2(18, 0), Vector2(rect.size.x - 30, rect.size.y)), TYPE_META, Color(1.0, 1.0, 1.0, exit_alpha), 3.0)


func _record_press_feedback(position: Vector2) -> void:
	if reduced_motion:
		return
	press_feedback_position = position
	press_feedback_timer = MOTION_FAST


func _draw_press_feedback() -> void:
	var progress := clampf(1.0 - press_feedback_timer / MOTION_FAST, 0.0, 1.0)
	var radius := lerpf(5.0, 18.0, progress)
	var alpha := (1.0 - progress) * 0.48
	draw_circle(press_feedback_position, maxf(1.0, 3.0 * (1.0 - progress)), Color(GREEN_BRIGHT, alpha * 0.75))
	draw_arc(press_feedback_position, radius, 0.0, TAU, 24, Color(GREEN_BRIGHT, alpha), 1.5, true)


func _draw_settings_launcher() -> void:
	if settings_open:
		return
	var rect := _settings_button_rect()
	var hovered := rect.has_point(mouse_position)
	draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size), Color(0.0, 0.02, 0.025, 0.18))
	draw_rect(rect, INK if hovered else INK)
	draw_rect(rect, COLD_50, false, 1.0)
	draw_rect(Rect2(rect.position, Vector2(4, rect.size.y)), GREEN)
	var launcher_key := "START" if gamepad_focus_visible else "F1"
	_draw_text(launcher_key, rect.position + Vector2(10, 27), 10, GREEN_BRIGHT)
	_draw_text("设置", rect.position + Vector2(58 if gamepad_focus_visible else 44, 28), 12, COLD_10)


func _draw_settings_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), SCRIM)
	# Pause-time controls are a single clipped paper form. Rows, keyboard guide,
	# and close action all belong to the same sheet instead of nested UI cards.
	var panel := Rect2(354, 78, 572, 562)
	draw_rect(Rect2(panel.position + Vector2(10, 12), panel.size), Color(0.0, 0.02, 0.03, 0.32))
	draw_rect(panel, Color(0.93, 0.93, 0.87, 0.99))
	draw_rect(panel, COLD_40, false, 1.0)
	draw_rect(Rect2(panel.position, Vector2(7, panel.size.y)), GREEN)
	draw_rect(Rect2(panel.position + Vector2(242, -5), Vector2(88, 12)), COLD_30)
	_draw_text("CONTROL SHEET  /  LOCAL", panel.position + Vector2(34, 34), 11, GREEN)
	_draw_display_text("设置与辅助", panel.position + Vector2(34, 75), 28, INK)
	_draw_text("这些选项会保存在本机，不会改写战役选择。", panel.position + Vector2(34, 103), 12, MUTED)
	_draw_folio_stamp(Rect2(panel.end.x - 154, panel.position.y + 27, 118, 48), "PAUSED", GREEN, -0.02)
	draw_line(panel.position + Vector2(34, 127), panel.position + Vector2(panel.size.x - 34, 127), COLD_30, 1.0)
	_draw_settings_row(_settings_motion_rect(), "降低动态效果", "关闭滑入、脉冲与长时间静默等待", reduced_motion, _focus_is("settings", 0))
	_draw_settings_row(_settings_audio_rect(), "全部声音", "环境 / 配乐 / 物理拟音", office_audio != null and not office_audio.muted, _focus_is("settings", 1))
	var fullscreen_on := get_window().mode == Window.MODE_FULLSCREEN
	_draw_settings_row(_settings_fullscreen_rect(), "全屏显示", "也可随时按 F11", fullscreen_on, _focus_is("settings", 2))
	var guide := Rect2(panel.position + Vector2(34, 363), Vector2(panel.size.x - 68, 116))
	draw_line(guide.position, guide.position + Vector2(guide.size.x, 0), COLD_30, 1.0)
	_draw_text("手柄 / 键盘速查", guide.position + Vector2(0, 25), TYPE_META, INK)
	_draw_text("D-pad 选项   A 确认 / 亲自   X 委派   Y 结束周", guide.position + Vector2(0, 50), TYPE_META, MUTED)
	_draw_text("LB / RB 翻档   B 返回   START 设置", guide.position + Vector2(0, 72), TYPE_META, MUTED)
	_draw_text("夜班：D-pad 选择，A 交互，终端 X 中断", guide.position + Vector2(0, 94), TYPE_META, MUTED)
	_draw_text("键盘：ENTER 确认   ESC 返回   F1 设置   F11 全屏", guide.position + Vector2(0, 116), TYPE_META, MUTED)
	var close_rect := _settings_close_rect()
	_draw_ledger_button(close_rect, "归档并返回", _gamepad_shortcut("A / B", "ESC"), "primary", true, _focus_is("settings", 3))


func _draw_settings_row(rect: Rect2, title: String, description: String, enabled: bool, focused: bool = false) -> void:
	var hovered := rect.has_point(mouse_position)
	if hovered or focused:
		draw_rect(rect, Color(0.73, 0.82, 0.76, 0.20))
	if focused:
		_draw_panel(rect.grow(3.0), Color.TRANSPARENT, GREEN_BRIGHT, RADIUS_CONTROL + 2.0, 2.0)
	if enabled:
		draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), GREEN)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.end, COLD_30, 1.0)
	_draw_text(title, rect.position + Vector2(18, 26), 13, INK)
	_draw_text(description, rect.position + Vector2(18, 48), TYPE_META, MUTED)
	var toggle := Rect2(rect.end - Vector2(72, 45), Vector2(52, 26))
	# Two separate stamp boxes read as a paper register, not a number spinner or
	# software pill. The chosen state is the only solid impression.
	var off_cell := Rect2(toggle.position + Vector2(1, 2), Vector2(22, 22))
	var on_cell := Rect2(toggle.position + Vector2(29, 2), Vector2(22, 22))
	draw_rect(off_cell, WARM_10)
	draw_rect(on_cell, WARM_10)
	draw_rect(off_cell, COLD_40, false, 1.0)
	draw_rect(on_cell, COLD_40, false, 1.0)
	var active_cell := on_cell if enabled else off_cell
	draw_rect(active_cell.grow(-2.0), GREEN if enabled else COLD_60)
	_draw_text_centered("关", off_cell, TYPE_META, COLD_05 if not enabled else MUTED, 1.0)
	_draw_text_centered("开", on_cell, TYPE_META, COLD_05 if enabled else MUTED, 1.0)


func _open_settings() -> void:
	_play_foley("page")
	settings_open = true
	_sync_settings_focus()
	if name_edit != null:
		name_edit.release_focus()
		name_edit.visible = false
	if command_edit != null:
		night_command_focus_before_settings = command_edit.has_focus()
		command_edit.release_focus()
		command_edit.visible = false
	queue_redraw()


func _close_settings() -> void:
	if focus_router != null and focus_router.section == "settings":
		focused_settings_row = focus_router.index
	settings_open = false
	_play_foley("page")
	if name_edit != null:
		name_edit.visible = screen == Screen.ONBOARDING
	if command_edit != null:
		command_edit.visible = screen == Screen.NIGHT_SHIFT and night_interaction != null and night_interaction.terminal_accepts_command()
		if command_edit.visible and night_command_focus_before_settings:
			command_edit.grab_focus()
	night_command_focus_before_settings = false
	_sync_focus_for_current_screen()
	queue_redraw()


func _toggle_settings() -> void:
	if settings_open:
		_close_settings()
	else:
		_open_settings()


func _handle_settings_click(position: Vector2) -> void:
	if _settings_motion_rect().has_point(position):
		_set_reduced_motion(not reduced_motion)
	elif _settings_audio_rect().has_point(position):
		_toggle_audio_setting()
	elif _settings_fullscreen_rect().has_point(position):
		_toggle_fullscreen()
	elif _settings_close_rect().has_point(position):
		_close_settings()


func _set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_play_foley("switch")
	_save_meta()
	_show_toast("降低动态效果已开启。" if enabled else "动态效果已恢复。")
	queue_redraw()


func _toggle_audio_setting() -> void:
	if office_audio == null:
		return
	var was_muted: bool = office_audio.muted
	var muted := false
	if was_muted:
		muted = office_audio.toggle_mute()
		_play_foley("switch")
	else:
		var switch_started := _play_foley("switch")
		muted = office_audio.mute_preserving_latest_foley(switch_started)
	_save_meta()
	_show_toast("全部声音已关闭。" if muted else "全部声音已开启。")
	queue_redraw()


func _event_body_pages() -> Array:
	var raw = current_event.get("pages", current_event.get("body", []))
	if raw is String:
		return [[str(raw)]]
	if raw is Array and not raw.is_empty() and raw[0] is Array:
		return raw
	return _paginate_paragraphs(_to_string_array(raw), 10, 620.0, 16)


func _event_page_hold_seconds() -> float:
	var holds: Array = current_event.get("page_hold_seconds", [])
	if current_event_page < 0 or current_event_page >= holds.size():
		return 0.0
	return maxf(0.0, float(holds[current_event_page]))


func _event_page_is_silence() -> bool:
	return current_event_page in Array(current_event.get("silence_pages", []))


func _event_page_can_advance() -> bool:
	var required := _event_page_hold_seconds()
	if _event_page_is_silence():
		required = minf(required, 0.15 if reduced_motion else 10.0)
	return event_page_elapsed + 0.0001 >= required


func _draw_event_silence(panel: Rect2) -> void:
	var scene := Rect2(panel.position + Vector2(34, 48), Vector2(656, 174))
	draw_line(scene.position, Vector2(scene.position.x, scene.end.y), Color(GREEN, 0.54), 2.0)
	_draw_text("08:47 / 录音未开始", scene.position + Vector2(22, 28), 12, MUTED)
	_draw_cup_icon(scene.position + Vector2(126, 106), 0.68, WARM_10, WARM_60)
	_draw_display_text("林越把杯子放下。", scene.position + Vector2(190, 104), 18, INK)
	_draw_text("……", scene.position + Vector2(scene.size.x - 54, 106), 15, MUTED)
	var wait_cap := minf(_event_page_hold_seconds(), 0.15 if reduced_motion else 10.0)
	if wait_cap > 0.0:
		var silence_hint := "ENTER 可继续" if _event_page_can_advance() else "沉默中 · %d 秒后可继续" % maxi(1, int(ceil(wait_cap - event_page_elapsed)))
		_draw_text(silence_hint, scene.position + Vector2(190, 146), 12, MUTED)


func _event_choices_visible() -> bool:
	if _is_second_time_event():
		return _second_time_phase() == SECOND_TIME_PHASE_QUESTION
	var pages := _event_body_pages()
	return pages.is_empty() or current_event_page >= pages.size() - 1


func _result_pages() -> Array:
	return _paginate_paragraphs(result_lines, 10, 712.0, 16)


func _ending_pages() -> Array:
	var body := _render_ending_body(current_ending.get("body", current_ending.get("text", [])))
	var final_line := _interpolate_ending_text(str(current_ending.get("final_line", "")))
	if not final_line.is_empty() and not body.has(final_line):
		body.append("—— %s" % final_line)
	return _paginate_paragraphs(body, 13, 850.0, 16)


func _render_ending_body(raw_body: Variant) -> Array[String]:
	var rendered: Array[String] = []
	var entries: Array = raw_body if raw_body is Array else [raw_body]
	for entry_value in entries:
		var paragraph := ""
		if entry_value is Dictionary:
			var conditional: Dictionary = entry_value
			var employee_id := str(conditional.get("employee_id", ""))
			if employee_id.is_empty():
				paragraph = str(conditional.get("text", ""))
			else:
				var branch := "present" if _has_employee(employee_id) else "absent"
				paragraph = str(conditional.get(branch, ""))
		else:
			paragraph = str(entry_value)
		if not paragraph.is_empty():
			rendered.append(_interpolate_ending_text(paragraph))
	var lin_echo := _lin_ending_echo()
	if not lin_echo.is_empty():
		rendered.append(lin_echo)
	var intranet_echo := _intranet_ending_echo()
	if not intranet_echo.is_empty():
		rendered.append(intranet_echo)
	var operating_echo := _operating_ending_echo()
	if not operating_echo.is_empty():
		rendered.append(operating_echo)
	return rendered


func _lin_ending_echo() -> String:
	if model == null:
		return ""
	if bool(model.flags.get("lin_last_scene_delegated", false)):
		return "最后一次谈话也由 LANTERN 替你完成。林越记住的不是答案，是你没有亲口说。"
	if bool(model.flags.get("lin_scene_4_lied", false)):
		return "林越把你说的『没有』和后来留下的版本记录放在一起。她没有再问第二遍。"
	if bool(model.flags.get("lin_scene_4_admitted", false)) or bool(model.flags.get("lin_low_author_truthful", false)) or bool(model.flags.get("lin_low_author_drift_admitted", false)):
		return "林越记得你至少有一次亲口承认：有些话已经分不清是谁写的。"
	if bool(model.flags.get("lin_warm_scene", false)):
		return "楼下那次啤酒什么都没解决，却留下一个没有交给模型代写的答案。"
	if bool(model.flags.get("lin_yue_left", false)) or bool(model.flags.get("lin_yue_departed_at_night_2", false)):
		return "林越离开之后，她的工位仍被系统列为一段可检索的历史。"
	return ""


func _intranet_ending_echo() -> String:
	if model == null:
		return ""
	var reviews: Array = Array(model.memory.get("intranet_action_reviews", []))
	if reviews.is_empty() or not reviews.back() is Dictionary:
		return ""
	var last_review: Dictionary = reviews.back()
	var title := str(last_review.get("title", "一份内网文档"))
	if str(last_review.get("author", "founder")) == "lantern":
		return "结局前，%s 替你审阅了《%s》。归档里只留下四个字：审阅通过。" % [_model_official_name(), title]
	return "结局前，你亲自为《%s》留下审阅标记。系统记住的不是停留时长，是署名。" % title


func _operating_ending_echo() -> String:
	if model == null or not bool(model.flags.get("expansion_systems_unlocked", false)):
		return ""
	var business_state: Dictionary = model.business.public_state()
	var ledger: Dictionary = business_state.get("ledger", {})
	var operations_state: Dictionary = model.operations.public_state()
	var office: Dictionary = operations_state.get("office", {})
	var lease: Dictionary = office.get("lease", {})
	var office_name := str(lease.get("name", "分布式办公室"))
	var policy: Dictionary = business_state.get("policy", {})
	var policy_note := ""
	if bool(policy.get("government_contractor", false)):
		policy_note = "、政府供应商资格"
	elif str(policy.get("standard_draft_status", "")) == "submitted":
		policy_note = "、一份进入工作组的行业标准草案"
	return "最后一份经营台账写着：现金 %s，MRR %s，%d 位付费客户，%d 人团队，办公室是%s%s。无论最后一段由谁写，这些数字是团队真正做出来的。" % [
		_format_usd_compact(int(ledger.get("cash_usd", 0))),
		_format_usd_compact(int(ledger.get("mrr_usd", 0))),
		int(ledger.get("customer_count", 0)),
		int(operations_state.get("active_employees", model.employees.size())) + 1,
		office_name,
		policy_note,
	]


func _interpolate_ending_text(raw_text: String) -> String:
	var rendered := raw_text
	var actual_company := str(model.company_name) if model != null else "提灯实验室"
	if rendered.contains("{{company_name}}"):
		rendered = rendered.replace("{{company_name}}", actual_company)
	else:
		# Legacy authored endings may still contain the old canonical default.
		# This branch is exclusive so a company named “新提灯实验室” cannot become
		# “新新提灯实验室” after token interpolation.
		rendered = rendered.replace("提灯实验室", actual_company)
	return rendered


func _paginate_paragraphs(paragraphs: Array[String], max_lines: int, width: float, font_size: int) -> Array:
	var pages: Array = []
	var page: Array[String] = []
	var used_lines := 0
	for paragraph in paragraphs:
		var wrapped := _wrap_text_px(paragraph, width, font_size)
		var needed := maxi(1, wrapped.size()) + 1
		if not page.is_empty() and used_lines + needed > max_lines:
			pages.append(page)
			page = []
			used_lines = 0
		page.append(paragraph)
		used_lines += needed
	if not page.is_empty() or pages.is_empty():
		pages.append(page)
	return pages


func _calendar_entries_for_day(day_index: int) -> Array:
	var fixed := HiringContent.get_fixed_event(int(model.chapter), int(model.week_in_chapter))
	var schedules := [
		[
			{"time": "09:30", "title": "本周计划"},
			{"time": "16:00", "title": "训练 / eval 同步"}
		],
		[
			{"time": "10:00", "title": "产品与研究"},
			{"time": "15:30", "title": "候选人面试"}
		],
		[
			{"time": "11:00", "title": "客户进度"},
			{"time": "17:00", "title": "全员会"}
		],
		[
			{"time": "14:00", "title": "融资材料"},
			{"time": "23:00", "title": "发布窗口"}
		],
		[
			{"time": "10:30", "title": "周报归档"},
			{"time": "18:30", "title": "办公室轮值"}
		]
	]
	var result: Array = Array(schedules[clampi(day_index, 0, schedules.size() - 1)]).duplicate(true)
	if day_index == 2 and not fixed.is_empty() and not _event_is_silent(fixed):
		result[0] = {"time": "11:00", "title": str(fixed.get("title", "本周事项"))}
	if day_index == 3 and bool(model.flags.get("meeting_room_d_available", false)):
		result[1] = {"time": "下周", "title": "会议室 D · 同时段"}
	return result


func _announcement_items() -> Array:
	var items: Array = [
		{"title": "本周工作区已开放", "meta": "运营 · 第 %d 周" % int(model.total_week), "metric": "%d 项待处理" % week_action_ids.size()},
		{"title": "服务器与算力使用说明", "meta": "基础设施 · 长期有效", "metric": "%s units" % _format_number(model.compute)}
	]
	var industry_echo: Dictionary = Dictionary(model.memory.get("last_industry_echo", {}))
	if not industry_echo.is_empty():
		items.push_front({
			"title": str(industry_echo.get("title", "行业回声已处理")),
			"meta": "行业回声 · 第 %d 周" % int(industry_echo.get("week", model.total_week)),
			"metric": str(industry_echo.get("choice_label", "已归档")),
		})
	var ambient_feed: Array = Array(model.memory.get("industry_ambient_feed", []))
	# Only the two newest background jokes stay pinned. They are explicitly
	# labelled as observation, so a player never mistakes them for a missed task.
	for index in range(maxi(0, ambient_feed.size() - 2), ambient_feed.size()):
		if not ambient_feed[index] is Dictionary:
			continue
		var ambient: Dictionary = ambient_feed[index]
		items.push_front({
			"title": str(ambient.get("title", "行业又发生了一件事")),
			"meta": "行业边角料 · 第 %d 周 · 纯围观" % int(ambient.get("week", model.total_week)),
			"metric": str(ambient.get("metric", "不占注意力")),
		})
	if bool(model.flags.get("seen_investor_repost", false)) or int(model.chapter) >= 2:
		items.push_front({"title": "一位投资人转发了团队动态", "meta": "社交媒体 · 未附评论", "metric": "转发"})
	if bool(model.flags.get("seen_hiring_page_traffic", false)):
		items.push_front({"title": "招聘页面周度数据", "meta": "人才 · 自动归档", "metric": "4,200 / 3"})
	if bool(model.flags.get("after_add_employee_shen_yan", false)) or _has_employee("shen_yan"):
		items.push_front({"title": "沈砚提交了本周周报", "meta": "战略项目 · 准时", "metric": "已提交"})
	if bool(model.flags.get("board_resolved", false)):
		items.push_front({"title": "董事会材料已归档", "meta": "董事会办公室 · LANTERN", "metric": "已批准"})
	if int(model.chapter) >= 4:
		items.push_front({"title": "季度投资材料", "meta": "内部沟通 · 今天", "metric": "LANTERN"})
	return items


func _announcement_page_count() -> int:
	if model == null:
		return 1
	var item_count := _announcement_items().size()
	return maxi(1, int(ceil(float(item_count) / float(_announcement_balanced_page_size(item_count)))))


func _announcement_balanced_page_size(item_count: int) -> int:
	if item_count <= 0:
		return ANNOUNCEMENTS_PER_PAGE
	var page_count := maxi(1, int(ceil(float(item_count) / float(ANNOUNCEMENTS_PER_PAGE))))
	return mini(ANNOUNCEMENTS_PER_PAGE, int(ceil(float(item_count) / float(page_count))))


func _announcement_sidebar_metrics() -> Dictionary:
	var visible := model != null and bool(model.flags.get("seen_hiring_page_traffic", false))
	return {
		"visible": visible,
		"views": "4,200" if visible else "—",
		"applications": "3" if visible else "—",
	}


func _employee_profile(employee: Dictionary) -> Dictionary:
	var employee_id := str(employee.get("id", ""))
	if HiringContent.EMPLOYEE_TEMPLATES.has(employee_id):
		return HiringContent.EMPLOYEE_TEMPLATES[employee_id]
	for template_id in HiringContent.EMPLOYEE_TEMPLATES.keys():
		if employee_id.begins_with(str(template_id) + "_"):
			return HiringContent.EMPLOYEE_TEMPLATES[template_id]
	return employee


func _document_meta(document: Dictionary) -> String:
	var pieces: Array[String] = []
	for key in ["type", "author", "date"]:
		var value := str(document.get(key, ""))
		if not value.is_empty():
			pieces.append(value)
	return " · ".join(pieces) if not pieces.is_empty() else "内部"


func _intranet_documents() -> Array:
	var docs: Array = []
	for value in HiringContent.INTRANET_DOCS.values():
		if not value is Dictionary:
			continue
		var document: Dictionary = value
		var document_chapter := int(document.get("chapter", 0))
		var document_week := int(document.get("week", 1))
		var available := document_chapter < int(model.chapter) or (document_chapter == int(model.chapter) and document_week <= int(model.week_in_chapter))
		if available:
			docs.append(_personalize_internal_document(document.duplicate(true)))
	docs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", "")))
	return docs


func _selected_document_pages(docs: Array = []) -> Array:
	var source_docs := docs if not docs.is_empty() else _intranet_documents()
	if source_docs.is_empty():
		return [[]]
	var selected: Dictionary = source_docs[clampi(selected_document, 0, source_docs.size() - 1)]
	var body_height := 346.0
	if str(selected.get("id", "")) == "our_origin" and (_origin_interaction_required() or bool(model.flags.get("origin_article_interaction_complete", false))):
		body_height -= 60.0
	return _paginate_document_paragraphs(_to_string_array(selected.get("body", [])), 642.0, TYPE_BODY, 24.0, body_height)


func _paginate_document_paragraphs(paragraphs: Array[String], width: float, font_size: int, line_height: float, max_height: float) -> Array:
	var pages: Array = []
	var page: Array[String] = []
	var used_height := 0.0
	var paragraph_gap := line_height * 0.48
	for index in paragraphs.size():
		var paragraph := paragraphs[index]
		var needed_height := _document_paragraph_height(paragraph, width, font_size, line_height, paragraph_gap)
		var keep_with_next_height := 0.0
		if _is_document_section_heading(paragraph) and index + 1 < paragraphs.size():
			# A heading must share the page with at least the first body line.
			keep_with_next_height = line_height + paragraph_gap
		if not page.is_empty() and used_height + needed_height + keep_with_next_height > max_height:
			pages.append(page)
			page = []
			used_height = 0.0
		if not page.is_empty() and used_height + needed_height > max_height:
			pages.append(page)
			page = []
			used_height = 0.0
		page.append(paragraph)
		used_height += needed_height
	if not page.is_empty() or pages.is_empty():
		pages.append(page)
	_rebalance_sparse_document_tail(pages, width, font_size, line_height, paragraph_gap, max_height)
	return pages


func _document_paragraph_height(paragraph: String, width: float, font_size: int, line_height: float, paragraph_gap: float) -> float:
	return float(maxi(1, _wrap_text_px(paragraph, width, font_size).size())) * line_height + paragraph_gap


func _rebalance_sparse_document_tail(pages: Array, width: float, font_size: int, line_height: float, paragraph_gap: float, max_height: float) -> void:
	if pages.size() < 2:
		return
	var tail: Array = pages[pages.size() - 1]
	var tail_height := 0.0
	for paragraph_value in tail:
		tail_height += _document_paragraph_height(str(paragraph_value), width, font_size, line_height, paragraph_gap)
	# A nearly empty final sheet looks accidental. Pull the previous complete
	# section forward so the turn feels editorially intentional, never orphaned.
	if tail_height >= max_height * 0.34:
		return
	var previous: Array = pages[pages.size() - 2]
	var section_start := -1
	for index in range(previous.size() - 1, -1, -1):
		if _is_document_section_heading(str(previous[index])):
			section_start = index
			break
	if section_start <= 0:
		return
	var moved_height := 0.0
	for index in range(section_start, previous.size()):
		moved_height += _document_paragraph_height(str(previous[index]), width, font_size, line_height, paragraph_gap)
	if tail_height + moved_height > max_height:
		return
	var balanced_tail: Array[String] = []
	for index in range(section_start, previous.size()):
		balanced_tail.append(str(previous[index]))
	for paragraph_value in tail:
		balanced_tail.append(str(paragraph_value))
	previous.resize(section_start)
	pages[pages.size() - 2] = previous
	pages[pages.size() - 1] = balanced_tail


func _is_document_section_heading(paragraph: String) -> bool:
	var normalized := paragraph.strip_edges()
	return normalized in ["本周完成", "下周计划", "风险", "需要协助"] or ((normalized.ends_with("：") or normalized.ends_with(":")) and normalized.length() <= 18)


func _personalize_internal_document(document: Dictionary) -> Dictionary:
	var actual_company := str(model.company_name) if model != null else "提灯实验室"
	document["title"] = str(document.get("title", "")).replace("提灯实验室", actual_company)
	var body := _to_string_array(document.get("body", []))
	for index in body.size():
		body[index] = body[index].replace("提灯实验室", actual_company)
	var document_id := str(document.get("id", ""))
	if model != null and int(model.memory.get("values_version", 0)) >= 3 and model.writer_stage() >= 3 and document_id != "values_v1":
		var combined := str(document.get("title", "")) + "\n" + "\n".join(body)
		if not combined.contains("第三版价值观") and document_id != "values_v3":
			body.append("内部表述依据：%s价值观 · 第三版。" % actual_company)
		document["memory_callback"] = "values_v3_written"
		document["values_basis"] = "第三版价值观"
	document["body"] = body
	return document


func _select_intranet_document(document_id: String) -> bool:
	var docs := _intranet_documents()
	for index in docs.size():
		if str(Dictionary(docs[index]).get("id", "")) == document_id:
			selected_document = index
			document_page = 0
			return true
	return false


func _mark_selected_document_read() -> bool:
	if model == null:
		return false
	var docs := _intranet_documents()
	if docs.is_empty():
		return false
	selected_document = clampi(selected_document, 0, docs.size() - 1)
	var document: Dictionary = docs[selected_document]
	var document_id := str(document.get("id", "document"))
	for flag_value in document.get("flags", []):
		model.flags[str(flag_value)] = true
	model.flags["read_%s" % document_id] = true
	model.memory["last_read_intranet"] = document_id
	if document_id == "our_origin":
		var previous_count := clampi(int(model.memory.get("origin_read_count", 0)), 0, 3)
		if previous_count < 3:
			var read_count := previous_count + 1
			model.memory["origin_read_count"] = read_count
			if read_count == 3 and not bool(model.flags.get("origin_editor_closed_without_change", false)):
				model.flags["origin_attribution_realized"] = true
				model.flags["origin_editor_open"] = true
				model.flags["origin_editor_closed_without_change"] = false
	return bool(_save_game().get("ok", false))


func _latest_intranet_document_index(docs: Array) -> int:
	if docs.is_empty():
		return 0
	var latest_index := 0
	var latest_order := -1
	for index in docs.size():
		var document: Dictionary = docs[index]
		var order := int(document.get("chapter", 0)) * 100 + int(document.get("week", 0))
		if order > latest_order:
			latest_order = order
			latest_index = index
	return latest_index


func _record_intranet_action_review(docs: Array, use_ai: bool) -> void:
	if model == null or docs.is_empty():
		return
	selected_document = clampi(selected_document, 0, docs.size() - 1)
	var document: Dictionary = docs[selected_document]
	var reviews: Array = Array(model.memory.get("intranet_action_reviews", [])).duplicate(true)
	reviews.append({
		"week": int(model.total_week),
		"document_id": str(document.get("id", "document")),
		"title": str(document.get("title", "文档")),
		"author": "lantern" if use_ai else "founder",
	})
	model.memory["intranet_action_reviews"] = reviews
	model.memory["last_intranet_action_review_week"] = int(model.total_week)


func _current_week_intranet_review() -> Dictionary:
	if model == null:
		return {}
	var reviews: Array = Array(model.memory.get("intranet_action_reviews", []))
	for offset in reviews.size():
		var index := reviews.size() - 1 - offset
		if reviews[index] is Dictionary:
			var review: Dictionary = reviews[index]
			if int(review.get("week", -1)) == int(model.total_week):
				return review
	return {}


func _origin_editor_is_open() -> bool:
	return model != null and bool(model.flags.get("origin_editor_open", false)) and not bool(model.flags.get("origin_editor_closed_without_change", false))


func _origin_interaction_required() -> bool:
	return (
		model != null
		and bool(model.flags.get("origin_article_interaction_required", false))
		and not bool(model.flags.get("origin_editor_closed_without_change", false))
	)


func _close_origin_editor_without_change() -> void:
	if not _origin_editor_is_open():
		return
	_play_foley("page")
	model.flags["origin_editor_open"] = false
	model.flags["origin_editor_closed_without_change"] = true
	model.flags["origin_article_unchanged"] = true
	model.flags["origin_article_interaction_required"] = false
	model.flags["origin_article_interaction_complete"] = true
	model.memory["origin_editor_close_count"] = 1
	_save_game()
	queue_redraw()


func _team_administrative_count() -> int:
	return WINDOW_TOTAL_PERSON_COUNT if model != null and bool(model.flags.get("window_desks", false)) else 1 + int(model.employees.size())


func _window_exterior_person_count() -> int:
	return maxi(0, WINDOW_TOTAL_PERSON_COUNT - WINDOW_INTERIOR_PERSON_COUNT)


func _window_population_fixture() -> Dictionary:
	return {
		"inside": WINDOW_INTERIOR_PERSON_COUNT,
		"outside": _window_exterior_person_count(),
		"total": WINDOW_TOTAL_PERSON_COUNT,
	}


func _team_desk_signal() -> String:
	return "chen_three_cups" if model != null and _has_active_employee("chen_xiaoyu") else "none"


func _window_anomaly_visible() -> bool:
	return model != null and bool(model.flags.get("window_desks", false)) and not bool(model.flags.get("window_curtain_closed", false))


func _window_interaction_required() -> bool:
	return (
		model != null
		and bool(model.flags.get("window_curtain_interaction_required", false))
		and not bool(model.flags.get("window_curtain_interaction_complete", false))
	)


func _close_window_curtain() -> void:
	if not _window_anomaly_visible() or screen != Screen.TEAM:
		return
	_play_foley("curtain")
	model.flags["window_curtain_open"] = false
	model.flags["window_curtain_closed"] = true
	model.flags["window_curtain_pending_reopen"] = true
	model.flags["window_curtain_reopened"] = false
	if _window_interaction_required():
		model.flags["window_curtain_interaction_required"] = false
		model.flags["window_curtain_interaction_complete"] = true
	model.memory["window_curtain_close_count"] = int(model.memory.get("window_curtain_close_count", 0)) + 1
	_save_game()
	queue_redraw()


func _night_for_current_week() -> Dictionary:
	if int(model.chapter) == 2 and int(model.week_in_chapter) == 12:
		return HiringContent.get_night_shift(1)
	if int(model.chapter) == 3 and int(model.week_in_chapter) == 14:
		return HiringContent.get_night_shift(2)
	return {}


func _night_complete() -> bool:
	return night_interaction != null and night_interaction.can_leave()


func _action_data(action_id: String) -> Dictionary:
	if HiringContent.ACTIONS.has(action_id):
		return HiringContent.ACTIONS[action_id]
	if HiringExpansionContent.SYSTEM_ACTIONS.has(action_id):
		return HiringExpansionContent.SYSTEM_ACTIONS[action_id]
	return {"id": action_id, "name": action_id, "category": "运营", "attention": 1, "description": ""}


func _action_display_description(action_id: String, action: Dictionary) -> String:
	if action_id == "eval" and model != null and bool(model.flags.get("capability_revealed", false)):
		return str(action.get("repeat_description", action.get("description", "")))
	return str(action.get("description", ""))


func _action_effect_summary(action_id: String, use_ai: bool) -> String:
	if action_id == "sign":
		return "无可见数值变化"
	if action_id == "read_intranet":
		return "留下署名审阅"
	if action_id == "one_on_one":
		return "进入具名员工对话" if not use_ai else "由模型代答 · 员工会记住"
	var action := _action_data(action_id)
	var authored_summary_key := "ai_summary" if use_ai else "manual_summary"
	if action.has(authored_summary_key):
		return str(action[authored_summary_key])
	var effects := _action_preview_effects(action_id, use_ai)
	if action_id == "large_train":
		var capability_range: Array = effects.get("capability", [])
		if capability_range.size() >= 2:
			return "能力 %s–%s · 算力 %s" % [_signed_number(capability_range[0]), _signed_number(capability_range[1]), _signed_number(effects.get("compute", 0.0))]
	if action_id == "buy_compute":
		return "算力 %s · 现金周 %s" % [_signed_number(effects.get("compute", 0.0)), _signed_number(effects.get("cash_weeks", 0.0))]
	var labels := {
		"narrative": "叙事", "capability": "能力", "coherence": "连贯", "morale": "士气",
		"cash_weeks": "现金周", "compute": "算力", "team_size": "人数", "belief": "信念",
		"burn_rate": "烧钱档", "training_boost_uses": "训练增益",
	}
	var pieces: Array[String] = []
	for key in ["narrative", "capability", "coherence", "morale", "cash_weeks", "compute", "team_size", "belief", "burn_rate", "training_boost_uses"]:
		if not effects.has(key):
			continue
		var raw = effects[key]
		if raw is Array and raw.size() >= 2:
			pieces.append("%s %s–%s" % [labels[key], _signed_number(raw[0]), _signed_number(raw[1])])
		else:
			pieces.append("%s %s" % [labels[key], _signed_number(raw)])
	if effects.has("fundraise_by_narrative"):
		pieces.append("按叙事融资")
	if effects.has("open_hiring"):
		pieces.append("打开候选人")
	if effects.has("reveal_capability"):
		pieces.append("核验能力")
	if effects.has("open_intranet"):
		pieces.append("留下署名审阅")
	if effects.has("block_training"):
		pieces.append("锁定训练窗")
	if pieces.is_empty():
		return "无数值变化"
	return " · ".join(pieces.slice(0, 2))


func _action_preview_effects(action_id: String, use_ai: bool) -> Dictionary:
	# Preview the same stateful base resolution used by HiringModel, then apply
	# its shared delegation advantage. HiringContent.ai_effects is retained as
	# authorship metadata; it is not a second, contradictory settlement table.
	var action := _action_data(action_id)
	var effects: Dictionary = Dictionary(action.get("effects", {})).duplicate(true)
	match action_id:
		"tech_blog":
			effects.erase("debt_if_capability_below_40")
			if model != null and float(model.capability) < float(model.TECH_BLOG_CAPABILITY_THRESHOLD):
				effects["debt"] = 4.0
		"exclusive_interview":
			if model != null and float(model.debt) > float(model.EXCLUSIVE_INTERVIEW_DEBT_THRESHOLD):
				effects = {"narrative": [-8.0, 20.0], "coherence": [-5.0, 0.0]}
			else:
				effects = {"narrative": 20.0}
		"train":
			var boost := 1.5 if model != null and int(model.training_boost_uses) > 0 else 1.0
			effects = {"capability": [3.0 * boost, 6.0 * boost], "compute": -1.0}
		"eval":
			effects = {"compute": -1.0}
			if model != null and not bool(model.flags.get("capability_revealed", false)):
				effects["debt"] = -5.0
		"large_train":
			var large_boost := 1.5 if model != null and int(model.training_boost_uses) > 0 else 1.0
			effects = {"capability": [12.0 * large_boost, 18.0 * large_boost], "compute": -8.0}
		"all_hands":
			effects.erase("coherence_if_contradiction")
			if model != null and (bool(model.flags.get("recent_layoffs", false)) or bool(model.flags.get("contradictory_all_hands", false))):
				effects["coherence"] = -12.0
		"fundraising":
			var raised := 0.0
			if model != null and float(model.narrative) >= 20.0:
				raised = 4.0 + floorf(float(model.narrative) / 15.0)
			effects = {"cash_weeks": raised if raised > 0.0 else -1.0}
		"read_intranet":
			effects = {"open_intranet": 1}
	if not use_ai or action_id == "sign":
		return effects
	if action_id == "read_intranet":
		effects["author_weight"] = float(Dictionary(action.get("ai_effects", {})).get("author_weight", 0.0))
		return effects
	_add_preview_numeric_effect(effects, "cash_weeks", 1.0)
	if action_id != "one_on_one":
		_add_preview_numeric_effect(effects, "morale", 4.0)
	if action_id != "eval" or effects.has("debt"):
		_add_preview_numeric_effect(effects, "debt", -3.0)
	_add_preview_numeric_effect(effects, "author_weight", float(Dictionary(action.get("ai_effects", {})).get("author_weight", 0.0)))
	if action_id in ["tweet", "tech_blog", "podcast", "demo_video", "conference_talk", "manifesto", "exclusive_interview"]:
		_add_preview_numeric_effect(effects, "narrative", 2.0)
	if action_id in ["train", "large_train", "clean_data", "alignment_week"]:
		_add_preview_numeric_effect(effects, "capability", 1.0)
	return effects


func _add_preview_numeric_effect(effects: Dictionary, key: String, amount: float) -> void:
	if is_zero_approx(amount):
		return
	if not effects.has(key):
		effects[key] = amount
		return
	var current = effects[key]
	if current is Array and current.size() >= 2:
		effects[key] = [float(current[0]) + amount, float(current[1]) + amount]
	elif current is int or current is float:
		effects[key] = float(current) + amount


func _signed_number(value: Variant) -> String:
	var formatted := _format_number(value)
	return "+" + formatted if float(value) > 0.0 else formatted


func _action_compute_requirement(action_id: String, _use_ai: bool) -> int:
	match action_id:
		"train", "eval":
			return 1
		"large_train":
			return 8
	return 0


func _action_unavailable_reason(action_id: String, use_ai: bool) -> String:
	if used_action_ids.has(action_id):
		return "本周已处理"
	if action_id in ["train", "large_train"] and bool(model.flags.get("training_blocked_this_week", false)):
		return "外包占用本周训练窗口"
	var required_compute := _action_compute_requirement(action_id, use_ai)
	if required_compute > 0 and float(model.compute) < float(required_compute):
		return "算力不足：需要 %d，当前 %s" % [required_compute, _format_number(model.compute)]
	if not use_ai and int(model.attention) < int(_action_data(action_id).get("attention", 1)):
		return "注意力不足"
	if use_ai and bool(model.flags.get("ai_used_this_week", false)):
		return "本周已委托一次"
	if model != null and model.has_method("operating_action_status"):
		var operating_status_value = model.operating_action_status(action_id)
		if operating_status_value is Dictionary:
			var operating_status: Dictionary = operating_status_value
			if not bool(operating_status.get("available", true)):
				return str(operating_status.get("reason", "当前经营节点尚未开放"))
	return "当前条件不满足"


func _compact_action_unavailable_reason(action_id: String, use_ai: bool) -> String:
	var required_compute := _action_compute_requirement(action_id, use_ai)
	if required_compute > 0 and float(model.compute) < float(required_compute):
		return "需算力 %d / 当前 %s" % [required_compute, _format_number(model.compute)]
	return _action_unavailable_reason(action_id, use_ai)


func _action_name(action_id: String) -> String:
	return str(_action_data(action_id).get("name", action_id))


func _category_color(category: String) -> Color:
	match category:
		"叙事", "narrative": return AMBER
		"能力", "capability": return BLUE
		"团队", "team": return GREEN
		"经营", "strategy": return BLUE
		_: return COLD_60


func _category_label(category: String) -> String:
	match category:
		"narrative": return "叙事"
		"capability": return "能力"
		"team": return "团队"
		"operations": return "运营"
		"strategy": return "经营"
		"finale": return "终局"
		_: return category


func _chapter_label() -> String:
	var chapter_data: Dictionary = content.chapter(int(model.chapter))
	return str(chapter_data.get("name", "第 %d 章" % int(model.chapter)))


func _model_official_name() -> String:
	var chapter_data: Dictionary = content.chapter(int(model.chapter))
	return str(chapter_data.get("model_official", chapter_data.get("official_name", "lantern-v0.1")))


func _model_private_name() -> String:
	var chapter_data: Dictionary = content.chapter(int(model.chapter))
	var nickname := str(chapter_data.get("model_nickname", chapter_data.get("nickname", "阿灯")))
	return nickname if not nickname.is_empty() else "——"


func _content_call(method: StringName, args: Array, fallback):
	if content.has_method(method):
		return content.callv(method, args)
	return fallback


func _screen_save_name(screen_value: int) -> String:
	var names := {
		Screen.ONBOARDING: "onboarding", Screen.DASHBOARD: "dashboard", Screen.ACTION_RESULT: "action_result",
		Screen.EVENT: "event", Screen.TEAM: "team", Screen.TERMINAL: "terminal", Screen.INTRANET: "intranet",
		Screen.NIGHT_SHIFT: "night_shift", Screen.ENDING: "ending", Screen.CALENDAR: "calendar",
		Screen.ANNOUNCEMENTS: "announcements", Screen.SIGNATURE: "signature",
		Screen.BOARD_PRESENTATION: "board_presentation", Screen.LIVE_REPLAY: "live_replay",
		Screen.LAYOFF_SOCIAL: "layoff_social",
	}
	return str(names.get(screen_value, "dashboard"))


func _screen_from_save(payload: Dictionary) -> int:
	var by_name := {
		"onboarding": Screen.ONBOARDING, "dashboard": Screen.DASHBOARD, "action_result": Screen.ACTION_RESULT,
		"event": Screen.EVENT, "team": Screen.TEAM, "terminal": Screen.TERMINAL, "intranet": Screen.INTRANET,
		"night_shift": Screen.NIGHT_SHIFT, "ending": Screen.ENDING, "calendar": Screen.CALENDAR,
		"announcements": Screen.ANNOUNCEMENTS, "signature": Screen.SIGNATURE,
		"board_presentation": Screen.BOARD_PRESENTATION, "live_replay": Screen.LIVE_REPLAY,
		"layoff_social": Screen.LAYOFF_SOCIAL,
	}
	var saved_name := str(payload.get("ui_screen_name", ""))
	if by_name.has(saved_name):
		return int(by_name[saved_name])
	return clampi(int(payload.get("ui_screen", Screen.DASHBOARD)), Screen.ONBOARDING, Screen.LAYOFF_SOCIAL)


func _save_exists_or_recoverable() -> bool:
	var path := _save_file_path()
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


func _report_loaded_storage_status(loaded: Dictionary) -> Dictionary:
	if bool(loaded.get("migration_required", false)):
		var migrated := _save_game()
		if bool(migrated.get("ok", false)):
			var backup_copy := "；旧文件已验证备份" if bool(migrated.get("backup_created", false)) else ""
			_show_toast("旧存档已安全升级%s。" % backup_copy)
		else:
			_show_toast("旧存档已加载，但升级写入失败；原档未被覆盖。")
		return migrated
	if bool(loaded.get("used_backup", false)):
		if bool(loaded.get("primary_restored", false)):
			_show_toast("主存档异常，已从备份加载并修复。")
			return {"ok": true, "status": "backup_loaded_and_repaired"}
		_show_toast("已从备份加载；主存档尚未修复。")
		return {"ok": true, "status": "backup_loaded_repair_failed"}
	return {"ok": true, "status": "primary_loaded"}


func _recover_meta_from_campaign(payload: Dictionary) -> void:
	var recovery_value = payload.get("ui_meta_recovery", {})
	if not recovery_value is Dictionary:
		return
	var recovery: Dictionary = recovery_value
	if recovery.is_empty():
		return
	second_run_unlocked = second_run_unlocked or bool(recovery.get("second_run", false))
	var recovered_last := str(recovery.get("last_ending", ""))
	if not recovered_last.is_empty():
		last_ending_id = recovered_last
	for ending_id in _to_string_array(recovery.get("seen_endings", [])):
		if not seen_endings.has(ending_id):
			seen_endings.append(ending_id)
	# A campaign save is the durable fallback when the smaller meta file could not
	# be committed. Retry immediately; failure is harmless because the campaign
	# remains intact and every later autosave keeps this recovery envelope.
	_save_meta()


func _register_seen_ending(ending_id: String) -> Dictionary:
	if ending_id.is_empty():
		return {"ok": false, "status": "empty_ending_id"}
	if not seen_endings.has(ending_id):
		seen_endings.append(ending_id)
	return _save_meta()


func _save_game() -> Dictionary:
	if screen == Screen.ONBOARDING:
		return {"ok": false, "status": "skipped_onboarding", "message": "No campaign save is written on onboarding."}
	var payload: Dictionary = director.save_payload()
	payload["ui_schema_version"] = UI_SCHEMA_VERSION
	payload["ui_used_actions"] = used_action_ids
	payload["ui_used_action_authors"] = used_action_authors
	payload["ui_week_actions"] = week_action_ids
	payload["ui_action_pool_week"] = int(model.total_week)
	payload["ui_terminal"] = terminal_lines
	payload["ui_screen"] = int(screen)
	payload["ui_screen_name"] = _screen_save_name(screen)
	payload["ui_pending_week_advance"] = pending_week_advance
	payload["ui_pending_night_id"] = pending_night_id
	payload["ui_result_title"] = result_title
	payload["ui_result_lines"] = result_lines
	payload["ui_result_return"] = result_return
	payload["ui_result_page"] = result_page
	payload["ui_current_event"] = current_event
	payload["ui_current_event_page"] = current_event_page
	payload["ui_event_page_elapsed"] = event_page_elapsed
	payload["ui_current_ending_id"] = current_ending_id
	payload["ui_current_ending"] = current_ending
	payload["ui_ending_page"] = ending_page
	payload["ui_current_night"] = current_night
	payload["ui_night_seen"] = night_seen
	payload["ui_night_focus_index"] = night_focused_object_index
	payload["ui_night_interaction"] = night_interaction.to_save() if night_interaction != null else {}
	payload["ui_selected_action"] = selected_action
	payload["ui_selected_document"] = selected_document
	payload["ui_document_page"] = document_page
	payload["ui_team_page"] = team_page
	payload["ui_announcement_page"] = announcement_page
	payload["ui_meta_recovery"] = {
		"second_run": second_run_unlocked,
		"last_ending": last_ending_id,
		"seen_endings": seen_endings,
	}
	var saved: Dictionary = HiringStorage.save_dictionary(_save_file_path(), payload)
	if bool(saved.get("ok", false)):
		save_status_text = "已自动保存"
		save_status_timer = 1.8
	else:
		save_status_text = "保存失败"
		save_status_timer = 4.0
		_show_toast("自动保存失败；没有覆盖上一份可用存档。")
		push_error("HIRING_SAVE_FAILURE: %s" % str(saved.get("message", saved.get("status", "unknown"))))
	return saved


func _save_file_path() -> String:
	return save_path_override if not save_path_override.is_empty() else SAVE_PATH


func _meta_file_path() -> String:
	return meta_path_override if not meta_path_override.is_empty() else META_PATH


func _load_meta() -> void:
	var loaded: Dictionary = HiringStorage.load_dictionary(_meta_file_path())
	if not bool(loaded.get("ok", false)):
		return
	var parsed: Dictionary = Dictionary(loaded.get("data", {}))
	second_run_unlocked = bool(parsed.get("second_run", false))
	last_ending_id = str(parsed.get("last_ending", ""))
	seen_endings = _to_string_array(parsed.get("seen_endings", []))
	reduced_motion = bool(parsed.get("reduced_motion", false))
	if office_audio != null:
		office_audio.muted = bool(parsed.get("audio_muted", false))
	if DisplayServer.get_name() != "headless" and bool(parsed.get("fullscreen", false)):
		get_window().mode = Window.MODE_FULLSCREEN
	if bool(loaded.get("migration_required", false)):
		_save_meta()


func _save_meta() -> Dictionary:
	var payload := {
		"second_run": second_run_unlocked,
		"last_ending": last_ending_id,
		"seen_endings": seen_endings,
		"reduced_motion": reduced_motion,
		"audio_muted": office_audio != null and office_audio.muted,
		"fullscreen": get_window().mode == Window.MODE_FULLSCREEN,
	}
	var saved: Dictionary = HiringStorage.save_dictionary(_meta_file_path(), payload)
	if not bool(saved.get("ok", false)):
		push_error("HIRING_META_SAVE_FAILURE: %s" % str(saved.get("message", saved.get("status", "unknown"))))
	return saved


func _show_toast(message: String, kind: String = "auto") -> void:
	toast_text = message
	toast_kind = _infer_toast_kind(message) if kind == "auto" else kind
	toast_duration = {"error": 5.2, "warning": 4.5}.get(toast_kind, 2.6)
	toast_timer = toast_duration


func _infer_toast_kind(message: String) -> String:
	for marker in ["失败", "无法读取", "没有覆盖", "初始化失败"]:
		if message.contains(marker):
			return "error"
	for marker in ["不足", "不能", "尚未", "不可", "还未", "再次", "做不了", "无法提交", "无法推进"]:
		if message.contains(marker):
			return "warning"
	for marker in ["已开启", "已关闭", "已恢复", "已登记", "安全升级", "已修复"]:
		if message.contains(marker):
			return "success"
	return "info"


func _toggle_fullscreen() -> void:
	_play_foley("switch")
	get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	_save_meta()


func _format_number(value) -> String:
	var number := float(value)
	return "%d" % int(round(number)) if is_equal_approx(number, round(number)) else "%.1f" % number


func _runway_weeks() -> int:
	return int(model.public_state().get("runway_weeks", 0))


func _to_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is String:
		result.append(str(value))
	elif value is Array:
		for item in value:
			result.append(str(item))
	return result


func _draw_paper_card(rect: Rect2, fill: Color, border: Color, radius: float, shadow_depth: float = 4.0, border_width: float = 1.0) -> void:
	if shadow_depth > 0.0:
		_draw_panel(Rect2(rect.position + Vector2(2, minf(3.0, shadow_depth)), rect.size), Color(0.015, 0.045, 0.055, 0.11), Color.TRANSPARENT, minf(radius, RADIUS_CARD), 0.0)
	_draw_panel(rect, fill, border, minf(radius, RADIUS_CARD), border_width)
	draw_line(rect.position + Vector2(10, rect.size.y - 1), rect.end - Vector2(10, 1), Color(0.20, 0.26, 0.25, 0.10), 1.0)


func _draw_folio_stamp(rect: Rect2, label: String, color: Color, angle: float = 0.0) -> void:
	var local_rect := Rect2(-rect.size * 0.5, rect.size)
	draw_set_transform(rect.get_center(), angle)
	_draw_panel(local_rect, Color(color, 0.035), Color(color, 0.82), 1.0, 1.5)
	_draw_panel(local_rect.grow(-4.0), Color.TRANSPARENT, Color(color, 0.42), 1.0, 1.0)
	_draw_text_centered(label, local_rect, 12, Color(color, 0.92), 2.0)
	draw_set_transform(Vector2.ZERO)


func _draw_ledger_button(rect: Rect2, label: String, shortcut: String = "", variant: String = "primary", enabled: bool = true, focused: bool = false) -> void:
	var fill := SURFACE_DARK
	var text_color := Color.WHITE
	var border := GREEN_BRIGHT
	match variant:
		"secondary":
			fill = SURFACE
			text_color = PAPER_GREEN
			border = GREEN
		"quiet":
			fill = SURFACE
			text_color = MUTED
			border = LINE
		"attention":
			# Warmth belongs in the word, not in an outline. This is the one human
			# decision on a cold screen; it should read as ink, not as a warning.
			fill = WARM_05
			text_color = PAPER_AMBER
			border = WARM_40
		"danger":
			fill = COLD_00
			text_color = RED
			border = RED
		"night":
			fill = INK
			text_color = NIGHT_TEXT
			border = COLD_50
	if not enabled:
		fill = DISABLED_BG
		text_color = DISABLED_TEXT
		border = LINE
	var hovered := enabled and rect.has_point(mouse_position)
	var pressed := hovered and press_feedback_timer > 0.0 and rect.has_point(press_feedback_position)
	if hovered:
		var hover_tint := RED if variant == "danger" else GREEN_BRIGHT
		fill = fill.lerp(hover_tint, 0.08)
		border = hover_tint
	var offset := Vector2(0, 1) if pressed else Vector2.ZERO
	var shadow_depth := 1.0 if pressed else 3.0
	_draw_panel(Rect2(rect.position + Vector2(0, shadow_depth), rect.size), Color(0.015, 0.045, 0.055, 0.14), Color.TRANSPARENT, RADIUS_CONTROL, 0.0)
	var face := Rect2(rect.position + offset, rect.size)
	_draw_panel(face, fill, border, RADIUS_CONTROL, 1.5 if hovered or focused else 1.0)
	if focused:
		_draw_panel(face.grow(4.0), Color.TRANSPARENT, GREEN_BRIGHT, RADIUS_CONTROL + 3.0, 2.0)
	# The label carries the decision; it should not be the same size as the page
	# numbers. Long fallback labels ("需算力 8 / 当前 7") step down one rung so a
	# blocked control still reads as one line rather than clipping.
	var label_size := TYPE_ACTION if label.length() <= 7 else TYPE_LABEL
	if shortcut.is_empty():
		_draw_text_centered(label, face, label_size, text_color, 2.0)
	else:
		var key_width := maxf(48.0, font.get_string_size(shortcut, HORIZONTAL_ALIGNMENT_LEFT, -1, TYPE_META).x + 20.0)
		var label_rect := Rect2(face.position + Vector2(10, 0), Vector2(face.size.x - key_width - 14.0, face.size.y))
		var key_rect := Rect2(face.end.x - key_width, face.position.y, key_width, face.size.y)
		draw_line(Vector2(key_rect.position.x, face.position.y + 10), Vector2(key_rect.position.x, face.end.y - 10), Color(border, 0.34), 1.0)
		_draw_text_centered(label, label_rect, label_size, text_color, 2.0)
		_draw_text_centered(shortcut, key_rect, TYPE_META, Color(text_color, 0.78), 2.0)


func _draw_page_button(rect: Rect2, label: String, enabled: bool) -> void:
	_draw_ledger_button(rect, label, "", "primary", enabled)


func _draw_page_counter(rect: Rect2, current: int, total: int) -> void:
	_draw_panel(rect, SURFACE, LINE, RADIUS_CONTROL, 1.0)
	_draw_text_centered("%d / %d" % [current, total], rect, TYPE_META, MUTED, 2.0)


func _draw_panel(rect: Rect2, fill: Color, border: Color, radius: float, border_width: float) -> void:
	var cache_key := "%s|%s|%.2f|%.2f" % [fill.to_html(), border.to_html(), radius, border_width]
	var box: StyleBoxFlat
	if _panel_style_cache.has(cache_key):
		box = _panel_style_cache[cache_key]
	else:
		box = StyleBoxFlat.new()
		box.bg_color = fill
		box.border_color = border
		box.set_border_width_all(int(border_width))
		box.corner_radius_top_left = int(radius)
		box.corner_radius_top_right = int(radius)
		box.corner_radius_bottom_left = int(radius)
		box.corner_radius_bottom_right = int(radius)
		_panel_style_cache[cache_key] = box
	draw_style_box(box, rect)


func _line_edit_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.content_margin_left = 18.0
	box.content_margin_right = 18.0
	return box


func _draw_text(text: String, position: Vector2, size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var readable_size := maxi(12, size)
	draw_string(font, position, text, alignment, width, readable_size, color)


func _draw_display_text(text: String, position: Vector2, size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var readable_size := maxi(12, size)
	draw_string(font_display, position, text, alignment, width, readable_size, color)


func _draw_text_centered(text: String, rect: Rect2, size: int, color: Color, baseline_offset: float = 0.0) -> void:
	var readable_size := maxi(12, size)
	var baseline := rect.position.y + (rect.size.y + float(readable_size)) * 0.5 - 2.0 + baseline_offset
	draw_string(font, Vector2(rect.position.x, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, readable_size, color)


func _draw_multiline(text: String, rect: Rect2, size: int, color: Color, line_height: float) -> void:
	var readable_size := maxi(12, size)
	var lines := _wrap_text_px(text, rect.size.x, readable_size)
	for i in mini(lines.size(), int(rect.size.y / line_height)):
		_draw_text(lines[i], rect.position + Vector2(0, readable_size + i * line_height), readable_size, color)


func _draw_paragraph_array(paragraphs: Array[String], rect: Rect2, size: int, color: Color, line_height: float) -> void:
	var readable_size := maxi(12, size)
	var y := rect.position.y
	for paragraph in paragraphs:
		var lines := _wrap_text_px(paragraph, rect.size.x, readable_size)
		for line in lines:
			if y + line_height > rect.end.y:
				return
			_draw_text(line, Vector2(rect.position.x, y + readable_size), readable_size, color)
			y += line_height
		y += line_height * 0.48


func _wrap_text_px(text: String, max_width: float, size: int) -> Array[String]:
	var readable_size := maxi(12, size)
	var cache_key := "%s|%.1f|%d" % [text, max_width, readable_size]
	if _wrap_cache.has(cache_key):
		return _to_string_array(_wrap_cache[cache_key])
	var lines: Array[String] = []
	var no_break_before := "，。！？；：、）》」』】…,.!?;:%)]}"
	for paragraph in text.split("\n"):
		if paragraph.is_empty():
			lines.append("")
			continue
		var line := ""
		for character in paragraph:
			var candidate := line + character
			if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, readable_size).x > max_width:
				if no_break_before.contains(character):
					# Keep closing punctuation with a preceding glyph without allowing
					# that typographic rule to overflow the reading plane. Move the
					# final glyph and punctuation together onto the next line.
					var carry_start := maxi(0, line.length() - 1)
					var stable_line := line.substr(0, carry_start)
					var carry := line.substr(carry_start) + character
					if not stable_line.is_empty():
						lines.append(stable_line)
						line = carry
					else:
						lines.append(candidate)
						line = ""
				else:
					lines.append(line)
					line = character
			else:
				line = candidate
		if not line.is_empty():
			lines.append(line)
	if _wrap_cache.size() > 1536:
		_wrap_cache.clear()
	_wrap_cache[cache_key] = lines.duplicate()
	return lines


func _onboarding_start_rect() -> Rect2:
	return Rect2(812, 438, 300, 52)


func _continue_rect() -> Rect2:
	return Rect2(812, 504, 300, 48)


func _settings_button_rect() -> Rect2:
	return Rect2(1152, 7, 98, UI_MIN_TARGET)


func _settings_motion_rect() -> Rect2:
	return Rect2(388, 226, 504, 64)


func _settings_audio_rect() -> Rect2:
	return Rect2(388, 300, 504, 64)


func _settings_fullscreen_rect() -> Rect2:
	return Rect2(388, 374, 504, 64)


func _settings_close_rect() -> Rect2:
	return Rect2(686, 570, 206, UI_MIN_TARGET)


func _nav_rect(index: int) -> Rect2:
	return Rect2(18, 132 + index * 56, 228, 46)


func _action_card_rect(index: int) -> Rect2:
	return Rect2(316, 232 + index * 62, 440, 52)


func _action_self_rect() -> Rect2:
	return Rect2(790, 482, 155, 48)


func _action_ai_rect() -> Rect2:
	return Rect2(955, 482, 167, 48)


func _end_week_rect() -> Rect2:
	return Rect2(962, 124, 160, UI_MIN_TARGET)


func _event_choice_rect(index: int) -> Rect2:
	var choice_count := Array(current_event.get("choices", [])).size()
	if choice_count >= 4:
		var column := index % 2
		var row := index / 2
		return Rect2(88 + column * 334, 512 + row * 60, 318, 50)
	return Rect2(88, 510 + index * 54, 654, 48)


func _event_continue_rect() -> Rect2:
	return Rect2(510, 610, 232, 46)


func _first_day_choice_rect(index: int) -> Rect2:
	return Rect2(86, 444 + index * 56, 640, 48)


func _first_day_continue_rect() -> Rect2:
	return Rect2(510, 612, 216, UI_MIN_TARGET)


func _first_day_skip_rect() -> Rect2:
	return Rect2(976, 58, 160, UI_MIN_TARGET)


func _second_time_choice_rect(index: int) -> Rect2:
	return Rect2(812, 424 + index * 64, 344, 52)


func _second_time_continue_rect() -> Rect2:
	return Rect2(812, 484, 344, 52)


func _content_back_rect() -> Rect2:
	return Rect2(1064, 644, 180, UI_MIN_TARGET)


func _document_rect(index: int) -> Rect2:
	return Rect2(306, 181 + index * 62, 208, 54)


func _result_continue_rect() -> Rect2:
	return Rect2(840, 566, 146, 46)


func _signature_continue_rect() -> Rect2:
	return Rect2(508, 544, 264, UI_MIN_TARGET)


func _document_prev_rect() -> Rect2:
	return Rect2(994, 177, UI_MIN_TARGET, UI_MIN_TARGET)


func _document_page_counter_rect() -> Rect2:
	return Rect2(1046, 177, 68, UI_MIN_TARGET)


func _document_next_rect() -> Rect2:
	return Rect2(1122, 177, UI_MIN_TARGET, UI_MIN_TARGET)


func _team_prev_rect() -> Rect2:
	return Rect2(746, 584, UI_MIN_TARGET, UI_MIN_TARGET)


func _team_page_counter_rect() -> Rect2:
	return Rect2(798, 584, 52, UI_MIN_TARGET)


func _team_next_rect() -> Rect2:
	return Rect2(858, 584, UI_MIN_TARGET, UI_MIN_TARGET)


func _announcement_prev_rect() -> Rect2:
	return Rect2(798, 636, UI_MIN_TARGET, UI_MIN_TARGET)


func _announcement_page_counter_rect() -> Rect2:
	return Rect2(850, 636, 56, UI_MIN_TARGET)


func _announcement_next_rect() -> Rect2:
	return Rect2(914, 636, UI_MIN_TARGET, UI_MIN_TARGET)


func _origin_reread_rect() -> Rect2:
	return Rect2(1002, 568, 214, UI_MIN_TARGET)


func _window_curtain_button_rect() -> Rect2:
	return Rect2(926, 323, 164, UI_MIN_TARGET)


func _origin_editor_close_rect() -> Rect2:
	return Rect2(512, 536, 328, 44)


func _board_continue_rect() -> Rect2:
	return Rect2(920, 638, 272, 44)


func _live_replay_continue_rect() -> Rect2:
	return Rect2(936, 536, 258, 46)


func _layoff_social_continue_rect() -> Rect2:
	return Rect2(768, 566, 286, 46)


func _default_night_object_rect(index: int) -> Rect2:
	var positions := [
		Rect2(138, 122, 132, 68), Rect2(334, 288, 150, 68), Rect2(572, 122, 154, 68),
		Rect2(812, 288, 150, 68), Rect2(1000, 450, 132, 68), Rect2(572, 450, 154, 68)
	]
	return positions[index % positions.size()]


func _night_object_rect(object: Dictionary, fallback_index: int) -> Rect2:
	var position_value = object.get("position", [])
	if position_value is Array and position_value.size() >= 2:
		var center := Vector2(
			108.0 + clampf(float(position_value[0]), 0.0, 1.0) * 1064.0,
			92.0 + clampf(float(position_value[1]), 0.0, 1.0) * 492.0
		)
		return Rect2(center - Vector2(76.0, 36.0), Vector2(152.0, 72.0))
	return _default_night_object_rect(fallback_index)


func _night_exit_rect() -> Rect2:
	return Rect2(520, 626, 240, UI_MIN_TARGET)


func _night_modal_close_rect() -> Rect2:
	return Rect2(486, 532, 308, UI_MIN_TARGET)


func _ending_restart_rect() -> Rect2:
	return Rect2(416, 620, 448, 48)
