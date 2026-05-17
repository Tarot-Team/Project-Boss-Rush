extends Node2D
## Full-width horizontal beam at the caster’s height; direction sets segment flip only.

@export var lifetime: float = 0.65
@export var damage: int = 3
@export var knockback_force: float = 900.0
## Base width of art + hitbox in scene (before scale.x).
const BASE_BEAM_WIDTH: float = 420.0

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO

var _damaged: Dictionary = {}


func _ready() -> void:
	get_tree().create_timer(lifetime, true, false, true).timeout.connect(queue_free)


func setup(p_vel: Vector2, p_pos: Vector2, facing_right: bool, screen_width_px: float) -> void:
	player_velocity_at_hit = p_vel
	player_pos_at_hit = p_pos
	var span: float = maxf(screen_width_px * 4.5, 3000.0)
	scale.x = span / BASE_BEAM_WIDTH
	if is_instance_valid($Segments):
		$Segments.scale.x = 1.0 if facing_right else -1.0


func _physics_process(_delta: float) -> void:
	var hit_area: Area2D = $HitArea as Area2D
	if hit_area == null:
		return
	for body in hit_area.get_overlapping_bodies():
		if body.is_in_group("player") or body.is_in_group("enemies"):
			continue
		queue_free()
		return
	for area in hit_area.get_overlapping_areas():
		var enemy: Node2D = area.get_parent() as Node2D
		if enemy == null or not enemy.is_in_group("enemies") or not enemy.has_method("take_damage"):
			continue
		var eid: int = enemy.get_instance_id()
		if _damaged.has(eid):
			continue
		_damaged[eid] = true
		var hit_dir: Vector2 = (enemy.global_position - player_pos_at_hit).normalized()
		var mom: float = 1.0 + (player_velocity_at_hit.dot(hit_dir) / 600.0)
		mom = clampf(mom, 0.5, 1.8)
		enemy.take_damage(damage, player_pos_at_hit, knockback_force * mom)
