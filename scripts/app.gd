extends Node3D
const RaceWorld = preload("res://scripts/race/race_world.gd")
const MidnightTheme = preload("res://scripts/midnight_theme.gd")
const MenuAction = preload("res://scripts/menu_action.gd")
const LIME: Color = Color("d6f663")
const PALE: Color = Color("eff5e4")
var modal_focus_modes: Dictionary = {}
var previous_focus: Control
var menu_motion: bool = true
var menu_hint: Label
var saved_address := "127.0.0.1"
var saved_port := 24567
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
var test_events: bool = false
var test_events_verified: bool = false
var capture_path: String = ""
var results_shown: bool = false
var shift_busy_until: int = 0

func _ready() -> void:
	_setup_input()
	var preferences := ConfigFile.new()
	if preferences.load("user://menu_settings.cfg") == OK:
		menu_motion = bool(preferences.get_value("menu", "motion", true))
	ui = CanvasLayer.new()
	ui.name = "Interface"
	add_child(ui)
	get_viewport().size_changed.connect(_fit_screen)
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
	screen.name = "Screen"
	screen.size = Vector2(1280,720)
	ui.add_child(screen)
	_fit_screen()
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

func _fit_screen() -> void:
	if not is_instance_valid(screen): return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var factor: float = minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	screen.scale = Vector2.ONE * factor
	screen.position = (viewport_size - Vector2(1280,720) * factor) * 0.5

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
	node.pressed.connect(SoundManager.play_ui_click)
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
	screen.set_meta("midnight_menu",true)
	var art: Control = preload("res://scripts/menu_art.gd").new()
	art.name = "MenuArt"
	screen.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.motion_enabled = menu_motion
	_menu_theme()
	label(screen,"SHIFT MART   /   AFTER-HOURS TROLLEY RACING",Vector2(64,34),13,MidnightTheme.PAPER)
	label(screen,"STORE CLOSED.  NIGHT WIDE OPEN.",Vector2(66,324),14,MidnightTheme.PAPER)
	menu_hint = label(screen,"",Vector2(66,589),16,MidnightTheme.PAPER)
	var clock_in := _menu_action("CLOCK IN", "Host a lobby or join your friends.  2-4 riders.", 0, _multiplayer_menu)
	_menu_action("PRACTICE SOLO", "One trolley. The whole store. Practice offline.", 1, _solo_debug_drive)
	_menu_action("HOW TO PLAY", "Learn the routes, the gears, and the dirty tricks.", 2, _help)
	_menu_action("SETTINGS", "Tune your sound, screen, and menu motion.", 3, _settings)
	label(screen,"RACER",Vector2(66,632),12,MidnightTheme.MUTED)
	player_name = field(Session.local_name,Vector2(128,621),302)
	player_name.name = "RacerName"
	player_name.size.y = 36
	player_name.max_length = 20
	player_name.placeholder_text = "Your racer name"
	player_name.text_changed.connect(func(value: String): Session.local_name = value)
	label(screen,"TAB / ARROWS   MOVE     ENTER   SELECT",Vector2(64,686),12,MidnightTheme.MUTED)
	var credits := button(screen,"CREDITS",Vector2(684,670),132,_credits)
	credits.size.y = 40
	var quit := button(screen,"QUIT",Vector2(833,670),112,func(): get_tree().quit())
	quit.size.y = 40
	if not notice.is_empty(): panel(screen,Rect2(522,578,710,70),MidnightTheme.INK)
	status_label = label(screen,notice,Vector2(538,590),16,MidnightTheme.PINK)
	status_label.size = Vector2(678,48)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clock_in.grab_focus()

func _menu_action(text: String, hint: String, index: int, callback: Callable) -> Button:
	var action := MenuAction.new()
	action.name = "MenuAction%d" % index
	action.text = text
	action.index_text = "%02d" % (index + 1)
	action.position = Vector2(66 + index * 5,356 + index * 55)
	action.size = Vector2(398,49)
	action.motion_enabled = menu_motion
	action.pressed.connect(callback, CONNECT_DEFERRED)
	action.pressed.connect(SoundManager.play_ui_click)
	action.focus_entered.connect(func():
		if is_instance_valid(menu_hint): menu_hint.text = hint
	)
	screen.add_child(action)
	action.enter(0.08 + index * 0.065)
	return action

