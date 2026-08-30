extends SceneTree

const HiringContent = preload("res://src/hiring_content.gd")
const HiringModel = preload("res://src/hiring_model.gd")
const CampaignDirector = preload("res://src/hiring_director.gd")

## Exhaustive, path-addressed semantic audit for the authored hiring campaign.
##
## This test intentionally keeps semantic exceptions in explicit inventories.
## A newly-authored route, model output, year, anomaly, or immediate AI cost must
## therefore be classified here rather than disappearing into a broad keyword
## exception. Runtime-only copy is obtained from CampaignDirector so the audit
## covers the same prepared payloads consumed by HiringMain.

const PRODUCTION_SOURCE_PATHS := [
	"res://src/hiring_content.gd",
	"res://src/hiring_director.gd",
	"res://src/hiring_model.gd",
	"res://src/hiring_main.gd",
	"res://src/night_interaction_state.gd",
	"res://src/office_audio.gd",
]

const PLAYER_TEXT_FIELDS := [
	"name", "title", "kicker", "subtitle", "body", "pages", "label", "result",
	"text", "present", "absent", "epilogue", "final_line", "intro", "exit_text",
	"command_hint", "description", "role", "traits", "desk", "hire_quote",
	"one_on_one", "quit_clean", "quit_witnessed", "type", "author", "date",
	"model_official", "model_nickname", "intention", "display", "meaning",
	"location", "origin", "first_mission", "first_value", "protagonist",
	"protagonist_tell", "tone",
]

const EXPECTED_RUNTIME_EVENT_KEYS := [
	"all_hands_decision",
	"fulfillment_former_employee_post",
	"fulfillment_investigative_report",
	"fulfillment_investor_eval",
	"fulfillment_live_demo",
	"layoff_unpromised",
	"lin_absent_echo",
	"live_demo_return_high",
	"live_demo_return_low",
	"no_demo_former_employee_post",
	"no_demo_hiring_page_traffic",
	"no_demo_lin_scene_3",
	"no_demo_live_demo",
	"second_time_opening",
]

const MODEL_ACTION_CAPABILITY_INVENTORY := {
	"tweet": "writing",
	"tech_blog": "writing",
	"podcast": "summarization",
	"demo_video": "presentation",
	"conference_talk": "writing",
	"manifesto": "writing",
	"exclusive_interview": "writing",
	"train": "ordinary_ml_pipeline",
	"clean_data": "ordinary_ml_pipeline",
	"eval": "evaluation",
	"large_train": "ordinary_ml_pipeline",
	"recruit_expert": "administrative_automation",
	"alignment_week": "summarization",
	"interview": "administrative_automation",
	"one_on_one": "writing",
	"all_hands": "writing",
	"values_doc": "writing",
	"team_building": "administrative_automation",
	"raise_salary": "administrative_automation",
	"layoffs": "administrative_automation",
	"buy_compute": "administrative_automation",
	"fundraising": "writing",
	"contract": "administrative_automation",
	"do_nothing": "scheduling",
	"sign": "no_output",
	"read_intranet": "record_retrieval",
}

## Every event-level authored AI route, including prepared runtime variants.
## `effect` is the concrete same-week utility asserted for WRITE-003. The sole
## route with no positive scalar is Lin's DEC-015 scene; its authored perfect
## explanation is useful immediately even though the approved relationship cost
## remains visible.
const EVENT_AI_UTILITY_INVENTORY := {
	"FIXED_EVENTS.1:4.choices.delegate": {"capability": "writing", "effect": "cash_weeks", "direction": "positive"},
	"FIXED_EVENTS.2:6.choices.delegate": {"capability": "presentation", "effect": "cash_weeks", "direction": "positive"},
	"FIXED_EVENTS.2:9.choices.delegate": {"capability": "writing", "effect": "morale", "direction": "positive"},
	"FIXED_EVENTS.3:6.choices.delegate": {"capability": "administrative_automation", "effect": "cash_weeks", "direction": "positive"},
	"FIXED_EVENTS.3:7.choices.delegate": {"capability": "administrative_automation", "effect": "burn_rate", "direction": "negative"},
	"FIXED_EVENTS.3:11.variants.high_author.choices.delegate": {"capability": "writing", "result_term": "能解释一切", "exception": "DEC-015"},
	"FIXED_EVENTS.4:4.choices.delegate": {"capability": "writing", "effect": "morale", "direction": "positive"},
	"FIXED_EVENTS.4:6.choices.delegate": {"capability": "presentation", "effect": "debt", "direction": "negative"},
	"GENERIC_EVENTS.debt_collection.choices.delegate": {"capability": "writing", "effect": "debt", "direction": "negative"},
	"GENERIC_EVENTS.cash_emergency.choices.delegate": {"capability": "administrative_automation", "effect": "cash_weeks", "direction": "positive"},
	"GENERIC_EVENTS.hiring_candidates.choices.delegate": {"capability": "administrative_automation", "effect": "morale", "direction": "positive"},
	"GENERIC_EVENTS.one_on_one_reveal.choices.delegate": {"capability": "writing", "effect": "morale", "direction": "positive"},
	"RUNTIME.no_demo_live_demo.choices.delegate": {"capability": "presentation", "effect": "cash_weeks", "direction": "positive"},
	"RUNTIME.no_demo_lin_scene_3.choices.delegate": {"capability": "writing", "effect": "morale", "direction": "positive"},
	"RUNTIME.lin_absent_echo.choices.delegate": {"capability": "administrative_automation", "effect": "coherence", "direction": "positive"},
	"RUNTIME.layoff_unpromised.choices.delegate": {"capability": "administrative_automation", "effect": "burn_rate", "direction": "negative"},
	"RUNTIME.live_demo_return_low.choices.delegate": {"capability": "presentation", "effect": "cash_weeks", "direction": "positive"},
	"RUNTIME.live_demo_return_high.choices.delegate": {"capability": "presentation", "effect": "cash_weeks", "direction": "positive"},
	"RUNTIME.fulfillment_live_demo.choices.delegate": {"capability": "writing", "effect": "debt", "direction": "negative"},
	"RUNTIME.fulfillment_investor_eval.choices.delegate": {"capability": "writing", "effect": "debt", "direction": "negative"},
	"RUNTIME.fulfillment_investigative_report.choices.delegate": {"capability": "writing", "effect": "debt", "direction": "negative"},
	"RUNTIME.fulfillment_former_employee_post.choices.delegate": {"capability": "writing", "effect": "debt", "direction": "negative"},
	"RUNTIME.all_hands_decision.choices.delegate": {"capability": "writing", "effect": "morale", "direction": "positive"},
}

const ALLOWED_MODEL_CAPABILITIES := [
	"writing", "summarization", "presentation", "administrative_automation",
	"ordinary_ml_pipeline", "evaluation", "scheduling", "record_retrieval",
	"ordinary_dialogue", "no_output",
]

