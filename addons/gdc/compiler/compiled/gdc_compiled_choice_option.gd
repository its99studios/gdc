@tool
class_name GDCCompiledChoiceOption
extends Resource


@export var text: String = ""
@export var instructions: Array[GDCCompiledInstruction] = []


func _init(
	p_text: String = "",
	p_instructions: Array[GDCCompiledInstruction] = []
) -> void:
	text = p_text
	instructions = p_instructions