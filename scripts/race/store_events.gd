extends Node3D
## Host advances gameplay; every peer derives visuals from compact event timestamps.
const CABINET_WARNING: int = 60
const CABINET_IMPACT: float = 1.49 * 60.0
const CABINET_DOWN_END: int = 300
const CABINET_RESET_END: int = 360
const CABINET_CYCLE: int = 1080
const FRUIT_DROP: int = 36
const FRUIT_LAND: int = 60
const FRUIT_CLEAR: int = 555
const FRUIT_CYCLE: int = 900
const STUN_TICKS: int = 45
const FRUIT_OFFSETS: Array[Vector3] = [
	Vector3(-1.1,0,-1.8),Vector3(1,0,-0.9),Vector3(-0.4,0,0.2),
	Vector3(1.1,0,1.3),Vector3(-1,0,2.3),
]
const SITES: Array[Dictionary] = [
	{"kind":"cabinet", "pos":Vector3(27,0,4), "yaw":-PI/2},
	{"kind":"cabinet", "pos":Vector3(-4,0,55), "yaw":0.0},
	{"kind":"cabinet", "pos":Vector3(10,0,-55), "yaw":PI},
	{"kind":"fruit", "pos":Vector3(46.5,0,20), "yaw":PI/2},
	{"kind":"fruit", "pos":Vector3(35.5,0,27), "yaw":PI/2},
]
var events: Array[Dictionary] = []

func _ready() -> void:
	for site: Dictionary in SITES:
		var root := Node3D.new()
		root.position = site.pos
		root.rotation.y = site.yaw
		add_child(root)
		var cabinet: bool = site.kind == "cabinet"
		var body := StaticBody3D.new()
		root.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(3,5,1) if cabinet else Vector3(2.8,1.3,1.3)
		collision.shape = shape
		collision.position.y = shape.size.y*0.5
		body.add_child(collision)
		if cabinet:
			body.set_meta("cabinet_event", events.size())
			body.set_meta("store_events", self)
		var pivot := Node3D.new()
		root.add_child(pivot)
		var color := Color("7193a3") if cabinet else Color("a67c4c")
		_mesh_box(pivot,Vector3(3,0.2,1.2),Vector3(0,0.1,0),color)
		if cabinet:
			_mesh_box(pivot,Vector3(3,5,0.12),Vector3(0,2.5,0.45),color.darkened(0.3))
			for side: float in [-1.45,1.45]:
				_mesh_box(pivot,Vector3(0.1,5,1.1),Vector3(side,2.5,0),color)
			for shelf: int in 4:
				_mesh_box(pivot,Vector3(3,0.12,1.2),Vector3(0,1.1+shelf*1.15,0),color)
				for item: int in 3:
					_mesh_box(pivot,Vector3(0.55,0.6,0.65),Vector3(item-1,1.45+shelf*1.15,0),Color("e6b77b"))
		else:
			_mesh_box(pivot,Vector3(2.8,1.2,1.3),Vector3(0,0.6,0),color)
			for item: int in 7:
				_fruit(pivot,Vector3(-1.05+item*0.35,1.4,0),item)
		var marker: MeshInstance3D = _mesh_box(root,Vector3(4.2,0.025,6.2) if cabinet else Vector3(3.4,0.025,6.2),Vector3(0,0.04,-2.5),Color("f02f41") if cabinet else Color("ffbc3d"))
		var material := marker.material_override as StandardMaterial3D
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var warning := Label3D.new()
		warning.text = "! FALLING CABINET !" if cabinet else "! FALLING FRUIT !"
		warning.font_size = 40
		warning.pixel_size = 0.012
		warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		warning.position = Vector3(0,2.5,-2.5)
		warning.modulate = Color("ff5964") if cabinet else Color("ffce6e")
		root.add_child(warning)
		var fruits: Array[MeshInstance3D] = []
		if not cabinet:
			for i: int in FRUIT_OFFSETS.size():
				fruits.append(_fruit(root,Vector3.ZERO,i))
		events.append({"root":root,"pivot":pivot,"collision":collision,"marker":marker,"warning":warning,"fruits":fruits,"cabinet":cabinet,"trigger":-1,"mask":0,"impact_done":false})
	render(0)

func _mesh_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

func _fruit(parent: Node3D, pos: Vector3, index: int) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.5
	sphere.radial_segments = 8
	sphere.rings = 4
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("f79432") if index%2 == 0 else Color("a6d34c")
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

func _eligible(cart, tick: int) -> bool:
	return not cart.repairing and cart.finish_tick < 0 and tick >= cart.protection_end

