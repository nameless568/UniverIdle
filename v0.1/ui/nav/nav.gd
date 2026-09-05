class_name NavView
extends PanelContainer

signal location_selected(loc_id: String)

var _box: VBoxContainer
var _built_key := ""

func _ready() -> void:
	_box = VBoxContainer.new()
	add_child(_box)

func refresh(selected_id: String) -> void:
	var key := _make_key(selected_id)
	if key == _built_key:
		return
	_built_key = key

	for c in _box.get_children():
		c.queue_free()
	for loc_id in GameState.environment.locations:
		var loc: LocationData = GameState.environment.locations[loc_id]
		if loc.parent_id != "":
			continue
		var btn := Button.new()
		btn.text = loc.name if loc.unlocked else loc.name + "（未解锁）"
		btn.disabled = not loc.unlocked
		btn.toggle_mode = true
		btn.button_pressed = (loc_id == selected_id)
		btn.pressed.connect(_on_pressed.bind(loc_id))
		_box.add_child(btn)

func _make_key(selected_id: String) -> String:
	var parts := ["sel=" + selected_id]
	for loc_id in GameState.environment.locations:
		var loc: LocationData = GameState.environment.locations[loc_id]
		parts.append(loc_id + "=" + str(loc.unlocked))
	return "|".join(parts)

func _on_pressed(loc_id: String) -> void:
	location_selected.emit(loc_id)
