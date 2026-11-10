extends Node
const World = preload("res://scripts/race/race_world.gd")
var failures: int = 0
var world

func check(condition: bool, description: String) -> void:
	if condition: print("PASS: ",description)
	else:
		failures += 1
		push_error("FAIL: "+description)

func _ready() -> void:
	world = World.new()
	add_child(world)
	var players: Dictionary = {}
	for id: int in range(1,5): players[id] = {"name":"Test %d" % id,"ready":true}
	Session.roster = players
	world.setup(players,1)
	world.set_physics_process(false)
	world.set_process(false)
	await get_tree().physics_frame
	for test: String in ["checkpoint_rules","route_physics","shift_rules","items_and_respawn","ram_rules","branch_progress","replication","can_aim_assist","slip_steering"]:
		if await call(test) != true:
			failures += 1
			push_error("Test did not finish: "+test)
	world.free()
	Session.roster.clear()
	print("STATE TEST COMPLETE failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)

func reset_cart(cart) -> void:
	cart.laps = 0
	cart.next_checkpoint = 0
	cart.finish_tick = -1
	cart.repairing = false
	cart.protection_end = 0
	cart.health = 100
	cart.held_item = ""

func slip_steering() -> bool:
	var cart = world.carts[1]
	cart.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().physics_frame
	reset_cart(cart)
	for gear: int in [1, 2]:
		cart.position = Vector3(0, 10, 0)
		cart.rotation.y = 0
		cart.velocity = Vector3(3, 0, -6)
		cart.external_velocity = Vector3.ZERO
		cart.gear = gear
		cart.steer = 1.0
		cart.throttle = 0.0
		cart.last_input_tick = 100
		cart.slip_end = 160
		cart.simulate(1.0 / 60.0, 100, true)
		check(cart.rotation.y < 0 if gear == 1 else cart.rotation.y > 0, "Slip steering stays normal in Grip and reverses in Rush (gear %d)" % gear)
		if gear == 1:
			check(absf(cart.velocity.x) > 2.0, "Grip still slides sideways while slipping")
	return true

func can_aim_assist() -> bool:
	# Elevated isolated fixture avoids depending on authored track geometry.
	for id: int in world.carts:
		var cart = world.carts[id]
		cart.process_mode = Node.PROCESS_MODE_DISABLED
		reset_cart(cart)
		cart.position = Vector3(50 + id * 10,10,0)
	var owner = world.carts[1]
	var target = world.carts[2]
	owner.position = Vector3(0,10,0)
	owner.rotation = Vector3.ZERO
	var forward := Vector3.FORWARD
	var origin: Vector3 = owner.position + forward * 1.5 + Vector3.UP * 0.6
	check(world._can_launch_direction(owner,origin,forward,100) == forward,"Can without a target fires straight")
	target.position = Vector3(0.6,10,-8)
	var assisted: Vector3 = world._can_launch_direction(owner,origin,forward,100)
	check(assisted.x > 0 and forward.angle_to(assisted) <= deg_to_rad(8),"Can corrects toward a target inside the narrow cone")
	world.carts[3].position = Vector3(-0.2,10,-9)
	check(world._can_launch_direction(owner,origin,forward,100).x < 0,"Can prefers the target closest to the firing line")
	world.carts[3].position = Vector3(80,10,0)
	for invalid_position: Vector3 in [Vector3(4,10,-8),Vector3(0.2,10,-14),Vector3(0,10,5)]:
		target.position = invalid_position
		check(world._can_launch_direction(owner,origin,forward,100) == forward,"Can rejects target outside cone, range or forward direction")
	target.position = Vector3(0.6,10,-8)
	target.protection_end = 200
	check(world._can_launch_direction(owner,origin,forward,100) == forward,"Can ignores protected targets")
	target.protection_end = 0
	target.repairing = true
	check(world._can_launch_direction(owner,origin,forward,100) == forward,"Can ignores respawning targets")
	target.repairing = false
	target.finish_tick = 10
	check(world._can_launch_direction(owner,origin,forward,100) == forward,"Can ignores finished targets")
	target.finish_tick = -1
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3,3,0.5)
	collision.shape = shape
	blocker.add_child(collision)
	blocker.position = Vector3(0,10,-4)
	world.add_child(blocker)
	await get_tree().physics_frame
	check(world._can_launch_direction(owner,origin,forward,100) == forward,"Can assist cannot target through solid obstacles")
	blocker.free()
	await get_tree().physics_frame
	world._spawn_can(owner,100)
	var projectile: Dictionary = world.cans.back()
	var velocity: Vector3 = projectile.velocity
	target.position = Vector3(-5,10,-8)
	world._update_cans(1.0/60.0,101)
	check(velocity.x > 0 and projectile.velocity == velocity,"Can keeps its launch velocity when the target moves; no homing")
	return true

