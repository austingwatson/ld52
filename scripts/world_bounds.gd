extends Node

const world_bounds_left = Vector2(-480, -430)
const world_bounds_right = Vector2(480, 305)

var panic_level = 0
var max_panic_level = 8
var dome_spotlight = false
var dome_turret = false
var soldiers_spawn = false
var soldiers_patrol = false
var dome_wall = false
var soldiers_replace_colonists = false
var domes_sealed = false
var soldiers_attack_mother = false

var drones_selected = false

func _process(delta):
	var percent = float(panic_level) / float(max_panic_level) * 100
	
	if percent > 96:
		if !soldiers_attack_mother:
			soldiers_attack_mother = true
	elif percent > 84:
		if !domes_sealed:
			domes_sealed = true
	elif percent > 72:
		if !soldiers_replace_colonists:
			soldiers_replace_colonists = true
	elif percent > 60:
		if !dome_wall:
			dome_wall = true
			
			var domes = get_tree().get_nodes_in_group("dome")
			for dome in domes:
				dome.turn_on_spotlight()
	elif percent > 48:
		if !soldiers_patrol:
			soldiers_patrol = true
	elif percent > 36:
		if !soldiers_spawn:
			soldiers_spawn = true
	elif percent > 24:
		if !dome_turret:
			dome_turret = true
			
			var domes = get_tree().get_nodes_in_group("dome")
			for dome in domes:
				dome.turn_on_spotlight()
	elif percent > 12:
		if !dome_spotlight:
			dome_spotlight = true
			
			var domes = get_tree().get_nodes_in_group("dome")
			for dome in domes:
				dome.turn_on_spotlight()
