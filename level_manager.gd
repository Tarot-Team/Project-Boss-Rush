extends Node2D

@export var room_scenes: Array[PackedScene] # Room variants (inherited) go here
@export var start_room_scene: PackedScene

@onready var room_container = $RoomContainer
#@onready var camera = $Camera2D

var room_size = Vector2(1280, 720)
var grid = {} # Dictionary of room instances
var current_grid_pos = Vector2.ZERO
var current_room_node = null

func get_room_center(room) -> Vector2:
	var room_rect = room.get_room_pixel_rect()
	return room.global_position + room_rect.position + (room_rect.size / 2)

func _ready():
	Events.room_transition_requested.connect(_on_transition_requested)
	generate_map()
	setup_start_position()

func setup_start_position():
	var player = get_tree().get_first_node_in_group("player")
	
	if grid.has(Vector2.ZERO):
		var start_room = grid[Vector2.ZERO]
		current_room_node = start_room
		
		# Center the player based on this room's specific size
		var room_rect = start_room.get_room_pixel_rect()
		player.global_position = start_room.global_position + room_rect.position + (room_rect.size / 2)
		
		update_camera_limits(start_room)
		start_room.start_room()
		
		var hud = get_node("../HUD")
		if hud and hud.has_method("init_minimap"):
			hud.init_minimap(get_room_center(start_room))

func generate_map():
	var walker_pos = Vector2.ZERO
	var room_count = 8
	var spawned_rooms = 0 # Track actual rooms spawned, not just grid spaces filled
	
	# Create the starting room
	spawn_room(walker_pos, start_room_scene)
	spawned_rooms += 1
	
	# Generate Rooms
	while spawned_rooms < room_count:
		var direction = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()
		walker_pos += direction
		
		# Check if this spot is empty
		if not grid.has(walker_pos):
			var new_room_scene = room_scenes.pick_random()
			
			# (Optional) If you have a 2x2 room, you'd need to check if ALL 4 spots it needs are empty here before spawning it!
			
			spawn_room(walker_pos, new_room_scene)
			spawned_rooms += 1
			#room.setup_doors(has_north, has_south, has_east, has_west)
	
	# Configure the doors for each room (THIS IS THE CORRECT PLACE FOR IT!)
	for grid_pos in grid.keys():
		var room = grid[grid_pos]
		
		# Check if a neighbor exists at each adjacent grid coordinate
		var has_north = grid.has(grid_pos + Vector2.UP)
		var has_south = grid.has(grid_pos + Vector2.DOWN)
		var has_east = grid.has(grid_pos + Vector2.RIGHT)
		var has_west = grid.has(grid_pos + Vector2.LEFT)
		
		# Pass the neighbor data to the room
		if room.has_method("setup_doors"):
			room.setup_doors(has_north, has_south, has_east, has_west)

func spawn_room(grid_pos: Vector2, scene: PackedScene):
	var room = scene.instantiate()
	
	# Get the actual pixel size of THIS specific room
	var current_room_size = room.get_room_pixel_rect()
	
	# Position it based on the grid coordinate, but using the base 1280x720 unit size
	# (Assuming your grid coordinates still represent 1280x720 blocks)
	room.global_position = grid_pos * Vector2(1280, 720) 
	
	room_container.add_child(room)
	
	# If a room is larger than 1x1, it needs to occupy multiple grid spaces!
	# We loop through its width and height and claim all those grid spots.
	for x in range(room.room_width_units):
		for y in range(room.room_height_units):
			var occupied_pos = grid_pos + Vector2(x, y)
			grid[occupied_pos] = room
	
	room.set_meta("grid_pos", grid_pos)
	
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
	var player = get_tree().get_first_node_in_group("player")
	var player_camera = player.get_node("Camera2D")
	
	var room_rect = room.get_room_pixel_rect()
	
	# Add the room's global position to the tilemap's local offset
	var true_top_left = room.global_position + room_rect.position
	
	player_camera.limit_left = true_top_left.x
	player_camera.limit_top = true_top_left.y
	player_camera.limit_right = true_top_left.x + room_rect.size.x
	player_camera.limit_bottom = true_top_left.y + room_rect.size.y

func transition_to_room(next_room, door_hit):
	# 1. Pause gameplay / ignore inputs during transition (You can add this later)
	
	var player = get_tree().get_first_node_in_group("player")
	
	# Figure out which door to spawn at in the next room
	var target_door_name = ""
	var push_offset = Vector2.ZERO 
	
	match door_hit:
		"NorthDoor": 
			target_door_name = "SouthDoor"
			push_offset = Vector2(0, -50) 
		"SouthDoor": 
			target_door_name = "NorthDoor"
			push_offset = Vector2(0, 50)  
		"EastDoor":  
			target_door_name = "WestDoor"
			push_offset = Vector2(50, 0) 
		"WestDoor":  
			target_door_name = "EastDoor"
			push_offset = Vector2(-50, 0)  
			
	# Find the actual door node in the next room
	var target_door = next_room.get_node_or_null("Doors/" + target_door_name)
	
	if target_door != null:
		player.global_position = target_door.global_position + push_offset
	else:
		print("Error: Could not find target door: ", target_door_name)
	
	var prev_center = get_room_center(current_room_node)
	var next_center = get_room_center(next_room)
	
	var hud = get_node("../HUD")
	if hud and hud.has_method("update_minimap"):
		hud.update_minimap(prev_center, next_center)
		
	current_room_node = next_room
	
	# Update the camera limits to the new room!
	update_camera_limits(next_room)
	
	# 4. Activate Room: spawn enemies, etc.
	if next_room.has_method("start_room"):
		next_room.start_room()
