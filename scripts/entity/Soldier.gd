extends "res://scripts/entity/Colonist.gd"

onready var guard_timer = $GuardTimer
onready var shoot_timer = $ShootTimer
onready var rest_timer = $RestTimer

enum FightState {
	None,
	GuardMoving,
	Guard,
	DragColonistMoving,
	DragColonist,
	Pursue
}
var fight_state = FightState.None

var suspect = 0
var guard_start_position = Vector2.ZERO
export var guard_rotation_speed = 0.005
var colonist_to_drag = null

var drone_in_sight = false
var drone_target = null
var resting = false
var can_shoot = false

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
		else:
			target = drone_target.position
			vision_cone.rotation = position.direction_to(target).angle()
			shoot()

func _exit_tree():
	if colonist_to_drag != null && is_instance_valid(colonist_to_drag):
		colonist_to_drag.queue_free()

func shoot():
	print("shoot")
	can_shoot = false
	shoot_timer.start()
	resting = true
	rest_timer.start()

func _on_SearchTimer_timeout():
	if suspect == 1:
		fight_state = FightState.GuardMoving
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
			shoot()
		elif state != State.Searching:
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
				target = area.position
				guard_start_position = position
				colonist_to_drag = area
				state = State.Searching
				search_timer.start()
				suspect = 1

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
	fight_state = FightState.DragColonistMoving
	dome_target = null

func _on_ShootTimer_timeout():
	can_shoot = true

func _on_RestTimer_timeout():
	resting = false
