extends SceneTree

const OfficeAudio = preload("res://src/office_audio.gd")

const SILENT_DB := -80.0
const EPSILON := 0.0001

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio = OfficeAudio.new()
	root.add_child(audio)
	await process_frame

	_test_audio_graph_and_generated_signal(audio)
	_test_title_opening_and_authored_silence(audio)
	_test_chapter_zero_has_no_distant_voices(audio)
	_test_keyboard_crossfade_from_35_to_85(audio)
	_test_chapter_four_ambience_and_restrained_score(audio)
	_test_chapter_four_weekly_withdrawal_and_music_duck(audio)
	await _test_foley_pool_cooldown_and_mute(audio)

	# Dummy/headless audio does not always release active WAVs on its own.
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	audio._foley_streams.clear()
	audio.queue_free()
	await process_frame
	if failures.is_empty():
		print("HIRING_AUDIO_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_AUDIO_TEST_FAILURE: " + failure)
		quit(1)


func _test_audio_graph_and_generated_signal(audio) -> void:
	var ambience_players: Array[AudioStreamPlayer] = [
		audio._air, audio._rain, audio._server_fan, audio._voices, audio._keys_loose, audio._keys_sync,
	]
	var score_players: Array[AudioStreamPlayer] = [audio._score_human, audio._score_system]
	var continuous_players: Array[AudioStreamPlayer] = ambience_players + score_players
	for bus_name: StringName in [&"Ambience", &"Music", &"Foley"]:
		_check(AudioServer.get_bus_index(bus_name) >= 0, "project audio layout exposes the %s bus" % bus_name)
	_check(ambience_players.size() == 6, "graph exposes HVAC, rain, server fan, voices, and two keyboard variants")
	_check(score_players.size() == 2, "graph exposes separate sustained human and system score stems")
	_check(audio._foley_pool.size() == OfficeAudio.FOLEY_POOL_SIZE, "graph provides a bounded one-shot foley player pool")
	_check(audio.get_child_count() == continuous_players.size() + audio._foley_pool.size(), "every playback child belongs to a declared continuous stem or foley pool")

	var unique_players := {}
	for player: AudioStreamPlayer in continuous_players:
		unique_players[player.get_instance_id()] = true
		_check(player.stream is AudioStreamWAV, "each continuous stem is a generated WAV")
		if player.stream is AudioStreamWAV:
			var stream := player.stream as AudioStreamWAV
			_check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "continuous stems loop")
			_check(stream.mix_rate == OfficeAudio.MIX_RATE, "continuous stems use the declared mix rate")
			_check(_stream_has_signal(stream), "continuous stems contain nonzero generated signal")
			_check(_stream_peak(stream) < 0.5, "continuous source signal leaves generous raw headroom")
	_check(unique_players.size() == continuous_players.size(), "all continuous players are distinct")
	for player: AudioStreamPlayer in ambience_players:
		_check(player.bus == &"Ambience", "every ambience player routes to the Ambience bus")
		var ambience_stream := player.stream as AudioStreamWAV
		_check(ambience_stream.data.size() == int(OfficeAudio.MIX_RATE * OfficeAudio.LOOP_SECONDS) * 2, "ambience loops retain the original loop duration")
	for player: AudioStreamPlayer in score_players:
		_check(player.bus == &"Music", "both score stems route to the Music bus")
		var score_stream := player.stream as AudioStreamWAV
		_check(score_stream.data.size() == int(OfficeAudio.MIX_RATE * OfficeAudio.SCORE_LOOP_SECONDS) * 2, "score stems use a long, non-repetitive loop")
		_check(_stream_silence_ratio(score_stream) < 0.20, "score stems sustain a musical bed instead of disappearing for most of the loop")

	_check(audio._foley_streams.size() == OfficeAudio.FOLEY_KINDS.size(), "every declared physical foley kind has one generated stream")
	for player: AudioStreamPlayer in audio._foley_pool:
		_check(player.bus == &"Foley", "every one-shot pool voice routes to the Foley bus")
	for kind: String in OfficeAudio.FOLEY_KINDS:
		var stream := audio._foley_streams.get(kind) as AudioStreamWAV
		_check(stream != null, "foley '%s' has a stream" % kind)
		if stream != null:
			_check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "foley '%s' is a true one-shot" % kind)
			_check(stream.mix_rate == OfficeAudio.MIX_RATE, "foley '%s' uses the declared mix rate" % kind)
			_check(_stream_has_signal(stream), "foley '%s' contains generated physical signal" % kind)
			_check(_stream_peak(stream) < 0.4, "foley '%s' retains raw headroom" % kind)
		var foley_gain := float(OfficeAudio.FOLEY_VOLUMES_DB.get(kind, 0.0))
		_check(foley_gain >= -12.0 and foley_gain <= -5.0, "foley '%s' is audible while retaining playback headroom" % kind)


