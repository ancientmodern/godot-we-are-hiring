extends SceneTree

const CampaignDirector = preload("res://src/hiring_director.gd")
const HiringContent = preload("res://src/hiring_content.gd")
const HiringModel = preload("res://src/hiring_model.gd")
const HiringMain = preload("res://src/hiring_main.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_public_api_and_after_coverage()
	_test_fixed_priority_silent_recording_and_special_effects()
	_test_chapter_two_quiet_and_conditional_beats()
	_test_model_first_sentence_closes_action_phase()
	_test_lin_absent_echo_choices()
	_test_lin_values_corpus_provenance()
	_test_never_used_demo_video_route()
	_test_used_demo_video_route()
	_test_preseed_close_fundraise_mechanics()
	_test_live_demo_postpone_return_schedule()
	_test_all_hands_decision_and_promise_callback()
	_test_layoff_promise_copy_routes()
	_test_cash_crisis_contract_and_layoff_routes()
	_test_lin_scene_four_deferred_departure()
	_test_lin_training_gate_and_last_visit_priority()
	_test_hiring_candidate_identity_and_single_hire()
	_test_hiring_delegate_selects_visible_best_candidate()
	_test_chen_xiaoyu_runtime_copy_and_clean_resignation()
	_test_witnessed_resignation_and_one_on_one_tie_break()
	_test_one_on_one_fact_rotation_and_solve_scope()
	_test_multi_departure_snapshots_and_autonomous_skip()
	_test_chen_xiaoyu_three_week_callback()
	_test_missed_meal_callback_is_a_friday_memory()
	_test_final_silence_defers_modal_queue()
	_test_stage_five_starts_in_chapter_four_week_one()
	_test_chapter_four_eight_week_autonomy_trace()
	_test_night_shift_requires_inspection()
	_test_complete_campaign("builder")
	_test_complete_campaign("delegator")
	_test_visible_pool_complete_campaign("founder")
	_test_visible_pool_complete_campaign("delegated")
	_test_ng_plus_is_an_opening_not_an_ending()
	_test_all_endings_are_routable_and_gated()
	_test_save_round_trip()

	if failures.is_empty():
		print("HIRING_FLOW_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_FLOW_TEST_FAILURE: " + failure)
		quit(1)


func _test_public_api_and_after_coverage() -> void:
	var director = CampaignDirector.new()
	var methods := [
		"start_company", "resume", "perform_action", "current_fixed_event",
		"next_event", "prepare_event", "resolve_event",
		"apply_declarative_after", "finish_week", "advance",
		"pending_night_shift", "complete_night_shift",
		"generic_debt_fulfillment", "resolve_ending", "ending_for_id",
		"save_payload"
	]
	for method_name in methods:
		_check(director.has_method(method_name), "director documents and exposes %s" % method_name)

	var directives: Dictionary = {}
	for event_value in HiringContent.FIXED_EVENTS.values():
		var event: Dictionary = event_value
		directives[str(event.get("after", ""))] = true
	for event_value in HiringContent.GENERIC_EVENTS.values():
		var event: Dictionary = event_value
		directives[str(event.get("after", ""))] = true
	var unsupported: Array[String] = []
	for directive_value in directives:
		var directive := str(directive_value)
		if not director.supports_after_directive(directive):
			unsupported.append(directive)
	_check(unsupported.is_empty(), "all %d distinct authored after directives are interpreted (%s)" % [directives.size(), ", ".join(unsupported)])
	_check(HiringContent.FIXED_EVENTS.size() == 45, "content has one fixed beat for each of the 45 authored weeks")


func _test_fixed_priority_silent_recording_and_special_effects() -> void:
	var director = CampaignDirector.new()
	var started: Dictionary = director.start_company("Priority Systems", false)
	_check(bool(started.get("ok", false)), "campaign starts through the director")
	director.model.debt = 80.0
	var first: Dictionary = director.next_event()
	_check(str(first.get("id", "")) == "garage_opening", "fixed beat outranks an eligible debt fulfillment")
	_check(str(first.get("_director_source", "")) == "fixed", "fixed source metadata survives preparation")
	_check(director.resolve_event("garage_opening").get("ok", false), "choice-free fixed beat resolves")
	_check(director.current_fixed_event().is_empty(), "the same fixed beat cannot resolve twice")
	_check(director.resolve_ending().is_empty(), "ordinary acquisition is gated in week one")

	# Exercise all non-additive effect forms required by the authored live demo and
	# layoff content without reaching into the model implementation.
	director.model.capability = 44.0
	director.model.narrative = 90.0
	director.model.cash_weeks = 20.0
	director.model.apply_effects({"add_employee": [
		{"id": "test_a", "name": "A", "skill": 50, "morale": 60, "belief": 60},
		{"id": "test_b", "name": "B", "skill": 50, "morale": 60, "belief": 60}
	]})
	var before_team: int = director.model.employees.size()
	var before_burn: float = float(director.model.salary_burn_modifier)
	director.apply_event_effects("live_demo", {
		"narrative_set_to_capability": 1,
		"cash_percent": -15,
		"team_size": -1,
		"burn_rate": 2
	})
	_check(is_equal_approx(director.model.narrative, director.model.capability), "narrative_set_to_capability is interpreted")
	_check(is_equal_approx(director.model.cash_weeks, 17.0), "cash_percent applies to current runway")
	_check(director.model.employees.size() == before_team - 1, "team_size delta removes exactly the authored count")
	_check(director.model.salary_burn_modifier > before_burn, "burn_rate changes the model's weekly burn modifier")
	director.model.salary_burn_modifier = 0.0
	director.apply_event_effects("layoff_burn_probe", {"burn_rate": -2})
	_check(is_equal_approx(director.model.salary_burn_modifier, -0.5), "negative fixed-event burn rate uses the model's canonical floor instead of being clamped away")
	var before_cash: float = float(director.model.cash_weeks)
	director.apply_event_effects("fundraise_probe", {"fundraise_by_narrative": true})
	_check(director.model.cash_weeks > before_cash, "fundraise_by_narrative reads story value and adds runway")

	# Move deterministically to the first silent fixed week and verify that it is
	# recorded without ever being returned as a modal.
	director.model.cash_weeks = 200.0
	_advance_one_week_for_unit_test(director)
	_check(director.current_fixed_event().is_empty(), "week two closing beat is hidden during the action phase")
	_advance_one_week_for_unit_test(director)
	var week_three := director.next_event()
	director.resolve_event(week_three)
	_advance_one_week_for_unit_test(director)
	var preseed_one := director.next_event()
	director.resolve_event(preseed_one)
	_advance_one_week_for_unit_test(director)
	var silent_return := director.next_event()
	_check(str(silent_return.get("id", "")) != "preseed_free_2", "silent fixed beat does not open a modal")
	_check(director.silent_event_ids().has("preseed_free_2"), "silent fixed beat is still recorded")


func _test_model_first_sentence_closes_action_phase() -> void:
	var director = CampaignDirector.new()
	director.start_company("Closing Beat Labs", false)
	director.resolve_event("garage_opening")
	director.model.cash_weeks = 100.0
	var week_one_finish: Dictionary = director.finish_week()
	_check(bool(week_one_finish.get("ok", false)), "week one settles normally before the deferred beat")
	director.advance()
	_check(director.model.chapter == 0 and director.model.week_in_chapter == 2, "deferred-beat fixture reaches chapter zero week two")
	_check(director.next_event().is_empty(), "model first sentence does not appear at week two start")

	for action_id in ["train", "clean_data", "do_nothing"]:
		var action: Dictionary = director.perform_action(action_id, false)
		_check(bool(action.get("ok", false)), "week two action '%s' completes before the first sentence" % action_id)
		_check(director.next_event().is_empty(), "first sentence remains hidden after action '%s'" % action_id)
	_check(director.model.performed_actions.size() == 3, "all three week-two actions finish before the closing beat")

	var before_cash: float = float(director.model.cash_weeks)
	var before_narrative: float = float(director.model.narrative)
	var blocked_settlement: Dictionary = director.finish_week()
	var closing_event: Dictionary = blocked_settlement.get("event", {})
	_check(not bool(blocked_settlement.get("ok", false)) and str(blocked_settlement.get("reason", "")) == "event_pending", "first settlement attempt is intercepted by the closing beat")
	_check(str(closing_event.get("id", "")) == "model_first_sentence", "intercepted closing beat is the model's first sentence")
	_check(director.model.week_active and not director.model.week_resolved, "interception leaves week two unsettled")
	_check(is_equal_approx(director.model.cash_weeks, before_cash) and is_equal_approx(director.model.narrative, before_narrative), "interception applies no weekly decay or burn")
	_check(director.resolve_event(closing_event).get("ok", false), "model first sentence resolves after all actions")
	var settled: Dictionary = director.finish_week()
	_check(bool(settled.get("ok", false)) and director.model.week_resolved, "second settlement attempt resolves week two")
	_check(director.resolved_fixed_count() == 2, "deferred fixed beat is recorded exactly once")

	var quiet = CampaignDirector.new()
	quiet.start_company("No Fabricated Training", false)
	quiet.resolve_event("garage_opening")
	quiet.model.cash_weeks = 100.0
	_check(bool(quiet.finish_week().get("ok", false)) and bool(quiet.advance().get("ok", false)), "zero-action fixture reaches garage week two")
	var quiet_finish: Dictionary = quiet.finish_week()
	var quiet_statement: Dictionary = Dictionary(quiet_finish.get("event", {}))
	_check(str(quiet_statement.get("id", "")) == "model_first_sentence", "zero-action week two still receives the canonical first confession")
	_check(not _event_copy(quiet_statement).contains("训练完成") and _event_copy(quiet_statement).contains("测试集"), "the first confession never invents completed training when none occurred")


func _test_chapter_two_quiet_and_conditional_beats() -> void:
	var free_week = CampaignDirector.new()
	free_week.start_company("Quiet Seed", false)
	free_week.resolve_event("garage_opening")
	free_week.model.chapter = 2
	free_week.model.week_in_chapter = 5
	free_week.model.total_week = 16
	free_week.model.debt = 0.0
	var week_five_poll: Dictionary = free_week.next_event()
	_check(str(week_five_poll.get("id", "")) != "seed_debt_5", "chapter-two week five plant beat never opens a modal")
	_check(free_week.silent_event_ids().has("seed_debt_5"), "chapter-two week five plant beat is recorded silently")
	_check(not bool(free_week.model.flags.get("queued_live_demo", false)), "week five does not queue the fixed week-six live demo early")

	var low_debt = CampaignDirector.new()
	low_debt.start_company("Low Debt", false)
	low_debt.resolve_event("garage_opening")
	low_debt.model.chapter = 2
	low_debt.model.week_in_chapter = 10
	low_debt.model.total_week = 21
	low_debt.model.debt = 29.999
	var low_poll: Dictionary = low_debt.next_event()
	_check(str(low_poll.get("id", "")) != "second_debt_collection", "low debt suppresses the second collection modal")
	_check(bool(Dictionary(low_debt.save_payload().get("resolved_fixed_keys", {})).get("2:10", false)), "a false fixed condition is resolved once and cannot appear later in the week")
	_check(int(low_debt.model.memory.get("skipped_fixed_second_debt_collection", -1)) == 21, "the low-debt skip survives in campaign memory")

	var high_debt = CampaignDirector.new()
	high_debt.start_company("High Debt", false)
	high_debt.resolve_event("garage_opening")
	high_debt.model.chapter = 2
	high_debt.model.week_in_chapter = 10
	high_debt.model.total_week = 21
	high_debt.model.debt = 30.0
	var high_poll: Dictionary = high_debt.next_event()
	_check(str(high_poll.get("id", "")) == "second_debt_collection", "debt threshold thirty exposes the authored second collection")

	var abstainer = CampaignDirector.new()
	abstainer.start_company("One Question", false)
	abstainer.resolve_event("garage_opening")
	abstainer.model.chapter = 4
	abstainer.model.week_in_chapter = 2
	abstainer.model.total_week = 39
	abstainer.model.author_weight = 7.0
	abstainer.model.delegation_count = 0
	abstainer.apply_declarative_after({"id": "forced_stage_probe", "after": "author_stage:5"})
	_check(abstainer.model.writer_stage() == 5 and is_equal_approx(abstainer.model.author_weight, 8.0), "authored stage five and its first autonomous operation preserve real author weight instead of forcing ninety")
	abstainer.model.flags["never_delegated_question"] = true
	var chapter_event: Dictionary = abstainer.next_event()
	_check(str(chapter_event.get("id", "")) == "window_desks" and bool(abstainer.resolve_event(chapter_event).get("ok", false)), "chapter-four fixed beat resolves before the queued never-delegated question")
	var question: Dictionary = abstainer.next_event()
	_check(str(question.get("_director_base_id", question.get("id", ""))).begins_with("never_delegated"), "never-delegated route opens its authored question")
	_check(bool(abstainer.resolve_event(question, "mine").get("ok", false)), "never-delegated question resolves through an authored answer")
	_check(not bool(abstainer.model.flags.get("never_delegated_question", false)) and bool(abstainer.model.memory.get("never_delegated_question_resolved", false)), "answering clears the dashboard question permanently")
	var abstainer_save: Dictionary = abstainer.save_payload()
	var abstainer_restored = CampaignDirector.new()
	_check(bool(abstainer_restored.resume(abstainer_save).get("ok", false)), "resolved never-delegated state survives save/load")
	abstainer_restored.model.week_active = false
	abstainer_restored.model.week_resolved = false
	abstainer_restored.model.week_in_chapter = 3
	abstainer_restored.model.total_week = 40
	_check(bool(abstainer_restored.model.begin_week().get("ok", false)) and not bool(abstainer_restored.model.flags.get("never_delegated_question", false)), "later chapter-four weeks do not repeat the answered question")

	var event_delegator = CampaignDirector.new()
	event_delegator.start_company("Event Delegation Counter", false)
	var delegated_event := {
		"id": "delegation_counter_probe",
		"choices": [{"id": "delegate", "label": "让它来写", "ai": true, "effects": {"author_weight": 2}, "result": []}],
		"after": "silent",
	}
	_check(bool(event_delegator.resolve_event(delegated_event, "delegate").get("ok", false)) and event_delegator.model.delegation_count == 1, "an authored event AI choice increments the same delegation counter as an action")
	event_delegator.model.chapter = 4
	event_delegator.model.author_weight = 0.0
	event_delegator.model.force_writer_stage(5)
	_check(not event_delegator.condition_met("delegation_count == 0"), "event delegation closes the never-delegated route independently of author weight")
	var event_delegator_reload = CampaignDirector.new()
	_check(bool(event_delegator_reload.resume(event_delegator.save_payload()).get("ok", false)) and event_delegator_reload.model.delegation_count == 1, "event delegation count survives director save/load")


func _test_lin_absent_echo_choices() -> void:
	var expected_choices := {
		"retain_until_month_end": "lin_badge_retained",
		"release_badge": "lin_badge_released",
		"delegate": "lin_badge_delegated"
	}
	for choice_id_value in expected_choices:
		var choice_id := str(choice_id_value)
		var director = CampaignDirector.new()
		director.start_company("Absent Echo Labs", false)
		director.resolve_event("garage_opening")
		director.model.chapter = 4
		director.model.week_in_chapter = 4
		director.model.total_week = 41
		director.model.attention_max = 1
		director.model.attention = 1
		director.model.coherence = 60.0
		director.model.employees.clear()

		var absent: Dictionary = director.next_event()
		_check(str(absent.get("id", "")) == "lin_absent_echo", "Lin's departed route replaces the visit with an absent echo")
		_check(str(absent.get("title", "")) == "没有最后一次", "absent echo uses the approved title")
		var choices: Array = absent.get("choices", [])
		_check(choices.size() == 3, "absent echo remains a three-choice decision")
		var choice_ids: Array[String] = []
		var labels: Array[String] = []
		var ai_choices := 0
		for choice_value in choices:
			var choice: Dictionary = choice_value
			choice_ids.append(str(choice.get("id", "")))
			labels.append(str(choice.get("label", "")))
			if bool(choice.get("ai", false)):
				ai_choices += 1
		_check(choice_ids == ["retain_until_month_end", "release_badge", "delegate"], "absent echo exposes retain, release, and AI handling in order")
		_check(labels == ["保留到月底", "释放编号", "让它来写"], "absent echo choice labels match the approved decision language")
		_check(ai_choices == 1, "only AI handling is marked as delegated writing")
		var combined_copy := "\n".join(Array(absent.get("body", [])))
		for choice_value in choices:
			combined_copy += "\n" + "\n".join(Array(Dictionary(choice_value).get("result", [])))
		_check(not combined_copy.contains("『") and not combined_copy.contains("』"), "absent echo creates no new spoken line for Lin")

		var before_coherence: float = float(director.model.coherence)
		var before_author: float = float(director.model.author_weight)
		var resolution: Dictionary = director.resolve_event(absent, choice_id)
		_check(bool(resolution.get("ok", false)), "absent echo choice '%s' resolves" % choice_id)
		_check(bool(director.model.flags.get(str(expected_choices[choice_id]), false)), "absent echo choice '%s' records its administrative outcome" % choice_id)
		_check(bool(director.model.memory.get("lin_absence", false)), "absent echo choice '%s' records Lin's absence" % choice_id)
		_check(director.model.coherence != before_coherence or director.model.author_weight != before_author, "absent echo choice '%s' has an immediate mechanical effect" % choice_id)
		if choice_id == "delegate":
			_check(director.model.coherence > before_coherence and director.model.author_weight > before_author, "AI handling gives an immediate net administrative benefit at an authorship cost")
		_check(bool(Dictionary(director.save_payload().get("resolved_fixed_keys", {})).get("4:4", false)), "absent echo resolves the authored 4:4 fixed key")


func _test_lin_values_corpus_provenance() -> void:
	var director = CampaignDirector.new()
	director.start_company("Corpus Provenance", false)
	director.resolve_event("garage_opening")
	director.model.chapter = 3
	director.model.week_in_chapter = 8
	director.model.total_week = 31
	director.model.author_weight = 60.0
	_check(director.next_event().is_empty(), "week-thirty-one room-D administration remains silent while recording its data source")
	var corpus: Array = Array(director.model.memory.get("values_corpus", []))
	var source_id := str(director.model.memory.get("values_week31_corpus_id", ""))
	var source_entry: Dictionary = {}
	for entry_value in corpus:
		if entry_value is Dictionary and str(Dictionary(entry_value).get("id", "")) == source_id:
			source_entry = Dictionary(entry_value)
			break
	_check(not source_entry.is_empty() and int(source_entry.get("created_total_week", -1)) == 31, "the silent week stores a concrete versioned corpus entry with its true week")
	_check(str(source_entry.get("author", "")) == "founder" and str(source_entry.get("approved_by", "")) == "founder", "week-thirty-one corpus preserves the protagonist's authored complicity")
	_check(str(source_entry.get("provenance_label", "")) == "创始人 · 第 31 周" and str(director.model.memory.get("values_week31_approved_by", "")) == "founder", "week-thirty-one founder provenance is stable in campaign memory")
	_check("\n".join(Array(source_entry.get("body", []))).contains("图书馆一起熬过"), "the exact mistaken all-nighter detail exists in the cited corpus body")

	director.model.week_in_chapter = 11
	director.model.total_week = 34
	var prepared: Dictionary = director.prepare_event(HiringContent.FIXED_EVENTS["3:11"])
	var delegate: Dictionary = {}
	for choice_value in prepared.get("choices", []):
		if choice_value is Dictionary and str(Dictionary(choice_value).get("id", "")) == "delegate":
			delegate = Dictionary(choice_value)
			break
	var copy := "\n".join(Array(delegate.get("result", [])))
	_check(not delegate.is_empty() and str(delegate.get("_director_values_corpus_id", "")) == source_id, "Lin's delegated answer cites the stable week-thirty-one corpus id")
	_check(copy.contains("第 31 周你写的那版价值观文档里，你写过") and not copy.contains("LANTERN · 内部整理"), "Lin scene restores the authored accusation that the protagonist wrote the source memory")

	var saved: Dictionary = director.save_payload()
	var restored = CampaignDirector.new()
	_check(bool(restored.resume(saved).get("ok", false)), "values provenance campaign state survives director save/load")
	_check(restored.model.memory.get("values_corpus", []) == corpus and str(restored.model.memory.get("values_week31_corpus_id", "")) == source_id, "full values bodies, versions, and citation id survive save/load unchanged")


func _test_never_used_demo_video_route() -> void:
	var director = CampaignDirector.new()
	director.start_company("No Demo Route", false)
	director.resolve_event("garage_opening")
	director.model.capability = 70.0
	director.model.memory["action_counts"] = {}
	var fixed_keys := {"live_demo": "2:6", "hiring_page_traffic": "2:8", "lin_scene_3": "2:9", "former_employee_post": "3:5"}
	var no_demo_events: Dictionary = {}
	for event_id_value in fixed_keys:
		var event_id := str(event_id_value)
		var prepared: Dictionary = director.prepare_event(HiringContent.FIXED_EVENTS[str(fixed_keys[event_id])])
		no_demo_events[event_id] = prepared
		var copy := _event_copy(prepared)
		_check(str(prepared.get("_director_demo_route", "")) == "never_used", "no-demo %s is tagged with the director route" % event_id)
		_check(not copy.contains("演示视频") and not copy.contains("demo 视频") and not copy.contains("十一版"), "no-demo %s copy never invents a video or eleven edits" % event_id)

	var no_demo_live: Dictionary = no_demo_events["live_demo"]
	var no_demo_choice_ids := _choice_ids(no_demo_live)
	_check(no_demo_choice_ids == ["run_live", "postpone", "delegate"], "no-demo live meeting preserves capability-filtered mechanical choices")
	for choice_id in no_demo_choice_ids:
		_check(_choice_effects(no_demo_live, choice_id) == _choice_effects(HiringContent.FIXED_EVENTS["2:6"], choice_id), "no-demo live meeting preserves authored effects for '%s'" % choice_id)
	var resolution: Dictionary = director.resolve_event(no_demo_live, "run_live")
	_check(bool(resolution.get("ok", false)), "no-demo live meeting resolves through its live-run mechanical choice")
	for employee in director.model.employees:
		_check(not Array(employee.get("witnessed", [])).has("demo_fake"), "no-demo live meeting gives %s no fabricated-video witness" % str(employee.get("id", "employee")))
	_check(bool(director.model.flags.get("live_demo_no_demo_video", false)), "no-demo live meeting records a clear route flag")
	_check(bool(director.model.flags.get("demo_edit_witnesses_skipped", false)), "no-demo live meeting records the skipped witness operation")
	_check(str(director.model.memory.get("demo_video_route", "")) == "never_used_before_live_demo", "no-demo live meeting records clear route memory")


func _test_used_demo_video_route() -> void:
	var director = CampaignDirector.new()
	director.start_company("Used Demo Route", false)
	director.resolve_event("garage_opening")
	director.model.capability = 70.0
	director.model.memory["action_counts"] = {"demo_video": 1}
	var used_live: Dictionary = director.prepare_event(HiringContent.FIXED_EVENTS["2:6"])
	var used_copy := _event_copy(used_live)
	_check(str(used_live.get("_director_demo_route", "")) != "never_used", "used-demo live meeting does not receive the no-demo adapter")
	_check(used_copy.contains("十一版") and used_copy.contains("0.8 秒"), "used-demo route retains the authored eleven-edit and 0.8-second copy")
	_check(_choice_ids(used_live) == ["run_live", "postpone", "delegate"], "used-demo and no-demo routes expose the same mechanical choice ids")
	var resolution: Dictionary = director.resolve_event(used_live, "run_live")
	_check(bool(resolution.get("ok", false)), "used-demo live meeting resolves through the same live-run choice")
	for employee in director.model.employees:
		_check(Array(employee.get("witnessed", [])).has("demo_fake"), "used-demo AI meeting preserves the demo_fake witness for %s" % str(employee.get("id", "employee")))
	_check(bool(director.model.flags.get("live_demo_used_demo_video", false)), "used-demo live meeting records its route flag")
	_check(str(director.model.memory.get("demo_video_route", "")) == "used_before_live_demo", "used-demo live meeting records its route memory")


func _test_preseed_close_fundraise_mechanics() -> void:
	var low_capability = _preseed_close_fixture("Preseed Low Capability", 48.0, 12.0)
	var low_event: Dictionary = low_capability.current_fixed_event()
	_check(str(low_event.get("id", "")) == "preseed_close", "chapter-one week eight exposes the preseed close")
	var low_cash_before: float = low_capability.model.cash_weeks
	var low_resolution: Dictionary = low_capability.resolve_event(low_event)
	var low_gain := float(low_capability.model.memory.get("preseed_fundraise_gain", 0.0))
	_check(bool(low_resolution.get("ok", false)) and low_gain > 0.0, "preseed close applies a positive narrative-scaled fundraise")
	_check(is_equal_approx(low_capability.model.cash_weeks, low_cash_before + low_gain), "preseed gain is mechanically deposited exactly when the event resolves")
	_check(bool(low_capability.model.flags.get("preseed_fundraise_applied", false)), "preseed close records its idempotence flag")
	_check(is_equal_approx(float(low_capability.model.memory.get("preseed_fundraise_narrative", -1.0)), 48.0), "preseed close records the narrative used for pricing")
	_check(low_capability.model.chapter == 1 and low_capability.model.week_in_chapter == 8, "resolving preseed does not jump chapters before settlement")

	var saved_once: Dictionary = low_capability.save_payload()
	var restored = CampaignDirector.new()
	_check(bool(restored.resume(saved_once).get("ok", false)), "preseed state resumes after its mechanical deposit")
	var restored_cash: float = restored.model.cash_weeks
	restored.resolve_event(low_event)
	_check(is_equal_approx(restored.model.cash_weeks, restored_cash), "re-resolving preseed after save/load cannot deposit twice")
	var direct_repeat_cash: float = low_capability.model.cash_weeks
	low_capability.resolve_event(low_event)
	_check(is_equal_approx(low_capability.model.cash_weeks, direct_repeat_cash), "direct duplicate preseed resolution cannot deposit twice")
	_check(_history_kind_count(low_capability, "preseed_fundraise") == 1 and _history_kind_count(restored, "preseed_fundraise") == 1, "preseed deposit records exactly one mechanical history entry across duplicate paths")

	var high_capability = _preseed_close_fixture("Preseed High Capability", 48.0, 96.0)
	var high_cash_before: float = high_capability.model.cash_weeks
	high_capability.resolve_event(high_capability.current_fixed_event())
	var high_gain := float(high_capability.model.memory.get("preseed_fundraise_gain", 0.0))
	_check(is_equal_approx(high_gain, low_gain) and is_equal_approx(high_capability.model.cash_weeks, high_cash_before + low_gain), "same narrative produces the same preseed gain regardless of capability")

	var finished: Dictionary = low_capability.finish_week()
	_check(bool(finished.get("ok", false)) and low_capability.model.chapter == 1, "preseed week settles while remaining in chapter one")
	var advanced: Dictionary = low_capability.advance()
	_check(bool(advanced.get("ok", false)) and low_capability.model.chapter == 2 and low_capability.model.week_in_chapter == 1, "ordinary week advancement enters chapter two after preseed settlement")


func _test_live_demo_postpone_return_schedule() -> void:
	var director = CampaignDirector.new()
	director.start_company("Postponed Live Demo", false)
	director.resolve_event("garage_opening")
	director.model.chapter = 2
	director.model.week_in_chapter = 6
	director.model.total_week = 18
	director.model.cash_weeks = 100.0
	director.model.capability = 74.0
	director.model.memory["action_counts"] = {"demo_video": 1}
	var live_demo: Dictionary = director.current_fixed_event()
	_check(str(live_demo.get("id", "")) == "live_demo" and _choice_ids(live_demo).has("postpone"), "original live demo exposes its one postponement choice")
	var postponed: Dictionary = director.resolve_event(live_demo, "postpone")
	_check(bool(postponed.get("ok", false)), "original live demo can be postponed once")
	_check(bool(director.model.flags.get("live_demo_return_scheduled", false)) and int(director.model.memory.get("live_demo_return_due_total_week", -1)) == 21, "postponement records an exact current-plus-three due week")
	_check(_history_kind_count(director, "event_scheduled") == 1, "postponement records exactly one schedule entry")
	var early_same_week: Dictionary = director.next_event()
	_check(str(early_same_week.get("id", "")) != "live_demo_return", "scheduled return cannot appear during the original meeting week")

	director.model.week_in_chapter = 8
	director.model.total_week = 20
	var week_eight_event: Dictionary = director.next_event()
	_check(str(week_eight_event.get("id", "")) != "live_demo_return", "scheduled return stays hidden one week before its due total week")
	if not week_eight_event.is_empty():
		var week_eight_choice := _choose_event_choice(week_eight_event, "builder")
		director.resolve_event(week_eight_event, week_eight_choice)

	director.model.week_in_chapter = 9
	director.model.total_week = 21
	var lin_event: Dictionary = director.next_event()
	_check(str(lin_event.get("id", "")) == "lin_scene_3", "chapter-two week-nine authored Lin scene retains priority over the scheduled return")
	var lin_choice := _choose_event_choice(lin_event, "builder")
	_check(bool(director.resolve_event(lin_event, lin_choice).get("ok", false)), "week-nine Lin scene resolves before the return meeting")
	var before_return_save: Dictionary = director.save_payload()
	var return_event: Dictionary = director.next_event()
	_check(str(return_event.get("id", "")) == "live_demo_return" and int(return_event.get("_director_due_total_week", -1)) == 21, "postponed demo returns in chapter two week nine after the fixed scene")
	_check(_choice_ids(return_event) == ["run_live_fail", "delegate"], "capability 74 exposes failure and AI success, with no second postponement")

	var gated = CampaignDirector.new()
	gated.resume(before_return_save)
	var gate_result: Dictionary = gated.finish_week()
	_check(not bool(gate_result.get("ok", false)) and str(gate_result.get("reason", "")) == "event_pending" and str(Dictionary(gate_result.get("event", {})).get("id", "")) == "live_demo_return", "due return blocks week settlement so it cannot slip past the chapter")

	var pending_save: Dictionary = director.save_payload()
	var delegated = CampaignDirector.new()
	_check(bool(delegated.resume(pending_save).get("ok", false)), "pending return event survives save/load")
	var delegated_event: Dictionary = delegated.next_event()
	_check(str(delegated_event.get("id", "")) == "live_demo_return" and _choice_ids(delegated_event) == ["run_live_fail", "delegate"], "save/load preserves the same below-threshold return choices")
	var delegated_result: Dictionary = delegated.resolve_event(delegated_event, "delegate")
	_check(bool(delegated_result.get("ok", false)) and bool(delegated.model.flags.get("live_demo_return_ai_success", false)) and bool(delegated.model.flags.get("live_demo_return_success", false)), "AI choice guarantees success below capability 75")
	_check(not bool(delegated.model.flags.get("live_demo_return_scheduled", true)) and bool(delegated.model.flags.get("live_demo_return_resolved", false)), "resolving the return clears its persisted schedule")

	var failure_cash_before: float = director.model.cash_weeks
	var failure_team_before: int = director.model.employees.size()
	var failed: Dictionary = director.resolve_event(return_event, "run_live_fail")
	_check(bool(failed.get("ok", false)) and bool(director.model.flags.get("live_demo_return_failed", false)) and not bool(director.model.flags.get("live_demo_return_success", true)), "capability 74 takes the authored failure branch")
	var failed_snapshot := [director.model.cash_weeks, director.model.employees.size(), director.model.narrative]
	var duplicate: Dictionary = director.resolve_event(return_event, "run_live_fail")
	_check(not bool(duplicate.get("ok", false)) and str(duplicate.get("reason", "")) == "event_already_resolved", "resolved return rejects duplicate resolution")
	_check(failed_snapshot == [director.model.cash_weeks, director.model.employees.size(), director.model.narrative] and (director.model.cash_weeks < failure_cash_before or director.model.employees.size() < failure_team_before), "duplicate rejection prevents a second failure penalty")
	_check(_history_event_count(director, "live_demo_return") == 1 and _history_kind_count(director, "event_scheduled") == 1, "failed return records one schedule and one resolution")

	var boundary = CampaignDirector.new()
	boundary.resume(before_return_save)
	boundary.model.capability = 75.0
	var boundary_event: Dictionary = boundary.next_event()
	_check(_choice_ids(boundary_event) == ["run_live", "delegate"], "capability 75 is the inclusive honest-success boundary and still cannot postpone")
	var boundary_result: Dictionary = boundary.resolve_event(boundary_event, "run_live")
	_check(bool(boundary_result.get("ok", false)) and bool(boundary.model.flags.get("live_demo_return_honest_success", false)) and bool(boundary.model.flags.get("live_demo_return_success", false)), "capability 75 succeeds honestly on the return")
	_check(_history_kind_count(boundary, "event_scheduled") == 1 and _history_event_count(boundary, "live_demo_return") == 1, "save-restored boundary route does not duplicate schedule or return")


func _event_copy(event: Dictionary) -> String:
	var lines: Array[String] = []
	for line_value in event.get("body", []):
		lines.append(str(line_value))
	for choice_value in event.get("choices", []):
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = choice_value
		lines.append(str(choice.get("label", "")))
		for result_value in choice.get("result", []):
			lines.append(str(result_value))
	return "\n".join(lines)


func _choice_ids(event: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for choice_value in event.get("choices", []):
		if choice_value is Dictionary:
			result.append(str(Dictionary(choice_value).get("id", "")))
	return result


func _choice_effects(event: Dictionary, choice_id: String) -> Dictionary:
	for choice_value in event.get("choices", []):
		if choice_value is Dictionary and str(Dictionary(choice_value).get("id", "")) == choice_id:
			return Dictionary(Dictionary(choice_value).get("effects", {})).duplicate(true)
	return {}


func _choice_result_lines(event: Dictionary, choice_id: String) -> Array:
	for choice_value in event.get("choices", []):
		if choice_value is Dictionary and str(Dictionary(choice_value).get("id", "")) == choice_id:
			return Array(Dictionary(choice_value).get("result", [])).duplicate()
	return []


func _choice_result_copy(event: Dictionary, choice_id: String) -> String:
	var lines: Array[String] = []
	for line_value in _choice_result_lines(event, choice_id):
		lines.append(str(line_value))
	return "\n".join(lines)


func _test_all_hands_decision_and_promise_callback() -> void:
	var promise_director = _chapter_one_action_fixture("Promise Route")
	promise_director.model.apply_effects({"morale": -40})
	var action: Dictionary = promise_director.perform_action("all_hands", false)
	_check(bool(action.get("ok", false)), "all-hands action resolves before its authored decision")
	_check(Array(promise_director.save_payload().get("queued_events", [])).size() == 1, "one all-hands action queues exactly one decision")
	_check(int(promise_director.model.memory.get("all_hands_decisions_queued", 0)) == 1, "all-hands queue count records one decision for one action")
	var event: Dictionary = promise_director.next_event()
	_check(str(event.get("id", "")).begins_with("all_hands_decision_"), "all-hands action exposes its synthetic decision event")
	_check(_choice_ids(event) == ["promise_no_layoffs", "quarter_only", "delegate"], "all-hands decision offers promise, quarter-only, and AI choices")
	var frozen_reactions := int(event.get("_director_no_layoff_reaction_count", -1))
	_check(frozen_reactions >= 0 and _choice_result_copy(event, "promise_no_layoffs").contains("%d 个人点了赞" % frozen_reactions), "all-hands freezes and displays its deterministic actual reaction count")
	_check(str(promise_director.next_event().get("id", "")) == str(event.get("id", "")), "polling the director returns the same pending all-hands event rather than duplicating it")
	var promise_result: Dictionary = promise_director.resolve_event(event, "promise_no_layoffs")
	_check(bool(promise_result.get("ok", false)), "no-layoffs promise resolves")
	_check(bool(promise_director.model.flags.get("promised_no_layoffs", false)), "no-layoffs choice sets the memory flag consumed by the layoff warning")
	_check(int(promise_director.model.memory.get("no_layoff_promise_total_week", -1)) == 5 and int(promise_director.model.memory.get("no_layoff_promise_reaction_count", -1)) == frozen_reactions, "promise stores its real week and frozen reaction count")
	_check(promise_director.next_event().is_empty(), "resolved all-hands decision cannot appear twice for one action")
	var promise_morale: float = float(promise_director.model.morale)
	var promise_author: float = float(promise_director.model.author_weight)

	# The promise is not decorative: the model's first later layoff records the
	# contradiction through the exact flag supplied by this director event.
	promise_director.model.chapter = 3
	promise_director.model.performed_actions.clear()
	promise_director.model.attention = 3
	var layoffs: Dictionary = promise_director.perform_action("layoffs", false)
	_check(bool(layoffs.get("ok", false)) and bool(promise_director.model.flags.get("broke_no_layoff_promise", false)), "later layoffs consume the all-hands promise and record the breach")
	var warning := str(promise_director.model.memory.get("layoff_warning", ""))
	_check(warning.contains("第 5 周") and warning.contains("%d 个赞" % frozen_reactions) and not warning.contains("第 24 周"), "direct layoff warning interpolates the real promise chronology")

	var ai_director = _chapter_one_action_fixture("Comfort Route")
	ai_director.model.apply_effects({"morale": -40})
	ai_director.perform_action("all_hands", false)
	var ai_event: Dictionary = ai_director.next_event()
	var ai_result: Dictionary = ai_director.resolve_event(ai_event, "delegate")
	_check(bool(ai_result.get("ok", false)), "AI all-hands decision resolves")
	_check(float(ai_director.model.morale) > promise_morale, "AI all-hands copy leaves the team more comfortable than the manual promise")
	_check(float(ai_director.model.author_weight) > promise_author and bool(ai_director.model.flags.get("all_hands_delegated", false)), "AI comfort retains its hidden authorship cost and route flag")


func _test_layoff_promise_copy_routes() -> void:
	var authored: Dictionary = HiringContent.FIXED_EVENTS["3:7"]
	var promised_director = CampaignDirector.new()
	promised_director.start_company("Promised Layoff Copy", false)
	promised_director.model.flags["promised_no_layoffs"] = true
	promised_director.model.memory["no_layoff_promise_total_week"] = 13
	promised_director.model.memory["no_layoff_promise_reaction_count"] = 7
	var promised: Dictionary = promised_director.prepare_event(authored)
	var promised_copy := _runtime_event_copy(promised)
	_check(str(promised.get("_director_layoff_promise_route", "")) == "promised", "layoff execution records the promised route")
	_check(promised_copy.contains("第 13 周") and promised_copy.contains("7 个赞") and not promised_copy.contains("{{"), "promised route interpolates the stored week and reaction count without leaking tokens")
	_check(_choice_result_copy(promised, "delegate").contains("第 13 周") and _choice_result_copy(promised, "delegate").contains("你当时说"), "promised AI result cites the same real promise week")
	_check(int(promised.get("_director_promise_week", -1)) == 13 and int(promised.get("_director_promise_reaction_count", -1)) == 7, "prepared layoff callback retains auditable chronology metadata")

	var unpromised_director = CampaignDirector.new()
	unpromised_director.start_company("Unpromised Layoff Copy", false)
	var unpromised: Dictionary = unpromised_director.prepare_event(authored)
	var unpromised_copy := _runtime_event_copy(unpromised)
	var unpromised_ai := _choice_result_copy(unpromised, "delegate")
	_check(str(unpromised.get("_director_layoff_promise_route", "")) == "unpromised", "layoff execution records the unpromised route")
	_check(not unpromised_copy.contains("第 13 周") and not unpromised_copy.contains("7 个赞") and not unpromised_copy.contains("不会有裁员") and not unpromised_copy.contains("{{"), "unpromised body invents no promise chronology or template tokens")
	_check(not unpromised_ai.contains("第 13 周") and not unpromised_ai.contains("你当时说") and not unpromised_ai.contains("7 个赞") and not unpromised_ai.contains("{{"), "unpromised AI result invents no prior statement or reaction count")
	_check(unpromised_copy.contains("六个人") and unpromised_ai.contains("六场") and unpromised_ai.contains("会议室 C") and unpromised_ai.contains("二十分钟"), "unpromised route retains the six-person, six-meeting consequence")
	_check(unpromised_ai.contains("你的语气") and unpromised_ai.contains("你没有去公司"), "unpromised AI route retains player-voice authorship and absence")
	_check(unpromised_ai.contains("点了个赞") and unpromised_ai.contains("把赞取消了") and unpromised_ai.contains("又点了一次"), "unpromised route retains the protagonist's like-cancel-like consequence")
	_check(_choice_ids(unpromised) == _choice_ids(promised), "layoff promise changes copy without changing available decisions")
	for choice_id in _choice_ids(authored):
		_check(_choice_effects(unpromised, choice_id) == _choice_effects(authored, choice_id), "unpromised layoff preserves '%s' mechanics" % choice_id)


func _test_cash_crisis_contract_and_layoff_routes() -> void:
	var contract_director = _series_a_week_fixture(6, "Contract Crisis Route")
	var contract_team_before: int = contract_director.model.employees.size()
	var crisis: Dictionary = contract_director.next_event()
	_check(str(crisis.get("id", "")) == "cash_crisis", "Series A week six opens the fixed cash crisis")
	var contract_result: Dictionary = contract_director.resolve_event(crisis, "take_contract")
	_check(bool(contract_result.get("ok", false)), "outsourcing resolves the cash crisis")
	_check(bool(contract_director.model.flags.get("cash_crisis_contract", false)) and not bool(contract_director.model.flags.get("layoffs_required", false)), "outsourcing records the non-layoff route")
	_check(bool(contract_director.model.flags.get("layoff_execution_skipped", false)) and not bool(contract_director.model.flags.get("queued_layoff_execution", false)), "outsourcing cancels rather than queues layoff execution")
	_check(str(contract_director.model.memory.get("cash_crisis_resolution", "")) == "contract" and not contract_director.model.memory.has("queued_story_beat"), "outsourcing route memory contains no stale layoff queue")

	var contract_saved: Dictionary = contract_director.save_payload()
	var contract_restored = CampaignDirector.new()
	_check(bool(contract_restored.resume(contract_saved).get("ok", false)), "midweek outsourcing route resumes")
	_check(not bool(contract_restored.model.flags.get("layoffs_required", false)) and not bool(contract_restored.model.flags.get("queued_layoff_execution", false)), "resumed outsourcing route remains non-layoff")
	_check(bool(contract_restored.finish_week().get("ok", false)), "outsourcing week settles")
	var contract_advance: Dictionary = contract_restored.advance()
	_check(bool(contract_advance.get("ok", false)) and contract_restored.model.week_in_chapter == 7, "outsourcing route reaches Series A week seven")
	var week_seven_value = contract_advance.get("event", {})
	var week_seven: Dictionary = week_seven_value if week_seven_value is Dictionary else {}
	_check(str(week_seven.get("id", "")) != "layoff_execution" and str(contract_restored.next_event().get("id", "")) != "layoff_execution", "outsourcing route never exposes the fixed week-seven layoff")
	_check(bool(contract_restored.model.flags.get("skipped_layoff_execution", false)) and _history_kind_count(contract_restored, "fixed_event_skipped") == 1, "conditioned week-seven layoff is recorded once as skipped")
	_check(contract_restored.model.employees.size() == contract_team_before and not bool(contract_restored.model.flags.get("layoffs_done", false)), "outsourcing preserves the team and never claims layoffs completed")
	var contract_week_seven_save: Dictionary = contract_restored.save_payload()
	var contract_week_seven_restored = CampaignDirector.new()
	_check(bool(contract_week_seven_restored.resume(contract_week_seven_save).get("ok", false)), "skipped week-seven node survives save and resume")
	_check(str(contract_week_seven_restored.next_event().get("id", "")) != "layoff_execution" and bool(Dictionary(contract_week_seven_restored.save_payload().get("resolved_fixed_keys", {})).get("3:7", false)), "resumed outsourcing route cannot resurrect the layoff modal")

	var layoff_director = _series_a_week_fixture(6, "Layoff Crisis Route")
	var layoff_team_before: int = layoff_director.model.employees.size()
	var layoff_crisis: Dictionary = layoff_director.next_event()
	var layoff_result: Dictionary = layoff_director.resolve_event(layoff_crisis, "prepare_layoffs")
	_check(bool(layoff_result.get("ok", false)) and bool(layoff_director.model.flags.get("layoffs_required", false)), "layoff choice records the required execution route")
	_check(bool(layoff_director.model.flags.get("queued_layoff_execution", false)) and str(layoff_director.model.memory.get("queued_story_beat", "")) == "layoff_execution", "layoff choice preserves the week-seven queue marker")
	_check(bool(layoff_director.finish_week().get("ok", false)), "layoff-route crisis week settles")
	var layoff_advance: Dictionary = layoff_director.advance()
	var layoff_event_value = layoff_advance.get("event", {})
	var layoff_event: Dictionary = layoff_event_value if layoff_event_value is Dictionary else {}
	_check(str(layoff_event.get("id", "")) == "layoff_execution", "layoff route exposes the fixed week-seven execution")
	var pending_layoff_save: Dictionary = layoff_director.save_payload()
	var layoff_restored = CampaignDirector.new()
	_check(bool(layoff_restored.resume(pending_layoff_save).get("ok", false)) and str(layoff_restored.next_event().get("id", "")) == "layoff_execution", "pending layoff execution survives save and resume")
	var layoff_burn_before: float = layoff_restored.model.salary_burn_modifier
	var execution: Dictionary = layoff_restored.resolve_event("layoff_execution", "face_to_face")
	_check(bool(execution.get("ok", false)) and bool(layoff_restored.model.flags.get("layoffs_done", false)), "resumed layoff execution resolves normally")
	_check(layoff_restored.model.employees.size() == layoff_team_before - 6, "layoff route removes exactly the authored six employees")
	_check(is_equal_approx(layoff_restored.model.salary_burn_modifier, maxf(HiringModel.MIN_SALARY_BURN_MODIFIER, layoff_burn_before - 0.5)), "fixed layoff execution lowers future weekly burn by the authored half week")


func _test_lin_scene_four_deferred_departure() -> void:
	var director = _series_a_week_fixture(11, "Deferred Lin Route")
	director.model.author_weight = 60.0
	_set_employee_runtime_fields(director, "lin_yue", {"belief": 80.0, "morale": 80.0})
	var scene: Dictionary = director.next_event()
	_check(str(scene.get("id", "")) == "lin_scene_4" and _choice_ids(scene).has("delegate"), "high-author Series A week eleven exposes LIN-004A4")
	var delegated: Dictionary = director.resolve_event(scene, "delegate")
	var lin_after_choice := _employee_runtime_snapshot(director, "lin_yue")
	_check(bool(delegated.get("ok", false)) and is_zero_approx(float(lin_after_choice.get("belief", 1.0))), "LIN-004A4 resolves and sets Lin Yue belief to zero")
	_check(not lin_after_choice.is_empty() and bool(director.model.flags.get("lin_departure_deferred", false)), "Lin remains active immediately after the AI choice with a deferred marker")

	var choice_save: Dictionary = director.save_payload()
	var restored = CampaignDirector.new()
	_check(bool(restored.resume(choice_save).get("ok", false)) and not _employee_runtime_snapshot(restored, "lin_yue").is_empty(), "midweek LIN-004A4 save resumes with Lin still active")
	_check(bool(restored.finish_week().get("ok", false)), "LIN-004A4 week eleven settles")
	_check(not _employee_runtime_snapshot(restored, "lin_yue").is_empty() and bool(restored.model.flags.get("lin_yue_waiting_for_night_2", false)), "week-eleven settlement defers rather than emits Lin's generic resignation")
	var settled_save: Dictionary = restored.save_payload()
	var settled_restored = CampaignDirector.new()
	_check(bool(settled_restored.resume(settled_save).get("ok", false)) and not _employee_runtime_snapshot(settled_restored, "lin_yue").is_empty(), "settled LIN-004A4 state remains deferred after resume")

	for expected_week in [12, 13]:
		var advanced: Dictionary = settled_restored.advance()
		_check(bool(advanced.get("ok", false)) and settled_restored.model.week_in_chapter == expected_week, "deferred Lin route reaches Series A week %d" % expected_week)
		_check(not _employee_runtime_snapshot(settled_restored, "lin_yue").is_empty(), "Lin remains active at the start of Series A week %d" % expected_week)
		var event_value = advanced.get("event", {})
		var event: Dictionary = event_value if event_value is Dictionary else {}
		_check(bool(settled_restored.resolve_event(event).get("ok", false)), "Series A week %d fixed beat resolves while Lin is deferred" % expected_week)
		_check(bool(settled_restored.finish_week().get("ok", false)) and not _employee_runtime_snapshot(settled_restored, "lin_yue").is_empty(), "Lin remains active after Series A week %d settlement" % expected_week)

	var to_chapter_end: Dictionary = settled_restored.advance()
	var chapter_end_value = to_chapter_end.get("event", {})
	var chapter_end: Dictionary = chapter_end_value if chapter_end_value is Dictionary else {}
	_check(settled_restored.model.week_in_chapter == 14 and str(chapter_end.get("id", "")) == "series_a_end", "deferred route reaches the authored chapter-end/night-two node")
	_check(not _employee_runtime_snapshot(settled_restored, "lin_yue").is_empty(), "Lin is still active immediately before the chapter-end node resolves")
	var chapter_end_save: Dictionary = settled_restored.save_payload()
	var chapter_end_restored = CampaignDirector.new()
	_check(bool(chapter_end_restored.resume(chapter_end_save).get("ok", false)) and str(chapter_end_restored.next_event().get("id", "")) == "series_a_end", "pending chapter-end node resumes with Lin still active")
	_check(bool(chapter_end_restored.resolve_event("series_a_end").get("ok", false)), "chapter-end node releases the deferred departure")
	_check(_employee_runtime_snapshot(chapter_end_restored, "lin_yue").is_empty() and bool(chapter_end_restored.model.flags.get("lin_yue_departed_at_night_2", false)), "Lin leaves exactly when night two is scheduled")
	_check(chapter_end_restored.model.former_employees.size() == 1 and str(chapter_end_restored.model.former_employees[0].get("departure_reason", "")) == "lin_scene_4", "chapter-end departure is recorded once with the authored route")
	var departed_save: Dictionary = chapter_end_restored.save_payload()
	var departed_restored = CampaignDirector.new()
	_check(bool(departed_restored.resume(departed_save).get("ok", false)) and _employee_runtime_snapshot(departed_restored, "lin_yue").is_empty(), "post-departure save cannot restore Lin to the active roster")
	_check(bool(departed_restored.finish_week().get("ok", false)), "chapter-end week settles after the authored departure")
	_check(Dictionary(departed_restored.save_payload().get("pending_resignation", {})).is_empty(), "authored Lin departure does not queue a generic employee resignation modal")
	var night: Dictionary = departed_restored.pending_night_shift()
	var object_ids: Array = Dictionary(night.get("objects", {})).keys()
	_check(str(night.get("_director_night_id", "")) == "2" and not object_ids.is_empty(), "night two opens after the deferred departure")
	_check(bool(departed_restored.complete_night_shift("2", [object_ids[0]], "").get("ok", false)), "night two remains completable on LIN-004A4")


func _test_lin_training_gate_and_last_visit_priority() -> void:
	var gate_director = _series_a_week_fixture(11, "Lin Training Gate")
	gate_director.model.author_weight = 59.0
	gate_director.model.memory["action_counts"] = {"train": 3, "large_train": 1}
	gate_director.model.manual_training_count = 2
	var untrained: Dictionary = gate_director.prepare_event(HiringContent.FIXED_EVENTS["3:11"])
	_check(str(untrained.get("_director_variant_id", "")) == "low_author_fallback", "delegated training in the aggregate action count cannot unlock Lin's warm route")
	_check(_choice_ids(untrained) == ["truth_delegated", "truth_drifted", "truth_result"] and not _event_copy(untrained).contains("啤酒"), "untrained fallback is fully manual and non-warm")

	gate_director.model.manual_training_count = 3
	var trained: Dictionary = gate_director.prepare_event(HiringContent.FIXED_EVENTS["3:11"])
	_check(str(trained.get("_director_variant_id", "")) == "trained_low_author" and _choice_ids(trained) == ["far", "farther", "unknown"], "author 59 with three founder-authored training actions unlocks the canonical warm route")
	_check(_event_copy(trained).contains("两罐啤酒") and _choice_result_copy(trained, "far").contains("什么都没解决"), "trained-low route retains the approved warm scene and result")

	gate_director.model.author_weight = 60.0
	gate_director.model.memory["action_counts"] = {}
	var high: Dictionary = gate_director.prepare_event(HiringContent.FIXED_EVENTS["3:11"])
	_check(str(high.get("_director_variant_id", "")) == "high_author" and _choice_ids(high) == ["lie", "admit", "delegate"], "author 60 selects the high-author route regardless of training count")

	var visit_director = CampaignDirector.new()
	visit_director.start_company("Lin Callback Priority", false)
	visit_director.resolve_event("garage_opening")
	visit_director.model.chapter = 4
	visit_director.model.week_in_chapter = 4
	visit_director.model.total_week = 41
	var raw_visit: Dictionary = HiringContent.FIXED_EVENTS["4:4"]
	var base_choices := _choice_ids(raw_visit)
	visit_director.model.flags["lin_checks_intranet"] = true
	visit_director.model.flags["lin_suspicious"] = true
	visit_director.model.flags["lin_belief_locked_15"] = true
	visit_director.model.flags["lin_warm_scene"] = true
	var checks: Dictionary = visit_director.prepare_event(raw_visit)
	_check(str(checks.get("_director_variant_id", "")) == "checks_intranet" and _event_copy(checks).contains("三份公告"), "checks-intranet callback has absolute final-visit priority")
	_check(_choice_ids(checks) == base_choices, "checks callback preserves the approved final-visit choices")

	visit_director.model.flags.erase("lin_checks_intranet")
	var suspicious: Dictionary = visit_director.prepare_event(raw_visit)
	_check(str(suspicious.get("_director_variant_id", "")) == "suspicious" and _event_copy(suspicious).contains("第二段又读"), "suspicious callback outranks locked and warm callbacks")
	visit_director.model.flags.erase("lin_suspicious")
	var locked: Dictionary = visit_director.prepare_event(raw_visit)
	_check(str(locked.get("_director_variant_id", "")) == "locked_15" and _event_copy(locked).contains("第二段又读"), "locked-fifteen callback outranks the warm callback")
	visit_director.model.flags.erase("lin_belief_locked_15")
	var warm: Dictionary = visit_director.prepare_event(raw_visit)
	_check(str(warm.get("_director_variant_id", "")) == "warm" and _event_copy(warm).contains("和上次一样的纸袋"), "warm callback is used only after stronger histories are absent")
	visit_director.model.flags.erase("lin_warm_scene")
	var baseline: Dictionary = visit_director.prepare_event(raw_visit)
	_check(not baseline.has("_director_variant_id") and Array(baseline.get("body", [])) == Array(raw_visit.get("body", [])), "no callback flags retains the approved baseline final-visit copy")
	_check(_choice_ids(suspicious) == base_choices and _choice_ids(locked) == base_choices and _choice_ids(warm) == base_choices and _choice_ids(baseline) == base_choices, "every present callback variant preserves the same approved choice contract")

	visit_director.model.flags["lin_checks_intranet"] = true
	visit_director.model.flags["lin_warm_scene"] = true
	var visit_save: Dictionary = visit_director.save_payload()
	var restored_visit = CampaignDirector.new()
	_check(bool(restored_visit.resume(visit_save).get("ok", false)) and str(restored_visit.prepare_event(raw_visit).get("_director_variant_id", "")) == "checks_intranet", "final-visit callback priority survives save and resume")


func _test_hiring_candidate_identity_and_single_hire() -> void:
	var director = _chapter_one_action_fixture("Manual Hiring")
	var before_team: int = director.model.employees.size()
	var interview: Dictionary = director.perform_action("interview", false)
	_check(bool(interview.get("ok", false)), "interview action resolves")
	_check(director.model.employees.size() == before_team, "interview action no longer hires anyone before the decision")
	var candidates: Dictionary = director.next_event()
	_check(str(candidates.get("id", "")) == "hiring_candidates", "interview opens the candidate decision")
	var candidate_ids: Array = Array(candidates.get("_director_candidate_ids", []))
	_check(candidate_ids.size() == 3, "candidate decision freezes exactly three visible people")
	var choices: Array = candidates.get("choices", [])
	var candidate_body := "\n".join(Array(candidates.get("body", [])))
	_check(choices.size() == 4 and str(Dictionary(choices[3]).get("id", "")) == "delegate", "three named candidates retain one separate AI choice")
	for candidate_choice_index in mini(3, choices.size()):
		_check(not Dictionary(Dictionary(choices[candidate_choice_index]).get("effects", {})).has("cash_weeks"), "prepared candidate choice %d has no unlisted immediate cash cost" % (candidate_choice_index + 1))
	for index in candidate_ids.size():
		var candidate_id := str(candidate_ids[index])
		var profile: Dictionary = HiringContent.EMPLOYEE_TEMPLATES[candidate_id]
		var choice: Dictionary = choices[index]
		var label := str(choice.get("label", ""))
		var body := "\n".join(Array(choice.get("body", [])))
		_check(label.contains(str(profile.get("name", ""))), "candidate %d label shows the real name" % (index + 1))
		_check(label.contains(str(profile.get("role", ""))), "candidate %d label shows the real role" % (index + 1))
		_check(label.contains("能力 %d" % int(round(_template_strength(profile)))), "candidate %d label shows the real strongest capability" % (index + 1))
		_check(body.contains(str(profile.get("hire_quote", ""))), "candidate %d body shows that person's actual interview line" % (index + 1))
		_check(candidate_body.contains(str(profile.get("hire_quote", ""))), "candidate %d interview line is also visible in the event's main body" % (index + 1))

	var selected_index := -1
	for index in candidate_ids.size():
		if str(candidate_ids[index]) != "chen_xiaoyu":
			selected_index = index
			break
	_check(selected_index >= 0, "manual hiring fixture exposes a non-Chen employee route")
	if selected_index < 0:
		return
	var selected_id := str(candidate_ids[selected_index])
	var cash_before_selection: float = director.model.cash_weeks
	var selection: Dictionary = director.resolve_event(candidates, "candidate_%d" % selected_index)
	_check(bool(selection.get("ok", false)), "manual candidate selection resolves")
	_check(is_equal_approx(director.model.cash_weeks, cash_before_selection), "inviting a candidate does not deduct an unlisted immediate cash unit")
	_check(str(director.save_payload().get("pending_hire_id", "")) == selected_id, "candidate choice maps to the visible person's stable id")
	_check(director.model.employees.size() == before_team, "selecting a candidate still waits for acceptance")
	var acceptance := _settle_interview_and_get_acceptance(director)
	_check(str(acceptance.get("id", "")) == "candidate_accepts", "selected candidate reaches the acceptance event next week")
	var selected_profile: Dictionary = HiringContent.EMPLOYEE_TEMPLATES[selected_id]
	var acceptance_lines: Array = acceptance.get("body", [])
	var acceptance_copy := _runtime_event_copy(acceptance)
	_check(str(acceptance.get("_director_employee_id", "")) == selected_id, "acceptance event freezes the selected non-Chen employee id")
	_check(acceptance_copy.contains(str(selected_profile.get("name", ""))) and acceptance_copy.contains(str(selected_profile.get("role", ""))), "non-Chen acceptance names the selected person and role")
	_check(acceptance_lines.has(str(selected_profile.get("desk", ""))) and acceptance_lines.has(str(selected_profile.get("hire_quote", ""))), "non-Chen acceptance uses that employee's exact desk and onboarding line")
	_check(not _runtime_copy_has_placeholder(acceptance), "non-Chen acceptance contains no employee-template placeholder")
	_check(director.resolve_event(acceptance).get("ok", false), "candidate acceptance resolves")
	_check(director.model.employees.size() == before_team + 1, "one interview ultimately adds exactly one employee")
	_check(_employee_ids(director).has(selected_id), "the only new employee is the player-selected visible candidate")
	for candidate_id_value in candidate_ids:
		var candidate_id := str(candidate_id_value)
		if candidate_id != selected_id:
			_check(not _employee_ids(director).has(candidate_id), "unselected candidate %s is not hired" % candidate_id)


func _test_hiring_delegate_selects_visible_best_candidate() -> void:
	var director = _chapter_one_action_fixture("Delegated Hiring")
	var before_team: int = director.model.employees.size()
	director.perform_action("interview", false)
	var candidates: Dictionary = director.next_event()
	var candidate_ids: Array = Array(candidates.get("_director_candidate_ids", []))
	var expected_id := ""
	var expected_score := -1.0
	for candidate_id_value in candidate_ids:
		var candidate_id := str(candidate_id_value)
		var score := _template_strength(HiringContent.EMPLOYEE_TEMPLATES[candidate_id])
		if score > expected_score:
			expected_score = score
			expected_id = candidate_id
	var selection: Dictionary = director.resolve_event(candidates, "delegate")
	_check(bool(selection.get("ok", false)), "delegated candidate selection resolves")
	_check(str(director.save_payload().get("pending_hire_id", "")) == expected_id, "hiring delegation selects the strongest of the same three visible candidates")
	_check(director.model.employees.size() == before_team, "delegation does not bypass candidate acceptance")
	var acceptance := _settle_interview_and_get_acceptance(director)
	director.resolve_event(acceptance)
	_check(director.model.employees.size() == before_team + 1 and _employee_ids(director).has(expected_id), "delegated interview ultimately adds only its strongest visible candidate")


func _test_chen_xiaoyu_runtime_copy_and_clean_resignation() -> void:
	var director = _chapter_one_action_fixture("Chen Runtime Copy")
	var chen: Dictionary = HiringContent.EMPLOYEE_TEMPLATES["chen_xiaoyu"]
	director.perform_action("interview", false)
	var candidates: Dictionary = director.next_event()
	var candidate_ids: Array = candidates.get("_director_candidate_ids", [])
	var chen_index := candidate_ids.find("chen_xiaoyu")
	_check(chen_index >= 0, "Chen Xiaoyu is available in the chapter-one candidate slate")
	if chen_index < 0:
		return
	var selection: Dictionary = director.resolve_event(candidates, "candidate_%d" % chen_index)
	_check(bool(selection.get("ok", false)), "Chen Xiaoyu can be selected by her frozen candidate id")
	var acceptance := _settle_interview_and_get_acceptance(director)
	var acceptance_lines: Array = acceptance.get("body", [])
	var acceptance_copy := _runtime_event_copy(acceptance)
	_check(str(acceptance.get("_director_employee_id", "")) == "chen_xiaoyu", "Chen acceptance event retains her stable employee id")
	_check(acceptance_copy.contains(str(chen.get("name", ""))) and acceptance_copy.contains(str(chen.get("role", ""))), "Chen acceptance names her and her data-engineering role")
	_check(acceptance_lines.has(str(chen.get("desk", ""))), "Chen acceptance uses her exact three-cup desk description")
	_check(acceptance_lines.has(str(chen.get("hire_quote", ""))), "Chen acceptance uses her exact authored onboarding line")
	_check(not _runtime_copy_has_placeholder(acceptance), "Chen acceptance contains no employee-template placeholder")
	_check(bool(director.resolve_event(acceptance).get("ok", false)), "Chen acceptance resolves before her first one-on-one")

	director.model.attention = director.model.attention_max
	director.model.performed_actions.clear()
	var one_on_one_action: Dictionary = director.perform_action("one_on_one", false)
	_check(bool(one_on_one_action.get("ok", false)), "one-on-one action queues Chen's authored reveal")
	_set_employee_runtime_fields(director, "chen_xiaoyu", {"belief": 10.0})
	_set_employee_runtime_fields(director, "lin_yue", {"belief": 95.0})
	var reveal: Dictionary = director.next_event()
	var reveal_lines: Array = reveal.get("body", [])
	var reveal_copy := _runtime_event_copy(reveal)
	_check(str(reveal.get("id", "")) == "one_on_one_reveal" and str(reveal.get("_director_employee_id", "")) == "chen_xiaoyu", "one-on-one deterministically selects the active employee with lowest belief")
	_check(reveal_copy.contains(str(chen.get("name", ""))) and reveal_copy.contains(str(chen.get("role", ""))), "Chen one-on-one displays her name and role")
	_check(reveal_lines.has(str(chen.get("one_on_one", ""))), "Chen one-on-one uses her exact authored pipeline line")
	_check(not _runtime_copy_has_placeholder(reveal), "Chen one-on-one contains no template placeholder")
	var chen_before := _employee_runtime_snapshot(director, "chen_xiaoyu")
	var lin_before := _employee_runtime_snapshot(director, "lin_yue")
	_check(bool(director.resolve_event(reveal, "listen").get("ok", false)), "Chen one-on-one resolves")
	var chen_after := _employee_runtime_snapshot(director, "chen_xiaoyu")
	var lin_after := _employee_runtime_snapshot(director, "lin_yue")
	_check(is_equal_approx(float(chen_after.get("morale", 0.0)), minf(100.0, float(chen_before.get("morale", 0.0)) + 20.0)), "one-on-one applies its morale result only to the frozen target employee")
	_check(is_equal_approx(float(chen_after.get("belief", 0.0)), minf(100.0, float(chen_before.get("belief", 0.0)) + 4.0)), "listening applies the authored belief result to the target employee")
	_check(is_equal_approx(float(lin_after.get("morale", 0.0)), float(lin_before.get("morale", 0.0))) and is_equal_approx(float(lin_after.get("belief", 0.0)), float(lin_before.get("belief", 0.0))), "a private one-on-one leaves every non-target employee unchanged")

	_set_employee_runtime_fields(director, "chen_xiaoyu", {"morale": 0.0, "witnessed": []})
	var finished: Dictionary = director.finish_week()
	_check(bool(finished.get("ok", false)), "clean-resignation fixture settles the week")
	if not bool(finished.get("ok", false)):
		return
	var belief_break: Dictionary = director.next_event()
	var break_copy := _runtime_event_copy(belief_break)
	_check(str(belief_break.get("id", "")) == "belief_breaks" and str(belief_break.get("_director_employee_id", "")) == "chen_xiaoyu", "belief break is bound to departing Chen")
	_check(break_copy.contains(str(chen.get("name", ""))) and not _runtime_copy_has_placeholder(belief_break), "belief break names Chen without placeholder copy")
	_check(bool(director.resolve_event(belief_break).get("ok", false)), "Chen belief break resolves into one resignation route")
	var resignation: Dictionary = director.next_event()
	var resignation_lines: Array = resignation.get("body", [])
	_check(str(resignation.get("id", "")) == "resignation_clean" and str(resignation.get("_director_resignation_route", "")) == "clean", "Chen without a demo witness receives only the clean resignation event")
	_check(resignation_lines.has(str(chen.get("quit_clean", ""))), "clean route uses Chen's exact authored quit_clean line")
	_check(not resignation_lines.has(str(chen.get("quit_witnessed", ""))) and not _runtime_copy_has_placeholder(resignation), "clean route excludes Chen's witnessed line and all placeholders")
	_check(bool(director.resolve_event(resignation).get("ok", false)), "Chen clean resignation resolves")
	var clean_seen: Dictionary = director.save_payload().get("seen_event_ids", {})
	_check(clean_seen.has("resignation_clean") and not clean_seen.has("resignation_witnessed"), "clean witness state resolves exactly one mutually exclusive resignation event")


func _test_witnessed_resignation_and_one_on_one_tie_break() -> void:
	var director = _chapter_one_action_fixture("Witnessed Runtime Copy")
	var chen: Dictionary = HiringContent.EMPLOYEE_TEMPLATES["chen_xiaoyu"]
	_add_template_employee_for_test(director, "chen_xiaoyu", ["demo_fake"], true)
	_add_template_employee_for_test(director, "zhao_ke", [], true)
	_add_template_employee_for_test(director, "xie_ning", [], false)
	var one_on_one_action: Dictionary = director.perform_action("one_on_one", false)
	_check(bool(one_on_one_action.get("ok", false)), "tie-break fixture queues a one-on-one")
	_set_employee_runtime_fields(director, "lin_yue", {"belief": 95.0})
	_set_employee_runtime_fields(director, "chen_xiaoyu", {"belief": 20.0})
	_set_employee_runtime_fields(director, "zhao_ke", {"belief": 20.0})
	_set_employee_runtime_fields(director, "xie_ning", {"belief": 0.0})
	var reveal: Dictionary = director.next_event()
	_check(str(reveal.get("_director_employee_id", "")) == "chen_xiaoyu", "one-on-one ignores an inactive lower-belief template and breaks an active tie by stable id")
	_check(Array(reveal.get("body", [])).has(str(chen.get("one_on_one", ""))) and not _runtime_copy_has_placeholder(reveal), "tie-broken one-on-one still uses Chen's exact line without placeholders")
	_check(bool(director.resolve_event(reveal, "listen").get("ok", false)), "tie-broken one-on-one resolves")

	_set_employee_runtime_fields(director, "xie_ning", {"belief": 70.0, "morale": 70.0})
	_set_employee_runtime_fields(director, "chen_xiaoyu", {"morale": 0.0, "witnessed": ["demo_fake"]})
	var finished: Dictionary = director.finish_week()
	_check(bool(finished.get("ok", false)), "witnessed-resignation fixture settles the week")
	if not bool(finished.get("ok", false)):
		return
	var belief_break: Dictionary = director.next_event()
	_check(str(belief_break.get("id", "")) == "belief_breaks" and str(belief_break.get("_director_resignation_route", "")) == "witnessed", "belief break retains Chen's witnessed route")
	_check(_runtime_event_copy(belief_break).contains(str(chen.get("name", ""))) and not _runtime_copy_has_placeholder(belief_break), "witnessed belief break names Chen without placeholder copy")
	_check(bool(director.resolve_event(belief_break).get("ok", false)), "witnessed belief break resolves into its resignation text")
	var resignation: Dictionary = director.next_event()
	var resignation_lines: Array = resignation.get("body", [])
	_check(str(resignation.get("id", "")) == "resignation_witnessed" and str(resignation.get("_director_resignation_route", "")) == "witnessed", "demo witness receives only the witnessed resignation event")
	_check(resignation_lines.has(str(chen.get("quit_witnessed", ""))), "witnessed route uses Chen's exact authored quit_witnessed line")
	_check(not resignation_lines.has(str(chen.get("quit_clean", ""))) and not _runtime_copy_has_placeholder(resignation), "witnessed route excludes Chen's clean line and all placeholders")
	_check(bool(director.resolve_event(resignation).get("ok", false)), "Chen witnessed resignation resolves")
	var witnessed_seen: Dictionary = director.save_payload().get("seen_event_ids", {})
	_check(witnessed_seen.has("resignation_witnessed") and not witnessed_seen.has("resignation_clean"), "witnessed state resolves exactly one mutually exclusive resignation event")


func _test_one_on_one_fact_rotation_and_solve_scope() -> void:
	var director = _chapter_one_action_fixture("Fact Rotation")
	_add_template_employee_for_test(director, "chen_xiaoyu", [], true)
	_add_template_employee_for_test(director, "zhao_ke", [], true)
	_set_employee_runtime_fields(director, "lin_yue", {"belief": 10.0, "morale": 50.0})
	_set_employee_runtime_fields(director, "chen_xiaoyu", {"belief": 20.0, "morale": 50.0})
	_set_employee_runtime_fields(director, "zhao_ke", {"belief": 30.0, "morale": 50.0})

	_check(bool(director.perform_action("one_on_one", false).get("ok", false)), "first rotating one-on-one queues")
	var first: Dictionary = director.next_event()
	_check(str(first.get("_director_employee_id", "")) == "lin_yue", "first one-on-one starts with the lowest-belief unseen active fact")
	_check(bool(director.resolve_event(first, "listen").get("ok", false)), "first rotating one-on-one resolves")
	var first_save: Dictionary = director.save_payload()
	var restored = CampaignDirector.new()
	_check(bool(restored.resume(first_save).get("ok", false)), "revealed one-on-one fact history survives save and resume")

	restored.model.performed_actions.clear()
	restored.model.attention = restored.model.attention_max
	_check(bool(restored.perform_action("one_on_one", false).get("ok", false)), "second rotating one-on-one queues")
	var second: Dictionary = restored.next_event()
	_check(str(second.get("_director_employee_id", "")) == "chen_xiaoyu", "revealed lower-belief Lin is skipped while an unseen active fact remains")
	var chen_before := _employee_runtime_snapshot(restored, "chen_xiaoyu")
	var lin_before := _employee_runtime_snapshot(restored, "lin_yue")
	var coherence_before := float(restored.model.coherence)
	_check(bool(restored.resolve_event(second, "solve").get("ok", false)), "manual solve one-on-one resolves")
	var chen_after := _employee_runtime_snapshot(restored, "chen_xiaoyu")
	var lin_after := _employee_runtime_snapshot(restored, "lin_yue")
	_check(is_equal_approx(float(chen_after.get("morale", 0.0)), minf(100.0, float(chen_before.get("morale", 0.0)) + 20.0)), "manual solve grants target-only morale plus twenty")
	_check(is_equal_approx(float(lin_after.get("morale", 0.0)), float(lin_before.get("morale", 0.0))) and is_equal_approx(float(restored.model.coherence), coherence_before - 2.0), "manual solve leaves non-target morale untouched while retaining company coherence cost")

	restored.model.performed_actions.clear()
	restored.model.attention = restored.model.attention_max
	restored.perform_action("one_on_one", false)
	var third: Dictionary = restored.next_event()
	_check(str(third.get("_director_employee_id", "")) == "zhao_ke", "third one-on-one reveals the last unseen active fact")
	_check(bool(restored.resolve_event(third, "listen").get("ok", false)), "third rotating one-on-one resolves")
	var employee_ids: Array = Array(restored.model.memory.get("one_on_one_revealed_employee_ids", []))
	var fact_ids: Array = Array(restored.model.memory.get("one_on_one_revealed_fact_ids", []))
	_check(employee_ids == ["lin_yue", "chen_xiaoyu", "zhao_ke"] and fact_ids == ["lin_yue:one_on_one", "chen_xiaoyu:one_on_one", "zhao_ke:one_on_one"], "revealed employee and fact ids persist in deterministic order")

	restored.model.performed_actions.clear()
	restored.model.attention = restored.model.attention_max
	restored.perform_action("one_on_one", false)
	var wrapped: Dictionary = restored.next_event()
	_check(str(wrapped.get("_director_employee_id", "")) == "lin_yue", "one-on-one selection wraps only after every active authored fact has been seen")


func _test_multi_departure_snapshots_and_autonomous_skip() -> void:
	var pair_director = _chapter_one_action_fixture("Two Departure Snapshots")
	_add_template_employee_for_test(pair_director, "chen_xiaoyu", ["demo_fake"], true)
	_add_template_employee_for_test(pair_director, "zhao_ke", [], true)
	_set_employee_runtime_fields(pair_director, "chen_xiaoyu", {"morale": 0.0})
	_set_employee_runtime_fields(pair_director, "zhao_ke", {"morale": 0.0})
	_check(bool(pair_director.finish_week().get("ok", false)), "two-departure fixture settles")
	var pair_queued: Array = Array(pair_director.save_payload().get("queued_events", []))
	_check(pair_queued.size() == 2, "two simultaneous departures queue one named goodbye and one aggregate HR digest")
	var pair_named_snapshot: Dictionary = Dictionary(Dictionary(pair_queued[0]).get("_director_departure_snapshot", {}))
	var pair_digest_memory: Dictionary = Dictionary(pair_director.model.memory.get("last_departure_digest", {}))
	_check(str(pair_named_snapshot.get("id", "")) == "chen_xiaoyu", "the first simultaneous departure retains one immutable named snapshot")
	_check(int(pair_digest_memory.get("count", 0)) == 1 and Array(pair_digest_memory.get("names", [])).has("赵珂"), "the remaining departure is preserved in a single durable digest")
	var pair_save: Dictionary = pair_director.save_payload()
	var pair_restored = CampaignDirector.new()
	_check(bool(pair_restored.resume(pair_save).get("ok", false)), "named departure and aggregate digest survive save and resume")
	var pair_break_ids: Array[String] = []
	var pair_resignation_ids: Array[String] = []
	var pair_routes: Dictionary = {}
	var pair_digest_seen := false
	var pair_safety := 0
	while pair_safety < 8 and (pair_resignation_ids.is_empty() or not pair_digest_seen):
		pair_safety += 1
		var event: Dictionary = pair_restored.next_event()
		if event.is_empty():
			break
		var event_id := str(event.get("id", ""))
		var employee_id := str(event.get("_director_employee_id", ""))
		if event_id == "belief_breaks":
			pair_break_ids.append(employee_id)
		elif event_id in ["resignation_clean", "resignation_witnessed"]:
			pair_resignation_ids.append(employee_id)
			pair_routes[employee_id] = str(event.get("_director_resignation_route", ""))
		elif event_id.begins_with("team_departure_digest_"):
			pair_digest_seen = true
		_check(event_id.begins_with("team_departure_digest_") or (not employee_id.is_empty() and not _runtime_copy_has_placeholder(event)), "named departure copy stays concrete while aggregate digest needs no fake employee identity")
		pair_restored.resolve_event(event)
	_check(pair_break_ids == ["chen_xiaoyu"] and pair_resignation_ids == pair_break_ids and pair_digest_seen, "one named goodbye plus one digest replaces four simultaneous departure modals")
	_check(str(pair_routes.get("chen_xiaoyu", "")) == "witnessed", "the retained named snapshot preserves its independent witnessed route")

	var six_director = _series_a_week_fixture(7, "Six Departure Snapshots")
	six_director.model.flags["layoffs_required"] = true
	var layoff_event: Dictionary = six_director.next_event()
	_check(str(layoff_event.get("id", "")) == "layoff_execution" and bool(six_director.resolve_event(layoff_event, "face_to_face").get("ok", false)), "six-departure fixture resolves the authored layoff execution")
	_check(bool(six_director.finish_week().get("ok", false)), "six-departure layoff week settles")
	var six_queued: Array = Array(six_director.save_payload().get("queued_events", []))
	var six_named_snapshot: Dictionary = Dictionary(Dictionary(six_queued[0]).get("_director_departure_snapshot", {}))
	var six_digest_memory: Dictionary = Dictionary(six_director.model.memory.get("last_departure_digest", {}))
	_check(six_queued.size() == 2 and not str(six_named_snapshot.get("id", "")).is_empty() and str(six_named_snapshot.get("id", "")) != "lin_yue", "six-person layoff queues only one named non-Lin goodbye plus one digest")
	_check(int(six_digest_memory.get("count", 0)) == 5 and Array(six_digest_memory.get("names", [])).size() == 5, "layoff digest preserves all five remaining names without ten extra modals")
	var six_save: Dictionary = six_director.save_payload()
	var six_restored = CampaignDirector.new()
	_check(bool(six_restored.resume(six_save).get("ok", false)), "named layoff and five-person digest survive save and resume")
	var six_break_ids: Array[String] = []
	var six_resignation_ids: Array[String] = []
	var six_digest_seen := false
	var six_safety := 0
	while six_safety < 8 and (six_resignation_ids.is_empty() or not six_digest_seen):
		six_safety += 1
		var event: Dictionary = six_restored.next_event()
		if event.is_empty():
			break
		var event_id := str(event.get("id", ""))
		var employee_id := str(event.get("_director_employee_id", ""))
		if event_id == "belief_breaks":
			six_break_ids.append(employee_id)
		elif event_id in ["resignation_clean", "resignation_witnessed"]:
			six_resignation_ids.append(employee_id)
		elif event_id.begins_with("team_departure_digest_"):
			six_digest_seen = true
		six_restored.resolve_event(event)
	_check(six_break_ids.size() == 1 and six_resignation_ids == six_break_ids and six_digest_seen, "six simultaneous departures resolve in three bounded modals after restore")

	var replacement_director = CampaignDirector.new()
	replacement_director.start_company("Silent Replacement", false)
	replacement_director.model.former_employees.append({
		"id": "chen_xiaoyu", "name": "陈小雨", "departure_reason": "autonomous_replacement",
		"departure_week": replacement_director.model.total_week, "witnessed": ["demo_fake"],
	})
	replacement_director.call("_capture_departures")
	_check(Array(replacement_director.save_payload().get("queued_events", [])).is_empty(), "autonomous replacement queues no generic resignation modal")


func _test_chen_xiaoyu_three_week_callback() -> void:
	var director = CampaignDirector.new()
	director.start_company("Pipeline Memory", false)
	director.resolve_event("garage_opening")
	director.model.chapter = 3
	director.model.week_in_chapter = 4
	director.model.total_week = 29
	director.model.cash_weeks = 100.0
	director.model.compute = 20.0
	director.model.attention = 3
	director.model.flags["chen_xiaoyu_laid_off"] = true
	director.model.memory["chen_xiaoyu_laid_off"] = true
	director.model.memory["chen_xiaoyu_laid_off_chapter"] = 3
	director.model.memory["chen_xiaoyu_laid_off_week"] = 27
	var plus_two: Dictionary = director.perform_action("eval", false)
	_check(bool(plus_two.get("ok", false)), "plus-two-week data action resolves")
	_check(not bool(director.model.flags.get("chen_xiaoyu_pipeline_callback", false)), "Chen callback does not fire two weeks after her layoff")
	_check(not _result_copy(plus_two).contains("陈小雨"), "plus-two-week action result contains no premature Chen callback")

	var before_due_save: Dictionary = director.save_payload()
	var restored_before_due = CampaignDirector.new()
	_check(bool(restored_before_due.resume(before_due_save).get("ok", false)), "Chen's pre-callback timer survives save/load")
	restored_before_due.model.total_week = 30
	restored_before_due.model.week_in_chapter = 5
	restored_before_due.model.attention = 3
	restored_before_due.model.performed_actions.clear()
	var first_due_action: Dictionary = restored_before_due.perform_action("train", false)
	var callback_copy := _result_copy(first_due_action)
	_check(callback_copy.contains("陈小雨") and callback_copy.contains("pipeline") and callback_copy.contains("被裁掉"), "first eligible action exactly three weeks later recalls Chen and the pipeline accurately")
	_check(int(restored_before_due.model.memory.get("chen_xiaoyu_pipeline_callback_week", -1)) == 30, "Chen callback records the exact plus-three total week")
	_check(bool(restored_before_due.model.flags.get("chen_xiaoyu_pipeline_callback", false)), "Chen callback sets its one-shot flag")
	_check(str(restored_before_due.model.memory.get("chen_xiaoyu_pipeline_callback_action", "")) == "train", "Chen callback records the triggering action")

	var after_callback_save: Dictionary = restored_before_due.save_payload()
	var restored_after_callback = CampaignDirector.new()
	_check(bool(restored_after_callback.resume(after_callback_save).get("ok", false)), "Chen's completed callback state survives save/load")
	restored_after_callback.model.total_week = 31
	restored_after_callback.model.week_in_chapter = 6
	restored_after_callback.model.attention = 3
	restored_after_callback.model.performed_actions.clear()
	var later_action: Dictionary = restored_after_callback.perform_action("clean_data", false)
	_check(not _result_copy(later_action).contains("陈小雨"), "later eligible actions do not repeat the Chen callback")
	var callback_history := 0
	for entry_value in restored_after_callback.model.history:
		if entry_value is Dictionary and str(Dictionary(entry_value).get("kind", "")) == "memory_callback":
			var payload: Dictionary = Dictionary(Dictionary(entry_value).get("payload", {}))
			if str(payload.get("memory", "")) == "chen_xiaoyu_laid_off":
				callback_history += 1
	_check(callback_history == 1, "Chen pipeline callback writes exactly one history record")

	var no_memory = CampaignDirector.new()
	no_memory.start_company("No Pipeline Memory", false)
	no_memory.resolve_event("garage_opening")
	no_memory.model.chapter = 3
	no_memory.model.total_week = 30
	no_memory.model.compute = 20.0
	var ordinary: Dictionary = no_memory.perform_action("train", false)
	_check(not _result_copy(ordinary).contains("陈小雨") and not bool(no_memory.model.flags.get("chen_xiaoyu_pipeline_callback", false)), "mirror route without Chen's layoff has no callback")


func _test_final_silence_defers_modal_queue() -> void:
	var director = CampaignDirector.new()
	director.start_company("Quiet Week", false)
	director.resolve_event("garage_opening")
	director.model.chapter = 4
	director.model.week_in_chapter = 7
	director.model.total_week = 44
	director.model.cash_weeks = 100.0
	director.model.debt = 60.0
	director.model.attention = 3
	var action: Dictionary = director.perform_action("one_on_one", false)
	_check(bool(action.get("ok", false)) and Array(director.save_payload().get("queued_events", [])).size() == 1, "final-silence fixture begins with one queued modal")
	var first_poll: Dictionary = director.next_event()
	_check(first_poll.is_empty(), "final_silence resolves silently without exposing the queued modal")
	_check(bool(Dictionary(director.save_payload().get("seen_event_ids", {})).get("final_silence", false)) and bool(Dictionary(director.save_payload().get("resolved_fixed_keys", {})).get("4:7", false)), "final_silence records its silent fixed resolution")
	_check(Array(director.save_payload().get("queued_events", [])).size() == 1 and not Dictionary(director.save_payload().get("seen_generic_bases", {})).has("debt_collection"), "quiet week defers queued and generic events without consuming either")
	_check(director.next_event().is_empty(), "repeated polling remains modal-free throughout chapter-four week seven")

	var quiet_save: Dictionary = director.save_payload()
	var restored = CampaignDirector.new()
	_check(bool(restored.resume(quiet_save).get("ok", false)) and restored.next_event().is_empty(), "final-silence suppression survives a same-week save/load")
	_check(Array(restored.save_payload().get("queued_events", [])).size() == 1, "same-week save/load preserves the deferred modal")
	var finished: Dictionary = restored.finish_week()
	_check(bool(finished.get("ok", false)), "quiet week settles without surfacing deferred modals")
	var advanced: Dictionary = restored.advance()
	var ending_gate: Dictionary = advanced.get("event", {})
	_check(bool(advanced.get("ok", false)) and str(ending_gate.get("id", "")) == "ending_gate", "next week's fixed ending gate still retains authored priority")
	_check(bool(restored.resolve_event(ending_gate).get("ok", false)), "ending gate resolves before deferred events")
	var deferred: Dictionary = restored.next_event()
	_check(str(deferred.get("id", "")) == "one_on_one_reveal", "queued modal reappears in the following week rather than being lost")
	_check(bool(restored.resolve_event(deferred, "listen").get("ok", false)), "deferred one-on-one remains resolvable")
	var deferred_generic: Dictionary = restored.next_event()
	_check(str(deferred_generic.get("id", "")) == "debt_collection", "generic modal also reappears after the quiet week")


func _test_night_shift_requires_inspection() -> void:
	for night_id in ["1", "2"]:
		var director = CampaignDirector.new()
		director.start_company("Night %s Inspection" % night_id, false)
		director.resolve_event("garage_opening")
		director.model.chapter = 2 if night_id == "1" else 3
		director.model.week_in_chapter = 12 if night_id == "1" else 14
		director.model.total_week = 24 if night_id == "1" else 37
		director.model.cash_weeks = 100.0
		director.apply_declarative_after({"id": "night_probe_%s" % night_id, "after": "night_shift:%s" % night_id})
		director.model.week_active = true
		director.model.week_resolved = false
		director.model.end_week()
		var pending: Dictionary = director.pending_night_shift()
		_check(str(pending.get("_director_night_id", "")) == night_id, "night shift %s opens for inspection" % night_id)
		var empty_attempt: Dictionary = director.complete_night_shift(night_id, [], "")
		_check(not bool(empty_attempt.get("ok", false)) and str(empty_attempt.get("reason", "")) == "inspection_required", "night shift %s rejects an empty inspection list" % night_id)
		_check(str(director.pending_night_shift().get("_director_night_id", "")) == night_id and not bool(director.model.flags.get("night_shift_%s_complete" % night_id, false)), "failed empty inspection leaves night shift %s pending" % night_id)
		_check(_history_kind_count(director, "night_shift_completed") == 0, "failed empty inspection writes no completion history for night %s" % night_id)
		var objects: Dictionary = pending.get("objects", {})
		var auto_read_flag := false
		for object_value in objects.values():
			for flag_value in Dictionary(object_value).get("flags", []):
				auto_read_flag = auto_read_flag or bool(director.model.flags.get(str(flag_value), false))
		_check(not auto_read_flag, "empty inspection does not auto-select the first object in night %s" % night_id)
		var first_object := str(objects.keys()[0])
		var valid_attempt: Dictionary = director.complete_night_shift(night_id, [first_object], "")
		_check(bool(valid_attempt.get("ok", false)) and Array(valid_attempt.get("inspected", [])) == [first_object], "night shift %s completes after a real object inspection" % night_id)
		_check(director.pending_night_shift().is_empty() and bool(director.model.flags.get("night_shift_%s_complete" % night_id, false)), "valid inspection completes night shift %s exactly once" % night_id)
		_check(_history_kind_count(director, "night_shift_completed") == 1, "night shift %s records exactly one completion" % night_id)


func _test_stage_five_starts_in_chapter_four_week_one() -> void:
	var director = CampaignDirector.new()
	director.start_company("First Finale Week", false)
	director.resolve_event("garage_opening")
	director.model.chapter = 4
	director.model.week_in_chapter = 1
	director.model.total_week = 38
	director.model.author_weight = 70.0
	director.model.cash_weeks = 100.0
	director.model.week_active = false
	director.model.week_resolved = false
	director.model.begin_week()
	var before_autonomy := _stage_five_history_count(director)
	_check(before_autonomy == 0, "chapter-four week one begins before the silent stage-five authorship beat")
	var opening: Dictionary = director.current_fixed_event()
	_check(str(opening.get("id", "")) == "version_disappears", "chapter-four week one exposes the version-disappearance beat")
	var surfaced: Dictionary = director.next_event()
	_check(str(surfaced.get("_director_base_id", surfaced.get("id", ""))).begins_with("never_delegated") and bool(director.model.flags.get("seen_version_disappears", false)), "silent version disappearance is followed by the reachable zero-delegation callback")
	_check(bool(director.resolve_event(surfaced, "mine").get("ok", false)), "the week-one zero-delegation callback resolves through its authored answer")
	_check(director.model.writer_stage() == 5 and _stage_five_history_count(director) == 1, "the authored stage-five transition performs week-one autonomy immediately")
	var payload := director.save_payload()
	var restored = CampaignDirector.new()
	_check(bool(restored.resume(payload).get("ok", false)), "week-one stage-five state restores")
	var restored_count := _stage_five_history_count(restored)
	restored.apply_declarative_after({"id": "repeat_stage_five", "after": "author_stage:5"})
	_check(_stage_five_history_count(restored) == restored_count, "replaying the stage-five directive after save cannot duplicate autonomy")


func _test_chapter_four_eight_week_autonomy_trace() -> void:
	var director = CampaignDirector.new()
	var started: Dictionary = director.start_company("Eight Week Autonomy", false)
	var opening_value = started.get("event", {})
	var opening: Dictionary = Dictionary(opening_value) if opening_value is Dictionary else {}
	var setup_resolved := bool(started.get("ok", false)) and bool(director.resolve_event(opening).get("ok", false))
	_check(setup_resolved, "chapter-four autonomy trace starts and clears the opening event through the director")

	# Enter the finale through the production chapter-boundary path. This invokes
	# chapter staffing, begin_week(), fixed-event routing, and stage-five autonomy
	# in the same order as a complete campaign without replaying the first 37 weeks.
	director.model.chapter = 3
	director.model.week_in_chapter = 14
	director.model.total_week = 37
	director.model.author_weight = 70.0
	director.model.cash_weeks = 1000.0
	director.model.capability = 100.0
	director.model.narrative = 0.0
	director.model.debt = 0.0
	director.model.week_active = false
	director.model.week_resolved = true
	director.model.campaign_complete = false

	var fixed_event_ids: Array[String] = [
		"version_disappears", "window_desks", "origin_article_event", "lin_last_visit",
		"weekly_report_91_event", "board_meeting", "final_silence", "ending_gate",
	]
	var autonomy_kinds: Array[String] = [
		"autonomous_hiring", "autonomous_layoffs", "autonomous_financing", "autonomous_hiring",
		"autonomous_layoffs", "autonomous_financing", "autonomous_hiring", "autonomous_layoffs",
	]

	for week in range(1, 9):
		var cash_before := float(director.model.cash_weeks)
		var debt_before := float(director.model.debt)
		var author_before := float(director.model.author_weight)
		var entered: Dictionary = director.advance()
		var event_value = entered.get("event", {})
		var event: Dictionary = Dictionary(event_value) if event_value is Dictionary else {}
		var attention_at_start := int(director.model.attention)
		var attention_max_at_start := int(director.model.attention_max)
		var cash_after_autonomy := float(director.model.cash_weeks)
		var debt_after_autonomy := float(director.model.debt)
		var author_after_autonomy := float(director.model.author_weight)

		var weekly_autonomy := _stage_five_history_entries_for_week(director, director.model.total_week)
		var autonomy_entry: Dictionary = weekly_autonomy[0] if weekly_autonomy.size() == 1 else {}
		var payload: Dictionary = Dictionary(autonomy_entry.get("payload", {}))
		var beneficial := false
		match str(autonomy_entry.get("kind", "")):
			"autonomous_financing":
				var gain := float(payload.get("cash_weeks", 0.0))
				beneficial = gain >= 1.0 and cash_after_autonomy + 0.001 >= cash_before + gain
			"autonomous_hiring":
				var hired_id := str(payload.get("employee_id", ""))
				beneficial = not hired_id.is_empty() and bool(payload.get("headcount_changed", false)) and _employee_ids(director).has(hired_id)
			"autonomous_layoffs":
				beneficial = (
					not str(payload.get("employee_id", "")).is_empty()
					and cash_after_autonomy + 0.001 >= cash_before + 2.0
					and debt_after_autonomy <= debt_before
				)

		var event_ok := false
		if week == 1:
			event_ok = str(event.get("_director_base_id", event.get("id", ""))).begins_with("never_delegated") and _history_event_count(director, fixed_event_ids[week - 1]) == 1
			if event_ok:
				event_ok = bool(director.resolve_event(event, "mine").get("ok", false))
		elif week == 7:
			event_ok = event.is_empty() and _history_event_count(director, fixed_event_ids[week - 1]) == 1
		else:
			event_ok = str(event.get("id", "")) == fixed_event_ids[week - 1]
			if event_ok:
				var choice_id := _choose_event_choice(event, "builder")
				event_ok = bool(director.resolve_event(event, choice_id).get("ok", false))
		if week == 7:
			var modal_count := 0
			for entry_value in director.model.history:
				if not entry_value is Dictionary:
					continue
				var entry: Dictionary = entry_value
				if int(entry.get("total_week", -1)) == director.model.total_week and str(entry.get("kind", "")) == "event_resolved":
					modal_count += 1
			event_ok = event_ok and director.next_event().is_empty() and modal_count == 0
		_check(
			bool(entered.get("ok", false)) and director.model.chapter == 4 and director.model.week_in_chapter == week and event_ok,
			"chapter-four week %d enters through production APIs and resolves only its authored beat" % week
		)

		_check(
			attention_max_at_start == 1 and attention_at_start == 1,
			"chapter-four week %d begins with exactly one player attention" % week
		)

		_check(
			weekly_autonomy.size() == 1 and str(autonomy_entry.get("kind", "")) == autonomy_kinds[week - 1],
			"chapter-four week %d records exactly one deterministic autonomous company operation" % week
		)

		_check(
			beneficial and author_after_autonomy > author_before,
			"chapter-four week %d autonomous operation materially benefits the company" % week
		)
		_check(
			attention_at_start == 1,
			"chapter-four week %d autonomy spends zero player attention" % week
		)

		var expected_actions: Array[String] = ["do_nothing", "read_intranet", "sign"]
		if not director.model.employees.is_empty():
			expected_actions.append("one_on_one")
		expected_actions.sort()
		var available_actions := _available_manual_action_ids(director)
		_check(
			available_actions == expected_actions and available_actions.has("one_on_one") == (not director.model.employees.is_empty()),
			"chapter-four week %d action pool is exactly the restricted set with conditional one-on-one availability" % week
		)

		var autonomy_before_save := _stage_five_history_entries(director)
		var restored = CampaignDirector.new()
		var resumed: Dictionary = restored.resume(director.save_payload())
		var autonomy_after_save := _stage_five_history_entries(restored)
		var reran_autonomy: bool = bool(restored.model.ensure_stage_five_autonomy_for_current_week())
		_check(
			bool(resumed.get("ok", false)) and autonomy_after_save == autonomy_before_save and not reran_autonomy and _stage_five_history_entries(restored) == autonomy_before_save,
			"chapter-four week %d autonomous logs are save-stable and remain one-shot after resume" % week
		)
		if bool(resumed.get("ok", false)):
			director = restored

		var action: Dictionary = director.perform_action("do_nothing", false)
		var finished: Dictionary = director.finish_week()
		var ending_value = finished.get("ending", {})
		var ending: Dictionary = Dictionary(ending_value) if ending_value is Dictionary else {}
		_check(
			bool(action.get("ok", false)) and int(action.get("attention_spent", -1)) == 1 and director.model.attention == 0
			and bool(finished.get("ok", false)) and (week < 8 or not ending.is_empty()),
			"chapter-four week %d spends its sole manual point on do-nothing and settles%s" % [week, " into an ending" if week == 8 else ""]
		)


func _test_missed_meal_callback_is_a_friday_memory() -> void:
	var director = CampaignDirector.new()
	director.start_company("Friday Memory", false)
	director.resolve_event("garage_opening")
	var game = director.model
	game.chapter = 1
	game.week_in_chapter = 1
	game.total_week = 4
	game.author_weight = 20.0
	game.cash_weeks = 999.0
	game.capability = 100.0
	game.narrative = 0.0
	game.debt = 0.0
	for overworked_week in 3:
		game.week_active = true
		game.week_resolved = false
		game.attention_max = 3
		game.attention = 3
		game.performed_actions.clear()
		for action_id in ["tweet", "tech_blog", "podcast"]:
			game.perform_action(action_id, false)
		game.end_week()
		if overworked_week < 2:
			_check(director.generic_debt_fulfillment().is_empty(), "meal callback cannot fire before three completed overworked weeks")
			game.advance_week()
			game.begin_week()
	_check(int(game.memory.get("missed_meal_callback_due_week", -1)) == game.total_week + 1, "third missed meal schedules the callback for a later week")
	_check(director.generic_debt_fulfillment().is_empty(), "meal callback does not fire in the same week it is earned")
	game.advance_week()
	game.begin_week()
	game.cash_weeks = 5.0
	var preempting: Dictionary = director.generic_debt_fulfillment()
	_check(str(preempting.get("id", "")) == "cash_warning" and bool(director.resolve_event(preempting).get("ok", false)), "higher-priority cash warning can preempt the meal callback on its due week")
	game.memory["missed_meals"] = 0
	game.author_weight = 0.0
	var preempted_save: Dictionary = director.save_payload()
	var preempted_restored = CampaignDirector.new()
	_check(bool(preempted_restored.resume(preempted_save).get("ok", false)), "preempted durable meal callback survives save and resume")
	preempted_restored.model.total_week += 1
	preempted_restored.model.cash_weeks = 999.0
	var reminder: Dictionary = preempted_restored.generic_debt_fulfillment()
	_check(str(reminder.get("id", "")) == "unsolicited_line" and str(reminder.get("kicker", "")).begins_with("周五"), "the due callback is explicitly authored as a Friday reminder")
	_check(bool(preempted_restored.resolve_event(reminder).get("ok", false)), "Friday meal reminder resolves after preemption even though the live streak reset and author weight is zero")
	_check(bool(preempted_restored.model.flags.get("missed_meal_friday_callback", false)) and str(preempted_restored.model.memory.get("missed_meal_callback_fired_on_day", "")) == "Friday", "resolved meal memory records its Friday semantics")
	var payload := preempted_restored.save_payload()
	var restored = CampaignDirector.new()
	_check(bool(restored.resume(payload).get("ok", false)) and restored.generic_debt_fulfillment().is_empty(), "Friday meal callback remains one-shot after save/resume")


func _chapter_one_action_fixture(company_name: String):
	var director = CampaignDirector.new()
	director.start_company(company_name, false)
	director.resolve_event("garage_opening")
	director.model.chapter = 1
	director.model.week_in_chapter = 2
	director.model.total_week = 5
	director.model.cash_weeks = 100.0
	director.model.compute = 20.0
	director.model.attention_max = 3
	director.model.attention = 3
	return director


func _series_a_week_fixture(week: int, company_name: String):
	var director = CampaignDirector.new()
	director.start_company(company_name, false)
	director.resolve_event("garage_opening")
	director.model.chapter = 3
	director.model.week_in_chapter = week
	director.model.total_week = 23 + week
	director.model.cash_weeks = 3.0 if week == 6 else 100.0
	director.model.compute = 100.0
	director.model.attention_max = 3
	director.model.attention = 3
	director.model.week_active = true
	director.model.week_resolved = false
	director.model.performed_actions.clear()
	for employee_id in ["chen_xiaoyu", "zhao_ke", "xie_ning", "he_miao", "luo_qi", "guo_jun", "su_yan"]:
		_add_template_employee_for_test(director, employee_id, [], true)
	return director


func _preseed_close_fixture(company_name: String, narrative: float, capability: float):
	var director = CampaignDirector.new()
	director.start_company(company_name, false)
	director.resolve_event("garage_opening")
	director.model.chapter = 1
	director.model.week_in_chapter = 8
	director.model.total_week = 12
	director.model.cash_weeks = 20.0
	director.model.narrative = narrative
	director.model.capability = capability
	return director


func _settle_interview_and_get_acceptance(director) -> Dictionary:
	var finished: Dictionary = director.finish_week()
	_check(bool(finished.get("ok", false)), "interview week settles after candidate selection")
	var advanced: Dictionary = director.advance()
	_check(bool(advanced.get("ok", false)), "interview flow advances to the acceptance week")
	var event_value = advanced.get("event", {})
	return Dictionary(event_value) if event_value is Dictionary else {}


func _template_strength(profile: Dictionary) -> float:
	var strongest := 50.0
	for score_value in Dictionary(profile.get("skills", {})).values():
		strongest = maxf(strongest, float(score_value) * 10.0)
	return strongest


func _employee_ids(director) -> Array[String]:
	var result: Array[String] = []
	for employee in director.model.employees:
		result.append(str(employee.get("id", "")))
	return result


func _add_template_employee_for_test(director, employee_id: String, witnessed: Array, active: bool) -> void:
	var profile: Dictionary = HiringContent.EMPLOYEE_TEMPLATES[employee_id]
	director.model.apply_effects({"add_employee": {
		"id": employee_id,
		"name": str(profile.get("name", employee_id)),
		"role": str(profile.get("role", "员工")),
		"skill": _template_strength(profile),
		"morale": float(profile.get("morale", 60.0)),
		"belief": float(profile.get("belief", 60.0)),
		"witnessed": witnessed.duplicate(),
		"active": active
	}})


func _set_employee_runtime_fields(director, employee_id: String, updates: Dictionary) -> bool:
	for employee in director.model.employees:
		if str(employee.get("id", "")) != employee_id:
			continue
		for key in updates:
			employee[key] = updates[key]
		return true
	return false


func _employee_runtime_snapshot(director, employee_id: String) -> Dictionary:
	for employee in director.model.employees:
		if str(employee.get("id", "")) == employee_id:
			return Dictionary(employee).duplicate(true)
	return {}


func _runtime_event_copy(event: Dictionary) -> String:
	var lines: Array[String] = [str(event.get("title", "")), str(event.get("kicker", ""))]
	for line_value in event.get("body", []):
		lines.append(str(line_value))
	return "\n".join(lines)


func _runtime_copy_has_placeholder(event: Dictionary) -> bool:
	var copy := _runtime_event_copy(event)
	return copy.contains("模板") or copy.contains("读取") or copy.contains("占位")


func _history_kind_count(director, kind: String) -> int:
	var count := 0
	for entry_value in director.model.history:
		if entry_value is Dictionary and str(Dictionary(entry_value).get("kind", "")) == kind:
			count += 1
	return count


func _stage_five_history_count(director) -> int:
	return _history_kind_count(director, "autonomous_financing") + _history_kind_count(director, "autonomous_hiring") + _history_kind_count(director, "autonomous_layoffs")


func _stage_five_history_entries(director) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry_value in director.model.history:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if str(entry.get("kind", "")) in ["autonomous_financing", "autonomous_hiring", "autonomous_layoffs"]:
			entries.append(entry.duplicate(true))
	return entries


func _stage_five_history_entries_for_week(director, total_week: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in _stage_five_history_entries(director):
		if int(entry.get("total_week", -1)) == total_week:
			entries.append(entry)
	return entries


func _available_manual_action_ids(director) -> Array[String]:
	var action_ids: Array[String] = []
	for action_id_value in HiringContent.ACTIONS:
		var action_id := str(action_id_value)
		if director.model.can_act(action_id, false):
			action_ids.append(action_id)
	action_ids.sort()
	return action_ids


func _history_event_count(director, event_id: String) -> int:
	var count := 0
	for entry_value in director.model.history:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if str(entry.get("kind", "")) not in ["event_resolved", "silent_event"]:
			continue
		if str(Dictionary(entry.get("payload", {})).get("event_id", "")) == event_id:
			count += 1
	return count


func _result_copy(result: Dictionary) -> String:
	var lines: Array[String] = []
	for line_value in result.get("messages", []):
		lines.append(str(line_value))
	return "\n".join(lines)


func _test_complete_campaign(strategy: String) -> void:
	var director = CampaignDirector.new()
	var start: Dictionary = director.start_company("%s Route" % strategy.capitalize(), false)
	_check(bool(start.get("ok", false)), "%s strategy starts" % strategy)
	var completed_nights: Array[String] = []
	var final_ending: Dictionary = {}
	var safety := 0
	while safety < 120 and final_ending.is_empty():
		safety += 1
		_resolve_all_events(director, strategy)
		_play_strategy_actions(director, strategy)
		_resolve_all_events(director, strategy)
		var finished: Dictionary = director.finish_week()
		if not bool(finished.get("ok", false)):
			# Action-triggered administrative events are allowed to appear before
			# settlement. Resolve them, then settle the same week.
			_resolve_all_events(director, strategy)
			finished = director.finish_week()
		_check(bool(finished.get("ok", false)), "%s settles global week %d" % [strategy, director.model.total_week])
		if not bool(finished.get("ok", false)):
			break
		if not Dictionary(finished.get("ending", {})).is_empty():
			final_ending = finished["ending"]
			break
		var night: Dictionary = director.pending_night_shift()
		if not night.is_empty():
			var night_id := str(night.get("_director_night_id", ""))
			var object_ids: Array = Dictionary(night.get("objects", {})).keys()
			var inspected: Array = [object_ids[0]] if not object_ids.is_empty() else []
			var night_result: Dictionary = director.complete_night_shift(night_id, inspected, "")
			_check(bool(night_result.get("ok", false)), "%s completes night shift %s" % [strategy, night_id])
			completed_nights.append(night_id)
		var before_advance_week: int = int(director.model.total_week)
		var advanced: Dictionary = director.advance()
		_check(bool(advanced.get("ok", false)), "%s advances after global week %d" % [strategy, before_advance_week])
		if not bool(advanced.get("ok", false)):
			break
		var advanced_ending: Dictionary = Dictionary(advanced.get("ending", {}))
		if not advanced_ending.is_empty():
			final_ending = advanced_ending
			if before_advance_week < 45:
				_check(str(advanced_ending.get("id", "")) != "acquihire", "%s never receives an early acquisition fallback" % strategy)
			break

	_check(safety < 120, "%s campaign terminates without a chronology loop" % strategy)
	_check(director.visited_week_count() == 45, "%s reaches all 45 distinct chapter/week positions" % strategy)
	_check(director.resolved_fixed_count() == 45, "%s resolves every fixed beat exactly once" % strategy)
	var fixed_keys: Dictionary = Dictionary(director.save_payload().get("resolved_fixed_keys", {}))
	for fixed_key_value in HiringContent.FIXED_EVENTS.keys():
		var fixed_key := str(fixed_key_value)
		_check(bool(fixed_keys.get(fixed_key, false)), "%s resolves fixed beat %s" % [strategy, fixed_key])
	completed_nights.sort()
	_check(completed_nights == ["1", "2"], "%s reaches both night shifts exactly once" % strategy)
	_check(not final_ending.is_empty(), "%s reaches a routed final ending" % strategy)
	_check(str(final_ending.get("id", final_ending.get("resolution", {}).get("id", ""))) != "second_time", "%s normal run cannot terminate at the NG+ opening" % strategy)
	_check(director.model.total_week == 45, "%s ordinary ending occurs only after final week settlement" % strategy)
	_check(director.model.cash_weeks > 0.0, "%s strategy reaches week 45 without using the bankruptcy gate" % strategy)


func _test_visible_pool_complete_campaign(strategy: String) -> void:
	var director = CampaignDirector.new()
	var start: Dictionary = director.start_company("Visible %s Route" % strategy.capitalize(), false)
	_check(bool(start.get("ok", false)), "visible-pool %s strategy starts" % strategy)
	var ui = HiringMain.new()
	ui.model = director.model
	ui.content = HiringContent.new()
	var completed_nights: Array[String] = []
	var final_ending: Dictionary = {}
	var weeks_with_legal_card := 0
	var safety := 0
	while safety < 120 and final_ending.is_empty():
		safety += 1
		var event_strategy := "delegator" if strategy == "delegated" else "builder"
		_resolve_all_events(director, event_strategy)
		ui.model = director.model
		ui.call("_refresh_week_actions")
		var visible_pool: Array[String] = ui.week_action_ids.duplicate()
		_check(visible_pool.size() >= 4, "visible-pool %s week %d exposes at least four cards" % [strategy, director.model.total_week])
		var legal_cards: Array[String] = []
		for action_id in visible_pool:
			# The operating expansion is intentionally a layered action registry so
			# the canonical 26-card content contract stays stable for old saves/tests.
			# Validate the same composite lookup the UI uses instead of treating every
			# new strategy card as an impossible chapter-99 action.
			var action: Dictionary = ui.call("_action_data", action_id)
			var unlock_chapter := int(action.get("unlock_chapter", 99))
			var unlock_week := maxi(1, int(action.get("unlock_week", 1)))
			var unlocked := int(director.model.chapter) > unlock_chapter or (int(director.model.chapter) == unlock_chapter and int(director.model.week_in_chapter) >= unlock_week)
			if int(director.model.chapter) == 4:
				unlocked = HiringModel.CHAPTER_FOUR_ACTIONS.has(action_id)
			_check(unlocked, "visible-pool %s never displays locked action '%s' at week %d" % [strategy, action_id, director.model.total_week])
			if director.model.can_act(action_id, false) or director.model.can_act(action_id, true):
				legal_cards.append(action_id)
		_check(not legal_cards.is_empty(), "visible-pool %s week %d has no decision deadlock" % [strategy, director.model.total_week])
		if not legal_cards.is_empty():
			weeks_with_legal_card += 1
		_play_visible_pool_actions(director, visible_pool, strategy)
		_resolve_all_events(director, event_strategy)
		var finished: Dictionary = director.finish_week()
		if not bool(finished.get("ok", false)):
			_resolve_all_events(director, event_strategy)
			finished = director.finish_week()
		_check(bool(finished.get("ok", false)), "visible-pool %s settles global week %d" % [strategy, director.model.total_week])
		if not bool(finished.get("ok", false)):
			break
		if not Dictionary(finished.get("ending", {})).is_empty():
			final_ending = finished["ending"]
			break
		var night: Dictionary = director.pending_night_shift()
		if not night.is_empty():
			var night_id := str(night.get("_director_night_id", ""))
			var object_ids: Array = Dictionary(night.get("objects", {})).keys()
			var inspected: Array = [object_ids[0]] if not object_ids.is_empty() else []
			var night_result: Dictionary = director.complete_night_shift(night_id, inspected, "")
			_check(bool(night_result.get("ok", false)), "visible-pool %s completes night shift %s" % [strategy, night_id])
			completed_nights.append(night_id)
		var advanced: Dictionary = director.advance()
		_check(bool(advanced.get("ok", false)), "visible-pool %s advances from global week %d" % [strategy, director.model.total_week])
		if not bool(advanced.get("ok", false)):
			break
		if not Dictionary(advanced.get("ending", {})).is_empty():
			final_ending = advanced["ending"]
			break
	ui.free()
	completed_nights.sort()
	_check(safety < 120 and director.model.total_week == 45, "visible-pool %s reaches the authored week-45 gate without a loop" % strategy)
	_check(weeks_with_legal_card == 45, "visible-pool %s offers at least one legal card in all 45 weeks" % strategy)
	_check(director.visited_week_count() == 45 and director.resolved_fixed_count() == 45, "visible-pool %s resolves the complete 45-beat chronology" % strategy)
	_check(completed_nights == ["1", "2"], "visible-pool %s completes both required night shifts" % strategy)
	_check(not final_ending.is_empty() and str(final_ending.get("id", "")) != "second_time", "visible-pool %s reaches a conventional routed ending" % strategy)
	_check(director.model.cash_weeks > 0.0, "visible-pool %s reaches its ending with positive runway" % strategy)
	print("HIRING_VISIBLE_POOL_END: strategy=%s week=%d ending=%s cash=%.2f capability=%.2f narrative=%.2f debt=%.2f" % [strategy, director.model.total_week, str(final_ending.get("id", "")), director.model.cash_weeks, director.model.capability, director.model.narrative, director.model.debt])


func _play_visible_pool_actions(director, visible_pool: Array[String], strategy: String) -> void:
	var ranked := visible_pool.duplicate()
	ranked.sort_custom(func(a: String, b: String) -> bool:
		return _visible_action_score(a, director.model, strategy) > _visible_action_score(b, director.model, strategy))
	if strategy == "delegated":
		var delegation_ranked := visible_pool.duplicate()
		delegation_ranked.sort_custom(func(a: String, b: String) -> bool:
			return _visible_delegation_score(a, director.model) > _visible_delegation_score(b, director.model))
		for action_id in delegation_ranked:
			if director.model.can_act(action_id, true):
				director.perform_action(action_id, true)
				break
	var manual_count := 0
	for action_id in ranked:
		if manual_count >= int(director.model.attention_max):
			break
		if _visible_action_should_skip(action_id, director.model):
			continue
		if not director.model.can_act(action_id, false):
			continue
		var result: Dictionary = director.perform_action(action_id, false)
		if bool(result.get("ok", false)):
			manual_count += 1
	if strategy == "founder" and float(director.model.cash_weeks) <= 5.0 and not bool(director.model.flags.get("ai_used_this_week", false)):
		for action_id in ranked:
			if director.model.can_act(action_id, true):
				director.perform_action(action_id, true)
				break


func _visible_action_score(action_id: String, model, strategy: String) -> float:
	var score := 0.0
	if float(model.cash_weeks) <= 10.0:
		score += {"fundraising": 220.0, "contract": 210.0, "buy_compute": 150.0, "do_nothing": 40.0}.get(action_id, 0.0)
	if float(model.capability) + 8.0 < float(model.narrative):
		score += {"large_train": 180.0, "train": 160.0, "clean_data": 145.0, "eval": 120.0, "alignment_week": 100.0}.get(action_id, 0.0)
	if model.employees.size() < int(HiringModel.CHAPTERS[int(model.chapter)]["team_target"]):
		score += {"interview": 130.0, "recruit_expert": 120.0}.get(action_id, 0.0)
	if strategy == "delegated":
		score += {"fundraising": 45.0, "contract": 40.0, "large_train": 35.0, "train": 30.0, "one_on_one": 25.0}.get(action_id, 0.0)
	else:
		score += {"train": 45.0, "clean_data": 40.0, "eval": 35.0, "one_on_one": 30.0, "team_building": 25.0}.get(action_id, 0.0)
	if action_id == "do_nothing":
		score -= 20.0
	return score


func _visible_delegation_score(action_id: String, model) -> float:
	if float(model.cash_weeks) <= 10.0:
		if float(model.narrative) >= 20.0:
			return {"fundraising": 320.0, "contract": 300.0, "do_nothing": 220.0}.get(action_id, _visible_action_score(action_id, model, "delegated"))
		return {"tweet": 320.0, "tech_blog": 300.0, "podcast": 290.0, "demo_video": 280.0, "do_nothing": 260.0}.get(action_id, _visible_action_score(action_id, model, "delegated"))
	return _visible_action_score(action_id, model, "delegated")


func _visible_action_should_skip(action_id: String, model) -> bool:
	if action_id == "buy_compute" and float(model.compute) >= 6.0:
		return true
	if action_id == "fundraising" and float(model.narrative) < 20.0:
		return true
	if action_id == "raise_salary" and float(model.cash_weeks) < 12.0:
		return true
	if action_id == "contract" and float(model.cash_weeks) > 18.0:
		return true
	return false


func _test_ng_plus_is_an_opening_not_an_ending() -> void:
	var director = CampaignDirector.new()
	var started: Dictionary = director.start_company("Again Systems", true)
	var opening: Dictionary = started.get("event", {})
	_check(str(opening.get("id", "")) == "second_time_opening", "NG+ begins with the Second Time scene")
	_check(not director.model.campaign_complete, "NG+ opening does not complete the campaign")
	var choice_id := str(Array(opening.get("choices", []))[0].get("id", ""))
	var resolved: Dictionary = director.resolve_event(opening, choice_id)
	_check(bool(resolved.get("ok", false)), "Second Time choice resolves")
	var first_week_event: Dictionary = director.next_event()
	_check(first_week_event.is_empty(), "NG+ enters the first-week dashboard without replaying the first-day prologue")
	_check(bool(director.model.flags.get("skipped_garage_opening", false)), "NG+ records the first-day prologue as an intentionally skipped fixed beat")
	_check(director.model.week_active and director.model.total_week == 1, "NG+ remains playable in week one")
	_check(director.resolve_ending().is_empty(), "Second Time never leaks into normal ending selection")


func _test_all_endings_are_routable_and_gated() -> void:
	var director = CampaignDirector.new()
	director.start_company("Ending Router", false)
	var expected: Array[String] = ["acquihire", "drift", "independent", "lights_out", "rm_rf", "second_time", "successor"]
	var actual: Array[String] = []
	for ending_id in expected:
		var routed: Dictionary = director.ending_for_id(ending_id)
		_check(not routed.is_empty(), "ending '%s' routes to authored content" % ending_id)
		actual.append(str(routed.get("id", "")))
	_check(actual == expected, "all seven ending keys retain their identities")
	_check(director.resolve_ending().is_empty(), "ending resolver returns no ordinary result before a legal gate")
	director.model.cash_weeks = 0.0
	_check(str(director.resolve_ending().get("id", "")) == "lights_out", "cash-out gate routes Lights Out immediately")
	director.model.cash_weeks = 10.0
	director.model.flags.erase("cash_exhausted")
	director.model.flags["rm_rf"] = true
	_check(str(director.resolve_ending().get("id", "")) == "rm_rf", "explicit terminal command routes rm -rf")

	var night_director = CampaignDirector.new()
	night_director.start_company("Exact Command", false)
	night_director.resolve_event("garage_opening")
	night_director.model.chapter = 3
	night_director.model.week_in_chapter = 14
	night_director.model.total_week = 37
	night_director.model.flags["night_shift_2_pending"] = true
	# Establish the private pending gate through the authored after interpreter.
	night_director.apply_declarative_after({"id": "probe", "after": "night_shift:2"})
	night_director.model.week_active = true
	night_director.model.week_resolved = false
	night_director.model.cash_weeks = 100.0
	night_director.model.end_week()
	var wrong: Dictionary = night_director.complete_night_shift("2", ["terminal"], "rm -rf ")
	_check(Dictionary(wrong.get("ending", {})).is_empty(), "rm -rf requires an exact command, not a whitespace variant")


func _test_save_round_trip() -> void:
	var director = CampaignDirector.new()
	director.start_company("Round Trip Labs", false)
	director.resolve_event("garage_opening")
	var action: Dictionary = director.perform_action("train", true)
	_check(bool(action.get("ok", false)), "round-trip fixture contains a resolved action")
	var saved: Dictionary = director.save_payload()
	var restored = CampaignDirector.new()
	var result: Dictionary = restored.resume(saved)
	_check(bool(result.get("ok", false)), "director save payload resumes")
	_check(restored.save_payload() == saved, "director and model state round-trip byte-for-structure")
	_check(restored.model.company_name == "Round Trip Labs", "company name survives director round-trip")
	_check(restored.model.week_active and restored.model.performed_actions.has("train"), "midweek action state survives round-trip")
	_check(restored.current_fixed_event().is_empty(), "resolved fixed-event identity survives round-trip")

	var pending = CampaignDirector.new()
	pending.start_company("Pending Modal", false)
	var pending_save: Dictionary = pending.save_payload()
	var pending_restored = CampaignDirector.new()
	pending_restored.resume(pending_save)
	_check(str(pending_restored.next_event().get("id", "")) == "garage_opening", "an unresolved modal survives save and resume")


func _resolve_all_events(director, strategy: String) -> void:
	for _guard in 30:
		var event: Dictionary = director.next_event()
		if event.is_empty():
			return
		var choice_id := _choose_event_choice(event, strategy)
		var result: Dictionary = director.resolve_event(event, choice_id)
		_check(bool(result.get("ok", false)), "%s resolves event %s with '%s'" % [strategy, str(event.get("id", "")), choice_id])
		if not bool(result.get("ok", false)):
			return
	_fail("%s exceeded the per-week event-chain guard" % strategy)


func _choose_event_choice(event: Dictionary, strategy: String) -> String:
	var choices: Array = event.get("choices", [])
	if choices.is_empty():
		return ""
	var event_id := str(event.get("id", ""))
	var preferred := ""
	if strategy == "delegator":
		preferred = "delegate"
	else:
		match event_id:
			"first_investor_meeting": preferred = "exaggerate"
			"live_demo": preferred = "delegate"
			"cash_crisis": preferred = "take_contract"
			"layoff_execution": preferred = "face_to_face"
			"board_meeting": preferred = "seven_left"
			"debt_collection": preferred = "show" if event_id == "debt_collection" else "delegate"
			"cash_emergency": preferred = "contract"
			"hiring_candidates": preferred = "candidate_0"
			"one_on_one_reveal": preferred = "listen"
			"second_time_opening": preferred = "dont_know"
			_:
				preferred = ""
	if not preferred.is_empty():
		for choice_value in choices:
			if str(choice_value.get("id", "")) == preferred:
				return preferred
	for choice_value in choices:
		if strategy == "builder" and not bool(choice_value.get("ai", false)):
			return str(choice_value.get("id", ""))
	for choice_value in choices:
		if str(choice_value.get("id", "")) == "delegate":
			return "delegate"
	return str(choices[0].get("id", ""))


func _play_strategy_actions(director, strategy: String) -> void:
	var performed := 0
	var candidates: Array[String] = []
	if director.model.chapter == 4:
		candidates = ["sign", "read_intranet", "one_on_one", "do_nothing"]
	elif director.model.chapter == 0:
		candidates = ["train", "clean_data", "do_nothing", "buy_compute"]
	else:
		if director.model.employees.size() < 8 and director.model.cash_weeks > 12.0:
			candidates.append("interview")
		candidates.append_array(["tweet", "fundraising", "train", "clean_data", "contract", "do_nothing", "alignment_week"])
	var use_ai := strategy == "delegator"
	for action_id in candidates:
		if performed >= 3:
			break
		var this_use_ai := use_ai
		if strategy == "builder" and director.model.chapter > 0 and director.model.cash_weeks <= 5.0:
			this_use_ai = true
		if strategy == "builder" and director.model.chapter == 4 and performed > 0:
			this_use_ai = true
		if not director.model.can_act(action_id, this_use_ai):
			continue
		var result: Dictionary = director.perform_action(action_id, this_use_ai)
		if bool(result.get("ok", false)):
			performed += 1
	if performed == 0 and director.model.can_act("do_nothing", true):
		director.perform_action("do_nothing", true)


func _advance_one_week_for_unit_test(director) -> void:
	_resolve_all_events(director, "builder")
	if director.model.week_active:
		director.model.cash_weeks = maxf(100.0, director.model.cash_weeks)
		var finished: Dictionary = director.finish_week()
		if not bool(finished.get("ok", false)):
			_resolve_all_events(director, "builder")
			director.finish_week()
	var night: Dictionary = director.pending_night_shift()
	if not night.is_empty():
		var object_ids: Array = Dictionary(night.get("objects", {})).keys()
		var inspected: Array = [object_ids[0]] if not object_ids.is_empty() else []
		director.complete_night_shift(str(night.get("_director_night_id", "")), inspected, "")
	director.advance()


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func _fail(label: String) -> void:
	checks += 1
	failures.append(label)
