extends KinematicBody2D

onready var selection_label = $SelectionLabel
onready var brain = $Brain

var selected = false

var action_target = null
var target = Vector2.ZERO
const target_max = 1.0

var velocity = Vector2.ZERO
export var speed = 60

var flock_drones = []
var enemy = null
var enemy_min_distance = 0

var rotation_direction = 0
export var min_rotation = -5.0
export var max_rotation = 5.0
export var rotation_speed = 40.0

enum State {
	Idle,
	Moving,
	Action,
	ActionMoving
}
var state = State.Idle

func _physics_process(delta):
	velocity = Vector2.ZERO
	
	if state == State.ActionMoving:
		target = action_target.position
	
	if state == State.Moving || state == State.ActionMoving:
		velocity = position.direction_to(target) * speed
		position += velocity * delta
		
		if state != State.ActionMoving && position.distance_to(target) <= target_max:
			state = State.Idle
		
		if rotation_direction == 0:
			rotation_degrees += rotation_speed * delta
			if rotation_degrees >= max_rotation:
				rotation_direction = 1
		else:
			rotation_degrees -= rotation_speed * delta
			if rotation_degrees <= min_rotation:
				rotation_direction = 0

	elif state == State.Idle:
		if enemy != null:
			velocity = position.direction_to(enemy.position) * -speed
			position += velocity * delta
			
			if position.distance_to(enemy.position) > enemy_min_distance:
				enemy = null
		elif flock_drones.size() > 0:
			velocity = position.direction_to(flock_drones[0].position) * -speed
			position += velocity * delta
			
	if velocity.length() == 0:
		rotation_degrees = 0

func select():
	selected = true
	selection_label.visible = true

func deselect():
	selected = false
	selection_label.visible = false

func in_action():
	state = State.Action
	
func stop_action(enemy, enemy_min_distance):
	state = State.Idle
	
	self.enemy = enemy
	self.enemy_min_distance = enemy_min_distance

func give_brain():
	if brain.visible:
		return false
	else:
		brain.visible = true
		return true

func move_to(target):
	action_target = null
	self.target = target
	state = State.Moving

func action_move_to(action_target):
	self.action_target = action_target
	self.target = action_target.position
	state = State.ActionMoving

func is_action_moving():
	if state == State.ActionMoving:
		return true
	else:
		return false

func _on_SeperationRange_body_entered(body):
	if body == self:
		return
	
	if body.is_in_group("drone"):
		flock_drones.append(body)

func _on_SeperationRange_body_exited(body):
	if body == self:
		return
	
	if body.is_in_group("drone"):
		flock_drones.erase(body)