func _test_title_opening_and_authored_silence(audio) -> void:
	audio.muted = false
	_check(float(audio._target_rain) > SILENT_DB, "title mix initializes with audible rain")
	_check(float(audio._target_air) > SILENT_DB, "title mix initializes with a restrained room bed")
	_check(float(audio._target_score_human) > SILENT_DB, "title mix initializes with the human theme")
	_check(is_equal_approx(float(audio._target_server_fan), SILENT_DB), "title mix does not leak the office server fan")
	_check(is_equal_approx(float(audio._target_voices), SILENT_DB), "title mix does not leak office voices")
	audio._process(20.0)
	_check(is_equal_approx(float(audio._rain.volume_db), float(audio._target_rain)), "title rain settles at its audible target")
	_check(is_equal_approx(float(audio._score_human.volume_db), float(audio._target_score_human)), "title theme settles at its audible target")

	audio.set_scene_context({"screen": "onboarding", "chapter": 3, "author_weight": 80.0, "team_size": 24})
	_check(float(audio._target_rain) > SILENT_DB and float(audio._target_score_human) > SILENT_DB, "onboarding keeps rain and music independent of late-game company values")
	_check(is_equal_approx(float(audio._target_server_fan), SILENT_DB) and is_equal_approx(float(audio._target_keys_sync), SILENT_DB), "onboarding still excludes office machinery and typing")

	audio.set_scene_context({"screen": "opening", "phase": "arrival", "silence_mode": "normal"})
	_check(float(audio._target_rain) > SILENT_DB and float(audio._target_score_human) > SILENT_DB, "opening arrival carries rain and the human theme")
	_check(is_equal_approx(float(audio._target_server_fan), -18.0), "opening arrival establishes the live server fan")
	audio.set_scene_context({"screen": "opening", "phase": "power", "silence_mode": "normal"})
	_check(is_equal_approx(float(audio._target_server_fan), SILENT_DB), "opening power failure removes the server fan")
	_check(float(audio._target_rain) > SILENT_DB and float(audio._target_score_human) > SILENT_DB, "opening power failure preserves rain and score continuity")
	audio.set_scene_context({"screen": "opening", "phase": "handoff", "silence_mode": "normal"})
	_check(is_equal_approx(float(audio._target_server_fan), -14.0), "opening handoff restores the server fan with a clear payoff")
	_check(float(audio._target_server_fan) > -18.0, "restored opening fan is stronger than its arrival level")

	audio.set_scene_context({"screen": "office", "full_silence": true})
	_check(_all_targets_silent(audio), "explicit full_silence suppresses rain, ambience, and both score stems")
	audio._process(20.0)
	for player: AudioStreamPlayer in audio._continuous_players():
		_check(is_equal_approx(player.volume_db, SILENT_DB), "full_silence settles each continuous player at silence")

	audio.set_scene_context({"screen": "office", "silence_mode": "room_tone_only", "chapter": 2})
	_check(audio._target_air > SILENT_DB, "room_tone_only retains low HVAC")
	_check(audio._target_server_fan > SILENT_DB, "room_tone_only retains low server room tone")
	_check(is_equal_approx(audio._target_voices, SILENT_DB), "room_tone_only removes voices")
	_check(is_equal_approx(audio._target_keys_loose, SILENT_DB), "room_tone_only removes loose typing")
	_check(is_equal_approx(audio._target_keys_sync, SILENT_DB), "room_tone_only removes synchronized typing")
	_check(is_equal_approx(audio._target_score_human, SILENT_DB), "room_tone_only removes human score")
	_check(is_equal_approx(audio._target_score_system, SILENT_DB), "room_tone_only removes system score")
	_check(is_equal_approx(audio._target_rain, SILENT_DB), "room_tone_only removes exterior rain")

	var before_count: int = int(audio._foley_play_count)
	audio.set_scene_context({"screen": "office", "event_id": "phantom_employee", "silence_mode": "normal"})
	_check(audio._foley_play_count == before_count, "changing to an anomaly context never auto-fires a cue")
	_check(not audio.play_foley("anomaly"), "anomaly is not a valid generic foley cue")