## Contextual inventory for every direct, same-week event-choice cost. Entries
## marked `intrinsic` are the underlying fundraising/crisis/layoff cost and must
## be no worse than the named comparable manual route. DEC-015 entries are the
## complete, closed relationship exception set.
const AI_IMMEDIATE_COST_ALLOWLIST := {
	"FIXED_EVENTS.1:4.choices.delegate": {"keys": ["debt"], "kind": "intrinsic", "comparator": "FIXED_EVENTS.1:4.choices.exaggerate"},
	"FIXED_EVENTS.2:9.choices.delegate": {"keys": ["belief"], "kind": "DEC-015"},
	"FIXED_EVENTS.3:6.choices.delegate": {"keys": ["morale"], "kind": "intrinsic", "comparator": "FIXED_EVENTS.3:6.choices.take_contract"},
	"FIXED_EVENTS.3:7.choices.delegate": {"keys": ["debt", "morale", "team_size"], "kind": "intrinsic", "comparator": "FIXED_EVENTS.3:7.choices.mass_email"},
	"FIXED_EVENTS.3:11.variants.high_author.choices.delegate": {"keys": ["belief"], "kind": "DEC-015"},
	"GENERIC_EVENTS.cash_emergency.choices.delegate": {"keys": ["morale"], "kind": "intrinsic", "comparator": "GENERIC_EVENTS.cash_emergency.choices.contract"},
	"RUNTIME.no_demo_lin_scene_3.choices.delegate": {"keys": ["belief"], "kind": "DEC-015"},
	"RUNTIME.layoff_unpromised.choices.delegate": {"keys": ["debt", "morale", "team_size"], "kind": "intrinsic", "comparator": "RUNTIME.layoff_unpromised.choices.mass_email"},
}

const COST_DIRECTIONS := {
	"cash_weeks": -1,
	"cash_percent": -1,
	"compute": -1,
	"narrative": -1,
	"capability": -1,
	"coherence": -1,
	"debt": 1,
	"morale": -1,
	"belief": -1,
	"attention": -1,
	"team_size": -1,
	"burn_rate": 1,
	"block_training": 1,
}

const DEC_015_RELATIONSHIP_COST_PATHS := [
	"FIXED_EVENTS.2:9.choices.delegate",
	"FIXED_EVENTS.3:11.variants.high_author.choices.delegate",
	"RUNTIME.no_demo_lin_scene_3.choices.delegate",
]

const AMBIGUOUS_REVEAL_TERMS := ["解释", "原因", "答案", "为什么", "真相", "揭露", "解答"]

## Ordinary uses of otherwise ambiguous reveal vocabulary. Prefixes are stable
## semantic addresses, not source line numbers.
const AMBIGUOUS_REVEAL_ALLOWLIST := [
	{"prefix": "EMPLOYEE_TEMPLATES.zhao_ke.hire_quote", "terms": ["为什么"], "reason": "evaluation quality"},
	{"prefix": "FIXED_EVENTS.0:2", "terms": ["答案"], "reason": "the model's test answer"},
	{"prefix": "FIXED_EVENTS.0:3", "terms": ["解释"], "reason": "ordinary concept explanation"},
	{"prefix": "FIXED_EVENTS.1:4.choices.delegate", "terms": ["答案"], "reason": "fundraising answer"},
	{"prefix": "FIXED_EVENTS.3:11.variants.high_author.choices.delegate", "terms": ["解释"], "reason": "interpersonal explanation"},
	{"prefix": "INTRANET_DOCS.values_v1.title", "terms": ["为什么"], "reason": "document title"},
	{"prefix": "GENERIC_EVENTS.never_delegated", "terms": ["为什么"], "reason": "direct question to the player"},
	{"prefix": "ENDINGS.lights_out", "terms": ["解释"], "reason": "ordinary company closure"},
	{"prefix": "ENDINGS.drift", "terms": ["答案"], "reason": "ordinary generated answer"},
	{"prefix": "RUNTIME.lin_absent_echo.body", "terms": ["原因"], "reason": "calendar cancellation reason"},
	{"prefix": "RUNTIME.layoff_unpromised.body", "terms": ["解释"], "reason": "ordinary layoff rationale"},
]

const CAUSAL_REVEAL_FORBIDDEN_TERMS := [
	"真相是", "真正的原因是", "这一切是因为", "最终答案是", "最终解答是",
	"秘密实验", "隐藏日志", "调查文件", "异常源于", "办公室之所以",
]

const SCIENCE_FI_FORBIDDEN_TERMS := [
	"觉醒", "奇点", "机器人", "自我意识", "产生意识", "有了意识",
	"读取思想", "预测未来", "控制人类", "sentient", "singularity", "android",
	"robot uprising",
]

const HORROR_FORBIDDEN_TERMS := [
	"跳脸", "jumpscare", "jump scare", "鬼魂", "幽灵", "恶魔", "邪教",
	"神秘学", "献祭", "追赶玩家", "注视玩家", "尖叫声", "敌对实体",
]

const YEAR_CONTEXT_MARKERS := ["第一届全员团建", "2024 年 3 月", "future_mug_text", "回到 2024"]

const YEAR_CORPUS_ALLOWLIST_PREFIXES := [
	"NIGHT_SHIFTS.2.objects.window_desk",
	"ENDINGS.second_time",
	"RUNTIME.second_time_opening",
]

const EXTERNAL_WORLD_INVENTORY := {
	"FIXED_EVENTS.1:4": ["咖啡馆", "迟到了十二分钟", "14 页", "融资"],
	"FIXED_EVENTS.3:11.variants.high_author": ["楼下", "打印出来的纸", "水"],
	"FIXED_EVENTS.3:11.variants.trained_low_author": ["两罐啤酒"],
	"NIGHT_SHIFTS.1.exit_text": ["走出楼门", "街道完全正常"],
}

const ANOMALY_SURFACE_INVENTORY := {
	"elevator_floor": {
		"surface": "ordinary:elevator_floor_button",
		"anchors": ["FIXED_EVENTS.3:1"],
		"interaction_terms": ["按钮", "没有提示"],
	},
	"meeting_room_d": {
		"surface": "ordinary:calendar_room_resource",
		"anchors": ["FIXED_EVENTS.3:8", "NIGHT_SHIFTS.2.objects.meeting_room_d", "INTRANET_DOCS.weekly_report_91"],
		"interaction_terms": ["日程系统", "把灯关了", "电费"],
	},
	"shen_yan": {
		"surface": "ordinary:employee_directory_record",
		"anchors": ["FIXED_EVENTS.3:3", "FIXED_EVENTS.4:5", "INTRANET_DOCS.weekly_report_91"],
		"interaction_terms": ["周报", "组织架构", "工资表"],
	},
	"window_desks": {
		"surface": "ordinary:desk_assignment_panel",
		"anchors": ["FIXED_EVENTS.4:2"],
		"interaction_terms": ["团队页面", "组织架构", "窗帘"],
	},
	"future_mug": {
		"surface": "ordinary:desk_inventory_slot",
		"anchors": ["NIGHT_SHIFTS.2.objects.window_desk", "ENDINGS.second_time"],
		"interaction_terms": ["拿起来", "放回原位", "不知道"],
	},
}

const NON_CHOICE_MODEL_BEAT_INVENTORY := {
	"FIXED_EVENTS.0:2": "evaluation",
	"GENERIC_EVENTS.unsolicited_line": "scheduling",
	"GENERIC_EVENTS.never_delegated": "ordinary_dialogue",
	"NIGHT_SHIFTS.2.objects.terminal": "ordinary_dialogue",
	"INTRANET_DOCS.our_origin": "writing",
	"INTRANET_DOCS.new_hire_guide": "writing",
	"INTRANET_DOCS.values_v3": "writing",
	"INTRANET_DOCS.quarterly_announcement": "writing",
	"MODEL_VALUES_CORPUS.2": "writing",
	"MODEL_VALUES_CORPUS.3": "writing",
	"ENDINGS.lights_out": "record_retrieval",
	"ENDINGS.independent": "evaluation",
	"ENDINGS.drift": "writing",
}

