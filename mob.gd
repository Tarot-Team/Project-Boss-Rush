extends CharacterBody2D
class_name Enemy

@export_group("Movement")
@export var top_speed = 150
@export var acceleration = 800
@export var friction = 600
@export var attack_range: float = 42.0
@export var attack_cooldown: float = 1.1

@export_group("Knockback")
@export var knockback_resistance = 0.8
@export var knockback_decay: float = 10.0 # Using linear interpolation for smoother feel
@export var bowling_transfer_ratio: float = 0.8 # Higher = more chain reaction
@export var bowling_bounce_factor: float = 0.4 # How much the "ball" bounces off the "pin"
@export var bowling_threshold: float = 150.0

@export_group("Health")
@export var max_health: int = 4
@export var health_bar_hide_delay: float = 1.2

@export_group("Combat")
@export var contact_damage: int = 1

var current_health: int = 0
var player: Node2D = null
var knockback_velocity: Vector2 = Vector2.ZERO
var attack_cooldown_left: float = 0.0
var is_attacking: bool = false

var base_sprite_scale: Vector2


# If we want to do some kind of player death effect
var is_fleeing = false
var flee_target = Vector2.ZERO
@export var flee_speed = 400
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_bar_timer: Timer = $HealthBar/HideTimer


func _ready() -> void:
	current_health = max_health
	base_sprite_scale = animated_sprite.scale
	player = get_tree().get_first_node_in_group("player") as Node2D
	_setup_health_bar()
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(&"run"):
		animated_sprite.play(&"run")
	add_child(AmbientGlow.enemy_aura())


func _physics_process(delta: float) -> void:
	if attack_cooldown_left > 0.0:
		attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)

	# Handles Knockback decay
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
	if knockback_velocity.length() < 10:
		knockback_velocity = Vector2.ZERO
	
	# Directional Stuff
	var direction = Vector2.ZERO
	if is_fleeing:
		direction = (global_position - flee_target).normalized()
	elif is_instance_valid(player):
		var to_player := player.global_position - global_position
		if _can_attack_player(to_player):
			_attack_player()
		if not is_attacking:
			direction = to_player.normalized()

	# Chase Velocity
	var target_chase_velocity = direction * top_speed
	var move_velocity = velocity.lerp(target_chase_velocity, (acceleration / top_speed) * delta)
	
	velocity = move_velocity + knockback_velocity
	var velocity_before_collision = velocity
	
	move_and_slide()

	# Bowling: transfer knockback through stacked mobs (must check collider, not KinematicCollision2D).
	if knockback_velocity.length() > bowling_threshold:
		handle_bowling_collisions(velocity_before_collision)
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0


func _setup_health_bar() -> void:
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.visible = false
	health_bar_timer.wait_time = health_bar_hide_delay


func _show_health_bar() -> void:
	health_bar.visible = current_health > 0 and current_health < max_health
	health_bar_timer.start()


func _sync_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = clampi(current_health, 0, max_health)
	_show_health_bar()


func handle_bowling_collisions(pre_collision_vel: Vector2) -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("enemies") and collider.has_method("receive_knockback"):
			var transfer_energy = pre_collision_vel * bowling_transfer_ratio
			collider.receive_knockback(transfer_energy)
			knockback_velocity = knockback_velocity.bounce(collision.get_normal()) * bowling_bounce_factor

			if collider.has_method("punchy_scale"):
				collider.punchy_scale()

func receive_knockback(impact_vector: Vector2) -> void:
	var actual_force = impact_vector * (1.0 - knockback_resistance)
	knockback_velocity += actual_force
	
	velocity += actual_force


func _can_attack_player(to_player: Vector2) -> bool:
	if is_attacking or attack_cooldown_left > 0.0 or not is_instance_valid(player):
		return false
	return to_player.length_squared() <= attack_range * attack_range


func _attack_player() -> void:
	is_attacking = true
	attack_cooldown_left = attack_cooldown
	velocity = Vector2.ZERO
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(&"attack"):
		animated_sprite.play(&"attack")
		await animated_sprite.animation_finished
	if current_health <= 0:
		return
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(contact_damage)
	is_attacking = false
	if current_health > 0 and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(&"run"):
		animated_sprite.play(&"run")

func take_damage(amount: int, source_pos: Vector2, force: float = 800.0) -> void:
	if current_health <= 0:
		return
	current_health = clampi(current_health - amount, 0, max_health)
	_sync_health_bar()

	var knockback_dir = (global_position - source_pos).normalized()

	# Reduce vertical knockback so hits feel punchy without launching enemies too far upward/downward.
	knockback_dir.y *= 0.6
	knockback_dir = knockback_dir.normalized()
	var final_kb_velocity = knockback_dir * force * (1.0 - knockback_resistance)

	knockback_velocity = final_kb_velocity
	velocity = knockback_velocity

	flash_sprite()
	punchy_scale()
	if current_health <= 0:
		die()


func flash_sprite() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color.WHITE * 5
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)


func die() -> void:
	#$CollisionShape2D.set_deferred("disabled", true)
	$CollisionPolygon2D.set_deferred("disabled", true)
	health_bar.hide()
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(&"death"):
		set_physics_process(false) # Stop moving
		animated_sprite.play(&"death")
		await animated_sprite.animation_finished
	else:
		animated_sprite.modulate.a = 0.5
		#while velocity.length() > 0.1:
			#await get_tree().physics_frame
		await get_tree().create_timer(0.2).timeout
		
		
	velocity = Vector2.ZERO
	self.queue_free()


func _on_hitbox_entered(area: Area2D) -> void:
	if area.is_in_group("swing") or area.is_in_group("player_proj"):
		# apply a direction based on the player position
		var hit_dir = (global_position - area.player_pos_at_hit).normalized()
		
		# Dynamic momentum bonus
		var velocity_alignment = area.player_velocity_at_hit.dot(hit_dir)
		var momentum_bonus = 1.0 + (velocity_alignment / 600.0) 
		momentum_bonus = clamp(momentum_bonus, 0.5, 1.8) # Caps insane values
		
		var final_force = area.knockback_force * momentum_bonus
	
		take_damage(area.damage, area.player_pos_at_hit, final_force)


func start_fleeing(player_pos: Vector2) -> void:
	is_fleeing = true
	flee_target = player_pos


func _on_game_over() -> void:
	if is_instance_valid(player):
		start_fleeing(player.global_position)


func time_freeze() -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0


func punchy_scale() -> void:
	var tween = create_tween()
	animated_sprite.scale = base_sprite_scale * Vector2(0.7, 1.3)
	tween.tween_property(animated_sprite, "scale", base_sprite_scale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_health_bar_hide_timer_timeout() -> void:
	if current_health > 0:
		health_bar.hide()
