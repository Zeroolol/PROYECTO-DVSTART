extends Node2D

signal mapa_cambiado(indice_mapa)
signal score_changed(new_score)
signal streak_changed(new_streak)

@onready var fondo: Sprite2D = $background
@onready var contador_label: Label = $CanvasLayer/contador
@onready var player: CharacterBody2D = $Player
@onready var shader_rect: TextureRect = $ShaderMafia

@export var fondos: Array[Texture2D] = []
@export var fist_scene: PackedScene  # 🔥 Puño - Fondo 0
@export var hand_scene: PackedScene  # 🔫 Hand/Proyectil - Fondo 1
@export var sword_scene: PackedScene # ⚔️ Espada - Fondo 2
@export var fondo_con_shader: int = 1

@export var enemigo_scene: PackedScene = preload("res://scenes/enemigo.tscn")
@export var enemigo_fuerte_scene: PackedScene = preload("res://scenes/enemigo_fuerte.tscn")

@export var enemigos_por_oleada: int = 3
@export var enemigos_extra_cada_oleada: int = 1
@export var max_oleadas: int = 6
@export var delay_spawn_enemy: float = 0.5

var indice_fondo: int = 0
var tiempo_restante: int = 30
var current_weapon: Node2D = null
var ui_instance: CanvasLayer = null
var oleada_actual: int = 0
var power_up_threshold: int = 8
var is_player_powered_up: bool = false
var score: int = 0
var streak: int = 0
var streak_timer: Timer

var weapon_array: Array = []
var enemies_to_spawn: Array = []

func _ready() -> void:
	# 🔥 ORDEN DE ARMAS: Puño (0), Hand (1), Espada (2)
	weapon_array = [fist_scene, hand_scene, sword_scene]
	
	apply_skin_to_player(indice_fondo)
	
	if fondos.size() > 0:
		fondo.texture = fondos[indice_fondo]
	contador_label.text = str(tiempo_restante)

	# Cambiar al arma correspondiente al fondo actual
	switch_to_weapon(indice_fondo % weapon_array.size())

	# Timer de contador
	var contador_timer = Timer.new()
	contador_timer.wait_time = 1.0
	contador_timer.one_shot = false
	contador_timer.autostart = true
	add_child(contador_timer)
	contador_timer.timeout.connect(_on_contador_timer_timeout)

	# Timer de oleadas
	var oleada_timer = Timer.new()
	oleada_timer.wait_time = 1.0
	oleada_timer.one_shot = false
	oleada_timer.autostart = true
	add_child(oleada_timer)
	oleada_timer.timeout.connect(_on_oleada_timer_timeout)

	# UI
	var ui_scene = preload("res://scenes/ui.tscn")
	ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	
	if player:
		player.player_health_changed.connect(ui_instance.set_hearts)
		player.player_died.connect(_on_player_died)
	
	score_changed.connect(ui_instance.set_score)
	streak_changed.connect(ui_instance.set_streak)
	
	if ui_instance:
		ui_instance.set_score(score)
		ui_instance.set_streak(streak)
		if ui_instance.has_method("set_hearts") and player:
			ui_instance.set_hearts(player.current_lives)

	# Timer de racha
	streak_timer = Timer.new()
	streak_timer.wait_time = 3.0  # 3 segundos para mantener la racha
	streak_timer.one_shot = true
	streak_timer.timeout.connect(_on_streak_timeout)
	add_child(streak_timer)

	_update_shader_visibility()
	streak_changed.connect(_on_streak_changed)

# Cambio de fondo y arma cada 30 segundos
func _on_contador_timer_timeout() -> void:
	if tiempo_restante > 0:
		tiempo_restante -= 1
		contador_label.text = str(tiempo_restante)
	else:
		tiempo_restante = 30
		oleada_actual = 0  # Reiniciar oleadas al cambiar de fondo
		enemies_to_spawn.clear()  # Limpiar enemigos pendientes
		cambiar_fondo()
		# 🔥 Cambiar al arma correspondiente al nuevo fondo
		switch_to_weapon(indice_fondo % weapon_array.size())

func cambiar_fondo() -> void:
	if fondos.size() == 0:
		return
	
	indice_fondo = (indice_fondo + 1) % fondos.size()
	fondo.texture = fondos[indice_fondo]
	emit_signal("mapa_cambiado", indice_fondo)
	print("Cambiando a mapa: ", indice_fondo)
	_update_shader_visibility()
	apply_skin_to_player(indice_fondo)

