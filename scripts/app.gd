extends Node3D
const RaceWorld = preload("res://scripts/race/race_world.gd")
const LIME: Color = Color("d6f663")
const PALE: Color = Color("eff5e4")
var modal_focus_modes: Dictionary = {}
var previous_focus: Control
var menu_motion: bool = true
var ui: CanvasLayer
var screen: Control
var world
var player_name: LineEdit
var address: LineEdit
var port: SpinBox
var roster_label: Label
var status_label: Label
var start_button: Button
var ready_button: Button
var hud: Label
var center_label: Label
var overlay: Control
var last_phase: String = ""
var notice: String = ""
var debug_ready: bool = false
var debug_expected: int = 4
var test_seconds: float = -1
var test_elapsed: float = 0
var test_rematched: bool = false
var test_verified: bool = false
var test_shift_requested: bool = false
var test_shift_verified: bool = false
var capture_path: String = ""
var results_shown: bool = false
var shift_busy_until: int = 0

func _ready() -> void:
	_setup_input()
	ui = CanvasLayer.new()
	add_child(ui)
	Session.changed.connect(_session_changed)
	Session.message.connect(_message)
	Session.begin_race.connect(_begin)
	Session.return_lobby.connect(_return_lobby)
	_main_menu()
	_cli.call_deferred()

func _setup_input() -> void:
	var bindings: Dictionary = {"accelerate":[KEY_W,KEY_UP],"brake":[KEY_S,KEY_DOWN],"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"shift":[KEY_E],"recover":[KEY_R],"use_item":[KEY_SPACE]}
	for action: String in bindings:
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)

