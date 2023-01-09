extends "res://scripts/entity/Enemy.gd"

onready var animated_sprite = $AnimatedSprite
onready var brain_progress = $BrainProgress
onready var hurt_node = $Hurt
onready var animation_player = $AnimationPlayer

var brains = 0
export var brains_needed = 40
var health = 100
var total_health = health

func _ready():
	brain_progress.max_value = brains_needed
	brain_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE

func action_done():
	.action_done()
	
	for drone in current_drones:
		if drone.brain.visible:
			WorldBounds.play_text(2)
			animation_player.play("plus_brain")
			brains += 1
			drone.brain.visible = false
			calculate_stage()
			SoundManager.play_hurray()

func start_boosters():
	$Boosters.visible = true

func hurt():
	if WorldBounds.play_win_cutscene || WorldBounds.play_lost_cutscene:
		return
	
	SoundManager.play_gun_shot()
	health -= 1
	
	if float(health) / float(total_health) <= 0.1:
		hurt_node.frame = 2
	elif float(health) / float(total_health) <= 0.4:
		hurt_node.frame = 1
	elif float(health) / float(total_health) <= 0.7:
		hurt_node.frame = 0
		hurt_node.visible = true
	if health <= 0:
		WorldBounds.lose()

func calculate_stage():
	if brains >= brains_needed:
		WorldBounds.win()
	
	brain_progress.value = brains
	
	var percent = float(brains) / float(brains_needed) * 100
	
	if percent >= 85:
		animated_sprite.play("stage6")
	elif percent >= 68:
		animated_sprite.play("stage5")
		WorldBounds.dominate_av = true
	elif percent >= 51:
		animated_sprite.play("stage4")
		WorldBounds.teleport_av = true
	elif percent >= 34:
		animated_sprite.play("stage3")
		WorldBounds.slow_av = true
	elif percent >= 17:
		animated_sprite.play("stage2")
		WorldBounds.noise_av = true
	else:
		animated_sprite.play("stage1")
