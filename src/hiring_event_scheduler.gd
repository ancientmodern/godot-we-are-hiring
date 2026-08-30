class_name HiringEventScheduler
extends RefCounted

## Deterministic, save-stable scheduler for optional systemic story events.
##
## The scheduler deliberately owns a separate integer RNG. It never reads or
## mutates HiringModel's action RNG, and it never performs a draw from peek/pop.
## A selected template is copied into a complete queue snapshot immediately, so
## queued content survives later template, actor, or context changes.
##
## Public API:
##   reset(seed, options)
##   plan_week(total_week, chapter, templates, context, blocked)
##   enqueue_materialized(event, due_week, priority, options)
##   peek_next(current_week) / pop_next(current_week)
##   pending_events() / pending_count() / has_due_event(current_week)
##   to_save() / load_save(data)
##   debug_state()

const SAVE_VERSION := 1
const DEFAULT_SEED := 104729
const RNG_MODULUS := 2147483647
const RNG_MULTIPLIER := 40692

const DEFAULT_RECENT_LIMIT := 4
const DEFAULT_ACTOR_COOLDOWN_WEEKS := 1
const DEFAULT_AGING_PER_WEEK := 1
const DEFAULT_OPPORTUNITY_PERMILLE := 650
const DEFAULT_PITY_START_WEEKS := 2
const DEFAULT_PITY_STEP_PERMILLE := 175

const _PLANNING_KEYS := [
	"actor_cooldown_weeks",
	"actor_ids",
	"base_weight",
	"chapter_range",
	"condition",
	"conditions",
	"cooldown_weeks",
	"due_in_weeks",
	"enabled",
	"family_cooldown_weeks",
	"ignore_recent",
	"max_per_run",
	"opportunity_permille",
	"pity_start_weeks",
	"pity_step_permille",
	"priority",
	"aging_per_week",
]

var _seed := DEFAULT_SEED
var _rng_state := DEFAULT_SEED
var _current_week := 0
var _serial := 0

var _recent_limit := DEFAULT_RECENT_LIMIT
var _default_actor_cooldown_weeks := DEFAULT_ACTOR_COOLDOWN_WEEKS
var _default_aging_per_week := DEFAULT_AGING_PER_WEEK
var _opportunity_permille := DEFAULT_OPPORTUNITY_PERMILLE
var _pity_start_weeks := DEFAULT_PITY_START_WEEKS
var _pity_step_permille := DEFAULT_PITY_STEP_PERMILLE

var _weeks_without_optional_event := 0
var _queue: Array[Dictionary] = []
var _planned_weeks: Dictionary = {}
var _occurrence_counts: Dictionary = {}
var _last_id_week: Dictionary = {}
var _last_family_week: Dictionary = {}
var _last_actor_week: Dictionary = {}
var _recent_ids: Array[String] = []


func _init(seed: int = DEFAULT_SEED) -> void:
	reset(seed)


func reset(seed: int = DEFAULT_SEED, options: Dictionary = {}) -> void:
	_seed = _normalize_seed(seed)
	_rng_state = _seed
	_current_week = 0
	_serial = 0
	_recent_limit = maxi(0, int(options.get("recent_limit", DEFAULT_RECENT_LIMIT)))
	_default_actor_cooldown_weeks = maxi(0, int(options.get("actor_cooldown_weeks", DEFAULT_ACTOR_COOLDOWN_WEEKS)))
	_default_aging_per_week = maxi(0, int(options.get("aging_per_week", DEFAULT_AGING_PER_WEEK)))
	_opportunity_permille = clampi(int(options.get("opportunity_permille", DEFAULT_OPPORTUNITY_PERMILLE)), 0, 1000)
	_pity_start_weeks = maxi(0, int(options.get("pity_start_weeks", DEFAULT_PITY_START_WEEKS)))
	_pity_step_permille = maxi(0, int(options.get("pity_step_permille", DEFAULT_PITY_STEP_PERMILLE)))
	_weeks_without_optional_event = 0
	_queue.clear()
	_planned_weeks.clear()
	_occurrence_counts.clear()
	_last_id_week.clear()
	_last_family_week.clear()
	_last_actor_week.clear()
	_recent_ids.clear()