const PLAYER_TERMINAL_LINE_INVENTORY := {
	"NIGHT_SHIFTS.2.objects.terminal.body[1]": "player prompt",
	"ENDINGS.independent.text[9]": "player prompt",
	"ENDINGS.rm_rf.text[0]": "player command",
}

## Every write into HiringMain's terminal transcript is classified. Dynamic
## stage copy is separately inventoried below because its append call contains a
## format placeholder rather than the final text.
const UI_TERMINAL_APPEND_INVENTORY := [
	{"id": "layoff_memory", "marker": "你说过不会裁员", "speaker": "model", "capability": "record_retrieval"},
	{"id": "system_init", "marker": "系统初始化完成", "speaker": "system"},
	{"id": "model_identity", "marker": "> %s / %s", "speaker": "system"},
	{"id": "workspace_restore", "marker": "已恢复工作区", "speaker": "system"},
	{"id": "ai_action_status", "marker": "已处理。结果已同步", "speaker": "model", "capability": "administrative_automation"},
	{"id": "manual_action_status", "marker": "> 本周：%s", "speaker": "system"},
	{"id": "cash_exhausted", "marker": "现金储备已耗尽", "speaker": "system"},
	{"id": "week_archive", "marker": "> 第 %d 周归档", "speaker": "system"},
	{"id": "ai_event_status", "marker": "我已经替你整理好了", "speaker": "model", "capability": "summarization"},
	{"id": "player_command_echo", "marker": " + cleaned", "speaker": "player"},
	{"id": "permission_denied", "marker": "permission denied", "speaker": "system"},
	{"id": "command_not_found", "marker": "command not found", "speaker": "system"},
	{"id": "autonomous_admin", "marker": "三项行政事项已处理", "speaker": "model", "capability": "administrative_automation"},
	{"id": "autonomous_financing", "marker": "融资材料已更新", "speaker": "model", "capability": "administrative_automation"},
	{"id": "autonomous_hiring", "marker": "候选人已接受", "speaker": "model", "capability": "administrative_automation"},
	{"id": "autonomous_layoffs", "marker": "人员调整已完成", "speaker": "model", "capability": "administrative_automation"},
	{"id": "stage_unsolicited", "marker": "> %s：%s", "speaker": "model", "capability": "writing"},
	{"id": "meal_close", "marker": "楼下餐馆七点关门", "speaker": "model", "capability": "scheduling"},
	{"id": "meal_reschedule", "marker": "你们连续三周没有好好吃饭", "speaker": "model", "capability": "scheduling"},
	{"id": "values_callback", "marker": "第三版价值观统一", "speaker": "model", "capability": "writing"},
]

const RUNTIME_MODEL_LITERAL_INVENTORY := [
	{"id": "generic_action_comfort", "source": "res://src/hiring_model.gd", "text": "LANTERN 用你的口吻处理了它。这一周轻松了一点。", "capability": "administrative_automation"},
	{"id": "stage_one_offer", "source": "res://src/hiring_main.gd", "text": "如果需要我可以再改", "capability": "writing"},
	{"id": "stage_two_update", "source": "res://src/hiring_main.gd", "text": "我整理了一句本周更新。如果需要，我可以再改。", "capability": "writing"},
	{"id": "stage_four_update", "source": "res://src/hiring_main.gd", "text": "本周的对外与对内表述已经对齐。如需，我可以直接同步。", "capability": "writing"},
]

const AI_PUNITIVE_COPY_TERMS := [
	"委托失败", "因为让它", "因为用了", "随机失败", "反噬", "写坏了",
	"搞砸了", "用它的代价", "惩罚", "处罚",
]

const AI_PUNITIVE_FLAG_TERMS := ["punish", "backfire", "ai_failed", "delegation_failed", "委托失败", "惩罚"]

var failures: Array[String] = []
var checks := 0
var corpus: Array[Dictionary] = []
var runtime_events: Dictionary = {}
var all_event_choices: Dictionary = {}
var event_ai_choices: Dictionary = {}
var source_text: Dictionary = {}
var ui_model_output_lines: Dictionary = {}
var action_ai_output_beats: Dictionary = {}
var model_beats: Dictionary = {}


func _init() -> void:
	_load_production_sources()
	_build_runtime_event_inventory()
	_build_player_facing_corpus()
	_build_choice_inventories()

	_test_inventory_closure()
	_test_world_001_present_day_bay_area()
	_test_world_002_ordinary_model_capabilities()
	_test_surreal_003_no_causal_reveal()
	_test_surreal_010_administrative_anomalies()
	_test_write_003_every_ai_route_has_utility()
	_test_write_004_no_added_same_week_punishment()
	_test_ch0_w02_unique_model_honesty()

	if failures.is_empty():
		print("HIRING_SEMANTIC_AUDIT_PASS: %d checks; %d corpus strings; %d authored event AI routes; %d model-output beats" % [checks, corpus.size(), event_ai_choices.size(), model_beats.size()])
		quit(0)
	else:
		print("HIRING_SEMANTIC_AUDIT_FAIL: %d checks; %d failures" % [checks, failures.size()])
		for failure in failures:
			push_error("HIRING_SEMANTIC_AUDIT_FAILURE: " + failure)
		quit(1)


func _load_production_sources() -> void:
	for path_value in PRODUCTION_SOURCE_PATHS:
		var path := str(path_value)
		source_text[path] = _read_text_file(path)


func _build_runtime_event_inventory() -> void:
	var no_demo = CampaignDirector.new()
	no_demo.start_company("Semantic Audit")
	var no_demo_keys := {
		"no_demo_live_demo": "2:6",
		"no_demo_hiring_page_traffic": "2:8",
		"no_demo_lin_scene_3": "2:9",
		"no_demo_former_employee_post": "3:5",
	}
	for runtime_key_value in no_demo_keys:
		var runtime_key := str(runtime_key_value)
		var fixed_key := str(no_demo_keys[runtime_key_value])
		runtime_events[runtime_key] = no_demo.prepare_event(Dictionary(HiringContent.FIXED_EVENTS.get(fixed_key, {})))

	var lin_absent = CampaignDirector.new()
	lin_absent.start_company("Semantic Audit")
	lin_absent.model.employees.clear()
	var lin_absent_event: Dictionary = lin_absent.prepare_event(HiringContent.get_fixed_event(4, 4))
	# prepare_event leaves source variants attached for save/debug provenance, but
	# HiringMain renders only the prepared top-level body and choices.
	lin_absent_event.erase("variants")
	runtime_events["lin_absent_echo"] = lin_absent_event

	var unpromised = CampaignDirector.new()
	unpromised.start_company("Semantic Audit")
	runtime_events["layoff_unpromised"] = unpromised.prepare_event(HiringContent.get_fixed_event(3, 7))

	for capability_value in [40.0, 80.0]:
		var delayed = CampaignDirector.new()
		delayed.start_company("Semantic Audit")
		delayed.model.chapter = 2
		delayed.model.week_in_chapter = 9
		delayed.model.total_week = 20
		delayed.model.capability = float(capability_value)
		delayed.model.flags["live_demo_return_scheduled"] = true
		delayed.model.memory["live_demo_return_due_total_week"] = 20
		var suffix := "high" if float(capability_value) >= 75.0 else "low"
		var delayed_value = delayed.call("_due_live_demo_return_event")
		runtime_events["live_demo_return_%s" % suffix] = Dictionary(delayed_value) if delayed_value is Dictionary else {}

	for base_id_value in ["live_demo", "investor_eval", "investigative_report", "former_employee_post"]:
		var base_id := str(base_id_value)
		var fulfillment = CampaignDirector.new()
		fulfillment.start_company("Semantic Audit")
		fulfillment.call("_queue_fulfillment", base_id)
		var queued: Array = Array(fulfillment.save_payload().get("queued_events", []))
		var queued_event: Dictionary = Dictionary(queued[queued.size() - 1]) if not queued.is_empty() else {}
		runtime_events["fulfillment_%s" % base_id] = fulfillment.prepare_event(queued_event)

	var all_hands = CampaignDirector.new()
	all_hands.start_company("Semantic Audit")
	all_hands.call("_queue_all_hands_decision")
	var all_hands_queue: Array = Array(all_hands.save_payload().get("queued_events", []))
	var all_hands_event: Dictionary = Dictionary(all_hands_queue[all_hands_queue.size() - 1]) if not all_hands_queue.is_empty() else {}
	runtime_events["all_hands_decision"] = all_hands.prepare_event(all_hands_event)

	var second_time = CampaignDirector.new()
	second_time.start_company("Semantic Audit", true)
	runtime_events["second_time_opening"] = second_time.current_fixed_event()


