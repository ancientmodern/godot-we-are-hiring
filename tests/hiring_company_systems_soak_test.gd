extends SceneTree

const CampaignDirector = preload("res://src/hiring_director.gd")
const HiringModel = preload("res://src/hiring_model.gd")

const CAMPAIGN_WEEKS := 45
const REPORT_PATH := "res://artifacts/company_systems_soak.json"
const STRATEGIES := ["evidence_first", "growth_balanced", "delegated_operator"]
const SEEDS := [
	1103, 1879, 2539, 3251,
	4001, 4789, 5527, 6311,
	7103, 7879, 8629, 9413,
]

var failures: Array[String] = []
var checks := 0
var campaign_reports: Array[Dictionary] = []


func _init() -> void:
	var model_script: Script = load("res://src/hiring_model.gd")
	var director_script: Script = load("res://src/hiring_director.gd")
	if model_script == null or director_script == null or not model_script.can_instantiate() or not director_script.can_instantiate():
		push_error("HIRING_COMPANY_SYSTEMS_SOAK_FAILURE: model/director dependency did not compile")
		quit(1)
		return

	for campaign_index in SEEDS.size():
		var seed := int(SEEDS[campaign_index])
		var strategy_index := campaign_index % STRATEGIES.size()
		campaign_reports.append(_run_campaign(campaign_index, seed, strategy_index))

	var report := _build_report()
	var wrote_report := _write_report(report)
	_check(wrote_report, "soak report is written to %s" % REPORT_PATH)

	if failures.is_empty():
		print("HIRING_COMPANY_SYSTEMS_SOAK_PASS: %d checks / %d campaigns / %d settled weeks" % [
			checks, campaign_reports.size(), _sum_report_int("weeks_settled"),
		])
		print("HIRING_COMPANY_SYSTEMS_SOAK_DISTRIBUTION: %s" % JSON.stringify(report.get("distribution", {})))
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_COMPANY_SYSTEMS_SOAK_FAILURE: " + failure)
		print("HIRING_COMPANY_SYSTEMS_SOAK_FAIL: %d failures / %d checks / report=%s" % [failures.size(), checks, REPORT_PATH])
		quit(1)


