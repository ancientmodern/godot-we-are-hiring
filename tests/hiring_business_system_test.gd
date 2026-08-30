extends SceneTree

const BusinessSystem = preload("res://src/hiring_business_system.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_initial_contract_and_api()
	_test_dollar_ledger_and_commitments()
	_test_financing_quote_is_narrative_only()
	_test_safe_priced_round_and_idempotency()
	_test_outstanding_safe_pro_forma_and_liquidity_exit()
	_test_option_grants_and_cap_table_invariants()
	_test_option_departure_vesting_and_idempotency()
	_test_non_participating_exit_waterfall()
	_test_named_investors_and_relationships()
	_test_market_determinism_public_information_and_rng_isolation()
	_test_skipped_week_external_catch_up_and_single_player_settlement()
	_test_policy_program_semantics_and_capability_gate()
	_test_event_candidates_and_decision_contracts()
	_test_save_round_trip_and_replay_boundaries()

	if failures.is_empty():
		print("HIRING_BUSINESS_SYSTEM_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_BUSINESS_SYSTEM_TEST_FAILURE: " + failure)
		quit(1)


func _test_initial_contract_and_api() -> void:
	var business = BusinessSystem.new()
	for method_name in [
		"public_state", "to_save", "from_save", "tick_week", "apply_decision",
		"event_candidates", "financing_quote", "issue_post_money_safe",
		"close_priced_round", "grant_options", "process_option_departure", "exit_waterfall", "cap_table",
		"fully_diluted_shares", "set_weekly_cost", "add_commitment",
	]:
		_check(business.has_method(method_name), "public API exposes %s" % method_name)
	var state: Dictionary = business.public_state()
	_check(int(state["ledger"]["cash_usd"]) == 200_000, "opening ledger stores exact USD cash")
	_check(int(state["ledger"]["weekly_cost_usd"]) == 20_000, "opening weekly costs are itemized and summed")
	_check(Dictionary(state["ledger"]["weekly_costs"]).size() == 5, "public ledger exposes the itemized weekly cost basis")
	_check(Array(state["ledger"]["recent_journal"]).is_empty(), "public ledger starts with an empty bounded audit journal")
	_check(int(state["ledger"]["weekly_burn_usd"]) == 20_000, "opening gross burn is derived")
	_check(int(state["ledger"]["runway_weeks"]) == 10, "runway remains a derived public display")
	_check(business.fully_diluted_shares() == 10_000_000, "founding fully diluted capitalization is ten million shares")
	var table: Dictionary = business.cap_table()
	_check(_cap_owner_shares(table, "founder") == 5_000_000, "founder owns five million common shares")
	_check(_cap_owner_shares(table, "lin_yue") == 4_000_000, "Lin Yue owns four million common shares")
	_check(_cap_owner_shares(table, "option_pool") == 1_000_000, "founding option pool reserves one million shares")
	_check(_cap_bp_sum(table) == 10_000, "display cap-table basis points sum exactly to one hundred percent")
	_check(Array(state["capital"]["board_seats"]).size() == 2, "founder and CTO begin as the two board seats")
	_check(Array(state["capital"]["safes"]).is_empty(), "public capital state exposes outstanding SAFE instruments")
	_check(Array(state["investors"]).size() == 4, "four stable fictional investors are available")
	_check(Array(state["market"]["competitors"]).size() == 3, "three stable fictional competitors are available")
	for competitor_value in Array(state["market"]["competitors"]):
		var competitor: Dictionary = competitor_value
		_check(not competitor.has("capability") and not competitor.has("narrative") and not competitor.has("cash_usd"), "public competitor dossier does not leak hidden simulation truth")
	_check(not state.has("market_rng_state") and not state.has("policy_rng_state"), "public state never exposes RNG internals")


func _test_dollar_ledger_and_commitments() -> void:
	var business = BusinessSystem.new()
	var payroll = business.set_weekly_cost("cost:payroll", "payroll", 15_000)
	_check(bool(payroll.get("ok", false)) and int(payroll.get("before_usd", 0)) == 12_000, "weekly cost mutation returns an audit delta")
	_check(business.weekly_cost_usd() == 23_000, "weekly cost update changes the ledger sum")
	var repeated_payroll = business.set_weekly_cost("cost:payroll", "payroll", 99_000)
	_check(bool(repeated_payroll.get("idempotent", false)), "weekly cost transaction is idempotent")
	_check(business.weekly_cost_usd() == 23_000, "idempotent weekly cost replay cannot overwrite the first amount")
	_check(not bool(business.set_weekly_cost("cost:bad", "payroll", -1).get("ok", true)), "negative weekly cost is rejected")

	var commitment = business.add_commitment("commit:add", "security_audit", "security", 30_000, 2, true)
	_check(bool(commitment.get("ok", false)), "future cash commitment is recorded")
	_check(Dictionary(business.public_state()["ledger"]["commitments"]).has("security_audit"), "commitment appears in public ledger state")
	var tick_one = business.tick_week({"total_week": 1})
	_check(bool(tick_one.get("ok", false)) and bool(tick_one["operating"].get("settled", false)), "weekly operating settlement runs through tick_week")
	_check(int(tick_one.get("world_cash_delta_usd", 99)) == 0, "random outside-world tick never changes player cash")
	_check(int(business.ledger["cash_usd"]) == 177_000, "week one deducts only deterministic recurring cost")
	var tick_two = business.tick_week({"total_week": 2})
	_check(int(business.ledger["cash_usd"]) == 124_000, "due commitment settles after deterministic week-two operations")
	_check(int(tick_two["operating"]["cash_delta_usd"]) == -53_000, "settlement reports recurring and committed cash movement together")
	var commitment_state: Dictionary = business.ledger["commitments"]["security_audit"]
	_check(str(commitment_state["status"]) == "paid" and int(commitment_state["paid_usd"]) == 30_000, "auto commitment is paid exactly once")
	var replay = business.tick_week({"total_week": 2})
	_check(bool(replay.get("idempotent", false)), "weekly tick is idempotent")
	_check(int(business.ledger["cash_usd"]) == 124_000, "weekly replay cannot double-charge operations or commitment")
	_check(not bool(business.add_commitment("commit:bad", "", "vendor", 1, 1).get("ok", true)), "blank commitment id is rejected")

	var manual = BusinessSystem.new()
	_check(bool(manual.add_commitment("manual:add", "filing", "legal", 25_000, 10, false).get("ok", false)), "manual commitment can be recorded without auto settlement")
	var paid = manual.settle_commitment("manual:pay", "filing")
	_check(bool(paid.get("ok", false)) and int(paid.get("paid_usd", 0)) == 25_000, "manual commitment settlement uses exact USD")
	var paid_again = manual.settle_commitment("manual:pay", "filing")
	_check(bool(paid_again.get("idempotent", false)), "manual settlement transaction is idempotent")
	_check(int(manual.ledger["cash_usd"]) == 175_000, "manual settlement is not applied twice")

	var revenue = BusinessSystem.new()
	revenue.ledger["mrr_usd"] = 40_000
	revenue.ledger["gross_margin_bp"] = 8_000
	_check(revenue.weekly_gross_profit_usd() == 7_384, "MRR converts through twelve months over fifty-two weeks before gross margin")
	_check(revenue.weekly_burn_usd() == 12_616, "gross profit reduces derived weekly burn")
	_check(revenue.runway_weeks() == 16, "runway uses net weekly burn and ceiling")


func _test_financing_quote_is_narrative_only() -> void:
	var business = BusinessSystem.new()
	var stage_amounts := {
		"preseed": [250_000, 500_000, 750_000, 1_000_000],
		"bridge": [200_000, 400_000, 750_000, 1_250_000],
		"seed": [1_500_000, 2_500_000, 4_000_000, 6_000_000],
		"series_a": [4_000_000, 7_000_000, 10_000_000, 14_000_000],
	}
	var narratives := [0, 35, 55, 75]
	for stage_value in stage_amounts:
		var stage := str(stage_value)
		var last_amount := -1
		for index in narratives.size():
			var quote: Dictionary = business.financing_quote(stage, narratives[index])
			_check(bool(quote.get("ok", false)), "%s financing quote exists at narrative band %d" % [stage, index])
			_check(int(quote.get("amount_usd", -1)) == int(stage_amounts[stage][index]), "%s amount is locked to narrative band %d" % [stage, index])
			_check(int(quote.get("amount_usd", 0)) > last_amount, "%s financing amount rises monotonically with narrative" % stage)
			last_amount = int(quote.get("amount_usd", 0))
			_check(int(quote.get("narrative_basis", -1)) == narratives[index], "%s quote records only its narrative basis" % stage)
	_check(not bool(business.financing_quote("ipo", 100).get("ok", true)), "unsupported financing stage is rejected")

	var low_capability = BusinessSystem.new()
	var high_capability = BusinessSystem.new()
	var low_result: Dictionary = low_capability.apply_decision("raise_seed", "clean", {
		"transaction_id": "seed:low_capability", "total_week": 22,
		"narrative": 61, "capability": 0, "coherence": 0, "cash_usd": 1,
	})
	var high_result: Dictionary = high_capability.apply_decision("raise_seed", "clean", {
		"transaction_id": "seed:high_capability", "total_week": 22,
		"narrative": 61, "capability": 100, "coherence": 100, "cash_usd": 999_999_999,
	})
	_check(bool(low_result.get("ok", false)) and bool(high_result.get("ok", false)), "same-narrative financing resolves at both capability extremes")
	_check(int(low_result["amount_usd"]) == int(high_result["amount_usd"]), "financing amount is invariant to capability")
	_check(int(low_result["pre_money_usd"]) == int(high_result["pre_money_usd"]), "default valuation is invariant to capability")
	_check(int(low_result["shares_issued"]) == int(high_result["shares_issued"]), "financing share issuance is invariant to capability and unrelated context")
	_check(int(low_result["narrative_basis"]) == 61 and int(high_result["narrative_basis"]) == 61, "financing audit records the sole company-state input")

	var lower_story = BusinessSystem.new()
	var lower_result: Dictionary = lower_story.apply_decision("raise_seed", "clean", {"transaction_id": "seed:lower", "total_week": 22, "narrative": 40, "capability": 100})
	_check(int(lower_result["amount_usd"]) < int(high_result["amount_usd"]), "changing narrative changes financing amount")

	var clean = BusinessSystem.new()
	var headline = BusinessSystem.new()
	var delegated = BusinessSystem.new()
	var clean_result: Dictionary = clean.apply_decision("raise_seed", "clean", {"transaction_id": "choice:clean", "narrative": 60, "total_week": 22})
	var headline_result: Dictionary = headline.apply_decision("raise_seed", "headline", {"transaction_id": "choice:headline", "narrative": 60, "total_week": 22})
	var delegate_result: Dictionary = delegated.apply_decision("raise_seed", "delegate", {"transaction_id": "choice:delegate", "narrative": 60, "total_week": 22})
	_check(int(clean_result["amount_usd"]) == int(headline_result["amount_usd"]) and int(clean_result["amount_usd"]) == int(delegate_result["amount_usd"]), "term choice changes governance and dilution but never fundraising amount")
	_check(int(headline_result["pre_money_usd"]) > int(clean_result["pre_money_usd"]), "headline term offers a higher pre-money valuation")
	_check(int(delegate_result["effects"]["author_weight"]) > 0, "delegated negotiation exposes its authorship price")


func _test_safe_priced_round_and_idempotency() -> void:
	var business = BusinessSystem.new()
	var initial_cash := int(business.ledger["cash_usd"])
	var safe: Dictionary = business.issue_post_money_safe(
		"safe:juniper", "juniper_ventures", "preseed", 60,
		{"signed_week": 7, "pro_rata": true}
	)
	_check(bool(safe.get("ok", false)), "post-money SAFE closes through the public capital API")
	_check(int(safe["amount_usd"]) == 750_000 and int(safe["post_money_cap_usd"]) == 8_000_000, "SAFE amount and cap come from the narrative-stage quote")
	_check(int(safe["estimated_ownership_ppm"]) == 93_750, "SAFE stores an exact post-money ownership estimate in ppm")
	_check(int(business.ledger["cash_usd"]) == initial_cash + 750_000, "SAFE proceeds enter the USD ledger")
	_check(Array(business.capital["safes"]).size() == 1, "SAFE is represented by one durable security record")
	_check(str(business.capital["safes"][0]["status"]) == "outstanding", "SAFE remains outstanding before a priced round")
	var safe_replay = business.issue_post_money_safe("safe:juniper", "relay_syndicate", "preseed", 100)
	_check(bool(safe_replay.get("idempotent", false)), "SAFE transaction id is idempotent")
	_check(Array(business.capital["safes"]).size() == 1 and int(business.ledger["cash_usd"]) == initial_cash + 750_000, "SAFE replay cannot add a security or cash")
	_check(not bool(business.issue_post_money_safe("safe:bad", "unknown", "preseed", 60).get("ok", true)), "unknown SAFE investor is rejected")
	_check(not bool(business.issue_post_money_safe("safe:wrong_stage", "juniper_ventures", "seed", 60).get("ok", true)), "priced stage cannot be issued as SAFE")

	var before_round_shares = business.fully_diluted_shares()
	var round: Dictionary = business.close_priced_round(
		"round:seed", "north_quay_capital", "seed", 60,
		{"round_id": "seed_01", "option_pool_target_bp": 1_200, "board_seat": "director"}
	)
	_check(bool(round.get("ok", false)), "priced Seed round closes through the public capital API")
	_check(int(round["amount_usd"]) == 4_000_000 and int(round["pre_money_usd"]) == 16_000_000, "Seed amount and default pre-money derive from stage and narrative")
	_check(Array(round["converted_safe_ids"]) == ["safe:juniper"], "priced round converts every outstanding SAFE exactly once")
	_check(str(business.capital["safes"][0]["status"]) == "converted", "SAFE records its converted status")
	_check(int(business.capital["safes"][0]["conversion_shares"]) > 0, "SAFE conversion issues exact integer shares")
	_check(int(round["option_pool_top_up_shares"]) > 0, "pre-money option pool top-up issues integer shares")
	_check(int(round["shares_issued"]) > 0, "priced investor receives integer preferred shares")
	_check(business.fully_diluted_shares() > before_round_shares, "SAFE, pool top-up, and preferred issuance expand fully diluted shares")
	_check(int(business.capital["authorized_shares"]) >= business.fully_diluted_shares(), "authorized share capacity expands to cover issuance")
	_check(_cap_bp_sum(business.cap_table()) == 10_000, "post-round cap table basis points remain exact")
	_check(int(business.ledger["cash_usd"]) == initial_cash + 750_000 + 4_000_000, "priced proceeds enter cash without re-adding converted SAFE cash")
	_check(Array(business.capital["rounds"]).size() == 1, "one priced round record is appended")
	_check(_board_has(business, "north_quay_capital", "director"), "negotiated director seat enters board state")
	var round_replay = business.close_priced_round("round:seed", "civic_compute_fund", "series_a", 100)
	_check(bool(round_replay.get("idempotent", false)), "priced round transaction id is idempotent")
	_check(Array(business.capital["rounds"]).size() == 1, "round replay cannot append a second round")
	_check(int(business.ledger["cash_usd"]) == initial_cash + 750_000 + 4_000_000, "round replay cannot add cash twice")
	_check(not bool(business.close_priced_round("round:wrong", "north_quay_capital", "preseed", 60).get("ok", true)), "SAFE stage cannot close as priced preferred")


func _test_outstanding_safe_pro_forma_and_liquidity_exit() -> void:
	var business = BusinessSystem.new()
	var safe: Dictionary = business.issue_post_money_safe(
		"safe:liquidity", "juniper_ventures", "preseed", 60,
		{"signed_week": 7, "post_money_cap_usd": 8_000_000}
	)
	_check(bool(safe.get("ok", false)), "outstanding SAFE fixture closes before any priced round")
	var issued_total := business.fully_diluted_shares()
	var table: Dictionary = business.cap_table()
	_check(bool(table.get("includes_outstanding_safes", false)), "cap table declares that outstanding SAFE ownership is included")
	_check(str(table.get("ownership_basis", "")) == "pro_forma_including_outstanding_safes", "cap table exposes an explicit pro-forma ownership basis")
	_check(str(table.get("ownership_basis_label", "")) == "PRO FORMA · SAFE INCLUDED", "cap table supplies a truthful display label while a SAFE is outstanding")
	_check(int(table.get("issued_fully_diluted_shares", 0)) == issued_total, "pro-forma disclosure retains the issued fully diluted subtotal")
	_check(int(table.get("fully_diluted_shares", 0)) > issued_total, "pro-forma disclosure adds projected SAFE conversion shares to its denominator")
	var safe_row := _cap_row(table, "juniper_ventures")
	_check(not safe_row.is_empty() and bool(safe_row.get("is_pro_forma", false)), "outstanding SAFE investor receives a visible pro-forma cap-table row")
	_check(int(safe_row.get("issued_shares", -1)) == 0 and int(safe_row.get("pro_forma_safe_shares", 0)) > 0, "SAFE row distinguishes projected shares from issued shares")
	_check(int(safe_row.get("ownership_bp", 0)) in [937, 938], "SAFE row reflects the authored 9.375 percent post-money estimate within basis-point rounding")
	_check(int(_cap_row(table, "founder").get("ownership_bp", 10_000)) < 5_000, "founder display is diluted by the outstanding SAFE instead of staying at fifty percent")
	_check(_cap_bp_sum(table) == 10_000, "pro-forma cap-table rows still sum to exactly one hundred percent")

	var capital_before: Dictionary = business.capital.duplicate(true)
	var low: Dictionary = business.exit_waterfall(500_000)
	_check(int(low.get("total_paid_usd", 0)) == 500_000, "pre-priced-round SAFE waterfall conserves a low exit")
	_check(int(Dictionary(low.get("payouts_by_owner", {})).get("juniper_ventures", 0)) == 500_000, "SAFE holder receives the entire exit below its 1x cash-out amount")
	_check(int(Dictionary(low.get("payouts_by_owner", {})).get("founder", 0)) == 0, "common receives nothing while the outstanding SAFE preference is under water")
	_check(Array(low.get("outstanding_safe_ids", [])) == ["safe:liquidity"], "waterfall identifies the outstanding SAFE included in the liquidity event")
	var high: Dictionary = business.exit_waterfall(20_000_000)
	_check(int(high.get("total_paid_usd", 0)) == 20_000_000, "pre-priced-round SAFE waterfall conserves a high exit")
	_check(int(Dictionary(high.get("payouts_by_owner", {})).get("juniper_ventures", 0)) > int(safe.get("amount_usd", 0)), "SAFE holder takes as-converted value when it beats 1x")
	_check(not Array(high.get("preferred_taking_preference", [])).any(func(key: Variant) -> bool: return str(key).begins_with("liquidity_safe:")), "high-upside SAFE converts instead of participating twice")
	_check(business.capital == capital_before and str(business.capital["safes"][0]["status"]) == "outstanding", "liquidity preview is pure and never converts or mutates the SAFE")


func _test_option_grants_and_cap_table_invariants() -> void:
	var business = BusinessSystem.new()
	var total_before = business.fully_diluted_shares()
	var grant = business.grant_options("option:chen", "chen_xiaoyu", 120_000)
	_check(bool(grant.get("ok", false)), "employee option grant succeeds within the pool")
	_check(int(grant["pool_remaining_shares"]) == 880_000, "option grant decrements unissued pool exactly")
	_check(business.fully_diluted_shares() == total_before, "moving shares from pool to employee does not change fully diluted capitalization")
	_check(_cap_owner_shares(business.cap_table(), "chen_xiaoyu") == 120_000, "employee option holder appears in cap table")
	_check(_cap_owner_shares(business.cap_table(), "option_pool") == 880_000, "remaining unissued pool appears separately")
	var replay = business.grant_options("option:chen", "chen_xiaoyu", 999_999)
	_check(bool(replay.get("idempotent", false)), "option grant transaction is idempotent")
	_check(_cap_owner_shares(business.cap_table(), "chen_xiaoyu") == 120_000, "option replay cannot increase the grant")
	var second = business.grant_options("option:chen:refresh", "chen_xiaoyu", 30_000, 104, 26)
	_check(bool(second.get("ok", false)), "same employee may receive a later refresh grant")
	_check(_cap_owner_shares(business.cap_table(), "chen_xiaoyu") == 150_000, "refresh grant aggregates under the employee owner")
	_check(business.fully_diluted_shares() == total_before, "multiple pool transfers preserve fully diluted total")
	_check(not bool(business.grant_options("option:too_large", "candidate", 2_000_000).get("ok", true)), "grant larger than remaining pool is rejected")
	_check(not bool(business.grant_options("option:invalid", "candidate", 0).get("ok", true)), "zero-share option grant is rejected")
	_check(_cap_bp_sum(business.cap_table()) == 10_000, "option grants preserve exact displayed cap-table total")
	for row_value in Array(business.cap_table()["rows"]):
		var row: Dictionary = row_value
		_check(int(row["shares"]) >= 0 and int(row["ownership_bp"]) >= 0, "cap table rows never contain negative shares or ownership")


func _test_option_departure_vesting_and_idempotency() -> void:
	var before_cliff = BusinessSystem.new()
	var before_total := before_cliff.fully_diluted_shares()
	_check(bool(before_cliff.grant_options("departure:pre:grant", "pre_cliff", 208_000).get("ok", false)), "pre-cliff departure fixture receives a standard grant")
	var before: Dictionary = before_cliff.process_option_departure("departure:pre", "pre_cliff", 51)
	_check(bool(before.get("ok", false)) and not bool(before.get("cliff_reached", true)), "departure before week 52 does not reach the cliff")
	_check(int(before.get("vested_shares", -1)) == 0 and int(before.get("unvested_shares", -1)) == 208_000, "departure before the cliff forfeits the full grant")
	_check(_cap_owner_shares(before_cliff.cap_table(), "pre_cliff") == 0, "pre-cliff employee retains no vested option shares")
	_check(_cap_owner_shares(before_cliff.cap_table(), "option_pool") == 1_000_000, "pre-cliff unvested options return to the pool")
	_check(before_cliff.fully_diluted_shares() == before_total, "pre-cliff forfeiture preserves fully diluted capitalization")

	var linear = BusinessSystem.new()
	_check(bool(linear.grant_options("departure:linear:grant", "linear_employee", 208_000).get("ok", false)), "linear vesting fixture receives a standard grant")
	var halfway: Dictionary = linear.process_option_departure("departure:linear", "linear_employee", 104)
	_check(bool(halfway.get("cliff_reached", false)) and not bool(halfway.get("fully_vested", true)), "week 104 is after the cliff but before full vesting")
	_check(int(halfway.get("vested_shares", -1)) == 104_000 and int(halfway.get("unvested_shares", -1)) == 104_000, "post-cliff options vest linearly over 208 weeks")
	_check(_cap_owner_shares(linear.cap_table(), "linear_employee") == 104_000, "vested half remains with the departing employee")
	_check(_cap_owner_shares(linear.cap_table(), "option_pool") == 896_000, "only the unvested half returns to the option pool")

	var fully_vested = BusinessSystem.new()
	_check(bool(fully_vested.grant_options("departure:full:grant", "veteran", 80_000).get("ok", false)), "full-vesting fixture receives options")
	var full: Dictionary = fully_vested.process_option_departure("departure:full", "veteran", 260)
	_check(bool(full.get("fully_vested", false)) and int(full.get("vested_shares", -1)) == 80_000, "service beyond 208 weeks preserves the entire vested grant")
	_check(int(full.get("unvested_shares", -1)) == 0 and _cap_owner_shares(fully_vested.cap_table(), "option_pool") == 920_000, "fully vested departure returns nothing to the pool")

	var pool_after_first := _cap_owner_shares(linear.cap_table(), "option_pool")
	var replay: Dictionary = linear.process_option_departure("departure:linear", "linear_employee", 208)
	_check(bool(replay.get("idempotent", false)) and int(replay.get("service_weeks", -1)) == 104, "same departure transaction replays its original vesting result")
	_check(_cap_owner_shares(linear.cap_table(), "option_pool") == pool_after_first and _cap_owner_shares(linear.cap_table(), "linear_employee") == 104_000, "same-id departure replay cannot recover options twice")
	var alternate_replay: Dictionary = linear.process_option_departure("departure:linear:alternate", "linear_employee", 208)
	_check(bool(alternate_replay.get("idempotent", false)) and str(alternate_replay.get("reason", "")) == "option_departure_already_processed", "fresh transaction id cannot resettle an already departed holder")
	_check(_cap_owner_shares(linear.cap_table(), "option_pool") == pool_after_first and _cap_owner_shares(linear.cap_table(), "linear_employee") == 104_000, "alternate-id replay also leaves pool and vested holdings unchanged")

	var unknown = BusinessSystem.new()
	var unknown_pool_before := _cap_owner_shares(unknown.cap_table(), "option_pool")
	var missing: Dictionary = unknown.process_option_departure("departure:missing", "not_a_holder", 104)
	_check(not bool(missing.get("ok", true)) and str(missing.get("reason", "")) == "unknown_option_holder", "unknown option holder is rejected explicitly")
	_check(_cap_owner_shares(unknown.cap_table(), "option_pool") == unknown_pool_before, "unknown-holder departure cannot mutate the pool")


func _test_non_participating_exit_waterfall() -> void:
	var business = BusinessSystem.new()
	var round: Dictionary = business.close_priced_round(
		"waterfall:seed", "north_quay_capital", "seed", 10,
		{"option_pool_target_bp": 0, "board_seat": "observer"}
	)
	_check(bool(round.get("ok", false)) and int(round["amount_usd"]) == 1_500_000, "waterfall fixture closes a low-band Seed round")
	var low: Dictionary = business.exit_waterfall(500_000)
	_check(int(low["total_paid_usd"]) == 500_000, "low exit waterfall pays every available dollar exactly once")
	_check(int(Dictionary(low["payouts_by_owner"]).get("north_quay_capital", 0)) == 500_000, "preferred investor receives the entire sub-preference exit")
	_check(int(Dictionary(low["payouts_by_owner"]).get("founder", 0)) == 0, "common receives nothing below the preference stack")
	_check(not Dictionary(low["payouts_by_owner"]).has("option_pool"), "unissued option pool never receives exit proceeds")
	_check(Array(low["preferred_taking_preference"]).size() == 1, "low exit records preferred taking its 1x preference")

	var medium: Dictionary = business.exit_waterfall(8_000_000)
	_check(int(medium["total_paid_usd"]) == 8_000_000, "medium exit waterfall conserves proceeds exactly")
	_check(int(Dictionary(medium["payouts_by_owner"]).get("north_quay_capital", 0)) >= 1_500_000, "non-participating preferred gets at least its 1x floor when superior")
	_check(int(Dictionary(medium["payouts_by_owner"]).get("founder", 0)) > 0, "common participates in residual after preference")
	_check(int(Dictionary(medium["payouts_by_owner"]).get("lin_yue", 0)) > 0, "Lin Yue remains an economic holder at exit")

	var high: Dictionary = business.exit_waterfall(100_000_000)
	_check(int(high["total_paid_usd"]) == 100_000_000, "high exit waterfall conserves proceeds exactly")
	_check(Array(high["preferred_taking_preference"]).is_empty(), "preferred converts when as-converted value beats 1x preference")
	_check(int(Dictionary(high["payouts_by_owner"]).get("north_quay_capital", 0)) > 1_500_000, "converted preferred shares in high upside without participating twice")
	var zero: Dictionary = business.exit_waterfall(0)
	_check(int(zero["total_paid_usd"]) == 0, "zero exit produces zero payout")

	var stacked = BusinessSystem.new()
	_check(bool(stacked.close_priced_round("waterfall:stack:seed", "north_quay_capital", "seed", 0, {"option_pool_target_bp": 0}).get("ok", false)), "stacked waterfall closes Seed preferred")
	_check(bool(stacked.close_priced_round("waterfall:stack:a", "civic_compute_fund", "series_a", 100, {"option_pool_target_bp": 0}).get("ok", false)), "stacked waterfall closes Series A preferred")
	var scarce: Dictionary = stacked.exit_waterfall(12_000_000)
	_check(int(scarce["total_paid_usd"]) == 12_000_000, "scarce multi-series exit still conserves every dollar")
	_check(int(Dictionary(scarce["payouts_by_owner"]).get("north_quay_capital", 0)) > 0, "when preferences exhaust proceeds, smaller preferred joins the pari-passu stack")
	_check(int(Dictionary(scarce["payouts_by_owner"]).get("civic_compute_fund", 0)) > 0, "larger preferred receives its pro-rata share of the exhausted preference stack")
	_check(int(Dictionary(scarce["payouts_by_owner"]).get("founder", 0)) == 0, "common receives zero while the aggregate 1x stack is under water")


func _test_named_investors_and_relationships() -> void:
	var business = BusinessSystem.new()
	var investor_states: Array = business.investor_public_state()
	var expected_people := ["Asha Raman", "Daniel Ortiz", "Maya Chen", "Owen Bell"]
	var people: Array[String] = []
	for investor_value in investor_states:
		var investor: Dictionary = investor_value
		people.append(str(investor["person"]))
		_check(not str(investor["firm"]).is_empty() and not str(investor["role"]).is_empty(), "named investor has a firm and concrete role")
		_check(Array(investor["stages"]).size() >= 1 and Array(investor["thesis"]).size() >= 1, "named investor has stage and thesis identity")
		_check(int(investor["check_min_usd"]) > 0 and int(investor["check_max_usd"]) >= int(investor["check_min_usd"]), "investor dossier exposes a concrete check range")
		_check(Array(investor["diligence"]).size() >= 2, "investor dossier exposes concrete diligence priorities")
	people.sort()
	_check(people == expected_people, "the four investor actors are stable and explicitly fictional")
	var before: Dictionary = _investor_state(business, "juniper_ventures")
	var safe = business.issue_post_money_safe("relation:safe", "juniper_ventures", "preseed", 60)
	_check(bool(safe.get("ok", false)), "investor relationship fixture closes financing")
	var after: Dictionary = _investor_state(business, "juniper_ventures")
	_check(int(after["invested_usd"]) == int(safe["amount_usd"]), "investor relation aggregates invested capital")
	_check(int(after["trust"]) > int(before["trust"]), "closing builds persistent investor trust")
	_check(int(after.get("conviction", 0)) == 60, "investor conviction remembers the narrative used at closing")
	var update = business.apply_decision("investor_update", "raw", {"transaction_id": "relation:update", "investor_id": "juniper_ventures", "total_week": 10})
	_check(bool(update.get("ok", false)) and int(update.get("trust_delta", 0)) == 6, "raw monthly update changes persistent relationship")
	var updated: Dictionary = _investor_state(business, "juniper_ventures")
	_check(int(updated["last_update_week"]) == 10, "investor update week is remembered")
	_check(int(updated["board_support"]) > int(after["board_support"]), "investor update affects later board support")
	var delegated = business.apply_decision("investor_update", "delegate", {"transaction_id": "relation:update:ai", "investor_id": "juniper_ventures", "total_week": 11})
	_check(int(delegated["effects"]["author_weight"]) == 3, "delegated investor update records authorship cost")
	_check(not bool(business.apply_decision("investor_update", "raw", {"transaction_id": "bad:update", "investor_id": "imaginary"}).get("ok", true)), "unknown investor update is rejected")


func _test_market_determinism_public_information_and_rng_isolation() -> void:
	var first = BusinessSystem.new()
	var second = BusinessSystem.new()
	for week in range(1, 13):
		var first_tick: Dictionary = first.tick_week({"total_week": week, "settle_operations": false})
		var second_tick: Dictionary = second.tick_week({"total_week": week, "settle_operations": false})
		_check(first_tick == second_tick, "same seed produces identical public market result in week %d" % week)
		_check(int(first_tick.get("world_cash_delta_usd", 99)) == 0, "week %d market event never directly changes player cash" % week)
		_check(not Dictionary(first_tick.get("public_feed", {})).is_empty(), "week %d emits one public market signal" % week)
	_check(first.market == second.market, "same seed produces identical complete hidden competitor state")
	_check(Array(first.market["public_feed"]).size() == 12, "market tape emits one restrained headline per week")
	_check(int(first.market["talent_pressure_bp"]) >= 8_000 and int(first.market["talent_pressure_bp"]) <= 20_000, "talent pressure remains bounded")
	_check(int(first.market["price_pressure_bp"]) >= 7_000 and int(first.market["price_pressure_bp"]) <= 20_000, "price pressure remains bounded")
	_check(int(first.market["category_demand"]) >= 0 and int(first.market["category_demand"]) <= 100, "category demand remains bounded")
	for competitor_value in Dictionary(first.market["competitors"]).values():
		var competitor: Dictionary = competitor_value
		_check(int(competitor["capability"]) >= 0 and int(competitor["capability"]) <= 100, "competitor capability remains bounded")
		_check(int(competitor["narrative"]) >= 0 and int(competitor["narrative"]) <= 100, "competitor narrative remains bounded")
		_check(int(competitor["cash_usd"]) >= 0, "competitor cash never becomes negative")

	var save_mid = first.to_save()
	var restored = BusinessSystem.new()
	_check(restored.from_save(save_mid), "market state restores from a mid-campaign save")
	var next_first = first.tick_week({"total_week": 13, "settle_operations": false})
	var next_restored = restored.tick_week({"total_week": 13, "settle_operations": false})
	_check(next_first == next_restored and first.market == restored.market, "saved market RNG reproduces the next weekly tick exactly")

	var isolation = BusinessSystem.new()
	var market_rng_before := int(isolation.market["rng_state"])
	var policy_rng_before := int(isolation.policy["rng_state"])
	var finance = isolation.apply_decision("raise_seed", "clean", {"transaction_id": "isolation:finance", "narrative": 60, "capability": 100, "total_week": 22})
	_check(bool(finance.get("ok", false)), "RNG isolation financing fixture resolves")
	_check(int(isolation.market["rng_state"]) == market_rng_before, "capital transaction does not consume market RNG")
	_check(int(isolation.policy["rng_state"]) == policy_rng_before, "capital transaction does not consume policy RNG")
	var grant = isolation.apply_decision("apply_grant", "manual", {"transaction_id": "isolation:grant", "capability": 90, "coherence": 70, "narrative": 1, "total_week": 14})
	_check(bool(grant.get("ok", false)), "RNG isolation grant fixture resolves")
	_check(int(isolation.market["rng_state"]) == market_rng_before, "policy review does not consume market RNG")
	_check(int(isolation.policy["rng_state"]) != policy_rng_before, "policy review consumes only policy RNG")
	var policy_after_grant := int(isolation.policy["rng_state"])
	isolation.tick_week({"total_week": 1, "settle_operations": false})
	_check(int(isolation.policy["rng_state"]) == policy_after_grant, "ordinary market tick without due policy item leaves policy RNG untouched")
	_check(int(isolation.market["rng_state"]) != market_rng_before, "market tick consumes its own RNG stream")


func _test_skipped_week_external_catch_up_and_single_player_settlement() -> void:
	var sequential = BusinessSystem.new()
	var jumped = BusinessSystem.new()
	for week in range(1, 11):
		sequential.tick_week({"total_week": week, "settle_operations": false})
	var jump_result: Dictionary = jumped.tick_week({"total_week": 10, "settle_operations": false})
	_check(bool(jump_result.get("ok", false)), "a forward week jump is accepted")
	_check(jumped.market == sequential.market, "forward jump catches up every hidden competitor and market week exactly")
	_check(jumped.policy == sequential.policy, "forward jump processes every elapsed policy-calendar week exactly")
	_check(Array(jumped.market["public_feed"]).size() == 10, "forward jump emits one restrained market signal for every elapsed week")
	_check(int(Dictionary(jump_result.get("public_feed", {})).get("week", -1)) == 10, "jump result presents the target week's public signal")
	_check(int(jumped.ledger["cash_usd"]) == 200_000, "external catch-up without settlement cannot touch player cash")

	var old_save_source = BusinessSystem.new()
	for week in range(1, 4):
		old_save_source.tick_week({"total_week": week, "settle_operations": false})
	var old_save_payload: Dictionary = old_save_source.to_save()
	var resumed_sequential = BusinessSystem.new()
	var resumed_jump = BusinessSystem.new()
	_check(resumed_sequential.from_save(old_save_payload) and resumed_jump.from_save(old_save_payload), "mid-campaign market save loads for catch-up regression")
	for week in range(4, 9):
		resumed_sequential.tick_week({"total_week": week, "settle_operations": false})
	resumed_jump.tick_week({"total_week": 8, "settle_operations": false})
	_check(resumed_jump.market == resumed_sequential.market and resumed_jump.policy == resumed_sequential.policy, "old save resumed several weeks ahead converges with sequential external simulation")

	var dated_policy_sequential = BusinessSystem.new()
	var dated_policy_jump = BusinessSystem.new()
	for business in [dated_policy_sequential, dated_policy_jump]:
		business.apply_decision("public_comment", "strong_disclosure", {"transaction_id": "jump:comment", "total_week": 2})
	for week in range(1, 9):
		dated_policy_sequential.tick_week({"total_week": week, "settle_operations": false})
	dated_policy_jump.tick_week({"total_week": 8, "settle_operations": false})
	_check(dated_policy_jump.policy == dated_policy_sequential.policy, "jump resolves dated policy work on the same elapsed week as sequential play")
	var resolved_comment: Dictionary = Array(dated_policy_jump.policy["comments"])[0]
	_check(str(resolved_comment.get("status", "pending")) != "pending", "intermediate policy deadline is not skipped by a forward jump")
	_check(int(Dictionary(Array(dated_policy_jump.policy["public_feed"])[0]).get("week", -1)) == 5, "policy resolution keeps its actual due-week timestamp during catch-up")

	var settlement = BusinessSystem.new()
	_check(bool(settlement.add_commitment("jump:add", "jump_audit", "security", 30_000, 4, true).get("ok", false)), "jump settlement fixture records a due commitment")
	var settled: Dictionary = settlement.tick_week({"total_week": 10})
	_check(int(settlement.ledger["cash_usd"]) == 150_000, "week jump charges one target-week operating cost plus one due commitment, not every skipped week")
	_check(int(Dictionary(settled.get("operating", {})).get("cash_delta_usd", 0)) == -50_000, "jump settlement reports only the explicit target-week ledger movement")
	var weekly_journal_count := 0
	for journal_value in Array(settlement.ledger["journal"]):
		if journal_value is Dictionary and str(Dictionary(journal_value).get("category", "")) == "weekly_operations":
			weekly_journal_count += 1
	_check(weekly_journal_count == 1, "catch-up writes exactly one player weekly-operations journal entry")
	var cash_after_first_settlement := int(settlement.ledger["cash_usd"])
	var replay: Dictionary = settlement.tick_week({"total_week": 10})
	_check(bool(replay.get("idempotent", false)) and int(settlement.ledger["cash_usd"]) == cash_after_first_settlement, "replaying a caught-up target week cannot settle player cash twice")


func _test_policy_program_semantics_and_capability_gate() -> void:
	var low_capability = BusinessSystem.new()
	var high_capability = BusinessSystem.new()
	var low_grant: Dictionary = low_capability.apply_decision("apply_grant", "manual", {
		"transaction_id": "grant:low", "total_week": 14,
		"capability": 10, "coherence": 50, "narrative": 100,
	})
	var high_grant: Dictionary = high_capability.apply_decision("apply_grant", "manual", {
		"transaction_id": "grant:high", "total_week": 14,
		"capability": 90, "coherence": 50, "narrative": 0,
	})
	_check(bool(low_grant.get("ok", false)) and bool(high_grant.get("ok", false)), "grant review resolves at both capability extremes")
	_check(not bool(low_grant["approved"]) and bool(high_grant["approved"]), "grant selection reads technical capability")
	_check(int(high_grant["technical_score"]) - int(low_grant["technical_score"]) == 560, "grant score delta equals capability delta times its locked coefficient")
	_check(int(low_grant["cash_received_usd"]) == 0 and int(high_grant["cash_received_usd"]) == 75_000, "grant first tranche is non-dilutive and paid only after selection")
	_check(Array(high_capability.capital["rounds"]).is_empty() and Array(high_capability.capital["safes"]).is_empty(), "grant cash creates no shares or security")

	var narrative_zero = BusinessSystem.new()
	var narrative_hundred = BusinessSystem.new()
	var grant_zero: Dictionary = narrative_zero.apply_decision("apply_grant", "manual", {"transaction_id": "grant:n0", "capability": 70, "coherence": 60, "narrative": 0, "total_week": 14})
	var grant_hundred: Dictionary = narrative_hundred.apply_decision("apply_grant", "manual", {"transaction_id": "grant:n100", "capability": 70, "coherence": 60, "narrative": 100, "total_week": 14})
	_check(int(grant_zero["technical_score"]) == int(grant_hundred["technical_score"]) and bool(grant_zero["approved"]) == bool(grant_hundred["approved"]), "grant outcome is invariant to narrative when technical inputs and policy RNG match")

	var high_cash_after_first := int(high_capability.ledger["cash_usd"])
	var milestone: Dictionary = high_capability.apply_decision("complete_grant_milestone", "submit", {"transaction_id": "grant:milestone", "capability": 65, "total_week": 20})
	_check(bool(milestone.get("passed", false)) and int(milestone["cash_received_usd"]) == 125_000, "grant second tranche requires the technical milestone")
	_check(int(high_capability.ledger["cash_usd"]) == high_cash_after_first + 125_000, "milestone payment enters cash exactly once")
	var milestone_replay = high_capability.apply_decision("complete_grant_milestone", "delegate", {"transaction_id": "grant:milestone", "capability": 100, "total_week": 20})
	_check(bool(milestone_replay.get("idempotent", false)) and int(high_capability.ledger["cash_usd"]) == high_cash_after_first + 125_000, "grant milestone replay cannot double-pay")

	var tax = BusinessSystem.new()
	var tax_cash_before := int(tax.ledger["cash_usd"])
	var tax_credit: Dictionary = tax.apply_decision("tax_credit", "accept", {"transaction_id": "tax:accept", "total_week": 16})
	_check(bool(tax_credit.get("accepted", false)) and int(tax_credit["deferred_tax_credit_usd"]) == 300_000, "tax incentive creates a deferred tax asset")
	_check(int(tax_credit["cash_received_usd"]) == 0 and int(tax.ledger["cash_usd"]) == tax_cash_before, "pre-profit tax credit never pretends to be immediate cash")
	_check(int(tax.policy["job_commitment"]) == 20 and int(tax.policy["investment_commitment_usd"]) == 1_500_000, "tax credit records jobs and investment commitments")
	var tax_use: Dictionary = tax.apply_decision("realize_tax_credit", "apply", {"transaction_id": "tax:use", "tax_liability_usd": 80_000})
	_check(int(tax_use["tax_liability_offset_usd"]) == 80_000, "tax credit offsets only actual tax liability")
	_check(int(tax.policy["deferred_tax_credit_usd"]) == 220_000 and int(tax.ledger["cash_usd"]) == tax_cash_before, "using a credit reduces the deferred asset without manufacturing cash")

	var pilot = BusinessSystem.new()
	var pilot_cash_before := int(pilot.ledger["cash_usd"])
	var bid: Dictionary = pilot.apply_decision("government_pilot", "bid", {"transaction_id": "pilot:bid", "capability": 90, "product_fit": 80, "narrative": 0, "total_week": 18})
	_check(bool(bid.get("awarded", false)), "strong capability can win a government pilot")
	_check(int(bid["cash_received_usd"]) == 0 and int(pilot.ledger["cash_usd"]) == pilot_cash_before, "pilot award pays no cash before delivery")
	_check(bool(pilot.policy["government_contractor"]), "awarded pilot records government-contractor status")
	var delivered: Dictionary = pilot.apply_decision("complete_pilot", "deliver", {"transaction_id": "pilot:deliver", "capability": 70, "total_week": 22})
	_check(bool(delivered.get("passed", false)) and int(delivered["cash_received_usd"]) == 250_000, "pilot cash arrives only after capable delivery")
	_check(int(pilot.ledger["mrr_usd"]) == 25_000 and int(pilot.ledger["contracted_arr_usd"]) == 300_000, "completed pilot becomes concrete recurring and contracted revenue")

	var comment = BusinessSystem.new()
	var filed: Dictionary = comment.apply_decision("public_comment", "strong_disclosure", {"transaction_id": "comment:file", "total_week": 30})
	_check(bool(filed.get("ok", false)) and int(filed["resolution_week"]) == 33, "public comment has a delayed resolution window")
	_check(str(comment.policy["issues"]["eval_disclosure"]["stage"]) == "monitoring", "filing a comment does not instantly rewrite regulation")
	var comment_cash := int(comment.ledger["cash_usd"])
	var resolved_tick = comment.tick_week({"total_week": 33, "settle_operations": false})
	_check(bool(resolved_tick.get("ok", false)) and str(comment.policy["issues"]["eval_disclosure"]["stage"]) == "final_rule", "agency resolves the comment after the delay")
	_check(int(comment.ledger["cash_usd"]) == comment_cash and int(resolved_tick["world_cash_delta_usd"]) == 0, "policy outcome never randomly deducts player cash")
	_check(Array(comment.policy["public_feed"]).size() == 1, "resolved rule produces a public policy record")

	var influence = BusinessSystem.new()
	var joined: Dictionary = influence.apply_decision("industry_coalition", "join", {"transaction_id": "coalition:join", "total_week": 28})
	_check(bool(joined.get("joined", false)) and int(joined["weekly_cost_delta_usd"]) == 1_500, "industry coalition has a transparent recurring cost")
	_check(int(influence.policy["industry_influence"]) == 10 and int(influence.policy["access"]) == 7, "coalition builds bounded influence and access")
	var influence_candidates: Array = influence.event_candidates({"chapter": 3, "week_in_chapter": 13, "total_week": 43})
	_check(_candidate_ids(influence_candidates).has("registered_lobbying"), "industry influence unlocks transparent registered lobbying as a later candidate")
	var lobby: Dictionary = influence.apply_decision("registered_lobbying", "engage", {"transaction_id": "lobby:engage", "total_week": 38})
	_check(bool(lobby.get("engaged", false)) and bool(lobby.get("lda_registered", false)), "lobbying spend above the modeled threshold creates disclosure status")
	_check(int(influence.policy["lobby_spend_usd_quarter"]) == 20_000, "lobbying records quarterly spend rather than a corruption abstraction")


func _test_event_candidates_and_decision_contracts() -> void:
	var business = BusinessSystem.new()
	var save_before = business.to_save()
	var chapter_one: Array = business.event_candidates({"chapter": 1, "week_in_chapter": 4, "total_week": 7})
	_check(_candidate_ids(chapter_one).has("raise_preseed"), "Chapter 1 week 4 exposes the preseed side decision")
	_check(business.to_save() == save_before, "event candidate query is pure and consumes no RNG")
	var chapter_two: Array = business.event_candidates({"chapter": 2, "week_in_chapter": 11, "total_week": 22})
	for expected_id in ["raise_seed", "apply_grant", "tax_credit", "government_pilot"]:
		_check(_candidate_ids(chapter_two).has(expected_id), "Chapter 2 candidates include %s" % expected_id)
	var priorities: Array[int] = []
	for candidate_value in chapter_two:
		priorities.append(int(Dictionary(candidate_value).get("priority", 0)))
	for index in range(1, priorities.size()):
		_check(priorities[index - 1] >= priorities[index], "candidate priorities are returned in deterministic descending order")
	var chapter_three: Array = business.event_candidates({"chapter": 3, "week_in_chapter": 12, "total_week": 35})
	for expected_id in ["raise_series_a", "public_comment", "industry_coalition"]:
		_check(_candidate_ids(chapter_three).has(expected_id), "Chapter 3 candidates include %s" % expected_id)

	var preseed: Dictionary = business.apply_decision("raise_preseed", "clean", {"transaction_id": "event:preseed", "narrative": 60, "capability": 0, "total_week": 7})
	_check(bool(preseed.get("ok", false)), "preseed candidate resolves through apply_decision")
	var after_preseed: Array = business.event_candidates({"chapter": 1, "week_in_chapter": 5, "total_week": 8})
	_check(not _candidate_ids(after_preseed).has("raise_preseed"), "closed preseed is removed from candidate pool")
	var replay = business.apply_decision("raise_preseed", "delegate", {"transaction_id": "event:preseed", "narrative": 100, "total_week": 7})
	_check(bool(replay.get("idempotent", false)) and str(replay.get("choice_id", "")) == "clean", "decision replay preserves the first committed choice")
	_check(not bool(business.apply_decision("raise_seed", "invalid", {"transaction_id": "event:invalid", "narrative": 60}).get("ok", true)), "invalid financing choice is rejected")
	_check(not bool(business.apply_decision("unknown", "x", {"transaction_id": "event:unknown"}).get("ok", true)), "unknown decision is rejected")

	var delegate = BusinessSystem.new()
	for decision_and_choice in [
		["raise_preseed", "delegate", {"narrative": 60, "total_week": 7}],
		["investor_update", "delegate", {"investor_id": "juniper_ventures", "total_week": 8}],
		["tax_credit", "delegate", {"total_week": 15}],
		["industry_coalition", "delegate", {"total_week": 28}],
	]:
		var decision_id := str(decision_and_choice[0])
		var context: Dictionary = Dictionary(decision_and_choice[2]).duplicate(true)
		context["transaction_id"] = "delegate:%s" % decision_id
		var delegated: Dictionary = delegate.apply_decision(decision_id, str(decision_and_choice[1]), context)
		_check(bool(delegated.get("ok", false)), "delegated %s decision resolves" % decision_id)
		_check(int(Dictionary(delegated.get("effects", {})).get("author_weight", 0)) > 0, "delegated %s decision exposes positive authorship cost" % decision_id)


func _test_save_round_trip_and_replay_boundaries() -> void:
	var business = BusinessSystem.new()
	_check(bool(business.set_weekly_cost("save:cost", "vendors", 4_250).get("ok", false)), "save fixture updates operating ledger")
	_check(bool(business.add_commitment("save:commit", "lease_deposit", "office", 45_000, 4, true).get("ok", false)), "save fixture records commitment")
	_check(bool(business.apply_decision("raise_preseed", "delegate", {"transaction_id": "save:safe", "narrative": 65, "total_week": 7}).get("ok", false)), "save fixture closes a SAFE")
	_check(bool(business.grant_options("save:option", "he_miao", 75_000).get("ok", false)), "save fixture grants options")
	_check(bool(business.apply_decision("tax_credit", "accept", {"transaction_id": "save:tax", "total_week": 14}).get("ok", false)), "save fixture accepts a tax credit")
	for week in range(1, 4):
		_check(bool(business.tick_week({"total_week": week}).get("ok", false)), "save fixture advances week %d" % week)
	var payload: Dictionary = business.to_save()
	var restored = BusinessSystem.new()
	_check(restored.from_save(payload), "complete business state loads from save payload")
	_check(restored.to_save() == payload, "save round trip preserves every deterministic domain field")
	_check(restored.public_state() == business.public_state(), "public business state is identical after load")
	var safe_cash := int(restored.ledger["cash_usd"])
	var safe_count := Array(restored.capital["safes"]).size()
	var replay = restored.apply_decision("raise_preseed", "clean", {"transaction_id": "save:safe", "narrative": 100, "total_week": 7})
	_check(bool(replay.get("idempotent", false)), "loaded decision transaction remains idempotent")
	_check(int(restored.ledger["cash_usd"]) == safe_cash and Array(restored.capital["safes"]).size() == safe_count, "loaded replay cannot duplicate cash or security")
	var next_original = business.tick_week({"total_week": 4})
	var next_restored = restored.tick_week({"total_week": 4})
	_check(next_original == next_restored, "loaded RNG and due commitments reproduce the next week exactly")
	_check(restored.to_save() == business.to_save(), "original and restored simulations converge after next tick")

	var invalid_version := payload.duplicate(true)
	invalid_version["save_version"] = 999
	var invalid_target = BusinessSystem.new()
	_check(not invalid_target.from_save(invalid_version), "unknown save version is rejected")
	var malformed := payload.duplicate(true)
	malformed["market"] = []
	_check(not invalid_target.from_save(malformed), "malformed domain dictionary is rejected")
	var negative_shares := payload.duplicate(true)
	negative_shares["capital"]["holders"]["founder"]["shares"] = -1
	_check(not invalid_target.from_save(negative_shares), "save with negative shares is rejected")
	var missing_investor := payload.duplicate(true)
	missing_investor["investors"].erase("juniper_ventures")
	_check(not invalid_target.from_save(missing_investor), "save missing a stable investor actor is rejected")
	var wrong_competitors := payload.duplicate(true)
	var competitor_payload: Dictionary = wrong_competitors["market"]["competitors"]
	competitor_payload.erase("morrow_ai")
	competitor_payload["impostor_inc"] = {}
	_check(not invalid_target.from_save(wrong_competitors), "save rejects a same-sized but non-canonical competitor roster")


func _candidate_ids(candidates: Array) -> Array[String]:
	var result: Array[String] = []
	for candidate_value in candidates:
		if candidate_value is Dictionary:
			result.append(str(Dictionary(candidate_value).get("decision_id", "")))
	return result


func _cap_owner_shares(table: Dictionary, owner_id: String) -> int:
	for row_value in Array(table.get("rows", [])):
		if row_value is Dictionary and str(Dictionary(row_value).get("owner_id", "")) == owner_id:
			return int(Dictionary(row_value).get("shares", 0))
	return 0


func _cap_row(table: Dictionary, owner_id: String) -> Dictionary:
	for row_value in Array(table.get("rows", [])):
		if row_value is Dictionary and str(Dictionary(row_value).get("owner_id", "")) == owner_id:
			return Dictionary(row_value)
	return {}


func _cap_bp_sum(table: Dictionary) -> int:
	var total := 0
	for row_value in Array(table.get("rows", [])):
		if row_value is Dictionary:
			total += int(Dictionary(row_value).get("ownership_bp", 0))
	return total


func _board_has(business, holder_id: String, kind: String) -> bool:
	for seat_value in Array(business.capital.get("board_seats", [])):
		if seat_value is Dictionary:
			var seat: Dictionary = seat_value
			if str(seat.get("holder_id", "")) == holder_id and str(seat.get("kind", "")) == kind:
				return true
	return false


func _investor_state(business, investor_id: String) -> Dictionary:
	return Dictionary(business.investors.get(investor_id, {})).duplicate(true)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