func _test_chapter_zero_has_no_distant_voices(audio) -> void:
	audio.muted = false
	audio.set_context(0, 0.0, 2)
	audio._process(20.0)
	_check(is_equal_approx(float(audio._target_voices), SILENT_DB), "chapter zero targets distant voices to silence")
	_check(is_equal_approx(float(audio._voices.volume_db), SILENT_DB), "chapter-zero distant voices settle at silence")
	_check(float(audio._target_air) > SILENT_DB, "chapter zero retains the HVAC bed")
	_check(float(audio._target_server_fan) > SILENT_DB, "chapter zero adds a separate quiet server fan bed")
	_check(float(audio._target_keys_loose) > SILENT_DB, "chapter zero retains loose keyboard ambience")
	_check(float(audio._target_score_human) >= -20.0 and float(audio._target_score_human) <= -6.0, "chapter-zero human score remains clearly audible but below full scale")

	audio.set_context(1, 0.0, 4)
	_check(float(audio._target_voices) > SILENT_DB, "distant voices layer in only after the garage chapter")


func _test_keyboard_crossfade_from_35_to_85(audio) -> void:
	var targets: Array[Array] = []
	var previous_loose := INF
	var previous_sync := -INF
	for weight in range(35, 86, 5):
		audio.set_context(2, float(weight), 9)
		var loose_db := float(audio._target_keys_loose)
		var sync_db := float(audio._target_keys_sync)
		targets.append([loose_db, sync_db])
		_check(loose_db <= previous_loose + EPSILON, "loose keyboard fades monotonically down at author weight %d" % weight)
		_check(sync_db >= previous_sync - EPSILON, "synchronized keyboard fades monotonically up at author weight %d" % weight)
		previous_loose = loose_db
		previous_sync = sync_db

	var at_35: Array = targets.front()
	var at_60: Array = targets[5]
	var at_85: Array = targets.back()
	_check(float(at_35[0]) > float(at_35[1]), "at weight 35 loose keyboard is dominant")
	_check(absf(float(at_60[0]) - float(at_60[1])) <= EPSILON, "at weight 60 keyboard variants meet exactly")
	_check(float(at_85[1]) > float(at_85[0]), "at weight 85 synchronized keyboard is dominant")

	var power_35 := pow(db_to_linear(float(at_35[0])), 2.0) + pow(db_to_linear(float(at_35[1])), 2.0)
	var power_60 := pow(db_to_linear(float(at_60[0])), 2.0) + pow(db_to_linear(float(at_60[1])), 2.0)
	var power_85 := pow(db_to_linear(float(at_85[0])), 2.0) + pow(db_to_linear(float(at_85[1])), 2.0)
	_check(absf(power_35 - power_60) <= EPSILON, "keyboard crossfade preserves equal power through its first half")
	_check(absf(power_60 - power_85) <= EPSILON, "keyboard crossfade preserves equal power through its second half")

	audio.set_context(2, 0.0, 9)
	var before_threshold := [float(audio._target_keys_loose), float(audio._target_keys_sync)]
	audio.set_context(2, 35.0, 9)
	_check(absf(float(audio._target_keys_loose) - float(before_threshold[0])) <= EPSILON, "weights below 35 clamp to the loose endpoint")
	_check(absf(float(audio._target_keys_sync) - float(before_threshold[1])) <= EPSILON, "weights below 35 do not leak extra synchronized typing")
	audio.set_context(2, 100.0, 9)
	var after_threshold := [float(audio._target_keys_loose), float(audio._target_keys_sync)]
	audio.set_context(2, 85.0, 9)
	_check(absf(float(audio._target_keys_loose) - float(after_threshold[0])) <= EPSILON, "weights above 85 clamp the loose endpoint")
	_check(absf(float(audio._target_keys_sync) - float(after_threshold[1])) <= EPSILON, "weights above 85 clamp the synchronized endpoint")


