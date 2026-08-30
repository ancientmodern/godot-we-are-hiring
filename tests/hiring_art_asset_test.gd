extends SceneTree

const MANIFEST_PATH := "res://assets/hiring_assets.json"
const REQUIRED_GLYPHS := "我们正在招人林越AI0123456789"

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var payload := _read_manifest()
	if not payload.is_empty():
		_verify_assets(payload)

	if failures.is_empty():
		print("HIRING_ART_ASSET_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_ART_ASSET_TEST_FAILURE: " + failure)
		quit(1)


func _read_manifest() -> Dictionary:
	_check(FileAccess.file_exists(MANIFEST_PATH), "asset manifest exists")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	_check(not manifest_text.is_empty(), "asset manifest is nonempty")
	var parsed: Variant = JSON.parse_string(manifest_text)
	_check(parsed is Dictionary, "asset manifest parses as a Dictionary")
	if not parsed is Dictionary:
		return {}
	var payload := parsed as Dictionary
	_check(int(payload.get("schema", -1)) == 1, "asset manifest uses schema one")
	_check(payload.get("assets") is Array and not Array(payload.get("assets", [])).is_empty(), "asset manifest has a nonempty asset array")
	return payload


func _verify_assets(payload: Dictionary) -> void:
	var ids := {}
	var paths := {}
	var runtime_count := 0
	var expected_runtime_count := 0
	var license_count := 0
	var expected_license_count := 0
	for value: Variant in Array(payload.get("assets", [])):
		_check(value is Dictionary, "every asset entry is a Dictionary")
		if not value is Dictionary:
			continue
		var entry := value as Dictionary
		var asset_id := str(entry.get("id", ""))
		var path := str(entry.get("path", ""))
		var kind := str(entry.get("kind", ""))
		_check(not asset_id.is_empty(), "asset id is nonempty")
		_check(not ids.has(asset_id), "asset id '%s' is unique" % asset_id)
		ids[asset_id] = true
		_check(path.begins_with("res://assets/") and path == path.simplify_path(), "asset '%s' has a canonical res://assets path" % asset_id)
		var folded_path := path.to_lower()
		_check(not paths.has(folded_path), "asset path '%s' is unique without case aliases" % path)
		paths[folded_path] = true
		_check(FileAccess.file_exists(path), "asset '%s' source file exists" % asset_id)

		if kind == "license":
			expected_license_count += 1
			license_count += 1
			_check(not bool(entry.get("runtime", true)), "license '%s' is not a runtime resource" % asset_id)
			var license_text := FileAccess.get_file_as_string(path)
			_check(license_text.contains("SIL Open Font License") and license_text.contains("Version 1.1"), "license '%s' contains the expected OFL 1.1 text" % asset_id)
			continue

		_check(kind in ["texture", "font"], "asset '%s' has a supported runtime kind" % asset_id)
		expected_runtime_count += 1
		_check(bool(entry.get("runtime", false)), "asset '%s' is marked runtime" % asset_id)
		var type_hint := str(entry.get("resource_type", ""))
		_check(not type_hint.is_empty(), "asset '%s' declares a ResourceLoader type" % asset_id)
		_check(ResourceLoader.exists(path, type_hint), "ResourceLoader sees asset '%s' as %s" % [asset_id, type_hint])
		var resource := ResourceLoader.load(path, type_hint, ResourceLoader.CACHE_MODE_IGNORE)
		_check(resource != null, "ResourceLoader loads asset '%s' with cache ignored" % asset_id)
		if resource == null:
			continue
		runtime_count += 1
		_check(resource.resource_path == path, "asset '%s' retains its canonical resource path" % asset_id)
		if kind == "texture":
			_check(resource is Texture2D, "asset '%s' loads as Texture2D" % asset_id)
			if resource is Texture2D:
				var texture := resource as Texture2D
				_check(texture.get_width() == int(entry.get("width", -1)), "texture '%s' has declared width" % asset_id)
				_check(texture.get_height() == int(entry.get("height", -1)), "texture '%s' has declared height" % asset_id)
				var image := texture.get_image()
				_check(image != null and not image.is_empty(), "texture '%s' exposes imported image data" % asset_id)
				if image != null and not image.is_empty():
					var has_alpha := image.detect_alpha() != Image.ALPHA_NONE
					_check(has_alpha == bool(entry.get("alpha", false)), "texture '%s' has declared alpha behavior" % asset_id)
		elif kind == "font":
			_check(resource is FontFile, "asset '%s' loads as FontFile" % asset_id)
			if resource is FontFile:
				var font := resource as FontFile
				for glyph_index in REQUIRED_GLYPHS.length():
					var glyph := REQUIRED_GLYPHS.substr(glyph_index, 1)
					_check(font.has_char(glyph.unicode_at(0)), "font '%s' contains glyph '%s'" % [asset_id, glyph])

	_check(ids.size() == Array(payload.get("assets", [])).size(), "all manifest asset ids are unique")
	_check(paths.size() == Array(payload.get("assets", [])).size(), "all manifest asset paths are unique")
	_check(runtime_count == expected_runtime_count, "every runtime manifest entry loads through ResourceLoader")
	_check(expected_runtime_count > 0, "manifest exposes at least one runtime resource")
	_check(license_count == expected_license_count and expected_license_count == 2, "manifest exposes both verified non-runtime font licenses")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
