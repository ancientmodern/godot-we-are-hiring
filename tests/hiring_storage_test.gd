extends SceneTree

const HiringStorage = preload("res://src/hiring_storage.gd")
const FORMAL_SAVE_PATH := "user://we_are_hiring_save.json"
const FORMAL_META_PATH := "user://we_are_hiring_meta.json"

var failures: Array[String] = []
var checks := 0
var _prefix := ""
var _paths: Array[String] = []
var _directories: Array[String] = []


func _init() -> void:
	_prefix = "user://we_are_hiring_storage_test_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]

	_test_missing_and_invalid_paths()
	_test_round_trip_and_root_envelope()
	_test_legacy_bare_dictionary_compatibility()
	_test_backup_rotation_and_primary_recovery()
	_test_non_mutating_backup_fallback()
	_test_corrupt_primary_and_backup_diagnostics()
	_test_schema_version_fallback_and_mismatch()
	_test_unsupported_values_and_write_side_failures()

	_cleanup_test_artifacts()
	if failures.is_empty():
		print("HIRING_STORAGE_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_STORAGE_TEST_FAILURE: " + failure)
		quit(1)


func _test_missing_and_invalid_paths() -> void:
	var path := _new_path("missing")
	var missing: Dictionary = HiringStorage.load_dictionary(path)
	_check(not bool(missing.get("ok", true)), "missing storage fails closed")
	_check(str(missing.get("status", "")) == "not_found", "missing primary and backup return the not_found status")
	_check(str(Dictionary(missing.get("primary_error", {})).get("status", "")) == "not_found", "missing result identifies the primary as absent")
	_check(str(Dictionary(missing.get("backup_error", {})).get("status", "")) == "not_found", "missing result identifies the backup as absent")

	var invalid_save: Dictionary = HiringStorage.save_dictionary("res://must_not_write.json", {"safe": true})
	_check(not bool(invalid_save.get("ok", true)) and str(invalid_save.get("status", "")) == "invalid_path", "save rejects non-user paths before I/O")
	var invalid_load: Dictionary = HiringStorage.load_dictionary("user://../outside.json")
	_check(not bool(invalid_load.get("ok", true)) and str(invalid_load.get("status", "")) == "invalid_path", "load rejects parent-directory traversal")


func _test_round_trip_and_root_envelope() -> void:
	var path := _new_path("round_trip")
	var payload := {
		"company": "Mothlight Systems",
		"week": 12,
		"flags": [true, false, null],
		"nested": {"route": "warm", "score": 3.5},
	}
	var saved: Dictionary = HiringStorage.save_dictionary(path, payload)
	_check(bool(saved.get("ok", false)) and str(saved.get("status", "")) == "saved", "a JSON-compatible dictionary saves successfully")
	_check(int(saved.get("schema_version", 0)) == HiringStorage.ROOT_SCHEMA_VERSION, "save result reports the root schema version")
	_check(not bool(saved.get("backup_created", true)), "the first save does not invent a backup")
	_check(FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".tmp"), "first save promotes the temporary file and leaves no temporary artifact")

	var parsed: Variant = JSON.parse_string(_read_raw(path))
	_check(typeof(parsed) == TYPE_DICTIONARY, "the on-disk JSON root is a dictionary")
	if typeof(parsed) == TYPE_DICTIONARY:
		var root: Dictionary = parsed
		_check(int(root.get("schema_version", 0)) == HiringStorage.ROOT_SCHEMA_VERSION, "the on-disk root contains the storage schema version")
		_check(typeof(root.get("data")) == TYPE_DICTIONARY, "the on-disk root contains a dictionary data field")

	var loaded: Dictionary = HiringStorage.load_dictionary(path)
	_check(bool(loaded.get("ok", false)) and str(loaded.get("status", "")) == "loaded_primary", "a healthy primary loads without consulting backup")
	_check(_json_equivalent(Dictionary(loaded.get("data", {})), payload), "primary load returns the saved dictionary with JSON-equivalent values")
	_check(not bool(loaded.get("used_backup", true)) and not bool(loaded.get("primary_restored", true)), "healthy load reports neither fallback nor recovery")


