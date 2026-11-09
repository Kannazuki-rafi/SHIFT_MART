extends Node
## All RPCs live at this stable autoload path. Clients never submit transforms.
signal changed
signal message(text: String)
signal begin_race(roster: Dictionary, session_id: int)
signal input_received(peer_id: int, throttle: float, steer: float, recovery: bool, use_item: bool)
signal shift_received(peer_id: int)
signal snapshot_received(data: Dictionary)
signal return_lobby
const VERSION: String = "shift-mart-store-events-v4"
const MAX_PLAYERS: int = 4
var roster: Dictionary = {}
var phase: String = "menu"
var local_name: String = "Night Rider"
var peer: ENetMultiplayerPeer
var session_id: int = 0
var loaded: Dictionary = {}
var input_sequences: Dictionary = {}
var last_snapshot: int = -1
var timeout: float = 0.0
var version: String = VERSION
var debug_small_lobby: bool = false
var solo_mode: bool = false
var failure_reason: String = ""
var last_notice: String = ""

func _ready() -> void:
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): leave("Connection failed. Check address, UDP port and firewall."))
	multiplayer.server_disconnected.connect(func(): leave(failure_reason if not failure_reason.is_empty() else "Host disconnected. Session closed."))
	multiplayer.peer_disconnected.connect(_disconnected)
	for argument in OS.get_cmdline_user_args():
		if argument == "--debug-small-lobby": debug_small_lobby = true
		if argument == "--wrong-version": version = "incompatible-test"

func start_solo(display_name: String) -> void:
	leave()
	solo_mode = true
	local_name = _clean_name(display_name)
	phase = "lobby"
	roster[1] = {"name":local_name,"ready":true}
	start_race()

func host_session(display_name: String, port: int) -> Error:
	leave()
	local_name = _clean_name(display_name)
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port,MAX_PLAYERS-1,3)
	if error != OK:
		leave("Cannot open UDP port %d (error %d)." % [port,error])
		return error
	multiplayer.multiplayer_peer = peer
	phase = "lobby"
	roster[1] = {"name":local_name,"ready":false}
	changed.emit()
	return OK

func join_session(display_name: String, address: String, port: int) -> Error:
	leave()
	local_name = _clean_name(display_name)
	if address.strip_edges().is_empty():
		leave("Enter a host IP or hostname.")
		return ERR_INVALID_PARAMETER
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address.strip_edges(),port,3)
	if error != OK:
		leave("Cannot create connection (error %d)." % error)
		return error
	multiplayer.multiplayer_peer = peer
	phase = "connecting"
	timeout = 12.0
	changed.emit()
	return OK

func leave(reason: String = "") -> void:
	if peer != null: peer.close()
	peer = null
	solo_mode = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	roster.clear()
	loaded.clear()
	input_sequences.clear()
	last_snapshot = -1
	phase = "menu"
	timeout = 0
	failure_reason = ""
	changed.emit()
	if not reason.is_empty():
		last_notice = reason
		message.emit(reason)

func _process(delta: float) -> void:
	if timeout <= 0: return
	timeout -= delta
	if timeout <= 0:
		if phase == "connecting": leave("Connection timed out. Host may be full, offline, or unreachable through NAT/firewall.")
		elif phase == "loading" and multiplayer.is_server(): back_to_lobby("Loading timed out. Try again.")

func _connected() -> void:
	_register.rpc_id(1,local_name,version)

@rpc("any_peer","call_remote","reliable",0)
func _register(display_name: String, client_version: String) -> void:
	if not multiplayer.is_server(): return
	var sender: int = multiplayer.get_remote_sender_id()
	if client_version != VERSION:
		_reject.rpc_id(sender,"Version mismatch. Everyone must use the same SHIFT MART build.")
		return
	if phase != "lobby":
		_reject.rpc_id(sender,"Race already started. Join the next lobby.")
		return
	if roster.size() >= MAX_PLAYERS and not roster.has(sender):
		_reject.rpc_id(sender,"Server full (4 players).")
		return
	if roster.has(sender): return
	roster[sender] = {"name":_clean_name(display_name),"ready":false}
	_broadcast_roster()

@rpc("authority","call_remote","reliable",0)
func _reject(reason: String) -> void:
	leave(reason)

func _clean_name(value: String) -> String:
	var clean: String = value.strip_edges().replace("\n"," ").replace("\r"," ").substr(0,20)
	return "Night Rider" if clean.is_empty() else clean

func _broadcast_roster() -> void:
	if peer != null: _roster.rpc(roster)
	changed.emit()

@rpc("authority","call_remote","reliable",0)
func _roster(data: Dictionary) -> void:
	roster = data
	if phase == "connecting":
		phase = "lobby"
		timeout = 0
	changed.emit()

