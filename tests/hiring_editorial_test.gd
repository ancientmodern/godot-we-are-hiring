extends SceneTree

## Editorial conventions, made executable.
##
## The rules here are the ones that are invisible one string at a time and
## obvious across two thousand of them: how many ways a character is allowed to
## be quoted, whether a number belongs in a sentence or in the panel that is
## already showing that number, and how often the prose is allowed to raise its
## voice. They exist as a test because prose drifts and a style guide does not
## fail a build.

const SOURCES := [
	"res://src/hiring_content.gd",
	"res://src/hiring_expansion_content.gd",
	"res://src/hiring_industry_echo_content.gd",
	"res://src/hiring_model.gd",
	"res://src/hiring_main.gd",
	"res://src/hiring_director.gd",
]

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var corpus := _collect_corpus()
	_check(corpus.size() > 1500, "the editorial audit reads the whole player-visible corpus (%d strings)" % corpus.size())
	_test_one_way_to_quote_a_person(corpus)
	_test_prose_does_not_shout(corpus)
	_test_actions_do_not_repeat_their_own_panel()

	if failures.is_empty():
		print("HIRING_EDITORIAL_TESTS_PASS: %d checks over %d strings" % [checks, corpus.size()])
		quit(0)
	else:
		for failure in failures:
			push_error("HIRING_EDITORIAL_TEST_FAILURE: " + failure)
		quit(1)


func _test_one_way_to_quote_a_person(corpus: Array) -> void:
	# Two speakers, two conventions: people get 『』, the machine gets a `>`
	# prefix. A third convention reads as a different author, because it is one.
	for banned in ["‘", "’", "「", "」"]:
		var offenders: Array[String] = []
		for entry_value in corpus:
			var entry: Dictionary = entry_value
			if str(entry["text"]).contains(banned):
				offenders.append("%s:%d %s" % [str(entry["file"]), int(entry["line"]), str(entry["text"]).substr(0, 40)])
		_check(offenders.is_empty(), "no player-visible string quotes with `%s` (%d found: %s)" % [banned, offenders.size(), ", ".join(PackedStringArray(offenders.slice(0, 3)))])
	var corner := 0
	for entry_value in corpus:
		if str(Dictionary(entry_value)["text"]).contains("『"):
			corner += 1
	_check(corner > 100, "the corner-quote convention is actually the one in use (%d strings)" % corner)


func _test_prose_does_not_shout(corpus: Array) -> void:
	var shouted: Array[String] = []
	var dashes := 0
	for entry_value in corpus:
		var entry: Dictionary = entry_value
		var text := str(entry["text"])
		if text.contains("！"):
			shouted.append("%s:%d" % [str(entry["file"]), int(entry["line"])])
		if text.contains("——"):
			dashes += 1
	_check(shouted.is_empty(), "nothing in this game raises its voice (%d exclamation marks)" % shouted.size())
	# The dash is a real punctuation mark; it is only a tic in bulk. This bound is
	# a smoke alarm, not a ban.
	_check(dashes <= 18, "the em dash stays rare enough to still mean something (%d uses)" % dashes)


func _test_actions_do_not_repeat_their_own_panel() -> void:
	# Every action is drawn beside a block that prints its exact ranges. A
	# description that also prints them spends the one line the action gets on
	# something the player is already reading.
	var numeric := RegEx.new()
	numeric.compile("[+\\-][0-9]|[0-9]+%|[0-9]+\\s*[~–]\\s*[0-9]")
	var offenders: Array[String] = []
	for action_id in HiringContent.ACTIONS:
		var action: Dictionary = HiringContent.ACTIONS[action_id]
		var description := str(action.get("description", ""))
		_check(not description.is_empty(), "action `%s` has a description at all" % action_id)
		if numeric.search(description) != null:
			offenders.append("%s: %s" % [str(action_id), description])
	_check(offenders.is_empty(), "no action description restates its own effect panel (%s)" % ", ".join(PackedStringArray(offenders)))


func _collect_corpus() -> Array:
	var han := RegEx.new()
	han.compile("[\\x{4e00}-\\x{9fff}]")
	var quoted := RegEx.new()
	quoted.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var corpus: Array = []
	for path in SOURCES:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var line_number := 0
		while not file.eof_reached():
			line_number += 1
			var line := file.get_line()
			var trimmed := line.strip_edges()
			if trimmed.begins_with("#") or trimmed.begins_with("##"):
				continue
			for match_value in quoted.search_all(line):
				var text: String = match_value.get_string(1)
				if text.length() > 5 and han.search(text) != null:
					corpus.append({"file": path.get_file(), "line": line_number, "text": text})
		file.close()
	return corpus


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
