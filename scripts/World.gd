extends Node2D

onready var camera = $Camera2D
onready var cloud_layer = $ParallaxBackground/ParallaxLayer
onready var hud = $Hud
onready var click_spot = $ClickSpot
onready var mother_brain = $MotherBrain
onready var double_click_timer = $DoubleClickTimer
onready var restart_timer = $RestartTimer

const dome_scene = preload("res://scenes/entity/Dome.tscn")
const drone_scene = preload("res://scenes/entity/Drone.tscn")
const path_texture = preload("res://assets/structures/path.png")
const generator_scene = preload("res://scenes/entity/Generator.tscn")
const path_junction = preload("res://assets/structures/path_junction2.png")

# variables to show the selection rectangle
# and query the physics engine for selected units
var dragging := false
var selected := []
var drag_start := Vector2.ZERO
var select_rect := RectangleShape2D.new()
var select_query := Physics2DShapeQueryParameters.new()

export var camera_speed_keys := 200
var camera_movement := [false, false, false, false]

var zoom_min = 0.25
var zoom_max = 2

# variables to drag the camera based on if the
# mouse is near the screen edges
var mouse_in_screen := false
var mouse_pos := Vector2.ZERO
export(float, 1.0) var screen_margin = 0.1
export var camera_speed_edge = 150
var screen_margin_up := 0.0
var screen_margin_left := 0.0
var screen_margin_down := 0.0
var screen_margin_right := 0.0

var queue_modifier = false

var mother_ship_accel = 5.0
var start_lose_timer = false

var double_click = 0

func _ready():
	select_query.collide_with_bodies = false
	select_query.collide_with_areas = true
	
	var viewport = get_viewport().get_visible_rect().size
	screen_margin_up = viewport.y * screen_margin
	screen_margin_left = viewport.x * screen_margin
	screen_margin_down = viewport.y * (1.0 - screen_margin)
	screen_margin_right = viewport.x * (1.0 - screen_margin)
	
	generate_map(5)

func _unhandled_input(event):
	if WorldBounds.play_win_cutscene || WorldBounds.play_lost_cutscene:
		return
	
	# if mouse 1 is down start showing the rectagnle
	if event.is_action_pressed("select_units"):
		dragging = true
		drag_start = get_global_mouse_position()
		double_click += 1
		double_click_timer.start()
		
	# when mouse 1 is lifted the rectangle stops drawing
	# and the selected units are found
	elif event.is_action_released("select_units"):
		dragging = false
		update()
		
		if double_click <= 1:
			select_units(get_global_mouse_position())
		else:
			select_from_double_click()
		
	elif event.is_action_pressed("basic_action"):
		var mouse_pos = get_global_mouse_position()
		
		var in_bounds = true
		if mouse_pos.x < WorldBounds.world_bounds_left.x || mouse_pos.x > WorldBounds.world_bounds_right.x:
			in_bounds = false
		elif mouse_pos.y < WorldBounds.world_bounds_left.y || mouse_pos.y > WorldBounds.world_bounds_right.y:
			in_bounds = false
		
		if in_bounds:
			action(mouse_pos)
			click_spot.play("default")
			click_spot.position = mouse_pos
			click_spot.frame = 0
			click_spot.visible = true
	
	elif event.is_action_pressed("move_up"):
		camera_movement[0] = true
	elif event.is_action_released("move_up"):
		camera_movement[0] = false
		
	elif event.is_action_pressed("move_left"):
		camera_movement[1] = true
	elif event.is_action_released("move_left"):
		camera_movement[1] = false
		
	elif event.is_action_pressed("move_down"):
		camera_movement[2] = true
	elif event.is_action_released("move_down"):
		camera_movement[2] = false
		
	elif event.is_action_pressed("move_right"):
		camera_movement[3] = true
	elif event.is_action_released("move_right"):
		camera_movement[3] = false
		
	elif event.is_action_pressed("zoom_in"):
		camera.zoom /= 2
		if camera.zoom.x < zoom_min:
			camera.zoom = Vector2(zoom_min, zoom_min)
	elif event.is_action_pressed("zoom_out"):
		camera.zoom *= 2
		if camera.zoom.x > zoom_max:
			camera.zoom = Vector2(zoom_max, zoom_max)
	
	elif event.is_action_pressed("drag_screen"):
		camera.position = get_global_mouse_position()
	
	elif event.is_action_pressed("shift"):
		queue_modifier = true
		
		for drone in get_tree().get_nodes_in_group("drone"):
			drone.holding_shift(true)
		
	elif event.is_action_released("shift"):
		queue_modifier = false
		
		for drone in get_tree().get_nodes_in_group("drone"):
			drone.holding_shift(false)
	
	elif event.is_action_pressed("restart"):
		restart_timer.start()
	elif event.is_action_released("restart"):
		restart_timer.stop()
	
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		
func _physics_process(delta):
	for drone in selected:
		if drone.holding_brain():
			WorldBounds.drones_selected_has_brain = true
	
	if WorldBounds.play_win_cutscene:
		mother_brain.position.y -= mother_ship_accel * delta
		mother_ship_accel += 0.5
		
		if mother_brain.position.y < -650:
			get_tree().change_scene("res://scenes/GameOverScreen.tscn")
	elif WorldBounds.play_lost_cutscene:
		var dir = camera.position.direction_to(mother_brain.position)
		if camera.position.distance_to(mother_brain.position) <= 1.0:
			if !start_lose_timer:
				start_lose_timer = true
				$LoseTimer.start()
		else:
			camera.position += dir * delta * 50
		
