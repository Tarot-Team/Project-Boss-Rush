extends Node2D

signal room_cleared

@export var enemy_scenes: Array[PackedScene]
var enemies_count = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_doors() # Closes the doors when the player enters
	spawn_enemies()

func spawn_enemies():
	for marker in $EnemySpawnPoints.get_children():
		var enemy_type = enemy_scenes.pick_random()
		var enemy = enemy_type.instantiate()
		
		enemy.global_position = marker.global_position
		enemy.add_to_group("enemies")
		enemy.tree_exited.connect(_on_enemy_died)
		
		add_child(enemy)
		enemies_count += 1
		
func _on_enemy_died():
		enemies_count -= 1
		if enemies_count <= 0:
			open_doors()
			room_cleared.emit()

func open_doors():
	print("doors opened")

func close_doors():
	print("doors closed")
