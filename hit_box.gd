extends Area2D

@onready var interaction_area = $InteractionArea

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	player.change_money(1)
