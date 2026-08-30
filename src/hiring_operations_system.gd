class_name HiringOperationsSystem
extends RefCounted

## Deterministic, independently serializable operations vertical slice.
##
## This system never inserts or removes employees from HiringModel. Accepted
## candidates finish their notice period in `scheduled_joins`, then become
## consumable records in `pending_joins`. The owning model remains the sole
## authority that turns those records into formal employees and confirms the
## result through sync_employee_roster().

const SAVE_VERSION := 1
const RNG_INITIAL_STATE := 104729
const RNG_MODULUS := 2147483647
const RNG_MULTIPLIER := 48271
const BENEFITS_RATE := 0.18
const WEEKS_PER_YEAR := 52.0
const MAX_INTERVIEW_SCORE := 5.0
const RELEASED_CANDIDATE_COOLDOWN_WEEKS := 3

const INTERVIEW_STAGES := ["screen", "work_sample", "panel"]
const PROTECTED_ATTRIBUTE_KEYS := [
	"age", "birth_date", "gender", "sex", "ethnicity", "race", "religion",
	"marital_status", "family_status", "pregnancy", "disability",
]

const ROLE_SCORECARDS: Dictionary = {
	"infrastructure": [
		{"id": "systems_depth", "label": "系统深度", "weight": 0.40, "stage": "work_sample"},
		{"id": "incident_judgment", "label": "事故判断", "weight": 0.30, "stage": "panel"},
		{"id": "clear_communication", "label": "清晰沟通", "weight": 0.15, "stage": "screen"},
		{"id": "team_leverage", "label": "团队杠杆", "weight": 0.15, "stage": "panel"},
	],
	"research": [
		{"id": "research_depth", "label": "研究深度", "weight": 0.40, "stage": "work_sample"},
		{"id": "experimental_rigor", "label": "实验严谨", "weight": 0.30, "stage": "work_sample"},
		{"id": "clear_communication", "label": "清晰沟通", "weight": 0.15, "stage": "screen"},
		{"id": "collaboration", "label": "协作", "weight": 0.15, "stage": "panel"},
	],
	"product": [
		{"id": "product_judgment", "label": "产品判断", "weight": 0.35, "stage": "work_sample"},
		{"id": "customer_evidence", "label": "客户证据", "weight": 0.25, "stage": "panel"},
		{"id": "clear_communication", "label": "清晰沟通", "weight": 0.20, "stage": "screen"},
		{"id": "execution", "label": "落地能力", "weight": 0.20, "stage": "panel"},
	],
	"data": [
		{"id": "data_systems", "label": "数据系统", "weight": 0.40, "stage": "work_sample"},
		{"id": "quality_judgment", "label": "质量判断", "weight": 0.25, "stage": "panel"},
		{"id": "clear_communication", "label": "清晰沟通", "weight": 0.15, "stage": "screen"},
		{"id": "execution", "label": "落地能力", "weight": 0.20, "stage": "panel"},
	],
	"security": [
		{"id": "security_depth", "label": "安全深度", "weight": 0.40, "stage": "work_sample"},
		{"id": "risk_judgment", "label": "风险判断", "weight": 0.30, "stage": "panel"},
		{"id": "clear_communication", "label": "清晰沟通", "weight": 0.15, "stage": "screen"},
		{"id": "response_discipline", "label": "响应纪律", "weight": 0.15, "stage": "panel"},
	],
	"design": [
		{"id": "design_craft", "label": "设计工艺", "weight": 0.35, "stage": "work_sample"},
		{"id": "product_judgment", "label": "产品判断", "weight": 0.25, "stage": "panel"},
		{"id": "clear_communication", "label": "清晰沟通", "weight": 0.20, "stage": "screen"},
		{"id": "systems_thinking", "label": "系统思考", "weight": 0.20, "stage": "panel"},
	],
	"sales": [
		{"id": "commercial_judgment", "label": "商业判断", "weight": 0.35, "stage": "work_sample"},
		{"id": "customer_trust", "label": "客户信任", "weight": 0.30, "stage": "panel"},
		{"id": "clear_communication", "label": "清晰沟通", "weight": 0.20, "stage": "screen"},
		{"id": "forecast_discipline", "label": "预测纪律", "weight": 0.15, "stage": "panel"},
	],
	"people": [
		{"id": "people_judgment", "label": "人才判断", "weight": 0.35, "stage": "work_sample"},
		{"id": "process_design", "label": "流程设计", "weight": 0.25, "stage": "panel"},
		{"id": "clear_communication", "label": "清晰沟通", "weight": 0.20, "stage": "screen"},
		{"id": "confidentiality", "label": "保密判断", "weight": 0.20, "stage": "panel"},
	],
}

const CANDIDATE_TEMPLATES: Dictionary = {
	"zhou_cen": {
		"id": "zhou_cen", "name": "周岑", "role_family": "infrastructure", "role_title": "资深基础设施工程师",
		"current_company": "霜桥云", "current_title": "平台可靠性负责人", "years_experience": 7,
		"location": "杭州", "notice_weeks": 4, "salary_target": 58.0, "equity_target_bps": 18.0,
		"skill_evidence": ["把三套训练集群收敛为一套可追溯调度系统", "主导过两次跨区域故障复盘，保留原始时间线"],
		"unknowns": ["从未在十人以下公司工作", "是否愿意承担长期值班"],
		"actual_skills": {"engineering": 9.1, "operations": 8.8, "management": 6.2, "communication": 6.8},
		"mission_interest": 0.70, "scope_interest": 0.82, "manager_preference": 0.62, "risk_tolerance": 0.58,
		"competing_offer": {"company": "曜石算力", "salary": 61.0, "equity_bps": 8.0, "deadline_week": 4},
		"interview_quotes": {"screen": "我不介意慢，但每次慢都要能解释。", "work_sample": "先把失败路径画出来，再谈吞吐。", "panel": "我愿意值班，不愿意替没有预算的系统假装稳定。"},
	},
	"qiao_nian": {
		"id": "qiao_nian", "name": "乔念", "role_family": "research", "role_title": "研究科学家",
		"current_company": "纸鸢模型", "current_title": "多模态研究员", "years_experience": 5,
		"location": "北京", "notice_weeks": 4, "salary_target": 64.0, "equity_target_bps": 24.0,
		"skill_evidence": ["公开了一个负结果数据集并写清失败边界", "将离线评测与线上投诉样本建立可回放映射"],
		"unknowns": ["交付节奏是否适合产品团队", "对管理职责没有明确意愿"],
		"actual_skills": {"research": 9.4, "evaluation": 9.0, "engineering": 7.1, "communication": 7.3},
		"mission_interest": 0.86, "scope_interest": 0.78, "manager_preference": 0.70, "risk_tolerance": 0.67,
		"competing_offer": {"company": "曙潮智能", "salary": 66.0, "equity_bps": 12.0, "deadline_week": 5},
		"interview_quotes": {"screen": "我想知道你们保留了多少失败样本。", "work_sample": "这个提升只在过滤后的切片里成立。", "panel": "论文可以晚，错误结论不能早。"},
	},
	"cai_he": {
		"id": "cai_he", "name": "蔡禾", "role_family": "product", "role_title": "高级产品经理",
		"current_company": "南窗协作", "current_title": "工作流产品负责人", "years_experience": 6,
		"location": "上海", "notice_weeks": 3, "salary_target": 50.0, "equity_target_bps": 14.0,
		"skill_evidence": ["把七类客户请求压成两个可验证工作流", "连续六个月亲自主持流失客户访谈"],
		"unknowns": ["对研究不确定性的容忍度", "能否在没有销售承诺时拒绝客户"],
		"actual_skills": {"product": 8.9, "customer": 8.6, "execution": 8.1, "communication": 8.4},
		"mission_interest": 0.76, "scope_interest": 0.88, "manager_preference": 0.68, "risk_tolerance": 0.61,
		"competing_offer": {"company": "刻度云", "salary": 52.0, "equity_bps": 7.0, "deadline_week": 4},
		"interview_quotes": {"screen": "先让我看三个真的用户，不看画像。", "work_sample": "需求里最危险的是已经被销售写成完成时的那句。", "panel": "我可以说不，但需要你在客户面前也说不。"},
	},
	"duan_qiu": {
		"id": "duan_qiu", "name": "段秋", "role_family": "data", "role_title": "数据平台工程师",
		"current_company": "澄池数据", "current_title": "数据质量工程师", "years_experience": 4,
		"location": "深圳", "notice_weeks": 2, "salary_target": 44.0, "equity_target_bps": 16.0,
		"skill_evidence": ["为两百余条数据链路建立 owner 与 freshness 预算", "曾因指标口径不完整阻止季度报表发布"],
		"unknowns": ["大型训练数据经验较少", "尚未带过新人"],
		"actual_skills": {"data": 9.0, "engineering": 7.8, "quality": 9.2, "communication": 6.5},
		"mission_interest": 0.80, "scope_interest": 0.74, "manager_preference": 0.60, "risk_tolerance": 0.72,
		"competing_offer": {"company": "微澜数据库", "salary": 45.0, "equity_bps": 9.0, "deadline_week": 3},
		"interview_quotes": {"screen": "如果没人承认拥有一张表，那张表就不该进训练。", "work_sample": "这不是脏数据，是没有责任人的数据。", "panel": "我希望入职后先修 lineage，不先做漂亮看板。"},
	},
	"shen_mo": {
		"id": "shen_mo", "name": "沈墨", "role_family": "security", "role_title": "安全工程负责人",
		"current_company": "栈桥安全", "current_title": "云安全架构师", "years_experience": 8,
		"location": "成都", "notice_weeks": 4, "salary_target": 60.0, "equity_target_bps": 20.0,
		"skill_evidence": ["主导身份系统最小权限改造并完成全员迁移", "披露过供应商 token 泄漏且推动客户通知"],
		"unknowns": ["在资源紧张时的取舍方式", "是否接受兼任 IT"],
		"actual_skills": {"security": 9.3, "risk": 9.0, "operations": 7.4, "communication": 7.8},
		"mission_interest": 0.73, "scope_interest": 0.72, "manager_preference": 0.75, "risk_tolerance": 0.48,
		"competing_offer": {"company": "界碑系统", "salary": 63.0, "equity_bps": 10.0, "deadline_week": 5},
		"interview_quotes": {"screen": "安全评审可以快，不能假装已经做过。", "work_sample": "先撤销这把永久钥匙。", "panel": "如果通知客户会伤害叙事，那就让叙事受伤。"},
	},
	"yu_ting": {
		"id": "yu_ting", "name": "俞汀", "role_family": "design", "role_title": "产品设计师",
		"current_company": "雾港工具", "current_title": "设计系统负责人", "years_experience": 6,
		"location": "苏州", "notice_weeks": 3, "salary_target": 47.0, "equity_target_bps": 15.0,
		"skill_evidence": ["维护跨三产品的设计 token 与可访问性规范", "删掉一整套无法解释业务状态的动效"],
		"unknowns": ["是否愿意承担品牌工作", "对创始人直接改稿的容忍度"],
		"actual_skills": {"design": 9.2, "product": 7.9, "systems": 8.7, "communication": 7.6},
		"mission_interest": 0.79, "scope_interest": 0.84, "manager_preference": 0.66, "risk_tolerance": 0.63,
		"competing_offer": {"company": "折光界面", "salary": 49.0, "equity_bps": 8.0, "deadline_week": 4},
		"interview_quotes": {"screen": "我想先看错误状态，不看首页。", "work_sample": "用户需要知道系统没听懂，不需要更顺的等待。", "panel": "品牌可以冷，但不能没有人。"},
	},
	"liang_wei": {
		"id": "liang_wei", "name": "梁惟", "role_family": "sales", "role_title": "企业业务负责人",
		"current_company": "刻度云", "current_title": "战略客户总监", "years_experience": 9,
		"location": "上海", "notice_weeks": 4, "salary_target": 56.0, "equity_target_bps": 12.0,
		"skill_evidence": ["连续四季预测误差低于一成", "主动放弃过一个需要虚构交付日期的大单"],
		"unknowns": ["从成熟销售体系转向早期公司的适应性", "对低客单价客户的耐心"],
		"actual_skills": {"sales": 9.1, "customer": 8.9, "forecast": 8.8, "management": 7.5},
		"mission_interest": 0.68, "scope_interest": 0.86, "manager_preference": 0.64, "risk_tolerance": 0.55,
		"competing_offer": {"company": "北岬软件", "salary": 59.0, "equity_bps": 6.0, "deadline_week": 5},
		"interview_quotes": {"screen": "我可以卖路线图，不能卖假装已经上线的路线图。", "work_sample": "这单的赢率不是八成，是没人敢改成四成。", "panel": "我会替工程挡客户，也需要工程给我真实日期。"},
	},
	"bai_lu": {
		"id": "bai_lu", "name": "白露", "role_family": "people", "role_title": "人才与组织负责人",
		"current_company": "折线人才", "current_title": "人才运营负责人", "years_experience": 7,
		"location": "北京", "notice_weeks": 3, "salary_target": 48.0, "equity_target_bps": 14.0,
		"skill_evidence": ["为四十人公司建立岗位 scorecard 与薪酬 band", "在一次重组中保留了每个岗位变更的书面理由"],
		"unknowns": ["是否能独立处理高压离职", "对极速扩张的容忍度"],
		"actual_skills": {"people": 9.0, "process": 8.8, "management": 8.1, "communication": 8.7},
		"mission_interest": 0.82, "scope_interest": 0.80, "manager_preference": 0.78, "risk_tolerance": 0.57,
		"competing_offer": {"company": "方格组织", "salary": 50.0, "equity_bps": 7.0, "deadline_week": 4},
		"interview_quotes": {"screen": "我先看组织图，再看招聘计划。", "work_sample": "这个岗位写的是负责人，预算却只够执行者。", "panel": "流程不是为了让决定没有作者。"},
	},
}