func _process(delta):
	var drones = get_tree().get_nodes_in_group("drone")
	if drones.size() < 1:
		WorldBounds.play_text(5)
		var panic = WorldBounds.max_panic()
		hud.set_panic(panic)
	elif drones.size() < 4:
		WorldBounds.play_text(4)
	
	if WorldBounds.play_win_cutscene || WorldBounds.play_lost_cutscene:
		return
	
	if dragging:
		update()
		
	if camera_movement[0]:
		camera.position.y -= camera_speed_keys * delta
	if camera_movement[1]:
		camera.position.x -= camera_speed_keys * delta
	if camera_movement[2]:
		camera.position.y += camera_speed_keys * delta
	if camera_movement[3]:
		camera.position.x += camera_speed_keys * delta
		
	# move the camera if the mouse cursor is near the edge
	if mouse_in_screen:
		if mouse_pos.y <= screen_margin_up:
			camera.position.y -= camera_speed_edge * delta
		if mouse_pos.x <= screen_margin_left:
			camera.position.x -= camera_speed_edge * delta
		if mouse_pos.y >= screen_margin_down:
			camera.position.y += camera_speed_edge * delta
		if mouse_pos.x >= screen_margin_right:
			camera.position.x += camera_speed_edge * delta
		
func _draw():
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start), Color(0.5, 0.5, 0.5), false)

func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_MOUSE_EXIT:
			mouse_in_screen = false
		MainLoop.NOTIFICATION_WM_MOUSE_ENTER:
			mouse_in_screen = true

