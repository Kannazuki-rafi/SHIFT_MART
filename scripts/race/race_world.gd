extends Node3D
const Cart = preload("res://scripts/race/trolley_controller.gd")
const TUNING = preload("res://resources/balance.tres")
const COLORS: Array[Color] = [Color("d6f663"),Color("ffad62"),Color("65d8d0"),Color("e29dc9"),Color("929ef5")]

# One authored circuit. Every branch rejoins before the next shared checkpoint.
const GATES: Array[Vector3] = [
	Vector3(23,0,-23), Vector3(31,0,-14), Vector3(31,0,0),
	Vector3(31,0,14), Vector3(20,0,23), Vector3(0,0,23),
	Vector3(-20,0,23), Vector3(-31,0,14), Vector3(-31,0,0),
	Vector3(-31,0,-14), Vector3(-24,0,-23), Vector3(16,0,-23),
]
const DIRECTIONS: Array[Vector3] = [
	Vector3.RIGHT, Vector3.BACK, Vector3.BACK, Vector3.BACK,
	Vector3.LEFT, Vector3.LEFT, Vector3.LEFT, Vector3.FORWARD,
	Vector3.FORWARD, Vector3.FORWARD, Vector3.RIGHT, Vector3.RIGHT,
]
const CHECKPOINT_HALF_WIDTH: float = 9.0
const PUDDLES: Array[Dictionary] = [
	{"pos":Vector3(0,0,28), "size":Vector2(7,4)},
]
const PICKUP_STANDS: Array[Dictionary] = [
	{"pos":Vector3(26,0,5), "item":"banana"},
	{"pos":Vector3(36,0,5), "item":"banana"},
	{"pos":Vector3(-6,0,19), "item":"can"},
	{"pos":Vector3(-6,0,28), "item":"can"},
	{"pos":Vector3(-31,0,-3), "item":"banana"},
	{"pos":Vector3(19,0,-23), "item":"can"},
]
# Entrances close; exits always stay open. Blue/Orange are route identities.
const FORKS: Array[Dictionary] = [
	{"name":"PRODUCE", "a":Vector3(26,0,-10), "b":Vector3(36,0,-10), "forward":Vector3.BACK, "size":Vector3(8,1.1,0.5)},
	{"name":"FREEZER", "a":Vector3(14,0,28), "b":Vector3(14,0,19), "forward":Vector3.LEFT, "size":Vector3(0.5,1.1,7.5)},
	{"name":"CHECKOUT", "a":Vector3(-14,0,-19), "b":Vector3(-14,0,-28), "forward":Vector3.RIGHT, "size":Vector3(0.5,1.1,7.5)},
]
var route_gates: Array[Dictionary] = []
var fork_arrows: Array[MeshInstance3D] = []
var layout: int = 0
var shift_owner: int = 0
var shift_at: int = -1
var shift_available: int = 0
var lap_notice_until: int = 0

var pickup_cooldowns: Dictionary = {}  # stand index -> tick when available again
var pickup_visuals: Array[Dictionary] = []  # visual references for floating pickup items
var carts: Dictionary = {}
var cans: Array = []  # straight canned-drink projectiles
var peels: Array[Dictionary] = []
var item_was_pressed: bool = false
var tick: int = 0
var start_tick: int = 180
var deadline_tick: int = 18180
var complete: bool = false
var pair_cooldowns: Dictionary = {}
var previous_positions: Dictionary = {}
var camera: Camera3D
var camera_started: bool = false
var local_id: int = 1
var input_sequence: int = 0
var input_elapsed: float = 0.0
var snapshot_elapsed: float = 0.0
var session_id: int = 0
var local_menu: bool = false

func _ready() -> void:
	Session.input_received.connect(_input_received)
	Session.snapshot_received.connect(_receive)
	Session.changed.connect(_roster_changed)
	Session.shift_received.connect(request_shift)
	_environment()
	_track()
	camera = Camera3D.new()
	camera.fov = 65
	camera.far = 240
	add_child(camera)
	camera.current = true

func setup(players: Dictionary, id: int) -> void:
	session_id = id
	local_id = multiplayer.get_unique_id()
	var ids: Array = players.keys()
	ids.sort()
	# Starting grid sits in the initially open Blue checkout branch.
	# Carts spawn facing East (rotation.y = -PI / 2) with next_checkpoint = 0
	for index: int in ids.size():
		var cart = Cart.new()
		cart.peer_id = ids[index]
		cart.paint = COLORS[index % COLORS.size()]
		cart.position = Vector3(-6.0 - float(index / 2) * 3.2, 0.0, -19.0 + float(index % 2) * 2.0 - 1.0)
		cart.rotation.y = -PI / 2.0
		cart.safe_position = cart.position
		cart.safe_yaw = cart.rotation.y
		add_child(cart)
		cart.label.text = players[ids[index]].name
		carts[ids[index]] = cart
		previous_positions[ids[index]] = cart.position

