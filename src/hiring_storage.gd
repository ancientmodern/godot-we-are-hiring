class_name HiringStorage
extends RefCounted

## Transactional JSON-dictionary storage for user:// files.
##
## The on-disk root is an envelope so storage migrations stay independent from
## the game's model-save version:
##     {"schema_version": 1, "data": {...}}
##
## Updating an existing file writes and verifies both a temporary new file and
## a temporary backup before the primary is replaced. Public methods never
## throw on ordinary I/O or parse failures; callers receive a status dictionary.
## Legacy bare-dictionary JSON can be read without being rewritten; an explicit
## later save is what migrates it into the versioned envelope.

const ROOT_SCHEMA_VERSION := 1
const SCHEMA_VERSION_KEY := "schema_version"
const DATA_KEY := "data"


static func save_dictionary(path: String, data: Dictionary, schema_version: int = ROOT_SCHEMA_VERSION) -> Dictionary:
	var path_check := _validate_user_path(path)
	if not bool(path_check.get("ok", false)):
		return _failure(
			"save",
			"invalid_path",
			path,
			str(path_check.get("message", "The storage path is invalid.")),
			ERR_INVALID_PARAMETER
		)

	var normalized_path := str(path_check["path"])
	if schema_version <= 0:
		return _failure(
			"save",
			"invalid_schema_version",
			normalized_path,
			"Schema versions must be positive integers.",
			ERR_INVALID_PARAMETER
		)

	var value_error := _json_value_error(data, "data")
	if not value_error.is_empty():
		return _failure(
			"save",
			"unsupported_value",
			normalized_path,
			"The dictionary contains a value that cannot be represented safely as JSON.",
			ERR_INVALID_DATA,
			value_error
		)

	var envelope := {
		SCHEMA_VERSION_KEY: schema_version,
		DATA_KEY: data,
	}
	var serialized := JSON.stringify(envelope)
	var serialized_check := _parse_envelope(serialized, schema_version)
	if not bool(serialized_check.get("ok", false)):
		return _failure(
			"save",
			"serialize_failed",
			normalized_path,
			"The JSON serializer did not produce a valid storage envelope.",
			int(serialized_check.get("error_code", ERR_INVALID_DATA)),
			{"serialization_error": _read_error_summary(serialized_check)}
		)

	var temporary_path := normalized_path + ".tmp"
	var backup_path := normalized_path + ".bak"
	var temporary_cleanup_error := _remove_file_if_exists(temporary_path)
	if temporary_cleanup_error != OK:
		return _failure(
			"save",
			"temporary_cleanup_failed",
			normalized_path,
			"A stale temporary file could not be removed.",
			temporary_cleanup_error,
			{"temporary_path": temporary_path}
		)

	var temporary_write := _write_text_file(temporary_path, serialized)
	if not bool(temporary_write.get("ok", false)):
		return _failure(
			"save",
			str(temporary_write.get("status", "write_failed")),
			normalized_path,
			str(temporary_write.get("message", "The temporary file could not be written.")),
			int(temporary_write.get("error_code", FAILED)),
			{"temporary_path": temporary_path}
		)

	var temporary_check := _read_envelope(temporary_path, schema_version)
	if not bool(temporary_check.get("ok", false)):
		_remove_file_if_exists(temporary_path)
		return _failure(
			"save",
			"temporary_verification_failed",
			normalized_path,
			"The flushed temporary file could not be read back as the expected envelope.",
			int(temporary_check.get("error_code", ERR_INVALID_DATA)),
			{
				"temporary_path": temporary_path,
				"verification_error": _read_error_summary(temporary_check),
			}
		)

	var primary_existed := FileAccess.file_exists(normalized_path)
	var primary_snapshot: Dictionary = {}
	var backup_created := false
	if primary_existed:
		primary_snapshot = _read_envelope(normalized_path, -1, true)
		if bool(primary_snapshot.get("ok", false)):
			var backup_result := _prepare_backup(primary_snapshot, backup_path)
			if not bool(backup_result.get("ok", false)):
				_remove_file_if_exists(temporary_path)
				return _failure(
					"save",
					str(backup_result.get("status", "backup_failed")),
					normalized_path,
					str(backup_result.get("message", "The current primary file could not be backed up safely.")),
					int(backup_result.get("error_code", FAILED)),
					{"backup_path": backup_path, "temporary_path": temporary_path}
				)
			backup_created = true

		var primary_remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(normalized_path))
		if primary_remove_error != OK:
			_remove_file_if_exists(temporary_path)
			return _failure(
				"save",
				"primary_remove_failed",
				normalized_path,
				"The old primary file could not be removed after the replacement was verified.",
				primary_remove_error,
				{"backup_path": backup_path, "backup_created": backup_created}
			)

	var promote_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(normalized_path)
	)
	if promote_error != OK:
		var rollback := _rollback_from_available_backup(normalized_path, backup_path)
		_remove_file_if_exists(temporary_path)
		return _failure(
			"save",
			"promote_failed",
			normalized_path,
			"The verified temporary file could not be promoted to the primary path.",
			promote_error,
			{
				"backup_path": backup_path,
				"backup_created": backup_created,
				"rollback_attempted": bool(rollback.get("attempted", false)),
				"rollback_ok": bool(rollback.get("ok", false)),
				"rollback_status": str(rollback.get("status", "not_attempted")),
			}
		)

	var final_check := _read_envelope(normalized_path, schema_version)
	if not bool(final_check.get("ok", false)):
		var rollback := _rollback_from_available_backup(normalized_path, backup_path)
		return _failure(
			"save",
			"post_write_verification_failed",
			normalized_path,
			"The promoted primary file failed its final read-back verification.",
			int(final_check.get("error_code", ERR_INVALID_DATA)),
			{
				"backup_path": backup_path,
				"backup_created": backup_created,
				"verification_error": _read_error_summary(final_check),
				"rollback_attempted": bool(rollback.get("attempted", false)),
				"rollback_ok": bool(rollback.get("ok", false)),
				"rollback_status": str(rollback.get("status", "not_attempted")),
			}
		)

	return {
		"ok": true,
		"operation": "save",
		"status": "saved",
		"path": normalized_path,
		"temporary_path": temporary_path,
		"backup_path": backup_path,
		"schema_version": schema_version,
		"backup_created": backup_created,
		"replaced_invalid_primary": primary_existed and not bool(primary_snapshot.get("ok", false)),
		"replaced_legacy_primary": primary_existed and bool(primary_snapshot.get("legacy", false)),
		"message": "The dictionary was saved and verified.",
		"error_code": OK,
	}


