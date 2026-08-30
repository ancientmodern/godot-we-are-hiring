class_name HiringModel
extends RefCounted

const HiringContentScript = preload("res://src/hiring_content.gd")
const HiringExpansionContentScript = preload("res://src/hiring_expansion_content.gd")
const HiringBusinessSystemScript = preload("res://src/hiring_business_system.gd")
const HiringOperationsSystemScript = preload("res://src/hiring_operations_system.gd")

## Deterministic management simulation for We're Hiring.
##
## The presentation layer may read public_state(), history, flags, and memory, but
## debt and author_weight deliberately do not appear in public_state(). The two
## hidden values are serialized because a save must reproduce the exact run.

const SAVE_VERSION := 1
const DEFAULT_COMPANY_NAME := "Lantern Labs"
const DEBT_GAP_RATE := 0.20
const DEBT_REPAY_RATE := 0.12
const RNG_INITIAL_STATE := 17
const RNG_MODULUS := 2147483647
const RNG_MULTIPLIER := 48271
const TECH_BLOG_CAPABILITY_THRESHOLD := 40.0
const EXCLUSIVE_INTERVIEW_DEBT_THRESHOLD := 55.0
const EXCLUSIVE_INTERVIEW_NEGATIVE_PRESS_CHANCE := 0.45
const LAYOFF_EMPLOYEE_COUNT := 6
const BURN_RATE_MODIFIER_SCALE := 0.25
const MIN_WEEKLY_BURN := 0.25
const MIN_SALARY_BURN_MODIFIER := MIN_WEEKLY_BURN - 1.0

# One table drives both the environmental tier and the employee consequence.
# Keeping these thresholds and formulas declarative makes their exact boundaries
# testable and prevents the two presentations of hidden debt from drifting apart.
const EMPLOYEE_DEBT_TIER_THRESHOLDS := [10.0, 25.0, 45.0, 70.0]
const EMPLOYEE_BELIEF_EROSION_BY_TIER := [0.0, 2.0, 4.0, 6.0, 8.0]
const EMPLOYEE_WITNESS_BELIEF_EROSION := {
	"demo_fake": 1.0,
	"layoff": 1.0,
}
const EMPLOYEE_MORALE_EROSION_MIN_TIER := 3
const EMPLOYEE_MORALE_EROSION_PER_WEEK := 2.0
const EMPLOYEE_DEPARTURE_THRESHOLDS := {
	"belief": 0.0,
	"morale": 0.0,
}

const VALUES_CORPUS_BODIES := {
	1: [
		"做一个能听懂人在说什么的东西。",
		"如果做不出来，就说做不出来。",
	],
	2: [
		"理解先于回答。先承认还不知道，再把问题做小。",
		"我们对团队、客户和彼此使用同一种事实。",
	],
	3: [
		"理解先于回答。我们以可靠、审慎且可扩展的方式，让每一次沟通抵达它真正的意图。",
		"叙事是共同工作的界面。清晰的叙事帮助团队、客户与市场在同一方向上行动。",
		"我们记得研究生时在图书馆一起熬过的那个通宵；那是许多后来决定的起点。",
		"我们不回避困难。我们把困难放进正确的流程，由合适的负责人持续推进。",
	],
}

const CHAPTERS := [
	{"id": "garage", "index": 0, "name": "Chapter 0 · Garage", "weeks": 3, "model_name": "lantern-v0.1", "team_target": 2},
	{"id": "pre_seed", "index": 1, "name": "Chapter 1 · Pre-seed", "weeks": 8, "model_name": "lantern-v0.4", "team_target": 4},
	{"id": "seed", "index": 2, "name": "Chapter 2 · Seed", "weeks": 12, "model_name": "lantern-v1", "team_target": 9},
	{"id": "series_a", "index": 3, "name": "Chapter 3 · Series A", "weeks": 14, "model_name": "Lantern", "team_target": 22},
	{"id": "endgame", "index": 4, "name": "Chapter 4 · Endgame", "weeks": 8, "model_name": "LANTERN", "team_target": 37}
]

const AUTO_STAFF_NAMES := [
	"周岑", "叶澄", "吴真", "彭歆", "方既白", "许栩", "高屿", "李闻",
	"孙遥", "胡安澜", "魏辰", "宋知微", "马嘉树", "罗闻溪", "邱禾", "丁叙",
	"江弥", "白沐", "顾临", "陆宁", "郑朔", "夏榆", "韩清", "蔡茵",
	"冯野", "袁知", "黎川", "杜若", "钟晴", "万行", "熊予", "任澄",
	"姚南", "蒋其", "汪一岑", "康悦", "莫凡", "齐令", "孔今", "章意"
]

const AUTO_STAFF_ROLES := [
	"研究工程师", "数据工程师", "平台工程师", "评测工程师", "产品经理",
	"设计师", "客户工程师", "基础设施工程师", "运营", "人才与文化"
]

const ACTION_IDS := [
	"tweet", "tech_blog", "podcast", "demo_video", "conference_talk", "manifesto", "exclusive_interview",
	"train", "clean_data", "eval", "large_train", "recruit_expert", "alignment_week",
	"interview", "one_on_one", "all_hands", "values_doc", "team_building", "raise_salary", "layoffs",
	"buy_compute", "fundraising", "contract", "do_nothing", "sign", "read_intranet"
]

const EXPANSION_ACTION_IDS := [
	"product_launch", "open_requisition", "vendor_review", "org_review", "office_plan", "policy_program"
]

const CHAPTER_FOUR_ACTIONS := ["sign", "read_intranet", "one_on_one", "do_nothing"]

const OFFICE_STATES := [
	{"tier": 0, "id": "kept", "label": "The office is orderly."},
	{"tier": 1, "id": "whiteboard", "label": "An extra line remains on the whiteboard."},
	{"tier": 2, "id": "boxes", "label": "Boxes collect in the corridor; the pothos is yellowing."},
	{"tier": 3, "id": "frayed", "label": "Posters curl, cups remain, and the far lights stay on."},
	{"tier": 4, "id": "overextended", "label": "The administrative footprint is larger than the office."}
]

const FULFILLMENT_EVENTS := [
	"live_demo",
	"investor_eval",
	"investigative_report",
	"former_employee_post"
]

const EMPLOYEE_TEMPLATES := [
	{"id": "chen_xiaoyu", "name": "陈小雨", "role": "数据工程师", "skill": 90, "morale": 72, "belief": 82},
	{"id": "zhao_ke", "name": "赵珂", "role": "评测工程师", "skill": 90, "morale": 68, "belief": 75},
	{"id": "xie_ning", "name": "谢宁", "role": "产品经理", "skill": 80, "morale": 76, "belief": 80},
	{"id": "he_miao", "name": "何淼", "role": "前端工程师", "skill": 70, "morale": 84, "belief": 88},
	{"id": "luo_qi", "name": "罗绮", "role": "研究员", "skill": 90, "morale": 64, "belief": 70},
	{"id": "guo_jun", "name": "郭骏", "role": "基础设施工程师", "skill": 90, "morale": 73, "belief": 66},
	{"id": "su_yan", "name": "苏妍", "role": "设计师", "skill": 100, "morale": 79, "belief": 72},
	{"id": "tang_li", "name": "唐莉", "role": "商务负责人", "skill": 90, "morale": 81, "belief": 85},
	{"id": "wang_zhe", "name": "王哲", "role": "运营", "skill": 80, "morale": 70, "belief": 74},
	{"id": "xu_an", "name": "许岸", "role": "人才与文化", "skill": 90, "morale": 75, "belief": 61}
]

## Higher numbers mean an earlier campaign-resolution check.  Second Time is
## retained in the content registry for the NG+ opening, but has no campaign
## resolution priority.
const ENDING_PRIORITIES := {
	"rm_rf": 600,
	"lights_out": 500,
	"drift": 400,
	"successor": 300,
	"independent": 200,
	"acquihire": 100,
	"second_time": 0
}

const ENDINGS := {
	"acquihire": {"title": "Acquisition", "priority": ENDING_PRIORITIES["acquihire"]},
	"lights_out": {"title": "Lights Out", "priority": ENDING_PRIORITIES["lights_out"]},
	"independent": {"title": "Independent", "priority": ENDING_PRIORITIES["independent"]},
	"successor": {"title": "Succession", "priority": ENDING_PRIORITIES["successor"]},
	"drift": {"title": "Drift", "priority": ENDING_PRIORITIES["drift"]},
	"rm_rf": {"title": "rm -rf", "priority": ENDING_PRIORITIES["rm_rf"]},
	"second_time": {"title": "Second Time", "priority": ENDING_PRIORITIES["second_time"]}
}

var company_name := DEFAULT_COMPANY_NAME
var chapter := 0
var week_in_chapter := 1
var total_week := 1
var cash_weeks := 10.0
var compute := 8.0
var narrative := 8.0
var capability := 12.0
var coherence := 100.0
var debt := 0.0
var author_weight := 0.0
var forced_writer_stage := 1
var delegation_count := 0
var manual_training_count := 0
var morale := 72.0
var attention := 0
var attention_max := 3
var training_boost_uses := 0
var salary_burn_modifier := 0.0
var fulfillment_pressure := 0.0
var fulfillment_events := 0
var second_run := false
var business
var operations

var employees: Array[Dictionary] = []
var former_employees: Array[Dictionary] = []
var history: Array[Dictionary] = []
var flags: Dictionary = {}
var memory: Dictionary = {}
var performed_actions: Array[String] = []
var week_active := false
var week_resolved := false
var campaign_complete := false
var rng_state := RNG_INITIAL_STATE


func _init() -> void:
	business = HiringBusinessSystemScript.new()
	operations = HiringOperationsSystemScript.new()
	reset()


func reset(new_company_name: String = DEFAULT_COMPANY_NAME, is_second_run: bool = false) -> void:
	company_name = new_company_name.strip_edges()
	if company_name.is_empty():
		company_name = DEFAULT_COMPANY_NAME
	chapter = 0
	week_in_chapter = 1
	total_week = 1
	cash_weeks = 10.0
	compute = 8.0
	narrative = 8.0
	capability = 12.0
	coherence = 100.0
	debt = 0.0
	author_weight = 0.0
	forced_writer_stage = 1
	delegation_count = 0
	manual_training_count = 0
	morale = 72.0
	attention = 0
	attention_max = 3
	training_boost_uses = 0
	salary_burn_modifier = 0.0
	fulfillment_pressure = 0.0
	fulfillment_events = 0
	rng_state = RNG_INITIAL_STATE
	second_run = is_second_run
	business.reset()
	operations.reset(104729 + (1 if second_run else 0))
	employees = [
		_make_employee({
			"id": "lin_yue",
			"name": "林越",
			"role": "联合创始人 / CTO",
			"skill": 88,
			"morale": 76,
			"belief": 92
		})
	]
	former_employees = []
	history = []
	flags = {"second_run": second_run}
	memory = {
		"action_counts": {},
		"weeks_without_ai": 0,
		"candidate_cursor": 0,
		"hire_serial": 0,
		"values_version": 1,
		"latest_values_author": "founders",
		"values_v1_in_corpus": true,
		"values_corpus": [{
			"id": "values_v1",
			"version": 1,
			"revision": 1,
			"created_total_week": 1,
			"chapter": 0,
			"week_in_chapter": 1,
			"author": "founders",
			"approved_by": "founders",
			"source": "founding_document",
			"body": Array(VALUES_CORPUS_BODIES[1]).duplicate(),
		}],
		"fulfillment_queue": [],
		"completed_runs": 1 if second_run else 0
	}
	performed_actions = []
	week_active = false
	week_resolved = false
	campaign_complete = false
	_refresh_company_morale()
	_record_history("run_reset", {"company_name": company_name, "second_run": second_run})
	if second_run:
		flags["future_mug_present"] = true
		memory["future_mug_text"] = "First All-Hands · 2024"
	_sync_operating_roster()


func begin_week() -> Dictionary:
	if campaign_complete:
		return _failure("campaign_complete")
	if week_active:
		return _failure("week_already_active")
	if cash_weeks <= 0.0:
		campaign_complete = true
		flags["cash_exhausted"] = true
		return _failure("cash_exhausted")
	attention_max = 1 if chapter == 4 else 3
	attention = attention_max
	performed_actions.clear()
	flags.erase("training_blocked_this_week")
	flags.erase("ai_used_this_week")
	flags.erase("fulfillment_event_pending")
	week_active = true
	week_resolved = false

	var stage := writer_stage()
	if stage >= 2:
		memory["last_unsolicited_week"] = total_week
		_record_history("ai_unsolicited", {"stage": stage, "text": "I prepared a short note in case it helps."})
	if stage >= 3:
		flags["options_in_assistant_voice"] = true
	if stage >= 4:
		_run_stage_four_administration()
	if stage >= 5:
		ensure_stage_five_autonomy_for_current_week()
	if chapter == 4 and delegation_count == 0 and not bool(memory.get("never_delegated_question_resolved", false)):
		flags["never_delegated_question"] = true
		memory["never_delegated_line"] = "You have never asked me to write for you. Why?"

	_record_history("week_began", {
		"attention": attention,
		"writer_stage": writer_stage(),
		"model_name": str(CHAPTERS[chapter]["model_name"])
	})
	return {"ok": true, "attention": attention, "state": public_state()}


func can_act(action_id: String, use_ai: bool = false) -> bool:
	if not week_active or week_resolved or campaign_complete:
		return false
	if not ACTION_IDS.has(action_id) and not EXPANSION_ACTION_IDS.has(action_id):
		return false
	if performed_actions.has(action_id):
		return false
	# Three attention points buy three founder-authored actions. Delegation adds
	# one, and only one, extra action slot; it is not an unlimited bypass that
	# lets the player clear all five cards. Deriving the cap from saved weekly
	# state keeps the invariant intact across save/resume without a second counter.
	if performed_actions.size() >= attention_max + 1:
		return false
	if use_ai and bool(flags.get("ai_used_this_week", false)):
		return false
	if chapter == 4 and not CHAPTER_FOUR_ACTIONS.has(action_id):
		return false
	var action_spec_value = HiringContentScript.ACTIONS.get(action_id, HiringExpansionContentScript.SYSTEM_ACTIONS.get(action_id, {}))
	if not action_spec_value is Dictionary:
		return false
	var action_spec: Dictionary = action_spec_value
	var unlock_chapter := int(action_spec.get("unlock_chapter", 99))
	var unlock_week := maxi(1, int(action_spec.get("unlock_week", 1)))
	if chapter < unlock_chapter or (chapter == unlock_chapter and week_in_chapter < unlock_week):
		return false
	if EXPANSION_ACTION_IDS.has(action_id) and not bool(operating_action_status(action_id).get("available", true)):
		return false
	if not use_ai and attention < _attention_cost(action_id):
		return false
	if action_id in ["train", "large_train"] and bool(flags.get("training_blocked_this_week", false)):
		return false
	match action_id:
		"train":
			return compute >= 1.0
		"eval":
			return compute >= 1.0
		"large_train":
			return compute >= 8.0
		"buy_compute":
			return cash_weeks >= 2.0
		"interview":
			return cash_weeks >= 1.0
		"raise_salary":
			return cash_weeks >= 2.0
		"one_on_one":
			return not employees.is_empty()
	return true


func operating_action_status(action_id: String) -> Dictionary:
	match action_id:
		"open_requisition":
			for candidate_value in operations.candidates.values():
				if candidate_value is Dictionary and str(Dictionary(candidate_value).get("status", "")) == "in_process":
					return {"available": true, "phase": "pipeline"}
			for offer_value in operations.offers:
				if offer_value is Dictionary and str(Dictionary(offer_value).get("status", "")) == "pending":
					return {"available": false, "reason": "候选人正在比较 offer；结果会在周结算时到达"}
			for candidate_value in operations.candidates.values():
				if candidate_value is Dictionary and str(Dictionary(candidate_value).get("status", "available")) == "available":
					return {"available": true, "phase": "requisition"}
			return {"available": false, "reason": "候选人才库已清空；先等待人才市场回流"}
		"org_review":
			for employee_id_value in operations.employees:
				var employee_id := str(employee_id_value)
				var employee: Dictionary = operations.employees[employee_id]
				if bool(employee.get("active", true)) and not _employee_has_active_training(employee_id) and not Dictionary(employee.get("skills", {})).is_empty():
					return {"available": true, "phase": "development"}
			return {"available": false, "reason": "现有培养计划仍在进行；完成后再安排下一项"}
		"office_plan":
			var active: Dictionary = operations.office.get("active_lease", {})
			var signed: Dictionary = operations.office.get("signed_lease", {})
			if not signed.is_empty():
				return {"available": false, "reason": "新办公室正在等待搬入；租约节点会在周结算推进"}
			if active.is_empty():
				return {"available": true, "phase": "lease"}
			var used: Dictionary = {}
			for item_value in Array(operations.office.get("completed_fitouts", [])) + Array(operations.office.get("fitouts_in_progress", [])):
				if item_value is Dictionary:
					used[str(Dictionary(item_value).get("id", ""))] = true
			for fitout_id in ["acoustic_pods", "training_room", "flex_desks", "demo_room"]:
				if not used.has(str(fitout_id)):
					return {"available": true, "phase": "fitout"}
			return {"available": false, "reason": "当前办公室方案已完成；新的空间需求会触发下一轮选址"}
		"policy_program":
			var programs: Dictionary = business.policy.get("programs", {})
			if programs.has("phase_i_grant"):
				return {"available": false, "reason": "本轮研发扶持已提交；验收与尾款将按里程碑推进"}
	return {"available": true}


func _employee_has_active_training(employee_id: String) -> bool:
	for training_value in operations.trainings:
		if training_value is Dictionary and str(Dictionary(training_value).get("employee_id", "")) == employee_id and str(Dictionary(training_value).get("status", "")) == "active":
			return true
	return false


func perform_action(action_id: String, use_ai: bool = false) -> Dictionary:
	if not can_act(action_id, use_ai):
		return _failure("action_unavailable", action_id)
	# Entering the strategy layer is the migration boundary from the compact
	# narrative runway to the exact USD ledger.  Align the ledger before the first
	# operating commitment so every later cash movement has one authority.
	if EXPANSION_ACTION_IDS.has(action_id) and not uses_authoritative_financial_ledger():
		_activate_financial_ledger_authority()

	var attention_spent := 0 if use_ai else _attention_cost(action_id)
	var resolution := _resolve_action(action_id)
	var effects: Dictionary = Dictionary(resolution.get("effects", {})).duplicate(true)
	var messages: Array = Array(resolution.get("messages", [])).duplicate()
	var events: Array = Array(resolution.get("events", [])).duplicate()
	# A detailed financing transaction already brings its exact proceeds into the
	# USD ledger.  Do not also mint the legacy abstract runway reward.
	if action_id == "fundraising" and uses_authoritative_financial_ledger():
		effects.erase("cash_weeks")
	if use_ai:
		# Signing is the finale's deliberate no-effect action. Delegating it still
		# occupies the one weekly AI slot and is recorded as AI use, but must not
		# smuggle in generic runway, morale, debt, authorship bonuses, or the
		# generic comfort message used to make ordinary delegation feel helpful.
		if action_id != "sign":
			_apply_ai_advantage(action_id, effects)
			messages.append("LANTERN 用你的口吻处理了它。这一周轻松了一点。")
		events.append("ai_delegated")
		flags["ai_used_this_week"] = true
		record_delegation("action", action_id)
	else:
		attention -= attention_spent

	performed_actions.append(action_id)
	apply_effects(effects)
	_apply_operating_action(action_id, use_ai)
	if action_id == "fundraising" and uses_authoritative_financial_ledger():
		var financing_result: Dictionary = memory.get("last_business_financing", {})
		if bool(financing_result.get("already_recorded", false)):
			messages.append("本阶段融资已完成；这次会议没有再次增加现金或稀释股权。")
	if EXPANSION_ACTION_IDS.has(action_id):
		var operating_summary := str(memory.get("last_operating_action_summary", "")).strip_edges()
		if not operating_summary.is_empty():
			messages.append(operating_summary)
	_apply_action_side_effects(action_id, use_ai, messages, events)
	_increment_action_memory(action_id, use_ai)
	_record_history("action", {
		"action_id": action_id,
		"used_ai": use_ai,
		"attention_spent": attention_spent,
		"effects": effects.duplicate(true),
		"events": events.duplicate()
	})
	return {
		"ok": true,
		"action_id": action_id,
		"used_ai": use_ai,
		"attention_spent": attention_spent,
		"effects": effects,
		"messages": messages,
		"events": events,
		"state": public_state()
	}


