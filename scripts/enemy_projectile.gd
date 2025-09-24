extends Area2D

@export var speed: float = 300.0
@export var damage: int = 1
var direction: Vector2 = Vector2.ZERO
var has_hit: bool = false 

func _ready() -> void:
	print("=== PROYECTIL ENEMIGO CREADO ===")
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = false
		print("CollisionShape activado")
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	await get_tree().create_timer(3.0).timeout
	if not has_hit:
		print("Proyectil auto-destruido por tiempo")
		queue_free()

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO and not has_hit:
		global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	print("Proyectil - Body entered: ", body.name)
	handle_collision(body)

func _on_area_entered(area: Area2D) -> void:
	print("Proyectil - Area entered: ", area.name)
	if area.get_parent().is_in_group("player"):
		handle_collision(area.get_parent())

func handle_collision(target: Node) -> void:
	if has_hit:
		return
	
	print("Manejando colisión con: ", target.name)
	print("Es player: ", target.is_in_group("player"))
	
	if target.is_in_group("player"):
		has_hit = true
		print("¡IMPACTO CON JUGADOR CONFIRMADO!")
		
		if target.has_method("take_damage"):
			print("Aplicando ", damage, " de daño al jugador")
			target.take_damage(damage)
		else:
			print("ERROR: El objetivo no tiene método take_damage")
		
		queue_free()
		
	elif not target.is_in_group("enemy"):
		print("Colisión con objeto neutral, destruyendo proyectil")
		has_hit = true
		queue_free()
