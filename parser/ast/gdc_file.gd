@tool
class_name GDCFile
extends RefCounted


var character: String
var dialogues: Array[GDCDialogue] = []


func _init(
	p_character: String = "",
	p_dialogues: Array[GDCDialogue] = []
) -> void:
	character = p_character
	dialogues = p_dialogues