const OFFICE_LEASE_CATALOG: Dictionary = {
	"harbor_desk": {
		"id": "harbor_desk", "name": "雾港联合工位", "kind": "coworking", "capacity": 8,
		"legal_capacity": 10, "deposit": 0.6, "weekly_rent": 0.42, "term_weeks": 13,
		"fitout_allowance": 0.0, "move_in_weeks": 0, "commute_score": 0.82, "prestige": 0.38,
	},
	"canal_sublease": {
		"id": "canal_sublease", "name": "北渠转租层", "kind": "sublease", "capacity": 24,
		"legal_capacity": 28, "deposit": 2.4, "weekly_rent": 1.08, "term_weeks": 26,
		"fitout_allowance": 1.2, "move_in_weeks": 1, "commute_score": 0.70, "prestige": 0.61,
	},
	"frostline_works": {
		"id": "frostline_works", "name": "霜线工场", "kind": "direct", "capacity": 48,
		"legal_capacity": 56, "deposit": 6.0, "weekly_rent": 2.14, "term_weeks": 52,
		"fitout_allowance": 3.0, "move_in_weeks": 3, "commute_score": 0.63, "prestige": 0.84,
	},
}

const FITOUT_CATALOG: Dictionary = {
	"acoustic_pods": {"id": "acoustic_pods", "name": "声学小间", "cost": 1.6, "duration_weeks": 2, "capacity_delta": -2, "focus": 0.12},
	"training_room": {"id": "training_room", "name": "培训室", "cost": 1.2, "duration_weeks": 2, "capacity_delta": -3, "training_speed": 0.25},
	"demo_room": {"id": "demo_room", "name": "客户演示间", "cost": 1.8, "duration_weeks": 3, "capacity_delta": -4, "prestige": 0.10},
	"flex_desks": {"id": "flex_desks", "name": "弹性工位", "cost": 0.9, "duration_weeks": 1, "capacity_delta": 6, "workspace_strain": 0.08},
}

const SAAS_CATALOG: Dictionary = {
	"forgenest_team": {
		"id": "forgenest_team", "name": "铸巢代码台", "category": "code", "pricing_model": "per_seat",
		"billing": "weekly", "unit_weekly": 0.018, "minimum_seats": 3, "term_weeks": 13,
		"included_usage": 3000.0, "overage_unit": 0.00002, "auto_provision": true,
	},
	"quietwire_annual": {
		"id": "quietwire_annual", "name": "静线协作", "category": "collaboration", "pricing_model": "per_seat",
		"billing": "annual_prepaid", "unit_weekly": 0.012, "minimum_seats": 5, "term_weeks": 52,
		"included_usage": 0.0, "overage_unit": 0.0, "auto_provision": true,
	},
	"signalharbor_observe": {
		"id": "signalharbor_observe", "name": "信港观测", "category": "observability", "pricing_model": "usage",
		"billing": "weekly", "minimum_weekly": 0.12, "base_weekly": 0.05, "term_weeks": 13,
		"included_usage": 100.0, "overage_unit": 0.002, "auto_provision": false,
	},
	"staffloom_core": {
		"id": "staffloom_core", "name": "人织名册", "category": "hris", "pricing_model": "per_seat",
		"billing": "weekly", "unit_weekly": 0.025, "minimum_seats": 10, "term_weeks": 26,
		"included_usage": 0.0, "overage_unit": 0.0, "auto_provision": true,
	},
}

var current_week := 1
var rng_state := RNG_INITIAL_STATE
var requisitions: Array = []
var candidates: Dictionary = {}
var offers: Array = []
var scheduled_joins: Array = []
var pending_joins: Array = []
var employees: Dictionary = {}
var teams: Dictionary = {}
var trainings: Array = []
var office: Dictionary = {}
var subscriptions: Dictionary = {}
var commitments: Array = []
var event_cooldowns: Dictionary = {}
var history: Array = []
var week_cash_outlays: Dictionary = {}
var week_cash_outlay_records: Dictionary = {}


func _init(seed: int = RNG_INITIAL_STATE) -> void:
	reset(seed)


func reset(seed: int = RNG_INITIAL_STATE) -> void:
	current_week = 1
	rng_state = maxi(1, seed)
	requisitions = []
	candidates = {}
	for candidate_id_value in CANDIDATE_TEMPLATES:
		var candidate_id := str(candidate_id_value)
		candidates[candidate_id] = _make_runtime_candidate(Dictionary(CANDIDATE_TEMPLATES[candidate_id]))
	offers = []
	scheduled_joins = []
	pending_joins = []
	employees = {}
	teams = {
		"founders": {"id": "founders", "name": "创始团队", "manager_id": "", "member_ids": []},
	}
	trainings = []
	office = {
		"active_lease": {}, "signed_lease": {}, "completed_fitouts": [], "fitouts_in_progress": [],
		"lease_history": [], "workspace_strain": 0.0,
	}
	subscriptions = {}
	commitments = []
	event_cooldowns = {}
	history = []
	week_cash_outlays = {}
	week_cash_outlay_records = {}
	_record_history("operations_reset", {"seed": rng_state})


