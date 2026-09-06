class_name TopBar
extends PanelContainer

signal open_inventory
signal open_character
signal back_to_welcome
signal debug_step

const GOLD_ICON := "res://assets/temp/ItemIcon/item_gold.png"

var gold_label: Label
var settings_btn: MenuButton

func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.BG_DARK, 0))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	add_child(h)

	# 左：徽记 + 标题
	var logo := ColorRect.new()
	logo.color = UiTheme.ACCENT
	logo.custom_minimum_size = Vector2(26, 26)
	logo.rotation = PI / 4.0
	h.add_child(logo)

	var title := Label.new()
	title.text = "坠星谷 · 银杏村"
	title.add_theme_color_override("font_color", UiTheme.INK)
	h.add_child(title)

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer_l)

	# 中：金币
	var gold_icon := TextureRect.new()
	gold_icon.texture = UiTheme.load_texture(GOLD_ICON)
	gold_icon.custom_minimum_size = Vector2(26, 26)
	gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	h.add_child(gold_icon)

	gold_label = Label.new()
	gold_label.add_theme_color_override("font_color", UiTheme.INK)
	h.add_child(gold_label)

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer_r)

	# 右：图鉴（占位）/ 背包 / 设置
	var codex_btn := Button.new()
	codex_btn.text = "图鉴"
	codex_btn.disabled = true
	UiTheme.style_button(codex_btn)
	h.add_child(codex_btn)

	var inv_btn := Button.new()
	inv_btn.text = "背包"
	UiTheme.style_button(inv_btn)
	inv_btn.pressed.connect(func(): open_inventory.emit())
	h.add_child(inv_btn)

	settings_btn = MenuButton.new()
	settings_btn.text = "设置"
	settings_btn.flat = false
	UiTheme.style_button(settings_btn)
	var popup := settings_btn.get_popup()
	popup.add_item("角色改名", 0)
	popup.add_item("返回标题", 1)
	# 可勾选项 + 禁止勾选后隐藏，使 debug 可连续点按且菜单不收起
	popup.add_check_item("debug：↑快↑速↑地↑等↑", 2)
	popup.hide_on_checkable_item_selection = false
	popup.id_pressed.connect(_on_settings_id)
	h.add_child(settings_btn)

func _on_settings_id(id: int) -> void:
	match id:
		0:
			open_character.emit()
		1:
			back_to_welcome.emit()
		2:
			debug_step.emit()
			settings_btn.get_popup().set_item_checked(2, false)

func refresh() -> void:
	if GameState.save == null:
		return
	gold_label.text = str(GameState.save.character.inventory.gold())