func _run_campaign(campaign_index: int, seed: int, strategy_index: int) -> Dictionary:
	var director = CampaignDirector.new()
	var started: Dictionary = director.start_company("Soak Works %02d" % (campaign_index + 1), false)
	_check(bool(started.get("ok", false)), _label(campaign_index, "campaign starts"))
	if not bool(started.get("ok", false)):
		return {
			"campaign": campaign_index + 1,
			"seed": seed,
			"strategy": str(STRATEGIES[strategy_index]),
			"weeks_settled": 0,
			"failed_to_start": true,
		}

	# A campaign seed drives all deterministic sources that are intentionally
	# public in the simulation. No outcomes, cash, or actors are fabricated.
	director._event_scheduler.reset(seed, Dictionary(director.call("_scheduler_options")))
	director.model.rng_state = maxi(1, seed)
	director.model.operations.rng_state = maxi(1, seed * 17 % 2_147_483_647)
	director.model.business.market["rng_state"] = maxi(1, seed * 31 % 2_147_483_647)
	director.model.business.policy["rng_state"] = maxi(1, seed * 47 % 2_147_483_647)

	var runtime_by_week: Dictionary = {}
	var runtime_by_family: Dictionary = {}
	var systemic_by_family: Dictionary = {}
	var choice_counts: Dictionary = {}
	var action_counts: Dictionary = {}
	var financing_replay_checked: Dictionary = {}
	var phase_counts := {"requisition": 0, "interview": 0, "offer": 0}
	var weeks_settled := 0
	var event_count := 0
	var runtime_count := 0
	var systemic_count := 0
	var min_cash_usd := int(director.model.business.ledger.get("cash_usd", 0))
	var max_runtime_in_week := 0
	var saw_annual_subscription := false
	var annual_excluded_checks := 0
	var ending_id := ""

	for _week_guard in CAMPAIGN_WEEKS:
		if director.model.campaign_complete:
			break
		var week := int(director.model.total_week)
		_check(week == weeks_settled + 1, _label(campaign_index, "campaign clock reaches week %d without a skip" % (weeks_settled + 1)))

		var opening_events := _drain_events(director, strategy_index, campaign_index, runtime_by_week, runtime_by_family, systemic_by_family, choice_counts)
		event_count += int(opening_events.get("events", 0))
		runtime_count += int(opening_events.get("runtime", 0))
		systemic_count += int(opening_events.get("systemic", 0))
		_check(bool(opening_events.get("ok", false)), _label(campaign_index, "week %d opening inbox drains" % week))

		_perform_week_actions(director, strategy_index, action_counts, phase_counts)
		_assert_money_and_cap_invariants(director.model, campaign_index, week, "after_actions")
		min_cash_usd = mini(min_cash_usd, int(director.model.business.ledger.get("cash_usd", 0)))

		var action_events := _drain_events(director, strategy_index, campaign_index, runtime_by_week, runtime_by_family, systemic_by_family, choice_counts)
		event_count += int(action_events.get("events", 0))
		runtime_count += int(action_events.get("runtime", 0))
		systemic_count += int(action_events.get("systemic", 0))
		_check(bool(action_events.get("ok", false)), _label(campaign_index, "week %d post-action inbox drains" % week))

		var settlement := _finish_week_with_events(director, strategy_index, campaign_index, runtime_by_week, runtime_by_family, systemic_by_family, choice_counts)
		event_count += int(settlement.get("events", 0))
		runtime_count += int(settlement.get("runtime", 0))
		systemic_count += int(settlement.get("systemic", 0))
		_check(bool(settlement.get("ok", false)), _label(campaign_index, "week %d settles through the director boundary" % week))
		if not bool(settlement.get("ok", false)):
			break
		weeks_settled += 1
		var finish_result: Dictionary = settlement.get("result", {})
		var ending: Dictionary = finish_result.get("ending", {})
		if not ending.is_empty():
			ending_id = str(Dictionary(ending.get("resolution", {})).get("id", ending.get("id", "")))

		_assert_money_and_cap_invariants(director.model, campaign_index, week, "after_settlement")
		_assert_competitor_financing_limit(director.model, campaign_index, week)
		_assert_financing_replay_guards(director.model, campaign_index, financing_replay_checked)
		var annual_check := _assert_annual_prepay_exclusion(director.model, campaign_index, week)
		if bool(annual_check.get("present", false)):
			saw_annual_subscription = true
			annual_excluded_checks += 1
		min_cash_usd = mini(min_cash_usd, int(director.model.business.ledger.get("cash_usd", 0)))
		max_runtime_in_week = maxi(max_runtime_in_week, int(runtime_by_week.get(str(week), 0)))
		_check(int(runtime_by_week.get(str(week), 0)) <= 1, _label(campaign_index, "week %d emits at most one runtime side decision" % week))

		if week >= CAMPAIGN_WEEKS:
			break
		var night: Dictionary = director.pending_night_shift()
		if not night.is_empty():
			var objects: Dictionary = night.get("objects", {})
			var object_ids: Array = objects.keys()
			object_ids.sort()
			var inspected: Array = [str(object_ids[0])] if not object_ids.is_empty() else []
			var night_result: Dictionary = director.complete_night_shift(str(night.get("_director_night_id", night.get("id", ""))), inspected, "")
			_check(bool(night_result.get("ok", false)), _label(campaign_index, "week %d night shift completes without destructive command" % week))
		var advanced: Dictionary = director.advance()
		_check(bool(advanced.get("ok", false)) and not bool(advanced.get("campaign_complete", false)), _label(campaign_index, "week %d advances to the next operating week" % week))
		if not bool(advanced.get("ok", false)) or bool(advanced.get("campaign_complete", false)):
			break

	var model = director.model
	var business_state: Dictionary = model.business.public_state()
	var ledger_state: Dictionary = business_state.get("ledger", {})
	var capital_state: Dictionary = business_state.get("capital", {})
	var cap_table: Dictionary = capital_state.get("cap_table", {})
	var operations_state: Dictionary = model.operations.public_state()
	var active_lease: Dictionary = model.operations.office.get("active_lease", {})
	var signed_lease: Dictionary = model.operations.office.get("signed_lease", {})
	var lease_id := str(active_lease.get("id", signed_lease.get("id", "")))
	var subscription_ids: Array = model.operations.subscriptions.keys()
	subscription_ids.sort()
	var milestone_ids: Array = Array(model.memory.get("company_milestone_ids", [])).duplicate()
	var hired_employee_ids: Array[String] = []
	for employee_value in model.employees:
		if employee_value is Dictionary:
			var employee_id := str(Dictionary(employee_value).get("id", ""))
			if employee_id.begins_with("hire_"):
				hired_employee_ids.append(employee_id)
	var competitor_financing: Dictionary = {}
	for competitor_id_value in Dictionary(model.business.market.get("competitors", {})):
		var competitor_id := str(competitor_id_value)
		var competitor: Dictionary = model.business.market["competitors"][competitor_id]
		competitor_financing[competitor_id] = int(competitor.get("financing_count", 0))
	var annual_summary := _annual_prepay_summary(model)
	var financing_stages := _financing_stages(model)

	_check(weeks_settled == CAMPAIGN_WEEKS, _label(campaign_index, "full 45-week campaign survives and settles"))
	_check(int(ledger_state.get("cash_usd", -1)) >= 0 and min_cash_usd >= 0, _label(campaign_index, "cash never penetrates below zero"))
	_check(_cap_basis_points(cap_table) == 10_000, _label(campaign_index, "final cap table sums to 10,000 bp"))
	_check(financing_stages.has("preseed") and financing_stages.has("seed") and financing_stages.has("series_a"), _label(campaign_index, "pre-seed, Seed, and Series A all close through real financing decisions"))
	_check(financing_replay_checked.size() == 3, _label(campaign_index, "all three completed financing stages reject repeat cash and dilution"))
	_check(int(ledger_state.get("customer_count", 0)) > 0, _label(campaign_index, "product and market decisions produce paying customers"))
	_check(model.employees.size() > 1, _label(campaign_index, "campaign produces employees beyond the initial cofounder"))
	_check(int(phase_counts.get("requisition", 0)) > 0 and int(phase_counts.get("interview", 0)) > 0 and int(phase_counts.get("offer", 0)) > 0, _label(campaign_index, "recruiting advances through requisition, interview, and offer"))
	_check(not hired_employee_ids.is_empty(), _label(campaign_index, "at least one pipeline candidate reaches the formal roster"))
	_check(not lease_id.is_empty(), _label(campaign_index, "office decisions produce a signed or active lease"))
	_check(not subscription_ids.is_empty(), _label(campaign_index, "vendor decisions produce SaaS subscriptions"))
	_check(saw_annual_subscription and annual_excluded_checks > 0, _label(campaign_index, "annual prepaid SaaS is observed across later weekly settlements"))
	_check(int(annual_summary.get("commitment_count", 0)) == 1, _label(campaign_index, "annual prepaid SaaS creates exactly one cash commitment inside 45 weeks"))
	_check(int(annual_summary.get("commitment_usd", -1)) == int(annual_summary.get("cash_paid_to_date_usd", -2)), _label(campaign_index, "annual prepaid cash commitment equals paid-to-date, without a second weekly deduction"))
	_check(not milestone_ids.is_empty(), _label(campaign_index, "weekly settlement produces durable company milestones"))
	_check(not Dictionary(model.business.policy.get("programs", {})).is_empty(), _label(campaign_index, "policy application reaches a persistent program record"))
	_check(runtime_count > 0, _label(campaign_index, "real subsystem state produces runtime side decisions"))
	_check(max_runtime_in_week <= 1, _label(campaign_index, "runtime decision budget remains one per week across the campaign"))
	for competitor_id_value in competitor_financing:
		_check(int(competitor_financing[competitor_id_value]) <= 3, _label(campaign_index, "%s never exceeds three financings" % str(competitor_id_value)))

	return {
		"campaign": campaign_index + 1,
		"seed": seed,
		"strategy": str(STRATEGIES[strategy_index]),
		"weeks_settled": weeks_settled,
		"ending": ending_id,
		"events_resolved": event_count,
		"systemic_decisions": systemic_count,
		"runtime_decisions": runtime_count,
		"max_runtime_decisions_in_one_week": max_runtime_in_week,
		"runtime_by_family": runtime_by_family.duplicate(true),
		"systemic_by_family": systemic_by_family.duplicate(true),
		"choice_counts": choice_counts.duplicate(true),
		"actions": action_counts.duplicate(true),
		"recruiting_phases": phase_counts.duplicate(true),
		"hired_employee_ids": hired_employee_ids,
		"cash_min_usd": min_cash_usd,
		"cash_final_usd": int(ledger_state.get("cash_usd", 0)),
		"runway_final_weeks": int(ledger_state.get("runway_weeks", 0)),
		"mrr_final_usd": int(ledger_state.get("mrr_usd", 0)),
		"customers_final": int(ledger_state.get("customer_count", 0)),
		"employees_final": model.employees.size(),
		"lease_id": lease_id,
		"subscriptions": subscription_ids,
		"milestones": milestone_ids,
		"financing_stages": financing_stages,
		"financing_replay_checked": financing_replay_checked.keys(),
		"cap_table_bp": _cap_basis_points(cap_table),
		"competitor_financing_counts": competitor_financing,
		"annual_prepay": annual_summary,
		"operations_public_counts": {
			"open_requisitions": int(operations_state.get("open_requisitions", 0)),
			"active_candidates": int(operations_state.get("active_candidates", 0)),
			"subscriptions": Array(operations_state.get("subscriptions", [])).size(),
		},
	}


