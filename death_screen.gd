extends Control

func _ready():
	visible = false
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.died.connect(_on_player_died)

func _on_player_died():
	get_tree().paused = true
	visible = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()
