extends Area2D

@onready var interaction_area = $InteractionArea
var cost: int = 200
@onready var player = get_tree().get_nodes_in_group("player")[0]
func reset():
	show()
	interaction_area.set_deferred("monitoring", true)
	
func _ready():
	interaction_area.interact = Callable(self, "_on_interact")	

func _on_interact():
	#if player.coins < cost: return
	player.change_max_health(1)
	print(player.health)
	hide()
	interaction_area.set_deferred("monitoring", false)

	