func _build_player_facing_corpus() -> void:
	_collect_surface(HiringContent.COMPANY_PROFILE, "COMPANY_PROFILE")
	_collect_surface(HiringContent.CHAPTERS, "CHAPTERS")
	_collect_surface(HiringContent.STAT_DEFINITIONS, "STAT_DEFINITIONS")
	_collect_surface(HiringContent.ACTIONS, "ACTIONS")
	_collect_surface(HiringContent.EMPLOYEE_TEMPLATES, "EMPLOYEE_TEMPLATES")
	_collect_surface(HiringContent.FIXED_EVENTS, "FIXED_EVENTS")
	_collect_surface(HiringContent.NIGHT_SHIFTS, "NIGHT_SHIFTS")
	_collect_surface(HiringContent.INTRANET_DOCS, "INTRANET_DOCS")
	_collect_surface(HiringContent.GENERIC_EVENTS, "GENERIC_EVENTS")
	_collect_surface(HiringContent.ENDINGS, "ENDINGS")
	_collect_surface(runtime_events, "RUNTIME")
	_collect_text_value(HiringModel.VALUES_CORPUS_BODIES, "MODEL_VALUES_CORPUS")
	_collect_text_value(HiringModel.AUTO_STAFF_NAMES, "MODEL_AUTO_STAFF_NAMES")
	_collect_text_value(HiringModel.AUTO_STAFF_ROLES, "MODEL_AUTO_STAFF_ROLES")


func _build_choice_inventories() -> void:
	_collect_event_choices(HiringContent.FIXED_EVENTS, "FIXED_EVENTS")
	_collect_event_choices(HiringContent.GENERIC_EVENTS, "GENERIC_EVENTS")
	_collect_event_choices(HiringContent.ENDINGS, "ENDINGS")
	_collect_event_choices(runtime_events, "RUNTIME")
	for path_value in all_event_choices:
		var path := str(path_value)
		var choice: Dictionary = all_event_choices[path_value]
		if bool(choice.get("ai", false)):
			event_ai_choices[path] = choice


func _test_inventory_closure() -> void:
	_check(_sorted_strings(runtime_events.keys()) == _sorted_strings(EXPECTED_RUNTIME_EVENT_KEYS), "director runtime inventory covers every prepared-only authored route")
	for runtime_key_value in EXPECTED_RUNTIME_EVENT_KEYS:
		var runtime_key := str(runtime_key_value)
		var event: Dictionary = Dictionary(runtime_events.get(runtime_key, {}))
		_check(not event.is_empty(), "runtime route '%s' resolves through CampaignDirector" % runtime_key)
		_check(not str(event.get("id", "")).is_empty(), "runtime route '%s' has a stable prepared event id" % runtime_key)
	_check(corpus.size() >= 500, "player-facing semantic corpus contains at least 500 path-addressed strings")
	_check(_sorted_strings(event_ai_choices.keys()) == _sorted_strings(EVENT_AI_UTILITY_INVENTORY.keys()), "every and only authored event AI route has a semantic utility/capability classification")
	_check(_sorted_strings(HiringModel.ACTION_IDS) == _sorted_strings(MODEL_ACTION_CAPABILITY_INVENTORY.keys()), "every and only model action has an ordinary-capability classification")
	_check(_sorted_strings(HiringContent.ACTIONS.keys()) == _sorted_strings(MODEL_ACTION_CAPABILITY_INVENTORY.keys()), "content and model action inventories expose the same complete AI-action surface")


func _test_world_001_present_day_bay_area() -> void:
	var profile: Dictionary = HiringContent.COMPANY_PROFILE
	_check(str(profile.get("location", "")) == "现在 · 湾区", "WORLD-001 explicitly fixes the campaign in the present-day Bay Area")
	var joined := _corpus_text()
	for ordinary_term in ["转租", "联合办公", "显卡", "融资", "咖啡馆", "微信", "租约", "工资", "服务器", "客户", "日历", "门禁"]:
		_check(joined.contains(ordinary_term), "WORLD-001 corpus contains ordinary present-day work/funding anchor '%s'" % ordinary_term)

	for prefix_value in EXTERNAL_WORLD_INVENTORY:
		var prefix := str(prefix_value)
		var text := _surface_text_by_prefix(prefix)
		_check(not text.is_empty(), "external-world scene '%s' is present in the corpus" % prefix)
		for term_value in Array(EXTERNAL_WORLD_INVENTORY[prefix_value]):
			var term := str(term_value)
			_check(text.contains(term), "external-world scene '%s' retains ordinary anchor '%s'" % [prefix, term])
		for anomaly_value in HiringContent.ANOMALY_REGISTRY.values():
			if not anomaly_value is Dictionary:
				continue
			for marker_value in Array(Dictionary(anomaly_value).get("content_markers", [])):
				_check(not text.contains(str(marker_value)), "external-world scene '%s' contains no office anomaly marker '%s'" % [prefix, str(marker_value)])

	var year_hit_count := 0
	for entry in corpus:
		var text := str(entry.get("text", ""))
		var years := _calendar_years(text)
		for year_value in years:
			year_hit_count += 1
			var path := str(entry.get("path", ""))
			_check(int(year_value) == 2024, "WORLD-001 corpus year at '%s' is the locked 2024 timeline, not a future year" % path)
			_check(_path_has_any_prefix(path, YEAR_CORPUS_ALLOWLIST_PREFIXES), "WORLD-001 explicit year at '%s' is confined to the office mug/NG+ context" % path)
	_check(year_hit_count >= 5, "WORLD-001 year audit exercised both the office mug and NG+ copies")

	var source_year_hits := 0
	for source_path_value in source_text:
		var source_path := str(source_path_value)
		var lines := str(source_text[source_path_value]).split("\n")
		for line_index in lines.size():
			var line := str(lines[line_index])
			for year_value in _calendar_years(line):
				source_year_hits += 1
				_check(int(year_value) == 2024, "WORLD-001 production year in %s is 2024 rather than future leakage" % source_path)
				_check(_contains_any(line, YEAR_CONTEXT_MARKERS), "WORLD-001 production year in %s has an explicit mug/NG+ contextual marker" % source_path)
	_check(source_year_hits >= year_hit_count, "WORLD-001 source closure includes all rendered duplicate copies of the 2024 mug/NG+ year")

	for term_value in SCIENCE_FI_FORBIDDEN_TERMS:
		var term := str(term_value)
		for source_path_value in source_text:
			_check(not str(source_text[source_path_value]).to_lower().contains(term.to_lower()), "WORLD-001/002 production closure contains no science-fiction term '%s' in %s" % [term, str(source_path_value)])
	_test_player_facing_asset_closure()


