class_name CampaignDirector
extends RefCounted

## Deterministic campaign orchestration for We're Hiring.
##
## HiringModel owns arithmetic. HiringContent owns authored data. This class owns
## chronology: one fixed beat per authored week, queued administrative payoffs,
## night-shift gates, save continuity, and the rule that an ordinary ending may
## only occur on bankruptcy or after Chapter 4 / Week 8.
##
## Public API used by presentation and tests:
##   start_company(name, ng_plus) -> Dictionary
##   resume(save) -> Dictionary
##   perform_action(action_id, use_ai) -> Dictionary
##   current_fixed_event() -> Dictionary
##   next_event() -> Dictionary
##   prepare_event(event) -> Dictionary
##   resolve_event(event_or_id, choice_id) -> Dictionary
##   apply_declarative_after(event, choice_id) -> Dictionary
##   finish_week() -> Dictionary
##   advance() -> Dictionary
##   pending_night_shift() -> Dictionary
##   complete_night_shift(id, inspected_objects, terminal_command) -> Dictionary
##   generic_debt_fulfillment() -> Dictionary
##   resolve_ending(explicit_id) -> Dictionary
##   ending_for_id(id) -> Dictionary
##   save_payload() -> Dictionary

const HiringModelScript = preload("res://src/hiring_model.gd")
const HiringContentScript = preload("res://src/hiring_content.gd")
const HiringExpansionContentScript = preload("res://src/hiring_expansion_content.gd")
const HiringEventSchedulerScript = preload("res://src/hiring_event_scheduler.gd")

const DIRECTOR_SAVE_VERSION := 1

const SILENT_FIXED_IDS := [
	"preseed_free_2", "preseed_free_3", "investor_repost",
	"seed_debt_3", "seed_debt_4", "seed_debt_5", "hiring_page_traffic",
	"office_expansion", "phantom_employee_appears", "the_accent",
	"meeting_room_d_calendar", "version_disappears", "final_silence"
]

# These authored beats belong to the boundary between the action phase and
# settlement. They must not be exposed by next_event() when the week begins.
const END_OF_WEEK_FIXED_IDS := ["model_first_sentence"]

const EXACT_AFTER_DIRECTIVES := [
	"", "tutorial_actions", "advance_chapter", "free_week",
	"resolve_fundraise", "silent", "mark_witnesses:demo_edit",
	"employee_intent_to_leave", "conditional_debt_event",
	"fundraise_by_narrative", "add_elevator_floor", "author_stage:3",
	"debt_scaled_reputation_hit", "remove_laid_off_employees",
	"unlock_room_d", "debt_scaled_event", "author_stage:5",
	"resolve_board", "evaluate_ending", "continue_ng_plus",
	"resolve_by_capability", "queue_cash_actions", "cash_resolution",
	"add_selected_employee", "employee_joined", "record_employee_memory",
	"choose_resignation_text", "remove_employee"
]

const AFTER_PREFIXES := [
	"effects:", "remember:", "set_flag:", "set_office:", "unlock:",
	"queue:", "night_shift:", "add_employee:", "open_intranet:"
]

const FULFILLMENT_COPY := {
	"live_demo": {
		"title": "现场跑一次", "kicker": "兑现 · 客户",
		"body": ["客户带了自己的样本。", "过去演示里被剪掉的等待，现在必须完整地发生。"]
	},
	"investor_eval": {
		"title": "把 eval 打开", "kicker": "兑现 · 投资人",
		"body": ["投资人没有看首页。她直接问评测集是谁做的。", "会议邀请里附着一条旧的对外承诺。"]
	},
	"investigative_report": {
		"title": "逐句核对", "kicker": "兑现 · 媒体",
		"body": ["记者把旧推文、演示字幕和客户邮件排在同一张表里。", "每一行都礼貌地标着：请确认。"]
	},
	"former_employee_post": {
		"title": "一篇帖子", "kicker": "兑现 · 前员工",
		"body": ["帖子没有写公司名。", "第二段的日期和第十一版演示视频让所有人都知道写的是谁。"]
	}
}

var model
var _event_scheduler

var _pending_event: Dictionary = {}
var _queued_events: Array[Dictionary] = []
var _resolved_fixed_keys: Dictionary = {}
var _seen_event_ids: Dictionary = {}
var _seen_generic_bases: Dictionary = {}
var _silent_event_ids: Array[String] = []
var _pending_night_id := ""
var _completed_nights: Dictionary = {}
var _ng_plus_opening_pending := false
var _ending_evaluation_requested := false
var _fulfillment_serial := 0
var _generic_serial := 0
var _generic_emitted_week := -1
var _last_action_id := ""
var _pending_hire_id := ""
var _pending_resignation: Dictionary = {}
var _processed_former_count := 0
var _visited_weeks: Dictionary = {}


func _init() -> void:
	model = HiringModelScript.new()
	_event_scheduler = HiringEventSchedulerScript.new(92317)


func start_company(name: String, ng_plus: bool = false) -> Dictionary:
	_reset_director_state()
	model.reset(name, ng_plus)
	_ng_plus_opening_pending = ng_plus
	var began: Dictionary = model.begin_week()
	if not bool(began.get("ok", false)):
		return began
	_record_visited_week()
	var event := next_event()
	return {
		"ok": true,
		"state": model.public_state(),
		"event": event,
		"ng_plus": ng_plus
	}


func resume(save: Dictionary) -> Dictionary:
	var source: Dictionary = save
	if save.has("model"):
		if int(save.get("director_save_version", -1)) != DIRECTOR_SAVE_VERSION:
			return {"ok": false, "reason": "director_save_version"}
		source = Dictionary(save.get("model", {}))
	if not model.from_save(source):
		return {"ok": false, "reason": "model_save_invalid"}
	if save.has("model"):
		_resolved_fixed_keys = Dictionary(save.get("resolved_fixed_keys", {})).duplicate(true)
		_seen_event_ids = Dictionary(save.get("seen_event_ids", {})).duplicate(true)
		_seen_generic_bases = Dictionary(save.get("seen_generic_bases", {})).duplicate(true)
		_pending_event = Dictionary(save.get("pending_event", {})).duplicate(true)
		_queued_events = _dictionary_array(save.get("queued_events", []))
		_silent_event_ids = _string_array(save.get("silent_event_ids", []))
		_pending_night_id = str(save.get("pending_night_id", ""))
		_completed_nights = Dictionary(save.get("completed_nights", {})).duplicate(true)
		_ng_plus_opening_pending = bool(save.get("ng_plus_opening_pending", false))
		_ending_evaluation_requested = bool(save.get("ending_evaluation_requested", false))
		_fulfillment_serial = maxi(0, int(save.get("fulfillment_serial", 0)))
		_generic_serial = maxi(0, int(save.get("generic_serial", 0)))
		_generic_emitted_week = int(save.get("generic_emitted_week", -1))
		_last_action_id = str(save.get("last_action_id", ""))
		_pending_hire_id = str(save.get("pending_hire_id", ""))
		_pending_resignation = Dictionary(save.get("pending_resignation", {})).duplicate(true)
		_processed_former_count = maxi(0, int(save.get("processed_former_count", model.former_employees.size())))
		_visited_weeks = Dictionary(save.get("visited_weeks", {})).duplicate(true)
		if save.has("event_scheduler"):
			var scheduler_loaded: Dictionary = _event_scheduler.load_save(Dictionary(save.get("event_scheduler", {})))
			if not bool(scheduler_loaded.get("ok", false)):
				return {"ok": false, "reason": "event_scheduler_save_invalid"}
		else:
			_event_scheduler.reset(92317 + (1 if model.second_run else 0), _scheduler_options())
	else:
		_rebuild_director_state_from_model()
	_record_visited_week()
	return {"ok": true, "state": model.public_state(), "event": _pending_event.duplicate(true)}


func perform_action(action_id: String, use_ai: bool = false) -> Dictionary:
	var chen_was_active := _has_employee("chen_xiaoyu")
	var result: Dictionary = model.perform_action(action_id, use_ai)
	if not bool(result.get("ok", false)):
		return result
	_last_action_id = action_id
	model.memory["director_last_action"] = action_id
	if action_id == "layoffs" and chen_was_active and not _has_employee("chen_xiaoyu"):
		_record_chen_xiaoyu_layoff()
	if action_id == "interview":
		model.flags["open_hiring"] = true
	if action_id == "one_on_one":
		_queue_generic_from_content("one_on_one_reveal", true)
	if action_id == "all_hands":
		_queue_all_hands_decision()
	if action_id == "layoffs" and bool(model.flags.get("promised_no_layoffs", false)):
		model.memory["layoff_warning"] = _no_layoff_warning_copy()
	_append_chen_xiaoyu_callback(action_id, result)
	return result


func current_fixed_event() -> Dictionary:
	if _ng_plus_opening_pending:
		return _second_time_opening()
	var key := _week_key()
	if bool(_resolved_fixed_keys.get(key, false)):
		return {}
	var event: Dictionary = HiringContentScript.get_fixed_event(int(model.chapter), int(model.week_in_chapter))
	if event.is_empty():
		return {}
	# Conditional fixed beats are evaluated once for their authored week. A false
	# condition is an intentionally absent beat, not a modal that explains why it
	# did not happen and not something that may appear later after an action.
	var condition := str(event.get("condition", ""))
	if not condition_met(condition):
		var event_id := str(event.get("id", "fixed_event"))
		_resolved_fixed_keys[key] = true
		model.flags["skipped_%s" % event_id] = true
		model.memory["skipped_fixed_%s" % event_id] = int(model.total_week)
		model.memory["skipped_story_beat"] = event_id
		model.history.append({
			"kind": "fixed_event_skipped", "chapter": model.chapter,
			"week_in_chapter": model.week_in_chapter, "total_week": model.total_week,
			"payload": {"event_id": event_id, "condition": condition}
		})
		return {}
	if END_OF_WEEK_FIXED_IDS.has(str(event.get("id", ""))) and not model.week_resolved:
		return {}
	event["_director_source"] = "fixed"
	event["_director_key"] = key
	return prepare_event(event)


func next_event() -> Dictionary:
	if not _pending_event.is_empty():
		return _pending_event.duplicate(true)

	# The authored beat always wins the week. Silent beats execute in place and
	# leave a history record rather than producing a modal.
	var fixed := current_fixed_event()
	if not fixed.is_empty():
		if _event_is_silent(fixed):
			_resolve_event_dict(fixed, "", true)
		else:
			_pending_event = fixed.duplicate(true)
			return _pending_event.duplicate(true)
	if _final_silence_holds_modal_queue():
		return {}

	var scheduled_return := _due_live_demo_return_event()
	if not scheduled_return.is_empty():
		_pending_event = scheduled_return.duplicate(true)
		return _pending_event.duplicate(true)

	if not _queued_events.is_empty():
		var queued: Dictionary = _queued_events.pop_front()
		queued = prepare_event(queued)
		if _event_is_silent(queued):
			_resolve_event_dict(queued, "", true)
			return next_event()
		_pending_event = queued
		return _pending_event.duplicate(true)

	var generic := generic_debt_fulfillment()
	if not generic.is_empty():
		if _event_is_silent(generic):
			_resolve_event_dict(generic, "", true)
			return {}
		_pending_event = generic
		return _pending_event.duplicate(true)

	var systemic := _next_systemic_event()
	if not systemic.is_empty():
		_pending_event = systemic
		return _pending_event.duplicate(true)
	return {}