func advance(tick: int, carts: Dictionary, active: bool) -> void:
	if not multiplayer.is_server() or not active: return
	for event: Dictionary in events:
		var cycle: int = CABINET_CYCLE if event.cabinet else FRUIT_CYCLE
		if event.trigger >= 0 and tick-event.trigger >= cycle:
			event.trigger = -1
			event.mask = 0
			event.impact_done = false
		if event.trigger < 0:
			var center: Vector3 = event.root.to_global(Vector3(0,0,-2.5))
			for cart in carts.values():
				if _eligible(cart,tick) and cart.position.distance_to(center) < 12:
					event.trigger = tick
					break
			continue
		var age: int = tick-event.trigger
		if event.cabinet:
			if age >= CABINET_IMPACT and not event.impact_done:
				event.impact_done = true
				for cart in carts.values():
					if not _eligible(cart,tick): continue
					var local: Vector3 = event.root.to_local(cart.position)
					if absf(local.x) <= 2.1 and local.z >= -5.6 and local.z <= 0.6 and absf(local.y) < 2:
						cart.damage(25,tick)
						cart.trigger_stun(tick,STUN_TICKS)
		elif age >= FRUIT_LAND and age < FRUIT_CLEAR:
			for i: int in FRUIT_OFFSETS.size():
				if event.mask & (1 << i): continue
				var pos: Vector3 = event.root.to_global(Vector3(0,0,-2.5)+FRUIT_OFFSETS[i])
				for cart in carts.values():
					if _eligible(cart,tick) and cart.position.distance_to(pos) < 1.0:
						cart.trigger_slip(tick,75)
						cart.velocity *= 0.7
						event.mask |= 1 << i
						break

func break_cabinet(index: int, tick: int) -> void:
	if not multiplayer.is_server(): return
	var event: Dictionary = events[index]
	var age: int = tick-event.trigger if event.trigger >= 0 else -1
	if age < CABINET_IMPACT or age >= CABINET_DOWN_END or event.mask != 0: return
	event.mask = 1
	event.pivot.visible = false
	event.collision.disabled = true

func state_data() -> PackedInt32Array:
	var state := PackedInt32Array()
	for event: Dictionary in events:
		state.append(event.trigger)
		state.append(event.mask)
	return state

func apply_state(state: PackedInt32Array) -> void:
	if state.size() != events.size()*2: return
	for i: int in events.size():
		events[i].trigger = state[i*2]
		events[i].mask = state[i*2+1]

func render(tick: int) -> void:
	for event: Dictionary in events:
		var age: int = tick-event.trigger if event.trigger >= 0 else -1
		var landing: float = CABINET_IMPACT if event.cabinet else FRUIT_LAND
		event.marker.visible = age >= 0 and age < landing
		event.warning.visible = event.marker.visible
		if event.marker.visible:
			var material := event.marker.material_override as StandardMaterial3D
			material.albedo_color = (Color("ff2943") if event.cabinet else Color("ffbc3d")).lerp(Color.WHITE,0.15 if tick%24 < 12 else 0.0)
		if event.cabinet:
			var angle: float = 0.0
			if age >= CABINET_WARNING and age < CABINET_IMPACT:
				angle = -PI*0.5*pow(float(age-CABINET_WARNING)/float(CABINET_IMPACT-CABINET_WARNING),2)
			elif age >= CABINET_IMPACT and age < CABINET_DOWN_END:
				angle = -PI*0.5
			elif age >= CABINET_DOWN_END and age < CABINET_RESET_END:
				angle = lerpf(-PI*0.5,0.0,float(age-CABINET_DOWN_END)/float(CABINET_RESET_END-CABINET_DOWN_END))
			event.pivot.rotation.x = angle
			var fallen: bool = age >= CABINET_IMPACT and age < CABINET_DOWN_END
			event.pivot.visible = event.mask == 0
			event.collision.rotation.x = -PI*0.5 if fallen else 0.0
			event.collision.position = Vector3(0,0.5,-2.5) if fallen else Vector3(0,2.5,0)
			event.collision.disabled = event.mask != 0 or (age >= CABINET_WARNING and age < CABINET_RESET_END and not fallen)
		else:
			for i: int in event.fruits.size():
				var fruit: MeshInstance3D = event.fruits[i]
				fruit.visible = age >= FRUIT_DROP and age < FRUIT_CLEAR and not (event.mask & (1 << i))
				if not fruit.visible: continue
				var progress: float = clampf(float(age-FRUIT_DROP)/float(FRUIT_LAND-FRUIT_DROP),0,1)
				var target: Vector3 = Vector3(0,0.25,-2.5)+FRUIT_OFFSETS[i]
				fruit.position = Vector3(target.x,2,0).lerp(target,progress)
				fruit.position.y += sin(progress*PI)*0.8
