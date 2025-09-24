extends CharacterBody2D

# Cambiar health a 1 para instakill o ajustar el método take_damage
var health = 1  # ← Cambiado a 1 para instakill

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

func take_damage() -> void:
	# INSTAKILL - Comportamiento igual al proyectil
	print("Enemigo recibió daño: ", name)
	queue_free()  # ← Esto hace el instakill

# Opcional: Si quieres efectos visuales antes de morir
func take_damage_with_effects() -> void:
	print("Enemigo recibió daño: ", name)
	
	queue_free()
