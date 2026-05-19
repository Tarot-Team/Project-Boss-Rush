extends Node

@export var mob_scene: PackedScene
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.player_class.is_empty():
		push_warning(
				"Global.player_class is empty. You probably ran main.tscn directly (F6 Run Current Scene). "
				+ "Use Play Project (F5) from main_menu.tscn, pick a character, then Confirm — "
				+ "otherwise loadout stays Mars defaults and edits to Moon won't show."
		)
	if Global.player_class.has("stats"):
		$Player1.apply_class_stats(Global.player_class["stats"])
		
	if Global.player_class.has("texture"):
		$HUD.change_avatar(Global.player_class["texture"])
		
	$Player1.setup_hud($HUD)
	$HUD.configure_ability_pips($Player1.has_ability(CharacterData.ABILITY_DODGE), true)
	$Player1.refresh_secondary_hud_icon()
		
	$HUD.update_health($Player1.max_health, $Player1.health)
	$Player1.health_changed.connect($HUD.update_health)
	$HUD/StartButton.hide()
	$HUD/Message.hide()
	new_game()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over():
	$MobTimer.stop()
	$ScoreTimer.stop()
	$HUD.show_game_over()
	get_tree().call_group("enemies", "start_fleeing", $Player1.global_position)

func new_game():
	score = 0
	$Player1.reset()
	$Player1.show()
	$Player1.set_body_collision_enabled(true)
	$LevelManager.setup_start_position()
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$HUD.configure_ability_pips($Player1.has_ability(CharacterData.ABILITY_DODGE), true)
	$Player1.refresh_secondary_hud_icon()
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
	$Player1.set_abilities_enabled(true)
	$ScoreTimer.start()
	$HUD.show_message("")
