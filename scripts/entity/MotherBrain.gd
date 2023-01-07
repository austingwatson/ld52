extends "res://scripts/entity/Enemy.gd"

onready var label = $Label

var brains = 0

func action_done():
	.action_done()
	
	for drone in current_drones:
		if drone.brain.visible:
			brains += 1
			drone.brain.visible = false

	label.text = "Brains: " + str(brains)
