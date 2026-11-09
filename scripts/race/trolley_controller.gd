extends CharacterBody3D
const TUNING = preload("res://resources/balance.tres")
var peer_id: int = 1
var throttle: float = 0.0
var steer: float = 0.0
var last_input_tick: int = 0
var recovery_held: bool = false
var recovery_ticks: int = 0
var health: float = 100.0
var repair_end: int = 0
var protection_end: int = 0
var repairing: bool = false
var recovery_only: bool = false
var gear: int = 1
var laps: int = 0
var next_checkpoint: int = 0
var finish_tick: int = -1
var stun_end: int = 0
var slip_end: int = 0
var held_item: String = ""
var safe_position: Vector3
var safe_yaw: float = 0.0
var target_position: Vector3
var target_yaw: float = 0.0
var external_velocity: Vector3 = Vector3.ZERO
var mesh_root: Node3D
var label: Label3D
var paint: Color = Color("d6f663")
var wheels: Array[MeshInstance3D] = []
var rider: Node3D
var visual_yaw: float = 0.0
var branch_choices: Array[int] = [-1,-1,-1]
var collapse: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.6
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	add_child(shape)
	mesh_root = Node3D.new()
	add_child(mesh_root)
	# Meter scale; forward is -Z. Camera is a sibling, never attached to wobble.
	box(Vector3(1.05,0.12,1.4),Vector3(0,0.55,0),Color("8ba8ad"))
	for x: float in [-0.52,0.52]:
		box(Vector3(0.08,0.65,1.4),Vector3(x,0.94,0),paint)
	for z: float in [-0.7,0.7]:
		box(Vector3(1.05,0.65,0.08),Vector3(0,0.94,z),paint)
	for x: float in [-0.5,0.5]:
		for z: float in [-0.5,0.5]:
			wheels.append(box(Vector3(0.2,0.3,0.3),Vector3(x,0.25,z),Color("13232d")))
	box(Vector3(1.25,0.09,0.12),Vector3(0,1.3,0.83),Color("d9f5ec"))
	rider = Node3D.new()
	rider.position = Vector3(0,1.0,0.2)
	mesh_root.add_child(rider)
	box(Vector3(0.5,0.65,0.4),Vector3(0,0.38,0),paint.darkened(0.25),rider)
	box(Vector3(0.43,0.43,0.43),Vector3(0,0.94,0),Color("f2b88f"),rider)
	box(Vector3(0.45,0.10,0.5),Vector3(0,1.17,-0.04),Color("243b4a"),rider)
	box(Vector3(0.34,0.4,0.35),Vector3(-0.22,0.82,-0.35),Color("ffad62"))
	label = Label3D.new()
	label.position.y = 2.7
	label.font_size = 36
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = paint
	add_child(label)
	target_position = position
	target_yaw = rotation.y
	visual_yaw = rotation.y

