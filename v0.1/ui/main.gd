extends Control

var welcome: WelcomeView
var main_view: Control
var top_bar: TopBar
var skill_sidebar: SkillSidebar
var work_center: WorkCenterView
var detail_panel: DetailPanel
var toast: ToastView
var inventory_overlay: InventoryView
var character_overlay: CharacterView

const TICK_INTERVAL := 0.02   # 逻辑层节流步进间隔（秒）

var _accum := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ThemeDB.fallback_font_size = 20

	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	welcome = WelcomeView.new()
	add_child(welcome)
	welcome.game_started.connect(_on_game_started)

	main_view = VBoxContainer.new()
	main_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_view.visible = false
	main_view.add_theme_constant_override("separation", 0)
	add_child(main_view)

	top_bar = TopBar.new()
	main_view.add_child(top_bar)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	main_view.add_child(content)

	skill_sidebar = SkillSidebar.new()
	skill_sidebar.custom_minimum_size = Vector2(300, 0)
	content.add_child(skill_sidebar)

	work_center = WorkCenterView.new()
	work_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var center_wrap := PanelContainer.new()
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrap.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL, 0))
	center_wrap.add_child(work_center)
	content.add_child(center_wrap)

	detail_panel = DetailPanel.new()
	detail_panel.custom_minimum_size = Vector2(440, 0)
	content.add_child(detail_panel)

	work_center.action_selected.connect(_on_action_selected)
	skill_sidebar.skill_selected.connect(work_center.scroll_to_skill)
	top_bar.debug_step.connect(_on_debug_step)
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
	_refresh()

func _on_action_selected(action_id: String) -> void:
	detail_panel.select_action(action_id)
	detail_panel.refresh()

# 调试：每点一次多结算 30 秒（经操作队列，回拨上次更新时间）
func _on_debug_step() -> void:
	if GameState.save == null:
		return
	GameState.append_operation(Operation.TYPE_DEBUG_STEP, "30")
	GameState.update(Time.get_unix_time_from_system())
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
	skill_sidebar.refresh()
	work_center.refresh()
	detail_panel.refresh()
