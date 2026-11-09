# Sound manager

Audio scripts and the Master/Music/SFX bus layout live here. SoundManager is an
autoload and keeps playing across scenes. Settings are stored locally in
`user://audio_settings.cfg` and restored on startup. Volume 0 mutes that bus.

- `SoundManager.play_music(stream)` / `stop_music()` for background music.
- `SoundManager.play_sfx(stream)` for non-positional effects.
- `SoundManager.play_ui_click()` for the original generated UI tone.
- `SoundManager.set_volume(&"Music", 0.7)` for a linear 0–1 volume.

Put future music and sound files in this directory (or subdirectories). Enable
looping in music stream/import settings. Route positional AudioStreamPlayer3D
nodes to `SFX` so the same volume controls apply. No music assets ship yet.
