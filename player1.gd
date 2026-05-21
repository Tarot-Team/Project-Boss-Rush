extends CharacterBody2D
class_name Player

signal health_changed(max_health, health)
signal died

@export var max_speed: int = 450
@export var acceleration: int = 2500
@export var friction: int = 2500
@export var recoil_from_mob: int = 600

@export var max_health: int = 5
@export var attack_swing_scene: PackedScene
@export var fireball_scene: PackedScene = preload("res://fireball.tscn")
## Secondary Moon beam scene (also default-preloaded — assign in Inspector if overridden).
@export var moon_laser_scene: PackedScene = preload("res://moon_laser.tscn")
## Beam origin along aim, in pixels from the player root (clears the torso so the slash reads).
@export var moon_laser_emit_offset_px: float = 58.0
## Faint guide + sparklets during Moon charge (see `_moon_spawn_charge_preview`).
@export var moon_charge_preview_line_width: float = 2.2
@export var moon_charge_preview_line_color: Color = Color(0.74, 0.94, 1.0, 0.2)
@export var iFrame_duration: float = 0.2
@export var swing_cooldown: float = 0.45
@export var iFrame_duration: float = 0.2 # Time in seconds
@export var swing_cooldown: float = 0.5
@export var original_speed: int = 300
@export var lunge_distance: int = 5
@export var original_health: int = 5

const ARROW_SCN := preload("res://arrow.tscn")
const POISON_FLASK_SCN := preload("res://poison_flask.tscn")
const NEPTUNE_RING_SCN := preload("res://neptune_summon_ring.tscn")

const DODGE_DURATION: float = 0.24
const DODGE_COOLDOWN_TIME: float = 1.15
const DODGE_SPEED_MULT: float = 3.2

var original_speed: int = 400
var health: int
var is_invincible: bool = false
var screen_size: Vector2
var flipped: bool = true
var on_swing_cooldown: bool = false
var attacking: bool = false

var last_move_dir: Vector2 = Vector2.LEFT

var is_dodging: bool = false
var dodge_time_left: float = 0.0
var dodge_direction: Vector2 = Vector2.RIGHT
var dodge_cooldown_left: float = 0.0

var secondary_cooldown_left: float = 0.0
var secondary_cooldown_total: float = 1.5

var hud: Node = null

## False during "Get Ready" / start countdown so RMB/LMB/shift don't fire abilities early.
var abilities_enabled: bool = false

## Moon beam secondary: suppress other attacks during windup/beam/recovery.
var _moon_beam_channeling: bool = false

## Top-level: follows the player at scale 1 so orbit visuals aren't crushed by Player1.scale.
var _companion_anchor: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D


func set_abilities_enabled(enabled: bool) -> void:
	abilities_enabled = enabled


func set_body_collision_enabled(enabled: bool) -> void:
	body_collision.disabled = not enabled


func _cleanup_legacy_companion_nodes() -> void:
	## Pre-anchor builds parented companions under the player root; strip so we don't double-spawn.
	for nm: String in ["NeptuneOrb", "MoonSummonController"]:
		var n: Node = get_node_or_null(nm)
		if n != null:
			n.queue_free()


func _ensure_companion_anchor() -> void:
	if _companion_anchor != null and is_instance_valid(_companion_anchor):
		return
	_cleanup_legacy_companion_nodes()
	_companion_anchor = Node2D.new()
	_companion_anchor.name = "CompanionAnchor"
	add_child(_companion_anchor)
	_companion_anchor.set_as_top_level(true)
	_companion_anchor.z_as_relative = false
	_companion_anchor.z_index = 6
	_companion_anchor.visible = visible
	_companion_anchor.global_position = global_position


func setup_hud(layer: Node) -> void:
	hud = layer
	refresh_secondary_hud_icon()


func refresh_secondary_hud_icon() -> void:
	if hud == null or not hud.has_method("configure_secondary_ability"):
		return
	var sid: String = AbilityKit.normalize_ability_id(Global.active_secondary_ability())
	if sid == CharacterData.ABILITY_NEPTUNE_SURGE:
		var n_summ: int = _neptune_summon_count()
		var preview: Texture2D = NeptuneSummonRing.preview_texture_for_next_summon(n_summ)
		hud.configure_secondary_ability(sid, preview)
	else:
		hud.configure_secondary_ability(sid)


