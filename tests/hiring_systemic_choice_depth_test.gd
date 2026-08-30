extends SceneTree

const HiringModel = preload("res://src/hiring_model.gd")
const HiringExpansionContent = preload("res://src/hiring_expansion_content.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	var model_script: Script = load("res://src/hiring_model.gd")
	if model_script == null or not model_script.can_instantiate():
		push_error("HIRING_SYSTEMIC_CHOICE_DEPTH_TEST_FAILURE: HiringModel did not compile")
		quit(1)
		return
	_test_jobs_commitment_changes_policy_ledger()
	_test_candidate_counteroffer_changes_offer_terms()
	_test_title_inflation_survives_closed_focus()
	_test_promotion_choice_changes_people_system()
	_test_identity_plan_changes_procurement_state()
	_test_competitor_response_changes_unit_economics()
	_test_office_shortlist_changes_lease_commitment()
	_test_office_capacity_event_respects_inflight_replacement()
	_test_capital_diligence_and_board_governance_persist()
	_test_lease_trade_and_sublease_change_operations()

	if failures.is_empty():
		print("HIRING_SYSTEMIC_CHOICE_DEPTH_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_SYSTEMIC_CHOICE_DEPTH_TEST_FAILURE: " + failure)
		print("HIRING_SYSTEMIC_CHOICE_DEPTH_TESTS_FAIL: %d failures / %d checks" % [failures.size(), checks])
		quit(1)


func _test_jobs_commitment_changes_policy_ledger() -> void:
	var baseline = _fixture(2, 18)
	var modest = _clone_model(baseline, "jobs commitment modest branch restores from the common snapshot")
	var headline = _clone_model(baseline, "jobs commitment headline branch restores from the common snapshot")
	var event := _event_template("jobs_tax_credit")
	var cash_before := int(baseline.business.ledger.get("cash_usd", 0))
	var modest_result: Dictionary = modest.resolve_systemic_event(event, "modest_commitment")
	var headline_result: Dictionary = headline.resolve_systemic_event(event, "headline_commitment")

	_check(bool(modest_result.get("ok", false)) and bool(headline_result.get("ok", false)), "both jobs-credit choices resolve through the systemic boundary")
	_check(int(modest.business.policy.get("job_commitment", 0)) == 12, "modest policy choice records the promised twelve jobs")
	_check(int(headline.business.policy.get("job_commitment", 0)) == 40, "headline policy choice records the promised forty jobs")
	_check(int(modest.business.policy.get("investment_commitment_usd", 0)) == 900_000, "modest policy choice retains its smaller investment covenant")
	_check(int(headline.business.policy.get("investment_commitment_usd", 0)) == 3_000_000, "headline policy choice retains its larger investment covenant")
	_check(int(modest.business.policy.get("deferred_tax_credit_usd", 0)) == 180_000, "modest commitment produces the smaller deferred credit")
	_check(int(headline.business.policy.get("deferred_tax_credit_usd", 0)) == 500_000, "headline commitment produces the larger deferred credit")
	_check(int(modest.business.ledger.get("cash_usd", 0)) == cash_before and int(headline.business.ledger.get("cash_usd", 0)) == cash_before, "a deferred tax credit never masquerades as current cash")


func _test_candidate_counteroffer_changes_offer_terms() -> void:
	var baseline = _candidate_offer_fixture()
	var original_offer := _pending_offer(baseline)
	_check(not original_offer.is_empty(), "candidate fixture contains one pending negotiated offer")
	if original_offer.is_empty():
		return
	var original_terms: Dictionary = original_offer.get("terms", {})
	var original_salary := float(original_terms.get("salary", 0.0))
	var original_score := float(original_offer.get("acceptance_score", 0.0))
	var scope = _clone_model(baseline, "candidate scope branch restores from the common offer snapshot")
	var cash = _clone_model(baseline, "candidate cash branch restores from the common offer snapshot")
	var event := _event_template("candidate_counteroffer")
	var scope_result: Dictionary = scope.resolve_systemic_event(event, "increase_scope")
	var cash_result: Dictionary = cash.resolve_systemic_event(event, "increase_cash")
	var scope_offer := _pending_offer(scope)
	var cash_offer := _pending_offer(cash)
	var scope_terms: Dictionary = scope_offer.get("terms", {})
	var cash_terms: Dictionary = cash_offer.get("terms", {})

	_check(bool(scope_result.get("ok", false)) and bool(cash_result.get("ok", false)), "both counteroffer choices mutate the live candidate offer")
	_check(is_equal_approx(float(scope_terms.get("salary", 0.0)), original_salary), "scope negotiation preserves the cash salary")
	_check(int(scope_terms.get("scope_review_week", -1)) == scope.total_week + 26, "scope negotiation writes a six-month review into durable offer terms")
	_check(float(cash_terms.get("salary", 0.0)) > original_salary, "cash negotiation raises the durable salary commitment")
	_check(not cash_terms.has("scope_review_week"), "cash negotiation does not silently grant the scope-review covenant")
	_check(float(scope_offer.get("acceptance_score", 0.0)) > original_score and float(cash_offer.get("acceptance_score", 0.0)) > float(scope_offer.get("acceptance_score", 0.0)), "the two negotiations produce distinct acceptance improvements")
	_check(scope.operations.to_save() != cash.operations.to_save(), "candidate choices diverge in serialized operations state")


func _test_title_inflation_survives_closed_focus() -> void:
	var game = _candidate_offer_fixture()
	var offer := _pending_offer(game)
	_check(not offer.is_empty(), "title-calibration fixture begins with a live offer")
	if offer.is_empty():
		return
	var candidate_id := str(offer.get("candidate_id", ""))
	offer["acceptance_score"] = 1.0
	offer["response_week"] = game.total_week + 1
	var tick: Dictionary = game.operations.tick_week({
		"week": game.total_week + 1,
		"company_credibility": 0.80,
		"manager_quality": 0.80,
		"role_scope": 0.80,
	})
	_check(not Array(tick.get("outcomes", [])).is_empty(), "weekly operations boundary resolves the fixture offer")
	_check(str(offer.get("status", "")) == "accepted", "title-calibration fixture retains an accepted offer")
	_check(str(game.call("_first_focus_candidate_id")) == "", "accepted offer closes the requisition focus before the delayed title decision")

	var result: Dictionary = game.resolve_systemic_event(_event_template("title_inflation"), "principal_track")
	var candidate: Dictionary = game.operations.candidates.get(candidate_id, {})
	var terms: Dictionary = offer.get("terms", {})
	var scheduled: Dictionary = game.operations.scheduled_joins[0] if not game.operations.scheduled_joins.is_empty() else {}
	var scheduled_employee: Dictionary = scheduled.get("employee", {})
	_check(bool(result.get("ok", false)), "materialized title decision follows the accepted candidate after its focus cursor closes")
	_check(str(result.get("candidate_id", "")) == candidate_id and not bool(result.get("opened_requisition", true)), "title decision reuses the real accepted offer instead of inventing a replacement candidate")
	_check(str(candidate.get("title_model", "")) == "principal_ic" and str(candidate.get("role_title", "")).begins_with("Principal "), "principal branch persists the calibrated candidate title")
	_check(str(terms.get("title_model", "")) == "principal_ic" and str(terms.get("title", "")) == str(candidate.get("role_title", "")), "accepted offer terms receive the same calibrated title")
	_check(str(scheduled_employee.get("role", "")) == str(candidate.get("role_title", "")), "already-materialized join record receives the title before onboarding")


func _test_promotion_choice_changes_people_system() -> void:
	var baseline = _fixture(3, 25)
	baseline.call("_add_employee", {
		"id": "chen_xiaoyu", "name": "陈小雨", "role": "数据工程师", "skill": 90,
		"level": 3, "salary_annual": 62.0, "equity_bps": 4.0,
		"morale": 72, "belief": 82, "team_id": "founders", "manager_id": "lin_yue",
	})
	var baseline_level := int(Dictionary(baseline.operations.employees.get("chen_xiaoyu", {})).get("level", 0))
	var defer = _clone_model(baseline, "promotion deferral branch restores from the common employee snapshot")
	var promote = _clone_model(baseline, "promotion approval branch restores from the common employee snapshot")
	var event := _event_template("promotion_calibration")
	var defer_result: Dictionary = defer.resolve_systemic_event(event, "defer_with_scope")
	var promote_result: Dictionary = promote.resolve_systemic_event(event, "promote_on_judgment")
	var deferred_employee: Dictionary = defer.operations.employees.get("chen_xiaoyu", {})
	var promoted_employee: Dictionary = promote.operations.employees.get("chen_xiaoyu", {})

	_check(bool(defer_result.get("ok", false)) and bool(promote_result.get("ok", false)), "both promotion-calibration choices resolve against the named employee")
	_check(int(deferred_employee.get("level", 0)) == baseline_level, "deferral keeps the employee at the current level")
	_check(_has_active_training(defer, "chen_xiaoyu"), "deferral creates a concrete evidence-building development plan")
	_check(int(promoted_employee.get("level", 0)) == baseline_level + 1, "promotion persists the employee's next level in operations state")
	_check(float(promoted_employee.get("salary_annual", 0.0)) > float(deferred_employee.get("salary_annual", 0.0)), "promotion persists its higher payroll commitment")
	_check(float(promoted_employee.get("equity_bps", 0.0)) > float(deferred_employee.get("equity_bps", 0.0)), "promotion persists its equity refresh")
	_check(not _has_active_training(promote, "chen_xiaoyu"), "immediate promotion does not also create the deferral training plan")
	_check(defer.operations.to_save() != promote.operations.to_save(), "promotion choices diverge in serialized people-operations state")


func _test_identity_plan_changes_procurement_state() -> void:
	var baseline = _fixture(2, 18)
	var manual = _clone_model(baseline, "manual identity-control branch restores from the common procurement snapshot")
	var upgrade = _clone_model(baseline, "identity upgrade branch restores from the common procurement snapshot")
	var event := _event_template("identity_plan_wall")
	var manual_result: Dictionary = manual.resolve_systemic_event(event, "manual_controls")
	var upgrade_result: Dictionary = upgrade.resolve_systemic_event(event, "upgrade")

	_check(bool(manual_result.get("ok", false)) and bool(upgrade_result.get("ok", false)), "both identity-control choices resolve through procurement")
	_check(bool(manual.operations.office.get("manual_identity_review", false)), "manual path records the recurring offboarding control")
	_check(not manual.operations.subscriptions.has("quietwire_annual"), "manual path avoids silently purchasing the enterprise plan")
	_check(upgrade.operations.subscriptions.has("quietwire_annual"), "upgrade path creates the real QuietWire annual subscription")
	var subscription: Dictionary = upgrade.operations.subscriptions.get("quietwire_annual", {})
	_check(str(Dictionary(subscription.get("spec", {})).get("billing", "")) == "annual_prepaid", "upgrade path retains annual-prepayment contract timing")
	_check(not bool(upgrade.operations.office.get("manual_identity_review", false)), "upgrade path does not also claim the manual-control workflow")
	_check(Dictionary(upgrade.business.ledger.get("commitments", {})).size() > Dictionary(manual.business.ledger.get("commitments", {})).size(), "upgrade path adds a real cash commitment to the business ledger")
	_check(manual.operations.to_save() != upgrade.operations.to_save(), "manual and purchased identity controls diverge in serialized operations state")


func _test_competitor_response_changes_unit_economics() -> void:
	var baseline = _fixture(2, 18)
	var hold = _clone_model(baseline, "hold-price branch restores from the common market snapshot")
	var match_price = _clone_model(baseline, "match-price branch restores from the common market snapshot")
	var event := _event_template("harbor_price_cut")
	var margin_before := int(baseline.business.ledger.get("gross_margin_bp", 0))
	var pressure_before := int(baseline.business.market.get("price_pressure_bp", 0))
	var hold_result: Dictionary = hold.resolve_systemic_event(event, "hold_price")
	var match_result: Dictionary = match_price.resolve_systemic_event(event, "match_price")

	_check(bool(hold_result.get("ok", false)) and bool(match_result.get("ok", false)), "both HarborDesk responses resolve against the durable competitor actor")
	_check(int(hold.business.market.get("price_pressure_bp", 0)) == pressure_before - 500 and int(match_price.business.market.get("price_pressure_bp", 0)) == pressure_before - 500, "the rival price cut reaches market pressure regardless of response")
	_check(int(hold.business.ledger.get("gross_margin_bp", 0)) == margin_before, "holding price preserves gross-margin basis points")
	_check(int(match_price.business.ledger.get("gross_margin_bp", 0)) == margin_before - 500, "matching the rival records the gross-margin sacrifice")
	_check(str(Dictionary(match_price.business.market.get("competitors", {})).get("harbor_desk", {}).get("last_strategy", "")) == "harbor_price_cut", "competitor state remembers the concrete market move")
	_check(hold.business.to_save() != match_price.business.to_save(), "competitor responses diverge in serialized business state")


func _test_office_shortlist_changes_lease_commitment() -> void:
	var baseline = _fixture(2, 18)
	var flexible = _clone_model(baseline, "flexible-office branch restores from the common shortlist snapshot")
	var capacity = _clone_model(baseline, "capacity-office branch restores from the common shortlist snapshot")
	var event := _event_template("office_shortlist")
	var flexible_result: Dictionary = flexible.resolve_systemic_event(event, "rail_yard")
	var capacity_result: Dictionary = capacity.resolve_systemic_event(event, "eighth_street")
	var flexible_lease: Dictionary = flexible.operations.office.get("signed_lease", {})
	var capacity_lease: Dictionary = capacity.operations.office.get("signed_lease", {})

	_check(bool(flexible_result.get("ok", false)) and bool(capacity_result.get("ok", false)), "both office-shortlist choices sign an actual lease")
	_check(str(flexible_lease.get("id", "")) == "canal_sublease", "flexibility choice persists the shorter canal sublease")
	_check(str(capacity_lease.get("id", "")) == "frostline_works", "capacity choice persists the larger frostline direct lease")
	_check(int(flexible_lease.get("capacity", 0)) < int(capacity_lease.get("capacity", 0)), "office choices retain materially different seat capacities")
	_check(float(flexible_lease.get("deposit", 0.0)) < float(capacity_lease.get("deposit", 0.0)), "larger office retains its higher deposit commitment")
	_check(int(flexible_lease.get("term_weeks", 0)) < int(capacity_lease.get("term_weeks", 0)), "flexible office retains its shorter legal term")
	_check(Dictionary(capacity.business.ledger.get("commitments", {})).size() == 1 and Dictionary(flexible.business.ledger.get("commitments", {})).size() == 1, "each office path creates exactly one business-ledger commitment")
	_check(flexible.operations.to_save() != capacity.operations.to_save(), "office choices diverge in serialized lease state")


func _test_office_capacity_event_respects_inflight_replacement() -> void:
	var game = _fixture(3, 26)
	var active: Dictionary = Dictionary(game.operations.OFFICE_LEASE_CATALOG["canal_sublease"]).duplicate(true)
	active["status"] = "active"
	active["start_week"] = 20
	active["end_week"] = 46
	var signed: Dictionary = Dictionary(game.operations.OFFICE_LEASE_CATALOG["frostline_works"]).duplicate(true)
	signed["status"] = "signed"
	signed["signed_week"] = 25
	signed["start_week"] = 28
	signed["end_week"] = 80
	game.operations.office["active_lease"] = active
	game.operations.office["signed_lease"] = signed
	game.operations.office["completed_fitouts"] = [{"id": "flex_desks", "lease_id": "canal_sublease", "capacity_delta": 6, "status": "complete"}]
	var result: Dictionary = game.call("_resolve_runtime_operations_event", "office_over_capacity", "delegate")
	_check(bool(result.get("ok", false)), "stale capacity modal resolves truthfully when a larger signed lease is already moving in")
	_check(bool(result.get("already_resolving", false)), "capacity result identifies the in-flight replacement instead of repeating a fitout")
	_check(str(Dictionary(result.get("lease", {})).get("id", "")) == "frostline_works", "capacity confirmation names the actual signed replacement")
	_check(int(result.get("move_in_week", -1)) == 28, "capacity confirmation preserves the concrete move-in deadline")


func _test_capital_diligence_and_board_governance_persist() -> void:
	var baseline = _fixture(3, 25)
	var disclose = _clone_model(baseline, "reference disclosure branch restores from the common capital snapshot")
	var coach = _clone_model(baseline, "reference coaching branch restores from the common capital snapshot")
	var reference_event := _event_template("customer_reference_diligence")
	var disclosed_result: Dictionary = disclose.resolve_systemic_event(reference_event, "disclose_workflow")
	var coached_result: Dictionary = coach.resolve_systemic_event(reference_event, "coach_customer")
	_check(bool(disclosed_result.get("ok", false)) and bool(coached_result.get("ok", false)), "both customer-reference choices resolve into investor diligence state")
	_check(bool(Dictionary(disclose.business.market.get("northstar_reference", {})).get("disclosed", false)), "truthful reference branch records all three manual review steps as disclosed")
	_check(not bool(Dictionary(coach.business.market.get("northstar_reference", {})).get("disclosed", true)), "coached reference branch durably records that workflow disclosure was withheld")
	_check(int(Dictionary(disclose.business.investors.get("juniper_ventures", {})).get("trust", 0)) > int(Dictionary(coach.business.investors.get("juniper_ventures", {})).get("trust", 0)), "investor trust distinguishes transparent diligence from message coaching")

	var accept = _clone_model(baseline, "board condition branch restores from the common governance snapshot")
	var lobby = _clone_model(baseline, "board lobbying branch restores from the common governance snapshot")
	var board_event := _event_template("board_consent_required")
	var accepted_result: Dictionary = accept.resolve_systemic_event(board_event, "accept_condition")
	var lobbied_result: Dictionary = lobby.resolve_systemic_event(board_event, "lobby_board")
	var accepted_consent: Dictionary = Array(accept.business.capital.get("board_consents", [])).back()
	var lobbied_consent: Dictionary = Array(lobby.business.capital.get("board_consents", [])).back()
	_check(bool(accepted_result.get("ok", false)) and bool(lobbied_result.get("ok", false)), "both board-consent routes create an actual governance record")
	_check(str(accepted_consent.get("performance_guarantee", "")) == "removed" and str(accepted_consent.get("vote", "")) == "unanimous", "condition route removes the guarantee and records unanimous consent")
	_check(str(lobbied_consent.get("performance_guarantee", "")) == "retained" and str(lobbied_consent.get("vote", "")) == "one_vote_margin", "lobby route retains the guarantee and records its narrow vote")


func _test_lease_trade_and_sublease_change_operations() -> void:
	var baseline = _fixture(3, 25)
	var active_lease: Dictionary = Dictionary(baseline.operations.OFFICE_LEASE_CATALOG["frostline_works"]).duplicate(true)
	active_lease["status"] = "active"
	active_lease["start_week"] = baseline.total_week
	active_lease["end_week"] = baseline.total_week + int(active_lease.get("term_weeks", 52))
	baseline.operations.office["active_lease"] = active_lease
	baseline.call("_sync_operating_roster")

	var keep_break = _clone_model(baseline, "keep-break branch restores from the common lease snapshot")
	var take_credit = _clone_model(baseline, "free-rent branch restores from the common lease snapshot")
	var rent_event := _event_template("landlord_free_rent")
	var keep_result: Dictionary = keep_break.resolve_systemic_event(rent_event, "keep_break")
	var credit_result: Dictionary = take_credit.resolve_systemic_event(rent_event, "take_free_rent")
	var keep_lease: Dictionary = keep_break.operations.office.get("active_lease", {})
	var credit_lease: Dictionary = take_credit.operations.office.get("active_lease", {})
	_check(bool(keep_result.get("ok", false)) and bool(credit_result.get("ok", false)), "both landlord trade routes mutate the active lease")
	_check(int(keep_lease.get("break_option_week", -1)) > 0 and int(keep_lease.get("rent_credit_weeks_remaining", 0)) == 0, "keep-break route preserves an exit date without inventing rent credit")
	_check(int(credit_lease.get("break_option_week", 0)) == -1 and int(credit_lease.get("rent_credit_weeks_remaining", 0)) == 12, "free-rent route removes the break and records twelve credited weeks")
	_check(float(take_credit.operations.burn_summary().get("lease", 99.0)) == 0.0, "active rent credit immediately reaches the operating burn ledger")

	var sublease = _clone_model(baseline, "sublease branch restores from the common capacity snapshot")
	var reserve = _clone_model(baseline, "capacity reserve branch restores from the common capacity snapshot")
	var sublease_event := _event_template("sublease_opportunity")
	var sublease_result: Dictionary = sublease.resolve_systemic_event(sublease_event, "sublease")
	var reserve_result: Dictionary = reserve.resolve_systemic_event(sublease_event, "keep_capacity")
	_check(bool(sublease_result.get("ok", false)) and bool(reserve_result.get("ok", false)), "both sublease choices resolve against the real active lease")
	_check(int(Dictionary(sublease.operations.office.get("active_lease", {})).get("subleased_seats", 0)) > 0, "accepting Chorus writes the concrete subleased seat count")
	_check(sublease.operations.office_capacity() < reserve.operations.office_capacity(), "sublease reduces usable company capacity instead of granting free runway")
	_check(float(sublease.operations.burn_summary().get("lease", 0.0)) < float(reserve.operations.burn_summary().get("lease", 0.0)), "sublease income reduces net lease burn while reserved capacity keeps full rent")


func _candidate_offer_fixture():
	var game = _fixture(2, 18)
	var opened: Dictionary = game.call("_open_next_requisition", "choice_depth_fixture")
	_check(bool(opened.get("ok", false)), "candidate fixture opens a real requisition")
	if not bool(opened.get("ok", false)):
		return game
	var requisition: Dictionary = Dictionary(game.operations.requisitions.back())
	var candidate_id := str(requisition.get("focus_candidate_id", ""))
	_check(not candidate_id.is_empty(), "candidate fixture has a focused candidate")
	if candidate_id.is_empty():
		return game
	for stage in game.operations.INTERVIEW_STAGES:
		var interview: Dictionary = game.operations.apply_decision("interview_candidate", {"candidate_id": candidate_id, "stage": str(stage)}, {"week": game.total_week})
		_check(bool(interview.get("ok", false)), "candidate fixture completes %s evidence stage" % str(stage))
	var dossier: Dictionary = game.operations.candidate_dossier(candidate_id)
	var competing: Dictionary = dossier.get("competing_offer", {})
	var issued: Dictionary = game.operations.apply_decision("issue_offer", {
		"candidate_id": candidate_id,
		"salary": maxf(float(dossier.get("salary_target", 45.0)), float(competing.get("salary", 45.0))),
		"equity_bps": maxf(float(dossier.get("equity_target_bps", 8.0)), float(competing.get("equity_bps", 8.0))),
		"level": int(requisition.get("level", 2)),
		"title": str(dossier.get("role_title", "关键岗位")),
		"team_id": str(requisition.get("team_id", "founders")),
		"manager_id": str(requisition.get("hiring_manager_id", "lin_yue")),
		"allow_out_of_band": true,
	}, {"week": game.total_week, "company_credibility": 0.72, "manager_quality": 0.78, "role_scope": 0.72})
	_check(bool(issued.get("ok", false)), "candidate fixture issues the real pending offer")
	return game


func _fixture(target_chapter: int, target_week: int):
	var game = HiringModel.new()
	game.reset("Choice Depth Works")
	game.chapter = target_chapter
	game.week_in_chapter = 4
	game.total_week = target_week
	game.cash_weeks = 100.0
	game.compute = 100.0
	game.narrative = 68.0
	game.capability = 72.0
	game.coherence = 92.0
	var began: Dictionary = game.begin_week()
	_check(bool(began.get("ok", false)), "choice-depth fixture begins chapter %d at week %d" % [target_chapter, target_week])
	game.call("_sync_operating_roster")
	return game


func _clone_model(source, check_message: String):
	var restored = HiringModel.new()
	_check(restored.from_save(source.to_save()), check_message)
	return restored


func _event_template(event_id: String) -> Dictionary:
	for value in HiringExpansionContent.event_templates():
		if value is Dictionary and str(Dictionary(value).get("id", "")) == event_id:
			return Dictionary(value).duplicate(true)
	_check(false, "authored event template exists: %s" % event_id)
	return {"id": event_id, "family": "unknown"}


func _pending_offer(game) -> Dictionary:
	for value in game.operations.offers:
		if value is Dictionary and str(Dictionary(value).get("status", "")) == "pending":
			return Dictionary(value)
	return {}


func _has_active_training(game, employee_id: String) -> bool:
	for value in game.operations.trainings:
		if value is Dictionary and str(Dictionary(value).get("employee_id", "")) == employee_id and str(Dictionary(value).get("status", "")) == "active":
			return true
	return false


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
