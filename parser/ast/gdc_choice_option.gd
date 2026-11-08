@tool
class_name GDCChoiceOption
extends RefCounted


var text: String
var instructions: Array[GDCInstruction] = []


func _init(
	p_text: String = "",
	p_instructions: Array[GDCInstruction] = []
) -> void:
	text = p_text
	instructions = p_instructions
