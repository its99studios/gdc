@tool
class_name GDCCompiledSetSpeaker
extends GDCCompiledInstruction


@export var speaker: String = ""


func _init(p_speaker: String = "") -> void:
	speaker = p_speaker