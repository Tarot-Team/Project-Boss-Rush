extends Area2D

@export var speed: float = 540.0
@export var damage: int = 1
@export var knockback_force: float = 480.0
@export var lifetime: float = 1.8

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO

var _vel: Vector2 = Vector2.ZERO
var _hit: bool = false


func setup(direction: Vector2, origin: Vector2, p_vel: Vector2, projectile_texture: Texture2D = null) -> void:
	global_position = origin
	player_pos_at_hit = origin
	player_velocity_at_hit = p_vel
	_vel = direction.normalized() * speed
	rotation = _vel.angle()
	if projectile_texture != null:
		var spr := get_node_or_null("Sprite2D") as Sprite2D
		if spr != null:
			spr.texture = projectile_texture


func _ready() -> void:
	add_to_group("player_proj")
	## Motion uses physics raycasts so thin walls/obstacles aren’t tunnelled through.
	monitoring = false
	get_tree().create_timer(lifetime, true, false, true).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	if _hit:
		return
	var motion: Vector2 = _vel * delta
	var player: Node = get_tree().get_first_node_in_group("player")
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var res: Dictionary = CharacterCombat.projectile_resolve_move(space, global_position, motion, player)
	global_position = res.end
	var hit: Dictionary = res.hit
	if hit.is_empty():
		return
	var col: Variant = hit.get("collider")
	if CharacterCombat.collider_is_enemy_damage_target(col) and not _hit:
		_hit = true
		var enemy: Node2D
		if col is Area2D:
			enemy = (col as Area2D).get_parent() as Node2D
		else:
			enemy = col as Node2D
		if enemy != null:
			enemy.take_damage(damage, player_pos_at_hit, knockback_force)
	queue_free()
