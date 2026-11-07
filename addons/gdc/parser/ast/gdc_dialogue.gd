@tool
class_name GDCDialogue
extends RefCounted


var identifier: String
var instructions: Array[GDCInstruction] = []


func _init(
	p_identifier: String = "",
	p_instructions: Array[GDCInstruction] = []
) -> void:
	identifier = p_identifier
	instructions = p_instructions
