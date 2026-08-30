extends SceneTree

const HiringMain = preload("res://src/hiring_main.gd")
const HiringModel = preload("res://src/hiring_model.gd")
const EchoContent = preload("res://src/hiring_industry_echo_content.gd")

const VIEW_SAFE_RECT := Rect2(0, 0, 1280, 720)
const EVENT_SHEET_RECT := Rect2(54, 290, 724, 390)
const EVENT_BODY_SIZE := Vector2(656, 166)
const EVENT_BODY_FONT_SIZE := 15
const EVENT_BODY_LINE_HEIGHT := 25.0
const EVENT_BODY_PARAGRAPH_GAP := EVENT_BODY_LINE_HEIGHT * 0.48
const CHOICE_TEXT_FONT_SIZE := 13
const CHOICE_TEXT_LINE_HEIGHT := 16.0
const CHOICE_TEXT_INSET := Vector2(45, 8)
const CHOICE_TEXT_RIGHT_BOTTOM_INSET := Vector2(13, 8)
const RESULT_BODY_SIZE := Vector2(712, 278)
const RESULT_BODY_FONT_SIZE := 16
const RESULT_BODY_LINE_HEIGHT := 27.0

var SAVE_PATH := "user://industry_echo_ui_fit_save_%d.json" % OS.get_process_id()
var META_PATH := "user://industry_echo_ui_fit_meta_%d.json" % OS.get_process_id()

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_test_file(SAVE_PATH)
	_remove_test_file(META_PATH)

	var ui = HiringMain.new()
	ui.save_path_override = SAVE_PATH
	ui.meta_path_override = META_PATH
	root.add_child(ui)
	await process_frame

	_test_all_echo_event_surfaces(ui)
	_test_ambient_announcement_fit(ui)

	_dispose_ui(ui)
	await process_frame
	_remove_test_file(SAVE_PATH)
	_remove_test_file(META_PATH)

	if failures.is_empty():
		print("HIRING_INDUSTRY_ECHO_UI_FIT_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_INDUSTRY_ECHO_UI_FIT_TEST_FAILURE: " + failure)
		quit(1)


func _test_all_echo_event_surfaces(ui) -> void:
	var events: Array[Dictionary] = EchoContent.interactive_event_templates()
	_check(events.size() == 14, "UI fixture covers all fourteen interactive industry-echo events")
	for event in events:
		var event_id := str(event.get("id", "missing_event"))
		ui.model.flags.erase("options_in_assistant_voice")
		ui._open_event(event)
		_check(str(ui.current_event.get("id", "")) == event_id, "%s opens through the real event preparation path" % event_id)
		_check(ui.screen == HiringMain.Screen.EVENT, "%s enters the event screen" % event_id)
		_test_header_fit(ui, event_id)
		_test_body_pagination(ui, event, event_id)
		_test_choice_geometry_and_labels(ui, event_id)
		_test_effect_receipts(ui, event, event_id)
	ui.current_event.clear()
	ui.model.flags.erase("options_in_assistant_voice")