func _test_legacy_bare_dictionary_compatibility() -> void:
	var path := _new_path("legacy")
	var legacy_payload := {
		"save_version": 1,
		"company_name": "Mothlight Systems",
		"chapter": 2,
		"flags": {"met_lin_yue": true},
	}
	var legacy_text := JSON.stringify(legacy_payload)
	_check(_write_raw(path, legacy_text), "legacy fixture writes an isolated bare dictionary")

	var loaded: Dictionary = HiringStorage.load_dictionary(path)
	_check(bool(loaded.get("ok", false)) and str(loaded.get("status", "")) == "loaded_legacy", "legacy bare dictionaries are accepted by default with an explicit status")
	_check(_json_equivalent(Dictionary(loaded.get("data", {})), legacy_payload), "legacy load returns the complete bare dictionary as data")
	_check(bool(loaded.get("legacy", false)) and bool(loaded.get("migration_required", false)), "legacy load tells main that an explicit migration is required")
	_check(int(loaded.get("schema_version", -1)) == 0, "legacy load never pretends to have an envelope schema version")
	_check(not bool(loaded.get("used_backup", true)) and not bool(loaded.get("primary_restored", true)), "legacy primary load reports no backup use or repair")
	_check(_read_raw(path) == legacy_text, "legacy load leaves the primary byte-for-byte unchanged")
	_check(not FileAccess.file_exists(path + ".tmp") and not FileAccess.file_exists(path + ".bak"), "legacy load creates neither migration temporary files nor backups")

	var rejected: Dictionary = HiringStorage.load_dictionary(path, HiringStorage.ROOT_SCHEMA_VERSION, true, false)
	_check(not bool(rejected.get("ok", true)) and str(rejected.get("status", "")) == "load_failed", "callers can disable legacy compatibility")
	_check(str(Dictionary(rejected.get("primary_error", {})).get("status", "")) == "missing_schema_version", "disabled legacy compatibility applies strict envelope validation")
	_check(_read_raw(path) == legacy_text, "rejecting a legacy file also leaves it unchanged")

	var migrated: Dictionary = HiringStorage.save_dictionary(path, legacy_payload)
	_check(bool(migrated.get("ok", false)) and bool(migrated.get("backup_created", false)), "an explicit save can safely migrate a previously loaded legacy primary")
	_check(bool(migrated.get("replaced_legacy_primary", false)), "explicit migration is identified in the save result")
	_check(str(HiringStorage.load_dictionary(path).get("status", "")) == "loaded_primary", "explicit migration installs a strict versioned envelope")
	var legacy_backup: Dictionary = HiringStorage.load_dictionary(path + ".bak")
	_check(str(legacy_backup.get("status", "")) == "loaded_legacy" and _json_equivalent(Dictionary(legacy_backup.get("data", {})), legacy_payload), "explicit migration preserves the old bare dictionary as a readable backup")
	_check(_read_raw(path + ".bak") == legacy_text, "explicit migration backs up the legacy bytes without silently enveloping them")

	var fallback_path := _new_path("legacy_backup")
	var corrupt_primary := "{broken primary"
	_check(_write_raw(fallback_path, corrupt_primary), "legacy-backup fixture corrupts only its isolated primary")
	_check(_write_raw(fallback_path + ".bak", legacy_text), "legacy-backup fixture writes an isolated bare backup")
	var fallback: Dictionary = HiringStorage.load_dictionary(fallback_path)
	_check(bool(fallback.get("ok", false)) and str(fallback.get("status", "")) == "loaded_legacy", "a usable legacy backup is surfaced as loaded_legacy")
	_check(bool(fallback.get("used_backup", false)) and not bool(fallback.get("primary_restored", true)), "legacy backup fallback never auto-restores or migrates the primary")
	_check(_read_raw(fallback_path) == corrupt_primary and not FileAccess.file_exists(fallback_path + ".tmp"), "legacy backup fallback performs no disk mutation")

	var schema_only_path := _new_path("damaged_envelope_schema_only")
	_check(_write_raw(schema_only_path, JSON.stringify({"schema_version": 1, "company_name": "Not legacy"})), "schema-marker fixture writes isolated JSON")
	var schema_only: Dictionary = HiringStorage.load_dictionary(schema_only_path)
	_check(not bool(schema_only.get("ok", true)) and str(Dictionary(schema_only.get("primary_error", {})).get("status", "")) == "invalid_data", "an envelope schema marker without data is rejected instead of downgraded to legacy")

	var data_only_path := _new_path("damaged_envelope_data_only")
	_check(_write_raw(data_only_path, JSON.stringify({"data": {"save_version": 1}})), "data-marker fixture writes isolated JSON")
	var data_only: Dictionary = HiringStorage.load_dictionary(data_only_path)
	_check(not bool(data_only.get("ok", true)) and str(Dictionary(data_only.get("primary_error", {})).get("status", "")) == "missing_schema_version", "an envelope data marker without schema is rejected instead of downgraded to legacy")

	var wrong_data_path := _new_path("damaged_envelope_wrong_data")
	_check(_write_raw(wrong_data_path, JSON.stringify({"schema_version": 1, "data": []})), "wrong-data fixture writes isolated JSON")
	var wrong_data: Dictionary = HiringStorage.load_dictionary(wrong_data_path)
	_check(not bool(wrong_data.get("ok", true)) and str(Dictionary(wrong_data.get("primary_error", {})).get("status", "")) == "invalid_data", "a malformed complete envelope is never accepted as legacy")


