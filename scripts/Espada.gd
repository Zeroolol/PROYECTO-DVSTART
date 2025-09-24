extends Area2D

@export var damage: int = 1
@export var attack_cooldown: float = 0.3

var can_attack: bool = true
var enemies_in_cooldown: Dictionary = {}

func _ready() -> void:
	print("Espada de daño inmediato inicializada")
	body_entered.connect(_on_body_entered)
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = false

func _process(delta: float) -> void:
	var enemies_to_remove = []
	for enemy_id in enemies_in_cooldown:
		enemies_in_cooldown[enemy_id] -= delta
		if enemies_in_cooldown[enemy_id] <= 0:
			enemies_to_remove.append(enemy_id)
	
	for enemy_id in enemies_to_remove:
		enemies_in_cooldown.erase(enemy_id)

func attack() -> void:
	if can_attack:
		print("Ataque de espada ejecutado")
		can_attack = false
		
		var enemies_hit = 0
		for body in get_overlapping_bodies():
			if body.is_in_group("enemy"):
				apply_damage(body)
				enemies_hit += 1
		
		print("Enemigos golpeados: ", enemies_hit)
		
		# Cooldown simple
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func _on_body_entered(body: Node) -> void:
	pass

func apply_damage(enemy: Node) -> void:
	var enemy_id = enemy.get_instance_id()
	
	if enemies_in_cooldown.has(enemy_id):
		return
	
	var target = enemy
	if enemy is Area2D:
		target = enemy.get_parent()
	
	if target and target.has_method("take_damage"):
		print("Espada hizo daño a: ", target.name)
		target.take_damage(damage)
		enemies_in_cooldown[enemy_id] = 0.5

func set_damage_enabled(enabled: bool) -> void:
	can_attack = enabled
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = !enabled