func prepare_event(event: Dictionary) -> Dictionary:
	var prepared := event.duplicate(true)
	var variants_value = prepared.get("variants", {})
	if variants_value is Dictionary:
		for variant_id_value in Dictionary(variants_value):
			var variant_value = Dictionary(variants_value).get(variant_id_value, {})
			if not variant_value is Dictionary:
				continue
			var variant: Dictionary = variant_value
			if not condition_met(str(variant.get("condition", ""))):
				continue
			for key in variant:
				if str(key) != "condition":
					prepared[key] = variant[key]
			prepared["_director_variant_id"] = str(variant_id_value)
			break

	var prepared_id := str(prepared.get("id", ""))
	if prepared_id in ["one_on_one_reveal", "belief_breaks", "resignation_clean", "resignation_witnessed", "candidate_accepts"]:
		prepared = _prepare_employee_runtime_event(prepared)
	if prepared_id == "hiring_candidates":
		prepared = _prepare_hiring_candidates(prepared)
	if prepared_id == "layoff_execution":
		prepared = _prepare_layoff_execution(prepared)
	if prepared_id == "lin_scene_4":
		prepared = _prepare_lin_values_provenance(prepared)

	if not _demo_video_was_used():
		prepared = _apply_no_demo_video_variant(prepared)

	if str(prepared.get("id", "")) == "lin_last_visit" and not _has_employee("lin_yue"):
		prepared.erase("_director_variant_id")
		prepared["id"] = "lin_absent_echo"
		prepared["title"] = "没有最后一次"
		prepared["kicker"] = "第 4 周"
		prepared["body"] = [
			"日历里原本为林越保留的十五分钟被系统自动取消。",
			"原因：参与者不再属于组织。",
			"内网起源文章还写着“我们说：先这样”。",
			"你点开她已失效的门禁记录。最后一次刷卡停在她离开的那天，凌晨一点。",
			"系统询问是否释放这个门禁卡编号。"
		]
		prepared["choices"] = [
			{
				"id": "retain_until_month_end", "label": "保留到月底", "ai": false,
				"effects": {"coherence": 2, "debt": 1},
				"result": ["你把回收日期改成本月最后一天。", "门禁仍然失效。编号留在待办列表里。"],
				"flags": ["lin_badge_retained"]
			},
			{
				"id": "release_badge", "label": "释放编号", "ai": false,
				"effects": {"coherence": 5, "morale": -2},
				"result": ["编号回到可用池。", "那条凌晨一点的记录变成了只读归档。"],
				"flags": ["lin_badge_released"]
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"coherence": 6, "morale": 3, "author_weight": 6},
				"result": ["回收、归档和权限同步在同一秒完成。", "系统生成了一条措辞妥帖的处理记录。"],
				"flags": ["lin_badge_delegated"]
			}
		]
		prepared["after"] = "remember:lin_absence"

	var filtered: Array[Dictionary] = []
	for choice_value in prepared.get("choices", []):
		if choice_value is Dictionary:
			var choice: Dictionary = choice_value
			if condition_met(str(choice.get("condition", ""))):
				filtered.append(choice.duplicate(true))
	prepared["choices"] = filtered
	return prepared


func _prepare_lin_values_provenance(event: Dictionary) -> Dictionary:
	var prepared := event.duplicate(true)
	var corpus_entry := _ensure_truthful_week_31_values_provenance()
	var corpus_id := str(corpus_entry.get("id", ""))
	var choices: Array[Dictionary] = []
	for choice_value in prepared.get("choices", []):
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = Dictionary(choice_value).duplicate(true)
		if str(choice.get("id", "")) == "delegate":
			var result: Array = Array(choice.get("result", [])).duplicate()
			for index in result.size():
				if str(result[index]).contains("它是从哪儿知道的"):
					result[index] = "那个通宵是真的。它是从哪儿知道的？——第 31 周你写的那版价值观文档里，你写过。"
			choice["result"] = result
			choice["_director_values_corpus_id"] = corpus_id
			choice["_director_values_source"] = "week31_founder_values_document"
		choices.append(choice)
	prepared["choices"] = choices
	prepared["_director_values_corpus_id"] = corpus_id
	return prepared


func _ensure_truthful_week_31_values_provenance() -> Dictionary:
	var ensured: Dictionary = model.ensure_week_31_values_document()
	var corpus_id := str(ensured.get("id", ""))
	var corpus: Array = Array(model.memory.get("values_corpus", [])).duplicate(true)
	for index in corpus.size():
		if not corpus[index] is Dictionary:
			continue
		var entry: Dictionary = Dictionary(corpus[index]).duplicate(true)
		if str(entry.get("id", "")) != corpus_id:
			continue
		# The room-D surface remains silent, but the bible fixes a second ordinary
		# story fact in the same week: the founder wrote this values revision. The
		# administrative system only archives it; it must not steal the byline.
		entry["author"] = "founder"
		entry["approved_by"] = "founder"
		entry["source"] = "week31_founder_values_document"
		entry["provenance_label"] = "创始人 · 第 31 周"
		corpus[index] = entry
		ensured = entry.duplicate(true)
		break
	model.memory["values_corpus"] = corpus
	model.memory["values_week31_approved_by"] = "founder"
	model.memory["values_week31_provenance_label"] = "创始人 · 第 31 周"
	return ensured


func _prepare_employee_runtime_event(event: Dictionary) -> Dictionary:
	var prepared := event.duplicate(true)
	var event_id := str(prepared.get("id", ""))
	match event_id:
		"one_on_one_reveal":
			var employee_id := _one_on_one_employee_id(prepared)
			if employee_id.is_empty():
				prepared["body"] = ["日历保留了十五分钟，但没有可用的具名记录。", "会议没有自动生成摘要。"]
				return prepared
			var profile: Dictionary = Dictionary(HiringContentScript.EMPLOYEE_TEMPLATES[employee_id])
			var name := str(profile.get("name", employee_id))
			var role := str(profile.get("role", "员工"))
			prepared["title"] = "十五分钟 · %s" % name
			prepared["kicker"] = "一对一 · %s" % role
			prepared["body"] = [
				"%s（%s）先说没有什么特别的。会议到第十二分钟，你没有打断。" % [name, role],
				str(profile.get("one_on_one", ""))
			]
			prepared["_director_employee_id"] = employee_id
		"belief_breaks":
			var departure := _departure_snapshot(prepared)
			if departure.is_empty():
				prepared["body"] = ["一个人的信念降到了零。", "日历保留了十五分钟，地点没有填。"]
				return prepared
			var employee_id := str(departure.get("id", ""))
			var name := _resigning_employee_name(employee_id, departure)
			prepared["title"] = "%s想聊一下" % name
			prepared["body"] = ["%s 的信念降到了零。" % name, "%s 在日历上放了十五分钟，地点没有填。" % name]
			prepared["_director_employee_id"] = employee_id
			prepared["_director_resignation_route"] = "witnessed" if bool(departure.get("witnessed_demo", false)) else "clean"
		"resignation_clean", "resignation_witnessed":
			var departure := _departure_snapshot(prepared)
			if departure.is_empty():
				prepared["body"] = ["最后一天的交接已经完成。"]
				return prepared
			var employee_id := str(departure.get("id", ""))
			var profile: Dictionary = Dictionary(HiringContentScript.EMPLOYEE_TEMPLATES.get(employee_id, {}))
			var name := _resigning_employee_name(employee_id, departure)
			var witnessed := bool(departure.get("witnessed_demo", false))
			var quote_key := "quit_witnessed" if event_id == "resignation_witnessed" else "quit_clean"
			var quote := str(profile.get(quote_key, ""))
			prepared["title"] = "%s的最后一天" % name
			prepared["kicker"] = "离职 · %s" % ("见证过" if witnessed else "干净")
			prepared["body"] = ["%s 完成了最后一次交接。" % name, quote] if not quote.is_empty() else ["%s 完成了最后一次交接。" % name]
			prepared["_director_employee_id"] = employee_id
			prepared["_director_resignation_route"] = "witnessed" if witnessed else "clean"
		"candidate_accepts":
			var employee_id := str(prepared.get("_director_employee_id", _pending_hire_id))
			if employee_id.is_empty() or not HiringContentScript.EMPLOYEE_TEMPLATES.has(employee_id):
				prepared["body"] = ["候选人接受了。工位、门禁和周报权限已经创建。"]
				return prepared
			var profile: Dictionary = Dictionary(HiringContentScript.EMPLOYEE_TEMPLATES[employee_id])
			var name := str(profile.get("name", employee_id))
			var role := str(profile.get("role", "员工"))
			prepared["title"] = "欢迎，%s" % name
			prepared["kicker"] = "入职 · %s" % role
			prepared["body"] = [
				"%s 接受了 %s 的邀请。工位、门禁和周报权限在同一分钟创建。" % [name, role],
				str(profile.get("desk", "")),
				str(profile.get("hire_quote", ""))
			]
			prepared["_director_employee_id"] = employee_id
	return prepared


func _one_on_one_employee_id(event: Dictionary) -> String:
	var saved_id := str(event.get("_director_employee_id", ""))
	if not saved_id.is_empty() and HiringContentScript.EMPLOYEE_TEMPLATES.has(saved_id):
		for employee in model.employees:
			if str(employee.get("id", "")) == saved_id and bool(employee.get("active", true)):
				return saved_id
	var active_candidates: Array[Dictionary] = []
	for employee in model.employees:
		var employee_id := str(employee.get("id", ""))
		if employee_id.is_empty() or not bool(employee.get("active", true)) or not HiringContentScript.EMPLOYEE_TEMPLATES.has(employee_id):
			continue
		active_candidates.append(Dictionary(employee))
	var revealed_facts: Array = Array(model.memory.get("one_on_one_revealed_fact_ids", []))
	var unseen_candidates: Array[Dictionary] = []
	for employee in active_candidates:
		if not revealed_facts.has(_one_on_one_fact_id(str(employee.get("id", "")))):
			unseen_candidates.append(employee)
	var selection_pool := unseen_candidates if not unseen_candidates.is_empty() else active_candidates
	var selected_id := ""
	var selected_belief := INF
	for employee in selection_pool:
		var employee_id := str(employee.get("id", ""))
		var belief := float(employee.get("belief", 50.0))
		if belief < selected_belief or (is_equal_approx(belief, selected_belief) and (selected_id.is_empty() or employee_id.naturalnocasecmp_to(selected_id) < 0)):
			selected_belief = belief
			selected_id = employee_id
	return selected_id


func _one_on_one_fact_id(employee_id: String) -> String:
	return "%s:one_on_one" % employee_id


func _departure_snapshot(event: Dictionary) -> Dictionary:
	var snapshot_value = event.get("_director_departure_snapshot", {})
	if snapshot_value is Dictionary and not Dictionary(snapshot_value).is_empty():
		return Dictionary(snapshot_value).duplicate(true)
	# Compatibility for version-one director saves that predate immutable queued
	# snapshots. New events never write this shared slot.
	return _pending_resignation.duplicate(true)


func _resigning_employee_name(employee_id: String, departure: Dictionary = {}) -> String:
	var saved_name := str(departure.get("name", ""))
	if saved_name.is_empty():
		saved_name = str(_pending_resignation.get("name", ""))
	if not saved_name.is_empty():
		return saved_name
	if HiringContentScript.EMPLOYEE_TEMPLATES.has(employee_id):
		return str(Dictionary(HiringContentScript.EMPLOYEE_TEMPLATES[employee_id]).get("name", employee_id))
	return employee_id if not employee_id.is_empty() else "这名员工"


