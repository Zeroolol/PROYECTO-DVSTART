extends CharacterBody2D

@export var speed: float = 600.0
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var projectible_scene: PackedScene

var can_dash: bool = true
var is_dashing: bool = false
var is_moving: bool = false
var last_input_dir: Vector2 = Vector2.ZERO

@onready var hand: Sprite2D = $Hand
@onready var muzzle: Marker2D = $Hand/Muzzle
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if muzzle:
		muzzle.position = Vector2(30, 0)
	play_idle_animation()

func _physics_process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()

	hand.look_at(mouse_pos)

	var hand_offset: float = 110.0
	var dir_to_mouse = (mouse_pos - global_position).normalized()
	hand.global_position = global_position + dir_to_mouse * hand_offset

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var was_moving = is_moving
	is_moving = input_dir != Vector2.ZERO and not is_dashing
	
	if input_dir != Vector2.ZERO:
		last_input_dir = input_dir
	
	if is_moving and not was_moving:
		play_walk_animation()
	elif not is_moving and was_moving:
		play_idle_animation()
	
	if input_dir.x != 0:
		animated_sprite.flip_h = input_dir.x < 0
	
	if not is_dashing:
		velocity = input_dir * speed

	if Input.is_action_just_pressed("Dash") and can_dash and input_dir != Vector2.ZERO:
		start_dash(input_dir)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		shoot(get_global_mouse_position())

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

func shoot(target_pos: Vector2) -> void:
	if projectible_scene == null:
		return

	hand.force_update_transform()
	muzzle.force_update_transform()
	
	var muzzle_global_pos = muzzle.global_position
	var dir = (target_pos - muzzle_global_pos).normalized()
	if dir == Vector2.ZERO:
		return

	var projectible = projectible_scene.instantiate()
	get_tree().current_scene.add_child(projectible)
	projectible.global_position = muzzle_global_pos
	projectible.direction = dir
	play_shoot_animation()

func play_idle_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	else:
		print("Animation 'idle' not found")

func play_walk_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")
	else:
		print("Animation 'walk' not found")

func play_dash_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("dash"):
		animated_sprite.play("dash")

func play_shoot_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("shoot"):
		animated_sprite.play("shoot")
