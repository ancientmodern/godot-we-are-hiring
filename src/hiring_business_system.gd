class_name HiringBusinessSystem
extends RefCounted


## Deterministic business-domain simulation for We're Hiring.
##
## This model deliberately has no dependency on HiringModel.  It can be adopted
## incrementally: the existing game may keep presenting runway as weeks while
## this class owns the dollar ledger, capital transactions, outside actors, and
## policy programs.  Every mutating public operation accepts or derives a stable
## transaction id so a save resumed around a choice cannot apply money or shares
## twice.

const SAVE_VERSION := 1
const PPM := 1_000_000
const BP_DENOMINATOR := 10_000
const RNG_MODULUS := 2_147_483_647
const RNG_MULTIPLIER := 48_271
const MARKET_RNG_INITIAL_STATE := 83_729
const POLICY_RNG_INITIAL_STATE := 104_729
const START_AUTHORIZED_SHARES := 12_000_000

const INVESTOR_PROFILES := {
	"juniper_ventures": {
		"person": "Maya Chen", "firm": "Juniper Ventures",
		"role": "合伙人", "stages": ["preseed", "seed"],
		"check_min_usd": 500_000, "check_max_usd": 2_500_000,
		"thesis": ["applied_ai", "enterprise"],
		"diligence": ["customer_references", "eval_provenance", "cap_table", "security"],
		"control_appetite": 25,
	},
	"north_quay_capital": {
		"person": "Daniel Ortiz", "firm": "North Quay Capital",
		"role": "普通合伙人", "stages": ["seed", "series_a"],
		"check_min_usd": 2_000_000, "check_max_usd": 15_000_000,
		"thesis": ["category_leader", "growth"],
		"diligence": ["growth_cohorts", "sales_pipeline", "option_pool", "board"],
		"control_appetite": 72,
	},
	"civic_compute_fund": {
		"person": "Asha Raman", "firm": "Civic Compute Fund",
		"role": "投资总监", "stages": ["seed", "series_a"],
		"check_min_usd": 1_000_000, "check_max_usd": 8_000_000,
		"thesis": ["public_interest", "government_market"],
		"diligence": ["eval_provenance", "data_rights", "security", "public_procurement"],
		"control_appetite": 45,
	},
	"relay_syndicate": {
		"person": "Owen Bell", "firm": "Relay Operator Syndicate",
		"role": "召集人", "stages": ["preseed"],
		"check_min_usd": 100_000, "check_max_usd": 1_000_000,
		"thesis": ["founder_network", "fast_checks"],
		"diligence": ["founder_references", "cap_table"],
		"control_appetite": 12,
	},
}

const COMPETITOR_PROFILES := {
	"morrow_ai": {
		"name": "Morrow AI", "archetype": "research_first",
		"description": "公开失败样本，发布很慢，benchmark 很少撤回。",
	},
	"chorus_systems": {
		"name": "Chorus Systems", "archetype": "narrative_first",
		"description": "总能比别人早一周宣布下一件事。",
	},
	"harbor_desk": {
		"name": "HarborDesk", "archetype": "enterprise_first",
		"description": "折扣、pilot、采购清单和候选人反要约都做得很熟。",
	},
}

var ledger: Dictionary = {}
var capital: Dictionary = {}
var investors: Dictionary = {}
var market: Dictionary = {}
var policy: Dictionary = {}
var _transactions: Dictionary = {}
var _week_results: Dictionary = {}


func _init() -> void:
	reset()


func reset() -> void:
	ledger = {
		"cash_usd": 200_000,
		"weekly_costs": {
			"payroll": 12_000,
			"vendors": 3_500,
			"rent": 2_500,
			"compute": 2_000,
			"policy": 0,
		},
		"mrr_usd": 0,
		"contracted_arr_usd": 0,
		"gross_margin_bp": 8_000,
		"customer_count": 0,
		"commitments": {},
		"journal": [],
	}
	capital = {
		"authorized_shares": START_AUTHORIZED_SHARES,
		"holders": {
			"founder": {
				"owner_id": "founder", "kind": "common", "security": "common",
				"shares": 5_000_000,
			},
			"lin_yue": {
				"owner_id": "lin_yue", "kind": "common", "security": "common",
				"shares": 4_000_000,
			},
			"option_pool": {
				"owner_id": "option_pool", "kind": "option_pool", "security": "option_pool",
				"shares": 1_000_000,
			},
		},
		"safes": [],
		"rounds": [],
		"board_seats": [
			{"id": "founder_seat", "holder_id": "founder", "kind": "director"},
			{"id": "cto_seat", "holder_id": "lin_yue", "kind": "director"},
		],
	}
	investors = {}
	for investor_id_value in INVESTOR_PROFILES:
		var investor_id := str(investor_id_value)
		investors[investor_id] = {
			"trust": 50,
			"conviction": 0,
			"board_support": 50,
			"last_update_week": -1,
			"promises": [],
			"invested_usd": 0,
			"information_rights": false,
		}
	market = {
		"rng_state": MARKET_RNG_INITIAL_STATE,
		"last_ticked_week": 0,
		"category_demand": 38,
		"talent_pressure_bp": 10_000,
		"price_pressure_bp": 10_000,
		"regulatory_scrutiny": 10,
		"competitors": {
			"morrow_ai": {
				"stage": "preseed", "cash_usd": 900_000, "weekly_burn_usd": 42_000,
				"capability": 58, "narrative": 31, "product_fit": 35,
				"enterprise_logos": 1, "price_index_bp": 11_000,
				"hiring_brand": 48, "policy_access": 5, "last_strategy": "research_sprint",
				"announced_funding_usd": 0, "public_product_signal": "private_beta",
				"financing_count": 0, "last_financing_week": -99, "series_a_raised": false,
				"solvency": "operating",
			},
			"chorus_systems": {
				"stage": "seed", "cash_usd": 5_500_000, "weekly_burn_usd": 155_000,
				"capability": 34, "narrative": 73, "product_fit": 43,
				"enterprise_logos": 4, "price_index_bp": 9_500,
				"hiring_brand": 76, "policy_access": 12, "last_strategy": "fundraise",
				"announced_funding_usd": 5_000_000, "public_product_signal": "announced",
				"financing_count": 1, "last_financing_week": -8, "series_a_raised": false,
				"solvency": "operating",
			},
			"harbor_desk": {
				"stage": "seed", "cash_usd": 3_800_000, "weekly_burn_usd": 105_000,
				"capability": 45, "narrative": 52, "product_fit": 61,
				"enterprise_logos": 8, "price_index_bp": 8_800,
				"hiring_brand": 63, "policy_access": 8, "last_strategy": "enterprise_win",
				"announced_funding_usd": 3_500_000, "public_product_signal": "enterprise_pilot",
				"financing_count": 1, "last_financing_week": -8, "series_a_raised": false,
				"solvency": "operating",
			},
		},
		"public_feed": [],
	}
	policy = {
		"rng_state": POLICY_RNG_INITIAL_STATE,
		"programs": {},
		"pilots": {},
		"deferred_tax_credit_usd": 0,
		"tax_credit_used_usd": 0,
		"job_commitment": 0,
		"investment_commitment_usd": 0,
		"access": 0,
		"regulatory_credibility": 50,
		"public_trust": 50,
		"industry_influence": 0,
		"lobby_spend_usd_quarter": 0,
		"lda_registered": false,
		"government_contractor": false,
		"issues": {
			"eval_disclosure": {"stage": "monitoring", "strength": 1},
			"public_procurement": {"stage": "monitoring", "strength": 0},
		},
		"comments": [],
		"public_feed": [],
	}
	_transactions = {}
	_week_results = {}


## The sole financing quote table.  Its signature intentionally has no company
## capability, cash, team, debt, or market argument.  Investment amount and the
## default valuation therefore remain a pure function of stage and narrative.
func financing_quote(stage: String, narrative_value: float) -> Dictionary:
	var normalized_stage := stage.to_lower().strip_edges()
	var story := clampi(int(floor(narrative_value)), 0, 100)
	var band := 0
	if story >= 75:
		band = 3
	elif story >= 55:
		band = 2
	elif story >= 35:
		band = 1
	var table := {
		"preseed": {
			"amounts": [250_000, 500_000, 750_000, 1_000_000],
			"valuations": [4_000_000, 6_000_000, 8_000_000, 11_000_000],
			"instrument": "post_money_safe",
		},
		"bridge": {
			"amounts": [200_000, 400_000, 750_000, 1_250_000],
			"valuations": [4_000_000, 6_000_000, 8_000_000, 10_000_000],
			"instrument": "post_money_safe",
		},
		"seed": {
			"amounts": [1_500_000, 2_500_000, 4_000_000, 6_000_000],
			"valuations": [8_000_000, 12_000_000, 16_000_000, 24_000_000],
			"instrument": "priced_round",
		},
		"series_a": {
			"amounts": [4_000_000, 7_000_000, 10_000_000, 14_000_000],
			"valuations": [18_000_000, 28_000_000, 40_000_000, 60_000_000],
			"instrument": "priced_round",
		},
	}
	if not table.has(normalized_stage):
		return {"ok": false, "reason": "unknown_stage", "stage": normalized_stage}
	var row: Dictionary = table[normalized_stage]
	return {
		"ok": true,
		"stage": normalized_stage,
		"story_band": band,
		"narrative_basis": story,
		"amount_usd": int(Array(row["amounts"])[band]),
		"valuation_usd": int(Array(row["valuations"])[band]),
		"instrument": str(row["instrument"]),
	}


func weekly_cost_usd() -> int:
	var total := 0
	for amount_value in Dictionary(ledger.get("weekly_costs", {})).values():
		total += maxi(0, int(amount_value))
	return total


func weekly_gross_profit_usd() -> int:
	# MRR is a monthly run-rate, while settlement happens weekly.  Twelve months
	# over fifty-two weeks keeps cash and runway from inheriting the common but
	# materially optimistic four-weeks-per-month shortcut.
	var weekly_revenue := _floor_div(maxi(0, int(ledger.get("mrr_usd", 0))) * 12, 52)
	return _floor_div(weekly_revenue * clampi(int(ledger.get("gross_margin_bp", 0)), 0, BP_DENOMINATOR), BP_DENOMINATOR)


func weekly_burn_usd() -> int:
	return maxi(0, weekly_cost_usd() - weekly_gross_profit_usd())


func runway_weeks() -> int:
	var burn := weekly_burn_usd()
	if burn <= 0:
		return 999
	return _ceil_div(maxi(0, int(ledger.get("cash_usd", 0))), burn)


func set_weekly_cost(transaction_id: String, category: String, amount_usd: int) -> Dictionary:
	if transaction_id.strip_edges().is_empty() or category.strip_edges().is_empty() or amount_usd < 0:
		return {"ok": false, "reason": "invalid_weekly_cost"}
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	var costs: Dictionary = ledger["weekly_costs"]
	var before := int(costs.get(category, 0))
	costs[category] = amount_usd
	var result := {
		"ok": true, "transaction_id": transaction_id, "category": category,
		"before_usd": before, "after_usd": amount_usd,
	}
	return _commit_transaction(transaction_id, "weekly_cost", result)


