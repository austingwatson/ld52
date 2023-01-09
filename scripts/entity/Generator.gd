extends "res://scripts/entity/Enemy.gd"

onready var animated_sprite = $AnimatedSprite
onready var power_timer = $PowerTimer

var parent = null

func _ready():
	$Line2D.set_as_toplevel(true)
	pass

func action_done():
	.action_done()

	animated_sprite.play("off")
	parent.turn_off()
	turn_off()
	power_timer.start()

func move_to_parent(parent):
	self.parent = parent
	position = parent.position
	
	var oy = randi() % 60 - 30
	var rng = randi() % 2
	if rng == 0:
		position = position + Vector2(44, oy)
	else:
		position = position + Vector2(-44, oy)
	
	$Line2D.add_point(position)
	$Line2D.add_point(parent.position)

func _on_PowerTimer_timeout():
	animated_sprite.play("on")
	parent.turn_on()
	turn_on()
