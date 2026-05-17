extends InteractionArea

func _ready():
	super() # IMPORTANT: This calls the InteractionArea setup code
	
	if action_name == "Press [E]":
		action_name = "Press [F] to Interact"
func set_locked(is_locked: bool):
	if is_locked:
		modulate = Color.RED
		monitoring = false # Player cannot interact while locked
	else:
		modulate = Color.WHITE
		monitoring = true