func _environment() -> void:
	var world: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0d1828")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c0daf0")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_color = Color("f4faea")
	light.light_energy = 1.35
	light.shadow_enabled = false
	add_child(light)

func box(size: Vector3, position_value: Vector3, color: Color, solid: bool = false) -> void:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.position = position_value
	add_child(root)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var cube: BoxMesh = BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh.material_override = material
	root.add_child(mesh)
	if solid:
		var shape: CollisionShape3D = CollisionShape3D.new()
		var rectangle: BoxShape3D = BoxShape3D.new()
		rectangle.size = size
		shape.shape = rectangle
		root.add_child(shape)

func puddle(pos: Vector3, size: Vector2) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var cube: BoxMesh = BoxMesh.new()
	cube.size = Vector3(size.x, 0.02, size.y)
	mesh.mesh = cube
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.65, 0.95, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.15
	mesh.material_override = mat
	mesh.position = Vector3(pos.x, 0.012, pos.z)
	add_child(mesh)
	var cone: MeshInstance3D = MeshInstance3D.new()
	var cone_mesh: BoxMesh = BoxMesh.new()
	cone_mesh.size = Vector3(0.4, 0.65, 0.4)
	cone.mesh = cone_mesh
	var cone_mat: StandardMaterial3D = StandardMaterial3D.new()
	cone_mat.albedo_color = Color("f1c40f")
	cone.material_override = cone_mat
	cone.position = Vector3(pos.x + size.x * 0.5 + 0.35, 0.33, pos.z)
	add_child(cone)
	var label_cone: Label3D = Label3D.new()
	label_cone.text = "CAUTION\nWET"
	label_cone.font_size = 28
	label_cone.pixel_size = 0.007
	label_cone.modulate = Color("11222d")
	label_cone.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_cone.position = Vector3(pos.x + size.x * 0.5 + 0.35, 0.85, pos.z)
	add_child(label_cone)

func sign_text(text: String, pos: Vector3, font_size: int = 96, col: Color = Color("d6f663")) -> void:
	var sign_label: Label3D = Label3D.new()
	sign_label.text = text
	sign_label.position = pos
	sign_label.font_size = font_size
	sign_label.pixel_size = 0.008
	sign_label.modulate = col
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sign_label)

func _gantry(pos: Vector3, span: float, is_z_span: bool, title: String, subtitle: String = "JALUR SEARAH / ONE WAY ➔") -> void:
	var pillar_h: float = 4.5
	var p1: Vector3 = Vector3(pos.x, pillar_h * 0.5, pos.z - span * 0.5) if is_z_span else Vector3(pos.x - span * 0.5, pillar_h * 0.5, pos.z)
	box(Vector3(0.6, pillar_h, 0.6), p1, Color("223545"), true)
	var p2: Vector3 = Vector3(pos.x, pillar_h * 0.5, pos.z + span * 0.5) if is_z_span else Vector3(pos.x + span * 0.5, pillar_h * 0.5, pos.z)
	box(Vector3(0.6, pillar_h, 0.6), p2, Color("223545"), true)
	var beam_size: Vector3 = Vector3(0.7, 0.5, span + 0.6) if is_z_span else Vector3(span + 0.6, 0.5, 0.7)
	box(beam_size, Vector3(pos.x, pillar_h + 0.25, pos.z), Color("172633"), false)
	var sign_size: Vector3 = Vector3(0.15, 1.2, minf(span * 0.8, 9.0)) if is_z_span else Vector3(minf(span * 0.8, 9.0), 1.2, 0.15)
	box(sign_size, Vector3(pos.x, pillar_h - 0.45, pos.z), Color("09141c"), false)
	var glabel: Label3D = Label3D.new()
	glabel.text = "%s\n%s" % [title, subtitle]
	glabel.font_size = 48
	glabel.pixel_size = 0.012
	glabel.modulate = Color("d6f663")
	glabel.outline_modulate = Color("0a171c")
	glabel.outline_size = 6
	glabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glabel.no_depth_test = true
	glabel.position = Vector3(pos.x, pillar_h - 0.45, pos.z)
	add_child(glabel)

