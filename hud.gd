extends CanvasLayer
signal start_game

@onready var heart_container = $TopLeftUI/HBoxContainer/HeartContainer
@onready var avatar_icon = $TopLeftUI/HBoxContainer/AvatarIcon
@onready var minimap = $MinimapContainer/VBoxContainer/Minimap
@onready var dodge_cooldown_slot = $TopLeftUI/HBoxContainer/AbilitySlots/DodgeSlot
@onready var fireball_cooldown_slot = $TopLeftUI/HBoxContainer/AbilitySlots/FireballSlot
var heart_scene = preload("res://Heart.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func init_minimap(start_center: Vector2):
	minimap.init_map(start_center)

func update_minimap(prev_center: Vector2, new_center: Vector2):
	minimap.visit_room(prev_center, new_center)
	
func clear_minimap():
	minimap.clear()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_health(max_hp: int, current_hp: int):
	# Clear old hearts
	for child in heart_container.get_children():
		child.queue_free()

	# Rebuild hearts
	var num_hearts = ceil(max_hp)
	var hearts = []

	for i in range(num_hearts):
		var h = heart_scene.instantiate()
		heart_container.add_child(h)
		hearts.append(h)

	# Fill hearts
	for i in range(hearts.size()):
		hearts[i].set_heart_state(1 if i < current_hp else 0)

func set_ability_cooldowns(dodge_rem: float, dodge_tot: float, fire_rem: float, fire_tot: float) -> void:
	if dodge_cooldown_slot and dodge_cooldown_slot.visible:
		dodge_cooldown_slot.set_cooldown_remaining(dodge_rem, dodge_tot)
	if fireball_cooldown_slot and fireball_cooldown_slot.visible:
		fireball_cooldown_slot.set_cooldown_remaining(fire_rem, fire_tot)


func configure_ability_pips(show_dodge: bool, show_secondary: bool) -> void:
	if dodge_cooldown_slot:
		dodge_cooldown_slot.visible = show_dodge
	if fireball_cooldown_slot:
		fireball_cooldown_slot.visible = show_secondary


func configure_abilities(show_fireball: bool) -> void:
	## Kept for compatibility; prefer configure_ability_pips.
	configure_ability_pips(false, show_fireball)


func configure_secondary_ability(ability_id: String, override_icon: Texture2D = null) -> void:
	if fireball_cooldown_slot:
		var tex: Texture2D = override_icon if override_icon != null else AbilityKit.secondary_hud_icon(ability_id)
		if fireball_cooldown_slot.has_method("set_ability_icon"):
			fireball_cooldown_slot.set_ability_icon(tex)
		else:
			fireball_cooldown_slot.ability_icon = tex
			fireball_cooldown_slot.queue_redraw()


func configure_for_character(_character_id: String) -> void:
	configure_secondary_ability(Global.active_secondary_ability())


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
	$Message.hide()

func _on_message_timer_timeout() -> void:
	#$Message.hide()
	pass