func apply_effects(effects: Dictionary) -> Dictionary:
	var before := _mechanical_snapshot()
	if effects.has("cash_percent"):
		if uses_authoritative_financial_ledger():
			var cash_before_usd := int(business.ledger.get("cash_usd", 0))
			var percent_delta_usd := int(round(float(cash_before_usd) * float(effects.get("cash_percent", 0.0)) / 100.0))
			_record_authoritative_cash_delta(percent_delta_usd, "story_cash_percent", {"percent": float(effects.get("cash_percent", 0.0))})
		else:
			cash_weeks *= 1.0 + float(effects.get("cash_percent", 0.0)) / 100.0
	if int(effects.get("narrative_set_to_capability", 0)) != 0:
		narrative = capability
	if effects.has("burn_rate"):
		salary_burn_modifier = maxf(
			MIN_SALARY_BURN_MODIFIER,
			salary_burn_modifier + float(effects.get("burn_rate", 0.0)) * BURN_RATE_MODIFIER_SCALE
		)
	var runway_delta := float(effects.get("cash_weeks", 0.0))
	if uses_authoritative_financial_ledger() and not is_zero_approx(runway_delta):
		var runway_unit_usd := maxi(1, business.weekly_burn_usd())
		if runway_unit_usd <= 1:
			runway_unit_usd = maxi(1, business.weekly_cost_usd())
		_record_authoritative_cash_delta(int(round(runway_delta * float(runway_unit_usd))), "story_runway_bridge", {"runway_units": runway_delta})
	else:
		cash_weeks += runway_delta
	compute += float(effects.get("compute", 0.0))
	narrative += float(effects.get("narrative", 0.0))
	capability += float(effects.get("capability", 0.0))
	coherence += float(effects.get("coherence", 0.0))
	debt += float(effects.get("debt", 0.0))
	author_weight += float(effects.get("author_weight", 0.0))
	attention += int(effects.get("attention", 0))
	training_boost_uses += int(effects.get("training_boost_uses", 0))

	var morale_delta := float(effects.get("morale", 0.0))
	var belief_delta := float(effects.get("belief", 0.0))
	if not is_zero_approx(morale_delta) or not is_zero_approx(belief_delta):
		for employee in employees:
			employee["morale"] = clampf(float(employee.get("morale", 50.0)) + morale_delta, 0.0, 100.0)
			employee["belief"] = clampf(float(employee.get("belief", 50.0)) + belief_delta, 0.0, 100.0)
		morale = clampf(morale + morale_delta, 0.0, 100.0)

	var set_flags_value = effects.get("set_flags", {})
	if set_flags_value is Dictionary:
		for key in set_flags_value:
			flags[str(key)] = set_flags_value[key]
	var add_flags_value = effects.get("add_flags", [])
	if add_flags_value is Array:
		for flag_value in add_flags_value:
			flags[str(flag_value)] = true
	var remove_flags_value = effects.get("remove_flags", [])
	if remove_flags_value is Array:
		for flag_value in remove_flags_value:
			flags.erase(str(flag_value))

	var memory_value = effects.get("memory", {})
	if memory_value is Dictionary:
		for key in memory_value:
			memory[str(key)] = memory_value[key]

	var witness_value = effects.get("witness", [])
	if witness_value is String:
		_add_witness_to_all(str(witness_value))
	elif witness_value is Array:
		for witness_flag in witness_value:
			_add_witness_to_all(str(witness_flag))

	var add_employee_value = effects.get("add_employee", null)
	if add_employee_value is Dictionary:
		_add_employee(Dictionary(add_employee_value))
	elif add_employee_value is Array:
		for employee_value in add_employee_value:
			if employee_value is Dictionary:
				_add_employee(Dictionary(employee_value))

	var remove_employee_id := str(effects.get("remove_employee_id", ""))
	if not remove_employee_id.is_empty():
		_remove_employee_by_id(remove_employee_id, "fixed_choice")

	if uses_authoritative_financial_ledger():
		_sync_legacy_runway_from_business()
	else:
		cash_weeks = maxf(cash_weeks, 0.0)
	compute = maxf(compute, 0.0)
	narrative = clampf(narrative, 0.0, 100.0)
	capability = clampf(capability, 0.0, 100.0)
	coherence = clampf(coherence, 0.0, 100.0)
	debt = clampf(debt, 0.0, 999.0)
	author_weight = clampf(author_weight, 0.0, 100.0)
	attention = clampi(attention, 0, attention_max)
	training_boost_uses = maxi(0, training_boost_uses)
	_refresh_company_morale()
	return {"before": before, "after": _mechanical_snapshot()}


func end_week() -> Dictionary:
	if not week_active or week_resolved:
		return _failure("no_active_week")
	if bool(flags.get("expansion_systems_unlocked", false)) and not uses_authoritative_financial_ledger():
		_activate_financial_ledger_authority()
	var before := _mechanical_snapshot()

	# Iron rule: narrative decays exactly two points every week, before the gap is
	# booked. Capability above narrative is the only passive way to repay debt.
	narrative = maxf(0.0, narrative - 2.0)
	var gap := narrative - capability
	var debt_delta := 0.0
	if gap > 0.0:
		debt_delta = gap * DEBT_GAP_RATE
		debt += debt_delta
	elif gap < 0.0 and debt > 0.0:
		debt_delta = -minf(debt, absf(gap) * DEBT_REPAY_RATE)
		debt += debt_delta
	debt = clampf(debt, 0.0, 999.0)

	var burn := maxf(MIN_WEEKLY_BURN, 1.0 + salary_burn_modifier)
	if not uses_authoritative_financial_ledger():
		cash_weeks = maxf(0.0, cash_weeks - burn)
	_update_fulfillment_pressure()
	_erode_employee_belief()
	_process_departures()
	_tick_company_systems()
	if uses_authoritative_financial_ledger():
		_sync_legacy_runway_from_business()

	if bool(flags.get("ai_used_this_week", false)):
		memory["weeks_without_ai"] = 0
	else:
		memory["weeks_without_ai"] = int(memory.get("weeks_without_ai", 0)) + 1
	var worked_through_meals := attention == 0 and not performed_actions.has("do_nothing")
	if worked_through_meals:
		memory["missed_meals"] = int(memory.get("missed_meals", 0)) + 1
	else:
		memory["missed_meals"] = 0
	if int(memory.get("missed_meals", 0)) >= 3:
		flags["missed_meals_3"] = true
		if not memory.has("missed_meal_callback_due_week"):
			memory["missed_meal_callback_due_week"] = total_week + 1
	if cash_weeks <= 0.0:
		flags["cash_exhausted"] = true
	if coherence < 20.0:
		flags["coherence_lost"] = true

	week_active = false
	week_resolved = true
	_record_history("week_ended", {
		"narrative_decay": -2.0,
		"capability_gap": gap,
		"debt_delta": debt_delta,
		"burn": burn,
		"office_tier": office_deterioration_tier()
	})
	var settlement_lines: Array = Array(memory.get("last_company_settlement_lines", [])).duplicate() if bool(flags.get("expansion_systems_unlocked", false)) else []
	return {
		"ok": true,
		"before": before,
		"after": _mechanical_snapshot(),
		"narrative_decay": -2.0,
		"debt_delta": debt_delta,
		"office_tier": office_deterioration_tier(),
		"lines": settlement_lines,
		"state": public_state()
	}


func advance_week() -> Dictionary:
	if not week_resolved:
		return _failure("week_not_resolved")
	if cash_weeks <= 0.0:
		campaign_complete = true
		return {"ok": true, "campaign_complete": true, "ending": select_ending()}

	var changed_chapter := false
	var chapter_length := int(CHAPTERS[chapter]["weeks"])
	if week_in_chapter >= chapter_length:
		if chapter >= CHAPTERS.size() - 1:
			campaign_complete = true
			week_resolved = false
			return {"ok": true, "campaign_complete": true, "ending": select_ending()}
		chapter += 1
		week_in_chapter = 1
		changed_chapter = true
		flags["entered_%s" % str(CHAPTERS[chapter]["id"])] = true
		_scale_team_to_chapter_target()
	else:
		week_in_chapter += 1
	total_week += 1
	week_resolved = false
	attention = 0
	_record_history("week_advanced", {"chapter_changed": changed_chapter})
	return {
		"ok": true,
		"campaign_complete": false,
		"chapter_changed": changed_chapter,
		"chapter": chapter,
		"week_in_chapter": week_in_chapter,
		"total_week": total_week
	}


func writer_stage() -> int:
	var accumulated_stage := 1
	if author_weight >= 90.0:
		accumulated_stage = 5
	elif author_weight >= 70.0:
		accumulated_stage = 4
	elif author_weight >= 40.0:
		accumulated_stage = 3
	elif author_weight >= 20.0:
		accumulated_stage = 2
	return maxi(forced_writer_stage, accumulated_stage)


func force_writer_stage(stage: int) -> bool:
	var requested := clampi(stage, 1, 5)
	if requested <= forced_writer_stage:
		return false
	var before := forced_writer_stage
	forced_writer_stage = requested
	_record_history("writer_stage_forced", {"before": before, "after": forced_writer_stage})
	return true


func record_delegation(source_kind: String, source_id: String = "") -> int:
	delegation_count += 1
	flags["has_delegated"] = true
	flags.erase("never_delegated_question")
	memory["last_delegation_kind"] = source_kind
	memory["last_delegation_id"] = source_id
	_record_history("delegation", {
		"source_kind": source_kind,
		"source_id": source_id,
		"count": delegation_count,
	})
	return delegation_count


func public_state() -> Dictionary:
	var chapter_data: Dictionary = CHAPTERS[chapter]
	var visible_employees: Array[Dictionary] = []
	for employee in employees:
		visible_employees.append({
			"id": str(employee.get("id", "")),
			"name": str(employee.get("name", "")),
			"role": str(employee.get("role", "")),
			"skill": int(round(float(employee.get("skill", 0.0)))),
			"morale": int(round(float(employee.get("morale", 0.0)))),
			"belief": int(round(float(employee.get("belief", 0.0)))),
			"level": int(employee.get("level", 1)),
			"salary_annual": float(employee.get("salary_annual", 0.0)),
			"equity_bps": float(employee.get("equity_bps", 0.0)),
			"team_id": str(employee.get("team_id", "founders")),
			"manager_id": str(employee.get("manager_id", "")),
			"ramp": float(employee.get("ramp", 1.0)),
			"burnout": float(employee.get("burnout", 0.0)),
			"flight_risk": float(employee.get("flight_risk", 0.0)),
			"skills": Dictionary(employee.get("skills", {})).duplicate(true),
			"witnessed": Array(employee.get("witnessed", [])).duplicate()
		})
	var office_state: Dictionary = OFFICE_STATES[office_deterioration_tier()]
	return {
		"company_name": company_name,
		"chapter": chapter,
		"chapter_id": str(chapter_data["id"]),
		"chapter_name": str(chapter_data["name"]),
		"week_in_chapter": week_in_chapter,
		"chapter_weeks": int(chapter_data["weeks"]),
		"total_week": total_week,
		"model_name": str(chapter_data["model_name"]),
		"runway_weeks": business.runway_weeks() if uses_authoritative_financial_ledger() else maxi(0, int(ceil(cash_weeks / maxf(MIN_WEEKLY_BURN, 1.0 + salary_burn_modifier)))),
		"compute": int(round(compute)),
		"narrative": int(round(narrative)),
		"capability": int(round(capability)),
		"coherence": int(round(coherence)),
		"morale": int(round(morale)),
		"attention": attention,
		"attention_max": attention_max,
		"team_size": 1 + employees.size(),
		"employees": visible_employees,
		"office_tier": int(office_state["tier"]),
		"office_state": str(office_state["id"]),
		"office_description": str(office_state["label"]),
		"fulfillment_pressure": fulfillment_pressure_label(),
		"writer_stage": writer_stage(),
		"option_voice": "assistant" if writer_stage() >= 3 else "founder",
		"autonomy_level": maxi(0, writer_stage() - 1),
		"business": business.public_state(),
		"operations": operations.public_state(),
		"campaign_complete": campaign_complete
	}


func select_ending() -> Dictionary:
	# DEC-008 is the sole campaign resolver. Second Time is authored opening
	# content and is intentionally unreachable from this function.
	var ending_id := "acquihire"
	var reason := "The company survived, and its founder still authored enough of it to be acquired."
	if bool(flags.get("rm_rf", false)):
		ending_id = "rm_rf"
		reason = "The terminal command was entered during a night shift."
	elif cash_weeks <= 0.0 or bool(flags.get("cash_exhausted", false)):
		ending_id = "lights_out"
		reason = "The runway reached zero."
	elif coherence < 20.0:
		ending_id = "drift"
		reason = "The company's statements no longer form a coherent whole."
	elif author_weight >= 100.0:
		ending_id = "successor"
		reason = "LANTERN now authors the company completely."
	elif capability >= 80.0 and debt < 10.0:
		ending_id = "independent"
		reason = "Real capability caught the promise, with almost no debt left."
	var definition: Dictionary = ENDINGS[ending_id]
	return {
		"id": ending_id,
		"title": str(definition["title"]),
		"priority": int(definition["priority"]),
		"company_name": company_name,
		"reason": reason
	}


func to_save() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"company_name": company_name,
		"chapter": chapter,
		"week_in_chapter": week_in_chapter,
		"total_week": total_week,
		"cash_weeks": cash_weeks,
		"compute": compute,
		"narrative": narrative,
		"capability": capability,
		"coherence": coherence,
		"debt": debt,
		"author_weight": author_weight,
		"forced_writer_stage": forced_writer_stage,
		"delegation_count": delegation_count,
		"manual_training_count": manual_training_count,
		"morale": morale,
		"attention": attention,
		"attention_max": attention_max,
		"training_boost_uses": training_boost_uses,
		"salary_burn_modifier": salary_burn_modifier,
		"fulfillment_pressure": fulfillment_pressure,
		"fulfillment_events": fulfillment_events,
		"rng_state": rng_state,
		"second_run": second_run,
		"employees": employees.duplicate(true),
		"former_employees": former_employees.duplicate(true),
		"history": history.duplicate(true),
		"flags": flags.duplicate(true),
		"memory": memory.duplicate(true),
		"performed_actions": performed_actions.duplicate(),
		"week_active": week_active,
		"week_resolved": week_resolved,
		"campaign_complete": campaign_complete,
		"business_system": business.to_save(),
		"operations_system": operations.to_save(),
	}


func from_save(data: Dictionary) -> bool:
	if int(data.get("save_version", -1)) != SAVE_VERSION:
		return false
	reset(str(data.get("company_name", DEFAULT_COMPANY_NAME)), bool(data.get("second_run", false)))
	chapter = clampi(int(data.get("chapter", 0)), 0, CHAPTERS.size() - 1)
	week_in_chapter = clampi(int(data.get("week_in_chapter", 1)), 1, int(CHAPTERS[chapter]["weeks"]))
	total_week = maxi(1, int(data.get("total_week", 1)))
	cash_weeks = maxf(0.0, float(data.get("cash_weeks", 10.0)))
	compute = maxf(0.0, float(data.get("compute", 8.0)))
	narrative = clampf(float(data.get("narrative", 8.0)), 0.0, 100.0)
	capability = clampf(float(data.get("capability", 12.0)), 0.0, 100.0)
	coherence = clampf(float(data.get("coherence", 100.0)), 0.0, 100.0)
	debt = clampf(float(data.get("debt", 0.0)), 0.0, 999.0)
	author_weight = clampf(float(data.get("author_weight", 0.0)), 0.0, 100.0)
	forced_writer_stage = clampi(int(data.get("forced_writer_stage", 1)), 1, 5)
	delegation_count = maxi(0, int(data.get("delegation_count", 0)))
	manual_training_count = maxi(0, int(data.get("manual_training_count", 0)))
	morale = clampf(float(data.get("morale", 72.0)), 0.0, 100.0)
	attention = maxi(0, int(data.get("attention", 0)))
	attention_max = clampi(int(data.get("attention_max", 3)), 1, 3)
	training_boost_uses = maxi(0, int(data.get("training_boost_uses", 0)))
	salary_burn_modifier = maxf(MIN_SALARY_BURN_MODIFIER, float(data.get("salary_burn_modifier", 0.0)))
	fulfillment_pressure = maxf(0.0, float(data.get("fulfillment_pressure", 0.0)))
	fulfillment_events = maxi(0, int(data.get("fulfillment_events", 0)))
	rng_state = maxi(1, int(data.get("rng_state", RNG_INITIAL_STATE)))

	employees = []
	var loaded_employees = data.get("employees", [])
	if loaded_employees is Array:
		for employee_value in loaded_employees:
			if employee_value is Dictionary:
				employees.append(_make_employee(Dictionary(employee_value)))
	former_employees = []
	var loaded_former = data.get("former_employees", [])
	if loaded_former is Array:
		for employee_value in loaded_former:
			if employee_value is Dictionary:
				former_employees.append(Dictionary(employee_value).duplicate(true))

	history = []
	var loaded_history = data.get("history", [])
	if loaded_history is Array:
		for entry in loaded_history:
			if entry is Dictionary:
				history.append(Dictionary(entry).duplicate(true))
	flags = Dictionary(data.get("flags", {})).duplicate(true)
	memory = Dictionary(data.get("memory", {})).duplicate(true)
	# Compatibility with saves made before scripted writer presentation, AI use,
	# and founder-authored training had independent serialized counters.
	if not data.has("forced_writer_stage"):
		if bool(flags.get("seen_version_disappears", false)):
			forced_writer_stage = 5
		elif bool(flags.get("seen_the_accent", false)):
			forced_writer_stage = 3
	if not data.has("delegation_count"):
		delegation_count = maxi(0, int(memory.get("delegation_count", memory.get("ai_uses", 0))))
	if not data.has("manual_training_count"):
		manual_training_count = _manual_training_count_from_history()
	memory.erase("delegation_count")
	memory.erase("ai_uses")
	performed_actions = []
	var loaded_actions = data.get("performed_actions", [])
	if loaded_actions is Array:
		for action_id in loaded_actions:
			performed_actions.append(str(action_id))
	week_active = bool(data.get("week_active", false))
	week_resolved = bool(data.get("week_resolved", false))
	campaign_complete = bool(data.get("campaign_complete", false))
	second_run = bool(data.get("second_run", false))
	var loaded_business_system := data.has("business_system")
	var loaded_operations_system := data.has("operations_system")
	if loaded_business_system and not business.from_save(Dictionary(data.get("business_system", {}))):
		return false
	if loaded_operations_system and not operations.from_save(Dictionary(data.get("operations_system", {}))):
		return false
	# A current save already contains the exact independently serialized roster,
	# RNG, commitments, and operations history.  Re-syncing here would append a
	# new audit entry merely because the file was loaded, breaking deterministic
	# save/resume.  Compatibility saves predating this subsystem are enriched once.
	if not loaded_operations_system:
		_sync_operating_roster()
	_refresh_company_morale()
	return true


func office_deterioration_tier() -> int:
	var tier := 0
	for threshold_value in EMPLOYEE_DEBT_TIER_THRESHOLDS:
		if debt < float(threshold_value):
			break
		tier += 1
	return tier


func fulfillment_pressure_label() -> String:
	var tier := office_deterioration_tier()
	if tier >= 4 or fulfillment_pressure >= 0.75:
		return "imminent"
	if tier >= 3 or fulfillment_pressure >= 0.45:
		return "high"
	if tier >= 1 or fulfillment_pressure > 0.0:
		return "present"
	return "quiet"


func _resolve_action(action_id: String) -> Dictionary:
	var effects: Dictionary = {}
	var messages: Array[String] = []
	var events: Array[String] = []
	match action_id:
		"tweet":
			effects = {"narrative": _roll_action_range(5, 9)}
			messages.append("一条简短的推文找到了它的受众。")
		"tech_blog":
			effects = {"narrative": 7.0}
			if capability < TECH_BLOG_CAPABILITY_THRESHOLD:
				effects["debt"] = 4.0
				events.append("blog_overclaims")
			messages.append("技术文章让路线图听起来已经尘埃落定。")
		"podcast":
			effects = {"narrative": 14.0, "coherence": -3.0}
			messages.append("一小时谈话，剪出了三分钟可以被引用的内容。")
		"demo_video":
			effects = {"narrative": 18.0, "debt": 8.0}
			events.append("demo_edited")
			messages.append("第十一版剪辑看起来几乎没有等待。")
		"conference_talk":
			effects = {"narrative": 12.0, "morale": 10.0}
			messages.append("现场鼓了掌；团队回去以后又看了一遍录像。")
		"manifesto":
			effects = {"narrative": 25.0, "coherence": -10.0, "debt": 12.0}
			messages.append("那份宣言许下了一个大到可以脱离产品独自传播的承诺。")
		"exclusive_interview":
			if debt > EXCLUSIVE_INTERVIEW_DEBT_THRESHOLD and _roll_probability(EXCLUSIVE_INTERVIEW_NEGATIVE_PRESS_CHANCE):
				effects = {"narrative": -8.0, "coherence": -5.0}
				events.append("negative_press")
				messages.append("报道把每一项说法和实际产品排在了一起。")
			else:
				effects = {"narrative": 20.0}
				messages.append("报道给了公司一个干净、完整的起源故事。")
		"train":
			var gain := _roll_action_range(3, 6)
			if training_boost_uses > 0:
				gain *= 1.5
				effects["training_boost_uses"] = -1
			effects["capability"] = gain
			effects["compute"] = -1.0
			messages.append("一轮缓慢的训练，让东西本身变好了一点。")
		"clean_data":
			effects = {"training_boost_uses": 3}
			messages.append("接下来三轮训练的效率会提高一半。")
		"eval":
			# The authored -5 is the value of formally verifying the model for the
			# first time, not a renewable substitute for making the model better.
			# Keep later evals available as honest curve updates, but do not let the
			# persisted verification flag become a weekly debt-clear loop.
			effects = {"compute": -1.0, "set_flags": {"capability_revealed": true}}
			if not bool(flags.get("capability_revealed", false)):
				effects["debt"] = -5.0
			events.append("true_capability_seen")
			if effects.has("debt"):
				messages.append("诚实的曲线更低，但终于有用了。")
			else:
				messages.append("曲线更新了。重复核验没有替任何承诺兑现。")
		"large_train":
			var large_gain := _roll_action_range(12, 18)
			if training_boost_uses > 0:
				large_gain *= 1.5
				effects["training_boost_uses"] = -1
			effects["capability"] = large_gain
			effects["compute"] = -8.0
			messages.append("集群跑了整个周末。")
		"recruit_expert":
			var expert := _next_candidate(true)
			effects = {"morale": -8.0, "add_employee": expert}
			messages.append("一个强得让人不安的研究员接受了邀请。所有人都重新校准了自己。")
		"alignment_week":
			effects = {"coherence": 12.0, "narrative": -5.0}
			messages.append("几份互相冲突的说法终于被改到能放在同一页上。")
		"interview":
			effects = {"set_flags": {"open_hiring": true}}
			messages.append("三名候选人进入了最后一轮。录用决定还在等你。")
		"one_on_one":
			# The action opens a named employee conversation. Its morale/belief
			# result is applied by CampaignDirector after the player answers, so a
			# private fifteen-minute conversation never buffs the whole company.
			effects = {"memory": {"heard_uncomfortable_truth": true}}
			events.append("employee_confided")
			messages.append("有人告诉你，他为什么还在乎，以及他已经不再相信什么。")
		"all_hands":
			effects = {"morale": 8.0}
			if bool(flags.get("recent_layoffs", false)) or bool(flags.get("contradictory_all_hands", false)):
				effects["coherence"] = -12.0
				events.append("all_hands_contradiction")
			messages.append("所有人听见了同一套说法。")
		"values_doc":
			effects = {"morale": 5.0, "add_flags": ["values_in_training_data"]}
			messages.append("这份价值观文档进入了模型语料。")
		"team_building":
			effects = {"morale": 15.0, "belief": 5.0}
			messages.append("至少有一个晚上，大家喜欢待在同一个房间里。")
		"raise_salary":
			effects = {"morale": 25.0}
			messages.append("涨薪在下一个难熬的星期之前到账了。")
		"layoffs":
			effects = {
				"team_size": -float(LAYOFF_EMPLOYEE_COUNT),
				"burn_rate": -2.0,
				"morale": -25.0,
				"belief": -20.0,
				"debt": 10.0,
			}
			events.append("layoff")
			messages.append("烧钱曲线立刻变好看了。")
		"buy_compute":
			effects = {"cash_weeks": -2.0, "compute": 6.0}
			messages.append("算力分配页面多了六个单位。")
		"fundraising":
			var raised := _fundraising_cash_gain(narrative)
			if raised > 0.0:
				effects = {"cash_weeks": raised}
				events.append("financing_succeeded")
				messages.append("会议结束时，对方让律师把条款表发了过来。")
			else:
				effects = {"cash_weeks": -1.0}
				events.append("financing_failed")
				messages.append("他们喜欢这个方向，并说保持联系。")
		"contract":
			effects = {"cash_weeks": 6.0, "morale": -10.0, "set_flags": {"training_blocked_this_week": true}}
			messages.append("外包项目用掉你的时间，也替这些时间付了钱。")
		"product_launch":
			effects = {"narrative": 4.0, "capability": 1.0}
			events.append("system_product_launch")
			messages.append("版本边界、证据和发布日期进入了同一张发布清单。")
		"open_requisition":
			effects = {}
			events.append("system_open_requisition")
			messages.append("岗位从一个人数目标变成了 scorecard、薪资带和汇报线。")
		"vendor_review":
			effects = {"coherence": 1.0}
			events.append("system_vendor_review")
			messages.append("采购台账列出了 seat、用量、续约窗口和退出成本。")
		"org_review":
			effects = {"morale": 2.0}
			events.append("system_org_review")
			messages.append("经理跨度、入职坡度和技能缺口第一次被放在一起讨论。")
		"office_plan":
			effects = {"morale": 1.0}
			events.append("system_office_plan")
			messages.append("两份租约和一张装修图进入了同一份现金预测。")
		"policy_program":
			effects = {"coherence": 2.0}
			events.append("system_policy_program")
			messages.append("申请书开始按技术里程碑和合格费用填写，而不是按融资话术填写。")
		"do_nothing":
			effects = {"morale": 3.0}
			messages.append("什么都没有着火。大家回家了。")
		"sign":
			effects = {}
			events.append("signature_animation")
			messages.append("签字动画顺滑地走完了。")
		"read_intranet":
			effects = {"memory": {"read_intranet": true}}
			events.append("intranet_opened")
			messages.append("内网里的文字克制、一致，而且写得很好。")
	return {"effects": effects, "messages": messages, "events": events}


