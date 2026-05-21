extends Area2D

@export var swing_length: float = 0.15
@export var knockback_force: float = 1000.0
@export var damage: int = 1

## Assign on the instance before add_child(); if null, scene default frames are used.
var slash_texture: SpriteFrames
var slash_scale_mult: float = 1.0
var hitbox_scale_mult: float = 1.0

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("swing")
	if slash_texture != null:
		var sf := SpriteFrames.new()
		sf.add_animation(&"swing")
		sf.set_animation_loop(&"swing", true)
		sf.set_animation_speed(&"swing", 14.0)
		sf.add_frame(&"swing", slash_texture, 1.0, -1)
		$AnimatedSprite2D.sprite_frames = sf
	if slash_scale_mult != 1.0:
		$AnimatedSprite2D.scale *= slash_scale_mult
	if hitbox_scale_mult != 1.0:
		$CollisionShape2D.scale *= hitbox_scale_mult
	$AnimatedSprite2D.play(&"swing")
	get_tree().create_timer(swing_length).timeout.connect(queue_free)


func set_player_info(p_vel: Vector2, p_pos: Vector2) -> void:
	player_velocity_at_hit = p_vel
	player_pos_at_hit = p_pos