func _pickup_stand(pos: Vector3, item_type: String, stand_idx: int) -> void:
	var col: Color = Color("f5d45c") if item_type == "banana" else Color("65d8d0")
	# 1. 100% PASS-THROUGH Holographic Floor Pad (solid = false, zero collision, NO stones)
	box(Vector3(2.6, 0.015, 2.6), Vector3(pos.x, 0.008, pos.z), Color(col.r * 0.2, col.g * 0.2, col.b * 0.2, 0.8), false)
	box(Vector3(2.1, 0.02, 2.1), Vector3(pos.x, 0.01, pos.z), col, false)
	box(Vector3(0.5, 0.025, 1.5), Vector3(pos.x, 0.012, pos.z), Color("ffffff"), false)

	# 2. Floating 3D Item Model (PASS-THROUGH, visual only)
	var anchor: Node3D = Node3D.new()
	anchor.position = Vector3(pos.x, 0.85, pos.z)
	add_child(anchor)

	var item_mesh := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = col
	if item_type == "banana":
		var peel := PrismMesh.new()
		peel.size = Vector3(0.8,0.35,0.45)
		item_mesh.mesh = peel
	else:
		var can := CylinderMesh.new()
		can.top_radius = 0.22
		can.bottom_radius = 0.22
		can.height = 0.65
		item_mesh.mesh = can
	item_mesh.material_override = material
	anchor.add_child(item_mesh)

	# 3. Floating 3D Label
	var stand_label: Label3D = Label3D.new()
	stand_label.text = "BANANA / READY" if item_type == "banana" else "CAN / READY"
	stand_label.font_size = 32
	stand_label.pixel_size = 0.008
	stand_label.modulate = col
	stand_label.outline_modulate = Color("0a151a")
	stand_label.outline_size = 4
	stand_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stand_label.position = Vector3(pos.x, 2.05, pos.z)
	add_child(stand_label)

	pickup_visuals.append({
		"anchor": anchor,
		"label": stand_label,
		"col": col,
		"item": item_type,
		"pos": pos,
		"index": stand_idx
	})

func _floor_arrow(pos: Vector3, forward: Vector3, color: Color = Color("d6f663")) -> MeshInstance3D:
	# A real arrow silhouette in world space, readable from either chase direction.
	var side: Vector3 = Vector3.UP.cross(forward).normalized()
	var vertices := PackedVector3Array()
	var points: Array[Vector2] = [Vector2(-0.3,-1.3), Vector2(0.3,-1.3), Vector2(0.3,0), Vector2(1,0), Vector2(0,1.5), Vector2(-1,0), Vector2(-0.3,0)]
	# Shaft quad plus head triangle: fan triangulation would fill the concave corners.
	for j: int in [0,1,2,0,2,6,5,3,4]:
		vertices.append(side * points[j].x + forward * points[j].y + Vector3.UP * 0.025)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	instance.position = pos
	add_child(instance)
	return instance