func apply_decision(decision_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	if context.has("week"):
		current_week = maxi(current_week, int(context.get("week", current_week)))
	var result: Dictionary
	match decision_id:
		"open_requisition": result = _open_requisition(payload)
		"interview_candidate": result = _interview_candidate(payload)
		"issue_offer": result = _issue_offer(payload, context)
		"create_team": result = _create_team(payload)
		"set_manager": result = _set_manager(payload)
		"transfer_employee": result = _transfer_employee(payload)
		"start_training": result = _start_training(payload)
		"promote_employee": result = _promote_employee(payload)
		"sign_office_lease": result = _sign_office_lease(payload)
		"replace_office_lease": result = _replace_office_lease(payload)
		"start_fitout": result = _start_fitout(payload)
		"subscribe_saas": result = _subscribe_saas(payload)
		"cancel_saas": result = _cancel_saas(payload)
		"provision_saas": result = provision_user(str(payload.get("service_id", "")), str(payload.get("employee_id", "")))
		"deprovision_saas": result = deprovision_user(str(payload.get("service_id", "")), str(payload.get("employee_id", "")))
		"report_saas_usage": result = _report_saas_usage(payload)
		"acknowledge_event": result = _acknowledge_event(payload)
		_: result = _failure("unknown_decision", decision_id)
	if bool(result.get("ok", false)):
		_rebuild_commitments()
		_record_history("decision", {"decision_id": decision_id, "payload": _safe_public_payload(payload)})
	return result


func tick_week(context: Dictionary = {}) -> Dictionary:
	var target_week := int(context.get("week", current_week + 1))
	if target_week <= current_week:
		return _failure("week_must_advance")
	var start_week := current_week
	var outcomes: Array = []
	while current_week < target_week:
		current_week += 1
		week_cash_outlays[str(current_week)] = 0.0
		week_cash_outlay_records[str(current_week)] = []
		outcomes.append_array(_refresh_released_candidates())
		outcomes.append_array(_resolve_due_offers(context))
		outcomes.append_array(_expire_due_focus_candidates())
		outcomes.append_array(_release_due_joins())
		outcomes.append_array(_advance_onboarding())
		outcomes.append_array(_advance_trainings())
		outcomes.append_array(_advance_office())
		outcomes.append_array(_advance_subscriptions())
		_update_people_risk()
		_record_history("operations_week_tick", {"outcomes": outcomes.duplicate(true)})
	_rebuild_commitments()
	var cash_outlays := _cash_outlays_between(start_week + 1, current_week)
	var cash_outlay_total := 0.0
	for outlay_value in cash_outlays:
		cash_outlay_total += float(Dictionary(outlay_value).get("amount", 0.0))
	var burn := burn_summary()
	return {
		"ok": true,
		"week": current_week,
		"outcomes": outcomes,
		"pending_join_count": pending_joins.size(),
		"events": event_candidates(context),
		"burn": burn,
		"cash_outlays": cash_outlays,
		"cash_outlay_total": cash_outlay_total,
		"pnl_expense": {
			"basis": "weekly_accrual",
			"weekly_total": float(burn.get("total_weekly", 0.0)),
			"saas_weekly": float(burn.get("saas", 0.0)),
		},
		"commitment_changes": _commitment_changes_from_outcomes(outcomes),
	}


func sync_employee_roster(roster: Array, week: int = -1) -> Dictionary:
	if week > 0:
		current_week = maxi(current_week, week)
	var seen: Dictionary = {}
	var added: Array[String] = []
	var deactivated: Array[String] = []
	for employee_value in roster:
		if not employee_value is Dictionary:
			continue
		var source: Dictionary = employee_value
		var employee_id := str(source.get("id", ""))
		if employee_id.is_empty():
			continue
		seen[employee_id] = true
		if not employees.has(employee_id):
			employees[employee_id] = _make_operations_employee(source)
			added.append(employee_id)
		else:
			_merge_roster_employee(Dictionary(employees[employee_id]), source)
		var record: Dictionary = employees[employee_id]
		record["active"] = true
		if str(record.get("team_id", "")).is_empty():
			record["team_id"] = "founders"
		_ensure_team_membership(employee_id, str(record.get("team_id", "founders")))
	for employee_id_value in employees.keys():
		var employee_id := str(employee_id_value)
		var record: Dictionary = employees[employee_id]
		if bool(record.get("active", true)) and not seen.has(employee_id):
			record["active"] = false
			record["departure_week"] = current_week
			deactivated.append(employee_id)
			_remove_from_all_teams(employee_id)
			for service_id_value in subscriptions:
				deprovision_user(str(service_id_value), employee_id)
	_auto_provision_active_roster()
	_rebuild_commitments()
	_record_history("roster_synced", {"added": added, "deactivated": deactivated, "formal_count": roster.size()})
	return {"ok": true, "added": added, "deactivated": deactivated, "active_count": active_employee_count()}


func consume_pending_joins() -> Array:
	var ready := pending_joins.duplicate(true)
	# Settle every operations-owned side of the boundary before exposing the
	# consumed records. The model still owns formal roster insertion, but a
	# consumed join can no longer remain visible in the candidate funnel.
	for join_value in ready:
		if not join_value is Dictionary:
			continue
		var join: Dictionary = join_value
		var candidate_id := str(join.get("candidate_id", ""))
		var requisition_id := str(join.get("requisition_id", ""))
		if requisition_id.is_empty():
			requisition_id = _requisition_id_for_offer(str(join.get("offer_id", "")))
		if candidates.has(candidate_id):
			var candidate: Dictionary = candidates[candidate_id]
			candidate["status"] = "hired"
			candidate["hired_week"] = current_week
			candidate["last_requisition_id"] = requisition_id
			candidate["requisition_id"] = ""
		var requisition_index := _find_requisition(requisition_id)
		if requisition_index >= 0:
			var requisition: Dictionary = requisitions[requisition_index]
			requisition["status"] = "filled"
			requisition["filled_week"] = current_week
			requisition["selected_candidate_id"] = candidate_id
			requisition["focus_candidate_id"] = ""
			_cleanup_requisition_funnel(requisition, candidate_id, "hire_consumed")
		join["consumed_week"] = current_week
		join["requisition_id"] = requisition_id
	pending_joins.clear()
	_rebuild_commitments()
	_record_history("pending_joins_consumed", {"count": ready.size()})
	return ready


func candidate_dossier(candidate_id: String) -> Dictionary:
	if not candidates.has(candidate_id):
		return {}
	var candidate: Dictionary = candidates[candidate_id]
	return {
		"id": candidate_id,
		"name": str(candidate.get("name", "")),
		"role_family": str(candidate.get("role_family", "")),
		"role_title": str(candidate.get("role_title", "")),
		"current_company": str(candidate.get("current_company", "")),
		"current_title": str(candidate.get("current_title", "")),
		"years_experience": int(candidate.get("years_experience", 0)),
		"location": str(candidate.get("location", "")),
		"notice_weeks": int(candidate.get("notice_weeks", 0)),
		"salary_target": float(candidate.get("salary_target", 0.0)),
		"equity_target_bps": float(candidate.get("equity_target_bps", 0.0)),
		"skill_evidence": Array(candidate.get("skill_evidence", [])).duplicate(),
		"revealed_evidence": Array(candidate.get("revealed_evidence", [])).duplicate(),
		"unknowns": Array(candidate.get("unknowns", [])).duplicate(),
		"confidence": Dictionary(candidate.get("confidence", {})).duplicate(true),
		"competing_offer": Dictionary(candidate.get("competing_offer", {})).duplicate(true),
		"deadline_week": int(Dictionary(candidate.get("competing_offer", {})).get("deadline_week", -1)),
		"deadline_materialized": bool(Dictionary(candidate.get("competing_offer", {})).get("deadline_materialized", false)),
		"deadline_window_weeks": int(Dictionary(candidate.get("competing_offer", {})).get("deadline_window_weeks", -1)),
		"status": str(candidate.get("status", "available")),
		"requisition_id": str(candidate.get("requisition_id", "")),
		"available_after_week": int(candidate.get("available_after_week", -1)),
		"interview_stage": str(candidate.get("interview_stage", "not_started")),
		"scorecard_results": Dictionary(candidate.get("scorecard_results", {})).duplicate(true),
		"interview_notes": Array(candidate.get("interview_notes", [])).duplicate(true),
	}


func offer_acceptance_score(candidate_id: String, terms: Dictionary, context: Dictionary = {}) -> float:
	if not candidates.has(candidate_id):
		return 0.0
	var candidate: Dictionary = candidates[candidate_id]
	# Deliberately enumerate only job-relevant values. No dictionary-wide loop is
	# allowed here, so adding a protected profile field cannot affect the score.
	var salary_ratio := float(terms.get("salary", 0.0)) / maxf(1.0, float(candidate.get("salary_target", 1.0)))
	var equity_ratio := float(terms.get("equity_bps", 0.0)) / maxf(1.0, float(candidate.get("equity_target_bps", 1.0)))
	var company_credibility := clampf(float(context.get("company_credibility", 0.60)), 0.0, 1.0)
	var manager_quality := clampf(float(context.get("manager_quality", 0.60)), 0.0, 1.0)
	var role_scope := clampf(float(context.get("role_scope", 0.65)), 0.0, 1.0)
	var process_trust := clampf(_candidate_overall_confidence(candidate), 0.0, 1.0)
	var score := 0.0
	score += 0.34 * clampf(salary_ratio / 1.10, 0.0, 1.0)
	score += 0.18 * clampf(equity_ratio / 1.25, 0.0, 1.0)
	score += 0.12 * company_credibility * float(candidate.get("mission_interest", 0.5))
	score += 0.10 * manager_quality * float(candidate.get("manager_preference", 0.5))
	score += 0.10 * role_scope * float(candidate.get("scope_interest", 0.5))
	score += 0.06 * process_trust
	var competitor: Dictionary = candidate.get("competing_offer", {})
	if not competitor.is_empty() and current_week <= int(competitor.get("deadline_week", -1)):
		var competitor_salary_ratio := float(competitor.get("salary", 0.0)) / maxf(1.0, float(candidate.get("salary_target", 1.0)))
		var competitor_equity_ratio := float(competitor.get("equity_bps", 0.0)) / maxf(1.0, float(candidate.get("equity_target_bps", 1.0)))
		score -= 0.16 * clampf((competitor_salary_ratio - salary_ratio + 0.15) / 0.50, 0.0, 1.0)
		score -= 0.06 * clampf((competitor_equity_ratio - equity_ratio + 0.25) / 1.00, 0.0, 1.0)
	return clampf(score, 0.05, 0.95)


func manager_span(manager_id: String) -> Dictionary:
	if manager_id.is_empty() or not employees.has(manager_id):
		return {"manager_id": manager_id, "direct_reports": 0, "capacity": 0, "overload": 0}
	var direct_reports := 0
	for employee_value in employees.values():
		var employee: Dictionary = employee_value
		if bool(employee.get("active", true)) and str(employee.get("manager_id", "")) == manager_id:
			direct_reports += 1
	var manager: Dictionary = employees[manager_id]
	var management_skill := float(Dictionary(manager.get("skills", {})).get("management", 4.0))
	var capacity := clampi(3 + int(floor(management_skill / 2.0)), 3, 8)
	return {
		"manager_id": manager_id,
		"direct_reports": direct_reports,
		"capacity": capacity,
		"overload": maxi(0, direct_reports - capacity),
	}


func office_capacity() -> int:
	var lease: Dictionary = office.get("active_lease", {})
	if lease.is_empty():
		return 0
	var capacity := int(lease.get("capacity", 0))
	var active_lease_id := str(lease.get("id", ""))
	for fitout_value in office.get("completed_fitouts", []):
		if not fitout_value is Dictionary:
			continue
		var fitout: Dictionary = fitout_value
		if str(fitout.get("lease_id", active_lease_id)) == active_lease_id:
			capacity += int(fitout.get("capacity_delta", 0))
	capacity += int(office.get("temporary_phone_room_capacity_delta", 0))
	capacity -= maxi(0, int(lease.get("subleased_seats", 0)))
	return maxi(0, capacity)


func office_capacity_plan_pending() -> bool:
	# A signed replacement or a capacity-positive fitout is already a concrete
	# response to crowding. Keep the pressure visible in the ledger, but do not
	# raise another modal asking the player to buy the same solution twice.
	var signed: Dictionary = office.get("signed_lease", {})
	if not signed.is_empty() and int(signed.get("capacity", 0)) > office_capacity():
		return true
	var active_id := str(Dictionary(office.get("active_lease", {})).get("id", ""))
	for fitout_value in Array(office.get("fitouts_in_progress", [])):
		if not fitout_value is Dictionary:
			continue
		var fitout: Dictionary = fitout_value
		if str(fitout.get("lease_id", active_id)) == active_id and int(fitout.get("capacity_delta", 0)) > 0:
			return true
	return false


func provision_user(service_id: String, employee_id: String) -> Dictionary:
	if service_id.is_empty() or employee_id.is_empty() or not subscriptions.has(service_id):
		return _failure("subscription_or_employee_missing")
	var subscription: Dictionary = subscriptions[service_id]
	var assigned: Array = Array(subscription.get("assigned_users", [])).duplicate()
	if not assigned.has(employee_id):
		assigned.append(employee_id)
		subscription["assigned_users"] = assigned
	_rebuild_commitments()
	return {"ok": true, "service_id": service_id, "assigned_users": assigned.size(), "weekly_cost": subscription_weekly_cost(service_id)}


func deprovision_user(service_id: String, employee_id: String) -> Dictionary:
	if service_id.is_empty() or not subscriptions.has(service_id):
		return _failure("subscription_missing")
	var subscription: Dictionary = subscriptions[service_id]
	var assigned: Array = Array(subscription.get("assigned_users", [])).duplicate()
	assigned.erase(employee_id)
	subscription["assigned_users"] = assigned
	_rebuild_commitments()
	return {"ok": true, "service_id": service_id, "assigned_users": assigned.size(), "weekly_cost": subscription_weekly_cost(service_id)}


func subscription_weekly_cost(service_id: String) -> float:
	if not subscriptions.has(service_id):
		return 0.0
	var subscription: Dictionary = subscriptions[service_id]
	# Annual prepaid access remains usable (and economically committed) through
	# its paid term even after auto-renew has been turned off.
	if not ["active", "non_renewing"].has(str(subscription.get("status", "active"))):
		return 0.0
	var spec: Dictionary = subscription.get("spec", {})
	var pricing_model := str(spec.get("pricing_model", "per_seat"))
	if pricing_model == "usage":
		var usage := float(subscription.get("usage", 0.0))
		var included := float(spec.get("included_usage", 0.0))
		var calculated := float(spec.get("base_weekly", 0.0)) + maxf(0.0, usage - included) * float(spec.get("overage_unit", 0.0))
		return maxf(float(spec.get("minimum_weekly", 0.0)), calculated)
	var billed_seats := maxi(int(spec.get("minimum_seats", 0)), Array(subscription.get("assigned_users", [])).size())
	var seat_cost := float(billed_seats) * float(spec.get("unit_weekly", 0.0))
	var included_usage := float(spec.get("included_usage", 0.0))
	var usage_overage := maxf(0.0, float(subscription.get("usage", 0.0)) - included_usage) * float(spec.get("overage_unit", 0.0))
	return seat_cost + usage_overage


func burn_summary() -> Dictionary:
	var payroll := 0.0
	for employee_value in employees.values():
		var employee: Dictionary = employee_value
		if bool(employee.get("active", true)):
			payroll += float(employee.get("salary_annual", 0.0)) / WEEKS_PER_YEAR
	var benefits := payroll * BENEFITS_RATE
	var lease := 0.0
	var active_lease: Dictionary = office.get("active_lease", {})
	if not active_lease.is_empty() and str(active_lease.get("status", "active")) == "active":
		var rent_credit_active := bool(active_lease.get("rent_credit_active_this_week", false)) or int(active_lease.get("rent_credit_weeks_remaining", 0)) > 0
		var contractual_rent := 0.0 if rent_credit_active else float(active_lease.get("weekly_rent", 0.0))
		lease = maxf(0.0, contractual_rent - float(active_lease.get("sublease_weekly_income", 0.0)))
	var saas := 0.0
	for service_id_value in subscriptions:
		saas += subscription_weekly_cost(str(service_id_value))
	var training := 0.0
	for training_value in trainings:
		if training_value is Dictionary and str(Dictionary(training_value).get("status", "")) == "active":
			training += float(Dictionary(training_value).get("weekly_cost", 0.0))
	var total := payroll + benefits + lease + saas + training
	return {
		"payroll": payroll,
		"benefits": benefits,
		"lease": lease,
		"saas": saas,
		"training": training,
		"total_weekly": total,
		"accounting_basis": "weekly_accrual",
		"cash_due_this_week": float(week_cash_outlays.get(str(current_week), 0.0)),
		"cash_outlays_this_week": Array(week_cash_outlay_records.get(str(current_week), [])).duplicate(true),
	}


func event_candidates(context: Dictionary = {}) -> Array:
	var week := int(context.get("week", current_week))
	var result: Array = []
	for offer_value in offers:
		if not offer_value is Dictionary:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("status", "")) == "pending" and int(offer.get("deadline_week", 9999)) <= week + 1:
			_append_event_if_ready(result, {
				"id": "candidate_deadline:%s" % str(offer.get("candidate_id", "")), "family": "people",
				"priority": 85, "weight": 2.0, "reason": "候选人的竞品 offer 即将到期。",
			}, week)
	for employee_id_value in employees:
		var employee_id := str(employee_id_value)
		var employee: Dictionary = employees[employee_id]
		if not bool(employee.get("active", true)):
			continue
		var span := manager_span(employee_id)
		if int(span.get("overload", 0)) > 0:
			_append_event_if_ready(result, {
				"id": "manager_overload:%s" % employee_id, "family": "organization", "priority": 75,
				"weight": 1.5, "reason": "%s 的直属人数超过当前管理容量。" % str(employee.get("name", employee_id)),
			}, week)
		if float(employee.get("flight_risk", 0.0)) >= 65.0:
			_append_event_if_ready(result, {
				"id": "flight_risk:%s" % employee_id, "family": "people", "priority": 70,
				"weight": 1.4, "reason": "%s 的离职风险已进入需要谈话的区间。" % str(employee.get("name", employee_id)),
			}, week)
	var capacity := office_capacity()
	if capacity > 0 and active_employee_count() > capacity and not office_capacity_plan_pending():
		_append_event_if_ready(result, {
			"id": "office_over_capacity", "family": "office", "priority": 90, "weight": 2.0,
			"reason": "在职人数超过当前可用工位。",
		}, week)
	for service_id_value in subscriptions:
		var service_id := str(service_id_value)
		var subscription: Dictionary = subscriptions[service_id]
		var spec: Dictionary = subscription.get("spec", {})
		if int(subscription.get("renewal_week", 9999)) <= week + 4:
			_append_event_if_ready(result, {
				"id": "saas_renewal:%s" % service_id, "family": "vendor", "priority": 65, "weight": 1.2,
				"reason": "%s 将在四周内续约。" % str(spec.get("name", service_id)),
			}, week)
		if str(spec.get("pricing_model", "")) == "usage" and float(subscription.get("usage", 0.0)) > float(spec.get("included_usage", 0.0)):
			_append_event_if_ready(result, {
				"id": "saas_overage:%s" % service_id, "family": "vendor", "priority": 60, "weight": 1.0,
				"reason": "%s 已进入用量超额计费。" % str(spec.get("name", service_id)),
			}, week)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var priority_a := int(a.get("priority", 0))
		var priority_b := int(b.get("priority", 0))
		return priority_a > priority_b if priority_a != priority_b else str(a.get("id", "")) < str(b.get("id", ""))
	)
	return result


func public_state() -> Dictionary:
	var open_requisitions := 0
	for requisition_value in requisitions:
		if requisition_value is Dictionary and str(Dictionary(requisition_value).get("status", "")) == "open":
			open_requisitions += 1
	var active_offers := 0
	for offer_value in offers:
		if offer_value is Dictionary and str(Dictionary(offer_value).get("status", "")) == "pending":
			active_offers += 1
	var candidate_pipeline: Array[Dictionary] = []
	var candidate_ids: Array = candidates.keys()
	candidate_ids.sort()
	for candidate_id_value in candidate_ids:
		var candidate_id := str(candidate_id_value)
		var candidate: Dictionary = candidates[candidate_id]
		if str(candidate.get("status", "available")) not in ["shortlisted", "in_process", "offer_pending", "accepted", "ready_to_join"]:
			continue
		var competing: Dictionary = candidate.get("competing_offer", {})
		candidate_pipeline.append({
			"id": candidate_id,
			"name": str(candidate.get("name", "")),
			"role_title": str(candidate.get("role_title", "")),
			"current_company": str(candidate.get("current_company", "")),
			"status": str(candidate.get("status", "")),
			"requisition_id": str(candidate.get("requisition_id", "")),
			"interview_stage": str(candidate.get("interview_stage", "not_started")),
			"completed_interviews": Array(candidate.get("completed_interviews", [])).duplicate(),
			"confidence": float(Dictionary(candidate.get("confidence", {})).get("overall", 0.0)),
			"unknowns_remaining": Array(candidate.get("unknowns", [])).size(),
			"competing_company": str(competing.get("company", "")),
			"competing_salary": float(competing.get("salary", 0.0)),
			"competing_equity_bps": float(competing.get("equity_bps", 0.0)),
			"deadline_week": int(competing.get("deadline_week", -1)),
			"deadline_materialized": bool(competing.get("deadline_materialized", false)),
		})
	var employee_summaries: Array = []
	for employee_id_value in employees:
		var employee: Dictionary = employees[employee_id_value]
		if not bool(employee.get("active", true)):
			continue
		employee_summaries.append({
			"id": str(employee.get("id", "")), "name": str(employee.get("name", "")),
			"level": int(employee.get("level", 1)), "team_id": str(employee.get("team_id", "")),
			"manager_id": str(employee.get("manager_id", "")), "ramp": float(employee.get("ramp", 1.0)),
			"burnout": float(employee.get("burnout", 0.0)), "flight_risk": float(employee.get("flight_risk", 0.0)),
		})
	var subscription_summaries: Array = []
	for service_id_value in subscriptions:
		var service_id := str(service_id_value)
		var subscription: Dictionary = subscriptions[service_id]
		var spec: Dictionary = subscription.get("spec", {})
		subscription_summaries.append({
			"id": service_id, "name": str(spec.get("name", service_id)), "billing": str(spec.get("billing", "weekly")),
			"assigned_users": Array(subscription.get("assigned_users", [])).size(), "weekly_cost": subscription_weekly_cost(service_id),
			"renewal_week": int(subscription.get("renewal_week", -1)), "auto_renew": bool(subscription.get("auto_renew", false)),
			"pnl_weekly_expense": float(subscription.get("pnl_weekly_expense", subscription_weekly_cost(service_id))),
			"cash_paid_to_date": float(subscription.get("cash_paid_to_date", 0.0)),
			"prepaid_through_week": int(subscription.get("prepaid_through_week", -1)),
		})
	return {
		"week": current_week,
		"open_requisitions": open_requisitions,
		"active_candidates": _active_candidate_count(),
		"active_offers": active_offers,
		"candidate_pipeline": candidate_pipeline,
		"scheduled_joins": scheduled_joins.size(),
		"pending_joins": pending_joins.size(),
		"active_employees": active_employee_count(),
		"employees": employee_summaries,
		"teams": teams.duplicate(true),
		"office": {
			"lease": Dictionary(office.get("active_lease", {})).duplicate(true),
			"signed_lease": Dictionary(office.get("signed_lease", {})).duplicate(true),
			"capacity": office_capacity(), "occupancy": active_employee_count(),
			"completed_fitouts": Array(office.get("completed_fitouts", [])).duplicate(true),
		},
		"subscriptions": subscription_summaries,
		"commitment_count": commitments.size(),
		"burn": burn_summary(),
		"cash_flow": {
			"cash_due_this_week": float(week_cash_outlays.get(str(current_week), 0.0)),
			"outlays": Array(week_cash_outlay_records.get(str(current_week), [])).duplicate(true),
		},
		"event_count": event_candidates().size(),
	}


