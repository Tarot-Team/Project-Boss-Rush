extends Area2D

var player_ref: Node2D = null # Initializes the player as global so everything can reference it
var damage = 10

func _ready() -> void:
	monitoring = true  

func _on_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("player"):
		player_ref = body
		print("Player Collided with Hazard!")
		player_ref.take_damage(damage)
		$Timer.start()
	

		
		

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref: # checks if just this object left the field
		player_ref = null
		$Timer.stop()
		
		print("Player left the bad guy!")


func _on_timer_timeout() -> void:
	if player_ref:
		player_ref.take_damage(damage)
		print("player took " + str(damage) + " damage!")
	
