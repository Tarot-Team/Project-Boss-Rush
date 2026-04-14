extends Area2D

func set_locked(is_locked: bool):
	if is_locked:
		modulate = Color.RED
		monitoring = false
	else:
		modulate = Color.WHITE
		monitoring = true
