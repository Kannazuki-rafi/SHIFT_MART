extends Control
## All basket, frame and wheel vertices use the same isometric projection.
var elapsed: float = 0.0
var motion_enabled: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if motion_enabled:
		elapsed += delta
		queue_redraw()

func project_point(point: Vector3) -> Vector2:
	return Vector2(265, 535) + Vector2(point.x * 0.88 + point.z * 0.62, point.x * 0.23 - point.z * 0.36 - point.y)

func rail(a: Vector3, b: Vector3, color: Color, width: float = 3.0) -> void:
	draw_line(project_point(a), project_point(b), color, width, true)

func face(points: Array[Vector3], color: Color) -> void:
	var polygon := PackedVector2Array()
	for point: Vector3 in points:
		polygon.append(project_point(point))
	draw_colored_polygon(polygon, color)

func wheel(x: float, z: float) -> void:
	var center: Vector2 = project_point(Vector3(x, 13, z))
	rail(Vector3(x, 39, z), Vector3(x, 15, z), Color("a3bac0"), 5)
	draw_set_transform(center, 0, Vector2(0.70, 1.0))
	draw_circle(Vector2.ZERO, 14, Color("080e16"))
	draw_arc(Vector2.ZERO, 9, 0, TAU, 32, Color("78929d"), 3, true)
	draw_circle(Vector2.ZERO, 3, Color("d6f663"))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var steel := Color("8da9b4")
	var rim := Color("d6f663")
	draw_rect(Rect2(0, 0, 1280, 720), Color("101923"))
	draw_circle(Vector2(260, 420), 245, Color("152831"))
	for i: int in range(7):
		var y: float = 410 + i * 35
		draw_line(Vector2(40, y), Vector2(530, y), Color("20363f"), 1, true)
	draw_set_transform(Vector2(280, 559), 0, Vector2(1, 0.16))
	draw_circle(Vector2.ZERO, 192, Color(0.02, 0.04, 0.06, 0.55))
	draw_set_transform(Vector2.ZERO)
	wheel(-112, 65)
	wheel(105, 65)
	for z: float in [-65.0, 65.0]:
		rail(Vector3(-112, 39, z), Vector3(105, 39, z), steel, 6)
		rail(Vector3(-112, 39, z), Vector3(-145, 201, z), steel, 6)
		rail(Vector3(-145, 201, z), Vector3(-165, 211, z), steel, 6)
		rail(Vector3(-70, 45, z), Vector3(95, 91, z), steel, 4)
	rail(Vector3(-112, 39, -65), Vector3(-112, 39, 65), steel, 5)
	rail(Vector3(105, 39, -65), Vector3(105, 39, 65), steel, 5)
	var a := Vector3(-115, 185, -78)
	var b := Vector3(135, 185, -78)
	var c := Vector3(135, 185, 78)
	var d := Vector3(-115, 185, 78)
	var e := Vector3(-88, 94, -56)
	var f := Vector3(105, 94, -56)
	var g := Vector3(105, 94, 56)
	var h := Vector3(-88, 94, 56)
	face([d, c, g, h], Color("28434a"))
	face([e, f, g, h], Color("1c3039"))
	face([b, c, g, f], Color("304b51"))
	face([a, b, f, e], Color("223a43"))
	for i: int in range(1, 11):
		var t: float = i / 11.0
		rail(a.lerp(b, t), e.lerp(f, t), steel, 1.5)
	for i: int in range(1, 6):
		var t: float = i / 6.0
		rail(b.lerp(c, t), f.lerp(g, t), steel, 1.5)
	for i: int in range(1, 4):
		var t: float = i / 4.0
		rail(a.lerp(e, t), b.lerp(f, t), steel, 1.5)
		rail(b.lerp(f, t), c.lerp(g, t), steel, 1.5)
	for edge: Array in [[a,b],[b,c],[c,d],[d,a],[a,e],[b,f],[c,g],[d,h],[e,f],[f,g],[g,h],[h,e]]:
		rail(edge[0], edge[1], rim, 3)
	rail(Vector3(-165, 211, -65), Vector3(-165, 211, 65), Color("ff9654"), 9)
	wheel(-112, -65)
	wheel(105, -65)
