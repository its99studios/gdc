extends SceneTree


func _initialize() -> void:
	var source := """
character BullyWalker

dialogue introduction:
	say "Who are you?"

	speaker Player say "I'm Mark."

	speaker BullyWalker
	say "I didn't ask."

	end
"""

	var lexer := GDCLexer.new()
	var parser := GDCParser.new()

	var tokens := lexer.tokenize(source)
	var result := parser.parse(tokens)

	print("\n--- GDC PARSER TEST ---")

	if result.is_valid():
		print("Parsing successful!")
		print("Character: ", result.file.character)
		print("Dialogues: ", result.file.dialogues.size())

		for dialogue in result.file.dialogues:
			print("Dialogue: ", dialogue.identifier)
			print("Instructions: ", dialogue.instructions.size())

			for instruction in dialogue.instructions:
				print(
					"Instruction: ",
					instruction.get_script().get_global_name()
				)

				if instruction is GDCSayInstruction:
					print("Text: ", instruction.text)
					print("Auto advance: ", instruction.has_auto_advance)
					print("Duration: ", instruction.auto_advance_seconds)

	else:
		print("Parsing failed.")

		for error in result.errors:
			print("  ", error)

	print("--- END TEST ---\n")

	quit()