var speed 
var health
var is_invincible = false
var screen_size
var flipped = true
var on_swing_cooldown = false
var attacking = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_health = original_health
	health = max_health
	speed = original_speed
	#hide()
	screen_size = get_viewport_rect().size
	_ensure_companion_anchor()
	apply_character_visuals_from_global()
	call_deferred("_sync_companion_nodes")


func refresh_ability_loadout() -> void:
	if Global.player_class.has("stats"):
		apply_class_stats(Global.player_class["stats"])
	else:
		swing_cooldown = AbilityKit.attack_cooldown(AbilityKit.normalize_ability_id(Global.active_primary_ability()))
		secondary_cooldown_total = AbilityKit.secondary_cooldown(AbilityKit.normalize_ability_id(Global.active_secondary_ability()))
		_sync_companion_nodes()
	refresh_secondary_hud_icon()
	if hud and hud.has_method("configure_ability_pips"):
		hud.configure_ability_pips(has_ability(CharacterData.ABILITY_DODGE), true)


func _sync_companion_nodes() -> void:
	_ensure_companion_anchor()
	var sec: String = AbilityKit.normalize_ability_id(Global.active_secondary_ability())
	var ring: Node = _companion_anchor.get_node_or_null("NeptuneSummonRing")

	if AbilityKit.secondary_requires_neptune_orb(sec):
		pass
	elif ring != null:
		ring.queue_free()


func _neptune_summon_count() -> int:
	if _companion_anchor == null or not is_instance_valid(_companion_anchor):
		return 0
	var r: Node = _companion_anchor.get_node_or_null("NeptuneSummonRing")
	if r == null:
		return 0
	return r.get_child_count()


func _ensure_neptune_summon_ring() -> NeptuneSummonRing:
	_ensure_companion_anchor()
	var ring: NeptuneSummonRing = _companion_anchor.get_node_or_null("NeptuneSummonRing") as NeptuneSummonRing
	if ring != null:
		return ring
	var inst: NeptuneSummonRing = NEPTUNE_RING_SCN.instantiate() as NeptuneSummonRing
	inst.setup_follow_target(self)
	inst.name = "NeptuneSummonRing"
	_companion_anchor.add_child(inst)
	return inst


func apply_character_visuals_from_global() -> void:
	if not Global.player_class.has("id"):
		return
	var cid: String = Global.player_class["id"]
	var frames := PlayerAnimationLoader.build_sprite_frames_for_character(cid)
	if frames != null:
		animated_sprite.sprite_frames = frames


func apply_class_stats(stats: Dictionary) -> void:
	original_health = int(stats.get("health", 5))
	max_health = original_health
	health = max_health

	max_speed = int(stats.get("speed", 450))
	original_speed = max_speed
	speed = max_speed

	lunge_distance = int(stats.get("lunge", 300))

	swing_cooldown = AbilityKit.attack_cooldown(AbilityKit.normalize_ability_id(Global.active_primary_ability()))
	secondary_cooldown_total = AbilityKit.secondary_cooldown(AbilityKit.normalize_ability_id(Global.active_secondary_ability()))

	
	speed = original_speed
	
	lunge_distance = stats.get("lunge", 300)
	
	# We also emit the health changed signal so the HUD updates immediately
	health_changed.emit(max_health, health)
	_sync_companion_nodes()
	refresh_secondary_hud_icon()
	## After loadout resolves, rebuild SpriteFrames (Moon beam animations, ordered attacks, etc.).
	apply_character_visuals_from_global()


func has_ability(ability_id: String) -> bool:
	if Global.player_class.is_empty():
		return ability_id == CharacterData.ABILITY_DODGE
	var list: Array = Global.player_class.get("abilities", [])
	return ability_id in list


