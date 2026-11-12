extends Control
const AISLE = preload("res://assets/menu/midnight-aisle.png")
const TITLE = preload("res://assets/menu/midnight-title.png")
const Palette = preload("res://scripts/midnight_theme.gd")
var motion_enabled := true
var drift := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	var target := Vector2.ZERO
	if motion_enabled:
		target = (get_local_mouse_position() / Vector2(1280, 720) - Vector2(0.5, 0.5)).clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5)) * 9.0
	drift = drift.lerp(target, 1.0 - exp(-delta * 4.0)) if motion_enabled else Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Palette.INK)
	draw_texture_rect(AISLE, Rect2(Vector2(-9, -6) + drift, Vector2(1298, 732)), false)
	# The title stays still while the aisle subtly follows the pointer.
	draw_texture_rect(TITLE, Rect2(49, 53, 474, 260), false)
	draw_rect(Rect2(0, 666, 1280, 54), Palette.INK)
	draw_line(Vector2(36, 666), Vector2(1244, 666), Color("6a517a"), 1)
	for i: int in range(52):
		var bar_width: float = 1.0 + float((i * 7) % 3)
		draw_rect(Rect2(1065 + i * 3, 684, bar_width, 16), Palette.MUTED)
