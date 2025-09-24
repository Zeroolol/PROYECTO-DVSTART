extends Node2D

@export var damage: int = 2
@export var orbit_radius: float = 120.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5
@export var effect_radius: float = 100.0

var player: Node2D = null
var can_dash: bool = true
var is_dashing: bool = false

func _ready() -> void:
	player = get_parent()

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
		
	if not is_dashing:
		handle_orbit()
		handle_input()

func handle_orbit() -> void:
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = (mouse_pos - player.global_position).normalized()
	global_position = player.global_position + dir_to_mouse * orbit_radius
	rotation = dir_to_mouse.angle()

func handle_input() -> void:
	if Input.is_action_just_pressed("shoot") and can_dash:
		start_dash()

func start_dash() -> void:
	can_dash = false
	is_dashing = true
	
	# Indicar al jugador que está en dash
	if player.has_method("set_dashing_state"):
		player.set_dashing_state(true)
	
	var dash_direction = (get_global_mouse_position() - player.global_position).normalized()
	var start_pos = player.global_position
	var end_pos = start_pos + dash_direction * orbit_radius * 1.5
	
	var tween = create_tween()
	tween.tween_method(_safe_update_dash.bind(start_pos, end_pos, dash_direction), 0.0, 1.0, dash_duration)
	tween.finished.connect(_on_dash_finished)
	
	_apply_area_effects()

func _safe_update_dash(progress: float, start_pos: Vector2, end_pos: Vector2, direction: Vector2) -> void:
	player.global_position = start_pos.lerp(end_pos, progress)
	global_position = player.global_position + (-direction * orbit_radius * 0.5)
	rotation = direction.angle()

func _apply_area_effects() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var hit_count = 0
	var push_count = 0
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
		
		if distance < effect_radius:
			_push_enemy(enemy, distance)
			push_count += 1
			
			if distance < effect_radius * 0.6:
				_damage_enemy(enemy)
				hit_count += 1
	
	print("💥 Enemigos golpeados: ", hit_count)
	print("💨 Enemigos empujados: ", push_count)

func _damage_enemy(enemy: Node) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		_apply_knockback(enemy, 500.0)

func _push_enemy(enemy: Node, distance: float) -> void:
	if enemy is CharacterBody2D:
		var push_dir = (enemy.global_position - player.global_position).normalized()
		var force = 300.0 * (1.0 - distance / effect_radius)
		enemy.velocity += push_dir * force

func _apply_knockback(enemy: Node, force: float) -> void:
	if enemy is CharacterBody2D:
		var knockback_dir = (enemy.global_position - player.global_position).normalized()
		enemy.velocity += knockback_dir * force

func _on_dash_finished() -> void:
	is_dashing = false
	
	# Indicar al jugador que ya no está en dash
	if player.has_method("set_dashing_state"):
		player.set_dashing_state(false)
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