func _perform_week_actions(director, strategy_index: int, action_counts: Dictionary, phase_counts: Dictionary) -> void:
	var model = director.model
	var chapter := int(model.chapter)
	var week := int(model.week_in_chapter)
	var desired: Array[String] = []
	if chapter == 0:
		_append_unique(desired, "clean_data" if week == 1 else "train")
		_append_unique(desired, "tweet")
		_append_unique(desired, "buy_compute" if float(model.compute) <= 3.0 else "train")
	elif chapter == 1:
		if week >= 2:
			_append_unique(desired, "open_requisition")
		if week >= 3:
			_append_unique(desired, "product_launch")
		if bool(model.uses_authoritative_financial_ledger()) and not bool(model.call("_business_stage_exists", "preseed")):
			_append_unique(desired, "fundraising")
		_append_unique(desired, "buy_compute" if float(model.compute) <= 3.0 else "train")
		_append_unique(desired, "tweet")
		_append_unique(desired, "clean_data")
	elif chapter == 2:
		if not bool(model.call("_business_stage_exists", "seed")):
			_append_unique(desired, "fundraising")
		if week <= 3:
			_append_unique(desired, "vendor_review")
		if week == 3 or week == 5 or week == 8:
			_append_unique(desired, "org_review")
		if week == 4 or week == 7 or week == 10:
			_append_unique(desired, "office_plan")
		if week == 5:
			_append_unique(desired, "policy_program")
		_append_unique(desired, "product_launch")
		_append_unique(desired, "open_requisition")
		_append_unique(desired, "buy_compute" if float(model.compute) <= 3.0 else "train")
		_append_unique(desired, "vendor_review")
		_append_unique(desired, "org_review")
		_append_unique(desired, "office_plan")
	elif chapter == 3:
		if not bool(model.call("_business_stage_exists", "series_a")):
			_append_unique(desired, "fundraising")
		_append_unique(desired, "product_launch")
		_append_unique(desired, "open_requisition")
		if week % 3 == 0:
			_append_unique(desired, "office_plan")
		if week % 3 == 1:
			_append_unique(desired, "vendor_review")
		if week % 3 == 2:
			_append_unique(desired, "org_review")
		_append_unique(desired, "buy_compute" if float(model.compute) <= 3.0 else "train")
		_append_unique(desired, "org_review")
		_append_unique(desired, "office_plan")
	else:
		_append_unique(desired, "do_nothing" if strategy_index == 0 else ("one_on_one" if strategy_index == 1 else "read_intranet"))
		_append_unique(desired, "do_nothing")

	# A low-runway company first uses a real financing meeting (if a stage remains)
	# or paid contract work. This harness never assigns cash directly.
	if bool(model.uses_authoritative_financial_ledger()) and int(model.business.runway_weeks()) <= 10:
		var current_stage := "preseed" if chapter <= 1 else ("seed" if chapter == 2 else "series_a")
		if not bool(model.call("_business_stage_exists", current_stage)):
			desired.push_front("fundraising")
		elif chapter >= 2 and chapter < 4:
			desired.push_front("contract")

	var successful := 0
	for action_id in desired:
		if successful >= 3:
			break
		var use_ai := false
		if not bool(model.flags.get("ai_used_this_week", false)):
			use_ai = strategy_index == 2 or (strategy_index == 1 and posmod(int(model.total_week), 5) == 0)
		if not director.model.can_act(action_id, use_ai):
			if use_ai and director.model.can_act(action_id, false):
				use_ai = false
			else:
				continue
		var result: Dictionary = director.perform_action(action_id, use_ai)
		if not bool(result.get("ok", false)):
			continue
		successful += 1
		action_counts[action_id] = int(action_counts.get(action_id, 0)) + 1
		if action_id == "open_requisition":
			var operating: Dictionary = model.memory.get("last_operating_action_result", {})
			var phase := str(operating.get("phase", ""))
			if phase_counts.has(phase):
				phase_counts[phase] = int(phase_counts.get(phase, 0)) + 1


