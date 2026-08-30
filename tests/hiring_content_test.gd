extends SceneTree

const HiringContent = preload("res://src/hiring_content.gd")

const EXPECTED_CHAPTER_DURATIONS: Array[int] = [3, 8, 12, 14, 8]
const EXPECTED_MODEL_NAMES: Array[String] = ["lantern-v0.1", "lantern-v0.4", "lantern-v1", "Lantern", "LANTERN"]
const EXPECTED_MODEL_NICKNAMES: Array[String] = ["那个模型", "阿灯", "阿灯", "阿灯", ""]

const EXPECTED_FIXED_EVENT_IDS: Dictionary = {
	"0:1": "garage_opening",
	"0:2": "model_first_sentence",
	"0:3": "lin_scene_1",
	"1:1": "preseed_unlocks",
	"1:2": "preseed_free_2",
	"1:3": "preseed_free_3",
	"1:4": "first_investor_meeting",
	"1:5": "investor_repost",
	"1:6": "viral_tweet",
	"1:7": "lin_scene_2",
	"1:8": "preseed_close",
	"2:1": "real_office",
	"2:2": "demo_video_unlock",
	"2:3": "seed_debt_3",
	"2:4": "seed_debt_4",
	"2:5": "seed_debt_5",
	"2:6": "live_demo",
	"2:7": "first_resignation_intent",
	"2:8": "hiring_page_traffic",
	"2:9": "lin_scene_3",
	"2:10": "second_debt_collection",
	"2:11": "seed_raise_1",
	"2:12": "seed_raise_2",
	"3:1": "office_expansion",
	"3:2": "series_a_unlocks",
	"3:3": "phantom_employee_appears",
	"3:4": "the_accent",
	"3:5": "former_employee_post",
	"3:6": "cash_crisis",
	"3:7": "layoff_execution",
	"3:8": "meeting_room_d_calendar",
	"3:9": "debt_reckoning_1",
	"3:10": "debt_reckoning_2",
	"3:11": "lin_scene_4",
	"3:12": "series_a_raise_1",
	"3:13": "series_a_raise_2",
	"3:14": "series_a_end",
	"4:1": "version_disappears",
	"4:2": "window_desks",
	"4:3": "origin_article_event",
	"4:4": "lin_last_visit",
	"4:5": "weekly_report_91_event",
	"4:6": "board_meeting",
	"4:7": "final_silence",
	"4:8": "ending_gate",
}

const EXPECTED_ACTION_IDS: Array[String] = [
	"alignment_week", "all_hands", "buy_compute", "clean_data", "conference_talk",
	"contract", "demo_video", "do_nothing", "eval", "exclusive_interview",
	"fundraising", "interview", "large_train", "layoffs", "manifesto", "one_on_one",
	"podcast", "raise_salary", "read_intranet", "recruit_expert", "sign", "team_building",
	"tech_blog", "train", "tweet", "values_doc",
]

const REQUIRED_MANUAL_EFFECTS: Dictionary = {
	"tweet": {"narrative": [5, 9]},
	"tech_blog": {"narrative": 7, "debt_if_capability_below_40": 4},
	"podcast": {"narrative": 14, "coherence": -3},
	"demo_video": {"narrative": 18, "debt": 8},
	"conference_talk": {"narrative": 12, "morale": 10},
	"manifesto": {"narrative": 25, "coherence": -10, "debt": 12},
	"exclusive_interview": {"narrative": 20},
	"train": {"capability": [3, 6]},
	"clean_data": {"training_boost_uses": 3},
	"eval": {"debt": -5, "reveal_capability": 1},
	"large_train": {"capability": [12, 18]},
	"recruit_expert": {"team_size": 1, "morale": -8},
	"alignment_week": {"coherence": 12, "narrative": -5},
	"interview": {"open_hiring": 1},
	"one_on_one": {},
	"all_hands": {"morale": 8, "coherence_if_contradiction": -12},
	"values_doc": {"morale": 5, "values_version": 1},
	"team_building": {"morale": 15, "belief": 5},
	"raise_salary": {"morale": 25, "burn_rate": 1},
	"layoffs": {"morale": -25, "debt": 10, "belief": -20},
	"buy_compute": {"compute": 6},
	"fundraising": {"fundraise_by_narrative": 1},
	"contract": {"morale": -10, "block_training": 1},
	"do_nothing": {"morale": 3},
	"sign": {},
	"read_intranet": {"open_intranet": 1},
}

const EXPECTED_EMPLOYEE_IDS: Array[String] = [
	"chen_xiaoyu", "guo_jun", "he_miao", "lin_yue", "luo_qi", "shen_yan",
	"su_yan", "tang_li", "wang_zhe", "xie_ning", "xu_an", "zhao_ke",
]

const EXPECTED_DOC_IDS: Array[String] = [
	"new_hire_guide", "our_origin", "quarterly_announcement", "values_v1",
	"values_v3", "weekly_report_91",
]

const EXPECTED_ENDING_IDS: Array[String] = [
	"acquihire", "drift", "independent", "lights_out", "rm_rf", "second_time", "successor",
]

const REQUIRED_EVENT_TERMS: Dictionary = {
	"garage_opening": ["围巾", "A4", "最后一个字母", "先这样", "什么都不做"],
	"model_first_sentence": ["测试集", "第 47 题", "日期是编的", "可能会用这个结果去给人看"],
	"lin_scene_1": ["绕了三圈", "我们能做成", "游戏没有记录"],
	"first_investor_meeting": ["十二分钟", "14 页", "第 1 页", "第 9 页", "让它来写"],
	"viral_tweet": ["2,300", "有意思", "两次手机"],
	"lin_scene_2": ["最近还在训练", "我看过记录", "我不是在指责你", "需要说出来"],
	"live_demo": ["会议室 B", "十一版", "0.8 秒", "40 秒", "两次重试", "人工润色", "小龙虾", "让它来写", "我们"],
	"hiring_page_traffic": ["4,200", "收到简历：3"],
	"lin_scene_3": ["第一次关门", "第七版", "后面还有四版", "让它来写"],
	"phantom_employee_appears": ["沈砚", "没人记得见过"],
	"the_accent": ["更整齐", "更准确", "逗号", "不做任何提示"],
	"cash_crisis": ["必须", "裁员", "外包", "让它来写"],
	"layoff_execution": ["六个人", "{{promise_week_label}}", "{{promise_reaction_label}}", "会议室 C", "间隔二十分钟", "让它来写"],
	"meeting_room_d_calendar": ["会议室 D", "A、B、C"],
	"lin_scene_4": ["作者权重", "审慎", "314 教室", "两罐啤酒"],
	"version_disappears": ["LANTERN", "没有版本号", "一点", "阿灯"],
	"window_desks": ["三米", "四台显示器", "肩膀", "团队页面", "窗帘"],
	"origin_article_event": ["我们的起源", "置顶文章", "LANTERN", "今天 08:30", "内网入口"],
	"lin_last_visit": ["最后一次", "先这样", "我还知道", "让它来写"],
	"weekly_report_91_event": ["第 91 份", "沈砚", "三十七人", "三十六人"],
	"board_meeting": ["六个人", "一块屏幕", "手机壁纸", "自然流失率 11%", "二十分钟", "让它来写"],
	"final_silence": ["同一个节拍", "说话声已经没有", "签字"],
}

var failures: Array[String] = []
var checks: int = 0


