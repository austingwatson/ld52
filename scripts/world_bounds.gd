extends Node

const world_bounds_left = Vector2(-480, -430)
const world_bounds_right = Vector2(480, 305)

var in_world = false

var panic_level = 0
var max_panic_level = 30
var dome_spotlight = false
var dome_turret = false
var soldiers_spawn = false
var soldiers_patrol = false
var dome_wall = false
var soldiers_replace_colonists = false
var domes_sealed = false
var soldiers_attack_mother = false

var noise_av = false
var slow_av = false
var teleport_av = false
var dominate_av = false

var drones_selected = false

var play_win_cutscene = false
var play_lost_cutscene = false
var status = 0

func _process(delta):
	var percent = float(panic_level) / float(max_panic_level) * 100
	
	if percent > 96:
		if !soldiers_attack_mother:
			soldiers_attack_mother = true
			
			var soldiers = get_tree().get_nodes_in_group("soldier")
			for soldier in soldiers:
				soldier.attack_mother_brain()
	if percent > 84:
		if !domes_sealed:
			domes_sealed = true
			
			var domes = get_tree().get_nodes_in_group("dome")
			for dome in domes:
				dome.turn_on_spotlight(5)
	if percent > 72:
		if !soldiers_replace_colonists:
			soldiers_replace_colonists = true
	if percent > 60:
		if !dome_wall:
			dome_wall = true
			
			var domes = get_tree().get_nodes_in_group("dome")
			for dome in domes:
				dome.turn_on_spotlight(4)
				dome.action_wait_time *= 2
				dome.max_action_spots *= 2
	if percent > 48:
		if !soldiers_patrol:
			soldiers_patrol = true
	if percent > 36:
		if !soldiers_spawn:
			soldiers_spawn = true
	if percent > 24:
		if !dome_turret:
			dome_turret = true
			
			var domes = get_tree().get_nodes_in_group("dome")
			for dome in domes:
				dome.turn_on_spotlight(3)
	if percent > 12:
		if !dome_spotlight:
			dome_spotlight = true
			
			var domes = get_tree().get_nodes_in_group("dome")
			for dome in domes:
				dome.turn_on_spotlight(0)

func max_panic():
	panic_level = max_panic_level
	print("max panic")
	return panic_level

func play_text(number):
	var dialogue = get_tree().get_nodes_in_group("dialogue")
	dialogue[0].play_text(number)

func reset():
	in_world = false
	
	panic_level = 0
	dome_spotlight = false
	dome_turret = false
	soldiers_spawn = false
	soldiers_patrol = false
	dome_wall = false
	soldiers_replace_colonists = false
	domes_sealed = false
	soldiers_attack_mother = false

	noise_av = false
	slow_av = false
	teleport_av = false
	dominate_av = false

	drones_selected = false

	play_win_cutscene = false
	play_lost_cutscene = false
	status = 0

func lose():
	status = 1
	if !play_lost_cutscene:
		play_text(6)
		var world = get_tree().get_nodes_in_group("world")
		world[0].start_lost_cutscene()
		play_lost_cutscene = true
	
func win():
	status = 2
	if !play_win_cutscene:
		play_text(7)
		var world = get_tree().get_nodes_in_group("world")
		world[0].start_win_cutscene()
		play_win_cutscene = true