## Records an explicit non-financing cash movement in the authoritative USD
## ledger.  The stable transaction id makes story choices, legacy-runway bridges,
## and save/resume boundaries replay-safe without pretending they are capital.
func record_cash_adjustment(transaction_id: String, category: String, delta_usd: int, metadata: Dictionary = {}) -> Dictionary:
	if transaction_id.strip_edges().is_empty() or category.strip_edges().is_empty():
		return {"ok": false, "reason": "invalid_cash_adjustment"}
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	var before := maxi(0, int(ledger.get("cash_usd", 0)))
	var after := maxi(0, before + delta_usd)
	var applied := after - before
	ledger["cash_usd"] = after
	var journal_metadata := metadata.duplicate(true)
	journal_metadata["transaction_id"] = transaction_id
	_append_journal(category, applied, journal_metadata)
	var result := {
		"ok": true,
		"transaction_id": transaction_id,
		"category": category,
		"requested_delta_usd": delta_usd,
		"applied_delta_usd": applied,
		"cash_before_usd": before,
		"cash_after_usd": after,
	}
	return _commit_transaction(transaction_id, "cash_adjustment", result)


func add_commitment(transaction_id: String, commitment_id: String, category: String, amount_usd: int, due_week: int, auto_settle: bool = true) -> Dictionary:
	if transaction_id.strip_edges().is_empty() or commitment_id.strip_edges().is_empty() or amount_usd <= 0 or due_week <= 0:
		return {"ok": false, "reason": "invalid_commitment"}
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	var commitments: Dictionary = ledger["commitments"]
	if commitments.has(commitment_id):
		return {"ok": false, "reason": "commitment_exists", "commitment_id": commitment_id}
	commitments[commitment_id] = {
		"id": commitment_id, "category": category, "amount_usd": amount_usd,
		"due_week": due_week, "auto_settle": auto_settle, "status": "open",
		"paid_usd": 0, "unpaid_usd": 0,
	}
	var result := {"ok": true, "transaction_id": transaction_id, "commitment": Dictionary(commitments[commitment_id]).duplicate(true)}
	return _commit_transaction(transaction_id, "commitment_added", result)


func settle_commitment(transaction_id: String, commitment_id: String) -> Dictionary:
	if transaction_id.strip_edges().is_empty():
		return {"ok": false, "reason": "missing_transaction_id"}
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	var commitments: Dictionary = ledger["commitments"]
	if not commitments.has(commitment_id):
		return {"ok": false, "reason": "unknown_commitment"}
	var commitment: Dictionary = commitments[commitment_id]
	if str(commitment.get("status", "")) != "open":
		return {"ok": false, "reason": "commitment_not_open"}
	var amount := maxi(0, int(commitment.get("amount_usd", 0)))
	var available := maxi(0, int(ledger.get("cash_usd", 0)))
	var paid := mini(amount, available)
	ledger["cash_usd"] = available - paid
	commitment["paid_usd"] = paid
	commitment["unpaid_usd"] = amount - paid
	commitment["status"] = "paid" if paid == amount else "defaulted"
	_append_journal("commitment", -paid, {"commitment_id": commitment_id})
	var result := {"ok": true, "transaction_id": transaction_id, "commitment_id": commitment_id, "paid_usd": paid, "unpaid_usd": amount - paid, "status": commitment["status"]}
	return _commit_transaction(transaction_id, "commitment_settled", result)


func issue_post_money_safe(transaction_id: String, investor_id: String, stage: String, narrative_value: float, terms: Dictionary = {}) -> Dictionary:
	if transaction_id.strip_edges().is_empty():
		return {"ok": false, "reason": "missing_transaction_id"}
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	if not INVESTOR_PROFILES.has(investor_id):
		return {"ok": false, "reason": "unknown_investor"}
	var quote := financing_quote(stage, narrative_value)
	if not bool(quote.get("ok", false)) or str(quote.get("instrument", "")) != "post_money_safe":
		return {"ok": false, "reason": "safe_stage_required"}
	var amount := int(quote["amount_usd"])
	var cap_usd := maxi(amount + 1, int(terms.get("post_money_cap_usd", quote["valuation_usd"])))
	var safe_id := str(terms.get("safe_id", transaction_id))
	var safe := {
		"id": safe_id,
		"transaction_id": transaction_id,
		"investor_id": investor_id,
		"stage": str(quote["stage"]),
		"invested_usd": amount,
		"post_money_cap_usd": cap_usd,
		"estimated_ownership_ppm": _floor_div(amount * PPM, cap_usd),
		"pro_rata": bool(terms.get("pro_rata", false)),
		"information_rights": bool(terms.get("information_rights", true)),
		"signed_week": int(terms.get("signed_week", 0)),
		"status": "outstanding",
		"conversion_shares": 0,
		"conversion_holder_key": "",
	}
	var safes: Array = capital["safes"]
	safes.append(safe)
	_change_cash(amount, "safe_financing", {"safe_id": safe_id, "investor_id": investor_id})
	_update_investor_after_financing(investor_id, amount, int(quote["narrative_basis"]), bool(safe["information_rights"]))
	var result := {
		"ok": true, "transaction_id": transaction_id, "instrument": "post_money_safe",
		"stage": quote["stage"], "amount_usd": amount, "post_money_cap_usd": cap_usd,
		"safe_id": safe_id, "estimated_ownership_ppm": safe["estimated_ownership_ppm"],
		"narrative_basis": quote["narrative_basis"],
	}
	return _commit_transaction(transaction_id, "post_money_safe", result)


func close_priced_round(transaction_id: String, investor_id: String, stage: String, narrative_value: float, terms: Dictionary = {}) -> Dictionary:
	if transaction_id.strip_edges().is_empty():
		return {"ok": false, "reason": "missing_transaction_id"}
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	if not INVESTOR_PROFILES.has(investor_id):
		return {"ok": false, "reason": "unknown_investor"}
	var quote := financing_quote(stage, narrative_value)
	if not bool(quote.get("ok", false)) or str(quote.get("instrument", "")) != "priced_round":
		return {"ok": false, "reason": "priced_stage_required"}
	var amount := int(quote["amount_usd"])
	var pre_money := maxi(1, int(terms.get("pre_money_usd", quote["valuation_usd"])))
	var round_id := str(terms.get("round_id", transaction_id))
	var safe_conversion := _convert_outstanding_safes(round_id)
	if not bool(safe_conversion.get("ok", false)):
		return safe_conversion
	var option_pool_target_bp := clampi(int(terms.get("option_pool_target_bp", 1_000)), 0, 4_000)
	var option_pool_top_up := _top_up_option_pool_for_post_round_target(option_pool_target_bp, pre_money, amount)
	var pre_round_shares := fully_diluted_shares()
	var investor_shares := _ceil_div(amount * pre_round_shares, pre_money)
	var holder_key := "preferred:%s:%s" % [round_id, investor_id]
	var holders: Dictionary = capital["holders"]
	holders[holder_key] = {
		"owner_id": investor_id,
		"kind": "preferred",
		"security": "%s_preferred" % str(quote["stage"]),
		"shares": investor_shares,
		"invested_usd": amount,
		"liquidation_preference_bp": 10_000,
		"participating": false,
		"round_id": round_id,
	}
	_ensure_authorized_share_capacity()
	var board_seat := str(terms.get("board_seat", "observer"))
	if board_seat in ["director", "observer"]:
		_add_board_seat(round_id, investor_id, board_seat)
	var round := {
		"id": round_id,
		"transaction_id": transaction_id,
		"stage": quote["stage"],
		"investor_id": investor_id,
		"amount_usd": amount,
		"pre_money_usd": pre_money,
		"post_money_usd": pre_money + amount,
		"pre_round_shares": pre_round_shares,
		"shares_issued": investor_shares,
		"holder_key": holder_key,
		"option_pool_target_bp": option_pool_target_bp,
		"option_pool_top_up_shares": option_pool_top_up,
		"liquidation_preference_bp": 10_000,
		"participating": false,
		"board_seat": board_seat,
		"protective_rights": Array(terms.get("protective_rights", ["new_financing", "sale", "charter_change"])).duplicate(),
		"narrative_basis": quote["narrative_basis"],
		"converted_safe_ids": Array(safe_conversion.get("safe_ids", [])).duplicate(),
	}
	var rounds: Array = capital["rounds"]
	rounds.append(round)
	_change_cash(amount, "priced_financing", {"round_id": round_id, "investor_id": investor_id})
	_update_investor_after_financing(investor_id, amount, int(quote["narrative_basis"]), true)
	var result := {
		"ok": true, "transaction_id": transaction_id, "instrument": "priced_round",
		"round_id": round_id, "stage": quote["stage"], "amount_usd": amount,
		"pre_money_usd": pre_money, "shares_issued": investor_shares,
		"option_pool_top_up_shares": option_pool_top_up,
		"converted_safe_ids": Array(safe_conversion.get("safe_ids", [])).duplicate(),
		"narrative_basis": quote["narrative_basis"],
	}
	return _commit_transaction(transaction_id, "priced_round", result)


func grant_options(transaction_id: String, employee_id: String, shares: int, vesting_weeks: int = 208, cliff_weeks: int = 52) -> Dictionary:
	if transaction_id.strip_edges().is_empty() or employee_id.strip_edges().is_empty() or shares <= 0:
		return {"ok": false, "reason": "invalid_option_grant"}
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	var holders: Dictionary = capital["holders"]
	var pool: Dictionary = holders.get("option_pool", {})
	if int(pool.get("shares", 0)) < shares:
		return {"ok": false, "reason": "option_pool_insufficient"}
	pool["shares"] = int(pool["shares"]) - shares
	var holder_key := "option:%s" % employee_id
	if holders.has(holder_key):
		holders[holder_key]["shares"] = int(holders[holder_key].get("shares", 0)) + shares
	else:
		holders[holder_key] = {
			"owner_id": employee_id, "kind": "option", "security": "common_option",
			"shares": shares, "vesting_weeks": maxi(1, vesting_weeks),
			"cliff_weeks": clampi(cliff_weeks, 0, maxi(1, vesting_weeks)),
		}
	var result := {
		"ok": true, "transaction_id": transaction_id, "employee_id": employee_id,
		"shares": shares, "pool_remaining_shares": int(pool["shares"]),
	}
	return _commit_transaction(transaction_id, "option_grant", result)


