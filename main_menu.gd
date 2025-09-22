extends Control

@onready var main_button: VBoxContainer = $"Main button"
@onready var option: Panel = $option
@onready var panel2: Panel = $Panel2

# <<< แก้ path ให้ตรง Scene Tree ปัจจุบัน >>>
@onready var guide_text: Label = $Panel2/Label/Pages/GuideText
@onready var guide_image: TextureRect = $Panel2/Label/Pages/GuideImage

@onready var next_button: Button = $Panel2/NextButton
# รองรับทั้ง BackButton และ Back2 (เลือกอันที่มีอยู่จริง)
@onready var back_button: Button = $Panel2/BackButton if has_node("Panel2/BackButton") else $Panel2/Back2

# เสียงคลิก (มีค่อยเล่น ไม่มีข้ามได้)
@onready var click_sfx: AudioStreamPlayer = get_node_or_null("ClickSfx")

@export var use_label_initial_text := true

@export var guide_pages: Array[Dictionary] = [
	{"text": "หน้า 1: วิธีเล่นพื้นฐาน", "image": "res://assets/guide/page1.png"},
	{"text": "หน้า 2: การทอยลูกเต๋า", "image": "res://assets/guide/page2.png"},
	{"text": "หน้า 3: การ์ด/การโจมตี", "image": "res://assets/guide/page3.png"},
	{"text": "หน้า 4: กติกาGAME", "image": "res://assets/guide/page4.png"},
	{"text": "หน้า 5: การ์ด/การโจมตี", "image": ""} # ว่าง = ไม่แสดงรูป
]

var guide_index := 0
var _initial_label_text: String = ""
var _initial_image_texture: Texture2D = null

func _ready() -> void:
	main_button.visible = true
	option.visible = false
	panel2.visible = false

	# ต่อสัญญาณปุ่ม (กันพลาด)
	if next_button and not next_button.pressed.is_connected(_on_NextButton_pressed):
		next_button.pressed.connect(_on_NextButton_pressed)
	if back_button and not back_button.pressed.is_connected(_on_BackButton_pressed):
		back_button.pressed.connect(_on_BackButton_pressed)

	_wire_click_sounds()

func _wire_click_sounds() -> void:
	for b in get_tree().get_nodes_in_group("ui_click"):
		if b is Button and not b.pressed.is_connected(_on_any_button_pressed):
			b.pressed.connect(_on_any_button_pressed.bind(b))

func _on_any_button_pressed(_btn: Button) -> void:
	if click_sfx and click_sfx.stream:
		if click_sfx.playing: click_sfx.stop()
		click_sfx.play()

func _on_Start_pressed() -> void:
	get_tree().change_scene_to_file("res://board.tscn")

func _on_setting_pressed() -> void:
	main_button.visible = false
	option.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_back_option_pressed() -> void:
	option.visible = false
	panel2.visible = false
	main_button.visible = true

func _on_guide_pressed() -> void:
	main_button.visible = false
	option.visible = false
	panel2.visible = true
	guide_index = 0

	# ป้องกัน path ผิด
	if not is_instance_valid(guide_text) or not is_instance_valid(guide_image):
		push_error("GuideText หรือ GuideImage หาไม่เจอ (เช็คว่าอยู่ที่ $Panel2/Label/Pages/...)")
		return

	# เก็บข้อความ+รูปเดิมของหน้าแรก
	_initial_label_text = guide_text.text
	_initial_image_texture = guide_image.texture

	if use_label_initial_text and guide_pages.size() > 0:
		guide_pages[0]["text"] = _initial_label_text
		_update_nav_buttons()  # หน้าแรกให้คงข้อความจาก Label
	else:
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
		panel2.visible = false
		main_button.visible = true

func _update_guide_page() -> void:
	if guide_index == 0 and use_label_initial_text:
		# หน้า 1: ใช้ข้อความจาก Label; รูปจะใช้จากไฟล์ถ้ากำหนดไว้ ไม่งั้นใช้รูปเดิมใน Editor
		guide_text.text = _initial_label_text

		var img_path0 := ""
		if guide_pages.size() > 0 and guide_pages[0].has("image"):
			img_path0 = String(guide_pages[0]["image"])

		if img_path0 != "" and ResourceLoader.exists(img_path0):
			guide_image.texture = load(img_path0) as Texture2D
		else:
			guide_image.texture = _initial_image_texture
	else:
		# หน้าอื่น ๆ: ดึงจาก array
		var page := guide_pages[guide_index]
		if page.has("text"):
			guide_text.text = page["text"]

		var img_path := String(page["image"]) if page.has("image") else ""
		if img_path != "" and ResourceLoader.exists(img_path):
			guide_image.texture = load(img_path) as Texture2D
		else:
			guide_image.texture = null

	_update_nav_buttons()

func _update_nav_buttons() -> void:
	next_button.disabled = (guide_index >= guide_pages.size() - 1)
	back_button.disabled = (guide_index == 0)
