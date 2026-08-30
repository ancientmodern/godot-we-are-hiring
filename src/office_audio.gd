class_name OfficeAudio
extends Node

const MIX_RATE := 22050
const LOOP_SECONDS := 12.0
const SCORE_LOOP_SECONDS := 48.0
const SILENT_DB := -80.0
const FADE_DB_PER_SECOND := 24.0
const FOLEY_POOL_SIZE := 4
const FOLEY_COOLDOWN_MS := 90
const FOLEY_KINDS: Array[String] = [
	"confirm", "page", "blocked", "signature", "terminal", "curtain",
	"door", "footstep", "switch", "cup", "projector", "phone", "server_stop",
	"gpu_start",
]
const FOLEY_DURATIONS := {
	"confirm": 0.075,
	"page": 0.34,
	"blocked": 0.12,
	"signature": 1.05,
	"terminal": 0.11,
	"curtain": 0.48,
	"door": 0.32,
	"footstep": 0.22,
	"switch": 0.085,
	"cup": 0.18,
	"projector": 0.095,
	"phone": 0.055,
	"server_stop": 1.15,
	"gpu_start": 1.35,
}
const FOLEY_VOLUMES_DB := {
	"confirm": -7.0,
	"page": -9.0,
	"blocked": -9.0,
	"signature": -8.0,
	"terminal": -6.0,
	"curtain": -8.0,
	"door": -7.0,
	"footstep": -10.0,
	"switch": -8.0,
	"cup": -9.0,
	"projector": -8.0,
	"phone": -11.0,
	"server_stop": -7.0,
	"gpu_start": -5.0,
}

var muted := false:
	set(value):
		muted = value
		if muted:
			_stop_foley(_preserve_latest_foley_on_mute)

var _air: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _server_fan: AudioStreamPlayer
var _voices: AudioStreamPlayer
var _keys_loose: AudioStreamPlayer
var _keys_sync: AudioStreamPlayer
var _score_human: AudioStreamPlayer
var _score_system: AudioStreamPlayer
var _foley_pool: Array[AudioStreamPlayer] = []
var _foley_streams: Dictionary = {}
var _foley_cursor := 0
var _foley_last_played_ms: Dictionary = {}
var _foley_play_count := 0
var _preserve_latest_foley_on_mute := false

var _target_air := SILENT_DB
var _target_rain := SILENT_DB
var _target_server_fan := SILENT_DB
var _target_voices := SILENT_DB
var _target_keys_loose := SILENT_DB
var _target_keys_sync := SILENT_DB
var _target_score_human := SILENT_DB
var _target_score_system := SILENT_DB
var _scene_context: Dictionary = {
		"screen": "title",
	"chapter": 0,
	"author_weight": 0.0,
	"team_size": 1,
	"week_in_chapter": 1,
	"silence_mode": "normal",
	"music_enabled": true,
	"night_id": "",
	"ending_id": "",
	"phase": "",
}


func _ready() -> void:
	# Continuous layers start silent. The legacy caller does not update audio while
	# onboarding, so this prevents an office HVAC bed leaking into the opening.
	_air = _make_player(_build_air_loop(), SILENT_DB)
	_rain = _make_player(_build_rain_loop(), SILENT_DB)
	_server_fan = _make_player(_build_server_fan_loop(), SILENT_DB)
	_voices = _make_player(_build_voice_loop(), SILENT_DB)
	_keys_loose = _make_player(_build_keyboard_loop(false), SILENT_DB)
	_keys_sync = _make_player(_build_keyboard_loop(true), SILENT_DB)
	_score_human = _make_player(_build_score_loop(true), SILENT_DB)
	_score_system = _make_player(_build_score_loop(false), SILENT_DB)
	for player: AudioStreamPlayer in [_air, _rain, _server_fan, _voices, _keys_loose, _keys_sync]:
		player.bus = &"Ambience"
	for player: AudioStreamPlayer in [_score_human, _score_system]:
		player.bus = &"Music"
	for kind: String in FOLEY_KINDS:
		_foley_streams[kind] = _build_foley_stream(kind)
	for index in FOLEY_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "Foley%02d" % index
		player.volume_db = SILENT_DB
		player.bus = &"Foley"
		add_child(player)
		_foley_pool.append(player)
	# The dummy/headless backend never mixes a frame, so starting loop playbacks
	# there leaves their WAV resources retained at process shutdown. Desktop builds
	# keep every continuous layer running so context changes can crossfade cleanly.
	if DisplayServer.get_name() != "headless":
		for player: AudioStreamPlayer in _continuous_players():
			player.play()
	_apply_scene_context()
	if DisplayServer.get_name() != "headless":
		_snap_continuous_to_targets()


