extends Node

var music_started = false

func _input(event):
	if !music_started:
		music_started = true
		$MainMenuMusic.play()

func _on_Play_pressed():
	get_tree().change_scene("res://scenes/World.tscn")

func _on_Exit_pressed():
	get_tree().quit()

func _on_Volume_value_changed(value):
	AudioServer.set_bus_volume_db(SoundManager.sound_db, value)
	if value == -60:
		AudioServer.set_bus_mute(SoundManager.sound_db, true)
	else:
		AudioServer.set_bus_mute(SoundManager.sound_db, false)

func _on_Music_value_changed(value):
	AudioServer.set_bus_volume_db(SoundManager.music_db, value)
	if value == -60:
		AudioServer.set_bus_mute(SoundManager.music_db, true)
	else:
		AudioServer.set_bus_mute(SoundManager.music_db, false)