func to_save() -> Dictionary:
	_rebuild_commitments()
	return {
		"save_version": SAVE_VERSION,
		"current_week": current_week,
		"rng_state": rng_state,
		"requisitions": requisitions.duplicate(true),
		"candidates": candidates.duplicate(true),
		"offers": offers.duplicate(true),
		"scheduled_joins": scheduled_joins.duplicate(true),
		"pending_joins": pending_joins.duplicate(true),
		"employees": employees.duplicate(true),
		"teams": teams.duplicate(true),
		"trainings": trainings.duplicate(true),
		"office": office.duplicate(true),
		"subscriptions": subscriptions.duplicate(true),
		"commitments": commitments.duplicate(true),
		"event_cooldowns": event_cooldowns.duplicate(true),
		"history": history.duplicate(true),
		"week_cash_outlays": week_cash_outlays.duplicate(true),
		"week_cash_outlay_records": week_cash_outlay_records.duplicate(true),
	}


func from_save(data: Dictionary) -> bool:
	if int(data.get("save_version", -1)) != SAVE_VERSION:
		return false
	current_week = maxi(1, int(data.get("current_week", 1)))
	rng_state = maxi(1, int(data.get("rng_state", RNG_INITIAL_STATE)))
	requisitions = _dictionary_array(data.get("requisitions", []))
	candidates = Dictionary(data.get("candidates", {})).duplicate(true)
	offers = _dictionary_array(data.get("offers", []))
	scheduled_joins = _dictionary_array(data.get("scheduled_joins", []))
	pending_joins = _dictionary_array(data.get("pending_joins", []))
	employees = Dictionary(data.get("employees", {})).duplicate(true)
	teams = Dictionary(data.get("teams", {})).duplicate(true)
	trainings = _dictionary_array(data.get("trainings", []))
	office = Dictionary(data.get("office", {})).duplicate(true)
	subscriptions = Dictionary(data.get("subscriptions", {})).duplicate(true)
	commitments = _dictionary_array(data.get("commitments", []))
	event_cooldowns = Dictionary(data.get("event_cooldowns", {})).duplicate(true)
	history = _dictionary_array(data.get("history", []))
	week_cash_outlays = Dictionary(data.get("week_cash_outlays", {})).duplicate(true)
	week_cash_outlay_records = Dictionary(data.get("week_cash_outlay_records", {})).duplicate(true)
	if candidates.is_empty():
		return false
	if teams.is_empty():
		teams = {"founders": {"id": "founders", "name": "创始团队", "manager_id": "", "member_ids": []}}
	if not office.has("lease_history"):
		office["lease_history"] = []
	_repair_requisition_focuses()
	_rebuild_commitments()
	return true


func active_employee_count() -> int:
	var count := 0
	for employee_value in employees.values():
		if employee_value is Dictionary and bool(Dictionary(employee_value).get("active", true)):
			count += 1
	return count


func _open_requisition(payload: Dictionary) -> Dictionary:
	var requisition_id := str(payload.get("id", "req_%03d" % (requisitions.size() + 1)))
	if _find_requisition(requisition_id) >= 0:
		return _failure("duplicate_requisition", requisition_id)
	var role_family := str(payload.get("role_family", ""))
	if not ROLE_SCORECARDS.has(role_family):
		return _failure("unsupported_role_family", role_family)
	var pipeline := _select_candidates_for_requisition(role_family, Array(payload.get("candidate_ids", [])))
	if pipeline.is_empty():
		return _failure("no_available_candidates", requisition_id)
	var scorecard := Array(ROLE_SCORECARDS[role_family]).duplicate(true)
	var requisition := {
		"id": requisition_id,
		"team_id": str(payload.get("team_id", "founders")),
		"role_family": role_family,
		"level": clampi(int(payload.get("level", 2)), 1, 6),
		"reason": str(payload.get("reason", "growth")),
		"salary_band": Array(payload.get("salary_band", [35.0, 65.0])).duplicate(),
		"equity_band_bps": Array(payload.get("equity_band_bps", [5.0, 25.0])).duplicate(),
		"hiring_manager_id": str(payload.get("hiring_manager_id", "")),
		"priority": clampi(int(payload.get("priority", 2)), 1, 3),
		"opened_week": current_week,
		"status": "open",
		"scorecard": scorecard,
		"candidate_ids": pipeline.duplicate(),
		"focus_candidate_id": "",
	}
	requisitions.append(requisition)
	for pipeline_index in pipeline.size():
		var candidate_id_value = pipeline[pipeline_index]
		var candidate_id := str(candidate_id_value)
		var candidate: Dictionary = candidates[candidate_id]
		candidate["requisition_id"] = requisition_id
		var competing_offer: Dictionary = Dictionary(candidate.get("competing_offer", {})).duplicate(true)
		if not competing_offer.is_empty():
			var window_weeks := maxi(1, int(competing_offer.get("deadline_window_weeks", competing_offer.get("deadline_week", 3))))
			competing_offer["deadline_window_weeks"] = window_weeks
			competing_offer["deadline_week"] = -1
			competing_offer["deadline_materialized"] = false
			candidate["competing_offer"] = competing_offer
		candidate["status"] = "shortlisted"
	if not pipeline.is_empty():
		_activate_requisition_candidate(requisition, str(pipeline[0]))
	return {
		"ok": true,
		"requisition": requisition.duplicate(true),
		"candidate_ids": pipeline,
		"focus_candidate_id": str(requisition.get("focus_candidate_id", "")),
		"shortlisted_candidate_ids": pipeline.slice(1),
	}


func _interview_candidate(payload: Dictionary) -> Dictionary:
	var candidate_id := str(payload.get("candidate_id", ""))
	var stage := str(payload.get("stage", ""))
	if not candidates.has(candidate_id) or not INTERVIEW_STAGES.has(stage):
		return _failure("candidate_or_stage_missing", candidate_id)
	var candidate: Dictionary = candidates[candidate_id]
	if str(candidate.get("status", "")) != "in_process":
		return _failure("candidate_not_in_process", candidate_id)
	var completed: Array = Array(candidate.get("completed_interviews", [])).duplicate()
	var expected_stage := str(INTERVIEW_STAGES[mini(completed.size(), INTERVIEW_STAGES.size() - 1)])
	if completed.has(stage):
		return _failure("interview_already_completed", stage)
	if stage != expected_stage:
		return _failure("interview_out_of_order", expected_stage)
	var requisition := _requisition_by_id(str(candidate.get("requisition_id", "")))
	if requisition.is_empty():
		return _failure("requisition_missing")
	if str(requisition.get("focus_candidate_id", "")) != candidate_id:
		return _failure("candidate_not_requisition_focus", candidate_id)
	var stage_scores: Dictionary = _score_candidate_stage(candidate, requisition, stage)
	var scorecard_results: Dictionary = Dictionary(candidate.get("scorecard_results", {})).duplicate(true)
	for score_id_value in stage_scores:
		scorecard_results[str(score_id_value)] = stage_scores[score_id_value]
	candidate["scorecard_results"] = scorecard_results
	completed.append(stage)
	candidate["completed_interviews"] = completed
	candidate["interview_stage"] = stage
	var confidence: Dictionary = Dictionary(candidate.get("confidence", {})).duplicate(true)
	confidence[stage] = 0.72 + 0.08 * float(completed.size())
	confidence["overall"] = [0.35, 0.62, 0.88][completed.size() - 1]
	candidate["confidence"] = confidence
	var unknowns: Array = Array(candidate.get("unknowns", [])).duplicate()
	if not unknowns.is_empty():
		unknowns.pop_front()
	candidate["unknowns"] = unknowns
	var interview_quotes: Dictionary = candidate.get("interview_quotes", {})
	var note := str(interview_quotes.get(stage, "没有留下可复用的原话。"))
	var notes: Array = Array(candidate.get("interview_notes", [])).duplicate(true)
	notes.append({"stage": stage, "week": current_week, "quote": note, "scores": stage_scores.duplicate(true)})
	candidate["interview_notes"] = notes
	var revealed: Array = Array(candidate.get("revealed_evidence", [])).duplicate()
	var evidence: Array = Array(candidate.get("skill_evidence", []))
	if stage != "screen" and revealed.size() < evidence.size():
		revealed.append(str(evidence[revealed.size()]))
	candidate["revealed_evidence"] = revealed
	return {
		"ok": true, "candidate_id": candidate_id, "stage": stage, "quote": note,
		"scores": stage_scores, "confidence": float(confidence["overall"]), "unknowns_remaining": unknowns.size(),
	}


func _issue_offer(payload: Dictionary, context: Dictionary) -> Dictionary:
	var candidate_id := str(payload.get("candidate_id", ""))
	if not candidates.has(candidate_id):
		return _failure("candidate_missing", candidate_id)
	var candidate: Dictionary = candidates[candidate_id]
	if Array(candidate.get("completed_interviews", [])).size() < INTERVIEW_STAGES.size():
		return _failure("interviews_incomplete", candidate_id)
	if str(candidate.get("status", "")) != "in_process":
		return _failure("candidate_not_offerable", candidate_id)
	var requisition := _requisition_by_id(str(candidate.get("requisition_id", "")))
	if requisition.is_empty():
		return _failure("requisition_missing")
	if str(requisition.get("focus_candidate_id", "")) != candidate_id:
		return _failure("candidate_not_requisition_focus", candidate_id)
	var salary := float(payload.get("salary", 0.0))
	var equity_bps := float(payload.get("equity_bps", 0.0))
	if salary <= 0.0 or equity_bps < 0.0:
		return _failure("invalid_offer_terms")
	var salary_band: Array = requisition.get("salary_band", [0.0, 999.0])
	var equity_band: Array = requisition.get("equity_band_bps", [0.0, 999.0])
	if not bool(payload.get("allow_out_of_band", false)):
		if salary < float(salary_band[0]) or salary > float(salary_band[1]):
			return _failure("salary_out_of_band")
		if equity_bps < float(equity_band[0]) or equity_bps > float(equity_band[1]):
			return _failure("equity_out_of_band")
	var competitor: Dictionary = candidate.get("competing_offer", {})
	var deadline_week := int(competitor.get("deadline_week", current_week + 2))
	var terms := {
		"salary": salary,
		"equity_bps": equity_bps,
		"level": clampi(int(payload.get("level", requisition.get("level", 2))), 1, 6),
		"team_id": str(payload.get("team_id", requisition.get("team_id", "founders"))),
		"manager_id": str(payload.get("manager_id", requisition.get("hiring_manager_id", ""))),
		"title": str(payload.get("title", candidate.get("role_title", ""))),
		"vesting_weeks": maxi(52, int(payload.get("vesting_weeks", 208))),
		"cliff_weeks": maxi(0, int(payload.get("cliff_weeks", 52))),
	}
	var offer_id := "offer_%03d" % (offers.size() + 1)
	var offer := {
		"id": offer_id, "candidate_id": candidate_id, "requisition_id": str(requisition.get("id", "")),
		"terms": terms, "issued_week": current_week, "response_week": current_week + 1,
		"deadline_week": deadline_week, "status": "pending",
		"acceptance_score": offer_acceptance_score(candidate_id, terms, context),
		"decision_context": {
			"company_credibility": float(context.get("company_credibility", 0.60)),
			"manager_quality": float(context.get("manager_quality", 0.60)),
			"role_scope": float(context.get("role_scope", 0.65)),
		},
	}
	offers.append(offer)
	candidate["status"] = "offer_pending"
	return {"ok": true, "offer": offer.duplicate(true)}


