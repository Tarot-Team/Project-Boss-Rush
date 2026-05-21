extends Node2D
class_name NeptuneSummonRing

const UNIT_SCN := preload("res://neptune_summon_unit.tscn")
const ORB_TEXTURES := [
	preload("res://assets/player/neptune/neptune_summons/fire orb.jpg"),
	preload("res://assets/player/neptune/neptune_summons/water orb.jpg"),
	preload("res://assets/player/neptune/neptune_summons/plant orb.jpg"),
	preload("res://assets/player/neptune/neptune_summons/void orb.jpg"),
]

var _player: CharacterBody2D
var _orbit_phase: float = 0.0

@export var orbit_radius: float = 68.0
@export var orbit_speed: float = 1.65
@export var fire_interval: float = 0.95
## Each shot picks a new delay in [fire_interval × (1 - j), fire_interval × (1 + j)] so orbs don’t sync.
@export_range(0.0, 0.55, 0.01) var shot_cooldown_jitter: float = 0.22


static func preview_texture_for_next_summon(current_summon_count: int) -> Texture2D:
	return ORB_TEXTURES[current_summon_count % ORB_TEXTURES.size()] as Texture2D


func setup_follow_target(player: CharacterBody2D) -> void:
	_player = player


func add_summon() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var u: NeptuneSummonUnit = UNIT_SCN.instantiate() as NeptuneSummonUnit
	var idx: int = get_child_count()
	var tex: Texture2D = ORB_TEXTURES[idx % ORB_TEXTURES.size()] as Texture2D
	u.configure(_player, tex, fire_interval, shot_cooldown_jitter)
	add_child(u)
	_respread_slots()


func _respread_slots() -> void:
	var n: int = get_child_count()
	if n < 1:
		return
	for i in range(n):
		var u: NeptuneSummonUnit = get_child(i) as NeptuneSummonUnit
		if u != null:
			u.base_angle = TAU * float(i) / float(n)


func _physics_process(delta: float) -> void:
	_orbit_phase += orbit_speed * delta
	var r: float = orbit_radius
	for i in range(get_child_count()):
		var u: NeptuneSummonUnit = get_child(i) as NeptuneSummonUnit
		if u == null:
			continue
		var ang: float = u.base_angle + _orbit_phase
		u.position = Vector2(cos(ang), sin(ang)) * r
