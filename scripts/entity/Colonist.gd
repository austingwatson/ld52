extends "res://scripts/entity/Enemy.gd"

const blood_texture = preload("res://assets/effects/blood.png")

onready var animated_sprite = $AnimatedSprite
onready var vision_cone = $VisionCone
onready var search_timer = $SearchTimer
onready var idle_timer = $IdleTimer
onready var harvest_effect = $HarvestEffect
onready var alert = $Alert
onready var force_home_timer = $ForceHome

var current_action = 0

var colonist_target = null
var dome_target = null
var target = Vector2.ZERO
const target_max = 1.0
const noise_target_max = 30.0

var velocity = Vector2.ZERO
export var speed = 20

var rotation_direction = 0
export var min_rotation = -5.0
export var max_rotation = 5.0
export var rotation_speed = 40.0

export var brains = 1
var in_action = false

var reported = false
var killed = false

var force_home = false
var in_dome = false
var home_dome = null
var drones_in_range = 0

enum PanicState {
	Calm,
	Panic,
	PanicFight
}
var panic_state = PanicState.Calm

enum State {
	Idle,
	Moving,
	MoveSearch,
	Searching,
	MoveNoise
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
	if in_action:
		return
	
	velocity = Vector2.ZERO
	if state == State.Moving || panic_state == PanicState.Panic || state == State.MoveSearch || state == State.MoveNoise:
		move(delta)
	elif state == State.Idle:
		if !force_home:
			force_home = true
			force_home_timer.start()
	
	vision_cone.position = position
	
	if velocity.length() == 0:
		rotation_degrees = 0
		
	if in_dome && state == State.Searching:
		search_timer.start()

func set_home_dome(dome):
	home_dome = dome

func move(delta):
	if slowed:
		delta *= 0.25
	
	var direction = position.direction_to(target)
		
	if direction.x >= 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
		
	velocity = direction * speed
	position += velocity * delta
	
	var in_bounds = true
	if position.x < WorldBounds.world_bounds_left.x || position.x > WorldBounds.world_bounds_right.x:
		in_bounds = false
	if position.y < WorldBounds.world_bounds_left.y || position.y > WorldBounds.world_bounds_right.y:
		in_bounds = false
	if !in_bounds:
		position -= velocity * delta
		state = State.Idle
		
	vision_cone.rotation = direction.angle() + rotation
	
	if state == State.MoveNoise && position.distance_to(target) <= noise_target_max:
		idle_timer.start()
		state = State.Idle
	elif position.distance_to(target) <= target_max:
		if panic_state == PanicState.Panic:
			get_parent().add_to_panic(1)
			if colonist_target != null && is_instance_valid(colonist_target):
				colonist_target.reported = true
		
		if state == State.MoveSearch:
			idle_timer.start()
		
		state = State.Idle
			
		if dome_target != null:
			dome_target.add_food()
			queue_free()
				
	if rotation_direction == 0:
		rotation_degrees += rotation_speed * delta
		if rotation_degrees >= max_rotation:
			rotation_direction = 1
	else:
		rotation_degrees -= rotation_speed * delta
		if rotation_degrees <= min_rotation:
			rotation_direction = 0

func dead():
	if !killed:
		if in_dome:
			go_to_closest_dome()
			var removing = false
			if dome_target != null && is_instance_valid(dome_target):
				var dis = position.distance_to(dome_target.position)
				if dis <= 35:
					removing = true
					queue_free()
			
			if !removing:
				killed = true
				var sprite = Sprite.new()
				sprite.z_index = -1
				sprite.position = position
				sprite.texture = blood_texture
				get_parent().add_child(sprite)
				SoundManager.play_death_sound()

func action_done():
	in_action = false	
	.action_done()
	
	search_timer.paused = false
	
	if current_action == 0:
		alert.visible = false
		alive = false
		#vision_cone.monitoring = false
		#vision_cone.monitorable = false
		vision_cone.set_deferred("monitoring", false)
		vision_cone.set_deferred("monitorable", false)
		vision_cone.visible = false
		animated_sprite.play("dead")
		
		current_action += 1
		action.text = "Harvest"
		dead()
		
	elif current_action == 1:
		for drone in current_drones:
			if drone.give_brain():
				SoundManager.play_harvest(0)
				brains -= 1
				harvest_effect.play("default")
				harvest_effect.visible = true
				#turn_off()
				#max_action_spots = 0
				break
		if brains <= 0:
			current_action += 1
			action.text = "Clean Up"
			
	elif current_action == 2:
		queue_free()

func move_to(target):
	self.target = target
	state = State.Moving
	
func move_to_dome(dome_target):
	self.dome_target = dome_target
	target = self.dome_target.position
	state = State.Moving

func move_to_noise(position):
	self.target = position
	state = State.MoveNoise
	dome_target = null
	panic_state = PanicState.Calm
	alert.visible = false
	
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
		#vision_cone.monitoring = false
		vision_cone.collision_layer = 0
		vision_cone.collision_mask = 0
		#vision_cone.set_deferred("monitoring", false)
		#vision_cone.set_deferred("monitorable", false)
		#vision_cone.monitorable = false
		target = closest_dome.position
		dome_target = closest_dome

func _on_SearchTimer_timeout():
	if state == State.MoveNoise:
		return
	
	panic_state = PanicState.Panic
	animated_sprite.play("panic")
	alert.play("panic")
	vision_cone.visible = false
	SoundManager.play_bing()
	
	go_to_closest_dome()

func _on_VisionCone_area_entered(area):
	if panic_state == PanicState.Panic || panic_state == PanicState.PanicFight:
		return
	
	if area.is_in_group("drone"):
		drones_in_range += 1
		if state != State.Searching:
			alert.play("spotted")
			if !in_dome:
				alert.visible = true
			state = State.Searching
			search_timer.start()
	elif area.is_in_group("colonist"):
		if !area.alive:
			if area.being_dragged:
				return
			
			if state != State.Searching:
				alert.play("spotted")
				alert.visible = true
				colonist_target = area
				state = State.Searching
				search_timer.start()

func _on_VisionCone_area_exited(area):
	if panic_state == PanicState.Panic || panic_state == PanicState.PanicFight:
		return
	
	if area.is_in_group("drone"):
		drones_in_range -= 1
		
		if drones_in_range <= 0: 
			search_timer.stop()
		
			if state == State.Searching:
				state = State.Moving
				alert.visible = false

func _on_IdleTimer_timeout():
	go_to_closest_dome()
	state = State.Moving

func _on_Colonist_area_entered(area):
	if area.is_in_group("dome"):
		vision_cone.visible = false
		in_dome = true

func _on_Colonist_area_exited(area):
	if alive and area.is_in_group("dome"):
		vision_cone.visible = true
		in_dome = false
		if state == State.Searching:
			alert.visible = true

func _on_HarvestEffect_animation_finished():
	harvest_effect.visible = false

func _on_ForceHome_timeout():
	force_home = false
	go_to_closest_dome()
	state = State.Moving
