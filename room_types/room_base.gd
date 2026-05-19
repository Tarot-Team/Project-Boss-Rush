extends Node2D

@export var room_width_units: int = 1 # how many grid cells wide
@export var room_height_units: int = 1 # how many grid cells tall
@export_range(1, 10) var min_spawns_per_enemy_type: int = 1
@export_range(1, 10) var max_spawns_per_enemy_type: int = 3
@export var spawn_jitter_radius: float = 96.0
@export var spawn_door_clearance: float = 128.0

signal room_cleared
signal player_entered(room_node)

@export var enemy_scenes: Array[PackedScene] # This defines which enemies can spawn
var is_cleared = false
var is_active = false
var has_spawned_enemies = false

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
		push_warning("BaseRoom: could not find WallPatch on %s." % door_node.name)
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
	set_room_active(false)

func start_room() -> void:
	if is_cleared: return
	set_room_active(true)
	if not has_spawned_enemies:
		spawn_enemies()

func set_room_active(active: bool) -> void:
	is_active = active
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_ancestor_of(enemy):
			if active:
				enemy.process_mode = Node.PROCESS_MODE_INHERIT
			else:
				enemy.process_mode = Node.PROCESS_MODE_DISABLED


func spawn_enemies() -> void:
	var choices: Array[PackedScene] = []
	for scene_entry in enemy_scenes:
		if scene_entry != null:
			choices.push_back(scene_entry as PackedScene)
	if choices.is_empty():
		push_warning("BaseRoom.spawn_enemies: enemy_scenes has no PackedScene assigned.")
		has_spawned_enemies = true
		is_cleared = true
		lock_doors(false)
		return
	has_spawned_enemies = true
	for enemy_scene in choices:
		var spawn_count := randi_range(min_spawns_per_enemy_type, max_spawns_per_enemy_type)
		for i in range(spawn_count):
			_spawn_enemy(enemy_scene)


func _spawn_enemy(enemy_scene: PackedScene) -> void:
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	enemy.add_to_group("enemies")
	enemy.tree_exited.connect(_check_room_cleared)
	if is_active:
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(enemy)
	enemy.global_position = _random_spawn_position()


func _random_spawn_position() -> Vector2:
	var markers := spawner_container.get_children()
	if markers.is_empty():
		var room_rect := get_room_pixel_rect()
		return global_position + room_rect.position + room_rect.size / 2.0

	for attempt in range(12):
		var marker: Node2D = markers.pick_random() as Node2D
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, spawn_jitter_radius)
		var spawn_position := marker.global_position + offset
		if _is_clear_of_doors(spawn_position):
			return spawn_position

	var fallback_marker: Node2D = markers.pick_random() as Node2D
	return fallback_marker.global_position


func _is_clear_of_doors(spawn_position: Vector2) -> bool:
	for door in doors.get_children():
		var door_node: Node2D = door as Node2D
		if door_node != null and spawn_position.distance_to(door_node.global_position) < spawn_door_clearance:
			return false
	return true


func _check_room_cleared() -> void:
	await get_tree().process_frame # delay a frame to not break stuff
	var enemies = get_tree().get_nodes_in_group("enemies")
	var room_enemies = 0
	for enemy in enemies:
		if is_ancestor_of(enemy): room_enemies += 1
	
	if room_enemies == 0:
		is_cleared = true
		lock_doors(false)
		room_cleared.emit()



func lock_doors(locked: bool):
	for door in doors.get_children():
		door.set_locked(locked) # placeholder for future animation n interactable

#func _on_door_entered(body, door_name):
	#if body.is_in_group("player"):
		#Events.room_transition_requested.emit(door_name)

func get_room_pixel_rect() -> Rect2:
	var walls_layer = tilemap
	if walls_layer == null:
		walls_layer = get_node_or_null("Walls")
	if walls_layer == null:
		return Rect2()
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
	pass

func close_doors():
	pass