func _test_chapter_four_ambience_and_restrained_score(audio) -> void:
	audio.muted = false
	audio.set_context(4, 100.0, 37)
	_check(is_equal_approx(float(audio._target_air), SILENT_DB), "chapter four mutes HVAC ambience")
	_check(is_equal_approx(float(audio._target_server_fan), SILENT_DB), "chapter four mutes server ambience")
	_check(is_equal_approx(float(audio._target_voices), SILENT_DB), "chapter four mutes distant voices")
	_check(is_equal_approx(float(audio._target_keys_loose), SILENT_DB), "chapter four mutes loose typing")
	_check(float(audio._target_keys_sync) > SILENT_DB, "chapter four leaves synchronized typing audible")
	_check(is_equal_approx(float(audio._target_score_human), SILENT_DB), "chapter four removes the human score")
	_check(float(audio._target_score_system) >= -20.0 and float(audio._target_score_system) <= -8.0, "chapter four system score is present at a restrained audible level")

	audio._process(20.0)
	var audible_ambience := 0
	for player: AudioStreamPlayer in [audio._air, audio._server_fan, audio._voices, audio._keys_loose, audio._keys_sync]:
		if player.volume_db > SILENT_DB:
			audible_ambience += 1
	_check(audible_ambience == 1, "chapter four has exactly one audible ambience player")
	_check(is_equal_approx(audio._keys_sync.volume_db, audio._target_keys_sync), "chapter-four synchronized typing settles at target")
	_check(is_equal_approx(audio._score_system.volume_db, audio._target_score_system), "chapter-four system score settles at its audible target")

	audio.set_scene_context({"screen": "night", "night_id": "night_shift_1", "chapter": 2, "silence_mode": "normal"})
	_check(audio._target_air > SILENT_DB, "night one retains HVAC")
	_check(is_equal_approx(audio._target_server_fan, SILENT_DB), "night one removes server activity")
	_check(is_equal_approx(audio._target_voices, SILENT_DB), "night one removes people")
	_check(is_equal_approx(audio._target_keys_loose, SILENT_DB) and is_equal_approx(audio._target_keys_sync, SILENT_DB), "night one removes typing")
	_check(is_equal_approx(audio._target_score_human, SILENT_DB) and is_equal_approx(audio._target_score_system, SILENT_DB), "night one remains unscored")


func _test_chapter_four_weekly_withdrawal_and_music_duck(audio) -> void:
	var weekly_targets: Array[Array] = []
	for week in range(1, 9):
		audio.set_scene_context({
			"screen": "office", "chapter": 4, "week_in_chapter": week,
			"author_weight": 100.0, "team_size": 37, "silence_mode": "normal",
		})
		weekly_targets.append([
			float(audio._target_air), float(audio._target_server_fan),
			float(audio._target_voices), float(audio._target_keys_sync),
		])
		if week > 1:
			var previous: Array = weekly_targets[week - 2]
			_check(float(audio._target_air) <= float(previous[0]) + EPSILON, "endgame HVAC withdraws monotonically in week %d" % week)
			_check(float(audio._target_server_fan) <= float(previous[1]) + EPSILON, "endgame server tone withdraws monotonically in week %d" % week)
			_check(float(audio._target_voices) <= float(previous[2]) + EPSILON, "endgame voices withdraw monotonically in week %d" % week)
			_check(float(audio._target_keys_sync) >= float(previous[3]) - EPSILON, "endgame synchronized typing emerges monotonically in week %d" % week)
	_check(float(weekly_targets.front()[0]) > SILENT_DB and float(weekly_targets.front()[2]) > SILENT_DB, "endgame week one still carries an inhabited office residue")
	_check(is_equal_approx(float(weekly_targets.back()[0]), SILENT_DB) and is_equal_approx(float(weekly_targets.back()[1]), SILENT_DB) and is_equal_approx(float(weekly_targets.back()[2]), SILENT_DB), "endgame week eight removes every non-keyboard ambience layer")

	audio.set_scene_context({"screen": "office", "chapter": 2, "author_weight": 20.0, "team_size": 9, "silence_mode": "normal"})
	var normal_human := float(audio._target_score_human)
	var normal_system := float(audio._target_score_system)
	audio.set_scene_context({"screen": "office", "chapter": 2, "author_weight": 20.0, "team_size": 9, "silence_mode": "duck_music"})
	_check(is_equal_approx(float(audio._target_score_human), maxf(SILENT_DB, normal_human - 6.0)), "duck_music lowers the human motif by exactly 6 dB")
	_check(is_equal_approx(float(audio._target_score_system), maxf(SILENT_DB, normal_system - 6.0)), "duck_music preserves a silent system motif instead of inventing one")
	_check(float(audio._target_air) > SILENT_DB and float(audio._target_keys_loose) > SILENT_DB, "duck_music leaves the diegetic room intact")