func _test_ambient_announcement_fit(ui) -> void:
	var ambient: Array[Dictionary] = EchoContent.ambient_templates()
	_check(ambient.size() == 4, "announcement fixture covers four interruption-free vignettes")
	var feed: Array = []
	for index in ambient.size():
		var item: Dictionary = ambient[index].duplicate(true)
		item["week"] = 20 + index
		feed.append(item)
		_check(not item.has("choices") and not item.has("effects"), "%s has no modal interaction payload" % str(item.get("id", "ambient")))
	ui.model.memory["industry_ambient_feed"] = feed
	var announcements: Array = ui._announcement_items()
	for ambient_index in range(ambient.size() - 2, ambient.size()):
		var expected: Dictionary = ambient[ambient_index]
		var matched: Dictionary = {}
		for item_value in announcements:
			if item_value is Dictionary and str(Dictionary(item_value).get("title", "")) == str(expected.get("title", "")):
				matched = item_value
				break
		_check(not matched.is_empty(), "%s reaches the two-item announcement pin" % str(expected.get("id", "ambient")))
		if matched.is_empty():
			continue
		var title_width := float(ui.font.get_string_size(str(matched.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)
		var metric_width := float(ui.font.get_string_size(str(matched.get("metric", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x)
		_check(title_width <= 408.0, "%s announcement title fits its column" % str(expected.get("id", "ambient")))
		_check(metric_width <= 172.0, "%s announcement metric fits its column" % str(expected.get("id", "ambient")))
	ui.model.memory.erase("industry_ambient_feed")


func _test_header_fit(ui, event_id: String) -> void:
	var title := str(ui.current_event.get("title", ""))
	var kicker := str(ui.current_event.get("kicker", ""))
	_check(not title.is_empty() and not kicker.is_empty(), "%s generates both title and kicker labels" % event_id)
	var title_width: float = float(ui.font_display.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x)
	var kicker_width: float = float(ui.font.get_string_size(kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x)
	_check(title_width <= 720.0, "%s title stays within the 1280x720 event header safe width" % event_id)
	_check(kicker_width <= 632.0, "%s kicker stays within the event header rule" % event_id)


func _test_body_pagination(ui, source_event: Dictionary, event_id: String) -> void:
	var pages: Array = ui._event_body_pages()
	_check(not pages.is_empty(), "%s produces at least one body page" % event_id)
	var flattened: Array[String] = []
	for page_index in pages.size():
		var page_value = pages[page_index]
		_check(page_value is Array, "%s body page %d is a paragraph array" % [event_id, page_index + 1])
		if not page_value is Array:
			continue
		var page: Array = page_value
		var metrics := _paragraph_layout_metrics(
			ui, page, EVENT_BODY_SIZE, EVENT_BODY_FONT_SIZE,
			EVENT_BODY_LINE_HEIGHT, EVENT_BODY_PARAGRAPH_GAP
		)
		_check(not bool(metrics.get("vertical_overflow", true)), "%s body page %d fits the 656x166 reading plane without clipped lines" % [event_id, page_index + 1])
		_check(not bool(metrics.get("horizontal_overflow", true)), "%s body page %d has no wrapped line wider than the reading plane" % [event_id, page_index + 1])
		for paragraph_value in page:
			flattened.append(str(paragraph_value))
	_check(flattened == _to_string_array(source_event.get("body", [])), "%s pagination preserves every authored paragraph exactly once" % event_id)


func _test_choice_geometry_and_labels(ui, event_id: String) -> void:
	var pages: Array = ui._event_body_pages()
	ui.current_event_page = maxi(0, pages.size() - 1)
	var choices: Array = ui.current_event.get("choices", [])
	_check(choices.size() == 3 and ui._event_choices_visible(), "%s exposes its three choices only on the final body page" % event_id)
	var rects: Array[Rect2] = []
	for choice_index in choices.size():
		var choice: Dictionary = choices[choice_index]
		var choice_label := str(ui._choice_display_label(choice))
		var rect: Rect2 = ui._event_choice_rect(choice_index)
		rects.append(rect)
		_check(VIEW_SAFE_RECT.encloses(rect), "%s choice %d stays inside the 1280x720 safe area" % [event_id, choice_index + 1])
		_check(EVENT_SHEET_RECT.encloses(rect), "%s choice %d stays on the event decision sheet" % [event_id, choice_index + 1])
		_check(rect.size.x >= 44.0 and rect.size.y >= 44.0, "%s choice %d keeps a minimum 44px interaction target" % [event_id, choice_index + 1])
		_check(not choice_label.is_empty(), "%s choice %d generates a visible label" % [event_id, choice_index + 1])
		_check(_choice_label_fits(ui, choice_label, rect), "%s choice %d label fits its two-line card" % [event_id, choice_index + 1])
		var visual: Dictionary = ui._event_choice_visual_contract(choice)
		_check(int(visual.get("label_font_size", 0)) >= 13 and float(visual.get("line_height", 0.0)) >= 16.0, "%s choice %d generates the readable event visual contract" % [event_id, choice_index + 1])

		ui.model.flags["options_in_assistant_voice"] = true
		var authored_label := str(ui._choice_display_label(choice))
		_check(not authored_label.is_empty(), "%s choice %d also generates its late-campaign label" % [event_id, choice_index + 1])
		_check(_choice_label_fits(ui, authored_label, rect), "%s choice %d late-campaign label still fits its two-line card" % [event_id, choice_index + 1])
		ui.model.flags.erase("options_in_assistant_voice")
	for left in rects.size():
		for right in range(left + 1, rects.size()):
			_check(not rects[left].intersects(rects[right]), "%s choice cards %d and %d do not overlap" % [event_id, left + 1, right + 1])


func _test_effect_receipts(ui, source_event: Dictionary, event_id: String) -> void:
	for choice_value in Array(source_event.get("choices", [])):
		var choice: Dictionary = choice_value
		var choice_id := str(choice.get("id", ""))
		var isolated_model = HiringModel.new()
		isolated_model.apply_effects(Dictionary(choice.get("effects", {})))
		var resolved: Dictionary = isolated_model.resolve_systemic_event(source_event, choice_id)
		var receipt := str(resolved.get("receipt", "")).strip_edges()
		_check(bool(resolved.get("ok", false)), "%s / %s resolves while generating its effect summary" % [event_id, choice_id])
		_check(not receipt.is_empty(), "%s / %s generates a non-empty operating receipt summary" % [event_id, choice_id])
		_check(str(isolated_model.memory.get("last_operating_action_summary", "")) == receipt, "%s / %s stores the same summary shown by the result flow" % [event_id, choice_id])

		ui.result_lines.clear()
		ui.result_lines.append(receipt)
		var result_pages: Array = ui._result_pages()
		_check(not result_pages.is_empty(), "%s / %s effect summary enters result pagination" % [event_id, choice_id])
		var flattened := _flatten_pages(result_pages)
		_check(flattened == [receipt], "%s / %s effect summary survives result pagination verbatim" % [event_id, choice_id])
		for page_value in result_pages:
			if not page_value is Array:
				_fail("%s / %s result page is not a paragraph array" % [event_id, choice_id])
				continue
			var metrics := _paragraph_layout_metrics(
				ui, page_value, RESULT_BODY_SIZE, RESULT_BODY_FONT_SIZE,
				RESULT_BODY_LINE_HEIGHT, RESULT_BODY_LINE_HEIGHT * 0.48
			)
			_check(not bool(metrics.get("vertical_overflow", true)) and not bool(metrics.get("horizontal_overflow", true)), "%s / %s effect summary fits the result reading plane" % [event_id, choice_id])


func _choice_label_fits(ui, label: String, rect: Rect2) -> bool:
	var text_size := rect.size - CHOICE_TEXT_INSET - CHOICE_TEXT_RIGHT_BOTTOM_INSET
	var lines: Array[String] = ui._wrap_text_px(label, text_size.x, CHOICE_TEXT_FONT_SIZE)
	var visible_lines := int(text_size.y / CHOICE_TEXT_LINE_HEIGHT)
	if lines.size() > visible_lines:
		return false
	for line in lines:
		if ui.font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, CHOICE_TEXT_FONT_SIZE).x > text_size.x + 0.5:
			return false
	return true


func _paragraph_layout_metrics(ui, paragraphs: Array, size: Vector2, font_size: int, line_height: float, paragraph_gap: float) -> Dictionary:
	var y := 0.0
	var vertical_overflow := false
	var horizontal_overflow := false
	for paragraph_value in paragraphs:
		var lines: Array[String] = ui._wrap_text_px(str(paragraph_value), size.x, font_size)
		for line in lines:
			if y + line_height > size.y + 0.001:
				vertical_overflow = true
			if ui.font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x + 0.5:
				horizontal_overflow = true
			y += line_height
		y += paragraph_gap
	return {
		"vertical_overflow": vertical_overflow,
		"horizontal_overflow": horizontal_overflow,
		"used_height": y,
	}


func _flatten_pages(pages: Array) -> Array[String]:
	var flattened: Array[String] = []
	for page_value in pages:
		if not page_value is Array:
			continue
		for paragraph_value in page_value:
			flattened.append(str(paragraph_value))
	return flattened


func _to_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is String:
		result.append(str(value))
	elif value is Array:
		for item in value:
			result.append(str(item))
	return result


func _dispose_ui(ui) -> void:
	if ui.office_audio != null:
		for child in ui.office_audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
	ui.queue_free()


func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	checks += 1
	failures.append(message)
