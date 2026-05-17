extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 5.5
@export var damage: int = 1
@export var knockback_force: float = 650.0
## Detonate after this many distinct enemies damaged during the pierce phase.
@export var max_pierce_hits: int = 2
## If you never reach max pierce hits, detonate after traveling this far.
@export var max_travel_distance: float = 520.0
@export var aoe_radius: float = 78.0

var move_velocity: Vector2 = Vector2.ZERO
var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO

var _distance_traveled: float = 0.0
var _pierce_hits: Dictionary = {}
var _pierce_enemy_count: int = 0
var _exploded: bool = false


func setup(origin: Vector2, direction: Vector2, p_vel: Vector2) -> void:
	global_position = origin
	player_velocity_at_hit = p_vel
	player_pos_at_hit = origin
	move_velocity = direction.normalized() * speed
	rotation = move_velocity.angle()


func set_mercury_silver_style() -> void:
	var spr: Node = get_node_or_null("Sprite2D")
	if spr == null:
		return
	spr.modulate = Color(0.78, 0.86, 0.96, 1.0)
	if spr.material is ShaderMaterial:
		(spr.material as ShaderMaterial).set_shader_parameter("glow_strength", 0.72)


func _ready() -> void:
	monitoring = false
	get_tree().create_timer(lifetime, true, false, true).timeout.connect(_on_lifetime_out)


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	var seg_len: float = move_velocity.length() * delta
	if seg_len < 0.00001:
		return
	var dir: Vector2 = move_velocity / move_velocity.length()
	var pos: Vector2 = global_position
	var player: Node = get_tree().get_first_node_in_group("player")
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var exclude_rids: Array = []
	var travel_left: float = seg_len
	var safety: int = 0

	while travel_left > 0.0001 and not _exploded and safety < 48:
		safety += 1
		var pq: PhysicsRayQueryParameters2D = CharacterCombat.make_player_projectile_ray(
				pos, pos + dir * travel_left, player, exclude_rids
		)
		var hit: Dictionary = space.intersect_ray(pq)
		if hit.is_empty():
			pos += dir * travel_left
			travel_left = 0.0
			break
		var hit_pos: Vector2 = hit.position
		travel_left -= pos.distance_to(hit_pos)
		pos = hit_pos + dir * 0.35
		var col: Variant = hit.get("collider")
		if CharacterCombat.should_ignore_projectile_collision(col):
			if col is CollisionObject2D:
				exclude_rids.append((col as CollisionObject2D).get_rid())
			continue
		if CharacterCombat.collider_is_enemy_damage_target(col):
			var enemy: Node2D
			if col is Area2D:
				enemy = (col as Area2D).get_parent() as Node2D
			else:
				enemy = col as Node2D
			if enemy != null:
				var eid: int = enemy.get_instance_id()
				if not _pierce_hits.has(eid):
					_pierce_hits[eid] = true
					_pierce_enemy_count += 1
					enemy.take_damage(damage, player_pos_at_hit, knockback_force)
				exclude_rids.append(col.get_rid())
				if _pierce_enemy_count >= max_pierce_hits:
					global_position = pos
					_explode()
					return
			continue
		global_position = hit_pos
		_explode()
		return

	global_position = pos
	_distance_traveled += seg_len
	if _distance_traveled >= max_travel_distance:
		_explode()


func _on_lifetime_out() -> void:
	if not _exploded:
		_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	set_physics_process(false)

	var space := get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = aoe_radius
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.motion = Vector2.ZERO
	params.collision_mask = 2

	var hits: Array = space.intersect_shape(params, 64)
	for item in hits:
		var col: Variant = item.get("collider", null)
		if col == null or not col is Area2D:
			continue
		var enemy: Node2D = col.get_parent() as Node2D
		if enemy == null or not enemy.is_in_group("enemies") or not enemy.has_method("take_damage"):
			continue
		var eid: int = enemy.get_instance_id()
		if _pierce_hits.has(eid):
			continue
		enemy.take_damage(damage, global_position, knockback_force * 0.88)

	var spr: Node = get_node_or_null("Sprite2D")
	if spr:
		spr.hide()
	await get_tree().create_timer(0.06, true, false, true).timeout
	queue_free()
