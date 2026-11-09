extends Node
var failures: int = 0
var app

func check(condition: bool, description: String) -> void:
	if condition: print("PASS: ",description)
	else:
		failures += 1
		push_error("FAIL: "+description)

func click(text: String) -> bool:
	for child in app.screen.find_children("*", "Button", true, false):
		if child is Button and child.text == text:
			child.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
			return true
	check(false,"Button exists: "+text)
	return false

func _ready() -> void:
	if await run_solo() != true:
		failures += 1
		push_error("Solo regression did not finish")
	if is_instance_valid(app): app.free()
	Session.leave()
	print("SOLO TEST COMPLETE failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)

func run_solo() -> bool:
	# Solo must work even when the menu's selected UDP port is already occupied.
	var blocker := ENetMultiplayerPeer.new()
	var occupied: Error = blocker.create_server(24567,1)
	print("Port blocker status: ",occupied)
	app = load("res://scenes/app.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	app.player_name.text = "Solo Regression"
	await click("PRACTICE SOLO")
	check(Session.phase == "race" and is_instance_valid(app.world),"Actual Solo button loads the race")
	check(Session.solo_mode and Session.peer == null and Session.multiplayer.multiplayer_peer is OfflineMultiplayerPeer,"Solo uses offline multiplayer and opens no UDP server")
	check(Session.roster.size() == 1 and Session.roster[1].name == "Solo Regression","Solo preserves player name with exactly one cart")
	if not is_instance_valid(app.world):
		blocker.close()
		return false
	for frame: int in 200: await get_tree().physics_frame
	check(app.world.tick >= app.world.start_tick,"Countdown ends and simulation starts")
	var cart = app.world.carts[1]
	var before: Vector3 = cart.position
	Input.action_press("accelerate")
	for frame: int in 90: await get_tree().physics_frame
	Input.action_release("accelerate")
	check(cart.position.distance_to(before) > 1.0,"Solo cart moves with the real accelerate input")
	Session.request_shift()
	for frame: int in 95: await get_tree().physics_frame
	check(app.world.layout == 1 and cart.gear == 2,"Offline Solo shift changes layout and personal gear")
	Session.back_to_lobby()
	await get_tree().process_frame
	check(Session.phase == "lobby" and Session.solo_mode,"Solo rematch returns to its one-player lobby")
	await click("READY")
	await click("START RACE")
	check(Session.phase == "race" and app.world.layout == 0 and app.world.carts[1].gear == 1,"Solo rematch loads fresh default route and gear")
	Session.leave()
	await get_tree().process_frame
	check(not Session.solo_mode and not Session.debug_small_lobby,"Leaving Solo restores normal multiplayer minimum")
	blocker.close()
	app.port.value = 24791
	await click("HOST LOBBY")
	check(Session.phase == "lobby" and Session.peer != null,"Host button still creates a network lobby without freed-signal errors")
	Session.set_ready(true)
	check(not Session.can_start(),"Normal network lobby still requires two players")
	Session.leave()
	await get_tree().process_frame
	await click("PRACTICE SOLO")
	check(Session.phase == "race" and Session.peer == null,"Solo can be launched again after leaving a network lobby")
	return true