func _track() -> void:
	box(Vector3(84,0.5,68), Vector3(0,-0.3,0), Color("53636b"), true)
	# Quiet floor, continuous boundaries, low shelves for clear camera sightlines.
	for z: float in [-33,33]:
		box(Vector3(84,2,0.8), Vector3(0,1,z), Color("233b45"), true)
	for x: float in [-41,41]:
		box(Vector3(0.8,2,66), Vector3(x,1,0), Color("233b45"), true)
	for z: float in [-14,14]:
		box(Vector3(44,0.8,0.6), Vector3(0,0.4,z), Color("93a6a6"), true)
	for x: float in [-22,22]:
		box(Vector3(0.6,0.8,28), Vector3(x,0.4,0), Color("93a6a6"), true)
	for x: int in [-16,-5,6,17]:
		box(Vector3(3,0.3,23),Vector3(x,0.15,0),Color("294650"),true)
		for z: float in [-11.5,11.5]:
			box(Vector3(3,1.4,0.25),Vector3(x,0.7,z),Color("294650"),true)
		for row: int in 2:
			box(Vector3(3,0.12,23),Vector3(x,0.6+row*0.65,0),Color("8c9f9e"))
			for z: int in range(-9,10,3):
				for side: float in [-1,1]:
					box(Vector3(0.6,0.4,0.9),Vector3(x+side,0.86+row*0.65,z),COLORS[(row+absi(z))%COLORS.size()])
	# Three fixed splitters separate authored branch pairs; no cross-aisle clutter.
	box(Vector3(1,0.9,17), Vector3(31,0.45,0), Color("567b60"), true)
	box(Vector3(25,1.1,1), Vector3(0,0.55,23.5), Color("739baa"), true)
	box(Vector3(25,1,1), Vector3(0,0.5,-23.5), Color("947454"), true)
	# Produce chicane: short, visible pallets with at least 4m clearance.
	box(Vector3(2,0.55,2), Vector3(23.5,0.275,-3), Color("a58955"), true)
	box(Vector3(2,0.55,2), Vector3(29,0.275,4), Color("a58955"), true)
	for x: int in [-10,0,10]:
		box(Vector3(3,1.2,1.4), Vector3(x,0.6,-23.5), Color("3c5360"))
	for z: int in [-8,0,8]:
		box(Vector3(1.3,1,3), Vector3(39.6,0.5,z), Color("779758"))
	for x: int in [-10,0,10]:
		box(Vector3(4,1.6,0.6), Vector3(x,0.8,32.2), Color("a5cbd5"))
	for z: int in [-8,0,8]:
		box(Vector3(1.4,1.2,2.5), Vector3(-39.5,0.6,z), Color("9a805e"))
	for p: Dictionary in PUDDLES:
		puddle(p.pos,p.size)
	# Direction marks follow both branches, then merge into the same circuit.
	for z: int in [-6,2,9]:
		_floor_arrow(Vector3(26,0,z),Vector3.BACK)
		_floor_arrow(Vector3(36,0,z),Vector3.BACK)
	for x: int in [9,1,-8]:
		_floor_arrow(Vector3(x,0,19),Vector3.LEFT)
		_floor_arrow(Vector3(x,0,28),Vector3.LEFT)
		_floor_arrow(Vector3(x,0,-19),Vector3.RIGHT)
		_floor_arrow(Vector3(x,0,-28),Vector3.RIGHT)
	for z: int in [17,7,-3,-13]:
		_floor_arrow(Vector3(-31,0,z),Vector3.FORWARD)
	for p: Vector3 in [Vector3(26,0,-23),Vector3(31,0,-17),Vector3(31,0,18),Vector3(24,0,23),Vector3(-24,0,23),Vector3(-31,0,-22),Vector3(-22,0,-23)]:
		var direction: Vector3 = Vector3.RIGHT if p.z < -20 else Vector3.LEFT
		if p.x == 31: direction = Vector3.BACK
		_floor_arrow(p,direction)
	# Finish artwork and the lap detector share the exact same coordinates.
	var finish: Vector3 = GATES[-1]
	_gantry(finish,18,true,"CHECKOUT / FINISH","3 LAPS / ONE WAY")
	for row: int in 18:
		for col: int in 2:
			box(Vector3(0.8,0.02,1),Vector3(finish.x+(col-0.5)*0.8,0.015,-31.5+row),Color.WHITE if (row+col)%2 == 0 else Color("182a32"))
	for i: int in 4:
		box(Vector3(2,0.02,1.4),Vector3(-6-(i/2)*3.2,0.012,-20+(i%2)*2),Color("87978a"))
	for i: int in FORKS.size():
		var fork: Dictionary = FORKS[i]
		var approach: Vector3 = (fork.a+fork.b)*0.5-fork.forward*6.0
		fork_arrows.append(_floor_arrow(approach,Vector3.FORWARD))
		for branch: int in 2:
			var pos: Vector3 = fork.a if branch == 0 else fork.b
			var body := StaticBody3D.new()
			body.position = pos + Vector3.UP*0.55
			add_child(body)
			var shape := CollisionShape3D.new()
			var rectangle := BoxShape3D.new()
			rectangle.size = fork.size
			shape.shape = rectangle
			body.add_child(shape)
			var visual := MeshInstance3D.new()
			var cube := BoxMesh.new()
			cube.size = fork.size
			visual.mesh = cube
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("65bafa") if branch == 0 else Color("ffad62")
			visual.material_override = material
			body.add_child(visual)
			var label := Label3D.new()
			label.font_size = 38
			label.pixel_size = 0.008
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.position = pos + Vector3.UP*2.6
			add_child(label)
			var lamp := MeshInstance3D.new()
			var bulb := SphereMesh.new()
			bulb.radius = 0.18
			bulb.height = 0.36
			lamp.mesh = bulb
			lamp.position = pos+Vector3.UP*1.8
			var lamp_material := StandardMaterial3D.new()
			lamp_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			lamp.material_override = lamp_material
			add_child(lamp)
			route_gates.append({"body":body,"shape":shape,"visual":visual,"label":label,"lamp":lamp_material,"branch":branch,"fork":i,"closed":false,"warning":false})
	_update_gates()
	for gate: Dictionary in route_gates:
		gate.visual.position.y = 0.0 if gate.closed else -1.8
	pickup_visuals.clear()
	for i: int in PICKUP_STANDS.size():
		_pickup_stand(PICKUP_STANDS[i].pos,PICKUP_STANDS[i].item,i)

func _update_gates(states: PackedByteArray = PackedByteArray()) -> void:
	for i: int in fork_arrows.size():
		var indicated_layout: int = 1-layout if shift_at >= 0 else layout
		var target: Vector3 = FORKS[i].a if indicated_layout == 0 else FORKS[i].b
		var direction: Vector3 = (target-fork_arrows[i].position).normalized()
		fork_arrows[i].rotation.y = atan2(-direction.x,-direction.z)
	for gate_index: int in route_gates.size():
		var gate: Dictionary = route_gates[gate_index]
		var should_close: bool = gate.branch != layout
		var occupied: bool = false
		var fork: Dictionary = FORKS[gate.fork]
		if should_close and not gate.closed:
			for cart in carts.values():
				var offset: Vector3 = cart.position-gate.body.position
				if absf(offset.x) < fork.size.x*0.5+1.4 and absf(offset.z) < fork.size.z*0.5+1.4:
					occupied = true
		gate.closed = should_close and not occupied
		if states.size() == route_gates.size():
			gate.closed = states[gate_index] == 1
			occupied = should_close and not gate.closed
		gate.shape.disabled = not gate.closed
		var route: String = "BLUE" if gate.branch == 0 else "ORANGE"
		var status: String = "CLOSED" if gate.closed else "OPEN"
		if occupied: status = "WAIT / CLEAR GATE"
		elif shift_at >= 0: status = "CLOSING" if gate.branch == layout else "OPENING"
		gate.label.text = "%s / %s\n%s" % [fork.name,route,status]
		gate.label.modulate = Color("ffad62") if occupied or shift_at >= 0 else (Color("65bafa") if gate.branch == 0 else Color("ffad62"))
		gate.warning = occupied or shift_at >= 0

