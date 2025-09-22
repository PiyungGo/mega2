@tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/card_editor/card_editor.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	dock.visible = true

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()