func _test_foley_pool_cooldown_and_mute(audio) -> void:
	audio.muted = false
	audio._foley_last_played_ms.clear()
	var start_count: int = int(audio._foley_play_count)
	_check(audio.play_foley("confirm"), "a known physical cue is accepted")
	_check(audio._foley_play_count == start_count + 1, "accepted foley increments playback count once")
	var first_player: AudioStreamPlayer = audio._foley_pool[0] as AudioStreamPlayer
	_check(first_player.stream is AudioStreamWAV, "foley pool receives the generated one-shot stream")
	if first_player.stream is AudioStreamWAV:
		_check((first_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "played foley never loops")
	_check(not audio.play_foley("confirm"), "same foley kind is rejected inside its cooldown")
	_check(audio._foley_play_count == start_count + 1, "cooldown rejection does not consume another pool voice")

	# Headless SceneTree timers can advance faster than the OS monotonic clock, so
	# move the recorded timestamp beyond the boundary deterministically.
	audio._foley_last_played_ms["confirm"] = Time.get_ticks_msec() - OfficeAudio.FOLEY_COOLDOWN_MS - 1
	_check(audio.play_foley("confirm"), "same foley kind can play after cooldown")
	_check(audio._foley_play_count == start_count + 2, "post-cooldown playback is counted once")

	audio.muted = true
	_check(not audio.play_foley("door"), "global mute rejects new one-shot foley")
	for player: AudioStreamPlayer in audio._foley_pool:
		_check(not player.playing, "global mute immediately stops every active foley pool voice")
	audio._process(20.0)
	for player: AudioStreamPlayer in audio._continuous_players():
		_check(is_equal_approx(player.volume_db, SILENT_DB), "global mute settles continuous stems at silence")
	_check(not audio.toggle_mute(), "toggle_mute remains backward compatible and returns the new state")


func _all_targets_silent(audio) -> bool:
	return (
		is_equal_approx(audio._target_air, SILENT_DB)
		and is_equal_approx(audio._target_rain, SILENT_DB)
		and is_equal_approx(audio._target_server_fan, SILENT_DB)
		and is_equal_approx(audio._target_voices, SILENT_DB)
		and is_equal_approx(audio._target_keys_loose, SILENT_DB)
		and is_equal_approx(audio._target_keys_sync, SILENT_DB)
		and is_equal_approx(audio._target_score_human, SILENT_DB)
		and is_equal_approx(audio._target_score_system, SILENT_DB)
	)


func _stream_has_signal(stream: AudioStreamWAV) -> bool:
	var data: PackedByteArray = stream.data
	if data.size() < 2:
		return false
	var step := maxi(2, int(data.size() / 1024.0))
	step -= step % 2
	for offset in range(0, data.size() - 1, step):
		if data.decode_s16(offset) != 0:
			return true
	return false


func _stream_peak(stream: AudioStreamWAV) -> float:
	var data: PackedByteArray = stream.data
	var peak := 0.0
	var step := maxi(2, int(data.size() / 4096.0))
	step -= step % 2
	for offset in range(0, data.size() - 1, step):
		peak = maxf(peak, absf(float(data.decode_s16(offset)) / 32767.0))
	return peak


func _stream_silence_ratio(stream: AudioStreamWAV) -> float:
	var data: PackedByteArray = stream.data
	var silent_samples := 0
	var sample_count := 0
	var step := maxi(2, int(data.size() / 8192.0))
	step -= step % 2
	for offset in range(0, data.size() - 1, step):
		sample_count += 1
		if abs(data.decode_s16(offset)) <= 1:
			silent_samples += 1
	return float(silent_samples) / maxf(1.0, float(sample_count))


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
