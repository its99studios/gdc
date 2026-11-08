@tool
class_name GDCParser
extends RefCounted


var tokens: Array[GDCToken] = []
var current: int = 0

var errors: Array[String] = []
var _dialogue_identifiers: Dictionary = {}


func parse(p_tokens: Array[GDCToken]) -> GDCParseResult:
	tokens = p_tokens
	current = 0

	errors.clear()
	_dialogue_identifiers.clear()

	var character := ""
	var character_found := false
	var dialogues: Array[GDCDialogue] = []

	_skip_newlines()

	while not _is_at_end():
		if _match_keyword("character"):
			if character_found:
				_error("A GDC file can only declare one character.")
			else:
				character_found = true
				character = _consume_identifier(
					"Expected a character identifier."
				)

			_consume_line_end()

		elif _check_keyword("dialogue"):
			var declaration_token := _advance()
			var dialogue := _parse_dialogue()

			if not dialogue.identifier.is_empty():
				if _dialogue_identifiers.has(dialogue.identifier):
					_report_error_at(
						declaration_token,
						"Duplicate dialogue identifier '%s'."
						% dialogue.identifier
					)
				else:
					_dialogue_identifiers[dialogue.identifier] = true

			dialogues.append(dialogue)

		else:
			_error("Expected 'character' or 'dialogue'.")
			_synchronize_top_level()

		_skip_newlines()

	if not character_found:
		_error("Missing character declaration.")

	var file := GDCFile.new(character, dialogues)

	return GDCParseResult.new(file, errors)


# Parses a complete dialogue declaration.
func _parse_dialogue() -> GDCDialogue:
	var identifier := _consume_identifier(
		"Expected a dialogue identifier."
	)

	_consume(
		GDCToken.Type.COLON,
		"Expected ':' after dialogue identifier."
	)

	_consume_line_end()

	_consume(
		GDCToken.Type.INDENT,
		"Expected an indented dialogue block."
	)

	var result := _parse_instruction_block(true, false)

	if not result.ended:
		_error(
			"Dialogue '%s' is missing its 'end' terminator."
			% identifier
		)

	_skip_newlines()

	_consume(
		GDCToken.Type.DEDENT,
		"Expected the end of the dialogue block."
	)

	return GDCDialogue.new(identifier, result.instructions)


# Parses instructions until a DEDENT or, when allowed, 'end'.
func _parse_instruction_block(
	stop_at_end: bool,
	consume_dedent: bool
) -> Dictionary:
	var instructions: Array[GDCInstruction] = []
	var ended := false

	while not _is_at_end():
		_skip_newlines()

		if _check(GDCToken.Type.DEDENT):
			if consume_dedent:
				_advance()

			break

		if stop_at_end and _check_keyword("end"):
			_advance()
			_consume_line_end()
			ended = true
			break

		if _check_keyword("end"):
			_error("'end' can only terminate a dialogue.")
			_advance()
			_consume_line_end()
			continue

		if _match_keyword("say"):
			instructions.append(_parse_say())

		elif _match_keyword("speaker"):
			instructions.append(_parse_speaker())

		elif _match_keyword("wait"):
			instructions.append(_parse_wait())

		elif _match_keyword("choice"):
			instructions.append(_parse_choice())

		elif _match_keyword("event"):
			instructions.append(_parse_event())

		elif _match_keyword("autoadvance"):
			_parse_autoadvance(instructions)

		else:
			_error("Unexpected instruction.")
			_synchronize_line()

	return {
		"instructions": instructions,
		"ended": ended
	}


# Parses a say instruction.
func _parse_say() -> GDCSayInstruction:
	var text := _consume_string(
		"Expected dialogue text after 'say'."
	)

	var instruction := GDCSayInstruction.new(text)

	_consume_line_end()

	return instruction


# Parses either a speaker change or a speaker-prefixed say.
func _parse_speaker() -> GDCInstruction:
	var speaker := _consume_identifier(
		"Expected a speaker identifier."
	)

	if _match_keyword("say"):
		var text := _consume_string(
			"Expected dialogue text after 'say'."
		)

		var instruction := GDCSayInstruction.new(
			text,
			speaker
		)

		_consume_line_end()

		return instruction

	_consume_line_end()

	return GDCSetSpeakerInstruction.new(speaker)


# Parses a wait instruction.
func _parse_wait() -> GDCWaitInstruction:
	var duration := _consume_number(
		"Expected a duration after 'wait'."
	)

	if duration < 0.0:
		_error("Wait duration cannot be negative.")

	_consume_line_end()

	return GDCWaitInstruction.new(duration)


# Parses an event instruction.
func _parse_event() -> GDCEventInstruction:
	var identifier := _consume_identifier(
		"Expected an event identifier."
	)

	_consume_line_end()

	return GDCEventInstruction.new(identifier)