## Settles an employee's option position once when they leave.  Service time is
## supplied explicitly in weeks so the business model does not need to know the
## employment calendar.  Before the cliff nothing vests; at and after the cliff
## vesting is straight-line through the holder's recorded vesting term (208
## weeks with a 52-week cliff for the standard grant).  Unvested shares return
## to the unissued option pool while vested shares remain with the employee.
##
## Both the transaction log and the holder-level settlement marker are checked:
## replaying the same id returns the stored result, and a second id cannot
## forfeit the already-settled position again.
func process_option_departure(transaction_id: String, employee_id: String, service_weeks: int) -> Dictionary:
	if transaction_id.strip_edges().is_empty() or employee_id.strip_edges().is_empty() or service_weeks < 0:
		return {"ok": false, "reason": "invalid_option_departure"}
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	var holders: Dictionary = capital.get("holders", {})
	var holder_key := "option:%s" % employee_id
	if not holders.has(holder_key) or not holders[holder_key] is Dictionary:
		return {
			"ok": false,
			"reason": "unknown_option_holder",
			"transaction_id": transaction_id,
			"employee_id": employee_id,
			"holder_key": holder_key,
		}
	var holder: Dictionary = holders[holder_key]
	if str(holder.get("kind", "")) != "option":
		return {
			"ok": false,
			"reason": "unknown_option_holder",
			"transaction_id": transaction_id,
			"employee_id": employee_id,
			"holder_key": holder_key,
		}
	var prior_settlement_value = holder.get("departure_settlement", null)
	if prior_settlement_value is Dictionary:
		var prior: Dictionary = Dictionary(prior_settlement_value).duplicate(true)
		prior["idempotent"] = true
		prior["requested_transaction_id"] = transaction_id
		prior["reason"] = "option_departure_already_processed"
		return prior

	var original_shares := maxi(0, int(holder.get("shares", 0)))
	var vesting_weeks := maxi(1, int(holder.get("vesting_weeks", 208)))
	var cliff_weeks := clampi(int(holder.get("cliff_weeks", 52)), 0, vesting_weeks)
	var vested_shares := 0
	if service_weeks >= vesting_weeks:
		vested_shares = original_shares
	elif service_weeks >= cliff_weeks:
		vested_shares = _floor_div(original_shares * service_weeks, vesting_weeks)
	var unvested_shares := original_shares - vested_shares
	var pool: Dictionary = holders.get("option_pool", {})
	var pool_before := maxi(0, int(pool.get("shares", 0)))
	pool["shares"] = pool_before + unvested_shares
	holder["shares"] = vested_shares

	var result := {
		"ok": true,
		"transaction_id": transaction_id,
		"employee_id": employee_id,
		"holder_key": holder_key,
		"service_weeks": service_weeks,
		"vesting_weeks": vesting_weeks,
		"cliff_weeks": cliff_weeks,
		"cliff_reached": service_weeks >= cliff_weeks,
		"fully_vested": service_weeks >= vesting_weeks,
		"original_shares": original_shares,
		"vested_shares": vested_shares,
		"unvested_shares": unvested_shares,
		"holder_remaining_shares": vested_shares,
		"pool_before_shares": pool_before,
		"pool_after_shares": int(pool["shares"]),
	}
	# Keep a durable copy on the holder as a second idempotency boundary.  This
	# prevents a caller from substituting a fresh transaction id after departure.
	holder["departure_settlement"] = result.duplicate(true)
	return _commit_transaction(transaction_id, "option_departure", result)


func fully_diluted_shares() -> int:
	var total := 0
	for holder_value in Dictionary(capital.get("holders", {})).values():
		if holder_value is Dictionary:
			total += maxi(0, int(Dictionary(holder_value).get("shares", 0)))
	return total


func cap_table() -> Dictionary:
	var owner_shares: Dictionary = {}
	var owner_issued_shares: Dictionary = {}
	var owner_safe_shares: Dictionary = {}
	var owner_safe_ids: Dictionary = {}
	for holder_value in Dictionary(capital.get("holders", {})).values():
		if not holder_value is Dictionary:
			continue
		var holder: Dictionary = holder_value
		var owner_id := str(holder.get("owner_id", "unknown"))
		var issued_shares := maxi(0, int(holder.get("shares", 0)))
		owner_shares[owner_id] = int(owner_shares.get(owner_id, 0)) + issued_shares
		owner_issued_shares[owner_id] = int(owner_issued_shares.get(owner_id, 0)) + issued_shares

	var issued_total := fully_diluted_shares()
	var safe_projection := _outstanding_safe_pro_forma_positions(issued_total)
	for position_value in Array(safe_projection.get("positions", [])):
		if not position_value is Dictionary:
			continue
		var position: Dictionary = position_value
		var owner_id := str(position.get("investor_id", "unknown"))
		var safe_shares := maxi(0, int(position.get("shares", 0)))
		owner_shares[owner_id] = int(owner_shares.get(owner_id, 0)) + safe_shares
		owner_safe_shares[owner_id] = int(owner_safe_shares.get(owner_id, 0)) + safe_shares
		var safe_ids: Array = Array(owner_safe_ids.get(owner_id, [])).duplicate()
		safe_ids.append(str(position.get("safe_id", "")))
		owner_safe_ids[owner_id] = safe_ids
	var total := issued_total + int(safe_projection.get("total_pro_forma_shares", 0))
	var rows: Array[Dictionary] = []
	var keys: Array = owner_shares.keys()
	keys.sort()
	var assigned_bp := 0
	var largest_index := -1
	var largest_shares := -1
	for owner_id_value in keys:
		var owner_id := str(owner_id_value)
		var shares := int(owner_shares[owner_id])
		var ownership_bp := _floor_div(shares * BP_DENOMINATOR, maxi(1, total))
		var pro_forma_safe_shares := int(owner_safe_shares.get(owner_id, 0))
		rows.append({
			"owner_id": owner_id,
			"shares": shares,
			"issued_shares": int(owner_issued_shares.get(owner_id, 0)),
			"pro_forma_safe_shares": pro_forma_safe_shares,
			"outstanding_safe_ids": Array(owner_safe_ids.get(owner_id, [])).duplicate(),
			"is_pro_forma": pro_forma_safe_shares > 0,
			"ownership_bp": ownership_bp,
		})
		assigned_bp += ownership_bp
		if shares > largest_shares:
			largest_shares = shares
			largest_index = rows.size() - 1
	if largest_index >= 0:
		rows[largest_index]["ownership_bp"] = int(rows[largest_index]["ownership_bp"]) + (BP_DENOMINATOR - assigned_bp)
	var safe_estimates: Array[Dictionary] = []
	for safe_value in Array(capital.get("safes", [])):
		if safe_value is Dictionary and str(Dictionary(safe_value).get("status", "")) == "outstanding":
			var safe: Dictionary = safe_value
			var projected_shares := 0
			for position_value in Array(safe_projection.get("positions", [])):
				if position_value is Dictionary and str(Dictionary(position_value).get("safe_id", "")) == str(safe.get("id", "")):
					projected_shares = int(Dictionary(position_value).get("shares", 0))
					break
			safe_estimates.append({
				"safe_id": safe.get("id", ""), "investor_id": safe.get("investor_id", ""),
				"estimated_ownership_ppm": safe.get("estimated_ownership_ppm", 0),
				"pro_forma_shares": projected_shares,
			})
	var includes_outstanding_safes := not safe_estimates.is_empty()
	return {
		"fully_diluted_shares": total,
		"issued_fully_diluted_shares": issued_total,
		"pro_forma_fully_diluted_shares": total,
		"ownership_basis": "pro_forma_including_outstanding_safes" if includes_outstanding_safes else "fully_diluted",
		"ownership_basis_label": "PRO FORMA · SAFE INCLUDED" if includes_outstanding_safes else "FULLY DILUTED",
		"includes_outstanding_safes": includes_outstanding_safes,
		"pro_forma_valid": bool(safe_projection.get("ok", false)),
		"pro_forma_error": str(safe_projection.get("reason", "")),
		"rows": rows,
		"outstanding_safe_estimates": safe_estimates,
	}


## Applies 1x non-participating preferred economics.  Each preferred security,
## including an outstanding SAFE in a pre-priced-round liquidity event,
## iteratively chooses the better of its preference and as-converted common
## payout.  Unissued option-pool shares never receive exit proceeds.
func exit_waterfall(exit_usd: int) -> Dictionary:
	var proceeds := maxi(0, exit_usd)
	# Synthetic SAFE securities are local to this calculation: a liquidity event
	# must honor the SAFE before a priced conversion without mutating the cap table
	# or making a later financing think that conversion already occurred.
	var holders: Dictionary = Dictionary(capital.get("holders", {})).duplicate(true)
	var safe_projection := _outstanding_safe_pro_forma_positions(fully_diluted_shares())
	var outstanding_safe_ids: Array[String] = []
	for position_value in Array(safe_projection.get("positions", [])):
		if not position_value is Dictionary:
			continue
		var position: Dictionary = position_value
		var safe_id := str(position.get("safe_id", ""))
		var holder_key := "liquidity_safe:%03d:%s" % [int(position.get("safe_index", 0)), safe_id]
		holders[holder_key] = {
			"owner_id": str(position.get("investor_id", "unknown")),
			"kind": "preferred",
			"security": "outstanding_safe_liquidity",
			"shares": maxi(0, int(position.get("shares", 0))),
			"invested_usd": maxi(0, int(position.get("invested_usd", 0))),
			"liquidation_preference_bp": 10_000,
			"participating": false,
			"source_safe_id": safe_id,
		}
		outstanding_safe_ids.append(safe_id)
	var participating_weights: Dictionary = {}
	var preferred_keys: Array[String] = []
	var preferences: Dictionary = {}
	for holder_key_value in holders:
		var holder_key := str(holder_key_value)
		var holder: Dictionary = holders[holder_key]
		var kind := str(holder.get("kind", "common"))
		if kind == "option_pool":
			continue
		var shares := maxi(0, int(holder.get("shares", 0)))
		participating_weights[holder_key] = shares
		if kind == "preferred":
			preferred_keys.append(holder_key)
			preferences[holder_key] = _floor_div(
				maxi(0, int(holder.get("invested_usd", 0))) * maxi(0, int(holder.get("liquidation_preference_bp", 10_000))),
				10_000
			)
	preferred_keys.sort()
	var non_converting: Dictionary = {}
	for _iteration in range(16):
		var preference_total := 0
		var conversion_weights := participating_weights.duplicate()
		for holder_key_value in non_converting:
			var holder_key := str(holder_key_value)
			preference_total += int(preferences.get(holder_key, 0))
			conversion_weights.erase(holder_key)
		if preference_total >= proceeds:
			# Once the preference stack exhausts the exit, every remaining
			# preferred security would receive zero as-converted.  They therefore
			# join the pari-passu 1x preference pool as well.
			for holder_key in preferred_keys:
				non_converting[holder_key] = true
			break
		var conversion_pool := proceeds - preference_total
		var conversion_preview := _allocate_pro_rata(conversion_pool, conversion_weights)
		var changed := false
		for holder_key in preferred_keys:
			if non_converting.has(holder_key):
				continue
			if int(preferences.get(holder_key, 0)) > int(conversion_preview.get(holder_key, 0)):
				non_converting[holder_key] = true
				changed = true
		if not changed:
			break
	var payouts_by_security: Dictionary = {}
	var final_preference_total := 0
	for holder_key_value in non_converting:
		final_preference_total += int(preferences.get(str(holder_key_value), 0))
	if final_preference_total >= proceeds and final_preference_total > 0:
		var preference_weights: Dictionary = {}
		for holder_key_value in non_converting:
			var holder_key := str(holder_key_value)
			preference_weights[holder_key] = int(preferences.get(holder_key, 0))
		payouts_by_security = _allocate_pro_rata(proceeds, preference_weights)
	else:
		for holder_key_value in non_converting:
			var holder_key := str(holder_key_value)
			payouts_by_security[holder_key] = int(preferences.get(holder_key, 0))
		var residual := proceeds - final_preference_total
		var residual_weights := participating_weights.duplicate()
		for holder_key_value in non_converting:
			residual_weights.erase(str(holder_key_value))
		var residual_payouts := _allocate_pro_rata(residual, residual_weights)
		for holder_key_value in residual_payouts:
			payouts_by_security[str(holder_key_value)] = int(residual_payouts[holder_key_value])
	var payouts_by_owner: Dictionary = {}
	for holder_key_value in payouts_by_security:
		var holder_key := str(holder_key_value)
		var holder: Dictionary = holders.get(holder_key, {})
		var owner_id := str(holder.get("owner_id", holder_key))
		payouts_by_owner[owner_id] = int(payouts_by_owner.get(owner_id, 0)) + int(payouts_by_security[holder_key])
	var total_paid := 0
	for payout_value in payouts_by_owner.values():
		total_paid += int(payout_value)
	return {
		"exit_usd": proceeds,
		"total_paid_usd": total_paid,
		"payouts_by_owner": payouts_by_owner,
		"payouts_by_security": payouts_by_security,
		"preferred_taking_preference": non_converting.keys(),
		"outstanding_safe_ids": outstanding_safe_ids,
		"includes_outstanding_safes": not outstanding_safe_ids.is_empty(),
		"safe_liquidity_basis": "greater_of_1x_or_as_converted",
	}


