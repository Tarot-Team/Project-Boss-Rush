extends CharacterBody2D

signal health_changed(new_health)
signal died
@export var max_speed: int = 450
@export var acceleration: int = 2500
@export var friction: int = 2500 # Basically acts as a global deceleration, we can change it later if needed
@export var recoil_from_mob: int = 600

@export var max_health: int = 5
@export var attack_swing_scene: PackedScene
@export var iFrame_duration: float = 0.2 # Time in seconds
@export var swing_cooldown: float = 0.5

var health
var is_invincible = false
var screen_size
var flipped = true
var on_swing_cooldown = false
var attacking = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = max_health
	hide()
	screen_size = get_viewport_rect().size


func _physics_process(delta: float) -> void:
	if attacking: return
	# Grab Inputs
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()
	
	# Apply Acceleration and Friction
	if input_direction != Vector2.ZERO:
		# Approach max speed by acceleration
		velocity = velocity.move_toward(input_direction * max_speed, acceleration * delta * 2)
		
		# Animation Stuff
		if not attacking:
			$AnimatedSprite2D.play("run")
		flipped = input_direction.x < 0
		$AnimatedSprite2D.flip_h = flipped
	else:
		# Decelerate
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if not attacking:
			$AnimatedSprite2D.play("idle")
	
	if Input.is_action_just_pressed("attack_swing"):
		attack_swing()
	
	move_and_slide() # Somehow applies movement, idrk :shrug:
	#position = position.clamp(Vector2.ZERO, screen_size)
	
	# Handle bouncing/collisions
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("enemies"):
			take_damage(1) # handles the invincibility automatically
			bounce_player(collision.get_normal())

func bounce_player(collision_normal: Vector2):
	# Note that "normal" is the direction pointing away from whatever was hit
	velocity = collision_normal * recoil_from_mob

func take_damage(damage):
	if is_invincible or health <= 0:
		return
	health -= damage
	health_changed.emit(health)
	print(health)
	
	if health <= 0:
		died.emit()
	else:
		start_invincibility()	

func start_invincibility():
	is_invincible = true
	$AnimatedSprite2D.modulate.a = 0.5 # makes the player transparent
	
	await get_tree().create_timer(iFrame_duration).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0

func attack_swing():
	if on_swing_cooldown: return
	on_swing_cooldown = true
	var swing = attack_swing_scene.instantiate()
	var offset = 67
	
	add_child(swing)
	swing.global_position = global_position
	$AnimatedSprite2D.play("attack")
	#attacking = true
	#$AnimatedSprite2D.animation_finished.connect()
	#get_tree().create_timer(0.2).timeout.connect(queue_free)
	if not flipped:
		swing.global_position.x += offset
		swing.scale *= -1
	else:
		swing.global_position.x -= offset
		swing.scale *= 1
	#await $AnimatedSprite2D.animation_finished
	await get_tree().create_timer(swing_cooldown).timeout
	on_swing_cooldown = false

func reset():
	health = max_health
	health_changed.emit(max_health)

#func _on_area_entered(area):
	#if area.is_in_group("enemies"):
		#take_damage(1)
		#print("working")
		##$CollisionShape2D.set_deferred("disabled", true)
	

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	#pass


#func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("enemies"):
		#take_damage(1)
		#print("enemies entered the player")
		##$CollisionShape2D.set_deferred("disabled", true)
