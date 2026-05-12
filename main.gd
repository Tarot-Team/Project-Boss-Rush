extends Node

@export var mob_scene: PackedScene
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HUD.update_health($Player1.max_health, $Player1.health)
	$Player1.health_changed.connect($HUD.update_health)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	get_tree().call_group("enemies", "start_fleeing", $Player1.global_position)

func new_game():
	print("starting new game")
	score = 0
	$Player1.reset()
	$Player1.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("items", "reset")


func _on_mob_timer_timeout() -> void:
	var mob = mob_scene.instantiate()
	
	# Choose a random location on the path
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	
	mob.position = mob_spawn_location.position
	
	# Set the mob's direction perpendicular to the path direction.
	#var direction = mob_spawn_location.rotation + PI / 2
	var direction = ($Player1.position - mob.position).angle()

	#direction += randf_range(-PI/4, PI/4)
	mob.rotation = direction
	
	var velocity = Vector2(randf_range(150, 250), 0)
	mob.velocity = velocity.rotated(direction)

	# Spawns the mob by adding an instance to the main scene
	add_child(mob)

func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
	$HUD.show_message("")