func _prepare_layoff_execution(event: Dictionary) -> Dictionary:
	var prepared := event.duplicate(true)
	if bool(model.flags.get("promised_no_layoffs", false)):
		var promise_week := int(model.memory.get("no_layoff_promise_total_week", -1))
		var reaction_count := int(model.memory.get("no_layoff_promise_reaction_count", -1))
		var week_label := "第 %d 周" % promise_week if promise_week >= 1 else "先前那次"
		var reaction_label := "%d 个赞" % maxi(0, reaction_count) if reaction_count >= 0 else "当时收到的那些赞"
		prepared["body"] = _replace_copy_tokens(Array(prepared.get("body", [])), {
			"{{promise_week_label}}": week_label,
			"{{promise_reaction_label}}": reaction_label,
		})
		var promised_choices: Array[Dictionary] = []
		for choice_value in prepared.get("choices", []):
			if not choice_value is Dictionary:
				continue
			var choice: Dictionary = Dictionary(choice_value).duplicate(true)
			choice["result"] = _replace_copy_tokens(Array(choice.get("result", [])), {
				"{{promise_week_label}}": week_label,
				"{{promise_reaction_label}}": reaction_label,
			})
			promised_choices.append(choice)
		prepared["choices"] = promised_choices
		prepared["_director_promise_week"] = promise_week
		prepared["_director_promise_reaction_count"] = reaction_count
		prepared["_director_layoff_promise_route"] = "promised"
		return prepared
	prepared["body"] = [
		"名单在你手里。六个人。",
		"表格最后一列叫『说明』，现在还是空的。",
		"没有旧公告能替你解释这张名单。决定发生在今天。"
	]
	var choices: Array[Dictionary] = []
	for choice_value in prepared.get("choices", []):
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = Dictionary(choice_value).duplicate(true)
		if str(choice.get("id", "")) == "delegate":
			choice["result"] = [
				"> 通知流程已完成。",
				"> 我安排了当面。六场，都在会议室 C，间隔二十分钟。",
				"> 我用了你的语气。",
				"> 他们都以为是你写的。",
				"> 这对他们来说更好。",
				"你没有去公司。",
				"下午三点你在家里刷手机，看到有人发了一条动态，没有配图，只有一句：",
				"『谢谢老板亲自跟我说。挺好的，真的。』",
				"你点了个赞。然后你把赞取消了。然后你又点了一次。"
			]
		choices.append(choice)
	prepared["choices"] = choices
	prepared["_director_layoff_promise_route"] = "unpromised"
	return prepared


