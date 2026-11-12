extends Button
## Native Button hit target, animated receipt artwork.
const Palette = preload("res://scripts/midnight_theme.gd")
var index_text := "01"
var motion_enabled := true
var selected := false
var reveal := 1.0
var activation := 0.0
var compression := 0.0
var _font: Font
var _tween: Tween
var _entrance: Tween
var _press: Tween

func _ready() -> void:
	_font = Palette.heading_font()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	mouse_entered.connect(func(): grab_focus())
	focus_entered.connect(func(): _select(true))
	focus_exited.connect(func(): _select(false))
	button_down.connect(func(): _compress(1.0))
	button_up.connect(func(): _compress(0.0))

func _process(_delta: float) -> void:
	queue_redraw()

func enter(delay: float) -> void:
	if not motion_enabled: return
	reveal = 0.0
	_entrance = create_tween()
	_entrance.tween_interval(delay)
	_entrance.tween_property(self, "reveal", 1.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_motion(value: bool) -> void:
	motion_enabled = value
	if value: return
	for tween: Tween in [_tween, _entrance, _press]:
		if tween: tween.kill()
	reveal = 1.0
	activation = 1.0 if has_focus() else 0.0
	compression = 0.0

func _select(value: bool) -> void:
	selected = value
	if _tween: _tween.kill()
	if not motion_enabled:
		activation = 1.0 if value else 0.0
		return
	_tween = create_tween()
	_tween.tween_property(self, "activation", 1.0 if value else 0.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _compress(value: float) -> void:
	if _press: _press.kill()
	if not motion_enabled:
		compression = value
		return
	_press = create_tween()
	_press.tween_property(self, "compression", value, 0.07)

func _draw() -> void:
	if _font == null: return
	var slide: float = -65.0 * (1.0 - reveal) + activation * 12.0
	var tilt: float = deg_to_rad(-1.0) * activation
	var squeeze: float = 1.0 - compression * 0.035
	draw_set_transform(Vector2(slide, 0), tilt, Vector2(squeeze, squeeze))
	var w: float = size.x - 16
	var h: float = size.y - 3
	var paper := PackedVector2Array([Vector2(3, 3), Vector2(w - 17, 0), Vector2(w, 8), Vector2(w - 8, h * 0.45), Vector2(w, h - 7), Vector2(0, h)])
	var shadow := PackedVector2Array()
	for p: Vector2 in paper: shadow.append(p + Vector2(5, 5))
	var opacity: float = clampf(reveal, 0.0, 1.0)
	draw_colored_polygon(shadow, Color(Palette.PINK, opacity * activation))
	var bg: Color = Color("251b32").lerp(Palette.ACID, activation)
	bg.a = opacity
	draw_colored_polygon(paper, bg)
	var ink: Color = Palette.PAPER.lerp(Palette.INK, activation)
	ink.a = opacity
	draw_string(ThemeDB.fallback_font, Vector2(17, 33), index_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_line(Vector2(47, 12), Vector2(47, h - 10), Color(ink, opacity * 0.4), 1.0)
	draw_string(_font, Vector2(61, 34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, ink)
	if activation > 0.05:
		draw_string(_font, Vector2(w - 40, 34), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(ink, opacity * activation))
	draw_set_transform(Vector2.ZERO)
