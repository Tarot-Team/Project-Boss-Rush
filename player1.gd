extends CharacterBody2D

signal health_changed(new_health)
signal died
@export var speed: int = 400
@export var max_health: int = 5
@export var attack_swing_scene: PackedScene
@export var iFrame_duration: float = 0.2 # Time in seconds
@export var swing_cooldown: float = 0.5
var health
var is_invincible = false
var screen_size
var flipped

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = max_health
	hide()
	screen_size = get_viewport_rect().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x += -1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y += -1
	if Input.is_action_just_pressed("attack_swing"):
		attack_swing()
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "run"
		
		if velocity.x != 0:
			flipped = velocity.x > 0
			$AnimatedSprite2D.flip_h = flipped
	else:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.animation = "idle"
		
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	

func reset():
	health = max_health
	health_changed.emit(max_health)

#func _on_area_entered(area):
	#if area.is_in_group("enemies"):
		#take_damage(1)
		#print("working")
		##$CollisionShape2D.set_deferred("disabled", true)

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
	$AnimatedSprite2D.modulate.a = 0.8 # makes the player transparent
	
	await get_tree().create_timer(iFrame_duration).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0
	

func attack_swing():
	var swing = attack_swing_scene.instantiate()
	add_child(swing)

	# Position at player
	swing.global_position = global_position

	# Get mouse position in world
	var mouse_pos = get_global_mouse_position()

	# Direction from player to mouse
	var direction = (mouse_pos - global_position).normalized()

	# Rotate swing to face cursor
	swing.rotation = direction.angle() + deg_to_rad(-90)

	# Optional: push the swing outward from player
	var offset = 43
	swing.global_position += direction * offset

	await get_tree().create_timer(swing_cooldown).timeout

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