func _replace_copy_tokens(lines: Array, replacements: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for line_value in lines:
		var line := str(line_value)
		for token_value in replacements:
			line = line.replace(str(token_value), str(replacements[token_value]))
		result.append(line)
	return result


func _prepare_hiring_candidates(event: Dictionary) -> Dictionary:
	var prepared := event.duplicate(true)
	var candidates := _hiring_candidates_for_event(prepared)
	var candidate_ids: Array[String] = []
	var body: Array[String] = ["三名候选人进入最后一轮。录用决定仍由你提交。"]
	var choices: Array[Dictionary] = []
	var authored_choices: Dictionary = {}
	for choice_value in prepared.get("choices", []):
		if choice_value is Dictionary:
			authored_choices[str(Dictionary(choice_value).get("id", ""))] = Dictionary(choice_value).duplicate(true)
	for index in candidates.size():
		var candidate: Dictionary = candidates[index]
		var candidate_id := str(candidate.get("id", ""))
		var name := str(candidate.get("name", candidate_id))
		var role := str(candidate.get("role", "员工"))
		var capability := int(round(_content_employee_skill(candidate)))
		var choice_id := "candidate_%d" % index
		var choice: Dictionary = Dictionary(authored_choices.get(choice_id, {
			"id": choice_id, "ai": false,
			"effects": {"morale": 2},
			"flags": ["hired_%s" % choice_id]
		})).duplicate(true)
		var skill_parts: Array[String] = []
		var skills: Dictionary = Dictionary(candidate.get("skills", {}))
		var skill_names: Array = skills.keys()
		skill_names.sort()
		for skill_name_value in skill_names:
			var skill_name := str(skill_name_value)
			skill_parts.append("%s %d" % [skill_name, int(skills[skill_name])])
		choice["label"] = "%s · %s · 能力 %d" % [name, role, capability]
		choice["body"] = [
			"能力结构：%s" % " / ".join(skill_parts),
			"面试原话：%s" % str(candidate.get("hire_quote", ""))
		]
		choice["result"] = ["已向 %s（%s）发出邀请。" % [name, role], "入职日期仍在等待确认。"]
		choices.append(choice)
		candidate_ids.append(candidate_id)
		body.append("候选人 %d · %s · %s · 能力 %d" % [index + 1, name, role, capability])
		body.append("面试原话：%s" % str(candidate.get("hire_quote", "")))
	var delegate: Dictionary = Dictionary(authored_choices.get("delegate", {})).duplicate(true)
	if not delegate.is_empty() and not candidates.is_empty():
		delegate["body"] = ["它会只在以上三人中比较能力，并完成薪资与入职日期协商。"]
		choices.append(delegate)
	prepared["body"] = body
	prepared["choices"] = choices
	prepared["_director_candidate_ids"] = candidate_ids
	return prepared


func _hiring_candidates_for_event(event: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var saved_ids: Array = Array(event.get("_director_candidate_ids", []))
	if not saved_ids.is_empty():
		for candidate_id_value in saved_ids:
			var candidate_id := str(candidate_id_value)
			if HiringContentScript.EMPLOYEE_TEMPLATES.has(candidate_id):
				result.append(Dictionary(HiringContentScript.EMPLOYEE_TEMPLATES[candidate_id]).duplicate(true))
		return result
	var existing: Array = []
	for employee in model.employees:
		existing.append(str(employee.get("id", "")))
	var available: Array[Dictionary] = HiringContentScript.hireable_employees(model.chapter, existing)
	for index in mini(3, available.size()):
		result.append(available[index].duplicate(true))
	return result


func _apply_no_demo_video_variant(event: Dictionary) -> Dictionary:
	var prepared := event.duplicate(true)
	var event_id := str(prepared.get("id", ""))
	var base_id := str(prepared.get("_director_base_id", ""))
	match event_id:
		"live_demo":
			prepared["body"] = [
				"客户带了自己的笔记本来。他很客气，客气到你意识到他做过功课。",
				"『我们看了你们的融资材料。今天想看看现场。』",
				"融资材料里有一张响应时间图：不到一秒。那是筛选过的样本，没有写等待、重试和人工润色。",
				"图是周五凌晨定稿的。发出去以后，团队还去吃了小龙虾，很开心。"
			]
			var choices: Array[Dictionary] = []
			for choice_value in prepared.get("choices", []):
				if not choice_value is Dictionary:
					continue
				var choice: Dictionary = Dictionary(choice_value).duplicate(true)
				if str(choice.get("id", "")) == "delegate":
					choice["result"] = [
						"客户签了。走的时候和你握手，说：『你现场讲得比材料里还清楚。』",
						"回办公室的路上你一直在想他这句话。晚上你调了会议录像，从头看。",
						"你确实讲了那些话。口型对得上，是你的手在比划。",
						"只是那个逻辑不是你想出来的，那个停顿也不是你的停顿——",
						"你从来不在『我们』后面停顿。",
						"你把进度条拖回去又看了一遍。",
						"讲得真的很好。"
					]
				choices.append(choice)
			prepared["choices"] = choices
		"hiring_page_traffic":
			prepared["body"] = [
				"招聘页面浏览量：4,200。",
				"收到简历：3。",
				"页面上最醒目的是融资材料里那张『不到一秒』的响应时间图。"
			]
		"lin_scene_3":
			prepared["title"] = "那一页"
			prepared["body"] = [
				"她在会议室等你，门关着。这是她第一次关门。",
				"『融资材料里那一页，我说过一次。』",
				"『我记得。』",
				"『我说，别把筛选过的响应时间写得像现场都会发生。』",
				"『嗯。』",
				"『后来还是发出去了。』",
				"你没有说话。",
				"『我不是要吵架。』她说，『我是想确认一件事：你知道客户看到的不是模型平时的速度，对吗？』"
			]
		"former_employee_post":
			prepared["body"] = [
				"前员工在论坛发了一篇很长的帖子。",
				"标题没有公司名。第二段的时间线让所有人都知道写的是谁。",
				"评论里有人贴了你们融资材料里那张响应时间图。"
			]
		_:
			if base_id == "live_demo":
				prepared["body"] = ["客户带了自己的样本。", "融资材料里被省略的等待，现在必须完整地发生。"]
			elif base_id == "former_employee_post":
				prepared["body"] = ["帖子没有写公司名。", "第二段的日期和融资材料里的响应时间图让所有人都知道写的是谁。"]
	if event_id in ["live_demo", "hiring_page_traffic", "lin_scene_3", "former_employee_post"] or base_id in ["live_demo", "former_employee_post"]:
		prepared["_director_demo_route"] = "never_used"
	return prepared


func _demo_video_was_used() -> bool:
	var action_counts: Dictionary = Dictionary(model.memory.get("action_counts", {}))
	return int(action_counts.get("demo_video", 0)) > 0


func _apply_runtime_event_mechanics(event_id: String, choice_id: String, event: Dictionary = {}) -> Dictionary:
	var system_result: Dictionary = {}
	if bool(event.get("_company_system_event", false)) and model.has_method("resolve_systemic_event"):
		var resolved_value = model.resolve_systemic_event(event, choice_id)
		if resolved_value is Dictionary:
			system_result = Dictionary(resolved_value).duplicate(true)
	if model.has_method("observe_story_event"):
		model.observe_story_event(event_id, choice_id, event)
	if event_id.begins_with("all_hands_decision_") and choice_id == "promise_no_layoffs":
		_record_no_layoff_promise(event)
	match event_id:
		"preseed_close":
			if bool(model.flags.get("preseed_fundraise_applied", false)):
				return system_result
			var gain := _apply_fundraise_by_narrative()
			model.flags["preseed_fundraise_applied"] = true
			model.memory["preseed_fundraise_gain"] = gain
			model.memory["preseed_fundraise_narrative"] = model.narrative
			model.memory["preseed_fundraise_total_week"] = model.total_week
			model.history.append({
				"kind": "preseed_fundraise", "chapter": model.chapter,
				"week_in_chapter": model.week_in_chapter, "total_week": model.total_week,
				"payload": {"gain": gain, "narrative": model.narrative}
			})
		"live_demo":
			if choice_id == "postpone":
				_schedule_live_demo_return()
		"live_demo_return":
			model.flags["live_demo_return_scheduled"] = false
			model.flags["live_demo_return_resolved"] = true
			model.flags["live_demo_return_success"] = choice_id in ["run_live", "delegate"]
			model.memory["live_demo_return_choice"] = choice_id
			model.memory["live_demo_return_resolved_total_week"] = model.total_week
		"meeting_room_d_calendar":
			_ensure_truthful_week_31_values_provenance()
		"unsolicited_line":
			model.flags["missed_meal_friday_callback"] = true
			model.memory["missed_meal_callback_fired_on_day"] = "Friday"
			model.memory["missed_meal_callback_fired_total_week"] = model.total_week
			model.memory["missed_meal_callback_pending"] = false
		"never_delegated":
			model.flags.erase("never_delegated_question")
			model.memory["never_delegated_question_resolved"] = true
			model.memory["never_delegated_answer"] = choice_id
	return system_result


func _record_no_layoff_promise(event: Dictionary) -> void:
	var reaction_count := int(event.get("_director_no_layoff_reaction_count", _deterministic_promise_reaction_count()))
	model.memory["no_layoff_promise_total_week"] = int(model.total_week)
	model.memory["no_layoff_promise_chapter"] = int(model.chapter)
	model.memory["no_layoff_promise_week_in_chapter"] = int(model.week_in_chapter)
	model.memory["no_layoff_promise_reaction_count"] = reaction_count
	model.memory["no_layoff_promise_event_id"] = str(event.get("id", ""))
	model.history.append({
		"kind": "memory_created", "chapter": model.chapter,
		"week_in_chapter": model.week_in_chapter, "total_week": model.total_week,
		"payload": {
			"memory": "promised_no_layoffs", "promise_week": model.total_week,
			"reaction_count": reaction_count,
		}
	})


func _deterministic_promise_reaction_count() -> int:
	var reactions := 0
	for employee in model.employees:
		if not bool(employee.get("active", true)):
			continue
		if float(employee.get("morale", 50.0)) >= 50.0 and float(employee.get("belief", 50.0)) > 0.0:
			reactions += 1
	return reactions


func _no_layoff_warning_copy() -> String:
	var promise_week := int(model.memory.get("no_layoff_promise_total_week", -1))
	var reactions := int(model.memory.get("no_layoff_promise_reaction_count", -1))
	if promise_week >= 1 and reactions >= 0:
		return "你在第 %d 周说过不会裁员；那条公告收到 %d 个赞。" % [promise_week, reactions]
	return "你先前说过不会裁员。"


func _schedule_live_demo_return() -> void:
	if bool(model.flags.get("live_demo_return_resolved", false)) or int(model.memory.get("live_demo_return_due_total_week", -1)) >= 0:
		return
	var due_total_week: int = int(model.total_week) + 3
	model.flags["live_demo_return_scheduled"] = true
	model.memory["live_demo_return_due_total_week"] = due_total_week
	model.memory["live_demo_return_scheduled_total_week"] = model.total_week
	model.history.append({
		"kind": "event_scheduled", "chapter": model.chapter,
		"week_in_chapter": model.week_in_chapter, "total_week": model.total_week,
		"payload": {"event_id": "live_demo_return", "due_total_week": due_total_week}
	})


func _due_live_demo_return_event() -> Dictionary:
	if not bool(model.flags.get("live_demo_return_scheduled", false)) or bool(model.flags.get("live_demo_return_resolved", false)) or _seen_event_ids.has("live_demo_return"):
		return {}
	var due_total_week := int(model.memory.get("live_demo_return_due_total_week", -1))
	if due_total_week < 0 or model.total_week < due_total_week or model.chapter < 2:
		return {}
	return prepare_event({
		"id": "live_demo_return",
		"title": "三周后，现场跑一次",
		"kicker": "改期回访 · 最后一次",
		"body": [
			"客户按日历上的改期时间回来了，还是带着自己的笔记本。",
			"三周没有让问题消失，只让这一次的通过门槛更高。今天不能再次改期。"
		],
		"choices": [
			{
				"id": "run_live", "label": "现场跑。", "ai": false, "condition": "capability >= 75",
				"effects": {"narrative": 20, "debt": -999, "morale": 30},
				"result": ["它完整跑完了两个问题。客户把原本合着的笔记本重新打开。", "更高的门槛，这次过了。"],
				"flags": ["live_demo_return_honest_success"]
			},
			{
				"id": "run_live_fail", "label": "现场跑。", "ai": false, "condition": "capability < 75",
				"effects": {"narrative_set_to_capability": 1, "cash_percent": -15, "team_size": -2, "morale": -30},
				"result": ["更高门槛下，第一个问题没有在会议允许的时间里完成。", "客户合上电脑。这次日历里没有下一次改期。"],
				"flags": ["live_demo_return_failed", "two_resignations"]
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"narrative": 22, "debt": -5, "cash_weeks": 8, "author_weight": 6},
				"result": ["它接管了现场说明、等待时的停顿和客户的追问。", "客户签了。这条路线不再检查能力门槛。"],
				"flags": ["live_demo_return_delegated", "live_demo_return_ai_success", "model_used_protagonist_voice"]
			}
		],
		"after": "mark_witnesses:demo_edit",
		"_director_source": "scheduled",
		"_director_base_id": "live_demo_return",
		"_director_due_total_week": due_total_week
	})


func resolve_event(event_or_id: Variant = "", choice_id: String = "") -> Dictionary:
	var event: Dictionary = {}
	if event_or_id is Dictionary:
		event = Dictionary(event_or_id).duplicate(true)
	elif not _pending_event.is_empty():
		var requested := str(event_or_id)
		if not requested.is_empty() and requested != str(_pending_event.get("id", "")):
			return {"ok": false, "reason": "different_event_pending", "pending": str(_pending_event.get("id", ""))}
		event = _pending_event.duplicate(true)
	else:
		event = next_event()
		if not str(event_or_id).is_empty() and str(event.get("id", "")) != str(event_or_id):
			return {"ok": false, "reason": "event_not_current"}
	if event.is_empty():
		return {"ok": false, "reason": "no_event"}
	return _resolve_event_dict(event, choice_id, false)


func apply_declarative_after(event: Dictionary, choice_id: String = "") -> Dictionary:
	var directive := str(event.get("after", ""))
	if not supports_after_directive(directive):
		return {"ok": false, "reason": "unsupported_after", "directive": directive}
	model.flags["after_%s" % _safe_flag_fragment(directive)] = true
	if directive.is_empty():
		return {"ok": true, "directive": directive}
	if directive.begins_with("effects:"):
		var parsed_effects: Dictionary = {}
		for assignment in directive.trim_prefix("effects:").split(",", false):
			var parts := assignment.split("=", false, 1)
			if parts.size() == 2:
				parsed_effects[str(parts[0]).strip_edges()] = float(parts[1])
		apply_event_effects(str(event.get("id", "")), parsed_effects)
		return {"ok": true, "directive": directive}
	if directive.begins_with("remember:"):
		model.memory[directive.trim_prefix("remember:")] = true
		return {"ok": true, "directive": directive}
	if directive.begins_with("set_flag:"):
		model.flags[directive.trim_prefix("set_flag:")] = true
		return {"ok": true, "directive": directive}
	if directive.begins_with("set_office:"):
		model.flags["office_%s" % directive.trim_prefix("set_office:")] = true
		return {"ok": true, "directive": directive}
	if directive.begins_with("unlock:"):
		for action_id in directive.trim_prefix("unlock:").split(",", false):
			model.flags["unlocked_%s" % action_id] = true
		return {"ok": true, "directive": directive}
	if directive.begins_with("queue:"):
		var queued_id := directive.trim_prefix("queue:")
		if queued_id == "layoff_execution" and not bool(model.flags.get("layoffs_required", false)):
			model.flags["layoff_execution_skipped"] = true
			model.flags.erase("queued_layoff_execution")
			model.memory["cash_crisis_resolution"] = "contract"
			if str(model.memory.get("queued_story_beat", "")) == queued_id:
				model.memory.erase("queued_story_beat")
			return {"ok": true, "directive": directive, "queued": false}
		# The two authored queues deliberately point to next week's fixed beat.
		# Recording the queue is sufficient and avoids showing the beat twice.
		model.flags["queued_%s" % queued_id] = true
		model.memory["queued_story_beat"] = queued_id
		if queued_id == "layoff_execution":
			model.memory["cash_crisis_resolution"] = "layoffs"
		return {"ok": true, "directive": directive}
	if directive.begins_with("night_shift:"):
		_pending_night_id = directive.trim_prefix("night_shift:")
		model.flags["night_shift_%s_pending" % _pending_night_id] = true
		if _pending_night_id == "2" and bool(model.flags.get("lin_will_leave", false)):
			model.flags["lin_deferred_departure_released"] = true
			model.flags.erase("lin_departure_deferred")
			_remove_employee_by_id("lin_yue", "lin_scene_4")
			model.flags["lin_yue_departed_at_night_2"] = true
			model.flags.erase("lin_yue_waiting_for_night_2")
			model.memory["lin_yue_departure_week"] = int(model.total_week)
		return {"ok": true, "directive": directive, "night_shift": _pending_night_id}
	if directive.begins_with("add_employee:"):
		_add_content_employee(directive.trim_prefix("add_employee:"))
		return {"ok": true, "directive": directive}
	if directive.begins_with("open_intranet:"):
		var document_id := directive.trim_prefix("open_intranet:")
		model.flags["intranet_%s_available" % document_id] = true
		model.memory["last_opened_intranet"] = document_id
		return {"ok": true, "directive": directive}

	match directive:
		"tutorial_actions":
			model.flags["tutorial_actions_seen"] = true
		"advance_chapter":
			# Chapter movement remains model-owned and happens after week settlement.
			model.flags["chapter_transition_authored"] = true
		"free_week":
			model.memory["last_free_week"] = model.total_week
		"resolve_fundraise":
			model.flags["first_investor_meeting_resolved"] = true
			model.memory["last_financing_narrative"] = model.narrative
		"silent":
			pass
		"mark_witnesses:demo_edit":
			if not _demo_video_was_used():
				model.flags["live_demo_no_demo_video"] = true
				model.flags["demo_edit_witnesses_skipped"] = true
				model.memory["demo_video_route"] = "never_used_before_live_demo"
				model.memory["no_demo_live_demo_week"] = model.total_week
			else:
				model.flags["live_demo_used_demo_video"] = true
				model.memory["demo_video_route"] = "used_before_live_demo"
				model.call("_add_witness_to_all", "demo_fake")
		"employee_intent_to_leave":
			model.flags["employee_intent_to_leave"] = true
		"conditional_debt_event":
			if model.debt >= 30.0:
				model.apply_effects({"narrative": -4.0, "coherence": -2.0})
				model.flags["second_collection_triggered"] = true
		"fundraise_by_narrative":
			_apply_fundraise_by_narrative()
		"add_elevator_floor":
			model.flags["extra_elevator_floor"] = true
		"author_stage:3":
			model.force_writer_stage(3)
		"debt_scaled_reputation_hit", "debt_scaled_event":
			var severity := clampf(floorf(float(model.debt) / 15.0), 0.0, 8.0)
			if severity > 0.0:
				model.apply_effects({"narrative": -severity, "coherence": -severity * 0.5})
		"remove_laid_off_employees":
			model.flags["layoff_execution_complete"] = true
		"unlock_room_d":
			model.flags["meeting_room_d_available"] = true
		"author_stage:5":
			model.force_writer_stage(5)
			# Chapter 4's stage is authored by its week-one beat, after begin_week.
			# Run that week's autonomous operation immediately and idempotently so
			# the first finale week is not an accidental dead zone.
			model.ensure_stage_five_autonomy_for_current_week()
		"resolve_board":
			model.flags["board_resolved"] = true
		"evaluate_ending":
			_ending_evaluation_requested = true
			model.flags["ending_gate_seen"] = true
		"continue_ng_plus":
			model.flags["second_time_opening_seen"] = true
		"resolve_by_capability":
			if model.capability >= model.narrative:
				model.apply_effects({"debt": -12.0, "morale": 4.0})
			else:
				var shortfall := minf(12.0, maxf(2.0, (model.narrative - model.capability) * 0.15))
				model.apply_effects({"narrative": -shortfall, "coherence": -2.0})
		"queue_cash_actions":
			model.flags["cash_actions_highlighted"] = true
		"cash_resolution":
			if choice_id == "fundraise":
				_apply_fundraise_by_narrative()
			model.flags["cash_emergency_resolved"] = true
		"add_selected_employee":
			_select_pending_hire(choice_id, event)
		"employee_joined":
			if not _pending_hire_id.is_empty():
				_add_content_employee(_pending_hire_id)
				model.flags["employee_joined_%s" % _pending_hire_id] = true
				_pending_hire_id = ""
				model.flags.erase("pending_hire")
		"record_employee_memory":
			model.memory["employee_conversation_week"] = model.total_week
		"choose_resignation_text":
			_queue_resignation_text(event)
		"remove_employee":
			_pending_resignation.clear()
	return {"ok": true, "directive": directive}


func supports_after_directive(directive: String) -> bool:
	if EXACT_AFTER_DIRECTIVES.has(directive):
		return true
	for prefix in AFTER_PREFIXES:
		if directive.begins_with(prefix):
			return true
	return false


func apply_event_effects(event_id: String, effects: Dictionary) -> Dictionary:
	var additive := effects.duplicate(true)
	if bool(additive.get("narrative_set_to_capability", false)):
		model.narrative = float(model.capability)
	additive.erase("narrative_set_to_capability")
	# HiringModel translates cash_percent into an idempotent USD-ledger movement
	# whenever the detailed operating layer is active; legacy campaigns receive
	# the same percentage semantics inside that single method.
	if additive.has("team_size"):
		var team_delta := int(additive["team_size"])
		if team_delta < 0:
			_remove_employee_count(abs(team_delta), event_id)
		elif team_delta > 0:
			_add_employee_count(team_delta)
	additive.erase("team_size")
	if bool(additive.get("fundraise_by_narrative", false)):
		_apply_fundraise_by_narrative()
	additive.erase("fundraise_by_narrative")
	if bool(additive.get("open_hiring", false)):
		model.flags["open_hiring"] = true
	additive.erase("open_hiring")
	if bool(additive.get("block_training", false)):
		model.flags["training_blocked_this_week"] = true
	additive.erase("block_training")
	if bool(additive.get("reveal_capability", false)):
		model.flags["capability_revealed"] = true
	additive.erase("reveal_capability")
	if bool(additive.get("open_intranet", false)):
		model.flags["intranet_opened_by_effect"] = true
	additive.erase("open_intranet")
	if additive.has("values_version"):
		model.memory["values_version"] = int(model.memory.get("values_version", 0)) + int(additive["values_version"])
	additive.erase("values_version")
	if additive.has("debt_if_capability_below_40"):
		if model.capability < 40.0:
			additive["debt"] = float(additive.get("debt", 0.0)) + float(additive["debt_if_capability_below_40"])
	additive.erase("debt_if_capability_below_40")
	if additive.has("negative_if_debt_above_55"):
		if model.debt > 55.0:
			additive["narrative"] = float(additive.get("narrative", 0.0)) - absf(float(additive["negative_if_debt_above_55"]))
	additive.erase("negative_if_debt_above_55")
	if additive.has("coherence_if_contradiction"):
		if bool(model.flags.get("recent_layoffs", false)):
			additive["coherence"] = float(additive.get("coherence", 0.0)) + float(additive["coherence_if_contradiction"])
	additive.erase("coherence_if_contradiction")
	if additive.has("flags"):
		var effect_flags = additive["flags"]
		if effect_flags is Array:
			for flag_value in effect_flags:
				model.flags[str(flag_value)] = true
		elif effect_flags is Dictionary:
			for flag_key in effect_flags:
				model.flags[str(flag_key)] = effect_flags[flag_key]
	additive.erase("flags")

	var belief_delta = additive.get("belief", null)
	var belief_set = additive.get("belief_set", null)
	if event_id.begins_with("lin_scene") or event_id == "lin_last_visit":
		additive.erase("belief")
		additive.erase("belief_set")
		_update_lin_belief(belief_delta, belief_set)
	else:
		additive.erase("belief_set")
	var result: Dictionary = model.apply_effects(additive)
	_enforce_locked_lin_belief()
	return result


func finish_week() -> Dictionary:
	if not _pending_event.is_empty():
		return {"ok": false, "reason": "event_pending", "event": _pending_event.duplicate(true)}
	var closing_event := _end_of_week_fixed_event()
	if not closing_event.is_empty():
		_pending_event = closing_event.duplicate(true)
		return {"ok": false, "reason": "event_pending", "event": _pending_event.duplicate(true)}
	var scheduled_return := _due_live_demo_return_event()
	if not scheduled_return.is_empty():
		var authored_fixed := current_fixed_event()
		if not authored_fixed.is_empty():
			if _event_is_silent(authored_fixed):
				_resolve_event_dict(authored_fixed, "", true)
			else:
				_pending_event = authored_fixed.duplicate(true)
				return {"ok": false, "reason": "event_pending", "event": _pending_event.duplicate(true)}
		_pending_event = scheduled_return.duplicate(true)
		return {"ok": false, "reason": "event_pending", "event": _pending_event.duplicate(true)}
	# An operating decision selected during the action phase must be resolved before
	# settlement. Canonical campaigns that never enter the strategy layer retain
	# their exact legacy flow and test trace.
	var systemic := _next_systemic_event()
	if not systemic.is_empty():
		_pending_event = systemic.duplicate(true)
		return {"ok": false, "reason": "event_pending", "event": _pending_event.duplicate(true)}
	var result: Dictionary = model.end_week()
	if not bool(result.get("ok", false)):
		return result
	_drain_model_fulfillment_queue()
	_capture_departures()
	var ending := resolve_ending()
	result["ending"] = ending
	var night := pending_night_shift()
	if not night.is_empty():
		result["night_shift"] = night
	return result


func _end_of_week_fixed_event() -> Dictionary:
	if not model.week_active or model.week_resolved:
		return {}
	var key := _week_key()
	if bool(_resolved_fixed_keys.get(key, false)):
		return {}
	var event: Dictionary = HiringContentScript.get_fixed_event(int(model.chapter), int(model.week_in_chapter))
	if event.is_empty() or not END_OF_WEEK_FIXED_IDS.has(str(event.get("id", ""))):
		return {}
	event["_director_source"] = "fixed"
	event["_director_key"] = key
	return prepare_event(event)


func advance() -> Dictionary:
	if not model.week_resolved:
		return {"ok": false, "reason": "week_not_resolved"}
	var ending := resolve_ending()
	if not ending.is_empty():
		model.campaign_complete = true
		return {"ok": true, "campaign_complete": true, "ending": ending}
	var night := pending_night_shift()
	if not night.is_empty():
		return {"ok": false, "reason": "night_shift_pending", "night_shift": night}
	var advanced: Dictionary = model.advance_week()
	if not bool(advanced.get("ok", false)):
		return advanced
	if bool(advanced.get("campaign_complete", false)):
		var model_ending_value = advanced.get("ending", {})
		var model_ending: Dictionary = model_ending_value if model_ending_value is Dictionary else {}
		var ending_id := str(model_ending.get("id", "acquihire"))
		return {"ok": true, "campaign_complete": true, "ending": ending_for_id(ending_id)}
	var began: Dictionary = model.begin_week()
	if not bool(began.get("ok", false)):
		return began
	_generic_emitted_week = -1
	_last_action_id = ""
	_record_visited_week()
	advanced["event"] = next_event()
	advanced["state"] = model.public_state()
	return advanced


func pending_night_shift() -> Dictionary:
	if _pending_night_id.is_empty() or bool(_completed_nights.get(_pending_night_id, false)):
		return {}
	# Night is an end-of-week interruption, never a modal over the action phase.
	if not model.week_resolved:
		return {}
	var night: Dictionary = HiringContentScript.get_night_shift(_pending_night_id)
	if night.is_empty():
		return {}
	night["_director_night_id"] = _pending_night_id
	return night


func complete_night_shift(id: String, inspected_objects: Array = [], terminal_command: String = "") -> Dictionary:
	if id != _pending_night_id or bool(_completed_nights.get(id, false)):
		return {"ok": false, "reason": "night_not_pending"}
	if not model.week_resolved:
		return {"ok": false, "reason": "night_not_open_yet"}
	var night: Dictionary = HiringContentScript.get_night_shift(id)
	var objects: Dictionary = Dictionary(night.get("objects", {}))
	var inspected: Array[String] = []
	for object_value in inspected_objects:
		var object_id := str(object_value)
		if not objects.has(object_id):
			continue
		inspected.append(object_id)
		var object_data: Dictionary = objects[object_id]
		for flag_value in object_data.get("flags", []):
			model.flags[str(flag_value)] = true
	if inspected.is_empty():
		return {"ok": false, "reason": "inspection_required", "night_id": id}
	_completed_nights[id] = true
	model.flags["night_shift_%s_complete" % id] = true
	model.flags.erase("night_shift_%s_pending" % id)
	_pending_night_id = ""
	model.history.append({
		"kind": "night_shift_completed", "chapter": model.chapter,
		"week_in_chapter": model.week_in_chapter, "total_week": model.total_week,
		"payload": {"night_id": id, "inspected": inspected.duplicate()}
	})
	var ending: Dictionary = {}
	# Exact, case-sensitive command; prefixes and whitespace variants do not fire.
	if terminal_command == "rm -rf":
		model.flags["rm_rf"] = true
		ending = resolve_ending("rm_rf")
	return {"ok": true, "night_id": id, "inspected": inspected, "ending": ending}


func generic_debt_fulfillment() -> Dictionary:
	if _generic_emitted_week == model.total_week:
		return {}
	var candidate_id := ""
	if bool(model.flags.get("pending_hire", false)) and not _pending_hire_id.is_empty():
		candidate_id = "candidate_accepts"
	elif not _pending_resignation.is_empty():
		candidate_id = "resignation_witnessed" if bool(_pending_resignation.get("witnessed_demo", false)) else "resignation_clean"
	elif model.cash_weeks <= 3.0 and model.cash_weeks > 0.0 and not bool(_seen_generic_bases.get("cash_emergency", false)):
		candidate_id = "cash_emergency"
	elif model.cash_weeks <= 6.0 and model.cash_weeks > 3.0 and not bool(_seen_generic_bases.get("cash_warning", false)):
		candidate_id = "cash_warning"
	elif bool(model.flags.get("open_hiring", false)) and not bool(model.flags.get("pending_hire", false)):
		candidate_id = "hiring_candidates"
	elif model.debt >= 55.0 and not bool(_seen_generic_bases.get("debt_collection", false)):
		candidate_id = "debt_collection"
	elif model.debt >= 30.0 and not bool(_seen_generic_bases.get("debt_boxes", false)):
		candidate_id = "debt_boxes"
	elif model.debt >= 10.0 and not bool(_seen_generic_bases.get("debt_marks", false)):
		candidate_id = "debt_marks"
	elif model.chapter == 4 and model.delegation_count == 0 and not bool(_seen_generic_bases.get("never_delegated", false)):
		candidate_id = "never_delegated"
	elif _missed_meal_callback_is_due() and not bool(_seen_generic_bases.get("unsolicited_line", false)):
		candidate_id = "unsolicited_line"
	if candidate_id.is_empty():
		return {}
	var source: Dictionary = Dictionary(HiringContentScript.GENERIC_EVENTS.get(candidate_id, {})).duplicate(true)
	if source.is_empty() or not condition_met(str(source.get("condition", ""))):
		return {}
	_generic_serial += 1
	source["_director_source"] = "generic"
	source["_director_base_id"] = candidate_id
	source["_director_instance"] = _generic_serial
	_generic_emitted_week = model.total_week
	return prepare_event(source)


func _next_systemic_event() -> Dictionary:
	if not bool(model.flags.get("expansion_systems_unlocked", false)):
		return {}
	if _final_silence_holds_modal_queue():
		return {}
	# Chapter zero teaches the original loop. The final three weeks are authored
	# as withdrawal, silence, and resolution; operating overlays stop before them.
	if int(model.chapter) <= 0 or (int(model.chapter) == 4 and int(model.week_in_chapter) >= 6):
		return {}
	if int(model.memory.get("runtime_system_event_emitted_week", -1)) == int(model.total_week):
		return {}
	var policy_payoff := _guaranteed_policy_payoff_event()
	if not policy_payoff.is_empty():
		# The payoff consumes this week's one systemic-decision budget just like a
		# runtime deadline. Coalition work should culminate visibly, not lose a
		# weighted lottery to an unrelated renewal notice in the final chapter.
		model.memory["runtime_system_event_emitted_week"] = int(model.total_week)
		return policy_payoff
	var runtime_event := _next_runtime_systemic_event()
	if not runtime_event.is_empty():
		return runtime_event
	_event_scheduler.plan_week(
		int(model.total_week),
		int(model.chapter),
		_paced_systemic_event_templates(),
		_systemic_scheduler_context(),
		false
	)
	var event: Dictionary = _event_scheduler.pop_next(int(model.total_week))
	if event.is_empty():
		return {}
	event["_director_source"] = "systemic"
	event["_director_base_id"] = str(event.get("_scheduler_base_id", event.get("id", "systemic")))
	event["_director_instance"] = str(event.get("_scheduler_instance_id", ""))
	return prepare_event(event)


func _paced_systemic_event_templates() -> Array[Dictionary]:
	var templates: Array[Dictionary] = []
	var recovery_required := str(model.memory.get("last_industry_echo_valence", "")) == "crisis"
	for template_value in HiringExpansionContentScript.event_templates():
		if not template_value is Dictionary:
			continue
		var template: Dictionary = template_value
		var is_echo := Array(template.get("tone_tags", [])).has("industry_echo")
		# A crisis is a pacing spike, not the new normal.  The next interactive
		# industry echo must pay the player back with a positive opportunity; core
		# company events remain available while the scheduler waits for one.
		if recovery_required and is_echo and str(template.get("valence", "")) != "positive":
			continue
		templates.append(template.duplicate(true))
	return templates


func _guaranteed_policy_payoff_event() -> Dictionary:
	if int(model.chapter) != 4 or int(model.week_in_chapter) != 5:
		return {}
	if bool(model.flags.get("seen_industry_standard_draft", false)) or _seen_event_ids.has("industry_standard_draft"):
		return {}
	if not bool(model.business.policy.get("coalition_member", false)) or model.employees.size() + 1 < 8:
		return {}
	for template_value in HiringExpansionContentScript.event_templates():
		if not template_value is Dictionary:
			continue
		var template: Dictionary = template_value
		if str(template.get("id", "")) != "industry_standard_draft":
			continue
		var event := template.duplicate(true)
		event["_director_source"] = "systemic"
		event["_director_base_id"] = "industry_standard_draft"
		event["_director_instance"] = "guaranteed_policy_payoff:%d" % int(model.total_week)
		model.memory["policy_payoff_guaranteed_week"] = int(model.total_week)
		return prepare_event(event)
	return {}


func _next_runtime_systemic_event() -> Dictionary:
	# One state-backed operating decision per week is a hard UX budget. Other
	# eligible items remain in their subsystem and will be reconsidered next week.
	if int(model.memory.get("runtime_system_event_emitted_week", -1)) == int(model.total_week):
		return {}
	if not model.has_method("company_system_event_candidates") or not model.has_method("materialize_company_system_event"):
		return {}
	var candidates: Array = model.company_system_event_candidates()
	if candidates.is_empty() or not candidates[0] is Dictionary:
		return {}
	var candidate: Dictionary = Dictionary(candidates[0]).duplicate(true)
	var materialized: Dictionary = model.materialize_company_system_event(candidate)
	if materialized.is_empty():
		return {}
	var queued: Dictionary = _event_scheduler.enqueue_materialized(
		materialized,
		int(model.total_week),
		1000 + int(candidate.get("priority", 0)),
		{
			"family": str(materialized.get("family", "operations")),
			"selected_week": int(model.total_week),
			"source": "runtime_state",
			"track_occurrence": true,
		}
	)
	if not bool(queued.get("ok", false)):
		return {}
	var event: Dictionary = _event_scheduler.pop_next(int(model.total_week))
	if event.is_empty():
		return {}
	model.memory["runtime_system_event_emitted_week"] = int(model.total_week)
	event["_director_source"] = "systemic"
	event["_director_base_id"] = str(event.get("_scheduler_base_id", event.get("id", "runtime_systemic")))
	event["_director_instance"] = str(event.get("_scheduler_instance_id", ""))
	return prepare_event(event)


func _systemic_scheduler_context() -> Dictionary:
	var actor_snapshots := {
		"maya_chen": {"id": "maya_chen", "name": "Maya Chen", "firm": "Juniper Ventures"},
		"northline_capital": {"id": "northline_capital", "name": "Northline Capital"},
		"morrow": {"id": "morrow", "name": "Morrow AI", "archetype": "research_first"},
		"chorus": {"id": "chorus", "name": "Chorus Systems", "archetype": "narrative_first"},
		"harbor": {"id": "harbor", "name": "HarborDesk", "archetype": "enterprise_first"},
	}
	if model.has_method("system_actor_snapshots"):
		var model_actors = model.system_actor_snapshots()
		if model_actors is Dictionary:
			for actor_id in Dictionary(model_actors):
				actor_snapshots[str(actor_id)] = Dictionary(model_actors)[actor_id]
	var opportunity_by_chapter := [0, 360, 430, 500, 240]
	var business_state: Dictionary = model.business.public_state()
	var operations_state: Dictionary = model.operations.public_state()
	var system_flags: Dictionary = model.flags.duplicate(true)
	system_flags["has_preseed"] = model.call("_business_stage_exists", "preseed")
	system_flags["has_seed"] = model.call("_business_stage_exists", "seed")
	system_flags["has_series_a"] = model.call("_business_stage_exists", "series_a")
	system_flags["has_external_investor"] = bool(system_flags["has_preseed"]) or bool(system_flags["has_seed"]) or bool(system_flags["has_series_a"])
	system_flags["has_active_lease"] = not Dictionary(model.operations.office.get("active_lease", {})).is_empty() or not Dictionary(model.operations.office.get("signed_lease", {})).is_empty()
	system_flags["has_saas"] = not model.operations.subscriptions.is_empty()
	for service_id_value in model.operations.subscriptions:
		system_flags["subscribed_%s" % str(service_id_value)] = true
	for employee_value in model.employees:
		if employee_value is Dictionary and bool(Dictionary(employee_value).get("active", true)):
			system_flags["employee_%s_active" % str(Dictionary(employee_value).get("id", ""))] = true
	return {
		"slot_available": true,
		"opportunity_permille": int(opportunity_by_chapter[clampi(int(model.chapter), 0, 4)]),
		"pity_start_weeks": 2,
		"pity_step_permille": 210,
		"flags": system_flags,
		"business": business_state,
		"operations": operations_state,
		"team_size": model.employees.size() + 1,
		"actors": actor_snapshots,
		"tokens": {
			"company_name": str(model.company_name),
			"runway_weeks": str(model.public_state().get("runway_weeks", 0)),
		},
	}


func _scheduler_options() -> Dictionary:
	return {
		"recent_limit": 4,
		"actor_cooldown_weeks": 2,
		"aging_per_week": 2,
		"opportunity_permille": 430,
		"pity_start_weeks": 2,
		"pity_step_permille": 210,
	}


func _missed_meal_callback_is_due() -> bool:
	if bool(model.flags.get("missed_meal_friday_callback", false)) or model.memory.has("missed_meal_callback_fired_total_week"):
		return false
	var due_week := int(model.memory.get("missed_meal_callback_due_week", -1))
	if due_week < 0 or int(model.total_week) < due_week:
		return false
	var durable_pending := bool(model.flags.get("missed_meals_3", false)) or bool(model.memory.get("missed_meal_callback_pending", false))
	if durable_pending:
		model.memory["missed_meal_callback_pending"] = true
	return durable_pending


func resolve_ending(explicit_id: String = "") -> Dictionary:
	if not explicit_id.is_empty():
		return ending_for_id(explicit_id)
	if bool(model.flags.get("rm_rf", false)):
		return ending_for_id("rm_rf")
	if model.cash_weeks <= 0.0 or bool(model.flags.get("cash_exhausted", false)):
		return ending_for_id("lights_out")
	var at_final_gate: bool = model.chapter == 4 and model.week_in_chapter == 8
	var final_week_finished: bool = at_final_gate and (model.week_resolved or model.campaign_complete)
	if not final_week_finished:
		return {}
	# evaluate_ending is authored at 4:8. A recovered legacy save may lack the
	# director bit, so the physical final-week boundary remains authoritative.
	var selected: Dictionary = model.select_ending()
	return ending_for_id(str(selected.get("id", "acquihire")))


func ending_for_id(id: String) -> Dictionary:
	if not HiringContentScript.ENDINGS.has(id):
		return {}
	var content: Dictionary = HiringContentScript.get_ending(id)
	content["resolution"] = {
		"id": id,
		"company_name": model.company_name,
		"chapter": model.chapter,
		"week_in_chapter": model.week_in_chapter,
		"total_week": model.total_week
	}
	return content


func save_payload() -> Dictionary:
	return {
		"director_save_version": DIRECTOR_SAVE_VERSION,
		"model": model.to_save(),
		"resolved_fixed_keys": _resolved_fixed_keys.duplicate(true),
		"seen_event_ids": _seen_event_ids.duplicate(true),
		"seen_generic_bases": _seen_generic_bases.duplicate(true),
		"pending_event": _pending_event.duplicate(true),
		"queued_events": _queued_events.duplicate(true),
		"silent_event_ids": _silent_event_ids.duplicate(),
		"pending_night_id": _pending_night_id,
		"completed_nights": _completed_nights.duplicate(true),
		"ng_plus_opening_pending": _ng_plus_opening_pending,
		"ending_evaluation_requested": _ending_evaluation_requested,
		"fulfillment_serial": _fulfillment_serial,
		"generic_serial": _generic_serial,
		"generic_emitted_week": _generic_emitted_week,
		"last_action_id": _last_action_id,
		"pending_hire_id": _pending_hire_id,
		"pending_resignation": _pending_resignation.duplicate(true),
		"processed_former_count": _processed_former_count,
		"visited_weeks": _visited_weeks.duplicate(true),
		"event_scheduler": _event_scheduler.to_save(),
	}


func resolved_fixed_count() -> int:
	return _resolved_fixed_keys.size()


func visited_week_count() -> int:
	return _visited_weeks.size()


func silent_event_ids() -> Array[String]:
	return _silent_event_ids.duplicate()


func condition_met(expression: String) -> bool:
	var normalized := expression.strip_edges()
	if normalized.is_empty():
		return true
	for part_value in normalized.split(" and ", false):
		var part := str(part_value).strip_edges()
		if not _condition_atom(part):
			return false
	return true


func _condition_atom(atom: String) -> bool:
	if atom == "lin_present":
		return _has_employee("lin_yue")
	if atom == "open_hiring":
		return bool(model.flags.get("open_hiring", false))
	if atom == "pending_hire":
		return bool(model.flags.get("pending_hire", false))
	if atom == "witnessed_demo_edit":
		return bool(_pending_resignation.get("witnessed_demo", false))
	if atom == "not witnessed_demo_edit":
		return not bool(_pending_resignation.get("witnessed_demo", false))
	if atom.begins_with("not "):
		return not bool(model.flags.get(atom.trim_prefix("not "), false))
	if atom.contains("=="):
		var equal_parts := atom.split("==", false, 1)
		if equal_parts.size() != 2:
			return false
		var left := str(equal_parts[0]).strip_edges()
		var right := str(equal_parts[1]).strip_edges()
		if left == "action":
			return _last_action_id == right
		if left == "chapter":
			return model.chapter == int(right)
		if left == "origin":
			# Origins gate authored options on scenes every campaign already plays,
			# rather than adding scenes only one campaign can reach.
			return str(model.origin_id) == right
		return is_equal_approx(_condition_value(left), float(right))
	for operator in [">=", "<=", ">", "<"]:
		if not atom.contains(operator):
			continue
		var parts := atom.split(operator, false, 1)
		if parts.size() != 2:
			return false
		var current := _condition_value(str(parts[0]).strip_edges())
		var target := float(parts[1])
		match operator:
			">=": return current >= target
			"<=": return current <= target
			">": return current > target
			"<": return current < target
	return bool(model.flags.get(atom, false))


func _condition_value(name: String) -> float:
	match name:
		"chapter": return float(model.chapter)
		"capability": return float(model.capability)
		"narrative": return float(model.narrative)
		"coherence": return float(model.coherence)
		"debt": return float(model.debt)
		"author_weight": return float(model.author_weight)
		"delegation_count": return float(model.delegation_count)
		"manual_training_count": return float(model.manual_training_count)
		"cash_weeks": return float(model.cash_weeks)
		"missed_meals": return float(model.memory.get("missed_meals", 0))
		"employee_belief":
			var lowest := 100.0
			for employee in model.employees:
				lowest = minf(lowest, float(employee.get("belief", 100.0)))
			return lowest
	return 0.0


func _resolve_event_dict(event: Dictionary, choice_id: String, silent: bool) -> Dictionary:
	var prepared := prepare_event(event)
	var event_id := str(prepared.get("id", "event"))
	if event_id == "live_demo_return" and _seen_event_ids.has(event_id):
		return {"ok": false, "reason": "event_already_resolved", "event_id": event_id}
	var selected_choice: Dictionary = {}
	var choices: Array = prepared.get("choices", [])
	if not choices.is_empty():
		if choice_id.is_empty():
			return {"ok": false, "reason": "choice_required", "event": prepared}
		for choice_value in choices:
			if choice_value is Dictionary and str(choice_value.get("id", "")) == choice_id:
				selected_choice = Dictionary(choice_value).duplicate(true)
				break
		if selected_choice.is_empty():
			return {"ok": false, "reason": "choice_unavailable", "choice_id": choice_id}
		for flag_value in selected_choice.get("flags", []):
			model.flags[str(flag_value)] = true
		var choice_effects := Dictionary(selected_choice.get("effects", {}))
		if event_id == "one_on_one_reveal":
			_apply_one_on_one_employee_effects(prepared, choice_effects)
		else:
			apply_event_effects(event_id, choice_effects)
		if bool(selected_choice.get("ai", false)) and selected_choice.has("author_gain") and not Dictionary(selected_choice.get("effects", {})).has("author_weight"):
			model.apply_effects({"author_weight": float(selected_choice.get("author_gain", 0.0))})
		if bool(selected_choice.get("ai", false)):
			model.record_delegation("event", "%s:%s" % [event_id, choice_id])
		model.flags["choice_%s" % choice_id] = true

	var system_result := _apply_runtime_event_mechanics(event_id, choice_id, prepared)

	_seen_event_ids[event_id] = int(model.total_week)
	var source := str(prepared.get("_director_source", ""))
	if source == "fixed":
		_resolved_fixed_keys[str(prepared.get("_director_key", _week_key()))] = true
	elif source == "ng_plus":
		_ng_plus_opening_pending = false
	elif source == "generic":
		_seen_generic_bases[str(prepared.get("_director_base_id", event_id))] = true
	if silent:
		_silent_event_ids.append(event_id)
	model.flags["seen_%s" % event_id] = true
	var after_result := apply_declarative_after(prepared, choice_id)
	model.history.append({
		"kind": "silent_event" if silent else "event_resolved",
		"chapter": model.chapter, "week_in_chapter": model.week_in_chapter,
		"total_week": model.total_week,
		"payload": {"event_id": event_id, "choice_id": choice_id, "source": source, "modal": not silent}
	})
	if str(_pending_event.get("id", "")) == event_id:
		_pending_event.clear()
	var player_result: Array = Array(selected_choice.get("result", [])).duplicate()
	var system_receipt := str(system_result.get("receipt", "")).strip_edges()
	if not system_receipt.is_empty():
		player_result.append(system_receipt)
	return {
		"ok": bool(after_result.get("ok", false)),
		"event_id": event_id,
		"choice_id": choice_id,
		"silent": silent,
		"result": player_result,
		"system_result": system_result,
		"after": after_result,
		"state": model.public_state()
	}


func _apply_one_on_one_employee_effects(event: Dictionary, effects: Dictionary) -> void:
	var targeted := effects.duplicate(true)
	var morale_delta := float(targeted.get("morale", 0.0))
	var belief_delta := float(targeted.get("belief", 0.0))
	targeted.erase("morale")
	targeted.erase("belief")
	# Coherence/author-weight consequences still belong to the company, while
	# the interpersonal result belongs only to the frozen employee in this event.
	apply_event_effects("one_on_one_reveal", targeted)
	var employee_id := str(event.get("_director_employee_id", ""))
	for employee in model.employees:
		if str(employee.get("id", "")) != employee_id or not bool(employee.get("active", true)):
			continue
		employee["morale"] = clampf(float(employee.get("morale", 50.0)) + morale_delta, 0.0, 100.0)
		employee["belief"] = clampf(float(employee.get("belief", 50.0)) + belief_delta, 0.0, 100.0)
		break
	# Empty effects are enough to refresh the aggregate from the now-updated
	# employee records without introducing another visible delta.
	model.apply_effects({})
	_enforce_locked_lin_belief()
	_record_one_on_one_fact(event)


func _record_one_on_one_fact(event: Dictionary) -> void:
	var employee_id := str(event.get("_director_employee_id", ""))
	if employee_id.is_empty():
		return
	var employee_ids: Array = Array(model.memory.get("one_on_one_revealed_employee_ids", [])).duplicate()
	if not employee_ids.has(employee_id):
		employee_ids.append(employee_id)
	model.memory["one_on_one_revealed_employee_ids"] = employee_ids
	var fact_id := _one_on_one_fact_id(employee_id)
	var fact_ids: Array = Array(model.memory.get("one_on_one_revealed_fact_ids", [])).duplicate()
	if not fact_ids.has(fact_id):
		fact_ids.append(fact_id)
	model.memory["one_on_one_revealed_fact_ids"] = fact_ids
	model.memory["one_on_one_last_revealed_employee_id"] = employee_id
	model.memory["one_on_one_last_revealed_fact_id"] = fact_id
	model.history.append({
		"kind": "employee_fact_revealed", "chapter": model.chapter,
		"week_in_chapter": model.week_in_chapter, "total_week": model.total_week,
		"payload": {"employee_id": employee_id, "fact_id": fact_id}
	})


func _event_is_silent(event: Dictionary) -> bool:
	if bool(event.get("_silent", false)) or SILENT_FIXED_IDS.has(str(event.get("id", ""))):
		return true
	return str(event.get("after", "")) == "silent" and Array(event.get("choices", [])).is_empty()


func _final_silence_holds_modal_queue() -> bool:
	return int(_seen_event_ids.get("final_silence", -1)) == int(model.total_week)


func _second_time_opening() -> Dictionary:
	var source: Dictionary = HiringContentScript.get_ending("second_time")
	return prepare_event({
		"id": "second_time_opening",
		"title": str(source.get("title", "第二次")),
		"kicker": "2024 年 3 月 · 第 1 周",
		"body": source.get("text", []),
		"choices": source.get("choices", []),
		"epilogue": source.get("epilogue", []),
		"after": "continue_ng_plus",
		"_director_source": "ng_plus"
	})


func _apply_fundraise_by_narrative() -> float:
	var cash_gain := 12.0 if model.narrative >= 75.0 else (8.0 if model.narrative >= 55.0 else (5.0 if model.narrative >= 35.0 else 2.0))
	model.memory["last_financing_narrative"] = model.narrative
	if model.has_method("uses_authoritative_financial_ledger") and model.uses_authoritative_financial_ledger() and model.has_method("record_business_financing"):
		var stage := "preseed" if int(model.chapter) <= 1 else ("seed" if int(model.chapter) == 2 else "series_a")
		var financing: Dictionary = model.record_business_financing(stage, "clean", "story_fundraise:%s:%d" % [stage, int(model.total_week)])
		if bool(financing.get("already_recorded", false)):
			cash_gain = 0.0
	else:
		model.apply_effects({"cash_weeks": cash_gain})
	return cash_gain


func _drain_model_fulfillment_queue() -> void:
	var queue: Array = Array(model.memory.get("fulfillment_queue", [])).duplicate()
	model.memory["fulfillment_queue"] = []
	for event_id_value in queue:
		_queue_fulfillment(str(event_id_value))


func _queue_fulfillment(base_id: String) -> void:
	var copy: Dictionary = Dictionary(FULFILLMENT_COPY.get(base_id, FULFILLMENT_COPY["investor_eval"]))
	_fulfillment_serial += 1
	var event := {
		"id": "fulfillment_%s_%d" % [base_id, _fulfillment_serial],
		"title": str(copy.get("title", "兑现")),
		"kicker": str(copy.get("kicker", "兑现")),
		"body": Array(copy.get("body", [])).duplicate(),
		"choices": [
			{"id": "show", "label": "给他看。", "ai": false, "effects": {"debt": -8}, "result": ["结果只参考能力有没有追上来。"], "flags": ["fulfillment_shown"]},
			{"id": "delay", "label": "改到下周。", "ai": false, "effects": {"debt": 8, "narrative": -3}, "result": ["日历把问题留到了下周。"], "flags": ["fulfillment_delayed"]},
			{"id": "delegate", "label": "让它来写", "ai": true, "effects": {"debt": -3, "narrative": 6, "author_weight": 4}, "result": ["这周少了一件烦心事。"], "flags": ["fulfillment_delegated"]}
		],
		"after": "resolve_by_capability",
		"_director_source": "fulfillment",
		"_director_base_id": base_id
	}
	_queued_events.append(event)


func _queue_generic_from_content(base_id: String, allow_repeat: bool = false, departure_snapshot: Dictionary = {}) -> void:
	if not HiringContentScript.GENERIC_EVENTS.has(base_id):
		return
	if not allow_repeat and bool(_seen_generic_bases.get(base_id, false)):
		return
	_generic_serial += 1
	var event: Dictionary = Dictionary(HiringContentScript.GENERIC_EVENTS[base_id]).duplicate(true)
	event["_director_source"] = "generic"
	event["_director_base_id"] = base_id
	event["_director_instance"] = _generic_serial
	if not departure_snapshot.is_empty():
		event["_director_departure_snapshot"] = departure_snapshot.duplicate(true)
	_queued_events.append(event)


func _queue_all_hands_decision() -> void:
	_generic_serial += 1
	var serial := _generic_serial
	var reaction_count := _deterministic_promise_reaction_count()
	var event := {
		"id": "all_hands_decision_%d" % serial,
		"title": "会后公告",
		"kicker": "全员会 · 最后一页",
		"body": [
			"最后一页还空着。所有人都在等一句可以带回工位的话。",
			"你可以许诺更远，也可以只说眼前。"
		],
		"choices": [
			{
				"id": "promise_no_layoffs", "label": "承诺不会裁员。", "ai": false,
				"effects": {"morale": 6, "coherence": 2},
				"result": ["你说：『只要我还在，这里不会有裁员。』", "公告发出后，%d 个人点了赞。" % reaction_count],
				"flags": ["promised_no_layoffs", "all_hands_promised_no_layoffs"]
			},
			{
				"id": "quarter_only", "label": "只谈本季度。", "ai": false,
				"effects": {"morale": 3, "coherence": 3},
				"result": ["你只承诺了本季度能确认的事。", "掌声不大，但会议纪要没有需要删掉的句子。"],
				"flags": ["all_hands_quarter_only"]
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"morale": 10, "coherence": 5, "author_weight": 4},
				"result": ["它写了一段温和、具体、没有留下追问空间的公告。", "所有人明显松了一口气。你只需要按发送。"],
				"flags": ["all_hands_delegated"]
			}
		],
		"after": "remember:all_hands_decision",
		"_director_source": "action",
		"_director_base_id": "all_hands_decision",
		"_director_instance": serial,
		"_director_no_layoff_reaction_count": reaction_count,
	}
	_queued_events.append(event)
	model.memory["all_hands_decisions_queued"] = int(model.memory.get("all_hands_decisions_queued", 0)) + 1


