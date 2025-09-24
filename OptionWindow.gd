# res://OptionWindow.gd
extends Control

@export var settings_btn: Button        # ลากปุ่ม SettingsBtn มาวางช่องนี้
@export var back_btn: Button            # ลากปุ่ม Back ในหน้าต่างมาวาง
@export var start_hidden := true        # เริ่มแบบซ่อน

func _ready() -> void:
	if start_hidden:
		hide()
		# ให้ปุ่มเริ่มไม่ถูกกด (กันสถานะไม่ตรงกัน)
		if settings_btn:
			settings_btn.set_pressed_no_signal(false)

	# ให้ SettingsBtn เป็น toggle เสมอ และเชื่อมสัญญาณให้เอง
	if settings_btn:
		settings_btn.toggle_mode = true
		if not settings_btn.toggled.is_connected(_on_settings_toggled):
			settings_btn.toggled.connect(_on_settings_toggled)

	# เชื่อมปุ่ม Back ให้ปิดหน้าต่างและคลายสถานะปุ่ม
	if back_btn and not back_btn.pressed.is_connected(_on_back_pressed):
		back_btn.pressed.connect(_on_back_pressed)

func _on_settings_toggled(on: bool) -> void:
	visible = on

func _on_back_pressed() -> void:
	hide()
	if settings_btn:
		settings_btn.set_pressed_no_signal(false)

# เผื่ออยากสั่งจากที่อื่น
func open() -> void:    show()
func close() -> void:   hide()
func toggle() -> void:  visible = not visible


func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.


func _on_settings_btn_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
