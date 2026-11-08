@tool
class_name GDCCompiledSwitch
extends GDCCompiledInstruction


@export var dialogue_identifier: String


func _init(p_dialogue_identifier: String = "") -> void:
	dialogue_identifier = p_dialogue_identifier