# Attaches autoadvance to the preceding say instruction.
func _parse_autoadvance(
	instructions: Array[GDCInstruction]
) -> void:
	var duration := _consume_number(
		"Expected a duration after 'autoadvance'."
	)

	if duration < 0.0:
		_error("Autoadvance duration cannot be negative.")

	if instructions.is_empty():
		_error("'autoadvance' must follow a 'say' instruction.")

	else:
		var previous = instructions.back()

		if previous is GDCSayInstruction:
			if previous.has_auto_advance:
				_error(
					"A say instruction cannot have multiple autoadvance declarations."
				)
			else:
				previous.has_auto_advance = true
				previous.auto_advance_seconds = duration
		else:
			_error(
				"'autoadvance' must follow a 'say' instruction."
			)

	_consume_line_end()


# Parses a complete choice block.

func _parse_choice() -> GDCChoiceInstruction:
	_consume(
		GDCToken.Type.COLON,
		"Expected ':' after 'choice'."
	)

	_consume_line_end()

	if not _check(GDCToken.Type.INDENT):
		_error("A choice block must contain at least one option.")
		return GDCChoiceInstruction.new()

	_advance()

	var options: Array[GDCChoiceOption] = []
	var option_identifiers: Dictionary = {}

	while not _is_at_end():
		_skip_newlines()

		if _match(GDCToken.Type.DEDENT):
			break

		var option_text := _consume_string(
			"Expected a quoted choice option."
		)

		_consume(
			GDCToken.Type.COLON,
			"Expected ':' after choice option."
		)

		_consume_line_end()

		_consume(
			GDCToken.Type.INDENT,
			"Expected indented choice instructions."
		)

		var result := _parse_instruction_block(false, true)

		if option_identifiers.has(option_text):
			_error(
				"Duplicate choice option '%s'."
				% option_text
			)
		else:
			option_identifiers[option_text] = true

		options.append(
			GDCChoiceOption.new(
				option_text,
				result.instructions
			)
		)

	return GDCChoiceInstruction.new(options)


# Consumes an identifier.
func _consume_identifier(message: String) -> String:
	if _check(GDCToken.Type.IDENTIFIER):
		return str(_advance().value)

	_error(message)
	return ""


# Consumes a string.
func _consume_string(message: String) -> String:
	if _check(GDCToken.Type.STRING):
		return str(_advance().value)

	_error(message)
	return ""


# Consumes a number.
func _consume_number(message: String) -> float:
	if _check(GDCToken.Type.NUMBER):
		return float(_advance().value)

	_error(message)
	return 0.0


# Consumes the end of a source line.
func _consume_line_end() -> void:
	if _match(GDCToken.Type.NEWLINE):
		return

	_error("Expected the end of the instruction.")
	_synchronize_line()


# Consumes a token of a specific type.
func _consume(
	type: GDCToken.Type,
	message: String
) -> GDCToken:
	if _check(type):
		return _advance()

	_error(message)
	return null


# Matches a keyword.
func _match_keyword(keyword: String) -> bool:
	if _check_keyword(keyword):
		_advance()
		return true

	return false


# Checks whether the current token is a keyword.
func _check_keyword(keyword: String) -> bool:
	return (
		not _is_at_end()
		and _peek().type == GDCToken.Type.KEYWORD
		and _peek().value == keyword
	)


# Matches a token type.
func _match(type: GDCToken.Type) -> bool:
	if _check(type):
		_advance()
		return true

	return false


# Checks the current token type.
func _check(type: GDCToken.Type) -> bool:
	if _is_at_end():
		return type == GDCToken.Type.EOF

	return _peek().type == type


# Advances through the token stream.
func _advance() -> GDCToken:
	if not _is_at_end():
		current += 1

	return tokens[current - 1]


# Returns the current token.
func _peek() -> GDCToken:
	return tokens[current]


# Skips blank lines.
func _skip_newlines() -> void:
	while _match(GDCToken.Type.NEWLINE):
		pass


# Checks whether the parser reached EOF.
func _is_at_end() -> bool:
	return (
		current >= tokens.size()
		or _peek().type == GDCToken.Type.EOF
	)


# Reports an error with its source location.
func _error(message: String) -> void:
	var line := 1
	var column := 1

	if not _is_at_end():
		line = _peek().line
		column = _peek().column

	errors.append(
		"Line %d, column %d: %s"
		% [line, column, message]
	)

func _report_error_at(
	token: GDCToken,
	message: String
) -> void:
	errors.append(
		"Line %d, column %d: %s"
		% [token.line, token.column, message]
	)

# Skips the remainder of the current line.
func _synchronize_line() -> void:
	while not _is_at_end():
		if _check(GDCToken.Type.NEWLINE):
			_advance()
			return

		_advance()


# Recovers when an unexpected top-level token is encountered.
func _synchronize_top_level() -> void:
	while not _is_at_end():
		if _check(GDCToken.Type.NEWLINE):
			_advance()
			return

		if _check_keyword("character") or _check_keyword("dialogue"):
			return

		_advance()
