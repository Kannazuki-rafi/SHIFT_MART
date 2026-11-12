extends RefCounted
## Shared palette and control styles for MIDNIGHT SHIFT menus.
const INK := Color("151020")
const PAPER := Color("fff1d1")
const ACID := Color("e3fa65")
const PINK := Color("ff6498")
const MUTED := Color("bdb0cc")

static func heading_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 1.4
	return font

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", PAPER)
	for type: String in ["Button", "LineEdit", "CheckButton", "LinkButton"]:
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(state, type, PAPER)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("30253e") if state == "normal" else Color("4a3857")
		box.set_corner_radius_all(0)
		box.set_content_margin_all(12)
		box.content_margin_left = 18
		box.content_margin_right = 18
		if state == "focus":
			box.bg_color = Color.TRANSPARENT
			box.set_border_width_all(2)
			box.border_color = ACID
		theme.set_stylebox(state, "Button", box)
	for state: String in ["normal", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = INK
		box.set_content_margin_all(10)
		box.set_border_width_all(2)
		box.border_color = ACID if state == "focus" else Color("6e5c7d")
		theme.set_stylebox(state, "LineEdit", box)
	theme.set_color("caret_color", "LineEdit", ACID)
	theme.set_color("selection_color", "LineEdit", Color("674b80"))
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("font_hover_color", "LinkButton", ACID)
	return theme
