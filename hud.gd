extends CanvasLayer
signal start_game

@onready var heart_container = $MarginContainer/HBoxContainer/HeartContainer
@onready var avatar_icon = $MarginContainer/HBoxContainer/AvatarIcon
var heart_scene = preload("res://Heart.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup_health(max_hp: int):
	# Clear old hearts if any
	for child in heart_container.get_children():
		child.queue_free()
	# var num_hearts = ceil(max_hp / 5.0) # Use if using all the heart pngs 
	var num_hearts = ceil(max_hp)
	
	for i in range(num_hearts):
		var h = heart_scene.instantiate()
		heart_container.add_child(h)

func update_health(current_hp: int):
	var hearts = heart_container.get_children()
	
	for i in range(hearts.size()):
		var heart_value = 0
		if current_hp > i:
			heart_value = 1
		hearts[i].set_heart_state(heart_value)

func change_avatar(tex: Texture2D):
	avatar_icon.texture = tex

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()

func show_game_over():
	show_message("Game Over")
	await $MessageTimer.timeout
	
	$Message.text = "Boss Rush"
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()

func update_score(score):
	$ScoreLabel.text = str(score)

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout() -> void:
	#$Message.hide()
	pass