func box(size: Vector3, pos: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	instance.position = pos
	if parent == null: parent = mesh_root
	parent.add_child(instance)
	return instance

func _process(delta: float) -> void:
	var destroyed: bool = repairing and health <= 0
	collapse = move_toward(collapse, 1.0 if destroyed else 0.0, delta*4.0)
	mesh_root.scale = Vector3(1.0+collapse*0.2,1.0-collapse*0.65,1.0)
	mesh_root.rotation.z = collapse*0.22
	# Visual motion also works for remote carts, whose steering input is not replicated.
	var turn_rate: float = angle_difference(visual_yaw, rotation.y) / maxf(delta, 0.001)
	visual_yaw = rotation.y
	var speed: float = velocity.dot(-transform.basis.z) if not repairing and finish_tick < 0 else 0.0
	var lean: float = clampf(turn_rate / TUNING.steering, -1.0, 1.0) * clampf(absf(speed) / 3.0, 0.0, 1.0)
	rider.rotation.z = lerp_angle(rider.rotation.z, deg_to_rad(TUNING.rider_lean_degrees) * lean, 1.0-exp(-10.0*delta))
	for wheel: MeshInstance3D in wheels:
		wheel.rotation.x = wrapf(wheel.rotation.x-speed*delta/0.15, -PI, PI)
	# A bent wheel is cosmetic; the existing speed penalty never changes steering.
	wheels[0].rotation.z = deg_to_rad(22.0) if health < 35 else 0.0

func trigger_stun(current_tick: int, duration_ticks: int = 25) -> void:
	if repairing or finish_tick >= 0: return
	stun_end = maxi(stun_end, current_tick + duration_ticks)
	velocity *= 0.35
	recovery_ticks = 0

func trigger_slip(current_tick: int, duration_ticks: int = 90) -> void:
	if repairing or finish_tick >= 0: return
	slip_end = maxi(slip_end, current_tick + duration_ticks)

func simulate(delta: float, tick: int, driving: bool) -> void:
	if repairing:
		velocity = Vector3.ZERO
		if tick >= repair_end:
			repairing = false
			health = 100
			position = safe_position
			rotation.y = safe_yaw
			protection_end = tick + int(TUNING.protection_seconds*60)
		return
	if not driving or finish_tick >= 0: return
	if tick < stun_end:
		throttle = 0
		steer = 0
		recovery_held = false
		velocity = velocity.move_toward(Vector3.ZERO, 14.0 * delta)
		external_velocity = external_velocity.move_toward(Vector3.ZERO, 14.0 * delta)
		velocity.y = -2
		move_and_slide()
		velocity.y = 0
		return
	if tick-last_input_tick > 30:
		throttle = 0
		steer = 0
		recovery_held = false
	recovery_ticks = recovery_ticks+1 if recovery_held else 0
	if recovery_ticks >= 120:
		start_repair(tick,true)
		return
	var forward: Vector3 = -transform.basis.z
	var speed: float = velocity.dot(forward)
	var is_slipping: bool = tick < slip_end
	var effective_steer: float = -steer if is_slipping else steer
	rotation.y -= effective_steer*TUNING.steering*(1.0 if gear == 1 else 0.8)*clampf(absf(speed)/3.0,0,1)*delta*(-1 if speed < -0.2 else 1)
	forward = -transform.basis.z
	var right: Vector3 = transform.basis.x
	var current_grip: float = TUNING.grip * (0.25 if is_slipping else (1.0 if gear == 1 else 0.6))
	velocity -= right*velocity.dot(right)*minf(1,current_grip*delta)
	var cur_top_speed: float = TUNING.top_speed * (0.8 if gear == 1 else 1.0)
	if health < 35: cur_top_speed *= 0.9
	var cur_accel: float = TUNING.acceleration
	velocity += forward*throttle*cur_accel*delta
	velocity = velocity.move_toward(Vector3.ZERO,(2.0 if throttle != 0 else 7.0)*delta)
	if throttle < 0 and speed > 0: velocity = velocity.move_toward(Vector3.ZERO,22*delta)
	velocity = velocity.limit_length(TUNING.reverse_speed if throttle < 0 and speed < 0 else cur_top_speed)
	velocity += external_velocity
	external_velocity = external_velocity.move_toward(Vector3.ZERO,16*delta)
	velocity.y = -2
	var before: Vector3 = velocity
	move_and_slide()
	for index: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(index)
		if absf(collision.get_normal().y) < 0.3:
			var impact: float = -before.dot(collision.get_normal())
			if impact > 2.2:
				trigger_stun(tick, TUNING.default_stun_ticks)
				external_velocity += collision.get_normal() * clampf(impact * 0.45, 1.5, 4.0)
				if impact > 6.0: damage(minf(25,(impact-4)*3),tick)
	velocity.y = 0
	if position.y < -3 or absf(position.x) > 52 or absf(position.z) > 62: start_repair(tick,true)

func damage(amount: float, tick: int) -> void:
	if repairing or tick < protection_end or finish_tick >= 0: return
	health = maxf(0,health-amount)
	protection_end = tick+60
	if health <= 0: start_repair(tick,false)

func start_repair(tick: int, recover: bool) -> void:
	repairing = true
	recovery_only = recover
	repair_end = tick+int(TUNING.repair_seconds*60)
	stun_end = 0
	velocity = Vector3.ZERO
	external_velocity = Vector3.ZERO
	recovery_ticks = 0

func state_data() -> PackedFloat32Array:
	var item_code: float = 1.0 if held_item == "banana" else (2.0 if held_item == "can" else 0.0)
	return PackedFloat32Array([position.x,position.y,position.z,rotation.y,velocity.x,velocity.y,velocity.z,health,1.0 if repairing else 0.0,repair_end,protection_end,laps,next_checkpoint,finish_tick,float(stun_end),float(slip_end),item_code,float(gear),float(branch_choices[0]),float(branch_choices[1]),float(branch_choices[2])])

func apply_snapshot(data: PackedFloat32Array) -> void:
	if data.size() != 21: return
	target_position = Vector3(data[0],data[1],data[2])
	target_yaw = data[3]
	velocity = Vector3(data[4],data[5],data[6])
	health = data[7]
	repairing = data[8] > 0
	repair_end = int(data[9])
	protection_end = int(data[10])
	laps = int(data[11])
	next_checkpoint = int(data[12])
	finish_tick = int(data[13])
	stun_end = int(data[14])
	slip_end = int(data[15])
	var item_code: int = int(data[16])
	held_item = "banana" if item_code == 1 else ("can" if item_code == 2 else "")
	gear = int(data[17])
	for i: int in 3: branch_choices[i] = int(data[18+i])

func interpolate(delta: float) -> void:
	position = position.lerp(target_position,1-exp(-18*delta))
	rotation.y = lerp_angle(rotation.y,target_yaw,1-exp(-18*delta))