## Plans at most one optional event for a campaign week. Repeating this call for
## the same week never draws again or adds another queue entry.
##
## `templates` may be an Array[Dictionary] or a Dictionary keyed by event id.
## Supported planning fields are documented by _template_is_eligible().
## `context` supplies condition values, actor snapshots, token replacements, and
## optional per-week opportunity/pity overrides.
func plan_week(
	total_week: int,
	chapter: int,
	templates: Variant,
	context: Dictionary = {},
	blocked: bool = false
) -> Dictionary:
	if total_week <= 0:
		return _failure("invalid_week")
	var week_key := str(total_week)
	if _planned_weeks.has(week_key):
		return {
			"ok": true,
			"status": "already_planned",
			"week": total_week,
			"queued": _queued_instances_for_planned_week(total_week),
		}

	_current_week = maxi(_current_week, total_week)
	_planned_weeks[week_key] = true
	if blocked or not bool(context.get("slot_available", true)):
		# A story-locked week is neutral: it consumes neither RNG nor pity time.
		return {
			"ok": true,
			"status": "blocked",
			"week": total_week,
			"drought": _weeks_without_optional_event,
		}

	var candidates := _eligible_candidates(total_week, chapter, templates, context)
	if candidates.is_empty():
		_weeks_without_optional_event += 1
		return {
			"ok": true,
			"status": "no_candidate",
			"week": total_week,
			"drought": _weeks_without_optional_event,
		}

	var opportunity := _effective_opportunity_permille(context)
	if opportunity <= 0:
		_weeks_without_optional_event += 1
		return {
			"ok": true,
			"status": "no_opportunity",
			"week": total_week,
			"opportunity_permille": opportunity,
			"drought": _weeks_without_optional_event,
		}
	if opportunity < 1000 and _roll_below(1000) >= opportunity:
		_weeks_without_optional_event += 1
		return {
			"ok": true,
			"status": "no_opportunity",
			"week": total_week,
			"opportunity_permille": opportunity,
			"drought": _weeks_without_optional_event,
		}

	var selected := _weighted_candidate(candidates)
	if selected.is_empty():
		_weeks_without_optional_event += 1
		return {
			"ok": true,
			"status": "no_candidate",
			"week": total_week,
			"drought": _weeks_without_optional_event,
		}

	var actor_ids: Array[String] = _string_array(selected.get("actor_ids", []))
	var actor_id := ""
	if not actor_ids.is_empty():
		actor_id = actor_ids[_roll_below(actor_ids.size())]
	var template: Dictionary = Dictionary(selected.get("template", {}))
	var snapshot := _snapshot_from_template(template, total_week, chapter, actor_id, context)
	var due_week := total_week + maxi(0, int(template.get("due_in_weeks", 0)))
	var options := {
		"family": str(selected.get("family", "")),
		"actor_id": actor_id,
		"actor_snapshot": snapshot.get("actor_snapshot", {}),
		"aging_per_week": maxi(0, int(template.get("aging_per_week", _default_aging_per_week))),
		"selected_week": total_week,
		"source": "optional",
		"track_occurrence": true,
	}
	var queued := enqueue_materialized(snapshot, due_week, int(template.get("priority", 0)), options)
	if not bool(queued.get("ok", false)):
		return queued
	_weeks_without_optional_event = 0
	return {
		"ok": true,
		"status": "selected",
		"week": total_week,
		"opportunity_permille": opportunity,
		"event": Dictionary(queued.get("event", {})).duplicate(true),
		"drought": 0,
	}


