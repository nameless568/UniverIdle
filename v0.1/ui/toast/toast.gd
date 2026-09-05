class_name ToastView
extends Control

var _box: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.anchor_left = 0.0
	_box.anchor_right = 1.0
	_box.anchor_top = 0.72
	_box.anchor_bottom = 1.0
	_box.offset_left = 12
	_box.offset_right = -12
	_box.offset_top = 0
	_box.offset_bottom = -12
	_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(_box)
	MessageBus.message.connect(_on_message)

func _on_message(color: String, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", _color(color))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(label)
	get_tree().create_timer(4.0).timeout.connect(label.queue_free)

func _color(name: String) -> Color:
	match name:
		"red":
			return Color(0.9, 0.25, 0.25)
		"blue":
			return Color(0.35, 0.5, 0.95)
		"yellow":
			return Color(0.95, 0.8, 0.2)
		"green":
			return Color(0.3, 0.8, 0.4)
		_:
			return Color(0.95, 0.95, 0.95)
