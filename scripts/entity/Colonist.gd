extends "res://scripts/entity/Enemy.gd"

onready var animated_sprite = $AnimatedSprite
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

export var brains = 1
var in_action = false

enum PanicState {
	Calm,
	Panic,
	PanicFight
}
var panic_state = PanicState.Calm

enum State {
	Idle,
	Moving,
	Searching
}
var state = State.Idle

var being_dragged = false

func _ready():
	vision_cone.set_as_toplevel(true)	
	pass

func _physics_process(delta):
	if not alive:
		rotation_degrees = 0
		return
	
	velocity = Vector2.ZERO
	if state == State.Moving || panic_state == PanicState.Panic:
		move(delta)
	
	vision_cone.position = position
	
	if velocity.length() == 0:
		rotation_degrees = 0

func move(delta):
	var direction = position.direction_to(target)
		
	if direction.x >= 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
		
	velocity = direction * speed
	position += velocity * delta
		
	vision_cone.rotation = direction.angle()
		
	if position.distance_to(target) <= target_max:
		if panic_state == PanicState.Panic:
			get_parent().add_to_panic(1)
		
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

func action_done():
	in_action = false	
	.action_done()
	
	search_timer.paused = false
	
	if current_action == 0:
		alive = false
		vision_cone.monitoring = false
		vision_cone.monitorable = false
		animated_sprite.play("dead")
		
		current_action += 1
	elif current_action == 1:
		for drone in current_drones:
			if drone.give_brain():
				brains -= 1
				#turn_off()
				#max_action_spots = 0
				break
		if brains <= 0:
			current_action += 1
	elif current_action == 2:
		queue_free()

func move_to(target):
	self.target = target
	state = State.Moving
	
func move_to_dome(dome_target):
	self.dome_target = dome_target
	target = dome_target.position
	state = State.Moving
	
func action_start():
	in_action = true
	search_timer.paused = true
	
	state = State.Idle
	
	if panic_state == PanicState.Panic:
		panic_state = PanicState.PanicFight
	
func action_interuppted():
	in_action = false
	search_timer.paused = false
	
	state = State.Moving
	
	if panic_state == PanicState.PanicFight:
		panic_state = PanicState.Panic

func go_to_closest_dome():
	var domes = get_tree().get_nodes_in_group("dome")
	var closest_dome_distance = 10000
	var closest_dome = null
	
	for dome in domes:
		if position.distance_to(dome.position) < closest_dome_distance:
			closest_dome_distance = position.distance_to(dome.position)
			closest_dome = dome
	if closest_dome != null:
		vision_cone.monitoring = false
		vision_cone.monitorable = false
		target = closest_dome.position
		dome_target = closest_dome

func _on_SearchTimer_timeout():
	panic_state = PanicState.Panic
	animated_sprite.play("panic")
	
	go_to_closest_dome()

func _on_VisionCone_area_entered(area):
	if panic_state == PanicState.Panic || panic_state == PanicState.PanicFight:
		return
	
	if area.is_in_group("drone"):
		if state != State.Searching:
			state = State.Searching
			search_timer.start()
	elif area.is_in_group("colonist"):
		if !area.alive:
			if area.being_dragged:
				return
			
			if state != State.Searching:
				state = State.Searching
				search_timer.start()

func _on_VisionCone_area_exited(area):
	if panic_state == PanicState.Panic || panic_state == PanicState.PanicFight:
		return
	
	if area.is_in_group("drone"):
		search_timer.stop()
		
		if state == State.Searching:
			state = State.Moving