## Queues an event that no longer depends on its source template. The event is
## deep-copied, receives stable scheduling metadata, and may safely outlive all
## caller-owned dictionaries.
func enqueue_materialized(
	event: Dictionary,
	due_week: int,
	priority: int = 0,
	options: Dictionary = {}
) -> Dictionary:
	var base_id := str(event.get("id", options.get("base_id", ""))).strip_edges()
	if base_id.is_empty():
		return _failure("event_id_required")
	if due_week <= 0:
		return _failure("invalid_due_week")

	_serial += 1
	var selected_week := maxi(1, int(options.get("selected_week", _current_week if _current_week > 0 else due_week)))
	var family := str(options.get("family", event.get("family", base_id))).strip_edges()
	if family.is_empty():
		family = base_id
	var actor_id := str(options.get("actor_id", event.get("actor_id", ""))).strip_edges()
	var aging_per_week := maxi(0, int(options.get("aging_per_week", _default_aging_per_week)))
	var snapshot := event.duplicate(true)
	if not actor_id.is_empty():
		snapshot["actor_id"] = actor_id
	var actor_snapshot_value = options.get("actor_snapshot", snapshot.get("actor_snapshot", {}))
	if actor_snapshot_value is Dictionary and not Dictionary(actor_snapshot_value).is_empty():
		snapshot["actor_snapshot"] = Dictionary(actor_snapshot_value).duplicate(true)
	var instance_id := "%s#%06d" % [base_id, _serial]
	snapshot["_scheduler_instance_id"] = instance_id
	snapshot["_scheduler_base_id"] = base_id
	snapshot["_scheduler_family"] = family
	snapshot["_scheduler_actor_id"] = actor_id
	snapshot["_scheduler_selected_week"] = selected_week
	snapshot["_scheduler_due_week"] = due_week
	snapshot["_scheduler_priority"] = priority
	snapshot["_scheduler_aging_per_week"] = aging_per_week
	snapshot["_scheduler_sequence"] = _serial
	snapshot["_scheduler_source"] = str(options.get("source", "materialized"))
	_queue.append(snapshot)
	if bool(options.get("track_occurrence", true)):
		_record_occurrence(base_id, family, actor_id, selected_week)
	return {"ok": true, "status": "queued", "event": snapshot.duplicate(true)}


## Returns the highest effective-priority due event without mutating queue or RNG.
func peek_next(current_week: int) -> Dictionary:
	var index := _next_due_index(current_week)
	if index < 0:
		return {}
	return _with_effective_priority(_queue[index], current_week)


## Removes and returns the same event that peek_next() would return. No random
## state is touched, so repeated peeks and a subsequent pop are replay-stable.
func pop_next(current_week: int) -> Dictionary:
	var index := _next_due_index(current_week)
	if index < 0:
		return {}
	var event := _with_effective_priority(_queue[index], current_week)
	_queue.remove_at(index)
	return event


func pending_count() -> int:
	return _queue.size()


func pending_events() -> Array[Dictionary]:
	return _queue.duplicate(true)


func has_due_event(current_week: int) -> bool:
	return _next_due_index(current_week) >= 0


func to_save() -> Dictionary:
	return {
		"scheduler_save_version": SAVE_VERSION,
		"seed": _seed,
		"rng_state": _rng_state,
		"current_week": _current_week,
		"serial": _serial,
		"recent_limit": _recent_limit,
		"default_actor_cooldown_weeks": _default_actor_cooldown_weeks,
		"default_aging_per_week": _default_aging_per_week,
		"opportunity_permille": _opportunity_permille,
		"pity_start_weeks": _pity_start_weeks,
		"pity_step_permille": _pity_step_permille,
		"weeks_without_optional_event": _weeks_without_optional_event,
		"queue": _queue.duplicate(true),
		"planned_weeks": _planned_weeks.duplicate(true),
		"occurrence_counts": _occurrence_counts.duplicate(true),
		"last_id_week": _last_id_week.duplicate(true),
		"last_family_week": _last_family_week.duplicate(true),
		"last_actor_week": _last_actor_week.duplicate(true),
		"recent_ids": _recent_ids.duplicate(),
	}