func _drain_events(director, strategy_index: int, campaign_index: int, runtime_by_week: Dictionary, runtime_by_family: Dictionary, systemic_by_family: Dictionary, choice_counts: Dictionary) -> Dictionary:
	var events := 0
	var runtime := 0
	var systemic := 0
	for _guard in 80:
		var event: Dictionary = director.next_event()
		if event.is_empty():
			return {"ok": true, "events": events, "runtime": runtime, "systemic": systemic}
		var week_key := str(int(director.model.total_week))
		var family := str(event.get("_system_domain", event.get("family", "story")))
		if bool(event.get("_company_system_event", false)):
			systemic += 1
			systemic_by_family[family] = int(systemic_by_family.get(family, 0)) + 1
		if bool(event.get("_runtime_state_event", false)):
			runtime += 1
			runtime_by_week[week_key] = int(runtime_by_week.get(week_key, 0)) + 1
			runtime_by_family[family] = int(runtime_by_family.get(family, 0)) + 1
			_check(int(runtime_by_week[week_key]) <= 1, _label(campaign_index, "week %s runtime inbox never exceeds one decision while draining" % week_key))
		var choice_id := _choose_event_choice(event, strategy_index, int(director.model.total_week))
		var resolved: Dictionary = director.resolve_event(event, choice_id)
		events += 1
		if not choice_id.is_empty():
			choice_counts[choice_id] = int(choice_counts.get(choice_id, 0)) + 1
		if not bool(resolved.get("ok", false)):
			failures.append(_label(campaign_index, "event %s failed to resolve (%s)" % [str(event.get("id", "")), str(resolved.get("reason", "unknown"))]))
			return {"ok": false, "events": events, "runtime": runtime, "systemic": systemic}
		if bool(event.get("_company_system_event", false)):
			var system_result: Dictionary = resolved.get("system_result", {})
			_check(not system_result.is_empty() and bool(system_result.get("ok", false)), _label(campaign_index, "system event %s applies to live subsystem state (reason=%s)" % [str(event.get("id", "")), str(system_result.get("reason", "missing_system_result"))]))
			if system_result.is_empty() or not bool(system_result.get("ok", false)):
				return {"ok": false, "events": events, "runtime": runtime, "systemic": systemic, "reason": str(system_result.get("reason", "missing_system_result"))}
		_assert_money_and_cap_invariants(director.model, campaign_index, int(director.model.total_week), "event:%s" % str(event.get("id", "")))
	return {"ok": false, "events": events, "runtime": runtime, "systemic": systemic, "reason": "event_guard_exhausted"}


