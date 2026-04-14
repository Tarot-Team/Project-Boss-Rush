extends Area2D
@export var swing_length = 0.15
@export var knockback_force = 1000.0 # Control strength here!
@export var damage = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$AnimatedSprite2D.animation = "swing"
	$AnimatedSprite2D.play("swing")
	get_tree().create_timer(swing_length).timeout.connect(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