func load_save(data: Dictionary) -> Dictionary:
	if int(data.get("scheduler_save_version", -1)) != SAVE_VERSION:
		return _failure("scheduler_save_version")
	var loaded_seed := _normalize_seed(int(data.get("seed", DEFAULT_SEED)))
	var loaded_rng := int(data.get("rng_state", loaded_seed))
	if loaded_rng <= 0 or loaded_rng >= RNG_MODULUS:
		return _failure("rng_state_invalid")
	if not data.get("queue", []) is Array:
		return _failure("queue_invalid")
	var loaded_queue := _dictionary_array(data.get("queue", []))
	if loaded_queue.size() != Array(data.get("queue", [])).size():
		return _failure("queued_event_invalid")
	for event in loaded_queue:
		if str(event.get("_scheduler_instance_id", "")).is_empty():
			return _failure("queued_event_invalid")
		if int(event.get("_scheduler_due_week", 0)) <= 0:
			return _failure("queued_event_due_week_invalid")

	_seed = loaded_seed
	_rng_state = loaded_rng
	_current_week = maxi(0, int(data.get("current_week", 0)))
	_serial = maxi(0, int(data.get("serial", 0)))
	_recent_limit = maxi(0, int(data.get("recent_limit", DEFAULT_RECENT_LIMIT)))
	_default_actor_cooldown_weeks = maxi(0, int(data.get("default_actor_cooldown_weeks", DEFAULT_ACTOR_COOLDOWN_WEEKS)))
	_default_aging_per_week = maxi(0, int(data.get("default_aging_per_week", DEFAULT_AGING_PER_WEEK)))
	_opportunity_permille = clampi(int(data.get("opportunity_permille", DEFAULT_OPPORTUNITY_PERMILLE)), 0, 1000)
	_pity_start_weeks = maxi(0, int(data.get("pity_start_weeks", DEFAULT_PITY_START_WEEKS)))
	_pity_step_permille = maxi(0, int(data.get("pity_step_permille", DEFAULT_PITY_STEP_PERMILLE)))
	_weeks_without_optional_event = maxi(0, int(data.get("weeks_without_optional_event", 0)))
	_queue = loaded_queue
	_planned_weeks = _string_key_dictionary(data.get("planned_weeks", {}))
	_occurrence_counts = _nonnegative_int_dictionary(data.get("occurrence_counts", {}))
	_last_id_week = _nonnegative_int_dictionary(data.get("last_id_week", {}))
	_last_family_week = _nonnegative_int_dictionary(data.get("last_family_week", {}))
	_last_actor_week = _nonnegative_int_dictionary(data.get("last_actor_week", {}))
	# Unlike actor/template ID lists, the recent ring is an ordered history. An
	# ignore_recent template may legitimately occur twice before saving, so load
	# must preserve duplicates to keep save/resume byte-for-structure stable.
	_recent_ids = _string_list(data.get("recent_ids", []))
	while _recent_ids.size() > _recent_limit:
		_recent_ids.pop_front()
	for event in _queue:
		_serial = maxi(_serial, int(event.get("_scheduler_sequence", 0)))
	return {"ok": true, "status": "loaded", "state": debug_state()}


func debug_state() -> Dictionary:
	return {
		"seed": _seed,
		"rng_state": _rng_state,
		"current_week": _current_week,
		"serial": _serial,
		"drought": _weeks_without_optional_event,
		"pending_count": _queue.size(),
		"planned_weeks": _planned_weeks.duplicate(true),
		"occurrence_counts": _occurrence_counts.duplicate(true),
		"last_id_week": _last_id_week.duplicate(true),
		"last_family_week": _last_family_week.duplicate(true),
		"last_actor_week": _last_actor_week.duplicate(true),
		"recent_ids": _recent_ids.duplicate(),
	}


