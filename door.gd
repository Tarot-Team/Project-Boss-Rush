extends InteractionArea

## When false, this door is a solid wall stub — never show prompt or accept transitions.
var _has_room_connection: bool = true


func _ready() -> void:
	super() # IMPORTANT: This calls the InteractionArea setup code

	if action_name == "Press [E]":
		action_name = "Press [F] to Interact"


func set_has_room_connection(has_neighbor: bool) -> void:
	_has_room_connection = has_neighbor
	monitoring = has_neighbor


func set_locked(is_locked: bool) -> void:
	if is_locked:
		modulate = Color.RED
		monitoring = false
	else:
		modulate = Color.WHITE
		monitoring = _has_room_connection
