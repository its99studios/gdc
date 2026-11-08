@tool
class_name GDCImportPlugin
extends EditorImportPlugin


func _get_importer_name() -> String:
	return "gdc.dialogue"


func _get_visible_name() -> String:
	return "GDC Dialogue"


func _get_recognized_extensions() -> PackedStringArray:
	return ["ngdc"]


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	return "Resource"


func _get_preset_count() -> int:
	return 0


func _get_preset_name(preset_index: int) -> String:
	return ""


func _get_import_options(
	path: String,
	preset_index: int
) -> Array[Dictionary]:
	return []


func _import(
	source_file: String,
	save_path: String,
	options: Dictionary,
	platform_variants: Array[String],
	gen_files: Array[String]
) -> Error:
	var file := FileAccess.open(
		source_file,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"GDC Importer: Could not open '%s'."
			% source_file
		)
		return FileAccess.get_open_error()

	var source_code := file.get_as_text()
	file.close()

	var lexer := GDCLexer.new()
	var parser := GDCParser.new()

	var tokens := lexer.tokenize(source_code)
	var parse_result := parser.parse(tokens)

	if not parse_result.is_valid():
		var error_message := "\n".join(parse_result.errors)

		push_error(
			"GDC Importer: Failed to parse '%s'.\n%s"
			% [source_file, error_message]
		)

		return ERR_PARSE_ERROR

	var compiler := GDCCompiler.new()
	var compiled_file := compiler.compile(parse_result.file)

	var dialogue_file := GDCDialogueFile.new()
	dialogue_file.source_code = source_code
	dialogue_file.character = compiled_file.character
	dialogue_file.dialogues = compiled_file.dialogues

	var save_error := ResourceSaver.save(
		dialogue_file,
		save_path + "." + _get_save_extension()
	)

	if save_error != OK:
		push_error(
			"GDC Importer: Failed to save resource. Error: %d"
			% save_error
		)
		return save_error

	return OK