extends "res://scripts/entity/Enemy.gd"

onready var label = $Label

export var population = 1
export var max_population = 6

var off = false
var powered = true

func action_done():
	.action_done()
	
	if population > 0:
		var brain_given = false
		
		for drone in current_drones:
			if drone.give_brain():
				brain_given = true
				break
		
		if not brain_given:
			return
		
		population -= 1
		label.text = str(population)
		
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
