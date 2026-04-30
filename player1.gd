extends CharacterBody2D

signal health_changed(max_health, health)
signal died
@export var speed: int = 400
@export var original_health: int = 5
@export var attack_swing_scene: PackedScene
@export var iFrame_duration: float = 0.2 # Time in seconds
@export var swing_cooldown: float = 0.5
var original_speed = 400
var max_health
var health
var is_invincible = false
var screen_size
var flipped

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_health = original_health
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
	speed = original_speed
	max_health = original_health
	health = max_health
	health_changed.emit(max_health, health)

#func _on_area_entered(area):
	#if area.is_in_group("enemies"):
		#take_damage(1)
		#print("working")
		##$CollisionShape2D.set_deferred("disabled", true)

func take_damage(damage):
	if is_invincible or health <= 0:
		return
	var new_health: int  = health - damage
	if max_health < new_health: return
	health = new_health
	health_changed.emit(max_health, health)
	if health <= 0:
		died.emit()
	else:
		start_invincibility()

func change_max_health(change):
	max_health += change
	health_changed.emit(max_health, health)
	take_damage(-change) 
	print("Max:", max_health, "Current:", health)

func change_speed(change):
	speed += change
	print(speed)


func start_invincibility():
	is_invincible = true
	$AnimatedSprite2D.modulate.a = 0.8 # makes the player transparent
	
	await get_tree().create_timer(iFrame_duration).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0
	

func attack_swing():
	var swing = attack_swing_scene.instantiate()
	var offset = 43
	
	add_child(swing)
	swing.global_position = global_position
	
	if flipped == true:
		swing.global_position.x += offset
		swing.scale *= -1
	else:
		swing.global_position.x -= offset
		swing.scale *= 1
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