func set_context(chapter: int, author_weight: float, team_size: int) -> void:
	# Backward-compatible entry point used by hiring_main.gd. A legacy update means
	# the player has left onboarding and is in the ordinary office sound field.
	set_scene_context({
		"screen": "office",
		"chapter": chapter,
		"author_weight": author_weight,
		"team_size": team_size,
		# The compatibility entry point historically represented the settled final
		# chapter mix. New callers provide the real week for the gradual withdrawal.
		"week_in_chapter": 8 if chapter >= 4 else 1,
		"silence_mode": "normal",
		"night_id": "",
		"ending_id": "",
		"phase": "",
	})


func set_scene_context(context: Dictionary) -> void:
	# Context is deliberately data-driven: narrative code can supply only fields
	# that changed, while silence aliases make authored quiet beats easy to express.
	if context.has("screen"):
		var next_screen := str(context["screen"]).strip_edges().to_lower()
		if not next_screen.contains("night") and not context.has("night_id"):
			_scene_context["night_id"] = ""
		if next_screen != "ending" and not context.has("ending_id"):
			_scene_context["ending_id"] = ""
	for key: Variant in context:
		if key not in ["full_silence", "room_tone_only"]:
			_scene_context[key] = context[key]
	if bool(context.get("full_silence", false)):
		_scene_context["silence_mode"] = "full_silence"
	elif bool(context.get("room_tone_only", false)):
		_scene_context["silence_mode"] = "room_tone_only"
	elif context.has("full_silence") or context.has("room_tone_only"):
		_scene_context["silence_mode"] = "normal"
	_apply_scene_context()


func play_foley(kind: String) -> bool:
	# There is intentionally no anomaly cue. Unknown names, including "anomaly",
	# are ignored instead of being mapped to a generic notification sound.
	var normalized := kind.strip_edges().to_lower()
	if muted or not _foley_streams.has(normalized) or _foley_pool.is_empty():
		return false
	var now := Time.get_ticks_msec()
	var last_played := int(_foley_last_played_ms.get(normalized, -FOLEY_COOLDOWN_MS - 1))
	if now - last_played < FOLEY_COOLDOWN_MS:
		return false
	var player := _foley_pool[_foley_cursor]
	_foley_cursor = (_foley_cursor + 1) % _foley_pool.size()
	player.stop()
	player.stream = _foley_streams[normalized]
	player.volume_db = float(FOLEY_VOLUMES_DB.get(normalized, -18.0))
	player.pitch_scale = 1.0
	# Headless/dummy audio never consumes playback objects reliably. Assigning the
	# exact one-shot stream still exercises the contract without leaking a playback
	# object when the test process exits.
	if DisplayServer.get_name() != "headless":
		player.play()
	_foley_last_played_ms[normalized] = now
	_foley_play_count += 1
	return true


func _process(delta: float) -> void:
	if _air == null:
		return
	var targets: Array[float] = [
		_target_air, _target_rain, _target_server_fan, _target_voices, _target_keys_loose,
		_target_keys_sync, _target_score_human, _target_score_system,
	]
	var players := _continuous_players()
	for index in players.size():
		var destination := SILENT_DB if muted else targets[index]
		players[index].volume_db = move_toward(players[index].volume_db, destination, delta * FADE_DB_PER_SECOND)


func toggle_mute() -> bool:
	muted = not muted
	return muted


func mute_preserving_latest_foley(preserve_latest: bool = true) -> bool:
	# The settings register is a physical switch. Keep only that already-started
	# 85 ms contact tail while muting; direct property assignment and the legacy
	# toggle still stop every one-shot immediately.
	if muted:
		return true
	_preserve_latest_foley_on_mute = preserve_latest
	muted = true
	_preserve_latest_foley_on_mute = false
	return muted


