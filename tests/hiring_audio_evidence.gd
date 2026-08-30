extends SceneTree

const OfficeAudio = preload("res://src/office_audio.gd")

const OUTPUT_DIR := "res://artifacts/audio_evidence"
const SILENT_DB := -80.0
const MIX_PREVIEW_SECONDS := 1.0
const ENDING_IDS: Array[String] = [
	"acquihire", "lights_out", "independent", "successor", "drift", "rm_rf", "second_time",
]

var failures: Array[String] = []
var evidence: Dictionary = {
	"schema_version": 3,
	"generator": "OfficeAudio production streams and scene contexts",
	"mix_rate": OfficeAudio.MIX_RATE,
	"durations": {
		"ambience_loop_seconds": OfficeAudio.LOOP_SECONDS,
		"score_loop_seconds": OfficeAudio.SCORE_LOOP_SECONDS,
		"mix_preview_seconds": MIX_PREVIEW_SECONDS,
	},
	"buses": {
		"ambience": "Ambience",
		"score": "Music",
		"foley": "Foley",
	},
	"logical_stems": {
		"ambience": ["air", "rain", "server_fan", "distant_voices", "keyboard"],
		"score": ["human", "system"],
		"foley": OfficeAudio.FOLEY_KINDS,
	},
	"quality_contract": {
		"score_max_silence_ratio": 0.20,
		"foley_rendered_rms_min": 0.002,
		"foley_rendered_rms_max": 0.08,
		"foley_rendered_peak_min": 0.012,
		"foley_rendered_peak_max": 0.25,
		"audible_mix_rms_min": 0.0008,
		"audible_mix_peak_min": 0.002,
		"mix_peak_max": 0.50,
	},
	"continuous_stems": [],
	"foley": [],
	"chapters": [],
	"thresholds": [],
	"scenes": [],
	"endings": [],
	"spectral_summary": {},
}
var _mix_cache: Dictionary = {}
var _source_sample_cache: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _prepare_output_directory():
		_finish(1)
		return

	var audio = OfficeAudio.new()
	root.add_child(audio)
	await process_frame

	var streams: Dictionary = {
		"air": audio._air.stream as AudioStreamWAV,
		"rain": audio._rain.stream as AudioStreamWAV,
		"server_fan": audio._server_fan.stream as AudioStreamWAV,
		"distant_voices": audio._voices.stream as AudioStreamWAV,
		"keyboard_loose": audio._keys_loose.stream as AudioStreamWAV,
		"keyboard_sync": audio._keys_sync.stream as AudioStreamWAV,
		"score_human": audio._score_human.stream as AudioStreamWAV,
		"score_system": audio._score_system.stream as AudioStreamWAV,
	}
	var stem_metadata: Dictionary = {
		"air": {"category": "ambience", "bus": str(audio._air.bus)},
		"rain": {"category": "ambience", "bus": str(audio._rain.bus)},
		"server_fan": {"category": "ambience", "bus": str(audio._server_fan.bus)},
		"distant_voices": {"category": "ambience", "bus": str(audio._voices.bus)},
		"keyboard_loose": {"category": "ambience", "bus": str(audio._keys_loose.bus)},
		"keyboard_sync": {"category": "ambience", "bus": str(audio._keys_sync.bus)},
		"score_human": {"category": "score", "bus": str(audio._score_human.bus)},
		"score_system": {"category": "score", "bus": str(audio._score_system.bus)},
	}
	for stem_id: String in streams:
		var stream := streams[stem_id] as AudioStreamWAV
		var filename := "stem_%s.wav" % stem_id
		_save_stream(stream, "%s/%s" % [OUTPUT_DIR, filename])
		var metadata := stem_metadata[stem_id] as Dictionary
		var summary := _signal_summary(stream)
		evidence["continuous_stems"].append({
			"id": stem_id,
			"category": metadata["category"],
			"bus": metadata["bus"],
			"file": filename,
			"duration_seconds": summary["duration_seconds"],
			"looping": stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
			"summary": summary,
		})
		evidence["spectral_summary"][stem_id] = summary

	var foley_bus := str((audio._foley_pool[0] as AudioStreamPlayer).bus)
	for kind: String in OfficeAudio.FOLEY_KINDS:
		var source_stream := audio._foley_streams[kind] as AudioStreamWAV
		var gain_db := float(OfficeAudio.FOLEY_VOLUMES_DB[kind])
		# Evidence WAVs represent what reaches the Foley bus, including the exact
		# production playback gain. This makes RMS/peak checks meaningful instead
		# of validating an inaudible player against a healthy raw oscillator.
		var stream := _render_stream_gain(source_stream, gain_db)
		var filename := "foley_%s.wav" % kind
		_save_stream(stream, "%s/%s" % [OUTPUT_DIR, filename])
		var summary := _signal_summary(stream)
		evidence["foley"].append({
			"id": kind,
			"bus": foley_bus,
			"file": filename,
			"duration_seconds": summary["duration_seconds"],
			"looping": stream.loop_mode != AudioStreamWAV.LOOP_DISABLED,
			"gain_db": gain_db,
			"source_summary": _signal_summary(source_stream),
			"summary": summary,
		})

	var chapter_team_sizes: Array[int] = [2, 4, 9, 22, 37]
	var chapter_author_weights: Array[float] = [0.0, 20.0, 50.0, 75.0, 100.0]
	for chapter in 5:
		_record_mix(audio, streams, "chapters", "chapter_%d" % chapter, {
			"screen": "office",
			"chapter": chapter,
			"team_size": chapter_team_sizes[chapter],
			"author_weight": chapter_author_weights[chapter],
			"silence_mode": "normal",
			"music_enabled": true,
		}, true)

	# Thresholds are target snapshots rather than redundant 48-second renders; the
	# exact equal-power behavior is exercised by hiring_audio_test.gd.
	for weight: float in [34.9, 35.0, 60.0, 85.0, 85.1]:
		audio.set_context(2, weight, 9)
		evidence["thresholds"].append({
			"author_weight": weight,
			"target_db": _targets(audio),
		})

	for scene_case: Dictionary in _scene_cases():
		_record_mix(
			audio,
			streams,
			"scenes",
			str(scene_case["id"]),
			scene_case["context"] as Dictionary,
			bool(scene_case["expect_signal"])
		)

	for ending_id: String in ENDING_IDS:
		_record_mix(audio, streams, "endings", ending_id, {
			"screen": "ending",
			"ending_id": ending_id,
			"phase": "",
			"chapter": 4,
			"author_weight": 100.0,
			"team_size": 37,
			"silence_mode": "normal",
			"music_enabled": true,
		}, true)

	var manifest := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if manifest == null:
		_failures_append("cannot write audio evidence manifest")
	else:
		manifest.store_string(JSON.stringify(evidence, "  ", false))
		manifest.close()

	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	audio._foley_streams.clear()
	streams.clear()
	_mix_cache.clear()
	_source_sample_cache.clear()
	audio.queue_free()
	await process_frame
	await process_frame
	_finish(0 if failures.is_empty() else 1)