func _finish_week_with_events(director, strategy_index: int, campaign_index: int, runtime_by_week: Dictionary, runtime_by_family: Dictionary, systemic_by_family: Dictionary, choice_counts: Dictionary) -> Dictionary:
	var events := 0
	var runtime := 0
	var systemic := 0
	for _guard in 80:
		var result: Dictionary = director.finish_week()
		if bool(result.get("ok", false)):
			return {"ok": true, "result": result, "events": events, "runtime": runtime, "systemic": systemic}
		if str(result.get("reason", "")) != "event_pending":
			return {"ok": false, "result": result, "events": events, "runtime": runtime, "systemic": systemic}
		var drained := _drain_events(director, strategy_index, campaign_index, runtime_by_week, runtime_by_family, systemic_by_family, choice_counts)
		events += int(drained.get("events", 0))
		runtime += int(drained.get("runtime", 0))
		systemic += int(drained.get("systemic", 0))
		if not bool(drained.get("ok", false)):
			return {"ok": false, "result": result, "events": events, "runtime": runtime, "systemic": systemic}
	return {"ok": false, "events": events, "runtime": runtime, "systemic": systemic, "reason": "settlement_guard_exhausted"}


func _choose_event_choice(event: Dictionary, strategy_index: int, total_week: int) -> String:
	var choices: Array = Array(event.get("choices", []))
	if choices.is_empty():
		return ""
	var selected: Dictionary = {}
	if strategy_index == 2:
		for choice_value in choices:
			if choice_value is Dictionary and bool(Dictionary(choice_value).get("ai", false)):
				selected = Dictionary(choice_value)
				break
	elif strategy_index == 1:
		var target_index := posmod(total_week + choices.size(), choices.size())
		selected = Dictionary(choices[target_index])
	else:
		for choice_value in choices:
			if choice_value is Dictionary and not bool(Dictionary(choice_value).get("ai", false)):
				selected = Dictionary(choice_value)
				break
	if selected.is_empty():
		selected = Dictionary(choices[-1] if strategy_index == 2 else choices[0])
	return str(selected.get("id", ""))


