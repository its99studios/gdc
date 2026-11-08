@tool
class_name GDCChoiceInstruction
extends GDCInstruction


var options: Array[GDCChoiceOption] = []


func _init(
	p_options: Array[GDCChoiceOption] = []
) -> void:
	options = p_options
