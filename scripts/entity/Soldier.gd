extends "res://scripts/entity/Colonist.gd"

onready var guard_timer = $GuardTimer
onready var shoot_timer = $ShootTimer
onready var rest_timer = $RestTimer
onready var muzzle_flash = $MuzzleFlash
onready var patrol_timer = $PatrolTimer

enum FightState {
	None,
	GuardMoving,
	Guard,
	DragColonistMoving,
	DragColonist,
	Pursue,
	Patrol,
	AttackMotherBrain
}
var fight_state = FightState.None

var suspect = 0
var guard_start_position = Vector2.ZERO
export var guard_rotation_speed = 0.005
var colonist_to_drag = null

var drone_in_sight = false
var drone_target = null
var mother_target = null
var resting = false
var can_shoot = false

var patrol_queue = []
var patrol_rest = true

var mother_brain_in_range = false

func _ready():
	var rng = randi() % 2
	if rng == 0:
		guard_rotation_speed = -guard_rotation_speed

func _physics_process(delta):
	if !alive:
		return
	if in_action:
		return
	
	if fight_state == FightState.GuardMoving:
		move(delta)
		if position.distance_to(target) <= guard_start_position.distance_to(target) * 0.5:
			fight_state = FightState.Guard
			
	elif fight_state == FightState.Guard:
		vision_cone.rotate(guard_rotation_speed)
		
		var dir = cos(vision_cone.rotation)
		if dir <= 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
		
		if is_instance_valid(colonist_to_drag) && colonist_to_drag.being_dragged:
			fight_state = FightState.None
			state = State.Moving
			go_to_closest_dome()
			
	elif fight_state == FightState.DragColonistMoving:
		move(delta)
		if position.distance_to(target) <= target_max:
			if !is_instance_valid(colonist_to_drag):
				fight_state = FightState.None
				state = State.Moving
				go_to_closest_dome()
			elif !colonist_to_drag.being_dragged:
				colonist_to_drag.being_dragged = true
				fight_state = FightState.DragColonist
				go_to_closest_dome()
				return
			else:
				fight_state = FightState.None
				state = State.Moving
				go_to_closest_dome()
		if is_instance_valid(colonist_to_drag) && colonist_to_drag.being_dragged:
			fight_state = FightState.None
			state = State.Moving
			go_to_closest_dome()
		
	elif fight_state == FightState.DragColonist:
		if !is_instance_valid(colonist_to_drag):
			fight_state = FightState.None
			state = State.Moving
			go_to_closest_dome()
			return
		move(delta)
		colonist_to_drag.position += velocity * delta
		
	elif fight_state == FightState.Pursue:
		if resting:
			return
		if !drone_in_sight:
			move(delta)
			if position.distance_to(target) <= target_max:
				fight_state = FightState.Guard
				guard_timer.start()
		else:
			if is_instance_valid(drone_target):
				target = drone_target.position
				vision_cone.rotation = position.direction_to(target).angle()
				if can_shoot:
					shoot()
			else:
				fight_state = FightState.Guard
	
	elif fight_state == FightState.Patrol:
		if state == State.Idle:
			if patrol_rest:
				patrol_timer.start()
				patrol_rest = false
				
	elif fight_state == FightState.AttackMotherBrain:
		if mother_brain_in_range && can_shoot:
			shoot()

func _exit_tree():
	if colonist_to_drag != null && is_instance_valid(colonist_to_drag):
		print("adding panic from here")
		get_parent().add_to_panic(1)
		colonist_to_drag.queue_free()

func go_to_mother_brain():
	var mother_brain = get_tree().get_nodes_in_group("mother_brain")
	move_to(mother_brain[0].position)

func attack_mother_brain():
	go_to_mother_brain()
	fight_state = FightState.AttackMotherBrain

func move_to_search(position):
	move_to(position)
	state = State.MoveSearch

func shoot():
	can_shoot = false
	shoot_timer.start()
	resting = true
	rest_timer.start()
	
	muzzle_flash.play("default")
	muzzle_flash.visible = true
	
	if animated_sprite.flip_h:
		muzzle_flash.flip_h = true
		muzzle_flash.position = Vector2(-13, -1)
	else:
		muzzle_flash.flip_h = false
		muzzle_flash.position = Vector2(13, -1)
	
	if fight_state == FightState.AttackMotherBrain:
		var mother_brain = get_tree().get_nodes_in_group("mother_brain")
		mother_brain[0].hurt()
	elif drone_target != null && is_instance_valid(drone_target):	
		drone_target.hurt()

func patrol():
	for i in range(4):
		var x = randi() % 301 - 150
		var y = randi() % 301 - 150
		patrol_queue.append(position + Vector2(x, y))
		
	move_to(patrol_queue.pop_front())
	fight_state = FightState.Patrol

func _on_SearchTimer_timeout():
	alert.visible = false
	
	if suspect == 1:
		fight_state = FightState.GuardMoving
		if !is_instance_valid(colonist_to_drag):
			return
		colonist_to_drag.reported = true
		guard_timer.start()
	elif suspect == 2:
		drone_in_sight = true
		fight_state = FightState.Pursue
		dome_target = null
		shoot()
	
	suspect = 0

func _on_VisionCone_area_entered(area):
	if area.is_in_group("drone"):
		if fight_state == FightState.GuardMoving || fight_state == FightState.Guard:
			drone_in_sight = true
			drone_target = area
			fight_state = FightState.Pursue
			dome_target = null
			if can_shoot:
				shoot()
		elif state != State.Searching:
			alert.play("spotted")
			alert.visible = true
			drone_target = area
			state = State.Searching
			search_timer.start()
			suspect = 2
	elif area.is_in_group("colonist"):
		if fight_state == FightState.GuardMoving || fight_state == FightState.Guard:
			return
		elif fight_state == FightState.DragColonistMoving || fight_state == FightState.DragColonist:
			return
		
		if !area.alive:
			if area.being_dragged:
				return
			
			if state != State.Searching:
				alert.play("spotted")
				alert.visible = true
				target = area.position
				guard_start_position = position
				colonist_to_drag = area
				state = State.Searching
				search_timer.start()
				suspect = 1
	elif area.is_in_group("mother_brain"):
		if fight_state == FightState.AttackMotherBrain:
			if !mother_brain_in_range:
				can_shoot = true
			
			state = State.Idle
			mother_brain_in_range = true
		else:
			panic_state = PanicState.Panic
			go_to_closest_dome()

func _on_VisionCone_area_exited(area):
	if area.is_in_group("drone"):
		if fight_state == FightState.Pursue:
			drone_in_sight = false
			return
		
		search_timer.stop()
		suspect = 0
		
		if state == State.Searching:
			state = State.Moving

func _on_GuardTimer_timeout():
	if drone_target != null:
		fight_state = FightState.None
		state = State.Moving
		go_to_closest_dome()
	else:
		fight_state = FightState.DragColonistMoving
		dome_target = null

func _on_ShootTimer_timeout():
	can_shoot = true

func _on_RestTimer_timeout():
	resting = false

func _on_MuzzleFlash_animation_finished():
	muzzle_flash.visible = false
	muzzle_flash.playing = false

func _on_PatrolTimer_timeout():
	patrol_rest = true
	if patrol_queue.size() > 0:
		move_to(patrol_queue.pop_front())
	else:
		fight_state = FightState.None
		state = State.Moving
		go_to_closest_dome()