func investor_public_state() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var keys: Array = INVESTOR_PROFILES.keys()
	keys.sort()
	for investor_id_value in keys:
		var investor_id := str(investor_id_value)
		var profile: Dictionary = INVESTOR_PROFILES[investor_id]
		var relation: Dictionary = investors.get(investor_id, {})
		result.append({
			"id": investor_id,
			"person": profile.get("person", ""),
			"firm": profile.get("firm", ""),
			"role": profile.get("role", ""),
			"stages": Array(profile.get("stages", [])).duplicate(),
			"thesis": Array(profile.get("thesis", [])).duplicate(),
			"check_min_usd": int(profile.get("check_min_usd", 0)),
			"check_max_usd": int(profile.get("check_max_usd", 0)),
			"diligence": Array(profile.get("diligence", [])).duplicate(),
			"control_appetite": int(profile.get("control_appetite", 0)),
			"trust": int(relation.get("trust", 0)),
			"conviction": int(relation.get("conviction", 0)),
			"board_support": int(relation.get("board_support", 0)),
			"last_update_week": int(relation.get("last_update_week", -1)),
			"invested_usd": int(relation.get("invested_usd", 0)),
			"information_rights": bool(relation.get("information_rights", false)),
			"promises": Array(relation.get("promises", [])).duplicate(true),
		})
	return result


## Advances all outside actors exactly once for every elapsed total week through
## the supplied target.  Market randomness changes competitor and shared-market
## state only; the player's cash can change here solely through one deterministic
## target-week operating settlement and explicit commitments, never because a
## random headline fired.
func tick_week(context: Dictionary = {}) -> Dictionary:
	var requested_week := int(context.get("total_week", int(market.get("last_ticked_week", 0)) + 1))
	if requested_week <= 0:
		return {"ok": false, "reason": "invalid_week"}
	var week_key := str(requested_week)
	if _week_results.has(week_key):
		var repeated: Dictionary = Dictionary(_week_results[week_key]).duplicate(true)
		repeated["idempotent"] = true
		return repeated
	if requested_week <= int(market.get("last_ticked_week", 0)):
		return {"ok": false, "reason": "week_out_of_order"}
	var cash_before_world := int(ledger.get("cash_usd", 0))
	var visible_signal: Dictionary = {}
	var first_missing_week := int(market.get("last_ticked_week", 0)) + 1
	# Old saves and chapter transitions can legitimately request a week several
	# steps ahead of the last business tick.  Outside actors must experience each
	# elapsed week so their burn, strategy RNG, pressure decay, and dated policy
	# resolutions match a game that advanced one week at a time.  These catch-up
	# weeks intentionally do not call _settle_operating_week: the player ledger is
	# settled only for the explicitly requested target week below.
	for simulated_week in range(first_missing_week, requested_week + 1):
		visible_signal = _advance_external_week(simulated_week)
	var cash_after_world := int(ledger.get("cash_usd", 0))
	var operating_result := {"settled": false, "cash_delta_usd": 0}
	if bool(context.get("settle_operations", true)):
		operating_result = _settle_operating_week(requested_week)
	market["last_ticked_week"] = requested_week
	var result := {
		"ok": true,
		"idempotent": false,
		"total_week": requested_week,
		"public_feed": visible_signal,
		"world_cash_delta_usd": cash_after_world - cash_before_world,
		"operating": operating_result,
		"market_summary": _market_public_summary(),
	}
	_week_results[week_key] = result.duplicate(true)
	return result


func _advance_external_week(week: int) -> Dictionary:
	_decay_market_pressures()
	var potential_signals: Array[Dictionary] = []
	var competitor_ids: Array = Dictionary(market.get("competitors", {})).keys()
	competitor_ids.sort()
	for competitor_id_value in competitor_ids:
		potential_signals.append(_simulate_competitor_week(str(competitor_id_value), week))
	var visible_signal: Dictionary = {}
	if not potential_signals.is_empty():
		visible_signal = potential_signals[_market_roll(potential_signals.size())].duplicate(true)
		var feed: Array = market["public_feed"]
		feed.append(visible_signal)
		while feed.size() > 80:
			feed.pop_front()
	_process_policy_calendar(week)
	market["last_ticked_week"] = week
	return visible_signal


## Returns eligible side decisions without consuming RNG or mutating state.
func event_candidates(context: Dictionary = {}) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var chapter := int(context.get("chapter", 0))
	var local_week := int(context.get("week_in_chapter", 1))
	if chapter == 1 and local_week >= 4 and Array(capital.get("safes", [])).is_empty():
		candidates.append(_event_candidate("raise_preseed", "capital", 100, "第一张 SAFE 条款仍在等签字。"))
	if chapter == 2 and local_week >= 11 and not _round_stage_exists("seed"):
		candidates.append(_event_candidate("raise_seed", "capital", 100, "Seed 数据室已进入条款阶段。"))
	if chapter == 3 and local_week >= 12 and not _round_stage_exists("series_a"):
		candidates.append(_event_candidate("raise_series_a", "capital", 100, "A 轮条款清单已到达。"))
	var programs: Dictionary = policy.get("programs", {})
	if chapter >= 2 and not programs.has("phase_i_grant"):
		candidates.append(_event_candidate("apply_grant", "policy", 55, "非稀释研发资金开放申请。"))
	if chapter >= 2 and int(policy.get("deferred_tax_credit_usd", 0)) == 0 and not bool(policy.get("tax_credit_declined", false)):
		candidates.append(_event_candidate("tax_credit", "policy", 35, "岗位与投资承诺可以换取递延税收抵免。"))
	if chapter >= 2 and not Dictionary(policy.get("pilots", {})).has("agency_pilot"):
		candidates.append(_event_candidate("government_pilot", "policy", 45, "一项政府 pilot 正在征集技术方案。"))
	if chapter >= 3 and Array(policy.get("comments", [])).is_empty():
		candidates.append(_event_candidate("public_comment", "policy", 40, "评测披露规则进入 public-comment 窗口。"))
	if chapter >= 3 and int(policy.get("industry_influence", 0)) == 0:
		candidates.append(_event_candidate("industry_coalition", "policy", 30, "行业协会邀请公司加入标准工作组。"))
	if chapter >= 3 and int(policy.get("industry_influence", 0)) >= 10 and not bool(policy.get("lda_registered", false)) and not bool(policy.get("lobbying_declined", false)):
		candidates.append(_event_candidate("registered_lobbying", "policy", 25, "公司已具备直接参与规则沟通的影响力；支出与登记义务必须透明。"))
	if programs.has("phase_i_grant"):
		var grant: Dictionary = programs["phase_i_grant"]
		if str(grant.get("status", "")) == "milestone_due" or (str(grant.get("status", "")) == "awarded" and int(context.get("total_week", 0)) >= int(grant.get("milestone_due_week", 999))):
			candidates.append(_event_candidate("complete_grant_milestone", "policy", 90, "Phase I 技术里程碑到期。"))
	var pilots: Dictionary = policy.get("pilots", {})
	if pilots.has("agency_pilot"):
		var pilot: Dictionary = pilots["agency_pilot"]
		if str(pilot.get("status", "")) == "awarded" and int(context.get("total_week", 0)) >= int(pilot.get("milestone_due_week", 999)):
			candidates.append(_event_candidate("complete_pilot", "policy", 85, "政府 pilot 进入验收。"))
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	return candidates


## Resolves the deliberately small set of high-value business decisions.  The
## context may contain capability for grants and product delivery, but financing
## branches pass only stage + narrative into financing_quote().
func apply_decision(decision_id: String, choice_id: String, context: Dictionary = {}) -> Dictionary:
	var total_week := maxi(1, int(context.get("total_week", 1)))
	var transaction_id := str(context.get("transaction_id", "decision:%s:%d" % [decision_id, total_week]))
	if _transactions.has(transaction_id):
		return _stored_result(transaction_id)
	var result: Dictionary = {}
	match decision_id:
		"raise_preseed":
			result = _resolve_financing_decision(transaction_id, "preseed", choice_id, context)
		"raise_seed":
			result = _resolve_financing_decision(transaction_id, "seed", choice_id, context)
		"raise_series_a":
			result = _resolve_financing_decision(transaction_id, "series_a", choice_id, context)
		"investor_update":
			result = _resolve_investor_update(transaction_id, choice_id, context)
		"apply_grant":
			result = _resolve_grant_application(transaction_id, choice_id, context)
		"complete_grant_milestone":
			result = _resolve_grant_milestone(transaction_id, choice_id, context)
		"tax_credit":
			result = _resolve_tax_credit(transaction_id, choice_id, context)
		"realize_tax_credit":
			result = _resolve_tax_credit_use(transaction_id, context)
		"government_pilot":
			result = _resolve_pilot_bid(transaction_id, choice_id, context)
		"complete_pilot":
			result = _resolve_pilot_milestone(transaction_id, choice_id, context)
		"public_comment":
			result = _resolve_public_comment(transaction_id, choice_id, context)
		"industry_coalition":
			result = _resolve_industry_coalition(transaction_id, choice_id, context)
		"registered_lobbying":
			result = _resolve_registered_lobbying(transaction_id, choice_id, context)
		_:
			return {"ok": false, "reason": "unknown_decision", "decision_id": decision_id}
	if not bool(result.get("ok", false)):
		return result
	# Capital helpers already wrote a child transaction.  The parent decision id
	# remains the replay boundary for UI resolution and contains the full result.
	if not _transactions.has(transaction_id):
		return _commit_transaction(transaction_id, "decision:%s" % decision_id, result)
	return result


