extends Area2D

onready var collision_shape = $CollisionShape2D
onready var texture_progress = $TextureProgress
onready var action = $Action

export var max_action_spots = 1
var current_drones = []
export var action_wait_time = 1.0
var time_left = 0.0

var action_range_radius = 0

var show_action = true
var on = true
var alive = true

var slowed = false

func _ready():
	if collision_shape.shape is CircleShape2D:
		action_range_radius = collision_shape.shape.radius

func _process(delta):
	if time_left > 0.0 && current_drones.size() > 0:
		time_left -= delta * current_drones.size()
		
		var progress = (action_wait_time - time_left) / action_wait_time * texture_progress.max_value
		texture_progress.value = progress
		
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
	on = true
	collision_layer = 1
	collision_mask = 1

func turn_off():
	on = false
	collision_layer = 0
	collision_mask = 0

func _on_Enemy_area_entered(area):
	if not area.is_in_group("drone"):
		return
	if not area.is_action_moving():
		return
	if area.action_target != self:
		return
	
	if current_drones.size() == max_action_spots:
		area.stop_action(self, action_range_radius)
		return
	
	if current_drones.size() == 0:
		time_left = action_wait_time
		texture_progress.visible = true
		action_start()
		
	current_drones.append(area)
	area.in_action()

func _on_Enemy_area_exited(area):
	if not area.is_in_group("drone"):
		return
	
	area.action_interuppted()
	current_drones.erase(area)
	if current_drones.size() == 0:
		action_interuppted()
		texture_progress.visible = false
		
	
	if area.action_target == self:
		area.stop_action(self, action_range_radius)

func _on_Enemy_mouse_entered():
	if WorldBounds.drones_selected && show_action:
		action.visible = true

func _on_Enemy_mouse_exited():
	action.visible = false
