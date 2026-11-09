extends Control
## Original vector title art, kept independent of race simulation and networking.
var elapsed: float = 0.0
var motion_enabled: bool = true
var pointer: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not motion_enabled: return
	elapsed += delta
	pointer = pointer.lerp(((get_local_mouse_position() - Vector2(640,360)) / 90.0).clamp(Vector2(-7,-4),Vector2(7,4)), minf(delta * 3.0,1.0))
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("10151d"))
	# Slanted aisle markings and receding supermarket floor.
	draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(660,0),Vector2(475,720),Vector2(0,720)]),Color("192a30"))
	for i: int in range(12):
		var x: float = float(i) * 80.0 - 320.0
		draw_line(Vector2(310,340),Vector2(x+300,660),Color("294149"),1.0,true)
	for y: int in [390,425,475,540,625]:
		draw_line(Vector2(0,y),Vector2(600,y),Color("294149"),1.0,true)
	for i: int in range(5):
		var x: float = 24.0 + i * 120.0
		draw_line(Vector2(x,0),Vector2(x+40,0),Color("d6f663"),5.0)
	# Speed trails remain below the title.
	for i: int in range(7):
		var x: float = fmod(elapsed * 42.0 + i * 83.0,560.0)
		draw_line(Vector2(x,410+i*20),Vector2(x+38,410+i*20),Color(0.4,0.8,0.76,0.18),2.0,true)
	var drift: Vector2 = pointer + Vector2(0,sin(elapsed*1.7)*3.0)
	draw_set_transform(Vector2(114,355)+drift,-0.09,Vector2.ONE)
	draw_ellipse_shadow()
	# Rear frame, handle and wheels.
	var lime: Color = Color("d6f663")
	var steel: Color = Color("8facb5")
	for wheel: Vector2 in [Vector2(86,163),Vector2(277,144),Vector2(191,190)]:
		draw_circle(wheel,19,Color("080d13"))
		draw_arc(wheel,13,0,TAU,32,steel,4,true)
		draw_circle(wheel,4,lime)
	draw_polyline(PackedVector2Array([Vector2(86,159),Vector2(59,14),Vector2(19,-1),Vector2(-6,7)]),steel,7,true)
	draw_line(Vector2(-7,7),Vector2(20,-1),Color("ff9654"),11,true)
	draw_polyline(PackedVector2Array([Vector2(80,149),Vector2(190,176),Vector2(282,132),Vector2(103,99)]),steel,6,true)
	var basket: PackedVector2Array = PackedVector2Array([Vector2(55,24),Vector2(238,-9),Vector2(320,33),Vector2(284,118),Vector2(124,149),Vector2(73,106)])
	draw_colored_polygon(basket,Color("263f47"))
	draw_polyline(PackedVector2Array([basket[0],basket[1],basket[2],basket[3],basket[4],basket[5],basket[0]]),lime,5,true)
	draw_line(Vector2(55,24),Vector2(137,65),lime,5,true)
	draw_line(Vector2(137,65),Vector2(320,33),lime,5,true)
	draw_line(Vector2(137,65),Vector2(124,149),lime,4,true)
	for i: int in range(1,8):
		var t: float = i/8.0
		draw_line(Vector2(137,65).lerp(Vector2(320,33),t),Vector2(124,149).lerp(Vector2(284,118),t),steel,2,true)
	for i: int in range(1,4):
		var t: float = i/4.0
		draw_line(Vector2(137,65).lerp(Vector2(124,149),t),Vector2(320,33).lerp(Vector2(284,118),t),steel,2,true)
	# Racing number plate.
	draw_rect(Rect2(183,75,63,43),Color("ff9654"))
	draw_string(ThemeDB.fallback_font,Vector2(193,107),"01",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("10151d"))
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(314,553)+pointer,0,Vector2(1,0.2))
	draw_circle(Vector2.ZERO,167,Color(0.02,0.04,0.06,0.5))
	draw_set_transform(Vector2(114,355)+pointer+Vector2(0,sin(elapsed*1.7)*3.0),-0.09,Vector2.ONE)
