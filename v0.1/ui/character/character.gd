class_name CharacterView
extends Control

signal closed

var _input: LineEdit

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.4)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.35
	panel.anchor_right = 0.65
	panel.anchor_top = 0.35
	panel.anchor_bottom = 0.65
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	add_child(panel)

	var v := VBoxContainer.new()
	panel.add_child(v)

	var title := Label.new()
	title.text = "角色名字"
	v.add_child(title)

	_input = LineEdit.new()
	v.add_child(_input)

	var ok := Button.new()
	ok.text = "确认"
	ok.pressed.connect(_on_ok)
	v.add_child(ok)

	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(func(): closed.emit())
	v.add_child(close)

func refresh() -> void:
	if GameState.save == null:
		return
	_input.text = GameState.save.character.name

func _on_ok() -> void:
	GameState.append_operation(Operation.TYPE_SET_NAME, _input.text)
	GameState.update(Time.get_unix_time_from_system())
	closed.emit()
