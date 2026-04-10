extends CharacterBody2D

@export var top_speed = 150
@export var acceleration = 800
@export var friction = 600
@export var health = 2
@export var knockback_resistance = 0.5 # range from 0-1

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
	# Handle Knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, friction * delta)
	
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
	
	
	# Checking for "bowling effect" in enemy knockback
	if knockback_velocity.length() > top_speed:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider.is_in_group("enemies") and collision.has_method("apply_impulse_knockback"):
				var push_force = velocity * 0.6
				collider.apply_impulse_knockback(push_force)
				knockback_velocity *= 0.4

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

func apply_impulse_knockback(force: Vector2):
	velocity += force

func take_damage(amount, source_pos):
	health -= amount
	var knockback_dir = (global_position - source_pos).normalized()
	knockback_velocity = knockback_dir * 800 * (1 - knockback_resistance)
	
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
		take_damage(1, area.global_position)

func start_fleeing(player_pos):
	is_fleeing = true
	flee_target = player_pos

func _on_game_over():
	start_fleeing(player.global_position)
