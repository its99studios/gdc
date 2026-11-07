@tool
extends RefCounted
class_name GDCToken


enum Type {
	KEYWORD,
	IDENTIFIER,
	STRING,
	NUMBER,

	COLON,
	NEWLINE,
	INDENT,
	DEDENT,

	EOF,
	UNKNOWN
}


var type: Type
var value: Variant
var line: int
var column: int


func _init(
	p_type: Type,
	p_value: Variant,
	p_line: int,
	p_column: int
) -> void:
	type = p_type
	value = p_value
	line = p_line
	column = p_column