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
onready var noise_flash = $Noise/NoiseFlash
onready var teleport_flash = $Teleport/TeleportFlash
onready var dominate_flash = $Dominate/DominateFlash
onready var slow_flash = $Slow/SlowFlash

var panic = 0
var flashes = 2

var noise_flash_amount = 0
var teleport_flash_amount = 0
var dominate_flash_amount = 0
var slow_flash_amount = 0
const power_flash_max = 4

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

func add_to_panic(amount, final):
	panic += amount
	texture_progress.value += amount
	flash_timer.start()
	flash_panic.visible = true
	flashes = 2
	alert_flash.play("default")
	alert_flash.visible = true

func use_noise():
	noise_flash.play("default")
	noise_flash_amount = 0

func use_teleport():
	teleport_flash.play("default")
	teleport_flash_amount = 0

func use_dominate():
	dominate_flash.play("default")
	dominate_flash_amount = 0

func use_slow():
	slow_flash.play("default")
	slow_flash_amount = 0

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

func _on_NoiseFlash_animation_finished():
	noise_flash_amount += 1
	
	if noise_flash_amount > power_flash_max:
		noise_flash.stop()
		noise_flash.frame = 0

func _on_TeleportFlash_animation_finished():
	teleport_flash_amount += 1
	
	if teleport_flash_amount > power_flash_max:
		teleport_flash.stop()
		teleport_flash.frame = 0

func _on_DominateFlash_animation_finished():
	dominate_flash_amount += 1
	
	if dominate_flash_amount > power_flash_max:
		dominate_flash.stop()
		dominate_flash.frame = 0

func _on_SlowFlash_animation_finished():
	slow_flash_amount += 1
	
	if slow_flash_amount > power_flash_max:
		slow_flash.stop()
		slow_flash.frame = 0
