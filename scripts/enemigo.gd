extends CharacterBody2D

var health = 4

@onready var player = get_node("../Player")

func _physics_process(delta: float) -> void:
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * 200.0
		
		var collision = move_and_collide(velocity * delta)
		if collision and collision.get_collider() == player:
			show_death_screen()

func show_death_screen() -> void:
	get_tree().change_scene_to_file("res://scenes/deathscreen.tscn")
	

func take_damage():
	health -= 1
	
	if health == 0:
		queue_free()