static func load_dictionary(
	path: String,
	expected_schema_version: int = ROOT_SCHEMA_VERSION,
	restore_primary_from_backup: bool = true,
	accept_legacy_bare_dictionary: bool = true
) -> Dictionary:
	var path_check := _validate_user_path(path)
	if not bool(path_check.get("ok", false)):
		return _failure(
			"load",
			"invalid_path",
			path,
			str(path_check.get("message", "The storage path is invalid.")),
			ERR_INVALID_PARAMETER
		)

	var normalized_path := str(path_check["path"])
	if expected_schema_version <= 0:
		return _failure(
			"load",
			"invalid_schema_version",
			normalized_path,
			"Expected schema versions must be positive integers.",
			ERR_INVALID_PARAMETER
		)

	var backup_path := normalized_path + ".bak"
	var primary := _read_envelope(normalized_path, expected_schema_version, accept_legacy_bare_dictionary)
	if bool(primary.get("ok", false)):
		if bool(primary.get("legacy", false)):
			return _loaded_result(
				"loaded_legacy",
				normalized_path,
				normalized_path,
				primary,
				false,
				false,
				"A legacy bare dictionary was loaded without modifying disk; save it explicitly to migrate to the versioned envelope."
			)
		return _loaded_result(
			"loaded_primary",
			normalized_path,
			normalized_path,
			primary,
			false,
			false,
			"The primary file was loaded."
		)

	var backup := _read_envelope(backup_path, expected_schema_version, accept_legacy_bare_dictionary)
	if not bool(backup.get("ok", false)):
		var status := "load_failed"
		var message := "Neither the primary file nor its backup could be loaded."
		if str(primary.get("status", "")) == "not_found" and str(backup.get("status", "")) == "not_found":
			status = "not_found"
			message = "Neither the primary file nor its backup exists."
		return _failure(
			"load",
			status,
			normalized_path,
			message,
			int(primary.get("error_code", backup.get("error_code", FAILED))),
			{
				"backup_path": backup_path,
				"primary_error": _read_error_summary(primary),
				"backup_error": _read_error_summary(backup),
			}
		)

	if bool(backup.get("legacy", false)):
		var loaded_legacy_backup := _loaded_result(
			"loaded_legacy",
			normalized_path,
			backup_path,
			backup,
			true,
			false,
			"A legacy bare dictionary was loaded from backup without modifying disk; save it explicitly to migrate to the versioned envelope."
		)
		loaded_legacy_backup["primary_error"] = _read_error_summary(primary)
		return loaded_legacy_backup

	if not restore_primary_from_backup:
		var loaded_backup := _loaded_result(
			"loaded_backup",
			normalized_path,
			backup_path,
			backup,
			true,
			false,
			"The primary file was unusable, so the backup was loaded without modifying disk."
		)
		loaded_backup["primary_error"] = _read_error_summary(primary)
		return loaded_backup

	var restore_result := _restore_primary(normalized_path, backup, expected_schema_version)
	if bool(restore_result.get("ok", false)):
		var recovered := _loaded_result(
			"recovered_from_backup",
			normalized_path,
			backup_path,
			backup,
			true,
			true,
			"The backup was loaded and the primary file was restored from it."
		)
		recovered["primary_error"] = _read_error_summary(primary)
		return recovered

	var usable_backup := _loaded_result(
		"loaded_backup_restore_failed",
		normalized_path,
		backup_path,
		backup,
		true,
		false,
		"The backup data is usable, but restoring the primary file failed."
	)
	usable_backup["primary_error"] = _read_error_summary(primary)
	usable_backup["recovery_error"] = _read_error_summary(restore_result)
	usable_backup["error_code"] = int(restore_result.get("error_code", FAILED))
	return usable_backup


