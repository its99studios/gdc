@tool
class_name GDCCompiledChoice
extends GDCCompiledInstruction


@export var options: Array[GDCCompiledChoiceOption] = []


func _init(
	p_options: Array[GDCCompiledChoiceOption] = []
) -> void:
	options = p_options