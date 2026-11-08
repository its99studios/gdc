@tool
class_name GDCLexer
extends RefCounted


const KEYWORDS: Array[String] = [
	"character",
	"dialogue",
	"say",
	"speaker",
	"autoadvance",
	"wait",
	"choice",
	"event",
	"end"
]


var tokens: Array[GDCToken] = []

var _indent_stack: Array[int] = [0]
var _line: int = 1
var _column: int = 1
var _position: int = 0
var _current_line: String = ""


func tokenize(source: String) -> Array[GDCToken]:
	tokens.clear()

	_indent_stack = [0]
	_line = 1

	var lines := source.split("\n", true)

	for current_line in lines:
		_current_line = current_line.trim_suffix("\r")
		_process_line()
		_line += 1

	_finish_indentation()

	_add_token(GDCToken.Type.EOF, null, _line, 1)

	return tokens


# Processes one physical source line.
func _process_line() -> void:
	_position = 0
	_column = 1

	var indentation := 0

	# Count leading tabs.
	while _position < _current_line.length():
		if _peek() != "\t":
			break

		_advance()
		indentation += 1

	# Reject spaces used for indentation.
	if _peek() == " ":
		push_error(
			"GDC Lexer: Spaces cannot be used for indentation at line %d."
			% _line
		)

		while _peek() == " ":
			_advance()

	# Ignore indentation changes on blank lines and comment-only lines.
	if _is_at_end() or _peek() == "#":
		_add_token(
			GDCToken.Type.NEWLINE,
			null,
			_line,
			_column
		)
		return

	_process_indentation(indentation)

	# Scan the actual contents of the line.
	while not _is_at_end():
		_scan_token()

	_add_token(
		GDCToken.Type.NEWLINE,
		null,
		_line,
		_column
	)


# Generates INDENT and DEDENT tokens.
func _process_indentation(indentation: int) -> void:
	var previous := _indent_stack.back()

	if indentation > previous:
		_indent_stack.append(indentation)

		_add_token(
			GDCToken.Type.INDENT,
			null,
			_line,
			1
		)

	elif indentation < previous:
		while _indent_stack.size() > 1:
			if indentation >= _indent_stack.back():
				break

			_indent_stack.pop_back()

			_add_token(
				GDCToken.Type.DEDENT,
				null,
				_line,
				1
			)

		if indentation != _indent_stack.back():
			push_error(
				"GDC Lexer: Inconsistent indentation at line %d."
				% _line
			)


# Scans one token from the current line.
func _scan_token() -> void:
	var start_column := _column
	var current := _advance()

	match current:
		" ", "\t", "\r":
			pass

		"#":
			_position = _current_line.length()

		":":
			_add_token(
				GDCToken.Type.COLON,
				":",
				_line,
				start_column
			)

		"\"", "'":
			_scan_string(current, start_column)

		_:
			if _is_digit(current):
				_scan_number(current, start_column)

			elif _is_identifier_start(current):
				_scan_identifier(current, start_column)

			else:
				push_error(
					"GDC Lexer: Unexpected character '%s' at line %d, column %d."
					% [current, _line, start_column]
				)

				_add_token(
					GDCToken.Type.UNKNOWN,
					current,
					_line,
					start_column
				)


# Scans identifiers and keywords.
func _scan_identifier(
	first_character: String,
	start_column: int
) -> void:
	var identifier := first_character

	while not _is_at_end():
		var current := _peek()

		if not _is_identifier_part(current):
			break

		identifier += _advance()

	var type := GDCToken.Type.IDENTIFIER

	if identifier in KEYWORDS:
		type = GDCToken.Type.KEYWORD

	_add_token(
		type,
		identifier,
		_line,
		start_column
	)


# Scans integer and decimal numbers.
func _scan_number(
	first_character: String,
	start_column: int
) -> void:
	var number := first_character
	var is_decimal := false

	while not _is_at_end():
		if not _is_digit(_peek()):
			break

		number += _advance()

	if not _is_at_end() and _peek() == ".":
		if _position + 1 < _current_line.length():
			if _is_digit(_current_line[_position + 1]):
				is_decimal = true
				number += _advance()

				while not _is_at_end():
					if not _is_digit(_peek()):
						break

					number += _advance()

	var value: Variant

	if is_decimal:
		value = number.to_float()
	else:
		value = number.to_int()

	_add_token(
		GDCToken.Type.NUMBER,
		value,
		_line,
		start_column
	)


# Scans quoted strings.
func _scan_string(
	quote: String,
	start_column: int
) -> void:
	var value := ""

	while not _is_at_end():
		var current := _advance()

		if current == quote:
			_add_token(
				GDCToken.Type.STRING,
				value,
				_line,
				start_column
			)
			return

		# Handle escaped characters.
		if current == "\\":
			if _is_at_end():
				break

			var escaped := _advance()

			match escaped:
				"n":
					value += "\n"

				"t":
					value += "\t"

				"\\":
					value += "\\"

				"\"":
					value += "\""

				"'":
					value += "'"

				_:
					push_error(
						"GDC Lexer: Unknown escape sequence '\\%s' at line %d."
						% [escaped, _line]
					)

					value += escaped

		else:
			value += current

	push_error(
		"GDC Lexer: Unterminated string at line %d."
		% _line
	)


# Closes all remaining indentation levels at EOF.
func _finish_indentation() -> void:
	while _indent_stack.size() > 1:
		_indent_stack.pop_back()

		_add_token(
			GDCToken.Type.DEDENT,
			null,
			_line,
			1
		)


func _advance() -> String:
	var character := _current_line[_position]

	_position += 1
	_column += 1

	return character


func _peek() -> String:
	if _is_at_end():
		return ""

	return _current_line[_position]


func _is_at_end() -> bool:
	return _position >= _current_line.length()


func _is_digit(character: String) -> bool:
	return character >= "0" and character <= "9"


func _is_letter(character: String) -> bool:
	if character.is_empty():
		return false

	return (
		(character >= "a" and character <= "z")
		or (character >= "A" and character <= "Z")
	)


func _is_identifier_start(character: String) -> bool:
	return _is_letter(character) or character == "_"


func _is_identifier_part(character: String) -> bool:
	return (
		_is_identifier_start(character)
		or _is_digit(character)
	)


func _add_token(
	type: GDCToken.Type,
	value: Variant,
	token_line: int,
	token_column: int
) -> void:
	tokens.append(
		GDCToken.new(
			type,
			value,
			token_line,
			token_column
		)
	)
