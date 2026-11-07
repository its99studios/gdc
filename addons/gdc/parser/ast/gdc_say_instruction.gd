@tool
class_name GDCSayInstruction
extends GDCInstruction


var text: String
var speaker_override: String = ""

var has_auto_advance: bool = false
var auto_advance_seconds: float = 0.0


func _init(
	p_text: String = "",
	p_speaker_override: String = ""
) -> void:
	text = p_text
	speaker_override = p_speaker_override
