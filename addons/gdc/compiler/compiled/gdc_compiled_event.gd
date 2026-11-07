@tool
class_name GDCCompiledEvent
extends GDCCompiledInstruction


@export var identifier: String = ""


func _init(p_identifier: String = "") -> void:
	identifier = p_identifier