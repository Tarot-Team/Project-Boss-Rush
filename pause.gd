extends CanvasLayer

func _ready():
	$Control.visible = false

func resume():
	get_tree().paused = false
	$Control.visible = false
	$AnimationPlayer.play_backwards("blur")

func pause():
	get_tree().paused = true
	$Control.visible = true
	$AnimationPlayer.play("blur")

func _input(event):
	if event.is_action_pressed("escape"):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_restart_pressed():
	resume()
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_resume_pressed():
	resume()

func _on_quit_pressed():
	get_tree().quit()