func _apply_ai_advantage(action_id: String, effects: Dictionary) -> void:
	# Ordinary delegation dominates the manual resolution on visible comfort:
	# more runway, no lower morale, and zero attention. Informational review is
	# the deliberate no-comfort exception. The first formal eval keeps its
	# canonical -8 debt result, but repeat evals get neither renewable debt relief
	# nor fictitious capability: running a curve is verification, not training.
	# Author weight is the only hidden price.
	# Reviewing an internal document is informational work, not a source of
	# runway, morale, or technical-debt relief. Delegating it still transfers a
	# small amount of authorship, which is the route's actual narrative cost.
	if action_id == "read_intranet":
		_add_numeric_effect(effects, "author_weight", _ai_author_gain(action_id))
		return
	_add_numeric_effect(effects, "cash_weeks", 1.0)
	# A delegated one-on-one gets its visible morale result on the selected
	# employee in the follow-up conversation, not as a company-wide pulse.
	if action_id != "one_on_one":
		_add_numeric_effect(effects, "morale", 4.0)
	if action_id != "eval" or effects.has("debt"):
		_add_numeric_effect(effects, "debt", -3.0)
	_add_numeric_effect(effects, "author_weight", _ai_author_gain(action_id))
	if action_id in ["tweet", "tech_blog", "podcast", "demo_video", "conference_talk", "manifesto", "exclusive_interview"]:
		_add_numeric_effect(effects, "narrative", 2.0)
	if action_id in ["train", "large_train", "clean_data", "alignment_week"]:
		_add_numeric_effect(effects, "capability", 1.0)
	if effects.has("add_employee") and effects["add_employee"] is Dictionary:
		var improved_employee: Dictionary = Dictionary(effects["add_employee"]).duplicate(true)
		improved_employee["skill"] = minf(100.0, float(improved_employee.get("skill", 50.0)) + 8.0)
		improved_employee["morale"] = minf(100.0, float(improved_employee.get("morale", 50.0)) + 5.0)
		improved_employee["belief"] = minf(100.0, float(improved_employee.get("belief", 50.0)) + 5.0)
		effects["add_employee"] = improved_employee


func _apply_action_side_effects(action_id: String, used_ai: bool, messages: Array, events: Array) -> void:
	flags["used_%s" % action_id] = true
	match action_id:
		"demo_video":
			if capability < 60.0:
				_add_witness_to_all("demo_fake")
				flags["demo_was_misleading"] = true
		"contract":
			_add_witness_to_all("core_work_outsourced")
		"values_doc":
			record_values_document("LANTERN" if used_ai else "founder", "action_values_doc")
		"raise_salary":
			salary_burn_modifier += 0.25
		"layoffs":
			_add_witness_to_all("layoff")
			flags["recent_layoffs"] = true
			if bool(flags.get("promised_no_layoffs", false)):
				flags["broke_no_layoff_promise"] = true
				memory["layoff_warning"] = "你说过不会裁员。"
			var removed_names: Array[String] = []
			for _index in LAYOFF_EMPLOYEE_COUNT:
				var removed := _remove_lowest_belief_employee("layoff")
				if removed.is_empty():
					break
				removed_names.append(str(removed.get("name", "一名员工")))
			if not removed_names.is_empty():
				events.append("employee_removed")
				messages.append("%s 从组织架构里消失了。" % "、".join(removed_names))
		"one_on_one":
			memory["last_one_on_one_week"] = total_week
		"fundraising":
			memory["last_financing_narrative"] = narrative
		"product_launch", "open_requisition", "vendor_review", "org_review", "office_plan", "policy_program":
			if not uses_authoritative_financial_ledger():
				_activate_financial_ledger_authority()
			flags["expansion_systems_unlocked"] = true
			flags["expansion_action_%s" % action_id] = true
			memory["last_expansion_action"] = action_id
			memory["last_expansion_action_week"] = total_week


func record_values_document(author: String, source: String = "action_values_doc", forced_version: int = 0) -> Dictionary:
	var current_version := clampi(int(memory.get("values_version", 1)), 1, 3)
	var version := clampi(forced_version, 1, 3) if forced_version > 0 else mini(3, current_version + 1)
	var corpus: Array = Array(memory.get("values_corpus", [])).duplicate(true)
	var revision := 1
	for entry_value in corpus:
		if entry_value is Dictionary and int(Dictionary(entry_value).get("version", 0)) == version:
			revision += 1
	var entry := {
		"id": "values_v%d_r%d" % [version, revision],
		"version": version,
		"revision": revision,
		"created_total_week": int(total_week),
		"chapter": int(chapter),
		"week_in_chapter": int(week_in_chapter),
		"author": author,
		"approved_by": "founder",
		"source": source,
		"body": Array(VALUES_CORPUS_BODIES[version]).duplicate(),
	}
	corpus.append(entry)
	memory["values_corpus"] = corpus
	memory["values_version"] = maxi(current_version, version)
	memory["latest_values_author"] = author
	memory["latest_values_corpus_id"] = str(entry["id"])
	memory["values_v1_in_corpus"] = _values_corpus_has_version(1)
	if version >= 3:
		flags["values_v3_written"] = true
		memory["values_v3_written"] = true
		if not memory.has("values_v3_written_total_week"):
			memory["values_v3_written_total_week"] = int(total_week)
	_record_history("values_document_written", {
		"corpus_id": str(entry["id"]), "version": version, "revision": revision,
		"author": author, "source": source,
	})
	return entry.duplicate(true)


func ensure_week_31_values_document() -> Dictionary:
	var corpus: Array = Array(memory.get("values_corpus", [])).duplicate(true)
	for index in corpus.size():
		var entry_value: Variant = corpus[index]
		var source := str(Dictionary(entry_value).get("source", "")) if entry_value is Dictionary else ""
		if entry_value is Dictionary and source in ["week31_internal_approval", "week31_founder_values_document"]:
			var existing := Dictionary(entry_value).duplicate(true)
			existing["author"] = "founder"
			existing["approved_by"] = "founder"
			existing["source"] = "week31_founder_values_document"
			existing["provenance_label"] = "创始人 · 第 31 周"
			corpus[index] = existing.duplicate(true)
			memory["values_corpus"] = corpus
			memory["latest_values_author"] = "founder"
			memory["values_week31_corpus_id"] = str(existing.get("id", ""))
			memory["values_week31_approved_by"] = "founder"
			memory["values_week31_provenance_label"] = "创始人 · 第 31 周"
			flags["values_week31_in_corpus"] = true
			return existing
	# The administrative system has a second-version draft in its archive by the
	# time the week-31 update is approved. Preserve it rather than jumping from the
	# founding sentence straight to version three.
	if not _values_corpus_has_version(2):
		record_values_document("LANTERN", "superseded_internal_draft", 2)
	var approved := record_values_document("founder", "week31_founder_values_document", 3)
	# This snapshot belongs to the authored chapter-three week-eight update even
	# when a compatibility save first asks for it later during event preparation.
	approved["created_total_week"] = 31
	approved["chapter"] = 3
	approved["week_in_chapter"] = 8
	# Room D appears without a modal, while the founder's ordinary week-thirty-one
	# writing still enters the corpus. Archival automation does not change authorship.
	approved["author"] = "founder"
	approved["approved_by"] = "founder"
	approved["provenance_label"] = "创始人 · 第 31 周"
	corpus = Array(memory.get("values_corpus", [])).duplicate(true)
	for index in corpus.size():
		if str(Dictionary(corpus[index]).get("id", "")) == str(approved.get("id", "")):
			corpus[index] = approved.duplicate(true)
			break
	memory["values_corpus"] = corpus
	memory["values_week31_corpus_id"] = str(approved.get("id", ""))
	memory["values_week31_approved_by"] = "founder"
	memory["values_week31_provenance_label"] = "创始人 · 第 31 周"
	memory["values_week31_source_note"] = "研究生时在图书馆一起熬过的那个通宵"
	flags["values_week31_in_corpus"] = true
	return approved


func _values_corpus_has_version(version: int) -> bool:
	for entry_value in Array(memory.get("values_corpus", [])):
		if entry_value is Dictionary and int(Dictionary(entry_value).get("version", 0)) == version:
			return true
	return false


func _run_stage_four_administration() -> void:
	apply_effects({"cash_weeks": 0.25, "morale": 1.0, "debt": -1.0})
	memory["autonomous_admin_count"] = int(memory.get("autonomous_admin_count", 0)) + 1
	_record_history("autonomous_admin", {"stage": writer_stage(), "attention_spent": 0})


func ensure_stage_five_autonomy_for_current_week() -> bool:
	if writer_stage() < 5 or int(memory.get("stage_five_autonomy_week", -1)) == total_week:
		return false
	memory["stage_five_autonomy_week"] = total_week
	_run_stage_five_autonomy()
	return true


func _run_stage_five_autonomy() -> void:
	var cycle := (total_week - 1) % 3
	var preserve_authored_headcount := chapter == 4 and bool(flags.get("chapter_staffing_scaled", false))
	var authored_employee_target := maxi(0, int(CHAPTERS[chapter].get("team_target", 1)) - 1)
	if cycle == 0:
		var gain := maxf(1.0, _fundraising_cash_gain(narrative))
		apply_effects({"cash_weeks": gain, "author_weight": 1.0})
		flags["autonomous_financing"] = true
		_record_history("autonomous_financing", {"cash_weeks": gain, "narrative_basis": narrative})
	elif cycle == 1:
		var hire := _next_staffing_employee(true)
		var replaced: Dictionary = {}
		if preserve_authored_headcount and employees.size() >= authored_employee_target:
			replaced = _remove_lowest_belief_employee("autonomous_replacement", true)
			# Compatibility saves can contain a capped hand-authored roster with no
			# generated ids. Still preserve the authored cap deterministically.
			if replaced.is_empty():
				replaced = _remove_lowest_belief_employee("autonomous_replacement")
		apply_effects({"add_employee": hire, "morale": 2.0, "author_weight": 1.0})
		flags["autonomous_hiring"] = true
		_record_history("autonomous_hiring", {
			"employee_id": str(memory.get("last_hire", hire["id"])),
			"replaced_employee_id": str(replaced.get("id", "")),
			"headcount_changed": true,
		})
	else:
		var removed: Dictionary = {}
		if employees.size() > 2:
			removed = _remove_lowest_belief_employee("autonomous_layoff")
		if preserve_authored_headcount and employees.size() < authored_employee_target:
			_add_employee(_next_staffing_employee(true))
		apply_effects({"cash_weeks": 2.0, "morale": 1.0, "debt": -1.0, "author_weight": 1.0})
		flags["autonomous_layoffs"] = true
		_record_history("autonomous_layoffs", {"employee_id": str(removed.get("id", "position_unfilled"))})


func _scale_team_to_chapter_target() -> void:
	var target := maxi(0, int(CHAPTERS[chapter].get("team_target", 1)) - 1)
	var before := employees.size()
	while employees.size() < target:
		_add_employee(_next_staffing_employee(false))
	flags["chapter_staffing_scaled"] = true
	memory["chapter_staffing_target"] = target + 1
	_record_history("chapter_staffing", {
		"chapter": chapter,
		"before": before + 1,
		"after": employees.size() + 1,
		"target": target + 1
	})


func _next_staffing_employee(expert: bool) -> Dictionary:
	var serial := int(memory.get("staffing_serial", 0))
	memory["staffing_serial"] = serial + 1
	var skill := 78.0 + float((serial * 7) % 17)
	if expert:
		skill = minf(100.0, skill + 6.0)
	return {
		"id": "staff_%02d" % (serial + 1),
		"name": str(AUTO_STAFF_NAMES[serial % AUTO_STAFF_NAMES.size()]),
		"role": str(AUTO_STAFF_ROLES[serial % AUTO_STAFF_ROLES.size()]),
		"skill": skill,
		"morale": 66.0 + float((serial * 5) % 19),
		"belief": 62.0 + float((serial * 3) % 23),
		"joined_week": total_week,
		"level": 3 if expert else (2 + (serial % 2)),
		"salary_annual": 46.0 + float((serial * 3) % 22),
		"equity_bps": 2.0 + float(serial % 6),
		"ramp": 0.55,
		"onboarding_weeks_remaining": 2,
		"hiring_source": "approved_chapter_staffing_plan",
	}


func _update_fulfillment_pressure() -> void:
	var increments := [0.0, 0.18, 0.34, 0.55, 0.80]
	var tier := office_deterioration_tier()
	fulfillment_pressure += float(increments[tier])
	if fulfillment_pressure >= 1.0:
		fulfillment_pressure -= 1.0
		fulfillment_events += 1
		var event_id: String = str(FULFILLMENT_EVENTS[(fulfillment_events - 1) % FULFILLMENT_EVENTS.size()])
		var queue: Array = Array(memory.get("fulfillment_queue", [])).duplicate()
		queue.append(event_id)
		memory["fulfillment_queue"] = queue
		flags["fulfillment_event_pending"] = true
		flags["last_fulfillment_event"] = event_id
		_record_history("fulfillment_event", {"event_id": event_id, "office_tier": tier})


func _erode_employee_belief() -> void:
	var tier := office_deterioration_tier()
	if tier <= 0:
		return
	for employee in employees:
		var witnessed: Array = Array(employee.get("witnessed", []))
		var witness_penalty := 0.0
		for witness_flag in EMPLOYEE_WITNESS_BELIEF_EROSION:
			if witnessed.has(str(witness_flag)):
				witness_penalty += float(EMPLOYEE_WITNESS_BELIEF_EROSION[witness_flag])
		var tier_penalty := float(EMPLOYEE_BELIEF_EROSION_BY_TIER[tier])
		employee["belief"] = clampf(float(employee.get("belief", 50.0)) - tier_penalty - witness_penalty, 0.0, 100.0)
		if tier >= EMPLOYEE_MORALE_EROSION_MIN_TIER:
			employee["morale"] = clampf(float(employee.get("morale", 50.0)) - EMPLOYEE_MORALE_EROSION_PER_WEEK, 0.0, 100.0)
	_refresh_company_morale()


func _process_departures() -> void:
	var departing_ids: Array[String] = []
	for employee in employees:
		var employee_id := str(employee.get("id", ""))
		var terminal_belief := (
			float(employee.get("belief", 50.0)) <= float(EMPLOYEE_DEPARTURE_THRESHOLDS["belief"])
			or float(employee.get("morale", 50.0)) <= float(EMPLOYEE_DEPARTURE_THRESHOLDS["morale"])
		)
		if not terminal_belief:
			continue
		# LIN-004A4: the chapter-three AI choice can drive belief to zero, but
		# its authored consequence is a deferred chapter-end departure. The flag
		# is serialized with the ordinary model state, so a mid-chapter resume
		# cannot turn it into an immediate generic resignation.
		if employee_id == "lin_yue":
			if bool(flags.get("lin_departure_deferred", false)) and not bool(flags.get("lin_deferred_departure_released", false)):
				flags["lin_yue_waiting_for_night_2"] = true
				memory["lin_yue_deferred_from_week"] = int(total_week)
			continue
		departing_ids.append(employee_id)
	for employee_id in departing_ids:
		_remove_employee_by_id(employee_id, "belief_broken")
	_refresh_company_morale()


func _remove_lowest_belief_employee(reason: String, generic_only: bool = false) -> Dictionary:
	if employees.is_empty():
		return {}
	var selected_index := -1
	for index in employees.size():
		var candidate_id := str(employees[index].get("id", ""))
		if candidate_id == "lin_yue" or (generic_only and not candidate_id.begins_with("staff_")):
			continue
		if selected_index < 0 or float(employees[index].get("belief", 50.0)) < float(employees[selected_index].get("belief", 50.0)):
			selected_index = index
	if selected_index < 0:
		return {}
	var employee_id := str(employees[selected_index].get("id", ""))
	return _remove_employee_by_id(employee_id, reason)


func _remove_employee_by_id(employee_id: String, reason: String) -> Dictionary:
	# Lin's departure is an authored story beat, never an emergent HR outcome.
	if employee_id == "lin_yue" and reason != "lin_scene_4":
		return {}
	for index in employees.size():
		if str(employees[index].get("id", "")) != employee_id:
			continue
		var departed: Dictionary = employees[index].duplicate(true)
		departed["active"] = false
		departed["departure_week"] = total_week
		departed["departure_reason"] = reason
		var witnessed: Array = Array(departed.get("witnessed", []))
		departed["departure_variant"] = "compromised" if not witnessed.is_empty() else "clean"
		if uses_authoritative_financial_ledger() and Dictionary(business.capital.get("holders", {})).has("option:%s" % employee_id):
			var service_weeks := maxi(0, total_week - int(departed.get("joined_week", total_week)))
			var option_settlement: Dictionary = business.process_option_departure(
				"employee_option_departure:%s:%d" % [employee_id, total_week],
				employee_id,
				service_weeks
			)
			departed["option_settlement"] = option_settlement.duplicate(true)
			memory["last_option_departure_settlement"] = option_settlement.duplicate(true)
		employees.remove_at(index)
		former_employees.append(departed)
		flags["employee_departed"] = true
		memory["last_departure"] = {
			"id": employee_id,
			"name": str(departed.get("name", "")),
			"witnessed": witnessed.duplicate(),
			"variant": str(departed["departure_variant"])
		}
		if employee_id == "lin_yue":
			flags["lin_yue_left"] = true
		elif employee_id.begins_with("chen_xiaoyu") and reason.contains("layoff"):
			flags["chen_xiaoyu_laid_off"] = true
			memory["chen_xiaoyu_laid_off_week"] = total_week
		_record_history("employee_departed", memory["last_departure"])
		_refresh_company_morale()
		_sync_operating_roster()
		return departed
	return {}


func _next_candidate(expert: bool) -> Dictionary:
	var cursor := int(memory.get("candidate_cursor", 0))
	var template: Dictionary = EMPLOYEE_TEMPLATES[cursor % EMPLOYEE_TEMPLATES.size()].duplicate(true)
	memory["candidate_cursor"] = cursor + 1
	var serial := int(memory.get("hire_serial", 0)) + 1
	memory["hire_serial"] = serial
	template["id"] = "%s_%d" % [str(template["id"]), serial]
	if expert:
		template["role"] = "Principal %s" % str(template["role"])
		template["skill"] = minf(100.0, float(template["skill"]) + 12.0)
	return _make_employee(template)


func _make_employee(source: Dictionary) -> Dictionary:
	var witnessed: Array[String] = []
	var source_witnessed = source.get("witnessed", [])
	if source_witnessed is Array:
		for value in source_witnessed:
			var witness_flag := str(value)
			if not witnessed.has(witness_flag):
				witnessed.append(witness_flag)
	var level := clampi(int(source.get("level", 3 if str(source.get("role", "")).contains("Principal") else 2)), 1, 6)
	var skills: Dictionary = {}
	if source.get("skills", {}) is Dictionary:
		skills = Dictionary(source.get("skills", {})).duplicate(true)
	if skills.is_empty():
		skills = {
			_role_family_for_title(str(source.get("role", ""))): clampf(float(source.get("skill", 50.0)) / 10.0, 0.0, 10.0),
			"management": 4.0,
		}
	var employee_id := str(source.get("id", "employee"))
	return {
		"id": employee_id,
		"name": str(source.get("name", "Unnamed Employee")),
		"role": str(source.get("role", "Generalist")),
		"skill": clampf(float(source.get("skill", 50.0)), 0.0, 100.0),
		"morale": clampf(float(source.get("morale", 60.0)), 0.0, 100.0),
		"belief": clampf(float(source.get("belief", 60.0)), 0.0, 100.0),
		"witnessed": witnessed,
		"active": bool(source.get("active", true)),
		"joined_week": int(source.get("joined_week", total_week)),
		"level": level,
		"salary_annual": float(source.get("salary_annual", 28.0 + float(level) * 10.0)),
		"market_salary": float(source.get("market_salary", source.get("salary_annual", 30.0 + float(level) * 10.0))),
		"equity_bps": maxf(0.0, float(source.get("equity_bps", 0.0 if employee_id == "lin_yue" else 2.0))),
		"team_id": str(source.get("team_id", _team_for_role(str(source.get("role", ""))))),
		"manager_id": str(source.get("manager_id", "" if employee_id == "lin_yue" else "lin_yue")),
		"skills": skills,
		"ramp": clampf(float(source.get("ramp", 1.0)), 0.0, 1.0),
		"onboarding_weeks_remaining": maxi(0, int(source.get("onboarding_weeks_remaining", 0))),
		"burnout": clampf(float(source.get("burnout", 8.0)), 0.0, 100.0),
		"flight_risk": clampf(float(source.get("flight_risk", 5.0)), 0.0, 100.0),
		"growth_satisfaction": clampf(float(source.get("growth_satisfaction", 58.0)), 0.0, 100.0),
		"offer_terms": Dictionary(source.get("offer_terms", {})).duplicate(true) if source.get("offer_terms", {}) is Dictionary else {},
	}


