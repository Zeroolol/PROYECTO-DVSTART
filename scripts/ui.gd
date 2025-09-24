extends CanvasLayer

@onready var heart_container: HBoxContainer = $HeartContainer
@onready var score_label: Label = $ScoreLabel
@onready var streak_label: Label = $StreakLabel
@onready var shader_texture_rect: TextureRect = $ShaderRacha 

@export var max_hearts: int = 5
@export var heart_texture: Texture2D
@export var empty_heart_texture: Texture2D
@export var streak_shader_threshold: int = 8

var current_hearts: int = max_hearts
var is_initializing: bool = false 
var current_streak: int = 0
var is_shader_active: bool = false

func _ready() -> void:
	print("UI inicializando...")
	
	if heart_container:
		heart_container.position = Vector2(50, 50)
		print("HeartContainer posicionado en: ", heart_container.position)
	
	# Ocultar shader al inicio
	if shader_texture_rect:
		shader_texture_rect.visible = false
		shader_texture_rect.modulate.a = 0.0
		print("Shader inicialmente oculto")
	
	await get_tree().process_frame
	initialize_hearts()

func initialize_hearts() -> void:
	if is_initializing:
		print("Ya se está inicializando, evitando bucle")
		return
		
	is_initializing = true
	print("Inicializando corazones. Máximo esperado: ", max_hearts)
	
	if not heart_container:
		print("ERROR: No hay HeartContainer")
		is_initializing = false
		return
	
	for child in heart_container.get_children():
		if child is TextureRect:
			child.queue_free()
	
	await get_tree().create_timer(0.1).timeout
	
	for i in range(max_hearts):
		var heart = TextureRect.new()
		heart.name = "Heart_" + str(i)
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(32, 32)
		heart.size = Vector2(32, 32)
		heart_container.add_child(heart)
		print("Corazón creado: ", i)
	
	await get_tree().create_timer(0.1).timeout
	is_initializing = false
	update_hearts()

func update_hearts() -> void:
	if not heart_container:
		print("ERROR: No hay HeartContainer en update_hearts")
		return
	
	var hearts = heart_container.get_children()
	print("Número de corazones encontrados en update: ", hearts.size())
	
	if hearts.size() == 0:
		print("No hay corazones, inicializando...")
		initialize_hearts()
		return
	
	if hearts.size() > max_hearts:
		print("Demasiados corazones (", hearts.size(), "), recortando...")
		for i in range(max_hearts, hearts.size()):
			hearts[i].queue_free()
		hearts = heart_container.get_children()
	
	for i in range(hearts.size()):
		var heart = hearts[i]
		if i < current_hearts:
			heart.texture = heart_texture
		else:
			heart.texture = empty_heart_texture

func set_hearts(amount: int) -> void:
	print("set_hearts llamado con: ", amount)
	current_hearts = clamp(amount, 0, max_hearts)
	update_hearts()

func set_score(value: int) -> void:
	score_label.text = "Puntos: " + str(value)

func set_streak(value: int) -> void:
	current_streak = value
	streak_label.text = "Racha: x" + str(value)
	
	update_shader_visibility()

func update_shader_visibility() -> void:
	if not shader_texture_rect:
		print("ERROR: No hay shader_texture_rect")
		return
	
	var should_show = (current_streak >= streak_shader_threshold)
	
	if should_show and not is_shader_active:
		activate_shader()
	elif not should_show and is_shader_active:
		deactivate_shader()

func activate_shader() -> void:
	print("🎯 ¡Racha x", current_streak, "! Activando shader en la UI")
	is_shader_active = true

	shader_texture_rect.visible = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(shader_texture_rect, "modulate:a", 0.8, 0.7)
	
	tween.tween_property(shader_texture_rect, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(shader_texture_rect, "scale", Vector2(1.0, 1.0), 0.4)
	
	tween.tween_property(streak_label, "modulate", Color.GOLD, 0.5)

func deactivate_shader() -> void:
	print("Desactivando shader de racha")
	is_shader_active = false
	
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(shader_texture_rect, "modulate:a", 0.0, 0.5)
	
	tween.tween_property(streak_label, "modulate", Color.WHITE, 0.3)
	
	tween.tween_callback(_hide_shader)

func _hide_shader() -> void:
	if not is_shader_active:
		shader_texture_rect.visible = false

func _process(delta: float) -> void:
	if is_shader_active and shader_texture_rect:
		var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.1 + 1.0
		shader_texture_rect.scale = Vector2(pulse, pulse)
