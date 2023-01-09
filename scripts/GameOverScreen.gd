extends Node

var accepting_input = false

func _ready():
	if WorldBounds.status == 1:
		$Label.text = "You Lose!"
	else:
		$Label.text = "You Win!"
	
func _input(event):	
	if accepting_input:
		WorldBounds.reset()
		get_tree().change_scene("res://scenes/TitleScreen.tscn")

func _on_EndTimer_timeout():
	WorldBounds.reset()
	get_tree().change_scene("res://scenes/TitleScreen.tscn")

func _on_StartInput_timeout():
	accepting_input = true
