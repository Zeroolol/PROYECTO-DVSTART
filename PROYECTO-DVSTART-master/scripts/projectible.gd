extends Area2D

@export var speed: float = 1000.0  # Velocidad reducida para debug
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	print("PROJECTIBLE READY")
	print("Position: ", global_position)
	print("Direction: ", direction)
	print("In tree: ", is_inside_tree())
	
	if direction == Vector2.ZERO:
		print("WARNING: No direction, destroying")
		queue_free()
		return
	
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Forzar visibilidad
	modulate = Color.RED
	scale = Vector2(3, 3)

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	
	print("Projectible moving from ", global_position, " to ", global_position + direction * speed * delta)
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	print("Projectil hit body: ", body.name)

	if body.has_method("take_damage"):
		body.take_damage()
	elif body.get_parent() and body.get_parent().has_method("take_damage"):
		body.get_parent().take_damage()

	queue_free()

func _on_area_entered(area: Area2D) -> void:
	print("Projectible hit area: ", area.name)
	queue_free()