func _resolve_due_offers(context: Dictionary) -> Array:
	var outcomes: Array = []
	for offer_value in offers:
		if not offer_value is Dictionary:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("status", "")) != "pending" or int(offer.get("response_week", 9999)) > current_week:
			continue
		var candidate_id := str(offer.get("candidate_id", ""))
		var requisition_id := str(offer.get("requisition_id", ""))
		if not candidates.has(candidate_id):
			offer["status"] = "invalid"
			offer["resolved_week"] = current_week
			var invalid_outcome := {"kind": "offer_invalid", "candidate_id": candidate_id, "requisition_id": requisition_id}
			outcomes.append(invalid_outcome)
			var invalid_next := _activate_next_shortlisted(requisition_id, "offer_invalid")
			if not invalid_next.is_empty():
				outcomes.append(invalid_next)
			_record_history("offer_resolved", invalid_outcome)
			continue
		var candidate: Dictionary = candidates[candidate_id]
		var score := float(offer.get("acceptance_score", 0.0))
		# Excellent offers have a deterministic success ceiling so scripted/tests
		# can plan around a fully competitive package; ordinary offers still use
		# this subsystem's independently persisted RNG.
		var accepted := score >= 0.78 or (score > 0.15 and _roll_unit() <= score)
		if current_week > int(offer.get("deadline_week", current_week)):
			accepted = false
		if accepted:
			offer["status"] = "accepted"
			offer["resolved_week"] = current_week
			candidate["status"] = "accepted"
			var terms: Dictionary = offer.get("terms", {})
			var start_week := current_week + int(candidate.get("notice_weeks", 0))
			scheduled_joins.append({
				"offer_id": str(offer.get("id", "")), "candidate_id": candidate_id,
				"requisition_id": requisition_id,
				"accepted_week": current_week, "start_week": start_week,
				"employee": _candidate_to_employee(candidate, terms, start_week),
			})
			_close_requisition(requisition_id, candidate_id)
			var accepted_outcome := {"kind": "offer_accepted", "candidate_id": candidate_id, "requisition_id": requisition_id, "start_week": start_week}
			outcomes.append(accepted_outcome)
			_record_history("offer_resolved", accepted_outcome)
		else:
			offer["status"] = "rejected"
			offer["resolved_week"] = current_week
			offer["rejection_reason"] = _offer_rejection_reason(candidate, Dictionary(offer.get("terms", {})), score)
			_release_candidate(candidate, str(offer["rejection_reason"]))
			var rejected_outcome := {"kind": "offer_rejected", "candidate_id": candidate_id, "requisition_id": requisition_id, "reason": offer["rejection_reason"]}
			outcomes.append(rejected_outcome)
			var next := _activate_next_shortlisted(requisition_id, "offer_rejected")
			if not next.is_empty():
				outcomes.append(next)
			_record_history("offer_resolved", rejected_outcome)
	return outcomes


func _release_due_joins() -> Array:
	var outcomes: Array = []
	var remaining: Array = []
	for join_value in scheduled_joins:
		if not join_value is Dictionary:
			continue
		var join: Dictionary = join_value
		if int(join.get("start_week", 9999)) <= current_week:
			pending_joins.append(join.duplicate(true))
			var candidate_id := str(join.get("candidate_id", ""))
			if candidates.has(candidate_id):
				Dictionary(candidates[candidate_id])["status"] = "ready_to_join"
			outcomes.append({"kind": "candidate_ready_to_join", "candidate_id": candidate_id})
		else:
			remaining.append(join)
	scheduled_joins = remaining
	return outcomes


func _create_team(payload: Dictionary) -> Dictionary:
	var team_id := str(payload.get("id", ""))
	if team_id.is_empty() or teams.has(team_id):
		return _failure("team_id_invalid_or_duplicate", team_id)
	var manager_id := str(payload.get("manager_id", ""))
	if not manager_id.is_empty() and (not employees.has(manager_id) or not bool(Dictionary(employees[manager_id]).get("active", true))):
		return _failure("manager_missing", manager_id)
	teams[team_id] = {"id": team_id, "name": str(payload.get("name", team_id)), "manager_id": manager_id, "member_ids": []}
	return {"ok": true, "team": Dictionary(teams[team_id]).duplicate(true)}


func _set_manager(payload: Dictionary) -> Dictionary:
	var employee_id := str(payload.get("employee_id", ""))
	var manager_id := str(payload.get("manager_id", ""))
	if not employees.has(employee_id):
		return _failure("employee_missing", employee_id)
	if not manager_id.is_empty() and not employees.has(manager_id):
		return _failure("manager_missing", manager_id)
	if employee_id == manager_id or _would_create_manager_cycle(employee_id, manager_id):
		return _failure("manager_cycle", employee_id)
	Dictionary(employees[employee_id])["manager_id"] = manager_id
	return {"ok": true, "employee_id": employee_id, "manager_id": manager_id, "span": manager_span(manager_id)}


func _transfer_employee(payload: Dictionary) -> Dictionary:
	var employee_id := str(payload.get("employee_id", ""))
	var team_id := str(payload.get("team_id", ""))
	if not employees.has(employee_id) or not teams.has(team_id):
		return _failure("employee_or_team_missing")
	var employee: Dictionary = employees[employee_id]
	var from_team := str(employee.get("team_id", ""))
	_remove_from_all_teams(employee_id)
	employee["team_id"] = team_id
	employee["ramp"] = minf(float(employee.get("ramp", 1.0)), 0.65)
	employee["onboarding_weeks_remaining"] = maxi(1, int(payload.get("ramp_weeks", 2)))
	employee["burnout"] = clampf(float(employee.get("burnout", 0.0)) + 4.0, 0.0, 100.0)
	_ensure_team_membership(employee_id, team_id)
	return {"ok": true, "employee_id": employee_id, "from_team": from_team, "team_id": team_id, "ramp": employee["ramp"]}


func _start_training(payload: Dictionary) -> Dictionary:
	var employee_id := str(payload.get("employee_id", ""))
	var skill_id := str(payload.get("skill_id", ""))
	var mentor_id := str(payload.get("mentor_id", ""))
	if not employees.has(employee_id) or skill_id.is_empty():
		return _failure("employee_or_skill_missing")
	if not mentor_id.is_empty() and not employees.has(mentor_id):
		return _failure("mentor_missing", mentor_id)
	for training_value in trainings:
		if training_value is Dictionary and str(Dictionary(training_value).get("employee_id", "")) == employee_id and str(Dictionary(training_value).get("status", "")) == "active":
			return _failure("training_already_active", employee_id)
	var training := {
		"id": "training_%03d" % (trainings.size() + 1), "employee_id": employee_id, "skill_id": skill_id,
		"mentor_id": mentor_id, "started_week": current_week, "remaining_weeks": maxi(1, int(payload.get("duration_weeks", 3))),
		"gain": clampf(float(payload.get("gain", 0.8)), 0.1, 2.0), "weekly_cost": maxf(0.0, float(payload.get("weekly_cost", 0.06))),
		"status": "active",
	}
	trainings.append(training)
	if not mentor_id.is_empty():
		var mentor: Dictionary = employees[mentor_id]
		mentor["burnout"] = clampf(float(mentor.get("burnout", 0.0)) + 3.0, 0.0, 100.0)
	return {"ok": true, "training": training.duplicate(true)}


func _promote_employee(payload: Dictionary) -> Dictionary:
	var employee_id := str(payload.get("employee_id", ""))
	if not employees.has(employee_id):
		return _failure("employee_missing", employee_id)
	var employee: Dictionary = employees[employee_id]
	var current_level := int(employee.get("level", 1))
	var new_level := int(payload.get("level", current_level + 1))
	if new_level != current_level + 1:
		return _failure("promotion_must_be_one_level")
	var new_salary := float(payload.get("salary", employee.get("salary_annual", 0.0)))
	if new_salary < float(employee.get("salary_annual", 0.0)):
		return _failure("promotion_salary_cannot_decrease")
	employee["level"] = new_level
	employee["salary_annual"] = new_salary
	employee["equity_bps"] = float(employee.get("equity_bps", 0.0)) + maxf(0.0, float(payload.get("equity_refresh_bps", 0.0)))
	employee["growth_satisfaction"] = clampf(float(employee.get("growth_satisfaction", 50.0)) + 18.0, 0.0, 100.0)
	return {"ok": true, "employee_id": employee_id, "level": new_level, "salary_annual": new_salary, "equity_bps": employee["equity_bps"]}


func _sign_office_lease(payload: Dictionary) -> Dictionary:
	var lease_id := str(payload.get("lease_id", ""))
	if not OFFICE_LEASE_CATALOG.has(lease_id):
		return _failure("lease_missing", lease_id)
	if not Dictionary(office.get("active_lease", {})).is_empty() or not Dictionary(office.get("signed_lease", {})).is_empty():
		return _failure("lease_already_present")
	var lease: Dictionary = Dictionary(OFFICE_LEASE_CATALOG[lease_id]).duplicate(true)
	lease["signed_week"] = current_week
	lease["start_week"] = current_week + int(lease.get("move_in_weeks", 0))
	lease["end_week"] = int(lease["start_week"]) + int(lease.get("term_weeks", 0))
	lease["status"] = "active" if int(lease["start_week"]) <= current_week else "signed"
	var cash_outlay := _add_cash_outlay(float(lease.get("deposit", 0.0)), {
		"kind": "office_deposit", "category": "office", "source_id": lease_id,
		"cash_timing": "upfront", "pnl_treatment": "balance_sheet_deposit",
		"normalized_weekly_expense": float(lease.get("weekly_rent", 0.0)),
	})
	if str(lease["status"]) == "active":
		office["active_lease"] = lease
	else:
		office["signed_lease"] = lease
	return {"ok": true, "lease": lease.duplicate(true), "cash_due": float(lease.get("deposit", 0.0)), "cash_outlay": cash_outlay}


func _replace_office_lease(payload: Dictionary) -> Dictionary:
	var active: Dictionary = office.get("active_lease", {})
	if active.is_empty():
		return _failure("active_lease_missing")
	if not Dictionary(office.get("signed_lease", {})).is_empty():
		return _failure("replacement_lease_already_signed")
	var lease_id := str(payload.get("lease_id", ""))
	if not OFFICE_LEASE_CATALOG.has(lease_id):
		return _failure("lease_missing", lease_id)
	if str(active.get("id", "")) == lease_id:
		return _failure("replacement_matches_active_lease", lease_id)
	var lease: Dictionary = Dictionary(OFFICE_LEASE_CATALOG[lease_id]).duplicate(true)
	lease["signed_week"] = current_week
	lease["start_week"] = current_week + int(lease.get("move_in_weeks", 0))
	lease["end_week"] = int(lease["start_week"]) + int(lease.get("term_weeks", 0))
	lease["status"] = "signed"
	lease["replaces_lease_id"] = str(active.get("id", ""))
	office["signed_lease"] = lease
	var cash_outlay := _add_cash_outlay(float(lease.get("deposit", 0.0)), {
		"kind": "office_replacement_deposit", "category": "office", "source_id": lease_id,
		"cash_timing": "upfront", "pnl_treatment": "balance_sheet_deposit",
		"normalized_weekly_expense": float(lease.get("weekly_rent", 0.0)),
		"commitment_start_week": int(lease.get("start_week", current_week)),
	})
	var move_in: Dictionary = {}
	if int(lease.get("start_week", current_week + 1)) <= current_week:
		move_in = _activate_signed_office_lease()
	return {
		"ok": true, "lease": lease.duplicate(true), "replaces_lease_id": str(active.get("id", "")),
		"cash_due": float(lease.get("deposit", 0.0)), "cash_outlay": cash_outlay,
		"move_in": move_in,
	}


func _start_fitout(payload: Dictionary) -> Dictionary:
	var fitout_id := str(payload.get("fitout_id", ""))
	if not FITOUT_CATALOG.has(fitout_id) or Dictionary(office.get("active_lease", {})).is_empty():
		return _failure("fitout_or_active_lease_missing", fitout_id)
	var lease: Dictionary = office.get("active_lease", {})
	var active_lease_id := str(lease.get("id", ""))
	for existing_value in Array(office.get("completed_fitouts", [])) + Array(office.get("fitouts_in_progress", [])):
		if existing_value is Dictionary and str(Dictionary(existing_value).get("id", "")) == fitout_id and str(Dictionary(existing_value).get("lease_id", active_lease_id)) == active_lease_id:
			return _failure("fitout_duplicate", fitout_id)
	var fitout: Dictionary = Dictionary(FITOUT_CATALOG[fitout_id]).duplicate(true)
	fitout["started_week"] = current_week
	fitout["complete_week"] = current_week + int(fitout.get("duration_weeks", 1))
	fitout["status"] = "building"
	fitout["lease_id"] = str(lease.get("id", ""))
	var allowance_remaining := float(lease.get("fitout_allowance_remaining", lease.get("fitout_allowance", 0.0)))
	var applied_allowance := minf(allowance_remaining, float(fitout.get("cost", 0.0)))
	lease["fitout_allowance_remaining"] = allowance_remaining - applied_allowance
	var cash_due := float(fitout.get("cost", 0.0)) - applied_allowance
	fitout["cash_due"] = cash_due
	var cash_outlay := _add_cash_outlay(cash_due, {
		"kind": "office_fitout", "category": "office", "source_id": fitout_id,
		"cash_timing": "upfront", "pnl_treatment": "capitalized_fitout",
		"lease_id": str(lease.get("id", "")),
	})
	var in_progress: Array = Array(office.get("fitouts_in_progress", [])).duplicate(true)
	in_progress.append(fitout)
	office["fitouts_in_progress"] = in_progress
	return {"ok": true, "fitout": fitout.duplicate(true), "cash_due": cash_due, "cash_outlay": cash_outlay}


