extends SceneTree

const HiringModel = preload("res://src/hiring_model.gd")
const CampaignDirector = preload("res://src/hiring_director.gd")
const HiringEventScheduler = preload("res://src/hiring_event_scheduler.gd")
const HiringExpansionContent = preload("res://src/hiring_expansion_content.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	var model_script: Script = load("res://src/hiring_model.gd")
	var director_script: Script = load("res://src/hiring_director.gd")
	if model_script == null or director_script == null or not model_script.can_instantiate() or not director_script.can_instantiate():
		push_error("HIRING_EXPANSION_INTEGRATION_TEST_FAILURE: model/director dependency did not compile")
		quit(1)
		return
	_test_strategy_unlock_and_requisition_action()
	_test_strategy_card_advances_recruiting_pipeline()
	_test_recruiting_vertical_slice_reaches_formal_roster()
	_test_financing_cap_table_through_model_public_state()
	_test_authoritative_cash_ledger_and_single_stage_financing()
	_test_annual_prepaid_cash_is_not_charged_twice()
	_test_market_state_changes_launch_conversion()
	_test_runtime_state_event_lane()
	_test_visible_company_settlement_and_milestones()
	_test_operating_action_gates_prevent_noop_spend()
	_test_policy_payoff_and_system_receipt()
	_test_employee_option_lifecycle_bridge()
	_test_authored_system_scheduler_seed_and_resume()
	_test_director_system_event_resume_boundary()
	_test_nested_public_state_and_model_save_round_trip()

	if failures.is_empty():
		print("HIRING_EXPANSION_INTEGRATION_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_EXPANSION_INTEGRATION_TEST_FAILURE: " + failure)
		print("HIRING_EXPANSION_INTEGRATION_TESTS_FAIL: %d failures / %d checks" % [failures.size(), checks])
		quit(1)


func _test_strategy_unlock_and_requisition_action() -> void:
	for action_id_value in HiringExpansionContent.SYSTEM_ACTIONS:
		var action_id := str(action_id_value)
		var spec: Dictionary = HiringExpansionContent.SYSTEM_ACTIONS[action_id]
		var unlock_chapter := int(spec.get("unlock_chapter", 99))
		var unlock_week := maxi(1, int(spec.get("unlock_week", 1)))
		var before = _calendar_model(unlock_chapter, maxi(1, unlock_week - 1))
		if unlock_week > 1:
			_check(not before.can_act(action_id), "%s stays locked before its authored week" % action_id)
		var available = _calendar_model(unlock_chapter, unlock_week)
		_check(available.can_act(action_id), "%s unlocks from the expansion action registry" % action_id)

	var game = _calendar_model(1, 2)
	var operation_before: Dictionary = game.operations.public_state()
	var action: Dictionary = game.perform_action("open_requisition", false)
	_check(bool(action.get("ok", false)), "strategy action resolves through HiringModel.perform_action")
	_check(bool(game.flags.get("expansion_systems_unlocked", false)), "first strategy action durably unlocks systemic events")
	_check(str(game.memory.get("last_expansion_action", "")) == "open_requisition", "model remembers the concrete strategy action")
	var operation_after: Dictionary = game.public_state().get("operations", {})
	_check(int(operation_after.get("open_requisitions", 0)) == int(operation_before.get("open_requisitions", 0)) + 1, "requisition action creates one real operations requisition")
	_check(int(operation_after.get("active_candidates", 0)) > 0, "requisition action materializes a candidate pipeline instead of adding headcount")
	var public_pipeline: Array = Array(operation_after.get("candidate_pipeline", []))
	_check(not public_pipeline.is_empty() and not str(Dictionary(public_pipeline[0]).get("name", "")).is_empty(), "public operations state retains the named candidate rather than only a funnel count")
	_check(not str(Dictionary(public_pipeline[0]).get("competing_company", "")).is_empty(), "public candidate state retains the named talent competitor")
	_check(game.employees.size() == 1, "opening a requisition does not instantly create an employee")


func _test_recruiting_vertical_slice_reaches_formal_roster() -> void:
	# Keep total_week at one while moving the authored chapter clock forward. This
	# isolates the recruiting timeline and lets candidate offer deadlines retain
	# their intended relative meaning.
	var game = _calendar_model(1, 2)
	game.cash_weeks = 100.0
	var baseline_employee_count: int = int(game.employees.size())
	var opened: Dictionary = game.perform_action("open_requisition", false)
	_check(bool(opened.get("ok", false)), "vertical slice opens its requisition through the strategy card")
	_check(not game.operations.requisitions.is_empty(), "model-owned operations system retains the requisition")
	if game.operations.requisitions.is_empty():
		return

	var requisition: Dictionary = Dictionary(game.operations.requisitions.back())
	var candidate_ids: Array = Array(requisition.get("candidate_ids", []))
	_check(not candidate_ids.is_empty(), "requisition carries stable candidate ids")
	if candidate_ids.is_empty():
		return
	var candidate_id := str(candidate_ids[0])
	var dossier_before: Dictionary = game.operations.candidate_dossier(candidate_id)
	_check(not dossier_before.is_empty() and str(dossier_before.get("status", "")) == "in_process", "selected candidate has an in-process dossier")
	_check(not str(dossier_before.get("current_company", "")).is_empty(), "candidate dossier exposes a concrete current employer")
	_check(Dictionary(dossier_before.get("competing_offer", {})).has("deadline_week"), "candidate dossier exposes a competing-offer deadline")

	for stage in ["screen", "work_sample", "panel"]:
		var interview: Dictionary = game.operations.apply_decision("interview_candidate", {
			"candidate_id": candidate_id,
			"stage": stage,
		})
		_check(bool(interview.get("ok", false)), "%s interview stage resolves" % stage)
	var dossier_after: Dictionary = game.operations.candidate_dossier(candidate_id)
	_check(Array(dossier_after.get("unknowns", [])).is_empty(), "structured loop resolves the candidate's explicit unknowns")
	_check(Dictionary(dossier_after.get("scorecard_results", {})).size() >= 4, "structured loop records a complete role scorecard")

	var competing: Dictionary = dossier_after.get("competing_offer", {})
	var salary := maxf(float(dossier_after.get("salary_target", 0.0)), float(competing.get("salary", 0.0))) + 40.0
	var equity := maxf(float(dossier_after.get("equity_target_bps", 0.0)), float(competing.get("equity_bps", 0.0))) + 30.0
	var issued: Dictionary = game.operations.apply_decision("issue_offer", {
		"candidate_id": candidate_id,
		"salary": salary,
		"equity_bps": equity,
		"level": maxi(3, int(requisition.get("level", 2))),
		"title": str(dossier_after.get("role_title", "关键岗位")),
		"team_id": str(requisition.get("team_id", "founders")),
		"manager_id": "lin_yue",
		"allow_out_of_band": true,
	}, {"company_credibility": 1.0, "manager_quality": 1.0, "role_scope": 1.0})
	_check(bool(issued.get("ok", false)), "fully evidenced candidate receives a concrete offer")
	_check(float(Dictionary(issued.get("offer", {})).get("acceptance_score", 0.0)) >= 0.78, "competitive terms reach the deterministic acceptance tier")

	# The model owns the formal roster boundary: offers and notice periods remain
	# in operations until end-of-week settlement consumes a due pending join.
	var joined_id := "hire_%s" % candidate_id
	var settled_weeks := 0
	while not _model_has_employee(game, joined_id) and settled_weeks < 12:
		if game.week_active and not game.week_resolved:
			var ended: Dictionary = game.end_week()
			_check(bool(ended.get("ok", false)), "operating week %d settles" % settled_weeks)
		if _model_has_employee(game, joined_id):
			break
		var advanced: Dictionary = game.advance_week()
		_check(bool(advanced.get("ok", false)) and not bool(advanced.get("campaign_complete", false)), "recruiting timeline advances without ending the campaign")
		var began: Dictionary = game.begin_week()
		_check(bool(began.get("ok", false)), "next recruiting week begins")
		settled_weeks += 1

	_check(_model_has_employee(game, joined_id), "accepted candidate joins the model-owned formal roster after notice")
	_check(game.employees.size() == baseline_employee_count + 1, "formal roster grows exactly once")
	var joined := _model_employee(game, joined_id)
	_check(is_equal_approx(float(joined.get("salary_annual", 0.0)), salary), "formal employee preserves negotiated salary")
	_check(is_equal_approx(float(joined.get("equity_bps", 0.0)), equity), "formal employee preserves negotiated equity")
	_check(float(joined.get("ramp", 1.0)) < 1.0, "new employee enters a visible onboarding ramp")
	var operations_state: Dictionary = game.public_state().get("operations", {})
	_check(int(operations_state.get("active_employees", 0)) == game.employees.size(), "operations roster and narrative roster agree after joining")
	_check(int(operations_state.get("scheduled_joins", -1)) == 0 and int(operations_state.get("pending_joins", -1)) == 0, "joined candidate leaves no duplicate notice or pending record")
	var cap_table: Dictionary = Dictionary(Dictionary(game.public_state().get("business", {})).get("capital", {})).get("cap_table", {})
	_check(_cap_table_has_owner(cap_table, joined_id), "new hire's negotiated equity becomes an option holder")


func _test_strategy_card_advances_recruiting_pipeline() -> void:
	var game = _calendar_model(1, 2)
	game.total_week = 5
	game.operations.sync_employee_roster(game.employees, game.total_week)
	var expected_phases := ["requisition", "interview", "interview", "interview", "offer"]
	var selected_candidate := ""
	for index in expected_phases.size():
		var action: Dictionary = game.perform_action("open_requisition", false)
		_check(bool(action.get("ok", false)), "strategy recruiting step %d resolves through the normal action card" % index)
		var operating: Dictionary = game.memory.get("last_operating_action_result", {})
		_check(str(operating.get("phase", "")) == str(expected_phases[index]), "strategy recruiting step %d reaches %s" % [index, expected_phases[index]])
		_check(not str(game.memory.get("last_operating_action_summary", "")).is_empty(), "strategy recruiting step %d returns a player-facing receipt" % index)
		if index == 0:
			selected_candidate = str(operating.get("candidate_name", ""))
			var dossier: Dictionary = operating.get("candidate_dossier", {})
			_check(int(dossier.get("deadline_week", 0)) > game.total_week + 4, "competing-offer deadline is materialized relative to the real campaign week")
		else:
			_check(str(operating.get("candidate_name", "")) == selected_candidate, "the strategy card advances the same named candidate through the funnel")
		if index >= expected_phases.size() - 1:
			break
		var ended: Dictionary = game.end_week()
		_check(bool(ended.get("ok", false)), "strategy recruiting step %d settles its week" % index)
		var advanced: Dictionary = game.advance_week()
		_check(bool(advanced.get("ok", false)), "strategy recruiting step %d advances the campaign" % index)
		var began: Dictionary = game.begin_week()
		_check(bool(began.get("ok", false)), "strategy recruiting step %d begins the next week" % index)
	var final_result: Dictionary = game.memory.get("last_operating_action_result", {})
	var offer: Dictionary = final_result.get("offer", {})
	_check(not offer.is_empty() and str(offer.get("status", "")) == "pending", "normal strategy play reaches a real pending offer")


func _test_financing_cap_table_through_model_public_state() -> void:
	var game = HiringModel.new()
	game.reset("North Ledger")
	game.narrative = 62.0
	var cash_before := int(Dictionary(game.public_state()["business"])["ledger"]["cash_usd"])
	var safe: Dictionary = game.business.apply_decision("raise_preseed", "clean", {
		"transaction_id": "integration:preseed",
		"total_week": 4,
		"narrative": game.narrative,
	})
	_check(bool(safe.get("ok", false)) and str(safe.get("instrument", "")) == "post_money_safe", "pre-seed closes as a post-money SAFE")
	var after_safe: Dictionary = game.public_state()["business"]
	_check(int(Dictionary(after_safe["ledger"])["cash_usd"]) > cash_before, "financing proceeds enter the model's public USD ledger")
	_check(Array(Dictionary(Dictionary(after_safe["capital"])["cap_table"])["outstanding_safe_estimates"]).size() == 1, "public cap table discloses the outstanding SAFE estimate")

	var seed: Dictionary = game.business.apply_decision("raise_seed", "clean", {
		"transaction_id": "integration:seed",
		"total_week": 15,
		"narrative": game.narrative,
	})
	_check(bool(seed.get("ok", false)) and str(seed.get("instrument", "")) == "priced_round", "Seed closes as a priced preferred round")
	var public_business: Dictionary = game.public_state()["business"]
	var public_capital: Dictionary = public_business["capital"]
	var table: Dictionary = public_capital["cap_table"]
	_check(Array(public_capital.get("rounds", [])).size() == 1, "priced financing appears in public round history")
	_check(Array(table.get("outstanding_safe_estimates", [])).is_empty(), "priced round visibly converts the outstanding SAFE")
	_check(_cap_basis_points(table) == 10_000, "public cap-table ownership sums to exactly one hundred percent")
	_check(_cap_owner_basis_points(table, "founder") < 5_000, "founder dilution is visible after external capital")
	_check(_cap_table_has_owner(table, "juniper_ventures"), "priced investor appears as a durable cap-table owner")
	_check(Array(public_business.get("investors", [])).size() == 4, "named investor relationship layer remains available after financing")


func _test_authoritative_cash_ledger_and_single_stage_financing() -> void:
	var game = _calendar_model(1, 3)
	var activated: Dictionary = game.perform_action("product_launch", false)
	_check(bool(activated.get("ok", false)) and game.uses_authoritative_financial_ledger(), "first strategy action makes the exact USD ledger authoritative")
	var cash_after_activation := int(game.business.ledger.get("cash_usd", 0))
	var burn_after_activation := maxi(1, int(game.business.weekly_burn_usd()))
	_check(is_equal_approx(game.cash_weeks, float(cash_after_activation) / float(burn_after_activation)), "legacy cash_weeks becomes a derived compatibility value")
	game.narrative = 62.0
	var first_raise: Dictionary = game.perform_action("fundraising", false)
	_check(bool(first_raise.get("ok", false)), "fundraising closes once through normal action play")
	var cash_after_raise := int(game.business.ledger.get("cash_usd", 0))
	var safe_count := Array(game.business.capital.get("safes", [])).size()
	var repeat_raise: Dictionary = game.record_business_financing("preseed", "clean", "integration:repeat_preseed")
	_check(bool(repeat_raise.get("ok", false)), "a repeated same-stage meeting resolves without corrupting the campaign")
	_check(int(game.business.ledger.get("cash_usd", 0)) == cash_after_raise and Array(game.business.capital.get("safes", [])).size() == safe_count, "same financing stage cannot mint cash or dilution twice")
	var runway_unit := maxi(1, int(game.business.weekly_burn_usd()))
	game.apply_effects({"cash_weeks": -1.0})
	_check(int(game.business.ledger.get("cash_usd", 0)) == maxi(0, cash_after_raise - runway_unit), "legacy runway effects translate into an explicit USD transaction")
	game.business.ledger["cash_usd"] = 0
	game.call("_sync_legacy_runway_from_business")
	_check(game.cash_weeks == 0.0 and bool(game.flags.get("cash_exhausted", false)), "zero USD cash is authoritative even if a stale legacy runway value was positive")


func _test_annual_prepaid_cash_is_not_charged_twice() -> void:
	var game = _calendar_model(2, 4)
	game.call("_activate_financial_ledger_authority")
	var subscribed: Dictionary = game.operations.apply_decision("subscribe_saas", {"service_id": "quietwire_annual", "auto_renew": false}, {"week": game.total_week})
	_check(bool(subscribed.get("ok", false)) and str(subscribed.get("billing", "")) == "annual_prepaid", "annual SaaS exposes its prepaid cash timing")
	game.call("_record_operations_cash_due", subscribed, "saas", "quietwire_annual")
	game.call("_sync_operating_roster")
	var weekly_costs: Dictionary = game.business.ledger.get("weekly_costs", {})
	_check(int(weekly_costs.get("vendors", 0)) == 1500, "annual SaaS amortization is excluded from recurring cash vendors")
	var cash_before := int(game.business.ledger.get("cash_usd", 0))
	var weekly_cash_cost := int(game.business.weekly_cost_usd())
	var prepaid_usd := int(round(float(subscribed.get("cash_due", 0.0)) * 1000.0))
	var ended: Dictionary = game.end_week()
	_check(bool(ended.get("ok", false)), "prepayment fixture settles through the model week boundary")
	_check(int(game.business.ledger.get("cash_usd", 0)) == maxi(0, cash_before - weekly_cash_cost - prepaid_usd), "annual SaaS deducts one prepayment plus ordinary weekly cash costs, never weekly amortization again")


func _test_market_state_changes_launch_conversion() -> void:
	var weak_market = _calendar_model(2, 4)
	var strong_market = _calendar_model(2, 4)
	weak_market.business.market["category_demand"] = 20
	weak_market.business.market["price_pressure_bp"] = 7000
	strong_market.business.market["category_demand"] = 90
	strong_market.business.market["price_pressure_bp"] = 12_000
	var weak_result: Dictionary = weak_market.perform_action("product_launch", false)
	var strong_result: Dictionary = strong_market.perform_action("product_launch", false)
	var weak_operating: Dictionary = weak_market.memory.get("last_operating_action_result", {})
	var strong_operating: Dictionary = strong_market.memory.get("last_operating_action_result", {})
	_check(bool(weak_result.get("ok", false)) and bool(strong_result.get("ok", false)), "market comparison launches both products through the same player action")
	_check(int(strong_operating.get("customer_gain", 0)) > int(weak_operating.get("customer_gain", 0)), "demand and price pressure materially change customer conversion")
	_check(int(strong_operating.get("mrr_gain_usd", 0)) > int(weak_operating.get("mrr_gain_usd", 0)), "shared market state materially changes launch revenue")


func _test_runtime_state_event_lane() -> void:
	var director = CampaignDirector.new()
	director.model.reset("Stateful Inbox")
	director.model.chapter = 2
	director.model.week_in_chapter = 5
	director.model.total_week = 16
	director.model.cash_weeks = 50.0
	director.model.flags["expansion_systems_unlocked"] = true
	director.model.begin_week()
	director._resolved_fixed_keys["2:5"] = true
	var event: Dictionary = director.call("_next_systemic_event")
	_check(not event.is_empty() and bool(event.get("_runtime_state_event", false)), "real subsystem candidate is materialized into the shared scheduler lane")
	_check(str(event.get("_runtime_source_system", "")) == "business", "chapter-two policy opportunity retains its business-system identity")
	var choices: Array = Array(event.get("choices", []))
	_check(not choices.is_empty(), "runtime event freezes actionable choices into its save-stable snapshot")
	if not choices.is_empty():
		var choice_id := str(Dictionary(choices[0]).get("id", ""))
		var resolved: Dictionary = director.resolve_event(event, choice_id)
		_check(bool(resolved.get("ok", false)), "runtime state event resolves through the ordinary director choice boundary")
		_check(not Dictionary(director.model.memory.get("last_systemic_event", {})).is_empty(), "runtime choice writes a durable systemic-event audit record")
	_check(Dictionary(director.call("_next_systemic_event")).is_empty(), "operating inbox enforces one runtime side decision per campaign week")


func _test_visible_company_settlement_and_milestones() -> void:
	var game = _calendar_model(2, 4)
	var launched: Dictionary = game.perform_action("product_launch", false)
	_check(bool(launched.get("ok", false)), "settlement fixture launches a real product")
	var settled: Dictionary = game.end_week()
	var lines: Array = Array(settled.get("lines", []))
	_check(bool(settled.get("ok", false)) and not lines.is_empty(), "strategy-enabled week returns player-visible company settlement lines")
	_check("经营结算" in "\n".join(lines), "weekly result exposes exact gross profit, cost, cash movement, and runway")
	_check("里程碑" in "\n".join(lines), "first paid-customer or MRR threshold becomes an earned milestone instead of a silent state change")
	_check(Array(game.memory.get("company_milestone_ids", [])).has("first_customer"), "earned company milestone is durable in the save model")
	_check(not str(game.memory.get("last_operating_action_summary", "")).is_empty(), "latest internal tape receives the system settlement result")


func _test_operating_action_gates_prevent_noop_spend() -> void:
	var policy_game = _calendar_model(2, 5)
	_check(bool(policy_game.perform_action("policy_program", false).get("ok", false)), "policy gate fixture submits the grant once")
	policy_game.performed_actions.clear()
	policy_game.attention = policy_game.attention_max
	var policy_status: Dictionary = policy_game.operating_action_status("policy_program")
	_check(not bool(policy_status.get("available", true)) and not policy_game.can_act("policy_program"), "resolved grant disables the action before attention can be spent twice")

	var people_game = _calendar_model(2, 4)
	_check(bool(people_game.perform_action("org_review", false).get("ok", false)), "people gate fixture starts one real training plan")
	people_game.performed_actions.clear()
	people_game.attention = people_game.attention_max
	_check(not people_game.can_act("org_review") and "进行" in str(people_game.operating_action_status("org_review").get("reason", "")), "active training presents an explicit wait state instead of a no-op card")

	var office_game = _calendar_model(2, 4)
	_check(bool(office_game.perform_action("office_plan", false).get("ok", false)), "office gate fixture signs one concrete lease")
	office_game.performed_actions.clear()
	office_game.attention = office_game.attention_max
	_check(not office_game.can_act("office_plan") and "搬入" in str(office_game.operating_action_status("office_plan").get("reason", "")), "signed lease disables duplicate office work while move-in is pending")


func _test_policy_payoff_and_system_receipt() -> void:
	var director = CampaignDirector.new()
	director.model.reset("Policy Payoff")
	director.model.chapter = 4
	director.model.week_in_chapter = 5
	director.model.total_week = 42
	director.model.cash_weeks = 100.0
	director.model.flags["expansion_systems_unlocked"] = true
	for index in 6:
		director.model.call("_add_employee", {
			"id": "policy_staff_%d" % index,
			"name": "政策团队 %d" % (index + 1),
			"role": "Policy Operations",
			"skill": 60,
			"morale": 70,
			"belief": 70,
		})
	director.model.business.policy["coalition_member"] = true
	director.model.begin_week()
	director._resolved_fixed_keys["4:5"] = true
	var event: Dictionary = director.call("_next_systemic_event")
	_check(str(event.get("id", "")) == "industry_standard_draft", "qualified coalition work is guaranteed a final-chapter policy payoff")
	var resolution: Dictionary = director.resolve_event(event, "sign_with_amendment")
	var system_result: Dictionary = resolution.get("system_result", {})
	_check(bool(resolution.get("ok", false)) and bool(system_result.get("ok", false)), "policy payoff resolves through the shared event boundary and returns its real system result")
	_check(str(director.model.business.policy.get("standard_draft_status", "")) == "submitted", "standard choice mutates durable policy state rather than only prose stats")
	_check(not str(system_result.get("receipt", "")).is_empty() and str(system_result.get("receipt", "")) in "\n".join(Array(resolution.get("result", []))), "result page appends the exact operating receipt")
	_check(Dictionary(director.call("_next_systemic_event")).is_empty(), "guaranteed payoff consumes the same one-decision weekly UX budget")


func _test_employee_option_lifecycle_bridge() -> void:
	var game = _calendar_model(1, 3)
	_check(bool(game.perform_action("product_launch", false).get("ok", false)), "option bridge fixture activates the authoritative company ledger")
	game.call("_add_employee", {
		"id": "option_hire",
		"name": "周晴",
		"role": "Product Engineer",
		"skill": 72,
		"morale": 74,
		"belief": 78,
		"equity_bps": 20.0,
		"joined_week": game.total_week,
	})
	var holders: Dictionary = game.business.capital.get("holders", {})
	var holder: Dictionary = holders.get("option:option_hire", {})
	_check(int(holder.get("shares", 0)) > 0, "employee equity promise creates one real cap-table option grant")
	var pool_before_departure := int(Dictionary(holders.get("option_pool", {})).get("shares", 0))
	game.total_week += 20
	var departed: Dictionary = game.call("_remove_employee_by_id", "option_hire", "voluntary_departure")
	var settlement: Dictionary = departed.get("option_settlement", {})
	_check(bool(settlement.get("ok", false)) and int(settlement.get("vested_shares", -1)) == 0, "departure before the cliff settles vesting through the model boundary")
	_check(int(Dictionary(game.business.capital["holders"].get("option_pool", {})).get("shares", 0)) > pool_before_departure, "unvested options return to the shared pool exactly once")


func _test_authored_system_scheduler_seed_and_resume() -> void:
	var templates: Array[Dictionary] = HiringExpansionContent.event_templates()
	_check(templates.size() >= 36, "integration scheduler consumes the full authored systemic event catalog")
	var options := {
		"recent_limit": 4,
		"actor_cooldown_weeks": 2,
		"aging_per_week": 2,
		"opportunity_permille": 1000,
		"pity_start_weeks": 2,
		"pity_step_permille": 210,
	}
	var context := {
		"opportunity_permille": 1000,
		"flags": {"expansion_systems_unlocked": true},
		"actors": {
			"maya_chen": {"id": "maya_chen", "name": "Maya Chen", "firm": "Juniper Ventures"},
			"morrow": {"id": "morrow", "name": "Morrow AI"},
			"chorus": {"id": "chorus", "name": "Chorus Systems"},
			"harbor": {"id": "harbor", "name": "HarborDesk"},
		},
		"tokens": {"company_name": "Deterministic Works", "runway_weeks": "17"},
	}
	var first = HiringEventScheduler.new()
	var same_seed = HiringEventScheduler.new()
	first.reset(92317, options)
	same_seed.reset(92317, options)
	var first_plan: Dictionary = first.plan_week(10, 2, templates, context)
	var same_plan: Dictionary = same_seed.plan_week(10, 2, templates, context)
	_check(bool(first_plan.get("ok", false)) and str(first_plan.get("status", "")) == "selected", "authored catalog yields an event at guaranteed opportunity")
	_check(first_plan == same_plan and first.to_save() == same_seed.to_save(), "fixed seed materializes the identical authored event and scheduler state")
	var frozen_event: Dictionary = first_plan.get("event", {})
	_check(Array(frozen_event.get("choices", [])).size() == 3, "materialized systemic decision freezes all three authored choices")
	_check(not str(frozen_event.get("_scheduler_instance_id", "")).is_empty(), "materialized event receives a stable instance identity")

	for week in range(11, 14):
		first.plan_week(week, 2, templates, context)
	var checkpoint: Dictionary = first.to_save()
	var restored = HiringEventScheduler.new()
	var loaded: Dictionary = restored.load_save(checkpoint)
	_check(bool(loaded.get("ok", false)), "system scheduler checkpoint loads")
	_check(restored.to_save() == checkpoint, "system scheduler checkpoint round-trips byte-for-structure")
	for week in range(14, 21):
		var left_plan: Dictionary = first.plan_week(week, 2, templates, context, week == 17)
		var right_plan: Dictionary = restored.plan_week(week, 2, templates, context, week == 17)
		_check(left_plan == right_plan, "week %d systemic selection is deterministic after resume" % week)
		while first.has_due_event(week) or restored.has_due_event(week):
			_check(first.pop_next(week) == restored.pop_next(week), "week %d due-event order survives resume" % week)
		_check(first.to_save() == restored.to_save(), "week %d complete scheduler state survives resume" % week)


func _test_director_system_event_resume_boundary() -> void:
	var director = _configured_systemic_director()
	var checkpoint: Dictionary = director.save_payload()
	var resumed = CampaignDirector.new()
	var resume_result: Dictionary = resumed.resume(checkpoint)
	_check(bool(resume_result.get("ok", false)), "director resumes a strategy-enabled campaign")
	var resumed_checkpoint: Dictionary = resumed.save_payload()
	_check(resumed_checkpoint == checkpoint, "director/model/scheduler checkpoint is byte-for-structure stable before polling (%s)" % _first_difference(checkpoint, resumed_checkpoint))
	var left_event: Dictionary = director.next_event()
	var right_event: Dictionary = resumed.next_event()
	_check(not left_event.is_empty(), "pity-guaranteed director poll produces a systemic event")
	_check(left_event == right_event, "director emits the same materialized systemic event after resume")
	_check(str(left_event.get("_director_source", "")) == "systemic", "director labels the overlay event with its systemic source")
	_check(Array(left_event.get("choices", [])).size() == 3, "director preserves authored systemic choices")
	var left_after_poll: Dictionary = director.save_payload()
	var right_after_poll: Dictionary = resumed.save_payload()
	_check(left_after_poll == right_after_poll, "post-poll pending event and scheduler state remain identical (%s)" % _first_difference(left_after_poll, right_after_poll))


func _test_nested_public_state_and_model_save_round_trip() -> void:
	var game = _calendar_model(2, 4)
	game.cash_weeks = 80.0
	_check(bool(game.perform_action("office_plan", false).get("ok", false)), "office strategy action resolves before save")
	_check(bool(game.perform_action("vendor_review", false).get("ok", false)), "vendor strategy action attaches a concrete SaaS subscription through the model boundary")
	_check(bool(game.business.apply_decision("raise_preseed", "delegate", {
		"transaction_id": "integration:save:preseed",
		"total_week": game.total_week,
		"narrative": 58,
	}).get("ok", false)), "capital state is nontrivial before save")
	var state_before: Dictionary = game.public_state()
	_check(state_before.has("business") and state_before.has("operations"), "model public state exposes both nested simulation systems")
	_check(Array(Dictionary(state_before["operations"]).get("subscriptions", [])).size() >= 1, "public operations state includes subscribed SaaS")
	var active_lease: Dictionary = game.operations.office.get("active_lease", {})
	var signed_lease: Dictionary = game.operations.office.get("signed_lease", {})
	_check(not active_lease.is_empty() or not signed_lease.is_empty(), "operations state retains the selected lease through its signed/move-in lifecycle")

	var saved: Dictionary = game.to_save()
	_check(saved.has("business_system") and saved.has("operations_system"), "model save contains both nested system payloads")
	var restored = HiringModel.new()
	_check(restored.from_save(saved), "model restores a nontrivial nested simulation save")
	var state_after: Dictionary = restored.public_state()
	var saved_after: Dictionary = restored.to_save()
	_check(state_after == state_before, "nested business and operations public state is identical after restore (%s)" % _first_difference(state_before, state_after))
	_check(saved_after == saved, "full model save round-trips byte-for-structure (%s)" % _first_difference(saved, saved_after))


func _calendar_model(chapter: int, week_in_chapter: int):
	var game = HiringModel.new()
	game.reset("Integrated Works")
	game.chapter = clampi(chapter, 0, HiringModel.CHAPTERS.size() - 1)
	game.week_in_chapter = clampi(week_in_chapter, 1, int(HiringModel.CHAPTERS[game.chapter]["weeks"]))
	# The chapter/week pair controls content unlocks; total_week intentionally
	# starts at one so subsystem deadlines can be exercised without a time skip.
	game.total_week = 1
	game.cash_weeks = 100.0
	game.compute = 100.0
	game.narrative = 60.0
	game.capability = 60.0
	game.coherence = 100.0
	var began: Dictionary = game.begin_week()
	_check(bool(began.get("ok", false)), "integration fixture begins chapter %d week %d" % [chapter, week_in_chapter])
	return game


func _configured_systemic_director():
	var director = CampaignDirector.new()
	director.model.reset("Resume Systems")
	director.model.chapter = 2
	director.model.week_in_chapter = 2
	director.model.total_week = 14
	director.model.cash_weeks = 100.0
	director.model.flags["expansion_systems_unlocked"] = true
	director.model.begin_week()
	# Match the nested operating clock before taking the checkpoint; resume is not
	# responsible for repairing an artificially time-skipped fixture.
	director.model.call("_sync_operating_roster")
	director.call("_record_visited_week")
	# This fixture is specifically about the overlay lane, so consume the authored
	# fixed-beat identity without resolving unrelated story effects.
	director._resolved_fixed_keys["2:2"] = true
	var scheduler_save: Dictionary = director._event_scheduler.to_save()
	scheduler_save["weeks_without_optional_event"] = 10
	director._event_scheduler.load_save(scheduler_save)
	return director


func _model_has_employee(game, employee_id: String) -> bool:
	for employee_value in game.employees:
		if employee_value is Dictionary and str(Dictionary(employee_value).get("id", "")) == employee_id:
			return true
	return false


func _model_employee(game, employee_id: String) -> Dictionary:
	for employee_value in game.employees:
		if employee_value is Dictionary and str(Dictionary(employee_value).get("id", "")) == employee_id:
			return Dictionary(employee_value)
	return {}


func _cap_table_has_owner(table: Dictionary, owner_id: String) -> bool:
	for row_value in Array(table.get("rows", [])):
		if row_value is Dictionary and str(Dictionary(row_value).get("owner_id", "")) == owner_id:
			return true
	return false


func _cap_owner_basis_points(table: Dictionary, owner_id: String) -> int:
	for row_value in Array(table.get("rows", [])):
		if row_value is Dictionary and str(Dictionary(row_value).get("owner_id", "")) == owner_id:
			return int(Dictionary(row_value).get("ownership_bp", 0))
	return 0


func _cap_basis_points(table: Dictionary) -> int:
	var total := 0
	for row_value in Array(table.get("rows", [])):
		if row_value is Dictionary:
			total += int(Dictionary(row_value).get("ownership_bp", 0))
	return total


func _first_difference(left: Variant, right: Variant, path: String = "root") -> String:
	if typeof(left) != typeof(right):
		return "%s type %s != %s" % [path, type_string(typeof(left)), type_string(typeof(right))]
	if left is Dictionary:
		var left_dict: Dictionary = left
		var right_dict: Dictionary = right
		var left_keys: Array = left_dict.keys()
		var right_keys: Array = right_dict.keys()
		left_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		right_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		if left_keys != right_keys:
			return "%s keys %s != %s" % [path, str(left_keys), str(right_keys)]
		for key_value in left_keys:
			var child_path := "%s.%s" % [path, str(key_value)]
			var difference := _first_difference(left_dict[key_value], right_dict[key_value], child_path)
			if not difference.is_empty():
				return difference
		return ""
	if left is Array:
		var left_array: Array = left
		var right_array: Array = right
		if left_array.size() != right_array.size():
			return "%s size %d != %d" % [path, left_array.size(), right_array.size()]
		for index in left_array.size():
			var difference := _first_difference(left_array[index], right_array[index], "%s[%d]" % [path, index])
			if not difference.is_empty():
				return difference
		return ""
	if left != right:
		return "%s %s != %s" % [path, str(left), str(right)]
	return ""


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
