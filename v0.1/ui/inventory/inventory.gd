class_name InventoryView
extends Control

signal closed

const SLOT_SIZE := 84
const GRID_COLUMNS := 6

const CATEGORY_NAMES := {
	"junk": "杂物",
	"monster": "魔物材料",
	"herb": "草药",
	"relic": "遗物",
	"wood": "木材",
	"ore": "矿石",
	"tool": "工具",
	"system": "系统",
}

var _cap_label: Label
var _gold_label: Label
var _grid: GridContainer
var _detail_icon: TextureRect
var _detail_name: Label
var _detail_cat: Label
var _detail_count: Label
var _detail_desc: Label
var _detail_hint: Label
var _detail_sep: HSeparator
var _detail_box: VBoxContainer

var _selected_id := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -480
	panel.offset_right = 480
	panel.offset_top = -310
	panel.offset_bottom = 310
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL, 10))
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	# 顶栏：标题 + 容量/金币 + 关闭
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var title := Label.new()
	title.text = "背包"
	title.add_theme_color_override("font_color", UiTheme.INK)
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)

	_cap_label = Label.new()
	_cap_label.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_cap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_cap_label)

	_gold_label = Label.new()
	_gold_label.add_theme_color_override("font_color", Color("#e8c66a"))
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_gold_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close := Button.new()
	close.text = "关闭"
	UiTheme.style_button(close, UiTheme.PANEL_DARK)
	close.pressed.connect(func(): closed.emit())
	header.add_child(close)

	# 主体：左格子 + 右侧展示
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	body.add_child(left)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)

	var buy := Button.new()
	buy.text = "购买背包格（+1）"
	buy.custom_minimum_size = Vector2(0, 44)
	UiTheme.style_button(buy, UiTheme.ACCENT.darkened(0.25))
	buy.pressed.connect(_on_buy)
	left.add_child(buy)

	body.add_child(_build_detail_panel())

func _build_detail_panel() -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(300, 0)
	wrap.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL_DARK, 8))

	_detail_box = VBoxContainer.new()
	_detail_box.add_theme_constant_override("separation", 10)
	wrap.add_child(_detail_box)

	_detail_hint = Label.new()
	_detail_hint.text = "点击左侧格子查看物品。"
	_detail_hint.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_box.add_child(_detail_hint)

	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(0, 180)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_box.add_child(_detail_icon)

	_detail_name = Label.new()
	_detail_name.add_theme_color_override("font_color", UiTheme.INK)
	_detail_name.add_theme_font_size_override("font_size", 26)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_box.add_child(_detail_name)

	_detail_cat = Label.new()
	_detail_cat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_box.add_child(_detail_cat)

	_detail_count = Label.new()
	_detail_count.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_detail_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_box.add_child(_detail_count)

	_detail_sep = HSeparator.new()
	_detail_box.add_child(_detail_sep)

	_detail_desc = Label.new()
	_detail_desc.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_box.add_child(_detail_desc)

	return wrap

func refresh() -> void:
	if GameState.save == null:
		return
	var inv: Inventory = GameState.save.character.inventory
	_cap_label.text = "格子 %d/%d" % [inv.occupied_slots(), inv.capacity]
	_gold_label.text = "金币 %d" % inv.gold()

	# 物品 id 列表（不含金币、数量为 0 的）
	var ids: Array = []
	for item_id in inv.items:
		if item_id == Inventory.GOLD_ITEM_ID:
			continue
		if int(inv.items[item_id]) <= 0:
			continue
		ids.append(item_id)

	# 选中项失效时回退到第一个
	if _selected_id == "" or not ids.has(_selected_id):
		_selected_id = ids[0] if ids.size() > 0 else ""

	_rebuild_grid(ids, inv)

	# 空格子补满到容量
	var empty := inv.capacity - ids.size()
	for i in empty:
		_grid.add_child(_make_slot("", 0))

	_rebuild_detail(inv)

func _rebuild_grid(ids: Array, inv: Inventory) -> void:
	for c in _grid.get_children():
		c.queue_free()
	for item_id in ids:
		_grid.add_child(_make_slot(item_id, int(inv.items[item_id])))

func _make_slot(item_id: String, amount: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var selected := item_id != "" and item_id == _selected_id
	if selected:
		slot.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL_DARK, 8, UiTheme.ACCENT))
	else:
		slot.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL_DARK, 8))

	if item_id == "":
		return slot

	# PanelContainer 只负责底色，内部用一层 Control 承载图标与角标
	var inner := Control.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot.add_child(inner)

	var icon := TextureRect.new()
	icon.texture = UiTheme.load_texture(GameState.config_items[item_id].icon)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 8
	icon.offset_top = 8
	icon.offset_right = -8
	icon.offset_bottom = -8
	inner.add_child(icon)

	var badge := Label.new()
	badge.text = "×%d" % amount
	badge.add_theme_color_override("font_color", UiTheme.INK)
	badge.add_theme_font_size_override("font_size", 16)
	badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.offset_left = -42
	badge.offset_top = -26
	badge.offset_right = -6
	badge.offset_bottom = -4
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inner.add_child(badge)

	slot.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_selected_id = item_id
			refresh())

	return slot

func _rebuild_detail(inv: Inventory) -> void:
	var has := _selected_id != ""
	_detail_hint.visible = not has
	_detail_icon.visible = has
	_detail_name.visible = has
	_detail_cat.visible = has
	_detail_count.visible = has
	_detail_sep.visible = has
	_detail_desc.visible = has
	if not has:
		return
	var item: ItemDef = GameState.config_items[_selected_id]
	_detail_icon.texture = UiTheme.load_texture(item.icon)
	_detail_name.text = item.name
	_detail_cat.text = CATEGORY_NAMES.get(item.category, item.category)
	_detail_cat.add_theme_color_override("font_color", UiTheme.TEAL)
	_detail_count.text = "拥有 ×%d" % int(inv.items[_selected_id])
	_detail_desc.text = item.description

func _on_buy() -> void:
	GameState.append_operation(Operation.TYPE_BUY_SLOTS, "1")
	GameState.update(Time.get_unix_time_from_system())
	refresh()
