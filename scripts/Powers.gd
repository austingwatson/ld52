extends Node2D

const slow_area_scene = preload("res://scenes/effect/SlowArea.tscn")
const dominated_drone_scene = preload("res://scenes/entity/DominatedDrone.tscn")

onready var noise_timer = $NoiseTimer
onready var slow_timer = $SlowTimer
onready var pulse = $Pulse
onready var mana_timer = $ManaTimer
onready var teleport_timer = $TeleportTimer
onready var dominate_timer = $DominateTimer

export var max_mana = 4
var mana = 1

export var noise_range = 200
var can_use_noise = true
var can_use_slow = true
var can_use_teleport = true
var can_use_dominate = true

func _unhandled_input(event):
	if WorldBounds.play_win_cutscene:
		return
	if mana <= 0:
		return
	
	if can_use_noise && WorldBounds.noise_av && event.is_action_pressed("noise"):
		var mouse_pos = get_global_mouse_position()
		
		var in_bounds = true
		if mouse_pos.x < WorldBounds.world_bounds_left.x || mouse_pos.x > WorldBounds.world_bounds_right.x:
			in_bounds = false
		elif mouse_pos.y < WorldBounds.world_bounds_left.y || mouse_pos.y > WorldBounds.world_bounds_right.y:
			in_bounds = false
		
		if in_bounds:
			var colonists = get_tree().get_nodes_in_group("colonist")
			for colonist in colonists:
				if mouse_pos.distance_to(colonist.position) <= noise_range:
					colonist.move_to_noise(mouse_pos)
			
			var domes = get_tree().get_nodes_in_group("dome")
			for dome in domes:
				if mouse_pos.distance_to(dome.position) <= noise_range:
					dome.turret_look_at(mouse_pos)
			
			pulse.visible = true
			pulse.play("default")
			pulse.frame = 0
			pulse.position = mouse_pos
			can_use_noise = false
			noise_timer.start()
		
			mana -= 2
			get_parent().add_to_mana(-2)
			
			SoundManager.play_physic()
	elif can_use_slow && WorldBounds.slow_av && event.is_action_pressed("slow"):
		var mouse_pos = get_global_mouse_position()
		
		var in_bounds = true
		if mouse_pos.x < WorldBounds.world_bounds_left.x || mouse_pos.x > WorldBounds.world_bounds_right.x:
			in_bounds = false
		elif mouse_pos.y < WorldBounds.world_bounds_left.y || mouse_pos.y > WorldBounds.world_bounds_right.y:
			in_bounds = false
		
		if in_bounds:
			var slow_area = slow_area_scene.instance()
			slow_area.position = mouse_pos
			get_parent().add_child(slow_area)
		
			can_use_slow = false
			slow_timer.start()
		
			mana -= 1
			get_parent().add_to_mana(-1)
			
			SoundManager.play_physic()
	elif can_use_teleport && WorldBounds.teleport_av && event.is_action_pressed("teleport"):
		var mouse_pos = get_global_mouse_position()
		
		var in_bounds = true
		if mouse_pos.x < WorldBounds.world_bounds_left.x || mouse_pos.x > WorldBounds.world_bounds_right.x:
			in_bounds = false
		elif mouse_pos.y < WorldBounds.world_bounds_left.y || mouse_pos.y > WorldBounds.world_bounds_right.y:
			in_bounds = false
		
		if in_bounds:
			var selected = get_parent().get_selected()
			if selected.size() > 0:
				can_use_teleport = false
				teleport_timer.start()
			
				for i in range(selected.size()):
					selected[i].position = mouse_pos + Vector2(i, i)
			
				mana -= 1
				get_parent().add_to_mana(-1)
				
				SoundManager.play_physic()
	elif can_use_dominate && WorldBounds.dominate_av && event.is_action_pressed("dominate"):
		can_use_dominate = false
		dominate_timer.start()
		
		var space = get_world_2d().direct_space_state
		var collision_objects = space.intersect_point(get_global_mouse_position(), 15, [], 0x7FFFFFFF, true, true)
		var enemy_unit = null
	
		for collision in collision_objects:
			if collision.collider.is_in_group("colonist"):
				enemy_unit = collision.collider
				break
		if enemy_unit != null:
			var dd = dominated_drone_scene.instance()
			dd.position = enemy_unit.position
			get_parent().add_child(dd)
			dd.switch_frames(enemy_unit.animated_sprite.frames)
			dd.health = 1
			enemy_unit.queue_free()
			
			mana -= 3
			get_parent().add_to_mana(-3)
			
			SoundManager.play_physic()

func start_mana_timer():
	mana_timer.start()

func _on_NoiseTimer_timeout():
	can_use_noise = true

func _on_Pulse_animation_finished():
	pulse.visible = false

func _on_ManaTimer_timeout():
	mana += 1
	if mana > max_mana:
		mana = max_mana
	else:
		get_parent().add_to_mana(1)

func _on_SlowTimer_timeout():
	can_use_slow = true

func _on_TeleportTimer_timeout():
	can_use_teleport = true

func _on_DominateTimer_timeout():
	can_use_dominate = true
