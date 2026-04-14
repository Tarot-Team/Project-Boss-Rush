extends CharacterBody2D

@export_group("Movement")
@export var top_speed = 150
@export var acceleration = 800
@export var friction = 600

@export_group("Knockback")
@export var health = 2
@export var knockback_resistance = 0.2 # range from 0-1
@export var knockback_decel: float = 320.0
## Min knockback speed before enemy-enemy "bowling" transfer runs (above normal chase speed).
@export var bowling_knockback_threshold: float = 200.0
@export var bowling_transfer_ratio: float = 0.55
@export var bowling_self_retention: float = 0.2
@export var max_knockback_speed: float = 950.0
## Below this knockback magnitude we clamp slide velocity to chase cap (stops idle slingshots).
@export var knockback_cap_blend: float = 90.0

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
	# Knockback decays on its own curve so it isn't eaten by the same friction as movement.
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decel * delta)
	
	# Directional Stuff
	var direction = Vector2.ZERO
	if is_fleeing:
		direction = (global_position - flee_target).normalized()
	elif player:
		direction = (player.global_position - global_position).normalized()

	# Chase Velocity
	var chase_speed = flee_speed if is_fleeing else top_speed	
	var target_chase_velocity = direction * chase_speed
	
	var desired_velocity = target_chase_velocity + knockback_velocity
	
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
	move_and_slide()

	# Bowling: transfer knockback through stacked mobs (must check collider, not KinematicCollision2D).
	if knockback_velocity.length() > bowling_knockback_threshold:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider.is_in_group("enemies") and collider.has_method("receive_bowling_knockback"):
				var transfer = knockback_velocity * bowling_transfer_ratio
				collider.receive_bowling_knockback(transfer)
				knockback_velocity *= bowling_self_retention

	# Idle enemy contact can build tangent speed from slide resolution; clamp unless knockback is active.
	var chase_cap = flee_speed if is_fleeing else top_speed
	var speed_cap = chase_cap
	if knockback_velocity.length() > knockback_cap_blend:
		speed_cap = max(chase_cap, min(knockback_velocity.length(), max_knockback_speed))
	if velocity.length() > speed_cap:
		velocity = velocity.limit_length(speed_cap)

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

func receive_bowling_knockback(incoming: Vector2) -> void:
	if incoming.length_squared() < 100.0:
		return
	knockback_velocity += incoming
	if knockback_velocity.length() > max_knockback_speed:
		knockback_velocity = knockback_velocity.limit_length(max_knockback_speed)

func take_damage(amount, source_pos, force = 800):
	health -= amount
	var knockback_dir = (global_position - source_pos).normalized()
	
	var final_force = force * (1.0 - knockback_resistance)
	knockback_velocity = knockback_dir * final_force
	
	velocity = knockback_velocity 
	
	$AnimatedSprite2D.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	$AnimatedSprite2D.modulate = Color.WHITE
	
	if health <= 0: die()

func die():
	#$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("hit")
	velocity = Vector2.ZERO
	await $AnimatedSprite2D.animation_finished
	self.queue_free()

func _on_hitbox_entered(area: Area2D):
	if area.is_in_group("swing"):
		take_damage(area.damage, area.global_position, area.knockback_force)

func start_fleeing(player_pos):
	is_fleeing = true
	flee_target = player_pos

func _on_game_over():
	start_fleeing(player.global_position)
