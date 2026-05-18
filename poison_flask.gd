extends Area2D
## Lobbed flask — impact spawns poison_cloud.

const CLOUD_SCN: PackedScene = preload("res://poison_cloud.tscn")

## Straight-ish toss toward cursor (top‑down plane). Loft is purely screen-space, not ballistic gravity.
@export var toss_speed_px: float = 480.0
@export var flight_time_min: float = 0.2
@export var flight_time_max: float = 0.62

## Clamp landing distance from spawn: `≥ min` after aim, then `≤ max` if enabled.
@export var min_throw_range_px: float = 112.0
@export var max_throw_range_px: float = 448.0

## Arc height peaks at ~`planar_distance * loft_height_scale` — short tosses stay low.
@export var loft_height_scale: float = 0.138
## Floor arc height after scaling (pixels); usually leave 0 so short throws flatten.
@export var loft_min_px: float = 0.0
@export var loft_cap_px: float = 72.0

## Smallest sprite scale multiplier at midpoint (looks like it’s farther / “above” the ground plane).
@export var scale_at_midpoint: float = 0.76

@export var landing_spread_px: float = 18.0
## Stops wedge-case infinite flight. `0 =` auto (`planar` + fudge for sideways arc).
@export var max_flight_distance: float = 0.0
@export var max_lifetime: float = 3.2

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO

var _spawn: Vector2 = Vector2.ZERO
var _land: Vector2 = Vector2.ZERO
var _planar_delta: Vector2 = Vector2.ZERO
var _planar_length: float = 0.0
var _flight_time: float = 1.0
var _elapsed: float = 0.0
var _loft_this_toss: float = 0.0
var _travel_fuse_px: float = 1200.0

var _dist: float = 0.0
var _dead: bool = false

var _sprite: Sprite2D
var _sprite_base_scale: Vector2 = Vector2.ONE


func setup(origin: Vector2, target: Vector2, p_vel: Vector2, planar_aim: Vector2) -> void:
	global_position = origin
	player_pos_at_hit = origin
	player_velocity_at_hit = p_vel
	_spawn = origin
	var j: float = landing_spread_px
	var aim: Vector2 = target + Vector2(randf_range(-j, j), randf_range(-j, j))
	var to_aim: Vector2 = aim - _spawn
	var dist_natural: float = to_aim.length()
	var aim_dir := planar_aim
	if aim_dir.length_squared() < 0.000001:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()

	var dir: Vector2 = aim_dir
	if dist_natural > 14.0:
		dir = to_aim / dist_natural

	var dist_used: float = dist_natural
	if min_throw_range_px > 0.0:
		dist_used = maxf(dist_used, min_throw_range_px)
	if max_throw_range_px > 0.0:
		dist_used = minf(dist_used, max_throw_range_px)

	_planar_delta = dir * dist_used
	_land = _spawn + _planar_delta

	_planar_length = dist_used
	_loft_this_toss = clampf(_planar_length * loft_height_scale, loft_min_px, loft_cap_px)

	if _planar_length > 0.001:
		_flight_time = clampf(_planar_length / toss_speed_px, flight_time_min, flight_time_max)
	else:
		_flight_time = flight_time_min

	if max_flight_distance > 0.0:
		_travel_fuse_px = max_flight_distance
	else:
		var travel_base: float = _planar_length * 3.14 + _loft_this_toss * 5.5
		if max_throw_range_px > 0.0:
			_travel_fuse_px = maxf(max_throw_range_px * 3.14, travel_base)
		else:
			_travel_fuse_px = travel_base

	_elapsed = 0.0
	_dist = 0.0
	_dead = false


func _ready() -> void:
	_sprite = $Sprite2D as Sprite2D
	if _sprite:
		_sprite_base_scale = _sprite.scale

	add_to_group("player_proj")
	monitoring = false
	get_tree().create_timer(max_lifetime, true, false, true).timeout.connect(_timeout_land)


func _loft_offset(u: float) -> Vector2:
	u = clampf(u, 0.0, 1.0)
	var w: float = sin(PI * u)
	return Vector2(0.0, -1.0) * (_loft_this_toss * w)


func _desired_position(u: float) -> Vector2:
	u = clampf(u, 0.0, 1.0)
	return _spawn.lerp(_land, u) + _loft_offset(u)


func _apply_flight_visuals(u: float) -> void:
	if _sprite == null:
		return
	u = clampf(u, 0.0, 1.0)
	var squash: float = abs(cos(PI * u))
	var r: float = lerpf(scale_at_midpoint, 1.0, squash)
	_sprite.scale = _sprite_base_scale * r


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_elapsed += delta
	var u_after: float = clampf(_elapsed / _flight_time, 0.0, 1.0)

	var desired: Vector2 = _desired_position(u_after)
	var step: Vector2 = desired - global_position

	_apply_flight_visuals(u_after)

	if step.length_squared() > 9.0:
		rotation = step.angle()

	var player: Node = get_tree().get_first_node_in_group("player")
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var res: Dictionary = CharacterCombat.projectile_resolve_move(space, global_position, step, player)
	global_position = res["end"] as Vector2
	var hit: Dictionary = res.get("hit", {}) as Dictionary
	if not hit.is_empty():
		_impact()
		return

	_dist += step.length()

	if (
			max_throw_range_px > 0.0
			and global_position.distance_to(_spawn) > max_throw_range_px + _loft_this_toss + 32.0
	):
		_impact()
		return

	if _dist > _travel_fuse_px:
		_impact()
		return

	if u_after >= 1.0:
		global_position = _desired_position(1.0)
		if _sprite:
			_sprite.scale = _sprite_base_scale
		_impact()


func _timeout_land() -> void:
	if _dead:
		return
	_impact()


func _impact() -> void:
	if _dead:
		return
	_dead = true
	var node: Node = CLOUD_SCN.instantiate()
	var cloud: Node2D = node as Node2D
	if cloud.has_method("setup"):
		cloud.setup(player_velocity_at_hit, global_position)
	cloud.global_position = global_position
	get_parent().add_child(cloud)
	queue_free()
