@tool
extends EditorPlugin


var import_plugin: GDCImportPlugin


func _enter_tree() -> void:
	import_plugin = GDCImportPlugin.new()
	add_import_plugin(import_plugin)


func _exit_tree() -> void:
	remove_import_plugin(import_plugin)
	import_plugin = null