func _physics_process(delta: float) -> void:
	if _companion_anchor != null and is_instance_valid(_companion_anchor):
		_companion_anchor.visible = visible
		if visible:
			_companion_anchor.global_position = global_position

	_update_cooldowns(delta)
	_update_hud_cooldowns()

	if is_dodging:
		_process_dodge(delta)
		return

	if attacking:
		return

	if _moon_beam_channeling:
	if attacking: return
	# Grab Inputs
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()
	
	# Apply Acceleration and Friction
	if input_direction != Vector2.ZERO:
		# Approach max speed by acceleration
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta * 2)
		
		# Animation Stuff
		if not attacking:
			$AnimatedSprite2D.play("run")
		flipped = input_direction.x < 0
		$AnimatedSprite2D.flip_h = flipped
	else:
		# Decelerate
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		var input_direction := Vector2(
				Input.get_axis("move_left", "move_right"),
				Input.get_axis("move_up", "move_down")
		)
		if input_direction.length_squared() > 0.01:
			input_direction = input_direction.normalized()
			last_move_dir = input_direction
			flipped = input_direction.x < 0
			animated_sprite.flip_h = flipped

		if Input.is_action_just_pressed("dodge") and abilities_enabled and has_ability(CharacterData.ABILITY_DODGE):
			try_start_dodge()

		if Input.is_action_pressed("fireball") and abilities_enabled:
			try_secondary_attack()

		if Input.is_action_pressed("attack_swing") and abilities_enabled:
			try_primary_attack()

		if not _moon_beam_channeling:
			if input_direction != Vector2.ZERO:
				velocity = velocity.move_toward(input_direction * max_speed, acceleration * delta * 2.0)
				animated_sprite.play(&"run")
			else:
				velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
				animated_sprite.play(&"idle")

			var spd_scale: float = clampf(
					velocity.length() / float(max(1, max_speed)) * 1.2, 0.35, 2.0
			)
			if animated_sprite.animation == &"run":
				animated_sprite.speed_scale = spd_scale
			else:
				animated_sprite.speed_scale = 1.0

	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider.is_in_group("enemies") and not is_dodge_active_invuln():
			take_damage(1)
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("enemies") :
			take_damage(1) # handles the invincibility automatically
			bounce_player(collision.get_normal())


func is_dodge_active_invuln() -> bool:
	return is_dodging


func _update_cooldowns(delta: float) -> void:
	if dodge_cooldown_left > 0.0:
		dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
	if secondary_cooldown_left > 0.0:
		secondary_cooldown_left = maxf(0.0, secondary_cooldown_left - delta)


func _update_hud_cooldowns() -> void:
	if hud == null or not hud.has_method("set_ability_cooldowns"):
		return
	hud.set_ability_cooldowns(
		dodge_cooldown_left, DODGE_COOLDOWN_TIME,
		secondary_cooldown_left, secondary_cooldown_total
	)


func try_primary_attack() -> void:
	if _moon_beam_channeling:
		return
	if on_swing_cooldown or is_dodging:
		return
	match AbilityKit.normalize_ability_id(Global.active_primary_ability()):
		CharacterData.ABILITY_ARROW_POISON:
			_fire_arrow()
		_:
			_spawn_slash(AbilityKit.melee_slash_texture(AbilityKit.normalize_ability_id(Global.active_primary_ability())))

	on_swing_cooldown = true
	await get_tree().create_timer(swing_cooldown).timeout
	on_swing_cooldown = false


func _fire_arrow() -> void:
	var dir := get_global_mouse_position() - global_position
	if dir.length_squared() < 4.0:
		dir = Vector2.RIGHT if not flipped else Vector2.LEFT
	dir = dir.normalized()
	flipped = dir.x < 0
	animated_sprite.flip_h = flipped
	var arr: Area2D = ARROW_SCN.instantiate() as Area2D
	if arr.has_method("apply_texture"):
		arr.apply_texture(CharacterCombat.load_tex(CharacterCombat.TEX_POISON_ARROW))
	arr.sprite_heading_offset_rad = PI * 0.5
	arr.setup(dir, global_position + dir * 22.0, velocity)
	get_parent().add_child(arr)


