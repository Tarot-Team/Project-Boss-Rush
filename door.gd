extends InteractionArea

## When false, this door is a solid wall stub — never show prompt or accept transitions.
var _has_room_connection: bool = true


func _ready() -> void:
	super()

	if action_name == "Press [E]":
		action_name = "Press [F] to Interact"


func _is_actual_gate_prompt() -> bool:
	## Wall stubs hide gate art and keep `WallPatch`; only real exits flip those.
	var wall_patch: CanvasItem = get_node_or_null("WallPatch") as CanvasItem
	if wall_patch != null and wall_patch.visible:
		return false
	var gv: CanvasItem = get_node_or_null("GateVisuals") as CanvasItem
	if gv != null:
		return gv.visible
	## Older rooms without `GateVisuals`: treat invisible wall_patch as traversable gap.
	return true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not _is_actual_gate_prompt():
			return
		InteractionManager.register_area(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister_area(self)


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
