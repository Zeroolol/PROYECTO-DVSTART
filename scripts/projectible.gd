extends Area2D

@export var speed: float = 1000.0
@export var damage: int = 10
@export var lifetime: float = 2.0 

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	if direction != Vector2.ZERO:
		rotation = direction.angle()

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	
	handle_hit(body)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	handle_hit(area)
	queue_free()

func handle_hit(target: Node) -> void:
	var damage_target = target
	
	if target is Area2D:
		damage_target = target.get_parent()
	
	if damage_target and damage_target.has_method("take_damage"):
		damage_target.take_damage()

	spawn_hit_effect()

func spawn_hit_effect() -> void:
	pass