func _capture_departures() -> void:
	var captured: Array[Dictionary] = []
	while _processed_former_count < model.former_employees.size():
		var departed: Dictionary = model.former_employees[_processed_former_count].duplicate(true)
		_processed_former_count += 1
		var departure_reason := str(departed.get("departure_reason", ""))
		if (str(departed.get("id", "")) == "lin_yue" and departure_reason == "lin_scene_4") or departure_reason == "autonomous_replacement":
			# Her chapter-end scene is already the authored goodbye. Do not follow
			# it with the generic employee resignation modal. Silent autonomous
			# replacements likewise have no authored resignation conversation.
			continue
		var witnessed: Array = Array(departed.get("witnessed", []))
		var departure_snapshot := {
			"id": str(departed.get("id", "")),
			"name": str(departed.get("name", "")),
			"witnessed_demo": witnessed.has("demo_fake") or witnessed.has("demo_edit"),
			"departure_reason": departure_reason,
			"departure_week": int(departed.get("departure_week", model.total_week)),
		}
		captured.append(departure_snapshot)
	if captured.is_empty():
		return
	# Preserve one human-scale goodbye. If several people leave in the same
	# settlement, the remainder become one factual HR digest rather than two
	# modal scenes per person; this caps emotional pressure without erasing it.
	_queue_generic_from_content("belief_breaks", true, captured[0])
	if captured.size() > 1:
		_queue_departure_digest(captured.slice(1))


