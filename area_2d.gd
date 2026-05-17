extends Area2D
class_name InteractionArea

@export var action_name: String = "Press [E]"
@export var door_direction: String = "" # change to the door names in inspector later

var interact: Callable = func():
	if door_direction != "":
		Events.room_transition_requested.emit(door_direction)
	else:
		print("Warning: Door direction not set on this InteractionArea")

func _ready():
	# Register this area with the manager when player is close
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.register_area(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister_area(self)
