extends Control


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_screen.tscn")


func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
