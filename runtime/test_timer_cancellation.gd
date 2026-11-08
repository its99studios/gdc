extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var interpreter := GDCInterpreter.new()
	root.add_child(interpreter)

	var source := """
character BullyWalker

dialogue first:
	say "This should never advance."
	autoadvance 5.0
	end

dialogue second:
	say "The new dialogue is working."
	end
"""

	var lexer := GDCLexer.new()
	var parser := GDCParser.new()
	var compiler := GDCCompiler.new()

	var parse_result := parser.parse(
		lexer.tokenize(source)
	)

	print("\n--- GDC TIMER CANCELLATION TEST ---")

	if not parse_result.is_valid():
		print("Parsing failed: ", parse_result.errors)
		quit()
		return

	var compiled_file := compiler.compile(parse_result.file)

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

	interpreter.start_dialogue(compiled_file, "first")
	interpreter.process_instructions()

	print("Waiting 1 second before stopping...")

	await create_timer(1.0).timeout

	interpreter.stop()

	print("First dialogue stopped.")

	if interpreter.start_dialogue(compiled_file, "second"):
		interpreter.process_instructions()
	else:
		print("Failed to start second dialogue.")
		quit()
		return

	await create_timer(5.0).timeout

	print("Five seconds elapsed.")
	print("The old timer should not have advanced the new dialogue.")
	print("--- END TEST ---\n")

	interpreter.stop()
	interpreter.queue_free()
	quit()