func _test_backup_rotation_and_primary_recovery() -> void:
	var path := _new_path("recovery")
	var first := {"revision": "first", "employees": ["lin_yue"]}
	var second := {"revision": "second", "employees": ["lin_yue", "chen_mo"]}
	_check(bool(HiringStorage.save_dictionary(path, first).get("ok", false)), "recovery fixture writes its first revision")
	var second_save: Dictionary = HiringStorage.save_dictionary(path, second)
	_check(bool(second_save.get("ok", false)) and bool(second_save.get("backup_created", false)), "updating a valid primary creates a verified backup")
	_check(FileAccess.file_exists(path + ".bak") and not FileAccess.file_exists(path + ".bak.tmp"), "backup rotation leaves one final backup and no backup temporary artifact")

	var backup_read: Dictionary = HiringStorage.load_dictionary(path + ".bak", HiringStorage.ROOT_SCHEMA_VERSION, false)
	_check(bool(backup_read.get("ok", false)) and Dictionary(backup_read.get("data", {})) == first, "the backup preserves the previous complete revision")
	_check(Dictionary(HiringStorage.load_dictionary(path).get("data", {})) == second, "the primary contains the new revision")

	_check(_write_raw(path, "{ definitely not valid json"), "test fixture can corrupt only its isolated primary")
	var recovered: Dictionary = HiringStorage.load_dictionary(path)
	_check(bool(recovered.get("ok", false)) and str(recovered.get("status", "")) == "recovered_from_backup", "a corrupt primary falls back to the valid backup")
	_check(Dictionary(recovered.get("data", {})) == first and bool(recovered.get("used_backup", false)), "backup fallback returns the previous complete dictionary")
	_check(bool(recovered.get("primary_restored", false)), "default fallback repairs the primary from the verified backup")
	_check(str(Dictionary(recovered.get("primary_error", {})).get("status", "")) == "parse_failed", "recovery result retains the corrupt primary's parse diagnosis")

	var after_recovery: Dictionary = HiringStorage.load_dictionary(path)
	_check(str(after_recovery.get("status", "")) == "loaded_primary" and Dictionary(after_recovery.get("data", {})) == first, "the repaired primary is independently readable on the next load")


func _test_non_mutating_backup_fallback() -> void:
	var path := _new_path("read_only_fallback")
	var first := {"revision": "stable"}
	var second := {"revision": "new"}
	HiringStorage.save_dictionary(path, first)
	HiringStorage.save_dictionary(path, second)
	var corrupt_text := "[broken primary"
	_check(_write_raw(path, corrupt_text), "non-mutating fallback fixture corrupts only its isolated primary")

	var fallback: Dictionary = HiringStorage.load_dictionary(path, HiringStorage.ROOT_SCHEMA_VERSION, false)
	_check(bool(fallback.get("ok", false)) and str(fallback.get("status", "")) == "loaded_backup", "callers can request backup fallback without disk repair")
	_check(Dictionary(fallback.get("data", {})) == first and bool(fallback.get("used_backup", false)), "non-mutating fallback still returns usable backup data")
	_check(not bool(fallback.get("primary_restored", true)) and _read_raw(path) == corrupt_text, "non-mutating fallback leaves the corrupt primary unchanged and reports that fact")