func _multiplayer_menu() -> void:
	_modal("CLOCK IN")
	label(overlay,"Bring the night crew. Host a lobby or join a friend.",Vector2(315,169),18,MidnightTheme.MUTED)
	var form := VBoxContainer.new()
	form.position = Vector2(315,213)
	form.size = Vector2(650,320)
	form.add_theme_constant_override("separation",12)
	overlay.add_child(form)
	var connection := HBoxContainer.new()
	connection.add_theme_constant_override("separation",16)
	form.add_child(connection)
	var address_column := VBoxContainer.new()
	address_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	address_column.add_theme_constant_override("separation",8)
	connection.add_child(address_column)
	_menu_caption(address_column,"HOST ADDRESS",13,PALE)
	address = field(saved_address,Vector2.ZERO,0)
	address.reparent(address_column)
	address.name = "HostAddress"
	address.custom_minimum_size.y = 44
	address.text_changed.connect(func(value: String): saved_address = value)
	var port_column := VBoxContainer.new()
	port_column.custom_minimum_size.x = 150
	port_column.add_theme_constant_override("separation",8)
	connection.add_child(port_column)
	_menu_caption(port_column,"PORT",13,PALE)
	port = SpinBox.new()
	port.custom_minimum_size.y = 44
	port.min_value = 1024
	port.max_value = 65535
	port.value = saved_port
	port.value_changed.connect(func(value: float): saved_port = int(value))
	port_column.add_child(port)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	form.add_child(actions)
	var host: Button = button(screen,"HOST LOBBY",Vector2.ZERO,0,func(): Session.host_session(player_name.text,int(port.value)))
	host.reparent(actions)
	host.custom_minimum_size.y = 50
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu_primary(host)
	var join: Button = button(screen,"JOIN HOST",Vector2.ZERO,0,func(): Session.join_session(player_name.text,address.text,int(port.value)))
	join.reparent(actions)
	join.custom_minimum_size.y = 50
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu_caption(form,"Same PC: 127.0.0.1  /  LAN: use the host IP",15,MidnightTheme.MUTED)
	var connection_help := LinkButton.new()
	connection_help.text = "Playing over the internet? Connection help"
	connection_help.add_theme_font_size_override("font_size",14)
	connection_help.pressed.connect(_connection_help, CONNECT_DEFERRED)
	form.add_child(connection_help)
	status_label = _menu_caption(form,notice,16,MidnightTheme.PINK)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 40
	button(overlay,"BACK",Vector2(315,550),650,_close_overlay)
	host.grab_focus()

