extends Node2D

onready var camera = $Camera2D

const dome_scene = preload("res://scenes/entity/Dome.tscn")
const drone_scene = preload("res://scenes/entity/Drone.tscn")

# variables to show the selection rectangle
# and query the physics engine for selected units
var dragging := false
var selected := []
var drag_start := Vector2.ZERO
var select_rect := RectangleShape2D.new()
var select_query := Physics2DShapeQueryParameters.new()

export var camera_speed_keys := 100
var camera_movement := [false, false, false, false]

var zoom_min = 0.25
var zoom_max = 4

# variables to drag the camera based on if the
# mouse is near the screen edges
var mouse_in_screen := false
var mouse_pos := Vector2.ZERO
export(float, 1.0) var screen_margin = 0.1
export var camera_speed_edge = 100
var screen_margin_up := 0.0
var screen_margin_left := 0.0
var screen_margin_down := 0.0
var screen_margin_right := 0.0

func _ready():
	var viewport = get_viewport().get_visible_rect().size
	screen_margin_up = viewport.y * screen_margin
	screen_margin_left = viewport.x * screen_margin
	screen_margin_down = viewport.y * (1.0 - screen_margin)
	screen_margin_right = viewport.x * (1.0 - screen_margin)
	
	generate_map(3)

func _unhandled_input(event):
	# if mouse 1 is down start showing the rectagnle
	if event.is_action_pressed("select_units"):
		dragging = true
		drag_start = get_global_mouse_position()
		
	# when mouse 1 is lifted the rectangle stops drawing
	# and the selected units are found
	elif event.is_action_released("select_units"):
		dragging = false
		update()
		select_units(get_global_mouse_position())
		
	elif event.is_action_pressed("basic_action"):
		action(get_global_mouse_position())
	
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
	
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		
func _process(delta):
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
	for i in range(difficulty):
		var drone = drone_scene.instance()
		drone.position = Vector2(i * 50, 0)
		add_child(drone)

# query the physics engine based on the rectangle created
func select_units(drag_end):
	select_rect.extents = (drag_end - drag_start) / 2		
	
	var space = get_world_2d().direct_space_state
	select_query.set_shape(select_rect)
	select_query.transform = Transform2D(0, (drag_end + drag_start) / 2)
	
	for unit in selected:
		unit.deselect()
	selected.clear()
	
	var selected_all = space.intersect_shape(select_query)
	for unit in selected_all:
		if unit.collider.is_in_group("drone"):
			unit.collider.select()
			selected.append(unit.collider)

func action(position):
	var space = get_world_2d().direct_space_state
	var collision_objects = space.intersect_point(position, 1)
	var enemy_unit = null
	
	if collision_objects:
		enemy_unit = collision_objects[0].collider
		
		if enemy_unit.is_in_group("drone"):
			enemy_unit = null
	
	if enemy_unit:
		work_units(enemy_unit)
	else:
		move_units(position)

func move_units(position):
	for unit in selected:
		unit.move_to(position)

func work_units(enemy_unit):
	if enemy_unit.is_in_group("dome") and not enemy_unit.allow_drone():
		return
	
	var amount = 0
	
	for unit in selected:
		unit.action_move_to(enemy_unit)
		
		amount += 1
		if amount >= enemy_unit.max_action_spots:
			break