func request_shift(id: int) -> void:
	if complete or tick < start_tick or not carts.has(id): return
	var cart = carts[id]
	if cart.repairing or cart.finish_tick >= 0: return
	if shift_at >= 0 or tick < shift_available:
		return
	shift_owner = id
	shift_at = tick + 90

func _advance_shift() -> void:
	if shift_at >= 0 and tick >= shift_at:
		layout = 1-layout
		if carts.has(shift_owner): carts[shift_owner].gear = 3-carts[shift_owner].gear
		shift_at = -1
		shift_available = tick+360
	_update_gates()

# ===================== CANNED DRINK PROJECTILES =====================

func _spawn_can(owner_cart, current_tick: int) -> void:
	var can_node: StaticBody3D = StaticBody3D.new()
	can_node.collision_layer = 0
	can_node.collision_mask = 0
	var forward: Vector3 = -owner_cart.transform.basis.z
	can_node.position = owner_cart.position + forward * 1.5 + Vector3.UP * 0.6
	add_child(can_node)

	var rmesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.16
	cylinder.bottom_radius = 0.16
	cylinder.height = 0.45
	rmesh.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("65d8d0")
	rmesh.material_override = material
	can_node.add_child(rmesh)

	cans.append({
		"node": can_node,
		"velocity": forward * TUNING.can_speed,
		"owner_id": owner_cart.peer_id,
		"spawn_tick": current_tick,
		"alive": true,
	})

