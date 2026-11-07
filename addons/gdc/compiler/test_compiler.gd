extends SceneTree


func _initialize() -> void:
	var source := """
character BullyWalker

dialogue introduction:
	say "Hello!"
	autoadvance 1.5

	speaker Player say "Who are you?"

	speaker BullyWalker

	wait 2.0

	choice:
		"Fight me!":
			event start_boss_fight

		"Leave me alone.":
			say "Fine."

	end
"""

	var lexer := GDCLexer.new()
	var parser := GDCParser.new()
	var compiler := GDCCompiler.new()

	var tokens := lexer.tokenize(source)
	var parse_result := parser.parse(tokens)

	print("\n--- GDC COMPILER TEST ---")

	if not parse_result.is_valid():
		print("Parsing failed.")

		for error in parse_result.errors:
			print("  ", error)

		quit()
		return

	var compiled_file := compiler.compile(parse_result.file)

	print("Compilation successful!")
	print("Character: ", compiled_file.character)
	print("Dialogues: ", compiled_file.dialogues.size())

	for dialogue in compiled_file.dialogues:
		print("\nDialogue: ", dialogue.identifier)
		print("Instructions: ", dialogue.instructions.size())

		for instruction in dialogue.instructions:
			print(
				"Compiled instruction: ",
				instruction.get_script().get_global_name()
			)

			if instruction is GDCCompiledSay:
				print("  Text: ", instruction.text)
				print("  Speaker: ", instruction.speaker_override)
				print("  Auto advance: ", instruction.has_auto_advance)
				print("  Duration: ", instruction.auto_advance_seconds)

			elif instruction is GDCCompiledSetSpeaker:
				print("  Speaker: ", instruction.speaker)

			elif instruction is GDCCompiledWait:
				print("  Duration: ", instruction.duration)

			elif instruction is GDCCompiledEvent:
				print("  Event: ", instruction.identifier)

			elif instruction is GDCCompiledChoice:
				for option in instruction.options:
					print("  Option: ", option.text)

					for nested_instruction in option.instructions:
						print(
							"    Nested instruction: ",
							nested_instruction.get_script().get_global_name()
						)

	print("\n--- END TEST ---\n")

	quit()
