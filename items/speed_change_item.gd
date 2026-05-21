extends ItemPickup


func _apply_to_player(player: Player) -> void:
	player.change_speed(50)	
