extends ItemPickup


func _apply_to_player(player: Player) -> void:
	player.take_damage(-1)