func cross_gate(cart, index: int, offset: Vector3 = Vector3.ZERO) -> void:
	var point: Vector3 = World.GATES[index]+offset
	var direction: Vector3 = World.DIRECTIONS[index]
	cart.position = point+direction
	cart.velocity = direction*10
	world.tick += 60
	world._checkpoint(cart,point-direction)

func checkpoint_rules() -> bool:
	var cart = world.carts[1]
	reset_cart(cart)
	cross_gate(cart,11)
	check(cart.laps == 0 and cart.next_checkpoint == 0,"Finish without ordered checkpoints gives no lap")
	cart.position = World.GATES[0]-Vector3.RIGHT
	world._checkpoint(cart,World.GATES[0]+Vector3.RIGHT)
	check(cart.next_checkpoint == 0,"Reverse checkpoint crossing is rejected")
	cross_gate(cart,0,Vector3(0,0,World.CHECKPOINT_HALF_WIDTH+3))
	check(cart.next_checkpoint == 0,"Crossing beyond the lane width is rejected")
	cart.position = World.GATES[0]+Vector3.RIGHT
	world._checkpoint(cart,World.GATES[0])
	check(cart.next_checkpoint == 1,"Leaving the exact checkpoint plane forward counts once")
	world._checkpoint(cart,World.GATES[0])
	check(cart.next_checkpoint == 1,"Repeated finish/plane samples cannot duplicate progress")
	reset_cart(cart)
	cart.position = World.GATES[0]+Vector3(10,0,10)
	world._checkpoint(cart,World.GATES[0]-Vector3.RIGHT)
	check(cart.next_checkpoint == 1,"Fast diagonal crossing uses the plane intersection, not the end position")
	reset_cart(cart)
	for lap: int in 3:
		for index: int in World.GATES.size(): cross_gate(cart,index)
		check(cart.laps == lap+1,"Complete ordered circuit increments lap %d" % (lap+1))
	check(cart.finish_tick >= 0 and world.deadline_tick == world.tick+1200,"Third lap finishes and starts the twenty-second deadline")
	cross_gate(cart,0)
	check(cart.laps == 3 and cart.next_checkpoint == 0,"Finished cart cannot advance again")
	return true

func route_physics() -> bool:
	var cart = world.carts[1]
	for selected: int in 2:
		world.layout = selected
		world.shift_at = -1
		world._update_gates()
		await get_tree().physics_frame
		reset_cart(cart)
		cart.position = Vector3(19,0,-23)*Vector3(1.2,1,1.76)
		var east: float = 26.0 if selected == 0 else 36.0
		var north: float = 28.0 if selected == 0 else 19.0
		var south: float = -19.0 if selected == 0 else -28.0
		var path: Array[Vector3] = [
			Vector3(31,0,-23),Vector3(31,0,-14),Vector3(east,0,-12),
			Vector3(east,0,10),Vector3(31,0,14),Vector3(31,0,23),
			Vector3(20,0,23),Vector3(18,0,north),Vector3(-18,0,north),
			Vector3(-20,0,23),Vector3(-31,0,23),Vector3(-31,0,14),
			Vector3(-34,0,12),Vector3(-34,0,7),Vector3(-28,0,3),Vector3(-28,0,-3),Vector3(-34,0,-7),Vector3(-34,0,-12),Vector3(-31,0,-23),Vector3(-24,0,-23),Vector3(-18,0,-23),
			Vector3(-16,0,south),Vector3(14,0,south),Vector3(19,0,-23),
		]
		for i: int in path.size(): path[i] *= Vector3(1.2,1,1.76)
		var clear: bool = true
		for lap: int in 3:
			for target: Vector3 in path:
				var attempts: int = 0
				while cart.position.distance_to(target) > 0.01 and attempts < 400:
					attempts += 1
					var previous: Vector3 = cart.position
					var motion: Vector3 = (target-cart.position).limit_length(0.25)
					var collision = cart.move_and_collide(motion)
					cart.velocity = motion*60
					world.tick += 1
					world._checkpoint(cart,previous)
					if collision != null:
						clear = false
						push_error("Blocked at %s toward %s on layout %d" % [cart.position,target,selected])
						break
				if not clear: break
			if not clear: break
		check(clear,"Actual trolley collider traverses all three branches in layout %d" % selected)
		check(cart.laps == 3 and cart.finish_tick >= 0,"Continuous physical circuit registers exactly three laps in layout %d (lap=%d next=%d)" % [selected,cart.laps,cart.next_checkpoint])
	# Test every pickup with the trolley collider instead of assigning held_item by hand.
	for i: int in World.PICKUP_STANDS.size():
		reset_cart(cart)
		var pos: Vector3 = World.PICKUP_STANDS[i].pos
		cart.position = pos+Vector3(0,0,-1.5)
		var collision = cart.move_and_collide(Vector3(0,0,3))
		check(collision == null,"Pickup %d has no pedestal or physical obstruction" % i)
		cart.position = pos
		world._collect_pickup(cart)
		check(cart.held_item == World.PICKUP_STANDS[i].item,"Pickup %d is collected by production logic" % i)
	return true

