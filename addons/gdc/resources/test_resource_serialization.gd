extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	print("\n--- GDC RESOURCE SERIALIZATION TEST ---")

	var dialogue_file := GDCDialogueFile.new()
	dialogue_file.source_code = """
character BullyWalker

dialogue introduction:
	say "Hello!"
	autoadvance 1.5

	end
"""

	var say := GDCCompiledSay.new()
	say.text = "Hello!"
	say.has_auto_advance = true
	say.auto_advance_seconds = 1.5

	var dialogue := GDCCompiledDialogue.new()
	dialogue.identifier = "introduction"
	dialogue.instructions.append(say)

	dialogue_file.dialogues.append(dialogue)

	var path := "user://gdc_serialization_test.res"

	var save_error := ResourceSaver.save(
		dialogue_file,
		path
	)

	if save_error != OK:
		print("Save failed: ", save_error)
		quit()
		return

	print("Resource saved successfully.")

	var loaded := ResourceLoader.load(
		path
	) as GDCDialogueFile

	if loaded == null:
		print("Resource failed to load.")
		quit()
		return

	print("Resource loaded successfully.")
	print("Character source: ", loaded.source_code.contains("BullyWalker"))
	print("Dialogue count: ", loaded.dialogues.size())

	var loaded_dialogue := loaded.load_dialogue("introduction")

	if loaded_dialogue == null:
		print("Dialogue was not preserved.")
		quit()
		return

	print("Dialogue: ", loaded_dialogue.identifier)

	var loaded_say := loaded_dialogue.instructions[0] as GDCCompiledSay

	if loaded_say == null:
		print("Instruction was not preserved.")
		quit()
		return

	print("Text: ", loaded_say.text)
	print("Auto advance: ", loaded_say.has_auto_advance)
	print("Duration: ", loaded_say.auto_advance_seconds)

	print("--- END TEST ---")

	quit()