extends Area2D

var areas = []

func _on_SlowArea_area_entered(area):
	if area.is_in_group("colonist") || area.is_in_group("dome"):
		areas.append(area)
		area.slowed = true

func _on_SlowArea_area_exited(area):
	if areas.has(area):
		area.slowed = false
	
	areas.erase(area)

func _on_Timer_timeout():
	for area in areas:
		area.slowed = false
	
	queue_free()
