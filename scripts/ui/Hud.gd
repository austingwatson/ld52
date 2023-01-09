extends CanvasLayer

onready var texture_progress = $TextureProgress
onready var flash_panic = $FlashPanic
onready var flash_timer = $FlashTimer

var panic = 0

func add_to_panic(amount):
	panic += amount
	texture_progress.value += amount
	flash_timer.start()
	flash_panic.visible = true
	print(panic)

func _on_FlashTimer_timeout():
	flash_panic.visible = false