func set_ready(value: bool) -> void:
	if multiplayer.is_server(): _ready_for(1,value)
	else: _ready_request.rpc_id(1,value)

@rpc("any_peer","call_remote","reliable",0)
func _ready_request(value: bool) -> void:
	if multiplayer.is_server(): _ready_for(multiplayer.get_remote_sender_id(),value)

func _ready_for(id: int, value: bool) -> void:
	if phase != "lobby" or not roster.has(id): return
	roster[id].ready = value
	_broadcast_roster()

func can_start() -> bool:
	if phase != "lobby" or roster.size() < (1 if solo_mode or debug_small_lobby else 2): return false
	for data: Dictionary in roster.values():
		if not data.ready: return false
	return true

func start_race() -> void:
	if not multiplayer.is_server() or not can_start(): return
	session_id += 1
	loaded.clear()
	input_sequences.clear()
	if solo_mode: _load(session_id,roster)
	else: _load.rpc(session_id,roster)

@rpc("authority","call_local","reliable",0)
func _load(id: int, players: Dictionary) -> void:
	session_id = id
	roster = players
	last_snapshot = -1
	phase = "loading"
	timeout = 15.0
	begin_race.emit(roster,session_id)
	if multiplayer.is_server(): _mark_loaded(1,id)
	else: _loaded.rpc_id(1,id)

@rpc("any_peer","call_remote","reliable",0)
func _loaded(id: int) -> void:
	if multiplayer.is_server(): _mark_loaded(multiplayer.get_remote_sender_id(),id)

func _mark_loaded(player_id: int, id: int) -> void:
	if phase != "loading" or id != session_id or not roster.has(player_id): return
	loaded[player_id] = true
	if loaded.size() == roster.size():
		if solo_mode: _go(session_id)
		else: _go.rpc(session_id)

@rpc("authority","call_local","reliable",0)
func _go(id: int) -> void:
	if id != session_id: return
	phase = "race"
	timeout = 0
	changed.emit()

func send_input(sequence: int, throttle: float, steer: float, recovery: bool, use_item: bool = false) -> void:
	if phase != "race": return
	if multiplayer.is_server(): _accept_input(1,session_id,sequence,throttle,steer,recovery,use_item)
	else: _command_input.rpc_id(1,session_id,sequence,throttle,steer,recovery,use_item)

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _command_input(id: int, sequence: int, throttle: float, steer: float, recovery: bool, use_item: bool = false) -> void:
	if multiplayer.is_server(): _accept_input(multiplayer.get_remote_sender_id(),id,sequence,throttle,steer,recovery,use_item)

func _accept_input(sender: int, id: int, sequence: int, throttle: float, steer: float, recovery: bool, use_item: bool = false) -> void:
	if phase != "race" or id != session_id or not roster.has(sender): return
	if sequence <= int(input_sequences.get(sender,-1)) or not is_finite(throttle) or not is_finite(steer): return
	input_sequences[sender] = sequence
	input_received.emit(sender,clampf(throttle,-1,1),clampf(steer,-1,1),recovery,use_item)

func publish_snapshot(data: Dictionary) -> void:
	if multiplayer.is_server() and peer != null: _snapshot.rpc(data)

@rpc("authority","call_remote","unreliable_ordered",2)
func _snapshot(data: Dictionary) -> void:
	if int(data.get("session",-1)) != session_id or int(data.get("tick",-1)) <= last_snapshot: return
	last_snapshot = data.tick
	snapshot_received.emit(data)

func back_to_lobby(reason: String = "") -> void:
	if not multiplayer.is_server(): return
	if solo_mode: _lobby(reason)
	else: _lobby.rpc(reason)

@rpc("authority","call_local","reliable",0)
func _lobby(reason: String) -> void:
	phase = "lobby"
	loaded.clear()
	input_sequences.clear()
	last_snapshot = -1
	timeout = 0
	for id: int in roster: roster[id].ready = false
	return_lobby.emit()
	changed.emit()
	if not reason.is_empty(): message.emit(reason)

func _disconnected(id: int) -> void:
	if not multiplayer.is_server(): return
	roster.erase(id)
	loaded.erase(id)
	input_sequences.erase(id)
	_broadcast_roster()
	if phase == "loading" and loaded.size() == roster.size(): _go.rpc(session_id)

# Shifts use a reliable edge-triggered request, separate from movement snapshots.
func request_shift() -> void:
	if phase != "race": return
	if multiplayer.is_server(): shift_received.emit(1)
	else: _shift_request.rpc_id(1,session_id)

@rpc("any_peer","call_remote","reliable",0)
func _shift_request(id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and phase == "race" and id == session_id and roster.has(sender):
		shift_received.emit(sender)