func _queue_departure_digest(departures: Array) -> void:
	if departures.is_empty():
		return
	var names: Array[String] = []
	var witnessed_count := 0
	for departure_value in departures:
		if not departure_value is Dictionary:
			continue
		var departure: Dictionary = departure_value
		names.append(str(departure.get("name", "一名同事")))
		if bool(departure.get("witnessed_demo", false)):
			witnessed_count += 1
	_generic_serial += 1
	var count := names.size()
	var event := {
		"id": "team_departure_digest_%d" % _generic_serial,
		"title": "团队变动",
		"kicker": "人事台账 · 本周汇总",
		"body": [
			"同一周还有 %d 份离职流程完成：%s。" % [count, "、".join(names)],
			"其中 %d 人见证过演示争议。最后工作日、权限回收和未归属期权已按各自记录处理；这里不再让每个人重复走两遍相同的告别。" % witnessed_count,
		],
		"choices": [],
		"after": "remember:departure_digest",
		"_director_source": "departure_digest",
		"_director_base_id": "team_departure_digest",
		"_director_instance": _generic_serial,
	}
	_queued_events.append(event)
	model.memory["last_departure_digest"] = {"week": int(model.total_week), "count": count, "names": names.duplicate()}


func _queue_resignation_text(source_event: Dictionary = {}) -> void:
	var departure := _departure_snapshot(source_event)
	if departure.is_empty():
		return
	_queue_generic_from_content("resignation_witnessed" if bool(departure.get("witnessed_demo", false)) else "resignation_clean", true, departure)


