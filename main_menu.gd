extends Control

@onready var main_button: VBoxContainer = $"Main button"
@onready var option: Panel = $option
@onready var panel2: Panel = $Panel2   # ต้องมี Node ชื่อ Panel2 ใน Scene

func _ready():
	main_button.visible = true
	option.visible = false
	panel2.visible = false

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

func _on_guide_pressed() -> void:
	print("guide pressed")
	main_button.visible = false
	panel2.visible = true
