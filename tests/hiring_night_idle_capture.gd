extends SceneTree

const MAIN_SCENE_PATH := "res://hiring_main.tscn"
var CAPTURE_SAVE_PATH := "user://we_are_hiring_night_idle_capture_save_%d.json" % OS.get_process_id()
var CAPTURE_META_PATH := "user://we_are_hiring_night_idle_capture_meta_%d.json" % OS.get_process_id()
const WATCHDOG_FRAMES := 360

var _capture_game: Node = null
var _finished := false


func _init() -> void:
	call_deferred("_watchdog")
	call_deferred("_run")


func _run() -> void:
	_remove_capture_files()
	root.size = Vector2i(1280, 720)
	var scene_path := MAIN_SCENE_PATH
	var scene_resource = ResourceLoader.load(scene_path)
	if not scene_resource is PackedScene:
		_fail("cannot load %s" % scene_path)
		return
	_capture_game = (scene_resource as PackedScene).instantiate()
	if _capture_game == null:
		_fail("main scene failed to instantiate")
		return
	_capture_game.set("save_path_override", CAPTURE_SAVE_PATH)
	_capture_game.set("meta_path_override", CAPTURE_META_PATH)
	root.add_child(_capture_game)
	await _frames(4)
	if not is_instance_valid(_capture_game):
		_fail("main scene was freed during startup")
		return
	var model = _capture_game.get("model")
	var content = _capture_game.get("content")
	if model == null or not model.has_method("reset"):
		_fail("main scene did not initialize its model")
		return
	if content == null or not content.has_method("get_night_shift") or not _capture_game.has_method("_open_night_shift"):
		_fail("main scene did not initialize its night-shift content")
		return
	model.call("reset", "提灯实验室")
	_capture_game.set("pending_night_id", "1")
	var night_data = content.call("get_night_shift", "1")
	if not night_data is Dictionary or Dictionary(night_data).is_empty():
		_fail("night-one content is unavailable")
		return
	_capture_game.call("_open_night_shift", night_data)
	await _frames(3)
	if not is_instance_valid(_capture_game) or _capture_game.get("night_interaction") == null:
		_fail("night shift did not finish initializing")
		return

	var before := _idle_contract(_capture_game)
	# With Movie Maker fixed at 1 fps, 300 rendered frames are an exact five
	# minutes of idle game time. No click, key, timer failure, chase, or scare is
	# injected during this interval.
	await _frames(300)
	if not is_instance_valid(_capture_game):
		_fail("main scene was freed during the idle capture")
		return
	var after := _idle_contract(_capture_game)
	if before != after:
		_fail("persistent or interaction state changed while idle")
		return

	_cleanup_game()
	await _frames(3)
	print("HIRING_NIGHT_IDLE_CAPTURE_PASS: 300 idle frames, zero state change (fixed 1 fps capture = 300 seconds)")
	_finish(0)


func _watchdog() -> void:
	await _frames(WATCHDOG_FRAMES)
	if _finished:
		return
	_fail("watchdog reached %d frames before capture completion" % WATCHDOG_FRAMES)


func _fail(message: String) -> void:
	push_error("HIRING_NIGHT_IDLE_CAPTURE_FAILURE: " + message)
	_finish(1)


func _finish(code: int) -> void:
	if _finished:
		return
	_finished = true
	_cleanup_game()
	_remove_capture_files()
	quit(code)


func _cleanup_game() -> void:
	if not is_instance_valid(_capture_game):
		_capture_game = null
		return
	var office_audio = _capture_game.get("office_audio")
	if office_audio is Node:
		for child in office_audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
	_capture_game.queue_free()
	_capture_game = null


func _remove_capture_files() -> void:
	for path in [CAPTURE_SAVE_PATH, CAPTURE_META_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _idle_contract(game) -> Dictionary:
	return {
		"screen": int(game.screen),
		"pending_night_id": str(game.pending_night_id),
		"model": game.model.to_save(),
		"night": game.night_interaction.to_save() if game.night_interaction != null else {},
		"player_position": game.night_player_position,
		"player_target": game.night_player_target,
		"arrival_armed": bool(game.night_arrival_armed),
		"result_lines": game.result_lines.duplicate(),
	}


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame
