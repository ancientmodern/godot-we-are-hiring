extends SceneTree

const EchoContent = preload("res://src/hiring_industry_echo_content.gd")
const ExpansionContent = preload("res://src/hiring_expansion_content.gd")
const HiringModel = preload("res://src/hiring_model.gd")
const CampaignDirector = preload("res://src/hiring_director.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_catalog_contract()
	_test_editorial_distance()
	_test_live_resolution()
	_test_ambient_delivery()
	_test_pacing_filter()
	if failures.is_empty():
		print("HIRING_INDUSTRY_ECHO_CONTENT_TESTS_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_INDUSTRY_ECHO_CONTENT_TEST_FAILURE: " + failure)
		quit(1)


func _test_catalog_contract() -> void:
	var events: Array[Dictionary] = EchoContent.event_templates()
	var decisions: Array[Dictionary] = EchoContent.interactive_event_templates()
	var ambient: Array[Dictionary] = EchoContent.ambient_templates()
	var register: Dictionary = EchoContent.source_register()
	_check(events.size() == 18, "industry echo pack contains eighteen fictional mutations")
	_check(events.size() == EchoContent.event_template_count(), "industry echo count matches its registry")
	_check(decisions.size() == 14 and decisions.size() == EchoContent.interactive_event_count(), "fourteen allusions earn a full operating decision")
	_check(ambient.size() == 4 and ambient.size() == EchoContent.ambient_template_count(), "four allusions remain interruption-free comic vignettes")
	_check(register.size() == 18, "each allusion category has an editorial source note")
	var ids: Dictionary = {}
	var seen_references: Dictionary = {}
	var families: Dictionary = {}
	var regions: Dictionary = {}
	var earned_delight_count := 0
	var valence_counts: Dictionary = {}
	var interaction_modes: Dictionary = {}
	var ai_route_count := 0
	for event in events:
		var event_id := str(event.get("id", ""))
		_check(not event_id.is_empty() and not ids.has(event_id), "%s has a unique stable id" % event_id)
		ids[event_id] = true
		_check(bool(event.get("fictionalized", false)), "%s is explicitly fictionalized" % event_id)
		_check(Array(event.get("tone_tags", [])).has("industry_echo"), "%s is tagged as an optional industry allusion" % event_id)
		_check(Array(event.get("tone_tags", [])).has("grounded"), "%s retains the grounded house tone" % event_id)
		_check(Array(event.get("tone_tags", [])).has("satirical_fiction"), "%s is allowed to exaggerate beyond its factual seed" % event_id)
		var valence := str(event.get("valence", ""))
		valence_counts[valence] = int(valence_counts.get(valence, 0)) + 1
		interaction_modes[str(event.get("interaction_mode", ""))] = true
		_check(int(event.get("comic_intensity", 0)) in range(1, 6), "%s declares a bounded comic intensity" % event_id)
		_check(Array(event.get("actor_ids", [])).has("industry_echo_lane") and int(event.get("actor_cooldown_weeks", 0)) == 4, "%s shares the four-week anti-spam lane" % event_id)
		if Array(event.get("tone_tags", [])).has("earned_delight"):
			earned_delight_count += 1
		families[str(event.get("family", ""))] = true
		var references: Array = Array(event.get("reference_tags", []))
		_check(not references.is_empty(), "%s declares its inspiration category" % event_id)
		for reference_value in references:
			var reference_id := str(reference_value)
			seen_references[reference_id] = true
			_check(register.has(reference_id), "%s resolves reference tag %s" % [event_id, reference_id])
			if register.has(reference_id):
				var note: Dictionary = register[reference_id]
				var region := str(note.get("region", ""))
				regions[region] = int(regions.get(region, 0)) + 1
				_check(not str(note.get("editorial_note", "")).is_empty(), "%s documents its adaptation boundary" % reference_id)
		if str(event.get("delivery", "decision")) == "decision":
			var choices: Array = Array(event.get("choices", []))
			_check(choices.size() == 3, "%s presents three operating tradeoffs" % event_id)
			var effect_signatures: Dictionary = {}
			for choice_value in choices:
				var choice: Dictionary = choice_value
				effect_signatures[JSON.stringify(choice.get("effects", {}))] = true
				_check(not str(choice.get("label", "")).is_empty(), "%s has no unlabeled punchline button" % event_id)
				_check(not Array(choice.get("result", [])).is_empty(), "%s carries its joke into a concrete aftermath" % event_id)
				if bool(choice.get("ai", false)):
					ai_route_count += 1
			_check(effect_signatures.size() == 3, "%s choices have materially different effect profiles" % event_id)
	_check(families.size() >= 6, "industry humor lives across market, capital, people, org, office, and SaaS surfaces")
	_check(earned_delight_count == 6, "six events pay off with earned delight while the rest stay dry and observational")
	_check(valence_counts == {"positive": 4, "comic_relief": 4, "dilemma": 6, "crisis": 4}, "tone mix balances four rewards, four vignettes, six dilemmas, and four crises")
	_check(interaction_modes.size() == 4, "reward, vignette, tradeoff, and containment use distinct interaction roles")
	_check(ai_route_count == 5, "AI delegation appears only in five contextually relevant industry decisions")
	for item in ambient:
		_check(not item.has("choices") and not item.has("effects"), "%s is pure ambient copy with no hidden decision or penalty" % str(item.get("id", "ambient")))
		_check(str(item.get("meta", "")).contains("不占用注意力"), "%s labels its interruption-free delivery" % str(item.get("id", "ambient")))
	var expansion_ids := _by_id(ExpansionContent.event_templates())
	for item in ambient:
		_check(not expansion_ids.has(str(item.get("id", ""))), "%s never enters the modal event scheduler" % str(item.get("id", "ambient")))
	for required_region in ["us", "china", "traditional", "global"]:
		_check(int(regions.get(required_region, 0)) > 0, "reference register covers %s startup culture" % required_region)
	_check(seen_references.size() == register.size(), "every researched reference category reaches playable copy")


func _test_editorial_distance() -> void:
	var events: Array[Dictionary] = EchoContent.event_templates()
	var player_text := _player_text(events)
	for direct_name in ["OpenAI", "Anthropic", "Corgi", "DeepSeek", "Sam Altman", "Dario Amodei", "梁文锋", "GPT-5"]:
		_check(not player_text.contains(direct_name), "player-facing copy fictionalizes %s instead of name-dropping" % direct_name)
	_check(not player_text.contains("强制纹身") and not player_text.contains("每个员工都纹"), "mascot event does not turn a participation anecdote into a mandatory-tattoo claim")
	var by_id := _by_id(events)
	var slider_text := _player_text([by_id["honorific_release_slider"]])
	_check(slider_text.contains("社区") and slider_text.contains("神 / 圣 / 全名 / 牢"), "honorific slider is clearly framed as a community release-cycle meme")
	var pricing_text := _player_text([by_id["accidental_catfish_price_war"], by_id["million_tokens_milk_tea"]])
	_check(pricing_text.contains("缓存") and pricing_text.contains("完整工作流"), "price-war jokes land on real unit economics rather than a floating slogan")
	var safety_text := _player_text([by_id["doom_and_dilution"]])
	_check(safety_text.contains("两位数概率") and safety_text.contains("P(dilution)"), "safety rhetoric is paired with a playable governance and dilution tension")


func _test_live_resolution() -> void:
	var events: Array[Dictionary] = EchoContent.interactive_event_templates()
	var by_id := _by_id(events)
	for event in events:
		for choice_value in Array(event.get("choices", [])):
			var choice: Dictionary = choice_value
			var isolated_game = HiringModel.new()
			var isolated_result: Dictionary = isolated_game.resolve_systemic_event(event, str(choice.get("id", "")))
			_check(bool(isolated_result.get("ok", false)) and bool(isolated_result.get("industry_echo_logged", false)), "%s / %s resolves against isolated live state" % [str(event.get("id", "")), str(choice.get("id", ""))])
	var game = HiringModel.new()
	var price_before := int(game.business.market.get("price_pressure_bp", 0))
	var feed_before := Array(game.business.market.get("public_feed", [])).size()
	var market_result: Dictionary = game.resolve_systemic_event(by_id["accidental_catfish_price_war"], "hold_value")
	_check(bool(market_result.get("ok", false)) and bool(market_result.get("industry_echo_logged", false)), "market allusion resolves through the live company system")
	_check(int(game.business.market.get("price_pressure_bp", 0)) == maxi(7_000, price_before - 350), "price-war echo applies real shared-market pressure")
	_check(Array(game.business.market.get("public_feed", [])).size() == feed_before + 1, "market allusion becomes an operating-ledger signal")
	var last_echo: Dictionary = Dictionary(game.memory.get("last_industry_echo", {}))
	_check(str(last_echo.get("id", "")) == "accidental_catfish_price_war" and str(last_echo.get("choice_label", "")) == "守住价格，承诺服务等级", "announcement memory records the actual player response")
	var invalid: Dictionary = game.resolve_systemic_event(by_id["ten_x_interview"], "make_them_ceo")
	_check(not bool(invalid.get("ok", true)) and str(invalid.get("reason", "")) == "invalid_industry_echo_choice", "industry event resolver rejects an invented punchline choice")


func _test_ambient_delivery() -> void:
	var game = HiringModel.new()
	game.flags["expansion_systems_unlocked"] = true
	game.chapter = 3
	game.week_in_chapter = 2
	game.total_week = 21
	game.attention = 2
	var business_before: Dictionary = game.business.to_save()
	var operations_before: Dictionary = game.operations.to_save()
	var actions_before: Array = game.performed_actions.duplicate()
	game.call("_tick_industry_ambient_echo")
	var feed: Array = Array(game.memory.get("industry_ambient_feed", []))
	_check(feed.size() == 1, "eligible week emits one ambient industry vignette")
	_check(game.attention == 2 and game.performed_actions == actions_before, "ambient vignette consumes no attention or action slot")
	_check(game.business.to_save() == business_before and game.operations.to_save() == operations_before, "ambient vignette cannot mutate market, cash, people, or procurement state")
	game.call("_tick_industry_ambient_echo")
	_check(Array(game.memory.get("industry_ambient_feed", [])).size() == 1, "same-week ambient emission is idempotent")
	game.total_week = 23
	game.call("_tick_industry_ambient_echo")
	var next_feed: Array = Array(game.memory.get("industry_ambient_feed", []))
	_check(next_feed.size() == 2 and str(Dictionary(next_feed[0]).get("id", "")) != str(Dictionary(next_feed[1]).get("id", "")), "later eligible week rotates to a new vignette without scheduler RNG")
	game.chapter = 4
	game.week_in_chapter = 6
	game.total_week = 24
	game.call("_tick_industry_ambient_echo")
	_check(Array(game.memory.get("industry_ambient_feed", [])).size() == 2, "final authored silence suppresses ambient jokes")


func _test_pacing_filter() -> void:
	var director = CampaignDirector.new()
	director.model.memory["last_industry_echo_valence"] = "crisis"
	var paced: Array[Dictionary] = director.call("_paced_systemic_event_templates")
	var echo_count := 0
	var core_count := 0
	for event in paced:
		if Array(event.get("tone_tags", [])).has("industry_echo"):
			echo_count += 1
			_check(str(event.get("valence", "")) == "positive", "%s cannot follow a crisis unless it is a positive recovery" % str(event.get("id", "echo")))
		else:
			core_count += 1
	_check(echo_count == 4 and core_count == 39, "crisis recovery filter preserves all core events and the four positive echoes")


func _by_id(events: Array) -> Dictionary:
	var result: Dictionary = {}
	for event_value in events:
		if event_value is Dictionary:
			var event: Dictionary = event_value
			result[str(event.get("id", ""))] = event
	return result


func _player_text(events: Array) -> String:
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
