extends CanvasLayer

onready var texture_progress = $TextureProgress
onready var flash_panic = $FlashPanic
onready var flash_timer = $FlashTimer

var panic = 0
var flashes = 2

func add_to_panic(amount):
	panic += amount
	texture_progress.value += amount
	flash_timer.start()
	flash_panic.visible = true
	flashes = 2

func _on_FlashTimer_timeout():
	if flashes > 0:
		if flashes % 2 == 0:
			flash_panic.visible = false
		else:
			flash_panic.visible = true
		flashes -= 1
		flash_timer.start()
	else:
		flash_panic.visible = false
