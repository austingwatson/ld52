extends "res://scripts/entity/Enemy.gd"

onready var animated_sprite = $AnimatedSprite
onready var brain_progress = $BrainProgress

var brains = 0
export var brains_needed = 5

func _ready():
	brain_progress.max_value = brains_needed
	brain_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE

func action_done():
	.action_done()
	
	for drone in current_drones:
		if drone.brain.visible:
			brains += 1
			drone.brain.visible = false
			calculate_stage()

func calculate_stage():
	brain_progress.value = brains
	
	var percent = float(brains) / float(brains_needed) * 100
	
	if percent >= 85:
		animated_sprite.play("stage6")
	elif percent >= 68:
		animated_sprite.play("stage5")
	elif percent >= 51:
		animated_sprite.play("stage4")
	elif percent >= 34:
		animated_sprite.play("stage3")
	elif percent >= 17:
		animated_sprite.play("stage2")
	else:
		animated_sprite.play("stage1")
