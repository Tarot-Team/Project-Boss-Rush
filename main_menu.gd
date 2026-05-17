extends Control

@onready var main_menu_container = $MarginContainer
@onready var class_picker_container = $ClassPicker
@onready var character_texture = $ClassPicker/VBoxContainer/HBoxContainer/CharacterTexture
@onready var character_name_label = $ClassPicker/VBoxContainer/CharacterName

var characters = [
	{"name": "Mars", "texture": preload("res://assets/player/Mars/mars walk_0001.png")},
	{"name": "Mercury", "texture": preload("res://assets/player/Mercury/Walk/Mercury_0001.png")},
	{"name": "Moon", "texture": preload("res://assets/player/moon/moon_walk/Moon walk 1.png")},
	{"name": "Neptune", "texture": preload("res://assets/player/neptune/Neptune_0001.png")},
	{"name": "Venus", "texture": preload("res://assets/player/venus/Venus_0001.png")}
]

var current_char_index = 0

func _ready() -> void:
	class_picker_container.hide()
	main_menu_container.show()
	$MarginContainer/VBoxContainer/StartButton.grab_focus()
	update_character_display()

func _input(event: InputEvent) -> void:
	if class_picker_container.visible:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
			scroll_character(-1)
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
			scroll_character(1)
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_character(-1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_character(1)

func scroll_character(dir: int) -> void:
	current_char_index += dir
	if current_char_index < 0:
		current_char_index = characters.size() - 1
	elif current_char_index >= characters.size():
		current_char_index = 0
	update_character_display()

func update_character_display() -> void:
	var char_data = characters[current_char_index]
	character_name_label.text = char_data["name"]
	character_texture.texture = char_data["texture"]

func _on_start_button_pressed() -> void:
	main_menu_container.hide()
	$TitleLabel.hide()
	class_picker_container.show()
	$ClassPicker/VBoxContainer/HBoxContainer2/ConfirmButton.grab_focus()

func _on_options_button_pressed() -> void:
	print("Options menu not implemented yet")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_confirm_button_pressed() -> void:
	# Here you could pass the selected character to a global singleton or directly to the next scene
	# For now, we'll just load the main scene
	print("Selected character: ", characters[current_char_index]["name"])
	get_tree().change_scene_to_file("res://main.tscn")

func _on_back_button_pressed() -> void:
	class_picker_container.hide()
	main_menu_container.show()
	$TitleLabel.show()
	$MarginContainer/VBoxContainer/StartButton.grab_focus()

func _on_left_button_pressed() -> void:
	scroll_character(-1)

func _on_right_button_pressed() -> void:
	scroll_character(1)
