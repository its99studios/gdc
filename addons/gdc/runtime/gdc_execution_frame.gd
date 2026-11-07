class_name GDCExecutionFrame
extends RefCounted


var instructions: Array[GDCCompiledInstruction] = []
var instruction_index: int = 0


func _init(
	p_instructions: Array[GDCCompiledInstruction] = []
) -> void:
	instructions = p_instructions


func is_finished() -> bool:
	return instruction_index >= instructions.size()


func get_next_instruction() -> GDCCompiledInstruction:
	if is_finished():
		return null

	var instruction := instructions[instruction_index]
	instruction_index += 1

	return instruction
