extends CharacterBody2D

# Vida del enemigo fuerte
var health: int = 4  

@onready var player = get_node("../Player")

func _physics_process(delta: float) -> void:
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * 150.0
		
		var collision = move_and_collide(velocity * delta)
		if collision and collision.get_collider() == player:
			show_death_screen()

func show_death_screen() -> void:
	get_tree().change_scene_to_file("res://scenes/deathscreen.tscn")

# --- Recibir daño ---
func take_damage(amount: int = 1) -> void:
	health -= amount
	print("Enemigo fuerte recibió daño, vida restante: ", health)

	if health <= 0:
		die()

func die() -> void:
	print("¡Enemigo fuerte derrotado!")
	queue_free()

# Opcional: para efectos visuales antes de morir
func take_damage_with_effects(amount: int = 1) -> void:
	health -= amount
	print("Enemigo fuerte recibió daño con efectos, vida restante: ", health)

	if health <= 0:
		# Podrías poner animación, partículas, etc.
		die()