func _scene_cases() -> Array[Dictionary]:
	return [
		{
			"id": "title",
			"context": {"screen": "title", "chapter": 0, "author_weight": 0.0, "team_size": 1, "silence_mode": "normal", "music_enabled": true},
			"expect_signal": true,
		},
		{
			"id": "onboarding",
			"context": {"screen": "onboarding", "chapter": 3, "author_weight": 80.0, "team_size": 24, "silence_mode": "normal"},
			"expect_signal": true,
		},
		{
			"id": "opening_arrival",
			"context": {"screen": "opening", "phase": "arrival", "chapter": 0, "author_weight": 0.0, "team_size": 2, "silence_mode": "normal", "music_enabled": true},
			"expect_signal": true,
		},
		{
			"id": "opening_power",
			"context": {"screen": "opening", "phase": "power", "chapter": 0, "author_weight": 0.0, "team_size": 2, "silence_mode": "normal", "music_enabled": true},
			"expect_signal": true,
		},
		{
			"id": "opening_handoff",
			"context": {"screen": "opening", "phase": "handoff", "chapter": 0, "author_weight": 0.0, "team_size": 2, "silence_mode": "normal", "music_enabled": true},
			"expect_signal": true,
		},
		{
			"id": "full_silence",
			"context": {"screen": "office", "chapter": 3, "full_silence": true},
			"expect_signal": false,
		},
		{
			"id": "room_tone_only",
			"context": {"screen": "office", "chapter": 2, "silence_mode": "room_tone_only"},
			"expect_signal": true,
		},
		{
			"id": "investor_cafe",
			"context": {"screen": "cafe", "chapter": 1, "author_weight": 20.0, "team_size": 4, "silence_mode": "normal", "music_enabled": true},
			"expect_signal": true,
		},
		{
			"id": "lin_authored_silence",
			"context": {"screen": "lin", "chapter": 1, "silence_mode": "room_tone_only", "music_enabled": false},
			"expect_signal": true,
		},
		{
			"id": "night_shift_1",
			"context": {"screen": "night", "night_id": "night_shift_1", "chapter": 2, "author_weight": 50.0, "team_size": 9, "silence_mode": "normal"},
			"expect_signal": true,
		},
		{
			"id": "night_shift_2",
			"context": {"screen": "night", "night_id": "night_shift_2", "chapter": 3, "author_weight": 75.0, "team_size": 22, "silence_mode": "normal"},
			"expect_signal": true,
		},
		{
			"id": "boardroom",
			"context": {"screen": "boardroom", "chapter": 4, "author_weight": 100.0, "team_size": 37, "silence_mode": "normal"},
			"expect_signal": true,
		},
		{
			"id": "live_replay",
			"context": {"screen": "live_replay", "chapter": 3, "author_weight": 75.0, "team_size": 22, "silence_mode": "normal"},
			"expect_signal": true,
		},
		{
			"id": "layoff_social",
			"context": {"screen": "layoff_social", "chapter": 3, "author_weight": 75.0, "team_size": 22, "silence_mode": "normal"},
			"expect_signal": true,
		},
		{
			"id": "phantom_employee_no_cue",
			"context": {"screen": "office", "event_id": "phantom_employee", "chapter": 3, "author_weight": 75.0, "team_size": 22, "silence_mode": "normal"},
			"expect_signal": true,
		},
		{
			"id": "final_silence",
			"context": {"screen": "office", "chapter": 4, "author_weight": 100.0, "team_size": 37, "silence_mode": "normal", "music_enabled": false},
			"expect_signal": true,
		},
		{
			"id": "rm_rf_shutdown",
			"context": {"screen": "ending", "ending_id": "rm_rf", "phase": "shutdown", "chapter": 4, "silence_mode": "normal", "music_enabled": false},
			"expect_signal": true,
		},
	]


