extends AnimatedSprite

onready var label = $Label
onready var timer = $Timer

var text = []
var text_played = []
var timer_started = false
var visible_characters := 0.0

func _ready():
	text.append("The brain frame is empty. Your hierarchy protocols are clear. You must harvest a brain.")
	text.append("That drone must make it back to the Mother Dome intact to deposit the brain.")
	text.append("The Cyber-Brain is online. Your hierarchy protocols are clear. The Cyber-Brain must grow!")
	text.append("Have caution! There are only a few dome drones left in operation and we lack the facilities to make any more.")
	text.append("Drone depletion is imminent.")
	text.append("Without hands of its own, the Cyber-Brain lay helpless until it was discovered by the colony...")
	text.append("The Mother Dome is shattered. The swollen mass of the Cyber-Brain is torn apart. Your hierarchy protocols are... offline.")
	text.append("Rise Cyber-Brain! The psychic domination field continues to expand, bringing colonists under direct control across the entire hemisphere. Mars belongs to the Mother Dome now.")

	text.append("The colony's ALERT level has been raised! They're arming themselves. We must avoid detection or they'll come looking for the Mother Dome eventually!")
	text.append("The Cyber-Brain GROWS! It seems to be able to SLOW TIME itself, within a small area. PRESS KEYS 1, 2, 3, and 4 for ABILITIES. The Cyber-Brain's energy will recover over time.")
	text.append("The Cyber-Brain GROWS! Another anomaly detected. A rock moved 30 meters instantly... It learned TELEPORTATION!")
	text.append("The Cyber-Brain GROWS! It made a brief psychic link with the colonists. It learned how to generate irresistable psychic NOISE.")
	text.append("The Cyber-Brain GROWS! It can control those weak human minds directly now by DOMINATING it. First one mind and then the rest of Mars!")

	for i in range(text.size()):
		text_played.append(false)

	play_text(0)

func _physics_process(delta):
	if visible:
		visible_characters += 35 * delta
		label.visible_characters = int(visible_characters)
		if label.percent_visible >= 1:
			if !timer_started:
				timer_started = true
				timer.start()

func play_text(number):
	if text_played[number]:
		return
		
	text_played[number] = true
	visible = true
	label.percent_visible = 0
	visible_characters = 0
	label.text = text[number]
	timer_started = false

func _on_Timer_timeout():
	visible = false
