extends Node2D
class_name MoonLaser
## Moon secondary: beam aligned to aim, clipped at room walls (+ small bleed), pierce enemies only.

const BASE_BEAM_WIDTH: float = 420.0

## Time at full thickness where damage ticks run (starts after blade_expand_sec).
@export var beam_duration_sec: float = 1.0
@export var damage_per_tick: int = 1
@export var tick_interval_sec: float = 0.08
@export var knockback_force: float = 420.0
## Shot past geometry so the sprite doesn’t visibly stop short before the tiles.
@export var wall_penetration_px: float = 52.0
## Raycast fallback if nothing is hit — larger than diagonal of a typical room.
@export var max_ray_px: float = 3200.0

@export_group("Blade silhouette")
## Very slim line instantly, then width ramps to full thickness.
@export var blade_expand_sec: float = 0.09
## Tapers from full thickness down to linger_thickness_mult.
@export var blade_shrink_sec: float = 0.6
## Stays visibly thin during this fade-out before freeing.
@export var blade_linger_sec: float = 0.13
@export var thickness_start_mult: float = 0.028
## After shrink, beam holds this proportion of collision/visual height before alpha fade.
@export var linger_thickness_mult: float = 0.11

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO

var _beam_elapsed: float = 0.0
var _tick_accum: float = 0.0
var _damage_end_t: float = 0.0
var _shrink_end_t: float = 0.0
var _total_life_t: float = 0.0

var _hit_area_scale0: Vector2 = Vector2.ONE


func setup(
		p_vel: Vector2,
		source_actor_pos: Vector2,
		beam_spawn_world: Vector2,
		dir_normalized: Vector2,
		length_px: float,
) -> void:
	player_velocity_at_hit = p_vel
	player_pos_at_hit = source_actor_pos

	var ha_snap: Area2D = $HitArea as Area2D
	if ha_snap != null:
		_hit_area_scale0 = ha_snap.scale

	var aim: Vector2 = dir_normalized
	if aim.length_squared() < 0.000001:
		aim = Vector2.RIGHT
	aim = aim.normalized()

	var len_clamped: float = clampf(length_px, 32.0, max_ray_px)
	global_position = beam_spawn_world + aim * (len_clamped * 0.5)
	rotation = aim.angle()
	scale = Vector2(len_clamped / BASE_BEAM_WIDTH, 1.0)

	var seg: Node2D = get_node_or_null("Segments") as Node2D
	if seg != null:
		seg.scale.x = 1.0

	const EXP_MIN := 1.0 / 480.0
	var exp_t := maxf(blade_expand_sec, EXP_MIN)

	_damage_end_t = exp_t + maxf(beam_duration_sec, 0.001)
	_shrink_end_t = _damage_end_t + maxf(blade_shrink_sec, 0.001)
	_total_life_t = _shrink_end_t + maxf(blade_linger_sec, 0.02)

	_beam_elapsed = 0.0
	_tick_accum = tick_interval_sec
	_refresh_visual(exp_t)


static func beam_length_through_space(
		space: PhysicsDirectSpaceState2D,
		from_world: Vector2,
		dir_normalized: Vector2,
		max_px: float,
		player_collision: CollisionObject2D,
		penetration_px: float,
) -> float:
	var dir := dir_normalized
	if dir.length_squared() < 0.000001:
		dir = Vector2.RIGHT
	dir = dir.normalized()

	var exclude: Array[RID] = []
	if player_collision != null and is_instance_valid(player_collision):
		exclude.append(player_collision.get_rid())

	var travelled: float = 0.0
	var ray_pos: Vector2 = from_world
	const EDGE_EPS: float = 0.25
	var iterations: int = 0

	while travelled < max_px - EDGE_EPS * 2.0 and iterations < 64:
		iterations += 1
		var ray_rem: float = max_px - travelled
		var pq := PhysicsRayQueryParameters2D.create(ray_pos, ray_pos + dir * ray_rem)
		pq.collision_mask = CharacterCombat.PROJECTILE_COLLISION_MASK
		pq.collide_with_areas = false
		pq.collide_with_bodies = true
		pq.exclude = exclude

		var hit: Dictionary = space.intersect_ray(pq)
		if hit.is_empty():
			travelled = max_px
			break

		var hit_pt: Vector2 = hit.position as Vector2
		var segment: float = ray_pos.distance_to(hit_pt)

		var collider: Variant = hit.get(&"collider")
		var cob: CollisionObject2D = collider as CollisionObject2D
		var ch_body: CharacterBody2D = collider as CharacterBody2D

		if cob != null and ch_body != null and ch_body.is_in_group(&"enemies"):
			var rid_enemy: RID = cob.get_rid()
			if not exclude.has(rid_enemy):
				exclude.append(rid_enemy)
			ray_pos = hit_pt + dir * EDGE_EPS
			travelled += segment + EDGE_EPS
			continue

		travelled += segment + penetration_px
		break

	return clampf(travelled, 48.0, max_px)