func public_state() -> Dictionary:
	return {
		"ledger": {
			"cash_usd": int(ledger.get("cash_usd", 0)),
			"weekly_costs": Dictionary(ledger.get("weekly_costs", {})).duplicate(true),
			"weekly_cost_usd": weekly_cost_usd(),
			"weekly_gross_profit_usd": weekly_gross_profit_usd(),
			"weekly_burn_usd": weekly_burn_usd(),
			"runway_weeks": runway_weeks(),
			"mrr_usd": int(ledger.get("mrr_usd", 0)),
			"contracted_arr_usd": int(ledger.get("contracted_arr_usd", 0)),
			"gross_margin_bp": int(ledger.get("gross_margin_bp", 0)),
			"customer_count": int(ledger.get("customer_count", 0)),
			"commitments": Dictionary(ledger.get("commitments", {})).duplicate(true),
			"recent_journal": Array(ledger.get("journal", [])).slice(maxi(0, Array(ledger.get("journal", [])).size() - 20)).duplicate(true),
		},
		"capital": {
			"authorized_shares": int(capital.get("authorized_shares", 0)),
			"cap_table": cap_table(),
			"safes": Array(capital.get("safes", [])).duplicate(true),
			"rounds": Array(capital.get("rounds", [])).duplicate(true),
			"board_seats": Array(capital.get("board_seats", [])).duplicate(true),
		},
		"investors": investor_public_state(),
		"market": _market_public_summary(),
		"policy": {
			"programs": Dictionary(policy.get("programs", {})).duplicate(true),
			"pilots": Dictionary(policy.get("pilots", {})).duplicate(true),
			"deferred_tax_credit_usd": int(policy.get("deferred_tax_credit_usd", 0)),
			"tax_credit_used_usd": int(policy.get("tax_credit_used_usd", 0)),
			"job_commitment": int(policy.get("job_commitment", 0)),
			"investment_commitment_usd": int(policy.get("investment_commitment_usd", 0)),
			"access": int(policy.get("access", 0)),
			"regulatory_credibility": int(policy.get("regulatory_credibility", 0)),
			"public_trust": int(policy.get("public_trust", 0)),
			"industry_influence": int(policy.get("industry_influence", 0)),
			"lobby_spend_usd_quarter": int(policy.get("lobby_spend_usd_quarter", 0)),
			"lda_registered": bool(policy.get("lda_registered", false)),
			"government_contractor": bool(policy.get("government_contractor", false)),
			"coalition_member": bool(policy.get("coalition_member", false)),
			"issues": Dictionary(policy.get("issues", {})).duplicate(true),
			"comments": Array(policy.get("comments", [])).duplicate(true),
			"public_feed": Array(policy.get("public_feed", [])).duplicate(true),
		},
	}


func to_save() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"ledger": ledger.duplicate(true),
		"capital": capital.duplicate(true),
		"investors": investors.duplicate(true),
		"market": market.duplicate(true),
		"policy": policy.duplicate(true),
		"transactions": _transactions.duplicate(true),
		"week_results": _week_results.duplicate(true),
	}


func from_save(data: Dictionary) -> bool:
	if int(data.get("save_version", -1)) != SAVE_VERSION:
		return false
	var loaded_ledger_value = data.get("ledger", null)
	var loaded_capital_value = data.get("capital", null)
	var loaded_investors_value = data.get("investors", null)
	var loaded_market_value = data.get("market", null)
	var loaded_policy_value = data.get("policy", null)
	if not loaded_ledger_value is Dictionary or not loaded_capital_value is Dictionary or not loaded_investors_value is Dictionary or not loaded_market_value is Dictionary or not loaded_policy_value is Dictionary:
		return false
	var candidate_ledger: Dictionary = Dictionary(loaded_ledger_value).duplicate(true)
	var candidate_capital: Dictionary = Dictionary(loaded_capital_value).duplicate(true)
	var candidate_investors: Dictionary = Dictionary(loaded_investors_value).duplicate(true)
	var candidate_market: Dictionary = Dictionary(loaded_market_value).duplicate(true)
	var candidate_policy: Dictionary = Dictionary(loaded_policy_value).duplicate(true)
	if not _valid_loaded_state(candidate_ledger, candidate_capital, candidate_investors, candidate_market, candidate_policy):
		return false
	ledger = candidate_ledger
	capital = candidate_capital
	investors = candidate_investors
	market = candidate_market
	policy = candidate_policy
	_transactions = Dictionary(data.get("transactions", {})).duplicate(true)
	_week_results = Dictionary(data.get("week_results", {})).duplicate(true)
	return true


func _resolve_financing_decision(transaction_id: String, stage: String, choice_id: String, context: Dictionary) -> Dictionary:
	if choice_id not in ["clean", "headline", "delegate"]:
		return {"ok": false, "reason": "invalid_financing_choice"}
	var narrative_value := float(context.get("narrative", 0.0))
	var quote := financing_quote(stage, narrative_value)
	if not bool(quote.get("ok", false)):
		return quote
	var investor_id := "juniper_ventures"
	var terms: Dictionary = {"signed_week": int(context.get("total_week", 0))}
	var authorship_effect := 0
	if stage in ["preseed", "bridge"]:
		if choice_id == "headline":
			investor_id = "relay_syndicate"
			terms["post_money_cap_usd"] = _floor_div(int(quote["valuation_usd"]) * 125, 100)
			terms["pro_rata"] = true
		elif choice_id == "delegate":
			investor_id = "juniper_ventures"
			terms["post_money_cap_usd"] = _floor_div(int(quote["valuation_usd"]) * 115, 100)
			terms["pro_rata"] = false
			authorship_effect = 4
		else:
			terms["post_money_cap_usd"] = int(quote["valuation_usd"])
			terms["pro_rata"] = true
		var child_id := "%s:capital" % transaction_id
		var financing := issue_post_money_safe(child_id, investor_id, stage, narrative_value, terms)
		if not bool(financing.get("ok", false)):
			return financing
		var result := financing.duplicate(true)
		result["transaction_id"] = transaction_id
		result["choice_id"] = choice_id
		result["investor_id"] = investor_id
		result["effects"] = {"author_weight": authorship_effect}
		return _commit_transaction(transaction_id, "decision:raise_%s" % stage, result)
	if choice_id == "headline":
		investor_id = "north_quay_capital"
		terms["pre_money_usd"] = _floor_div(int(quote["valuation_usd"]) * 125, 100)
		terms["option_pool_target_bp"] = 1_500
		terms["board_seat"] = "director"
	elif choice_id == "delegate":
		investor_id = "juniper_ventures" if stage == "seed" else "civic_compute_fund"
		terms["pre_money_usd"] = _floor_div(int(quote["valuation_usd"]) * 110, 100)
		terms["option_pool_target_bp"] = 1_000
		terms["board_seat"] = "observer"
		authorship_effect = 5 if stage == "seed" else 7
	else:
		investor_id = "juniper_ventures" if stage == "seed" else "north_quay_capital"
		terms["pre_money_usd"] = int(quote["valuation_usd"])
		terms["option_pool_target_bp"] = 1_200
		terms["board_seat"] = "observer" if stage == "seed" else "director"
	var child_id := "%s:capital" % transaction_id
	var financing := close_priced_round(child_id, investor_id, stage, narrative_value, terms)
	if not bool(financing.get("ok", false)):
		return financing
	var result := financing.duplicate(true)
	result["transaction_id"] = transaction_id
	result["choice_id"] = choice_id
	result["investor_id"] = investor_id
	result["effects"] = {"author_weight": authorship_effect}
	return _commit_transaction(transaction_id, "decision:raise_%s" % stage, result)


func _resolve_investor_update(transaction_id: String, choice_id: String, context: Dictionary) -> Dictionary:
	var investor_id := str(context.get("investor_id", "juniper_ventures"))
	if not investors.has(investor_id) or choice_id not in ["raw", "headline", "delegate"]:
		return {"ok": false, "reason": "invalid_investor_update"}
	var relation: Dictionary = investors[investor_id]
	var trust_delta := 6 if choice_id == "raw" else (1 if choice_id == "headline" else 8)
	var support_delta := 3 if choice_id == "raw" else (4 if choice_id == "headline" else 7)
	relation["trust"] = clampi(int(relation.get("trust", 50)) + trust_delta, 0, 100)
	relation["board_support"] = clampi(int(relation.get("board_support", 50)) + support_delta, 0, 100)
	relation["last_update_week"] = int(context.get("total_week", 0))
	return {
		"ok": true, "transaction_id": transaction_id, "investor_id": investor_id,
		"choice_id": choice_id, "trust_delta": trust_delta, "board_support_delta": support_delta,
		"effects": {"author_weight": 3 if choice_id == "delegate" else 0},
	}


func _resolve_grant_application(transaction_id: String, choice_id: String, context: Dictionary) -> Dictionary:
	if choice_id not in ["manual", "delegate", "skip"]:
		return {"ok": false, "reason": "invalid_grant_choice"}
	if Dictionary(policy.get("programs", {})).has("phase_i_grant"):
		return {"ok": false, "reason": "grant_already_resolved"}
	if choice_id == "skip":
		policy["programs"]["phase_i_grant"] = {"id": "phase_i_grant", "status": "declined"}
		return {"ok": true, "transaction_id": transaction_id, "choice_id": choice_id, "approved": false, "effects": {}}
	var capability := clampi(int(context.get("capability", 0)), 0, 100)
	var coherence := clampi(int(context.get("coherence", 50)), 0, 100)
	var review_roll := _policy_roll(101)
	var writing_bonus := 80 if choice_id == "delegate" else 0
	var score := capability * 7 + coherence * 2 + review_roll + writing_bonus
	var approved := score >= 610
	var program := {
		"id": "phase_i_grant",
		"status": "awarded" if approved else "not_selected",
		"technical_score": score,
		"capability_basis": capability,
		"award_usd": 200_000 if approved else 0,
		"paid_usd": 75_000 if approved else 0,
		"milestone_due_week": int(context.get("total_week", 1)) + 6,
	}
	policy["programs"]["phase_i_grant"] = program
	if approved:
		_change_cash(75_000, "grant_tranche", {"program_id": "phase_i_grant", "tranche": 1})
		policy["regulatory_credibility"] = clampi(int(policy["regulatory_credibility"]) + 8, 0, 100)
	return {
		"ok": true, "transaction_id": transaction_id, "choice_id": choice_id,
		"approved": approved, "technical_score": score,
		"capability_basis": capability, "cash_received_usd": 75_000 if approved else 0,
		"effects": {"author_weight": 4 if choice_id == "delegate" else 0},
	}


func _resolve_grant_milestone(transaction_id: String, choice_id: String, context: Dictionary) -> Dictionary:
	if choice_id not in ["submit", "delegate"]:
		return {"ok": false, "reason": "invalid_grant_milestone_choice"}
	var programs: Dictionary = policy.get("programs", {})
	if not programs.has("phase_i_grant"):
		return {"ok": false, "reason": "grant_missing"}
	var grant: Dictionary = programs["phase_i_grant"]
	if str(grant.get("status", "")) not in ["awarded", "milestone_due", "remediation"]:
		return {"ok": false, "reason": "grant_not_active"}
	var capability := clampi(int(context.get("capability", 0)), 0, 100)
	var passed := capability >= 60
	var payment := 125_000 if passed else 0
	grant["status"] = "completed" if passed else "remediation"
	grant["paid_usd"] = int(grant.get("paid_usd", 0)) + payment
	grant["milestone_capability"] = capability
	if passed:
		_change_cash(payment, "grant_tranche", {"program_id": "phase_i_grant", "tranche": 2})
	return {
		"ok": true, "transaction_id": transaction_id, "passed": passed,
		"capability_basis": capability, "cash_received_usd": payment,
		"effects": {"author_weight": 3 if choice_id == "delegate" else 0},
	}


