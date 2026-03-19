extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.animation = "swing"
	$AnimatedSprite2D.play()
	get_tree().create_timer(0.1).timeout.connect(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




#func _on_area_entered(area: Area2D) -> void:
	#area.queue_free()
