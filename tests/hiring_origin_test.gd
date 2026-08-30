extends SceneTree

## Contract for the origin system: three ways of arriving at the same garage
## door. The rules this file enforces come from what makes background systems
## fail elsewhere — a prologue that is unequal between paths, a background that
## turns out to be cosmetic after the prologue, and a head start that levelling
## quietly erases.

const HiringContent = preload("res://src/hiring_content.gd")
const HiringModel = preload("res://src/hiring_model.gd")
const CampaignDirector = preload("res://src/hiring_director.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_origin_registry()
	_test_prologues_are_equal_in_length_and_kind()
	_test_shared_past_is_reframed_not_duplicated()
	_test_origin_survives_persistence()
	_test_permanent_rule_does_not_wash_out()
	_test_authored_options_are_exclusive()
	_test_every_origin_option_costs_something()

	if failures.is_empty():
		print("HIRING_ORIGIN_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_ORIGIN_TEST_FAILURE: " + failure)
		quit(1)


func _test_origin_registry() -> void:
	_check(HiringContent.ORIGIN_ORDER.size() == 3, "there are exactly three origins")
	_check(HiringContent.ORIGINS.has(HiringContent.DEFAULT_ORIGIN), "the default origin exists in the registry")
	var names: Array[String] = []
	for origin_id in HiringContent.ORIGIN_ORDER:
		var origin: Dictionary = HiringContent.get_origin(origin_id)
		for key in ["name", "headline", "detail", "rule_title", "rule", "lin", "prologue", "history_lines"]:
			_check(origin.has(key) and not str(origin.get(key, "")).is_empty(), "origin %s declares `%s`" % [origin_id, key])
		_check(str(origin.get("name", "")).length() <= 8, "origin %s has an index-tab-sized name" % origin_id)
		names.append(str(origin.get("name", "")))
	_check(names.size() == names.size(), "origin names are populated")
	var unique_names := {}
	for name in names:
		unique_names[name] = true
	_check(unique_names.size() == 3, "no two origins share a name")


func _test_prologues_are_equal_in_length_and_kind() -> void:
	# Unequal prologues are the most-reported reason a background system reads as
	# unfair: whichever path is shortest is the one that feels unfinished.
	var lengths: Array[int] = []
	for origin_id in HiringContent.ORIGIN_ORDER:
		var prologue: Dictionary = HiringContent.origin_prologue(origin_id)
		_check(str(prologue.get("origin", "")) == str(origin_id), "prologue for %s declares its origin" % origin_id)
		var phases: Array = prologue.get("phases", [])
		lengths.append(phases.size())
		_check(phases.size() >= 5, "prologue %s is a scene, not a splash screen" % origin_id)
		var choice_beats := 0
		var response_ids := {}
		for phase_value in phases:
			var phase: Dictionary = phase_value
			_check(not str(phase.get("id", "")).is_empty(), "every prologue beat has an id")
			_check(not str(phase.get("title", "")).is_empty(), "every prologue beat has a title")
			_check(not Array(phase.get("body", [])).is_empty(), "every prologue beat has body copy")
			_check(not str(phase.get("place", "")).is_empty(), "every prologue beat says where it is")
			var responses: Array = phase.get("responses", [])
			if not responses.is_empty():
				choice_beats += 1
				_check(not str(phase.get("memory_key", "")).is_empty(), "a prologue beat with responses records them")
				for response_value in responses:
					var response_id := "%s:%s" % [str(phase.get("id", "")), str(Dictionary(response_value).get("id", ""))]
					_check(not response_ids.has(response_id), "prologue response ids are unique (%s)" % response_id)
					response_ids[response_id] = true
					_check(not str(Dictionary(response_value).get("label", "")).is_empty(), "every prologue response has a label")
			var variant_key := str(phase.get("variant_memory_key", ""))
			if not variant_key.is_empty():
				var variants: Dictionary = phase.get("body_variants", {})
				_check(variants.size() >= 2, "a variant beat carries a line for more than one earlier answer")
		_check(choice_beats >= 2, "prologue %s asks the player something at least twice" % origin_id)
		var last_phase: Dictionary = phases[phases.size() - 1]
		_check(bool(last_phase.get("complete", false)), "prologue %s ends on a completing beat" % origin_id)
		_check(bool(last_phase.get("lin", false)), "every prologue ends with Lin's message, at the same door")
	var shortest: int = int(lengths.min())
	var longest: int = int(lengths.max())
	_check(longest - shortest <= 2, "no prologue is meaningfully longer than another (%d..%d beats)" % [shortest, longest])


func _test_shared_past_is_reframed_not_duplicated() -> void:
	# The garage is mandatory content that means something different per origin.
	# That is cheaper than exclusive scenes and reads as deeper than dialogue tags.
	var garage: Dictionary = HiringContent.get_fixed_event(0, 1)
	var name_reply := {}
	for phase_value in Array(garage.get("opening_phases", [])):
		if str(Dictionary(phase_value).get("id", "")) == "name_reply":
			name_reply = phase_value
			break
	_check(not name_reply.is_empty(), "the garage still owns the shared-past beat")
	_check(Array(name_reply.get("body", [])).has("{{lin_history}}"), "the shared-past beat defers to the origin instead of hardcoding one past")
	var seen := {}
	for origin_id in HiringContent.ORIGIN_ORDER:
		var history: Array = HiringContent.get_origin(origin_id).get("history_lines", [])
		_check(history.size() >= 2, "origin %s writes its own shared past" % origin_id)
		var joined := "\n".join(PackedStringArray(history))
		_check(not seen.has(joined), "no two origins share the same past verbatim")
		seen[joined] = true


func _test_origin_survives_persistence() -> void:
	for origin_id in HiringContent.ORIGIN_ORDER:
		var model = HiringModel.new()
		model.origin_id = str(origin_id)
		model.reset("Origin Contract Labs")
		_check(str(model.origin_id) == str(origin_id), "reset keeps the chosen origin")
		var restored = HiringModel.new()
		_check(restored.from_save(model.to_save()), "an origin campaign round-trips through save")
		_check(str(restored.origin_id) == str(origin_id), "the origin survives save and load")
		_check(str(restored.public_state().get("origin_id", "")) == str(origin_id), "the origin is published to the presentation layer")
	var legacy = HiringModel.new()
	var legacy_payload: Dictionary = HiringModel.new().to_save()
	legacy_payload.erase("origin_id")
	_check(legacy.from_save(legacy_payload), "a save written before origins existed still loads")
	_check(str(legacy.origin_id) == HiringContent.DEFAULT_ORIGIN, "a pre-origin save loads as the default origin")


func _test_permanent_rule_does_not_wash_out() -> void:
	# A starting number is gone by week ten and is then read, correctly, as
	# nothing. The one economic origin rule has to still be doing work at week
	# forty, so it is asserted at both ends.
	var plain = HiringModel.new()
	plain.origin_id = "bigco"
	plain.reset("Burn Contract A")
	var funded = HiringModel.new()
	funded.origin_id = "funded"
	funded.reset("Burn Contract B")
	_check(is_equal_approx(plain.origin_weekly_burn_multiplier(), 1.0), "the default origin does not change the weekly rule")
	_check(funded.origin_weekly_burn_multiplier() < 1.0, "the funded origin burns slower every week")
	_check(is_equal_approx(plain.cash_weeks, funded.cash_weeks), "no origin starts with a cash head start instead of a rule")
	var plain_runway := int(plain.public_state().get("runway_weeks", 0))
	var funded_runway := int(funded.public_state().get("runway_weeks", 0))
	_check(funded_runway > plain_runway, "the rule is visible in the runway figure from week one (%d vs %d)" % [plain_runway, funded_runway])
	# Both campaigns are given a runway long enough to survive the full forty-five
	# weeks, so the comparison measures the rule rather than measuring zero.
	plain.cash_weeks = 90.0
	funded.cash_weeks = 90.0
	for _week in 45:
		plain.cash_weeks = maxf(0.0, plain.cash_weeks - maxf(HiringModel.MIN_WEEKLY_BURN, 1.0 * plain.origin_weekly_burn_multiplier()))
		funded.cash_weeks = maxf(0.0, funded.cash_weeks - maxf(HiringModel.MIN_WEEKLY_BURN, 1.0 * funded.origin_weekly_burn_multiplier()))
	_check(funded.cash_weeks - plain.cash_weeks >= 6.0, "forty-five weeks later the rule has compounded into most of a chapter (%.1f weeks)" % (funded.cash_weeks - plain.cash_weeks))


func _test_authored_options_are_exclusive() -> void:
	var gated := {}
	for event_key in ["1:4", "2:6", "3:7"]:
		var parts: PackedStringArray = event_key.split(":")
		var event: Dictionary = HiringContent.get_fixed_event(int(parts[0]), int(parts[1]))
		for choice_value in Array(event.get("choices", [])):
			var choice: Dictionary = choice_value
			var condition := str(choice.get("condition", ""))
			if condition.begins_with("origin =="):
				var owner: String = str(condition.split("==")[1]).strip_edges()
				gated[owner] = int(gated.get(owner, 0)) + 1
	for origin_id in HiringContent.ORIGIN_ORDER:
		_check(int(gated.get(str(origin_id), 0)) >= 1, "origin %s owns at least one authored option on a mandatory scene" % origin_id)
	var total := 0
	for owner in gated:
		total += int(gated[owner])
	_check(total >= 5, "the origins together own enough authored options to be scored as real (%d)" % total)

	for origin_id in HiringContent.ORIGIN_ORDER:
		var director = CampaignDirector.new()
		director.start_company("Origin Option Labs", false)
		director.model.origin_id = str(origin_id)
		var prepared: Dictionary = director.prepare_event(HiringContent.get_fixed_event(1, 4))
		var offered: Array[String] = []
		for choice_value in Array(prepared.get("choices", [])):
			offered.append(str(Dictionary(choice_value).get("id", "")))
		_check(offered.has("origin_%s" % origin_id), "%s is offered its own option at the first investor meeting" % origin_id)
		for other_id in HiringContent.ORIGIN_ORDER:
			if str(other_id) == str(origin_id):
				continue
			_check(not offered.has("origin_%s" % other_id), "%s is never offered %s's option" % [origin_id, other_id])


func _test_every_origin_option_costs_something() -> void:
	# A background that only unlocks things reads as a key. One that can also cost
	# you something reads as a person. "Cost" here means either a stat the option
	# spends — debt and author weight count as spending, not earning — or a stat
	# some ordinary sibling option gets more of.
	var spends_when_positive := ["debt", "author_weight", "burn_rate"]
	for event_key in ["1:4", "2:6", "3:7"]:
		var parts: PackedStringArray = event_key.split(":")
		var event: Dictionary = HiringContent.get_fixed_event(int(parts[0]), int(parts[1]))
		var siblings: Array[Dictionary] = []
		for sibling_value in Array(event.get("choices", [])):
			if not str(Dictionary(sibling_value).get("condition", "")).begins_with("origin =="):
				siblings.append(sibling_value)
		for choice_value in Array(event.get("choices", [])):
			var choice: Dictionary = choice_value
			if not str(choice.get("condition", "")).begins_with("origin =="):
				continue
			var choice_id := str(choice.get("id", ""))
			var effects: Dictionary = choice.get("effects", {})
			var has_cost := false
			for effect_key in effects:
				var amount := float(effects[effect_key])
				if amount < 0.0 or (amount > 0.0 and str(effect_key) in spends_when_positive):
					has_cost = true
					break
			if not has_cost:
				# No stat spent: then an ordinary option must beat it somewhere, so
				# the origin route is never simply the best answer available.
				for axis in ["cash_weeks", "narrative"]:
					for sibling in siblings:
						if float(Dictionary(sibling.get("effects", {})).get(axis, 0.0)) > float(effects.get(axis, 0.0)):
							has_cost = true
							break
					if has_cost:
						break
			_check(has_cost, "origin option `%s` on %s is not strictly the best answer in the room" % [choice_id, event_key])
			_check(not Array(choice.get("result", [])).is_empty(), "origin option `%s` is a scene, not a stat change" % choice_id)
			_check(not bool(choice.get("ai", false)), "origin options are things the founder does personally")


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
