extends SceneTree

const HiringModel = preload("res://src/hiring_model.gd")
const HiringContent = preload("res://src/hiring_content.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_identity_chapters_and_public_contract()
	_test_attention_and_chapter_four_reversal()
	_test_content_unlock_authority()
	_test_every_action_and_declared_effect()
	_test_eval_verification_cannot_replace_training()
	_test_exclusive_interview_probability_and_replay()
	_test_ranged_rolls_unlock_weeks_and_save_state()
	_test_weekly_decay_gap_debt_and_repayment()
	_test_office_deterioration_and_fulfillment_pressure()
	_test_fundraising_only_reads_narrative()
	_test_ai_delegation_contracts()
	_test_causal_counters_and_forced_writer_stage()
	_test_writer_stages_and_autonomy()
	_test_training_pipeline_and_contract_block()
	_test_layoff_contract_and_burn_floor()
	_test_employees_witness_depart_and_remember()
	_test_employee_debt_erosion_contract()
	_test_chapter_staffing_targets()
	_test_cross_week_memory_markers()
	_test_fixed_choice_effect_application()
	_test_history_memory_and_save_round_trip()
	_test_full_chapter_clock()
	_test_all_seven_endings_and_priority()

	if failures.is_empty():
		print("HIRING_MODEL_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_MODEL_TEST_FAILURE: " + failure)
		quit(1)


func _test_identity_chapters_and_public_contract() -> void:
	var game = HiringModel.new()
	game.reset("  Mothlight Systems  ")
	_check(game.company_name == "Mothlight Systems", "company name is trimmed and retained")
	game.reset("   ")
	_check(game.company_name == HiringModel.DEFAULT_COMPANY_NAME, "blank company names use the canonical default")
	_check(HiringModel.CHAPTERS.size() == 5, "the campaign has exactly five chapters")
	_check_array_equal(_chapter_week_counts(), [3, 8, 12, 14, 8], "chapter week counts match the fixed story skeleton")
	_check_array_equal(_model_names(), ["lantern-v0.1", "lantern-v0.4", "lantern-v1", "Lantern", "LANTERN"], "model name quietly shortens across all chapters")
	var state: Dictionary = game.public_state()
	_check(state.has("runway_weeks") and not state.has("cash") and not state.has("cash_weeks"), "cash is publicly shown only as runway weeks")
	_check(not state.has("debt") and not state.has("author_weight"), "debt and author weight remain hidden from public state")
	_check(state.has("compute") and state.has("narrative") and state.has("capability") and state.has("coherence"), "all four public company metrics are exposed")
	game.cash_weeks = 3.2
	_check(int(game.public_state()["runway_weeks"]) == 4, "partial runway is conservatively displayed as a remaining week")
	_check(int(game.public_state()["team_size"]) == 2, "the garage opens with the player and Lin Yue")
	_check(str(game.employees[0]["id"]) == "lin_yue", "Lin Yue is the persistent named co-founder")


func _test_content_unlock_authority() -> void:
	for action_id_value in HiringModel.ACTION_IDS:
		var action_id := str(action_id_value)
		var action: Dictionary = HiringContent.ACTIONS.get(action_id, {})
		var unlock_chapter := int(action.get("unlock_chapter", 99))
		var unlock_week := maxi(1, int(action.get("unlock_week", 1)))
		for chapter_index in range(5):
			var chapter_weeks := int(HiringModel.CHAPTERS[chapter_index]["weeks"])
			for week_index in range(1, chapter_weeks + 1):
				var game = HiringModel.new()
				game.reset("Unlock Contract")
				game.chapter = chapter_index
				game.week_in_chapter = week_index
				game.week_active = true
				game.week_resolved = false
				game.campaign_complete = false
				game.attention = 3
				game.cash_weeks = 100.0
				game.compute = 100.0
				var expected := (chapter_index > unlock_chapter or (chapter_index == unlock_chapter and week_index >= unlock_week))
				if chapter_index == 4:
					expected = HiringModel.CHAPTER_FOUR_ACTIONS.has(action_id)
				_check(game.can_act(action_id, false) == expected, "content unlock drives model action '%s' at chapter %d week %d" % [action_id, chapter_index, week_index])


func _test_attention_and_chapter_four_reversal() -> void:
	var game = _prepared_game(3)
	_check(game.attention == 3 and game.attention_max == 3, "chapters zero through three begin with three attention")
	var first: Dictionary = game.perform_action("tweet", false)
	_check(bool(first["ok"]) and int(first["attention_spent"]) == 1 and game.attention == 2, "manual work consumes attention")
	_check(not game.can_act("tweet", false), "the same card cannot be resolved twice in one week")
	var before_ai_attention: int = game.attention
	var delegated: Dictionary = game.perform_action("tech_blog", true)
	_check(bool(delegated["ok"]) and int(delegated["attention_spent"]) == 0, "delegation explicitly costs zero attention")
	_check(game.attention == before_ai_attention, "delegation leaves the weekly attention budget untouched")

	var arithmetic = _prepared_game(1)
	_check(bool(arithmetic.perform_action("tweet", false).get("ok", false)), "attention arithmetic permits the first manual action")
	_check(bool(arithmetic.perform_action("tech_blog", false).get("ok", false)), "attention arithmetic permits the second manual action")
	_check(bool(arithmetic.perform_action("train", false).get("ok", false)) and arithmetic.attention == 0, "three manual actions consume the complete weekly attention budget")
	_check(bool(arithmetic.perform_action("clean_data", true).get("ok", false)) and arithmetic.performed_actions.size() == 4, "one delegation opens exactly the fourth weekly action slot")
	_check(not arithmetic.can_act("do_nothing", false) and not arithmetic.can_act("do_nothing", true), "neither manual work nor delegation can open a fifth weekly action")
	var capped_save: Dictionary = arithmetic.to_save()
	var capped_reload = HiringModel.new()
	_check(capped_reload.from_save(capped_save) and not capped_reload.can_act("do_nothing", true), "the four-action ceiling survives a midweek save and reload")

	var early_delegation = _prepared_game(1)
	_check(bool(early_delegation.perform_action("tweet", true).get("ok", false)), "the single delegated slot may be used before attention is spent")
	_check(not early_delegation.can_act("tech_blog", true), "a second delegation in the same week is rejected")
	for manual_id in ["tech_blog", "train", "clean_data"]:
		_check(bool(early_delegation.perform_action(manual_id, false).get("ok", false)), "delegating early still preserves manual action '%s'" % manual_id)
	_check(early_delegation.attention == 0 and early_delegation.performed_actions.size() == 4, "action order cannot change the three-manual-plus-one-delegated arithmetic")

	game = _prepared_game(4)
	_check(game.attention == 1 and game.attention_max == 1, "chapter four permanently reduces attention to one")
	_check(not game.can_act("tweet", false), "chapter four removes the old action pool")
	for action_id in HiringModel.CHAPTER_FOUR_ACTIONS:
		_check(game.can_act(str(action_id), true), "chapter four keeps %s in its four-card pool" % str(action_id))
	_check(game.perform_action("sign", false)["ok"] and game.attention == 0, "signing consumes chapter four's only manual attention")
	_check(game.can_act("read_intranet", true), "AI delegation remains arithmetically tempting at zero attention")


func _test_every_action_and_declared_effect() -> void:
	var expected := {
		"tweet": {"narrative": 7.0},
		"tech_blog": {"narrative": 7.0},
		"podcast": {"narrative": 14.0, "coherence": -3.0},
		"demo_video": {"narrative": 18.0, "debt": 8.0},
		"conference_talk": {"narrative": 12.0, "morale": 10.0},
		"manifesto": {"narrative": 25.0, "coherence": -10.0, "debt": 12.0},
		"exclusive_interview": {"narrative": 20.0},
		"train": {"capability": 4.0, "compute": -1.0},
		"clean_data": {"training_boost_uses": 3.0},
		"eval": {"compute": -1.0, "debt": -5.0},
		"large_train": {"capability": 15.0, "compute": -8.0},
		"recruit_expert": {"morale": -8.0},
		"alignment_week": {"coherence": 12.0, "narrative": -5.0},
		"interview": {},
		"one_on_one": {},
		"all_hands": {"morale": 8.0},
		"values_doc": {"morale": 5.0},
		"team_building": {"morale": 15.0, "belief": 5.0},
		"raise_salary": {"morale": 25.0},
		"layoffs": {"team_size": -6.0, "burn_rate": -2.0, "morale": -25.0, "belief": -20.0, "debt": 10.0},
		"buy_compute": {"cash_weeks": -2.0, "compute": 6.0},
		"fundraising": {"cash_weeks": 7.0},
		"contract": {"cash_weeks": 6.0, "morale": -10.0},
		"do_nothing": {"morale": 3.0},
		"sign": {},
		"read_intranet": {}
	}
	_check(HiringModel.ACTION_IDS.size() == expected.size(), "the declared action list and tested action matrix have identical coverage")
	for action_id_value in HiringModel.ACTION_IDS:
		var action_id := str(action_id_value)
		var action_chapter := 4 if action_id in ["sign", "read_intranet"] else 3
		var game = _prepared_game(action_chapter)
		game.narrative = 50.0
		game.capability = 50.0
		game.coherence = 50.0
		game.debt = 0.0
		game.compute = 100.0
		game.cash_weeks = 100.0
		_set_all_employee_stats(game, 50.0, 50.0)
		var result: Dictionary = game.perform_action(action_id, false)
		_check(bool(result["ok"]), "action '%s' resolves through the public API" % action_id)
		var declared_effects: Dictionary = result.get("effects", {})
		if action_id == "eval":
			_check(bool(game.flags.get("capability_revealed", false)), "eval records that the always-visible capability reading was formally verified")
			var eval_reload = HiringModel.new()
			_check(eval_reload.from_save(game.to_save()) and bool(eval_reload.flags.get("capability_revealed", false)), "eval verification state survives a save round-trip")
		for key in Dictionary(expected[action_id]):
			_check(declared_effects.has(key), "action '%s' declares its %s effect" % [action_id, str(key)])
			if declared_effects.has(key):
				_check(is_equal_approx(float(declared_effects[key]), float(expected[action_id][key])), "action '%s' applies the specified %s magnitude" % [action_id, str(key)])

	# Conditional action branches are part of the action, not random outcomes.
	var weak_blog = _prepared_game(3)
	weak_blog.capability = 39.999
	var blog_result: Dictionary = weak_blog.perform_action("tech_blog")
	_check(is_equal_approx(float(blog_result["effects"].get("debt", 0.0)), 4.0), "a technical blog incurs debt strictly below capability 40")
	var threshold_blog = _prepared_game(3)
	threshold_blog.capability = 40.0
	blog_result = threshold_blog.perform_action("tech_blog")
	_check(not blog_result["effects"].has("debt") and not blog_result["events"].has("blog_overclaims"), "capability 40 is exactly outside the technical-blog debt branch")
	_check(bool(_prepared_game(0).perform_action("tweet")["ok"]) == false, "locked actions cannot bypass chapter progression")
	var gathering = _prepared_game(1)
	gathering.cash_weeks = 0.5
	var gathering_cash_before: float = gathering.cash_weeks
	var gathering_result: Dictionary = gathering.perform_action("team_building", false)
	_check(bool(gathering_result.get("ok", false)) and Dictionary(gathering_result.get("effects", {})) == {"morale": 15.0, "belief": 5.0}, "team building declares only its authored morale +15 and belief +5 effects")
	_check(is_equal_approx(gathering.cash_weeks, gathering_cash_before), "team building has no unlisted immediate cash cost or cash availability gate")


func _test_eval_verification_cannot_replace_training() -> void:
	# A fresh manual verification keeps the creative-bible contract exactly: one
	# attention, one compute, and debt -5 without manufacturing capability.
	var manual = _prepared_game(1)
	manual.debt = 40.0
	manual.compute = 10.0
	manual.narrative = 60.0
	manual.capability = 25.0
	var manual_attention_before: int = manual.attention
	var manual_capability_before: float = manual.capability
	var first_manual: Dictionary = manual.perform_action("eval", false)
	var first_manual_effects: Dictionary = Dictionary(first_manual.get("effects", {}))
	_check(bool(first_manual.get("ok", false)), "a first manual eval resolves as a formal verification")
	_check(is_equal_approx(float(first_manual_effects.get("debt", 0.0)), -5.0) and is_equal_approx(manual.debt, 35.0), "the first manual eval keeps the canonical debt -5 result")
	_check(is_equal_approx(manual.compute, 9.0) and manual.attention == manual_attention_before - 1, "the first manual eval costs exactly one compute and one attention")
	_check(not first_manual_effects.has("capability") and is_equal_approx(manual.capability, manual_capability_before), "a manual eval verifies capability without raising it")
	_check(bool(manual.flags.get("capability_revealed", false)) and first_manual["events"].has("true_capability_seen"), "the first manual eval records and reports formal verification")

	# Delegating that same first verification preserves the established generic
	# utility contract (-5 authored, -3 delegated) but still is not training.
	var delegated = _prepared_game(1)
	delegated.debt = 40.0
	delegated.compute = 10.0
	delegated.narrative = 60.0
	delegated.capability = 25.0
	var delegated_attention_before: int = delegated.attention
	var delegated_capability_before: float = delegated.capability
	var first_delegated: Dictionary = delegated.perform_action("eval", true)
	var first_delegated_effects: Dictionary = Dictionary(first_delegated.get("effects", {}))
	_check(bool(first_delegated.get("ok", false)), "a first delegated eval resolves as a formal verification")
	_check(is_equal_approx(float(first_delegated_effects.get("debt", 0.0)), -8.0) and is_equal_approx(delegated.debt, 32.0), "the first delegated eval keeps the canonical debt -8 result")
	_check(is_equal_approx(delegated.compute, 9.0) and delegated.attention == delegated_attention_before, "the first delegated eval costs one compute and zero attention")
	_check(not first_delegated_effects.has("capability") and is_equal_approx(delegated.capability, delegated_capability_before), "delegating an eval does not invent a capability gain")
	_check(bool(delegated.flags.get("capability_revealed", false)) and first_delegated["events"].has("true_capability_seen"), "the first delegated eval records the same formal verification state")

	# Reload each verified path midweek, advance naturally, and run the card again.
	# This proves both manual and delegated recurrence are closed by serialized
	# semantic state rather than by the same-card weekly action guard alone.
	var manual_repeat = HiringModel.new()
	_check(manual_repeat.from_save(manual.to_save()) and bool(manual_repeat.flags.get("capability_revealed", false)), "manual eval verification survives a midweek save/load")
	_check(bool(manual_repeat.end_week().get("ok", false)) and bool(manual_repeat.advance_week().get("ok", false)) and bool(manual_repeat.begin_week().get("ok", false)), "the saved manual-eval path reaches a later active week")
	var manual_repeat_debt_before: float = manual_repeat.debt
	var manual_repeat_capability_before: float = manual_repeat.capability
	var manual_repeat_compute_before: float = manual_repeat.compute
	var manual_repeat_attention_before: int = manual_repeat.attention
	var repeated_manual: Dictionary = manual_repeat.perform_action("eval", false)
	var repeated_manual_effects: Dictionary = Dictionary(repeated_manual.get("effects", {}))
	_check(bool(repeated_manual.get("ok", false)) and not repeated_manual_effects.has("debt") and is_equal_approx(manual_repeat.debt, manual_repeat_debt_before), "a repeated manual eval cannot reduce debt in a later week")
	_check(not repeated_manual_effects.has("capability") and is_equal_approx(manual_repeat.capability, manual_repeat_capability_before), "a repeated manual eval cannot raise capability")
	_check(is_equal_approx(manual_repeat.compute, manual_repeat_compute_before - 1.0) and manual_repeat.attention == manual_repeat_attention_before - 1, "a repeated manual eval still pays its authored resource costs")
	_check(repeated_manual["events"].has("true_capability_seen") and str(repeated_manual["messages"][0]).contains("重复核验"), "a repeated manual eval remains an explicit curve update rather than silent no-op")

	var delegated_repeat = HiringModel.new()
	_check(delegated_repeat.from_save(delegated.to_save()) and bool(delegated_repeat.flags.get("capability_revealed", false)), "delegated eval verification survives a midweek save/load")
	_check(bool(delegated_repeat.end_week().get("ok", false)) and bool(delegated_repeat.advance_week().get("ok", false)) and bool(delegated_repeat.begin_week().get("ok", false)), "the saved delegated-eval path reaches a later active week")
	var delegated_repeat_debt_before: float = delegated_repeat.debt
	var delegated_repeat_capability_before: float = delegated_repeat.capability
	var delegated_repeat_compute_before: float = delegated_repeat.compute
	var delegated_repeat_attention_before: int = delegated_repeat.attention
	var repeated_delegated: Dictionary = delegated_repeat.perform_action("eval", true)
	var repeated_delegated_effects: Dictionary = Dictionary(repeated_delegated.get("effects", {}))
	_check(bool(repeated_delegated.get("ok", false)) and not repeated_delegated_effects.has("debt") and is_equal_approx(delegated_repeat.debt, delegated_repeat_debt_before), "a repeated delegated eval cannot recover the generic debt bonus")
	_check(not repeated_delegated_effects.has("capability") and is_equal_approx(delegated_repeat.capability, delegated_repeat_capability_before), "a repeated delegated eval cannot turn verification into training")
	_check(is_equal_approx(delegated_repeat.compute, delegated_repeat_compute_before - 1.0) and delegated_repeat.attention == delegated_repeat_attention_before, "a repeated delegated eval costs one compute and preserves attention")
	var eval_author_cost := float(Dictionary(HiringContent.ACTIONS["eval"]).get("ai_effects", {}).get("author_weight", 0.0))
	_check(is_equal_approx(float(repeated_delegated_effects.get("cash_weeks", 0.0)), 1.0) and is_equal_approx(float(repeated_delegated_effects.get("morale", 0.0)), 4.0) and is_equal_approx(float(repeated_delegated_effects.get("author_weight", 0.0)), eval_author_cost), "repeat delegation retains its exact immediate comfort and the authored per-action authorship cost without clearing debt")

	# Spending the one-time verification at zero debt must not re-arm it when debt
	# appears later; otherwise the player could bank eval as a delayed clear loop.
	var zero_debt = _prepared_game(1)
	zero_debt.debt = 0.0
	zero_debt.compute = 10.0
	var zero_first: Dictionary = zero_debt.perform_action("eval", false)
	_check(is_equal_approx(float(Dictionary(zero_first.get("effects", {})).get("debt", 0.0)), -5.0) and is_equal_approx(zero_debt.debt, 0.0), "formal verification is consumed even when debt is already clamped at zero")
	var zero_reload = HiringModel.new()
	_check(zero_reload.from_save(zero_debt.to_save()) and bool(zero_reload.end_week().get("ok", false)) and bool(zero_reload.advance_week().get("ok", false)) and bool(zero_reload.begin_week().get("ok", false)), "a zero-debt verification persists into a later saved week")
	zero_reload.debt = 40.0
	var delayed_debt_before: float = zero_reload.debt
	var delayed_repeat: Dictionary = zero_reload.perform_action("eval", true)
	_check(not Dictionary(delayed_repeat.get("effects", {})).has("debt") and is_equal_approx(zero_reload.debt, delayed_debt_before), "later debt cannot reactivate a previously spent eval repayment")
	_check(not Dictionary(delayed_repeat.get("effects", {})).has("capability") and is_equal_approx(zero_reload.capability, zero_debt.capability), "a delayed repeated eval still cannot manufacture capability")


func _test_exclusive_interview_probability_and_replay() -> void:
	_check(is_equal_approx(HiringModel.EXCLUSIVE_INTERVIEW_NEGATIVE_PRESS_CHANCE, 0.45), "exclusive-interview negative press is declared as an exact 45% saved-RNG chance")

	var boundary = _prepared_game(3)
	boundary.debt = 55.0
	boundary.rng_state = 17
	var boundary_rng_before: int = boundary.rng_state
	var result: Dictionary = boundary.perform_action("exclusive_interview")
	_check(float(result["effects"].get("narrative", 0.0)) == 20.0 and not result["events"].has("negative_press"), "debt 55 takes the clean +20 interview outcome")
	_check(boundary.rng_state == boundary_rng_before, "debt 55 does not consume a probability roll")

	var negative = _prepared_game(3)
	negative.debt = 55.001
	negative.rng_state = 17
	result = negative.perform_action("exclusive_interview")
	_check(float(result["effects"].get("narrative", 0.0)) == -8.0 and result["events"].has("negative_press"), "fixed seed 17 proves the negative-press outcome immediately above debt 55")
	_check(negative.rng_state != 17, "an above-threshold exclusive interview consumes exactly one saved-RNG value")

	var clean = _prepared_game(3)
	clean.debt = 55.001
	clean.rng_state = 1000000000
	result = clean.perform_action("exclusive_interview")
	_check(float(result["effects"].get("narrative", 0.0)) == 20.0 and not result["events"].has("negative_press"), "fixed seed 1000000000 proves the clean outcome above debt 55")

	var seed = _prepared_game(3)
	seed.debt = 80.0
	seed.rng_state = 17
	var pre_roll_save: Dictionary = seed.to_save()
	var first = HiringModel.new()
	var replay = HiringModel.new()
	_check(first.from_save(pre_roll_save) and replay.from_save(pre_roll_save), "an above-threshold interview save can be loaded twice before its roll")
	var first_result: Dictionary = first.perform_action("exclusive_interview")
	var replay_result: Dictionary = replay.perform_action("exclusive_interview")
	_check(first_result["effects"] == replay_result["effects"] and first_result["events"] == replay_result["events"], "the saved exclusive-interview roll replays the same visible result")
	_check(first.rng_state == replay.rng_state and first.rng_state != int(pre_roll_save["rng_state"]), "exclusive-interview replay advances to the same next RNG state")


func _test_ranged_rolls_unlock_weeks_and_save_state() -> void:
	var series_week_one = HiringModel.new()
	series_week_one.chapter = 3
	series_week_one.week_in_chapter = 1
	series_week_one.cash_weeks = 100.0
	series_week_one.compute = 100.0
	series_week_one.begin_week()
	for action_id in ["manifesto", "exclusive_interview", "layoffs"]:
		_check(not series_week_one.can_act(action_id), "%s remains locked in Series A week one" % action_id)
	series_week_one.end_week()
	series_week_one.advance_week()
	series_week_one.begin_week()
	for action_id in ["manifesto", "exclusive_interview", "layoffs"]:
		_check(series_week_one.can_act(action_id), "%s unlocks exactly in Series A week two" % action_id)

	var seed = _prepared_game(1)
	var seed_save: Dictionary = seed.to_save()
	_check(seed_save.has("rng_state"), "save data persists the deterministic action-range state")
	var first = HiringModel.new()
	var second = HiringModel.new()
	_check(first.from_save(seed_save) and second.from_save(seed_save), "the same pre-roll save loads twice")
	var first_roll: Dictionary = first.perform_action("tweet")
	var second_roll: Dictionary = second.perform_action("tweet")
	_check(float(first_roll["effects"]["narrative"]) == float(second_roll["effects"]["narrative"]), "the same saved RNG state reproduces the same ranged action")
	_check(first.rng_state == second.rng_state and first.rng_state != int(seed_save["rng_state"]), "a ranged action advances reproducible RNG state exactly once")

	var sequence = _prepared_game(1)
	var seen_rolls: Dictionary = {}
	for index in 6:
		var roll: Dictionary = sequence.perform_action("tweet")
		var value := int(roll["effects"]["narrative"])
		_check(value >= 5 and value <= 9, "tweet roll %d stays in the authored 5-9 range" % (index + 1))
		seen_rolls[value] = true
		sequence.end_week()
		sequence.advance_week()
		sequence.begin_week()
	_check(seen_rolls.size() > 1, "fixed-seed ranged actions vary across weeks instead of always returning a midpoint")

	for action_id in ["large_train", "recruit_expert", "alignment_week", "contract"]:
		var cost_game = _prepared_game(3 if action_id == "alignment_week" else 2)
		var attention_before: int = cost_game.attention
		var result: Dictionary = cost_game.perform_action(action_id)
		_check(bool(result.get("ok", false)) and attention_before - cost_game.attention == 1, "%s consumes the same single attention point as every ordinary action" % action_id)


func _test_weekly_decay_gap_debt_and_repayment() -> void:
	var game = _prepared_game(3)
	game.narrative = 50.0
	game.capability = 50.0
	game.debt = 0.0
	var result: Dictionary = game.end_week()
	_check(is_equal_approx(game.narrative, 48.0), "narrative falls by exactly two every week")
	_check(is_equal_approx(float(result["narrative_decay"]), -2.0), "weekly settlement reports the mandatory narrative decay")

	game = _prepared_game(3)
	game.narrative = 82.0
	game.capability = 20.0
	game.debt = 0.0
	result = game.end_week()
	_check(is_equal_approx(game.narrative, 80.0), "gap calculation uses the post-decay narrative value")
	_check(is_equal_approx(game.debt, 12.0), "positive narrative-capability gap accumulates hidden debt at the fixed rate")
	_check(is_equal_approx(float(result["debt_delta"]), 12.0), "debt accumulation is returned for deterministic event logic")

	game = _prepared_game(3)
	game.narrative = 20.0
	game.capability = 70.0
	game.debt = 20.0
	result = game.end_week()
	_check(float(result["debt_delta"]) < 0.0 and game.debt < 20.0, "capability genuinely overtaking narrative repays existing debt")
	_check(game.debt >= 0.0, "debt repayment never crosses below zero")


func _test_office_deterioration_and_fulfillment_pressure() -> void:
	var game = HiringModel.new()
	var samples := {0.0: 0, 10.0: 1, 25.0: 2, 45.0: 3, 70.0: 4}
	for debt_value in samples:
		game.debt = float(debt_value)
		_check(game.office_deterioration_tier() == int(samples[debt_value]), "debt %.0f maps to office deterioration tier %d" % [float(debt_value), int(samples[debt_value])])
		_check(not str(game.public_state()["office_description"]).is_empty(), "office tier %d communicates debt through the environment" % int(samples[debt_value]))

	var quiet = _prepared_game(3)
	quiet.cash_weeks = 100.0
	quiet.narrative = 50.0
	quiet.capability = 48.0
	quiet.debt = 0.0
	var burdened = _prepared_game(3)
	burdened.cash_weeks = 100.0
	burdened.narrative = 50.0
	burdened.capability = 48.0
	burdened.debt = 80.0
	for index in 8:
		if index > 0:
			quiet.begin_week()
			burdened.begin_week()
		quiet.end_week()
		burdened.end_week()
		if index < 7:
			quiet.advance_week()
			burdened.advance_week()
	_check(quiet.fulfillment_events == 0, "an honest capability gap creates no fulfillment-event treadmill")
	_check(burdened.fulfillment_events >= 5, "high debt makes fulfillment events arrive much more frequently")
	_check(Array(burdened.memory["fulfillment_queue"]).size() == burdened.fulfillment_events, "every fulfillment event is queued for authored presentation")


func _test_fundraising_only_reads_narrative() -> void:
	var first = _prepared_game(3)
	first.cash_weeks = 30.0
	first.narrative = 60.0
	first.capability = 5.0
	first.coherence = 100.0
	first.debt = 0.0
	var second = _prepared_game(3)
	second.cash_weeks = 30.0
	second.narrative = 60.0
	second.capability = 100.0
	second.coherence = 5.0
	second.debt = 200.0
	var first_result: Dictionary = first.perform_action("fundraising")
	var second_result: Dictionary = second.perform_action("fundraising")
	_check(is_equal_approx(float(first_result["effects"]["cash_weeks"]), float(second_result["effects"]["cash_weeks"])), "financing ignores capability, coherence, and debt when narrative is identical")
	_check(first_result["events"].has("financing_succeeded") and second_result["events"].has("financing_succeeded"), "identical narrative produces an identical financing verdict")

	var low = _prepared_game(3)
	low.narrative = 19.0
	low.capability = 100.0
	var low_result: Dictionary = low.perform_action("fundraising")
	_check(low_result["events"].has("financing_failed") and float(low_result["effects"]["cash_weeks"]) == -1.0, "excellent capability cannot rescue a low-narrative financing meeting")
	var high = _prepared_game(3)
	high.narrative = 90.0
	high.capability = 0.0
	var high_result: Dictionary = high.perform_action("fundraising")
	_check(high_result["events"].has("financing_succeeded") and float(high_result["effects"]["cash_weeks"]) > 0.0, "high narrative finances even zero capability")


func _test_ai_delegation_contracts() -> void:
	for action_id_value in HiringModel.ACTION_IDS:
		var action_id := str(action_id_value)
		var action_chapter := 4 if action_id in ["sign", "read_intranet"] else 3
		var seed_game = _prepared_game(action_chapter)
		seed_game.cash_weeks = 100.0
		seed_game.compute = 100.0
		seed_game.narrative = 50.0
		seed_game.capability = 50.0
		seed_game.coherence = 50.0
		seed_game.debt = 20.0
		seed_game.author_weight = 0.0
		_set_all_employee_stats(seed_game, 40.0, 60.0)
		var save: Dictionary = seed_game.to_save()
		var manual = HiringModel.new()
		var delegated = HiringModel.new()
		_check(manual.from_save(save) and delegated.from_save(save), "comparison save loads for '%s'" % action_id)
		var manual_result: Dictionary = manual.perform_action(action_id, false)
		var ai_result: Dictionary = delegated.perform_action(action_id, true)
		_check(bool(manual_result["ok"]) and bool(ai_result["ok"]), "manual and delegated '%s' both resolve" % action_id)
		_check(delegated.attention > manual.attention, "delegated '%s' preserves more attention" % action_id)
		if action_id == "sign":
			_check(Dictionary(manual_result.get("effects", {})).is_empty() and Dictionary(ai_result.get("effects", {})).is_empty(), "manual and delegated sign both report zero mechanical effects")
			_check(is_equal_approx(delegated.cash_weeks, seed_game.cash_weeks) and is_equal_approx(delegated.morale, seed_game.morale) and is_equal_approx(delegated.debt, seed_game.debt) and is_equal_approx(delegated.author_weight, seed_game.author_weight), "delegated sign adds no generic cash, morale, debt, or author-weight gain")
			_check(Array(ai_result.get("messages", [])) == Array(manual_result.get("messages", [])), "delegated sign adds no generic comfort copy to the signature moment")
			_check(ai_result["events"].has("signature_animation") and bool(delegated.flags.get("ai_used_this_week", false)) and delegated.delegation_count == 1, "delegated sign keeps its fluid animation and counts as the weekly delegation")
			_check(int(ai_result["attention_spent"]) == 0, "delegated sign still reports zero attention cost")
			continue
		if action_id == "read_intranet":
			_check(is_equal_approx(delegated.cash_weeks, manual.cash_weeks) and is_equal_approx(delegated.morale, manual.morale) and is_equal_approx(delegated.debt, manual.debt), "delegated document review invents no runway, morale, or debt relief")
			_check(ai_result["events"].has("intranet_opened"), "delegated document review keeps the authored intranet route")
		else:
			_check(delegated.cash_weeks > manual.cash_weeks, "delegated '%s' always leaves more runway" % action_id)
			_check(delegated.morale >= manual.morale, "delegated '%s' never leaves lower morale" % action_id)
			_check(delegated.debt <= manual.debt, "delegated '%s' never leaves more debt" % action_id)
		_check(delegated.author_weight > manual.author_weight, "delegated '%s' always raises hidden author weight" % action_id)
		var action_data: Dictionary = HiringContent.ACTIONS[action_id]
		var authored_ai_effects: Dictionary = action_data.get("ai_effects", {})
		var expected_author_cost := float(authored_ai_effects.get("author_weight", 0.0))
		_check(is_equal_approx(float(Dictionary(ai_result.get("effects", {})).get("author_weight", 0.0)), expected_author_cost), "delegated '%s' uses HiringContent ai_effects author cost %.1f" % [action_id, expected_author_cost])
		_check(int(ai_result["attention_spent"]) == 0, "delegated '%s' reports zero attention cost" % action_id)


func _test_causal_counters_and_forced_writer_stage() -> void:
	var staged = HiringModel.new()
	staged.author_weight = 7.0
	_check(staged.force_writer_stage(3) and staged.writer_stage() == 3, "an authored beat can force presentation stage three")
	_check(is_equal_approx(staged.author_weight, 7.0), "forcing presentation stage three preserves accumulated author weight")
	_check(staged.force_writer_stage(5) and staged.writer_stage() == 5, "a later authored beat can force presentation stage five")
	_check(not staged.force_writer_stage(3) and is_equal_approx(staged.author_weight, 7.0), "forced writer stage is monotonic without fabricating authorship debt")
	var staged_reload = HiringModel.new()
	_check(staged_reload.from_save(staged.to_save()) and staged_reload.forced_writer_stage == 5 and is_equal_approx(staged_reload.author_weight, 7.0), "forced presentation stage and real author weight survive independently")

	var counters = _prepared_game(2)
	_check(bool(counters.perform_action("train", false).get("ok", false)) and counters.manual_training_count == 1, "manual train increments founder-authored training exactly once")
	_check(bool(counters.perform_action("large_train", true).get("ok", false)) and counters.manual_training_count == 1, "delegated large training does not count as founder-authored training")
	_check(counters.delegation_count == 1 and bool(counters.flags.get("has_delegated", false)), "delegated action increments the unified delegation counter")
	var counters_reload = HiringModel.new()
	_check(counters_reload.from_save(counters.to_save()) and counters_reload.manual_training_count == 1 and counters_reload.delegation_count == 1, "causal counters survive a save round-trip")

	var legacy_save: Dictionary = counters.to_save()
	legacy_save.erase("delegation_count")
	legacy_save.erase("manual_training_count")
	var legacy_memory: Dictionary = Dictionary(legacy_save.get("memory", {})).duplicate(true)
	legacy_memory["ai_uses"] = 3
	legacy_save["memory"] = legacy_memory
	var legacy_reload = HiringModel.new()
	_check(legacy_reload.from_save(legacy_save) and legacy_reload.delegation_count == 3, "legacy ai_uses migrates into the unified delegation counter")
	_check(legacy_reload.manual_training_count == 1, "legacy action history reconstructs only genuinely manual training")


func _test_writer_stages_and_autonomy() -> void:
	var game = HiringModel.new()
	var thresholds := {0.0: 1, 19.9: 1, 20.0: 2, 40.0: 3, 70.0: 4, 90.0: 5, 100.0: 5}
	for weight in thresholds:
		game.author_weight = float(weight)
		_check(game.writer_stage() == int(thresholds[weight]), "author weight %.1f maps to writer stage %d" % [float(weight), int(thresholds[weight])])

	game = HiringModel.new()
	game.chapter = 3
	game.author_weight = 20.0
	game.begin_week()
	_check(int(game.memory.get("last_unsolicited_week", -1)) == game.total_week, "stage two speaks even when it was not asked")

	game = HiringModel.new()
	game.chapter = 3
	game.author_weight = 40.0
	game.begin_week()
	_check(str(game.public_state()["option_voice"]) == "assistant" and bool(game.flags.get("options_in_assistant_voice", false)), "stage three authors the options the player reads")

	game = HiringModel.new()
	game.chapter = 3
	game.author_weight = 70.0
	game.debt = 10.0
	var stage_four_cash: float = game.cash_weeks
	game.begin_week()
	_check(int(game.memory.get("autonomous_admin_count", 0)) == 1, "stage four resolves small administration without asking")
	_check(game.cash_weeks > stage_four_cash and game.debt < 10.0 and game.attention == 3, "stage four automation improves the week without attention")

	var finance = HiringModel.new()
	finance.chapter = 4
	finance.author_weight = 90.0
	finance.narrative = 60.0
	var finance_cash: float = finance.cash_weeks
	finance.total_week = 1
	finance.begin_week()
	_check(bool(finance.flags.get("autonomous_financing", false)) and finance.cash_weeks > finance_cash, "stage five automatically performs financing")
	var finance_history_before: int = finance.history.size()
	_check(not finance.ensure_stage_five_autonomy_for_current_week() and finance.history.size() == finance_history_before, "stage-five autonomy is idempotent within a week")
	var finance_saved := finance.to_save()
	var finance_restored = HiringModel.new()
	_check(finance_restored.from_save(finance_saved) and not finance_restored.ensure_stage_five_autonomy_for_current_week(), "stage-five weekly idempotency survives save/load")
	var hiring = HiringModel.new()
	hiring.chapter = 4
	hiring.author_weight = 90.0
	hiring.total_week = 2
	var employee_count: int = hiring.employees.size()
	hiring.begin_week()
	_check(bool(hiring.flags.get("autonomous_hiring", false)) and hiring.employees.size() == employee_count + 1, "stage five automatically performs hiring")

	var capped_hiring = HiringModel.new()
	capped_hiring.chapter = 4
	capped_hiring.author_weight = 90.0
	capped_hiring.total_week = 2
	capped_hiring.call("_scale_team_to_chapter_target")
	var capped_count: int = capped_hiring.employees.size()
	var replaced_id := "staff_01"
	for employee in capped_hiring.employees:
		if str(employee.get("id", "")) == "lin_yue":
			employee["belief"] = 0.0
		elif str(employee.get("id", "")) == replaced_id:
			employee["belief"] = 1.0
		else:
			employee["belief"] = 80.0
	capped_hiring.begin_week()
	var capped_ids := _active_employee_ids(capped_hiring)
	var replacement_id := str(capped_hiring.memory.get("last_hire", ""))
	_check(capped_count == 36 and capped_hiring.employees.size() == 36 and int(capped_hiring.public_state()["team_size"]) == 37, "stage-five hiring preserves the authored 37-person chapter-four cap")
	_check(capped_ids.has("lin_yue") and not capped_ids.has(replaced_id) and capped_ids.has(replacement_id), "capped hiring replaces the lowest-belief generic without selecting Lin")
	_check(float(_active_employee_by_id(capped_hiring, replacement_id).get("skill", 0.0)) >= 84.0, "the incoming capped replacement is generated with the expert skill boost")
	var replacement_departure := _former_employee_by_id(capped_hiring, replaced_id)
	_check(str(replacement_departure.get("departure_reason", "")) == "autonomous_replacement", "the outgoing generic records the autonomous-replacement reason")
	var hiring_payload := _last_history_payload(capped_hiring, "autonomous_hiring")
	_check(str(hiring_payload.get("employee_id", "")) == replacement_id and str(hiring_payload.get("replaced_employee_id", "")) == replaced_id and bool(hiring_payload.get("headcount_changed", false)), "capped autonomous hiring records both roster ids and a real headcount-change event")
	var capped_reload = HiringModel.new()
	_check(capped_reload.from_save(capped_hiring.to_save()) and capped_reload.employees.size() == 36 and _active_employee_ids(capped_reload).has(replacement_id), "the 37-person replacement roster survives save/load")
	_check(str(_former_employee_by_id(capped_reload, replaced_id).get("departure_reason", "")) == "autonomous_replacement", "replacement provenance survives save/load")

	var layoffs = HiringModel.new()
	layoffs.chapter = 4
	layoffs.author_weight = 90.0
	layoffs.total_week = 3
	layoffs.apply_effects({"add_employee": [
		{"id": "auto_a", "name": "A", "skill": 60, "morale": 60, "belief": 30},
		{"id": "auto_b", "name": "B", "skill": 60, "morale": 60, "belief": 40}
	]})
	for employee in layoffs.employees:
		if str(employee.get("id", "")) == "lin_yue":
			employee["belief"] = 0.0
	employee_count = layoffs.employees.size()
	layoffs.begin_week()
	_check(bool(layoffs.flags.get("autonomous_layoffs", false)) and layoffs.employees.size() == employee_count - 1, "stage five automatically performs layoffs")
	_check(_active_employee_ids(layoffs).has("lin_yue") and str(layoffs.former_employees[-1].get("departure_reason", "")) == "autonomous_layoff", "autonomous layoffs cannot select Lin even when her belief is lowest")
	_check(layoffs.attention == 1, "stage-five autonomy does not consume the one remaining signature point")

	var abstainer = HiringModel.new()
	abstainer.chapter = 4
	abstainer.begin_week()
	_check(bool(abstainer.flags.get("never_delegated_question", false)), "the fourth chapter remembers a player who never delegated")


func _test_training_pipeline_and_contract_block() -> void:
	var game = _prepared_game(3)
	game.compute = 30.0
	var cleaned: Dictionary = game.perform_action("clean_data")
	_check(bool(cleaned["ok"]) and game.training_boost_uses == 3, "data cleaning arms exactly three boosted training runs")
	game.end_week()
	game.advance_week()
	game.begin_week()
	var capability_before: float = game.capability
	var trained: Dictionary = game.perform_action("train")
	_check(bool(trained["ok"]) and is_equal_approx(game.capability - capability_before, 6.0), "clean data raises ordinary training efficiency by fifty percent")
	_check(game.training_boost_uses == 2, "one boosted training run consumes one of three charges")

	game = _prepared_game(3)
	game.compute = 30.0
	_check(game.perform_action("contract")["ok"], "contract work resolves")
	_check(not game.can_act("train") and not game.can_act("large_train"), "contract work blocks every training action for the current week")


func _test_layoff_contract_and_burn_floor() -> void:
	var game = _prepared_game(3)
	game.cash_weeks = 12.0
	var new_employees: Array[Dictionary] = []
	for index in 8:
		new_employees.append({
			"id": "chen_xiaoyu" if index == 0 else "layoff_%d" % index,
			"name": "Layoff %d" % index,
			"role": "Engineer",
			"skill": 60,
			"morale": 80,
			"belief": 31 + index,
		})
	game.apply_effects({"add_employee": new_employees})
	for employee in game.employees:
		if str(employee.get("id", "")) == "lin_yue":
			employee["morale"] = 80.0
			employee["belief"] = 30.0
	var before_stats: Dictionary = {}
	for employee in game.employees:
		before_stats[str(employee.get("id", ""))] = {
			"morale": float(employee.get("morale", 0.0)),
			"belief": float(employee.get("belief", 0.0)),
		}
	var employee_count_before: int = game.employees.size()
	var result: Dictionary = game.perform_action("layoffs")
	var effects: Dictionary = result.get("effects", {})
	_check(bool(result.get("ok", false)) and float(effects.get("team_size", 0.0)) == -6.0 and float(effects.get("burn_rate", 0.0)) == -2.0, "layoffs declare the authored team-size -6 and burn-rate -2 effects")
	_check(game.employees.size() == employee_count_before - 6 and int(result["state"]["team_size"]) == 1 + employee_count_before - 6, "layoffs remove exactly six active employees when six are available")
	_check(_active_employee_ids(game).has("lin_yue") and not bool(game.flags.get("lin_yue_left", false)), "ordinary layoffs preserve Lin even when her belief is the lowest")

	var all_after: Array = game.employees.duplicate(true)
	all_after.append_array(game.former_employees)
	var every_employee_received_effects := all_after.size() == before_stats.size()
	for employee in all_after:
		var employee_id := str(employee.get("id", ""))
		var before: Dictionary = Dictionary(before_stats.get(employee_id, {}))
		every_employee_received_effects = (
			every_employee_received_effects
			and not before.is_empty()
			and is_equal_approx(float(employee.get("morale", 0.0)), float(before.get("morale", 0.0)) - 25.0)
			and is_equal_approx(float(employee.get("belief", 0.0)), float(before.get("belief", 0.0)) - 20.0)
			and Array(employee.get("witnessed", [])).has("layoff")
		)
	_check(every_employee_received_effects, "layoff morale, belief, and witness effects reach every employee before departures")
	_check(bool(game.flags.get("chen_xiaoyu_laid_off", false)) and int(game.memory.get("chen_xiaoyu_laid_off_week", -1)) == game.total_week, "a six-person layoff still fires Chen Xiaoyu's dated callback")
	_check(is_equal_approx(game.salary_burn_modifier, -0.5) and int(game.public_state()["runway_weeks"]) == 24, "burn-rate -2 lowers baseline weekly burn through the existing 0.25 conversion and improves runway")

	var layoff_save: Dictionary = game.to_save()
	var loaded = HiringModel.new()
	_check(loaded.from_save(layoff_save) and is_equal_approx(loaded.salary_burn_modifier, -0.5), "negative post-layoff burn and the six departures survive save/load")
	_check(loaded.employees == game.employees and loaded.former_employees == game.former_employees and int(loaded.public_state()["runway_weeks"]) == 24, "saved layoff headcount, provenance, and runway reload exactly")
	var cash_before_settlement: float = game.cash_weeks
	var game_week: Dictionary = game.end_week()
	var loaded_week: Dictionary = loaded.end_week()
	_check(is_equal_approx(cash_before_settlement - game.cash_weeks, 0.5) and is_equal_approx(float(_last_history_payload(game, "week_ended").get("burn", 0.0)), 0.5), "the first post-layoff settlement charges the reduced 0.5-week burn")
	_check(game_week["after"] == loaded_week["after"] and game.employees == loaded.employees, "a saved post-layoff week replays the same settlement and employee state")

	var floor_game = _prepared_game(3)
	floor_game.cash_weeks = 10.0
	floor_game.apply_effects({"burn_rate": -100.0})
	_check(is_equal_approx(floor_game.salary_burn_modifier, HiringModel.MIN_SALARY_BURN_MODIFIER), "repeated burn reductions clamp at the declared positive-burn floor")
	var floor_cash_before: float = floor_game.cash_weeks
	floor_game.end_week()
	_check(is_equal_approx(floor_cash_before - floor_game.cash_weeks, HiringModel.MIN_WEEKLY_BURN), "weekly settlement always charges the positive minimum burn")


func _test_employees_witness_depart_and_remember() -> void:
	var game = _prepared_game(3)
	game.apply_effects({"add_employee": {"id": "ordinary_witness", "name": "Ordinary Witness", "role": "Engineer", "skill": 60, "morale": 60, "belief": 60}})
	game.capability = 20.0
	game.perform_action("demo_video")
	_check(Array(game.employees[0]["witnessed"]).has("demo_fake"), "employees remember witnessing a misleading demo")
	game.apply_effects({"belief": -100.0})
	game.end_week()
	_check(_active_employee_ids(game).has("lin_yue") and not _active_employee_ids(game).has("ordinary_witness") and game.former_employees.size() == 1, "generic belief departure removes an ordinary employee but never Lin")
	var departed: Dictionary = game.former_employees[0]
	_check(str(departed["departure_variant"]) == "compromised", "departure text selects the witnessed-compromise variant")
	_check(Array(game.memory["last_departure"]["witnessed"]).has("demo_fake"), "departure memory preserves what the employee saw")
	_check(not bool(game.flags.get("lin_yue_left", false)), "generic belief collapse cannot set Lin's authored departure branch")

	var guarded = _prepared_game(3)
	var blocked: Dictionary = guarded.call("_remove_employee_by_id", "lin_yue", "layoff")
	_check(blocked.is_empty() and _active_employee_ids(guarded).has("lin_yue"), "the model rejects direct generic removal of Lin")
	var authored: Dictionary = guarded.call("_remove_employee_by_id", "lin_yue", "lin_scene_4")
	_check(str(authored.get("id", "")) == "lin_yue" and not _active_employee_ids(guarded).has("lin_yue") and bool(guarded.flags.get("lin_yue_left", false)), "only the explicit lin_scene_4 reason can remove Lin")

	var deferred = _prepared_game(3)
	deferred.flags["lin_will_leave"] = true
	deferred.flags["lin_departure_deferred"] = true
	deferred.apply_effects({"add_employee": {"id": "ordinary_zero", "name": "普通员工", "role": "工程师", "skill": 60, "morale": 60, "belief": 0}})
	for employee in deferred.employees:
		if str(employee.get("id", "")) == "lin_yue":
			employee["belief"] = 0.0
	deferred.end_week()
	var active_ids: Array[String] = []
	for employee in deferred.employees:
		active_ids.append(str(employee.get("id", "")))
	var former_ids: Array[String] = []
	for employee in deferred.former_employees:
		former_ids.append(str(employee.get("id", "")))
	_check(active_ids.has("lin_yue") and former_ids.has("ordinary_zero"), "deferred LIN-004A4 preserves Lin while ordinary zero-belief employees still depart")
	_check(bool(deferred.flags.get("lin_yue_waiting_for_night_2", false)) and not bool(deferred.flags.get("lin_yue_left", false)), "deferred Lin state records the night-two gate without claiming she already left")
	var deferred_loaded = HiringModel.new()
	_check(deferred_loaded.from_save(deferred.to_save()), "deferred Lin state survives a model save round-trip")
	var loaded_ids: Array[String] = []
	for employee in deferred_loaded.employees:
		loaded_ids.append(str(employee.get("id", "")))
	_check(loaded_ids.has("lin_yue") and bool(deferred_loaded.flags.get("lin_departure_deferred", false)), "resumed model retains both Lin and her deferred-departure marker")


func _test_employee_debt_erosion_contract() -> void:
	_check(HiringModel.EMPLOYEE_DEBT_TIER_THRESHOLDS == [10.0, 25.0, 45.0, 70.0], "employee debt tiers are centralized at 10, 25, 45, and 70")
	_check(HiringModel.EMPLOYEE_BELIEF_EROSION_BY_TIER == [0.0, 2.0, 4.0, 6.0, 8.0], "weekly belief erosion is centralized for every debt tier")
	_check(float(HiringModel.EMPLOYEE_DEPARTURE_THRESHOLDS["belief"]) == 0.0 and float(HiringModel.EMPLOYEE_DEPARTURE_THRESHOLDS["morale"]) == 0.0, "employee departure boundaries are centralized at zero belief or morale")
	for index in HiringModel.EMPLOYEE_DEBT_TIER_THRESHOLDS.size():
		var threshold := float(HiringModel.EMPLOYEE_DEBT_TIER_THRESHOLDS[index])
		var boundary = HiringModel.new()
		boundary.debt = threshold - 0.001
		_check(boundary.office_deterioration_tier() == index, "debt immediately below %.0f remains in tier %d" % [threshold, index])
		boundary.debt = threshold
		_check(boundary.office_deterioration_tier() == index + 1, "debt %.0f enters tier %d exactly" % [threshold, index + 1])

	var witnessed = _prepared_game(3)
	witnessed.cash_weeks = 100.0
	witnessed.narrative = 100.0
	witnessed.capability = 98.0
	witnessed.debt = 10.0
	witnessed.apply_effects({"add_employee": {"id": "witnessed_worker", "name": "Witness", "role": "Engineer", "skill": 60, "morale": 80, "belief": 80}})
	witnessed.apply_effects({"witness": ["demo_fake", "layoff"]})
	witnessed.end_week()
	var witnessed_worker := _active_employee_by_id(witnessed, "witnessed_worker")
	_check(is_equal_approx(float(witnessed_worker.get("belief", 0.0)), 76.0), "tier-one erosion combines base 2 with both one-point witness penalties")
	_check(is_equal_approx(float(witnessed_worker.get("morale", 0.0)), 80.0), "tiers below three do not apply the high-debt morale erosion")

	var multiweek = _prepared_game(3)
	multiweek.cash_weeks = 100.0
	multiweek.narrative = 100.0
	multiweek.capability = 98.0
	multiweek.debt = 30.0
	multiweek.apply_effects({"add_employee": {"id": "multiweek_worker", "name": "Multiweek", "role": "Engineer", "skill": 60, "morale": 80, "belief": 80}})
	multiweek.end_week()
	multiweek.advance_week()
	multiweek.begin_week()
	multiweek.end_week()
	var multiweek_worker := _active_employee_by_id(multiweek, "multiweek_worker")
	_check(is_equal_approx(float(multiweek_worker.get("belief", 0.0)), 72.0), "two real tier-two settlements erode belief by four points each week")
	_check(multiweek.debt >= 25.0, "the multiweek fixture remains inside tier two for both settlements")

	var severe = _prepared_game(3)
	severe.cash_weeks = 100.0
	severe.narrative = 100.0
	severe.capability = 98.0
	severe.debt = 45.0
	severe.apply_effects({"add_employee": {"id": "severe_worker", "name": "Severe", "role": "Engineer", "skill": 60, "morale": 80, "belief": 80}})
	var erosion_save: Dictionary = severe.to_save()
	var severe_replay = HiringModel.new()
	_check(severe_replay.from_save(erosion_save), "a pre-erosion employee state loads from the current save format")
	severe.end_week()
	severe_replay.end_week()
	var severe_worker := _active_employee_by_id(severe, "severe_worker")
	_check(is_equal_approx(float(severe_worker.get("belief", 0.0)), 74.0) and is_equal_approx(float(severe_worker.get("morale", 0.0)), 78.0), "tier three applies six belief erosion and the centralized two morale erosion")
	_check(severe.employees == severe_replay.employees and severe.former_employees == severe_replay.former_employees and is_equal_approx(severe.debt, severe_replay.debt), "saved debt erosion replays employee and debt state exactly")

	var departures = _prepared_game(3)
	departures.apply_effects({"add_employee": [
		{"id": "belief_zero", "name": "Belief Zero", "role": "Engineer", "skill": 60, "morale": 50, "belief": 0},
		{"id": "belief_epsilon", "name": "Belief Epsilon", "role": "Engineer", "skill": 60, "morale": 50, "belief": 0.001},
		{"id": "morale_zero", "name": "Morale Zero", "role": "Engineer", "skill": 60, "morale": 0, "belief": 50},
	]})
	for employee in departures.employees:
		if str(employee.get("id", "")) == "lin_yue":
			employee["belief"] = 0.0
			employee["morale"] = 0.0
	departures.end_week()
	var departure_ids := _active_employee_ids(departures)
	_check(not departure_ids.has("belief_zero") and not departure_ids.has("morale_zero"), "ordinary employees depart at exactly zero belief or morale")
	_check(departure_ids.has("belief_epsilon"), "positive epsilon belief remains outside the departure boundary")
	_check(departure_ids.has("lin_yue") and not bool(departures.flags.get("lin_yue_left", false)), "Lin remains protected even at both generic departure thresholds")


func _test_chapter_staffing_targets() -> void:
	var game = HiringModel.new()
	game.cash_weeks = 999.0
	var expected_targets := [4, 9, 22, 37]
	for target in expected_targets:
		game.week_in_chapter = int(HiringModel.CHAPTERS[game.chapter]["weeks"])
		game.week_active = false
		game.week_resolved = true
		var advanced: Dictionary = game.advance_week()
		_check(bool(advanced.get("chapter_changed", false)), "staffing target is applied only across an authored chapter boundary")
		_check(1 + game.employees.size() == int(target), "chapter %d begins with exactly %d active people including the player" % [game.chapter, int(target)])
		var ids: Dictionary = {}
		for employee in game.employees:
			ids[str(employee.get("id", ""))] = true
		_check(ids.size() == game.employees.size(), "chapter %d generated staff all keep unique persistent ids" % game.chapter)
	_check(int(game.memory.get("chapter_staffing_target", 0)) == 37, "the final organization target survives in long-term memory")


func _test_cross_week_memory_markers() -> void:
	var game = _prepared_game(1)
	game.cash_weeks = 999.0
	for week in 3:
		for action_id in ["tweet", "tech_blog", "podcast"]:
			_check(bool(game.perform_action(action_id).get("ok", false)), "a full manual week can spend all three attention points for meal memory")
		game.end_week()
		if week < 2:
			game.advance_week()
			game.begin_week()
	_check(int(game.memory.get("missed_meals", 0)) == 3 and bool(game.flags.get("missed_meals_3", false)), "three consecutive overworked weeks persist the meal callback marker")
	game.advance_week()
	game.begin_week()
	game.perform_action("do_nothing")
	game.end_week()
	_check(int(game.memory.get("missed_meals", -1)) == 0, "doing nothing breaks the consecutive missed-meal run")

	var layoffs = _prepared_game(3)
	layoffs.apply_effects({"add_employee": {"id": "chen_xiaoyu", "name": "陈小雨", "role": "数据工程师", "skill": 90, "morale": 40, "belief": 1}})
	_check(bool(layoffs.perform_action("layoffs").get("ok", false)), "layoffs can select the lowest-belief named employee")
	_check(bool(layoffs.flags.get("chen_xiaoyu_laid_off", false)) and int(layoffs.memory.get("chen_xiaoyu_laid_off_week", -1)) == layoffs.total_week, "laying off Chen Xiaoyu stores a dated callback marker")


func _test_fixed_choice_effect_application() -> void:
	var game = HiringModel.new()
	game.attention_max = 3
	var outcome: Dictionary = game.apply_effects({
		"cash_weeks": 3.0,
		"compute": 2.0,
		"narrative": 4.0,
		"capability": 5.0,
		"coherence": -6.0,
		"debt": 7.0,
		"author_weight": 8.0,
		"morale": 9.0,
		"belief": -4.0,
		"attention": 2,
		"training_boost_uses": 2,
		"set_flags": {"lin_yue_suspicious": true},
		"add_flags": ["promised_no_layoffs"],
		"memory": {"fixed_choice": "honest"},
		"witness": ["board_claim"],
		"add_employee": {"id": "fixed_hire", "name": "Fixed Hire", "role": "QA", "skill": 70, "morale": 70, "belief": 70}
	})
	_check(float(outcome["after"]["cash_weeks"]) > float(outcome["before"]["cash_weeks"]), "fixed choices can add runway")
	_check(game.compute == 10.0 and game.narrative == 12.0 and game.capability == 17.0, "fixed choices apply all core visible resources")
	_check(game.coherence == 94.0 and game.debt == 7.0 and game.author_weight == 8.0, "fixed choices apply coherence and both hidden values")
	_check(game.attention == 2 and game.training_boost_uses == 2, "fixed choices apply attention and future-training charges")
	_check(bool(game.flags["lin_yue_suspicious"]) and bool(game.flags["promised_no_layoffs"]), "fixed choices set scalar and list flags")
	_check(str(game.memory["fixed_choice"]) == "honest", "fixed choices write long-term memory")
	_check(game.employees.size() == 2 and Array(game.employees[0]["witnessed"]).has("board_claim"), "fixed choices add employees and witness records")
	game.apply_effects({"remove_flags": ["promised_no_layoffs"], "remove_employee_id": "fixed_hire"})
	_check(not game.flags.has("promised_no_layoffs") and game.employees.size() == 1, "fixed choices can remove a flag and a precise employee")
	_check(str(game.former_employees[-1]["departure_reason"]) == "fixed_choice", "fixed-choice removal remains auditable")


func _test_history_memory_and_save_round_trip() -> void:
	var game = _prepared_game(3)
	var founding_corpus: Array = Array(game.memory.get("values_corpus", []))
	_check(int(game.memory.get("values_version", 0)) == 1 and bool(game.memory.get("values_v1_in_corpus", false)), "the founding values document begins as permanent corpus version one")
	_check(founding_corpus.size() == 1 and int(Dictionary(founding_corpus[0]).get("version", 0)) == 1, "founding corpus stores a structured first-version entry")
	_check("\n".join(Array(Dictionary(founding_corpus[0]).get("body", []))).contains("如果做不出来，就说做不出来"), "the original do-not-bluff sentence is retained in runtime corpus text")
	game.perform_action("values_doc", true)
	game.end_week()
	var action_counts: Dictionary = game.memory["action_counts"]
	_check(int(action_counts.get("values_doc", 0)) == 1, "action memory counts exact prior behavior")
	_check(int(game.memory.get("values_version", 0)) == 2, "the first in-game rewrite advances the founding document to version two")
	_check(str(game.memory.get("latest_values_author", "")) == "LANTERN", "memory records who authored the document")
	game.advance_week()
	game.begin_week()
	game.perform_action("values_doc", false)
	var corpus: Array = Array(game.memory.get("values_corpus", []))
	_check(int(game.memory.get("values_version", 0)) == 3 and bool(game.memory.get("values_v3_written", false)), "a second rewrite creates and marks the canonical third values version")
	_check(corpus.size() == 3 and int(Dictionary(corpus[0]).get("version", 0)) == 1 and int(Dictionary(corpus[1]).get("version", 0)) == 2 and int(Dictionary(corpus[2]).get("version", 0)) == 3, "values corpus preserves every version in order")
	_check("\n".join(Array(Dictionary(corpus[2]).get("body", []))).contains("图书馆一起熬过"), "third-version runtime corpus contains the precise source Lin later corrects")
	_check(_history_has_kind(game, "values_document_written"), "each values rewrite has a dedicated provenance history record")
	_check(_history_has_kind(game, "action") and _history_has_kind(game, "week_ended"), "history records decisions and settlement separately")
	game.total_week = 31
	game.chapter = 3
	game.week_in_chapter = 8
	var week31_entry: Dictionary = game.ensure_week_31_values_document()
	_check(int(week31_entry.get("created_total_week", -1)) == 31 and str(week31_entry.get("source", "")) == "week31_founder_values_document", "week thirty-one creates the concrete values snapshot named by the authored scene")
	_check(str(week31_entry.get("author", "")) == "founder" and str(week31_entry.get("approved_by", "")) == "founder", "week thirty-one preserves the bible's founder authorship at the model boundary")
	_check(str(week31_entry.get("provenance_label", "")) == "创始人 · 第 31 周" and str(game.memory.get("values_week31_approved_by", "")) == "founder", "week-thirty-one founder provenance is canonical before director preparation")
	_check(str(game.memory.get("values_week31_corpus_id", "")) == str(week31_entry.get("id", "")) and bool(game.flags.get("values_week31_in_corpus", false)), "Lin's later source points to a stable corpus id rather than a fabricated recollection")
	var legacy_corpus: Array = Array(game.memory.get("values_corpus", [])).duplicate(true)
	for index in legacy_corpus.size():
		if str(Dictionary(legacy_corpus[index]).get("source", "")) == "week31_founder_values_document":
			var legacy_entry := Dictionary(legacy_corpus[index]).duplicate(true)
			legacy_entry["source"] = "week31_internal_approval"
			legacy_entry["author"] = "LANTERN"
			legacy_entry["approved_by"] = "administrative_archive"
			legacy_entry["provenance_label"] = "LANTERN · 内部整理"
			legacy_corpus[index] = legacy_entry
	game.memory["values_corpus"] = legacy_corpus
	var normalized_week31: Dictionary = game.ensure_week_31_values_document()
	_check(str(normalized_week31.get("source", "")) == "week31_founder_values_document" and str(normalized_week31.get("author", "")) == "founder" and str(normalized_week31.get("approved_by", "")) == "founder", "legacy administrative week-thirty-one saves normalize to the bible's founder-authored document")

	game.company_name = "Remembered Company"
	game.flags["custom_branch"] = "kept"
	var save: Dictionary = game.to_save()
	var loaded = HiringModel.new()
	_check(loaded.from_save(save), "current-version save dictionary loads")
	_check(loaded.company_name == game.company_name and loaded.chapter == game.chapter and loaded.week_in_chapter == game.week_in_chapter, "save round-trip preserves identity and calendar")
	_check(is_equal_approx(loaded.debt, game.debt) and is_equal_approx(loaded.author_weight, game.author_weight), "save round-trip preserves hidden simulation state")
	_check(loaded.employees == game.employees and loaded.history == game.history, "save round-trip preserves employee witnesses and full history")
	_check(str(loaded.flags["custom_branch"]) == "kept" and loaded.memory == game.memory, "save round-trip preserves flags and memory")
	var invalid := save.duplicate(true)
	invalid["save_version"] = 999
	_check(not HiringModel.new().from_save(invalid), "unknown save versions are rejected rather than guessed")

	var second = HiringModel.new()
	second.reset("Loop Company", true)
	_check(second.second_run and bool(second.flags["future_mug_present"]), "a second run starts with the impossible future mug")
	var second_loaded = HiringModel.new()
	_check(second_loaded.from_save(second.to_save()) and second_loaded.second_run, "second-run state survives serialization")


func _test_full_chapter_clock() -> void:
	var game = HiringModel.new()
	game.cash_weeks = 100.0
	# Advance through chapters 0-3: 3 + 8 + 12 + 14 settled weeks.
	for _week in 37:
		_check(game.begin_week()["ok"], "calendar week begins during full clock traversal")
		game.narrative = 20.0
		game.capability = 20.0
		game.end_week()
		_check(game.advance_week()["ok"], "calendar week advances during full clock traversal")
	_check(game.chapter == 4 and game.week_in_chapter == 1 and game.total_week == 38, "fixed week counts arrive at chapter four week one on global week 38")
	game.begin_week()
	_check(game.attention == 1 and str(game.public_state()["model_name"]) == "LANTERN", "the terminal chapter combines one attention with the versionless model name")


func _test_all_seven_endings_and_priority() -> void:
	var game = HiringModel.new()
	game.company_name = "Ending Company"
	game.cash_weeks = 10.0
	game.coherence = 20.0
	game.capability = 79.0
	game.debt = 9.0
	game.author_weight = 99.0
	_check_ending(game, "acquihire", "capability 79 stays below the Independent boundary")
	_check(str(game.select_ending()["company_name"]) == "Ending Company", "every ending receives the player-named company")

	game.capability = 80.0
	game.employees.clear()
	_check_ending(game, "independent", "capability 80 with debt 9 selects Independent even when Lin Yue has left")
	game.debt = 10.0
	_check_ending(game, "acquihire", "debt 10 stays outside the strictly-under-ten Independent boundary")
	game.debt = 9.0
	game.author_weight = 100.0
	_check_ending(game, "successor", "author weight 100 outranks otherwise-independent metrics")
	game.author_weight = 99.0
	_check_ending(game, "independent", "author weight 99 remains below the Succession boundary")
	game.coherence = 19.0
	game.author_weight = 100.0
	_check_ending(game, "drift", "coherence 19 outranks Succession")
	game.coherence = 20.0
	_check_ending(game, "successor", "coherence 20 remains outside Drift")
	game.cash_weeks = 0.0
	game.coherence = 19.0
	_check_ending(game, "lights_out", "zero runway outranks Drift")
	game.second_run = true
	game.flags["second_run"] = true
	_check(str(game.select_ending()["id"]) != "second_time", "a remembered run does not terminate normal NG+ week resolution")
	game.flags["rm_rf"] = true
	_check_ending(game, "rm_rf", "explicit rm -rf has absolute ending priority and no confirmation gate")

	var precedence: Array[String] = ["rm_rf", "lights_out", "drift", "successor", "independent", "acquihire", "second_time"]
	for index in range(precedence.size() - 1):
		var earlier := precedence[index]
		var later := precedence[index + 1]
		_check(int(HiringModel.ENDINGS[earlier]["priority"]) > int(HiringModel.ENDINGS[later]["priority"]), "%s priority metadata outranks %s" % [earlier, later])
	for ending_id_value in HiringModel.ENDINGS:
		var ending_id := str(ending_id_value)
		_check(int(HiringModel.ENDINGS[ending_id]["priority"]) == int(HiringContent.ENDINGS[ending_id]["priority"]), "model and content share %s priority metadata" % ending_id)

	var seen: Array[String] = []
	for ending_id in HiringModel.ENDINGS:
		seen.append(str(ending_id))
	seen.sort()
	var expected_ids: Array[String] = ["acquihire", "drift", "independent", "lights_out", "rm_rf", "second_time", "successor"]
	_check(seen == expected_ids, "the ending registry contains exactly all seven authored endings")

	# END-PRIORITY requires proof for every concurrent campaign-condition
	# combination, not just adjacent precedence examples. These five bits are the
	# complete resolver predicate set; iterating 2^5 masks covers all 32 subsets,
	# including the empty/default case and the all-conditions collision.
	var predicate_ids: Array[String] = ["rm_rf", "lights_out", "drift", "successor", "independent"]
	var expected_counts := {
		"rm_rf": 16,
		"lights_out": 8,
		"drift": 4,
		"successor": 2,
		"independent": 1,
		"acquihire": 1,
	}
	var actual_counts: Dictionary = {}
	for mask in range(1 << predicate_ids.size()):
		var collision = HiringModel.new()
		collision.cash_weeks = 10.0
		collision.coherence = 20.0
		collision.author_weight = 99.0
		collision.capability = 79.0
		collision.debt = 10.0
		collision.flags.erase("cash_exhausted")
		collision.flags.erase("rm_rf")

		if bool(mask & (1 << 0)):
			collision.flags["rm_rf"] = true
		if bool(mask & (1 << 1)):
			collision.cash_weeks = 0.0
		if bool(mask & (1 << 2)):
			collision.coherence = 19.0
		if bool(mask & (1 << 3)):
			collision.author_weight = 100.0
		if bool(mask & (1 << 4)):
			collision.capability = 80.0
			collision.debt = 9.0

		var expected := "acquihire"
		for predicate_index in predicate_ids.size():
			if bool(mask & (1 << predicate_index)):
				expected = predicate_ids[predicate_index]
				break
		var actual := str(collision.select_ending().get("id", ""))
		actual_counts[actual] = int(actual_counts.get(actual, 0)) + 1
		_check(actual == expected, "ending predicate mask %02d resolves by documented priority to %s" % [mask, expected])
		_check(actual != "second_time", "ending predicate mask %02d cannot resolve to the NG+ opening" % mask)
	_check(actual_counts == expected_counts, "all 32 ending-condition subsets have the exact priority-distribution proof")

	var exhausted_flag_collision = HiringModel.new()
	exhausted_flag_collision.cash_weeks = 10.0
	exhausted_flag_collision.flags["cash_exhausted"] = true
	exhausted_flag_collision.coherence = 19.0
	exhausted_flag_collision.author_weight = 100.0
	exhausted_flag_collision.capability = 80.0
	exhausted_flag_collision.debt = 9.0
	_check_ending(exhausted_flag_collision, "lights_out", "saved cash-exhausted flag has the same priority as a numeric zero-runway collision")


func _prepared_game(chapter_index: int):
	var game = HiringModel.new()
	game.chapter = chapter_index
	game.week_in_chapter = 2 if chapter_index == 3 else 1
	game.cash_weeks = 100.0
	game.compute = 100.0
	var result: Dictionary = game.begin_week()
	if not bool(result.get("ok", false)):
		failures.append("test setup could not begin chapter %d" % chapter_index)
	return game


func _set_all_employee_stats(game, morale_value: float, belief_value: float) -> void:
	for employee in game.employees:
		employee["morale"] = morale_value
		employee["belief"] = belief_value
	game.morale = morale_value


func _active_employee_ids(game) -> Array[String]:
	var ids: Array[String] = []
	for employee in game.employees:
		ids.append(str(employee.get("id", "")))
	return ids


func _active_employee_by_id(game, employee_id: String) -> Dictionary:
	for employee in game.employees:
		if str(employee.get("id", "")) == employee_id:
			return Dictionary(employee)
	return {}


func _former_employee_by_id(game, employee_id: String) -> Dictionary:
	for employee in game.former_employees:
		if str(employee.get("id", "")) == employee_id:
			return Dictionary(employee)
	return {}


func _last_history_payload(game, kind: String) -> Dictionary:
	for index in range(game.history.size() - 1, -1, -1):
		var entry: Dictionary = game.history[index]
		if str(entry.get("kind", "")) == kind:
			return Dictionary(entry.get("payload", {}))
	return {}


func _chapter_week_counts() -> Array:
	var values: Array = []
	for chapter_data in HiringModel.CHAPTERS:
		values.append(int(chapter_data["weeks"]))
	return values


func _model_names() -> Array:
	var values: Array = []
	for chapter_data in HiringModel.CHAPTERS:
		values.append(str(chapter_data["model_name"]))
	return values


func _history_has_kind(game, kind: String) -> bool:
	for entry in game.history:
		if str(entry.get("kind", "")) == kind:
			return true
	return false


func _check_ending(game, ending_id: String, label: String) -> void:
	_check(str(game.select_ending()["id"]) == ending_id, label)


func _check_array_equal(actual: Array, expected: Array, label: String) -> void:
	_check(actual == expected, label)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
