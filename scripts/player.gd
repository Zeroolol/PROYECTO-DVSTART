extends CharacterBody2D

@export var speed: float = 1200.0
@export var dash_speed: float = 2500.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var hand_scene: PackedScene
@export var fist_scene: PackedScene
@export var sword_scene: PackedScene
@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 0.15
@export var auto_fire: bool = true
@export var hand_orbit_radius: float = 150.0
@export var max_lives: int = 5
@export var invincibility_time: float = 1.0
@export var powerup_multiplier: float = 1.5
@export var powerup_damage_multiplier: int = 2
@export var base_sword_damage: int = 1
@export var base_projectile_damage: int = 1
@export var base_damage: int = 1
@export var skins: Array[SpriteFrames] = []  # Array con las 3 skins

# Estados internos
var current_hand: Node2D = null
var current_weapon_type: String = "hand"
var is_sword_mode: bool = false
var is_powered_up: bool = false
var current_lives: int = max_lives
var can_dash: bool = true
var is_dashing: bool = false
var can_shoot: bool = true
var is_invincible: bool = false
var is_facing_right: bool = true
var was_facing_right: bool = true
var current_skin_index: int = 0

# Nodes
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hand_pivot: Node2D = $HandPivot

signal player_health_changed(new_health)
signal player_died()

func _ready() -> void:
	add_to_group("player")
	current_lives = max_lives
	emit_signal("player_health_changed", current_lives)
	if skins.size() > 0:
		animated_sprite.sprite_frames = skins[current_skin_index]
	
	play_idle_animation()
	current_hand = null
	print("🎮 Player listo, skin inicial: ", current_skin_index)
	
	# Inicializar con arma vacía, el main se encargará de asignar la primera
	current_hand = null

func _physics_process(delta: float) -> void:
	handle_mouse_aim()
	handle_movement()
	handle_shooting_input()
	move_and_slide()

# -------- MOVIMIENTO --------
func handle_movement() -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if is_dashing:
		return

	velocity = input_dir * speed
	if Input.is_action_just_pressed("Dash") and can_dash and input_dir != Vector2.ZERO:
		start_dash(input_dir)

func start_dash(direction: Vector2) -> void:
	is_dashing = true
	can_dash = false
	velocity = direction.normalized() * dash_speed
	play_dash_animation()
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
	play_idle_animation()

# -------- MIRA Y ORIENTACION --------
func handle_mouse_aim() -> void:
	var mouse_pos = get_global_mouse_position()
	var mouse_dir = (mouse_pos - global_position).x
	was_facing_right = is_facing_right
	is_facing_right = mouse_dir >= 0

	if hand_pivot:
		var direction_to_mouse = (mouse_pos - global_position).normalized()
		hand_pivot.rotation = direction_to_mouse.angle()

# -------- DISPARO / ATAQUE --------
func handle_shooting_input() -> void:
	if current_hand == null:
		return
		
	if current_weapon_type == "hand" and can_shoot:
		if Input.is_action_just_pressed("shoot") or (auto_fire and Input.is_action_pressed("shoot")):
			shoot()
	elif current_weapon_type in ["sword", "fist"]:
		if Input.is_action_just_pressed("shoot") and current_hand.has_method("attack"):
			current_hand.attack()

func shoot() -> void:
	if not projectile_scene or current_weapon_type != "hand":
		return
	can_shoot = false
	var projectile = create_projectile()
	if projectile:
		get_tree().current_scene.add_child(projectile)
		if current_hand.has_method("get_shoot_position"):
			projectile.global_position = current_hand.get_shoot_position()
			projectile.direction = current_hand.get_shoot_direction()
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func create_projectile() -> Node:
	if not projectile_scene:
		return null
	var projectile = projectile_scene.instantiate()
	if projectile.has_method("set_damage"):
		projectile.set_damage(get_projectile_damage())
	return projectile

# -------- CAMBIO DE ARMAS CORREGIDO --------
func switch_to_hand() -> void:
	await clear_current_weapon()  # 🔥 ESPERAR a que se limpie
	
	if hand_scene:
		current_hand = hand_scene.instantiate()
		hand_pivot.add_child(current_hand)
		current_hand.position = Vector2(hand_orbit_radius, 0)
		current_weapon_type = "hand"
		is_sword_mode = false
		can_shoot = true
		print("🔫 Hand/Proyectil equipado")

