@tool
class_name GDCCompiler
extends RefCounted


func compile(file: GDCFile) -> GDCCompiledFile:
	var compiled_dialogues: Array[GDCCompiledDialogue] = []

	for dialogue in file.dialogues:
		compiled_dialogues.append(
			_compile_dialogue(dialogue)
		)

	return GDCCompiledFile.new(
		file.character,
		compiled_dialogues
	)


func _compile_dialogue(
	dialogue: GDCDialogue
) -> GDCCompiledDialogue:
	var instructions := _compile_instructions(
		dialogue.instructions
	)

	return GDCCompiledDialogue.new(
		dialogue.identifier,
		instructions
	)


func _compile_instructions(
	source_instructions: Array[GDCInstruction]
) -> Array[GDCCompiledInstruction]:
	var compiled_instructions: Array[GDCCompiledInstruction] = []

	for instruction in source_instructions:
		var compiled := _compile_instruction(instruction)

		if compiled != null:
			compiled_instructions.append(compiled)

	return compiled_instructions


func _compile_instruction(
	instruction: GDCInstruction
) -> GDCCompiledInstruction:
	if instruction is GDCSayInstruction:
		return GDCCompiledSay.new(
			instruction.text,
			instruction.speaker_override,
			instruction.has_auto_advance,
			instruction.auto_advance_seconds
		)

	elif instruction is GDCSetSpeakerInstruction:
		return GDCCompiledSetSpeaker.new(
			instruction.speaker
		)

	elif instruction is GDCWaitInstruction:
		return GDCCompiledWait.new(
			instruction.duration
		)

	elif instruction is GDCEventInstruction:
		return GDCCompiledEvent.new(
			instruction.identifier
		)

	elif instruction is GDCChoiceInstruction:
		return _compile_choice(instruction)
	
	elif instruction is GDCEndInstruction:
		return GDCCompiledEnd.new()
	
	elif instruction is GDCSwitchInstruction:
		return GDCCompiledSwitch.new(
			instruction.dialogue_identifier
		)

	push_error(
		"GDC Compiler: Unsupported instruction type '%s'."
		% instruction.get_script().get_global_name()
	)

	return null


func _compile_choice(
	choice: GDCChoiceInstruction
) -> GDCCompiledChoice:
	var compiled_options: Array[GDCCompiledChoiceOption] = []

	for option in choice.options:
		var compiled_instructions := _compile_instructions(
			option.instructions
		)

		compiled_options.append(
			GDCCompiledChoiceOption.new(
				option.text,
				compiled_instructions
			)
		)

	return GDCCompiledChoice.new(compiled_options)