func _init() -> void:
	_test_chapters_and_fixed_week_keys()
	_test_world_stats_stages_and_memories()
	_test_anomaly_registry_and_external_boundary()
	_test_all_actions_and_effect_contracts()
	_test_required_events_scenes_and_terms()
	_test_lin_tone_lint()
	_test_all_decisions_have_delegation()
	_test_employees_and_chen_cups()
	_test_night_shifts_and_exact_terminal_marker()
	_test_intranet_documents_and_report_91()
	_test_all_seven_endings()
	_test_ui_facing_schema_and_queries()

	if failures.is_empty():
		print("HIRING_CONTENT_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		print("HIRING_CONTENT_TESTS_FAIL: %d checks, %d failures" % [checks, failures.size()])
		for failure in failures:
			push_error("HIRING_CONTENT_TEST_FAILURE: " + failure)
		quit(1)


func _test_chapters_and_fixed_week_keys() -> void:
	_check(HiringContent.SCHEMA_VERSION is int and HiringContent.SCHEMA_VERSION >= 1, "content schema has a positive integer version")
	_check(HiringContent.CHAPTERS is Array, "chapters use the Array schema consumed by the campaign UI")
	_check(HiringContent.CHAPTERS.size() == 5, "campaign contains exactly five chapters")
	_check(HiringContent.MODEL_PROGRESSION.size() == 5, "model progression contains exactly one row per chapter")
	var durations: Array[int] = []
	var official_names: Array[String] = []
	var nicknames: Array[String] = []
	for index in HiringContent.CHAPTERS.size():
		var chapter: Dictionary = HiringContent.CHAPTERS[index]
		_validate_chapter_schema(chapter, index)
		durations.append(int(chapter.get("duration", -1)))
		official_names.append(str(chapter.get("model_official", "")))
		nicknames.append(str(chapter.get("model_nickname", "")))
		var progression: Dictionary = HiringContent.MODEL_PROGRESSION[index]
		_check(int(progression.get("chapter", -1)) == index, "model progression row %d matches its chapter" % index)
		_check(str(progression.get("official", "")) == official_names[-1], "chapter %d and model progression share the official model name" % index)
		_check(str(progression.get("nickname", "")) == nicknames[-1], "chapter %d and model progression share the private model name" % index)
	_check(durations == EXPECTED_CHAPTER_DURATIONS, "chapter durations are exactly 3, 8, 12, 14, and 8 weeks")
	_check(official_names == EXPECTED_MODEL_NAMES, "official model name quietly shortens across all five chapters")
	_check(nicknames == EXPECTED_MODEL_NICKNAMES, "the nickname disappears only in chapter four")
	var total_weeks: int = 0
	for duration in durations:
		total_weeks += duration
	_check(total_weeks == 45, "chapter calendar contains exactly forty-five fixed weeks")
	_check(HiringContent.FIXED_EVENTS is Dictionary, "fixed events use the keyed Dictionary schema")
	_check(HiringContent.FIXED_EVENTS.size() == 45, "fixed event registry contains exactly forty-five week keys")
	_check(_sorted_strings(HiringContent.FIXED_EVENTS.keys()) == _sorted_strings(EXPECTED_FIXED_EVENT_IDS.keys()), "fixed event keys cover every and only chapter-week pair")
	var seen_ids: Array[String] = []
	for key_value in EXPECTED_FIXED_EVENT_IDS:
		var key := str(key_value)
		_check(HiringContent.FIXED_EVENTS.has(key), "fixed event key %s exists" % key)
		if not HiringContent.FIXED_EVENTS.has(key):
			continue
		var event: Dictionary = HiringContent.FIXED_EVENTS[key]
		var expected_id := str(EXPECTED_FIXED_EVENT_IDS[key])
		_check(str(event.get("id", "")) == expected_id, "%s resolves to canonical event '%s'" % [key, expected_id])
		_check(not seen_ids.has(expected_id), "fixed event id '%s' is unique" % expected_id)
		seen_ids.append(expected_id)
		_validate_event_schema(event, "fixed event %s" % key)
		var parts := key.split(":")
		var copy: Dictionary = HiringContent.get_fixed_event(int(parts[0]), int(parts[1]))
		_check(copy == event and not copy.is_empty(), "fixed event query returns the complete %s payload" % key)
	_check(HiringContent.get_fixed_event(5, 1).is_empty(), "out-of-campaign fixed week queries return an empty dictionary")


func _test_world_stats_stages_and_memories() -> void:
	var company: Dictionary = HiringContent.COMPANY_PROFILE
	_check(str(company.get("default_name", "")) == "提灯实验室", "canonical company name is 提灯实验室")
	_check(str(company.get("english_name", "")) == "Lantern Labs", "canonical English company name is Lantern Labs")
	_check(bool(company.get("player_can_rename", false)), "company profile explicitly permits renaming")
	_check(str(company.get("location", "")).contains("现在") and str(company.get("location", "")).contains("湾区"), "company is explicitly set in the present-day Bay Area")
	_check(str(company.get("origin", "")).contains("两个人") and str(company.get("origin", "")).contains("一张显卡"), "company origin retains two people and one GPU")
	_check(str(company.get("first_mission", "")) == "做一个能听懂人在说什么的东西。", "first mission is preserved exactly")
	_check(str(company.get("protagonist", "")).contains("无名、无脸") and str(company.get("protagonist", "")).contains("家庭背景留白"), "protagonist remains unnamed and faceless while only the shared Lin history is fixed")
	var protagonist_tell := str(company.get("protagonist_tell", ""))
	_check(protagonist_tell.contains("我们") and protagonist_tell.contains("从不") and protagonist_tell.contains("停顿"), "protagonist's sole explicit tell is retained")
	_check(HiringContent.WORLD_RULES.size() == 5, "the registry contains exactly the five supernatural iron rules")
	var world_text := _flatten_text(HiringContent.WORLD_RULES)
	for term in ["办公室", "不威胁", "不被解释", "行政", "系统认为存在"]:
		_check(world_text.contains(term), "five world rules retain required term '%s'" % term)
	_check(HiringContent.STAT_DEFINITIONS.size() == 7, "all seven tracked values are declared despite the bible's six-value heading")
	var expected_stats: Array[String] = ["author_weight", "capability", "cash_weeks", "coherence", "compute", "debt", "narrative"]
	var actual_stats: Array[String] = []
	for stat_value in HiringContent.STAT_DEFINITIONS:
		var stat: Dictionary = stat_value
		actual_stats.append(str(stat.get("id", "")))
		_check(stat.get("name") is String and not str(stat.get("name", "")).is_empty(), "stat '%s' has a display name" % str(stat.get("id", "")))
		_check(stat.get("visible") is bool, "stat '%s' has an explicit visibility boolean" % str(stat.get("id", "")))
		_check(stat.get("display") is String and stat.get("meaning") is String, "stat '%s' provides display and meaning strings" % str(stat.get("id", "")))
	actual_stats.sort()
	_check(actual_stats == expected_stats, "stat registry contains the exact seven canonical ids")
	_check(not bool(_stat_by_id("debt").get("visible", true)) and not bool(_stat_by_id("author_weight").get("visible", true)), "debt and author weight are explicitly hidden")
	_check(str(_stat_by_id("cash_weeks").get("display", "")).contains("几周"), "cash is displayed as remaining weeks")
	_check(HiringContent.ECONOMY_RULES.size() == 5, "five economy rules cover narrative-only funding, decay, debt, attention, and delegation")
	var economy_ids: Array[String] = []
	for rule_value in HiringContent.ECONOMY_RULES:
		var rule: Dictionary = rule_value
		economy_ids.append(str(rule.get("id", "")))
	_check(_sorted_strings(economy_ids) == ["attention", "debt", "delegation_comfort", "funding_narrative_only", "weekly_decay"], "economy rule ids are canonical and complete")
	_check(HiringContent.AUTHOR_STAGES.size() == 5, "author weight has exactly five behavior stages")
	for stage_index in HiringContent.AUTHOR_STAGES.size():
		var stage: Dictionary = HiringContent.AUTHOR_STAGES[stage_index]
		_check(int(stage.get("id", -1)) == stage_index + 1, "author stage %d has the canonical sequential id" % (stage_index + 1))
		_check(stage.get("threshold") is int or stage.get("threshold") is float, "author stage %d has a numeric threshold" % (stage_index + 1))
		_check(stage.get("behavior") is String and not str(stage.get("behavior", "")).is_empty(), "author stage %d has authored behavior" % (stage_index + 1))
	_check(HiringContent.MEMORY_CALLBACKS.size() == 6, "all six specified cross-week memory callbacks are registered")
	var memory_ids: Array[String] = []
	for memory_value in HiringContent.MEMORY_CALLBACKS:
		var memory: Dictionary = memory_value
		memory_ids.append(str(memory.get("memory", "")))
		_check(memory.get("created_by") is String and memory.get("callback") is String, "memory '%s' has source and callback text" % str(memory.get("memory", "")))
	_check(_sorted_strings(memory_ids) == ["chen_xiaoyu_laid_off", "demo_video_used", "missed_meals_3", "never_delegated", "promised_no_layoffs", "values_v3_written"], "six memory callbacks use the canonical ids")


func _test_anomaly_registry_and_external_boundary() -> void:
	var expected_ids := ["elevator_floor", "future_mug", "meeting_room_d", "shen_yan", "window_desks"]
	_check(HiringContent.WORLD_RULES.size() == 5, "surreal canon retains exactly five global rules")
	_check(HiringContent.ANOMALY_REGISTRY is Dictionary, "anomalies use one canonical registry")
	_check(_sorted_strings(HiringContent.ANOMALY_REGISTRY.keys()) == expected_ids, "anomaly registry contains every and only the five canonical office anomalies")
	var anomaly_markers: Array[String] = []
	for anomaly_id_value in HiringContent.ANOMALY_REGISTRY:
		var anomaly_id := str(anomaly_id_value)
		var anomaly: Dictionary = HiringContent.ANOMALY_REGISTRY[anomaly_id]
		_check(str(anomaly.get("id", "")) == anomaly_id, "anomaly '%s' repeats its stable id" % anomaly_id)
		_check(str(anomaly.get("location", "")) == "leased_office", "anomaly '%s' stays inside the leased-office boundary" % anomaly_id)
		_check(not bool(anomaly.get("threatening", true)), "anomaly '%s' is explicitly non-threatening" % anomaly_id)
		_check(not bool(anomaly.get("explained", true)), "anomaly '%s' has no explanatory reveal" % anomaly_id)
		_check(bool(anomaly.get("system_extension", false)), "anomaly '%s' is an administrative-system extension" % anomaly_id)
		_check(not str(anomaly.get("administrative_source", "")).is_empty(), "anomaly '%s' declares a nonempty administrative source" % anomaly_id)
		_check(str(anomaly.get("software_surface", "")).begins_with("ordinary:"), "anomaly '%s' uses an ordinary software surface" % anomaly_id)
		var reaction := str(anomaly.get("restrained_reaction", ""))
		_check(not reaction.is_empty() and not reaction.contains("尖叫") and not reaction.contains("逃跑") and not reaction.contains("真相"), "anomaly '%s' receives only a restrained administrative reaction" % anomaly_id)
		for marker_value in anomaly.get("content_markers", []):
			var marker := str(marker_value)
			_check(not marker.is_empty(), "anomaly '%s' has a nonempty content marker" % anomaly_id)
			anomaly_markers.append(marker)
	var external_terms := ["咖啡馆", "家里", "街道", "楼下 ·", "回办公室的路上"]
	for registry_value in [HiringContent.FIXED_EVENTS, HiringContent.GENERIC_EVENTS]:
		for event_value in Dictionary(registry_value).values():
			if not event_value is Dictionary:
				continue
			var event: Dictionary = event_value
			var event_text := _flatten_text(event)
			var external := false
			for term_value in external_terms:
				external = external or event_text.contains(str(term_value))
			if not external:
				continue
			for marker in anomaly_markers:
				_check(not event_text.contains(marker), "external beat '%s' contains no office anomaly marker '%s'" % [str(event.get("id", "")), marker])


func _test_all_actions_and_effect_contracts() -> void:
	_check(HiringContent.ACTIONS is Dictionary, "actions use the Dictionary schema keyed by canonical id")
	_check(HiringContent.ACTIONS.size() == 26, "action registry contains exactly twenty-six canonical actions")
	_check(_sorted_strings(HiringContent.ACTIONS.keys()) == EXPECTED_ACTION_IDS, "action registry contains every and only canonical action id")
	var allowed_categories: Array[String] = ["narrative", "capability", "team", "operations", "finale"]
	for action_id in EXPECTED_ACTION_IDS:
		_check(HiringContent.ACTIONS.has(action_id), "canonical action '%s' exists" % action_id)
		if not HiringContent.ACTIONS.has(action_id):
			continue
		var action: Dictionary = HiringContent.ACTIONS[action_id]
		_check(str(action.get("id", "")) == action_id, "action '%s' repeats its canonical id" % action_id)
		_check(action.get("name") is String and not str(action.get("name", "")).is_empty(), "action '%s' has a nonempty UI name" % action_id)
		_check(action.get("category") is String and allowed_categories.has(str(action.get("category", ""))), "action '%s' has a UI-supported category" % action_id)
		_check(action.get("unlock_chapter") is int and int(action.get("unlock_chapter", -1)) in range(0, 5), "action '%s' has an integer chapter unlock in range" % action_id)
		_check(action.get("attention") is int and int(action.get("attention", 0)) == 1, "action '%s' consumes exactly one manual attention point" % action_id)
		_check(action.get("description") is String and not str(action.get("description", "")).is_empty(), "action '%s' has usable result/detail copy" % action_id)
		_check(action.get("effects") is Dictionary, "action '%s' provides explicit self effects" % action_id)
		_check(action.get("ai_effects") is Dictionary, "action '%s' provides explicit AI effects" % action_id)
		var manual: Dictionary = action.get("effects", {})
		var delegated: Dictionary = action.get("ai_effects", {})
		_check(_effect_dictionary_is_supported(manual), "action '%s' self effects use supported scalar/range types" % action_id)
		_check(_effect_dictionary_is_supported(delegated), "action '%s' AI effects use supported scalar/range types" % action_id)
		if action_id == "sign":
			_check(delegated.is_empty(), "sign is the explicit finale exception whose delegated form also has zero mechanical effects")
		else:
			_check(delegated.has("author_weight") and _is_number(delegated.get("author_weight")) and float(delegated.get("author_weight", 0)) > 0.0, "action '%s' delegation explicitly raises author weight" % action_id)
		var required: Dictionary = REQUIRED_MANUAL_EFFECTS[action_id]
		for effect_key_value in required:
			var effect_key := str(effect_key_value)
			_check(manual.has(effect_key), "action '%s' declares required self effect '%s'" % [action_id, effect_key])
			if manual.has(effect_key):
				_check(manual[effect_key] == required[effect_key], "action '%s' keeps the canonical '%s' magnitude" % [action_id, effect_key])
		var queried: Dictionary = HiringContent.get_action(action_id)
		_check(queried == action and not queried.is_empty(), "action query returns complete content for '%s'" % action_id)
		if action_id == "eval":
			var eval_description := str(action.get("description", ""))
			_check(eval_description.contains("核验") and not eval_description.contains("看见"), "eval describes verification rather than unlocking the always-visible capability value")
			var repeat_description := str(action.get("repeat_description", ""))
			_check(repeat_description.contains("更新核验记录") and repeat_description.contains("不会再次"), "eval owns stable player-facing copy for its non-repaying repeat state")
	var candidate_event: Dictionary = HiringContent.GENERIC_EVENTS["hiring_candidates"]
	for candidate_choice_value in Array(candidate_event.get("choices", [])).slice(0, 3):
		var candidate_choice: Dictionary = candidate_choice_value
		_check(not Dictionary(candidate_choice.get("effects", {})).has("cash_weeks"), "candidate invitation '%s' has no unlisted immediate cash cost" % str(candidate_choice.get("id", "candidate")))
	for delayed_action_id in ["manifesto", "exclusive_interview", "layoffs"]:
		var delayed_action: Dictionary = HiringContent.ACTIONS[delayed_action_id]
		_check(int(delayed_action.get("unlock_chapter", -1)) == 3 and int(delayed_action.get("unlock_week", -1)) == 2, "action '%s' is gated to Series A week two rather than chapter entry" % delayed_action_id)
	_check(HiringContent.get_action("not_an_action").is_empty(), "unknown action queries return an empty dictionary")


func _test_required_events_scenes_and_terms() -> void:
	for event_id_value in REQUIRED_EVENT_TERMS:
		var event_id := str(event_id_value)
		var event := _fixed_event_by_id(event_id)
		_check(not event.is_empty(), "required scene/event '%s' is reachable from a fixed week" % event_id)
		var text := _flatten_text(event)
		for term_value in REQUIRED_EVENT_TERMS[event_id]:
			var term := str(term_value)
			_check(text.contains(term), "event '%s' retains required term '%s'" % [event_id, term])
	var window_setup_text := _flatten_text(_fixed_event_by_id("window_desks"))
	_check(not window_setup_text.contains("查了一下") and not window_setup_text.contains("三十七人，一个不多") and not window_setup_text.contains("把窗帘拉上"), "window setup stops before the player's count check and curtain interaction")
	var origin_setup_text := _flatten_text(_fixed_event_by_id("origin_article_event"))
	_check(not origin_setup_text.contains("读了三遍") and not origin_setup_text.contains("打开编辑框") and not origin_setup_text.contains("编辑框关了"), "origin setup does not pre-narrate the three reads or unchanged editor close")
	var lin_scene_ids: Array[String] = ["lin_scene_1", "lin_scene_2", "lin_scene_3", "lin_scene_4", "lin_last_visit"]
	for lin_id in lin_scene_ids:
		_check(not _fixed_event_by_id(lin_id).is_empty(), "Lin Yue has required chapter scene '%s'" % lin_id)
	var first_lin := _fixed_event_by_id("lin_scene_1")
	_check(Array(first_lin.get("choices", [])).is_empty(), "Lin Yue scene one deliberately records no player response")
	var second_lin := _fixed_event_by_id("lin_scene_2")
	_check(Array(second_lin.get("pages", [])).size() == 5, "Lin Yue scene two declares separate speech/silence/speech/silence/speech presentation beats")
	_check(Array(second_lin.get("silence_pages", [])) == [1, 3], "Lin Yue scene two marks exactly two distinct silent pages")
	_check(Array(second_lin.get("page_hold_seconds", [])) == [0.0, 120.0, 0.0, 120.0, 0.0], "Lin Yue scene two preserves both approximately two-minute pauses as runtime holds")
	_check(not _flatten_text(second_lin).contains("一次") and not _flatten_text(second_lin).contains("零次"), "Lin Yue scene two no longer fabricates training counts that can contradict play history")
	var first_model_statement := _fixed_event_by_id("model_first_sentence")
	_check(str(first_model_statement.get("semantic_role", "")) == "most_honest_model_statement", "the first unsolicited model confession carries the unique authored honesty role without telling the player")
	_check(not _flatten_text(first_model_statement).contains("最诚实") and not _flatten_text(first_model_statement).contains("全游戏"), "the player-facing confession never labels its own narrative function or breaks the fourth wall")
	var honesty_role_count := 0
	for fixed_event_value in HiringContent.FIXED_EVENTS.values():
		if fixed_event_value is Dictionary and str(Dictionary(fixed_event_value).get("semantic_role", "")) == "most_honest_model_statement":
			honesty_role_count += 1
	_check(honesty_role_count == 1, "exactly one model utterance owns the most-honest semantic role across the campaign")
	var scene_three := _fixed_event_by_id("lin_scene_3")
	_check(_choice_ids(scene_three.get("choices", [])) == ["admit", "deflect", "delegate"], "Lin Yue scene three exposes the exact three canonical choices")
	var scene_four := _fixed_event_by_id("lin_scene_4")
	_check(scene_four.get("variants") is Dictionary, "Lin Yue scene four declares high, trained-low, and truthful-low variants")
	if scene_four.get("variants") is Dictionary:
		var variants: Dictionary = scene_four["variants"]
		_check(_sorted_strings(variants.keys()) == ["high_author", "low_author_fallback", "trained_low_author"], "Lin Yue scene four contains exactly the three approved gate variants")
		_check(Array(variants.keys()) == ["high_author", "trained_low_author", "low_author_fallback"], "Lin scene variant insertion order enforces 60 gate before trained-low before fallback")
		_check(_flatten_text(variants.get("high_author", {})).contains("author_weight >= 60"), "high-author Lin scene declares the sixty-point gate")
		var trained_low: Dictionary = Dictionary(variants.get("trained_low_author", {}))
		var fallback: Dictionary = Dictionary(variants.get("low_author_fallback", {}))
		_check(str(trained_low.get("condition", "")) == "author_weight < 60 and manual_training_count >= 3", "warm Lin scene requires three founder-authored train/large-train actions below author sixty")
		_check(str(fallback.get("condition", "")) == "author_weight < 60", "truthful manual fallback covers every remaining sub-sixty route")
		_check(_flatten_text(trained_low).contains("两罐啤酒") and _flatten_text(trained_low).contains("lin_warm_scene"), "only the trained-low variant contains the canonical warm beer callback")
		_check(not _flatten_text(fallback).contains("啤酒") and not _flatten_text(fallback).contains("lin_warm_scene") and not _choices_have_delegation(fallback.get("choices", [])), "untrained low-author fallback is truthful, non-warm, and fully manual")
		var high_delegate := _choice_by_id(Dictionary(variants.get("high_author", {})).get("choices", []), "delegate")
		_check(float(Dictionary(high_delegate.get("effects", {})).get("belief", 0.0)) <= -100.0, "LIN-004A4 can reduce Lin Yue's belief to zero")
		_check(Array(high_delegate.get("flags", [])).has("lin_departure_deferred") and Array(high_delegate.get("flags", [])).has("lin_will_leave"), "LIN-004A4 explicitly records a save-stable deferred departure")
	var last_visit := _fixed_event_by_id("lin_last_visit")
	var last_variants: Dictionary = Dictionary(last_visit.get("variants", {}))
	_check(Array(last_variants.keys()) == ["checks_intranet", "suspicious", "locked_15", "warm"], "Lin's final present visit declares checks > suspicious/locked > warm priority")
	for variant_value in last_variants.values():
		var variant: Dictionary = variant_value
		_check(not variant.has("choices"), "Lin final-visit history variants preserve the approved base choices")

	var one_on_one: Dictionary = HiringContent.GENERIC_EVENTS["one_on_one_reveal"]
	var listen := _choice_by_id(one_on_one.get("choices", []), "listen")
	var solve := _choice_by_id(one_on_one.get("choices", []), "solve")
	var delegated := _choice_by_id(one_on_one.get("choices", []), "delegate")
	_check(float(Dictionary(listen.get("effects", {})).get("morale", 0.0)) == 20.0 and float(Dictionary(solve.get("effects", {})).get("morale", 0.0)) == 20.0, "both manual one-on-one answers grant target-only morale plus twenty")
	_check(float(Dictionary(delegated.get("effects", {})).get("morale", 0.0)) == 24.0, "delegated one-on-one retains its target-only morale plus twenty-four")

	var layoff_copy := _flatten_text(_fixed_event_by_id("layoff_execution"))
	_check(not layoff_copy.contains("第 24 周") and not layoff_copy.contains("41 个赞"), "layoff source copy contains no fabricated fixed promise chronology")

	var cash_crisis := _fixed_event_by_id("cash_crisis")
	var layoff_route := _choice_by_id(cash_crisis.get("choices", []), "prepare_layoffs")
	var contract_route := _choice_by_id(cash_crisis.get("choices", []), "take_contract")
	var ai_route := _choice_by_id(cash_crisis.get("choices", []), "delegate")
	_check(str(cash_crisis.get("after", "")) == "queue:layoff_execution", "cash crisis routes through the director's conditional layoff queue")
	_check(Array(layoff_route.get("flags", [])).has("layoffs_required") and Array(ai_route.get("flags", [])).has("layoffs_required"), "layoff and AI cash-crisis routes require the week-seven execution")
	_check(Array(contract_route.get("flags", [])).has("cash_crisis_contract") and not Array(contract_route.get("flags", [])).has("layoffs_required"), "outsourcing is a real non-layoff cash-crisis route")
	_check(str(_fixed_event_by_id("layoff_execution").get("condition", "")) == "layoffs_required", "week-seven layoff execution is conditioned on the chosen crisis route")


func _test_all_decisions_have_delegation() -> void:
	_scan_decision_contract(HiringContent.FIXED_EVENTS, "FIXED_EVENTS")
	_check(HiringContent.GENERIC_EVENTS is Dictionary, "generic events use a Dictionary registry")
	_scan_decision_contract(HiringContent.GENERIC_EVENTS, "GENERIC_EVENTS")
	_scan_decision_contract(HiringContent.ENDINGS, "ENDINGS")


func _test_lin_tone_lint() -> void:
	var lin_sources: Array = [HiringContent.EMPLOYEE_TEMPLATES["lin_yue"]]
	for event_id in ["lin_scene_1", "lin_scene_2", "lin_scene_3", "lin_scene_4", "lin_last_visit"]:
		lin_sources.append(_fixed_event_by_id(event_id))
	var lines: Array[String] = []
	for source in lin_sources:
		_collect_strings(source, lines)
	var spoken_segments := 0
	for line in lines:
		_check(not _contains_emoji(line), "Lin corpus line contains no emoji: %s" % line)
		var cursor := 0
		while true:
			var opening := line.find("『", cursor)
			if opening < 0:
				break
			var closing := line.find("』", opening + 1)
			_check(closing > opening, "Lin dialogue has a complete closing quote: %s" % line)
			if closing <= opening:
				break
			var spoken := line.substr(opening + 1, closing - opening - 1)
			_check(not spoken.is_empty() and spoken.length() <= 32, "Lin dialogue remains a complete short line (1-32 chars): %s" % spoken)
			spoken_segments += 1
			cursor = closing + 1
	for quote_key in ["hire_quote", "one_on_one", "quit_clean", "quit_witnessed"]:
		var profile_line := str(HiringContent.EMPLOYEE_TEMPLATES["lin_yue"].get(quote_key, ""))
		_check(not profile_line.is_empty() and profile_line.length() <= 32, "Lin employee line '%s' remains short and complete" % quote_key)
	_check(spoken_segments >= 20, "Lin tone lint inspects the complete authored dialogue corpus")


func _test_employees_and_chen_cups() -> void:
	_check(HiringContent.EMPLOYEE_TEMPLATES is Dictionary, "employee templates use a canonical-id Dictionary")
	_check(HiringContent.EMPLOYEE_TEMPLATES.size() == 12, "employee registry contains exactly twelve authored people")
	_check(_sorted_strings(HiringContent.EMPLOYEE_TEMPLATES.keys()) == EXPECTED_EMPLOYEE_IDS, "employee registry contains every and only canonical employee id")
	var main_count := 0
	for employee_id in EXPECTED_EMPLOYEE_IDS:
		var employee: Dictionary = HiringContent.EMPLOYEE_TEMPLATES[employee_id]
		_check(str(employee.get("id", "")) == employee_id, "employee '%s' repeats its canonical id" % employee_id)
		for text_key in ["name", "role", "desk"]:
			_check(employee.get(text_key) is String and not str(employee.get(text_key, "")).is_empty(), "employee '%s' has nonempty %s text" % [employee_id, text_key])
		_check(employee.get("available_chapter") is int and int(employee.get("available_chapter", -1)) in range(0, 5), "employee '%s' has a valid availability chapter" % employee_id)
		_check(employee.get("skills") is Dictionary and not Dictionary(employee.get("skills", {})).is_empty(), "employee '%s' has a nonempty skills dictionary" % employee_id)
		if employee.get("skills") is Dictionary:
			for skill_value in Dictionary(employee["skills"]).values():
				_check(_is_number(skill_value), "employee '%s' skill magnitudes are numeric" % employee_id)
		_check(_is_number(employee.get("morale")) and _is_number(employee.get("belief")), "employee '%s' has numeric morale and belief" % employee_id)
		_check(employee.get("traits") is Array and not Array(employee.get("traits", [])).is_empty(), "employee '%s' has authored traits")
		for quote_key in ["hire_quote", "one_on_one", "quit_clean", "quit_witnessed"]:
			_check(employee.get(quote_key) is String, "employee '%s' %s uses the UI string schema" % [employee_id, quote_key])
		_check(employee.get("is_main") is bool, "employee '%s' explicitly declares main-character status" % employee_id)
		if bool(employee.get("is_main", false)):
			main_count += 1
	_check(main_count == 1 and bool(HiringContent.EMPLOYEE_TEMPLATES["lin_yue"].get("is_main", false)), "Lin Yue is the sole main employee template")
	var chen: Dictionary = HiringContent.EMPLOYEE_TEMPLATES["chen_xiaoyu"]
	_check(str(chen.get("name", "")) == "陈小雨" and str(chen.get("role", "")) == "数据工程师", "Chen Xiaoyu has the canonical name and role")
	_check(_flatten_text(chen.get("traits", [])).contains("三个没喝完的杯子"), "Chen's traits preserve exactly three unfinished cups")
	var chen_desk := str(chen.get("desk", ""))
	_check(chen_desk.contains("三个杯子") and chen_desk.contains("冷咖啡") and chen_desk.contains("茶包") and chen_desk.contains("杯底"), "Chen's desk individually accounts for all three cups")
	for quote_key in ["hire_quote", "one_on_one", "quit_clean", "quit_witnessed"]:
		_check(not str(chen.get(quote_key, "")).is_empty(), "Chen has required nonempty '%s' scene copy" % quote_key)
	var ghost: Dictionary = HiringContent.EMPLOYEE_TEMPLATES["shen_yan"]
	_check(_flatten_text(ghost).contains("从来没人见过"), "the phantom employee remains explicitly unseen")
	_check(_flatten_text(ghost).contains("杯子是空的") and _flatten_text(ghost).contains("凹陷"), "the phantom desk retains its empty cup and occupied-chair indentation")
	var hireable: Array[Dictionary] = HiringContent.hireable_employees(4, [])
	var hireable_ids: Array[String] = []
	for employee in hireable:
		hireable_ids.append(str(employee.get("id", "")))
	_check(not hireable_ids.has("lin_yue") and not hireable_ids.has("shen_yan"), "main and phantom employees never enter the ordinary candidate pool")


func _test_night_shifts_and_exact_terminal_marker() -> void:
	_check(HiringContent.NIGHT_SHIFTS is Dictionary, "night shifts use a keyed Dictionary registry")
	_check(HiringContent.NIGHT_SHIFTS.size() == 2, "registry contains exactly two night shifts")
	_check(_sorted_strings(HiringContent.NIGHT_SHIFTS.keys()) == ["1", "2"], "night shifts use canonical ids one and two")
	var expected_objects: Dictionary = {
		"1": ["corridor", "fridge", "mug", "pothos", "whiteboard"],
		"2": ["meeting_room_d", "pothos", "terminal", "window_desk"],
	}
	var total_objects := 0
	var command_markers := 0
	for night_id_value in ["1", "2"]:
		var night_id := str(night_id_value)
		var night: Dictionary = HiringContent.NIGHT_SHIFTS[night_id]
		_check(night.get("id") is String and not str(night.get("id", "")).is_empty(), "night shift %s has a stable id" % night_id)
		_check(night.get("chapter") is int and int(night.get("chapter", -1)) in [2, 3], "night shift %s belongs to chapter two or three" % night_id)
		for text_key in ["title", "subtitle", "exit_condition", "exit_text"]:
			_check(night.get(text_key) is String and not str(night.get(text_key, "")).is_empty(), "night shift %s has UI-safe %s text" % [night_id, text_key])
		_check(_is_string_array(night.get("intro")), "night shift %s intro is an array of strings" % night_id)
		_check(night.get("objects") is Dictionary or night.get("objects") is Array, "night shift %s objects use the approved keyed-Dictionary or Array adapter schema" % night_id)
		var objects := _night_objects_as_array(night.get("objects", []))
		total_objects += objects.size()
		var expected_count := 5 if night_id == "1" else 4
		_check(objects.size() == expected_count, "night shift %s contains its authored %d clickable objects" % [night_id, expected_count])
		var object_ids: Array[String] = []
		for object_value in objects:
			var object: Dictionary = object_value
			var object_id := str(object.get("id", ""))
			object_ids.append(object_id)
			_check(not object_id.is_empty(), "night shift %s object has a stable id" % night_id)
			_check(object.get("label") is String and not str(object.get("label", "")).is_empty(), "night object %s/%s has a UI label" % [night_id, object_id])
			_check(_is_string_array(object.get("body")), "night object %s/%s body is an array of strings" % [night_id, object_id])
			_check(_is_string_array(object.get("flags")), "night object %s/%s flags are an array of strings" % [night_id, object_id])
			_check(object.get("command") is String, "night object %s/%s command marker uses a string" % [night_id, object_id])
			if str(object.get("command", "")) == "rm -rf":
				command_markers += 1
				_check(object_id == "terminal", "the exact rm -rf marker belongs only to the terminal object")
				_check(str(object.get("command_hint", "")).contains("没有确认提示"), "rm -rf marker explicitly documents the no-confirmation behavior")
		_check(_sorted_strings(object_ids) == expected_objects[night_id], "night shift %s contains every and only canonical object" % night_id)
	_check(total_objects == 9, "night one has five objects and night two has four, for nine authored object records")
	_check(command_markers == 1, "exactly one night object carries the exact rm -rf command marker")
	var night_text := _flatten_text(HiringContent.NIGHT_SHIFTS)
	for term in ["这不是我们的 logo", "8 月 3 日", "8 月 19 日", "三分之二", "两厘米", "下周同一时间", "Ctrl+C", "电费是公司出的"]:
		_check(night_text.contains(term), "night-shift content retains required term '%s'" % term)


func _test_intranet_documents_and_report_91() -> void:
	_check(HiringContent.INTRANET_DOCS is Dictionary, "intranet documents use a canonical-id Dictionary")
	_check(HiringContent.INTRANET_DOCS.size() == 6, "intranet contains exactly six authored documents")
	_check(_sorted_strings(HiringContent.INTRANET_DOCS.keys()) == EXPECTED_DOC_IDS, "intranet contains every and only canonical document id")
	for doc_id in EXPECTED_DOC_IDS:
		var doc: Dictionary = HiringContent.INTRANET_DOCS[doc_id]
		_check(str(doc.get("id", "")) == doc_id, "document '%s' repeats its canonical id" % doc_id)
		_check(doc.get("chapter") is int and int(doc.get("chapter", -1)) in range(0, 5), "document '%s' has a valid chapter" % doc_id)
		_check(doc.get("week") is int and int(doc.get("week", 0)) >= 1, "document '%s' has a positive integer week" % doc_id)
		for text_key in ["type", "title", "author", "date"]:
			_check(doc.get(text_key) is String and not str(doc.get(text_key, "")).is_empty(), "document '%s' has UI-safe %s text" % [doc_id, text_key])
		_check(_is_string_array(doc.get("body")) and not Array(doc.get("body", [])).is_empty(), "document '%s' body is a nonempty string array" % doc_id)
		_check(_is_string_array(doc.get("flags")), "document '%s' flags are a string array" % doc_id)
		_check(HiringContent.get_intranet_doc(doc_id) == doc, "document query returns complete content for '%s'" % doc_id)
	var report: Dictionary = HiringContent.INTRANET_DOCS["weekly_report_91"]
	_check(str(report.get("title", "")).contains("91") and str(report.get("author", "")) == "沈砚", "report 91 has the exact sequence number and phantom author")
	var report_text := _flatten_text(report)
	for term in ["本周完成", "下周计划", "风险", "需要协助", "会议室 D", "无。谢谢。"]:
		_check(report_text.contains(term), "report 91 retains required section/term '%s'" % term)
	var origin_text := _flatten_text(HiringContent.INTRANET_DOCS["our_origin"])
	_check(origin_text.contains("我们说") and origin_text.contains("先这样") and origin_text.contains("不完美地开始"), "origin article performs the required authorship drift")
	_check(_flatten_text(HiringContent.INTRANET_DOCS["values_v1"]).contains("如果做不出来，就说做不出来"), "first values document remains in the corpus")
	_check(_flatten_text(HiringContent.INTRANET_DOCS["values_v3"]).contains("审慎"), "third values document contains the word Lin Yue recognizes")
	_check(_flatten_text(HiringContent.INTRANET_DOCS["values_v3"]).contains("图书馆一起熬过"), "third values document contains the mistaken all-nighter source Lin later corrects")
	_check(not str(HiringContent.GENERIC_EVENTS["debt_collection"].get("kicker", "")).contains("债"), "visible fulfillment copy never names the hidden debt stat")


func _test_all_seven_endings() -> void:
	_check(HiringContent.ENDINGS is Dictionary, "endings use a canonical-id Dictionary registry")
	_check(HiringContent.ENDINGS.size() == 7, "ending registry contains exactly seven endings")
	_check(_sorted_strings(HiringContent.ENDINGS.keys()) == EXPECTED_ENDING_IDS, "ending registry contains every and only canonical ending id")
	var priorities: Array[int] = []
	for ending_id in EXPECTED_ENDING_IDS:
		var ending: Dictionary = HiringContent.ENDINGS[ending_id]
		_check(str(ending.get("id", "")) == ending_id, "ending '%s' repeats its canonical id" % ending_id)
		_check(ending.get("title") is String and not str(ending.get("title", "")).is_empty(), "ending '%s' has a display title" % ending_id)
		_check(ending.get("priority") is int, "ending '%s' has an explicit integer priority" % ending_id)
		if ending.get("priority") is int:
			priorities.append(int(ending["priority"]))
		_check(ending.get("trigger") is String and not str(ending.get("trigger", "")).is_empty(), "ending '%s' has an explicit trigger expression" % ending_id)
		_check(_ending_text_is_ui_safe(ending.get("text")) and not Array(ending.get("text", [])).is_empty(), "ending '%s' has nonempty authored text accepted by the UI" % ending_id)
		_check(ending.get("choices") is Array, "ending '%s' choices use an Array" % ending_id)
		_check(ending.get("final_line") is String and not str(ending.get("final_line", "")).is_empty(), "ending '%s' has a final line" % ending_id)
		_check(HiringContent.get_ending(ending_id) == ending, "ending query returns complete content for '%s'" % ending_id)
	priorities.sort()
	_check(_unique_ints(priorities).size() == 7, "all seven ending priorities are unique and deterministic")
	var trigger_terms: Dictionary = {
		"acquihire": ["cash_weeks > 0", "author_weight"],
		"lights_out": ["cash_weeks <= 0"],
		"independent": ["capability >= 80", "debt < 10"],
		"successor": ["author_weight >= 100"],
		"drift": ["coherence < 20"],
		"rm_rf": ["terminal_command == 'rm -rf'"],
		"second_time": ["playthrough_count >= 1", "new_game_week == 1"],
	}
	for ending_id_value in trigger_terms:
		var ending_id := str(ending_id_value)
		var trigger := str(HiringContent.ENDINGS[ending_id].get("trigger", ""))
		for term_value in trigger_terms[ending_id]:
			var term := str(term_value)
			_check(trigger.contains(term), "ending '%s' trigger retains '%s'" % [ending_id, term])
	var second: Dictionary = HiringContent.ENDINGS["second_time"]
	_check(_choice_ids(second.get("choices", [])) == ["dont_know", "pause_dont_know"], "second-time exception has exactly the two canonical choices")
	var second_labels: Array[String] = []
	for choice_value in Array(second.get("choices", [])):
		second_labels.append(str(Dictionary(choice_value).get("label", "")))
	_check(second_labels == ["不知道。", "……不知道。"], "second-time exception offers exactly the two versions of '不知道'")
	_check(_is_string_array(second.get("epilogue")) and _flatten_text(second.get("epilogue", [])).contains("靠窗第二个"), "second-time epilogue places the future mug at the canonical empty desk")
	var ending_text := _flatten_text(HiringContent.ENDINGS)
	for term in ["十一分钟", "400 个付费用户", "周一有一个签字会", "每一句单独看都通顺", "没有确认提示", "第一届全员团建·2024"]:
		_check(ending_text.contains(term), "ending corpus retains required term '%s'" % term)


func _test_ui_facing_schema_and_queries() -> void:
	var content = HiringContent.new()
	_check(content.has_method("chapter"), "content exposes the chapter query used by HiringMain")
	_check(content.has_method("get_fixed_event"), "content exposes the fixed-event query used by HiringMain")
	_check(content.has_method("get_action"), "content exposes the action query")
	_check(content.has_method("get_ending"), "content exposes the ending query used by HiringMain")
	_check(_method_argument_count(content, "chapter") == 1, "chapter query accepts exactly one id")
	_check(_method_argument_count(content, "get_fixed_event") == 2, "fixed-event query accepts chapter and week")
	_check(_method_argument_count(content, "get_action") == 1, "action query accepts exactly one id")
	_check(_method_argument_count(content, "get_ending") == 1, "ending query accepts exactly one id")
	_check(content.callv("chapter", [0]) is Dictionary, "chapter query returns a Dictionary")
	_check(content.callv("get_fixed_event", [0, 1]) is Dictionary, "fixed-event query returns a Dictionary")
	_check(content.callv("get_action", ["tweet"]) is Dictionary, "action query returns a Dictionary")
	_check(content.callv("get_ending", ["independent"]) is Dictionary, "ending query returns a Dictionary")
	_check(HiringContent.NIGHT_SHIFTS.get("1", {}) is Dictionary and HiringContent.NIGHT_SHIFTS.get("2", {}) is Dictionary, "HiringMain can map both canonical night ids directly from NIGHT_SHIFTS")
	_check(HiringContent.INTRANET_DOCS is Dictionary and HiringContent.INTRANET_DOCS.size() == 6, "HiringMain can read the complete keyed INTRANET_DOCS registry directly")
	var ending: Dictionary = HiringContent.get_ending("independent")
	_check(ending.get("text") is Array or ending.get("body") is Array, "ending body uses one of the Array fields accepted by HiringMain")
	for fixed_value in HiringContent.FIXED_EVENTS.values():
		var fixed: Dictionary = fixed_value
		_check(fixed.get("choices") is Array, "fixed event '%s' choices can be iterated by HiringMain" % str(fixed.get("id", "")))
		_check(_event_body_is_ui_safe(fixed), "fixed event '%s' body/pages are renderable by HiringMain" % str(fixed.get("id", "")))


func _validate_chapter_schema(chapter: Dictionary, expected_id: int) -> void:
	_check(chapter.get("id") is int and int(chapter.get("id", -1)) == expected_id, "chapter %d has its sequential integer id" % expected_id)
	for key in ["name", "model_official", "model_nickname", "intention"]:
		_check(chapter.get(key) is String, "chapter %d field '%s' uses a UI string" % [expected_id, key])
	_check(not str(chapter.get("name", "")).is_empty(), "chapter %d has a nonempty display name" % expected_id)
	_check(chapter.get("duration") is int and int(chapter.get("duration", 0)) > 0, "chapter %d has a positive integer duration" % expected_id)
	_check(chapter.get("team_target") is int and int(chapter.get("team_target", 0)) >= 2, "chapter %d has an integer team target" % expected_id)


func _validate_event_schema(event: Dictionary, label: String) -> void:
	for key in ["id", "title", "kicker", "after"]:
		_check(event.get(key) is String, "%s field '%s' uses a UI string" % [label, key])
	_check(not str(event.get("id", "")).is_empty() and not str(event.get("title", "")).is_empty(), "%s has nonempty id and title" % label)
	_check(_event_body_is_ui_safe(event), "%s body/pages use a UI-renderable text schema" % label)
	_check(event.get("choices") is Array, "%s choices use an Array" % label)
	if event.get("choices") is Array:
		for choice_index in Array(event["choices"]).size():
			_validate_choice_schema(Array(event["choices"])[choice_index], "%s choice %d" % [label, choice_index])


func _validate_choice_schema(value, label: String) -> void:
	_check(value is Dictionary, "%s is a Dictionary" % label)
	if not value is Dictionary:
		return
	var choice: Dictionary = value
	_check(choice.get("id") is String and not str(choice.get("id", "")).is_empty(), "%s has a stable id" % label)
	_check(choice.get("label") is String and not str(choice.get("label", "")).is_empty(), "%s has a nonempty label" % label)
	_check(choice.get("ai") is bool, "%s explicitly declares whether it is delegated" % label)
	_check(choice.get("effects") is Dictionary, "%s has explicit effects" % label)
	_check(_effect_dictionary_is_supported(choice.get("effects", {})), "%s effects use supported types" % label)
	_check(_is_string_array(choice.get("result")), "%s result is an array of strings" % label)
	_check(_is_string_array(choice.get("flags")), "%s flags are an array of strings" % label)
	if choice.has("condition"):
		var condition = choice.get("condition")
		_check(condition is String or condition is Dictionary, "%s condition uses the approved String-or-Dictionary adapter schema" % label)
		if condition is String:
			_check(not str(condition).is_empty(), "%s string condition is nonempty" % label)
		elif condition is Dictionary:
			_check(not Dictionary(condition).is_empty(), "%s dictionary condition is nonempty" % label)


func _scan_decision_contract(value, path: String) -> void:
	if value is Dictionary:
		var dictionary: Dictionary = value
		if dictionary.has("choices") and dictionary.get("choices") is Array and not Array(dictionary["choices"]).is_empty():
			var event_id := str(dictionary.get("id", ""))
			var is_manual_lin_variant := path in ["FIXED_EVENTS.3:11.variants.trained_low_author", "FIXED_EVENTS.3:11.variants.low_author_fallback"]
			var is_no_delegation_exception := event_id == "second_time" or is_manual_lin_variant or path == "GENERIC_EVENTS.never_delegated"
			if is_no_delegation_exception:
				_check(not _choices_have_delegation(dictionary["choices"]), "%s is an approved no-delegation exception" % path)
				if is_manual_lin_variant:
					_check(Array(dictionary["choices"]).size() == 3, "%s retains exactly the bible's three manual responses" % path)
					if path.ends_with("trained_low_author"):
						_check(_choice_ids(dictionary["choices"]) == ["far", "farther", "unknown"], "%s retains the exact three canonical warm choice ids" % path)
			else:
				_check(_choices_have_delegation(dictionary["choices"]), "%s decision '%s' has an explicit AI/delegation option" % [path, event_id if not event_id.is_empty() else "variant"])
			for choice_index in Array(dictionary["choices"]).size():
				_validate_choice_schema(Array(dictionary["choices"])[choice_index], "%s choice %d" % [path, choice_index])
		for key_value in dictionary:
			var key := str(key_value)
			if key != "choices":
				_scan_decision_contract(dictionary[key_value], "%s.%s" % [path, key])
	elif value is Array:
		for index in Array(value).size():
			_scan_decision_contract(Array(value)[index], "%s[%d]" % [path, index])


func _choices_have_delegation(value) -> bool:
	if not value is Array:
		return false
	for choice_value in Array(value):
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = choice_value
		if bool(choice.get("ai", false)) or str(choice.get("id", "")) == "delegate" or str(choice.get("label", "")).contains("让它来写"):
			return true
	return false


func _event_body_is_ui_safe(event: Dictionary) -> bool:
	var body = event.get("pages", event.get("body", []))
	if body is String:
		return true
	if not body is Array:
		return false
	for item in Array(body):
		if item is String:
			continue
		if item is Array and _is_string_array(item):
			continue
		return false
	return true


func _effect_dictionary_is_supported(value) -> bool:
	if not value is Dictionary:
		return false
	for effect_value in Dictionary(value).values():
		if _is_number(effect_value) or effect_value is bool or effect_value is String:
			continue
		if effect_value is Array:
			for ranged_value in Array(effect_value):
				if not (_is_number(ranged_value) or ranged_value is String or ranged_value is Dictionary):
					return false
			continue
		if effect_value is Dictionary:
			continue
		return false
	return true


func _fixed_event_by_id(event_id: String) -> Dictionary:
	for value in HiringContent.FIXED_EVENTS.values():
		if value is Dictionary and str(Dictionary(value).get("id", "")) == event_id:
			return Dictionary(value)
	return {}


func _stat_by_id(stat_id: String) -> Dictionary:
	for value in HiringContent.STAT_DEFINITIONS:
		if value is Dictionary and str(Dictionary(value).get("id", "")) == stat_id:
			return Dictionary(value)
	return {}


func _choice_ids(value) -> Array[String]:
	var ids: Array[String] = []
	if value is Array:
		for choice_value in Array(value):
			if choice_value is Dictionary:
				ids.append(str(Dictionary(choice_value).get("id", "")))
	return ids


func _choice_by_id(value, choice_id: String) -> Dictionary:
	if value is Array:
		for choice_value in Array(value):
			if choice_value is Dictionary and str(Dictionary(choice_value).get("id", "")) == choice_id:
				return Dictionary(choice_value)
	return {}


func _night_objects_as_array(value) -> Array[Dictionary]:
	var objects: Array[Dictionary] = []
	if value is Array:
		for object_value in Array(value):
			if object_value is Dictionary:
				objects.append(Dictionary(object_value))
	elif value is Dictionary:
		# Continue auditing individual objects after reporting the UI-incompatible container.
		for object_value in Dictionary(value).values():
			if object_value is Dictionary:
				objects.append(Dictionary(object_value))
	return objects


func _is_string_array(value) -> bool:
	if not value is Array:
		return false
	for item in Array(value):
		if not item is String:
			return false
	return true


func _ending_text_is_ui_safe(value) -> bool:
	if not value is Array:
		return false
	for item in Array(value):
		if item is String:
			continue
		if item is Dictionary:
			var conditional: Dictionary = item
			if str(conditional.get("employee_id", "")).is_empty():
				if str(conditional.get("text", "")).is_empty():
					return false
			elif str(conditional.get("present", "")).is_empty() or str(conditional.get("absent", "")).is_empty():
				return false
			continue
		return false
	return true


func _is_number(value) -> bool:
	return value is int or value is float


func _flatten_text(value) -> String:
	if value is String or value is StringName:
		return str(value)
	var parts: Array[String] = []
	if value is Array:
		for item in Array(value):
			parts.append(_flatten_text(item))
	elif value is Dictionary:
		for key_value in Dictionary(value):
			parts.append(str(key_value))
			parts.append(_flatten_text(Dictionary(value)[key_value]))
	return "\n".join(parts)


func _collect_strings(value, output: Array[String]) -> void:
	if value is String or value is StringName:
		output.append(str(value))
		return
	if value is Array:
		for item in Array(value):
			_collect_strings(item, output)
	elif value is Dictionary:
		for item in Dictionary(value).values():
			_collect_strings(item, output)


func _contains_emoji(value: String) -> bool:
	for index in value.length():
		var codepoint := value.unicode_at(index)
		if (codepoint >= 0x1F300 and codepoint <= 0x1FAFF) or (codepoint >= 0x2600 and codepoint <= 0x27BF) or (codepoint >= 0x1F1E6 and codepoint <= 0x1F1FF) or codepoint == 0xFE0F:
			return true
	return false


func _sorted_strings(value) -> Array[String]:
	var result: Array[String] = []
	for item in value:
		result.append(str(item))
	result.sort()
	return result


func _unique_ints(values: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		if not result.has(value):
			result.append(value)
	return result


func _method_argument_count(object: Object, method_name: String) -> int:
	for method_value in object.get_method_list():
		var method: Dictionary = method_value
		if str(method.get("name", "")) == method_name:
			var args = method.get("args", [])
			return Array(args).size() if args is Array else -1
	return -1


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