func generate_map(difficulty):
	randomize()
	
	for i in range(difficulty * 3 + 1):
		var drone = drone_scene.instance()
		drone.position = Vector2(i * 16 - 100, -315)
		add_child(drone)
	
	var domes = []
	var x = 0
	var sy = 15
	var y = sy
	var dome = dome_scene.instance()
	dome.position = Vector2(x, y * 8)
	domes.append(dome)
	
	var min_distance = 250
	
	for i in range(1, difficulty):
		var valid = false
		while !valid:
			valid = true
			x = int(rand_range(-40, 40))
			y = int(rand_range(-35, 25))
			#x = randi() % 81 - 40
			#y = randi() % 61 - 40
			y += sy
			
			for d in domes:
				if d.position.distance_to(Vector2(x * 8, y * 8)) <= min_distance:
					valid = false
		
		dome = dome_scene.instance()
		dome.position = Vector2(x * 8, y * 8)
		domes.append(dome)

	var lines = []
	for i in range(domes.size()):
		for j in range(i + 1, domes.size()):
			var no_dome = randf()
			if no_dome <= 0.33:
				domes[i].add_dome_not_connected(domes[j])
				domes[j].add_dome_not_connected(domes[i])
				continue
			
			var line = Line2D.new()
			line.width = 4
			line.default_color = Color.white
			line.texture = path_texture
			line.texture_mode = Line2D.LINE_TEXTURE_TILE
			line.z_index = -1
		
			line.add_point(domes[i].position)
			line.add_point(domes[j].position)
		
			lines.append(line)
			add_child(line)
	
	for i in range(domes.size()):
		if domes[i].not_connected_to_dome(difficulty):
			var line = Line2D.new()
			line.width = 4
			line.default_color = Color.white
			line.texture = path_texture
			line.texture_mode = Line2D.LINE_TEXTURE_TILE
			line.z_index = -1
		
			if i == 0:
				line.add_point(domes[i].position)
				line.add_point(domes[1].position)
				domes[i].remove_dome_not_connected(domes[1])
				domes[1].remove_dome_not_connected(domes[i])
			else:
				line.add_point(domes[i].position)
				line.add_point(domes[0].position)
				domes[i].remove_dome_not_connected(domes[0])
				domes[0].remove_dome_not_connected(domes[i])
		
			lines.append(line)
			add_child(line)
	
	var junctions = {}
	for i in range(lines.size()):
		for j in range(i + 1, lines.size()):
			var intersection = line_intersects(lines[i].points[0], lines[i].points[1], lines[j].points[0], lines[j].points[1])
			if intersection != null:
				junctions[intersection] = lines[i].points[0]
				
	for junction in junctions.keys():
		var near_dome = false
		for d in domes:
			if d.position.distance_to(junction) <= 1:
				near_dome = true
				break
		if !near_dome:
			var angle_offset = 0
			
			for i in range(4):
				var sprite = Sprite.new()
				sprite.texture = path_junction
				sprite.position = junction
			
				var angle = sprite.position.direction_to(junctions[junction]).angle() + angle_offset
			
				sprite.rotation = angle
				add_child(sprite)
				
				angle_offset += PI / 2
	
	for d in domes:
		add_child(d)
	for d in domes:
		d.start()
	
	var temp_domes = []
	temp_domes.append_array(domes)
	
	for i in range(difficulty):
		var generator = generator_scene.instance()
		generator.move_to_parent(temp_domes.pop_front())
		add_child(generator)
		
	var mother_brain = $MotherBrain
	var rx = randi() % 901 - 450
	mother_brain.position = Vector2(mother_brain.position.x + rx, mother_brain.position.y)
	camera.position = mother_brain.position
	
	for drone in get_tree().get_nodes_in_group("drone"):
		drone.position.x += rx + 70
		
	WorldBounds.in_world = true

func line_intersects(p1: Vector2, p2: Vector2, q1: Vector2, q2: Vector2):
	var r: Vector2 = p2 - p1
	var s: Vector2 = q2 - q1
	var rxs = r.cross(s)
	var qpxr = (q1 - p1).cross(r)
	
	if rxs == 0 && qpxr == 0:
		return null
	
	if rxs == 0 && qpxr != 0:
		return null
		
	var t = (q1 - p1).cross(s) / rxs
	var u = (q1 - p1).cross(r) / rxs
	
	if rxs != 0 && (0 <= t && t <= 1) && (0 <= u && u <= 1):
		return p1 + t * r
	
	return null

func start_win_cutscene():
	mother_brain.start_boosters()
	
	camera.position = mother_brain.position
	camera.zoom = Vector2(1, 1)
	
	var drones = get_tree().get_nodes_in_group("drone")
	for drone in drones:
		drone.stop()

func start_lost_cutscene():
	camera.zoom = Vector2(1, 1)
	
	var drones = get_tree().get_nodes_in_group("drone")
	for drone in drones:
		drone.stop()

