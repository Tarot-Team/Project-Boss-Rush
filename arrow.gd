extends Area2D
## Fast arrow — one enemy per shot; same damage path as fireball (direct hit).

@export var speed: float = 1000.0
@export var damage: int = 1
@export var knockback_force: float = 520.0
@export var lifetime: float = 2.4
## Extra sprite rotation vs Area2D (flight dir). Venus overrides from player1 for Poison Arrow art.
@export var sprite_heading_offset_rad: float = 1.571

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO

var _vel: Vector2 = Vector2.ZERO
var _hit_ids: Dictionary = {}


func setup(direction: Vector2, origin: Vector2, p_vel: Vector2) -> void:
	global_position = origin
	player_pos_at_hit = origin
	player_velocity_at_hit = p_vel
	_vel = direction.normalized() * speed
	rotation = _vel.angle()
	_align_sprite_to_velocity()


func _ready() -> void:
	add_to_group("player_proj")
	monitoring = false
	get_tree().create_timer(lifetime, true, false, true).timeout.connect(queue_free)
	_align_sprite_to_velocity()


func _align_sprite_to_velocity() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	spr.rotation = .05


func apply_texture(tex: Texture2D) -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null and tex != null:
		spr.texture = tex


func _physics_process(delta: float) -> void:
	var motion: Vector2 = _vel * delta
	var player: Node = get_tree().get_first_node_in_group("player")
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var res: Dictionary = CharacterCombat.projectile_resolve_move(space, global_position, motion, player)
	global_position = res.end
	var hit: Dictionary = res.hit
	if hit.is_empty():
		return
	var col: Variant = hit.get("collider")
	if CharacterCombat.collider_is_enemy_damage_target(col):
		var enemy: Node2D
		if col is Area2D:
			enemy = (col as Area2D).get_parent() as Node2D
		else:
			enemy = col as Node2D
		if enemy != null:
			var eid: int = enemy.get_instance_id()
			if not _hit_ids.has(eid):
				_hit_ids[eid] = true
				enemy.take_damage(damage, player_pos_at_hit, knockback_force)
	queue_free()