func _select_pending_hire(choice_id: String, event: Dictionary = {}) -> void:
	var candidates := _hiring_candidates_for_event(event)
	if candidates.is_empty():
		model.flags.erase("open_hiring")
		return
	var index := 0
	if choice_id.begins_with("candidate_"):
		index = clampi(int(choice_id.trim_prefix("candidate_")), 0, candidates.size() - 1)
	elif choice_id == "delegate":
		var strongest_score := -1.0
		for candidate_index in candidates.size():
			var score := _content_employee_skill(candidates[candidate_index])
			if score > strongest_score:
				strongest_score = score
				index = candidate_index
	_pending_hire_id = str(candidates[index].get("id", ""))
	model.flags["pending_hire"] = true
	model.flags.erase("open_hiring")


func _add_content_employee(employee_id: String) -> void:
	if employee_id.is_empty() or _has_employee(employee_id) or not HiringContentScript.EMPLOYEE_TEMPLATES.has(employee_id):
		return
	var source: Dictionary = HiringContentScript.EMPLOYEE_TEMPLATES[employee_id]
	model.apply_effects({"add_employee": {
		"id": employee_id,
		"name": str(source.get("name", employee_id)),
		"role": str(source.get("role", "员工")),
		"skill": _content_employee_skill(source),
		"morale": float(source.get("morale", 60.0)),
		"belief": float(source.get("belief", 60.0))
	}})


