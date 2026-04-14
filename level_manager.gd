extends Node2D

@export var room_scenes: Array[PackedScene] # Room variants (inherited) go here
@export var start_room_scene: PackedScene

@onready var room_container = $RoomContainer
@onready var camera = $Camera2D

var room_size = Vector2(600, 420)
var grid = {} # Dictionary of room instances
var current_grid_pos = Vector2.ZERO

func _ready():
	Events.room_transition_requested.connect(_on_transition_requested)
	generate_map()
	setup_start_position()

func setup_start_position():
	var player = get_tree().get_first_node_in_group("player")
	
	if grid.has(Vector2.ZERO):
		var start_room = grid[Vector2.ZERO]
		
		camera.global_position = start_room.global_position + (room_size / 2)
		player.global_position = start_room.global_position + (room_size / 2)
		
		start_room.start_room()

func generate_map():
	var walker_pos = Vector2.ZERO
	var room_count = 8
	
	# Create the starting room
	spawn_room(walker_pos, start_room_scene)
	
	while grid.size() < room_count:
		var direction = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()
		walker_pos += direction
		
		if not grid.has(walker_pos):
			spawn_room(walker_pos, room_scenes.pick_random())

func spawn_room(grid_pos: Vector2, scene: PackedScene):
	var room = scene.instantiate()
	room.global_position = grid_pos * room_size
	room_container.add_child(room)
	grid[grid_pos] = room
	
	room.set_meta("grid_pos", grid_pos) # Identifying position of room on a grid

func _on_transition_requested(direction: String):
	var offset = Vector2.ZERO
	match direction:
		"NorthDoor": offset = Vector2.UP
		"SouthDoor": offset = Vector2.DOWN
		"EastDoor":  offset = Vector2.RIGHT
		"WestDoor":  offset = Vector2.LEFT
	
	var next_pos = current_grid_pos + offset
	
	if grid.has(next_pos):
		current_grid_pos = next_pos
		transition_to_room(grid[next_pos], direction)

func update_camera_limits(room):
	var size = room.get_room_pixel_size()
	camera.limit_left = room.global_position.x
	camera.limit_top = room.global_position.y
	camera.limit_right = room.global_position.x + size.x
	camera.limit_bottom = room.global_position.y + size.y

func transition_to_room(next_room, door_hit):
	# 1. Pause gameplay / ignore inputs during transition
	# 2. Tween camera
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", next_room.global_position + (room_size/2), 0.5)
	
	# 3. Teleport player into room
	var player = get_tree().get_first_node_in_group("player")
	var move_offset = Vector2.ZERO
	match door_hit:
		"NorthDoor": move_offset = Vector2(0, -200) # Jump the wall
		"SouthDoor": move_offset = Vector2(0, 200)
		"EastDoor":  move_offset = Vector2(200, 0)
		"WestDoor":  move_offset = Vector2(-200, 0)
		
	player.global_position += move_offset
	
	await tween.finished
	
	# 4. Activate Room: spawn enemies, etc.
	if next_room.has_method("start_room"):
		next_room.start_room()
