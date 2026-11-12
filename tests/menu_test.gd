extends Node
var app
var failures := 0

func check(value: bool, description: String) -> void:
	if value: print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func click(text: String) -> void:
	var root: Control = app.overlay if is_instance_valid(app.overlay) else app.screen
	for node: Node in root.find_children("*", "BaseButton", true, false):
		if node.get("text") == text:
			node.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
			return
	check(false, "Missing button: " + text)

func escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	app._unhandled_key_input(key)
	await get_tree().process_frame

func _ready() -> void:
	app = preload("res://scenes/app.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	var first: Button = app.screen.get_node("MenuAction0")
	check(first.has_focus(), "Clock in receives initial keyboard focus")
	await click("HOW TO PLAY")
	check(is_instance_valid(app.overlay), "How to play opens")
	check(first.focus_mode == Control.FOCUS_NONE, "Modal blocks background keyboard focus")
	await escape()
	check(not is_instance_valid(app.overlay) and first.has_focus(), "Escape closes modal and restores keyboard focus")
	await click("SETTINGS")
	var original_motion: bool = app.menu_motion
	var reduce: CheckButton = app.overlay.get_node("ReduceMotion")
	reduce.button_pressed = true
	check(not app.menu_motion and not app.screen.get_node("MenuArt").motion_enabled, "Reduce motion disables artwork parallax")
	check(not first.has_focus(), "Focus remains inside settings")
	check(not first.motion_enabled and is_equal_approx(first.reveal, 1.0), "Reduce motion stops button animation")
	app._set_menu_motion(original_motion)
	await click("TEST SOUND")
	await click("BACK")
	await click("CREDITS")
	check(is_instance_valid(app.overlay), "Credits opens")
	await click("BACK")
	await click("CLOCK IN")
	check(is_instance_valid(app.address) and is_instance_valid(app.port), "Clock in exposes connection fields")
	app.address.text = "192.0.2.10"
	app.address.text_changed.emit(app.address.text)
	app.port.value = 24678
	await click("Playing over the internet? Connection help")
	await click("BACK")
	check(app.address.text == "192.0.2.10" and app.port.value == 24678, "Connection help returns to the form with values preserved")
	await click("BACK")
	check(not is_instance_valid(app.overlay), "Connection form returns to main menu")
	var key := InputEventKey.new()
	key.keycode = KEY_DOWN
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().process_frame
	key.pressed = false
	Input.parse_input_event(key)
	check(app.screen.get_node("MenuAction1").has_focus(), "Down arrow moves selection to solo")
	app.free()
	print("MENU TEST COMPLETE failures=", failures)
	get_tree().quit(0 if failures == 0 else 1)
