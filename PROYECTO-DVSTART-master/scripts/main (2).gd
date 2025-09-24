extends Node2D

# Señal para notificar el cambio de mapa
signal mapa_cambiado(indice_mapa)

@onready var fondo: Sprite2D = $background
@onready var contador_label: Label = $Player/contador

@export var fondos: Array[Texture2D] = []

var indice_fondo: int = 0
var tiempo_restante: int = 30 

# --- Control de oleadas ---
var oleada_actual: int = 0
var max_oleadas: int = 6

@export var enemigo_scene: PackedScene = preload("res://scenes/enemigo.tscn")
@export var enemigo_fuerte_scene: PackedScene = preload("res://scenes/enemigo_fuerte.tscn")

# --- Configuración ---
@export var enemigos_por_oleada: int = 3  # cantidad de enemigos normales por oleada
@export var enemigos_extra_cada_oleada: int = 1  # para que la dificultad suba (se suma a cada oleada)

func _ready() -> void:
	if fondos.size() > 0:
		fondo.texture = fondos[indice_fondo]
	contador_label.text = str(tiempo_restante)

	# Timer para el contador de 30s
	var contador_timer = Timer.new()
	contador_timer.wait_time = 1.0
	contador_timer.one_shot = false
	contador_timer.autostart = true
	add_child(contador_timer)
	contador_timer.connect("timeout", Callable(self, "_on_contador_timer_timeout"))

	# Timer para las oleadas
	var oleada_timer = Timer.new()
	oleada_timer.wait_time = 4.0 # cada 4 segundos lanza la siguiente oleada
	oleada_timer.one_shot = false
	oleada_timer.autostart = true
	add_child(oleada_timer)
	oleada_timer.connect("timeout", Callable(self, "_on_oleada_timer_timeout"))

func _on_contador_timer_timeout() -> void:
	if tiempo_restante > 0:
		tiempo_restante -= 1
		contador_label.text = str(tiempo_restante)
	else:
		# Reinicio: cambia mapa y reinicia oleadas
		cambiar_fondo()
		tiempo_restante = 30 
		oleada_actual = 0
		print("Reiniciando oleadas con nuevo mapa")

func cambiar_fondo() -> void:
	if fondos.size() == 0:
		return
	indice_fondo = (indice_fondo + 1) % fondos.size()
	fondo.texture = fondos[indice_fondo]
	emit_signal("mapa_cambiado", indice_fondo)
	print("Cambiando a mapa: ", indice_fondo)

# --- Oleadas ---
func _on_oleada_timer_timeout() -> void:
	if oleada_actual < max_oleadas:
		oleada_actual += 1
		print("Oleada: ", oleada_actual)

		# calcular cantidad de enemigos normales para esta oleada
		var cantidad = enemigos_por_oleada + (oleada_actual - 1) * enemigos_extra_cada_oleada

		# spawnear enemigos normales
		for i in cantidad:
			spawn_mob(enemigo_scene)

		# cada 3 oleadas además aparece un enemigo fuerte
		if oleada_actual % 3 == 0:
			spawn_mob(enemigo_fuerte_scene)

	else:
		print("Ya se lanzaron todas las oleadas de esta ronda")

func spawn_mob(scene: PackedScene) -> void:
	var new_mob = scene.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)