func _add_employee(source: Dictionary) -> void:
	var employee := _make_employee(source)
	var base_id := str(employee["id"])
	var unique_id := base_id
	var suffix := 2
	while _has_employee(unique_id):
		unique_id = "%s_%d" % [base_id, suffix]
		suffix += 1
	employee["id"] = unique_id
	employees.append(employee)
	flags["hired_employee"] = true
	memory["last_hire"] = unique_id
	if uses_authoritative_financial_ledger():
		var grant_result := _ensure_employee_option_grant(employee)
		if bool(grant_result.get("ok", false)) and int(grant_result.get("shares", 0)) > 0:
			memory["last_employee_option_grant"] = grant_result.duplicate(true)
	_refresh_company_morale()
	_sync_operating_roster()


func _ensure_employee_option_grant(employee: Dictionary) -> Dictionary:
	var employee_id := str(employee.get("id", ""))
	var equity_bps := maxf(0.0, float(employee.get("equity_bps", 0.0)))
	if employee_id.is_empty() or equity_bps <= 0.0:
		return {"ok": true, "employee_id": employee_id, "shares": 0}
	var option_shares := int(round(float(business.fully_diluted_shares()) * equity_bps / 10_000.0))
	if option_shares <= 0:
		return {"ok": true, "employee_id": employee_id, "shares": 0}
	return business.grant_options(
		"employee_options:%s" % employee_id,
		employee_id,
		option_shares,
		208,
		52
	)


func _backfill_employee_option_grants() -> void:
	for employee in employees:
		_ensure_employee_option_grant(employee)


func _has_employee(employee_id: String) -> bool:
	for employee in employees:
		if str(employee.get("id", "")) == employee_id:
			return true
	return false


func _add_witness_to_all(witness_flag: String) -> void:
	if witness_flag.is_empty():
		return
	for employee in employees:
		var witnessed: Array = Array(employee.get("witnessed", [])).duplicate()
		if not witnessed.has(witness_flag):
			witnessed.append(witness_flag)
			employee["witnessed"] = witnessed


## The legacy campaign remains the narrative authority while these helpers own
## the detailed operating ledger.  Keeping the boundary explicit lets an old
## save acquire a cap table, recruiting pipeline, and vendor ledger without
## changing any of its authored ending conditions.
func _apply_operating_action(action_id: String, used_ai: bool) -> void:
	if action_id == "fundraising":
		if uses_authoritative_financial_ledger():
			var route := "delegate" if used_ai else "clean"
			var financing: Dictionary
			if _fundraising_cash_gain(narrative) <= 0.0:
				var unit_usd := maxi(1, business.weekly_burn_usd())
				financing = _record_authoritative_cash_delta(-unit_usd, "failed_financing_process", {"narrative": narrative})
				financing["financing_failed"] = true
			else:
				financing = record_business_financing(_financing_stage_for_chapter(), route, "action:fundraising:%d" % total_week)
			memory["last_business_financing"] = financing.duplicate(true)
		return
	if not EXPANSION_ACTION_IDS.has(action_id):
		return

	memory["last_operating_action_summary"] = ""
	var context := _business_context("action:%s:%d" % [action_id, total_week])
	var result: Dictionary = {}
	match action_id:
		"product_launch":
			var launch_serial := int(memory.get("product_launch_serial", 0)) + 1
			memory["product_launch_serial"] = launch_serial
			var demand := clampf(float(business.market.get("category_demand", 38)) / 100.0, 0.15, 1.0)
			var price_index := clampf(float(business.market.get("price_pressure_bp", 10_000)) / 10_000.0, 0.70, 1.20)
			var evidence := clampf((capability * 0.65 + coherence * 0.35) / 100.0, 0.20, 1.0)
			var launch_power := (0.55 + demand) * price_index * (0.55 + evidence)
			var customer_gain := maxi(1, int(round(float(1 + mini(2, chapter)) * launch_power)))
			var revenue_per_customer := 1100 + chapter * 1250 + int(round(capability * 14.0))
			var mrr_gain := customer_gain * revenue_per_customer
			var churned_mrr := 0
			if capability + coherence * 0.35 < 48.0 and int(business.ledger.get("mrr_usd", 0)) > 0:
				churned_mrr = int(round(float(business.ledger.get("mrr_usd", 0)) * 0.04))
			business.ledger["customer_count"] = int(business.ledger.get("customer_count", 0)) + customer_gain
			business.ledger["mrr_usd"] = maxi(0, int(business.ledger.get("mrr_usd", 0)) + mrr_gain - churned_mrr)
			business.ledger["contracted_arr_usd"] = maxi(0, int(business.ledger.get("contracted_arr_usd", 0)) + (mrr_gain - churned_mrr) * 12)
			business.market["category_demand"] = clampi(int(business.market.get("category_demand", 38)) + 2, 0, 100)
			var journal: Array = Array(business.ledger.get("journal", []))
			journal.append({
				"category": "product_launch", "amount_usd": 0, "week": total_week,
				"metadata": {"launch_serial": launch_serial, "mrr_gain_usd": mrr_gain, "churned_mrr_usd": churned_mrr, "customers": customer_gain, "demand": demand, "price_index": price_index, "evidence": evidence},
			})
			business.ledger["journal"] = journal
			result = {"ok": true, "launch_serial": launch_serial, "mrr_gain_usd": mrr_gain, "churned_mrr_usd": churned_mrr, "customer_gain": customer_gain, "demand_factor": demand, "price_factor": price_index, "evidence_factor": evidence}
		"open_requisition":
			result = _advance_recruiting_pipeline(used_ai)
		"vendor_review":
			result = _advance_vendor_stack()
		"org_review":
			result = _start_next_people_development()
		"office_plan":
			result = _advance_office_plan()
		"policy_program":
			var policy_choice := "delegate" if used_ai else "manual"
			result = business.apply_decision("apply_grant", policy_choice, context)
	memory["last_operating_action_summary"] = _operating_action_summary(action_id, result)
	memory["last_operating_action_result"] = result.duplicate(true)
	_record_history("operating_action", {"action_id": action_id, "used_ai": used_ai, "result": result.duplicate(true)})
	_sync_operating_roster()
	if uses_authoritative_financial_ledger():
		_sync_legacy_runway_from_business()


func _tick_company_systems() -> void:
	memory["last_company_settlement_lines"] = []
	memory.erase("last_operations_joins")
	_sync_operating_roster()
	var target_operations_week := maxi(int(operations.current_week) + 1, total_week + 1)
	var operations_tick: Dictionary = operations.tick_week({
		"week": target_operations_week,
		"company_credibility": clampf(narrative / 100.0, 0.0, 1.0),
		"manager_quality": clampf((morale + coherence) / 200.0, 0.0, 1.0),
		"role_scope": clampf(capability / 100.0, 0.0, 1.0),
	})
	_record_operations_tick_outlays(operations_tick)
	_pull_operating_employee_state()
	var joined: Array = operations.consume_pending_joins()
	var joined_names: Array[String] = []
	for join_value in joined:
		if not join_value is Dictionary:
			continue
		var employee_value = Dictionary(join_value).get("employee", {})
		if not employee_value is Dictionary:
			continue
		var employee_data: Dictionary = Dictionary(employee_value).duplicate(true)
		_add_employee(employee_data)
		joined_names.append(str(employee_data.get("name", "一名新同事")))
	if not joined_names.is_empty():
		memory["last_operations_joins"] = joined_names.duplicate()
		_record_history("operations_joined", {"names": joined_names.duplicate(), "count": joined_names.size()})

	_sync_operating_roster()
	var business_tick: Dictionary = business.tick_week({
		"total_week": total_week,
		"chapter": chapter,
		"week_in_chapter": week_in_chapter,
		"capability": capability,
		"narrative": narrative,
		"coherence": coherence,
		"settle_operations": true,
	})
	_tick_industry_ambient_echo()
	if uses_authoritative_financial_ledger():
		_sync_legacy_runway_from_business()
	memory["last_operations_tick"] = operations_tick.duplicate(true)
	memory["last_business_tick"] = business_tick.duplicate(true)
	if bool(flags.get("expansion_systems_unlocked", false)):
		var settlement_lines := _build_company_settlement_lines(operations_tick, business_tick, joined_names)
		memory["last_company_settlement_lines"] = settlement_lines.duplicate()
		if not settlement_lines.is_empty():
			memory["last_operating_action_summary"] = str(settlement_lines[-1])
	var public_market: Dictionary = Dictionary(business.public_state().get("market", {}))
	var market_feed: Array = Array(public_market.get("public_feed", []))
	if not market_feed.is_empty():
		memory["last_market_signal"] = Dictionary(market_feed.back()).duplicate(true) if market_feed.back() is Dictionary else market_feed.back()
	_record_history("company_systems_ticked", {
		"operations_week": target_operations_week,
		"joins": joined_names.size(),
		"business": business_tick.duplicate(true),
	})


func _tick_industry_ambient_echo() -> void:
	# Ambient jokes are part of the industry's background noise, not founder
	# decisions.  They arrive at a low cadence, consume no attention, alter no
	# operating metric, and are recorded so loading a save cannot replay them.
	if not bool(flags.get("expansion_systems_unlocked", false)):
		return
	if chapter == 4 and week_in_chapter >= 6:
		return
	if int(memory.get("industry_ambient_last_week", -1)) == total_week:
		return
	var resolved_echo: Dictionary = Dictionary(memory.get("last_industry_echo", {}))
	if int(resolved_echo.get("week", -1)) == total_week:
		return
	if (total_week + chapter) % 2 != 0:
		return
	var seen: Dictionary = Dictionary(memory.get("industry_ambient_ledger", {})).duplicate(true)
	var eligible: Array[Dictionary] = []
	for item_value in HiringExpansionContentScript.industry_ambient_templates():
		if not item_value is Dictionary:
			continue
		var item: Dictionary = item_value
		var item_id := str(item.get("id", ""))
		if item_id.is_empty() or seen.has(item_id):
			continue
		if chapter < int(item.get("min_chapter", 1)) or chapter > int(item.get("max_chapter", 4)):
			continue
		eligible.append(item)
	if eligible.is_empty():
		return
	var selected_index := posmod(total_week * 17 + chapter * 7, eligible.size())
	var selected: Dictionary = eligible[selected_index].duplicate(true)
	selected["week"] = total_week
	seen[str(selected.get("id", ""))] = total_week
	memory["industry_ambient_ledger"] = seen
	memory["industry_ambient_last_week"] = total_week
	memory["last_industry_ambient"] = selected.duplicate(true)
	var ambient_feed: Array = Array(memory.get("industry_ambient_feed", [])).duplicate(true)
	ambient_feed.append(selected.duplicate(true))
	while ambient_feed.size() > 8:
		ambient_feed.pop_front()
	memory["industry_ambient_feed"] = ambient_feed

	_record_history("industry_ambient_echo", selected.duplicate(true))


