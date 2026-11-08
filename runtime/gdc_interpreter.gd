class_name GDCInterpreter
extends Node


signal dialogue_line_requested(
	text: String,
	speaker: String,
	auto_advance: bool,
	auto_advance_seconds: float
)

signal choice_requested(
	options: Array[GDCCompiledChoiceOption]
)

signal event_requested(identifier: String)

signal dialogue_started(identifier: String)
signal dialogue_finished(identifier: String)

signal execution_error(message: String)

var _state: GDCExecutionState
var _context: GDCContext
var _compiled_file: GDCCompiledFile
var _timer_generation: int = 0

func advance() -> void:
	if _state == null or not _state.is_running:
		return

	if not _state.is_waiting_for_input:
		return

	_state.is_waiting_for_input = false

	process_instructions()


func select_choice(index: int) -> void:
	if _state == null or not _state.is_running:
		return

	if not _state.is_waiting_for_choice:
		return

	if index < 0 or index >= _state.available_choices.size():
		execution_error.emit(
			"Invalid choice index: %d."
			% index
		)
		return

	var selected_option := _state.available_choices[index]

	_state.is_waiting_for_choice = false
	_state.available_choices.clear()

	_state.push_frame(
		GDCExecutionFrame.new(selected_option.instructions)
	)

	process_instructions()


func stop() -> void:
	if _state == null or not _state.is_running:
		return

	_finish_dialogue()

func start_dialogue(
	compiled_file: GDCCompiledFile,
	dialogue_identifier: String
) -> bool:
	if compiled_file == null:
		execution_error.emit("Cannot start a null compiled file.")
		return false

	if _state != null and _state.is_running:
		execution_error.emit(
			"Cannot start a dialogue while another is running."
		)
		return false
	
	_timer_generation += 1

	var dialogue: GDCCompiledDialogue = null

	for candidate in compiled_file.dialogues:
		if candidate.identifier == dialogue_identifier:
			dialogue = candidate
			break

	if dialogue == null:
		execution_error.emit(
			"Dialogue '%s' was not found."
			% dialogue_identifier
		)
		return false

	_compiled_file = compiled_file

	_state = GDCExecutionState.new()
	_state.current_dialogue = dialogue
	_state.current_speaker = compiled_file.character
	_state.is_running = true

	_context = GDCContext.new(
		compiled_file.character,
		dialogue_identifier
	)

	_state.push_frame(
		GDCExecutionFrame.new(dialogue.instructions)
	)

	dialogue_started.emit(dialogue_identifier)

	process_instructions()

	return true

func process_instructions() -> void:
	if _state == null or not _state.is_running:
		return

	while _state.is_running:
		var frame := _state.get_current_frame()

		if frame == null:
			_finish_dialogue()
			return

		if frame.is_finished():
			_state.pop_frame()
			continue

		var instruction := frame.get_next_instruction()

		if not _execute_instruction(instruction):
			return

func _execute_instruction(
	instruction: GDCCompiledInstruction
) -> bool:
	if instruction is GDCCompiledSay:
		_execute_say(instruction)
		return false
	
	elif instruction is GDCCompiledWait:
		_execute_wait(instruction)
		return false
	
	elif instruction is GDCCompiledSetSpeaker:
		_execute_set_speaker(instruction)
		return true
	
	elif instruction is GDCCompiledChoice:
		_execute_choice(instruction)
		return false
	
	elif instruction is GDCCompiledEvent:
		_execute_event(instruction)
		return true
	
	elif instruction is GDCCompiledEnd:
		_finish_dialogue()
		return false
	
	elif instruction is GDCCompiledSwitch:
		_execute_switch(instruction)
		return true

	execution_error.emit(
		"Unsupported instruction type: %s"
		% instruction.get_script().get_global_name()
	)

	_stop_with_error()
	return false

func _execute_say(instruction: GDCCompiledSay) -> void:
	var speaker := _state.current_speaker

	if not instruction.speaker_override.is_empty():
		speaker = instruction.speaker_override

	_state.is_waiting_for_input = not instruction.has_auto_advance
	_state.is_waiting_for_timer = instruction.has_auto_advance

	dialogue_line_requested.emit(
		instruction.text,
		speaker,
		instruction.has_auto_advance,
		instruction.auto_advance_seconds
	)

	if instruction.has_auto_advance:
		_start_timer(instruction.auto_advance_seconds)

func _execute_wait(instruction: GDCCompiledWait) -> void:
	_state.is_waiting_for_timer = true

	_start_timer(instruction.duration)

func _execute_set_speaker(
	instruction: GDCCompiledSetSpeaker
) -> void:
	_state.current_speaker = instruction.speaker

func _execute_choice(
	instruction: GDCCompiledChoice
) -> void:
	_state.available_choices = instruction.options
	_state.is_waiting_for_choice = true

	choice_requested.emit(instruction.options)

func _execute_event(instruction: GDCCompiledEvent) -> void:
	event_requested.emit(instruction.identifier)

func _execute_switch(instruction: GDCCompiledSwitch) -> void:
	var target: GDCCompiledDialogue = null

	for dialogue in _compiled_file.dialogues:
		if dialogue.identifier == instruction.dialogue_identifier:
			target = dialogue
			break

	if target == null:
		execution_error.emit(
			"Dialogue '%s' was not found."
			% instruction.dialogue_identifier
		)
		_stop_with_error()
		return

	_timer_generation += 1
	
	_state.execution_stack.clear()
	_state.current_dialogue = target
	_state.current_speaker = _compiled_file.character

	_state.is_waiting_for_input = false
	_state.is_waiting_for_choice = false
	_state.is_waiting_for_timer = false
	_state.available_choices.clear()

	_context.dialogue_id = instruction.dialogue_identifier

	_state.push_frame(
		GDCExecutionFrame.new(target.instructions)
	)

func _finish_dialogue() -> void:
	var identifier := _context.dialogue_id

	_state.is_running = false
	_state.is_waiting_for_input = false
	_state.is_waiting_for_choice = false
	_state.is_waiting_for_timer = false

	dialogue_finished.emit(identifier)

	_timer_generation += 1

func _stop_with_error() -> void:
	_timer_generation += 1

	if _state == null:
		return

	_state.is_running = false
	_state.is_waiting_for_input = false
	_state.is_waiting_for_choice = false
	_state.is_waiting_for_timer = false

func _start_timer(duration: float) -> void:
	_timer_generation += 1

	var generation := _timer_generation
	var current_state := _state

	await get_tree().create_timer(duration).timeout

	if generation != _timer_generation:
		return

	if _state != current_state:
		return

	if not current_state.is_running:
		return

	current_state.is_waiting_for_timer = false

	process_instructions()