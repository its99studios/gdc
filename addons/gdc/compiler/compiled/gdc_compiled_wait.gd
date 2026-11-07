@tool
class_name GDCCompiledWait
extends GDCCompiledInstruction


@export var duration: float = 0.0


func _init(p_duration: float = 0.0) -> void:
	duration = p_duration