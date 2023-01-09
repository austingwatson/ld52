extends Node

var current = 0

func _on_Play_pressed():
	if current == 0:
		current += 1
		$Label.visible = false
		$Label2.visible = true
		$Play/Label.text = "Title Screen"
	else:
		get_tree().change_scene("res://scenes/TitleScreen.tscn")
