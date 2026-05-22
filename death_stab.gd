extends Area2D
@export var swing_length = 1
@export var knockback_force = 1000.0
@export var damage = 1
var player_velocity_at_hit = Vector2.ZERO
var player_pos_at_hit = Vector2.ZERO
var velocity = Vector2.ZERO  # add this

func _ready() -> void:
	$AnimatedSprite2D.play("swing")
	get_tree().create_timer(swing_length).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):  # add this
	position += velocity * delta

func set_player_info(p_vel: Vector2, p_pos: Vector2):
	player_velocity_at_hit = p_vel
	player_pos_at_hit = p_pos

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)	
