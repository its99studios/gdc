@tool
class_name GDCCompiledSay
extends GDCCompiledInstruction


@export var text: String
@export var speaker_override: String = ""

@export var has_auto_advance: bool = false
@export var auto_advance_seconds: float = 0.0


func _init(
	p_text: String = "",
	p_speaker_override: String = "",
	p_has_auto_advance: bool = false,
	p_auto_advance_seconds: float = 0.0
) -> void:
	text = p_text
	speaker_override = p_speaker_override
	has_auto_advance = p_has_auto_advance
	auto_advance_seconds = p_auto_advance_seconds