# query the physics engine based on the rectangle created
func select_units(drag_end):
	select_rect.extents = (drag_end - drag_start) / 2	
	
	var space = get_world_2d().direct_space_state
	select_query.set_shape(select_rect)
	select_query.transform = Transform2D(0, (drag_end + drag_start) / 2)
	
	
	for unit in selected:
		if is_instance_valid(unit):
			unit.deselect()
	selected.clear()
	
	var selected_all = space.intersect_shape(select_query)
	for unit in selected_all:
		if unit.collider.is_in_group("drone"):
			unit.collider.select()
			selected.append(unit.collider)
			
	if selected.size() > 0:
		WorldBounds.drones_selected = true
		
		var has_brain = false
		for drone in selected:
			if drone.holding_brain():
				has_brain = true
				break
		WorldBounds.drones_selected_has_brain = has_brain
	else:
		WorldBounds.drones_selected = false
		WorldBounds.drones_selected_has_brain = false

func select_from_double_click():
	var space = get_world_2d().direct_space_state
	var collision_objects = space.intersect_point(get_global_mouse_position(), 1, [], 0x7FFFFFFF, true, true)
		
	var selected_drone = 0
	
	for collision in collision_objects:
		if collision.collider.is_in_group("drone"):
			selected_drone = 1
			if collision.collider.holding_brain():
				selected_drone = 2
	if selected_drone != 0:
		for drone in selected:
			if is_instance_valid(drone):
				drone.deselect()
		selected.clear()
		
		var drones = get_tree().get_nodes_in_group("drone")
		for drone in drones:
			if !drone.is_idle():
				continue
			
			if selected_drone == 1 and !drone.holding_brain():
				drone.select()
				selected.append(drone)
			elif selected_drone == 2 and drone.holding_brain():
				drone.select()
				selected.append(drone)

func action(position):	
	var space = get_world_2d().direct_space_state
	var collision_objects = space.intersect_point(position, 15, [], 0x7FFFFFFF, true, true)
	var enemy_unit = null
	
	for collision in collision_objects:
		if collision.collider.is_in_group("enemy"):
			enemy_unit = collision.collider
			break
	
	if queue_modifier:
		if enemy_unit:
			work_units_with_queue(enemy_unit)
		else:
			move_units_with_queue(position)
	elif enemy_unit:
		work_units(enemy_unit)
	else:
		move_units(position)

func remove_from_selected(unit):
	selected.erase(unit)

func move_units(position):
	for unit in selected:
		unit.move_to(position)
		unit.remove_commands()

func work_units(enemy_unit):
	if !enemy_unit.allow_action():
		return
	
	var max_allowed = min(selected.size(), enemy_unit.action_spots_left())
	
	for i in range(max_allowed):
		if enemy_unit.is_in_group("mother_brain"):
			if !selected[i].holding_brain():
				continue
		elif selected[i].holding_brain():
			continue
		
		if enemy_unit.is_in_group("dome") && WorldBounds.domes_sealed:
			continue	
		
		selected[i].action_move_to(enemy_unit)
		selected[i].remove_commands()

func move_units_with_queue(position):
	for unit in selected:
		unit.add_action("move_to", position, position)
	
func work_units_with_queue(enemy_unit):
	if !enemy_unit.allow_action():
		return
	
	var max_allowed = min(selected.size(), enemy_unit.action_spots_left())
	
	for i in range(max_allowed):
		if enemy_unit.is_in_group("mother_brain"):
			if !selected[i].holding_brain():
				continue
		elif selected[i].holding_brain():
			continue
		
		if enemy_unit.is_in_group("dome") && WorldBounds.domes_sealed:
			continue
		
		selected[i].add_action("action_move_to", enemy_unit, enemy_unit.position)

func get_selected():
	return selected

func add_to_panic(amount):
	WorldBounds.panic_level += amount
	WorldBounds.add_to_panic()
	hud.add_to_panic(amount)

func add_to_mana(amount):
	hud.add_to_mana(amount)

func _on_ClickSpot_animation_finished():
	click_spot.playing = false
	click_spot.visible = false

func _on_LoseTimer_timeout():
	get_tree().change_scene("res://scenes/GameOverScreen.tscn")

func _on_DoubleClickTimer_timeout():
	double_click = 0

func _on_RestartTimer_timeout():
	get_tree().change_scene("res://scenes/TitleScreen.tscn")
