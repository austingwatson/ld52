extends KinematicBody2D

onready var action_range = $ActionRange
onready var texture_progress = $TextureProgress

export var max_action_spots = 1
var current_drones = []
export var action_wait_time = 1.0
var time_left = 0.0

var action_range_radius = 0

var alive = true

func _ready():
	action_range_radius = $ActionRange/CollisionShape2D.shape.radius * 2

func _process(delta):
	if time_left > 0.0 && current_drones.size() > 0:
		time_left -= delta * current_drones.size()
		
		texture_progress.value = (action_wait_time - time_left) * texture_progress.max_value
		
		if time_left <= 0.0:
			action_done()

func action_start():
	pass
	
func action_interuppted():
	pass

func action_done():
	texture_progress.visible = false
	for drone in current_drones:
		drone.stop_action(self, action_range_radius)

func turn_on():
	collision_layer = 1
	collision_mask = 1
	action_range.collision_layer = 1
	action_range.collision_mask = 1

func turn_off():
	collision_layer = 0
	collision_mask = 0
	action_range.collision_layer = 0
	action_range.collision_mask = 0

func _on_ActionRange_body_entered(body):
	if not body.is_in_group("drone"):
		return
	if not body.is_action_moving():
		return
	if body.action_target != self:
		return
	
	if current_drones.size() == max_action_spots:
		body.stop_action(self, action_range_radius)
		return
	
	if current_drones.size() == 0:
		time_left = action_wait_time
		texture_progress.visible = true
		action_start()
		
	current_drones.append(body)
	body.in_action()

func _on_ActionRange_body_exited(body):
	if not body.is_in_group("drone"):
		return
	
	current_drones.erase(body)
	if current_drones.size() == 0:
		action_interuppted()
		texture_progress.visible = false
	
	if body.action_target == self:
		body.stop_action(self, action_range_radius)
