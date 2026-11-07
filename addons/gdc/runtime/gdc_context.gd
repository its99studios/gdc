class_name GDCContext
extends RefCounted


var character: String = ""

var dialogue_id: String = ""

var variables: Dictionary = {}


func _init(
	p_character: String = "",
	p_dialogue_id: String = ""
) -> void:
	character = p_character
	dialogue_id = p_dialogue_id
