extends "res://scripts/entity/Enemy.gd"

onready var vision_cone = $VisionCone
onready var search_timer = $SearchTimer

var current_action = 0

var dome_target = null
var target = Vector2.ZERO
const target_max = 1.0

var velocity = Vector2.ZERO
export var speed = 20

var rotation_direction = 0
export var min_rotation = -5.0
export var max_rotation = 5.0
export var rotation_speed = 40.0

enum State {
	Idle,
	Moving,
	Panic,
	Searching
}
var state = State.Idle
var last_state = State.Idle

func _ready():
	move_to(Vector2(position.x - 500, position.y))

func _physics_process(delta):
	if not alive:
		return
	
	velocity = Vector2.ZERO
	if state == State.Moving || state == State.Panic:
		velocity = position.direction_to(target) * speed
		position += velocity * delta
		
		if position.distance_to(target) <= target_max:
			state = State.Idle
			
			if dome_target != null:
				queue_free()
			
		if rotation_direction == 0:
			rotation_degrees += rotation_speed * delta
			if rotation_degrees >= max_rotation:
				rotation_direction = 1
		else:
			rotation_degrees -= rotation_speed * delta
			if rotation_degrees <= min_rotation:
				rotation_direction = 0
	
	if velocity.length() == 0:
		rotation_degrees = 0

func action_done():
	.action_done()
	
	if current_action == 0:
		alive = false
		vision_cone.monitoring = false
		vision_cone.monitorable = false
	if current_action == 1:
		for drone in current_drones:
			if drone.give_brain():
				turn_off()
				max_action_spots = 0
				break
	
	current_action += 1

func move_to(target):
	self.target = target
	state = State.Moving
	
func move_to_dome(dome_target):
	self.dome_target = dome_target
	target = dome_target.position
	state = State.Moving
	
func action_start():
	last_state = state
	state = State.Idle
	
func action_interuppted():
	state = last_state

func _on_VisionCone_body_entered(body):
	if body.is_in_group("drone"):
		if state != State.Searching && state != State.Panic:
			state = State.Searching
			search_timer.start()

func _on_VisionCone_body_exited(body):
	if body.is_in_group("drone"):
		search_timer.stop()
		
		if state == State.Searching:
			state = State.Moving

func _on_SearchTimer_timeout():
	print("search complete")
	state = State.Panic
	
	var domes = get_tree().get_nodes_in_group("dome")
	var closest_dome_distance = 10000
	var closest_dome = null
	
	for dome in domes:
		if position.distance_to(dome.position) < closest_dome_distance:
			closest_dome_distance = dome.position
			closest_dome = dome
	if closest_dome != null:
		target = closest_dome.position
		dome_target = closest_dome