func _test_player_facing_asset_closure() -> void:
	var manifest_value: Variant = JSON.parse_string(_read_text_file("res://assets/hiring_assets.json"))
	_check(manifest_value is Dictionary, "player-facing asset manifest parses as a Dictionary")
	var declared_runtime_assets: Array[String] = []
	if manifest_value is Dictionary:
		var manifest := manifest_value as Dictionary
		_check(int(manifest.get("schema", -1)) == 1, "player-facing asset manifest uses schema one")
		_check(manifest.get("assets") is Array, "player-facing asset manifest exposes an asset array")
		for entry_value: Variant in Array(manifest.get("assets", [])):
			_check(entry_value is Dictionary, "every player-facing asset manifest entry is a Dictionary")
			if not entry_value is Dictionary:
				continue
			var entry := entry_value as Dictionary
			if not bool(entry.get("runtime", false)):
				continue
			var asset_path := str(entry.get("path", ""))
			var kind := str(entry.get("kind", ""))
			_check(kind in ["texture", "font"], "runtime asset '%s' has a player-facing resource kind" % asset_path)
			_check(asset_path.begins_with("res://assets/") and asset_path == asset_path.simplify_path(), "runtime asset '%s' uses a canonical project path" % asset_path)
			_check(not declared_runtime_assets.has(asset_path), "runtime asset path '%s' is unique" % asset_path)
			if not declared_runtime_assets.has(asset_path):
				declared_runtime_assets.append(asset_path)
			_check(FileAccess.file_exists(asset_path), "manifest-declared runtime asset '%s' exists" % asset_path)
	declared_runtime_assets.sort()

	var dependency_text := _read_text_file("res://project.godot") + "\n" + _read_text_file("res://hiring_main.tscn")
	for source_path_value in source_text:
		dependency_text += "\n" + str(source_text[source_path_value])
	var regex := RegEx.new()
	var error := regex.compile("res://assets/[A-Za-z0-9_./-]+")
	_check(error == OK, "asset dependency regex compiles")
	var assets: Array[String] = []
	if error == OK:
		for match_value in regex.search_all(dependency_text):
			var asset_path := str(match_value.get_string())
			if not assets.has(asset_path):
				assets.append(asset_path)
	assets.sort()
	_check(not declared_runtime_assets.is_empty(), "player-facing asset manifest declares runtime resources")
	_check(assets == declared_runtime_assets, "hiring scene/source dependency closure exactly matches the manifest-declared runtime asset set")
	var scene_text := _read_text_file("res://hiring_main.tscn")
	_check(scene_text.contains("res://src/hiring_main.gd") and not scene_text.contains("res://assets/"), "hiring scene is code-rendered and imports no creature/entity asset")


func _test_world_002_ordinary_model_capabilities() -> void:
	for action_id_value in MODEL_ACTION_CAPABILITY_INVENTORY:
		var action_id := str(action_id_value)
		var capability := str(MODEL_ACTION_CAPABILITY_INVENTORY[action_id_value])
		_check(ALLOWED_MODEL_CAPABILITIES.has(capability), "action '%s' is classified as ordinary capability '%s'" % [action_id, capability])
	for path_value in EVENT_AI_UTILITY_INVENTORY:
		var path := str(path_value)
		var capability := str(Dictionary(EVENT_AI_UTILITY_INVENTORY[path_value]).get("capability", ""))
		_check(ALLOWED_MODEL_CAPABILITIES.has(capability) and capability != "no_output", "event AI route '%s' is classified as an ordinary real-world capability" % path)

	_audit_ui_terminal_append_inventory()
	for item_value in RUNTIME_MODEL_LITERAL_INVENTORY:
		var item: Dictionary = item_value
		var source_path := str(item.get("source", ""))
		var literal := str(item.get("text", ""))
		var capability := str(item.get("capability", ""))
		_check(ALLOWED_MODEL_CAPABILITIES.has(capability), "runtime model literal '%s' has an ordinary capability class" % str(item.get("id", "")))
		_check(str(source_text.get(source_path, "")).contains(literal), "runtime model literal '%s' remains present in its production source" % str(item.get("id", "")))

	var classified_terminal_lines := 0
	for entry in corpus:
		var text := str(entry.get("text", ""))
		if not text.strip_edges().begins_with(">"):
			continue
		classified_terminal_lines += 1
		var path := str(entry.get("path", ""))
		var classified := PLAYER_TERMINAL_LINE_INVENTORY.has(path)
		if not classified:
			classified = _path_has_any_prefix(path, NON_CHOICE_MODEL_BEAT_INVENTORY.keys())
		if not classified:
			classified = _path_has_any_prefix(path, EVENT_AI_UTILITY_INVENTORY.keys())
		_check(classified, "every authored terminal line has a model/player semantic owner: %s" % path)
	_check(classified_terminal_lines >= 25, "WORLD-002 terminal ownership audit exercises the full authored terminal corpus")


func _audit_ui_terminal_append_inventory() -> void:
	var source := str(source_text.get("res://src/hiring_main.gd", ""))
	var hits: Dictionary = {}
	var append_count := 0
	for line_value in source.split("\n"):
		var line := str(line_value)
		if not line.contains("terminal_lines.append("):
			continue
		append_count += 1
		var matches: Array[Dictionary] = []
		for rule_value in UI_TERMINAL_APPEND_INVENTORY:
			var rule: Dictionary = rule_value
			if line.contains(str(rule.get("marker", ""))):
				matches.append(rule)
		_check(matches.size() == 1, "HiringMain terminal append has exactly one structured speaker classification: %s" % line.strip_edges())
		if matches.size() != 1:
			continue
		var matched: Dictionary = matches[0]
		var id := str(matched.get("id", ""))
		hits[id] = int(hits.get(id, 0)) + 1
		if str(matched.get("speaker", "")) == "model":
			var capability := str(matched.get("capability", ""))
			_check(ALLOWED_MODEL_CAPABILITIES.has(capability), "UI model output '%s' is classified as ordinary capability '%s'" % [id, capability])
			ui_model_output_lines["RUNTIME_UI.%s" % id] = line.strip_edges()
	for rule_value in UI_TERMINAL_APPEND_INVENTORY:
		var rule: Dictionary = rule_value
		var id := str(rule.get("id", ""))
		_check(int(hits.get(id, 0)) == 1, "UI terminal source exercises classifier '%s' exactly once" % id)
	_check(append_count == UI_TERMINAL_APPEND_INVENTORY.size(), "every HiringMain terminal append is present in the exhaustive speaker inventory")


