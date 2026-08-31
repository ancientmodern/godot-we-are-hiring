extends SceneTree

const HiringMain = preload("res://src/hiring_main.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ui = HiringMain.new()
	ui.save_path_override = "user://hiring_readability_contract_%d.json" % OS.get_process_id()
	ui.meta_path_override = "user://hiring_readability_contract_meta_%d.json" % OS.get_process_id()
	root.add_child(ui)
	await process_frame

	var contract: Dictionary = ui.ui_readability_contract()
	_test_dashboard_geometry(contract)
	_test_team_geometry(contract)
	_test_opening_geometry(contract)
	_test_shared_safe_areas(contract)
	_test_color_contrast(contract)

	ui.queue_free()
	await process_frame
	if failures.is_empty():
		print("HIRING_UI_READABILITY_CONTRACT_PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_UI_READABILITY_CONTRACT_FAILURE: " + failure)
		quit(1)


func _test_dashboard_geometry(contract: Dictionary) -> void:
	var viewport := Rect2(contract["viewport"])
	var dashboard: Dictionary = contract["dashboard"]
	var surfaces := [
		Rect2(dashboard["main"]), Rect2(dashboard["toolbar"]),
		Rect2(dashboard["detail"]), Rect2(dashboard["stats"]),
	]
	for i in surfaces.size():
		_check(viewport.encloses(surfaces[i]), "dashboard surface %d stays inside the viewport" % i)
		for j in range(i + 1, surfaces.size()):
			_check(not surfaces[i].intersects(surfaces[j]), "dashboard surfaces %d and %d do not overlap" % [i, j])
	_check(Rect2(dashboard["main"]).encloses(Rect2(dashboard["action_list"])), "dashboard action list belongs to its opaque main sheet")
	_check(Rect2(dashboard["detail"]).encloses(Rect2(dashboard["detail_content"])), "dashboard action note belongs to its opaque detail sheet")
	_check(Rect2(dashboard["stats"]).encloses(Rect2(dashboard["stats_content"])), "dashboard stats belong to their own opaque footer")
	_check(not Rect2(dashboard["attention"]).intersects(Rect2(dashboard["end_week"])), "attention indicators never intersect End Week")
	_check(Rect2(dashboard["toolbar"]).encloses(Rect2(dashboard["attention"])), "attention indicators stay inside the command toolbar")
	_check(Rect2(dashboard["toolbar"]).encloses(Rect2(dashboard["end_week"])), "End Week stays inside the command toolbar")


func _test_team_geometry(contract: Dictionary) -> void:
	var viewport := Rect2(contract["viewport"])
	var team: Dictionary = contract["team"]
	var main := Rect2(team["main"])
	var right := Rect2(team["right"])
	_check(viewport.encloses(main) and viewport.encloses(right), "both Team reading sheets stay inside the viewport")
	_check(not main.intersects(right), "Team ledger and evidence sheet do not overlap")
	_check(main.encloses(Rect2(team["table"])), "the complete Team table, status column, and pager stay on the main sheet")
	_check(right.encloses(Rect2(team["org"])), "Team organization summary stays on the right sheet")
	_check(right.encloses(Rect2(team["signals"])), "Team signals and window evidence stay on the right sheet")


func _test_opening_geometry(contract: Dictionary) -> void:
	var viewport := Rect2(contract["viewport"])
	var opening: Dictionary = contract["opening"]
	var surface := Rect2(opening["surface"])
	var body := Rect2(opening["body"])
	var choices: Array = opening["choices"]
	var continue_target := Rect2(opening["continue"])
	var skip_target := Rect2(opening["skip"])
	var minimum_target := float(opening["minimum_target"])

	_check(viewport.encloses(surface), "the complete opening reading sheet stays inside the viewport")
	_check(viewport.encloses(body), "the opening body stays inside the viewport")
	_check(viewport.encloses(continue_target), "the opening Continue target stays inside the viewport")
	_check(viewport.encloses(skip_target), "the opening Skip target stays inside the viewport")
	_check(surface.encloses(body), "the opening body belongs to its opaque reading sheet")
	_check(surface.encloses(continue_target), "the opening Continue target belongs to its opaque reading sheet")
	_check(choices.size() == 3, "the opening contract exposes exactly three response targets")

	# The beat either offers responses or offers Continue; it never offers both,
	# so the copy box is a different height in each case and each case is checked
	# against the controls that are actually on screen with it. Comparing one
	# published rect against every control at once is how a body that ran into its
	# own answer buttons passed for as long as it did.
	var body_with_choices := Rect2(opening["body_with_choices"])
	var body_with_continue := Rect2(opening["body_with_continue"])
	_check(surface.encloses(body_with_choices) and surface.encloses(body_with_continue), "both opening copy boxes belong to the opaque reading sheet")
	_check(not body_with_continue.intersects(continue_target), "the Continue beat's copy stops above its Continue control")
	_check(not body_with_continue.intersects(skip_target), "the Continue beat's copy never reaches Skip")
	_check(not body_with_choices.intersects(skip_target), "the response beat's copy never reaches Skip")

	var choice_regions: Array[Rect2] = [body_with_choices]
	for i in choices.size():
		var choice := Rect2(choices[i])
		_check(viewport.encloses(choice), "opening response target %d stays inside the viewport" % i)
		_check(surface.encloses(choice), "opening response target %d belongs to its opaque reading sheet" % i)
		_check(_meets_minimum_target(choice, minimum_target), "opening response target %d is at least %.0f px on both axes" % [i, minimum_target])
		choice_regions.append(choice)

	_check(_meets_minimum_target(continue_target, minimum_target), "opening Continue is at least %.0f px on both axes" % minimum_target)
	_check(_meets_minimum_target(skip_target, minimum_target), "opening Skip is at least %.0f px on both axes" % minimum_target)
	for i in choice_regions.size():
		for j in range(i + 1, choice_regions.size()):
			_check(not choice_regions[i].intersects(choice_regions[j]), "opening response regions %d and %d do not overlap" % [i, j])


func _test_shared_safe_areas(contract: Dictionary) -> void:
	var viewport := Rect2(contract["viewport"])
	var shared: Dictionary = contract["shared"]
	var office_footer := Rect2(shared["office_footer"])
	var settings_button := Rect2(shared["settings_button"])
	var night_hint := Rect2(shared["night_hint"])
	var toast_max := Rect2(shared["toast_max"])
	var content_header := Rect2(shared["content_header"])
	_check(viewport.encloses(office_footer), "the entire OFFICE footer is visible at 720p")
	_check(office_footer.end.y <= viewport.end.y - 6.0, "the OFFICE footer retains a bottom safe margin")
	_check(not night_hint.intersects(settings_button), "Night controls never sit under the Settings launcher")
	_check(not toast_max.intersects(settings_button), "the widest toast never covers the Settings launcher")
	_check(not toast_max.intersects(content_header), "toasts never cover workspace headings")
	_check(viewport.encloses(toast_max), "the widest toast stays inside the viewport")


func _test_color_contrast(contract: Dictionary) -> void:
	var colors: Dictionary = contract["colors"]
	var paper := Color(colors["paper"])
	for key in ["ink", "muted", "paper_green", "paper_blue", "paper_amber"]:
		var ratio := _contrast_ratio(Color(colors[key]), paper)
		_check(ratio >= 4.5, "%s text keeps 4.5:1 contrast on reading paper (%.2f:1)" % [key, ratio])
	var disabled_ratio := _contrast_ratio(Color(colors["disabled_text"]), Color(colors["disabled_bg"]))
	_check(disabled_ratio >= 4.5, "disabled labels remain readable (%.2f:1)" % disabled_ratio)
	var sidebar_ratio := _contrast_ratio(Color(colors["sidebar_meta"]), Color(colors["sidebar"]))
	_check(sidebar_ratio >= 4.5, "sidebar metadata remains readable (%.2f:1)" % sidebar_ratio)
	_check(Color(colors["scrim"]).a >= 0.82, "settings scrim visually retires the underlying controls")


func _contrast_ratio(foreground: Color, background: Color) -> float:
	var foreground_luminance := _relative_luminance(foreground)
	var background_luminance := _relative_luminance(background)
	return (maxf(foreground_luminance, background_luminance) + 0.05) / (minf(foreground_luminance, background_luminance) + 0.05)


func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)


func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)


func _meets_minimum_target(rect: Rect2, minimum: float) -> bool:
	return rect.size.x >= minimum and rect.size.y >= minimum


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
