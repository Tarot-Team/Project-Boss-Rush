extends Node2D
class_name NeptuneSummonUnit

const BOLT := preload("res://water_bolt.tscn")

## Set by NeptuneSummonRing so the whole formation stays equidistant as count changes.
var base_angle: float = 0.0

var _player: CharacterBody2D
var _cooldown: float = 0.0
var _orb_texture: Texture2D
var _fire_interval: float = 0.95
var _shot_jitter: float = 0.0


func configure(player: CharacterBody2D, orb_texture: Texture2D, interval: float, shot_jitter: float = 0.0) -> void:
	_player = player
	_orb_texture = orb_texture
	_fire_interval = maxf(0.05, interval)
	_shot_jitter = clampf(shot_jitter, 0.0, 0.75)
	var spr := get_node_or_null("OrbSprite") as Sprite2D
	if spr != null and orb_texture != null:
		spr.texture = orb_texture
	_cooldown = randf() * _roll_shot_delay() * 0.55


func _ready() -> void:
	z_as_relative = false
	z_index = 1


func _physics_process(delta: float) -> void:
	var p := _player
	if p == null or not is_instance_valid(p):
		return
	if p.has_method("set_abilities_enabled") and not p.abilities_enabled:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var orb_pos: Vector2 = global_position
	var tgt: Vector2 = _nearest_enemy_pos(orb_pos, p)
	if tgt.x > 999990.0:
		return
	_cooldown = _roll_shot_delay()
	_fire(p, tgt)


func _roll_shot_delay() -> float:
	var t: float = _fire_interval
	if _shot_jitter <= 0.0001:
		return t
	return t * randf_range(maxf(0.05, 1.0 - _shot_jitter), 1.0 + _shot_jitter)


func _nearest_enemy_pos(orb_pos: Vector2, player: CharacterBody2D) -> Vector2:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var best_d := 999999.0
	var found: bool = false
	var best: Vector2 = Vector2.ZERO
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node2D and n is CharacterBody2D:
			var en: Node2D = n as Node2D
			if not _is_valid_summon_target(en):
				continue
			if not CharacterCombat.has_clear_projectile_line_to_enemy(space, orb_pos, en, player):
				continue
			var d: float = orb_pos.distance_squared_to(en.global_position)
			if d < best_d:
				best_d = d
				best = en.global_position
				found = true
	if not found:
		return Vector2(999999.0, 999999.0)
	return best


func _is_valid_summon_target(enemy: Node2D) -> bool:
	var p := _player
	if p == null:
		return false
	var main := p.get_parent()
	if main == null:
		return true
	var lm: Node = main.get_node_or_null("LevelManager")
	if lm == null:
		return true
	var room_container: Node = lm.get_node_or_null("RoomContainer")
	if room_container == null or not room_container.is_ancestor_of(enemy):
		return true
	var room_inst: Node2D = _room_instance_that_owns(enemy)
	if room_inst == null:
		return false
	var active: Node = lm.get_active_room() if lm.has_method("get_active_room") else lm.get("current_room_node")
	if active == null:
		return false
	return room_inst == active


func _room_instance_that_owns(desc: Node) -> Node2D:
	var cur: Node = desc
	while cur != null:
		var par: Node = cur.get_parent()
		if par == null:
			return null
		var gp: Node = par.get_parent()
		if gp != null and String(gp.name) == "RoomContainer":
			return par as Node2D
		cur = par
	return null


func _fire(player: Node2D, target: Vector2) -> void:
	var start: Vector2 = to_global(Vector2.ZERO)
	var dir: Vector2 = (target - start).normalized()
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT
	var bolt := BOLT.instantiate() as Area2D
	bolt.setup(dir, start, player.velocity, _orb_texture)
	var world := player.get_parent()
	if world:
		world.add_child(bolt)
