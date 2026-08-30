extends SceneTree

const MAIN_SCENE_PATH := "res://hiring_main.tscn"
var CAPTURE_SAVE_PATH := "user://we_are_hiring_signature_capture_save_%d.json" % OS.get_process_id()
var CAPTURE_META_PATH := "user://we_are_hiring_signature_capture_meta_%d.json" % OS.get_process_id()
const WATCHDOG_FRAMES := 240

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
	if model == null or not model.has_method("reset") or not model.has_method("begin_week"):
		_fail("main scene did not initialize its model")
		return
	if not _capture_game.has_method("_change_screen"):
		_fail("main scene has no signature-screen transition")
		return
	var signature_screen := _screen_constant("SIGNATURE")
	if signature_screen < 0:
		_fail("main scene has no SIGNATURE screen constant")
		return
	model.call("reset", "提灯实验室")
	model.set("chapter", 4)
	model.set("week_in_chapter", 1)
	model.set("total_week", 38)
	var begin_result = model.call("begin_week")
	if not begin_result is Dictionary or not bool(Dictionary(begin_result).get("ok", false)):
		_fail("chapter-four capture week did not begin")
		return
	_capture_game.call("_change_screen", signature_screen)
	# Movie Maker mode advances at the requested fixed 60 fps. Ninety frames
	# include the complete 1.05 s stroke plus the final affordance fade-in.
	await _frames(90)
	if not is_instance_valid(_capture_game):
		_fail("main scene was freed during signature capture")
		return
	_cleanup_game()
	await _frames(3)
	print("HIRING_SIGNATURE_MOTION_CAPTURE_PASS: 90-frame timeline (capture command supplies fixed 60 fps)")
	_finish(0)


func _watchdog() -> void:
	await _frames(WATCHDOG_FRAMES)
	if _finished:
		return
	_fail("watchdog reached %d frames before capture completion" % WATCHDOG_FRAMES)


func _fail(message: String) -> void:
	push_error("HIRING_SIGNATURE_MOTION_CAPTURE_FAILURE: " + message)
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


func _screen_constant(constant_name: String) -> int:
	if not is_instance_valid(_capture_game):
		return -1
	var script = _capture_game.get_script()
	if not script is Script:
		return -1
	var constants: Dictionary = script.get_script_constant_map()
	var screens = constants.get("Screen", {})
	if not screens is Dictionary:
		return -1
	return int(Dictionary(screens).get(constant_name, -1))


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame
