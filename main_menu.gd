extends Control

@onready var main_button: VBoxContainer = $"Main button"
@onready var option: Panel = $option
@onready var panel2: Panel = $Panel2
@onready var guide_text: Label = $Panel2/GuideText
@onready var next_button: Button = $Panel2/NextButton
@onready var back_button: Button = $Panel2/BackButton

# ====== เพิ่ม: ตัวเล่นเสียงคลิก ======
@onready var click_sfx: AudioStreamPlayer = $ClickSfx
# =====================================

var guide_pages := [
	"หน้า 1: วิธีเล่นพื้นฐาน",
	"หน้า 2: การทอยลูกเต๋า",
	"หน้า 3: การ์ด/การโจมตี",
	"หน้า 4: การ์ด/การโจมตี",
	"หน้า 5: การ์ด/การโจมตี"
]
var guide_index := 0

func _ready():
	main_button.visible = true
	option.visible = false
	panel2.visible = false

	# ต่อสัญญาณ (กันพลาดต่อไม่ติด)
	if not next_button.pressed.is_connected(_on_NextButton_pressed):
		next_button.pressed.connect(_on_NextButton_pressed)
	if not back_button.pressed.is_connected(_on_BackButton_pressed):
		back_button.pressed.connect(_on_BackButton_pressed)

	# ====== เพิ่ม: ต่อสัญญาณปุ่มทุกอันในกลุ่ม ui_click ให้เล่นเสียง ======
	_wire_click_sounds()
	# =======================================================================

func _wire_click_sounds() -> void:
	# หา Button ทุกอันที่อยู่ในกลุ่ม ui_click แล้วให้มากดเรียกฟังก์ชันเดียวกัน
	for b in get_tree().get_nodes_in_group("ui_click"):
		if b is Button and not b.pressed.is_connected(_on_any_button_pressed):
			b.pressed.connect(_on_any_button_pressed.bind(b))

func _on_any_button_pressed(_btn: Button) -> void:
	# เล่นเสียงคลิก (กันเสียงทับซ้อนด้วยการ stop ก่อน)
	if click_sfx and click_sfx.stream:
		if click_sfx.playing:
			click_sfx.stop()
		click_sfx.play()

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
	guide_index = 0
	_update_guide_page()

func _on_NextButton_pressed() -> void:
	if guide_index < guide_pages.size() - 1:
		guide_index += 1
		_update_guide_page()

func _on_BackButton_pressed() -> void:
	if panel2.visible and guide_index > 0:
		guide_index -= 1
		_update_guide_page()
	else:
		# อยู่หน้าแรกแล้ว กด Back ให้กลับเมนูหลัก
		panel2.visible = false
		main_button.visible = true

func _update_guide_page() -> void:
	guide_text.text = guide_pages[guide_index]
	next_button.disabled = (guide_index >= guide_pages.size() - 1)
	back_button.disabled = (guide_index == 0)
