extends CharacterBody2D
signal died
var health: int = 100
const speed: int = 150
const acceleration: int = 15
const friction: int = 20


func _physics_process(delta: float) -> void:
	var input = Vector2(
		Input.get_action_strength("d") - Input.get_action_strength("a"),
		Input.get_action_strength("s") - Input.get_action_strength("w") 
	).normalized()

	var lerp_weight = delta *(acceleration if input else friction)
	velocity = lerp(velocity, input * speed, lerp_weight)
	move_and_slide()

func take_damage(damage:int):
	health -= damage
	if health <= 0:
		emit_signal("died")
	print(health)
