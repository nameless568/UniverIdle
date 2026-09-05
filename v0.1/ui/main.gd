extends Control

var welcome: WelcomeView
var main_view: Control
var top_bar: TopBar
var nav: NavView
var work_center: WorkCenterView
var toast: ToastView
var inventory_overlay: InventoryView
var character_overlay: CharacterView

const TICK_INTERVAL := 0.02   # 逻辑层节流步进间隔（秒）

var _current_location := ""
var _accum := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	welcome = WelcomeView.new()
	add_child(welcome)
	welcome.game_started.connect(_on_game_started)

	main_view = VBoxContainer.new()
	main_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_view.visible = false
	add_child(main_view)

	top_bar = TopBar.new()
	main_view.add_child(top_bar)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_view.add_child(content)

	nav = NavView.new()
	nav.custom_minimum_size = Vector2(180, 0)
	content.add_child(nav)

	work_center = WorkCenterView.new()
	work_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(work_center)

	nav.location_selected.connect(_on_location_selected)
	top_bar.open_inventory.connect(_on_open_inventory)
	top_bar.open_character.connect(_on_open_character)
	top_bar.back_to_welcome.connect(_on_back_to_welcome)

	inventory_overlay = InventoryView.new()
	inventory_overlay.visible = false
	add_child(inventory_overlay)
	inventory_overlay.closed.connect(func(): inventory_overlay.visible = false)

	character_overlay = CharacterView.new()
	character_overlay.visible = false
	add_child(character_overlay)
	character_overlay.closed.connect(func(): character_overlay.visible = false)

	toast = ToastView.new()
	add_child(toast)

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= TICK_INTERVAL:
		_accum = 0.0
		if GameState.save != null and main_view.visible:
			GameState.update(Time.get_unix_time_from_system())
			_refresh()

func _on_game_started() -> void:
	inventory_overlay.visible = false
	character_overlay.visible = false
	welcome.visible = false
	main_view.visible = true
	_pick_first_location()
	_refresh()

func _pick_first_location() -> void:
	_current_location = ""
	for loc_id in GameState.environment.locations:
		var loc: LocationData = GameState.environment.locations[loc_id]
		if loc.parent_id != "":
			continue
		if loc.unlocked:
			_current_location = loc_id
			break
	work_center.set_location(_current_location)

func _on_location_selected(loc_id: String) -> void:
	_current_location = loc_id
	work_center.set_location(loc_id)
	_refresh()

func _on_open_inventory() -> void:
	inventory_overlay.visible = true
	inventory_overlay.refresh()

func _on_open_character() -> void:
	character_overlay.visible = true
	character_overlay.refresh()

func _on_back_to_welcome() -> void:
	inventory_overlay.visible = false
	character_overlay.visible = false
	main_view.visible = false
	welcome.visible = true
	welcome.refresh()

func _refresh() -> void:
	top_bar.refresh()
	nav.refresh(_current_location)
	work_center.refresh()
