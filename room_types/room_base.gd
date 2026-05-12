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

var door_coords = {
	"NorthDoor": Vector2i(21, 1),
	"SouthDoor": Vector2i(18, 20),
	"WestDoor": Vector2i(0, 10),
	"EastDoor": Vector2i(36, 10)
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for door in doors.get_children():
		door.body_entered.connect(_on_door_entered.bind(door.name))
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

func _on_door_entered(body, door_name):
	if body.is_in_group("player"):
		Events.room_transition_requested.emit(door_name)

func get_room_pixel_size() -> Vector2:
	return Vector2(room_width_units * 1280, room_height_units * 720)

func open_doors():
	print("doors opened")

func close_doors():
	print("doors closed")