static func _prepare_backup(primary: Dictionary, backup_path: String) -> Dictionary:
	var backup_temporary_path := backup_path + ".tmp"
	var cleanup_error := _remove_file_if_exists(backup_temporary_path)
	if cleanup_error != OK:
		return {
			"ok": false,
			"status": "backup_temporary_cleanup_failed",
			"message": "A stale temporary backup could not be removed.",
			"error_code": cleanup_error,
		}

	var write_result := _write_text_file(backup_temporary_path, str(primary.get("raw_text", "")))
	if not bool(write_result.get("ok", false)):
		return {
			"ok": false,
			"status": "backup_" + str(write_result.get("status", "write_failed")),
			"message": "The temporary backup could not be written and flushed.",
			"error_code": int(write_result.get("error_code", FAILED)),
		}

	var verification := _read_envelope(backup_temporary_path, -1, bool(primary.get("legacy", false)))
	if not bool(verification.get("ok", false)):
		_remove_file_if_exists(backup_temporary_path)
		return {
			"ok": false,
			"status": "backup_verification_failed",
			"message": "The temporary backup failed read-back verification.",
			"error_code": int(verification.get("error_code", ERR_INVALID_DATA)),
		}

	if FileAccess.file_exists(backup_path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
		if remove_error != OK:
			_remove_file_if_exists(backup_temporary_path)
			return {
				"ok": false,
				"status": "backup_replace_failed",
				"message": "The previous backup could not be replaced.",
				"error_code": remove_error,
			}

	var promote_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(backup_temporary_path),
		ProjectSettings.globalize_path(backup_path)
	)
	if promote_error != OK:
		_remove_file_if_exists(backup_temporary_path)
		return {
			"ok": false,
			"status": "backup_promote_failed",
			"message": "The verified temporary backup could not be promoted.",
			"error_code": promote_error,
		}

	return {
		"ok": true,
		"status": "backup_ready",
		"message": "The previous primary file was backed up and verified.",
		"error_code": OK,
	}


static func _rollback_from_available_backup(primary_path: String, backup_path: String) -> Dictionary:
	var backup := _read_envelope(backup_path, -1, true)
	if not bool(backup.get("ok", false)):
		return {
			"attempted": false,
			"ok": false,
			"status": "no_usable_backup",
		}
	var rollback := _restore_primary(primary_path, backup, -1)
	rollback["attempted"] = true
	return rollback


