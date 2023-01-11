extends "res://scripts/entity/Enemy.gd"

const colonist_scene = preload("res://scenes/entity/Colonist.tscn")
const blue_colonist_scene = preload("res://scenes/entity/BlueColonist.tscn")
const scientist_scene = preload("res://scenes/entity/Scientist.tscn")
const soldier_scene = preload("res://scenes/entity/Soldier.tscn")

onready var animated_sprite = $AnimatedSprite
onready var food_timer = $FoodTimer
onready var food_bar = $FoodBar
onready var turret_base = $TurretBase
onready var vision_cone = $VisionCone
onready var build_timer = $BuildTimer
onready var action_timer = $ActionTimer
onready var turret = $VisionCone/Turret
onready var vision_light = $VisionCone/VisionLight
onready var dome_wall = $DomeWall
onready var muzzle_flash = $VisionCone/MuzzleFlash
onready var pop_change = $PopChange

export var population = 1
export var max_population = 7

var powered = true
var progress = 0

var pop_lights = []

export var spotlight_rotation_speed = 0.2
var spotlight_on = false
var spotlight_build = 0
var turret_on = false

var target_drone = null
var drones = []
var doing_action = false

var reported = []
var domes_not_connected = []

func _ready():
	pop_lights.append($Pop1)
	pop_lights.append($Pop2)
	pop_lights.append($Pop3)
	pop_lights.append($Pop4)
	pop_lights.append($Pop5)
	pop_lights.append($Pop6)
	pop_lights.append($Pop7)
	
	vision_cone.set_as_toplevel(true)
	vision_cone.position = position - Vector2(0, 28)
	vision_cone.rotation = rand_range(0.0, 10.0)
	vision_cone.z_index = 5
	
	build_timer.wait_time = rand_range(1.0, 3.0)
	
	var rng = randi() % 2
	if rng == 0:
		spotlight_rotation_speed = -spotlight_rotation_speed
		
	rng = randi() % max_population
	for i in range(rng):
		add_food()
	
	$StartFoodTimer.start(rand_range(0.1, 5))

func _physics_process(delta):
	if !on:
		return
		
	if slowed:
		delta *= 0.25
	
	if turret_on:
		if drones.size() > 0:
			vision_cone.rotation = lerp_angle(vision_cone.rotation, vision_cone.position.direction_to(drones[0].position).angle(), 0.7 * delta)
			
			if !doing_action:
				target_drone = drones[0]
				doing_action = true
				action_timer.start()
		else:
			vision_cone.rotate(spotlight_rotation_speed * delta)
	elif spotlight_on:
		if drones.size() > 0:
			vision_cone.rotation = lerp_angle(vision_cone.rotation, vision_cone.position.direction_to(drones[0].position).angle(), 0.7 * delta)
			
			if !doing_action:
				target_drone = drones[0]
				doing_action = true
				action_timer.start()
		else:
			vision_cone.rotate(spotlight_rotation_speed * delta)

func _process(delta):
	progress = (food_timer.wait_time - food_timer.time_left) / food_timer.wait_time * food_bar.max_value
	food_bar.value = progress
	
	if on:
		animated_sprite.play("powered")
		if progress < 25:
			animated_sprite.frame = 0
		elif progress >= 25 && progress < 50:
			animated_sprite.frame = 1
		elif progress >= 50 && progress < 75:
			animated_sprite.frame = 2
		elif progress >= 75:
			animated_sprite.frame = 3
	else:
		animated_sprite.play("unpowered")

func add_dome_not_connected(dome):
	domes_not_connected.append(dome)

func remove_dome_not_connected(dome):
	domes_not_connected.erase(dome)

func not_connected_to_dome(max_domes):
	return domes_not_connected.size() == max_domes - 1

func start():
	var rng = randi() % 3
	if rng == 0:
		spawn_colonist()
		remove_food()

func allow_action():
	if population <= 0:
		return false
	elif spotlight_build < 5:
		return true
	else:
		return false

func turret_look_at(position):
	vision_cone.rotation = position.direction_to(vision_cone.position).angle() + PI

func turn_off():
	if spotlight_build >= 5:
		on = false
		collision_layer = 0
		collision_mask = 0
	else:
		on = false
	
	#for i in range(population):
	#	pop_lights[i].visible = false
		
	food_timer.stop()
	food_bar.visible = false
	
	turret.frame = 1
	vision_light.visible = false

func turn_on():
	.turn_on()
	
	#for i in range(population):
	#	pop_lights[i].visible = true
	
	food_timer.paused = false
	food_timer.start()
	food_bar.visible = true
	
	turret.frame = 0
	
	var rng = randi() % 4 + 1
	for i in range(rng):
		var dir = randi() % 4
		var pos
		if dir == 0:
			pos = position + Vector2(rand_range(-80, -40), rand_range(-80, -40))
		elif dir == 1:
			pos = position + Vector2(rand_range(-80, -40), rand_range(40, 80))
		elif dir == 2:
			pos = position + Vector2(rand_range(40, 80), rand_range(40, 80))
		else:
			pos = position + Vector2(rand_range(40, 80), rand_range(-80, -40))
		spawn_soldier(pos)
	
	if spotlight_build > 2:
		vision_light.visible = true

