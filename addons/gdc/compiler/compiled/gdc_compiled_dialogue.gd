@tool
class_name GDCCompiledDialogue
extends Resource


@export var identifier: String = ""
@export var instructions: Array[GDCCompiledInstruction] = []


func _init(
	p_identifier: String = "",
	p_instructions: Array[GDCCompiledInstruction] = []
) -> void:
	identifier = p_identifier
	instructions = p_instructions