func _test_corrupt_primary_and_backup_diagnostics() -> void:
	var path := _new_path("double_corrupt")
	HiringStorage.save_dictionary(path, {"revision": 1})
	HiringStorage.save_dictionary(path, {"revision": 2})
	_check(_write_raw(path, "{primary broken"), "double-corruption fixture rewrites its isolated primary")
	_check(_write_raw(path + ".bak", "{backup broken"), "double-corruption fixture rewrites its isolated backup")

	var loaded: Dictionary = HiringStorage.load_dictionary(path)
	_check(not bool(loaded.get("ok", true)) and str(loaded.get("status", "")) == "load_failed", "two corrupt copies return a hard load failure")
	_check(str(Dictionary(loaded.get("primary_error", {})).get("status", "")) == "parse_failed", "hard load failure identifies the primary parse error")
	_check(str(Dictionary(loaded.get("backup_error", {})).get("status", "")) == "parse_failed", "hard load failure identifies the backup parse error")
	_check(not str(loaded.get("message", "")).is_empty() and int(loaded.get("error_code", OK)) != OK, "hard load failure includes a readable message and nonzero error code")

	var invalid_root_path := _new_path("invalid_root")
	_check(_write_raw(invalid_root_path, "[]"), "invalid-root fixture writes isolated JSON")
	var invalid_root: Dictionary = HiringStorage.load_dictionary(invalid_root_path)
	_check(str(Dictionary(invalid_root.get("primary_error", {})).get("status", "")) == "invalid_root", "valid JSON with a non-dictionary root receives a distinct diagnosis")


func _test_schema_version_fallback_and_mismatch() -> void:
	var path := _new_path("schema_recovery")
	var version_one := {"revision": "schema-one"}
	var version_two := {"revision": "schema-two"}
	HiringStorage.save_dictionary(path, version_one, 1)
	HiringStorage.save_dictionary(path, version_two, 2)

	var recovered: Dictionary = HiringStorage.load_dictionary(path, 1)
	_check(bool(recovered.get("ok", false)) and str(recovered.get("status", "")) == "recovered_from_backup", "a primary with the wrong schema can fall back to a compatible backup")
	_check(Dictionary(recovered.get("data", {})) == version_one and bool(recovered.get("primary_restored", false)), "schema fallback restores the compatible revision to primary")
	_check(str(Dictionary(recovered.get("primary_error", {})).get("status", "")) == "schema_version_mismatch", "schema fallback explicitly reports why the newer primary was rejected")

	var mismatch_path := _new_path("schema_mismatch")
	HiringStorage.save_dictionary(mismatch_path, version_two, 2)
	var mismatch: Dictionary = HiringStorage.load_dictionary(mismatch_path, 1, false)
	_check(not bool(mismatch.get("ok", true)) and str(mismatch.get("status", "")) == "load_failed", "an incompatible primary without a compatible backup fails closed")
	var primary_error: Dictionary = Dictionary(mismatch.get("primary_error", {}))
	_check(str(primary_error.get("status", "")) == "schema_version_mismatch", "schema mismatch is preserved in the public failure details")
	_check(int(primary_error.get("schema_version", 0)) == 2 and int(primary_error.get("expected_schema_version", 0)) == 1, "schema mismatch reports actual and expected versions")


