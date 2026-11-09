extends Node

func _ready() -> void:
	var app := preload("res://scenes/app.tscn").instantiate()
	add_child(app)
	app._settings()
	var slider: HSlider = app.overlay.find_child("SFXVolume", true, false)
	assert(slider != null, "Settings must contain the SFX slider")
	var original := SoundManager.get_volume(&"SFX")
	# Run with APPDATA pointing at a temporary directory to isolate saved settings.
	var bus := AudioServer.get_bus_index(&"SFX")
	assert(bus >= 0)
	assert(AudioServer.get_bus_index(&"Music") >= 0)
	assert(is_equal_approx(slider.value, original * 100.0))
	# Exercise real controls and save/load, then restore the original value.
	slider.value = 0
	assert(AudioServer.is_bus_mute(bus))
	slider.value = 35
	assert(not AudioServer.is_bus_mute(bus))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(bus)), 0.35))
	var config := ConfigFile.new()
	assert(config.load(SoundManager.SETTINGS_PATH) == OK)
	assert(is_equal_approx(float(config.get_value("volume", "SFX")), 0.35))
	SoundManager.play_ui_click()
	SoundManager.set_volume(&"SFX", original)
	app._close_overlay()
	print("PASS: audio settings UI, buses, mute, volume, persistence and playback")
	get_tree().quit()
