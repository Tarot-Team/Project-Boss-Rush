extends Node2D
## Lingering AoE — periodic damage to everyone inside.

@export var duration: float = 4.2
@export var tick_interval: float = 0.48
@export var damage_per_tick: int = 1
@export var knockback: float = 160.0

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO

var _elapsed: float = 0.0
var _tick_accum: float = 0.0


func setup(p_vel: Vector2, impact_pos: Vector2) -> void:
	player_velocity_at_hit = p_vel
	player_pos_at_hit = impact_pos


func _ready() -> void:
	z_index = 2


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return
	_tick_accum += delta
	if _tick_accum < tick_interval:
		return
	_tick_accum = 0.0

	var zone: Area2D = $DamageZone as Area2D
	if zone == null:
		return
	for area in zone.get_overlapping_areas():
		var enemy: Node2D = area.get_parent() as Node2D
		if enemy == null or not enemy.is_in_group("enemies") or not enemy.has_method("take_damage"):
			continue
		enemy.take_damage(damage_per_tick, player_pos_at_hit, knockback)
