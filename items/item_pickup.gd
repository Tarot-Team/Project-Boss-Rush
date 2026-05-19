extends Area2D
class_name ItemPickup

@onready var interaction_area: InteractionArea = get_node_or_null("InteractionArea") as InteractionArea


func _ready() -> void:
	add_to_group("items")
	if interaction_area == null:
		push_warning("%s is missing an InteractionArea child." % name)
		return
	interaction_area.interact = Callable(self, "_on_interact")


func reset() -> void:
	show()
	if interaction_area != null:
		interaction_area.set_deferred("monitoring", true)


func _on_interact() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return

	_apply_to_player(player)
	hide()

	if interaction_area != null:
		interaction_area.set_deferred("monitoring", false)


func _apply_to_player(_player: Player) -> void:
	pass