func _new_screen() -> void:
	modal_focus_modes.clear()
	previous_focus = null
	if is_instance_valid(screen): screen.free()
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(screen)
	var theme: Theme = Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color","Label",PALE)
	for state_name: String in ["normal","hover","pressed","focus"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("294b50") if state_name == "normal" else Color("486852")
		style.set_corner_radius_all(8)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		theme.set_stylebox(state_name,"Button",style)
	screen.theme = theme

func panel(parent: Node, rect: Rect2, color: Color = Color("112932")) -> Panel:
	var node: Panel = Panel.new()
	node.position = rect.position
	node.size = rect.size
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	node.add_theme_stylebox_override("panel",style)
	parent.add_child(node)
	return node

func label(parent: Node, text: String, pos: Vector2, font_size: int = 20, color: Color = PALE) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.position = pos
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	parent.add_child(node)
	return node

func button(parent: Node, text: String, pos: Vector2, width: float, callback: Callable) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.position = pos
	node.size = Vector2(width,48)
	node.pressed.connect(callback, CONNECT_DEFERRED)
	parent.add_child(node)
	if parent == overlay and not overlay.has_meta("initial_focus"):
		overlay.set_meta("initial_focus",true)
		node.grab_focus()
	return node

func field(text: String, pos: Vector2, width: float) -> LineEdit:
	var node: LineEdit = LineEdit.new()
	node.position = pos
	node.size = Vector2(width,44)
	node.text = text
	node.max_length = 100
	screen.add_child(node)
	return node

func _main_menu() -> void:
	_new_screen()
	var art: Control = preload("res://scripts/menu_art.gd").new()
	screen.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_theme()
	label(screen,"AFTER HOURS. NO SPEED LIMIT.",Vector2(44,30),15,LIME)
	var title: Label = label(screen,"SHIFT",Vector2(36,47),108,LIME)
	title.add_theme_constant_override("outline_size",2)
	label(screen,"MART",Vector2(39,149),108,Color("ffffff"))
	var badge: Panel = panel(screen,Rect2(398,190,135,38),Color("ff9654"))
	badge.rotation = -0.08
	label(badge,"NIGHT SHIFT",Vector2(10,7),17,Color("10151d"))
	label(screen,"Clock out. Roll in. Cause chaos.",Vector2(44,285),23)
	label(screen,"SUPERMARKET TROLLEY RACING",Vector2(45,322),13,Color("9bb8c1"))
	label(screen,"2-4 RIDERS    /    3 LAPS    /    TOTAL CHAOS",Vector2(44,574),15,LIME)
	button(screen,"HOW TO PLAY",Vector2(44,614),180,_help)
	button(screen,"SETTINGS",Vector2(236,614),145,_settings)
	button(screen,"CREDITS",Vector2(393,614),140,_credits)
	label(screen,"M0-M1  /  DEVELOPMENT BUILD",Vector2(44,680),12,Color("9bb8c1"))
	button(screen,"QUIT",Vector2(1120,660),112,func(): get_tree().quit())
	panel(screen,Rect2(582,28,650,612),Color("1c2632"))
	label(screen,"01  /  CLOCK IN",Vector2(614,50),14,Color("ff9654"))
	label(screen,"START YOUR SHIFT",Vector2(612,77),36,Color.WHITE)
	label(screen,"Grab a trolley. Bring your rivals.",Vector2(614,124),18,Color("b7cad3"))
	label(screen,"RACER NAME",Vector2(614,169),14,LIME)
	player_name = field(Session.local_name,Vector2(614,193),586)
	player_name.max_length = 20
	player_name.placeholder_text = "Enter your racer name"
	label(screen,"HOST ADDRESS",Vector2(614,252),14,Color("b7cad3"))
	address = field("127.0.0.1",Vector2(614,276),385)
	label(screen,"UDP PORT",Vector2(1020,252),14,Color("b7cad3"))
	port = SpinBox.new()
	port.position = Vector2(1020,276)
	port.size = Vector2(180,44)
	port.min_value = 1024
	port.max_value = 65535
	port.value = 24567
	screen.add_child(port)
	var host: Button = button(screen,"HOST LOBBY",Vector2(614,345),283,func(): Session.host_session(player_name.text,int(port.value)))
	_menu_primary(host)
	button(screen,"JOIN HOST",Vector2(917,345),283,func(): Session.join_session(player_name.text,address.text,int(port.value)))
	button(screen,"SOLO DEBUG DRIVE",Vector2(614,408),586,_solo_debug_drive)
	label(screen,"PRACTICE OFFLINE  /  NO CONNECTION NEEDED",Vector2(632,462),12,Color("9bb8c1"))
	label(screen,"DIRECT IP / CONNECTION NOTES",Vector2(614,504),13,Color("ff9654"))
	label(screen,"Host: public IP + UDP forwarding required (CGNAT unsupported).\nOn this PC: use 127.0.0.1 to connect a second window.",Vector2(614,530),15,Color("b7cad3"))
	status_label = label(screen,notice,Vector2(614,581),16,Color("ffb780"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size = Vector2(586,52)
	label(screen,"TAB / ARROWS  NAVIGATE     ENTER  SELECT",Vector2(614,678),12,Color("9bb8c1"))
	host.grab_focus()
	var motion: CheckButton = CheckButton.new()
	motion.text = "Menu motion"
	motion.position = Vector2(640,646)
	motion.button_pressed = menu_motion
	art.motion_enabled = menu_motion
	motion.toggled.connect(func(enabled: bool):
		menu_motion = enabled
		art.motion_enabled = enabled
	)
	screen.add_child(motion)
	if menu_motion:
		screen.modulate.a = 0.0
		screen.create_tween().tween_property(screen,"modulate:a",1.0,0.28)

func _menu_theme() -> void:
	for state_name: String in ["normal","hover","pressed","focus"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("293a4a") if state_name == "normal" else Color("40586b")
		if state_name == "focus": style.bg_color = Color(0,0,0,0)
		style.set_corner_radius_all(4)
		style.set_border_width_all(2 if state_name == "focus" else 1)
		style.border_color = LIME if state_name == "focus" else Color("577182")
		style.content_margin_left = 18
		style.content_margin_right = 18
		screen.theme.set_stylebox(state_name,"Button",style)
		screen.theme.set_color("font_color","Button",Color.WHITE)
	for state_name: String in ["normal","focus"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("101923")
		style.set_corner_radius_all(4)
		style.set_border_width_all(2)
		style.border_color = LIME if state_name == "focus" else Color("496172")
		style.content_margin_left = 14
		style.content_margin_right = 14
		screen.theme.set_stylebox(state_name,"LineEdit",style)
	screen.theme.set_color("font_color","LineEdit",Color.WHITE)
	screen.theme.set_color("font_color","CheckButton",PALE)

func _menu_primary(node: Button) -> void:
	for state_name: String in ["normal","hover","pressed"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = LIME if state_name == "normal" else Color("eaff9a")
		style.set_corner_radius_all(4)
		node.add_theme_stylebox_override(state_name,style)
	for state_name: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		node.add_theme_color_override(state_name,Color("10151d"))

func _solo_debug_drive() -> void:
	# Copy menu data before Session changes screens and frees the input controls.
	var display_name: String = player_name.text
	Session.start_solo(display_name)

func _message(text: String) -> void:
	notice = text
	print("SESSION NOTICE: ",text)
	if is_instance_valid(status_label): status_label.text = text

func _session_changed() -> void:
	if Session.phase == "menu":
		_destroy_world()
		_main_menu()
	elif Session.phase == "connecting":
		_lobby()
	elif Session.phase == "lobby":
		if last_phase != "lobby": _lobby()
		_update_lobby()
	last_phase = Session.phase

func _lobby() -> void:
	_new_screen()
	panel(screen,Rect2(100,60,1080,600))
	label(screen,"NIGHT SHIFT / LOBBY",Vector2(140,95),40,LIME)
	label(screen,"All riders must be ready. The host starts the session.",Vector2(142,155),20)
	roster_label = label(screen,"Connecting to host…",Vector2(145,220),27)
	ready_button = button(screen,"READY",Vector2(140,485),280,func():
		var id: int = multiplayer.get_unique_id()
		if Session.roster.has(id): Session.set_ready(not Session.roster[id].ready)
	)
	start_button = button(screen,"START RACE",Vector2(440,485),280,func(): Session.start_race())
	button(screen,"LEAVE",Vector2(740,485),280,func(): Session.leave())
	status_label = label(screen,"",Vector2(142,565),17,Color("ffb780"))
	_update_lobby()

func _update_lobby() -> void:
	if not is_instance_valid(roster_label): return
	var text: String = ""
	var ids: Array = Session.roster.keys()
	ids.sort()
	for id: int in ids:
		text += "%s   %s   %s\n" % ["✓" if Session.roster[id].ready else "○",Session.roster[id].name,"[HOST]" if id == 1 else ""]
	roster_label.text = text if not text.is_empty() else "Connecting… (12 second timeout)"
	start_button.visible = multiplayer.is_server() and Session.phase == "lobby"
	start_button.disabled = not Session.can_start()
	ready_button.disabled = Session.phase != "lobby"
	status_label.text = "%d / 4 riders  •  %s" % [ids.size(),"DEBUG: 1–2 riders allowed" if Session.debug_small_lobby else "Minimum 2 riders"]

func _destroy_world() -> void:
	if is_instance_valid(world): world.free()
	world = null
	results_shown = false
	shift_busy_until = 0

func _begin(players: Dictionary, id: int) -> void:
	_destroy_world()
	world = RaceWorld.new()
	world.name = "RaceWorld"
	add_child(world)
	world.setup(players,id)
	_new_screen()
	panel(screen,Rect2(20,18,1240,90),Color(0.04,0.10,0.14,0.94))
	hud = label(screen,"LOADING…",Vector2(45,34),21,LIME)
	center_label = label(screen,"WAITING FOR RIDERS",Vector2(410,245),42,LIME)
	panel(screen,Rect2(20,659,1240,43),Color(0.04,0.10,0.14,0.94))
	label(screen,"WASD / ARROWS  DRIVE      E  SHIFT      SPACE  USE ITEM      HOLD R  RECOVERY      ESC  LOCAL MENU",Vector2(40,669),15)
	print("WORLD LOADED session=",id," players=",players.size())

func _return_lobby() -> void:
	_destroy_world()
	last_phase = ""

func _process(delta: float) -> void:
	_test_process(delta)
	if not is_instance_valid(world) or not is_instance_valid(hud): return
	var id: int = multiplayer.get_unique_id()
	if not world.carts.has(id): return
	var cart = world.carts[id]
	var rank: int = world.rankings().find(id)+1
	var status_text: String = "GRIP: OK"
	if world.tick < cart.stun_end: status_text = "STUNNED! 💫"
	elif world.tick < cart.slip_end: status_text = "SLIPPING! 💧"
	var item_text: String = "[EMPTY]"
	if cart.held_item == "banana": item_text = "BANANA"
	elif cart.held_item == "can": item_text = "CAN"
	var layout_text: String = "BLUE" if world.layout == 0 else "ORANGE"
	var shift_text: String = "SHIFT READY"
	if world.shift_at >= 0:
		var name_text: String = Session.roster.get(world.shift_owner,{"name":"Racer"}).name
		shift_text = "%s > %s %.1fs" % [name_text,"ORANGE" if world.layout == 0 else "BLUE",(world.shift_at-world.tick)/60.0]
	elif world.tick < world.shift_available: shift_text = "SHIFT %.1fs" % ((world.shift_available-world.tick)/60.0)
	hud.text = "LAP %d / 3    POS %d / %d    DURABILITY %d    %s    ITEM %s\n%s    %s    %s    %s" % [mini(cart.laps+1,3),rank,world.carts.size(),cart.health,"GRIP" if cart.gear == 1 else "RUSH",item_text,layout_text,shift_text,status_text,world.navigation_text(cart)]
	if Session.phase == "loading": center_label.text = "WAITING FOR RIDERS"
	elif world.tick < 180: center_label.text = "READY  %d" % ceili((180-world.tick)/60.0)
	elif cart.repairing: center_label.text = "REPAIR  %.1fs" % maxf(0,(cart.repair_end-world.tick)/60.0)
	elif world.tick < cart.stun_end: center_label.text = "💫 STUNNED! 💫\n%.1fs" % maxf(0,(cart.stun_end-world.tick)/60.0)
	elif world.tick < cart.slip_end: center_label.text = "💧 WET TIRES / SLIP! 💧"
	elif cart.finish_tick >= 0 and not world.complete: center_label.text = "FINISHED!  WAITING…"
	elif world.tick < shift_busy_until: center_label.text = "SHIFT BUSY"
	elif world.tick < world.lap_notice_until: center_label.text = "LAP COMPLETE!"
	else: center_label.text = ""
	if world.complete and not results_shown:
		results_shown = true
		_results()

func _modal(title: String) -> Control:
	if is_instance_valid(overlay): _close_overlay()
	previous_focus = get_viewport().gui_get_focus_owner()
	for child: Node in screen.find_children("*","Control",true,false):
		var control: Control = child as Control
		if control.focus_mode != Control.FOCUS_NONE:
			modal_focus_modes[control] = control.focus_mode
			control.focus_mode = Control.FOCUS_NONE
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(overlay)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0,0,0,0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	panel(overlay,Rect2(280,90,720,540))
	label(overlay,title,Vector2(315,118),34,LIME)
	return overlay

func _close_overlay() -> void:
	if is_instance_valid(overlay): overlay.free()
	for control: Control in modal_focus_modes:
		if is_instance_valid(control): control.focus_mode = modal_focus_modes[control]
	modal_focus_modes.clear()
	if is_instance_valid(previous_focus): previous_focus.grab_focus()
	if is_instance_valid(world): world.local_menu = false

func _help() -> void:
	var box: Control = _modal("HOW TO PLAY")
	label(box,"W / Up      Accelerate\nS / Down    Brake, then reverse\nA / D       Steer\nE           Shift Grip / Rush and change shared layout\nSpace       Use banana peel or canned drink\nHold R 2s   Reset to last checkpoint (3s penalty)\nEsc         Local menu; race keeps running\n\nFollow floor arrows and pass checkpoints in order.\nCross checkout to complete each of three laps.\nBlue / Orange gates warn 1.5s before changing.\nDrive through marked pads to collect an item.\nBroken carts respawn at the last checkpoint after 3s.",Vector2(318,180),19)
	button(box,"BACK",Vector2(315,550),650,_close_overlay)

func _credits() -> void:
	var box: Control = _modal("CREDITS")
	label(box,"SHIFT MART / 3D multiplayer prototype\n\nProject direction: user-provided SHIFT MART plan\nImplementation: assisted by OpenAI Codex\nEngine: Godot 4.6.3 (MIT)\nAll meshes: original procedural primitive shapes\n\nReplace placeholders with your team's final assets.\nSee CREDITS.md for engine license information.",Vector2(318,200),20)
	button(box,"BACK",Vector2(315,550),650,_close_overlay)

func _settings() -> void:
	var box: Control = _modal("DISPLAY SETTINGS")
	var full: CheckButton = CheckButton.new()
	full.position = Vector2(320,220)
	full.text = "Fullscreen"
	full.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	full.toggled.connect(func(value: bool): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED))
	box.add_child(full)
	label(box,"Compatibility renderer • 720p canvas\nSimple lighting • Shadows off\nAudio and persistent settings planned for later milestone.",Vector2(320,310),19)
	button(box,"BACK",Vector2(315,550),650,_close_overlay)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("shift") and not event.is_echo() and is_instance_valid(world) and not is_instance_valid(overlay):
		if world.shift_at >= 0 or world.tick < world.shift_available: shift_busy_until = world.tick+90
		Session.request_shift()
	if event.is_pressed() and not event.is_echo() and event.keycode == KEY_ESCAPE:
		if is_instance_valid(overlay): _close_overlay()
		elif is_instance_valid(world) and not results_shown:
			world.local_menu = true
			var box: Control = _modal("TAKE A BREATHER")
			label(box,"The online race keeps running. Your trolley coasts.\nLeaving as host disconnects every rider.",Vector2(320,200),20)
			button(box,"CONTINUE",Vector2(315,315),650,_close_overlay)
			button(box,"LEAVE SESSION",Vector2(315,390),650,func(): Session.leave())

func _results() -> void:
	var box: Control = _modal("SHIFT COMPLETE")
	var text: String = ""
	var rank: int = 0
	for id: int in world.rankings():
		rank += 1
		var cart = world.carts[id]
		text += "%d.  %-20s  %s\n" % [rank,Session.roster[id].name,"%.2fs" % ((cart.finish_tick-180)/60.0) if cart.finish_tick >= 0 else "DNF"]
	label(box,text,Vector2(318,210),25)
	if multiplayer.is_server(): button(box,"REMATCH / BACK TO LOBBY",Vector2(315,485),650,func(): Session.back_to_lobby())
	else: label(box,"Waiting for host to return to lobby.",Vector2(318,485),20,LIME)
	button(box,"LEAVE SESSION",Vector2(315,550),650,func(): Session.leave())

func _cli() -> void:
	var host_port: int = 0
	var join_port: int = 0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--auto-host="): host_port = int(argument.get_slice("=",1))
		if argument.begins_with("--auto-join="): join_port = int(argument.get_slice("=",1))
		if argument.begins_with("--name="): Session.local_name = argument.get_slice("=",1)
		if argument == "--test-ready": debug_ready = true
		if argument.begins_with("--test-seconds="): test_seconds = float(argument.get_slice("=",1))
		if argument.begins_with("--test-expected="): debug_expected = int(argument.get_slice("=",1))
		if argument.begins_with("--capture="): capture_path = argument.trim_prefix("--capture=")
	if host_port > 0: Session.host_session(Session.local_name,host_port)
	elif join_port > 0: Session.join_session(Session.local_name,"127.0.0.1",join_port)
	if not capture_path.is_empty(): _capture.call_deferred()

func _test_process(delta: float) -> void:
	if test_seconds <= 0: return
	test_elapsed += delta
	if debug_ready and Session.phase == "lobby":
		var id: int = multiplayer.get_unique_id()
		if Session.roster.has(id) and not Session.roster[id].ready: Session.set_ready(true)
		if multiplayer.is_server() and Session.roster.size() == debug_expected and Session.can_start(): Session.start_race()
	if debug_ready and is_instance_valid(world) and Session.phase == "race":
		Input.action_press("accelerate")
		if world.tick > 230 and not test_verified:
			var local_cart = world.carts.get(multiplayer.get_unique_id())
			if local_cart != null and local_cart.position.distance_to(local_cart.safe_position) > 0.2:
				test_verified = true
				print("NETWORK VERIFIED: session=",Session.session_id," carts=",world.carts.size()," snapshot_tick=",world.tick," local movement=true")
		if multiplayer.is_server() and Session.session_id == 1 and world.tick > 235 and not test_shift_requested:
			test_shift_requested = true
			Session.request_shift()
		if Session.session_id == 1 and world.layout == 1 and world.carts[1].gear == 2 and not test_shift_verified:
			test_shift_verified = true
			print("SHIFT VERIFIED: session=1 layout=Orange host_gear=Rush")
		if multiplayer.is_server() and world.tick > 410 and not test_rematched:
			test_rematched = true
			Session.back_to_lobby("Integration test rematch")
		elif multiplayer.is_server() and Session.session_id == 2 and world.tick == 200:
			print("REMATCH VERIFIED: session=2 clean countdown and carts=",world.carts.size()," layout=",world.layout," gear=",world.carts[1].gear)
	if test_elapsed >= test_seconds:
		print("TEST EXIT phase=",Session.phase," roster=",Session.roster.size()," session=",Session.session_id)
		Session.leave()
		get_tree().quit()

func _capture() -> void:
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_path)
	Session.leave()
	get_tree().quit()