func _apply_scene_context() -> void:
	_resolve_scene_targets()
	if str(_scene_context.get("silence_mode", "normal")).strip_edges().to_lower() == "duck_music":
		# Duck only the non-diegetic stems. Physical room tone and direct-action
		# foley remain unchanged, so this cannot become an anomaly notification.
		_target_score_human = maxf(SILENT_DB, _target_score_human - 6.0)
		_target_score_system = maxf(SILENT_DB, _target_score_system - 6.0)


func _resolve_scene_targets() -> void:
	_reset_targets()
	var screen := str(_scene_context.get("screen", "office")).strip_edges().to_lower()
	var silence_mode := str(_scene_context.get("silence_mode", "normal")).strip_edges().to_lower()
	var chapter := clampi(int(_scene_context.get("chapter", 0)), 0, 4)
	var week_in_chapter := clampi(int(_scene_context.get("week_in_chapter", 1)), 1, 8)
	var author_weight := clampf(float(_scene_context.get("author_weight", 0.0)), 0.0, 100.0)
	var team_size := maxi(1, int(_scene_context.get("team_size", 1)))
	var music_enabled := bool(_scene_context.get("music_enabled", true))

	if silence_mode == "full_silence":
		return
	if silence_mode == "room_tone_only":
		_target_air = -21.0
		_target_server_fan = -31.0
		return
	if screen in ["title", "onboarding"]:
		_target_air = -25.0
		_target_rain = -13.0
		_target_score_human = -6.0 if music_enabled else SILENT_DB
		return
	if screen in ["opening", "tutorial"]:
		var opening_phase := str(_scene_context.get("phase", "arrival")).to_lower()
		_target_air = -24.0
		_target_rain = -11.0
		_target_score_human = -8.0 if music_enabled else SILENT_DB
		if opening_phase in ["arrival", "name_question", "name_reply", "mission_question"]:
			_target_server_fan = -18.0
		elif opening_phase == "handoff":
			_target_server_fan = -14.0
		return

	var night_id := str(_scene_context.get("night_id", "")).to_lower()
	if screen.contains("night") or not night_id.is_empty():
		_apply_night_context(night_id, author_weight, team_size)
		return
	var ending_id := str(_scene_context.get("ending_id", "")).to_lower()
	if screen == "ending" or not ending_id.is_empty():
		_apply_ending_context(ending_id, str(_scene_context.get("phase", "")).to_lower())
		if not music_enabled:
			_target_score_human = SILENT_DB
			_target_score_system = SILENT_DB
		return
	if screen in ["cafe", "café", "investor_cafe"]:
		_target_air = -23.0
		_target_rain = -20.0
		_target_voices = -27.0
		_target_score_human = -12.0 if music_enabled else SILENT_DB
		return
	if screen in ["downstairs", "outside", "lin"]:
		_target_air = -25.0
		_target_rain = -22.0
		_target_voices = -32.0
		_target_score_human = -14.0 if music_enabled else SILENT_DB
		return
	if screen in ["board", "boardroom", "live_replay", "layoff_social"]:
		_target_air = -22.0
		_target_server_fan = -27.0 if screen == "live_replay" else -32.0
		_target_score_system = -17.0 if music_enabled and screen == "board" else SILENT_DB
		return

	# Ordinary office ambience preserves the original chapter/team behaviour and
	# adds a separate low server layer. Chapter four still has exactly one audible
	# ambience layer; its sparse system score is a separate, much quieter voice.
	if chapter >= 4:
		# Endgame is an eight-week acoustic withdrawal, not a hard scene cut. Air,
		# server, voices, and loose typing recede week by week; the last week has
		# exactly one ambience layer, the unnaturally synchronized keyboard.
		var withdrawal := float(week_in_chapter - 1) / 7.0
		_target_air = lerpf(-18.0, SILENT_DB, withdrawal)
		_target_server_fan = lerpf(-27.0, SILENT_DB, withdrawal)
		_target_voices = lerpf(-25.0, SILENT_DB, withdrawal)
		_set_keyboard_targets(author_weight, lerpf(-25.0, -21.0, withdrawal))
		_target_keys_loose = lerpf(_target_keys_loose, SILENT_DB, withdrawal)
		_target_keys_sync = lerpf(_target_keys_sync, -14.0, withdrawal)
		_target_score_human = SILENT_DB
		_target_score_system = lerpf(-18.0, -12.0, withdrawal) if music_enabled else SILENT_DB
		if week_in_chapter == 8:
			_target_air = SILENT_DB
			_target_server_fan = SILENT_DB
			_target_voices = SILENT_DB
			_target_keys_loose = SILENT_DB
		return
	_target_air = -18.0 + minf(2.0, float(chapter) * 0.5)
	_target_server_fan = -28.0 + minf(7.0, float(chapter) * 1.2 + float(team_size) * 0.10)
	_target_voices = SILENT_DB if chapter == 0 else (-29.0 + minf(11.0, float(team_size) * 0.52))
	_set_keyboard_targets(author_weight, -28.0 + minf(12.0, float(team_size) * 0.45))
	if music_enabled:
		var system_weight := clampf((author_weight - 20.0) / 80.0, 0.0, 1.0)
		_target_score_human = lerpf(-9.0, -19.0, system_weight)
		_target_score_system = SILENT_DB if system_weight <= 0.01 else lerpf(-20.0, -10.0, system_weight)


