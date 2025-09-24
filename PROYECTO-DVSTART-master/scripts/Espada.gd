extends Area2D

@export var attack_duration: float = 0.2
@export var attack_cooldown: float = 0.5

var is_attacking: bool = false
var can_attack: bool = true
var bodies_golpeados: Array = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	collision.disabled = true
	
	# ✅ Conectar señal body_entered
	body_entered.connect(_on_body_entered)
	
	# ✅ Configurar capas (ejemplo: arma en capa 2, enemigos en capa 3)
	collision_layer = 2
	collision_mask = 2

func attack(global_pos: Vector2, global_rot: float) -> void:
	if not can_attack or is_attacking:
		return
	
	can_attack = false
	is_attacking = true
	bodies_golpeados.clear()
	
	# Activar colisión
	collision.disabled = false
	
	# Animación de ataque
	animate_attack()
	
	# Timer para el ataque
	attack_timer.wait_time = attack_duration
	attack_timer.start()

func animate_attack() -> void:
	# ✅ Solo animación, sin llamar a finish_attack
	var tween = create_tween()
	var end_rot = rotation + deg_to_rad(90)
	tween.tween_property(self, "rotation", end_rot, attack_duration)

func finish_attack() -> void:
	is_attacking = false
	collision.disabled = true
	bodies_golpeados.clear()
	
	# Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_body_entered(body: Node) -> void:
	# Evitar golpear múltiples veces el mismo cuerpo en un ataque
	if body in bodies_golpeados:
		return
	
	# No golpear al jugador ni a sí mismo
	var jugador = get_parent().get_parent()  # Espada → Mano → Jugador
	if body == jugador or body == self:
		return
	
	print("⚔️ Espada golpeó: ", body.name)
	
	# INSTAKILL - Igual que el proyectil
	if body.has_method("take_damage"):
		body.take_damage()
		bodies_golpeados.append(body)
		print("Instakill aplicado a: ", body.name)
	elif body.get_parent() and body.get_parent().has_method("take_damage"):
		body.get_parent().take_damage()
		bodies_golpeados.append(body.get_parent())
		print("Instakill aplicado al parent: ", body.get_parent().name)
	else:
		if body is CharacterBody2D:
			print("Eliminando enemigo directamente: ", body.name)
			body.queue_free()
			bodies_golpeados.append(body)

func _on_attack_timer_timeout() -> void:
	finish_attack()