func action_done():
	.action_done()
	
	if population > 0:
		var brain_given = false
		
		for drone in current_drones:
			if drone.give_brain():
				brain_given = true
				SoundManager.play_harvest(1)
				break
		
		if not brain_given:
			return
		
		if on:
			get_parent().add_to_panic(1)
		remove_food()

func turn_on_spotlight(build):
	build_timer.start()
	spotlight_build = build

func allow_drone():
	return true

func spawn_soldier(target):
	if population <= 0:
		return
	
	var solder = soldier_scene.instance()
	solder.position = position + Vector2(0.1, 0)
	get_parent().add_child(solder)
	solder.set_home_dome(self)
	solder.move_to_search(target)
	
	remove_food()

func spawn_colonist():
	var colonist
	
	var rng = 0
	if WorldBounds.soldiers_spawn:
		rng = randi() % 140
	else:
		rng = randi() % 100
	if rng < 10:
		colonist = scientist_scene.instance()
	elif rng < 55:
		if WorldBounds.soldiers_replace_colonists:
			colonist = soldier_scene.instance()
		else:
			colonist = colonist_scene.instance()
	elif rng < 100:
		if WorldBounds.soldiers_replace_colonists:
			colonist = soldier_scene.instance()
		else:
			colonist = blue_colonist_scene.instance()
	else:
		colonist = soldier_scene.instance()
	get_parent().add_child(colonist)	
		
	var domes = get_tree().get_nodes_in_group("dome")
	domes.erase(self)
	
	for dome in domes_not_connected:
		domes.erase(dome)
	
	if domes.size() == 0:
		return
		
	rng = randi() % domes.size()
	var target_dome = domes[rng]
	
	colonist.position = position + Vector2(0.1, 0)
	colonist.set_home_dome(self)
	
	if colonist.is_in_group("soldier"):
		if WorldBounds.soldiers_attack_mother:
			colonist.attack_mother_brain()
		elif WorldBounds.soldiers_patrol:
			colonist.patrol()
		else:
			colonist.move_to_dome(target_dome)
	else:
		colonist.move_to_dome(target_dome)

func add_food():
	population += 1
	if population > max_population:
		population = max_population
	elif spotlight_build < 5:
		pop_lights[population - 1].visible = true
	
	show_action = true
	pop_change.play("plus")
	pop_change.visible = true
	
func remove_food():
	pop_lights[population - 1].visible = false
	population -= 1
	if population <= 0:
		show_action = false
	
	pop_change.play("minus")
	pop_change.visible = true

func _on_FoodTimer_timeout():
	add_food()
		
	var rng = randi() % (8 - population)
	if rng == 0:
		spawn_colonist()
		
		if population < max_population:
			remove_food()

func _on_VisionCone_area_entered(area):
	if area.is_in_group("drone"):
		drones.append(area)
	elif area.is_in_group("colonist"):
		if !area.alive:
			if !area.reported:
				area.reported = true
				spawn_soldier(area.position)

func _on_VisionCone_area_exited(area):
	if area.is_in_group("drone"):
		drones.erase(area)

func _on_BuildTimer_timeout():
	if spotlight_build == 0:
		turret_base.visible = true
		build_timer.start()
		spotlight_build += 1
	elif spotlight_build == 1:
		turret.visible = true
		build_timer.start()
		spotlight_build += 1
		
		turret_base.visible = true
	elif spotlight_build == 2:
		vision_light.visible = true
		spotlight_on = true
		
		turret_base.visible = true
		turret.visible = true
	elif spotlight_build == 3:
		turret.play("turret")
		turret.playing = false
		turret.frame = 0
		turret_on = true
		
		vision_light.visible = true
		turret_base.visible = true
		turret.visible = true
	elif spotlight_build == 4:
		dome_wall.play("partial")
		dome_wall.visible = true
		
		turret.play("turret")
		turret.playing = false
		turret.frame = 0
		turret_on = true
		vision_light.visible = true
		turret_base.visible = true
		turret.visible = true
	elif spotlight_build == 5:
		dome_wall.play("full")
		dome_wall.visible = true
		
		turret.play("turret")
		turret.playing = false
		turret.frame = 0
		turret_on = true
		vision_light.visible = true
		turret_base.visible = true
		turret.visible = true
		
		for pop in pop_lights:
			pop.visible = false
	else:
		turret.play("turret")
		turret.playing = false
		turret.frame = 0
		turret_on = true
		vision_light.visible = true
		turret_base.visible = true
		turret.visible = true
		dome_wall.play("full")
		dome_wall.visible = true
		dome_wall.frame = 1

func _on_ActionTimer_timeout():
	doing_action = false
	
	if turret_on:
		if drones.size() > 0 && population > 0:
			if is_instance_valid(target_drone):
				if on:
					target_drone.hurt()
					muzzle_flash.visible = true
					muzzle_flash.play("default")
	elif spotlight_on:
		if drones.size() > 0 && population > 0:
			if is_instance_valid(target_drone):
				spawn_soldier(target_drone.position)

func _on_DomeWall_animation_finished():
	$DomeWall.playing = false
	$DomeWall.frame = 1

func _on_MuzzleFlash_animation_finished():
	muzzle_flash.visible = false

func _on_PopChange_animation_finished():
	pop_change.visible = false

func _on_StartFoodTimer_timeout():
	food_timer.start()
	food_bar.visible = true

func _on_Enemy_mouse_entered():
	if spotlight_build < 5:
		._on_Enemy_mouse_entered()