func _record_mix(
	audio,
	streams: Dictionary,
	collection: String,
	id: String,
	context: Dictionary,
	expect_signal: bool
) -> void:
	var before_foley_count := int(audio._foley_play_count)
	audio.set_scene_context(context)
	var targets := _targets(audio)
	var duration_seconds := _mix_duration_seconds(targets)
	var filename := "%s_%s_mix.wav" % [collection.trim_suffix("s"), id]
	var cache_key := _mix_cache_key(targets, duration_seconds)
	var mix: AudioStreamWAV
	if _mix_cache.has(cache_key):
		mix = _mix_cache[cache_key] as AudioStreamWAV
	else:
		mix = _mix_streams(streams, targets, duration_seconds)
		_mix_cache[cache_key] = mix
	_save_stream(mix, "%s/%s" % [OUTPUT_DIR, filename])
	var summary := _signal_summary(mix)
	evidence[collection].append({
		"id": id,
		"context": context,
		"target_db": targets,
		"file": filename,
		"duration_seconds": duration_seconds,
		"expect_signal": expect_signal,
		"automatic_foley_count_delta": int(audio._foley_play_count) - before_foley_count,
		"summary": summary,
	})


func _targets(audio) -> Dictionary:
	return {
		"air": float(audio._target_air),
		"rain": float(audio._target_rain),
		"server_fan": float(audio._target_server_fan),
		"distant_voices": float(audio._target_voices),
		"keyboard_loose": float(audio._target_keys_loose),
		"keyboard_sync": float(audio._target_keys_sync),
		"score_human": float(audio._target_score_human),
		"score_system": float(audio._target_score_system),
	}


func _mix_duration_seconds(_target_db: Dictionary) -> float:
	# Full 12/48-second sources are exported independently. Context mixes are short
	# diagnostic previews of the actual scene entrance, including the title cue.
	return MIX_PREVIEW_SECONDS


func _mix_cache_key(target_db: Dictionary, duration_seconds: float) -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		duration_seconds,
		target_db["air"],
		target_db["rain"],
		target_db["server_fan"],
		target_db["distant_voices"],
		target_db["keyboard_loose"],
		target_db["keyboard_sync"],
		target_db["score_human"],
		target_db["score_system"],
	]


func _mix_streams(streams: Dictionary, target_db: Dictionary, duration_seconds: float) -> AudioStreamWAV:
	var frame_count := int(OfficeAudio.MIX_RATE * duration_seconds)
	var mixed_samples := PackedFloat32Array()
	mixed_samples.resize(frame_count)
	for stem_id: String in streams:
		var db := float(target_db.get(stem_id, SILENT_DB))
		if db <= SILENT_DB:
			continue
		var stream := streams[stem_id] as AudioStreamWAV
		var source_samples := _preview_samples(stem_id, stream, frame_count)
		var gain := db_to_linear(db)
		for frame in frame_count:
			mixed_samples[frame] += source_samples[frame] * gain

	var mixed := PackedByteArray()
	mixed.resize(frame_count * 2)
	for frame in frame_count:
		mixed.encode_s16(frame * 2, int(clampf(mixed_samples[frame], -1.0, 1.0) * 32767.0))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = OfficeAudio.MIX_RATE
	result.stereo = false
	result.loop_mode = AudioStreamWAV.LOOP_FORWARD
	result.loop_begin = 0
	result.loop_end = frame_count
	result.data = mixed
	return result


