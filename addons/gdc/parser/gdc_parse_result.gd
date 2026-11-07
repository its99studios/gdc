@tool
class_name GDCParseResult
extends RefCounted


var file: GDCFile
var errors: Array[String] = []


func _init(
	p_file: GDCFile = null,
	p_errors: Array[String] = []
) -> void:
	file = p_file
	errors = p_errors


func is_valid() -> bool:
	return errors.is_empty() and file != null