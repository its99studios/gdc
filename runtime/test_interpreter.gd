extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var source := """
character BullyWalker

dialogue first:
	say "First dialogue."
	autoadvance 5.0
	end

dialogue second:
	say "Second dialogue."
	end
"""

	var lexer := GDCLexer.new()
	var parser := GDCParser.new()
	var compiler := GDCCompiler.new()

	var parse_result := parser.parse(
		lexer.tokenize(source)
	)

	print("\n--- GDC STATE VALIDATION TEST ---")

	if not parse_result.is_valid():
		print("Parsing failed: ", parse_result.errors)
		quit()
		return

	var compiled_file := compiler.compile(parse_result.file)

	var interpreter := GDCInterpreter.new()
	root.add_child(interpreter)

	interpreter.dialogue_line_requested.connect(
		func(
			text: String,
			speaker: String,
			auto_advance: bool,
			duration: float
		) -> void:
			print("Line: ", text)
	)

	interpreter.dialogue_finished.connect(
		func(identifier: String) -> void:
			print("Finished: ", identifier)
	)

	print("Starting first dialogue...")
	interpreter.start_dialogue(compiled_file, "first")
	interpreter.process_instructions()

	print("Trying to start second dialogue while first is running...")
	var second_started := interpreter.start_dialogue(
		compiled_file,
		"second"
	)
	print("Second dialogue started: ", second_started)

	print("Stopping first dialogue...")
	interpreter.stop()

	print("Stopping again...")
	interpreter.stop()

	print("--- END TEST ---")

	interpreter.queue_free()
	quit()
