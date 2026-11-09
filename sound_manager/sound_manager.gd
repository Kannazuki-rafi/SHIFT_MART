extends Node
## Global audio playback and persistent volume settings.

signal volume_changed(bus: StringName, value: float)

const SETTINGS_PATH := "user://audio_settings.cfg"
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX"]
var _volumes: Dictionary = {&"Master": 1.0, &"Music": 0.7, &"SFX": 0.8}
var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _click: AudioStreamWAV

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: StringName in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, &"Master")
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = &"SFX"
	_sfx.max_polyphony = 8
	add_child(_sfx)
	_click = _create_click()
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		for bus: StringName in BUSES:
			var value: Variant = config.get_value("volume", bus, _volumes[bus])
			if (value is float or value is int) and is_finite(float(value)):
				_volumes[bus] = clampf(float(value), 0.0, 1.0)
	for bus: StringName in BUSES:
		_apply_volume(bus)

func get_volume(bus: StringName) -> float:
	return float(_volumes.get(bus, 1.0))

func set_volume(bus: StringName, value: float) -> void:
	if not _volumes.has(bus) or not is_finite(value):
		return
	_volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_volume(bus)
	volume_changed.emit(bus, get_volume(bus))
	var config := ConfigFile.new()
	for name: StringName in BUSES:
		config.set_value("volume", name, _volumes[name])
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save audio settings: %s" % error_string(error))

func _apply_volume(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	var value := get_volume(bus)
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))

func play_music(stream: AudioStream) -> void:
	if stream == null:
		stop_music()
		return
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.play()

func stop_music() -> void:
	_music.stop()

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.play()

func play_ui_click() -> void:
	play_sfx(_click)

func _create_click() -> AudioStreamWAV:
	# Original short tone, so UI feedback needs no external audio assets.
	var data := PackedByteArray()
	var samples := 2646
	data.resize(samples * 2)
	for i in range(samples):
		var envelope := pow(1.0 - float(i) / samples, 3.0)
		var sample := sin(TAU * 660.0 * i / 44100.0) * envelope * 0.25
		data.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.data = data
	return stream