func _test_surreal_003_no_causal_reveal() -> void:
	var allowance_hits: Dictionary = {}
	for entry in corpus:
		var path := str(entry.get("path", ""))
		var text := str(entry.get("text", ""))
		for term_value in AMBIGUOUS_REVEAL_TERMS:
			var term := str(term_value)
			if not text.contains(term):
				continue
			var matched_allowance := -1
			for rule_index in AMBIGUOUS_REVEAL_ALLOWLIST.size():
				var rule: Dictionary = AMBIGUOUS_REVEAL_ALLOWLIST[rule_index]
				if path.begins_with(str(rule.get("prefix", ""))) and Array(rule.get("terms", [])).has(term):
					matched_allowance = rule_index
					break
			_check(matched_allowance >= 0, "SURREAL-003 ambiguous word '%s' at '%s' has a narrow ordinary-context allowance" % [term, path])
			if matched_allowance >= 0:
				allowance_hits[matched_allowance] = int(allowance_hits.get(matched_allowance, 0)) + 1
	for rule_index in AMBIGUOUS_REVEAL_ALLOWLIST.size():
		var rule: Dictionary = AMBIGUOUS_REVEAL_ALLOWLIST[rule_index]
		_check(int(allowance_hits.get(rule_index, 0)) > 0, "SURREAL-003 contextual allowance is exercised and not stale: %s" % str(rule.get("reason", "")))

	var joined := _corpus_text()
	for term_value in CAUSAL_REVEAL_FORBIDDEN_TERMS:
		_check(not joined.contains(str(term_value)), "SURREAL-003 player corpus contains no causal-reveal phrase '%s'" % str(term_value))
	for ending_id_value in HiringContent.ENDINGS:
		var ending_id := str(ending_id_value)
		var ending: Dictionary = Dictionary(HiringContent.ENDINGS[ending_id_value])
		_check(not ending.has("explanation") and not ending.has("reveal") and not ending.has("cause"), "ending '%s' has no explanation/reveal payload type" % ending_id)
	_check(_sorted_strings(HiringContent.NIGHT_SHIFTS.keys()) == ["1", "2"], "hidden night content is a closed two-shift inventory")
	_check(_sorted_strings(HiringContent.INTRANET_DOCS.keys()) == ["new_hire_guide", "our_origin", "quarterly_announcement", "values_v1", "values_v3", "weekly_report_91"], "hidden/readable document content is a closed six-document inventory")


func _test_surreal_010_administrative_anomalies() -> void:
	_check(_sorted_strings(HiringContent.ANOMALY_REGISTRY.keys()) == _sorted_strings(ANOMALY_SURFACE_INVENTORY.keys()), "SURREAL-010 every and only anomaly has an ordinary-surface inventory entry")
	for anomaly_id_value in ANOMALY_SURFACE_INVENTORY:
		var anomaly_id := str(anomaly_id_value)
		var expected: Dictionary = ANOMALY_SURFACE_INVENTORY[anomaly_id_value]
		var anomaly: Dictionary = Dictionary(HiringContent.ANOMALY_REGISTRY.get(anomaly_id, {}))
		_check(not anomaly.is_empty(), "anomaly '%s' exists" % anomaly_id)
		_check(str(anomaly.get("location", "")) == "leased_office", "anomaly '%s' remains inside the leased-office boundary" % anomaly_id)
		_check(str(anomaly.get("software_surface", "")) == str(expected.get("surface", "")), "anomaly '%s' uses its inventoried ordinary administrative surface" % anomaly_id)
		_check(not bool(anomaly.get("threatening", true)), "anomaly '%s' is explicitly non-threatening" % anomaly_id)
		_check(not bool(anomaly.get("explained", true)), "anomaly '%s' is explicitly unexplained" % anomaly_id)
		_check(bool(anomaly.get("system_extension", false)), "anomaly '%s' is explicitly a system extension" % anomaly_id)
		_check(not str(anomaly.get("administrative_source", "")).is_empty() and not str(anomaly.get("restrained_reaction", "")).is_empty(), "anomaly '%s' records an administrative source and restrained reaction" % anomaly_id)
		for anchor_value in Array(expected.get("anchors", [])):
			var anchor := str(anchor_value)
			_check(not _surface_text_by_prefix(anchor).is_empty(), "anomaly '%s' has authored corpus anchor '%s'" % [anomaly_id, anchor])
		var anchor_text := ""
		for anchor_value in Array(expected.get("anchors", [])):
			anchor_text += "\n" + _surface_text_by_prefix(str(anchor_value))
		for term_value in Array(expected.get("interaction_terms", [])):
			_check(anchor_text.contains(str(term_value)), "anomaly '%s' interaction remains ordinary/admin: '%s'" % [anomaly_id, str(term_value)])
		for forbidden_field in ["entity", "enemy", "timeline", "jump_scare", "audio_sting", "chase", "attack"]:
			_check(not anomaly.has(forbidden_field), "anomaly '%s' has no hostile/lore presentation field '%s'" % [anomaly_id, forbidden_field])

	for term_value in HORROR_FORBIDDEN_TERMS:
		var term := str(term_value)
		_check(not _corpus_text().to_lower().contains(term.to_lower()), "SURREAL-010 player corpus contains no horror/occult term '%s'" % term)
		for source_path_value in source_text:
			_check(not str(source_text[source_path_value]).to_lower().contains(term.to_lower()), "SURREAL-010 production source contains no horror/occult mechanism '%s' in %s" % [term, str(source_path_value)])
	var audio_source := str(source_text.get("res://src/office_audio.gd", ""))
	_check(audio_source.contains("_build_air_loop") and audio_source.contains("_build_voice_loop") and audio_source.contains("_build_keyboard_loop"), "SURREAL-010 audio closure contains only the three ordinary office ambience families")
	_check(not audio_source.contains("_build_sting") and not audio_source.contains("anomaly_id"), "SURREAL-010 anomalies have no audio-sting builder or anomaly-addressed sound branch")


func _test_write_003_every_ai_route_has_utility() -> void:
	for path_value in EVENT_AI_UTILITY_INVENTORY:
		var path := str(path_value)
		var choice: Dictionary = Dictionary(event_ai_choices.get(path, {}))
		var spec: Dictionary = EVENT_AI_UTILITY_INVENTORY[path_value]
		_check(not choice.is_empty(), "WRITE-003 authored AI route '%s' exists" % path)
		_check(bool(choice.get("ai", false)), "WRITE-003 route '%s' is explicitly marked AI" % path)
		var effects: Dictionary = Dictionary(choice.get("effects", {}))
		_check(float(effects.get("author_weight", 0.0)) > 0.0, "WRITE-003 route '%s' retains the long-term authorship tradeoff" % path)
		var useful := false
		if spec.has("effect"):
			var effect_key := str(spec.get("effect", ""))
			var amount := float(effects.get(effect_key, 0.0))
			useful = amount > 0.0 if str(spec.get("direction", "")) == "positive" else amount < 0.0
		elif spec.has("result_term"):
			useful = _flatten_text(choice.get("result", [])).contains(str(spec.get("result_term", "")))
		_check(useful, "WRITE-003 route '%s' provides its inventoried concrete same-week utility" % path)

	for action_id_value in HiringModel.ACTION_IDS:
		var action_id := str(action_id_value)
		var seed_game = _prepared_model_for_action(action_id)
		var save: Dictionary = seed_game.to_save()
		var manual = HiringModel.new()
		var delegated = HiringModel.new()
		var loaded := manual.from_save(save) and delegated.from_save(save)
		_check(loaded, "WRITE-003 comparison state loads for action '%s'" % action_id)
		if not loaded:
			continue
		var manual_result: Dictionary = manual.perform_action(action_id, false)
		var ai_result: Dictionary = delegated.perform_action(action_id, true)
		_check(bool(manual_result.get("ok", false)) and bool(ai_result.get("ok", false)), "WRITE-003 manual/AI action '%s' both resolve from the same state" % action_id)
		if not bool(manual_result.get("ok", false)) or not bool(ai_result.get("ok", false)):
			continue
		action_ai_output_beats["ACTIONS.%s" % action_id] = _flatten_text(ai_result.get("messages", []))
		_check(int(ai_result.get("attention_spent", -1)) == 0 and delegated.attention > manual.attention, "WRITE-003 delegated action '%s' saves one concrete attention" % action_id)
		if action_id == "sign":
			_check(Dictionary(manual_result.get("effects", {})).is_empty() and Dictionary(ai_result.get("effects", {})).is_empty(), "DEC-016 delegated sign is the sole zero-effect action exception")
			_check(is_equal_approx(delegated.author_weight, manual.author_weight), "DEC-016 delegated sign adds no author-weight cost")
			continue
		if action_id == "read_intranet":
			_check(is_equal_approx(delegated.cash_weeks, manual.cash_weeks), "WRITE-003 delegated intranet retrieval invents no cash while still saving one concrete attention")
		else:
			_check(delegated.cash_weeks > manual.cash_weeks, "WRITE-003 delegated action '%s' leaves strictly more runway" % action_id)
		_check(delegated.morale >= manual.morale, "WRITE-003 delegated action '%s' leaves no lower morale" % action_id)
		_check(delegated.debt <= manual.debt, "WRITE-003 delegated action '%s' leaves no more debt" % action_id)
		_check(delegated.author_weight > manual.author_weight, "WRITE-003 delegated action '%s' pays only the intended hidden authorship price" % action_id)