func _physics_process(delta: float) -> void:
	_beam_elapsed += delta
	const EXP_MIN := 1.0 / 480.0
	var exp_t := maxf(blade_expand_sec, EXP_MIN)
	if _total_life_t <= 0.0:
		_damage_end_t = exp_t + maxf(beam_duration_sec, 0.001)
		_shrink_end_t = _damage_end_t + maxf(blade_shrink_sec, 0.001)
		_total_life_t = _shrink_end_t + maxf(blade_linger_sec, 0.02)

	if _beam_elapsed >= _total_life_t:
		queue_free()
		return

	_refresh_visual(exp_t)

	if _damage_ticks_active(exp_t):
		_tick_accum += delta
		while _tick_accum >= tick_interval_sec:
			_tick_accum -= tick_interval_sec
			_apply_tick_damage()


func _damage_ticks_active(exp_t: float) -> bool:
	return _beam_elapsed >= exp_t and _beam_elapsed < _damage_end_t


func _blade_thickness(t: float, exp_t: float) -> float:
	if t <= exp_t:
		var rel: float = clampf(t / exp_t, 0.0, 1.0)
		var sharp: float = 1.0 - pow(1.0 - rel, 2.75)
		return lerpf(thickness_start_mult, 1.0, sharp)

	if t < _damage_end_t:
		return 1.0

	if t < _shrink_end_t:
		var sh: float = clampf((t - _damage_end_t) / maxf(_shrink_end_t - _damage_end_t, 1.0 / 480.0), 0.0, 1.0)
		var eased: float = sh * sh * sh
		var outv: float = lerpf(1.0, linger_thickness_mult, eased)
		return maxf(outv, linger_thickness_mult * 0.4)

	return linger_thickness_mult


func _blade_alpha(exp_t: float) -> float:
	if _beam_elapsed < _shrink_end_t:
		return 1.0

	var lf: float = clampf((_beam_elapsed - _shrink_end_t) / maxf(_total_life_t - _shrink_end_t, 0.001), 0.0, 1.0)
	return lerpf(1.0, 0.05, lf * lf)


func _refresh_visual(exp_t: float) -> void:
	var thick: float = _blade_thickness(_beam_elapsed, exp_t)
	var alpha_v: float = _blade_alpha(exp_t)
	var tint: Color = Color(1.0, 1.0, 1.0, alpha_v)

	var seg: Node2D = get_node_or_null("Segments") as Node2D
	if seg != null:
		seg.scale.y = thick
		seg.modulate = tint

	var ha: Area2D = $HitArea as Area2D
	if ha != null:
		ha.scale = Vector2(_hit_area_scale0.x, _hit_area_scale0.y * thick)


func _apply_tick_damage() -> void:
	var hit_area: Area2D = $HitArea as Area2D
	if hit_area == null:
		return

	var seen: Dictionary = {}
	for area in hit_area.get_overlapping_areas():
		var enemy: Node2D = area.get_parent() as Node2D
		if enemy == null or not enemy.is_in_group("enemies"):
			continue
		if not enemy.has_method(&"take_damage"):
			continue
		var id: int = enemy.get_instance_id()
		if seen.has(id):
			continue
		seen[id] = true
		var hit_dir: Vector2 = enemy.global_position - player_pos_at_hit
		var hit_len: float = hit_dir.length()
		if hit_len < 4.0:
			hit_dir = Vector2.RIGHT
			hit_len = 1.0
		else:
			hit_dir /= hit_len
		var mom: float = 1.0 + (player_velocity_at_hit.dot(hit_dir) / 600.0)
		mom = clampf(mom, 0.5, 1.6)
		enemy.take_damage(damage_per_tick, player_pos_at_hit, knockback_force * mom)