func shift_rules() -> bool:
	for cart in world.carts.values():
		reset_cart(cart)
		cart.position = Vector3(-31,0,0)
		cart.gear = 1
	world.layout = 0
	world.tick = 300
	world.shift_available = 0
	world.request_shift(1)
	world.request_shift(2)
	check(world.shift_owner == 1 and world.shift_at == 390,"First shift wins; simultaneous requests do not queue")
	world.tick = 389
	world._advance_shift()
	check(world.layout == 0 and world.carts[1].gear == 1,"Warning keeps old route and gear for 1.5 seconds")
	# Occupied gate must wait, even if the instigator is destroyed.
	world.carts[1].repairing = true
	world.carts[2].position = World.FORKS[0].a
	world.tick = 390
	world._advance_shift()
	check(world.layout == 1 and world.carts[1].gear == 2 and world.carts[2].gear == 1,"Crash does not cancel shared layout change; only instigator changes gear")
	check(not world.route_gates[0].closed and world.route_gates[0].label.text.contains("WAIT"),"Occupied entrance stays open with warning")
	world.carts[2].position = Vector3(26,0,6)
	world._advance_shift()
	check(world.route_gates[0].closed,"Entrance closes after trolley clears; racer inside branch can continue")
	world.request_shift(2)
	check(world.shift_at == -1 and world.shift_available == 750,"Six-second shared cooldown rejects further requests")
	world.tick = 750
	world.request_shift(2)
	check(world.shift_at == 840,"Shift becomes available exactly at cooldown expiry")
	world.tick = 840
	world._advance_shift()
	check(world.layout == 0,"Second accepted shift restores Blue layout")
	return true

func items_and_respawn() -> bool:
	var cart = world.carts[1]
	reset_cart(cart)
	cart.health = 10
	cart.safe_position = Vector3(-31,0,-4)
	cart.position = Vector3(-31,0,5)
	cart.damage(15,1000)
	check(cart.repairing and cart.repair_end == 1180,"Destroyed trolley respawns after three seconds")
	cart.simulate(1.0/60,1179,true)
	check(cart.repairing,"Respawn never completes early")
	cart.simulate(1.0/60,1180,true)
	check(not cart.repairing and cart.health == 100 and cart.position == cart.safe_position,"Respawn returns to passed checkpoint at full durability")
	check(cart.protection_end == 1270,"Respawn protection lasts 1.5 seconds")
	world.tick = 1200
	cart.held_item = "can"
	world._input_received(1,0,0,false,true)
	check(cart.held_item == "can" and world.cans.is_empty(),"Protected cart cannot deploy harmful items")
	world.tick = 1300
	cart.held_item = "banana"
	world._input_received(1,0,0,false,true)
	check(cart.held_item == "" and world.peels.size() == 1,"Banana use drops one visible peel")
	cart.position = world.peels[0].node.position
	cart.position.y = 0
	world._update_peels()
	check(world.peels.is_empty() and cart.slip_end == world.tick+60,"Deployed peel can hit its owner and disappears on contact")
	cart.held_item = "can"
	world._input_received(1,0,0,false,true)
	check(cart.held_item == "" and world.cans.size() == 1,"Canned drink fires straight ahead")
	world._update_cans(1.0/60,world.tick+241)
	check(world.cans.is_empty(),"Can disappears after four seconds")
	cart.position = World.PICKUP_STANDS[0].pos
	cart.held_item = ""
	world.pickup_cooldowns[0] = world.tick+480
	world._collect_pickup(cart)
	check(cart.held_item == "","Pickup cooldown blocks early collection")
	world.tick += 480
	world._collect_pickup(cart)
	check(cart.held_item == "banana","Pickup refills after eight seconds")
	return true