func switch_to_weapon(index: int) -> void:
	if index < 0 or index >= weapon_array.size():
		print("ERROR: índice de arma inválido: ", index)
		return

	if player:
		# Esperar a que se limpie el arma anterior
		await player.clear_current_weapon()

	# 🔥 DETERMINAR QUÉ ARMA USAR SEGÚN EL ÍNDICE
	match index:
		0:  # Fondo 0 → Puño
			print("🔊 Cambiando a PUÑO (fondo ", index, ")")
			if player.has_method("switch_to_fist"):
				await player.switch_to_fist()  # 🔥 ESPERAR aquí también
		1:  # Fondo 1 → Hand/Proyectil
			print("🔊 Cambiando a HAND (fondo ", index, ")")
			if player.has_method("switch_to_hand"):
				await player.switch_to_hand()  # 🔥 ESPERAR aquí también
		2:  # Fondo 2 → Espada
			print("🔊 Cambiando a ESPADA (fondo ", index, ")")
			if player.has_method("switch_to_sword"):
				await player.switch_to_sword()  # 🔥 ESPERAR aquí también
		_:
			print("ERROR: Índice de arma no reconocido: ", index)

# Sistema de oleadas con spawn progresivo
func _on_oleada_timer_timeout() -> void:
	# Si no hay enemigos pendientes, crear nueva oleada
	if enemies_to_spawn.size() == 0:
		if oleada_actual < max_oleadas:
			oleada_actual += 1
			print("Oleada: ", oleada_actual)

			# Calcular cantidad de enemigos para esta oleada
			var cantidad = enemigos_por_oleada + (oleada_actual - 1) * enemigos_extra_cada_oleada
			
			# Agregar enemigos normales
			for i in cantidad:
				enemies_to_spawn.append(enemigo_scene)

			# Cada 3 oleadas agregar un enemigo fuerte
			if oleada_actual % 3 == 0:
				enemies_to_spawn.append(enemigo_fuerte_scene)
				
			print("Nueva oleada con ", enemies_to_spawn.size(), " enemigos")
		else:
			return  # Máximo de oleadas alcanzado

	# Spawnear un enemigo por tick
	if enemies_to_spawn.size() > 0:
		var scene_to_spawn = enemies_to_spawn.pop_front()
		spawn_mob(scene_to_spawn)

func spawn_mob(scene: PackedScene) -> void:
	if not player or not is_instance_valid(player):
		return
		
	var new_mob = scene.instantiate()
	
	# Spawnear en un radio alrededor del jugador
	var spawn_distance = 250.0
	var angle = randf() * 2 * PI
	var spawn_position = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance
	
	new_mob.global_position = spawn_position
	
	# Conectar señal de muerte del enemigo
	if new_mob.has_signal("enemy_killed"):
		new_mob.enemy_killed.connect(_on_enemy_killed)
	
	add_child(new_mob)
	print("Enemigo spawnedo en: ", new_mob.global_position)

# Sistema de puntuación y racha
func _on_enemy_killed(points: int = 100) -> void:
	score += points
	streak += 1
	
	emit_signal("score_changed", score)
	emit_signal("streak_changed", streak)
	
	# Reiniciar timer de racha
	streak_timer.start()
	
	print("Enemigo eliminado! Score: ", score, " | Racha: x", streak)

func _on_streak_timeout() -> void:
	if streak > 0:
		print("¡Racha perdida! Alcanzaste racha x", streak)
		streak = 0
		emit_signal("streak_changed", streak)
		
		# Desactivar power-up si estaba activo
		if is_player_powered_up:
			is_player_powered_up = false
			if player and player.has_method("set_power_up"):
				player.set_power_up(false)

func _on_streak_changed(new_streak: int) -> void:
	streak = new_streak
	handle_power_up(new_streak)

func handle_power_up(current_streak: int) -> void:
	var should_be_powered_up = (current_streak >= power_up_threshold)
	
	if should_be_powered_up and not is_player_powered_up:
		# Activar power-up
		is_player_powered_up = true
		if player and player.has_method("set_power_up"):
			player.set_power_up(true)
		print("🎯 ¡POWER-UP ACTIVADO! Racha: x", current_streak)
		
	elif not should_be_powered_up and is_player_powered_up:
		# Desactivar power-up
		is_player_powered_up = false
		if player and player.has_method("set_power_up"):
			player.set_power_up(false)
		print("🔻 Power-up desactivado")

# Manejo de shader y efectos visuales
func _update_shader_visibility() -> void:
	if shader_rect:
		shader_rect.visible = (indice_fondo == fondo_con_shader)

# Manejo de muerte del jugador
func _on_player_died() -> void:
	print("Jugador murió - Game Over")
	
	# Mostrar pantalla de game over o reiniciar
	get_tree().paused = true
	
	# Opcional: Esperar y reiniciar
	await get_tree().create_timer(2.0).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()

# Función para limpiar enemigos (útil para debugging)
func clear_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_to_spawn.clear()
	print("Todos los enemigos eliminados")

# Función para avanzar manualmente (debugging)
func skip_to_next_background() -> void:
	tiempo_restante = 1
	_on_contador_timer_timeout()

func apply_skin_to_player(map_index: int) -> void:
	if player and player.has_method("change_skin"):
		# Asignar skin según el índice del mapa (0, 1, 2)
		var skin_index = map_index % 3  # Asegurar que sea entre 0-2
		player.change_skin(skin_index)
		print("🎭 Aplicando skin ", skin_index, " para mapa ", map_index)
	else:
		print("❌ Player no tiene método change_skin")