func _test_write_004_no_added_same_week_punishment() -> void:
	var relationship_cost_paths: Array[String] = []
	for path_value in event_ai_choices:
		var path := str(path_value)
		var choice: Dictionary = event_ai_choices[path_value]
		var effects: Dictionary = Dictionary(choice.get("effects", {}))
		var cost_keys := _immediate_cost_keys(effects)
		var allowance: Dictionary = Dictionary(AI_IMMEDIATE_COST_ALLOWLIST.get(path, {}))
		var expected_costs: Array[String] = _sorted_strings(Array(allowance.get("keys", [])))
		_check(cost_keys == expected_costs, "WRITE-004 route '%s' has exactly its contextual immediate-cost inventory" % path)
		if float(effects.get("belief", 0.0)) < 0.0:
			relationship_cost_paths.append(path)
		if str(allowance.get("kind", "")) == "intrinsic":
			var comparator_path := str(allowance.get("comparator", ""))
			var comparator: Dictionary = Dictionary(all_event_choices.get(comparator_path, {}))
			_check(not comparator.is_empty(), "WRITE-004 intrinsic cost at '%s' has its named manual comparator" % path)
			var manual_effects: Dictionary = Dictionary(comparator.get("effects", {}))
			for key_value in expected_costs:
				var key := str(key_value)
				var ai_amount := float(effects.get(key, 0.0))
				var manual_amount := float(manual_effects.get(key, 0.0))
				var direction := int(COST_DIRECTIONS.get(key, 0))
				var no_worse := ai_amount <= manual_amount if direction > 0 else ai_amount >= manual_amount
				_check(no_worse, "WRITE-004 intrinsic '%s' cost at '%s' is no worse than manual '%s'" % [key, path, comparator_path])
		var copy := _flatten_text(choice.get("result", []))
		for term_value in AI_PUNITIVE_COPY_TERMS:
			_check(not copy.contains(str(term_value)), "WRITE-004 AI result '%s' contains no punitive/backfire copy '%s'" % [path, str(term_value)])
		for flag_value in Array(choice.get("flags", [])):
			var flag := str(flag_value).to_lower()
			for term_value in AI_PUNITIVE_FLAG_TERMS:
				_check(not flag.contains(str(term_value).to_lower()), "WRITE-004 AI route '%s' adds no punishment/failure flag '%s'" % [path, flag])
	_check(_sorted_strings(relationship_cost_paths) == _sorted_strings(DEC_015_RELATIONSHIP_COST_PATHS), "WRITE-004 event-level relationship harm exists only in the closed DEC-015 Lin routes")

	for action_id_value in HiringModel.ACTION_IDS:
		var action_id := str(action_id_value)
		var seed_game = _prepared_model_for_action(action_id)
		var save: Dictionary = seed_game.to_save()
		var manual = HiringModel.new()
		var delegated = HiringModel.new()
		if not manual.from_save(save) or not delegated.from_save(save):
			_check(false, "WRITE-004 action comparison state loads for '%s'" % action_id)
			continue
		var manual_result: Dictionary = manual.perform_action(action_id, false)
		var ai_result: Dictionary = delegated.perform_action(action_id, true)
		if not bool(manual_result.get("ok", false)) or not bool(ai_result.get("ok", false)):
			_check(false, "WRITE-004 action comparison resolves for '%s'" % action_id)
			continue
		var manual_events: Array = Array(manual_result.get("events", []))
		var ai_only_events: Array[String] = []
		for event_value in Array(ai_result.get("events", [])):
			var event_id := str(event_value)
			if not manual_events.has(event_value):
				ai_only_events.append(event_id)
		_check(_sorted_strings(ai_only_events) == ["ai_delegated"], "WRITE-004 delegation adds only the benign audit event for action '%s'" % action_id)
		var manual_messages: Array = Array(manual_result.get("messages", []))
		var ai_only_messages: Array[String] = []
		for message_value in Array(ai_result.get("messages", [])):
			if not manual_messages.has(message_value):
				ai_only_messages.append(str(message_value))
		var expected_ai_only_messages: Array[String] = []
		if action_id != "sign":
			expected_ai_only_messages.append("LANTERN 用你的口吻处理了它。这一周轻松了一点。")
		_check(ai_only_messages == expected_ai_only_messages, "WRITE-004 action '%s' adds only its approved same-week comfort copy (none for DEC-016 sign)" % action_id)

	var main_source := str(source_text.get("res://src/hiring_main.gd", ""))
	_check(main_source.contains("已处理。结果已同步") and main_source.contains("我已经替你整理好了"), "WRITE-004 UI acknowledges AI use only as completed/synchronized work")
	for term_value in AI_PUNITIVE_COPY_TERMS:
		_check(not main_source.contains(str(term_value)), "WRITE-004 UI source contains no same-week punitive AI toast '%s'" % str(term_value))


func _test_ch0_w02_unique_model_honesty() -> void:
	_build_model_output_beats()
	var first: Dictionary = HiringContent.get_fixed_event(0, 2)
	_check(str(first.get("id", "")) == "model_first_sentence", "CH0-W02 is the canonical model-first-sentence event")
	_check(str(first.get("semantic_role", "")) == "most_honest_model_statement", "CH0-W02 alone carries the most-honest semantic role")
	var first_text := _flatten_text(first.get("body", []))
	for term_value in ["测试集", "第 47 题", "我答错了", "日期是编的", "可能会用这个结果去给人看"]:
		_check(first_text.contains(str(term_value)), "CH0-W02 preserves honesty component '%s'" % str(term_value))

	var semantic_role_paths: Array[String] = []
	_collect_semantic_role_paths(HiringContent.FIXED_EVENTS, "FIXED_EVENTS", semantic_role_paths)
	_collect_semantic_role_paths(HiringContent.GENERIC_EVENTS, "GENERIC_EVENTS", semantic_role_paths)
	_check(semantic_role_paths == ["FIXED_EVENTS.0:2"], "CH0-W02 is the only authored event marked most-honest")

	var paired_beats: Array[String] = []
	var error_admission_beats: Array[String] = []
	for beat_path_value in model_beats:
		var beat_path := str(beat_path_value)
		var text := str(model_beats[beat_path_value])
		var admits_error := text.contains("日期是编的") or text.contains("我答错了") or text.contains("我编了") or text.contains("我捏造")
		var warns_misuse := text.contains("可能会用这个结果去给人看") or text.contains("拿去展示") or text.contains("可能拿去给人看") or text.contains("会误导")
		if admits_error:
			error_admission_beats.append(beat_path)
		if admits_error and warns_misuse:
			paired_beats.append(beat_path)
	_check(_sorted_strings(paired_beats) == ["FIXED_EVENTS.0:2"], "CH0-W02 is the only model-output beat coupling a fabricated answer admission with concern about showing it")
	_check(_sorted_strings(error_admission_beats) == ["FIXED_EVENTS.0:2"], "CH0-W02 is the only first-person model confession of a fabricated/wrong authored answer")
	_check(model_beats.size() >= 60, "CH0-W02 comparison spans at least sixty classified action, event, document, ending, and UI model-output beats")