func _spawn_slash(tex: Texture2D, slash_vis: float = 1.0, hit_vis: float = 1.0, dmg: int = 1, knock: float = 950.0, swing_len: float = 0.15) -> void:
	if attack_swing_scene == null:
		return
	var swing: Area2D = attack_swing_scene.instantiate() as Area2D
	swing.slash_texture = tex
	swing.slash_scale_mult = slash_vis
	swing.hitbox_scale_mult = hit_vis
	swing.damage = dmg
	swing.knockback_force = knock
	swing.swing_length = swing_len
	if swing.has_method("set_player_info"):
		swing.set_player_info(velocity, global_position)

	var lunge_dir := get_global_mouse_position() - global_position
	var dir := lunge_dir.normalized()
	if lunge_dir.length_squared() > 0.0001:
		velocity += dir * 280.0
		if absf(lunge_dir.x) > 0.01:
			flipped = lunge_dir.x < 0
			animated_sprite.flip_h = flipped
		velocity += dir * float(lunge_distance)

	add_child(swing)
	swing.global_position = global_position
	var mouse_pos := get_global_mouse_position()
	var direction := (mouse_pos - global_position).normalized()
	swing.rotation = direction.angle() + deg_to_rad(-90.0) + CharacterCombat.SLASH_WORLD_ROTATION_OFFSET
	swing.global_position += direction * 64.0


func try_secondary_attack() -> void:
	if secondary_cooldown_left > 0.0 or is_dodging:
		return
	if _moon_beam_channeling:
		return
	match AbilityKit.normalize_ability_id(Global.active_secondary_ability()):
		CharacterData.ABILITY_POISON_FLASK:
			var flask: Area2D = POISON_FLASK_SCN.instantiate() as Area2D
			var m := get_global_mouse_position()
			var d := m - global_position
			if d.length_squared() < 4.0:
				d = Vector2.RIGHT if not flipped else Vector2.LEFT
			d = d.normalized()
			flipped = d.x < 0
			animated_sprite.flip_h = flipped
			var toss_origin := global_position + d * 26.0
			flask.setup(toss_origin, m, velocity, d)
			get_parent().add_child(flask)
			secondary_cooldown_left = secondary_cooldown_total
		CharacterData.ABILITY_FIRE_SLASH:
			_spawn_slash(
					CharacterCombat.load_tex(CharacterCombat.TEX_FIRE),
					1.45, 1.35, 2, 1250.0, 0.22
			)
			secondary_cooldown_left = secondary_cooldown_total
		CharacterData.ABILITY_COMET:
			if fireball_scene == null:
				return
			var fb: Area2D = fireball_scene.instantiate() as Area2D
			var m2 := get_global_mouse_position()
			var d2 := m2 - global_position
			if d2.length_squared() < 4.0:
				d2 = Vector2.RIGHT if not flipped else Vector2.LEFT
			d2 = d2.normalized()
			fb.setup(global_position + d2 * 28.0, d2, velocity)
			if fb.has_method("set_mercury_silver_style"):
				fb.call("set_mercury_silver_style")
			get_parent().add_child(fb)
			secondary_cooldown_left = secondary_cooldown_total
		CharacterData.ABILITY_NEPTUNE_SURGE:
			var ring_n: NeptuneSummonRing = _ensure_neptune_summon_ring()
			ring_n.add_summon()
			secondary_cooldown_left = secondary_cooldown_total
			refresh_secondary_hud_icon()
		CharacterData.ABILITY_MOON_LASER:
			secondary_cooldown_left = secondary_cooldown_total
			await _moon_laser_cast_sequence()
		_:
			pass


func _moon_sprite_anim_playback_secs(sprite: AnimatedSprite2D, anim: StringName, fallback_secs: float) -> float:
	if sprite == null:
		return fallback_secs
	var sf_anim: SpriteFrames = sprite.sprite_frames
	if sf_anim == null or not sf_anim.has_animation(anim):
		return fallback_secs
	var fc: int = sf_anim.get_frame_count(anim)
	if fc <= 0:
		return fallback_secs
	var sum_duration_scales: float = 0.0
	var idx: int = 0
	while idx < fc:
		sum_duration_scales += float(sf_anim.get_frame_duration(anim, idx))
		idx += 1
	var anim_hz: float = float(sf_anim.get_animation_speed(anim))
	if anim_hz < 0.001:
		anim_hz = 12.0
	var play_scale: float = float(sprite.speed_scale)
	if play_scale < 0.001:
		play_scale = 1.0
	var secs: float = sum_duration_scales / (anim_hz * play_scale)
	return clampf(maxf(secs, 0.08) + 0.06, 0.06, 20.0)


