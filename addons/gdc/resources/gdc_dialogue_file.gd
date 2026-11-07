@tool
class_name GDCDialogueFile
extends Resource


@export_multiline var source_code: String = ""
@export var dialogues: Array[GDCCompiledDialogue] = []

var character: String = ""


func load_dialogue(identifier: String) -> GDCCompiledDialogue:
	for dialogue in dialogues:
		if dialogue.identifier == identifier:
			return dialogue

	return null