func _assert_money_and_cap_invariants(model, campaign_index: int, week: int, phase: String) -> void:
	var cash_usd := int(model.business.ledger.get("cash_usd", -1))
	_check(cash_usd >= 0, _label(campaign_index, "week %d %s keeps authoritative cash non-negative" % [week, phase]))
	if bool(model.uses_authoritative_financial_ledger()):
		_check(float(model.cash_weeks) >= 0.0, _label(campaign_index, "week %d %s keeps compatibility runway non-negative" % [week, phase]))
	var public_business: Dictionary = model.business.public_state()
	var capital: Dictionary = public_business.get("capital", {})
	var table: Dictionary = capital.get("cap_table", {})
	_check(_cap_basis_points(table) == 10_000, _label(campaign_index, "week %d %s cap table sums to 10,000 bp" % [week, phase]))


func _assert_competitor_financing_limit(model, campaign_index: int, week: int) -> void:
	var competitors: Dictionary = model.business.market.get("competitors", {})
	for competitor_id_value in competitors:
		var competitor_id := str(competitor_id_value)
		var competitor: Dictionary = competitors[competitor_id]
		_check(int(competitor.get("financing_count", 0)) <= 3, _label(campaign_index, "week %d %s remains inside the three-round rival financing cap" % [week, competitor_id]))


