extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var dialogue_file := load(
		"res://dialogue/npcs/adam.gdc"
	) as GDCDialogueFile

	if dialogue_file == null:
		print("Failed to load GDCDialogueFile.")
		quit()
		return

	var dialogue := dialogue_file.load_dialogue("introduction")

	if dialogue == null:
		print("Dialogue not found.")
		quit()
		return

	for instruction in dialogue.instructions:
		if instruction is GDCCompiledSay:
			print(instruction.text)

	quit()