func _menu_caption(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var caption: Label = label(parent,text,Vector2.ZERO,font_size,color)
	return caption

func _connection_help() -> void:
	_modal("CONNECT WITH FRIENDS")
	label(overlay,"Same computer: open two game windows.\nHost in one, then join 127.0.0.1 in the other.\n\nSame network: enter the host computer's local IP.\n\nInternet: enter the host's public IP. The host must\nforward UDP port 24567 (or the chosen port).\nDirect hosting through CGNAT is unsupported.",Vector2(315,185),19)
	button(overlay,"BACK",Vector2(315,540),650,_multiplayer_menu)

func _menu_theme() -> void:
	screen.theme = MidnightTheme.build()

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
	var backdrop := panel(overlay,Rect2(280,90,720,540))
	if screen.has_meta("midnight_menu"):
		var paper := StyleBoxFlat.new()
		paper.bg_color = MidnightTheme.INK
		paper.set_border_width_all(2)
		paper.border_color = MidnightTheme.MUTED
		paper.shadow_color = MidnightTheme.PINK
		paper.shadow_size = 0
		paper.shadow_offset = Vector2(8,8)
		backdrop.add_theme_stylebox_override("panel",paper)
		label(overlay,"STAFF ONLY / MIDNIGHT SHIFT",Vector2(315,603),11,MidnightTheme.MUTED)
	var heading := label(overlay,title,Vector2(315,118),34,MidnightTheme.ACID if screen.has_meta("midnight_menu") else LIME)
	heading.add_theme_font_override("font",MidnightTheme.heading_font())
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
	label(box,"DRIVE",Vector2(315,180),14,MidnightTheme.PINK)
	label(box,"W / Up    Accelerate\nS / Down    Brake, then reverse\nA / D    Steer\nE    Grip / Rush + route shift\nSpace    Use held item\nHold R (2s)    Recover\nEsc    Local menu",Vector2(315,211),17)
	label(box,"Recovery adds a 3s penalty.\nOnline races keep running\nwhile your local menu is open.",Vector2(315,440),16,MidnightTheme.MUTED)
	label(box,"RACE THE STORE",Vector2(650,180),14,MidnightTheme.PINK)
	label(box,"Follow the floor arrows.\nPass every checkpoint in order.\nCross checkout. Finish 3 laps.\n\nRoute gates give a 1.5s warning.\nMarked pads give you items.\nBroken carts respawn after 3s.\n\nRed floor: falling cabinet!\nDodge to avoid 25 damage + stun.\nFalling fruit makes tires slip.",Vector2(650,211),16)
	button(box,"BACK",Vector2(315,550),650,_close_overlay)

func _credits() -> void:
	var box: Control = _modal("CREDITS")
	label(box,"MIDNIGHT SHIFT / SHIFT MART\n\nProject direction: user-provided SHIFT MART plan\nImplementation: assisted by OpenAI Codex\nEngine: Godot (MIT)\n3D meshes: procedural prototype geometry\nMenu illustration + title: AI-generated concept assets\n\nReplaceable artwork for the final art pass.\nSee CREDITS.md for engine license information.",Vector2(318,200),19)
	button(box,"BACK",Vector2(315,550),650,_close_overlay)

func _settings() -> void:
	var box: Control = _modal("SETTINGS")
	var full: CheckButton = CheckButton.new()
	full.position = Vector2(320,180)
	full.text = "Fullscreen"
	full.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	full.toggled.connect(func(value: bool): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED))
	box.add_child(full)
	var reduce := CheckButton.new()
	reduce.name = "ReduceMotion"
	reduce.position = Vector2(320,225)
	reduce.text = "Reduce menu motion"
	reduce.button_pressed = not menu_motion
	reduce.toggled.connect(func(value: bool): _set_menu_motion(not value))
	box.add_child(reduce)
	label(box,"SOUND SETTINGS",Vector2(320,277),22,LIME)
	var audio_settings: VBoxContainer = preload("res://sound_manager/sound_settings.gd").new()
	audio_settings.position = Vector2(320,313)
	audio_settings.size.x = 640
	box.add_child(audio_settings)
	button(box,"BACK",Vector2(315,550),650,_close_overlay)
	full.grab_focus()

func _set_menu_motion(value: bool) -> void:
	menu_motion = value
	if screen.has_node("MenuArt"): screen.get_node("MenuArt").motion_enabled = value
	for child: Node in screen.get_children():
		if child is MenuAction: child.set_motion(value)
	var preferences := ConfigFile.new()
	preferences.set_value("menu","motion",value)
	var error: Error = preferences.save("user://menu_settings.cfg")
	if error != OK: push_warning("Could not save menu motion preference: %s" % error_string(error))

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
		if argument == "--test-events": test_events = true
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
		if test_events and world.session_id == 1:
			if multiplayer.is_server() and world.tick == 195:
				world.carts[1].position = world.store_events.events[0].root.to_global(Vector3(0,0,-2.5))
				world.carts[1].protection_end = 0
			if world.store_events.events[0].trigger >= 0 and not test_events_verified:
				test_events_verified = true
				print("EVENT VERIFIED: cabinet_trigger=",world.store_events.events[0].trigger)
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