func _test_unsupported_values_and_write_side_failures() -> void:
	var unsupported_path := _new_path("unsupported")
	var unsupported: Dictionary = HiringStorage.save_dictionary(unsupported_path, {"position": Vector2(2.0, 4.0)})
	_check(not bool(unsupported.get("ok", true)) and str(unsupported.get("status", "")) == "unsupported_value", "non-JSON Variant values are rejected before opening a file")
	_check(str(unsupported.get("value_path", "")) == "data.position" and not FileAccess.file_exists(unsupported_path), "unsupported-value result pinpoints the field and creates no primary")

	var keyed_path := _new_path("non_string_key")
	var invalid_keys := {1: "numeric keys lose identity in JSON"}
	var invalid_key_result: Dictionary = HiringStorage.save_dictionary(keyed_path, invalid_keys)
	_check(not bool(invalid_key_result.get("ok", true)) and str(invalid_key_result.get("value_type", "")) == "non_string_dictionary_key", "dictionary keys that cannot round-trip through JSON are rejected")

	var blocked_temporary_path := _new_path("blocked_temporary")
	var temporary_directory := blocked_temporary_path + ".tmp"
	_check(_make_nonempty_directory(temporary_directory), "write-failure fixture creates an isolated nonempty directory at the temporary path")
	var write_failure: Dictionary = HiringStorage.save_dictionary(blocked_temporary_path, {"safe": true})
	_check(not bool(write_failure.get("ok", true)), "an unavailable temporary path returns a write-side failure")
	_check(
		str(write_failure.get("status", "")) in ["temporary_cleanup_failed", "write_open_failed"],
		"write-side failure distinguishes stale-temp cleanup from opening failure"
	)
	_check(int(write_failure.get("error_code", OK)) != OK and not str(write_failure.get("message", "")).is_empty(), "write-side failure includes an error code and readable message")
	_check(not FileAccess.file_exists(blocked_temporary_path), "write-side failure never creates a primary")

	var blocked_primary_path := _new_path("blocked_primary")
	_check(_make_nonempty_directory(blocked_primary_path), "promotion-failure fixture creates an isolated directory at the primary path")
	var promote_failure: Dictionary = HiringStorage.save_dictionary(blocked_primary_path, {"safe": true})
	_check(not bool(promote_failure.get("ok", true)) and str(promote_failure.get("status", "")) == "promote_failed", "failure to promote a verified temporary file has its own status")
	_check(not bool(promote_failure.get("rollback_attempted", true)) and not FileAccess.file_exists(blocked_primary_path + ".tmp"), "promotion failure without a backup reports no rollback and cleans its temporary file")


func _new_path(label: String) -> String:
	var path := "%s_%s.json" % [_prefix, label]
	_check(path != FORMAL_SAVE_PATH and path != FORMAL_META_PATH, "test path '%s' is isolated from formal game storage" % label)
	_paths.append(path)
	return path


func _read_raw(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _write_raw(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	return error == OK


func _make_nonempty_directory(path: String) -> bool:
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return false
	_directories.append(path)
	return _write_raw(path + "/fixture.txt", "test-only blocker")


func _cleanup_test_artifacts() -> void:
	for path in _paths:
		for suffix in ["", ".tmp", ".bak", ".bak.tmp"]:
			var candidate: String = path + str(suffix)
			if FileAccess.file_exists(candidate):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))

	for index in range(_directories.size() - 1, -1, -1):
		var directory_path := _directories[index]
		var fixture_path := directory_path + "/fixture.txt"
		if FileAccess.file_exists(fixture_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory_path)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(directory_path))


func _json_equivalent(left: Variant, right: Variant) -> bool:
	if (typeof(left) == TYPE_INT or typeof(left) == TYPE_FLOAT) and (typeof(right) == TYPE_INT or typeof(right) == TYPE_FLOAT):
		return float(left) == float(right)
	if typeof(left) != typeof(right):
		return false
	if typeof(left) == TYPE_ARRAY:
		var left_array: Array = left
		var right_array: Array = right
		if left_array.size() != right_array.size():
			return false
		for index in range(left_array.size()):
			if not _json_equivalent(left_array[index], right_array[index]):
				return false
		return true
	if typeof(left) == TYPE_DICTIONARY:
		var left_dictionary: Dictionary = left
		var right_dictionary: Dictionary = right
		if left_dictionary.size() != right_dictionary.size():
			return false
		for key in left_dictionary:
			if not right_dictionary.has(key) or not _json_equivalent(left_dictionary[key], right_dictionary[key]):
				return false
		return true
	return left == right


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
