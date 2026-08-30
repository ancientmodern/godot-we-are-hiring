extends SceneTree

const ExpansionContent = preload("res://src/hiring_expansion_content.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_system_actions()
	_test_event_registry()
	_test_tone_and_trigger_alignment()
	if failures.is_empty():
		print("HIRING_EXPANSION_CONTENT_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_EXPANSION_CONTENT_TEST_FAILURE: " + failure)
		quit(1)


func _test_system_actions() -> void:
	_check(ExpansionContent.SYSTEM_ACTIONS.size() == 6, "the first operating slice has six strategic actions")
	for action_id_value in ExpansionContent.SYSTEM_ACTIONS:
		var action_id := str(action_id_value)
		var action: Dictionary = ExpansionContent.SYSTEM_ACTIONS[action_id]
		_check(str(action.get("id", "")) == action_id, "%s keeps a stable action id" % action_id)
		_check(str(action.get("category", "")) == "strategy", "%s belongs to the operating strategy lane" % action_id)
		_check(int(action.get("attention", 0)) == 1, "%s spends the shared founder attention" % action_id)
		_check(action.has("manual_summary") and action.has("ai_summary"), "%s explains both execution routes" % action_id)


func _test_event_registry() -> void:
	var templates := ExpansionContent.event_templates()
	_check(templates.size() >= 36, "the first overlay pool contains at least thirty-six systemic decisions")
	_check(templates.size() == 53, "the authored pool keeps thirty-nine core and fourteen decision-worthy industry echoes")
	_check(templates.size() == ExpansionContent.event_template_count(), "the reported template count matches the registry")
	var ids: Dictionary = {}
	var families: Dictionary = {}
	var actor_events := 0
	for event_value in templates:
		var event: Dictionary = event_value
		var event_id := str(event.get("id", ""))
		_check(not event_id.is_empty(), "every systemic event has an id")
		_check(not ids.has(event_id), "%s is unique" % event_id)
		ids[event_id] = true
		var family := str(event.get("family", ""))
		families[family] = int(families.get(family, 0)) + 1
		_check(str(event.get("channel", "")) == "side_decision", "%s uses the overlay decision channel" % event_id)
		_check(int(event.get("weight", 0)) > 0, "%s has positive scheduling weight" % event_id)
		_check(int(event.get("cooldown_weeks", 0)) >= 5, "%s cannot immediately repeat" % event_id)
		_check(bool(event.get("once_per_run", false)), "%s is a one-run story beat" % event_id)
		_check(bool(event.get("_company_system_event", false)), "%s routes through a domain system" % event_id)
		_check(event.has("max_chapter"), "%s declares a final relevant chapter" % event_id)
		_check(int(event.get("max_chapter", 0)) >= int(event.get("min_chapter", 99)), "%s has a valid chapter window" % event_id)
		_check(Array(event.get("chapter_range", [])).size() == 2, "%s exports a scheduler chapter range" % event_id)
		_check(int(Array(event.get("chapter_range", [0, 0]))[1]) == int(event.get("max_chapter", -1)), "%s scheduler range honors max_chapter" % event_id)
		_check(event.get("conditions", null) is Dictionary and not Dictionary(event.get("conditions", {})).is_empty(), "%s declares state-aware conditions" % event_id)
		_check(event.get("prerequisites", null) is Array and not Array(event.get("prerequisites", [])).is_empty(), "%s documents its systemic prerequisites" % event_id)
		_check(Array(event.get("tone_tags", [])).has("grounded"), "%s stays in the grounded house tone" % event_id)
		var actors: Array = Array(event.get("actors", []))
		if not actors.is_empty():
			actor_events += 1
		var choices: Array = Array(event.get("choices", []))
		_check(choices.size() == 3, "%s presents exactly three legible tradeoffs" % event_id)
		var has_delegate := false
		for choice_value in choices:
			var choice: Dictionary = choice_value
			_check(not str(choice.get("label", "")).is_empty(), "%s has a labeled choice" % event_id)
			_check(Array(choice.get("result", [])).size() > 0, "%s choice has authored aftermath" % event_id)
			if str(choice.get("id", "")) == "delegate":
				has_delegate = true
				_check(bool(choice.get("ai", false)), "%s delegation is marked as AI-authored" % event_id)
				_check(float(Dictionary(choice.get("effects", {})).get("author_weight", 0.0)) > 0.0, "%s delegation transfers authorship" % event_id)
		if not Array(event.get("tone_tags", [])).has("industry_echo"):
			_check(has_delegate, "%s preserves the central delegation route" % event_id)
	for required_family in ["capital", "market", "people", "org", "office", "saas", "policy"]:
		_check(int(families.get(required_family, 0)) > 0, "%s has authored systemic events" % required_family)
	_check(actor_events == templates.size(), "every systemic decision is attached to a persistent actor")


func _test_tone_and_trigger_alignment() -> void:
	var templates := ExpansionContent.event_templates()
	var by_id: Dictionary = {}
	var earned_delight_count := 0
	for event_value in templates:
		var event: Dictionary = event_value
		by_id[str(event.get("id", ""))] = event
		if Array(event.get("tone_tags", [])).has("earned_delight"):
			earned_delight_count += 1
	var delight_ratio := float(earned_delight_count) / float(templates.size())
	_check(delight_ratio >= 0.30 and delight_ratio <= 0.40, "thirty to forty percent of events carry an earned delight beat")

	var preseed: Dictionary = by_id["preseed_safe_terms"]
	_check(int(preseed.get("max_chapter", 4)) == 1, "pre-seed terms cannot drift into a late campaign chapter")
	_check(Array(Dictionary(preseed.get("conditions", {})).get("none_flags", [])).has("has_preseed"), "pre-seed terms disappear after pre-seed closes")
	var option_pool: Dictionary = by_id["option_pool_shuffle"]
	_check(Array(Dictionary(option_pool.get("conditions", {})).get("all_flags", [])).has("has_preseed"), "seed option-pool negotiation waits for pre-seed")
	_check(Array(Dictionary(option_pool.get("conditions", {})).get("none_flags", [])).has("has_seed"), "seed option-pool negotiation disappears after seed")
	var counteroffer_gate: Dictionary = Dictionary(by_id["candidate_counteroffer"].get("conditions", {})).get("gte", {})
	_check(int(counteroffer_gate.get("operations.active_offers", 0)) == 1, "candidate counteroffer waits for a live negotiable offer rather than any active interview")

	var service_gates := {
		"ci_usage_overage": "subscribed_forgenest_team",
		"vendor_outage_demo": "subscribed_signalharbor_observe",
		"automatic_renewal": "subscribed_quietwire_annual",
		"vendor_acquisition": "subscribed_signalharbor_observe",
	}
	for event_id_value in service_gates:
		var event_id := str(event_id_value)
		var flags: Array = Array(Dictionary(by_id[event_id].get("conditions", {})).get("all_flags", []))
		_check(flags.has(str(service_gates[event_id])), "%s requires its actual catalog subscription" % event_id)
	_check(Array(Dictionary(by_id["dormant_seat_audit"].get("conditions", {})).get("all_flags", [])).has("has_saas"), "seat audit requires at least one active SaaS service")

	var employee_gates := {
		"promotion_calibration": "employee_chen_xiaoyu_active",
		"mentor_burnout": "employee_guo_jun_active",
		"key_person_poach": "employee_chen_xiaoyu_active",
	}
	for event_id_value in employee_gates:
		var event_id := str(event_id_value)
		var flags: Array = Array(Dictionary(by_id[event_id].get("conditions", {})).get("all_flags", []))
		_check(flags.has(str(employee_gates[event_id])), "%s requires the named employee to be active" % event_id)
	_check(Array(Dictionary(by_id["office_shortlist"].get("conditions", {})).get("none_flags", [])).has("has_active_lease"), "office shortlist only appears before a lease")
	for office_event_id in ["fitout_delay", "meeting_room_capacity", "office_hvac", "sublease_opportunity"]:
		var flags: Array = Array(Dictionary(by_id[office_event_id].get("conditions", {})).get("all_flags", []))
		_check(flags.has("has_active_lease"), "%s requires a signed or active lease" % office_event_id)

	var complete_text := _event_text(templates)
	for catalog_name in ["QuietWire", "ForgeNest", "SignalHarbor", "StaffLoom"]:
		_check(complete_text.contains(catalog_name), "SaaS copy uses catalog vendor %s" % catalog_name)
	for retired_name in ["Keyring Cloud", "Relay Docs", "Forge CI", "TraceHarbor"]:
		_check(not complete_text.contains(retired_name), "retired placeholder vendor %s is absent" % retired_name)
	var grant_text := _event_text([by_id["rnd_grant_phase_one"]])
	_check(grant_text.contains("$200k") and grant_text.contains("$75k"), "grant copy matches the $200k award and $75k first tranche")
	_check(not grant_text.contains("$275k"), "grant copy no longer advertises a stale award amount")
	var pilot_text := _event_text([by_id["government_pilot"]])
	_check(pilot_text.contains("$250k"), "government pilot copy matches the $250k contract")
	_check(not pilot_text.contains("$420k"), "government pilot copy no longer advertises a stale contract value")


func _event_text(events: Array) -> String:
	var pieces: Array[String] = []
	for event_value in events:
		var event: Dictionary = event_value
		pieces.append(str(event.get("title", "")))
		pieces.append(str(event.get("kicker", "")))
		for line in Array(event.get("body", [])):
			pieces.append(str(line))
		for choice_value in Array(event.get("choices", [])):
			var choice: Dictionary = choice_value
			pieces.append(str(choice.get("label", "")))
			for line in Array(choice.get("result", [])):
				pieces.append(str(line))
	return "\n".join(pieces)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
