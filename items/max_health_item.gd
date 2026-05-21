extends ItemPickup


func _apply_to_player(player: Player) -> void:
	player.change_max_health(1)
