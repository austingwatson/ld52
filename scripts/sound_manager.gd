extends Node

var music_db = 0
var sound_db = 0

var death_rattle_1: AudioStreamPlayer
var death_rattle_2: AudioStreamPlayer
var death_rattle_3: AudioStreamPlayer
var death_rattle_4: AudioStreamPlayer
var gun_shot: AudioStreamPlayer
var harvest_saw: AudioStreamPlayer
var scoop: AudioStreamPlayer
var hurray: AudioStreamPlayer
var physic: AudioStreamPlayer
var alert: AudioStreamPlayer
var bing: AudioStreamPlayer

var final_alert = 0
var timer: Timer

func _ready():
	music_db = AudioServer.get_bus_index("Music")
	sound_db = AudioServer.get_bus_index("Sound")
	
	death_rattle_1 = AudioStreamPlayer.new()
	death_rattle_1.stream = preload("res://assets/sounds/DeathRattle_1.mp3")
	death_rattle_1.bus = "Sound"
	add_child(death_rattle_1)
	
	death_rattle_2 = AudioStreamPlayer.new()
	death_rattle_2.stream = preload("res://assets/sounds/DeathRattle_2.mp3")
	death_rattle_2.bus = "Sound"
	add_child(death_rattle_2)
	
	death_rattle_3 = AudioStreamPlayer.new()
	death_rattle_3.stream = preload("res://assets/sounds/DeathRattle_3.mp3")
	death_rattle_3.bus = "Sound"
	add_child(death_rattle_3)
	
	death_rattle_4 = AudioStreamPlayer.new()
	death_rattle_4.stream = preload("res://assets/sounds/DeathRattle_4.mp3")
	death_rattle_4.bus = "Sound"
	add_child(death_rattle_4)

	gun_shot = AudioStreamPlayer.new()
	gun_shot.stream = preload("res://assets/sounds/gunshot.wav")
	gun_shot.bus = "Sound"
	add_child(gun_shot)
	
	harvest_saw = AudioStreamPlayer.new()
	harvest_saw.stream = preload("res://assets/sounds/harvest_saw.wav")
	harvest_saw.bus = "Sound"
	add_child(harvest_saw)
	
	scoop = AudioStreamPlayer.new()
	scoop.stream = preload("res://assets/sounds/scoop.mp3")
	scoop.bus = "Sound"
	add_child(scoop)
	
	hurray = AudioStreamPlayer.new()
	hurray.stream = preload("res://assets/sounds/hurray.wav")
	hurray.bus = "Sound"
	add_child(hurray)
	
	physic = AudioStreamPlayer.new()
	physic.stream = preload("res://assets/sounds/psychic_pulse.wav")
	physic.bus = "Sound"
	add_child(physic)
	
	alert = AudioStreamPlayer.new()
	alert.stream = preload("res://assets/sounds/alarm.mp3")
	alert.bus = "Sound"
	add_child(alert)
	
	bing = AudioStreamPlayer.new()
	bing.stream = preload("res://assets/sounds/bing.mp3")
	bing.bus = "Sound"
	add_child(bing)
	
	timer = Timer.new()
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.one_shot = true
	add_child(timer)
	
func play_death_sound():
	var rng = randi() % 4
	match rng:
		0:
			if !death_rattle_1.playing:
				death_rattle_1.play()
		1:
			if !death_rattle_2.playing:
				death_rattle_2.play()
		2:
			if !death_rattle_3.playing:
				death_rattle_3.play()
		3:
			if !death_rattle_4.playing:
				death_rattle_4.play()
			
func play_gun_shot():
	gun_shot.play()

func play_harvest(number):
	if number > 0:
		if !harvest_saw.playing:
			harvest_saw.play()
		return
	var rng = randi() % 2
	match rng:
		0:
			if !harvest_saw.playing:
				harvest_saw.play()
		1:	
			if !scoop.playing:
				scoop.play()

func play_hurray():
	if !hurray.playing:
		hurray.play()
		
func play_physic():
	if !physic.playing:
		physic.play()

func play_alert():
	alert.play()

func play_bing():
	if !bing.playing:
		bing.play()

func play_final_alert():
	if final_alert == 0:
		final_alert += 1
		alert.play()
		timer.start(1.5)

func _on_Timer_timeout():
	if final_alert < 4:
		final_alert += 1
		alert.play()
		timer.start(1.5)
	