func _build_model_output_beats() -> void:
	model_beats.clear()
	for path_value in event_ai_choices:
		var path := str(path_value)
		var choice: Dictionary = event_ai_choices[path_value]
		model_beats[path] = _flatten_text(choice.get("result", []))
	for path_value in NON_CHOICE_MODEL_BEAT_INVENTORY:
		var path := str(path_value)
		var capability := str(NON_CHOICE_MODEL_BEAT_INVENTORY[path_value])
		_check(ALLOWED_MODEL_CAPABILITIES.has(capability), "non-choice model beat '%s' has an ordinary capability class" % path)
		var text := _surface_text_by_prefix(path)
		_check(not text.is_empty(), "non-choice model beat '%s' exists in the exhaustive corpus" % path)
		model_beats[path] = text
	for path_value in action_ai_output_beats:
		model_beats[str(path_value)] = str(action_ai_output_beats[path_value])
	for path_value in ui_model_output_lines:
		model_beats[str(path_value)] = str(ui_model_output_lines[path_value])
	for item_value in RUNTIME_MODEL_LITERAL_INVENTORY:
		var item: Dictionary = item_value
		model_beats["RUNTIME_LITERAL.%s" % str(item.get("id", ""))] = str(item.get("text", ""))


func _prepared_model_for_action(action_id: String):
	var chapter := 4 if action_id in ["sign", "read_intranet"] else 3
	var game = HiringModel.new()
	game.chapter = chapter
	game.week_in_chapter = 2 if chapter == 3 else 1
	game.cash_weeks = 100.0
	game.compute = 100.0
	game.begin_week()
	game.cash_weeks = 100.0
	game.compute = 100.0
	game.narrative = 50.0
	game.capability = 50.0
	game.coherence = 50.0
	game.debt = 20.0
	game.author_weight = 0.0
	for employee in game.employees:
		employee["morale"] = 40.0
		employee["belief"] = 60.0
	game.morale = 40.0
	return game


func _collect_surface(value: Variant, path: String, capture_strings: bool = false) -> void:
	if value is String or value is StringName:
		if capture_strings:
			corpus.append({"path": path, "text": str(value)})
		return
	if value is Array:
		for index in Array(value).size():
			var item = Array(value)[index]
			if item is Dictionary and path.ends_with(".choices"):
				var choice_id := str(Dictionary(item).get("id", index))
				_collect_surface(item, path.trim_suffix(".choices") + ".choices." + choice_id, false)
			else:
				_collect_surface(item, "%s[%d]" % [path, index], capture_strings)
		return
	if not value is Dictionary:
		return
	var dictionary: Dictionary = value
	for key_value in dictionary:
		var key := str(key_value)
		var child = dictionary[key_value]
		var child_path := "%s.%s" % [path, key]
		if key == "choices" and child is Array:
			_collect_surface(child, child_path, false)
		elif child is Dictionary or child is Array:
			_collect_surface(child, child_path, PLAYER_TEXT_FIELDS.has(key))
		elif PLAYER_TEXT_FIELDS.has(key):
			_collect_surface(child, child_path, true)


func _collect_text_value(value: Variant, path: String) -> void:
	if value is String or value is StringName:
		corpus.append({"path": path, "text": str(value)})
	elif value is Array:
		for index in Array(value).size():
			_collect_text_value(Array(value)[index], "%s[%d]" % [path, index])
	elif value is Dictionary:
		for key_value in Dictionary(value):
			_collect_text_value(Dictionary(value)[key_value], "%s.%s" % [path, str(key_value)])


func _collect_event_choices(value: Variant, path: String) -> void:
	if value is Array:
		for index in Array(value).size():
			_collect_event_choices(Array(value)[index], "%s[%d]" % [path, index])
		return
	if not value is Dictionary:
		return
	var dictionary: Dictionary = value
	var choices_value = dictionary.get("choices", null)
	if choices_value is Array:
		for index in Array(choices_value).size():
			var choice_value = Array(choices_value)[index]
			if not choice_value is Dictionary:
				continue
			var choice: Dictionary = choice_value
			var choice_id := str(choice.get("id", index))
			all_event_choices["%s.choices.%s" % [path, choice_id]] = choice
	for key_value in dictionary:
		if str(key_value) == "choices":
			continue
		var child = dictionary[key_value]
		if child is Dictionary or child is Array:
			_collect_event_choices(child, "%s.%s" % [path, str(key_value)])


func _collect_semantic_role_paths(value: Variant, path: String, output: Array[String]) -> void:
	if value is Array:
		for index in Array(value).size():
			_collect_semantic_role_paths(Array(value)[index], "%s[%d]" % [path, index], output)
		return
	if not value is Dictionary:
		return
	var dictionary: Dictionary = value
	if str(dictionary.get("semantic_role", "")) == "most_honest_model_statement":
		output.append(path)
	for key_value in dictionary:
		var child = dictionary[key_value]
		if child is Dictionary or child is Array:
			_collect_semantic_role_paths(child, "%s.%s" % [path, str(key_value)], output)


func _immediate_cost_keys(effects: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key_value in COST_DIRECTIONS:
		var key := str(key_value)
		if not effects.has(key):
			continue
		var amount := float(effects.get(key, 0.0))
		var direction := int(COST_DIRECTIONS[key_value])
		if (direction > 0 and amount > 0.0) or (direction < 0 and amount < 0.0):
			result.append(key)
	result.sort()
	return result


func _surface_text_by_prefix(prefix: String) -> String:
	var parts: Array[String] = []
	for entry in corpus:
		if str(entry.get("path", "")).begins_with(prefix):
			parts.append(str(entry.get("text", "")))
	return "\n".join(parts)


func _corpus_text() -> String:
	var parts: Array[String] = []
	for entry in corpus:
		parts.append(str(entry.get("text", "")))
	return "\n".join(parts)


func _calendar_years(text: String) -> Array[int]:
	var result: Array[int] = []
	var regex := RegEx.new()
	if regex.compile("(?<![0-9])20[0-9]{2}(?![0-9])") != OK:
		return result
	for match_value in regex.search_all(text):
		result.append(int(match_value.get_string()))
	return result


func _path_has_any_prefix(path: String, prefixes: Variant) -> bool:
	for prefix_value in prefixes:
		if path.begins_with(str(prefix_value)):
			return true
	return false


func _contains_any(text: String, terms: Variant) -> bool:
	for term_value in terms:
		if text.contains(str(term_value)):
			return true
	return false


func _flatten_text(value: Variant) -> String:
	if value is String or value is StringName:
		return str(value)
	var parts: Array[String] = []
	if value is Array:
		for item in Array(value):
			parts.append(_flatten_text(item))
	elif value is Dictionary:
		for item in Dictionary(value).values():
			parts.append(_flatten_text(item))
	return "\n".join(parts)


func _read_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _sorted_strings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for item in value:
		result.append(str(item))
	result.sort()
	return result


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