func _moon_laser_cast_sequence() -> void:
	_moon_beam_channeling = true
	var sprite: AnimatedSprite2D = animated_sprite
	var sf: SpriteFrames = null
	if sprite != null:
		sf = sprite.sprite_frames

	var mouse_gp: Vector2 = get_global_mouse_position()
	var aim: Vector2 = mouse_gp - global_position
	if aim.length_squared() < 4.0:
		aim = Vector2.RIGHT if not flipped else Vector2.LEFT
	else:
		aim = aim.normalized()

	flipped = aim.x < 0.0
	sprite.flip_h = flipped

	var charge_preview := MoonChargeBeamPreview.new()
	var old_fx := get_node_or_null("_MoonLaserChargeFx")
	if old_fx != null:
		old_fx.queue_free()
	charge_preview.name = "_MoonLaserChargeFx"
	add_child(charge_preview)
	charge_preview.activate(
			self,
			moon_laser_emit_offset_px,
			moon_charge_preview_line_width,
			moon_charge_preview_line_color,
	)

	if (
			sf != null
			and sf.has_animation(&"moon_laser_charge")
			and sf.get_frame_count(&"moon_laser_charge") > 0
	):
		sprite.speed_scale = 1.0
		sprite.play(&"moon_laser_charge")
		var charge_w: float = _moon_sprite_anim_playback_secs(sprite, &"moon_laser_charge", 0.52)
		await get_tree().create_timer(charge_w).timeout
	else:
		await get_tree().create_timer(0.35).timeout

	var snap: Dictionary = {}
	if charge_preview != null and is_instance_valid(charge_preview):
		snap = charge_preview.capture_fire_snapshot()
		charge_preview.queue_free()

	var aim_fire: Vector2 = snap.get(&"aim", aim)
	if aim_fire.length_squared() < 0.0001:
		aim_fire = aim
	if aim_fire.length_squared() < 0.0001:
		aim_fire = Vector2.RIGHT if not flipped else Vector2.LEFT
	else:
		aim_fire = aim_fire.normalized()

	flipped = aim_fire.x < 0.0
	sprite.flip_h = flipped

	var beam_spawn: Vector2 = snap.get(&"beam_spawn", global_position + aim_fire * moon_laser_emit_offset_px)
	var beam_len: float = float(snap.get(&"beam_len", 0.0))
	if beam_len < 24.0:
		var beam_space_fallback: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		beam_spawn = global_position + aim_fire * moon_laser_emit_offset_px
		beam_len = MoonLaser.beam_length_through_space(
				beam_space_fallback, beam_spawn, aim_fire, 3200.0, self, 52.0
		)

	var beam_pack: PackedScene = moon_laser_scene
	if beam_pack == null:
		beam_pack = load("res://moon_laser.tscn") as PackedScene

	if beam_pack == null:
		push_error("Player1: Moon laser scene missing (assign moon_laser_scene or add res://moon_laser.tscn).")
		_moon_beam_channeling = false
		return

	var beam_node: MoonLaser = beam_pack.instantiate() as MoonLaser
	var beam_duration_sec: float = 1.0
	if beam_node != null:
		beam_duration_sec = beam_node.beam_duration_sec
		get_parent().add_child(beam_node)
		beam_node.setup(velocity, global_position, beam_spawn, aim_fire, beam_len)

	await get_tree().create_timer(beam_duration_sec).timeout

	if (
			sf != null
			and sf.has_animation(&"moon_laser_recovery")
			and sf.get_frame_count(&"moon_laser_recovery") > 0
	):
		sprite.speed_scale = 1.0
		sprite.play(&"moon_laser_recovery")
		var rec_w: float = _moon_sprite_anim_playback_secs(sprite, &"moon_laser_recovery", 0.42)
		await get_tree().create_timer(rec_w).timeout

	_moon_beam_channeling = false


