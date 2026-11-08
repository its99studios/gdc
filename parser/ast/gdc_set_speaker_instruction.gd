@tool
class_name GDCSetSpeakerInstruction
extends GDCInstruction


var speaker: String


func _init(p_speaker: String = "") -> void:
	speaker = p_speaker
