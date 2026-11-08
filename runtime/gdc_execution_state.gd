class_name GDCExecutionState
extends RefCounted


var current_dialogue: GDCCompiledDialogue

var current_speaker: String = ""

var execution_stack: Array[GDCExecutionFrame] = []

var available_choices: Array[GDCCompiledChoiceOption] = []

var is_running: bool = false
var is_waiting_for_input: bool = false
var is_waiting_for_choice: bool = false
var is_waiting_for_timer: bool = false

func push_frame(frame: GDCExecutionFrame) -> void:
	execution_stack.append(frame)


func pop_frame() -> GDCExecutionFrame:
	if execution_stack.is_empty():
		return null

	return execution_stack.pop_back()


func get_current_frame() -> GDCExecutionFrame:
	if execution_stack.is_empty():
		return null

	return execution_stack.back()


func is_finished() -> bool:
	return execution_stack.is_empty()