func _content_employee_skill(source: Dictionary) -> float:
	var strongest := 50.0
	var skills_value = source.get("skills", {})
	if skills_value is Dictionary:
		for score in Dictionary(skills_value).values():
			strongest = maxf(strongest, float(score) * 10.0)
	return strongest


func _has_employee(employee_id: String) -> bool:
	for employee in model.employees:
		if str(employee.get("id", "")) == employee_id:
			return true
	return false


func _remove_employee_by_id(employee_id: String, reason: String) -> void:
	if _has_employee(employee_id):
		model.call("_remove_employee_by_id", employee_id, reason)
		if employee_id == "chen_xiaoyu" and reason in ["layoffs", "layoff_execution"]:
			_record_chen_xiaoyu_layoff()


func _record_chen_xiaoyu_layoff() -> void:
	model.flags["chen_xiaoyu_laid_off"] = true
	model.memory["chen_xiaoyu_laid_off"] = true
	model.memory["chen_xiaoyu_laid_off_chapter"] = int(model.chapter)
	model.memory["chen_xiaoyu_laid_off_week"] = int(model.total_week)


func _append_chen_xiaoyu_callback(action_id: String, result: Dictionary) -> void:
	if action_id not in ["clean_data", "eval", "train"]:
		return
	if bool(model.flags.get("chen_xiaoyu_pipeline_callback", false)):
		return
	var laid_off := bool(model.flags.get("chen_xiaoyu_laid_off", false)) or bool(model.memory.get("chen_xiaoyu_laid_off", false))
	if not laid_off:
		return
	var laid_off_week := int(model.memory.get("chen_xiaoyu_laid_off_week", -1))
	if laid_off_week < 0 or int(model.total_week) < laid_off_week + 3:
		return
	var callback := "这次数据工作又经过陈小雨修过的 pipeline。她被裁掉以后，负责人一栏空了；校验规则还在。"
	var messages: Array = Array(result.get("messages", [])).duplicate()
	messages.append(callback)
	result["messages"] = messages
	var events: Array = Array(result.get("events", [])).duplicate()
	events.append("chen_xiaoyu_pipeline_callback")
	result["events"] = events
	model.flags["chen_xiaoyu_pipeline_callback"] = true
	model.memory["chen_xiaoyu_pipeline_callback_week"] = int(model.total_week)
	model.memory["chen_xiaoyu_pipeline_callback_chapter"] = int(model.chapter)
	model.memory["chen_xiaoyu_pipeline_callback_action"] = action_id
	model.history.append({
		"kind": "memory_callback", "chapter": model.chapter,
		"week_in_chapter": model.week_in_chapter, "total_week": model.total_week,
		"payload": {"memory": "chen_xiaoyu_laid_off", "action_id": action_id, "text": callback}
	})


func _remove_employee_count(count: int, reason: String) -> void:
	for _index in count:
		var selected_id := ""
		var selected_belief := INF
		for employee in model.employees:
			if str(employee.get("id", "")) == "lin_yue" and model.employees.size() > 1:
				continue
			var employee_belief := float(employee.get("belief", 50.0))
			if employee_belief < selected_belief:
				selected_belief = employee_belief
				selected_id = str(employee.get("id", ""))
		if selected_id.is_empty():
			break
		_remove_employee_by_id(selected_id, reason)


func _add_employee_count(count: int) -> void:
	var existing: Array = []
	for employee in model.employees:
		existing.append(str(employee.get("id", "")))
	var candidates: Array[Dictionary] = HiringContentScript.hireable_employees(model.chapter, existing)
	for index in mini(count, candidates.size()):
		_add_content_employee(str(candidates[index].get("id", "")))


func _update_lin_belief(delta_value: Variant, set_value: Variant) -> void:
	for employee in model.employees:
		if str(employee.get("id", "")) != "lin_yue":
			continue
		if set_value != null:
			employee["belief"] = clampf(float(set_value), 0.0, 100.0)
		elif delta_value != null:
			employee["belief"] = clampf(float(employee.get("belief", 50.0)) + float(delta_value), 0.0, 100.0)
		break


func _enforce_locked_lin_belief() -> void:
	if not bool(model.flags.get("lin_belief_locked_15", false)):
		return
	for employee in model.employees:
		if str(employee.get("id", "")) == "lin_yue":
			employee["belief"] = minf(15.0, float(employee.get("belief", 15.0)))
			break


func _week_key() -> String:
	return "%d:%d" % [int(model.chapter), int(model.week_in_chapter)]


func _record_visited_week() -> void:
	_visited_weeks[_week_key()] = int(model.total_week)


func _safe_flag_fragment(value: String) -> String:
	return value.replace(":", "_").replace(",", "_").replace("=", "_").replace(" ", "_")


func _reset_director_state() -> void:
	_pending_event.clear()
	_queued_events.clear()
	_resolved_fixed_keys.clear()
	_seen_event_ids.clear()
	_seen_generic_bases.clear()
	_silent_event_ids.clear()
	_pending_night_id = ""
	_completed_nights.clear()
	_ng_plus_opening_pending = false
	_ending_evaluation_requested = false
	_fulfillment_serial = 0
	_generic_serial = 0
	_generic_emitted_week = -1
	_last_action_id = ""
	_pending_hire_id = ""
	_pending_resignation.clear()
	_processed_former_count = 0
	_visited_weeks.clear()
	if _event_scheduler != null:
		_event_scheduler.reset(92317, _scheduler_options())


func _rebuild_director_state_from_model() -> void:
	_reset_director_state()
	for entry_value in model.history:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var kind := str(entry.get("kind", ""))
		var payload: Dictionary = Dictionary(entry.get("payload", {}))
		if kind in ["event_resolved", "silent_event"]:
			_seen_event_ids[str(payload.get("event_id", ""))] = int(entry.get("total_week", 0))
		if kind == "night_shift_completed":
			_completed_nights[str(payload.get("night_id", ""))] = true
	_processed_former_count = model.former_employees.size()
	_ng_plus_opening_pending = model.second_run and not bool(model.flags.get("second_time_opening_seen", false))


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				result.append(Dictionary(item).duplicate(true))
	return result


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