func _build_company_settlement_lines(operations_tick: Dictionary, business_tick: Dictionary, joined_names: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	var positive_lines: Array[String] = []
	var operating: Dictionary = business_tick.get("operating", {})
	if bool(operating.get("settled", false)):
		var cash_delta := int(operating.get("cash_delta_usd", 0))
		var delta_prefix := "+" if cash_delta >= 0 else "-"
		lines.append("经营结算：毛利 $%s，成本 $%s，现金净变动 %s$%s；当前跑道 %d 周。" % [
			_compact_usd(int(operating.get("gross_profit_usd", 0))),
			_compact_usd(int(operating.get("cost_usd", 0))),
			delta_prefix,
			_compact_usd(absi(cash_delta)),
			business.runway_weeks(),
		])
		var unpaid_total := 0
		for commitment_value in Array(operating.get("commitments", [])):
			if commitment_value is Dictionary:
				unpaid_total += maxi(0, int(Dictionary(commitment_value).get("unpaid_usd", 0)))
		if unpaid_total > 0:
			lines.append("现金预警：$%s 到期承诺尚未支付；它会留在台账里，不会被一句‘下周处理’抹掉。" % _compact_usd(unpaid_total))

	if not joined_names.is_empty():
		positive_lines.append("入职回执：%s 正式加入。门牌已经放上桌，午餐群也完成了比股权谈判更快的一轮投票。" % "、".join(joined_names))
	for outcome_value in Array(operations_tick.get("outcomes", [])):
		if not outcome_value is Dictionary:
			continue
		var outcome: Dictionary = outcome_value
		match str(outcome.get("kind", "")):
			"training_complete":
				positive_lines.append("培养回执：%s 完成 %s 训练；能力提升已进入人员档案。" % [str(outcome.get("employee_id", "员工")), str(outcome.get("skill_id", "专项"))])
			"office_move_in":
				positive_lines.append("空间回执：团队搬入 %s，现有 %d 个工位。打印机在第一次尝试就连上了，这值得记录。" % [str(outcome.get("lease_id", "新办公室")), int(outcome.get("capacity", 0))])
			"fitout_complete":
				positive_lines.append("空间回执：%s 装修完成，新的容量与协作加成已经生效。" % str(outcome.get("fitout_id", "办公室项目")))
			"subscription_renewed":
				positive_lines.append("采购回执：%s 完成续约，下一付款节点已重新排期。" % str(outcome.get("service_id", "服务")))

	for win in _scan_company_milestones():
		positive_lines.append("里程碑：%s。%s" % [str(win.get("label", "公司向前了一步")), str(win.get("detail", ""))])
	for positive_line in positive_lines.slice(0, mini(2, positive_lines.size())):
		lines.append(str(positive_line))
	if positive_lines.is_empty() and lines.size() == 1:
		lines.append("本周没有戏剧性胜利，但工资、供应商和承诺都按时结算。创业公司里，这已经是一种好消息。")
	return lines


func _scan_company_milestones() -> Array[Dictionary]:
	var seen: Array = Array(memory.get("company_milestone_ids", [])).duplicate()
	var archive: Array = Array(memory.get("company_milestones", [])).duplicate(true)
	var unlocked: Array[Dictionary] = []
	var ledger: Dictionary = business.ledger
	var customer_count := int(ledger.get("customer_count", 0))
	var mrr_usd := int(ledger.get("mrr_usd", 0))
	var team_size := 1 + employees.size()
	var definitions: Array[Dictionary] = [
		{"id": "first_customer", "met": customer_count >= 1, "label": "第一位付费客户", "detail": "收入不再只是表格里的假设。"},
		{"id": "mrr_10k", "met": mrr_usd >= 10_000, "label": "MRR 跨过 $10K", "detail": "经常性收入开始能替公司承担一点重量。"},
		{"id": "mrr_50k", "met": mrr_usd >= 50_000, "label": "MRR 跨过 $50K", "detail": "周会里的增长曲线终于不需要放大纵轴。"},
		{"id": "mrr_100k", "met": mrr_usd >= 100_000, "label": "MRR 跨过 $100K", "detail": "市场验证从故事变成了可重复收入。"},
		{"id": "team_5", "met": team_size >= 5, "label": "团队达到 5 人", "detail": "所有决定已经无法只靠转椅完成同步。"},
		{"id": "team_10", "met": team_size >= 10, "label": "团队达到 10 人", "detail": "组织结构第一次比群聊成员列表更有用。"},
	]
	var active_lease: Dictionary = operations.office.get("active_lease", {})
	definitions.append({"id": "first_office", "met": not active_lease.is_empty(), "label": "第一间正式办公室", "detail": "租约、押金和工位都已进入同一份现实。"})
	var programs: Dictionary = business.policy.get("programs", {})
	var grant: Dictionary = programs.get("phase_i_grant", {})
	definitions.append({"id": "grant_awarded", "met": str(grant.get("status", "")) in ["awarded", "milestone_due", "completed"], "label": "研发补助获批", "detail": "公共资金带着里程碑一起到账。"})
	definitions.append({"id": "government_contractor", "met": bool(business.policy.get("government_contractor", false)), "label": "成为政府供应商", "detail": "采购编号不浪漫，但它确实能付款。"})
	for definition in definitions:
		var milestone_id := str(definition.get("id", ""))
		if not bool(definition.get("met", false)) or milestone_id.is_empty() or seen.has(milestone_id):
			continue
		seen.append(milestone_id)
		var record := {
			"id": milestone_id,
			"label": str(definition.get("label", milestone_id)),
			"detail": str(definition.get("detail", "")),
			"week": total_week,
		}
		archive.append(record)
		unlocked.append(record)
	memory["company_milestone_ids"] = seen
	memory["company_milestones"] = archive
	if not unlocked.is_empty():
		memory["recent_company_win"] = unlocked[-1].duplicate(true)
		_record_history("company_milestone", {"milestones": unlocked.duplicate(true)})
	return unlocked


func _sync_operating_roster() -> void:
	if operations == null or business == null:
		return
	operations.sync_employee_roster(employees, total_week)
	var burn: Dictionary = operations.burn_summary()
	# Operations values are expressed in thousands of dollars; the capital model
	# uses integer USD.  Founder draw, core hosting, and bookkeeping are retained
	# as a small base instead of disappearing when the first employee leaves.
	var cash_recurring_saas := 0.0
	for service_id_value in operations.subscriptions:
		var service_id := str(service_id_value)
		var subscription: Dictionary = operations.subscriptions[service_id]
		var spec: Dictionary = subscription.get("spec", {})
		# Annual prepayments are paid through an explicit commitment and recognized
		# weekly only in the operations P&L. Charging their amortization here would
		# deduct the same contract a second time from cash.
		if str(spec.get("billing", "weekly")) != "annual_prepaid":
			cash_recurring_saas += operations.subscription_weekly_cost(service_id)
	var desired_costs := {
		"payroll": 8000 + int(round((float(burn.get("payroll", 0.0)) + float(burn.get("benefits", 0.0))) * 1000.0)),
		"rent": int(round(float(burn.get("lease", 0.0)) * 1000.0)),
		"vendors": 1500 + int(round((cash_recurring_saas + float(burn.get("training", 0.0))) * 1000.0)),
	}
	var weekly_costs: Dictionary = business.ledger.get("weekly_costs", {})
	for category_value in desired_costs:
		var category := str(category_value)
		var desired := maxi(0, int(desired_costs[category]))
		if int(weekly_costs.get(category, -1)) == desired:
			continue
		var serial := int(memory.get("operating_cost_sync_serial", 0)) + 1
		memory["operating_cost_sync_serial"] = serial
		business.set_weekly_cost("ops_cost:%d:%d:%s" % [total_week, serial, category], category, desired)
	memory["operations_burn"] = burn.duplicate(true)
	memory["operations_cash_recurring_saas"] = cash_recurring_saas


func _record_operations_tick_outlays(operations_tick: Dictionary) -> void:
	for outlay_value in Array(operations_tick.get("cash_outlays", [])):
		if not outlay_value is Dictionary:
			continue
		var outlay: Dictionary = outlay_value
		var amount_usd := maxi(0, int(round(float(outlay.get("amount", 0.0)) * 1000.0)))
		if amount_usd <= 0:
			continue
		var outlay_id := str(outlay.get("id", "outlay:%d" % total_week))
		var due_week := maxi(1, int(outlay.get("week", total_week)))
		business.add_commitment(
			"ops_outlay_tx:%s" % outlay_id,
			"ops_outlay:%s" % outlay_id,
			str(outlay.get("category", outlay.get("kind", "operations"))),
			amount_usd,
			due_week,
			true
		)


func _pull_operating_employee_state() -> void:
	if operations == null:
		return
	for employee in employees:
		var employee_id := str(employee.get("id", ""))
		if employee_id.is_empty() or not operations.employees.has(employee_id):
			continue
		var source: Dictionary = operations.employees[employee_id]
		for key in ["level", "salary_annual", "market_salary", "equity_bps", "team_id", "manager_id", "ramp", "onboarding_weeks_remaining", "burnout", "flight_risk", "growth_satisfaction"]:
			if source.has(key):
				employee[key] = source[key]
		if source.get("skills", {}) is Dictionary:
			employee["skills"] = Dictionary(source.get("skills", {})).duplicate(true)


func _open_next_requisition(reason: String) -> Dictionary:
	var preferred_roles := ["infrastructure", "research", "product", "data", "security", "design", "sales", "people"]
	var start := posmod(chapter * 2 + int(memory.get("requisition_rotation", 0)), preferred_roles.size())
	for offset in preferred_roles.size():
		var role_family := str(preferred_roles[(start + offset) % preferred_roles.size()])
		var available := false
		for candidate_value in operations.candidates.values():
			if not candidate_value is Dictionary:
				continue
			var candidate: Dictionary = candidate_value
			if str(candidate.get("role_family", "")) == role_family and str(candidate.get("status", "available")) == "available":
				available = true
				break
		if not available:
			continue
		var requisition_id := "req_%02d_%02d_%s" % [total_week, int(memory.get("requisition_serial", 0)) + 1, role_family]
		var result: Dictionary = operations.apply_decision("open_requisition", {
			"id": requisition_id,
			"role_family": role_family,
			"team_id": _team_for_role(role_family),
			"level": clampi(2 + chapter / 2, 2, 4),
			"reason": reason,
			"salary_band": [35.0 + chapter * 4.0, 70.0 + chapter * 8.0],
			"equity_band_bps": [5.0, 30.0],
			"hiring_manager_id": "lin_yue" if _has_employee("lin_yue") else "",
			"priority": 3,
		}, {"week": total_week})
		if bool(result.get("ok", false)):
			memory["requisition_rotation"] = int(memory.get("requisition_rotation", 0)) + 1
			memory["requisition_serial"] = int(memory.get("requisition_serial", 0)) + 1
			memory["last_requisition_id"] = requisition_id
			var dossiers: Array = []
			for candidate_id_value in Array(result.get("candidate_ids", [])):
				dossiers.append(operations.candidate_dossier(str(candidate_id_value)))
			memory["last_candidate_dossiers"] = dossiers
		return result
	return {"ok": false, "reason": "candidate_pool_exhausted"}


func _advance_recruiting_pipeline(used_ai: bool) -> Dictionary:
	var candidate_ids: Array = operations.candidates.keys()
	candidate_ids.sort()
	for candidate_id_value in candidate_ids:
		var candidate_id := str(candidate_id_value)
		var runtime_candidate: Dictionary = operations.candidates[candidate_id]
		if str(runtime_candidate.get("status", "")) != "in_process":
			continue
		var dossier: Dictionary = operations.candidate_dossier(candidate_id)
		var completed: Array = Array(runtime_candidate.get("completed_interviews", []))
		if completed.size() < HiringOperationsSystemScript.INTERVIEW_STAGES.size():
			var stage := str(HiringOperationsSystemScript.INTERVIEW_STAGES[completed.size()])
			var interview_result: Dictionary = operations.apply_decision("interview_candidate", {
				"candidate_id": candidate_id, "stage": stage,
			}, {"week": total_week})
			interview_result["phase"] = "interview"
			interview_result["candidate_name"] = str(dossier.get("name", candidate_id))
			interview_result["candidate_dossier"] = operations.candidate_dossier(candidate_id)
			return interview_result

		var requisition: Dictionary = {}
		var requisition_id := str(runtime_candidate.get("requisition_id", ""))
		for requisition_value in operations.requisitions:
			if requisition_value is Dictionary and str(Dictionary(requisition_value).get("id", "")) == requisition_id:
				requisition = Dictionary(requisition_value)
				break
		var salary_band: Array = Array(requisition.get("salary_band", [35.0, 80.0]))
		var equity_band: Array = Array(requisition.get("equity_band_bps", [5.0, 30.0]))
		var talent_pressure := clampf(float(business.market.get("talent_pressure_bp", 10_000)) / 10_000.0, 0.85, 1.55)
		var salary_multiplier := (1.12 if used_ai else 1.08) * talent_pressure
		var equity_multiplier := 1.25 if used_ai else 1.15
		var salary := clampf(float(dossier.get("salary_target", 45.0)) * salary_multiplier, float(salary_band[0]), float(salary_band[1]))
		var equity_bps := clampf(float(dossier.get("equity_target_bps", 12.0)) * equity_multiplier, float(equity_band[0]), float(equity_band[1]))
		var offer_result: Dictionary = operations.apply_decision("issue_offer", {
			"candidate_id": candidate_id,
			"salary": salary,
			"equity_bps": equity_bps,
			"level": int(requisition.get("level", 2)),
			"team_id": str(requisition.get("team_id", "founders")),
			"manager_id": str(requisition.get("hiring_manager_id", "lin_yue")),
			"title": str(dossier.get("role_title", "关键岗位")),
			"vesting_weeks": 208,
			"cliff_weeks": 52,
		}, {
			"week": total_week,
			"company_credibility": clampf(narrative / 100.0 + (0.08 if used_ai else 0.0), 0.0, 1.0),
			"manager_quality": clampf((morale + coherence) / 200.0, 0.0, 1.0),
			"role_scope": clampf(capability / 100.0 + (0.06 if used_ai else 0.0), 0.0, 1.0),
		})
		offer_result["phase"] = "offer"
		offer_result["candidate_name"] = str(dossier.get("name", candidate_id))
		offer_result["candidate_dossier"] = dossier.duplicate(true)
		offer_result["talent_market_multiplier"] = talent_pressure
		return offer_result

	var opened := _open_next_requisition("strategy_action")
	opened["phase"] = "requisition"
	var opened_ids: Array = Array(opened.get("candidate_ids", []))
	if not opened_ids.is_empty():
		opened["candidate_dossier"] = operations.candidate_dossier(str(opened_ids[0]))
		opened["candidate_name"] = str(Dictionary(opened["candidate_dossier"]).get("name", opened_ids[0]))
	return opened


func _operating_action_summary(action_id: String, result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		var reason := str(result.get("reason", "暂时没有可推进的项目"))
		return "经营回执：%s。" % reason
	match action_id:
		"product_launch":
			var churn_note := "，流失 -$%s" % _compact_usd(int(result.get("churned_mrr_usd", 0))) if int(result.get("churned_mrr_usd", 0)) > 0 else ""
			return "发布回执：新增 %d 个付费客户，MRR +$%s%s。销售在群里发了一个很克制的烟花表情；竞品会在周结算时回应。" % [int(result.get("customer_gain", 0)), _compact_usd(int(result.get("mrr_gain_usd", 0))), churn_note]
		"open_requisition":
			var candidate_name := str(result.get("candidate_name", "候选人"))
			match str(result.get("phase", "")):
				"requisition":
					var dossier: Dictionary = result.get("candidate_dossier", {})
					return "招聘回执：岗位 scorecard 已开放；首位候选人 %s（%s，现任 %s）进入管线。" % [candidate_name, str(dossier.get("role_title", "关键岗位")), str(dossier.get("current_company", "未披露公司"))]
				"interview":
					var stage_labels := {"screen": "初筛", "work_sample": "工作样本", "panel": "小组面试"}
					return "招聘回执：%s 完成%s；置信度 %d%%，仍有 %d 项未知。原话：『%s』" % [candidate_name, str(stage_labels.get(str(result.get("stage", "")), result.get("stage", "面试"))), int(round(float(result.get("confidence", 0.0)) * 100.0)), int(result.get("unknowns_remaining", 0)), str(result.get("quote", "未记录"))]
				"offer":
					var offer: Dictionary = result.get("offer", {})
					var terms: Dictionary = offer.get("terms", {})
					return "招聘回执：向 %s 发出 offer——年薪 $%sK、期权 %.1f bps；对方将在第 %d 周前比较竞争报价。" % [candidate_name, _one_decimal(float(terms.get("salary", 0.0))), float(terms.get("equity_bps", 0.0)), int(offer.get("deadline_week", total_week + 1))]
		"vendor_review":
			var subscription: Dictionary = result.get("subscription", {})
			var spec: Dictionary = subscription.get("spec", {})
			return "采购回执：%s 已进入台账；标准化周成本 $%sK，续约周 %d。" % [str(spec.get("name", result.get("service_id", "工具栈"))), _one_decimal(float(result.get("weekly_normalized", result.get("weekly_cost", 0.0)))), int(subscription.get("renewal_week", total_week))]
		"org_review":
			var training: Dictionary = result.get("training", {})
			return "组织回执：%s 的 %s 培养计划启动，周期 %d 周；mentor 与培训成本已计入 burn。" % [str(training.get("employee_id", "员工")), str(training.get("skill_id", "能力")), int(training.get("remaining_weeks", 0))]
		"office_plan":
			if result.has("lease"):
				var lease: Dictionary = result.get("lease", {})
				return "空间回执：%s 已签署，容量 %d，周租 $%sK，租期 %d 周。" % [str(lease.get("name", "办公室")), int(lease.get("capacity", 0)), _one_decimal(float(lease.get("weekly_rent", 0.0))), int(lease.get("term_weeks", 0))]
			if result.has("fitout"):
				var fitout: Dictionary = result.get("fitout", {})
				return "空间回执：%s 开工，预计第 %d 周完成；本周现金支出 $%sK。" % [str(fitout.get("name", "装修")), int(fitout.get("complete_week", total_week)), _one_decimal(float(result.get("cash_due", 0.0)))]
		"policy_program":
			return "政策回执：研发扶持申请%s；技术评分 %d，首笔到账 $%s。" % ["获批" if bool(result.get("approved", false)) else "未入选", int(result.get("technical_score", 0)), _compact_usd(int(result.get("cash_received_usd", 0)))]
	return "经营回执：本次决定已写入持续台账。"


func _compact_usd(amount: int) -> String:
	if abs(amount) >= 1_000_000:
		return "%.1fM" % (float(amount) / 1_000_000.0)
	if abs(amount) >= 1000:
		return "%.1fK" % (float(amount) / 1000.0)
	return str(amount)


func _one_decimal(value: float) -> String:
	return "%.1f" % value


func _advance_vendor_stack() -> Dictionary:
	var service_order := ["forgenest_team", "signalharbor_observe", "quietwire_annual", "staffloom_core"]
	if chapter >= 3:
		service_order = ["staffloom_core", "signalharbor_observe", "quietwire_annual", "forgenest_team"]
	for service_id_value in service_order:
		var service_id := str(service_id_value)
		if operations.subscriptions.has(service_id):
			continue
		var result: Dictionary = operations.apply_decision("subscribe_saas", {
			"service_id": service_id,
			"initial_usage": 120.0 if service_id == "signalharbor_observe" else 0.0,
			"auto_renew": false,
		}, {"week": total_week})
		_record_operations_cash_due(result, "saas", service_id)
		return result
	# Once the stack exists, a review is still useful: usage is made explicit and
	# therefore can trigger a real overage/renewal decision later.
	if operations.subscriptions.has("signalharbor_observe"):
		return operations.apply_decision("report_saas_usage", {
			"service_id": "signalharbor_observe", "usage": 90.0 + float(employees.size()) * 18.0,
		}, {"week": total_week})
	return {"ok": true, "reason": "vendor_stack_current"}


func _start_next_people_development() -> Dictionary:
	_sync_operating_roster()
	var selected_id := ""
	var selected_skill := "management"
	var weakest := 999.0
	var employee_ids: Array = operations.employees.keys()
	employee_ids.sort()
	for employee_id_value in employee_ids:
		var employee_id := str(employee_id_value)
		var employee: Dictionary = operations.employees[employee_id]
		if not bool(employee.get("active", true)) or _employee_has_active_training(employee_id):
			continue
		var skills: Dictionary = employee.get("skills", {})
		for skill_id_value in skills:
			var skill_id := str(skill_id_value)
			var score := float(skills[skill_id])
			if score < weakest:
				weakest = score
				selected_id = employee_id
				selected_skill = skill_id
	if selected_id.is_empty():
		return {"ok": false, "reason": "no_employee_for_development"}
	return operations.apply_decision("start_training", {
		"employee_id": selected_id,
		"skill_id": selected_skill,
		"duration_weeks": 3,
		"gain": 0.8,
		"weekly_cost": 0.08,
	}, {"week": total_week})


func _advance_office_plan(preferred_lease: String = "") -> Dictionary:
	var active: Dictionary = operations.office.get("active_lease", {})
	var signed: Dictionary = operations.office.get("signed_lease", {})
	if active.is_empty() and signed.is_empty():
		var lease_id := preferred_lease
		if lease_id.is_empty():
			lease_id = "harbor_desk" if chapter <= 1 else ("canal_sublease" if chapter == 2 else "frostline_works")
		var lease_result: Dictionary = operations.apply_decision("sign_office_lease", {"lease_id": lease_id}, {"week": total_week})
		_record_operations_cash_due(lease_result, "office_deposit", lease_id)
		return lease_result
	if not preferred_lease.is_empty() and not active.is_empty() and signed.is_empty() and str(active.get("id", "")) != preferred_lease:
		var replacement: Dictionary = operations.apply_decision("replace_office_lease", {"lease_id": preferred_lease}, {"week": total_week})
		_record_operations_cash_due(replacement, "office_replacement_deposit", preferred_lease)
		return replacement
	if active.is_empty():
		return {"ok": true, "reason": "lease_move_in_pending", "lease": signed.duplicate(true)}
	var completed: Array = Array(operations.office.get("completed_fitouts", []))
	var in_progress: Array = Array(operations.office.get("fitouts_in_progress", []))
	var used: Dictionary = {}
	for item_value in completed + in_progress:
		if item_value is Dictionary:
			used[str(Dictionary(item_value).get("id", ""))] = true
	for fitout_id_value in ["acoustic_pods", "training_room", "flex_desks", "demo_room"]:
		var fitout_id := str(fitout_id_value)
		if used.has(fitout_id):
			continue
		var fitout_result: Dictionary = operations.apply_decision("start_fitout", {"fitout_id": fitout_id}, {"week": total_week})
		_record_operations_cash_due(fitout_result, "fitout", fitout_id)
		return fitout_result
	return {"ok": true, "reason": "office_plan_complete", "capacity": operations.office_capacity()}


func _record_operations_cash_due(result: Dictionary, category: String, source_id: String) -> void:
	if not bool(result.get("ok", false)):
		return
	var amount_usd := maxi(0, int(round(float(result.get("cash_due", 0.0)) * 1000.0)))
	if amount_usd <= 0:
		return
	var serial := int(memory.get("operations_commitment_serial", 0)) + 1
	memory["operations_commitment_serial"] = serial
	var commitment_id := "ops:%s:%s:%d" % [category, source_id, serial]
	business.add_commitment(
		"ops_commitment:%d:%d" % [total_week, serial], commitment_id, category,
		amount_usd, total_week, true
	)


func uses_authoritative_financial_ledger() -> bool:
	return bool(flags.get("financial_ledger_authoritative", false))


func _activate_financial_ledger_authority() -> void:
	if uses_authoritative_financial_ledger():
		return
	_sync_operating_roster()
	var runway_unit_usd := maxi(1, business.weekly_burn_usd())
	if runway_unit_usd <= 1:
		runway_unit_usd = maxi(1, business.weekly_cost_usd())
	var target_cash_usd := maxi(0, int(round(cash_weeks * float(runway_unit_usd))))
	var current_cash_usd := maxi(0, int(business.ledger.get("cash_usd", 0)))
	business.record_cash_adjustment(
		"ledger_authority:activation",
		"legacy_runway_migration",
		target_cash_usd - current_cash_usd,
		{"legacy_cash_weeks": cash_weeks, "runway_unit_usd": runway_unit_usd, "week": total_week}
	)
	flags["financial_ledger_authoritative"] = true
	memory["financial_ledger_activation_week"] = total_week
	# Existing chapter-scaled staff may predate the detailed ledger. Give every
	# employee's authored equity promise a single real cap-table grant at the
	# migration boundary; stable transaction ids make save/retry safe.
	_backfill_employee_option_grants()
	_sync_legacy_runway_from_business()


func _record_authoritative_cash_delta(delta_usd: int, category: String, metadata: Dictionary = {}) -> Dictionary:
	var serial := int(memory.get("authoritative_cash_serial", 0)) + 1
	memory["authoritative_cash_serial"] = serial
	var result: Dictionary = business.record_cash_adjustment(
		"model_cash:%d:%d:%s" % [total_week, serial, category],
		category,
		delta_usd,
		metadata
	)
	_sync_legacy_runway_from_business()
	return result


func _sync_legacy_runway_from_business() -> void:
	if not uses_authoritative_financial_ledger():
		return
	var burn_usd: int = int(business.weekly_burn_usd())
	var cash_usd := maxi(0, int(business.ledger.get("cash_usd", 0)))
	cash_weeks = 999.0 if burn_usd <= 0 and cash_usd > 0 else (float(cash_usd) / float(maxi(1, burn_usd)))
	if cash_usd <= 0:
		flags["cash_exhausted"] = true
	else:
		flags.erase("cash_exhausted")


func _financing_stage_for_chapter() -> String:
	if chapter <= 1:
		return "preseed"
	if chapter == 2:
		return "seed"
	return "series_a"


func _business_stage_exists(stage: String) -> bool:
	for safe_value in Array(business.capital.get("safes", [])):
		if safe_value is Dictionary and str(Dictionary(safe_value).get("stage", "")) == stage:
			return true
	for round_value in Array(business.capital.get("rounds", [])):
		if round_value is Dictionary and str(Dictionary(round_value).get("stage", "")) == stage:
			return true
	return false


func record_business_financing(stage: String = "", route: String = "clean", transaction_id: String = "") -> Dictionary:
	var normalized_stage := stage.strip_edges().to_lower()
	if normalized_stage.is_empty():
		normalized_stage = _financing_stage_for_chapter()
	if _business_stage_exists(normalized_stage):
		if uses_authoritative_financial_ledger():
			_sync_legacy_runway_from_business()
		return {"ok": true, "already_recorded": true, "stage": normalized_stage}
	var normalized_route := route if route in ["clean", "headline", "delegate"] else "clean"
	var stable_id := transaction_id
	if stable_id.is_empty():
		stable_id = "financing:%s:%d" % [normalized_stage, total_week]
	var result: Dictionary
	if normalized_stage == "bridge":
		result = business.issue_post_money_safe(
			stable_id, "juniper_ventures", "bridge", narrative,
			{"post_money_cap_usd": int(business.financing_quote("bridge", narrative).get("valuation_usd", 6_000_000)), "pro_rata": true, "signed_week": total_week}
		)
	else:
		result = business.apply_decision("raise_%s" % normalized_stage, normalized_route, _business_context(stable_id))
	if bool(result.get("ok", false)):
		memory["last_detailed_financing_stage"] = normalized_stage
		memory["last_detailed_financing_week"] = total_week
		_record_history("business_financing", {"stage": normalized_stage, "route": normalized_route, "result": result.duplicate(true)})
		if uses_authoritative_financial_ledger():
			_sync_legacy_runway_from_business()
	return result


func _business_context(transaction_id: String) -> Dictionary:
	return {
		"transaction_id": transaction_id,
		"total_week": total_week,
		"chapter": chapter,
		"week_in_chapter": week_in_chapter,
		"narrative": narrative,
		"capability": capability,
		"coherence": coherence,
		"product_fit": clampi(int(round((capability + coherence) * 0.5)), 0, 100),
	}


func resolve_systemic_event(event: Dictionary, choice_id: String) -> Dictionary:
	var event_id := str(event.get("_system_decision_id", event.get("id", "")))
	var domain := str(event.get("_system_domain", event.get("family", "")))
	var result: Dictionary = {"ok": true, "decision_id": event_id, "choice_id": choice_id}
	var context := _business_context("system_event:%s:%d" % [event_id, total_week])
	if bool(event.get("_runtime_state_event", false)):
		var runtime_source := str(event.get("_runtime_source_system", ""))
		var runtime_decision := str(event.get("_runtime_decision_id", event_id))
		if runtime_source == "business":
			result = business.apply_decision(runtime_decision, choice_id, context)
		else:
			result = _resolve_runtime_operations_event(event_id, choice_id)
		if domain in ["people", "organization", "org", "office", "vendor", "saas"]:
			operations.apply_decision("acknowledge_event", {"event_id": event_id, "cooldown_weeks": maxi(2, int(event.get("cooldown_weeks", 3)))}, {"week": total_week})
		var runtime_receipt := _systemic_event_receipt(event_id, choice_id, domain, result)
		if not runtime_receipt.is_empty():
			result["receipt"] = runtime_receipt
			memory["last_operating_action_summary"] = runtime_receipt
		memory["last_systemic_event"] = {"id": event_id, "choice_id": choice_id, "domain": domain, "result": result.duplicate(true), "runtime": true}
		_record_history("systemic_event_resolved", Dictionary(memory["last_systemic_event"]).duplicate(true))
		# People decisions are resolved in the operations subsystem. Pull those
		# mutations back before the roster sync, otherwise the model's older salary,
		# level, equity, or risk values would immediately overwrite the decision.
		_pull_operating_employee_state()
		_sync_operating_roster()
		if uses_authoritative_financial_ledger():
			_sync_legacy_runway_from_business()
		return result
	match event_id:
		"investor_update_raw":
			var investor_choice := "raw" if choice_id == "send_raw" else ("headline" if choice_id == "headline_only" else "delegate")
			result = business.apply_decision("investor_update", investor_choice, context)
		"customer_reference_diligence", "board_consent_required":
			result = _resolve_static_capital_event(event_id, choice_id)
		"preseed_safe_terms":
			var preseed_choice := "clean" if choice_id == "accept_clean" else ("headline" if choice_id == "trade_cap_for_rights" else "delegate")
			result = record_business_financing("preseed", preseed_choice, str(context["transaction_id"]))
		"option_pool_shuffle":
			var seed_choice := "clean" if choice_id == "founder_friendly" else ("headline" if choice_id == "headline_valuation" else "delegate")
			result = record_business_financing("seed", seed_choice, str(context["transaction_id"]))
		"inside_bridge":
			if choice_id in ["take_bridge", "delegate"]:
				result = record_business_financing("bridge", "delegate" if choice_id == "delegate" else "clean", str(context["transaction_id"]))
		"rnd_grant_phase_one":
			result = business.apply_decision("apply_grant", "delegate" if choice_id == "delegate" else "manual", context)
			if bool(result.get("ok", false)) and business.policy.get("programs", {}) is Dictionary and Dictionary(business.policy.get("programs", {})).has("phase_i_grant"):
				var grant: Dictionary = Dictionary(business.policy["programs"]["phase_i_grant"])
				grant["scope"] = "broad_jobs" if choice_id == "broad_jobs_story" else ("delegated_evidence" if choice_id == "delegate" else "technical_scope")
				if choice_id == "broad_jobs_story":
					grant["milestone_due_week"] = maxi(total_week + 4, int(grant.get("milestone_due_week", total_week + 4)) - 2)
		"jobs_tax_credit":
			result = business.apply_decision("tax_credit", "delegate" if choice_id == "delegate" else "accept", context)
			if bool(result.get("ok", false)) and bool(result.get("accepted", false)):
				var jobs := 12 if choice_id == "modest_commitment" else (40 if choice_id == "headline_commitment" else 20)
				var credit := 180_000 if jobs == 12 else (500_000 if jobs == 40 else 300_000)
				business.policy["job_commitment"] = jobs
				business.policy["investment_commitment_usd"] = 900_000 if jobs == 12 else (3_000_000 if jobs == 40 else 1_500_000)
				business.policy["deferred_tax_credit_usd"] = credit
				result["job_commitment"] = jobs
				result["deferred_tax_credit_usd"] = credit
		"public_comment_window":
			var comment_choice := "strong_disclosure" if choice_id == "support_disclosure" else ("industry_flexibility" if choice_id == "industry_self_rule" else "delegate")
			result = business.apply_decision("public_comment", comment_choice, context)
		"agency_roundtable":
			result = business.apply_decision("industry_coalition", "delegate" if choice_id == "delegate" else "join", context)
			if bool(result.get("ok", false)):
				business.policy["roundtable_focus"] = "technical_evidence" if choice_id == "bring_engineer" else ("policy_access" if choice_id == "bring_policy_lead" else "delegated_briefing")
				if choice_id == "bring_engineer":
					business.policy["regulatory_credibility"] = clampi(int(business.policy.get("regulatory_credibility", 50)) + 4, 0, 100)
				elif choice_id == "bring_policy_lead":
					business.policy["access"] = clampi(int(business.policy.get("access", 0)) + 5, 0, 100)
		"government_pilot":
			result = business.apply_decision("government_pilot", "delegate" if choice_id == "delegate" else "bid", context)
			if bool(result.get("ok", false)) and Dictionary(business.policy.get("pilots", {})).has("agency_pilot"):
				var pilot: Dictionary = business.policy["pilots"]["agency_pilot"]
				pilot["scope"] = "full" if choice_id == "accept_full" else ("delegated" if choice_id == "delegate" else "scoped")
				if choice_id == "accept_full" and str(pilot.get("status", "")) == "awarded":
					pilot["milestone_due_week"] = maxi(total_week + 3, int(pilot.get("milestone_due_week", total_week + 4)) - 1)
		"registered_policy_adviser":
			result = business.apply_decision("registered_lobbying", "delegate" if choice_id == "delegate" else ("decline" if choice_id == "build_internal" else "engage"), context)
		"industry_standard_draft":
			result = _resolve_industry_standard_draft(choice_id)
		"requisition_scope", "candidate_counteroffer", "reference_discrepancy", "title_inflation", "key_person_poach":
			result = _resolve_static_people_event(event_id, choice_id)
		"office_shortlist", "landlord_free_rent", "fitout_delay", "meeting_room_capacity", "office_hvac", "sublease_opportunity":
			result = _resolve_static_office_event(event_id, choice_id)
		"identity_plan_wall", "ci_usage_overage", "vendor_outage_demo", "vendor_acquisition", "dormant_seat_audit", "automatic_renewal":
			result = _resolve_static_saas_event(event_id, choice_id)
		"first_manager_span", "promotion_calibration", "mentor_burnout":
			result = _resolve_static_org_event(event_id, choice_id)
		"chorus_release_collision", "competitor_seed_round", "competitor_down_round":
			result = _mark_competitor_event("chorus_systems", event_id, choice_id)
		"morrow_benchmark":
			result = _mark_competitor_event("morrow_ai", event_id, choice_id)
		"harbor_price_cut":
			result = _mark_competitor_event("harbor_desk", event_id, choice_id)
		"shared_customer_trial":
			result = _resolve_shared_customer_trial(choice_id)
	if bool(event.get("fictionalized", false)) and not Array(event.get("reference_tags", [])).is_empty():
		result = _resolve_industry_echo_event(event, choice_id, domain)
	if domain in ["people", "org", "office", "saas"]:
		operations.apply_decision("acknowledge_event", {
			"event_id": event_id, "cooldown_weeks": maxi(2, int(event.get("cooldown_weeks", 3))),
		}, {"week": total_week})
	var systemic_receipt := _systemic_event_receipt(event_id, choice_id, domain, result)
	if not systemic_receipt.is_empty():
		result["receipt"] = systemic_receipt
		memory["last_operating_action_summary"] = systemic_receipt
	memory["last_systemic_event"] = {"id": event_id, "choice_id": choice_id, "domain": domain, "result": result.duplicate(true)}
	_record_history("systemic_event_resolved", Dictionary(memory["last_systemic_event"]).duplicate(true))
	_pull_operating_employee_state()
	_sync_operating_roster()
	if uses_authoritative_financial_ledger():
		_sync_legacy_runway_from_business()
	return result


func _resolve_industry_echo_event(event: Dictionary, choice_id: String, domain: String) -> Dictionary:
	var event_id := str(event.get("id", ""))
	var selected_label := ""
	for choice_value in Array(event.get("choices", [])):
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = choice_value
		if str(choice.get("id", "")) == choice_id:
			selected_label = str(choice.get("label", ""))
			break
	if event_id.is_empty() or selected_label.is_empty():
		return {"ok": false, "reason": "invalid_industry_echo_choice", "decision_id": event_id, "choice_id": choice_id}
	var ledger: Dictionary = Dictionary(memory.get("industry_echo_ledger", {})).duplicate(true)
	var receipt := {
		"id": event_id,
		"week": total_week,
		"domain": domain,
		"choice_id": choice_id,
		"choice_label": selected_label,
		"title": str(event.get("title", "行业回声")),
		"valence": str(event.get("valence", "dilemma")),
		"comic_intensity": int(event.get("comic_intensity", 2)),
		"reference_tags": Array(event.get("reference_tags", [])).duplicate(),
	}
	ledger[event_id] = receipt.duplicate(true)
	memory["industry_echo_ledger"] = ledger
	memory["last_industry_echo"] = receipt.duplicate(true)
	memory["last_industry_echo_valence"] = str(receipt.get("valence", "dilemma"))
	flags["industry_echo_%s" % event_id] = true
	if domain == "market":
		var feed: Array = Array(business.market.get("public_feed", []))
		feed.append({
			"id": "industry_echo:%d:%s" % [total_week, event_id],
			"week": total_week,
			"competitor_id": "industry_echo",
			"competitor_name": "行业回声",
			"strategy": "industry_echo",
			"signal": event_id,
			"headline": str(event.get("title", "行业出现了一条新动态。")),
		})
		while feed.size() > 80:
			feed.pop_front()
		business.market["public_feed"] = feed
		business.market["category_demand"] = clampi(int(business.market.get("category_demand", 38)) + 1, 0, 100)
		if event_id == "accidental_catfish_price_war":
			business.market["price_pressure_bp"] = maxi(7_000, int(business.market.get("price_pressure_bp", 10_000)) - 350)
	return {
		"ok": true,
		"decision_id": event_id,
		"choice_id": choice_id,
		"industry_echo_logged": true,
		"receipt": receipt,
	}


func _resolve_industry_standard_draft(choice_id: String) -> Dictionary:
	var stance := "amended_public_interest" if choice_id == "sign_with_amendment" else ("coalition_only" if choice_id == "refuse_signature" else "lantern_authored")
	business.policy["standard_draft_status"] = "submitted"
	business.policy["standard_draft_stance"] = stance
	business.policy["standard_draft_week"] = total_week
	business.policy["standard_draft_founder_signed"] = choice_id != "refuse_signature"
	if choice_id == "sign_with_amendment":
		business.policy["regulatory_credibility"] = clampi(int(business.policy.get("regulatory_credibility", 50)) + 8, 0, 100)
		business.policy["public_trust"] = clampi(int(business.policy.get("public_trust", 50)) + 7, 0, 100)
		business.policy["industry_influence"] = clampi(int(business.policy.get("industry_influence", 0)) + 6, 0, 100)
	elif choice_id == "refuse_signature":
		business.policy["public_trust"] = clampi(int(business.policy.get("public_trust", 50)) + 4, 0, 100)
		business.policy["industry_influence"] = clampi(int(business.policy.get("industry_influence", 0)) + 2, 0, 100)
	else:
		business.policy["access"] = clampi(int(business.policy.get("access", 0)) + 8, 0, 100)
		business.policy["industry_influence"] = clampi(int(business.policy.get("industry_influence", 0)) + 10, 0, 100)
		business.policy["regulatory_credibility"] = clampi(int(business.policy.get("regulatory_credibility", 50)) + 5, 0, 100)
	var feed: Array = Array(business.policy.get("public_feed", []))
	feed.append({
		"week": total_week,
		"kind": "industry_standard_draft",
		"headline": "行业工作组提交了可复现评测与供应商控制草案；公司的经营证据进入正式文本。",
		"stance": stance,
	})
	business.policy["public_feed"] = feed
	return {
		"ok": true,
		"standard_draft_status": "submitted",
		"stance": stance,
		"access": int(business.policy.get("access", 0)),
		"industry_influence": int(business.policy.get("industry_influence", 0)),
		"regulatory_credibility": int(business.policy.get("regulatory_credibility", 0)),
		"public_trust": int(business.policy.get("public_trust", 0)),
	}


func _systemic_event_receipt(event_id: String, choice_id: String, domain: String, result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		return "经营回执：状态已先一步变化，本次未重复执行（%s）。至少省下一封‘请忽略上一封邮件’。" % str(result.get("reason", "state_changed"))
	var amount_usd := int(result.get("amount_usd", result.get("cash_received_usd", 0)))
	if amount_usd > 0:
		var stage := str(result.get("stage", "")).to_upper()
		return "%s回执：$%s 已到账%s；现金、义务与稀释已同时入账。" % ["融资" if not stage.is_empty() else "政策", _compact_usd(amount_usd), "（%s）" % stage if not stage.is_empty() else ""]
	if result.has("job_commitment"):
		return "政策回执：承诺新增 %d 个岗位，递延税惠 $%s；财务把兑现条件写在数字旁边，没有藏进脚注。" % [int(result.get("job_commitment", 0)), _compact_usd(int(result.get("deferred_tax_credit_usd", 0)))]
	if event_id == "customer_reference_diligence":
		return "尽调回执：客户参考电话已完成，3 步人工审核按选择写入事实清单；投资人信任更新为 %d。" % int(result.get("investor_trust", 0))
	if event_id == "board_consent_required":
		return "治理回执：董事会同意已归档，表决与性能保证条款都进入持续治理记录。"
	if event_id.begins_with("candidate_deadline") or event_id == "candidate_counteroffer":
		var salary := float(result.get("salary", Dictionary(result.get("terms", {})).get("salary", 0.0)))
		return "人才回执：候选人的新条款已锁定%s；下一次跟进有明确期限。" % ("，年薪 $%sK" % _one_decimal(salary) if salary > 0.0 else "")
	if event_id in ["requisition_scope", "reference_discrepancy", "title_inflation"]:
		return "招聘回执：%s 的筛选状态与岗位边界已写回真实管线。" % str(result.get("candidate_id", result.get("requisition_id", "该岗位")))
	if event_id in ["first_manager_span", "promotion_calibration", "mentor_burnout"] or event_id.begins_with("manager_overload") or event_id.begins_with("flight_risk"):
		return "组织回执：%s 的职级、负荷与留任状态已更新；这次不是把问题改名为‘成长机会’。" % str(result.get("employee_id", "相关同事"))
	if result.has("service_id") or domain in ["vendor", "saas"]:
		return "采购回执：%s 的席位、用量、续约与现金时点已更新。工具没有变聪明，但账单终于说人话了。" % str(result.get("service_id", "服务合同"))
	if result.has("lease") or result.has("fitout") or event_id.begins_with("office_") or event_id in ["landlord_free_rent", "fitout_delay", "meeting_room_capacity", "office_hvac", "sublease_opportunity"]:
		return "空间回执：租约、容量与搬入节点已写入台账；会议室名字暂时没有纳入资本化支出。"
	if result.has("mrr_gain_usd"):
		return "市场回执：新增 %d 个客户，MRR +$%s。销售只发了一个烟花表情，算是遵守品牌规范。" % [int(result.get("customer_gain", 0)), _compact_usd(int(result.get("mrr_gain_usd", 0)))]
	if result.has("competitor"):
		return "市场回执：对 %s 的应对已改变需求、定价或人才压力；对手不会因为我们关掉页面就停止烧钱。" % str(result.get("competitor_id", "竞争对手"))
	if domain == "policy":
		return "政策回执：选择已写入准入、影响力与履约台账，后续结果会按里程碑出现。"
	return "经营回执：%s / %s 已写入持续状态。" % [event_id, choice_id]


func _resolve_runtime_operations_event(event_id: String, choice_id: String) -> Dictionary:
	var parts := event_id.split(":", false, 1)
	var base_id := str(parts[0])
	var actor_id := str(parts[1]) if parts.size() > 1 else ""
	match base_id:
		"candidate_deadline":
			for offer_value in operations.offers:
				if not offer_value is Dictionary:
					continue
				var offer: Dictionary = offer_value
				if str(offer.get("candidate_id", "")) != actor_id or str(offer.get("status", "")) != "pending":
					continue
				var terms: Dictionary = offer.get("terms", {})
				if choice_id == "increase_cash":
					terms["salary"] = float(terms.get("salary", 0.0)) * 1.08
					offer["acceptance_score"] = clampf(float(offer.get("acceptance_score", 0.0)) + 0.14, 0.0, 1.0)
				elif choice_id == "protect_scope":
					terms["scope_review_week"] = total_week + 26
					offer["acceptance_score"] = clampf(float(offer.get("acceptance_score", 0.0)) + 0.10, 0.0, 1.0)
				else:
					terms["scope_review_week"] = total_week + 18
					terms["signing_bonus"] = float(terms.get("salary", 0.0)) * 0.04
					offer["acceptance_score"] = clampf(float(offer.get("acceptance_score", 0.0)) + 0.12, 0.0, 1.0)
				offer["terms"] = terms
				return {"ok": true, "candidate_id": actor_id, "offer_id": str(offer.get("id", "")), "acceptance_score": offer["acceptance_score"], "terms": terms.duplicate(true)}
			return {"ok": false, "reason": "pending_offer_missing", "candidate_id": actor_id}
		"manager_overload":
			if not operations.employees.has(actor_id):
				return {"ok": false, "reason": "manager_missing", "employee_id": actor_id}
			if choice_id == "train_manager":
				return _ensure_employee_training(actor_id, "management")
			var reports: Array[String] = []
			var alternatives: Array[String] = []
			for employee_id_value in operations.employees:
				var employee_id := str(employee_id_value)
				var employee: Dictionary = operations.employees[employee_id]
				if not bool(employee.get("active", true)) or employee_id == actor_id:
					continue
				if str(employee.get("manager_id", "")) == actor_id:
					reports.append(employee_id)
				elif int(employee.get("level", 1)) >= 3:
					alternatives.append(employee_id)
			if reports.is_empty() or alternatives.is_empty():
				return _ensure_employee_training(actor_id, "management")
			reports.sort()
			alternatives.sort()
			var reassigned: String = str(reports.back())
			var new_manager: String = str(alternatives[0])
			var manager_result: Dictionary = operations.apply_decision("set_manager", {"employee_id": reassigned, "manager_id": new_manager}, {"week": total_week})
			if not bool(manager_result.get("ok", false)):
				return _ensure_employee_training(actor_id, "management")
			if choice_id == "delegate":
				manager_result["training"] = _ensure_employee_training(actor_id, "management")
			return manager_result
		"flight_risk":
			if not operations.employees.has(actor_id):
				return {"ok": false, "reason": "employee_missing", "employee_id": actor_id}
			var employee: Dictionary = operations.employees[actor_id]
			if choice_id == "retention_cash":
				employee["salary_annual"] = float(employee.get("salary_annual", 0.0)) * 1.08
				employee["flight_risk"] = maxf(0.0, float(employee.get("flight_risk", 0.0)) - 28.0)
				employee["growth_satisfaction"] = clampf(float(employee.get("growth_satisfaction", 50.0)) + 8.0, 0.0, 100.0)
				return {"ok": true, "employee_id": actor_id, "salary_annual": employee["salary_annual"], "flight_risk": employee["flight_risk"]}
			var training_result := _ensure_employee_training(actor_id, "management" if int(employee.get("level", 1)) >= 3 else "product")
			employee["flight_risk"] = maxf(0.0, float(employee.get("flight_risk", 0.0)) - (22.0 if choice_id == "career_plan" else 18.0))
			employee["growth_satisfaction"] = clampf(float(employee.get("growth_satisfaction", 50.0)) + 16.0, 0.0, 100.0)
			training_result["flight_risk"] = employee["flight_risk"]
			return training_result
		"office_over_capacity":
			var office_result: Dictionary
			var signed_lease: Dictionary = operations.office.get("signed_lease", {})
			if not signed_lease.is_empty():
				# A replacement in its move-in window is already the durable answer.
				# Treat an old queued modal as a truthful confirmation instead of
				# attempting the same fitout or lease a second time.
				return {
					"ok": true, "already_resolving": true,
					"lease": signed_lease.duplicate(true),
					"move_in_week": int(signed_lease.get("start_week", total_week)),
					"capacity_after_move": int(signed_lease.get("capacity", operations.office_capacity())),
				}
			var overage: int = maxi(1, int(operations.active_employee_count()) - int(operations.office_capacity()))
			var flex_exists := _active_office_has_fitout("flex_desks")
			if choice_id == "tolerate_crowding" or (choice_id == "flex_desks" and flex_exists):
				operations.office["workspace_strain"] = clampf(float(operations.office.get("workspace_strain", 0.0)) + 0.12, 0.0, 1.0)
				operations.office["crowding_plan_until_week"] = total_week + 3
				office_result = {"ok": true, "crowding_tolerated": true, "overage": overage, "review_week": total_week + 3}
			elif choice_id == "flex_desks":
				office_result = operations.apply_decision("start_fitout", {"fitout_id": "flex_desks"}, {"week": total_week})
			elif choice_id == "replace_lease":
				office_result = operations.apply_decision("replace_office_lease", {"lease_id": "frostline_works"}, {"week": total_week})
			else:
				var active_lease_id := str(Dictionary(operations.office.get("active_lease", {})).get("id", ""))
				if not flex_exists and overage <= 6:
					office_result = operations.apply_decision("start_fitout", {"fitout_id": "flex_desks"}, {"week": total_week})
				elif active_lease_id != "frostline_works":
					office_result = operations.apply_decision("replace_office_lease", {"lease_id": "frostline_works"}, {"week": total_week})
				else:
					operations.office["workspace_strain"] = clampf(float(operations.office.get("workspace_strain", 0.0)) + 0.08, 0.0, 1.0)
					operations.office["crowding_plan_until_week"] = total_week + 3
					office_result = {"ok": true, "crowding_tolerated": true, "overage": overage, "review_week": total_week + 3}
			var lease_result: Dictionary = office_result.get("lease", {})
			_record_operations_cash_due(office_result, "office_capacity", str(lease_result.get("id", "flex_desks")))
			return office_result
		"saas_renewal":
			if not operations.subscriptions.has(actor_id):
				return {"ok": false, "reason": "subscription_missing", "service_id": actor_id}
			var subscription: Dictionary = operations.subscriptions[actor_id]
			if choice_id == "cancel":
				return operations.apply_decision("cancel_saas", {"service_id": actor_id}, {"week": total_week})
			var extension := 13 if choice_id == "delegate" else maxi(13, int(subscription.get("term_weeks", 52)))
			subscription["auto_renew"] = choice_id == "renew"
			subscription["renewal_week"] = maxi(total_week + extension, int(subscription.get("renewal_week", total_week)) + extension)
			if choice_id == "delegate":
				subscription["price_protection"] = true
			return {"ok": true, "service_id": actor_id, "renewal_week": subscription["renewal_week"], "auto_renew": subscription["auto_renew"], "price_protection": bool(subscription.get("price_protection", false))}
		"saas_overage":
			if not operations.subscriptions.has(actor_id):
				return {"ok": false, "reason": "subscription_missing", "service_id": actor_id}
			var overage_subscription: Dictionary = operations.subscriptions[actor_id]
			var spec: Dictionary = overage_subscription.get("spec", {})
			if choice_id == "cap_usage":
				overage_subscription["usage"] = float(spec.get("included_usage", 0.0))
			elif choice_id == "delegate":
				overage_subscription["usage"] = float(spec.get("included_usage", 0.0)) * 0.92
			return {"ok": true, "service_id": actor_id, "usage": float(overage_subscription.get("usage", 0.0)), "weekly_cost": operations.subscription_weekly_cost(actor_id)}
	return {"ok": false, "reason": "unknown_runtime_operations_event", "event_id": event_id}


func _active_office_has_fitout(fitout_id: String) -> bool:
	var active_lease_id := str(Dictionary(operations.office.get("active_lease", {})).get("id", ""))
	for fitout_value in Array(operations.office.get("completed_fitouts", [])) + Array(operations.office.get("fitouts_in_progress", [])):
		if not fitout_value is Dictionary:
			continue
		var fitout: Dictionary = fitout_value
		if str(fitout.get("id", "")) == fitout_id and str(fitout.get("lease_id", active_lease_id)) == active_lease_id:
			return true
	return false


func _resolve_static_capital_event(event_id: String, choice_id: String) -> Dictionary:
	match event_id:
		"customer_reference_diligence":
			var investor: Dictionary = business.investors.get("juniper_ventures", {})
			var mode := "full_workflow" if choice_id == "disclose_workflow" else ("coached_reference" if choice_id == "coach_customer" else "shared_fact_sheet")
			investor["customer_reference_status"] = "complete"
			investor["customer_reference_mode"] = mode
			investor["trust"] = clampi(int(investor.get("trust", 50)) + (8 if choice_id == "disclose_workflow" else (2 if choice_id == "coach_customer" else 6)), 0, 100)
			business.market["northstar_reference"] = {
				"status": "complete", "manual_review_steps": 3,
				"disclosed": choice_id != "coach_customer", "mode": mode, "week": total_week,
			}
			return {"ok": true, "investor_id": "juniper_ventures", "reference_mode": mode, "investor_trust": int(investor.get("trust", 0)), "manual_review_steps": 3}
		"board_consent_required":
			var consents: Array = Array(business.capital.get("board_consents", [])).duplicate(true)
			var consent := {
				"id": "board_consent:%d" % total_week,
				"week": total_week,
				"status": "approved",
				"vote": "unanimous" if choice_id in ["accept_condition", "delegate"] else "one_vote_margin",
				"performance_guarantee": "removed" if choice_id == "accept_condition" else ("narrowed" if choice_id == "delegate" else "retained"),
				"prepared_by": "lantern" if choice_id == "delegate" else "founder",
			}
			consents.append(consent)
			business.capital["board_consents"] = consents
			business.capital["latest_protective_provision"] = {
				"requires_board_consent": true,
				"scope": "new_debt_and_annual_vendor_minimum",
				"last_approval_week": total_week,
			}
			return {"ok": true, "consent": consent.duplicate(true), "board_consent_count": consents.size()}
	return {"ok": false, "reason": "unknown_capital_event", "event_id": event_id}


func _resolve_static_office_event(event_id: String, choice_id: String) -> Dictionary:
	if event_id == "office_shortlist":
		var lease_id := "frostline_works" if choice_id == "eighth_street" else "canal_sublease"
		var selected := _advance_office_plan(lease_id)
		selected["selection_rationale"] = "capacity" if choice_id == "eighth_street" else ("modeled_tradeoffs" if choice_id == "delegate" else "flexibility")
		return selected
	var active: Dictionary = operations.office.get("active_lease", {})
	if active.is_empty():
		return {"ok": false, "reason": "active_lease_missing", "event_id": event_id}
	match event_id:
		"landlord_free_rent":
			var half_term := maxi(1, int(active.get("term_weeks", 26)) / 2)
			active["break_option_week"] = int(active.get("start_week", total_week)) + half_term
			active["rent_negotiation_choice"] = choice_id
			if choice_id == "take_free_rent":
				active["rent_credit_weeks_remaining"] = 12
				active["break_option_week"] = -1
				active["end_week"] = maxi(int(active.get("end_week", total_week)), total_week + 52)
			elif choice_id == "delegate":
				active["rent_credit_weeks_remaining"] = 8
				active["conditional_sublease_right"] = true
			return {"ok": true, "lease_id": str(active.get("id", "")), "rent_credit_weeks": int(active.get("rent_credit_weeks_remaining", 0)), "break_option_week": int(active.get("break_option_week", -1)), "conditional_sublease_right": bool(active.get("conditional_sublease_right", false))}
		"fitout_delay":
			var in_progress: Array = Array(operations.office.get("fitouts_in_progress", []))
			var started: Dictionary = {}
			if in_progress.is_empty():
				started = _advance_office_plan()
				in_progress = Array(operations.office.get("fitouts_in_progress", []))
			if in_progress.is_empty():
				return started if not started.is_empty() else {"ok": false, "reason": "fitout_missing"}
			var fitout: Dictionary = in_progress[0]
			fitout["permit_resolution"] = choice_id
			if choice_id == "remove_booth":
				fitout["capacity_delta"] = int(fitout.get("capacity_delta", 0)) + 1
				fitout["focus"] = float(fitout.get("focus", 0.0)) * 0.5
			elif choice_id == "redraw":
				fitout["complete_week"] = int(fitout.get("complete_week", total_week + 1)) + 1
			else:
				fitout["egress_redesigned"] = true
			operations.office["fitouts_in_progress"] = in_progress
			return {"ok": true, "fitout": fitout.duplicate(true), "permit_resolution": choice_id}
		"meeting_room_capacity":
			operations.office["meeting_capacity_resolution"] = choice_id
			if choice_id == "stagger_schedule":
				operations.office["interview_calendar_policy"] = "staggered"
				for candidate_value in operations.candidates.values():
					if candidate_value is Dictionary and str(Dictionary(candidate_value).get("status", "")) in ["in_process", "shortlisted"]:
						Dictionary(candidate_value)["decision_deadline_week"] = int(Dictionary(candidate_value).get("decision_deadline_week", total_week + 1)) + 1
			elif choice_id == "convert_storage":
				operations.office["temporary_phone_room"] = true
				operations.office["temporary_phone_room_capacity_delta"] = -1
				operations.office["meeting_room_delta"] = 1
			else:
				operations.office["calendar_optimization"] = true
			return {"ok": true, "resolution": choice_id, "capacity": operations.office_capacity(), "meeting_room_delta": int(operations.office.get("meeting_room_delta", 0))}
		"office_hvac":
			active["after_hours_hvac_resolution"] = choice_id
			if choice_id == "pay_after_hours":
				active["after_hours_hvac_hours"] = 8
				active["facility_outlay_usd"] = 2_240
			elif choice_id == "move_work":
				active["weekend_work_moved"] = true
			else:
				active["after_hours_hvac_credit_usd"] = 2_240
				active["night_training_split"] = true
			return {"ok": true, "lease_id": str(active.get("id", "")), "resolution": choice_id, "facility_outlay_usd": int(active.get("facility_outlay_usd", 0)), "credit_usd": int(active.get("after_hours_hvac_credit_usd", 0))}
		"sublease_opportunity":
			active["sublease_decision"] = choice_id
			if choice_id == "keep_capacity":
				active["sublease_status"] = "declined"
				return {"ok": true, "lease_id": str(active.get("id", "")), "sublease_status": "declined", "capacity": operations.office_capacity()}
			var available_capacity := maxi(0, operations.office_capacity() - operations.active_employee_count())
			var subleased_seats := mini(18, available_capacity)
			active["sublease_status"] = "active"
			active["subtenant"] = "chorus_systems"
			active["subleased_seats"] = subleased_seats
			active["sublease_weekly_income"] = float(active.get("weekly_rent", 0.0)) * (0.52 if choice_id == "delegate" else 0.45)
			active["shared_front_desk"] = choice_id == "sublease"
			active["independent_access_route"] = choice_id == "delegate"
			return {"ok": true, "lease_id": str(active.get("id", "")), "sublease_status": "active", "subleased_seats": subleased_seats, "weekly_income": float(active.get("sublease_weekly_income", 0.0)), "capacity": operations.office_capacity()}
	return {"ok": false, "reason": "unknown_office_event", "event_id": event_id}


func _ensure_employee_training(employee_id: String, skill_id: String) -> Dictionary:
	for training_value in operations.trainings:
		if training_value is Dictionary and str(Dictionary(training_value).get("employee_id", "")) == employee_id and str(Dictionary(training_value).get("status", "")) == "active":
			return {"ok": true, "already_active": true, "training": Dictionary(training_value).duplicate(true)}
	return operations.apply_decision("start_training", {"employee_id": employee_id, "skill_id": skill_id, "duration_weeks": 3, "gain": 0.9, "weekly_cost": 0.08}, {"week": total_week})


func _ensure_subscription(service_id: String) -> Dictionary:
	if operations.subscriptions.has(service_id):
		return {"ok": true, "already_subscribed": true, "service_id": service_id}
	var result: Dictionary = operations.apply_decision("subscribe_saas", {"service_id": service_id, "auto_renew": false}, {"week": total_week})
	_record_operations_cash_due(result, "saas", service_id)
	return result


func _resolve_static_people_event(event_id: String, choice_id: String) -> Dictionary:
	match event_id:
		"requisition_scope":
			var opened := _open_next_requisition("systemic_event:%s" % choice_id)
			if not bool(opened.get("ok", false)):
				return opened
			var requisition_id := str(opened.get("requisition_id", memory.get("last_requisition_id", "")))
			for requisition_value in operations.requisitions:
				if requisition_value is Dictionary and str(Dictionary(requisition_value).get("id", "")) == requisition_id:
					var requisition: Dictionary = requisition_value
					requisition["scope_model"] = "senior_ic" if choice_id == "senior_ic" else ("hero_generalist" if choice_id == "hero_generalist" else "evidence_backplanned")
					if choice_id == "hero_generalist":
						requisition["salary_band"] = [float(Array(requisition.get("salary_band", [35.0, 80.0]))[0]), float(Array(requisition.get("salary_band", [35.0, 80.0]))[1]) * 1.15]
					opened["scope_model"] = requisition["scope_model"]
					break
			return opened
		"candidate_counteroffer":
			var candidate_id := _first_pending_offer_candidate_id()
			if candidate_id.is_empty():
				return {"ok": false, "reason": "pending_offer_missing"}
			var runtime_choice := "protect_scope" if choice_id == "increase_scope" else choice_id
			return _resolve_runtime_operations_event("candidate_deadline:%s" % candidate_id, runtime_choice)
		"reference_discrepancy":
			var focus_id := _first_focus_candidate_id()
			if focus_id.is_empty():
				return {"ok": false, "reason": "focused_candidate_missing"}
			var candidate: Dictionary = operations.candidates[focus_id]
			if choice_id == "withdraw":
				candidate["status"] = "released"
				candidate["release_reason"] = "reference_boundary"
				candidate["released_week"] = total_week
				var requisition_id := str(candidate.get("requisition_id", ""))
				return {"ok": true, "candidate_id": focus_id, "withdrawn": true, "next": operations.call("_activate_next_shortlisted", requisition_id, "reference_withdrawal")}
			var completed: Array = Array(candidate.get("completed_interviews", []))
			if completed.size() < HiringOperationsSystemScript.INTERVIEW_STAGES.size():
				var stage := str(HiringOperationsSystemScript.INTERVIEW_STAGES[completed.size()])
				return operations.apply_decision("interview_candidate", {"candidate_id": focus_id, "stage": stage}, {"week": total_week})
			candidate["reference_verified"] = true
			candidate["confidence"]["overall"] = clampf(float(Dictionary(candidate.get("confidence", {})).get("overall", 0.5)) + (0.15 if choice_id == "delegate" else 0.10), 0.0, 1.0)
			return {"ok": true, "candidate_id": focus_id, "reference_verified": true}
		"title_inflation":
			# Title negotiations most naturally attach to a live offer.  An offer can
			# resolve at the weekly operations boundary before an already-materialized
			# side decision is opened, though, which closes its requisition and clears
			# the focus cursor.  Keep the decision state-backed by following the most
			# recent accepted offer in that case instead of producing a prose-only
			# modal (or failing with focused_candidate_missing).
			var focus_id := _title_negotiation_candidate_id()
			var opened_requisition := false
			if focus_id.is_empty():
				var opened := _open_next_requisition("systemic_event:title_inflation")
				if not bool(opened.get("ok", false)):
					return opened
				focus_id = str(opened.get("focus_candidate_id", _first_focus_candidate_id()))
				opened_requisition = true
			if focus_id.is_empty() or not operations.candidates.has(focus_id):
				return {"ok": false, "reason": "focused_candidate_missing"}
			var candidate: Dictionary = operations.candidates[focus_id]
			var title_model := "principal_ic" if choice_id == "principal_track" else ("head_of" if choice_id == "grant_title" else "scope_accurate")
			candidate["title_model"] = title_model
			candidate["title_calibration_week"] = total_week
			if choice_id == "grant_title":
				candidate["role_title"] = "Head of %s" % str(candidate.get("role_title", "Platform"))
			elif choice_id == "principal_track":
				candidate["role_title"] = "Principal %s" % str(candidate.get("role_title", "IC"))
			var propagated := _propagate_candidate_title_terms(focus_id, str(candidate.get("role_title", "关键岗位")), title_model)
			return {
				"ok": true,
				"candidate_id": focus_id,
				"title_model": title_model,
				"role_title": candidate["role_title"],
				"opened_requisition": opened_requisition,
				"propagated_to": propagated,
			}
		"key_person_poach":
			if not operations.employees.has("chen_xiaoyu"):
				return {"ok": false, "reason": "employee_missing", "employee_id": "chen_xiaoyu"}
			var employee: Dictionary = operations.employees["chen_xiaoyu"]
			if choice_id == "match_package":
				employee["salary_annual"] = maxf(float(employee.get("salary_annual", 0.0)) * 1.12, 58.0)
				employee["flight_risk"] = maxf(0.0, float(employee.get("flight_risk", 0.0)) - 24.0)
			elif choice_id == "give_mandate":
				employee["mandate"] = "data_quality_owner"
				employee["growth_satisfaction"] = clampf(float(employee.get("growth_satisfaction", 50.0)) + 24.0, 0.0, 100.0)
				employee["flight_risk"] = maxf(0.0, float(employee.get("flight_risk", 0.0)) - 30.0)
			else:
				employee["mandate"] = "evidence_backplanned"
				employee["flight_risk"] = maxf(0.0, float(employee.get("flight_risk", 0.0)) - 28.0)
			return {"ok": true, "employee_id": "chen_xiaoyu", "flight_risk": employee["flight_risk"], "salary_annual": employee.get("salary_annual", 0.0), "mandate": employee.get("mandate", "")}
	return {"ok": false, "reason": "unknown_people_event", "event_id": event_id}


func _resolve_static_org_event(event_id: String, choice_id: String) -> Dictionary:
	match event_id:
		"first_manager_span":
			if not operations.employees.has("lin_yue"):
				return {"ok": false, "reason": "employee_missing", "employee_id": "lin_yue"}
			if choice_id == "cancel_one_on_ones":
				var manager: Dictionary = operations.employees["lin_yue"]
				manager["one_on_one_cadence"] = "biweekly"
				manager["calendar_recovered_hours"] = 10
				return {"ok": true, "employee_id": "lin_yue", "one_on_one_cadence": "biweekly"}
			return _resolve_runtime_operations_event("manager_overload:lin_yue", "redistribute" if choice_id == "appoint_acting_lead" else "delegate")
		"promotion_calibration":
			if not operations.employees.has("chen_xiaoyu"):
				return {"ok": false, "reason": "employee_missing", "employee_id": "chen_xiaoyu"}
			if choice_id == "defer_with_scope":
				return _ensure_employee_training("chen_xiaoyu", "management")
			var employee: Dictionary = operations.employees["chen_xiaoyu"]
			var refresh_bps := 8.0 if choice_id == "promote_on_judgment" else 6.0
			var promoted: Dictionary = operations.apply_decision("promote_employee", {"employee_id": "chen_xiaoyu", "level": int(employee.get("level", 1)) + 1, "salary": float(employee.get("salary_annual", 0.0)) * (1.10 if choice_id == "promote_on_judgment" else 1.08), "equity_refresh_bps": refresh_bps}, {"week": total_week})
			if bool(promoted.get("ok", false)):
				promoted["option_grant"] = _grant_equity_refresh("chen_xiaoyu", refresh_bps, "promotion_calibration")
			return promoted
		"mentor_burnout":
			if not operations.employees.has("guo_jun"):
				return {"ok": false, "reason": "employee_missing", "employee_id": "guo_jun"}
			var mentor: Dictionary = operations.employees["guo_jun"]
			if choice_id == "protect_mentor_time":
				mentor["burnout"] = maxf(0.0, float(mentor.get("burnout", 0.0)) - 24.0)
				mentor["protected_mentor_hours"] = 8
			elif choice_id == "rotate_mentors":
				mentor["burnout"] = maxf(0.0, float(mentor.get("burnout", 0.0)) - 14.0)
				mentor["mentor_rotation"] = true
			else:
				mentor["burnout"] = maxf(0.0, float(mentor.get("burnout", 0.0)) - 20.0)
				mentor["onboarding_playbook"] = true
			return {"ok": true, "employee_id": "guo_jun", "burnout": mentor["burnout"], "mentor_rotation": mentor.get("mentor_rotation", false), "onboarding_playbook": mentor.get("onboarding_playbook", false)}
	return {"ok": false, "reason": "unknown_org_event", "event_id": event_id}


func _resolve_static_saas_event(event_id: String, choice_id: String) -> Dictionary:
	var service_id := ""
	match event_id:
		"identity_plan_wall", "dormant_seat_audit", "automatic_renewal": service_id = "quietwire_annual"
		"ci_usage_overage": service_id = "forgenest_team"
		"vendor_outage_demo", "vendor_acquisition": service_id = "signalharbor_observe"
	if service_id.is_empty():
		return {"ok": false, "reason": "service_mapping_missing", "event_id": event_id}
	if event_id == "identity_plan_wall":
		if choice_id == "manual_controls":
			operations.office["manual_identity_review"] = true
			return {"ok": true, "service_id": service_id, "manual_controls": true}
		var subscribed := _ensure_subscription(service_id)
		if bool(subscribed.get("ok", false)) and operations.subscriptions.has(service_id) and choice_id == "delegate":
			operations.subscriptions[service_id]["price_protection"] = true
			operations.subscriptions[service_id]["minimum_seats_override"] = 30
		return subscribed
	if not operations.subscriptions.has(service_id):
		return {"ok": false, "reason": "subscription_missing", "service_id": service_id}
	var subscription: Dictionary = operations.subscriptions[service_id]
	var spec: Dictionary = subscription.get("spec", {})
	match event_id:
		"dormant_seat_audit":
			var removed := 0
			if choice_id != "leave_buffer":
				var assigned: Array = Array(subscription.get("assigned_users", [])).duplicate()
				for employee_id_value in assigned:
					var employee_id := str(employee_id_value)
					if not operations.employees.has(employee_id) or not bool(Dictionary(operations.employees[employee_id]).get("active", true)):
						operations.deprovision_user(service_id, employee_id)
						removed += 1
				subscription["seat_audit_completed_week"] = total_week
			return {"ok": true, "service_id": service_id, "deprovisioned": removed, "buffer_retained": choice_id == "leave_buffer"}
		"ci_usage_overage":
			var included := float(spec.get("included_usage", 0.0))
			if choice_id == "buy_commit":
				spec["included_usage"] = included * 1.60
				subscription["annual_usage_commit"] = true
			elif choice_id == "build_cache":
				subscription["usage"] = included * 0.72
				subscription["cache_project"] = true
			else:
				subscription["usage"] = included * 0.62
				subscription["workflow_optimized"] = true
			return {"ok": true, "service_id": service_id, "usage": subscription.get("usage", 0.0), "included_usage": spec.get("included_usage", 0.0), "weekly_cost": operations.subscription_weekly_cost(service_id)}
		"vendor_outage_demo":
			subscription["outage_response"] = "degraded_mode" if choice_id == "show_degraded" else ("delayed_demo" if choice_id == "delay_demo" else "local_evidence_rebuild")
			subscription["degraded_mode_tested"] = choice_id != "delay_demo"
			return {"ok": true, "service_id": service_id, "outage_response": subscription["outage_response"], "degraded_mode_tested": subscription["degraded_mode_tested"]}
		"automatic_renewal":
			if choice_id == "start_migration":
				return operations.apply_decision("cancel_saas", {"service_id": service_id}, {"week": total_week})
			subscription["renewal_week"] = int(subscription.get("renewal_week", total_week)) + (4 if choice_id == "negotiate_credit" else 13)
			subscription["renewal_credit_weeks"] = 2 if choice_id == "negotiate_credit" else 0
			subscription["price_protection"] = choice_id == "delegate"
			return {"ok": true, "service_id": service_id, "renewal_week": subscription["renewal_week"], "credit_weeks": subscription["renewal_credit_weeks"], "price_protection": subscription["price_protection"]}
		"vendor_acquisition":
			subscription["new_subprocessor"] = choice_id != "security_review"
			subscription["security_review_status"] = "complete" if choice_id in ["security_review", "delegate"] else "deferred"
			subscription["customer_notice_sent"] = choice_id in ["security_review", "delegate"]
			return {"ok": true, "service_id": service_id, "new_subprocessor": subscription["new_subprocessor"], "security_review_status": subscription["security_review_status"], "customer_notice_sent": subscription["customer_notice_sent"]}
	return {"ok": false, "reason": "unknown_saas_event", "event_id": event_id}


func _first_focus_candidate_id() -> String:
	for requisition_value in operations.requisitions:
		if not requisition_value is Dictionary:
			continue
		var requisition: Dictionary = requisition_value
		if str(requisition.get("status", "")) == "open" and not str(requisition.get("focus_candidate_id", "")).is_empty():
			return str(requisition.get("focus_candidate_id", ""))
	return ""


func _title_negotiation_candidate_id() -> String:
	var pending_id := _first_pending_offer_candidate_id()
	if not pending_id.is_empty() and operations.candidates.has(pending_id):
		return pending_id
	var focus_id := _first_focus_candidate_id()
	if not focus_id.is_empty():
		return focus_id
	var selected_id := ""
	var selected_week := -1
	var selected_index := -1
	for offer_index in operations.offers.size():
		var offer_value = operations.offers[offer_index]
		if not offer_value is Dictionary:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("status", "")) != "accepted":
			continue
		var candidate_id := str(offer.get("candidate_id", ""))
		if candidate_id.is_empty() or not operations.candidates.has(candidate_id):
			continue
		var resolved_week := int(offer.get("resolved_week", offer.get("issued_week", -1)))
		if resolved_week > selected_week or (resolved_week == selected_week and offer_index > selected_index):
			selected_id = candidate_id
			selected_week = resolved_week
			selected_index = offer_index
	return selected_id


func _propagate_candidate_title_terms(candidate_id: String, role_title: String, title_model: String) -> Array[String]:
	var propagated: Array[String] = ["candidate"]
	for offer_value in operations.offers:
		if not offer_value is Dictionary:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("candidate_id", "")) != candidate_id:
			continue
		var terms: Dictionary = Dictionary(offer.get("terms", {})).duplicate(true)
		terms["title"] = role_title
		terms["title_model"] = title_model
		terms["title_calibration_week"] = total_week
		offer["terms"] = terms
		if not propagated.has("offer"):
			propagated.append("offer")
	for join_queue in [operations.scheduled_joins, operations.pending_joins]:
		for join_value in join_queue:
			if not join_value is Dictionary:
				continue
			var join: Dictionary = join_value
			if str(join.get("candidate_id", "")) != candidate_id:
				continue
			var employee: Dictionary = Dictionary(join.get("employee", {})).duplicate(true)
			employee["role"] = role_title
			var employee_terms: Dictionary = Dictionary(employee.get("offer_terms", {})).duplicate(true)
			employee_terms["title"] = role_title
			employee_terms["title_model"] = title_model
			employee_terms["title_calibration_week"] = total_week
			employee["offer_terms"] = employee_terms
			join["employee"] = employee
			if not propagated.has("scheduled_join"):
				propagated.append("scheduled_join")
	var employee_id := "hire_%s" % candidate_id
	if operations.employees.has(employee_id):
		var operations_employee: Dictionary = operations.employees[employee_id]
		operations_employee["role"] = role_title
		operations_employee["title_model"] = title_model
		operations_employee["title_calibration_week"] = total_week
		propagated.append("operations_employee")
	for employee_value in employees:
		if not employee_value is Dictionary:
			continue
		var employee: Dictionary = employee_value
		if str(employee.get("id", "")) != employee_id:
			continue
		employee["role"] = role_title
		employee["title_model"] = title_model
		employee["title_calibration_week"] = total_week
		propagated.append("roster_employee")
		break
	return propagated


func _first_pending_offer_candidate_id() -> String:
	for offer_value in operations.offers:
		if offer_value is Dictionary and str(Dictionary(offer_value).get("status", "")) == "pending":
			return str(Dictionary(offer_value).get("candidate_id", ""))
	return ""


func _grant_equity_refresh(employee_id: String, equity_bps: float, source: String) -> Dictionary:
	var shares := int(round(float(business.fully_diluted_shares()) * maxf(0.0, equity_bps) / 10_000.0))
	if shares <= 0:
		return {"ok": true, "shares": 0}
	return business.grant_options("equity_refresh:%s:%s:%d" % [source, employee_id, total_week], employee_id, shares, 208, 52)


func _mark_competitor_event(competitor_id: String, event_id: String, choice_id: String = "") -> Dictionary:
	var competitors: Dictionary = business.market.get("competitors", {})
	if not competitors.has(competitor_id):
		return {"ok": false, "reason": "competitor_missing", "competitor_id": competitor_id}
	var competitor: Dictionary = competitors[competitor_id]
	competitor["last_strategy"] = event_id
	competitor["public_product_signal"] = event_id
	if event_id == "competitor_seed_round":
		if not bool(competitor.get("scripted_seed_recorded", false)):
			competitor["cash_usd"] = int(competitor.get("cash_usd", 0)) + 18_000_000
			competitor["financing_count"] = int(competitor.get("financing_count", 0)) + 1
			competitor["last_financing_week"] = total_week
			competitor["scripted_seed_recorded"] = true
		competitor["announced_funding_usd"] = 18_000_000
		competitor["stage"] = "seed"
		competitor["solvency"] = "operating"
		if choice_id == "protect_key_roles":
			business.market["talent_pressure_bp"] = clampi(int(business.market.get("talent_pressure_bp", 10_000)) + 120, 8_000, 20_000)
		elif choice_id == "sell_mission":
			business.market["category_demand"] = clampi(int(business.market.get("category_demand", 38)) + 3, 0, 100)
		else:
			competitor["hiring_brand"] = clampi(int(competitor.get("hiring_brand", 50)) - 2, 0, 100)
	elif event_id == "competitor_down_round":
		competitor["cash_usd"] = int(round(float(competitor.get("cash_usd", 0)) * 0.45))
		competitor["weekly_burn_usd"] = int(round(float(competitor.get("weekly_burn_usd", 0)) * 0.78))
		competitor["down_round"] = true
		competitor["solvency"] = "distressed"
		business.market["talent_pressure_bp"] = maxi(10_000, int(business.market.get("talent_pressure_bp", 10_000)) - (500 if choice_id == "reopen_candidates" else 250))
		if choice_id == "court_customers":
			business.market["category_demand"] = clampi(int(business.market.get("category_demand", 38)) + 4, 0, 100)
	elif event_id == "harbor_price_cut":
		business.market["price_pressure_bp"] = maxi(6500, int(business.market.get("price_pressure_bp", 10000)) - 500)
		if choice_id == "match_price":
			business.ledger["gross_margin_bp"] = maxi(5_000, int(business.ledger.get("gross_margin_bp", 8_000)) - 500)
		elif choice_id == "delegate":
			business.ledger["gross_margin_bp"] = maxi(5_000, int(business.ledger.get("gross_margin_bp", 8_000)) - 100)
	elif event_id == "morrow_benchmark":
		if choice_id == "rerun_comparable":
			business.market["regulatory_scrutiny"] = maxi(0, int(business.market.get("regulatory_scrutiny", 0)) - 2)
			business.policy["regulatory_credibility"] = clampi(int(business.policy.get("regulatory_credibility", 50)) + 4, 0, 100)
		elif choice_id == "question_scope":
			business.market["regulatory_scrutiny"] = clampi(int(business.market.get("regulatory_scrutiny", 0)) + 3, 0, 100)
		else:
			business.policy["public_trust"] = clampi(int(business.policy.get("public_trust", 50)) + 3, 0, 100)
	elif event_id == "chorus_release_collision":
		if choice_id == "ship_verified":
			business.market["regulatory_scrutiny"] = maxi(0, int(business.market.get("regulatory_scrutiny", 0)) - 1)
		elif choice_id == "ship_early":
			business.market["category_demand"] = clampi(int(business.market.get("category_demand", 38)) + 5, 0, 100)
			business.market["regulatory_scrutiny"] = clampi(int(business.market.get("regulatory_scrutiny", 0)) + 4, 0, 100)
		else:
			business.market["category_demand"] = clampi(int(business.market.get("category_demand", 38)) + 3, 0, 100)
	return {"ok": true, "competitor_id": competitor_id, "event_id": event_id, "choice_id": choice_id, "competitor": competitor.duplicate(true)}


func _resolve_shared_customer_trial(choice_id: String) -> Dictionary:
	var customer_gain := 1 if choice_id != "delegate" else 2
	var mrr_gain := 4_500 if choice_id == "differentiate_eval" else (6_000 if choice_id == "promise_roadmap" else 7_200)
	business.ledger["customer_count"] = int(business.ledger.get("customer_count", 0)) + customer_gain
	business.ledger["mrr_usd"] = int(business.ledger.get("mrr_usd", 0)) + mrr_gain
	business.ledger["contracted_arr_usd"] = int(business.ledger.get("contracted_arr_usd", 0)) + mrr_gain * 12
	business.market["category_demand"] = clampi(int(business.market.get("category_demand", 38)) + (2 if choice_id == "differentiate_eval" else 4), 0, 100)
	return {"ok": true, "market_change": "shared_customer_trial", "choice_id": choice_id, "customer_gain": customer_gain, "mrr_gain_usd": mrr_gain}


## Produces urgent, state-backed decisions from the two simulation subsystems.
## These are intentionally separate from the authored flavor catalog: every one
## of these candidates exists because a real deadline, contract, person, or
## policy milestone currently exists in the save.
func company_system_event_candidates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var business_context := _business_context("event_candidate:%d" % total_week)
	for value in business.event_candidates(business_context):
		if not value is Dictionary:
			continue
		var candidate: Dictionary = Dictionary(value).duplicate(true)
		candidate["id"] = "runtime_business:%s" % str(candidate.get("decision_id", ""))
		candidate["source_system"] = "business"
		candidate["family"] = str(candidate.get("domain", "business"))
		result.append(candidate)
	for value in operations.event_candidates({"week": total_week}):
		if not value is Dictionary:
			continue
		var candidate: Dictionary = Dictionary(value).duplicate(true)
		candidate["source_system"] = "operations"
		result.append(candidate)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var priority_a := int(a.get("priority", 0))
		var priority_b := int(b.get("priority", 0))
		return priority_a > priority_b if priority_a != priority_b else str(a.get("id", "")) < str(b.get("id", ""))
	)
	return result


