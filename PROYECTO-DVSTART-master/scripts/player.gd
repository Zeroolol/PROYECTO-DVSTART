extends CharacterBody2D

@export var speed: float = 600.0
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var projectible_scene: PackedScene
@export var espada_scene: PackedScene

var can_dash: bool = true
var is_dashing: bool = false
var is_moving: bool = false
var last_input_dir: Vector2 = Vector2.ZERO
var is_facing_right: bool = true
var was_facing_right: bool = true


var modo_espada: bool = false
var espada_instance: Node2D = null

@onready var hand: Sprite2D = $Hand
@onready var muzzle: Marker2D = $Hand/Muzzle
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if muzzle:
		muzzle.position = Vector2(30, 0)
	
	if espada_scene:
		espada_instance = espada_scene.instantiate()
		hand.add_child(espada_instance) 
		espada_instance.visible = false

		espada_instance.position = Vector2(30, 0)  
	
	var main_node = get_tree().current_scene
	if main_node and main_node.has_signal("mapa_cambiado"):
		main_node.connect("mapa_cambiado", Callable(self, "_on_mapa_cambiado"))
	
	play_idle_animation()

func _on_mapa_cambiado(indice_mapa: int) -> void:
	if indice_mapa == 0: 
		cambiar_a_proyectiles()
	elif indice_mapa == 1: 
		cambiar_a_espada()

func cambiar_a_proyectiles() -> void:
	modo_espada = false
	
	hand.texture = load("res://ruta/a/tu/textura/de/mano.png") 
	if espada_instance:
		espada_instance.visible = false

	if muzzle:
		muzzle.visible = true
	
	print("Modo: Proyectiles - Mano visible")

func cambiar_a_espada() -> void:
	modo_espada = true
	
	hand.texture = null
	if espada_instance:
		espada_instance.visible = true
	
	if muzzle:
		muzzle.visible = false
	
	print("Modo: Espada - Espada visible en mano")

func _physics_process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()

	hand.look_at(mouse_pos)
	var hand_offset: float = 110.0
	var dir_to_mouse = (mouse_pos - global_position).normalized()
	hand.global_position = global_position + dir_to_mouse * hand_offset

	var mouse_direction = (mouse_pos - global_position).x
	was_facing_right = is_facing_right
	is_facing_right = mouse_direction >= 0
	
	if was_facing_right != is_facing_right:
		if not is_moving and not is_dashing:
			play_idle_animation()
		elif is_moving and not is_dashing:
			play_walk_animation()

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var was_moving = is_moving
	is_moving = input_dir != Vector2.ZERO and not is_dashing
	
	if input_dir != Vector2.ZERO:
		last_input_dir = input_dir
	
	if is_moving and not was_moving:
		play_walk_animation()
	elif not is_moving and was_moving:
		play_idle_animation()
	
	if not is_dashing:
		velocity = input_dir * speed

	if Input.is_action_just_pressed("Dash") and can_dash and input_dir != Vector2.ZERO:
		start_dash(input_dir)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		if modo_espada:
			ataque_espada()
		else:
			shoot(get_global_mouse_position())

func shoot(target_pos: Vector2) -> void:
	if projectible_scene == null or modo_espada:
		return

	hand.force_update_transform()
	muzzle.force_update_transform()
	
	var muzzle_global_pos = muzzle.global_position
	var dir = (target_pos - muzzle_global_pos).normalized()
	if dir == Vector2.ZERO:
		return

	var projectible = projectible_scene.instantiate()
	projectible.global_position = muzzle_global_pos
	projectible.direction = dir
	get_tree().current_scene.add_child(projectible)
	play_shoot_animation()

func ataque_espada() -> void:
	if not modo_espada or espada_instance == null:
		return
	
	if espada_instance.has_method("attack"):
		espada_instance.attack(hand.global_position, hand.global_rotation)
		play_sword_animation()

func play_sword_animation() -> void:
	var animation_name = "attack derecha" if is_facing_right else "attack izquierda"
	if animated_sprite and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback_name = "attack"
		if animated_sprite.sprite_frames.has_animation(fallback_name):
			animated_sprite.play(fallback_name)

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

func play_idle_animation() -> void:
	var animation_name = "idle derecha" if is_facing_right else "idle izquierda"
	if animated_sprite and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback_name = "idle"
		if animated_sprite.sprite_frames.has_animation(fallback_name):
			animated_sprite.play(fallback_name)

func play_walk_animation() -> void:
	var animation_name = "walk derecha" if is_facing_right else "walk izquierda"
	if animated_sprite and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback_name = "walk"
		if animated_sprite.sprite_frames.has_animation(fallback_name):
			animated_sprite.play(fallback_name)

func play_dash_animation() -> void:
	var animation_name = "dash derecha" if is_facing_right else "dash izquierda"
	if animated_sprite and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback_name = "dash"
		if animated_sprite.sprite_frames.has_animation(fallback_name):
			animated_sprite.play(fallback_name)

func play_shoot_animation() -> void:
	var animation_name = "shoot derecha" if is_facing_right else "shoot izquierda"
	if animated_sprite and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback_name = "shoot"
		if animated_sprite.sprite_frames.has_animation(fallback_name):
			animated_sprite.play(fallback_name)

func _on_main_mapa_cambiado(indice_mapa: Variant) -> void:
	if indice_mapa == 0:
		cambiar_a_proyectiles()
	elif indice_mapa == 1:
		cambiar_a_espada()