func _resolve_tax_credit(transaction_id: String, choice_id: String, _context: Dictionary) -> Dictionary:
	if choice_id not in ["accept", "delegate", "decline"]:
		return {"ok": false, "reason": "invalid_tax_credit_choice"}
	if int(policy.get("deferred_tax_credit_usd", 0)) > 0 or bool(policy.get("tax_credit_declined", false)):
		return {"ok": false, "reason": "tax_credit_already_resolved"}
	if choice_id == "decline":
		policy["tax_credit_declined"] = true
		return {"ok": true, "transaction_id": transaction_id, "accepted": false, "cash_received_usd": 0, "effects": {}}
	policy["deferred_tax_credit_usd"] = 300_000
	policy["job_commitment"] = 20
	policy["investment_commitment_usd"] = 1_500_000
	policy["access"] = clampi(int(policy["access"]) + (8 if choice_id == "delegate" else 5), 0, 100)
	return {
		"ok": true, "transaction_id": transaction_id, "accepted": true,
		"deferred_tax_credit_usd": 300_000, "cash_received_usd": 0,
		"job_commitment": 20, "investment_commitment_usd": 1_500_000,
		"effects": {"author_weight": 3 if choice_id == "delegate" else 0},
	}


func _resolve_tax_credit_use(transaction_id: String, context: Dictionary) -> Dictionary:
	var liability := maxi(0, int(context.get("tax_liability_usd", 0)))
	var available := maxi(0, int(policy.get("deferred_tax_credit_usd", 0)))
	var used := mini(liability, available)
	policy["deferred_tax_credit_usd"] = available - used
	policy["tax_credit_used_usd"] = int(policy.get("tax_credit_used_usd", 0)) + used
	return {
		"ok": true, "transaction_id": transaction_id, "tax_liability_offset_usd": used,
		"cash_received_usd": 0, "deferred_tax_credit_remaining_usd": policy["deferred_tax_credit_usd"],
	}


func _resolve_pilot_bid(transaction_id: String, choice_id: String, context: Dictionary) -> Dictionary:
	if choice_id not in ["bid", "delegate", "decline"]:
		return {"ok": false, "reason": "invalid_pilot_choice"}
	var pilots: Dictionary = policy.get("pilots", {})
	if pilots.has("agency_pilot"):
		return {"ok": false, "reason": "pilot_already_resolved"}
	if choice_id == "decline":
		pilots["agency_pilot"] = {"id": "agency_pilot", "status": "declined"}
		return {"ok": true, "transaction_id": transaction_id, "awarded": false, "cash_received_usd": 0, "effects": {}}
	var capability := clampi(int(context.get("capability", 0)), 0, 100)
	var product_fit := clampi(int(context.get("product_fit", 50)), 0, 100)
	var score := capability * 6 + product_fit * 3 + _policy_roll(101) + (70 if choice_id == "delegate" else 0)
	var awarded := score >= 620
	pilots["agency_pilot"] = {
		"id": "agency_pilot", "status": "awarded" if awarded else "not_selected",
		"contract_value_usd": 250_000 if awarded else 0,
		"paid_usd": 0,
		"milestone_due_week": int(context.get("total_week", 1)) + 4,
		"capability_basis": capability,
	}
	if awarded:
		policy["government_contractor"] = true
		policy["regulatory_credibility"] = clampi(int(policy["regulatory_credibility"]) + 6, 0, 100)
	return {
		"ok": true, "transaction_id": transaction_id, "awarded": awarded,
		"technical_score": score, "capability_basis": capability, "cash_received_usd": 0,
		"effects": {"author_weight": 4 if choice_id == "delegate" else 0},
	}


func _resolve_pilot_milestone(transaction_id: String, choice_id: String, context: Dictionary) -> Dictionary:
	if choice_id not in ["deliver", "delegate"]:
		return {"ok": false, "reason": "invalid_pilot_milestone_choice"}
	var pilots: Dictionary = policy.get("pilots", {})
	if not pilots.has("agency_pilot"):
		return {"ok": false, "reason": "pilot_missing"}
	var pilot: Dictionary = pilots["agency_pilot"]
	if str(pilot.get("status", "")) not in ["awarded", "remediation"]:
		return {"ok": false, "reason": "pilot_not_active"}
	var capability := clampi(int(context.get("capability", 0)), 0, 100)
	var passed := capability >= 65
	var payment := int(pilot.get("contract_value_usd", 0)) if passed else 0
	pilot["status"] = "completed" if passed else "remediation"
	pilot["paid_usd"] = payment
	pilot["delivery_capability"] = capability
	if passed:
		_change_cash(payment, "government_pilot", {"pilot_id": "agency_pilot"})
		ledger["mrr_usd"] = int(ledger.get("mrr_usd", 0)) + 25_000
		ledger["contracted_arr_usd"] = int(ledger.get("contracted_arr_usd", 0)) + 300_000
		ledger["customer_count"] = int(ledger.get("customer_count", 0)) + 1
	return {
		"ok": true, "transaction_id": transaction_id, "passed": passed,
		"capability_basis": capability, "cash_received_usd": payment,
		"effects": {"author_weight": 4 if choice_id == "delegate" else 0},
	}


func _resolve_public_comment(transaction_id: String, choice_id: String, context: Dictionary) -> Dictionary:
	if choice_id not in ["strong_disclosure", "industry_flexibility", "delegate", "abstain"]:
		return {"ok": false, "reason": "invalid_comment_choice"}
	var position := "none"
	var influence_delta := 0
	var authorship := 0
	match choice_id:
		"strong_disclosure":
			position = "strong_disclosure"
			influence_delta = 5
			policy["public_trust"] = clampi(int(policy["public_trust"]) + 8, 0, 100)
		"industry_flexibility":
			position = "industry_flexibility"
			influence_delta = 7
			policy["public_trust"] = clampi(int(policy["public_trust"]) - 2, 0, 100)
		"delegate":
			position = "industry_flexibility"
			influence_delta = 10
			authorship = 5
		"abstain":
			position = "abstain"
	policy["industry_influence"] = clampi(int(policy["industry_influence"]) + influence_delta, 0, 100)
	var comment := {
		"id": transaction_id,
		"issue_id": "eval_disclosure",
		"position": position,
		"filed_week": int(context.get("total_week", 1)),
		"resolution_week": int(context.get("total_week", 1)) + 3,
		"status": "pending" if position != "abstain" else "closed",
	}
	var comments: Array = policy["comments"]
	comments.append(comment)
	return {
		"ok": true, "transaction_id": transaction_id, "choice_id": choice_id,
		"position": position, "resolution_week": comment["resolution_week"],
		"effects": {"author_weight": authorship},
	}


func _resolve_industry_coalition(transaction_id: String, choice_id: String, _context: Dictionary) -> Dictionary:
	if choice_id not in ["join", "delegate", "decline"]:
		return {"ok": false, "reason": "invalid_coalition_choice"}
	if choice_id == "decline":
		policy["coalition_declined"] = true
		return {"ok": true, "transaction_id": transaction_id, "joined": false, "weekly_cost_delta_usd": 0, "effects": {}}
	var costs: Dictionary = ledger["weekly_costs"]
	var cost_delta := 1_500
	costs["policy"] = int(costs.get("policy", 0)) + cost_delta
	policy["industry_influence"] = clampi(int(policy["industry_influence"]) + (14 if choice_id == "delegate" else 10), 0, 100)
	policy["access"] = clampi(int(policy["access"]) + (10 if choice_id == "delegate" else 7), 0, 100)
	policy["coalition_member"] = true
	return {
		"ok": true, "transaction_id": transaction_id, "joined": true,
		"weekly_cost_delta_usd": cost_delta,
		"effects": {"author_weight": 4 if choice_id == "delegate" else 0},
	}


func _resolve_registered_lobbying(transaction_id: String, choice_id: String, _context: Dictionary) -> Dictionary:
	if choice_id not in ["engage", "delegate", "decline"]:
		return {"ok": false, "reason": "invalid_lobbying_choice"}
	if choice_id == "decline":
		policy["lobbying_declined"] = true
		return {"ok": true, "transaction_id": transaction_id, "engaged": false, "effects": {}}
	var costs: Dictionary = ledger["weekly_costs"]
	costs["policy"] = int(costs.get("policy", 0)) + 5_000
	policy["lobby_spend_usd_quarter"] = int(policy.get("lobby_spend_usd_quarter", 0)) + 20_000
	policy["lda_registered"] = int(policy["lobby_spend_usd_quarter"]) >= 16_000
	policy["access"] = clampi(int(policy["access"]) + (18 if choice_id == "delegate" else 14), 0, 100)
	policy["industry_influence"] = clampi(int(policy["industry_influence"]) + (16 if choice_id == "delegate" else 12), 0, 100)
	return {
		"ok": true, "transaction_id": transaction_id, "engaged": true,
		"weekly_cost_delta_usd": 5_000, "quarter_spend_usd": 20_000,
		"lda_registered": bool(policy["lda_registered"]),
		"effects": {"author_weight": 5 if choice_id == "delegate" else 0},
	}


## Projects outstanding post-money SAFEs onto the current fully diluted base.
## This is the same integer-share basis used at the next priced conversion, but
## it is read-only so cap-table disclosure and a liquidity waterfall cannot
## accidentally convert the instruments.
func _outstanding_safe_pro_forma_positions(base_shares: int) -> Dictionary:
	var outstanding: Array[Dictionary] = []
	var total_ppm := 0
	var safes: Array = capital.get("safes", [])
	for index in safes.size():
		var safe_value = safes[index]
		if not safe_value is Dictionary:
			continue
		var safe: Dictionary = safe_value
		if str(safe.get("status", "")) != "outstanding":
			continue
		var ownership_ppm := maxi(0, int(safe.get("estimated_ownership_ppm", 0)))
		outstanding.append({
			"safe_index": index,
			"safe_id": str(safe.get("id", index)),
			"investor_id": str(safe.get("investor_id", "unknown")),
			"invested_usd": maxi(0, int(safe.get("invested_usd", 0))),
			"estimated_ownership_ppm": ownership_ppm,
			"shares": 0,
		})
		total_ppm += ownership_ppm
	if outstanding.is_empty():
		return {"ok": true, "positions": [], "total_ownership_ppm": 0, "total_pro_forma_shares": 0}
	# Keep disclosure aligned with the priced-round conversion guard. A malformed
	# legacy state still exposes its SAFE records and 1x cash-out rights, but does
	# not manufacture an impossible as-converted denominator.
	if total_ppm >= 900_000:
		return {
			"ok": false,
			"reason": "safe_ownership_overflow",
			"positions": outstanding,
			"total_ownership_ppm": total_ppm,
			"total_pro_forma_shares": 0,
		}
	var denominator := PPM - total_ppm
	var total_pro_forma_shares := 0
	for position in outstanding:
		var ownership_ppm := int(position.get("estimated_ownership_ppm", 0))
		var projected_shares := 0
		if ownership_ppm > 0:
			projected_shares = maxi(1, _ceil_div(maxi(0, base_shares) * ownership_ppm, denominator))
		position["shares"] = projected_shares
		total_pro_forma_shares += projected_shares
	return {
		"ok": true,
		"positions": outstanding,
		"total_ownership_ppm": total_ppm,
		"total_pro_forma_shares": total_pro_forma_shares,
	}


