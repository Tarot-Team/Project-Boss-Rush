extends Area2D

@export var swing_length: float = 0.15
@export var knockback_force: float = 1000.0
@export var damage: int = 1

## Animation name to play from this scene's AnimatedSprite2D SpriteFrames.
var slash_animation: StringName = &"slash"
var slash_scale_mult: float = 1.0
var hitbox_scale_mult: float = 1.0

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("swing")
	if slash_scale_mult != 1.0:
		$AnimatedSprite2D.scale *= slash_scale_mult
	if hitbox_scale_mult != 1.0:
		$CollisionShape2D.scale *= hitbox_scale_mult
	if $AnimatedSprite2D.sprite_frames != null and $AnimatedSprite2D.sprite_frames.has_animation(slash_animation):
		$AnimatedSprite2D.play(slash_animation)
	elif $AnimatedSprite2D.sprite_frames != null and $AnimatedSprite2D.sprite_frames.has_animation(&"slash"):
		$AnimatedSprite2D.play(&"slash")
	else:
		$AnimatedSprite2D.play()
	if $AnimatedSprite2D.sprite_frames != null and not $AnimatedSprite2D.sprite_frames.get_animation_loop($AnimatedSprite2D.animation):
		await $AnimatedSprite2D.animation_finished
		queue_free()
	else:
		get_tree().create_timer(swing_length).timeout.connect(queue_free)


func set_player_info(p_vel: Vector2, p_pos: Vector2) -> void:
	player_velocity_at_hit = p_vel
	player_pos_at_hit = p_pos