func prepare_ram(a_speed: float, b_speed: float, b_yaw: float = 0.0) -> void:
	var a = world.carts[1]
	var b = world.carts[2]
	reset_cart(a)
	reset_cart(b)
	a.position = Vector3.ZERO
	b.position = Vector3(0,0,-1.2)
	a.rotation.y = 0
	b.rotation.y = b_yaw
	a.velocity = Vector3(0,0,-a_speed)
	b.velocity = Vector3(0,0,-b_speed)
	a.external_velocity = Vector3.ZERO
	b.external_velocity = Vector3.ZERO
	world.pair_cooldowns.clear()
	world.tick = 2000

func ram_rules() -> bool:
	var a = world.carts[1]
	var b = world.carts[2]
	prepare_ram(10,0)
	world._contact(a,b)
	var rear_damage: float = 100-b.health
	var attacker_damage: float = 100-a.health
	check(rear_damage >= 15 and rear_damage <= 25 and attacker_damage <= 5,"Rear impact primarily damages the recipient")
	world.tick += 1
	world._contact(a,b)
	check(is_equal_approx(b.health,100-rear_damage),"Sustained ram contact cannot repeat damage during protection")
	prepare_ram(10,0)
	world._contact(b,a)
	check(is_equal_approx(100-b.health,rear_damage) and is_equal_approx(100-a.health,attacker_damage),"Ram damage is independent of cart iteration order")
	prepare_ram(10,0,PI/2)
	world._contact(a,b)
	check(100-b.health > 100-a.health,"Side impact primarily damages the recipient")
	prepare_ram(6,-6,PI)
	world._contact(a,b)
	check(a.health < 100 and is_equal_approx(a.health,b.health),"Head-on impact damages both racers equally")
	prepare_ram(4.1,0)
	world._contact(a,b)
	check(100-b.health < rear_damage,"Lower closing speed causes less ram damage")
	prepare_ram(2,0)
	world._contact(a,b)
	check(a.health == 100 and b.health == 100 and b.external_velocity.length() > 0,"Gentle contact pushes without damage")
	prepare_ram(10,0)
	a.protection_end = world.tick+90
	world._contact(a,b)
	check(a.health == 100 and b.health == 100,"Protected attacker cannot deal ram damage")
	prepare_ram(10,0)
	b.protection_end = world.tick+90
	world._contact(a,b)
	check(a.health == 100 and b.health == 100,"Protected recipient takes no ram damage")
	prepare_ram(10,0)
	a.finish_tick = world.tick-1
	world._contact(a,b)
	check(b.health == 100,"Finished racer cannot deal ram damage")
	reset_cart(a)
	reset_cart(b)
	return true

func branch_progress() -> bool:
	var cart = world.carts[1]
	reset_cart(cart)
	for i: int in 3: cart.branch_choices[i] = -1
	cart.next_checkpoint = 2
	cart.position = (Vector3(36,0,-9)*Vector3(1.2,1,1.76))
	world._checkpoint(cart,(Vector3(36,0,-11)*Vector3(1.2,1,1.76)))
	check(cart.branch_choices[0] == 1,"Ranking remembers the actual Orange entrance")
	var before: float = world.progress(cart)
	world.layout = 0
	check(is_equal_approx(before,world.progress(cart)),"Layout change cannot change progress inside an existing branch")
	cart.position = (Vector3(36,0,-1)*Vector3(1.2,1,1.76))
	check(world.progress(cart) > before and world.progress(cart) < 3.0,"Branch progress increases toward the next ordered checkpoint")
	world.carts[2].apply_snapshot(cart.state_data())
	check(world.carts[2].branch_choices == cart.branch_choices,"Actual branch choices replicate to clients")
	reset_cart(cart)
	reset_cart(world.carts[2])
	return true

func replication() -> bool:
	var cart = world.carts[1]
	cart.gear = 2
	cart.held_item = "can"
	world.carts[2].apply_snapshot(cart.state_data())
	check(world.carts[2].gear == 2 and world.carts[2].held_item == "can","Snapshot restores personal gear and held item")
	world.layout = 1
	world._update_gates()
	var states: PackedByteArray = world._gate_states()
	world.route_gates[0].closed = false
	world._update_gates(states)
	check(world.route_gates[0].closed,"Replicated gate state follows the host instead of client occupancy estimates")
	check(var_to_bytes(world.snapshot()).size() < 1200,"Four-cart snapshot with shared gate and pickup state fits UDP budget")
	world.carts[2].finish_tick = 1000
	cart.finish_tick = 1000
	check(world.rankings()[0] == 1,"Finish ties rank by stable peer ID")
	return true