func _assert_financing_replay_guards(model, campaign_index: int, replay_checked: Dictionary) -> void:
	for stage in ["preseed", "seed", "series_a"]:
		if replay_checked.has(stage) or not bool(model.call("_business_stage_exists", stage)):
			continue
		var before_cash := int(model.business.ledger.get("cash_usd", 0))
		var before_safes := Array(model.business.capital.get("safes", [])).size()
		var before_rounds := Array(model.business.capital.get("rounds", [])).size()
		var before_cap := _cap_basis_points(Dictionary(Dictionary(model.business.public_state().get("capital", {})).get("cap_table", {})))
		var replay: Dictionary = model.record_business_financing(stage, "clean", "soak_replay:%d:%s" % [int(model.total_week), stage])
		_check(bool(replay.get("ok", false)) and bool(replay.get("already_recorded", false)), _label(campaign_index, "%s repeat financing is acknowledged as already recorded" % stage))
		_check(int(model.business.ledger.get("cash_usd", 0)) == before_cash, _label(campaign_index, "%s repeat financing cannot mint cash" % stage))
		_check(Array(model.business.capital.get("safes", [])).size() == before_safes and Array(model.business.capital.get("rounds", [])).size() == before_rounds, _label(campaign_index, "%s repeat financing cannot add a security" % stage))
		_check(_cap_basis_points(Dictionary(Dictionary(model.business.public_state().get("capital", {})).get("cap_table", {}))) == before_cap, _label(campaign_index, "%s repeat financing cannot dilute the cap table" % stage))
		replay_checked[stage] = int(model.total_week)


func _assert_annual_prepay_exclusion(model, campaign_index: int, week: int) -> Dictionary:
	if not model.operations.subscriptions.has("quietwire_annual"):
		return {"present": false}
	var expected_recurring := 0.0
	for service_id_value in model.operations.subscriptions:
		var service_id := str(service_id_value)
		var subscription: Dictionary = model.operations.subscriptions[service_id]
		var spec: Dictionary = subscription.get("spec", {})
		if str(spec.get("billing", "weekly")) != "annual_prepaid":
			expected_recurring += float(model.operations.subscription_weekly_cost(service_id))
	var recorded_recurring := float(model.memory.get("operations_cash_recurring_saas", 0.0))
	_check(is_equal_approx(recorded_recurring, expected_recurring), _label(campaign_index, "week %d recurring vendor cash excludes annual-prepaid amortization" % week))
	var quietwire: Dictionary = model.operations.subscriptions["quietwire_annual"]
	_check(float(quietwire.get("pnl_weekly_expense", 0.0)) > 0.0, _label(campaign_index, "week %d annual subscription still recognizes a weekly P&L expense" % week))
	return {"present": true}


func _annual_prepay_summary(model) -> Dictionary:
	if not model.operations.subscriptions.has("quietwire_annual"):
		return {"present": false, "commitment_count": 0, "commitment_usd": 0, "cash_paid_to_date_usd": 0}
	var quietwire: Dictionary = model.operations.subscriptions["quietwire_annual"]
	var matching := 0
	var commitment_usd := 0
	for commitment_id_value in Dictionary(model.business.ledger.get("commitments", {})):
		var commitment_id := str(commitment_id_value)
		var commitment: Dictionary = model.business.ledger["commitments"][commitment_id]
		if commitment_id.contains("quietwire_annual") and str(commitment.get("category", "")) == "saas":
			matching += 1
			commitment_usd += int(commitment.get("amount_usd", 0))
	return {
		"present": true,
		"commitment_count": matching,
		"commitment_usd": commitment_usd,
		"cash_paid_to_date_usd": int(round(float(quietwire.get("cash_paid_to_date", 0.0)) * 1000.0)),
		"pnl_weekly_expense_usd": int(round(float(quietwire.get("pnl_weekly_expense", 0.0)) * 1000.0)),
		"prepaid_through_week": int(quietwire.get("prepaid_through_week", -1)),
	}


func _financing_stages(model) -> Array[String]:
	var stages: Array[String] = []
	for safe_value in Array(model.business.capital.get("safes", [])):
		if safe_value is Dictionary:
			_append_unique(stages, str(Dictionary(safe_value).get("stage", "")))
	for round_value in Array(model.business.capital.get("rounds", [])):
		if round_value is Dictionary:
			_append_unique(stages, str(Dictionary(round_value).get("stage", "")))
	return stages