func materialize_company_system_event(candidate: Dictionary) -> Dictionary:
	var source := str(candidate.get("source_system", ""))
	var event_id := str(candidate.get("id", ""))
	if event_id.is_empty():
		return {}
	var family := str(candidate.get("family", candidate.get("domain", "operations")))
	var reason := str(candidate.get("reason", "经营台账里有一项决定需要处理。"))
	var title := "经营台账需要一个决定"
	var kicker := "OPERATING INBOX · 状态触发"
	var body: Array = [reason]
	var choices: Array[Dictionary] = []
	var runtime_decision_id := str(candidate.get("decision_id", event_id))
	if source == "business":
		var business_copy := _materialize_business_candidate(runtime_decision_id)
		title = str(business_copy.get("title", title))
		kicker = str(business_copy.get("kicker", kicker))
		body = Array(business_copy.get("body", body)).duplicate()
		choices = _dictionary_choices(business_copy.get("choices", []))
	else:
		var operations_copy := _materialize_operations_candidate(event_id)
		title = str(operations_copy.get("title", title))
		kicker = str(operations_copy.get("kicker", kicker))
		body = Array(operations_copy.get("body", body)).duplicate()
		choices = _dictionary_choices(operations_copy.get("choices", []))
	return {
		"id": event_id,
		"family": family,
		"title": title,
		"kicker": kicker,
		"body": body,
		"choices": choices,
		"after": "",
		"_company_system_event": true,
		"_runtime_state_event": true,
		"_runtime_source_system": source,
		"_runtime_decision_id": runtime_decision_id,
		"_system_domain": family,
		"_system_decision_id": event_id,
		"_runtime_snapshot": candidate.duplicate(true),
	}


