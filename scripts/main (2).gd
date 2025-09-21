extends Node2D

@onready var fondo: Sprite2D = $background
@onready var contador_label: Label = $Player/contador

@export var fondos: Array[Texture2D] = []

var indice_fondo: int = 0
var tiempo_restante: int = 30 

func _ready() -> void:
	if fondos.size() > 0:
		fondo.texture = fondos[indice_fondo]
	contador_label.text = str(tiempo_restante)

	var contador_timer = Timer.new()
	contador_timer.wait_time = 1.0
	contador_timer.one_shot = false
	contador_timer.autostart = true
	add_child(contador_timer)
	contador_timer.connect("timeout", Callable(self, "_on_contador_timer_timeout"))

func _on_contador_timer_timeout() -> void:
	if tiempo_restante > 0:
		tiempo_restante -= 1
		contador_label.text = str(tiempo_restante)
	else:
		cambiar_fondo()
		tiempo_restante = 30 

func cambiar_fondo() -> void:
	if fondos.size() == 0:
		return

	indice_fondo = (indice_fondo + 1) % fondos.size()
	fondo.texture = fondos[indice_fondo]
	print("Cambiando a fondo: ", indice_fondo)

func spawn_mob():
	var new_mob = preload("res://scenes/enemigo.tscn").instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)

func _on_timer_timeout() -> void:
	spawn_mob()
