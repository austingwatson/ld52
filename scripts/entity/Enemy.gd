extends KinematicBody2D

export var max_action_spots = 3
var current_drones = []
export var action_wait_time = 10.0
var time_left = 0.0

func _process(delta):
	if time_left > 0.0:
		time_left -= delta * current_drones.size()
		
		if time_left <= 0.0:
			action_done()

func action_done():
	pass

func _on_ActionRange_body_entered(body):
	if current_drones.size() == 0:
		time_left = action_wait_time
	current_drones.append(body)

func _on_ActionRange_body_exited(body):
	current_drones.erase(body)