func _convert_outstanding_safes(round_id: String) -> Dictionary:
	var safes: Array = capital["safes"]
	var outstanding_indices: Array[int] = []
	var total_ppm := 0
	for index in safes.size():
		var safe_value = safes[index]
		if safe_value is Dictionary and str(Dictionary(safe_value).get("status", "")) == "outstanding":
			outstanding_indices.append(index)
			total_ppm += maxi(0, int(Dictionary(safe_value).get("estimated_ownership_ppm", 0)))
	if outstanding_indices.is_empty():
		return {"ok": true, "safe_ids": [], "shares_issued": 0}
	if total_ppm >= 900_000:
		return {"ok": false, "reason": "safe_ownership_overflow"}
	var base_shares := fully_diluted_shares()
	var denominator := PPM - total_ppm
	var converted_ids: Array[String] = []
	var total_shares_issued := 0
	var holders: Dictionary = capital["holders"]
	for index in outstanding_indices:
		var safe: Dictionary = safes[index]
		var safe_ppm := int(safe.get("estimated_ownership_ppm", 0))
		var conversion_shares := maxi(1, _ceil_div(base_shares * safe_ppm, denominator))
		var holder_key := "preferred:safe:%s" % str(safe.get("id", index))
		holders[holder_key] = {
			"owner_id": str(safe.get("investor_id", "unknown")),
			"kind": "preferred", "security": "safe_preferred",
			"shares": conversion_shares,
			"invested_usd": int(safe.get("invested_usd", 0)),
			"liquidation_preference_bp": 10_000,
			"participating": false,
			"round_id": round_id,
			"source_safe_id": str(safe.get("id", "")),
		}
		safe["status"] = "converted"
		safe["conversion_round_id"] = round_id
		safe["conversion_shares"] = conversion_shares
		safe["conversion_holder_key"] = holder_key
		converted_ids.append(str(safe.get("id", "")))
		total_shares_issued += conversion_shares
	_ensure_authorized_share_capacity()
	return {"ok": true, "safe_ids": converted_ids, "shares_issued": total_shares_issued}


func _top_up_option_pool_for_post_round_target(target_bp: int, pre_money_usd: int, amount_usd: int) -> int:
	if target_bp <= 0:
		return 0
	var holders: Dictionary = capital["holders"]
	var pool: Dictionary = holders.get("option_pool", {})
	var unissued := maxi(0, int(pool.get("shares", 0)))
	var shares_before := fully_diluted_shares()
	# (U+x) / ((S+x)*(P+R)/P) = q/10000
	var numerator := target_bp * (pre_money_usd + amount_usd) * shares_before - unissued * pre_money_usd * BP_DENOMINATOR
	var denominator := pre_money_usd * BP_DENOMINATOR - target_bp * (pre_money_usd + amount_usd)
	if numerator <= 0 or denominator <= 0:
		return 0
	var top_up := _ceil_div(numerator, denominator)
	pool["shares"] = unissued + top_up
	_ensure_authorized_share_capacity()
	return top_up


func _update_investor_after_financing(investor_id: String, amount_usd: int, narrative_basis: int, information_rights: bool) -> void:
	var relation: Dictionary = investors[investor_id]
	relation["invested_usd"] = int(relation.get("invested_usd", 0)) + amount_usd
	relation["conviction"] = clampi(narrative_basis, 0, 100)
	relation["trust"] = clampi(int(relation.get("trust", 50)) + 4, 0, 100)
	relation["information_rights"] = bool(relation.get("information_rights", false)) or information_rights


func _add_board_seat(round_id: String, investor_id: String, kind: String) -> void:
	var seats: Array = capital["board_seats"]
	var seat_id := "%s:%s" % [round_id, investor_id]
	for seat_value in seats:
		if seat_value is Dictionary and str(Dictionary(seat_value).get("id", "")) == seat_id:
			return
	seats.append({"id": seat_id, "holder_id": investor_id, "kind": kind})


func _ensure_authorized_share_capacity() -> void:
	var needed := fully_diluted_shares()
	if needed <= int(capital.get("authorized_shares", 0)):
		return
	var block := 1_000_000
	capital["authorized_shares"] = _ceil_div(needed, block) * block


func _round_stage_exists(stage: String) -> bool:
	for round_value in Array(capital.get("rounds", [])):
		if round_value is Dictionary and str(Dictionary(round_value).get("stage", "")) == stage:
			return true
	return false


func _decay_market_pressures() -> void:
	market["talent_pressure_bp"] = maxi(10_000, int(market.get("talent_pressure_bp", 10_000)) - 80)
	var price_pressure := int(market.get("price_pressure_bp", 10_000))
	market["price_pressure_bp"] = price_pressure + signi(10_000 - price_pressure) * mini(50, absi(10_000 - price_pressure))
	market["regulatory_scrutiny"] = maxi(0, int(market.get("regulatory_scrutiny", 0)) - 1)


func _simulate_competitor_week(competitor_id: String, week: int) -> Dictionary:
	var competitors: Dictionary = market["competitors"]
	var company: Dictionary = competitors[competitor_id]
	company["cash_usd"] = maxi(0, int(company.get("cash_usd", 0)) - int(company.get("weekly_burn_usd", 0)))
	company["solvency"] = "distressed" if int(company.get("cash_usd", 0)) <= 0 else "operating"
	var strategy := _weighted_market_strategy(str(COMPETITOR_PROFILES[competitor_id]["archetype"]))
	if strategy == "fundraise" and not _competitor_can_fundraise(company, week):
		strategy = "retrenchment" if str(company.get("solvency", "operating")) == "distressed" else "research_sprint"
	elif str(company.get("solvency", "operating")) == "distressed" and strategy not in ["fundraise", "research_sprint"]:
		strategy = "retrenchment"
	company["last_strategy"] = strategy
	var headline := ""
	var public_signal := strategy
	match strategy:
		"research_sprint":
			company["capability"] = clampi(int(company["capability"]) + 3, 0, 100)
			company["narrative"] = clampi(int(company["narrative"]) + 1, 0, 100)
			headline = "%s 公开了一组失败样本，没有宣布发布日期。" % str(COMPETITOR_PROFILES[competitor_id]["name"])
		"product_launch":
			var launch_score := int(company["capability"]) * 6 + int(company["product_fit"]) * 3 + _market_roll(101)
			var strong := launch_score >= 500
			company["public_product_signal"] = "strong_launch" if strong else "mixed_launch"
			company["product_fit"] = clampi(int(company["product_fit"]) + (4 if strong else 1), 0, 100)
			company["enterprise_logos"] = int(company["enterprise_logos"]) + (2 if strong else 0)
			market["category_demand"] = clampi(int(market["category_demand"]) + (5 if strong else 2), 0, 100)
			market["regulatory_scrutiny"] = clampi(int(market["regulatory_scrutiny"]) + (2 if strong else 0), 0, 100)
			headline = "%s 发布了新版本；第一批客户反馈是%s。" % [str(COMPETITOR_PROFILES[competitor_id]["name"]), "明显正面" if strong else "好坏各半"]
		"fundraise":
			var stage := str(company.get("stage", "preseed"))
			var quote_stage := stage if stage in ["preseed", "seed", "series_a"] else "series_a"
			var quote := financing_quote(quote_stage, float(company.get("narrative", 0)))
			var amount := int(quote.get("amount_usd", 0))
			company["cash_usd"] = int(company["cash_usd"]) + amount
			company["announced_funding_usd"] = amount
			company["stage"] = "seed" if stage == "preseed" else ("series_a" if stage == "seed" else "series_a")
			company["financing_count"] = int(company.get("financing_count", 0)) + 1
			company["last_financing_week"] = week
			if stage == "series_a" or str(company.get("stage", "")) == "series_a":
				company["series_a_raised"] = true
			company["solvency"] = "operating"
			market["talent_pressure_bp"] = clampi(int(market["talent_pressure_bp"]) + 250, 8_000, 20_000)
			headline = "%s 宣布完成一轮融资，并同时挂出七个职位。" % str(COMPETITOR_PROFILES[competitor_id]["name"])
		"retrenchment":
			company["weekly_burn_usd"] = maxi(15_000, int(round(float(company.get("weekly_burn_usd", 0)) * 0.82)))
			company["hiring_brand"] = clampi(int(company.get("hiring_brand", 50)) - 5, 0, 100)
			company["public_product_signal"] = "runway_extension"
			headline = "%s 暂停新增岗位并缩减云资源，公开目标从增长改成延长 runway。" % str(COMPETITOR_PROFILES[competitor_id]["name"])
		"price_cut":
			company["price_index_bp"] = maxi(5_000, int(company["price_index_bp"]) - 500)
			company["enterprise_logos"] = int(company["enterprise_logos"]) + 1
			market["price_pressure_bp"] = maxi(7_000, int(market["price_pressure_bp"]) - 250)
			headline = "%s 把年度合同折扣写进了公开价目表。" % str(COMPETITOR_PROFILES[competitor_id]["name"])
		"enterprise_win":
			var win_score := int(company["product_fit"]) * 6 + int(company["capability"]) * 3 + _market_roll(101)
			if win_score >= 470:
				company["enterprise_logos"] = int(company["enterprise_logos"]) + 1
				company["narrative"] = clampi(int(company["narrative"]) + 3, 0, 100)
			market["category_demand"] = clampi(int(market["category_demand"]) + 2, 0, 100)
			headline = "%s 的采购案例出现在一家大客户官网。" % str(COMPETITOR_PROFILES[competitor_id]["name"])
		"talent_bid":
			company["hiring_brand"] = clampi(int(company["hiring_brand"]) + 2, 0, 100)
			market["talent_pressure_bp"] = clampi(int(market["talent_pressure_bp"]) + 300, 8_000, 20_000)
			headline = "%s 向同一批候选人发出了本周五到期的 offer。" % str(COMPETITOR_PROFILES[competitor_id]["name"])
		"policy_coalition":
			company["policy_access"] = clampi(int(company["policy_access"]) + 4, 0, 100)
			market["regulatory_scrutiny"] = clampi(int(market["regulatory_scrutiny"]) + 1, 0, 100)
			headline = "%s 加入了评测标准工作组。" % str(COMPETITOR_PROFILES[competitor_id]["name"])
		_:
			headline = "%s 本周没有对外宣布新事项。" % str(COMPETITOR_PROFILES[competitor_id]["name"])
	return {
		"id": "market:%d:%s:%s" % [week, competitor_id, strategy],
		"week": week, "competitor_id": competitor_id,
		"competitor_name": str(COMPETITOR_PROFILES[competitor_id]["name"]),
		"strategy": strategy, "signal": public_signal, "headline": headline,
	}


func _competitor_can_fundraise(company: Dictionary, week: int) -> bool:
	if week - int(company.get("last_financing_week", -99)) < 8:
		return false
	if int(company.get("financing_count", 0)) >= 3:
		return false
	if str(company.get("stage", "preseed")) == "series_a" and bool(company.get("series_a_raised", false)):
		return false
	return true


