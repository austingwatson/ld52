extends "res://scripts/entity/Enemy.gd"

onready var label = $Label

export var population = 1
export var max_population = 6

var off = false
var powered = true

func action_done():
	.action_done()
	
	if population > 0:
		population -= 1
		label.text = str(population)
		for drone in current_drones:
			if drone.give_brain():
				break
		
		if population == 0:
			off = true

func allow_drone():
	return not off

func _on_FoodTimer_timeout():
	population += 1
	if population >= max_population:
		population = max_population
	off = false
		
	label.text = str(population)