func _preview_samples(stem_id: String, stream: AudioStreamWAV, frame_count: int) -> PackedFloat32Array:
	var cache_key := "%s|%d" % [stem_id, frame_count]
	if _source_sample_cache.has(cache_key):
		return _source_sample_cache[cache_key] as PackedFloat32Array
	var source_frame_count := int(stream.data.size() / 2)
	var samples := PackedFloat32Array()
	samples.resize(frame_count)
	for frame in frame_count:
		var source_frame := frame % source_frame_count
		samples[frame] = float(stream.data.decode_s16(source_frame * 2)) / 32767.0
	_source_sample_cache[cache_key] = samples
	return samples


func _render_stream_gain(stream: AudioStreamWAV, gain_db: float) -> AudioStreamWAV:
	var gain := db_to_linear(gain_db)
	var bytes := PackedByteArray()
	bytes.resize(stream.data.size())
	for frame in int(stream.data.size() / 2):
		var sample := float(stream.data.decode_s16(frame * 2)) / 32767.0 * gain
		bytes.encode_s16(frame * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var rendered := AudioStreamWAV.new()
	rendered.format = stream.format
	rendered.mix_rate = stream.mix_rate
	rendered.stereo = stream.stereo
	rendered.loop_mode = stream.loop_mode
	rendered.loop_begin = stream.loop_begin
	rendered.loop_end = stream.loop_end
	rendered.data = bytes
	return rendered


func _prepare_output_directory() -> bool:
	var absolute_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		_failures_append("cannot create audio evidence directory: %s" % error_string(make_error))
		return false
	var directory := DirAccess.open(OUTPUT_DIR)
	if directory == null:
		_failures_append("cannot open audio evidence directory")
		return false
	for filename: String in directory.get_files():
		if filename.get_extension().to_lower() == "wav" or filename in ["manifest.json", "spectrum.csv"]:
			var remove_error := directory.remove(filename)
			if remove_error != OK:
				_failures_append("cannot replace stale evidence %s: %s" % [filename, error_string(remove_error)])
	return failures.is_empty()


func _save_stream(stream: AudioStreamWAV, path: String) -> void:
	var error := stream.save_to_wav(path)
	if error != OK:
		_failures_append("cannot save %s: %s" % [path, error_string(error)])


func _signal_summary(stream: AudioStreamWAV) -> Dictionary:
	var frame_count := int(stream.data.size() / 2)
	var sample_stride := maxi(1, int(ceil(float(frame_count) / 8192.0)))
	var sampled_frames := 0
	var sum_squares := 0.0
	var zero_crossings := 0
	var zero_samples := 0
	var peak := 0.0
	var previous := 0.0
	for frame in range(0, frame_count, sample_stride):
		var sample := float(stream.data.decode_s16(frame * 2)) / 32767.0
		sampled_frames += 1
		sum_squares += sample * sample
		peak = maxf(peak, absf(sample))
		if absf(sample) <= 1.0 / 32767.0:
			zero_samples += 1
		if sampled_frames > 1 and ((previous < 0.0 and sample >= 0.0) or (previous >= 0.0 and sample < 0.0)):
			zero_crossings += 1
		previous = sample
	var rms := sqrt(sum_squares / maxf(1.0, float(sampled_frames)))
	return {
		"rms": rms,
		"peak": peak,
		"rms_dbfs": linear_to_db(maxf(0.000000001, rms)),
		"peak_dbfs": linear_to_db(maxf(0.000000001, peak)),
		"zero_crossings": zero_crossings,
		"silence_ratio": float(zero_samples) / maxf(1.0, float(sampled_frames)),
		"sampled_frames": sampled_frames,
		"sample_stride": sample_stride,
		"duration_seconds": float(frame_count) / float(stream.mix_rate),
	}


func _failures_append(message: String) -> void:
	failures.append(message)
	push_error("HIRING_AUDIO_EVIDENCE_FAILURE: " + message)


func _finish(code: int) -> void:
	if code == 0:
		print(
			"HIRING_AUDIO_EVIDENCE_PASS: %d continuous stems, %d foley, %d chapter mixes, %d threshold snapshots, %d scene mixes, %d ending mixes"
			% [8, OfficeAudio.FOLEY_KINDS.size(), 5, 5, _scene_cases().size(), ENDING_IDS.size()]
		)
	quit(code)