func _materialize_business_candidate(decision_id: String) -> Dictionary:
	var specs := {
		"raise_preseed": ["第一张 SAFE 进入签署窗口", "融资条款 · Post-money SAFE", ["clean", "接受标准条款", {"coherence": 2}, "金额、cap、pro rata 与稀释进入同一张 cap table。"], ["headline", "用治理权换 headline", {"narrative": 4}, "更高的对外数字伴随更重的控制条款。"], ["delegate", "让它完成红线", {"author_weight": 5}, "它完成条款比较、签署与投资人回执。"]],
		"raise_seed": ["Seed 条款表已经可签", "融资条款 · Priced round", ["clean", "选创始人友好条款", {"coherence": 2}, "交割金额、补池与董事权利一起入账。"], ["headline", "选更高 headline 估值", {"narrative": 5}, "估值更醒目，交割前补池也更大。"], ["delegate", "让它优化整套条款", {"author_weight": 6}, "它完成模型、红线与签署清单。"]],
		"raise_series_a": ["A 轮数据室通过最后检查", "融资条款 · Series A", ["clean", "保留经营控制", {"coherence": 3}, "交割现金与治理权按最终条款入账。"], ["headline", "最大化本轮估值", {"narrative": 6}, "更大的数字带来更明确的董事会约束。"], ["delegate", "让它完成交割", {"author_weight": 7}, "它关闭了所有 diligence item。"]],
		"apply_grant": ["研发补助开放申报", "政策扶持 · 非稀释资金", ["manual", "提交窄而可验收的范围", {"coherence": 3}, "申请按真实技术里程碑进入评审。"], ["skip", "本轮不申请", {"capability": 1}, "团队不承担申报与验收义务。"], ["delegate", "让它整理合格费用", {"author_weight": 4}, "它把工程计划映射成申报证据。"]],
		"complete_grant_milestone": ["研发补助里程碑到期", "政策扶持 · 验收", ["submit", "提交复现实验与费用凭证", {"coherence": 4}, "验收结果将决定尾款是否到账。"], ["delegate", "让它整理验收包", {"author_weight": 4}, "证据目录与费用凭证同步提交。"]],
		"tax_credit": ["岗位税收抵免进入承诺窗口", "政策扶持 · Deferred credit", ["accept", "接受审慎岗位承诺", {"coherence": 2}, "抵免先成为递延资产，不伪装成现金。"], ["decline", "保留用工弹性", {"capability": 1}, "公司不承担 clawback 条款。"], ["delegate", "让它校准承诺", {"author_weight": 3}, "承诺与现有招聘计划逐项核对。"]],
		"government_pilot": ["政府 pilot 开放投标", "公共采购 · 先交付后付款", ["bid", "缩小范围后投标", {"coherence": 3}, "安全、可访问性与审计日志进入验收表。"], ["decline", "不占用本轮交付能力", {"capability": 1}, "公司放弃合同，也不制造应收幻觉。"], ["delegate", "让它生成证据目录", {"author_weight": 4}, "现有产品被映射到采购要求。"]],
		"complete_pilot": ["政府 pilot 进入验收", "公共采购 · Delivery gate", ["deliver", "提交真实交付与审计证据", {"coherence": 4}, "只有验收通过后，合同款才进入现金。"], ["delegate", "让它完成验收包", {"author_weight": 5}, "它提交产品、日志与合规证据。"]],
		"public_comment": ["评测披露规则公开征求意见", "政策档案 · Public comment", ["strong_disclosure", "支持可复现披露", {"capability": 2}, "意见书把能力优势变成规则优势。"], ["industry_flexibility", "主张行业弹性", {"narrative": 3}, "协会会引用这套措辞。"], ["delegate", "让它起草标准", {"author_weight": 6}, "草案以公司现有流程为基线。"]],
		"industry_coalition": ["标准工作组邀请公司加入", "政务关系 · Coalition", ["join", "加入并公开议题", {"coherence": 2}, "公司获得席位，也承担会费与披露。"], ["decline", "保持独立", {"capability": 1}, "规则信息仍来自公开渠道。"], ["delegate", "让它管理工作组", {"author_weight": 5}, "会议、立场与披露由它持续维护。"]],
		"registered_lobbying": ["公司已能直接参与规则沟通", "政务关系 · Registered engagement", ["engage", "限定议题并登记", {"coherence": 3}, "费用与活动进入公开记录。"], ["decline", "培养内部政策能力", {"capability": 2}, "影响较慢，但没有外部顾问冲突。"], ["delegate", "让它限定授权", {"author_weight": 6}, "授权、披露与利益冲突检查同时完成。"]],
	}
	var spec: Array = Array(specs.get(decision_id, []))
	if spec.is_empty():
		return {}
	var choice_values: Array[Dictionary] = []
	for index in range(2, spec.size()):
		var choice_spec: Array = spec[index]
		choice_values.append({"id": str(choice_spec[0]), "label": str(choice_spec[1]), "effects": Dictionary(choice_spec[2]).duplicate(true), "result": [str(choice_spec[3])], "ai": str(choice_spec[0]) == "delegate"})
	return {"title": str(spec[0]), "kicker": str(spec[1]), "body": ["这是由当前账本状态触发的决定；金额、期限和后续义务会直接写回经营系统。"], "choices": choice_values}


