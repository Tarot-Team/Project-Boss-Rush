extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().create_timer(0.3).timeout.connect(queue_free)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		area.damage


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
