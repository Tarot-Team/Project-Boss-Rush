extends Area2D
@export var swing_length = 0.15
@export var knockback_force = 1000.0 # Control strength here!
@export var damage = 1

var player_velocity_at_hit = Vector2.ZERO
var player_pos_at_hit = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$AnimatedSprite2D.animation = "swing"
	$AnimatedSprite2D.play("swing")
	get_tree().create_timer(swing_length).timeout.connect(queue_free)

func set_player_info(p_vel: Vector2, p_pos: Vector2):
	player_velocity_at_hit = p_vel
	player_pos_at_hit = p_pos