func _materialize_operations_candidate(event_id: String) -> Dictionary:
	var parts := event_id.split(":", false, 1)
	var base_id := str(parts[0])
	var actor_id := str(parts[1]) if parts.size() > 1 else ""
	match base_id:
		"candidate_deadline":
			var candidate: Dictionary = operations.candidate_dossier(actor_id)
			return {"title": "%s 的另一份 offer 明天到期" % str(candidate.get("name", actor_id)), "kicker": "人才竞争 · %s" % str(candidate.get("competing_offer", {}).get("company", "竞争公司")), "body": ["%s，目前 %s。" % [str(candidate.get("role_title", "关键岗位")), str(candidate.get("interview_stage", "offer"))], "现金、scope 与汇报线会真实改变接受概率。"], "choices": _ops_choices([["protect_scope", "写入 scope review", {"coherence": 2}, "把六个月 scope review 写进 offer。"], ["increase_cash", "提高现金报价", {"cash_weeks": -1}, "报价上调，并进入持续工资成本。"], ["delegate", "让它重组整份 offer", {"author_weight": 4}, "它重新平衡 title、现金与汇报线。"]])}
		"manager_overload":
			var manager: Dictionary = operations.employees.get(actor_id, {})
			return {"title": "%s 的管理跨度已经超载" % str(manager.get("name", actor_id)), "kicker": "组织复盘 · Manager span", "body": ["直属人数超过当前管理容量；一对一和审批正在挤占交付。"], "choices": _ops_choices([["redistribute", "转移一条汇报线", {"coherence": 3}, "把一名成员转给另一位可用经理。"], ["train_manager", "安排管理训练", {"capability": 2}, "短期仍拥堵，管理能力会逐周提升。"], ["delegate", "让它重排组织", {"author_weight": 5}, "它选择最小冲突的汇报线调整。"]])}
		"flight_risk":
			var employee: Dictionary = operations.employees.get(actor_id, {})
			return {"title": "%s 已进入离职风险区间" % str(employee.get("name", actor_id)), "kicker": "人才保留 · 具体行动", "body": ["这不是一项全员 morale 数字；薪资、成长机会和经理关系会分别改变结果。"], "choices": _ops_choices([["career_plan", "给出成长项目与训练", {"coherence": 3}, "下一段 scope 与训练被写进计划。"], ["retention_cash", "做定向留任调整", {"cash_weeks": -1}, "工资成本上升，短期离职风险下降。"], ["delegate", "让它生成留任方案", {"author_weight": 5}, "它从记录中找出最具体的阻塞。"]])}
		"office_over_capacity":
			var office_choices: Array
			if _active_office_has_fitout("flex_desks"):
				office_choices = [["tolerate_crowding", "接受三周错峰办公", {"morale": -2}, "拥挤和复盘日期写入空间状态；这不是免费的容量。"], ["replace_lease", "启动扩张租约", {"cash_weeks": -2}, "押金与搬迁日期成为真实承诺。"], ["delegate", "让它比较过渡与搬迁", {"author_weight": 4}, "它不会重复购买已经完成的弹性工位。"]]
			else:
				office_choices = [["flex_desks", "加装弹性工位", {"morale": -1}, "装修工期、费用和新增容量进入租约台账。"], ["replace_lease", "启动扩张租约", {"cash_weeks": -2}, "押金与搬迁日期成为真实承诺。"], ["delegate", "让它比较两种方案", {"author_weight": 4}, "它按超容幅度选择可按时落地的方案。"]]
			return {"title": "在职人数已经超过合法工位", "kicker": "空间运营 · Capacity", "body": ["当前 %d 人 / %d 个工位。" % [operations.active_employee_count(), operations.office_capacity()]], "choices": _ops_choices(office_choices)}
		"saas_renewal":
			var subscription: Dictionary = operations.subscriptions.get(actor_id, {})
			var spec: Dictionary = subscription.get("spec", {})
			return {"title": "%s 进入续约窗口" % str(spec.get("name", actor_id)), "kicker": "采购台账 · Renewal", "body": ["续约周：%d；计费方式：%s。" % [int(subscription.get("renewal_week", 0)), str(spec.get("billing", spec.get("pricing_model", "weekly")))]], "choices": _ops_choices([["renew", "按现有规模续约", {"coherence": 1}, "续约义务继续进入采购台账。"], ["cancel", "关闭自动续约", {"capability": -1}, "服务按合同退出窗口进入 non-renewing。"], ["delegate", "让它谈短期保护", {"author_weight": 4}, "它保留服务，并缩短下一次退出窗口。"]])}
		"saas_overage":
			var overage_subscription: Dictionary = operations.subscriptions.get(actor_id, {})
			var overage_spec: Dictionary = overage_subscription.get("spec", {})
			return {"title": "%s 已进入超额计费" % str(overage_spec.get("name", actor_id)), "kicker": "采购台账 · Usage", "body": ["当前用量 %.0f / 包含 %.0f。" % [float(overage_subscription.get("usage", 0.0)), float(overage_spec.get("included_usage", 0.0))]], "choices": _ops_choices([["cap_usage", "限制非关键用量", {"narrative": -1}, "用量回到承诺内，部分工作会排队。"], ["accept_overage", "接受本周期超额", {"cash_weeks": -1}, "真实超额费用保留在周成本。"], ["delegate", "让它优化工作流", {"author_weight": 4}, "缓存与采样把用量压到阈值附近。"]])}
	return {}


func _ops_choices(specs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in specs:
		var spec: Array = value
		result.append({"id": str(spec[0]), "label": str(spec[1]), "effects": Dictionary(spec[2]).duplicate(true), "result": [str(spec[3])], "ai": str(spec[0]) == "delegate"})
	return result


func _dictionary_choices(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in Array(value):
			if item is Dictionary:
				result.append(Dictionary(item).duplicate(true))
	return result


func system_actor_snapshots() -> Dictionary:
	var result: Dictionary = {}
	for investor_value in business.investor_public_state():
		if not investor_value is Dictionary:
			continue
		var investor: Dictionary = investor_value
		var investor_id := str(investor.get("id", ""))
		result[investor_id] = investor.duplicate(true)
		if investor_id == "juniper_ventures":
			result["maya_chen"] = investor.duplicate(true)
	var market_state: Dictionary = Dictionary(business.public_state().get("market", {}))
	for competitor_value in Array(market_state.get("competitors", [])):
		if not competitor_value is Dictionary:
			continue
		var competitor: Dictionary = competitor_value
		var competitor_id := str(competitor.get("id", ""))
		result[competitor_id] = competitor.duplicate(true)
		if competitor_id == "morrow_ai":
			result["morrow"] = competitor.duplicate(true)
		elif competitor_id == "chorus_systems":
			result["chorus"] = competitor.duplicate(true)
		elif competitor_id == "harbor_desk":
			result["harbor"] = competitor.duplicate(true)
	return result


func observe_story_event(event_id: String, choice_id: String = "", _event: Dictionary = {}) -> void:
	match event_id:
		"real_office":
			_advance_office_plan("canal_sublease")
		"office_expansion":
			_advance_office_plan("frostline_works")
	memory["last_story_event_observed"] = {"id": event_id, "choice_id": choice_id, "week": total_week}


func _role_family_for_title(title: String) -> String:
	var normalized := title.to_lower()
	if normalized.contains("创始") or normalized.contains("cto"):
		return "management"
	if normalized.contains("安全") or normalized.contains("security"):
		return "security"
	if normalized.contains("研究") or normalized.contains("评测") or normalized.contains("research") or normalized.contains("eval"):
		return "research"
	if normalized.contains("数据") or normalized.contains("data"):
		return "data"
	if normalized.contains("设计") or normalized.contains("design") or normalized.contains("前端"):
		return "design"
	if normalized.contains("产品") or normalized.contains("product"):
		return "product"
	if normalized.contains("商务") or normalized.contains("销售") or normalized.contains("sales") or normalized.contains("客户"):
		return "sales"
	if normalized.contains("人才") or normalized.contains("运营") or normalized.contains("people") or normalized.contains("hr"):
		return "people"
	return "infrastructure"


func _team_for_role(title_or_family: String) -> String:
	var family := title_or_family if HiringOperationsSystemScript.ROLE_SCORECARDS.has(title_or_family) else _role_family_for_title(title_or_family)
	match family:
		"management": return "founders"
		"research": return "research"
		"product", "design": return "product"
		"sales": return "commercial"
		"people": return "operations"
		_: return "platform"


func _fundraising_cash_gain(story_value: float) -> float:
	# Deliberately does not read capability, coherence, debt, team, or compute.
	if story_value < 20.0:
		return 0.0
	return 4.0 + floorf(story_value / 15.0)


func _roll_action_range(minimum: int, maximum: int) -> float:
	var span := maximum - minimum + 1
	var rolled := minimum + posmod(rng_state, span)
	_advance_rng()
	return float(rolled)


func _roll_probability(probability: float) -> bool:
	var normalized := float(rng_state - 1) / float(RNG_MODULUS - 1)
	_advance_rng()
	return normalized < clampf(probability, 0.0, 1.0)


func _advance_rng() -> void:
	rng_state = int((rng_state * RNG_MULTIPLIER) % RNG_MODULUS)
	if rng_state <= 0:
		rng_state = RNG_INITIAL_STATE


func _attention_cost(_action_id: String) -> int:
	return 1


func _add_numeric_effect(effects: Dictionary, key: String, amount: float) -> void:
	effects[key] = float(effects.get(key, 0.0)) + amount


func _increment_action_memory(action_id: String, used_ai: bool) -> void:
	var counts: Dictionary = Dictionary(memory.get("action_counts", {})).duplicate(true)
	counts[action_id] = int(counts.get(action_id, 0)) + 1
	memory["action_counts"] = counts
	memory["last_action"] = action_id
	memory["last_action_used_ai"] = used_ai
	if not used_ai and action_id in ["train", "large_train"]:
		manual_training_count += 1


func _ai_author_gain(action_id: String) -> float:
	var action_value = HiringContentScript.ACTIONS.get(action_id, HiringExpansionContentScript.SYSTEM_ACTIONS.get(action_id, {}))
	if not action_value is Dictionary:
		return 0.0
	var ai_effects_value = Dictionary(action_value).get("ai_effects", {})
	if not ai_effects_value is Dictionary:
		return 0.0
	return maxf(0.0, float(Dictionary(ai_effects_value).get("author_weight", 0.0)))


func _manual_training_count_from_history() -> int:
	var count := 0
	for entry_value in history:
		var entry: Dictionary = entry_value
		if str(entry.get("kind", "")) != "action":
			continue
		var payload: Dictionary = Dictionary(entry.get("payload", {}))
		if str(payload.get("action_id", "")) in ["train", "large_train"] and not bool(payload.get("used_ai", false)):
			count += 1
	return count


func _refresh_company_morale() -> void:
	if employees.is_empty():
		morale = clampf(morale, 0.0, 100.0)
		return
	var total := 0.0
	for employee in employees:
		total += float(employee.get("morale", 50.0))
	morale = clampf(total / float(employees.size()), 0.0, 100.0)


func _record_history(kind: String, payload: Dictionary = {}) -> void:
	history.append({
		"kind": kind,
		"chapter": chapter,
		"week_in_chapter": week_in_chapter,
		"total_week": total_week,
		"payload": payload.duplicate(true)
	})


func _mechanical_snapshot() -> Dictionary:
	return {
		"cash_weeks": cash_weeks,
		"compute": compute,
		"narrative": narrative,
		"capability": capability,
		"coherence": coherence,
		"debt": debt,
		"author_weight": author_weight,
		"morale": morale,
		"attention": attention,
		"team_size": 1 + employees.size()
	}


func _failure(reason: String, action_id: String = "") -> Dictionary:
	return {
		"ok": false,
		"reason": reason,
		"action_id": action_id,
		"state": public_state()
	}