func _subscribe_saas(payload: Dictionary) -> Dictionary:
	var service_id := str(payload.get("service_id", ""))
	if not SAAS_CATALOG.has(service_id) or subscriptions.has(service_id):
		return _failure("service_missing_or_duplicate", service_id)
	var spec: Dictionary = Dictionary(SAAS_CATALOG[service_id]).duplicate(true)
	var subscription := {
		"id": service_id, "spec": spec, "status": "active", "signed_week": current_week,
		"start_week": current_week, "renewal_week": current_week + int(spec.get("term_weeks", 13)),
		"assigned_users": [], "usage": maxf(0.0, float(payload.get("initial_usage", 0.0))),
		"auto_renew": bool(payload.get("auto_renew", false)),
	}
	subscriptions[service_id] = subscription
	if bool(spec.get("auto_provision", false)):
		for employee_id in _active_employee_ids():
			provision_user(service_id, employee_id)
	var weekly_normalized := subscription_weekly_cost(service_id)
	subscription["pnl_weekly_expense"] = weekly_normalized
	var cash_due := 0.0
	var cash_outlay: Dictionary = {}
	if str(spec.get("billing", "weekly")) == "annual_prepaid":
		cash_due = weekly_normalized * float(spec.get("term_weeks", 52))
		cash_outlay = _add_cash_outlay(cash_due, {
			"kind": "subscription_prepayment", "category": "saas", "source_id": service_id,
			"cash_timing": "upfront", "pnl_treatment": "straight_line_amortization",
			"amortization_weeks": int(spec.get("term_weeks", 52)),
			"normalized_weekly_expense": weekly_normalized,
			"auto_renew": bool(subscription.get("auto_renew", false)),
			"renewal_week": int(subscription.get("renewal_week", -1)),
		})
		subscription["cash_paid_to_date"] = cash_due
		subscription["prepaid_through_week"] = int(subscription.get("renewal_week", -1))
		subscription["last_cash_outlay"] = cash_outlay.duplicate(true)
	else:
		subscription["cash_paid_to_date"] = 0.0
		subscription["prepaid_through_week"] = -1
	var pnl := {
		"basis": "weekly_accrual",
		"recognition": "straight_line" if str(spec.get("billing", "weekly")) == "annual_prepaid" else "as_incurred",
		"weekly_expense": weekly_normalized,
		"amortization_weeks": int(spec.get("term_weeks", 0)) if str(spec.get("billing", "weekly")) == "annual_prepaid" else 0,
		"start_week": current_week,
		"end_week": int(subscription.get("renewal_week", -1)),
	}
	var commitment := _subscription_renewal_commitment(service_id, subscription, weekly_normalized)
	return {
		"ok": true, "subscription": Dictionary(subscriptions[service_id]).duplicate(true),
		"billing": str(spec.get("billing", "weekly")), "cash_due": cash_due,
		"cash_outlay": cash_outlay, "weekly_normalized": weekly_normalized,
		"pnl": pnl, "commitment": commitment,
	}


func _cancel_saas(payload: Dictionary) -> Dictionary:
	var service_id := str(payload.get("service_id", ""))
	if not subscriptions.has(service_id):
		return _failure("subscription_missing", service_id)
	var subscription: Dictionary = subscriptions[service_id]
	subscription["auto_renew"] = false
	if str(Dictionary(subscription.get("spec", {})).get("billing", "weekly")) == "annual_prepaid" and current_week < int(subscription.get("renewal_week", current_week)):
		subscription["status"] = "non_renewing"
		return {
			"ok": true, "service_id": service_id, "effective_week": int(subscription.get("renewal_week", current_week)),
			"commitment": _subscription_renewal_commitment(service_id, subscription, subscription_weekly_cost(service_id)),
		}
	subscription["status"] = "cancelled"
	subscription["cancelled_week"] = current_week
	return {
		"ok": true, "service_id": service_id, "effective_week": current_week,
		"commitment": _subscription_renewal_commitment(service_id, subscription, 0.0),
	}


func _report_saas_usage(payload: Dictionary) -> Dictionary:
	var service_id := str(payload.get("service_id", ""))
	if not subscriptions.has(service_id):
		return _failure("subscription_missing", service_id)
	var subscription: Dictionary = subscriptions[service_id]
	subscription["usage"] = maxf(0.0, float(payload.get("usage", 0.0)))
	return {"ok": true, "service_id": service_id, "usage": subscription["usage"], "weekly_cost": subscription_weekly_cost(service_id)}


func _acknowledge_event(payload: Dictionary) -> Dictionary:
	var event_id := str(payload.get("event_id", ""))
	if event_id.is_empty():
		return _failure("event_id_missing")
	event_cooldowns[event_id] = current_week + maxi(1, int(payload.get("cooldown_weeks", 3)))
	return {"ok": true, "event_id": event_id, "ready_after_week": event_cooldowns[event_id]}


func _advance_onboarding() -> Array:
	var outcomes: Array = []
	for employee_id_value in employees:
		var employee_id := str(employee_id_value)
		var employee: Dictionary = employees[employee_id]
		if not bool(employee.get("active", true)):
			continue
		var remaining := int(employee.get("onboarding_weeks_remaining", 0))
		if remaining <= 0:
			continue
		remaining -= 1
		employee["onboarding_weeks_remaining"] = remaining
		employee["ramp"] = clampf(float(employee.get("ramp", 0.35)) + 0.325, 0.0, 1.0)
		if remaining == 0:
			employee["ramp"] = 1.0
			outcomes.append({"kind": "onboarding_complete", "employee_id": employee_id})
	return outcomes


func _advance_trainings() -> Array:
	var outcomes: Array = []
	for training_value in trainings:
		if not training_value is Dictionary:
			continue
		var training: Dictionary = training_value
		if str(training.get("status", "")) != "active":
			continue
		training["remaining_weeks"] = int(training.get("remaining_weeks", 1)) - 1
		if int(training["remaining_weeks"]) > 0:
			continue
		var employee_id := str(training.get("employee_id", ""))
		if employees.has(employee_id):
			var employee: Dictionary = employees[employee_id]
			var skills: Dictionary = Dictionary(employee.get("skills", {})).duplicate(true)
			var skill_id := str(training.get("skill_id", ""))
			skills[skill_id] = clampf(float(skills.get(skill_id, 4.0)) + float(training.get("gain", 0.8)), 0.0, 10.0)
			employee["skills"] = skills
			employee["growth_satisfaction"] = clampf(float(employee.get("growth_satisfaction", 50.0)) + 8.0, 0.0, 100.0)
		training["status"] = "complete"
		training["completed_week"] = current_week
		outcomes.append({"kind": "training_complete", "employee_id": employee_id, "skill_id": str(training.get("skill_id", ""))})
	return outcomes


func _advance_office() -> Array:
	var outcomes: Array = []
	var signed: Dictionary = office.get("signed_lease", {})
	if not signed.is_empty() and int(signed.get("start_week", 9999)) <= current_week:
		outcomes.append(_activate_signed_office_lease())
	var active: Dictionary = office.get("active_lease", {})
	if not active.is_empty():
		var credit_remaining := maxi(0, int(active.get("rent_credit_weeks_remaining", 0)))
		active["rent_credit_active_this_week"] = credit_remaining > 0
		if credit_remaining > 0:
			active["rent_credit_weeks_remaining"] = credit_remaining - 1
	if not active.is_empty() and current_week >= int(active.get("end_week", 9999)):
		active["status"] = "expired"
		active["expired_week"] = current_week
		var lease_history: Array = Array(office.get("lease_history", [])).duplicate(true)
		lease_history.append(active.duplicate(true))
		office["lease_history"] = lease_history
		office["active_lease"] = {}
		outcomes.append({"kind": "office_lease_expired", "lease_id": str(active.get("id", ""))})
	var remaining: Array = []
	var completed: Array = Array(office.get("completed_fitouts", [])).duplicate(true)
	for fitout_value in office.get("fitouts_in_progress", []):
		if not fitout_value is Dictionary:
			continue
		var fitout: Dictionary = fitout_value
		if int(fitout.get("complete_week", 9999)) <= current_week:
			fitout["status"] = "complete"
			completed.append(fitout)
			office["workspace_strain"] = clampf(float(office.get("workspace_strain", 0.0)) + float(fitout.get("workspace_strain", 0.0)), 0.0, 1.0)
			outcomes.append({"kind": "fitout_complete", "fitout_id": str(fitout.get("id", ""))})
		else:
			remaining.append(fitout)
	office["fitouts_in_progress"] = remaining
	office["completed_fitouts"] = completed
	return outcomes


func _activate_signed_office_lease() -> Dictionary:
	var signed: Dictionary = office.get("signed_lease", {})
	if signed.is_empty():
		return {}
	var previous: Dictionary = office.get("active_lease", {})
	var previous_id := str(previous.get("id", ""))
	if not previous.is_empty():
		previous["status"] = "replaced"
		previous["replaced_week"] = current_week
		previous["replacement_lease_id"] = str(signed.get("id", ""))
		var lease_history: Array = Array(office.get("lease_history", [])).duplicate(true)
		lease_history.append(previous.duplicate(true))
		office["lease_history"] = lease_history
	signed["status"] = "active"
	office["active_lease"] = signed
	office["signed_lease"] = {}
	return {
		"kind": "office_move_in", "lease_id": str(signed.get("id", "")),
		"replaced_lease_id": previous_id, "capacity": int(signed.get("capacity", 0)),
	}


func _advance_subscriptions() -> Array:
	var outcomes: Array = []
	for service_id_value in subscriptions:
		var service_id := str(service_id_value)
		var subscription: Dictionary = subscriptions[service_id]
		if str(subscription.get("status", "active")) == "non_renewing" and current_week >= int(subscription.get("renewal_week", 9999)):
			subscription["status"] = "cancelled"
			outcomes.append({
				"kind": "subscription_cancelled", "service_id": service_id, "cash_due": 0.0,
				"cash_outlay": {}, "pnl": {"weekly_expense": 0.0, "basis": "weekly_accrual"},
				"commitment": {"status": "ended", "auto_renew": false, "renewal_week": int(subscription.get("renewal_week", -1))},
			})
		elif str(subscription.get("status", "active")) == "active" and current_week >= int(subscription.get("renewal_week", 9999)):
			if bool(subscription.get("auto_renew", false)):
				var spec: Dictionary = subscription.get("spec", {})
				var weekly_normalized := subscription_weekly_cost(service_id)
				subscription["renewal_week"] = current_week + int(spec.get("term_weeks", 13))
				var cash_due := 0.0
				var cash_outlay: Dictionary = {}
				if str(spec.get("billing", "weekly")) == "annual_prepaid":
					cash_due = weekly_normalized * float(spec.get("term_weeks", 52))
					cash_outlay = _add_cash_outlay(cash_due, {
						"kind": "subscription_renewal_prepayment", "category": "saas", "source_id": service_id,
						"cash_timing": "renewal", "pnl_treatment": "straight_line_amortization",
						"amortization_weeks": int(spec.get("term_weeks", 52)),
						"normalized_weekly_expense": weekly_normalized,
						"auto_renew": true, "renewal_week": int(subscription.get("renewal_week", -1)),
					})
					subscription["cash_paid_to_date"] = float(subscription.get("cash_paid_to_date", 0.0)) + cash_due
					subscription["prepaid_through_week"] = int(subscription.get("renewal_week", -1))
					subscription["last_cash_outlay"] = cash_outlay.duplicate(true)
				outcomes.append({
					"kind": "subscription_renewed", "service_id": service_id,
					"billing": str(spec.get("billing", "weekly")), "cash_due": cash_due,
					"cash_outlay": cash_outlay,
					"pnl": {"basis": "weekly_accrual", "weekly_expense": weekly_normalized, "recognition": "straight_line" if str(spec.get("billing", "weekly")) == "annual_prepaid" else "as_incurred"},
					"commitment": _subscription_renewal_commitment(service_id, subscription, weekly_normalized),
				})
			else:
				var weekly_normalized := subscription_weekly_cost(service_id)
				outcomes.append({
					"kind": "subscription_renewal_due", "service_id": service_id,
					"cash_due": 0.0, "cash_outlay": {},
					"pnl": {"basis": "weekly_accrual", "weekly_expense": weekly_normalized},
					"commitment": _subscription_renewal_commitment(service_id, subscription, weekly_normalized),
				})
		# Usage services start a fresh metering week after the settled snapshot.
		if str(Dictionary(subscription.get("spec", {})).get("pricing_model", "")) == "usage":
			subscription["previous_week_usage"] = float(subscription.get("usage", 0.0))
			subscription["usage"] = 0.0
	return outcomes


func _update_people_risk() -> void:
	for employee_id_value in employees:
		var employee_id := str(employee_id_value)
		var employee: Dictionary = employees[employee_id]
		if not bool(employee.get("active", true)):
			continue
		var manager_id := str(employee.get("manager_id", ""))
		var overload := int(manager_span(manager_id).get("overload", 0)) if not manager_id.is_empty() else 0
		var burnout := float(employee.get("burnout", 0.0))
		burnout += float(overload) * 1.5
		burnout -= 1.0 if overload == 0 else 0.0
		if float(employee.get("ramp", 1.0)) < 1.0:
			burnout += 0.5
		burnout = clampf(burnout, 0.0, 100.0)
		employee["burnout"] = burnout
		var comp_gap := maxf(0.0, float(employee.get("market_salary", employee.get("salary_annual", 0.0))) - float(employee.get("salary_annual", 0.0)))
		var comp_ratio := comp_gap / maxf(1.0, float(employee.get("market_salary", 1.0)))
		var growth_gap := maxf(0.0, 50.0 - float(employee.get("growth_satisfaction", 50.0)))
		employee["flight_risk"] = clampf(burnout * 0.58 + comp_ratio * 35.0 + growth_gap * 0.35 + float(overload) * 4.0, 0.0, 100.0)


