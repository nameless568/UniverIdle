class_name UiTheme
extends RefCounted

# 主界面统一配色（图示深色系，陶土强调色沿用资源清单）
const BG := Color("#232a29")        # 页底
const BG_DARK := Color("#1d2322")   # 顶栏（比页底深一档）
const PANEL := Color("#2e3836")     # 面板
const PANEL_DARK := Color("#272f2d")  # 凹槽/卡底
const INK := Color("#e4e0d8")       # 浅墨线/正文
const INK_DIM := Color("#9a978f")   # 次要文字
const ACCENT := Color("#c87048")    # 陶土强调
const TEAL := Color("#72a898")      # 灰青（进度/选中）

static func panel_style(color: Color = PANEL, corner := 6, border_color: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	if border_color.a > 0.0:
		s.border_color = border_color
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_width_bottom = 2
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func button_style(color: Color = PANEL_DARK, corner := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

# 给按钮套统一三态样式
static func style_button(btn: Button, base: Color = PANEL_DARK) -> void:
	btn.add_theme_stylebox_override("normal", button_style(base))
	btn.add_theme_stylebox_override("hover", button_style(base.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", button_style(base.darkened(0.12)))
	btn.add_theme_stylebox_override("disabled", button_style(base.darkened(0.25)))
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", INK)
	btn.add_theme_color_override("font_pressed_color", INK)
	btn.add_theme_color_override("font_disabled_color", INK_DIM)

static func progress_style(bar: ProgressBar, fill: Color = TEAL) -> void:
	var back := StyleBoxFlat.new()
	back.bg_color = PANEL_DARK
	back.corner_radius_top_left = 3
	back.corner_radius_top_right = 3
	back.corner_radius_bottom_left = 3
	back.corner_radius_bottom_right = 3
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.corner_radius_top_left = 3
	fg.corner_radius_top_right = 3
	fg.corner_radius_bottom_left = 3
	fg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fg)

static func load_texture(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null