func _apply_night_context(night_id: String, author_weight: float, team_size: int) -> void:
	# Night one explicitly says everyone has left and only the HVAC remains.
	if night_id.contains("1"):
		_target_air = -17.0
		return
	# Night two names all three audible office layers. Music remains absent so the
	# physical room, not a score, carries the scene.
	_target_air = -18.0
	_target_server_fan = -26.0
	_target_voices = -31.0
	_set_keyboard_targets(author_weight, -27.0 + minf(4.0, float(team_size) * 0.12))


func _apply_ending_context(ending_id: String, phase: String) -> void:
	match ending_id:
		"second_time":
			_target_air = -19.0
			_target_server_fan = -29.0
			_set_keyboard_targets(0.0, -25.0)
			_target_score_human = -9.0
		"rm_rf":
			_target_air = -18.0
			_target_server_fan = SILENT_DB if phase in ["shutdown", "aftermath", "complete"] else -23.0
		"lights_out":
			_target_air = -25.0
			_target_server_fan = -32.0
		"independent":
			_target_air = -19.0
			_target_voices = -30.0
			_set_keyboard_targets(18.0, -25.0)
			_target_score_human = -9.0
		"successor":
			_target_keys_sync = -17.0
			_target_score_system = -11.0
		"drift":
			_target_air = -22.0
			_target_keys_loose = -27.0
			_target_keys_sync = -27.0
			_target_score_system = -14.0
		"acquihire":
			_target_air = -21.0
			_target_voices = -31.0
		_:
			_target_keys_sync = -19.0


func _set_keyboard_targets(author_weight: float, base_keys: float) -> void:
	# Equal-power gains keep the authored 35..85 transition free of a midpoint dip.
	var sync := clampf((author_weight - 35.0) / 50.0, 0.0, 1.0)
	var loose_gain := sqrt(maxf(0.0, 1.0 - sync))
	var sync_gain := sqrt(maxf(0.0, sync))
	_target_keys_loose = base_keys + linear_to_db(maxf(0.001, loose_gain))
	_target_keys_sync = base_keys + linear_to_db(maxf(0.001, sync_gain))


func _reset_targets() -> void:
	_target_air = SILENT_DB
	_target_rain = SILENT_DB
	_target_server_fan = SILENT_DB
	_target_voices = SILENT_DB
	_target_keys_loose = SILENT_DB
	_target_keys_sync = SILENT_DB
	_target_score_human = SILENT_DB
	_target_score_system = SILENT_DB


func _stop_foley(preserve_latest: bool = false) -> void:
	var preserved: AudioStreamPlayer = null
	if preserve_latest and not _foley_pool.is_empty():
		preserved = _foley_pool[posmod(_foley_cursor - 1, _foley_pool.size())]
	for player: AudioStreamPlayer in _foley_pool:
		if player != preserved:
			player.stop()


