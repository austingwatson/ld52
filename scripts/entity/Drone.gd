extends KinematicBody2D

onready var selection_label = $SelectionLabel
onready var nav_agent = $NavigationAgent2D

var selected = false

var target = Vector2.ZERO
const target_max = 1.0

var velocity = Vector2.ZERO
export var speed = 60

var rotation_direction = 0
export var min_rotation = -5.0
export var max_rotation = 5.0
export var rotation_speed = 40.0

enum MovementState {
	Idle,
	GroupMove,
	DirectMove
}
var movement_state = MovementState.Idle

func _ready():
	set_target_location(position, false)

func _physics_process(delta):
	if movement_state == MovementState.GroupMove:
		move_with_group()
	elif movement_state == MovementState.DirectMove:
		direct_move(delta)

	if velocity.length() > 0:
		if rotation_direction == 0:
			rotation_degrees += rotation_speed * delta
			if rotation_degrees >= max_rotation:
				rotation_direction = 1
		else:
			rotation_degrees -= rotation_speed * delta
			if rotation_degrees <= min_rotation:
				rotation_direction = 0
		
	if movement_state == MovementState.Idle:
		rotation_degrees = 0.0

func move_with_group():
	var move_direction = position.direction_to(nav_agent.get_next_location())
	velocity = move_direction * speed
	nav_agent.set_velocity(velocity)
	
	if nav_agent.is_navigation_finished():
		movement_state = MovementState.Idle

func direct_move(delta):
	velocity = Vector2.ZERO
	if position.distance_to(target) > target_max:
		velocity = position.direction_to(target) * speed
		position += velocity * delta
	else:
		movement_state = MovementState.Idle

func select():
	selected = true
	selection_label.visible = true

func deselect():
	selected = false
	selection_label.visible = false

func stop():
	movement_state = MovementState.Idle

func set_target_location(target, direct):
	self.target = target
	
	if not direct:
		movement_state = MovementState.GroupMove
		nav_agent.set_target_location(target)
	else:
		movement_state = MovementState.DirectMove

func _on_NavigationAgent2D_velocity_computed(safe_velocity):
	if not nav_agent.is_navigation_finished():
		velocity = move_and_slide(safe_velocity)
