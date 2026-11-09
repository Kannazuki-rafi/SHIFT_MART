extends VBoxContainer
## Audio controls embedded in the main menu Settings modal.

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	for bus: StringName in SoundManager.BUSES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		add_child(row)
		var caption := Label.new()
		caption.text = str(bus)
		caption.custom_minimum_size.x = 90
		row.add_child(caption)
		var slider := HSlider.new()
		slider.name = str(bus) + "Volume"
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 36
		slider.max_value = 100
		slider.step = 1
		slider.value = SoundManager.get_volume(bus) * 100.0
		slider.tooltip_text = str(bus) + " volume (0 = mute)"
		row.add_child(slider)
		var percentage := Label.new()
		percentage.custom_minimum_size.x = 60
		percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		percentage.text = "%d%%" % slider.value
		row.add_child(percentage)
		slider.value_changed.connect(func(value: float):
			SoundManager.set_volume(bus, value / 100.0)
			percentage.text = "%d%%" % value
		)
	var preview := Button.new()
	preview.text = "TEST SOUND"
	preview.pressed.connect(SoundManager.play_ui_click)
	add_child(preview)
	var hint := Label.new()
	hint.text = "0% = mute. Volume changes are saved automatically."
	hint.add_theme_font_size_override("font_size", 16)
	add_child(hint)