func _make_runtime_candidate(template: Dictionary) -> Dictionary:
	var candidate := template.duplicate(true)
	var competing_offer: Dictionary = Dictionary(candidate.get("competing_offer", {})).duplicate(true)
	if not competing_offer.is_empty():
		competing_offer["deadline_window_weeks"] = maxi(1, int(competing_offer.get("deadline_week", 3)))
		competing_offer["deadline_week"] = -1
		competing_offer["deadline_materialized"] = false
		candidate["competing_offer"] = competing_offer
	candidate["status"] = "available"
	candidate["requisition_id"] = ""
	candidate["available_after_week"] = -1
	candidate["interview_stage"] = "not_started"
	candidate["completed_interviews"] = []
	candidate["confidence"] = {"overall": 0.18}
	candidate["scorecard_results"] = {}
	candidate["interview_notes"] = []
	candidate["revealed_evidence"] = []
	return candidate


func _make_operations_employee(source: Dictionary) -> Dictionary:
	var source_skills: Dictionary = {}
	if source.get("skills", {}) is Dictionary:
		source_skills = Dictionary(source.get("skills", {})).duplicate(true)
	if source_skills.is_empty():
		var scalar_skill := clampf(float(source.get("skill", 60.0)) / 10.0, 0.0, 10.0)
		source_skills = {"management": 4.0}
		source_skills[_role_family_from_title(str(source.get("role", "")))] = scalar_skill
	var salary := float(source.get("salary_annual", _default_salary_for_level(int(source.get("level", 1)))))
	return {
		"id": str(source.get("id", "employee")), "name": str(source.get("name", "员工")),
		"role": str(source.get("role", source.get("role_title", "通才"))),
		"role_family": str(source.get("role_family", _role_family_from_title(str(source.get("role", ""))))),
		"level": clampi(int(source.get("level", 1)), 1, 6),
		"salary_annual": salary, "market_salary": float(source.get("market_salary", salary)),
		"equity_bps": maxf(0.0, float(source.get("equity_bps", 0.0))),
		"team_id": str(source.get("team_id", "founders")), "manager_id": str(source.get("manager_id", "")),
		"skills": source_skills, "ramp": clampf(float(source.get("ramp", 1.0)), 0.0, 1.0),
		"onboarding_weeks_remaining": maxi(0, int(source.get("onboarding_weeks_remaining", 0))),
		"burnout": clampf(float(source.get("burnout", 8.0)), 0.0, 100.0),
		"flight_risk": clampf(float(source.get("flight_risk", 5.0)), 0.0, 100.0),
		"growth_satisfaction": clampf(float(source.get("growth_satisfaction", 55.0)), 0.0, 100.0),
		"active": bool(source.get("active", true)), "joined_week": int(source.get("joined_week", current_week)),
	}


func _candidate_to_employee(candidate: Dictionary, terms: Dictionary, start_week: int) -> Dictionary:
	var actual_skills: Dictionary = Dictionary(candidate.get("actual_skills", {})).duplicate(true)
	var average_skill := 0.0
	for value in actual_skills.values():
		average_skill += float(value)
	average_skill = average_skill / float(maxi(1, actual_skills.size()))
	return {
		"id": "hire_%s" % str(candidate.get("id", "candidate")),
		"name": str(candidate.get("name", "候选人")),
		"role": str(terms.get("title", candidate.get("role_title", "员工"))),
		"role_family": str(candidate.get("role_family", "generalist")),
		"skill": average_skill * 10.0,
		"skills": actual_skills,
		"morale": 72.0, "belief": 72.0,
		"level": int(terms.get("level", 2)), "salary_annual": float(terms.get("salary", 0.0)),
		"market_salary": float(candidate.get("salary_target", terms.get("salary", 0.0))),
		"equity_bps": float(terms.get("equity_bps", 0.0)),
		"team_id": str(terms.get("team_id", "founders")), "manager_id": str(terms.get("manager_id", "")),
		"ramp": 0.35, "onboarding_weeks_remaining": 2, "burnout": 6.0, "flight_risk": 4.0,
		"growth_satisfaction": 68.0, "joined_week": start_week,
		"offer_terms": terms.duplicate(true),
	}


func _merge_roster_employee(record: Dictionary, source: Dictionary) -> void:
	record["name"] = str(source.get("name", record.get("name", "员工")))
	record["role"] = str(source.get("role", record.get("role", "通才")))
	for key in ["level", "salary_annual", "market_salary", "equity_bps", "team_id", "manager_id", "ramp", "onboarding_weeks_remaining", "burnout", "flight_risk", "growth_satisfaction"]:
		if source.has(key):
			record[key] = source[key]
	if source.get("skills", {}) is Dictionary and not Dictionary(source.get("skills", {})).is_empty():
		record["skills"] = Dictionary(source.get("skills", {})).duplicate(true)


func _score_candidate_stage(candidate: Dictionary, requisition: Dictionary, stage: String) -> Dictionary:
	var results: Dictionary = {}
	var actual_skills: Dictionary = candidate.get("actual_skills", {})
	for item_value in requisition.get("scorecard", []):
		if not item_value is Dictionary:
			continue
		var item: Dictionary = item_value
		if str(item.get("stage", "")) != stage:
			continue
		var item_id := str(item.get("id", "score"))
		var basis := _score_basis_for_item(item_id, actual_skills)
		var jitter := (_roll_unit() - 0.5) * 0.50
		results[item_id] = clampf(1.0 + (basis / 10.0) * 4.0 + jitter, 1.0, MAX_INTERVIEW_SCORE)
	return results


func _score_basis_for_item(item_id: String, skills: Dictionary) -> float:
	match item_id:
		"systems_depth", "execution", "response_discipline": return maxf(float(skills.get("engineering", 5.0)), float(skills.get("operations", 5.0)))
		"incident_judgment": return maxf(float(skills.get("operations", 5.0)), float(skills.get("risk", 5.0)))
		"research_depth": return float(skills.get("research", 5.0))
		"experimental_rigor": return maxf(float(skills.get("evaluation", 5.0)), float(skills.get("quality", 5.0)))
		"product_judgment": return maxf(float(skills.get("product", 5.0)), float(skills.get("design", 5.0)))
		"customer_evidence", "customer_trust": return float(skills.get("customer", 5.0))
		"data_systems": return maxf(float(skills.get("data", 5.0)), float(skills.get("engineering", 5.0)))
		"quality_judgment": return float(skills.get("quality", 5.0))
		"security_depth": return float(skills.get("security", 5.0))
		"risk_judgment": return float(skills.get("risk", 5.0))
		"design_craft": return float(skills.get("design", 5.0))
		"systems_thinking": return maxf(float(skills.get("systems", 5.0)), float(skills.get("engineering", 5.0)))
		"commercial_judgment": return float(skills.get("sales", 5.0))
		"forecast_discipline": return float(skills.get("forecast", 5.0))
		"people_judgment": return float(skills.get("people", 5.0))
		"process_design": return maxf(float(skills.get("process", 5.0)), float(skills.get("management", 5.0)))
		"confidentiality": return maxf(float(skills.get("people", 5.0)), float(skills.get("risk", 5.0)))
		"team_leverage", "collaboration": return float(skills.get("management", 5.0))
		"clear_communication": return float(skills.get("communication", 6.0))
	return 5.0


func _select_candidates_for_requisition(role_family: String, requested_ids: Array) -> Array[String]:
	var selected: Array[String] = []
	for requested_id_value in requested_ids:
		var requested_id := str(requested_id_value)
		if selected.size() >= 3:
			break
		if candidates.has(requested_id) and not selected.has(requested_id):
			var requested: Dictionary = candidates[requested_id]
			if str(requested.get("status", "")) != "available" or str(requested.get("role_family", "")) != role_family:
				continue
			selected.append(requested_id)
	var available_ids: Array = candidates.keys()
	available_ids.sort()
	for candidate_id_value in available_ids:
		if selected.size() >= 3:
			break
		var candidate_id := str(candidate_id_value)
		var candidate: Dictionary = candidates[candidate_id]
		if selected.has(candidate_id) or str(candidate.get("status", "")) != "available":
			continue
		if str(candidate.get("role_family", "")) == role_family:
			selected.append(candidate_id)
	return selected


func _offer_rejection_reason(candidate: Dictionary, terms: Dictionary, score: float) -> String:
	if current_week > int(Dictionary(candidate.get("competing_offer", {})).get("deadline_week", current_week)):
		return "deadline_lost"
	if float(terms.get("salary", 0.0)) < float(candidate.get("salary_target", 0.0)) * 0.90:
		return "salary_below_expectation"
	if float(terms.get("equity_bps", 0.0)) < float(candidate.get("equity_target_bps", 0.0)) * 0.60:
		return "equity_below_expectation"
	if score < 0.45:
		return "role_or_company_fit"
	return "competing_offer"


func _close_requisition(requisition_id: String, selected_candidate_id: String) -> void:
	var index := _find_requisition(requisition_id)
	if index < 0:
		return
	var requisition: Dictionary = requisitions[index]
	requisition["status"] = "filled_pending_start"
	requisition["selected_candidate_id"] = selected_candidate_id
	requisition["focus_candidate_id"] = selected_candidate_id
	_cleanup_requisition_funnel(requisition, selected_candidate_id, "requisition_filled")


func _activate_requisition_candidate(requisition: Dictionary, candidate_id: String) -> Dictionary:
	if not candidates.has(candidate_id) or str(requisition.get("status", "")) != "open":
		return {}
	var candidate: Dictionary = candidates[candidate_id]
	if str(candidate.get("role_family", "")) != str(requisition.get("role_family", "")):
		return {}
	if str(candidate.get("status", "")) not in ["available", "shortlisted"]:
		return {}
	_reset_candidate_interviews(candidate)
	candidate["status"] = "in_process"
	candidate["requisition_id"] = str(requisition.get("id", ""))
	candidate["activated_week"] = current_week
	candidate["available_after_week"] = -1
	var competing_offer: Dictionary = Dictionary(candidate.get("competing_offer", {})).duplicate(true)
	var deadline_week := -1
	if not competing_offer.is_empty():
		var window_weeks := maxi(1, int(competing_offer.get("deadline_window_weeks", 3)))
		deadline_week = current_week + INTERVIEW_STAGES.size() + 1 + window_weeks
		competing_offer["deadline_window_weeks"] = window_weeks
		competing_offer["deadline_week"] = deadline_week
		competing_offer["deadline_materialized"] = true
		candidate["competing_offer"] = competing_offer
	requisition["focus_candidate_id"] = candidate_id
	return {
		"kind": "candidate_focus_activated", "candidate_id": candidate_id,
		"requisition_id": str(requisition.get("id", "")), "activated_week": current_week,
		"deadline_week": deadline_week,
	}


func _activate_next_shortlisted(requisition_id: String, reason: String) -> Dictionary:
	var index := _find_requisition(requisition_id)
	if index < 0:
		return {}
	var requisition: Dictionary = requisitions[index]
	if str(requisition.get("status", "")) != "open":
		return {}
	requisition["focus_candidate_id"] = ""
	for candidate_id_value in requisition.get("candidate_ids", []):
		var candidate_id := str(candidate_id_value)
		if not candidates.has(candidate_id):
			continue
		var candidate: Dictionary = candidates[candidate_id]
		if str(candidate.get("status", "")) == "shortlisted" and str(candidate.get("requisition_id", "")) == requisition_id:
			var activated := _activate_requisition_candidate(requisition, candidate_id)
			activated["activation_reason"] = reason
			return activated
	requisition["status"] = "exhausted"
	requisition["closed_week"] = current_week
	requisition["close_reason"] = reason
	return {"kind": "requisition_exhausted", "requisition_id": requisition_id, "reason": reason}


func _release_candidate(candidate: Dictionary, reason: String) -> void:
	var requisition_id := str(candidate.get("requisition_id", ""))
	candidate["status"] = "released"
	candidate["last_requisition_id"] = requisition_id
	candidate["requisition_id"] = ""
	candidate["released_week"] = current_week
	candidate["release_reason"] = reason
	candidate["available_after_week"] = current_week + RELEASED_CANDIDATE_COOLDOWN_WEEKS
	var competing_offer: Dictionary = Dictionary(candidate.get("competing_offer", {})).duplicate(true)
	if not competing_offer.is_empty():
		competing_offer["deadline_week"] = -1
		competing_offer["deadline_materialized"] = false
		candidate["competing_offer"] = competing_offer


func _cleanup_requisition_funnel(requisition: Dictionary, selected_candidate_id: String, reason: String) -> void:
	for candidate_id_value in requisition.get("candidate_ids", []):
		var candidate_id := str(candidate_id_value)
		if candidate_id == selected_candidate_id or not candidates.has(candidate_id):
			continue
		var candidate: Dictionary = candidates[candidate_id]
		if str(candidate.get("status", "")) in ["shortlisted", "in_process", "offer_pending"]:
			_release_candidate(candidate, reason)


func _refresh_released_candidates() -> Array:
	var outcomes: Array = []
	var candidate_ids: Array = candidates.keys()
	candidate_ids.sort()
	for candidate_id_value in candidate_ids:
		var candidate_id := str(candidate_id_value)
		var candidate: Dictionary = candidates[candidate_id]
		if str(candidate.get("status", "")) != "released" or current_week < int(candidate.get("available_after_week", 999999)):
			continue
		_reset_candidate_interviews(candidate)
		candidate["status"] = "available"
		candidate["requisition_id"] = ""
		candidate["available_after_week"] = -1
		outcomes.append({
			"kind": "candidate_returned_to_market", "candidate_id": candidate_id,
			"role_family": str(candidate.get("role_family", "")), "week": current_week,
		})
	return outcomes


