extends Node2D

@export var room_width_units: int = 1 # how many grid cells wide
@export var room_height_units: int = 1 # how many grid cells tall

signal room_cleared
signal player_entered(room_node)

@export var enemy_scenes: Array[PackedScene] # This defines which enemies can spawn
var is_cleared = false
var is_active = false

@onready var tilemap = $Walls

@onready var spawner_container = $EnemySpawnPoints
@onready var doors = $Doors

#var door_coords = {
	#"NorthDoor": Vector2i(21, 1),
	#"SouthDoor": Vector2i(18, 20),
	#"WestDoor": Vector2i(0, 10),
	#"EastDoor": Vector2i(36, 10)
#}
func setup_doors(has_north: bool, has_south: bool, has_east: bool, has_west: bool):
	_configure_door($Doors/NorthDoor, has_north)
	_configure_door($Doors/SouthDoor, has_south)
	_configure_door($Doors/EastDoor, has_east)
	_configure_door($Doors/WestDoor, has_west)
	
func _configure_door(door_node: InteractionArea, has_neighbor: bool):
	if door_node.has_method("set_has_room_connection"):
		door_node.set_has_room_connection(has_neighbor)
	else:
		door_node.monitoring = has_neighbor

	## No neighbor = solid stub: disable trigger shape so prompts cannot fire even if scripts run out of order.
	var interact_shape := door_node.get_node_or_null("InteractCollision") as CollisionShape2D
	if interact_shape != null:
		interact_shape.disabled = not has_neighbor

	var wall_patch = door_node.get_node_or_null("WallPatch")
	var gate_visuals = door_node.get_node_or_null("GateVisuals") # Get the visuals node

	if wall_patch == null:
		print("CRASH AVOIDED: Could not find WallPatch on ", door_node.name)
		return

	if has_neighbor:
		# Room exists! Open the path visually, disable the fake wall.
		wall_patch.hide()
		wall_patch.process_mode = Node.PROCESS_MODE_DISABLED

		if gate_visuals:
			gate_visuals.show() # Show just the gate visuals
	else:
		# No room here! Show the fake wall.
		wall_patch.show()
		wall_patch.process_mode = Node.PROCESS_MODE_INHERIT

		if gate_visuals:
			gate_visuals.hide() # Hide just the gate visuals

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_doors() # Closes the doors when the player enters
	spawn_enemies()

func start_room():
	if is_cleared: return
	is_active = true
	lock_doors(true)
	spawn_enemies()

func spawn_enemies():
	for marker in $EnemySpawnPoints.get_children():
		var enemy = enemy_scenes.pick_random().instantiate()
		enemy.global_position = marker.global_position
		enemy.add_to_group("enemies")
		enemy.tree_exited.connect(_check_room_cleared)
		add_child(enemy)

func _check_room_cleared():
	await get_tree().process_frame # delay a frame to not break stuff
	var enemies = get_tree().get_nodes_in_group("enemies")
	var room_enemies = 0
	for enemy in enemies:
		if is_ancestor_of(enemy): room_enemies += 1
	
	if room_enemies == 0:
		is_cleared = true
		lock_doors(false)
		room_cleared.emit



func lock_doors(locked: bool):
	for door in doors.get_children():
		door.set_locked(locked) # placeholder for future animation n interactable

#func _on_door_entered(body, door_name):
	#if body.is_in_group("player"):
		#Events.room_transition_requested.emit(door_name)

func get_room_pixel_rect() -> Rect2:
	var walls_layer = get_node("Walls")
	var map_rect = walls_layer.get_used_rect()
	var tile_size = walls_layer.tile_set.tile_size
	var map_scale = walls_layer.scale
	
	# Calculate the true pixel position and size
	var pixel_x = map_rect.position.x * tile_size.x * map_scale.x
	var pixel_y = map_rect.position.y * tile_size.y * map_scale.y
	var pixel_width = map_rect.size.x * tile_size.x * map_scale.x
	var pixel_height = map_rect.size.y * tile_size.y * map_scale.y
	
	return Rect2(pixel_x, pixel_y, pixel_width, pixel_height)

func open_doors():
	print("doors opened")

func close_doors():
	print("doors closed")
