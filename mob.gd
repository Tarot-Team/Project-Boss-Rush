extends Area2D
var velocity = Vector2.ZERO
var is_fleeing = false
var flee_target = Vector2.ZERO
@export var flee_speed = 500

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	monitoring = true  
	#var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	#$AnimatedSprite2D.animation = mob_types.pick_random()
	#$AnimatedSprite2D.play()
	$AnimatedSprite2D.flip_v = true
	#$AnimatedSprite2D.animation = "run"
	$AnimatedSprite2D.play("run")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_fleeing:
		var direction = (global_position - flee_target).normalized()
		position += direction * flee_speed * delta
		
		
	else:
		position += velocity * delta
	if velocity.x != 0 and not is_fleeing:
		$AnimatedSprite2D.flip_h = velocity.x < 0
		
func start_fleeing(player_pos):
	is_fleeing = true
	flee_target = player_pos
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1)
		#print("Player entered the area!")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		pass
		#print("Player left the area!")


func _on_area_entered(area):
	if area.is_in_group("swing"):
		$CollisionShape2D.set_deferred("disabled", true)
		$AnimatedSprite2D.play("hit")
		velocity = Vector2.ZERO
		await $AnimatedSprite2D.animation_finished
		self.queue_free()

func _on_game_over():
	pass