func try_start_dodge() -> void:
	if dodge_cooldown_left > 0.0:
		return
	var dir: Vector2
	## Prefer actual motion so diagonals match; idle uses last cardinal input + fallback to sprite flip.
	if velocity.length_squared() > 400.0:
		dir = velocity.normalized()
	else:
		dir = last_move_dir
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT if not flipped else Vector2.LEFT
	else:
		dir = dir.normalized()
	is_dodging = true
	dodge_time_left = DODGE_DURATION
	dodge_direction = dir
	dodge_cooldown_left = DODGE_COOLDOWN_TIME
	var dodge_spd: float = float(max_speed) * DODGE_SPEED_MULT
	velocity = dodge_direction * dodge_spd
	animated_sprite.flip_h = dodge_direction.x < 0
	animated_sprite.play(&"run")
	animated_sprite.speed_scale = 1.8
	set_dodge_visual(true)


func _process_dodge(delta: float) -> void:
	velocity = dodge_direction * (float(max_speed) * DODGE_SPEED_MULT)
	dodge_time_left -= delta
	move_and_slide()
	if dodge_time_left <= 0.0:
		is_dodging = false
		set_dodge_visual(false)


func set_dodge_visual(active: bool) -> void:
	if active:
		animated_sprite.modulate = Color(1, 1, 1, 0.55)
	else:
		if not is_invincible:
			animated_sprite.modulate = Color(1, 1, 1, 1.0)


func reset() -> void:
	abilities_enabled = false
	max_speed = original_speed
	speed = original_speed
	max_health = original_health
	health = max_health
	dodge_cooldown_left = 0.0
	secondary_cooldown_left = 0.0
	is_dodging = false
	set_dodge_visual(false)
	_moon_beam_channeling = false
	var moon_fx: Node = get_node_or_null("_MoonLaserChargeFx")
	if moon_fx != null:
		moon_fx.queue_free()
	_cleanup_legacy_companion_nodes()
	if _companion_anchor != null and is_instance_valid(_companion_anchor):
		for c in _companion_anchor.get_children():
			c.queue_free()
	health_changed.emit(max_health, health)
	call_deferred("_sync_companion_nodes")
	call_deferred("_post_reset_hud")


func _post_reset_hud() -> void:
	refresh_secondary_hud_icon()
	if hud and hud.has_method("configure_ability_pips"):
		hud.configure_ability_pips(has_ability(CharacterData.ABILITY_DODGE), true)


func bounce_player(collision_normal: Vector2) -> void:
	velocity = collision_normal * recoil_from_mob
	


func take_damage(damage_amount: int) -> void:
	if is_dodging:
		return
	if is_invincible or health <= 0:
		return
	var new_health: int = health - damage_amount
	if new_health > max_health:
		return
	health = new_health
	health_changed.emit(max_health, health)
	print(health)
	if health <= 0:
		died.emit()
	else:
		start_invincibility()


func change_max_health(change: int) -> void:
	max_health = max(1, max_health + change)
	if change > 0:
		health = mini(max_health, health + change)
	else:
		health = mini(health, max_health)
	health_changed.emit(max_health, health)


func change_speed(change: int) -> void:
	max_speed = max(1, max_speed + change)
	speed = max_speed


func start_invincibility() -> void:
	is_invincible = true
	if not is_dodging:
		animated_sprite.modulate.a = 0.5
	await get_tree().create_timer(iFrame_duration).timeout
	is_invincible = false
	if not is_dodging:
		animated_sprite.modulate.a = 1.0


func start(pos: Vector2) -> void:
	# Rotate swing to face cursor
	swing.rotation = direction.angle() + deg_to_rad(-90)

	# Optional: push the swing outward from player
	swing.global_position += direction * offset
	
	# Lil lunge effect:
	#velocity += direction * 300

	await get_tree().create_timer(swing_cooldown).timeout
	on_swing_cooldown = false

#func reset():
	#health = max_health
	#health_changed.emit(max_health)

#func _on_area_entered(area):
	#if area.is_in_group("enemies"):
		#take_damage(1)
		#print("working")
		##$CollisionShape2D.set_deferred("disabled", true)
	

func start(pos):
	position = pos
	show()
	set_body_collision_enabled(true)
