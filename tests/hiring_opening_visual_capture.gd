extends SceneTree

const OUTPUT_DIR := "res://artifacts/hiring_opening_visuals"
var save_path := "user://hiring_opening_visual_%d.json" % OS.get_process_id()
var meta_path := "user://hiring_opening_visual_meta_%d.json" % OS.get_process_id()
var failures: Array[String] = []
var capture_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_clear_storage()
	var game = preload("res://hiring_main.tscn").instantiate()
	game.save_path_override = save_path
	game.meta_path_override = meta_path
	root.add_child(game)
	await _settle(24)
	game.name_edit.text = "提灯实验室"
	game._start_new_company()
	await _show_phase(game)
	_capture("01_arrival")

	game._advance_first_day_prologue()
	await _show_phase(game)
	_capture("02_name_responses")
	game._choose_first_day_option(2)
	await _show_phase(game)
	_capture("03_exchange_history_flirt")

	game._advance_first_day_prologue()
	await _show_phase(game)
	_capture("04_mission_responses")
	game._choose_first_day_option(0)
	await _show_phase(game)
	_capture("05_power_failure")

	game._advance_first_day_prologue()
	await _show_phase(game)
	_capture("06_reset_power_strip")
	game._advance_first_day_prologue()
	await _show_phase(game)
	_capture("07_week_one_handoff")

	_release_audio(game)
	game.queue_free()
	await process_frame
	_clear_storage()
	if failures.is_empty() and capture_count == 7:
		print("HIRING_OPENING_VISUAL_CAPTURE_PASS: 7 captures")
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_OPENING_VISUAL_CAPTURE_FAILURE: " + failure)
		quit(1)


func _settle(frame_count: int) -> void:
	for _frame in frame_count:
		await process_frame


func _show_phase(game: Node) -> void:
	# Visual evidence must capture the fully revealed authored state. Runtime input
	# still keeps the first press as a safe "finish the text" action.
	await _settle(4)
	game._reveal_first_day_phase()
	await _settle(8)


func _capture(stem: String) -> void:
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("viewport image unavailable for " + stem)
		return
	var output_path := "%s/%s.png" % [ProjectSettings.globalize_path(OUTPUT_DIR), stem]
	var error := image.save_png(output_path)
	if error != OK:
		failures.append("cannot save %s: %s" % [stem, error_string(error)])
		return
	capture_count += 1
	print("CAPTURED: " + output_path)


func _release_audio(node: Node) -> void:
	for child in node.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
		_release_audio(child)


func _clear_storage() -> void:
	for path in [save_path, save_path + ".bak", save_path + ".tmp", meta_path, meta_path + ".bak", meta_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
