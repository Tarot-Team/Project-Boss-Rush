extends Control

@onready var main_menu_container = $MarginContainer
@onready var class_picker_container = $ClassPicker
@onready var character_texture = $ClassPicker/VBoxContainer/HBoxContainer/CharacterTexture
@onready var character_name_label = $ClassPicker/VBoxContainer/CharacterName
@onready var character_desc_label = $ClassPicker/VBoxContainer/CharacterDesc
@onready var character_stats_label = $ClassPicker/VBoxContainer/CharacterStats

var characters = [
	{
		"name": "Mars", 
		"texture": preload("res://assets/player/Mars/mars walk_0001.png"),
		"desc": "A fierce Fighter/Barbarian.\nExcels in close-quarters combat!",
		"stats": {
			"health": 8,
			"speed": 350,
			"lunge": 400,
			"speed_stars": 2,
			"lunge_stars": 4
		}
	},
	{
		"name": "Mercury", 
		"texture": preload("res://assets/player/Mercury/Walk/Mercury_0001.png"),
		"desc": "Small, fast, and deadly.\nA melee speedster!",
		"stats": {
			"health": 3,
			"speed": 600,
			"lunge": 500,
			"speed_stars": 5,
			"lunge_stars": 5
		}
	},
	{
		"name": "Moon", 
		"texture": preload("res://assets/player/moon/moon_walk/Moon walk 1.png"),
		"desc": "Spell-oriented with mystical vibes.\nMaster of the arcane!",
		"stats": {
			"health": 4,
			"speed": 400,
			"lunge": 200,
			"speed_stars": 3,
			"lunge_stars": 1
		}
	},
	{
		"name": "Neptune", 
		"texture": preload("res://assets/player/neptune/Neptune_0001.png"),
		"desc": "A water-based Summoner.\nLet the tides fight for you!",
		"stats": {
			"health": 5,
			"speed": 400,
			"lunge": 300,
			"speed_stars": 3,
			"lunge_stars": 3
		}
	},
	{
		"name": "Venus", 
		"texture": preload("res://assets/player/venus/Venus_0001.png"),
		"desc": "A deadly Ranger.\nMelts foes with heat and acid!",
		"stats": {
			"health": 4,
			"speed": 450,
			"lunge": 250,
			"speed_stars": 4,
			"lunge_stars": 2
		}
	}
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

func get_stars(count: int) -> String:
	var res = ""
	for i in range(5):
		if i < count:
			res += "★"
		else:
			res += "☆"
	return res

func update_character_display() -> void:
	var char_data = characters[current_char_index]
	character_name_label.text = char_data["name"]
	character_desc_label.text = char_data["desc"]
	character_texture.texture = char_data["texture"]
	
	var stats = char_data["stats"]
	var speed_str = get_stars(stats["speed_stars"])
	var lunge_str = get_stars(stats["lunge_stars"])
	
	character_stats_label.text = "Health: %d  |  Speed: %s  |  Lunge: %s" % [stats["health"], speed_str, lunge_str]

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
	# Save the selected character to our Global singleton
	Global.player_class = characters[current_char_index]
	
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
