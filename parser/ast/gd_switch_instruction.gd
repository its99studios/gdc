@tool
class_name GDCSwitchInstruction
extends GDCInstruction


var dialogue_identifier: String


func _init(p_dialogue_identifier: String = "") -> void:
	dialogue_identifier = p_dialogue_identifier