func _eligible_candidates(
	total_week: int,
	chapter: int,
	templates: Variant,
	context: Dictionary
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for template in _template_array(templates):
		var eligibility := _template_is_eligible(template, total_week, chapter, context)
		if not bool(eligibility.get("eligible", false)):
			continue
		result.append({
			"template": template,
			"id": str(template.get("id", "")),
			"family": str(template.get("family", template.get("id", ""))),
			"weight": maxi(0, int(round(float(template.get("base_weight", 0))))),
			"actor_ids": eligibility.get("actor_ids", []),
		})
	return result


func _template_is_eligible(
	template: Dictionary,
	total_week: int,
	chapter: int,
	context: Dictionary
) -> Dictionary:
	var event_id := str(template.get("id", "")).strip_edges()
	if event_id.is_empty() or not bool(template.get("enabled", true)):
		return {"eligible": false, "reason": "disabled_or_missing_id"}
	var weight := int(round(float(template.get("base_weight", 0))))
	if weight <= 0:
		return {"eligible": false, "reason": "zero_weight"}
	var chapter_range_value = template.get("chapter_range", [])
	if chapter_range_value is Array and Array(chapter_range_value).size() >= 2:
		var chapter_range: Array = chapter_range_value
		if chapter < int(chapter_range[0]) or chapter > int(chapter_range[1]):
			return {"eligible": false, "reason": "chapter_range"}
	var max_per_run := int(template.get("max_per_run", 1))
	if max_per_run >= 0 and int(_occurrence_counts.get(event_id, 0)) >= max_per_run:
		return {"eligible": false, "reason": "max_per_run"}
	if not bool(template.get("ignore_recent", false)) and _recent_ids.has(event_id):
		return {"eligible": false, "reason": "recent"}
	var cooldown := maxi(0, int(template.get("cooldown_weeks", 0)))
	if _last_id_week.has(event_id) and total_week - int(_last_id_week[event_id]) <= cooldown:
		return {"eligible": false, "reason": "id_cooldown"}
	var family := str(template.get("family", event_id)).strip_edges()
	if family.is_empty():
		family = event_id
	var family_cooldown := maxi(0, int(template.get("family_cooldown_weeks", 0)))
	if _last_family_week.has(family) and total_week - int(_last_family_week[family]) <= family_cooldown:
		return {"eligible": false, "reason": "family_cooldown"}
	var conditions = template.get("conditions", template.get("condition", {}))
	if not _conditions_met(conditions, context):
		return {"eligible": false, "reason": "conditions"}

	var actor_ids := _template_actor_ids(template)
	if not actor_ids.is_empty():
		var actor_cooldown := maxi(0, int(template.get("actor_cooldown_weeks", _default_actor_cooldown_weeks)))
		var available: Array[String] = []
		for actor_id in actor_ids:
			if not _last_actor_week.has(actor_id) or total_week - int(_last_actor_week[actor_id]) > actor_cooldown:
				available.append(actor_id)
		if available.is_empty():
			return {"eligible": false, "reason": "actor_cooldown"}
		actor_ids = available
	return {"eligible": true, "actor_ids": actor_ids}


func _weighted_candidate(candidates: Array[Dictionary]) -> Dictionary:
	var total_weight := 0
	for candidate in candidates:
		total_weight += maxi(0, int(candidate.get("weight", 0)))
	if total_weight <= 0:
		return {}
	var roll := _roll_below(total_weight)
	var cursor := 0
	for candidate in candidates:
		cursor += maxi(0, int(candidate.get("weight", 0)))
		if roll < cursor:
			return candidate.duplicate(true)
	return candidates.back().duplicate(true)


func _effective_opportunity_permille(context: Dictionary) -> int:
	var base := clampi(int(context.get("opportunity_permille", _opportunity_permille)), 0, 1000)
	var pity_start := maxi(0, int(context.get("pity_start_weeks", _pity_start_weeks)))
	var pity_step := maxi(0, int(context.get("pity_step_permille", _pity_step_permille)))
	var pity_steps := maxi(0, _weeks_without_optional_event - pity_start + 1)
	return clampi(base + pity_steps * pity_step, 0, 1000)


func _snapshot_from_template(
	template: Dictionary,
	total_week: int,
	chapter: int,
	actor_id: String,
	context: Dictionary
) -> Dictionary:
	var actor_snapshot := _actor_snapshot(actor_id, context)
	var tokens: Dictionary = {}
	var context_tokens_value = context.get("tokens", {})
	if context_tokens_value is Dictionary:
		for token_key in Dictionary(context_tokens_value):
			tokens[str(token_key)] = str(Dictionary(context_tokens_value)[token_key])
	tokens["total_week"] = str(total_week)
	tokens["chapter"] = str(chapter)
	if not actor_id.is_empty():
		tokens["actor_id"] = actor_id
	for actor_key in actor_snapshot:
		tokens["actor_%s" % str(actor_key)] = str(actor_snapshot[actor_key])
	if actor_snapshot.has("name"):
		tokens["actor_name"] = str(actor_snapshot["name"])

	var materialized_value = _replace_tokens(template.duplicate(true), tokens)
	var snapshot: Dictionary = materialized_value if materialized_value is Dictionary else template.duplicate(true)
	for planning_key in _PLANNING_KEYS:
		snapshot.erase(planning_key)
	if not actor_id.is_empty():
		snapshot["actor_id"] = actor_id
	if not actor_snapshot.is_empty():
		snapshot["actor_snapshot"] = actor_snapshot
	snapshot["materialized_week"] = total_week
	snapshot["materialized_chapter"] = chapter
	return snapshot


func _record_occurrence(event_id: String, family: String, actor_id: String, week: int) -> void:
	_occurrence_counts[event_id] = int(_occurrence_counts.get(event_id, 0)) + 1
	_last_id_week[event_id] = week
	_last_family_week[family] = week
	if not actor_id.is_empty():
		_last_actor_week[actor_id] = week
	if _recent_limit <= 0:
		_recent_ids.clear()
		return
	_recent_ids.append(event_id)
	while _recent_ids.size() > _recent_limit:
		_recent_ids.pop_front()


func _next_due_index(current_week: int) -> int:
	if current_week <= 0:
		return -1
	var selected_index := -1
	var selected_priority := -2147483648
	var selected_due := 2147483647
	var selected_sequence := 2147483647
	for index in _queue.size():
		var event: Dictionary = _queue[index]
		var due_week := int(event.get("_scheduler_due_week", 0))
		if due_week <= 0 or due_week > current_week:
			continue
		var effective := _effective_priority(event, current_week)
		var sequence := int(event.get("_scheduler_sequence", 0))
		if (
			selected_index < 0
			or effective > selected_priority
			or (effective == selected_priority and due_week < selected_due)
			or (effective == selected_priority and due_week == selected_due and sequence < selected_sequence)
		):
			selected_index = index
			selected_priority = effective
			selected_due = due_week
			selected_sequence = sequence
	return selected_index


func _effective_priority(event: Dictionary, current_week: int) -> int:
	var due_week := int(event.get("_scheduler_due_week", current_week))
	var age := maxi(0, current_week - due_week)
	return int(event.get("_scheduler_priority", 0)) + age * maxi(0, int(event.get("_scheduler_aging_per_week", 0)))


func _with_effective_priority(event: Dictionary, current_week: int) -> Dictionary:
	var result := event.duplicate(true)
	result["_scheduler_effective_priority"] = _effective_priority(event, current_week)
	result["_scheduler_age_weeks"] = maxi(0, current_week - int(event.get("_scheduler_due_week", current_week)))
	return result


func _queued_instances_for_planned_week(total_week: int) -> Array[String]:
	var result: Array[String] = []
	for event in _queue:
		if int(event.get("_scheduler_selected_week", -1)) == total_week:
			result.append(str(event.get("_scheduler_instance_id", "")))
	return result


func _template_array(templates: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if templates is Array:
		for value in Array(templates):
			if value is Dictionary:
				result.append(Dictionary(value).duplicate(true))
	elif templates is Dictionary:
		for key in Dictionary(templates):
			var value = Dictionary(templates)[key]
			if not value is Dictionary:
				continue
			var template := Dictionary(value).duplicate(true)
			if str(template.get("id", "")).is_empty():
				template["id"] = str(key)
			result.append(template)
	result.sort_custom(_template_id_less)
	return result


func _template_id_less(left: Dictionary, right: Dictionary) -> bool:
	return str(left.get("id", "")) < str(right.get("id", ""))


func _template_actor_ids(template: Dictionary) -> Array[String]:
	var result := _string_array(template.get("actor_ids", []))
	var single := str(template.get("actor_id", "")).strip_edges()
	if not single.is_empty() and not result.has(single):
		result.append(single)
	result.sort()
	return result


func _actor_snapshot(actor_id: String, context: Dictionary) -> Dictionary:
	if actor_id.is_empty():
		return {}
	var actors_value = context.get("actors", {})
	if actors_value is Dictionary:
		var found = Dictionary(actors_value).get(actor_id, {})
		if found is Dictionary:
			return Dictionary(found).duplicate(true)
	elif actors_value is Array:
		for actor_value in Array(actors_value):
			if actor_value is Dictionary and str(Dictionary(actor_value).get("id", "")) == actor_id:
				return Dictionary(actor_value).duplicate(true)
	return {"id": actor_id}


func _conditions_met(conditions: Variant, context: Dictionary) -> bool:
	if conditions == null:
		return true
	if conditions is bool:
		return bool(conditions)
	if conditions is String:
		var flag := str(conditions).strip_edges()
		if flag.is_empty():
			return true
		if flag.begins_with("not "):
			return not _context_flag(context, flag.trim_prefix("not ").strip_edges())
		return _context_flag(context, flag)
	if conditions is Array:
		for clause in Array(conditions):
			if not _condition_clause_met(clause, context):
				return false
		return true
	if not conditions is Dictionary:
		return false
	var dictionary: Dictionary = conditions
	if dictionary.is_empty():
		return true

	for flag_value in _string_array(dictionary.get("all_flags", [])):
		if not _context_flag(context, flag_value):
			return false
	for flag_value in _string_array(dictionary.get("none_flags", [])):
		if _context_flag(context, flag_value):
			return false
	if dictionary.has("all") and not _conditions_met(dictionary["all"], context):
		return false
	if dictionary.has("any"):
		var any_met := false
		var any_value = dictionary["any"]
		if any_value is Array:
			for clause in Array(any_value):
				if _condition_clause_met(clause, context):
					any_met = true
					break
		else:
			any_met = _condition_clause_met(any_value, context)
		if not any_met:
			return false

	var operator_maps := {
		"equals": "eq", "not_equals": "ne",
		"min": "gte", "gte": "gte", "gt": "gt",
		"max": "lte", "lte": "lte", "lt": "lt",
		"in": "in", "not_in": "not_in",
	}
	for map_key in operator_maps:
		if not dictionary.has(map_key):
			continue
		var values = dictionary[map_key]
		if not values is Dictionary:
			return false
		for path_value in Dictionary(values):
			if not _compare_context_value(context, str(path_value), str(operator_maps[map_key]), Dictionary(values)[path_value]):
				return false

	var known_keys := ["all_flags", "none_flags", "all", "any"]
	known_keys.append_array(operator_maps.keys())
	for key_value in dictionary:
		var key := str(key_value)
		if known_keys.has(key):
			continue
		if not _compare_context_value(context, key, "eq", dictionary[key_value]):
			return false
	return true


func _condition_clause_met(clause: Variant, context: Dictionary) -> bool:
	if clause is String or clause is bool or clause is Array:
		return _conditions_met(clause, context)
	if not clause is Dictionary:
		return false
	var dictionary: Dictionary = clause
	if dictionary.has("path"):
		return _compare_context_value(
			context,
			str(dictionary.get("path", "")),
			str(dictionary.get("op", "eq")),
			dictionary.get("value", true)
		)
	if dictionary.has("flag"):
		return _context_flag(context, str(dictionary["flag"]))
	if dictionary.has("not_flag"):
		return not _context_flag(context, str(dictionary["not_flag"]))
	return _conditions_met(dictionary, context)


func _compare_context_value(context: Dictionary, path: String, operator: String, target: Variant) -> bool:
	var found := _context_lookup(context, path)
	if not bool(found.get("found", false)):
		return false
	var value = found.get("value")
	match operator.to_lower():
		"eq", "==": return value == target
		"ne", "!=": return value != target
		"gte", ">=": return _numeric_compare(value, target, ">=")
		"gt", ">": return _numeric_compare(value, target, ">")
		"lte", "<=": return _numeric_compare(value, target, "<=")
		"lt", "<": return _numeric_compare(value, target, "<")
		"in": return target is Array and Array(target).has(value)
		"not_in": return target is Array and not Array(target).has(value)
		"contains":
			if value is Array:
				return Array(value).has(target)
			return str(value).contains(str(target))
	return false


func _numeric_compare(left: Variant, right: Variant, operator: String) -> bool:
	if typeof(left) not in [TYPE_INT, TYPE_FLOAT] or typeof(right) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var a := float(left)
	var b := float(right)
	match operator:
		">=": return a >= b
		">": return a > b
		"<=": return a <= b
		"<": return a < b
	return false


func _context_lookup(context: Dictionary, path: String) -> Dictionary:
	if path.is_empty():
		return {"found": false}
	var current: Variant = context
	for part_value in path.split(".", false):
		var part := str(part_value)
		if not current is Dictionary or not Dictionary(current).has(part):
			return {"found": false}
		current = Dictionary(current)[part]
	return {"found": true, "value": current}


func _context_flag(context: Dictionary, flag: String) -> bool:
	var flags_value = context.get("flags", {})
	if flags_value is Dictionary:
		return bool(Dictionary(flags_value).get(flag, false))
	if flags_value is Array:
		return Array(flags_value).has(flag)
	return false


func _replace_tokens(value: Variant, tokens: Dictionary) -> Variant:
	if value is String:
		var result := str(value)
		for token_key in tokens:
			result = result.replace("{{%s}}" % str(token_key), str(tokens[token_key]))
		return result
	if value is Array:
		var array: Array = []
		for item in Array(value):
			array.append(_replace_tokens(item, tokens))
		return array
	if value is Dictionary:
		var dictionary: Dictionary = {}
		for key in Dictionary(value):
			dictionary[key] = _replace_tokens(Dictionary(value)[key], tokens)
		return dictionary
	return value


func _advance_rng() -> void:
	_rng_state = int((_rng_state * RNG_MULTIPLIER) % RNG_MODULUS)
	if _rng_state <= 0:
		_rng_state = DEFAULT_SEED


func _roll_below(exclusive_maximum: int) -> int:
	if exclusive_maximum <= 1:
		return 0
	_advance_rng()
	return posmod(_rng_state, exclusive_maximum)


func _normalize_seed(seed: int) -> int:
	var normalized := posmod(seed, RNG_MODULUS)
	return DEFAULT_SEED if normalized <= 0 else normalized


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in Array(value):
			if item is Dictionary:
				result.append(Dictionary(item).duplicate(true))
	return result


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			var text := str(item).strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	elif value is String:
		var text := str(value).strip_edges()
		if not text.is_empty():
			result.append(text)
	return result


func _string_list(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			var text := str(item).strip_edges()
			if not text.is_empty():
				result.append(text)
	elif value is String:
		var text := str(value).strip_edges()
		if not text.is_empty():
			result.append(text)
	return result


func _string_key_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key in Dictionary(value):
			result[str(key)] = Dictionary(value)[key]
	return result


func _nonnegative_int_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key in Dictionary(value):
			result[str(key)] = maxi(0, int(Dictionary(value)[key]))
	return result


func _failure(reason: String) -> Dictionary:
	return {"ok": false, "status": reason, "reason": reason}
