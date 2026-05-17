extends Control

@onready var main_menu_container = $MarginContainer
@onready var class_picker_container = $ClassPicker
@onready var character_texture = $ClassPicker/VBoxContainer/HBoxContainer/CharacterTexture
@onready var character_name_label = $ClassPicker/VBoxContainer/CharacterName
@onready var character_desc_label = $ClassPicker/VBoxContainer/CharacterDesc
@onready var character_stats_label = $ClassPicker/VBoxContainer/CharacterStats

var characters: Array = [
	{
		"id": "mars",
		"name": "Mars",
		"texture": preload("res://assets/player/Mars/mars_idle/mars walk_0001.png"),
		"desc": "A fierce Fighter/Barbarian.\nExcels in close-quarters combat!",
		"abilities": [CharacterData.ABILITY_DODGE],
		"primary_ability": CharacterData.ABILITY_SLASH,
		"secondary_ability": CharacterData.ABILITY_FIRE_SLASH,
		"stats": {"health": 8, "speed": 200, "lunge": 100},
	},
	{
		"id": "mercury",
		"name": "Mercury",
		"texture": preload("res://assets/player/Mercury/Walk/Mercury_0001.png"),
		"desc": "Small, fast, and deadly.\nA melee speedster!",
		"abilities": [CharacterData.ABILITY_DODGE],
		"primary_ability": CharacterData.ABILITY_SLASH_QUICK,
		"secondary_ability": CharacterData.ABILITY_COMET,
		"stats": {"health": 3, "speed": 300, "lunge": 400},
	},
	{
		"id": "moon",
		"name": "Moon",
		"texture": preload("res://assets/player/moon/moon_walk/Moon walk 1.png"),
		"desc": "Spell-oriented with mystical vibes.\nRMB: a wide horizontal light beam.",
		"abilities": [CharacterData.ABILITY_DODGE],
		"primary_ability": CharacterData.ABILITY_SLASH_LIGHT,
		"secondary_ability": CharacterData.ABILITY_MOON_LASER,
		"stats": {"health": 4, "speed": 250, "lunge": 100},
	},
	{
		"id": "neptune",
		"name": "Neptune",
		"texture": preload("res://assets/player/neptune/neptune_walk/Neptune_0001.png"),
		"desc": "A water-based Summoner.\nLet the tides fight for you!",
		"abilities": [CharacterData.ABILITY_DODGE],
		"primary_ability": CharacterData.ABILITY_SLASH_WATER,
		"secondary_ability": CharacterData.ABILITY_NEPTUNE_SURGE,
		"stats": {"health": 5, "speed": 250, "lunge": 100},
	},
	{
		"id": "venus",
		"name": "Venus",
		"texture": preload("res://assets/player/venus/Venus_0001.png"),
		"desc": "A deadly Ranger.\nMelts foes with heat and acid!",
		"abilities": [CharacterData.ABILITY_DODGE],
		"primary_ability": CharacterData.ABILITY_ARROW_POISON,
		"secondary_ability": CharacterData.ABILITY_POISON_FLASK,
		"stats": {"health": 4, "speed": 250, "lunge": 100},
	},
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
	var char_data: Dictionary = characters[current_char_index]
	character_name_label.text = char_data["name"]
	character_desc_label.text = char_data["desc"]
	character_texture.texture = char_data["texture"]

	var stats: Dictionary = char_data["stats"]
	var sp: int = int(stats.get("speed", CharacterData.SPEED_STAT_MIN))
	var lg: int = int(stats.get("lunge", CharacterData.LUNGE_STAT_MIN))
	var speed_stars: int = CharacterData.value_to_stars(sp, CharacterData.SPEED_STAT_MIN, CharacterData.SPEED_STAT_MAX)
	var lunge_stars: int = CharacterData.value_to_stars(lg, CharacterData.LUNGE_STAT_MIN, CharacterData.LUNGE_STAT_MAX)
	var speed_str := get_stars(speed_stars)
	var lunge_str := get_stars(lunge_stars)

	character_stats_label.text = "Health: %d  |  Speed: %s  |  Lunge: %s\n%s" % [
		int(stats.get("health", 5)),
		speed_str,
		lunge_str,
		AbilityKit.loadout_summary(char_data)
	]

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
	Global.player_class = characters[current_char_index].duplicate(true)
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
