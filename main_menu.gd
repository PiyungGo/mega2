extends Control


@onready var main_button: VBoxContainer = $"Main button"
@onready var option: Panel = $option
func _ready():
	main_button.visible = true
	option.visible = false
	
func _on_Start_pressed() -> void:
	get_tree().change_scene_to_file("res://board.tscn")



func _on_setting_pressed() -> void:
	print("Settings pressed")
	main_button.visible = false
	option.visible = true
	


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_option_pressed() -> void:
	_ready()