func _update_cans(delta: float, current_tick: int) -> void:
	var to_remove: Array[int] = []
	for i: int in cans.size():
		var r: Dictionary = cans[i]
		if not r.alive:
			to_remove.append(i)
			continue
		var node: Node3D = r.node
		if not is_instance_valid(node):
			r.alive = false
			to_remove.append(i)
			continue
		var target: Vector3 = node.position+r.velocity*delta
		var query := PhysicsRayQueryParameters3D.create(node.position,target,1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			node.queue_free()
			to_remove.append(i)
			continue
		node.position = target
		if r.velocity.length() > 0.1:
			node.look_at(node.position + r.velocity, Vector3.UP)
		if current_tick - r.spawn_tick > 240:
			r.alive = false
			node.queue_free()
			to_remove.append(i)
			continue
		if absf(node.position.x) > 42.0 or absf(node.position.z) > 34.0:
			r.alive = false
			node.queue_free()
			to_remove.append(i)
			continue

		var hit_someone: bool = false
		for cart_id: int in carts:
			if cart_id == r.owner_id and current_tick - r.spawn_tick < 30:
				continue
			var cart = carts[cart_id]
			if cart.repairing or cart.finish_tick >= 0 or current_tick < cart.protection_end:
				continue
			var dist: float = node.position.distance_to(cart.position + Vector3.UP * 0.5)
			if dist < 1.6:
				cart.damage(TUNING.can_damage, current_tick)
				var knockback: Vector3 = r.velocity.normalized()
				knockback.y = 0
				cart.external_velocity += knockback * 6.0
				r.alive = false
				node.queue_free()
				hit_someone = true
				to_remove.append(i)
				break
		if hit_someone:
			continue


	to_remove.sort()
	for idx: int in range(to_remove.size() - 1, -1, -1):
		cans.remove_at(to_remove[idx])

# ===================== PHYSICS PROCESS =====================

func _physics_process(delta: float) -> void:
	if Session.phase != "race": return
	input_elapsed += delta
	if input_elapsed >= 1.0 / 30.0:
		input_elapsed = 0.0
		input_sequence += 1
		var throttle_value: float = Input.get_axis("brake", "accelerate") if not local_menu else 0.0
		var steer_value: float = Input.get_axis("left", "right") if not local_menu else 0.0
		var use_item_pressed: bool = Input.is_action_pressed("use_item") and not local_menu
		var item_edge: bool = use_item_pressed and not item_was_pressed
		item_was_pressed = use_item_pressed
		Session.send_input(input_sequence, throttle_value, steer_value, Input.is_action_pressed("recover") and not local_menu, item_edge)
	if not multiplayer.is_server(): return
	tick += 1
	_advance_shift()
	var ids: Array = carts.keys()
	ids.sort()
	for id: int in ids:
		var cart = carts[id]
		previous_positions[id] = cart.position
		# One marked fixed hazard, confined to the wide freezer branch.
		for p: Dictionary in PUDDLES:
			if absf(cart.position.x-p.pos.x) < p.size.x*0.5 and absf(cart.position.z-p.pos.z) < p.size.y*0.5:
				cart.trigger_slip(tick,45)
		var was_repairing: bool = cart.repairing
		cart.simulate(delta, tick, tick >= start_tick and not complete)
		if tick >= start_tick and not complete and not was_repairing:
			_checkpoint(cart, previous_positions[id])
			_collect_pickup(cart)
	# Update deployed items
	_update_cans(delta, tick)
	_update_peels()
	if not complete and tick >= start_tick:
		for i: int in ids.size():
			for j: int in range(i + 1, ids.size()):
				_contact(carts[ids[i]], carts[ids[j]])
		var all_finished: bool = not carts.is_empty()
		for cart in carts.values():
			if cart.finish_tick < 0:
				all_finished = false
		if tick >= deadline_tick or all_finished:
			complete = true
	snapshot_elapsed += delta
	if snapshot_elapsed >= 0.05:
		snapshot_elapsed = 0.0
		Session.publish_snapshot(snapshot())

func _checkpoint(cart, previous: Vector3) -> void:
	if cart.finish_tick >= 0 or cart.repairing: return
	# Remember the entrance actually crossed; shifts cannot change an occupied branch.
	for i: int in FORKS.size():
		var fork: Dictionary = FORKS[i]
		var midpoint: Vector3 = (fork.a+fork.b)*0.5
		if (previous-midpoint).dot(fork.forward) <= 0 and (cart.position-midpoint).dot(fork.forward) > 0:
			if cart.position.distance_to(midpoint) < 12.0:
				cart.branch_choices[i] = 0 if cart.position.distance_to(fork.a) < cart.position.distance_to(fork.b) else 1
	var index: int = cart.next_checkpoint
	var gate: Vector3 = GATES[index]
	var forward: Vector3 = DIRECTIONS[index].normalized()
	var old_side: float = (previous-gate).dot(forward)
	var new_side: float = (cart.position-gate).dot(forward)
	if old_side > 0.0 or new_side <= 0.0 or new_side <= old_side: return
	var crossing: Vector3 = previous.lerp(cart.position, -old_side/(new_side-old_side))
	if absf((crossing-gate).dot(Vector3.UP.cross(forward))) > CHECKPOINT_HALF_WIDTH: return
	if absf(crossing.y-gate.y) > 2.0: return
	# Save the actual driven lane, so reset never lands in a splitter or blocked fork.
	cart.safe_position = crossing + forward*2.0
	cart.safe_position.y = 0.0
	cart.safe_yaw = atan2(-forward.x,-forward.z)
	cart.next_checkpoint = (index+1)%GATES.size()
	if cart.next_checkpoint == 0:
		cart.laps += 1
		if cart.peer_id == local_id: lap_notice_until = tick+120
		if cart.laps >= TUNING.total_laps:
			cart.finish_tick = tick
			deadline_tick = mini(deadline_tick,tick+int(TUNING.finish_grace*60.0))

func _contact(a, b) -> void:
	if a.repairing or b.repairing or tick < a.protection_end or tick < b.protection_end or a.finish_tick >= 0 or b.finish_tick >= 0: return
	var offset: Vector3 = b.position - a.position
	offset.y = 0
	if offset.length() > 1.45: return
	var normal: Vector3 = offset.normalized() if offset.length() > 0.01 else Vector3.RIGHT
	var relative: float = (a.velocity - b.velocity).dot(normal)
	a.external_velocity -= normal * clampf(relative * 0.25 + 1.0, 0.0, 4.0)
	b.external_velocity += normal * clampf(relative * 0.25 + 1.0, 0.0, 4.0)
	a.external_velocity = a.external_velocity.limit_length(4.0)
	b.external_velocity = b.external_velocity.limit_length(4.0)
	var key: String = "%d:%d" % [a.peer_id, b.peer_id]
	if relative > TUNING.contact_threshold and tick >= int(pair_cooldowns.get(key, 0)):
		pair_cooldowns[key] = tick + 60
		var strength: float = clampf(inverse_lerp(TUNING.contact_threshold, TUNING.top_speed, relative), 0.0, 1.0)
		var impact_damage: float = TUNING.ram_damage * lerpf(0.75, 1.25, strength)
		var a_front: bool = (-a.transform.basis.z).dot(normal) > 0.5
		var b_front: bool = (-b.transform.basis.z).dot(-normal) > 0.5
		if a_front and b_front:
			a.damage(impact_damage, tick)
			b.damage(impact_damage, tick)
		else:
			# Compare each cart's motion into the contact, independent of peer order.
			var a_attacking: bool = a.velocity.dot(normal) >= b.velocity.dot(-normal)
			var attacker = a if a_attacking else b
			var recipient = b if a_attacking else a
			recipient.damage(impact_damage, tick)
			attacker.damage(impact_damage * TUNING.ram_attacker_damage_ratio, tick)

func _input_received(id: int, throttle_value: float, steer_value: float, recovery: bool, use_item: bool) -> void:
	if not carts.has(id): return
	carts[id].throttle = throttle_value
	carts[id].steer = steer_value
	carts[id].recovery_held = recovery
	carts[id].last_input_tick = tick
	if use_item and multiplayer.is_server() and not complete and tick >= start_tick:
		var cart = carts[id]
		if cart.held_item != "" and not cart.repairing and cart.finish_tick < 0 and tick >= cart.protection_end:
			if cart.held_item == "banana":
				_drop_peel(cart)
				cart.held_item = ""
			elif cart.held_item == "can":
				_spawn_can(cart, tick)
				cart.held_item = ""

func snapshot() -> Dictionary:
	var state: Dictionary = {}
	for id: int in carts:
		state[id] = carts[id].state_data()
	return {"session":session_id, "tick":tick, "deadline":deadline_tick, "complete":complete, "carts":state, "layout":layout, "gates":_gate_states(), "shift_owner":shift_owner, "shift_at":shift_at, "shift_available":shift_available, "pickups":pickup_cooldowns, "items":_item_snapshot()}

func _receive(data: Dictionary) -> void:
	tick = data.tick
	deadline_tick = data.deadline
	complete = data.complete
	layout = data.layout
	shift_owner = data.shift_owner
	shift_at = data.shift_at
	shift_available = data.shift_available
	pickup_cooldowns = data.pickups
	_receive_items(data.items)
	_update_gates(data.gates)
	for id: int in data.carts:
		if carts.has(id):
			var old_laps: int = carts[id].laps
			carts[id].apply_snapshot(data.carts[id])
			if id == local_id and carts[id].laps > old_laps: lap_notice_until = tick+120

func _roster_changed() -> void:
	for id: int in carts.keys():
		if not Session.roster.has(id):
			carts[id].queue_free()
			carts.erase(id)
			previous_positions.erase(id)

func _process(delta: float) -> void:
	for gate: Dictionary in route_gates:
		gate.visual.position.y = move_toward(gate.visual.position.y,0.0 if gate.closed else -1.8,delta*5.0)
		gate.lamp.albedo_color = Color("ffad62") if gate.warning and tick%30 < 15 else (Color("6fff99") if not gate.closed and not gate.warning else Color("763c28"))
	if not multiplayer.is_server():
		for cart in carts.values():
			cart.interpolate(delta)
	# Animate and update pickup stands
	for pv: Dictionary in pickup_visuals:
		if is_instance_valid(pv.anchor):
			var s_idx: int = pv.index
			var ready: bool = tick >= int(pickup_cooldowns.get(s_idx, 0))
			pv.anchor.visible = ready
			if ready:
				pv.anchor.rotation.y += 2.2 * delta
				pv.anchor.position.y = 0.85 + sin(float(tick) * 0.08 + float(s_idx)) * 0.1
				pv.label.text = "BANANA / READY" if pv.item == "banana" else "CAN / READY"
				pv.label.modulate = pv.col
			else:
				pv.label.text = "⏳ MENGISI ULANG..."
				pv.label.modulate = Color(0.5, 0.5, 0.5, 0.7)
	if not carts.has(local_id): return
	var cart = carts[local_id]
	if cart.finish_tick >= 0:
		for id: int in rankings():
			if carts[id].finish_tick < 0:
				cart = carts[id]
				break
	var speed_ratio: float = clampf(Vector2(cart.velocity.x, cart.velocity.z).length() / TUNING.top_speed, 0.0, 1.0)
	var follow: Vector3 = cart.position + cart.transform.basis.z * (9.0 + TUNING.camera_speed_pullback * speed_ratio) + Vector3.UP * 6.0
	camera.global_position = follow if not camera_started else camera.global_position.lerp(follow, 1.0 - exp(-7.0 * delta))
	camera_started = true
	camera.look_at(cart.position + Vector3.UP * 1.0 - cart.transform.basis.z * 3.0)
	for item_id: int in carts:
		var item = carts[item_id]
		item.mesh_root.visible = true
		if Session.roster.has(item_id):
			var base_name: String = Session.roster[item_id].name
			if tick < item.stun_end:
				item.label.text = "💫 %s [STUN] 💫" % base_name
				item.label.modulate = Color("ff6b6b")
			elif tick < item.slip_end:
				item.label.text = "💧 %s [SLIP] 💧" % base_name
				item.label.modulate = Color("65d8d0")
			else:
				item.label.text = base_name
				item.label.modulate = item.paint

func rankings() -> Array:
	var ids: Array = carts.keys()
	ids.sort_custom(func(a: int, b: int):
		var left = carts[a]
		var right = carts[b]
		if left.finish_tick >= 0 or right.finish_tick >= 0:
			if left.finish_tick < 0: return false
			if right.finish_tick < 0: return true
			return left.finish_tick < right.finish_tick if left.finish_tick != right.finish_tick else a < b
		var lp: float = progress(left)
		var rp: float = progress(right)
		return lp > rp if not is_equal_approx(lp, rp) else a < b
	)
	return ids

func progress(cart) -> float:
	var total: int = GATES.size()
	var previous: Vector3 = GATES[(cart.next_checkpoint + total - 1) % total]
	var target: Vector3 = GATES[cart.next_checkpoint]
	var path: Array[Vector3] = [previous,target]
	var index: int = cart.next_checkpoint
	var branch: int = cart.branch_choices[0]
	var lane: float = 26.0 if branch == 0 else 36.0
	if branch >= 0 and index == 2: path = [previous,Vector3(lane,0,-12),Vector3(lane,0,0)]
	elif branch >= 0 and index == 3: path = [Vector3(lane,0,0),Vector3(lane,0,10),target]
	branch = cart.branch_choices[1]
	lane = 28.0 if branch == 0 else 19.0
	if branch >= 0 and index == 5: path = [previous,Vector3(18,0,lane),Vector3(0,0,lane)]
	elif branch >= 0 and index == 6: path = [Vector3(0,0,lane),Vector3(-18,0,lane),target]
	branch = cart.branch_choices[2]
	lane = -19.0 if branch == 0 else -28.0
	if branch >= 0 and index == 11: path = [previous,Vector3(-16,0,lane),Vector3(14,0,lane),target]
	var length: float = 0.0
	for i: int in range(path.size()-1): length += path[i].distance_to(path[i+1])
	var travelled: float = 0.0
	var best_distance: float = INF
	var best_progress: float = 0.0
	for i: int in range(path.size()-1):
		var segment: Vector3 = path[i+1]-path[i]
		var fraction_on_segment: float = clampf((cart.position-path[i]).dot(segment)/segment.length_squared(),0.0,1.0)
		var distance: float = cart.position.distance_squared_to(path[i]+segment*fraction_on_segment)
		if distance < best_distance:
			best_distance = distance
			best_progress = travelled+segment.length()*fraction_on_segment
		travelled += segment.length()
	var fraction: float = clampf(best_progress/length,0.0,0.999)
	return float(cart.laps * total + cart.next_checkpoint) + fraction

func _drop_peel(cart) -> void:
	var node := _item_visual(cart.position+cart.transform.basis.z*1.8, true)
	peels.append({"node":node,"expires":tick+480})

func _update_peels() -> void:
	for i: int in range(peels.size()-1,-1,-1):
		var peel: Dictionary = peels[i]
		var consumed: bool = tick >= peel.expires
		for cart in carts.values():
			if cart.repairing or cart.finish_tick >= 0 or tick < cart.protection_end: continue
			if cart.position.distance_to(peel.node.position) < 1.0:
				cart.trigger_slip(tick,60)
				cart.velocity *= 0.7
				consumed = true
				break
		if consumed:
			peel.node.queue_free()
			peels.remove_at(i)

var remote_items: Array[Node3D] = []
func _item_snapshot() -> Array:
	var data: Array = []
	for peel: Dictionary in peels: data.append([peel.node.position,true])
	for can: Dictionary in cans: data.append([can.node.position,false])
	return data

func _item_visual(pos: Vector3, banana: bool) -> Node3D:
	var node := MeshInstance3D.new()
	if banana:
		var prism := PrismMesh.new()
		prism.size = Vector3(0.8,0.25,0.6)
		node.mesh = prism
	else:
		var can := CylinderMesh.new()
		can.top_radius = 0.16
		can.bottom_radius = 0.16
		can.height = 0.45
		node.mesh = can
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("f5d45c") if banana else Color("65d8d0")
	node.material_override = material
	node.position = pos
	if banana: node.position.y = 0.1
	add_child(node)
	return node

func _receive_items(items: Array) -> void:
	for node: Node3D in remote_items: node.queue_free()
	remote_items.clear()
	for item: Array in items: remote_items.append(_item_visual(item[0],item[1]))

func _collect_pickup(cart) -> void:
	if cart.held_item != "" or cart.repairing or cart.finish_tick >= 0: return
	for index: int in PICKUP_STANDS.size():
		if tick < int(pickup_cooldowns.get(index,0)): continue
		if cart.position.distance_to(PICKUP_STANDS[index].pos) < 1.7:
			cart.held_item = PICKUP_STANDS[index].item
			pickup_cooldowns[index] = tick+480
			return

func navigation_text(cart) -> String:
	var target: Vector3 = GATES[cart.next_checkpoint]
	# Guide toward the lane the racer occupies; never point into a branch splitter.
	if cart.next_checkpoint == 2: target.x = 26.0 if cart.position.x < 31.0 else 36.0
	if cart.next_checkpoint == 5: target.z = 19.0 if cart.position.z < 23.5 else 28.0
	var offset: Vector3 = target-cart.position
	var local_offset: Vector3 = cart.transform.basis.inverse()*offset
	var direction: String = "STRAIGHT"
	if local_offset.z > 2.0: direction = "TURN BACK"
	elif local_offset.x > maxf(3.0,-local_offset.z*0.35): direction = "RIGHT"
	elif local_offset.x < -maxf(3.0,-local_offset.z*0.35): direction = "LEFT"
	var destination: String = "FINISH" if cart.next_checkpoint == GATES.size()-1 else "CP %02d" % (cart.next_checkpoint+1)
	return "%s  /  %s  /  %dm" % [direction,destination,offset.length()]

func _gate_states() -> PackedByteArray:
	var states := PackedByteArray()
	for gate: Dictionary in route_gates: states.append(1 if gate.closed else 0)
	return states
