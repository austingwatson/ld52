extends Area2D

onready var animated_sprite = $AnimatedSprite
onready var brain = $Brain
onready var line = $Line2D
onready var commands = $Commands
onready var animation_player = $AnimationPlayer
onready var attack = $Attack
onready var hit = $Hit
onready var interaction_line = $InteractionLine

var alive = true

var action_target = null
var target = Vector2.ZERO
const target_max = 1.0

var velocity = Vector2.ZERO
export var speed = 60

var flock_drones = []
var flock_enemies = []
var enemy = null
var enemy_min_distance = 0

var rotation_direction = 0
export var min_rotation = -5.0
export var max_rotation = 5.0
export var rotation_speed = 40.0

var action_commands = []

var health = 5

enum State {
	Idle,
	Moving,
	Action,
	ActionMoving
}
var state = State.Idle

func _ready():
	commands.set_as_toplevel(true)
	commands.add_point(position)
	
	interaction_line.set_as_toplevel(true)

func _physics_process(delta):
	if not alive:
		animated_sprite.play("dead")
		return
	
	velocity = Vector2.ZERO
	
	if state == State.ActionMoving && action_target != null && is_instance_valid(action_target):
		target = action_target.position
	
	if state == State.Moving || state == State.ActionMoving:
		velocity = position.direction_to(target) * speed
		
		if velocity.x >= 0:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
		
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
		if action_commands.size() > 0:
			next_action()		
		elif enemy != null && is_instance_valid(enemy):
			velocity = position.direction_to(enemy.position) * -speed
			position += velocity * delta
			
			if position.distance_to(enemy.position) > enemy_min_distance:
				enemy = null
		elif flock_enemies.size() > 0:
			velocity = position.direction_to(flock_enemies[0].position) * -speed
			position += velocity * delta
		elif flock_drones.size() > 0:
			velocity = position.direction_to(flock_drones[0].position) * -speed
			position += velocity * delta
	
	commands.points[0] = position	
			
	if velocity.length() == 0:
		rotation_degrees = 0

func switch_frames(frames):
	animated_sprite.frames = frames

func hurt():
	if WorldBounds.play_win_cutscene || WorldBounds.play_lost_cutscene:
		return
	
	SoundManager.play_gun_shot()
	hit.play("default")
	hit.visible = true
	health -= 1
	if health <= 0:
		WorldBounds.play_text(3)
		get_parent().remove_from_selected(self)
		queue_free()

func select():
	line.visible = true

func deselect():
	line.visible = false

func holding_shift(shift):
	commands.visible = shift

func in_action():
	state = State.Action
	animated_sprite.play("action")
	
	interaction_line.clear_points()
	
	if action_target != null && is_instance_valid(action_target):
		interaction_line.add_point(position)
		interaction_line.add_point(action_target.position)
		
		if action_target.is_in_group("colonist") || action_target.is_in_group("generator"):
			if action_target.alive:
				attack.play("default")
				attack.visible = true
				
				if animated_sprite.flip_h:
					attack.position = Vector2(-7, 0)
				else:
					attack.position = Vector2(7, 0)

func stop():
	state = State.Idle
	
func stop_action(enemy, enemy_min_distance):
	state = State.Idle
	animated_sprite.play("alive")
	
	self.enemy = enemy
	self.enemy_min_distance = enemy_min_distance
	
	interaction_line.clear_points()

func action_interuppted():
	interaction_line.clear_points()

func holding_brain():
	return brain.visible

func give_brain():
	if brain.visible:
		return false
	else:
		WorldBounds.play_text(1)
		animation_player.play("plus_brain")
		brain.visible = true
		return true

func next_action():
	var type = action_commands.pop_front()
	var value = action_commands.pop_front()
	if type == "move_to":
		move_to(value)
	elif type == "action_move_to":
		action_move_to(value)
		
	if commands.points.size() > 2:
		commands.remove_point(1)

func add_action(type, value, position):
	commands.add_point(position)
		
	action_commands.push_back(type)
	action_commands.push_back(value)

func remove_commands():
	action_commands.clear()
	commands.clear_points()
	commands.add_point(position)

func move_to(target):
	action_target = null
	self.target = target
	state = State.Moving

func action_move_to(action_target):
	if !is_instance_valid(action_target):
		return
	self.action_target = action_target
	self.target = action_target.position
	state = State.ActionMoving
	
	for enemy in flock_enemies:
		if self.action_target == enemy:
			state = State.Idle
			break

func is_action_moving():
	if state == State.ActionMoving:
		return true
	else:
		return false

func _on_Drone_area_entered(area):
	if area == self:
		return
	
	if area.is_in_group("enemy"):
		flock_enemies.append(area)
	elif area.is_in_group("drone"):
		flock_drones.append(area)

func _on_Drone_area_exited(area):
	if area == self:
		return
	
	if area.is_in_group("enemy"):
		flock_enemies.erase(area)
	elif area.is_in_group("drone"):
		flock_drones.erase(area)

func _on_Attack_animation_finished():
	attack.visible = false

func _on_Hit_animation_finished():
	hit.visible = false