static func _restore_primary(primary_path: String, backup: Dictionary, expected_schema_version: int) -> Dictionary:
	var temporary_path := primary_path + ".tmp"
	var cleanup_error := _remove_file_if_exists(temporary_path)
	if cleanup_error != OK:
		return {
			"ok": false,
			"status": "recovery_temporary_cleanup_failed",
			"message": "The recovery temporary file could not be cleared.",
			"error_code": cleanup_error,
		}

	var write_result := _write_text_file(temporary_path, str(backup.get("raw_text", "")))
	if not bool(write_result.get("ok", false)):
		return {
			"ok": false,
			"status": "recovery_" + str(write_result.get("status", "write_failed")),
			"message": "The recovery temporary file could not be written and flushed.",
			"error_code": int(write_result.get("error_code", FAILED)),
		}

	var verification := _read_envelope(temporary_path, expected_schema_version, bool(backup.get("legacy", false)))
	if not bool(verification.get("ok", false)):
		_remove_file_if_exists(temporary_path)
		return {
			"ok": false,
			"status": "recovery_verification_failed",
			"message": "The recovery temporary file failed read-back verification.",
			"error_code": int(verification.get("error_code", ERR_INVALID_DATA)),
		}

	if FileAccess.file_exists(primary_path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(primary_path))
		if remove_error != OK:
			_remove_file_if_exists(temporary_path)
			return {
				"ok": false,
				"status": "recovery_primary_remove_failed",
				"message": "The unusable primary file could not be removed during recovery.",
				"error_code": remove_error,
			}

	var promote_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(primary_path)
	)
	if promote_error != OK:
		_remove_file_if_exists(temporary_path)
		return {
			"ok": false,
			"status": "recovery_promote_failed",
			"message": "The verified recovery file could not be promoted to primary.",
			"error_code": promote_error,
		}

	var final_check := _read_envelope(primary_path, expected_schema_version, bool(backup.get("legacy", false)))
	if not bool(final_check.get("ok", false)):
		return {
			"ok": false,
			"status": "recovery_final_verification_failed",
			"message": "The restored primary file failed final verification.",
			"error_code": int(final_check.get("error_code", ERR_INVALID_DATA)),
		}

	return {
		"ok": true,
		"status": "primary_restored",
		"message": "The primary file was restored from the verified backup.",
		"error_code": OK,
	}


static func _read_envelope(
	path: String,
	expected_schema_version: int,
	accept_legacy_bare_dictionary: bool = false
) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"status": "not_found",
			"message": "The file does not exist.",
			"error_code": ERR_FILE_NOT_FOUND,
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"status": "read_open_failed",
			"message": "The file could not be opened for reading.",
			"error_code": FileAccess.get_open_error(),
		}

	var raw_text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return {
			"ok": false,
			"status": "read_failed",
			"message": "The file could not be read completely.",
			"error_code": read_error,
		}

	var parsed := _parse_envelope(raw_text, expected_schema_version, accept_legacy_bare_dictionary)
	parsed["raw_text"] = raw_text
	return parsed


static func _parse_envelope(
	raw_text: String,
	expected_schema_version: int,
	accept_legacy_bare_dictionary: bool = false
) -> Dictionary:
	var parser := JSON.new()
	var parse_error := parser.parse(raw_text)
	if parse_error != OK:
		return {
			"ok": false,
			"status": "parse_failed",
			"message": parser.get_error_message(),
			"error_code": parse_error,
			"error_line": parser.get_error_line(),
		}

	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"status": "invalid_root",
			"message": "The JSON root must be a dictionary envelope.",
			"error_code": ERR_INVALID_DATA,
		}

	var root: Dictionary = parsed
	var has_schema_marker := root.has(SCHEMA_VERSION_KEY)
	var has_data_marker := root.has(DATA_KEY)
	if not has_schema_marker and not has_data_marker and accept_legacy_bare_dictionary:
		return {
			"ok": true,
			"status": "valid_legacy",
			"message": "The JSON root is a legacy bare dictionary.",
			"error_code": OK,
			"schema_version": 0,
			"data": root,
			"legacy": true,
		}

	if not root.has(SCHEMA_VERSION_KEY):
		return {
			"ok": false,
			"status": "missing_schema_version",
			"message": "The storage envelope has no root schema version.",
			"error_code": ERR_INVALID_DATA,
		}

	var raw_schema: Variant = root[SCHEMA_VERSION_KEY]
	if typeof(raw_schema) != TYPE_INT and typeof(raw_schema) != TYPE_FLOAT:
		return {
			"ok": false,
			"status": "invalid_schema_version",
			"message": "The root schema version must be a positive integer.",
			"error_code": ERR_INVALID_DATA,
		}
	var schema_number := float(raw_schema)
	if is_nan(schema_number) or is_inf(schema_number) or schema_number <= 0.0 or schema_number != floor(schema_number):
		return {
			"ok": false,
			"status": "invalid_schema_version",
			"message": "The root schema version must be a positive integer.",
			"error_code": ERR_INVALID_DATA,
		}
	var schema_version := int(schema_number)
	if expected_schema_version > 0 and schema_version != expected_schema_version:
		return {
			"ok": false,
			"status": "schema_version_mismatch",
			"message": "The storage schema version is %d, but version %d was expected." % [schema_version, expected_schema_version],
			"error_code": ERR_INVALID_DATA,
			"schema_version": schema_version,
			"expected_schema_version": expected_schema_version,
		}

	if not root.has(DATA_KEY) or typeof(root[DATA_KEY]) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"status": "invalid_data",
			"message": "The storage envelope data field must be a dictionary.",
			"error_code": ERR_INVALID_DATA,
			"schema_version": schema_version,
		}

	return {
		"ok": true,
		"status": "valid",
		"message": "The storage envelope is valid.",
		"error_code": OK,
		"schema_version": schema_version,
		"data": Dictionary(root[DATA_KEY]),
	}


