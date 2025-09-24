extends CharacterBody2D

var health: int = 2  
var damage_amount: int = 2
var attack_cooldown: float = 2
var can_attack: bool = true
var knockback_force: float = 300.0
var attack_timer: float = 0.0
var should_attack: bool = false
var attack_target: Node = null
var can_shoot: bool = true
var shoot_cooldown: float = 3.0
var shoot_timer: float = 0.0

@export var projectile_scene: PackedScene

signal enemy_killed(points)

@onready var player = get_node("../Player")

func _ready() -> void:
	add_to_group("enemy")
	
	var damage_area = Area2D.new()
	damage_area.name = "DamageArea"
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 25
	
	collision_shape.shape = circle_shape
	damage_area.add_child(collision_shape)
	add_child(damage_area)
	
	damage_area.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta: float) -> void:
	if shoot_timer > 0:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
	
	if can_shoot and player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < 300:
			shoot_at_player()
	
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
			attack_timer = 0.0
	
	if should_attack and attack_target and can_attack:
		execute_attack(attack_target)
		should_attack = false
		attack_target = null
	
	if player and is_instance_valid(player) and can_attack:
		var direction = global_position.direction_to(player.global_position)
		var distance = global_position.distance_to(player.global_position)
		
		if distance < 80:
			velocity = direction * 80.0
		else:
			velocity = direction * 120.0
		
		move_and_slide()
		
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() == player and can_attack:
				_on_damage_area_body_entered(player)

func shoot_at_player() -> void:
	if not can_shoot or not projectile_scene or not player:
		return
	
	can_shoot = false
	shoot_timer = shoot_cooldown
	
	print("Enemigo fuerte disparando al jugador")
	
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	var shoot_direction = global_position.direction_to(player.global_position)
	projectile.global_position = global_position + shoot_direction * 20
	projectile.direction = shoot_direction
	projectile.rotation = shoot_direction.angle()
	
	play_shoot_animation()

func play_shoot_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.CYAN, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _on_damage_area_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage") and can_attack:
		should_attack = true
		attack_target = body

func execute_attack(target: Node) -> void:
	if not can_attack or not is_instance_valid(target):
		return
	
	can_attack = false
	print("Enemigo fuerte atacando - Daño: ", damage_amount)

	target.take_damage(damage_amount)
	
	apply_knockback_to_player(target)
	apply_self_knockback(target.global_position)
	play_attack_animation()
	
	attack_timer = attack_cooldown

func apply_knockback_to_player(player_body: Node) -> void:
	if player_body is CharacterBody2D:
		var knockback_direction = (player_body.global_position - global_position).normalized()
		player_body.velocity += knockback_direction * knockback_force

func apply_self_knockback(player_position: Vector2) -> void:
	var self_knockback_direction = (global_position - player_position).normalized()
	velocity += self_knockback_direction * (knockback_force * 0.6)

func play_attack_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.chain()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func take_damage(amount: int = 1) -> void:
	health -= amount
	print("Enemigo fuerte recibió daño, vida restante: ", health)
	
	play_hurt_animation()

	if health <= 0:
		die()

func play_hurt_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 1), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func die() -> void:
	emit_signal("enemy_killed", 100)
	print("¡Enemigo fuerte derrotado!")
	queue_free()