func _expire_due_focus_candidates() -> Array:
	var outcomes: Array = []
	for requisition_value in requisitions:
		if not requisition_value is Dictionary:
			continue
		var requisition: Dictionary = requisition_value
		if str(requisition.get("status", "")) != "open":
			continue
		var candidate_id := str(requisition.get("focus_candidate_id", ""))
		if candidate_id.is_empty() or not candidates.has(candidate_id):
			continue
		var candidate: Dictionary = candidates[candidate_id]
		var competing: Dictionary = candidate.get("competing_offer", {})
		if str(candidate.get("status", "")) != "in_process" or not bool(competing.get("deadline_materialized", false)):
			continue
		if current_week <= int(competing.get("deadline_week", 999999)):
			continue
		_release_candidate(candidate, "deadline_lost")
		outcomes.append({"kind": "candidate_deadline_expired", "candidate_id": candidate_id, "requisition_id": str(requisition.get("id", ""))})
		var next := _activate_next_shortlisted(str(requisition.get("id", "")), "candidate_deadline_expired")
		if not next.is_empty():
			outcomes.append(next)
	return outcomes


func _reset_candidate_interviews(candidate: Dictionary) -> void:
	var candidate_id := str(candidate.get("id", ""))
	var template: Dictionary = CANDIDATE_TEMPLATES.get(candidate_id, {})
	if not template.is_empty():
		candidate["unknowns"] = Array(template.get("unknowns", [])).duplicate()
		candidate["skill_evidence"] = Array(template.get("skill_evidence", [])).duplicate()
	candidate["interview_stage"] = "not_started"
	candidate["completed_interviews"] = []
	candidate["confidence"] = {"overall": 0.18}
	candidate["scorecard_results"] = {}
	candidate["interview_notes"] = []
	candidate["revealed_evidence"] = []
	var competing_offer: Dictionary = Dictionary(candidate.get("competing_offer", {})).duplicate(true)
	if not competing_offer.is_empty():
		competing_offer["deadline_week"] = -1
		competing_offer["deadline_materialized"] = false
		candidate["competing_offer"] = competing_offer


func _repair_requisition_focuses() -> void:
	for requisition_value in requisitions:
		if not requisition_value is Dictionary:
			continue
		var requisition: Dictionary = requisition_value
		if str(requisition.get("status", "")) != "open":
			continue
		var focus_id := str(requisition.get("focus_candidate_id", ""))
		if focus_id.is_empty():
			for candidate_id_value in requisition.get("candidate_ids", []):
				var candidate_id := str(candidate_id_value)
				if candidates.has(candidate_id) and str(Dictionary(candidates[candidate_id]).get("status", "")) in ["in_process", "offer_pending"]:
					focus_id = candidate_id
					break
		requisition["focus_candidate_id"] = focus_id
		for candidate_id_value in requisition.get("candidate_ids", []):
			var candidate_id := str(candidate_id_value)
			if candidate_id == focus_id or not candidates.has(candidate_id):
				continue
			var candidate: Dictionary = candidates[candidate_id]
			if str(candidate.get("status", "")) == "in_process":
				candidate["status"] = "shortlisted"
				var competing: Dictionary = Dictionary(candidate.get("competing_offer", {})).duplicate(true)
				competing["deadline_week"] = -1
				competing["deadline_materialized"] = false
				candidate["competing_offer"] = competing


func _rebuild_commitments() -> void:
	var rebuilt: Array = []
	for employee_id_value in employees:
		var employee_id := str(employee_id_value)
		var employee: Dictionary = employees[employee_id]
		if bool(employee.get("active", true)):
			rebuilt.append({
				"id": "employment:%s" % employee_id, "kind": "employment", "counterparty_id": employee_id,
				"start_week": int(employee.get("joined_week", current_week)), "end_week": -1,
				"upfront_cost": 0.0, "weekly_cost": float(employee.get("salary_annual", 0.0)) / WEEKS_PER_YEAR,
				"billing": "weekly", "risk_tags": ["payroll"],
			})
	for lease_key in ["active_lease", "signed_lease"]:
		var lease: Dictionary = office.get(lease_key, {})
		if lease.is_empty():
			continue
		rebuilt.append({
			"id": "lease:%s" % str(lease.get("id", "")), "kind": "lease", "counterparty_id": str(lease.get("id", "")),
			"start_week": int(lease.get("start_week", current_week)), "end_week": int(lease.get("end_week", -1)),
			"upfront_cost": float(lease.get("deposit", 0.0)), "weekly_cost": float(lease.get("weekly_rent", 0.0)),
			"billing": "weekly", "risk_tags": [str(lease.get("kind", "lease")), str(lease.get("status", lease_key))],
			"cash_payment_schedule": {"deposit_paid_week": int(lease.get("signed_week", current_week)), "deposit": float(lease.get("deposit", 0.0))},
			"pnl_recognition": {"basis": "weekly_accrual", "weekly_expense": float(lease.get("weekly_rent", 0.0)), "starts_week": int(lease.get("start_week", current_week))},
		})
	for service_id_value in subscriptions:
		var service_id := str(service_id_value)
		var subscription: Dictionary = subscriptions[service_id]
		if str(subscription.get("status", "active")) == "cancelled":
			continue
		var spec: Dictionary = subscription.get("spec", {})
		var normalized := subscription_weekly_cost(service_id)
		var renewal_commitment := _subscription_renewal_commitment(service_id, subscription, normalized)
		rebuilt.append({
			"id": "subscription:%s" % service_id, "kind": "subscription", "counterparty_id": service_id,
			"start_week": int(subscription.get("start_week", current_week)), "end_week": int(subscription.get("renewal_week", -1)),
			"upfront_cost": normalized * float(spec.get("term_weeks", 0)) if str(spec.get("billing", "weekly")) == "annual_prepaid" else 0.0,
			"weekly_cost": normalized, "billing": str(spec.get("billing", "weekly")),
			"risk_tags": [str(spec.get("category", "software")), str(spec.get("pricing_model", "per_seat"))],
			"cash_payment_schedule": {
				"timing": "prepaid_on_signing_and_renewal" if str(spec.get("billing", "weekly")) == "annual_prepaid" else "weekly",
				"last_paid": float(Dictionary(subscription.get("last_cash_outlay", {})).get("amount", 0.0)),
				"next_payment_week": int(subscription.get("renewal_week", -1)),
				"next_payment_estimate": float(renewal_commitment.get("renewal_cash_estimate", 0.0)),
			},
			"pnl_recognition": {
				"basis": "weekly_accrual",
				"treatment": "straight_line_amortization" if str(spec.get("billing", "weekly")) == "annual_prepaid" else "as_incurred",
				"weekly_expense": normalized,
			},
			"renewal": renewal_commitment,
		})
	commitments = rebuilt


func _subscription_renewal_commitment(service_id: String, subscription: Dictionary, weekly_normalized: float) -> Dictionary:
	var spec: Dictionary = subscription.get("spec", {})
	var billing := str(spec.get("billing", "weekly"))
	var renewal_cash_estimate := weekly_normalized * float(spec.get("term_weeks", 52)) if billing == "annual_prepaid" else weekly_normalized
	return {
		"service_id": service_id,
		"status": str(subscription.get("status", "active")),
		"auto_renew": bool(subscription.get("auto_renew", false)),
		"renewal_week": int(subscription.get("renewal_week", -1)),
		"renewal_cash_estimate": renewal_cash_estimate,
		"billing": billing,
		"committed": bool(subscription.get("auto_renew", false)) and str(subscription.get("status", "active")) == "active",
	}


func _auto_provision_active_roster() -> void:
	for service_id_value in subscriptions:
		var service_id := str(service_id_value)
		var subscription: Dictionary = subscriptions[service_id]
		if not bool(Dictionary(subscription.get("spec", {})).get("auto_provision", false)):
			continue
		for employee_id in _active_employee_ids():
			provision_user(service_id, employee_id)


func _ensure_team_membership(employee_id: String, team_id: String) -> void:
	if not teams.has(team_id):
		teams[team_id] = {"id": team_id, "name": team_id, "manager_id": "", "member_ids": []}
	_remove_from_all_teams(employee_id)
	var team: Dictionary = teams[team_id]
	var members: Array = Array(team.get("member_ids", [])).duplicate()
	if not members.has(employee_id):
		members.append(employee_id)
	team["member_ids"] = members


func _remove_from_all_teams(employee_id: String) -> void:
	for team_value in teams.values():
		if not team_value is Dictionary:
			continue
		var team: Dictionary = team_value
		var members: Array = Array(team.get("member_ids", [])).duplicate()
		members.erase(employee_id)
		team["member_ids"] = members


func _would_create_manager_cycle(employee_id: String, manager_id: String) -> bool:
	var cursor := manager_id
	var visited: Dictionary = {}
	while not cursor.is_empty() and employees.has(cursor):
		if cursor == employee_id or visited.has(cursor):
			return true
		visited[cursor] = true
		cursor = str(Dictionary(employees[cursor]).get("manager_id", ""))
	return false


func _active_employee_ids() -> Array[String]:
	var ids: Array[String] = []
	for employee_id_value in employees:
		var employee_id := str(employee_id_value)
		if bool(Dictionary(employees[employee_id]).get("active", true)):
			ids.append(employee_id)
	return ids


func _active_candidate_count() -> int:
	var count := 0
	for candidate_value in candidates.values():
		if candidate_value is Dictionary and str(Dictionary(candidate_value).get("status", "")) in ["shortlisted", "in_process", "offer_pending", "accepted", "ready_to_join"]:
			count += 1
	return count


func _candidate_overall_confidence(candidate: Dictionary) -> float:
	return clampf(float(Dictionary(candidate.get("confidence", {})).get("overall", 0.18)), 0.0, 1.0)


func _find_requisition(requisition_id: String) -> int:
	for index in requisitions.size():
		if str(Dictionary(requisitions[index]).get("id", "")) == requisition_id:
			return index
	return -1


func _requisition_by_id(requisition_id: String) -> Dictionary:
	var index := _find_requisition(requisition_id)
	return Dictionary(requisitions[index]) if index >= 0 else {}


func _requisition_id_for_offer(offer_id: String) -> String:
	for offer_value in offers:
		if offer_value is Dictionary and str(Dictionary(offer_value).get("id", "")) == offer_id:
			return str(Dictionary(offer_value).get("requisition_id", ""))
	return ""


func _role_family_from_title(title: String) -> String:
	var lowered := title.to_lower()
	if "数据" in title: return "data"
	if "研究" in title or "research" in lowered: return "research"
	if "基础设施" in title or "平台" in title or "infra" in lowered: return "infrastructure"
	if "安全" in title or "security" in lowered: return "security"
	if "产品" in title or "product" in lowered: return "product"
	if "设计" in title or "design" in lowered: return "design"
	if "商务" in title or "销售" in title or "sales" in lowered: return "sales"
	if "人才" in title or "people" in lowered: return "people"
	return "generalist"


func _default_salary_for_level(level: int) -> float:
	return [0.0, 30.0, 40.0, 50.0, 62.0, 78.0, 96.0][clampi(level, 1, 6)]


func _append_event_if_ready(result: Array, event: Dictionary, week: int) -> void:
	var event_id := str(event.get("id", ""))
	if week >= int(event_cooldowns.get(event_id, -1)):
		result.append(event)


func _add_cash_outlay(amount: float, detail: Dictionary = {}) -> Dictionary:
	var key := str(current_week)
	var normalized_amount := maxf(0.0, amount)
	week_cash_outlays[key] = float(week_cash_outlays.get(key, 0.0)) + normalized_amount
	var records: Array = Array(week_cash_outlay_records.get(key, [])).duplicate(true)
	var record := detail.duplicate(true)
	record["id"] = str(record.get("id", "outlay:%d:%03d" % [current_week, records.size() + 1]))
	record["week"] = current_week
	record["amount"] = normalized_amount
	record["currency_unit"] = "ten_thousand_cny"
	if not record.has("cash_timing"):
		record["cash_timing"] = "current_week"
	if not record.has("pnl_treatment"):
		record["pnl_treatment"] = "as_incurred"
	records.append(record)
	week_cash_outlay_records[key] = records
	return record.duplicate(true)


func _cash_outlays_between(first_week: int, last_week: int) -> Array:
	var result: Array = []
	for week in range(first_week, last_week + 1):
		result.append_array(Array(week_cash_outlay_records.get(str(week), [])).duplicate(true))
	return result


func _commitment_changes_from_outcomes(outcomes: Array) -> Array:
	var changes: Array = []
	for outcome_value in outcomes:
		if not outcome_value is Dictionary:
			continue
		var outcome: Dictionary = outcome_value
		if str(outcome.get("kind", "")) in ["subscription_renewed", "subscription_renewal_due", "subscription_cancelled", "office_move_in", "office_lease_expired"]:
			changes.append(outcome.duplicate(true))
	return changes


func _roll_unit() -> float:
	var normalized := float(rng_state - 1) / float(RNG_MODULUS - 1)
	rng_state = int((rng_state * RNG_MULTIPLIER) % RNG_MODULUS)
	if rng_state <= 0:
		rng_state = RNG_INITIAL_STATE
	return normalized


func _record_history(kind: String, payload: Dictionary = {}) -> void:
	history.append({"kind": kind, "week": current_week, "payload": payload.duplicate(true)})


func _safe_public_payload(payload: Dictionary) -> Dictionary:
	var safe := payload.duplicate(true)
	for key in PROTECTED_ATTRIBUTE_KEYS:
		safe.erase(key)
	return safe


func _dictionary_array(value) -> Array:
	var result: Array = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				result.append(Dictionary(entry).duplicate(true))
	return result


func _failure(reason: String, subject: String = "") -> Dictionary:
	return {"ok": false, "reason": reason, "subject": subject}
