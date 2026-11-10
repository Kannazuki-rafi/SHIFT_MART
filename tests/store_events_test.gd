extends Node
const World = preload("res://scripts/race/race_world.gd")
const Events = preload("res://scripts/race/store_events.gd")
var failures: int = 0
var world

func check(condition: bool, message: String) -> void:
	if condition: print("PASS: ",message)
	else:
		failures += 1
		push_error(message)

func _ready() -> void:
	world = World.new()
	add_child(world)
	world.set_process(false)
	world.set_physics_process(false)
	var players: Dictionary = {}
	for id: int in range(1,5): players[id] = {"name":"Hazard %d" % id,"ready":true}
	world.setup(players,1)
	var events = world.store_events
	for event: Dictionary in events.events:
		if event.cabinet: test_cabinet(event)
		else: test_fruit(event)
	var replica = Events.new()
	add_child(replica)
	replica.apply_state(events.state_data())
	replica.render(1090)
	check(replica.state_data() == events.state_data(),"Warning timestamps and consumed fruit replicate exactly")
	replica.free()
	for i: int in World.PICKUP_STANDS.size(): world.pickup_cooldowns[i] = 1200
	check(var_to_bytes(world.snapshot()).size() < 1200,"Four players, twelve pickup cooldowns and all events fit the snapshot budget")
	var fresh = Events.new()
	add_child(fresh)
	check(fresh.events.all(func(e: Dictionary): return e.trigger == -1 and e.mask == 0),"Rematch event instances start with clean timers and fruit")
	fresh.free()
	if "--capture-events" in OS.get_cmdline_user_args():
		await capture_previews()
	world.free()
	print("STORE EVENTS TEST COMPLETE failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)

func reset_players() -> void:
	for id: int in world.carts:
		var cart = world.carts[id]
		cart.position = Vector3(-100-id*5,0,0)
		cart.health = 100
		cart.protection_end = 0
		cart.stun_end = 0
		cart.slip_end = 0
		cart.repairing = false
		cart.finish_tick = -1
		cart.velocity = Vector3.ZERO

func test_cabinet(event: Dictionary) -> void:
	reset_players()
	var cart = world.carts[1]
	cart.position = event.root.to_global(Vector3(0,0,-2.5))
	world.carts[2].position = event.root.to_global(Vector3(3,0,-2.5))
	world.carts[3].position = cart.position
	world.carts[3].protection_end = 2000
	world.carts[4].position = cart.position
	world.carts[4].finish_tick = 1
	event.trigger = -1
	event.impact_done = false
	world.store_events.advance(1000,world.carts,false)
	check(event.trigger == -1,"Cabinet cannot activate during countdown or after race end")
	world.store_events.advance(1000,world.carts,true)
	world.store_events.render(1000)
	check(event.trigger == 1000 and event.marker.visible,"Nearby racer starts a visible red landing warning")
	world.store_events.advance(1089,world.carts,true)
	check(cart.health == 100 and cart.stun_end == 0,"Cabinet cannot hurt racers before its impact")
	world.store_events.advance(1090,world.carts,true)
	world.store_events.render(1090)
	check(cart.health == 75 and cart.stun_end == 1135,"Cabinet impact deals exactly 25 damage and 0.75 second stun")
	check(not event.marker.visible and is_equal_approx(event.pivot.rotation.x,-PI/2),"Cabinet lands inside the marked area and clears warning")
	check(world.carts[2].health == 100 and world.carts[2].stun_end == 0,"Racer outside the red area dodges the cabinet")
	check(world.carts[3].health == 100 and world.carts[3].stun_end == 0,"Spawn protection blocks cabinet damage and stun")
	check(world.carts[4].health == 100,"Finished racer is immune to cabinets")
	cart.protection_end = 0
	world.store_events.advance(1091,world.carts,true)
	check(cart.health == 75,"A cabinet impacts only once per activation")
	check(not event.collision.disabled,"Fallen cabinet has solid collision")
	world.store_events.break_cabinet(world.store_events.events.find(event),1091)
	world.store_events.render(1091)
	check(event.mask == 1 and event.collision.disabled and not event.pivot.visible,"One collision destroys cabinet and clears passage")
	world.store_events.render(1360)
	check(is_zero_approx(event.pivot.rotation.x) and event.collision.disabled,"Destroyed cabinet stays passable until rearming")
	world.store_events.advance(2079,world.carts,true)
	check(event.trigger == 1000,"Cabinet cooldown prevents rapid retriggering")
	world.store_events.advance(2080,world.carts,true)
	check(event.trigger == 2080,"Cabinet can trigger again after its cooldown")
	event.trigger = -1
	event.impact_done = false

func test_fruit(event: Dictionary) -> void:
	reset_players()
	var cart = world.carts[1]
	cart.position = event.root.to_global(Vector3(0,0,-2.5)+Events.FRUIT_OFFSETS[0])
	cart.velocity = Vector3(0,0,10)
	event.trigger = -1
	event.mask = 0
	world.store_events.advance(1000,world.carts,true)
	world.store_events.render(1036)
	check(event.fruits[0].visible and event.fruits[0].position.y > 1,"Fruit visibly drops from the produce rack")
	world.store_events.advance(1059,world.carts,true)
	check(cart.slip_end == 0,"Airborne fruit does not cause a premature slip")
	world.store_events.advance(1060,world.carts,true)
	world.store_events.render(1060)
	check(cart.slip_end == 1135 and cart.velocity.length() < 10 and cart.health == 100,"Ground fruit causes grip/speed loss without damage")
	check(event.mask & 1 and not event.fruits[0].visible,"Stepped-on fruit is consumed and hidden")
	cart.slip_end = 0
	world.store_events.advance(1061,world.carts,true)
	check(cart.slip_end == 0,"Consumed fruit cannot repeatedly affect the same spot")
	cart.position = event.root.to_global(Vector3(0,0,-2.5)+Events.FRUIT_OFFSETS[1])
	cart.protection_end = 2000
	world.store_events.advance(1062,world.carts,true)
	check(cart.slip_end == 0 and not (event.mask & 2),"Protected racer neither slips nor consumes fruit")
	world.store_events.render(1555)
	check(event.fruits.all(func(f: MeshInstance3D): return not f.visible),"Remaining fruit clears after eight seconds on the floor")
	# Leave a nonempty state for the replication check.
	event.trigger = 1000

func capture_previews() -> void:
	reset_players()
	for cart in world.carts.values(): cart.visible = false
	for site: Dictionary in world.store_events.events:
		site.trigger = -1
		site.mask = 0
	world.store_events.render(0)
	world.camera.position = Vector3(95,115,105)
	world.camera.fov = 45
	world.camera.look_at(Vector3.ZERO)
	world.camera.far = 350
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/store-overview.png")
	var event: Dictionary = world.store_events.events[0]
	event.trigger = 1000
	world.store_events.render(1090)
	world.carts[1].visible = true
	world.carts[1].position = event.root.to_global(Vector3(2.8,0,-3))
	world.camera.position = event.root.to_global(Vector3(10,10,-14))
	world.camera.look_at(event.root.to_global(Vector3(0,1,-2)))
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/cabinet-warning.png")
	event.trigger = -1
	var produce: Dictionary = world.store_events.events[3]
	produce.trigger = 1000
	produce.mask = 0
	world.store_events.render(1060)
	world.camera.position = produce.root.to_global(Vector3(8,7,-12))
	world.camera.look_at(produce.root.to_global(Vector3(0,0.8,-2)))
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/fruit-spill.png")

