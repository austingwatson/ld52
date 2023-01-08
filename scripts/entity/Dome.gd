extends "res://scripts/entity/Enemy.gd"

const colonist_scene = preload("res://scenes/entity/Colonist.tscn")
const blue_colonist_scene = preload("res://scenes/entity/BlueColonist.tscn")
const scientist_scene = preload("res://scenes/entity/Scientist.tscn")
const soldier_scene = preload("res://scenes/entity/Soldier.tscn")

onready var animated_sprite = $AnimatedSprite
onready var label = $Label
onready var food_timer = $FoodTimer
onready var food_bar = $FoodBar

export var population = 1
export var max_population = 6

var off = false
var powered = true
var progress = 0

func _process(delta):
	progress = (food_timer.wait_time - food_timer.time_left) / food_timer.wait_time * food_bar.max_value
	food_bar.value = progress
	
	if not off:
		if progress < 25:
			animated_sprite.frame = 0
		elif progress >= 25 && progress < 50:
			animated_sprite.frame = 1
		elif progress >= 50 && progress < 75:
			animated_sprite.frame = 2
		elif progress >= 75:
			animated_sprite.frame = 3

func action_done():
	.action_done()
	
	if population > 0:
		var brain_given = false
		
		for drone in current_drones:
			if drone.give_brain():
				brain_given = true
				break
		
		if not brain_given:
			return
		
		get_parent().add_to_panic(1)
		population -= 1
		label.text = str(population)

func allow_drone():
	return not off

func spawn_colonist():
	var colonist
	
	#var rng = randi() % 100
	var rng = randi() % 2
	if rng == 0:
		colonist = soldier_scene.instance()
	elif rng < 10:
		colonist = scientist_scene.instance()
	elif rng < 55:
		colonist = colonist_scene.instance()
	else:
		colonist = blue_colonist_scene.instance()
		
	var domes = get_tree().get_nodes_in_group("dome")
	domes.erase(self)
	
	if domes.size() == 0:
		return
	
	rng = randi() % domes.size()
	var target_dome = domes[rng]
	
	colonist.position = position
	colonist.move_to_dome(target_dome)
	get_parent().add_child(colonist)

func _on_FoodTimer_timeout():
	population += 1
	if population >= max_population:
		population = max_population
		spawn_colonist()
		
	var rng = randi() % (100 - population) + population
	if rng == 99:
		spawn_colonist()
		
	label.text = str(population)
