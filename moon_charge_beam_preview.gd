extends Node2D
class_name MoonChargeBeamPreview
## Steerable charge guide: same Line2D + fixed spark layout as player1’s static preview, length from wall ray each tick.

const MOON_BEAM_MAX_RAY: float = 3200.0
const MOON_WALL_BLEED_PX: float = 52.0
const SPARK_FRACS: Array[float] = [0.07, 0.2, 0.36, 0.52, 0.68, 0.84, 0.95]

var _player: CharacterBody2D
var emit_px: float = 58.0
var line_width: float = 2.2
var line_color: Color = Color(0.74, 0.94, 1.0, 0.2)

var _guide: Line2D
var _sparks: Array[CPUParticles2D] = []

var _aim: Vector2 = Vector2.RIGHT
var _beam_spawn: Vector2 = Vector2.ZERO
var _beam_len: float = 320.0


func activate(
		player: CharacterBody2D,
		emit_offset_px: float,
		guide_width: float,
		guide_color: Color,
) -> void:
	_player = player
	emit_px = emit_offset_px
	line_width = guide_width
	line_color = guide_color
	z_index = 18
	z_as_relative = true

	_guide = Line2D.new()
	_guide.width = line_width
	_guide.default_color = line_color
	_guide.antialiased = true
	_guide.joint_mode = Line2D.LINE_JOINT_ROUND
	_guide.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_guide.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_guide)

	var spark_tint: Color = line_color
	spark_tint.a = minf(1.0, spark_tint.a * 2.4)
	for _f in SPARK_FRACS:
		var spk := _make_spark_burst(spark_tint)
		add_child(spk)
		_sparks.append(spk)

	set_physics_process(true)
	_update_ray()


func _make_spark_burst(spark_color: Color) -> CPUParticles2D:
	var spk := CPUParticles2D.new()
	spk.emitting = true
	spk.amount = 9
	spk.lifetime = 0.36
	spk.explosiveness = 0.1
	spk.randomness = 0.55
	spk.lifetime_randomness = 0.5
	spk.direction = Vector2(0.0, -1.0)
	spk.spread = 175.0
	spk.initial_velocity_min = 14.0
	spk.initial_velocity_max = 52.0
	spk.gravity = Vector2.ZERO
	spk.scale_amount_min = 1.1
	spk.scale_amount_max = 2.9
	spk.color = spark_color
	return spk


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_update_ray()


func _layout_along_beam(bl: float) -> void:
	if _guide != null:
		var len_clamped: float = maxf(bl, 4.0)
		_guide.points = PackedVector2Array([Vector2.ZERO, Vector2(len_clamped, 0.0)])
	var i := 0
	var n_frac: int = SPARK_FRACS.size()
	while i < _sparks.size() and i < n_frac:
		var frac: float = SPARK_FRACS[i]
		_sparks[i].position = Vector2(maxf(bl, 4.0) * frac, 0.0)
		i += 1


func _update_ray() -> void:
	var mouse_gp: Vector2 = get_global_mouse_position()
	var raw: Vector2 = mouse_gp - _player.global_position
	if raw.length_squared() < 4.0:
		raw = Vector2.RIGHT if _player.flipped else Vector2.LEFT
	else:
		raw = raw.normalized()

	_aim = raw
	_player.flipped = _aim.x < 0.0
	var spr: AnimatedSprite2D = _player.get_node_or_null(^"AnimatedSprite2D") as AnimatedSprite2D
	if spr != null:
		spr.flip_h = _player.flipped

	_beam_spawn = _player.global_position + _aim * emit_px
	var space_ss: PhysicsDirectSpaceState2D = _player.get_world_2d().direct_space_state
	_beam_len = MoonLaser.beam_length_through_space(
			space_ss, _beam_spawn, _aim, MOON_BEAM_MAX_RAY, _player, MOON_WALL_BLEED_PX
	)

	position = _aim * emit_px
	rotation = _aim.angle()

	_layout_along_beam(_beam_len)


func get_fire_snapshot() -> Dictionary:
	return {&"aim": _aim, &"beam_spawn": _beam_spawn, &"beam_len": _beam_len}


func capture_fire_snapshot() -> Dictionary:
	_update_ray()
	return get_fire_snapshot()