static func _write_text_file(path: String, text: String) -> Dictionary:
	var absolute_path := ProjectSettings.globalize_path(path)
	var parent_path := absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent_path):
		var directory_error := DirAccess.make_dir_recursive_absolute(parent_path)
		if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
			return {
				"ok": false,
				"status": "directory_create_failed",
				"message": "The storage directory could not be created.",
				"error_code": directory_error,
			}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"status": "write_open_failed",
			"message": "The file could not be opened for writing.",
			"error_code": FileAccess.get_open_error(),
		}

	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return {
			"ok": false,
			"status": "write_failed",
			"message": "The file could not be written and flushed completely.",
			"error_code": write_error,
		}

	return {
		"ok": true,
		"status": "written",
		"message": "The file was written and flushed.",
		"error_code": OK,
	}


static func _validate_user_path(path: String) -> Dictionary:
	var candidate := path.strip_edges().replace("\\", "/")
	if not candidate.begins_with("user://"):
		return {
			"ok": false,
			"message": "Storage paths must begin with user://.",
		}

	var relative := candidate.substr("user://".length())
	if relative.is_empty() or relative.ends_with("/"):
		return {
			"ok": false,
			"message": "Storage paths must name a file below user://.",
		}

	var parts := relative.split("/", true)
	var clean_parts := PackedStringArray()
	for part in parts:
		if part.is_empty() or part == "." or part == "..":
			return {
				"ok": false,
				"message": "Storage paths cannot contain empty, current-directory, or parent-directory segments.",
			}
		clean_parts.append(part)

	return {
		"ok": true,
		"path": "user://" + "/".join(clean_parts),
	}


static func _json_value_error(value: Variant, value_path: String, depth: int = 0) -> Dictionary:
	if depth > 64:
		return {
			"value_path": value_path,
			"value_type": "maximum_depth_exceeded",
		}

	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return {}
		TYPE_FLOAT:
			var number := float(value)
			if is_nan(number) or is_inf(number):
				return {
					"value_path": value_path,
					"value_type": "non_finite_float",
				}
			return {}
		TYPE_ARRAY:
			var array: Array = value
			for index in range(array.size()):
				var child_error := _json_value_error(array[index], "%s[%d]" % [value_path, index], depth + 1)
				if not child_error.is_empty():
					return child_error
			return {}
		TYPE_DICTIONARY:
			var dictionary: Dictionary = value
			for key in dictionary:
				if typeof(key) != TYPE_STRING:
					return {
						"value_path": value_path,
						"value_type": "non_string_dictionary_key",
					}
				var child_error := _json_value_error(dictionary[key], "%s.%s" % [value_path, key], depth + 1)
				if not child_error.is_empty():
					return child_error
			return {}
		_:
			return {
				"value_path": value_path,
				"value_type": "variant_type_%d" % typeof(value),
			}


static func _remove_file_if_exists(path: String) -> int:
	if not FileAccess.file_exists(path):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _loaded_result(
	status: String,
	primary_path: String,
	source_path: String,
	read_result: Dictionary,
	used_backup: bool,
	primary_restored: bool,
	message: String
) -> Dictionary:
	var is_legacy := bool(read_result.get("legacy", false))
	return {
		"ok": true,
		"operation": "load",
		"status": status,
		"path": primary_path,
		"source_path": source_path,
		"backup_path": primary_path + ".bak",
		"schema_version": int(read_result.get("schema_version", 0)),
		"data": Dictionary(read_result.get("data", {})).duplicate(true),
		"legacy": is_legacy,
		"migration_required": is_legacy,
		"used_backup": used_backup,
		"primary_restored": primary_restored,
		"message": message,
		"error_code": OK,
	}


static func _read_error_summary(result: Dictionary) -> Dictionary:
	var summary := {
		"status": str(result.get("status", "unknown")),
		"message": str(result.get("message", "Unknown storage error.")),
		"error_code": int(result.get("error_code", FAILED)),
	}
	for key in ["error_line", "schema_version", "expected_schema_version"]:
		if result.has(key):
			summary[key] = result[key]
	return summary


static func _failure(
	operation: String,
	status: String,
	path: String,
	message: String,
	error_code: int,
	details: Dictionary = {}
) -> Dictionary:
	var result := {
		"ok": false,
		"operation": operation,
		"status": status,
		"path": path,
		"message": message,
		"error_code": error_code,
	}
	for key in details:
		result[key] = details[key]
	return result
