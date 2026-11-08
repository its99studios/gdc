@tool
class_name GDCCompiledFile
extends RefCounted


var character: String
var dialogues: Array[GDCCompiledDialogue] = []


func _init(
	p_character: String = "",
	p_dialogues: Array[GDCCompiledDialogue] = []
) -> void:
	character = p_character
	dialogues = p_dialogues
