extends Control

func _ready() -> void:
	# Focus the start button when the menu loads
	$MarginContainer/VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_options_button_pressed() -> void:
	print("Options menu not implemented yet")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
