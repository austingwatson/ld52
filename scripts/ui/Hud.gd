extends CanvasLayer

onready var texture_progress = $TextureProgress

var panic = 0

func add_to_panic(amount):
	panic += amount
	texture_progress.value += amount
	print(panic)
