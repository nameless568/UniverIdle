extends Node

signal message(color: String, text: String)

func emit_message(color: String, text: String) -> void:
	message.emit(color, text)