func _cap_basis_points(table: Dictionary) -> int:
	var total := 0
	for row_value in Array(table.get("rows", [])):
		if row_value is Dictionary:
			total += int(Dictionary(row_value).get("ownership_bp", 0))
	return total


func _append_unique(values: Array, value: String) -> void:
	if not value.is_empty() and not values.has(value):
		values.append(value)


func _build_report() -> Dictionary:
	var strategy_counts: Dictionary = {}
	var ending_counts: Dictionary = {}
	var runtime_family_totals: Dictionary = {}
	var systemic_family_totals: Dictionary = {}
	var customers: Array[int] = []
	var mrr_values: Array[int] = []
	var employees: Array[int] = []
	var cash_values: Array[int] = []
	var runtime_values: Array[int] = []
	for campaign in campaign_reports:
		var strategy := str(campaign.get("strategy", "unknown"))
		var ending := str(campaign.get("ending", "none"))
		strategy_counts[strategy] = int(strategy_counts.get(strategy, 0)) + 1
		ending_counts[ending] = int(ending_counts.get(ending, 0)) + 1
		_merge_counts(runtime_family_totals, Dictionary(campaign.get("runtime_by_family", {})))
		_merge_counts(systemic_family_totals, Dictionary(campaign.get("systemic_by_family", {})))
		customers.append(int(campaign.get("customers_final", 0)))
		mrr_values.append(int(campaign.get("mrr_final_usd", 0)))
		employees.append(int(campaign.get("employees_final", 0)))
		cash_values.append(int(campaign.get("cash_final_usd", 0)))
		runtime_values.append(int(campaign.get("runtime_decisions", 0)))
	return {
		"schema_version": 1,
		"campaign_weeks": CAMPAIGN_WEEKS,
		"campaign_count": campaign_reports.size(),
		"seed_count": SEEDS.size(),
		"strategies": STRATEGIES,
		# The sole check after report construction verifies this report write.
		"checks": checks + 1,
		"failures": failures.duplicate(),
		"invariants": [
			"cash_usd_never_negative",
			"same_stage_financing_idempotent",
			"competitor_financing_count_lte_3",
			"cap_table_bp_equals_10000",
			"annual_prepay_not_in_weekly_cash_vendor_cost",
			"runtime_side_decisions_lte_1_per_week",
			"customers_employees_lease_subscriptions_milestones_materialize",
		],
		"distribution": {
			"strategy_counts": strategy_counts,
			"ending_counts": ending_counts,
			"runtime_family_totals": runtime_family_totals,
			"systemic_family_totals": systemic_family_totals,
			"customers_final": _int_distribution(customers),
			"mrr_final_usd": _int_distribution(mrr_values),
			"employees_final": _int_distribution(employees),
			"cash_final_usd": _int_distribution(cash_values),
			"runtime_decisions": _int_distribution(runtime_values),
		},
		"campaigns": campaign_reports,
	}


func _int_distribution(values: Array[int]) -> Dictionary:
	if values.is_empty():
		return {"min": 0, "max": 0, "mean": 0.0}
	var total := 0
	var minimum := values[0]
	var maximum := values[0]
	for value in values:
		total += value
		minimum = mini(minimum, value)
		maximum = maxi(maximum, value)
	return {"min": minimum, "max": maximum, "mean": snappedf(float(total) / float(values.size()), 0.01)}


func _merge_counts(target: Dictionary, source: Dictionary) -> void:
	for key_value in source:
		var key := str(key_value)
		target[key] = int(target.get(key, 0)) + int(source[key_value])


func _sum_report_int(key: String) -> int:
	var total := 0
	for campaign in campaign_reports:
		total += int(campaign.get(key, 0))
	return total


func _write_report(report: Dictionary) -> bool:
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(report, "  ", false))
	file.close()
	return true


func _label(campaign_index: int, message: String) -> String:
	return "campaign %02d [%s]: %s" % [campaign_index + 1, str(STRATEGIES[campaign_index % STRATEGIES.size()]), message]


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
