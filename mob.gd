extends CharacterBody2D

@export_group("Movement")
@export var top_speed = 150
@export var acceleration = 800
@export var friction = 600

@export_group("Knockback")
@export var knockback_resistance = 0.8
@export var knockback_decay: float = 10.0 # Using linear interpolation for smoother feel
@export var bowling_transfer_ratio: float = 0.8 # Higher = more chain reaction
@export var bowling_bounce_factor: float = 0.4 # How much the "ball" bounces off the "pin"
@export var bowling_threshold: float = 150.0

@export var health = 2
var player = null
var knockback_velocity = Vector2.ZERO

# If we want to do some kind of player death effect
var is_fleeing = false
var flee_target = Vector2.ZERO
@export var flee_speed = 400

func _ready():
	$AnimatedSprite2D.play("run")
	player = get_tree().get_first_node_in_group("player")

# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	# Handles Knockback decay
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
	if knockback_velocity.length() < 10:
		knockback_velocity = Vector2.ZERO
	
	# Directional Stuff
	var direction = Vector2.ZERO
	if is_fleeing:
		direction = (global_position - flee_target).normalized()
	elif player:
		direction = (player.global_position - global_position).normalized()

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
		$AnimatedSprite2D.flip_h = velocity.x < 0
		
func handle_bowling_collisions(pre_collision_vel: Vector2):
	for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider.is_in_group("enemies") and collider.has_method("receive_knockback"):
				var impact_dir = (collider.global_position - global_position).normalized()
				var transfer_energy = pre_collision_vel * bowling_transfer_ratio
				collider.receive_knockback(transfer_energy)
				
				var bounce_dir = collision.get_normal()
				knockback_velocity = knockback_velocity.bounce(collision.get_normal()) * bowling_bounce_factor
				
				if collider.has_method("punchy_scale"):
					collider.punchy_scale()

func receive_knockback(impact_vector: Vector2) -> void:
	var actual_force = impact_vector * (1.0 - knockback_resistance)
	knockback_velocity += actual_force
	
	velocity += actual_force

func take_damage(amount, source_pos, force = 800):
	health -= amount
	var knockback_dir = (global_position - source_pos).normalized()
	
	# Reduce vertical aspect of hits
	knockback_dir.y *= 0.6 
	knockback_dir = knockback_dir.normalized()
	var final_kb_velocity = knockback_dir * force * (1.0 - knockback_resistance)
	
	knockback_velocity = final_kb_velocity
	velocity = knockback_velocity 
	
	flash_sprite()
	punchy_scale()
	if health <= 0: die()

func flash_sprite():
	var tween = create_tween()
	$AnimatedSprite2D.modulate = Color.WHITE * 5 # Over-brighten if using HDR, or just use RED
	tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.2)

func die():
	#$CollisionShape2D.set_deferred("disabled", true)
	$CollisionPolygon2D.set_deferred("disabled", true)
	set_physics_process(false) # Stop moving
	$AnimatedSprite2D.play("hit")
	velocity = Vector2.ZERO
	await $AnimatedSprite2D.animation_finished
	self.queue_free()

func _on_hitbox_entered(area: Area2D):
	if area.is_in_group("swing"):
		# apply a direction based on the player position
		var hit_dir = (global_position - area.player_pos_at_hit).normalized()
		
		# Dynamic momentum bonus
		var velocity_alignment = area.player_velocity_at_hit.dot(hit_dir)
		var momentum_bonus = 1.0 + (velocity_alignment / 600.0) 
		momentum_bonus = clamp(momentum_bonus, 0.5, 1.8) # Caps insane values
		
		var final_force = area.knockback_force * momentum_bonus
	
		take_damage(area.damage, area.player_pos_at_hit, final_force)

func start_fleeing(player_pos):
	is_fleeing = true
	flee_target = player_pos

func _on_game_over():
	start_fleeing(player.global_position)

func time_freeze():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0

func punchy_scale():
	var tween = create_tween()
	$AnimatedSprite2D.scale = Vector2(0.7, 1.3) # Squash
	tween.tween_property($AnimatedSprite2D, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
