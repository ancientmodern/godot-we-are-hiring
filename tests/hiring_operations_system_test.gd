extends SceneTree

const Operations = preload("res://src/hiring_operations_system.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_api_and_authored_content()
	_test_interview_determinism_and_save_rng()
	_test_offer_notice_and_pending_join_boundary()
	_test_focus_candidate_lifecycle_and_role_integrity()
	_test_people_organization_and_training()
	_test_office_capacity_and_fitout()
	_test_saas_billing_and_provisioning()
	_test_commitments_burn_and_public_save()
	_test_events_are_read_only()
	if failures.is_empty():
		print("HIRING_OPERATIONS_SYSTEM_TESTS_PASS: %d assertions" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_OPERATIONS_SYSTEM_TEST_FAILURE: " + failure)
		print("HIRING_OPERATIONS_SYSTEM_TESTS_FAIL: %d failures / %d assertions" % [failures.size(), checks])
		quit(1)


func _test_api_and_authored_content() -> void:
	var operations = Operations.new(90210)
	for method_name in [
		"public_state", "to_save", "from_save", "tick_week", "apply_decision",
		"event_candidates", "sync_employee_roster", "consume_pending_joins",
		"candidate_dossier", "offer_acceptance_score", "manager_span",
		"office_capacity", "office_capacity_plan_pending", "provision_user", "deprovision_user",
		"subscription_weekly_cost", "burn_summary", "active_employee_count",
	]:
		_check(operations.has_method(method_name), "public API exposes %s" % method_name)
	_check(Operations.CANDIDATE_TEMPLATES.size() == 8, "exactly eight authored launch candidates are available")
	var names: Dictionary = {}
	var employers: Dictionary = {}
	for candidate_id_value in Operations.CANDIDATE_TEMPLATES:
		var candidate_id := str(candidate_id_value)
		var dossier := operations.candidate_dossier(candidate_id)
		_check(str(dossier.get("id", "")) == candidate_id, "%s has a stable dossier id" % candidate_id)
		for required_key in [
			"name", "current_company", "current_title", "years_experience", "location",
			"skill_evidence", "unknowns", "confidence", "salary_target",
			"equity_target_bps", "notice_weeks", "competing_offer", "deadline_week",
		]:
			_check(dossier.has(required_key), "%s dossier includes %s" % [candidate_id, required_key])
		_check(Array(dossier.get("skill_evidence", [])).size() >= 2, "%s has concrete skill evidence" % candidate_id)
		_check(Array(dossier.get("unknowns", [])).size() >= 2, "%s begins with explicit unknowns" % candidate_id)
		_check(float(Dictionary(dossier.get("confidence", {})).get("overall", 0.0)) < 0.5, "%s starts with low confidence" % candidate_id)
		_check(float(dossier.get("salary_target", 0.0)) > 0.0, "%s has a salary target" % candidate_id)
		_check(float(dossier.get("equity_target_bps", 0.0)) > 0.0, "%s has an equity target" % candidate_id)
		_check(int(dossier.get("notice_weeks", 0)) >= 2, "%s has a plausible notice period" % candidate_id)
		var competitor: Dictionary = dossier.get("competing_offer", {})
		_check(not str(competitor.get("company", "")).is_empty(), "%s has a named competing company" % candidate_id)
		_check(float(competitor.get("salary", 0.0)) > 0.0, "%s has concrete competing salary" % candidate_id)
		_check(int(competitor.get("deadline_week", 0)) == -1, "%s has no live deadline before activation" % candidate_id)
		_check(int(competitor.get("deadline_window_weeks", 0)) > 0, "%s retains an authored competing-offer window" % candidate_id)
		_check(not bool(competitor.get("deadline_materialized", true)), "%s deadline is explicitly unmaterialized while available" % candidate_id)
		_check(not names.has(str(dossier.get("name", ""))), "%s has a unique authored name" % candidate_id)
		names[str(dossier.get("name", ""))] = true
		employers[str(dossier.get("current_company", ""))] = true
		for protected_key in Operations.PROTECTED_ATTRIBUTE_KEYS:
			_check(not dossier.has(str(protected_key)), "%s public dossier excludes protected field %s" % [candidate_id, protected_key])
	_check(employers.size() >= 7, "candidate market spans distinct fictional employers")
	var authored_text := JSON.stringify(Operations.CANDIDATE_TEMPLATES) + JSON.stringify(Operations.SAAS_CATALOG)
	for real_brand in ["Slack", "GitHub", "AWS", "Google", "Notion", "Figma", "Greenhouse"]:
		_check(authored_text.findn(real_brand) < 0, "authored operations content excludes real brand %s" % real_brand)
	_check(not bool(operations.apply_decision("unknown_operation").get("ok", true)), "unknown decisions fail explicitly")


func _test_interview_determinism_and_save_rng() -> void:
	var left = Operations.new(7331)
	var right = Operations.new(7331)
	var open_payload := {
		"id": "req_infra", "role_family": "infrastructure", "team_id": "founders",
		"level": 3, "salary_band": [45.0, 70.0], "equity_band_bps": [8.0, 30.0],
		"candidate_ids": ["zhou_cen"],
	}
	var open_left := left.apply_decision("open_requisition", open_payload)
	var open_right := right.apply_decision("open_requisition", open_payload)
	_check(bool(open_left.get("ok", false)), "first deterministic requisition opens")
	_check(open_left == open_right, "same seed and input produce the same requisition pipeline")
	var before := left.candidate_dossier("zhou_cen")
	var screen_left := left.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": "screen"})
	var screen_right := right.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": "screen"})
	_check(screen_left == screen_right, "same seed produces identical screen results")
	var after_screen := left.candidate_dossier("zhou_cen")
	_check(float(Dictionary(after_screen.get("confidence", {})).get("overall", 0.0)) > float(Dictionary(before.get("confidence", {})).get("overall", 0.0)), "screen raises dossier confidence")
	_check(Array(after_screen.get("unknowns", [])).size() == Array(before.get("unknowns", [])).size() - 1, "screen resolves one explicit unknown")
	_check(Array(after_screen.get("interview_notes", [])).size() == 1, "screen records a concrete interview quote and score")
	var checkpoint: Dictionary = left.to_save()
	var restored = Operations.new(1)
	_check(restored.from_save(checkpoint), "valid checkpoint restores")
	_check(restored.rng_state == left.rng_state, "checkpoint restores independent RNG state")
	var work_left := left.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": "work_sample"})
	var work_restored := restored.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": "work_sample"})
	_check(work_left == work_restored, "restored RNG continues the exact interview sequence")
	_check(restored.rng_state == left.rng_state, "continued RNG states remain identical")
	var panel_left := left.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": "panel"})
	var panel_restored := restored.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": "panel"})
	_check(panel_left == panel_restored, "restored RNG also reproduces the panel")
	var final_dossier := left.candidate_dossier("zhou_cen")
	_check(Array(final_dossier.get("unknowns", [])).is_empty(), "full loop resolves all authored unknowns")
	_check(Array(final_dossier.get("revealed_evidence", [])).size() == 2, "work sample and panel reveal both evidence records")
	_check(Dictionary(final_dossier.get("scorecard_results", {})).size() == 4, "full loop completes the structured four-item scorecard")
	_check(float(Dictionary(final_dossier.get("confidence", {})).get("overall", 0.0)) == 0.88, "panel reaches the authored confidence ceiling")
	_check(not bool(left.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": "panel"}).get("ok", true)), "duplicate interview stages are rejected")
	var invalid = Operations.new()
	_check(not invalid.from_save({"save_version": 999}), "unknown save versions are rejected")


func _test_offer_notice_and_pending_join_boundary() -> void:
	var operations = Operations.new(44)
	_fully_interview(operations, "zhou_cen", "infrastructure", "req_offer")
	var generous_terms := {
		"candidate_id": "zhou_cen", "salary": 100.0, "equity_bps": 40.0,
		"level": 4, "title": "首席平台工程师", "team_id": "founders",
		"allow_out_of_band": true,
	}
	var ideal_context := {"company_credibility": 1.0, "manager_quality": 1.0, "role_scope": 1.0}
	var score_before := operations.offer_acceptance_score("zhou_cen", generous_terms, ideal_context)
	Dictionary(operations.candidates["zhou_cen"])["age"] = 61
	Dictionary(operations.candidates["zhou_cen"])["gender"] = "non_decision_test"
	var score_after := operations.offer_acceptance_score("zhou_cen", generous_terms, ideal_context)
	_check(is_equal_approx(score_before, score_after), "protected attributes cannot influence offer scoring")
	_check(score_before >= 0.78, "fully competitive package reaches deterministic acceptance tier")
	var issued := operations.apply_decision("issue_offer", generous_terms, ideal_context)
	_check(bool(issued.get("ok", false)), "structured offer is issued after all interviews")
	_check(str(Dictionary(issued.get("offer", {})).get("status", "")) == "pending", "offer begins pending")
	_check(operations.active_employee_count() == 0, "issuing an offer never creates a formal employee")
	var resolved := operations.tick_week({"week": 2})
	_check(bool(resolved.get("ok", false)), "response week advances")
	_check(str(Dictionary(operations.offers[0]).get("status", "")) == "accepted", "competitive offer accepts deterministically")
	_check(operations.scheduled_joins.size() == 1, "accepted offer enters notice-period schedule")
	_check(operations.pending_joins.is_empty(), "accepted hire is not ready before notice ends")
	_check(operations.active_employee_count() == 0, "accepted hire still does not mutate the formal roster")
	var expected_start := 2 + int(operations.candidate_dossier("zhou_cen").get("notice_weeks", 0))
	_check(int(Dictionary(operations.scheduled_joins[0]).get("start_week", -1)) == expected_start, "join schedule honors the exact notice period")
	operations.tick_week({"week": expected_start - 1})
	_check(operations.pending_joins.is_empty(), "join stays scheduled through the final notice week")
	operations.tick_week({"week": expected_start})
	_check(operations.scheduled_joins.is_empty(), "due join leaves the notice schedule")
	_check(operations.pending_joins.size() == 1, "due join is exposed through pending_joins")
	_check(operations.active_employee_count() == 0, "pending join remains outside the formal roster")
	var pending := operations.consume_pending_joins()
	_check(pending.size() == 1, "owner can consume one pending join exactly once")
	_check(operations.pending_joins.is_empty(), "consumption clears pending join output")
	_check(str(operations.candidate_dossier("zhou_cen").get("status", "")) == "hired", "join consumption atomically marks the candidate hired")
	_check(str(operations.candidate_dossier("zhou_cen").get("requisition_id", "stale")) == "", "hired candidate leaves the requisition funnel")
	_check(str(Dictionary(operations.requisitions[0]).get("status", "")) == "filled", "join consumption atomically settles the requisition as filled")
	_check(str(Dictionary(operations.requisitions[0]).get("focus_candidate_id", "stale")) == "", "filled requisition has no live focus cursor")
	_check(Array(operations.public_state().get("candidate_pipeline", [])).is_empty(), "consumed hire is absent from the public candidate funnel")
	_check(str(Dictionary(pending[0]).get("requisition_id", "")) == "req_offer", "consumed record exposes its settled requisition")
	_check(int(Dictionary(pending[0]).get("consumed_week", -1)) == expected_start, "consumed record exposes its atomic settlement week")
	var hire_record: Dictionary = Dictionary(pending[0]).get("employee", {})
	_check(str(hire_record.get("id", "")).begins_with("hire_"), "pending join contains a stable formal-roster payload")
	_check(float(hire_record.get("ramp", 1.0)) < 1.0, "new hire begins partially ramped")
	_check(int(hire_record.get("onboarding_weeks_remaining", 0)) == 2, "new hire includes concrete onboarding duration")
	operations.sync_employee_roster([hire_record], expected_start)
	_check(operations.active_employee_count() == 1, "formal employee appears only after owner roster sync")
	_check(float(Dictionary(operations.employees[hire_record["id"]]).get("salary_annual", 0.0)) == 100.0, "formal sync preserves accepted salary")
	_check(float(Dictionary(operations.employees[hire_record["id"]]).get("equity_bps", 0.0)) == 40.0, "formal sync preserves accepted equity")
	operations.tick_week({"week": expected_start + 2})
	_check(float(Dictionary(operations.employees[hire_record["id"]]).get("ramp", 0.0)) == 1.0, "two onboarding weeks complete ramp")

	var rejection = Operations.new(45)
	_fully_interview(rejection, "qiao_nian", "research", "req_reject")
	var weak_terms := {"candidate_id": "qiao_nian", "salary": 1.0, "equity_bps": 0.0, "allow_out_of_band": true}
	var weak_context := {"company_credibility": 0.0, "manager_quality": 0.0, "role_scope": 0.0}
	var weak_offer := rejection.apply_decision("issue_offer", weak_terms, weak_context)
	_check(bool(weak_offer.get("ok", false)), "out-of-band path can express a deliberately weak offer")
	_check(float(Dictionary(weak_offer.get("offer", {})).get("acceptance_score", 1.0)) <= 0.15, "weak offer lands below random acceptance range")
	rejection.tick_week({"week": 2})
	_check(str(Dictionary(rejection.offers[0]).get("status", "")) == "rejected", "noncompetitive offer rejects deterministically")
	_check(str(rejection.candidate_dossier("qiao_nian").get("status", "")) == "released", "rejected candidate enters a timed release cooldown")
	_check(rejection.scheduled_joins.is_empty() and rejection.pending_joins.is_empty(), "rejected offer creates no join record")


func _test_focus_candidate_lifecycle_and_role_integrity() -> void:
	var operations = Operations.new(52)
	var backup: Dictionary = Dictionary(operations.candidates["zhou_cen"]).duplicate(true)
	backup["id"] = "zhou_backup"
	backup["name"] = "周岑·备选"
	operations.candidates["zhou_backup"] = backup
	var opened := operations.apply_decision("open_requisition", {
		"id": "req_focus", "role_family": "infrastructure", "candidate_ids": ["qiao_nian", "zhou_cen", "zhou_backup"],
		"salary_band": [1.0, 100.0], "equity_band_bps": [0.0, 100.0],
	})
	_check(bool(opened.get("ok", false)), "focus-candidate requisition opens")
	var selected: Array = opened.get("candidate_ids", [])
	_check(selected.size() == 2, "strict matching keeps only the two infrastructure candidates and never pads to three")
	_check(not selected.has("qiao_nian"), "explicitly requested wrong-role candidate is rejected from the pipeline")
	for selected_id_value in selected:
		var selected_id := str(selected_id_value)
		_check(str(operations.candidate_dossier(selected_id).get("role_family", "")) == "infrastructure", "%s is an exact requisition role match" % selected_id)
	_check(str(opened.get("focus_candidate_id", "")) == "zhou_cen", "requested matching candidate becomes the sole focus")
	_check(str(operations.candidate_dossier("zhou_cen").get("status", "")) == "in_process", "focus candidate enters process")
	_check(str(operations.candidate_dossier("zhou_backup").get("status", "")) == "shortlisted", "backup remains shortlisted")
	_check(int(operations.candidate_dossier("zhou_backup").get("deadline_week", 0)) == -1, "shortlisted backup has no materialized deadline")
	_check(not bool(operations.candidate_dossier("zhou_backup").get("deadline_materialized", true)), "backup explicitly reports an unmaterialized deadline")
	_check(not bool(operations.apply_decision("interview_candidate", {"candidate_id": "zhou_backup", "stage": "screen"}).get("ok", true)), "backup cannot interview ahead of the focus candidate")
	for stage in Operations.INTERVIEW_STAGES:
		_check(bool(operations.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": stage}).get("ok", false)), "focus candidate completes %s" % stage)
	var weak_offer := operations.apply_decision("issue_offer", {
		"candidate_id": "zhou_cen", "salary": 1.0, "equity_bps": 0.0, "allow_out_of_band": true,
	}, {"company_credibility": 0.0, "manager_quality": 0.0, "role_scope": 0.0})
	_check(bool(weak_offer.get("ok", false)), "focus candidate receives a deliberately rejectable offer")
	var rejected_tick := operations.tick_week({"week": 2})
	_check(str(operations.candidate_dossier("zhou_cen").get("status", "")) == "released", "rejected focus enters cooldown")
	_check(int(operations.candidate_dossier("zhou_cen").get("available_after_week", -1)) == 2 + Operations.RELEASED_CANDIDATE_COOLDOWN_WEEKS, "release materializes the exact market cooldown")
	_check(str(operations.candidate_dossier("zhou_backup").get("status", "")) == "in_process", "rejection activates the next shortlisted candidate")
	_check(str(Dictionary(operations.requisitions[0]).get("focus_candidate_id", "")) == "zhou_backup", "requisition focus advances atomically")
	_check(bool(operations.candidate_dossier("zhou_backup").get("deadline_materialized", false)), "new focus materializes its deadline only on activation")
	_check(int(operations.candidate_dossier("zhou_backup").get("deadline_week", -1)) > 2, "new focus receives a future actionable deadline")
	_check(_outcome_kinds(Array(rejected_tick.get("outcomes", []))).has("candidate_focus_activated"), "tick reports the focus transition structurally")
	operations.tick_week({"week": 4})
	_check(str(operations.candidate_dossier("zhou_cen").get("status", "")) == "released", "candidate remains unavailable before cooldown boundary")
	var return_tick := operations.tick_week({"week": 5})
	_check(str(operations.candidate_dossier("zhou_cen").get("status", "")) == "available", "released candidate returns exactly after cooldown")
	_check(_outcome_kinds(Array(return_tick.get("outcomes", []))).has("candidate_returned_to_market"), "market return is emitted as a structured outcome")

	var invalid = Operations.new(53)
	var invalid_backup: Dictionary = Dictionary(invalid.candidates["zhou_cen"]).duplicate(true)
	invalid_backup["id"] = "zhou_invalid_backup"
	invalid_backup["name"] = "周岑·失效备选"
	invalid.candidates["zhou_invalid_backup"] = invalid_backup
	var invalid_open := invalid.apply_decision("open_requisition", {
		"id": "req_invalid", "role_family": "infrastructure", "candidate_ids": ["zhou_cen", "zhou_invalid_backup"],
		"salary_band": [1.0, 100.0], "equity_band_bps": [0.0, 100.0],
	})
	_check(bool(invalid_open.get("ok", false)), "invalid-offer fixture opens")
	for stage in Operations.INTERVIEW_STAGES:
		invalid.apply_decision("interview_candidate", {"candidate_id": "zhou_cen", "stage": stage})
	invalid.apply_decision("issue_offer", {"candidate_id": "zhou_cen", "salary": 60.0, "equity_bps": 20.0})
	invalid.candidates.erase("zhou_cen")
	var invalid_tick := invalid.tick_week({"week": 2})
	_check(str(invalid.candidate_dossier("zhou_invalid_backup").get("status", "")) == "in_process", "invalidated focus activates the next valid backup")
	_check(_outcome_kinds(Array(invalid_tick.get("outcomes", []))).has("offer_invalid"), "missing offer subject is reported as invalid")


func _test_people_organization_and_training() -> void:
	var operations = Operations.new(88)
	var roster: Array = [_employee("lead", "林照", 4, 82.0, "delivery", "", {"management": 2.0, "engineering": 8.0})]
	for index in range(1, 7):
		roster.append(_employee("report_%d" % index, "成员%d" % index, 2, 42.0 + index, "delivery", "lead", {"engineering": 6.0 + index * 0.1}))
	var sync := operations.sync_employee_roster(roster, 1)
	_check(bool(sync.get("ok", false)), "seven-person roster sync succeeds")
	_check(int(sync.get("active_count", 0)) == 7, "roster owns exactly seven formal employees")
	var span := operations.manager_span("lead")
	_check(int(span.get("direct_reports", 0)) == 6, "manager span counts six direct reports")
	_check(int(span.get("capacity", 0)) == 4, "management skill produces a four-report capacity")
	_check(int(span.get("overload", 0)) == 2, "span exposes two-report overload")
	_check(_event_ids(operations.event_candidates()).has("manager_overload:lead"), "manager overload emits a concrete organization event")
	var team_result := operations.apply_decision("create_team", {"id": "platform", "name": "平台组", "manager_id": "lead"})
	_check(bool(team_result.get("ok", false)), "new organization team can be created")
	var cycle := operations.apply_decision("set_manager", {"employee_id": "lead", "manager_id": "report_1"})
	_check(not bool(cycle.get("ok", true)) and str(cycle.get("reason", "")) == "manager_cycle", "manager hierarchy rejects reporting cycles")
	var transfer := operations.apply_decision("transfer_employee", {"employee_id": "report_1", "team_id": "platform", "ramp_weeks": 2})
	_check(bool(transfer.get("ok", false)), "employee transfer succeeds")
	_check(str(Dictionary(operations.employees["report_1"]).get("team_id", "")) == "platform", "transfer updates employee team")
	_check(float(Dictionary(operations.employees["report_1"]).get("ramp", 1.0)) == 0.65, "transfer applies a visible reramp cost")
	_check(_membership_count(operations.teams, "report_1") == 1, "transfer keeps exactly one team membership")
	_check(operations.active_employee_count() == 7, "transfer neither creates nor removes employees")
	var skill_before := float(Dictionary(Dictionary(operations.employees["report_1"]).get("skills", {})).get("engineering", 0.0))
	var mentor_burnout_before := float(Dictionary(operations.employees["lead"]).get("burnout", 0.0))
	var training := operations.apply_decision("start_training", {
		"employee_id": "report_1", "skill_id": "engineering", "mentor_id": "lead",
		"duration_weeks": 2, "gain": 1.0, "weekly_cost": 0.08,
	})
	_check(bool(training.get("ok", false)), "concrete two-week training begins")
	_check(float(Dictionary(operations.employees["lead"]).get("burnout", 0.0)) == mentor_burnout_before + 3.0, "mentorship has an immediate burnout load")
	_check(is_equal_approx(float(operations.burn_summary().get("training", 0.0)), 0.08), "active training contributes weekly burn")
	operations.tick_week({"week": 2})
	_check(str(Dictionary(operations.trainings[0]).get("status", "")) == "active", "training remains active after week one")
	operations.tick_week({"week": 3})
	_check(str(Dictionary(operations.trainings[0]).get("status", "")) == "complete", "training completes after the exact duration")
	var skill_after := float(Dictionary(Dictionary(operations.employees["report_1"]).get("skills", {})).get("engineering", 0.0))
	_check(is_equal_approx(skill_after, skill_before + 1.0), "training applies the configured skill gain")
	_check(is_zero_approx(float(operations.burn_summary().get("training", 1.0))), "completed training leaves weekly burn")
	var promotion := operations.apply_decision("promote_employee", {"employee_id": "report_1", "salary": 55.0, "equity_refresh_bps": 2.0})
	_check(bool(promotion.get("ok", false)), "one-level promotion succeeds")
	_check(int(Dictionary(operations.employees["report_1"]).get("level", 0)) == 3, "promotion raises level by exactly one")
	_check(float(Dictionary(operations.employees["report_1"]).get("salary_annual", 0.0)) == 55.0, "promotion records exact salary")
	_check(float(Dictionary(operations.employees["report_1"]).get("equity_bps", 0.0)) == 2.0, "promotion records equity refresh")


func _test_office_capacity_and_fitout() -> void:
	var operations = Operations.new(99)
	var roster: Array = []
	for index in range(9):
		roster.append(_employee("office_%d" % index, "工位%d" % index, 1, 36.0, "founders", "", {"operations": 6.0}))
	operations.sync_employee_roster(roster, 1)
	var signed := operations.apply_decision("sign_office_lease", {"lease_id": "harbor_desk"})
	_check(bool(signed.get("ok", false)), "coworking lease signs")
	_check(operations.office_capacity() == 8, "lease exposes eight fitted seats")
	_check(int(Dictionary(signed.get("lease", {})).get("legal_capacity", 0)) == 10, "lease distinguishes fitted and legal capacity")
	_check(is_equal_approx(float(signed.get("cash_due", 0.0)), 0.6), "lease charges exact deposit upfront")
	_check(_event_ids(operations.event_candidates()).has("office_over_capacity"), "nine people against eight seats emits capacity event")
	var fitout := operations.apply_decision("start_fitout", {"fitout_id": "flex_desks"})
	_check(bool(fitout.get("ok", false)), "capacity fitout begins")
	_check(is_equal_approx(float(fitout.get("cash_due", 0.0)), 0.9), "coworking fitout charges exact uncovered cost")
	_check(operations.office_capacity() == 8, "in-progress fitout does not grant capacity early")
	_check(operations.office_capacity_plan_pending(), "capacity-positive fitout is recognized as an active crowding plan")
	_check(not _event_ids(operations.event_candidates()).has("office_over_capacity"), "in-progress capacity work suppresses a duplicate crowding modal")
	operations.tick_week({"week": 2})
	_check(operations.office_capacity() == 14, "completed fitout adds six seats")
	_check(not _event_ids(operations.event_candidates()).has("office_over_capacity"), "fitout clears over-capacity event")
	_check(Array(operations.office.get("completed_fitouts", [])).size() == 1, "office retains completed fitout record")
	_check(_commitment_kinds(operations.commitments).has("lease"), "office lease appears in commitments")

	var upgrade = Operations.new(101)
	var canal := upgrade.apply_decision("sign_office_lease", {"lease_id": "canal_sublease"})
	_check(bool(canal.get("ok", false)), "chapter-two canal sublease signs")
	_check(is_equal_approx(float(canal.get("cash_due", 0.0)), 2.4), "canal signing pays the exact deposit")
	_check(upgrade.office_capacity() == 0, "future canal lease grants no capacity before move-in")
	upgrade.tick_week({"week": 2})
	_check(str(Dictionary(upgrade.office.get("active_lease", {})).get("id", "")) == "canal_sublease", "canal becomes active on its move-in week")
	var upgrade_roster: Array = []
	for index in range(25):
		upgrade_roster.append(_employee("upgrade_%d" % index, "扩张%d" % index, 1, 36.0, "founders", "", {"operations": 6.0}))
	upgrade.sync_employee_roster(upgrade_roster, 2)
	_check(_event_ids(upgrade.event_candidates()).has("office_over_capacity"), "one person beyond canal capacity raises a crowding decision before a plan exists")
	var replacement := upgrade.apply_decision("replace_office_lease", {"lease_id": "frostline_works"})
	_check(bool(replacement.get("ok", false)), "chapter-three frostline expansion lease signs against an active lease")
	_check(is_equal_approx(float(replacement.get("cash_due", 0.0)), 6.0), "replacement returns the exact deposit cash due")
	_check(str(Dictionary(upgrade.office.get("active_lease", {})).get("id", "")) == "canal_sublease", "old canal office remains active during the move window")
	_check(str(Dictionary(upgrade.office.get("signed_lease", {})).get("id", "")) == "frostline_works", "future frostline office is tracked as a signed commitment")
	_check(upgrade.office_capacity_plan_pending(), "signed larger replacement is recognized as the durable capacity plan")
	_check(not _event_ids(upgrade.event_candidates()).has("office_over_capacity"), "signed replacement suppresses repeated buy-the-same-solution capacity modals")
	_check(_commitment_count(upgrade.commitments, "lease") == 2, "ledger carries both incumbent and signed replacement leases")
	upgrade.tick_week({"week": 4})
	_check(upgrade.office_capacity() == 24, "old office capacity remains authoritative before replacement move-in")
	var move_tick := upgrade.tick_week({"week": 5})
	_check(str(Dictionary(upgrade.office.get("active_lease", {})).get("id", "")) == "frostline_works", "frostline atomically replaces canal on move-in")
	_check(upgrade.office_capacity() == 48, "replacement switches to frostline capacity")
	_check(Dictionary(upgrade.office.get("signed_lease", {})).is_empty(), "signed replacement slot clears after move-in")
	_check(str(Dictionary(Array(upgrade.office.get("lease_history", []))[0]).get("status", "")) == "replaced", "old canal lease is retained as replaced history")
	_check(_outcome_kinds(Array(move_tick.get("outcomes", []))).has("office_move_in"), "replacement tick reports a structural move-in outcome")


func _test_saas_billing_and_provisioning() -> void:
	var operations = Operations.new(109)
	var roster_two := [
		_employee("saas_a", "甲", 2, 52.0, "founders", "", {"product": 7.0}),
		_employee("saas_b", "乙", 3, 78.0, "founders", "", {"engineering": 8.0}),
	]
	operations.sync_employee_roster(roster_two, 1)
	var forge := operations.apply_decision("subscribe_saas", {"service_id": "forgenest_team"})
	_check(bool(forge.get("ok", false)), "fictional code SaaS subscribes")
	_check(Array(Dictionary(operations.subscriptions["forgenest_team"]).get("assigned_users", [])).size() == 2, "auto-provision assigns active roster")
	_check_close(operations.subscription_weekly_cost("forgenest_team"), 0.054, "two users still bill the three-seat minimum")
	var roster_four := roster_two.duplicate(true)
	roster_four.append(_employee("saas_c", "丙", 1, 40.0, "founders", "", {"design": 6.0}))
	roster_four.append(_employee("saas_d", "丁", 1, 40.0, "founders", "", {"sales": 6.0}))
	operations.sync_employee_roster(roster_four, 1)
	_check(Array(Dictionary(operations.subscriptions["forgenest_team"]).get("assigned_users", [])).size() == 4, "new formal employees auto-provision")
	_check_close(operations.subscription_weekly_cost("forgenest_team"), 0.072, "four seats bill four units")
	operations.sync_employee_roster(roster_two, 1)
	_check(Array(Dictionary(operations.subscriptions["forgenest_team"]).get("assigned_users", [])).size() == 2, "departed employees deprovision automatically")
	_check_close(operations.subscription_weekly_cost("forgenest_team"), 0.054, "deprovision falls back to contractual minimum")
	var manual := operations.provision_user("forgenest_team", "contractor_x")
	_check(bool(manual.get("ok", false)), "explicit provisioning supports a contractor seat")
	_check(Array(Dictionary(operations.subscriptions["forgenest_team"]).get("assigned_users", [])).has("contractor_x"), "explicit seat is recorded")
	operations.deprovision_user("forgenest_team", "contractor_x")
	_check(not Array(Dictionary(operations.subscriptions["forgenest_team"]).get("assigned_users", [])).has("contractor_x"), "explicit deprovision removes seat")

	var observe := operations.apply_decision("subscribe_saas", {"service_id": "signalharbor_observe"})
	_check(bool(observe.get("ok", false)), "fictional usage SaaS subscribes")
	_check_close(operations.subscription_weekly_cost("signalharbor_observe"), 0.12, "usage plan enforces minimum weekly spend")
	var usage := operations.apply_decision("report_saas_usage", {"service_id": "signalharbor_observe", "usage": 140.0})
	_check(bool(usage.get("ok", false)), "usage meter accepts weekly consumption")
	_check_close(operations.subscription_weekly_cost("signalharbor_observe"), 0.13, "usage plan charges base plus forty overage units")
	_check(_event_ids(operations.event_candidates()).has("saas_overage:signalharbor_observe"), "usage overage emits vendor-risk event")

	var annual := operations.apply_decision("subscribe_saas", {"service_id": "quietwire_annual"})
	_check(bool(annual.get("ok", false)), "fictional annual collaboration SaaS subscribes")
	_check_close(float(annual.get("weekly_normalized", 0.0)), 0.06, "annual plan normalizes five-seat minimum to weekly burn")
	_check_close(float(annual.get("cash_due", 0.0)), 3.12, "annual plan prepays fifty-two normalized weeks")
	_check_close(float(Dictionary(annual.get("cash_outlay", {})).get("amount", 0.0)), 3.12, "annual purchase returns its one-time cash outlay record")
	_check(str(Dictionary(annual.get("cash_outlay", {})).get("pnl_treatment", "")) == "straight_line_amortization", "annual cash record labels its accrual treatment")
	_check_close(float(Dictionary(annual.get("pnl", {})).get("weekly_expense", 0.0)), 0.06, "annual purchase separately exposes weekly P&L recognition")
	_check_close(float(Dictionary(annual.get("commitment", {})).get("renewal_cash_estimate", 0.0)), 3.12, "annual purchase exposes its next renewal cash estimate")
	var cancel := operations.apply_decision("cancel_saas", {"service_id": "quietwire_annual"})
	_check(bool(cancel.get("ok", false)), "annual plan can turn off renewal")
	_check(str(Dictionary(operations.subscriptions["quietwire_annual"]).get("status", "")) == "non_renewing", "annual cancellation is deferred to paid-term end")
	_check(not bool(Dictionary(operations.subscriptions["quietwire_annual"]).get("auto_renew", true)), "annual cancellation clears the automatic renewal commitment")
	_check_close(operations.subscription_weekly_cost("quietwire_annual"), 0.06, "paid annual access remains in normalized burn until term end")
	var hris := operations.apply_decision("subscribe_saas", {"service_id": "staffloom_core"})
	_check(bool(hris.get("ok", false)), "fictional HRIS subscribes")
	_check_close(operations.subscription_weekly_cost("staffloom_core"), 0.25, "HRIS applies ten-seat contractual minimum")
	_check(_commitment_kinds(operations.commitments).has("subscription"), "subscriptions emit commitments")

	var renewal = Operations.new(111)
	var renewable := renewal.apply_decision("subscribe_saas", {"service_id": "quietwire_annual", "auto_renew": true})
	_check(bool(renewable.get("ok", false)), "annual auto-renew fixture subscribes")
	_check(bool(Dictionary(renewable.get("commitment", {})).get("committed", false)), "annual decision exposes an active auto-renew commitment")
	var renewal_tick := renewal.tick_week({"week": 53})
	_check(_outcome_kinds(Array(renewal_tick.get("outcomes", []))).has("subscription_renewed"), "renewal tick emits a structured renewal")
	_check_close(float(renewal_tick.get("cash_outlay_total", 0.0)), 3.12, "renewal tick separates the exact prepaid cash movement")
	_check(Array(renewal_tick.get("cash_outlays", [])).size() == 1, "renewal tick exposes one auditable cash record")
	var renewal_outlay: Dictionary = Array(renewal_tick.get("cash_outlays", []))[0]
	_check(str(renewal_outlay.get("kind", "")) == "subscription_renewal_prepayment", "renewal cash record identifies its economic cause")
	_check_close(float(renewal_outlay.get("normalized_weekly_expense", 0.0)), 0.06, "renewal cash record retains the P&L normalization")
	_check_close(float(Dictionary(renewal_tick.get("pnl_expense", {})).get("saas_weekly", 0.0)), 0.06, "tick P&L remains weekly rather than expensing the prepayment")
	_check(Array(renewal_tick.get("commitment_changes", [])).size() == 1, "tick separately reports the auto-renew commitment change")
	_check(int(Dictionary(renewal.subscriptions["quietwire_annual"]).get("renewal_week", -1)) == 105, "renewal advances the contractual term exactly fifty-two weeks")
	_check_close(float(Dictionary(renewal.subscriptions["quietwire_annual"]).get("cash_paid_to_date", 0.0)), 6.24, "subscription accumulates signing and renewal cash paid")
	var annual_commitment := _commitment_by_id(renewal.commitments, "subscription:quietwire_annual")
	_check(Dictionary(annual_commitment.get("cash_payment_schedule", {})).has("next_payment_estimate"), "commitment ledger exposes future cash schedule")
	_check(str(Dictionary(annual_commitment.get("pnl_recognition", {})).get("treatment", "")) == "straight_line_amortization", "commitment ledger exposes annual P&L treatment")
	_check(bool(Dictionary(annual_commitment.get("renewal", {})).get("auto_renew", false)), "commitment ledger preserves automatic renewal state")


func _test_commitments_burn_and_public_save() -> void:
	var operations = Operations.new(120)
	operations.sync_employee_roster([
		_employee("burn_a", "薪甲", 2, 52.0, "founders", "", {"product": 7.0}),
		_employee("burn_b", "薪乙", 3, 78.0, "founders", "", {"engineering": 8.0}),
	], 1)
	operations.apply_decision("sign_office_lease", {"lease_id": "harbor_desk"})
	operations.apply_decision("subscribe_saas", {"service_id": "forgenest_team"})
	var burn := operations.burn_summary()
	_check_close(float(burn.get("payroll", 0.0)), 2.5, "burn itemizes weekly payroll")
	_check_close(float(burn.get("benefits", 0.0)), 0.45, "burn itemizes eighteen-percent benefits load")
	_check_close(float(burn.get("lease", 0.0)), 0.42, "burn itemizes active lease")
	_check_close(float(burn.get("saas", 0.0)), 0.054, "burn itemizes SaaS")
	_check_close(float(burn.get("total_weekly", 0.0)), 3.424, "weekly total reconciles all detailed lines")
	_check_close(float(burn.get("cash_due_this_week", 0.0)), 0.6, "cash view separates lease deposit from normalized burn")
	var kinds := _commitment_kinds(operations.commitments)
	_check(kinds.has("employment") and kinds.has("lease") and kinds.has("subscription"), "commitment ledger covers employment, lease and SaaS")
	for commitment_value in operations.commitments:
		var commitment: Dictionary = commitment_value
		for required_key in ["id", "kind", "counterparty_id", "start_week", "end_week", "upfront_cost", "weekly_cost", "billing", "risk_tags"]:
			_check(commitment.has(required_key), "%s commitment includes %s" % [str(commitment.get("id", "")), required_key])
	var public := operations.public_state()
	for required_key in ["week", "open_requisitions", "active_candidates", "active_offers", "scheduled_joins", "pending_joins", "active_employees", "employees", "teams", "office", "subscriptions", "commitment_count", "burn", "cash_flow", "event_count"]:
		_check(public.has(required_key), "public state includes %s" % required_key)
	_check(int(public.get("active_employees", 0)) == 2, "public state reports exact formal roster")
	_check(Dictionary(public.get("office", {})).has("capacity"), "public state reports office capacity")
	var save: Dictionary = operations.to_save()
	_check(save.has("rng_state") and save.has("pending_joins") and save.has("commitments") and save.has("week_cash_outlay_records"), "save contains RNG, pending outputs, commitments and structured outlays")
	var restored = Operations.new(999)
	_check(restored.from_save(save), "complete operating save restores")
	_check(restored.to_save() == save, "save round-trip is lossless")
	_check(restored.public_state() == public, "restored public state matches exactly")
	var mutating_copy: Dictionary = operations.to_save()
	Dictionary(mutating_copy["employees"])["burn_a"] = {}
	_check(not Dictionary(restored.employees["burn_a"]).is_empty(), "save data and restored state are deeply isolated")


func _test_events_are_read_only() -> void:
	var operations = Operations.new(131)
	var roster: Array = [_employee("event_lead", "领队", 3, 70.0, "founders", "", {"management": 0.0})]
	for index in range(5):
		roster.append(_employee("event_report_%d" % index, "报告%d" % index, 1, 35.0, "founders", "event_lead", {"engineering": 5.0}))
	operations.sync_employee_roster(roster, 1)
	operations.apply_decision("sign_office_lease", {"lease_id": "harbor_desk"})
	var before := operations.to_save()
	var formal_before := operations.active_employee_count()
	var pending_before: int = operations.pending_joins.size()
	var events := operations.event_candidates({"week": 1})
	var after := operations.to_save()
	_check(not events.is_empty(), "eligible operating state emits at least one event")
	_check(before == after, "event candidate query is completely read-only")
	_check(operations.active_employee_count() == formal_before, "event query cannot create or delete formal employees")
	_check(operations.pending_joins.size() == pending_before, "event query cannot manufacture pending joins")
	var first_event_id := str(Dictionary(events[0]).get("id", ""))
	var acknowledged := operations.apply_decision("acknowledge_event", {"event_id": first_event_id, "cooldown_weeks": 3})
	_check(bool(acknowledged.get("ok", false)), "event acknowledgement succeeds")
	_check(not _event_ids(operations.event_candidates({"week": 1})).has(first_event_id), "acknowledged event respects cooldown")
	_check(operations.active_employee_count() == formal_before, "event acknowledgement also preserves formal employee authority")


func _fully_interview(operations, candidate_id: String, role_family: String, requisition_id: String) -> void:
	var opened: Dictionary = operations.apply_decision("open_requisition", {
		"id": requisition_id, "role_family": role_family, "team_id": "founders",
		"level": 3, "salary_band": [35.0, 70.0], "equity_band_bps": [5.0, 30.0],
		"candidate_ids": [candidate_id],
	})
	_check(bool(opened.get("ok", false)), "%s requisition opens" % candidate_id)
	for stage in Operations.INTERVIEW_STAGES:
		var interview: Dictionary = operations.apply_decision("interview_candidate", {"candidate_id": candidate_id, "stage": stage})
		_check(bool(interview.get("ok", false)), "%s completes %s" % [candidate_id, stage])


func _employee(id: String, name: String, level: int, salary: float, team_id: String, manager_id: String, skills: Dictionary) -> Dictionary:
	return {
		"id": id, "name": name, "role": "测试岗位", "role_family": "operations",
		"level": level, "salary_annual": salary, "market_salary": salary,
		"equity_bps": 0.0, "team_id": team_id, "manager_id": manager_id,
		"skills": skills.duplicate(true), "ramp": 1.0,
		"burnout": 8.0, "flight_risk": 5.0, "growth_satisfaction": 55.0,
	}


func _event_ids(events: Array) -> Array[String]:
	var ids: Array[String] = []
	for event_value in events:
		if event_value is Dictionary:
			ids.append(str(Dictionary(event_value).get("id", "")))
	return ids


func _commitment_kinds(commitment_list: Array) -> Array[String]:
	var kinds: Array[String] = []
	for commitment_value in commitment_list:
		if commitment_value is Dictionary:
			var kind := str(Dictionary(commitment_value).get("kind", ""))
			if not kinds.has(kind):
				kinds.append(kind)
	return kinds


func _commitment_count(commitment_list: Array, kind: String) -> int:
	var count := 0
	for commitment_value in commitment_list:
		if commitment_value is Dictionary and str(Dictionary(commitment_value).get("kind", "")) == kind:
			count += 1
	return count


func _commitment_by_id(commitment_list: Array, commitment_id: String) -> Dictionary:
	for commitment_value in commitment_list:
		if commitment_value is Dictionary and str(Dictionary(commitment_value).get("id", "")) == commitment_id:
			return Dictionary(commitment_value)
	return {}


func _outcome_kinds(outcomes: Array) -> Array[String]:
	var kinds: Array[String] = []
	for outcome_value in outcomes:
		if outcome_value is Dictionary:
			kinds.append(str(Dictionary(outcome_value).get("kind", "")))
	return kinds


func _membership_count(team_map: Dictionary, employee_id: String) -> int:
	var count := 0
	for team_value in team_map.values():
		if team_value is Dictionary and Array(Dictionary(team_value).get("member_ids", [])).has(employee_id):
			count += 1
	return count


func _check_close(actual: float, expected: float, message: String) -> void:
	_check(is_equal_approx(actual, expected), "%s (expected %.6f, got %.6f)" % [message, expected, actual])


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