func switch_to_fist() -> void:
	await clear_current_weapon()  # 🔥 ESPERAR a que se limpie
	
	if fist_scene:
		current_hand = fist_scene.instantiate()
		hand_pivot.add_child(current_hand)
		current_hand.position = Vector2(hand_orbit_radius, 0)
		current_weapon_type = "fist"
		is_sword_mode = false
		can_shoot = false
		print("👊 Puño equipado")

func switch_to_sword() -> void:
	await clear_current_weapon()  # 🔥 ESPERAR a que se limpie
	
	if sword_scene:
		current_hand = sword_scene.instantiate()
		hand_pivot.add_child(current_hand)
		current_hand.position = Vector2(hand_orbit_radius, 0)
		current_weapon_type = "sword"
		is_sword_mode = true
		can_shoot = false
		print("⚔️ Espada equipada")

func clear_current_weapon() -> void:
	# Limpiar arma actual
	if current_hand and is_instance_valid(current_hand):
		current_hand.queue_free()
		current_hand = null
	
	# Limpiar todos los hijos del hand_pivot
	for child in hand_pivot.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	# Esperar a que se completen las eliminaciones
	await get_tree().process_frame
	await get_tree().process_frame  # 🔥 Doble espera para asegurar

# -------- DAÑO Y VIDAS --------
func take_damage(amount: int = 1) -> void:
	# Verificar primero si está en dash
	if is_dashing:
		print("🛡️ Jugador inmune durante dash")
		return
		
	if is_invincible:
		return
		
	current_lives -= amount
	emit_signal("player_health_changed", current_lives)
	play_hurt_animation()
	become_invincible()
	
	if current_lives <= 0:
		die()

func set_dashing_state(dashing: bool):
	is_dashing = dashing

func heal(amount: int = 1) -> void:
	current_lives = min(current_lives + amount, max_lives)
	emit_signal("player_health_changed", current_lives)

func die() -> void:
	emit_signal("player_died")
	get_tree().change_scene_to_file("res://scenes/deathscreen.tscn")	

func become_invincible() -> void:
	is_invincible = true
	var tween = create_tween()
	tween.set_loops(6)
	tween.tween_property(self, "modulate", Color(1,1,1,0.3), 0.08)
	tween.tween_property(self, "modulate", Color(1,1,1,1), 0.08)
	await get_tree().create_timer(invincibility_time).timeout
	is_invincible = false
	modulate = Color.WHITE

func play_hurt_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

# -------- ANIMACIONES --------
func play_idle_animation() -> void:
	var anim_name = "idle derecha" if is_facing_right else "idle izquierda"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		# Fallback: buscar animaciones genéricas
		var fallback_anim = "idle"
		if animated_sprite.sprite_frames.has_animation(fallback_anim):
			animated_sprite.play(fallback_anim)

func play_walk_animation() -> void:
	var anim_name = "correr derecha" if is_facing_right else "correr izquierda"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		var fallback_anim = "walk"
		if animated_sprite.sprite_frames.has_animation(fallback_anim):
			animated_sprite.play(fallback_anim)

func play_dash_animation() -> void:
	var anim_name = "dash derecha" if is_facing_right else "dash izquierda"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		var fallback_anim = "dash"
		if animated_sprite.sprite_frames.has_animation(fallback_anim):
			animated_sprite.play(fallback_anim)


# -------- POWER-UP --------
func set_power_up(active: bool) -> void:
	is_powered_up = active
	if active:
		speed *= powerup_multiplier
	else:
		speed = speed / powerup_multiplier
	update_weapons_damage()

func get_sword_damage() -> int:
	return base_sword_damage * (powerup_damage_multiplier if is_powered_up else 1)

func get_projectile_damage() -> int:
	return base_projectile_damage * (powerup_damage_multiplier if is_powered_up else 1)

func update_weapons_damage() -> void:
	if current_hand and current_hand.has_method("set_damage"):
		var dmg = get_sword_damage() if is_sword_mode else get_projectile_damage()
		current_hand.set_damage(dmg)

func change_skin(skin_index: int) -> void:
	if skin_index < 0 or skin_index >= skins.size():
		print("❌ Índice de skin inválido: ", skin_index)
		return
	
	current_skin_index = skin_index
	animated_sprite.sprite_frames = skins[skin_index]
	
	# Forzar actualización de animación actual
	play_idle_animation()
	print("🎭 Skin cambiada a: ", skin_index)

# 🔥 NUEVO MÉTODO: Obtener skin actual (para el main)
func get_current_skin_index() -> int:
	return current_skin_index
