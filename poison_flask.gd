extends Area2D
## Lobbed flask — impact spawns poison_cloud.

const CLOUD_SCN := preload("res://poison_cloud.tscn")

@export var speed: float = 520.0
@export var arc_gravity: float = 920.0
@export var max_flight_distance: float = 560.0
@export var max_lifetime: float = 3.2

var player_velocity_at_hit: Vector2 = Vector2.ZERO
var player_pos_at_hit: Vector2 = Vector2.ZERO

var _vel: Vector2 = Vector2.ZERO
var _dist: float = 0.0
var _dead: bool = false


func setup(origin: Vector2, direction: Vector2, p_vel: Vector2) -> void:
	global_position = origin
	player_pos_at_hit = origin
	player_velocity_at_hit = p_vel
	var dir := direction.normalized()
	_vel = dir * speed + Vector2(0.0, -220.0)
	_dist = 0.0
	_dead = false


func _ready() -> void:
	add_to_group("player_proj")
	monitoring = false
	get_tree().create_timer(max_lifetime, true, false, true).timeout.connect(_timeout_land)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_vel.y += arc_gravity * delta
	var step: Vector2 = _vel * delta
	var player: Node = get_tree().get_first_node_in_group("player")
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var res: Dictionary = CharacterCombat.projectile_resolve_move(space, global_position, step, player)
	global_position = res.end
	if not res.hit.is_empty():
		_impact()
		return
	_dist += step.length()
	rotation = _vel.angle()
	if _dist >= max_flight_distance:
		_impact()


func _timeout_land() -> void:
	if _dead:
		return
	_impact()


func _impact() -> void:
	if _dead:
		return
	_dead = true
	var cloud: Node2D = CLOUD_SCN.instantiate() as Node2D
	if cloud.has_method("setup"):
		cloud.setup(player_velocity_at_hit, global_position)
	cloud.global_position = global_position
	get_parent().add_child(cloud)
	queue_free()