func _continuous_players() -> Array[AudioStreamPlayer]:
	return [_air, _rain, _server_fan, _voices, _keys_loose, _keys_sync, _score_human, _score_system]


func _snap_continuous_to_targets() -> void:
	var targets: Array[float] = [
		_target_air, _target_rain, _target_server_fan, _target_voices,
		_target_keys_loose, _target_keys_sync, _target_score_human, _target_score_system,
	]
	var players := _continuous_players()
	for index in mini(players.size(), targets.size()):
		players[index].volume_db = SILENT_DB if muted else targets[index]


func _make_player(stream: AudioStreamWAV, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player


func _build_air_loop() -> AudioStreamWAV:
	var frames := int(MIX_RATE * LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var slow := 0.0
	for frame in frames:
		var white := _noise(frame * 17 + 11)
		slow = slow * 0.992 + white * 0.008
		var hum := sin(TAU * 58.0 * float(frame) / MIX_RATE) * 0.025
		var sample := slow * 0.55 + white * 0.035 + hum
		bytes.encode_s16(frame * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _loop_stream(bytes, frames)


func _build_rain_loop() -> AudioStreamWAV:
	var frames := int(MIX_RATE * LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var wash := 0.0
	var drops := PackedFloat32Array()
	drops.resize(frames)
	for drop in 92:
		var start := int(fposmod(float(drop * 1777 + 331), float(frames)))
		var drop_frames := int(MIX_RATE * (0.018 + float(drop % 5) * 0.004))
		for offset in drop_frames:
			var frame := (start + offset) % frames
			var local := float(offset) / float(maxi(1, drop_frames))
			drops[frame] += (_noise(frame * 43 + drop * 991) * 0.16 + sin(TAU * (1180.0 + drop % 7 * 83.0) * float(offset) / MIX_RATE) * 0.035) * pow(1.0 - local, 2.0)
	for frame in frames:
		var white := _noise(frame * 29 + 4049)
		wash = wash * 0.94 + white * 0.06
		var sample := wash * 0.19 + white * 0.045 + drops[frame]
		bytes.encode_s16(frame * 2, int(clampf(sample, -0.92, 0.92) * 32767.0))
	return _loop_stream(bytes, frames)


func _build_server_fan_loop() -> AudioStreamWAV:
	var frames := int(MIX_RATE * LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var filtered := 0.0
	for frame in frames:
		var t := float(frame) / MIX_RATE
		var white := _noise(frame * 23 + 701)
		filtered = filtered * 0.975 + white * 0.025
		var fan := sin(TAU * 92.0 * t) * 0.032 + sin(TAU * 184.0 * t + 0.4) * 0.013
		var sample := fan + filtered * 0.11 + white * 0.012
		bytes.encode_s16(frame * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _loop_stream(bytes, frames)


func _build_voice_loop() -> AudioStreamWAV:
	var frames := int(MIX_RATE * LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for frame in frames:
		var t := float(frame) / MIX_RATE
		var envelope := 0.0
		for group in 5:
			var center := 1.1 + group * 2.35
			var distance := absf(t - center)
			envelope += maxf(0.0, 1.0 - distance / 0.72) * (0.55 + 0.15 * sin(group * 4.2))
		var murmur := sin(TAU * 118.0 * t + sin(t * 2.1) * 1.3) + sin(TAU * 173.0 * t) * 0.52
		var sample := murmur * envelope * 0.045 + _noise(frame * 7) * envelope * 0.018
		bytes.encode_s16(frame * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _loop_stream(bytes, frames)


func _build_keyboard_loop(synchronized: bool) -> AudioStreamWAV:
	var frames := int(MIX_RATE * LOOP_SECONDS)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var times: Array[float] = []
	if synchronized:
		for beat in 48:
			times.append(0.12 + beat * 0.245)
	else:
		var cursor := 0.08
		for beat in 84:
			cursor += 0.075 + fposmod(sin(beat * 8.73) * 437.0, 0.19)
			if cursor < LOOP_SECONDS:
				times.append(cursor)
	var click_frames := int(MIX_RATE * 0.022)
	for key_time in times:
		var start_frame := int(key_time * MIX_RATE)
		for offset in click_frames:
			var frame := start_frame + offset
			if frame >= frames:
				break
			var local := float(offset) / MIX_RATE
			var envelope := 1.0 - local / 0.022
			samples[frame] += (_noise(frame * 31 + int(key_time * 1000.0)) * 0.28 + sin(TAU * 820.0 * local) * 0.12) * envelope
	for frame in frames:
		bytes.encode_s16(frame * 2, int(clampf(samples[frame], -1.0, 1.0) * 32767.0))
	return _loop_stream(bytes, frames)


func _build_score_loop(human: bool) -> AudioStreamWAV:
	var frames := int(MIX_RATE * SCORE_LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var starts: Array[float] = []
	var frequencies: Array[float] = []
	var note_duration := 3.6 if human else 5.2
	var human_melody := [293.66, 329.63, 349.23, 440.0, 349.23, 293.66, 261.63, 329.63, 293.66, 220.0, 261.63, 329.63]
	var system_melody := [146.83, 220.0, 164.81, 246.94, 174.61, 220.0, 146.83, 196.0]
	if human:
		for note in 24:
			starts.append(0.16 + float(note) * 2.0)
			frequencies.append(float(human_melody[note % human_melody.size()]))
	else:
		for note in 12:
			starts.append(0.7 + float(note) * 4.0)
			frequencies.append(float(system_melody[note % system_melody.size()]))
	var human_chords := [
		[146.83, 220.0, 293.66, 329.63],
		[116.54, 174.61, 220.0, 293.66],
		[174.61, 261.63, 329.63, 440.0],
		[130.81, 196.0, 293.66, 329.63],
		[146.83, 220.0, 293.66, 349.23],
		[130.81, 196.0, 261.63, 329.63],
	]
	for frame in frames:
		var t := float(frame) / MIX_RATE
		var sample := 0.0
		if human:
			var chord_index := clampi(int(t / 8.0), 0, human_chords.size() - 1)
			var chord_local := fposmod(t, 8.0)
			var chord_envelope := minf(1.0, chord_local / 0.9) * minf(1.0, (8.0 - chord_local) / 1.25)
			var chord: Array = human_chords[chord_index]
			for chord_frequency_value in chord:
				var chord_frequency := float(chord_frequency_value)
				sample += (
					sin(TAU * chord_frequency * t) * 0.018
					+ sin(TAU * chord_frequency * 2.002 * t + 0.31) * 0.0045
				) * chord_envelope
		var note_spacing := 2.0 if human else 4.0
		var first_note_start := 0.16 if human else 0.7
		var latest_note_index := int(floor((t - first_note_start) / note_spacing))
		for note_index in [latest_note_index - 1, latest_note_index]:
			if note_index < 0 or note_index >= starts.size():
				continue
			var local := t - starts[note_index]
			if local < 0.0 or local >= note_duration:
				continue
			var attack := minf(1.0, local / (0.035 if human else 0.8))
			var release := pow(maxf(0.0, 1.0 - local / note_duration), 2.15 if human else 1.55)
			var frequency := frequencies[note_index]
			if human:
				var drift := sin(local * 0.71 + note_index) * 0.0025
				var felt_body := (
					sin(TAU * frequency * (1.0 + drift) * local) * 0.105
					+ sin(TAU * frequency * 1.997 * local + 0.18) * 0.031
					+ sin(TAU * frequency * 3.006 * local + 0.51) * 0.012
				)
				var hammer_envelope := minf(1.0, local / 0.009) * exp(-local * 24.0)
				var felt_hammer := _noise(frame * 19 + note_index * 1709) * hammer_envelope * 0.036
				sample += felt_body * attack * release + felt_hammer * release
			else:
				# Inharmonic partials bloom slowly like rubbed glass; there is no short
				# tonal attack that could read as a notification or success cue.
				var glass_body := (
					sin(TAU * frequency * local) * 0.048
					+ sin(TAU * frequency * 1.498 * local + 0.61) * 0.029
					+ sin(TAU * frequency * 2.414 * local + 1.17) * 0.014
					+ sin(TAU * frequency * 3.903 * local + 0.33) * 0.006
				)
				sample += glass_body * attack * pow(maxf(0.0, 1.0 - local / note_duration), 1.45)
		bytes.encode_s16(frame * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _loop_stream(bytes, frames)


func _build_foley_stream(kind: String) -> AudioStreamWAV:
	var duration := float(FOLEY_DURATIONS.get(kind, 0.12))
	var frames := maxi(1, int(MIX_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var seed_offset := int(kind.hash())
	var filtered_noise := 0.0
	for frame in frames:
		var t := float(frame) / MIX_RATE
		var progress := clampf(t / duration, 0.0, 1.0)
		var noise := _noise(frame * 37 + seed_offset)
		filtered_noise = filtered_noise * 0.72 + noise * 0.28
		var sample := 0.0
		match kind:
			"page", "curtain":
				var cloth_envelope := pow(sin(PI * progress), 1.4)
				sample = (filtered_noise * 0.11 + noise * 0.025) * cloth_envelope * (1.0 if kind == "page" else 0.78)
			"signature":
				var scratch_gate := 0.35 + 0.65 * absf(sin(TAU * 7.0 * t))
				sample = (filtered_noise * 0.085 + noise * 0.025) * sin(PI * progress) * scratch_gate
			"blocked", "door", "footstep", "cup":
				var low_frequency := 105.0 if kind == "blocked" else (78.0 if kind == "footstep" else (142.0 if kind == "door" else 196.0))
				var knock_envelope := exp(-t * (18.0 if kind == "door" else 27.0))
				var contact := sin(TAU * low_frequency * t) * 0.145 + sin(TAU * low_frequency * 1.73 * t + 0.3) * 0.036
				sample = (contact + filtered_noise * 0.072 + noise * 0.018) * knock_envelope
				if kind == "cup":
					sample += (sin(TAU * 683.0 * t) * 0.035 + sin(TAU * 1037.0 * t) * 0.014) * exp(-t * 31.0)
			"server_stop":
				var spin := pow(maxf(0.0, 1.0 - progress), 1.7)
				var falling_frequency := 96.0 - progress * 46.0
				sample = (sin(TAU * falling_frequency * t) * 0.075 + sin(TAU * falling_frequency * 2.03 * t) * 0.018 + filtered_noise * 0.032) * spin
			"gpu_start":
				var click := (sin(TAU * 238.0 * t) * 0.13 + filtered_noise * 0.08) * exp(-t * 55.0)
				var motor_progress := clampf((t - 0.08) / maxf(0.01, duration - 0.08), 0.0, 1.0)
				var rising_frequency := 48.0 + motor_progress * 62.0
				var motor_envelope := minf(1.0, motor_progress * 5.0) * (0.75 + motor_progress * 0.25)
				var motor := (
					sin(TAU * rising_frequency * t) * 0.095
					+ sin(TAU * rising_frequency * 2.01 * t + 0.2) * 0.028
					+ filtered_noise * 0.045
				) * motor_envelope
				sample = click + motor
			"phone":
				var glass_tap := exp(-t * 82.0)
				sample = (filtered_noise * 0.09 + sin(TAU * 1283.0 * t) * 0.032 + sin(TAU * 1973.0 * t + 0.4) * 0.012) * glass_tap
			_:
				var contact_frequency := 224.0 if kind == "confirm" else (168.0 if kind == "terminal" else (312.0 if kind == "switch" else 186.0))
				var first_contact := exp(-t * 58.0)
				var second_local := t - (0.014 if kind in ["switch", "projector"] else 0.022)
				var second_contact := exp(-second_local * 76.0) if second_local >= 0.0 else 0.0
				sample = (
					(filtered_noise * 0.105 + sin(TAU * contact_frequency * t) * 0.052 + sin(TAU * contact_frequency * 1.81 * t + 0.2) * 0.018) * first_contact
					+ (_noise(frame * 53 + seed_offset + 991) * 0.052 + sin(TAU * contact_frequency * 0.74 * second_local) * 0.018) * second_contact
				)
		bytes.encode_s16(frame * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _one_shot_stream(bytes)


func _loop_stream(bytes: PackedByteArray, frames: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	stream.data = bytes
	return stream


func _one_shot_stream(bytes: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = bytes
	return stream


func _noise(seed_value: int) -> float:
	return fposmod(sin(float(seed_value * 91 + 17)) * 43758.5453, 2.0) - 1.0
