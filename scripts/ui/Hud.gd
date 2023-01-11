extends CanvasLayer

onready var texture_progress = $TextureProgress
onready var flash_panic = $FlashPanic
onready var flash_timer = $FlashTimer
onready var mana = $Mana
onready var alert_flash = $AlertFlash
onready var mana_flash = $Mana/ManaFlash

onready var noise = $Noise
onready var slow = $Slow
onready var teleport = $Teleport
onready var dominate = $Dominate

var panic = 0
var flashes = 2

func _process(delta):
	if WorldBounds.noise_av:
		noise.visible = true
	if WorldBounds.slow_av:
		slow.visible = true
		mana.visible = true
	if WorldBounds.teleport_av:
		teleport.visible = true
	if WorldBounds.dominate_av:
		dominate.visible = true
		

func add_to_mana(amount):
	mana.value += amount
	print(amount)
	if amount < 0:
		mana_flash.play("default")
		mana_flash.visible = true

func set_panic(amount):
	panic = amount
	texture_progress.value = panic
	flash_timer.start()
	flash_panic.visible = true
	alert_flash.play("default")
	alert_flash.visible = true
	flashes = 2

func add_to_panic(amount):
	panic += amount
	texture_progress.value += amount
	flash_timer.start()
	flash_panic.visible = true
	flashes = 2
	alert_flash.play("default")
	alert_flash.visible = true

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
		alert_flash.visible = false

func _on_ManaFlash_animation_finished():
	mana_flash.visible = false
