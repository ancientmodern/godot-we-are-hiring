extends SceneTree

const HiringEventScheduler = preload("res://src/hiring_event_scheduler.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_public_api_and_reset_contract()
	_test_seed_order_and_poll_determinism()
	_test_chapter_weight_and_condition_filters()
	_test_id_family_actor_and_occurrence_cooldowns()
	_test_recent_ring_contract()
	_test_recent_ring_save_preserves_history()
	_test_pity_and_blocked_week_contract()
	_test_materialized_snapshot_contract()
	_test_due_priority_aging_and_stable_ties()
	_test_save_resume_determinism()
	_test_invalid_save_rejection()

	if failures.is_empty():
		print("HIRING_EVENT_SCHEDULER_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_EVENT_SCHEDULER_TEST_FAILURE: " + failure)
		quit(1)


func _test_public_api_and_reset_contract() -> void:
	var scheduler = HiringEventScheduler.new(73)
	for method_name in [
		"reset", "plan_week", "enqueue_materialized", "peek_next", "pop_next",
		"pending_events", "pending_count", "has_due_event", "to_save", "load_save", "debug_state"
	]:
		_check(scheduler.has_method(method_name), "scheduler exposes public method %s" % method_name)
	var state: Dictionary = scheduler.debug_state()
	_check(int(state.get("seed", 0)) == 73 and int(state.get("rng_state", 0)) == 73, "constructor applies the fixed scheduler seed")
	_check(int(state.get("pending_count", -1)) == 0 and int(state.get("drought", -1)) == 0, "new scheduler begins with an empty queue and zero drought")
	_check(not bool(scheduler.plan_week(0, 0, []).get("ok", true)), "week zero is rejected")
	_check(not bool(scheduler.enqueue_materialized({}, 1).get("ok", true)), "materialized event requires an id")
	_check(not bool(scheduler.enqueue_materialized({"id": "bad_due"}, 0).get("ok", true)), "materialized event requires a positive due week")

	scheduler.enqueue_materialized({"id": "temporary"}, 1)
	scheduler.reset(73, {
		"recent_limit": 2,
		"actor_cooldown_weeks": 3,
		"aging_per_week": 4,
		"opportunity_permille": 411,
		"pity_start_weeks": 5,
		"pity_step_permille": 77,
	})
	var saved: Dictionary = scheduler.to_save()
	_check(scheduler.pending_count() == 0, "reset clears materialized queue entries")
	_check(int(saved.get("seed", 0)) == 73 and int(saved.get("rng_state", 0)) == 73, "reset restores the exact requested seed and RNG state")
	_check(int(saved.get("recent_limit", -1)) == 2, "reset stores the configured recent ring size")
	_check(int(saved.get("default_actor_cooldown_weeks", -1)) == 3, "reset stores the configured actor cooldown")
	_check(int(saved.get("default_aging_per_week", -1)) == 4, "reset stores the configured queue aging rate")
	_check(int(saved.get("opportunity_permille", -1)) == 411, "reset stores the configured opportunity chance")
	_check(int(saved.get("pity_start_weeks", -1)) == 5 and int(saved.get("pity_step_permille", -1)) == 77, "reset stores both pity controls")

	scheduler.reset(0)
	_check(int(scheduler.debug_state().get("seed", 0)) == HiringEventScheduler.DEFAULT_SEED, "zero seed normalizes to a stable nonzero default")


func _test_seed_order_and_poll_determinism() -> void:
	var first = HiringEventScheduler.new()
	var second = HiringEventScheduler.new()
	var options := {"recent_limit": 0, "opportunity_permille": 1000}
	first.reset(193, options)
	second.reset(193, options)
	var ordered := {
		"zeta": _template("zeta", "market", {"base_weight": 31}),
		"alpha": _template("alpha", "talent", {"base_weight": 17}),
		"middle": _template("middle", "capital", {"base_weight": 29}),
	}
	var reversed: Dictionary = {}
	reversed["middle"] = ordered["middle"]
	reversed["alpha"] = ordered["alpha"]
	reversed["zeta"] = ordered["zeta"]
	var first_plan: Dictionary = first.plan_week(1, 1, ordered)
	var second_plan: Dictionary = second.plan_week(1, 1, reversed)
	_check(str(first_plan.get("status", "")) == "selected" and str(second_plan.get("status", "")) == "selected", "same-seed fixtures both select an event")
	_check(_event_base_id(first_plan) == _event_base_id(second_plan), "template dictionary insertion order cannot change a fixed-seed selection")
	_check(first.to_save() == second.to_save(), "same seed and semantic templates produce identical scheduler state")

	var state_before_repeat: Dictionary = first.debug_state()
	var repeated: Dictionary = first.plan_week(1, 1, ordered)
	_check(str(repeated.get("status", "")) == "already_planned", "planning the same week twice reports an idempotent result")
	_check(first.pending_count() == 1, "planning the same week twice cannot duplicate its event")
	_check(first.debug_state() == state_before_repeat, "planning the same week twice consumes no RNG or scheduler state")

	var rng_before_peek := int(first.debug_state().get("rng_state", 0))
	var peek_one := first.peek_next(1)
	var peek_two := first.peek_next(1)
	_check(not peek_one.is_empty() and peek_one == peek_two, "repeated peek returns the exact same materialized event")
	_check(first.pending_count() == 1, "peek is non-mutating")
	_check(int(first.debug_state().get("rng_state", 0)) == rng_before_peek, "peek consumes no RNG")
	var popped := first.pop_next(1)
	_check(popped == peek_one, "pop returns exactly the event selected by peek")
	_check(first.pending_count() == 0 and first.peek_next(1).is_empty(), "pop removes one event without drawing a replacement")
	_check(int(first.debug_state().get("rng_state", 0)) == rng_before_peek, "pop consumes no RNG")

	first.reset(193, options)
	var after_reset := first.plan_week(1, 1, ordered)
	_check(_event_base_id(after_reset) == _event_base_id(first_plan), "resetting to the same seed reproduces the first selection")


func _test_chapter_weight_and_condition_filters() -> void:
	var scheduler = HiringEventScheduler.new()
	scheduler.reset(29, {"recent_limit": 0, "opportunity_permille": 1000})
	var templates: Dictionary = {
		"wrong_chapter": _template("wrong_chapter", "market", {"chapter_range": [3, 4], "base_weight": 9999}),
		"zero_weight": _template("zero_weight", "market", {"base_weight": 0}),
		"false_flag": _template("false_flag", "market", {"conditions": {"all_flags": ["missing"]}, "base_weight": 9999}),
		"wrong_number": _template("wrong_number", "market", {"conditions": {"gte": {"stats.cash": 99}}, "base_weight": 9999}),
		"eligible": {
			"family": "capital",
			"chapter_range": [1, 2],
			"base_weight": 1,
			"cooldown_weeks": 0,
			"family_cooldown_weeks": 0,
			"max_per_run": -1,
			"conditions": {
				"all_flags": ["market_open"],
				"none_flags": ["embargoed"],
				"equals": {"phase": "seed"},
				"gte": {"stats.cash": 5},
				"lt": {"market.heat": 10},
				"in": {"region": ["bay", "nyc"]},
				"any": [
					{"path": "stats.narrative", "op": ">=", "value": 20},
					{"flag": "warm_intro"},
				],
			},
			"body": ["eligible"],
		},
	}
	var context := {
		"flags": {"market_open": true, "warm_intro": true},
		"phase": "seed",
		"stats": {"cash": 5, "narrative": 3},
		"market": {"heat": 9},
		"region": "bay",
	}
	var result: Dictionary = scheduler.plan_week(1, 1, templates, context)
	_check(str(result.get("status", "")) == "selected", "eligible typed condition template is selected")
	_check(_event_base_id(result) == "eligible", "chapter, weight, flag, numeric, membership, and any filters exclude all invalid templates")
	_check(str(Dictionary(result.get("event", {})).get("id", "")) == "eligible", "dictionary registry key supplies a missing template id before materialization")

	var array_scheduler = HiringEventScheduler.new()
	array_scheduler.reset(29, {"recent_limit": 0, "opportunity_permille": 1000})
	var array_conditions := _template("array_conditions", "policy", {
		"conditions": [
			{"flag": "eligible"},
			{"not_flag": "disqualified"},
			{"path": "stats.headcount", "op": ">", "value": 10},
			{"path": "tags", "op": "contains", "value": "grant_ready"},
		],
	})
	var array_result := array_scheduler.plan_week(1, 3, [array_conditions], {
		"flags": ["eligible"], "stats": {"headcount": 11}, "tags": ["grant_ready"]
	})
	_check(str(array_result.get("status", "")) == "selected", "array condition clauses support flags, negated flags, comparisons, and contains")

	var false_scheduler = HiringEventScheduler.new()
	false_scheduler.reset(29, {"recent_limit": 0, "opportunity_permille": 1000})
	var false_result := false_scheduler.plan_week(1, 3, [array_conditions], {
		"flags": ["eligible", "disqualified"], "stats": {"headcount": 11}, "tags": ["grant_ready"]
	})
	_check(str(false_result.get("status", "")) == "no_candidate", "one failed array condition excludes the complete template")
	_check(int(false_scheduler.debug_state().get("drought", 0)) == 1, "an unblocked week with no eligible template advances pity drought")


func _test_id_family_actor_and_occurrence_cooldowns() -> void:
	var common_options := {"recent_limit": 0, "opportunity_permille": 1000, "actor_cooldown_weeks": 0}

	var id_scheduler = HiringEventScheduler.new()
	id_scheduler.reset(11, common_options)
	var repeatable := _template("repeatable", "id_family", {
		"cooldown_weeks": 2, "family_cooldown_weeks": 0, "max_per_run": -1
	})
	_check(str(id_scheduler.plan_week(1, 1, [repeatable]).get("status", "")) == "selected", "repeatable event selects in its first eligible week")
	_check(str(id_scheduler.plan_week(2, 1, [repeatable]).get("status", "")) == "no_candidate", "id cooldown blocks the first full week after selection")
	_check(str(id_scheduler.plan_week(3, 1, [repeatable]).get("status", "")) == "no_candidate", "id cooldown blocks its second full week")
	_check(str(id_scheduler.plan_week(4, 1, [repeatable]).get("status", "")) == "selected", "id cooldown releases after the configured number of full weeks")
	_check(int(Dictionary(id_scheduler.debug_state().get("occurrence_counts", {})).get("repeatable", 0)) == 2, "repeatable event records both materialized occurrences")

	var family_scheduler = HiringEventScheduler.new()
	family_scheduler.reset(17, common_options)
	var family_a := _template("family_a", "shared", {"family_cooldown_weeks": 2, "max_per_run": -1})
	var family_b := _template("family_b", "shared", {"family_cooldown_weeks": 2, "max_per_run": -1})
	_check(str(family_scheduler.plan_week(1, 1, [family_a, family_b]).get("status", "")) == "selected", "one member of a shared family selects")
	_check(str(family_scheduler.plan_week(2, 1, [family_a, family_b]).get("status", "")) == "no_candidate", "family cooldown blocks every template in that family")
	_check(str(family_scheduler.plan_week(3, 1, [family_a, family_b]).get("status", "")) == "no_candidate", "family cooldown lasts for all configured full weeks")
	_check(str(family_scheduler.plan_week(4, 1, [family_a, family_b]).get("status", "")) == "selected", "shared family becomes eligible after its cooldown")

	var actor_scheduler = HiringEventScheduler.new()
	actor_scheduler.reset(23, common_options)
	var actor_a := _template("actor_a", "actor_family_a", {
		"actor_ids": ["investor_lin"], "actor_cooldown_weeks": 2, "max_per_run": -1
	})
	var actor_b := _template("actor_b", "actor_family_b", {
		"actor_ids": ["investor_lin"], "actor_cooldown_weeks": 2, "max_per_run": -1
	})
	var first_actor := actor_scheduler.plan_week(1, 1, [actor_a, actor_b])
	_check(str(first_actor.get("status", "")) == "selected" and str(Dictionary(first_actor.get("event", {})).get("actor_id", "")) == "investor_lin", "selected actor is frozen into the event snapshot")
	_check(str(actor_scheduler.plan_week(2, 1, [actor_a, actor_b]).get("status", "")) == "no_candidate", "actor cooldown crosses event ids and families")
	_check(str(actor_scheduler.plan_week(3, 1, [actor_a, actor_b]).get("status", "")) == "no_candidate", "actor cooldown blocks its second full week")
	_check(str(actor_scheduler.plan_week(4, 1, [actor_a, actor_b]).get("status", "")) == "selected", "actor becomes eligible after its cooldown")

	var alternate_scheduler = HiringEventScheduler.new()
	alternate_scheduler.reset(31, common_options)
	var actor_prime := _template("actor_prime", "prime", {
		"actor_ids": ["a"], "actor_cooldown_weeks": 3, "max_per_run": 1
	})
	var actor_pool := _template("actor_pool", "pool", {
		"actor_ids": ["a", "b"], "actor_cooldown_weeks": 3, "max_per_run": 1
	})
	_check(_event_base_id(alternate_scheduler.plan_week(1, 1, [actor_prime])) == "actor_prime", "single-actor setup materializes its actor")
	var alternate := alternate_scheduler.plan_week(2, 1, [actor_pool])
	_check(str(alternate.get("status", "")) == "selected" and str(Dictionary(alternate.get("event", {})).get("actor_id", "")) == "b", "multi-actor template filters cooling actors before its actor draw")

	var capped_scheduler = HiringEventScheduler.new()
	capped_scheduler.reset(37, common_options)
	var capped := _template("capped", "cap", {"max_per_run": 1})
	_check(str(capped_scheduler.plan_week(1, 1, [capped]).get("status", "")) == "selected", "max-per-run fixture selects once")
	_check(str(capped_scheduler.plan_week(2, 1, [capped]).get("status", "")) == "no_candidate", "max-per-run prevents a second materialization")


func _test_recent_ring_contract() -> void:
	var scheduler = HiringEventScheduler.new()
	scheduler.reset(41, {"recent_limit": 2, "opportunity_permille": 1000, "actor_cooldown_weeks": 0})
	var first := _template("recent_a", "recent_a_family", {"max_per_run": -1})
	var second := _template("recent_b", "recent_b_family", {"max_per_run": -1})
	var week_one := scheduler.plan_week(1, 1, [first, second])
	var week_two := scheduler.plan_week(2, 1, [first, second])
	_check(str(week_one.get("status", "")) == "selected" and str(week_two.get("status", "")) == "selected", "two-event recent ring produces events in its first two weeks")
	_check(_event_base_id(week_one) != _event_base_id(week_two), "recent ring prevents immediate event-id repetition")
	_check(str(scheduler.plan_week(3, 1, [first, second]).get("status", "")) == "no_candidate", "recent ring can suppress a fully exhausted tiny pool instead of repeating it")
	var recent: Array = Array(scheduler.debug_state().get("recent_ids", []))
	_check(recent.size() == 2 and recent.has("recent_a") and recent.has("recent_b"), "recent ring stores the exact bounded selected-id history")


func _test_recent_ring_save_preserves_history() -> void:
	var scheduler = HiringEventScheduler.new()
	scheduler.reset(42, {"recent_limit": 2, "opportunity_permille": 1000})
	var repeat := _template("ignored_recent", "repeat", {
		"ignore_recent": true,
		"max_per_run": -1,
	})
	_check(str(scheduler.plan_week(1, 1, [repeat]).get("status", "")) == "selected", "ignore-recent fixture selects in week one")
	_check(str(scheduler.plan_week(2, 1, [repeat]).get("status", "")) == "selected", "ignore-recent fixture may repeat in week two")
	var saved := scheduler.to_save()
	var recent: Array = Array(saved.get("recent_ids", []))
	_check(recent == ["ignored_recent", "ignored_recent"], "recent ring remains an ordered history when repeats are explicitly allowed")
	var restored = HiringEventScheduler.new()
	_check(bool(restored.load_save(saved).get("ok", false)), "save with duplicate recent-history entries loads")
	_check(restored.to_save() == saved, "save/load preserves duplicate recent-history entries without deduplication")


func _test_pity_and_blocked_week_contract() -> void:
	var scheduler = HiringEventScheduler.new()
	scheduler.reset(43, {
		"recent_limit": 0,
		"opportunity_permille": 0,
		"pity_start_weeks": 2,
		"pity_step_permille": 1000,
	})
	var event := _template("pity_event", "pity", {"max_per_run": -1})
	var first := scheduler.plan_week(1, 1, [event])
	_check(str(first.get("status", "")) == "no_opportunity" and int(first.get("drought", 0)) == 1, "first zero-opportunity week starts the drought")
	var state_before_block: Dictionary = scheduler.debug_state()
	var blocked := scheduler.plan_week(2, 1, [event], {}, true)
	_check(str(blocked.get("status", "")) == "blocked", "authored story lock explicitly blocks optional planning")
	_check(int(scheduler.debug_state().get("rng_state", 0)) == int(state_before_block.get("rng_state", -1)), "blocked week consumes no RNG")
	_check(int(scheduler.debug_state().get("drought", 0)) == int(state_before_block.get("drought", -1)), "blocked week neither earns nor resets pity")
	var blocked_repeat := scheduler.plan_week(2, 1, [event])
	_check(str(blocked_repeat.get("status", "")) == "already_planned", "a blocked week remains idempotently planned")
	var second := scheduler.plan_week(3, 1, [event])
	_check(str(second.get("status", "")) == "no_opportunity" and int(second.get("drought", 0)) == 2, "second unblocked miss reaches the configured pity threshold")
	var guaranteed := scheduler.plan_week(4, 1, [event])
	_check(str(guaranteed.get("status", "")) == "selected" and int(guaranteed.get("opportunity_permille", 0)) == 1000, "pity guarantees the next eligible opportunity")
	_check(int(scheduler.debug_state().get("drought", -1)) == 0, "successful pity selection resets drought")

	var queued = HiringEventScheduler.new()
	queued.reset(43, {"opportunity_permille": 0})
	queued.enqueue_materialized({"id": "due_during_lock"}, 2, 10, {"track_occurrence": false})
	queued.plan_week(2, 1, [event], {}, true)
	_check(str(queued.peek_next(2).get("id", "")) == "due_during_lock", "blocked optional planning does not hide an already materialized due event")


func _test_materialized_snapshot_contract() -> void:
	var scheduler = HiringEventScheduler.new()
	scheduler.reset(47, {"recent_limit": 0, "opportunity_permille": 1000, "actor_cooldown_weeks": 0})
	var template := _template("term_sheet", "capital", {
		"actor_ids": ["north_partner"],
		"due_in_weeks": 2,
		"priority": 8,
		"aging_per_week": 3,
		"conditions": {"all_flags": ["introduced"]},
		"body": ["{{actor_name}} 发来 {{round_name}}，这是第 {{total_week}} 周。"],
		"choices": [{"id": "read", "label": "查看 {{actor_fund}} 的条款。"}],
	})
	var context := {
		"flags": {"introduced": true},
		"tokens": {"round_name": "Seed term sheet"},
		"actors": {
			"north_partner": {"id": "north_partner", "name": "梁清", "fund": "北岸创投", "trust": 61}
		},
	}
	var planned := scheduler.plan_week(2, 1, [template], context)
	var event: Dictionary = Dictionary(planned.get("event", {}))
	_check(str(planned.get("status", "")) == "selected", "materialization fixture selects")
	_check(str(event.get("actor_id", "")) == "north_partner", "materialized snapshot owns the selected actor id")
	_check(str(Dictionary(event.get("actor_snapshot", {})).get("name", "")) == "梁清", "materialized snapshot owns a deep actor snapshot")
	_check(str(Array(event.get("body", []))[0]).contains("梁清") and str(Array(event.get("body", []))[0]).contains("Seed term sheet") and str(Array(event.get("body", []))[0]).contains("第 2 周"), "actor, context, and week tokens are resolved before queueing")
	_check(str(Dictionary(Array(event.get("choices", []))[0]).get("label", "")).contains("北岸创投"), "nested choice text is token-materialized")
	for planning_key in ["actor_ids", "base_weight", "chapter_range", "conditions", "due_in_weeks", "priority", "aging_per_week"]:
		_check(not event.has(planning_key), "materialized event removes planning field %s" % planning_key)
	_check(int(event.get("_scheduler_due_week", 0)) == 4 and int(event.get("_scheduler_priority", 0)) == 8, "materialized event freezes due week and base priority")
	_check(not str(event.get("_scheduler_instance_id", "")).is_empty(), "materialized event receives a stable instance id")

	# Mutate every caller-owned source after queueing; the queued snapshot must not move.
	template["body"] = ["changed"]
	Dictionary(context["actors"])["north_partner"]["name"] = "已改变"
	context["tokens"]["round_name"] = "changed"
	_check(scheduler.peek_next(3).is_empty(), "future materialized event cannot surface before due week")
	var rng_before_peek := int(scheduler.debug_state().get("rng_state", 0))
	var due_one := scheduler.peek_next(4)
	var due_two := scheduler.peek_next(4)
	_check(str(Array(due_one.get("body", []))[0]).contains("梁清") and not str(Array(due_one.get("body", []))[0]).contains("changed"), "queued copy is isolated from later template, actor, and context mutations")
	_check(due_one == due_two and scheduler.pending_count() == 1, "materialized due snapshot is stable across peeks")
	_check(int(scheduler.debug_state().get("rng_state", 0)) == rng_before_peek, "materialized queue lookup consumes no RNG")
	var popped := scheduler.pop_next(4)
	_check(popped == due_one and scheduler.pending_count() == 0, "materialized event pops exactly once")
	_check(int(scheduler.debug_state().get("rng_state", 0)) == rng_before_peek, "materialized pop consumes no RNG")


func _test_due_priority_aging_and_stable_ties() -> void:
	var scheduler = HiringEventScheduler.new()
	scheduler.reset(53, {"recent_limit": 0})
	var low_source := {"id": "aged_low", "body": ["original"]}
	var low := scheduler.enqueue_materialized(low_source, 1, 2, {
		"aging_per_week": 4, "selected_week": 1, "track_occurrence": false
	})
	low_source["body"] = ["mutated"]
	var high := scheduler.enqueue_materialized({"id": "fresh_high"}, 3, 9, {
		"aging_per_week": 0, "selected_week": 1, "track_occurrence": false
	})
	scheduler.enqueue_materialized({"id": "future"}, 5, 100, {
		"aging_per_week": 0, "selected_week": 1, "track_occurrence": false
	})
	_check(bool(low.get("ok", false)) and bool(high.get("ok", false)), "manual materialized events enter the queue")
	var first := scheduler.peek_next(3)
	_check(str(first.get("id", "")) == "aged_low", "aging can raise an older commitment above a newer base priority")
	_check(int(first.get("_scheduler_effective_priority", 0)) == 10 and int(first.get("_scheduler_age_weeks", 0)) == 2, "peek reports exact effective priority and age")
	_check(str(Array(first.get("body", []))[0]) == "original", "manual enqueue also deep-copies its source")
	_check(not scheduler.pending_events().filter(func(item): return str(Dictionary(item).get("id", "")) == "future").is_empty(), "future queue entry remains stored while not yet due")
	_check(str(scheduler.pop_next(3).get("id", "")) == "aged_low", "pop respects aged priority order")
	_check(str(scheduler.pop_next(3).get("id", "")) == "fresh_high", "next due event follows after aged event is removed")
	_check(scheduler.peek_next(3).is_empty() and scheduler.has_due_event(3) == false, "future event is invisible to due-event queries")
	_check(str(scheduler.peek_next(5).get("id", "")) == "future", "future event becomes visible at its exact due week")

	var ties = HiringEventScheduler.new()
	ties.reset(59)
	var first_tie := ties.enqueue_materialized({"id": "tie_first"}, 2, 7, {"track_occurrence": false})
	var second_tie := ties.enqueue_materialized({"id": "tie_second"}, 2, 7, {"track_occurrence": false})
	_check(int(Dictionary(first_tie.get("event", {})).get("_scheduler_sequence", 0)) < int(Dictionary(second_tie.get("event", {})).get("_scheduler_sequence", 0)), "queue assigns monotonic insertion sequences")
	_check(str(ties.peek_next(2).get("id", "")) == "tie_first", "equal priority and due week resolve by stable insertion order")


func _test_save_resume_determinism() -> void:
	var options := {
		"recent_limit": 1,
		"opportunity_permille": 470,
		"pity_start_weeks": 2,
		"pity_step_permille": 260,
		"actor_cooldown_weeks": 1,
	}
	var templates := [
		_template("save_market", "market", {"max_per_run": -1, "actor_ids": ["rival_a", "rival_b"]}),
		_template("save_talent", "talent", {"max_per_run": -1, "actor_ids": ["candidate_a", "candidate_b"]}),
		_template("save_vendor", "vendor", {"max_per_run": -1}),
	]
	var context := {
		"actors": {
			"rival_a": {"id": "rival_a", "name": "对手甲"},
			"rival_b": {"id": "rival_b", "name": "对手乙"},
			"candidate_a": {"id": "candidate_a", "name": "候选人甲"},
			"candidate_b": {"id": "candidate_b", "name": "候选人乙"},
		},
	}
	var original = HiringEventScheduler.new()
	original.reset(61, options)
	for week in range(1, 6):
		original.plan_week(week, 2, templates, context)
	original.enqueue_materialized({"id": "saved_deadline", "body": ["frozen"]}, 8, 12, {
		"selected_week": 5, "aging_per_week": 2, "track_occurrence": false
	})
	var saved: Dictionary = original.to_save()
	var restored = HiringEventScheduler.new()
	var loaded: Dictionary = restored.load_save(saved)
	_check(bool(loaded.get("ok", false)) and str(loaded.get("status", "")) == "loaded", "scheduler save payload loads")
	_check(restored.to_save() == saved, "scheduler save payload round-trips byte-for-structure")
	_check(restored.pending_events() == original.pending_events(), "all materialized queue snapshots survive save/load")
	_check(restored.peek_next(5) == original.peek_next(5), "same due event is selected after resume")

	for week in range(6, 11):
		var original_result := original.plan_week(week, 2, templates, context, week == 7)
		var restored_result := restored.plan_week(week, 2, templates, context, week == 7)
		_check(_normalized_plan_result(original_result) == _normalized_plan_result(restored_result), "week %d plan result is identical after resume" % week)
		_check(original.to_save() == restored.to_save(), "week %d complete scheduler state remains identical after resume" % week)

	for due_week in [5, 8, 10]:
		while original.has_due_event(due_week) or restored.has_due_event(due_week):
			var original_pop := original.pop_next(due_week)
			var restored_pop := restored.pop_next(due_week)
			_check(original_pop == restored_pop, "due-week %d pop order is identical after resume" % due_week)
		_check(original.to_save() == restored.to_save(), "due-week %d post-pop scheduler state remains identical" % due_week)


func _test_invalid_save_rejection() -> void:
	var scheduler = HiringEventScheduler.new(67)
	var before := scheduler.to_save()
	var wrong_version := before.duplicate(true)
	wrong_version["scheduler_save_version"] = 99
	_check(not bool(scheduler.load_save(wrong_version).get("ok", true)), "unsupported scheduler save version is rejected")
	_check(scheduler.to_save() == before, "rejected version does not mutate live scheduler state")
	var bad_rng := before.duplicate(true)
	bad_rng["rng_state"] = 0
	_check(not bool(scheduler.load_save(bad_rng).get("ok", true)), "zero RNG state is rejected")
	_check(scheduler.to_save() == before, "rejected RNG state does not mutate live scheduler state")
	var bad_queue := before.duplicate(true)
	bad_queue["queue"] = [{"id": "missing_metadata"}]
	_check(not bool(scheduler.load_save(bad_queue).get("ok", true)), "queue entry without stable scheduler metadata is rejected")
	_check(scheduler.to_save() == before, "rejected queue does not mutate live scheduler state")
	var wrong_queue_type := before.duplicate(true)
	wrong_queue_type["queue"] = {"not": "an array"}
	_check(not bool(scheduler.load_save(wrong_queue_type).get("ok", true)), "non-array queue payload is rejected instead of silently loading empty")
	_check(scheduler.to_save() == before, "rejected queue type does not mutate live scheduler state")
	var mixed_queue := before.duplicate(true)
	mixed_queue["queue"] = ["not an event"]
	_check(not bool(scheduler.load_save(mixed_queue).get("ok", true)), "queue payload cannot silently discard non-dictionary entries")
	_check(scheduler.to_save() == before, "rejected mixed queue does not mutate live scheduler state")


func _template(event_id: String, family: String, overrides: Dictionary = {}) -> Dictionary:
	var result := {
		"id": event_id,
		"family": family,
		"chapter_range": [0, 4],
		"base_weight": 100,
		"cooldown_weeks": 0,
		"family_cooldown_weeks": 0,
		"actor_cooldown_weeks": 0,
		"max_per_run": -1,
		"body": [event_id],
		"choices": [],
	}
	for key in overrides:
		result[key] = overrides[key]
	return result


func _event_base_id(plan_result: Dictionary) -> String:
	var event_value = plan_result.get("event", {})
	if not event_value is Dictionary:
		return ""
	return str(Dictionary(event_value).get("_scheduler_base_id", Dictionary(event_value).get("id", "")))


func _normalized_plan_result(result: Dictionary) -> Dictionary:
	var normalized := result.duplicate(true)
	# The full event is already compared through to_save(). Keep this diagnostic
	# compact while retaining the selected identity and all status mechanics.
	if normalized.get("event") is Dictionary:
		normalized["event"] = {
			"id": str(Dictionary(normalized["event"]).get("id", "")),
			"instance": str(Dictionary(normalized["event"]).get("_scheduler_instance_id", "")),
			"actor": str(Dictionary(normalized["event"]).get("actor_id", "")),
		}
	return normalized


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
