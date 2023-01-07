extends "res://scripts/entity/Enemy.gd"

var current_action = 0

func action_done():
	.action_done()
	
	if current_action == 0:
		alive = false
	if current_action == 1:
		for drone in current_drones:
			if drone.give_brain():
				turn_off()
				max_action_spots = 0
				break
	
	current_action += 1