func _weighted_market_strategy(archetype: String) -> String:
	var tables := {
		"research_first": [
			{"id": "research_sprint", "weight": 35}, {"id": "product_launch", "weight": 25},
			{"id": "fundraise", "weight": 10}, {"id": "enterprise_win", "weight": 15},
			{"id": "talent_bid", "weight": 10}, {"id": "policy_coalition", "weight": 5},
		],
		"narrative_first": [
			{"id": "research_sprint", "weight": 10}, {"id": "product_launch", "weight": 25},
			{"id": "fundraise", "weight": 25}, {"id": "price_cut", "weight": 15},
			{"id": "talent_bid", "weight": 15}, {"id": "policy_coalition", "weight": 10},
		],
		"enterprise_first": [
			{"id": "research_sprint", "weight": 10}, {"id": "product_launch", "weight": 15},
			{"id": "fundraise", "weight": 10}, {"id": "price_cut", "weight": 20},
			{"id": "enterprise_win", "weight": 25}, {"id": "talent_bid", "weight": 15},
			{"id": "policy_coalition", "weight": 5},
		],
	}
	var entries: Array = Array(tables.get(archetype, tables["enterprise_first"]))
	var total_weight := 0
	for entry_value in entries:
		total_weight += int(Dictionary(entry_value).get("weight", 0))
	var roll := _market_roll(maxi(1, total_weight))
	var cursor := 0
	for entry_value in entries:
		var entry: Dictionary = entry_value
		cursor += int(entry.get("weight", 0))
		if roll < cursor:
			return str(entry.get("id", "research_sprint"))
	return "research_sprint"


func _process_policy_calendar(week: int) -> void:
	var comments: Array = policy["comments"]
	for comment_value in comments:
		if not comment_value is Dictionary:
			continue
		var comment: Dictionary = comment_value
		if str(comment.get("status", "")) != "pending" or week < int(comment.get("resolution_week", 999)):
			continue
		var influence := int(policy.get("industry_influence", 0))
		var accepted := influence + _policy_roll(101) >= 70
		comment["status"] = "considered" if accepted else "filed"
		comment["accepted"] = accepted
		var position := str(comment.get("position", ""))
		var issue: Dictionary = policy["issues"]["eval_disclosure"]
		if accepted and position == "strong_disclosure":
			issue["strength"] = clampi(int(issue.get("strength", 1)) + 1, 0, 3)
		elif accepted and position == "industry_flexibility":
			issue["strength"] = clampi(int(issue.get("strength", 1)) - 1, 0, 3)
		issue["stage"] = "final_rule"
		var feed: Array = policy["public_feed"]
		feed.append({
			"id": "policy:comment:%s" % str(comment.get("id", "")), "week": week,
			"headline": "机构发布最终规则，并在说明中%s公司提交的意见。" % ("回应了" if accepted else "列出了"),
			"issue_id": "eval_disclosure", "accepted": accepted,
		})
	var programs: Dictionary = policy["programs"]
	if programs.has("phase_i_grant"):
		var grant: Dictionary = programs["phase_i_grant"]
		if str(grant.get("status", "")) == "awarded" and week >= int(grant.get("milestone_due_week", 999)):
			grant["status"] = "milestone_due"


func _settle_operating_week(week: int) -> Dictionary:
	var gross_profit := weekly_gross_profit_usd()
	var costs := weekly_cost_usd()
	var before := maxi(0, int(ledger.get("cash_usd", 0)))
	var after := maxi(0, before + gross_profit - costs)
	ledger["cash_usd"] = after
	_append_journal("weekly_operations", after - before, {"week": week, "gross_profit_usd": gross_profit, "cost_usd": costs})
	var auto_results: Array[Dictionary] = []
	var commitments: Dictionary = ledger["commitments"]
	var commitment_ids: Array = commitments.keys()
	commitment_ids.sort()
	for commitment_id_value in commitment_ids:
		var commitment_id := str(commitment_id_value)
		var commitment: Dictionary = commitments[commitment_id]
		if str(commitment.get("status", "")) == "open" and bool(commitment.get("auto_settle", false)) and week >= int(commitment.get("due_week", 999)):
			var amount := maxi(0, int(commitment.get("amount_usd", 0)))
			var available := maxi(0, int(ledger.get("cash_usd", 0)))
			var paid := mini(amount, available)
			ledger["cash_usd"] = available - paid
			commitment["paid_usd"] = paid
			commitment["unpaid_usd"] = amount - paid
			commitment["status"] = "paid" if paid == amount else "defaulted"
			auto_results.append({"commitment_id": commitment_id, "paid_usd": paid, "unpaid_usd": amount - paid})
			_append_journal("commitment", -paid, {"commitment_id": commitment_id, "week": week})
	return {
		"settled": true,
		"cash_before_usd": before,
		"cash_after_usd": int(ledger["cash_usd"]),
		"cash_delta_usd": int(ledger["cash_usd"]) - before,
		"gross_profit_usd": gross_profit,
		"cost_usd": costs,
		"commitments": auto_results,
	}


func _market_public_summary() -> Dictionary:
	var public_competitors: Array[Dictionary] = []
	var competitors: Dictionary = market.get("competitors", {})
	var ids: Array = competitors.keys()
	ids.sort()
	for competitor_id_value in ids:
		var competitor_id := str(competitor_id_value)
		var company: Dictionary = competitors[competitor_id]
		var profile: Dictionary = COMPETITOR_PROFILES[competitor_id]
		public_competitors.append({
			"id": competitor_id, "name": profile.get("name", ""),
			"description": profile.get("description", ""),
			"stage": company.get("stage", ""),
			"announced_funding_usd": int(company.get("announced_funding_usd", 0)),
			"public_product_signal": company.get("public_product_signal", "unknown"),
			"last_strategy": company.get("last_strategy", "unknown"),
			"enterprise_logos": int(company.get("enterprise_logos", 0)),
			"solvency": str(company.get("solvency", "operating")),
			"financing_count": int(company.get("financing_count", 0)),
		})
	return {
		"last_ticked_week": int(market.get("last_ticked_week", 0)),
		"category_demand": int(market.get("category_demand", 0)),
		"talent_pressure_bp": int(market.get("talent_pressure_bp", 10_000)),
		"price_pressure_bp": int(market.get("price_pressure_bp", 10_000)),
		"regulatory_scrutiny": int(market.get("regulatory_scrutiny", 0)),
		"competitors": public_competitors,
		"public_feed": Array(market.get("public_feed", [])).duplicate(true),
	}


func _event_candidate(decision_id: String, domain: String, priority: int, reason: String) -> Dictionary:
	return {"decision_id": decision_id, "domain": domain, "priority": priority, "reason": reason}


func _change_cash(delta_usd: int, category: String, metadata: Dictionary = {}) -> void:
	ledger["cash_usd"] = maxi(0, int(ledger.get("cash_usd", 0)) + delta_usd)
	_append_journal(category, delta_usd, metadata)


func _append_journal(category: String, amount_usd: int, metadata: Dictionary = {}) -> void:
	var journal: Array = ledger["journal"]
	journal.append({"category": category, "amount_usd": amount_usd, "metadata": metadata.duplicate(true)})
	while journal.size() > 200:
		journal.pop_front()


func _commit_transaction(transaction_id: String, kind: String, result: Dictionary) -> Dictionary:
	var stored := result.duplicate(true)
	stored["idempotent"] = false
	_transactions[transaction_id] = {"kind": kind, "result": stored.duplicate(true)}
	return stored


func _stored_result(transaction_id: String) -> Dictionary:
	var stored: Dictionary = _transactions.get(transaction_id, {})
	var result: Dictionary = Dictionary(stored.get("result", {})).duplicate(true)
	result["idempotent"] = true
	return result


func _market_roll(max_exclusive: int) -> int:
	var limit := maxi(1, max_exclusive)
	var state := maxi(1, int(market.get("rng_state", MARKET_RNG_INITIAL_STATE)))
	var result := posmod(state, limit)
	state = int((state * RNG_MULTIPLIER) % RNG_MODULUS)
	market["rng_state"] = state if state > 0 else MARKET_RNG_INITIAL_STATE
	return result


func _policy_roll(max_exclusive: int) -> int:
	var limit := maxi(1, max_exclusive)
	var state := maxi(1, int(policy.get("rng_state", POLICY_RNG_INITIAL_STATE)))
	var result := posmod(state, limit)
	state = int((state * RNG_MULTIPLIER) % RNG_MODULUS)
	policy["rng_state"] = state if state > 0 else POLICY_RNG_INITIAL_STATE
	return result


func _allocate_pro_rata(total: int, weights: Dictionary) -> Dictionary:
	var allocation: Dictionary = {}
	var weight_total := 0
	var keys: Array = weights.keys()
	keys.sort()
	for key_value in keys:
		weight_total += maxi(0, int(weights[key_value]))
	if total <= 0 or weight_total <= 0 or keys.is_empty():
		return allocation
	var assigned := 0
	var largest_key := str(keys[0])
	var largest_weight := -1
	for key_value in keys:
		var key := str(key_value)
		var weight := maxi(0, int(weights[key_value]))
		var amount := _floor_div(total * weight, weight_total)
		allocation[key] = amount
		assigned += amount
		if weight > largest_weight:
			largest_weight = weight
			largest_key = key
	allocation[largest_key] = int(allocation.get(largest_key, 0)) + (total - assigned)
	return allocation


func _valid_loaded_state(candidate_ledger: Dictionary, candidate_capital: Dictionary, candidate_investors: Dictionary, candidate_market: Dictionary, candidate_policy: Dictionary) -> bool:
	if int(candidate_ledger.get("cash_usd", -1)) < 0 or not candidate_ledger.get("weekly_costs", null) is Dictionary:
		return false
	if not candidate_capital.get("holders", null) is Dictionary or int(candidate_capital.get("authorized_shares", 0)) <= 0:
		return false
	var share_total := 0
	for holder_value in Dictionary(candidate_capital["holders"]).values():
		if not holder_value is Dictionary or int(Dictionary(holder_value).get("shares", -1)) < 0:
			return false
		share_total += int(Dictionary(holder_value).get("shares", 0))
	if share_total <= 0 or share_total > int(candidate_capital.get("authorized_shares", 0)):
		return false
	for investor_id_value in INVESTOR_PROFILES:
		var investor_id := str(investor_id_value)
		if not candidate_investors.has(investor_id) or not candidate_investors[investor_id] is Dictionary:
			return false
	if not candidate_market.get("competitors", null) is Dictionary:
		return false
	var candidate_competitors: Dictionary = candidate_market["competitors"]
	if candidate_competitors.size() != COMPETITOR_PROFILES.size():
		return false
	for competitor_id_value in COMPETITOR_PROFILES:
		var competitor_id := str(competitor_id_value)
		if not candidate_competitors.has(competitor_id) or not candidate_competitors[competitor_id] is Dictionary:
			return false
	var market_rng := int(candidate_market.get("rng_state", 0))
	var policy_rng := int(candidate_policy.get("rng_state", 0))
	if market_rng <= 0 or market_rng >= RNG_MODULUS or policy_rng <= 0 or policy_rng >= RNG_MODULUS:
		return false
	return true


func _floor_div(numerator: int, denominator: int) -> int:
	if denominator <= 0:
		return 0
	return numerator / denominator


func _ceil_div(numerator: int, denominator: int) -> int:
	if numerator <= 0 or denominator <= 0:
		return 0
	return (numerator + denominator - 1) / denominator
