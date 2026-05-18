class_name CharacterCombat
extends RefCounted

const TEX_SLASH := "res://assets/attacks/Slash.png"
const TEX_WATER := "res://assets/attacks/Water Slash.png"
const TEX_FIRE := "res://assets/attacks/Fire Slash.png"
const TEX_LIGHT := "res://assets/attacks/Light Slash.png"
const TEX_UNDEAD := "res://assets/attacks/Undead Slash.png"
const TEX_POISON_ARROW := "res://assets/attacks/Poison Arrow.png"
const TEX_POISON_FLASK := "res://assets/attacks/Poison Flask.png"

## Baked into the slash PNGs; added on top of aim (-90°) so swings read square to the stroke.
const SLASH_WORLD_ROTATION_OFFSET := 1.1

## Room TileMap physics uses collision_layer = 7 (layers 1–3); enemy Hitbox Area2D uses layer 2.
## Player projectiles need this mask so `body_entered` hits walls and `area_entered` still hits enemies.
const PROJECTILE_COLLISION_MASK := 7


static func id() -> String:
	if not Global.player_class.has("id"):
		return "mars"
	return String(Global.player_class["id"])


static func load_tex(path: String) -> Texture2D:
	return load(path) as Texture2D


static func make_player_projectile_ray(from: Vector2, to: Vector2, player: Node, extra_exclude_rids: Array = []) -> PhysicsRayQueryParameters2D:
	var pq := PhysicsRayQueryParameters2D.create(from, to)
	pq.collision_mask = PROJECTILE_COLLISION_MASK
	pq.collide_with_areas = true
	pq.collide_with_bodies = true
	var ex: Array = []
	if player != null:
		ex.append(player.get_rid())
	for r in extra_exclude_rids:
		ex.append(r)
	pq.exclude = ex
	return pq


static func collider_is_enemy_damage_target(col: Object) -> bool:
	if col is Area2D:
		var par: Node2D = (col as Area2D).get_parent() as Node2D
		return par != null and par.is_in_group("enemies") and par.has_method("take_damage")
	if col is CharacterBody2D:
		var bod: CharacterBody2D = col as CharacterBody2D
		return bod.is_in_group("enemies") and bod.has_method("take_damage")
	return false


static func should_ignore_projectile_collision(col: Object) -> bool:
	if col is InteractionArea:
		return true
	## AoE overlays (poison cloud, etc.) must not intercept player projectile rays / movement sweeps.
	if col is CollisionObject2D and (col as CollisionObject2D).is_in_group(&"aoe_pass_projectiles"):
		return true
	return false


static func collider_belongs_to_enemy(col: Object, enemy: Node2D) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if col is Area2D:
		return (col as Area2D).get_parent() == enemy
	if col is CharacterBody2D:
		return col as Node == enemy
	return false


## Move along `motion`; first blocking hit skips InteractionArea (door/item triggers).
## Returns `{ "end": Vector2, "hit": Dictionary }` with `hit` empty if the full segment was free.
static func projectile_resolve_move(
		space: PhysicsDirectSpaceState2D,
		from: Vector2,
		motion: Vector2,
		player: Node,
		extra_exclude_rids: Array = [],
) -> Dictionary:
	var dist_total: float = motion.length()
	if dist_total < 0.00001:
		return {"end": from, "hit": {}}
	var dir: Vector2 = motion / dist_total
	var from_cur: Vector2 = from
	var rem: float = dist_total
	var ex: Array = []
	if player != null:
		ex.append(player.get_rid())
	for r in extra_exclude_rids:
		ex.append(r)
	var iters: int = 0
	while rem > 0.0001 and iters < 28:
		iters += 1
		var pq := PhysicsRayQueryParameters2D.create(from_cur, from_cur + dir * rem)
		pq.collision_mask = PROJECTILE_COLLISION_MASK
		pq.collide_with_areas = true
		pq.collide_with_bodies = true
		pq.exclude = ex
		var hit: Dictionary = space.intersect_ray(pq)
		if hit.is_empty():
			return {"end": from_cur + dir * rem, "hit": {}}
		var col: Variant = hit.get("collider")
		if should_ignore_projectile_collision(col):
			var hp: Vector2 = hit.position
			rem -= from_cur.distance_to(hp)
			from_cur = hp + dir * 0.12
			if col is CollisionObject2D:
				ex.append((col as CollisionObject2D).get_rid())
			continue
		return {"end": hit.position, "hit": hit}
	return {"end": from_cur, "hit": {}}


## Summons / similar — true if a projectile ray from `from` reaches `target_enemy` before any wall or other mob.
static func has_clear_projectile_line_to_enemy(
		space: PhysicsDirectSpaceState2D,
		from: Vector2,
		target_enemy: Node2D,
		player: Node,
) -> bool:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return false
	var motion: Vector2 = target_enemy.global_position - from
	var d2: float = motion.length_squared()
	if d2 < 4.0:
		return true
	var dist_total: float = sqrt(d2)
	var dir: Vector2 = motion / dist_total
	var from_cur: Vector2 = from
	var rem: float = dist_total
	var ex: Array = []
	if player != null:
		ex.append(player.get_rid())
	var iters: int = 0
	while rem > 0.0001 and iters < 32:
		iters += 1
		var pq := PhysicsRayQueryParameters2D.create(from_cur, from_cur + dir * rem)
		pq.collision_mask = PROJECTILE_COLLISION_MASK
		pq.collide_with_areas = true
		pq.collide_with_bodies = true
		pq.exclude = ex
		var hit: Dictionary = space.intersect_ray(pq)
		if hit.is_empty():
			return true
		var col: Variant = hit.get("collider")
		if should_ignore_projectile_collision(col):
			var hp: Vector2 = hit.position
			rem -= from_cur.distance_to(hp)
			from_cur = hp + dir * 0.12
			if col is CollisionObject2D:
				ex.append((col as CollisionObject2D).get_rid())
			continue
		if collider_is_enemy_damage_target(col) and collider_belongs_to_enemy(col, target_enemy):
			return true
		return false
	return true
