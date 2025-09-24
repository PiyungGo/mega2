# ติดที่โหนด 'option'
extends Node

func set_visible(v: bool) -> void:
	for c in get_children():
		if c is CanvasItem:
			(c as CanvasItem).visible = v


func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.
