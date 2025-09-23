extends Control

@onready var main_button: VBoxContainer = $"Main button"
@onready var option: Panel = $option

# Panels
@onready var panel2: Panel = $Panel2
@onready var panel_3: Panel = $Panel3
@onready var panel_4: Panel = $Panel4
@onready var panel_5: Panel = $Panel5
@onready var panel_6: Panel = $Panel6
@onready var panel_7: Panel = $Panel7
@onready var panel_8: Panel = $Panel8
@onready var panel_9: Panel = $Panel9
@onready var panel_10: Panel = $Panel10

# ====== เนื้อหาแต่ละหน้า (ไว้แก้ใน Editor) ======
@onready var guide_text: Label = $Panel2/Label/Pages/GuideText
@onready var guide_image: TextureRect = $Panel2/Label/Pages/GuideImage
@onready var guide_text_1: Label = $Panel3/Label/Pages/GuideText1
@onready var guide_image_1: TextureRect = $Panel3/Label/Pages/GuideImage1
@onready var guide_text_2: Label = $Panel4/Label/Pages/GuideText2
@onready var guide_image_2: TextureRect = $Panel4/Label/Pages/GuideImage2
@onready var guide_text_3: Label = $Panel5/Label/Pages/GuideText3
@onready var guide_image_3: TextureRect = $Panel5/Label/Pages/GuideImage3
@onready var guide_text_4: Label = $Panel6/Label/Pages/GuideText4
@onready var guide_image_4: TextureRect = $Panel6/Label/Pages/GuideImage4
@onready var guide_text_5: Label = $Panel7/Label/Pages/GuideText5
@onready var guide_image_5: TextureRect = $Panel7/Label/Pages/GuideImage5
@onready var guide_text_6: Label = $Panel8/Label/Pages/GuideText6
@onready var guide_image_6: TextureRect = $Panel8/Label/Pages/GuideImage6
@onready var guide_text_7: Label = $Panel9/Label/Pages/GuideText7
@onready var guide_image_7: TextureRect = $Panel9/Label/Pages/GuideImage7
@onready var guide_text_8: Label = $Panel10/Label/Pages/GuideText8
@onready var guide_image_8: TextureRect = $Panel10/Label/Pages/GuideImage8

# ====== ปุ่ม Next ======
@onready var next_button: Button   = $Panel2/NextButton
@onready var next_button_1: Button = $Panel3/NextButton1
@onready var next_button_2: Button = $Panel4/NextButton2
@onready var next_button_3: Button = $Panel5/NextButton3
@onready var next_button_4: Button = $Panel6/NextButton4
@onready var next_button_5: Button = $Panel7/NextButton5
@onready var next_button_6: Button = $Panel8/NextButton6
@onready var next_button_7: Button = $Panel9/NextButton7
@onready var next_button_8: Button = $Panel10/NextButton8

# ====== ปุ่ม Back เล็กซ้ายล่าง (ย้อนหน้า) ======
@onready var back_button:   Button = get_node_or_null("Panel2/BackButton")   # หน้า 2 (จะ disabled)
@onready var back_button_1: Button = get_node_or_null("Panel3/BackButton1")  # หน้า 3 → 2
@onready var back_button_2: Button = get_node_or_null("Panel4/BackButton2")  # หน้า 4 → 3
@onready var back_button_3: Button = get_node_or_null("Panel5/BackButton3")  # หน้า 5 → 4
@onready var back_button_4: Button = get_node_or_null("Panel6/BackButton4")  # หน้า 6 → 5
@onready var back_button_5: Button = get_node_or_null("Panel7/BackButton5")  # หน้า 7 → 6
@onready var back_button_6: Button = get_node_or_null("Panel8/BackButton6")  # หน้า 8 → 7
@onready var back_button_7: Button = get_node_or_null("Panel9/BackButton7")  # หน้า 9 → 8
@onready var back_button_8: Button = get_node_or_null("Panel10/BackButton8") # หน้า 10 → 9

# ====== ปุ่ม Back กลาง (กลับเมนูหลัก) ======
@onready var back2_p2:  Button = get_node_or_null("Panel2/Back2")
@onready var back2_p3:  Button = get_node_or_null("Panel3/Back2")
@onready var back2_p4:  Button = get_node_or_null("Panel4/Back2")
@onready var back2_p5:  Button = get_node_or_null("Panel5/Back2")
@onready var back2_p6:  Button = get_node_or_null("Panel6/Back2")
@onready var back2_p7:  Button = get_node_or_null("Panel7/Back2")
@onready var back2_p8:  Button = get_node_or_null("Panel8/Back2")
@onready var back2_p9:  Button = get_node_or_null("Panel9/Back2")
@onready var back2_p10: Button = get_node_or_null("Panel10/Back2")

# ====== เสียงคลิก ======
@onready var click_sfx: AudioStreamPlayer = get_node_or_null("ClickSfx")

# ====== สถานะ ======
var _panels: Array[Panel] = []
var _current_idx := 0

func _ready() -> void:
	main_button.visible = true
	option.visible = false

	# <<< ขยายให้ครบถึง Panel10 >>>
	_panels = [panel2, panel_3, panel_4, panel_5, panel_6, panel_7, panel_8, panel_9, panel_10]
	for p in _panels:
		if p:
			p.visible = false

	_connect_buttons()
	_wire_click_sounds()

# ─────────────────────────────────────────────────────────────
# ต่อสัญญาณปุ่มทั้งหมด
func _connect_buttons() -> void:
	# Next → ไปหน้าถัดไป
	if next_button   and not next_button.pressed.is_connected(_go_p3):  next_button.pressed.connect(_go_p3)
	if next_button_1 and not next_button_1.pressed.is_connected(_go_p4): next_button_1.pressed.connect(_go_p4)
	if next_button_2 and not next_button_2.pressed.is_connected(_go_p5): next_button_2.pressed.connect(_go_p5)
	if next_button_3 and not next_button_3.pressed.is_connected(_go_p6): next_button_3.pressed.connect(_go_p6)
	if next_button_4 and not next_button_4.pressed.is_connected(_go_p7): next_button_4.pressed.connect(_go_p7)
	if next_button_5 and not next_button_5.pressed.is_connected(_go_p8): next_button_5.pressed.connect(_go_p8)
	if next_button_6 and not next_button_6.pressed.is_connected(_go_p9): next_button_6.pressed.connect(_go_p9)
	if next_button_7 and not next_button_7.pressed.is_connected(_go_p10): next_button_7.pressed.connect(_go_p10)
	# Panel10 ปกติไม่มี next_button_8 (ถ้ามีและอยากต่อเพิ่มค่อยใส่)

	# Back เล็กซ้ายล่าง → ย้อนหน้า (Panel2 ไม่มีหน้าก่อนหน้า: ให้กดไม่ได้)
	if back_button   and not back_button.pressed.is_connected(_noop):         back_button.pressed.connect(_noop)
	if back_button_1 and not back_button_1.pressed.is_connected(_back_to_p2): back_button_1.pressed.connect(_back_to_p2)
	if back_button_2 and not back_button_2.pressed.is_connected(_back_to_p3): back_button_2.pressed.connect(_back_to_p3)
	if back_button_3 and not back_button_3.pressed.is_connected(_back_to_p4): back_button_3.pressed.connect(_back_to_p4)
	if back_button_4 and not back_button_4.pressed.is_connected(_back_to_p5): back_button_4.pressed.connect(_back_to_p5)
	if back_button_5 and not back_button_5.pressed.is_connected(_back_to_p6): back_button_5.pressed.connect(_back_to_p6)
	if back_button_6 and not back_button_6.pressed.is_connected(_back_to_p7): back_button_6.pressed.connect(_back_to_p7)
	if back_button_7 and not back_button_7.pressed.is_connected(_back_to_p8): back_button_7.pressed.connect(_back_to_p8)
	if back_button_8 and not back_button_8.pressed.is_connected(_back_to_p9): back_button_8.pressed.connect(_back_to_p9)

	# Back กลาง (Back2) → กลับเมนูหลัก
	if back2_p2  and not back2_p2.pressed.is_connected(_close_guide):  back2_p2.pressed.connect(_close_guide)
	if back2_p3  and not back2_p3.pressed.is_connected(_close_guide):  back2_p3.pressed.connect(_close_guide)
	if back2_p4  and not back2_p4.pressed.is_connected(_close_guide):  back2_p4.pressed.connect(_close_guide)
	if back2_p5  and not back2_p5.pressed.is_connected(_close_guide):  back2_p5.pressed.connect(_close_guide)
	if back2_p6  and not back2_p6.pressed.is_connected(_close_guide):  back2_p6.pressed.connect(_close_guide)
	if back2_p7  and not back2_p7.pressed.is_connected(_close_guide):  back2_p7.pressed.connect(_close_guide)
	if back2_p8  and not back2_p8.pressed.is_connected(_close_guide):  back2_p8.pressed.connect(_close_guide)
	if back2_p9  and not back2_p9.pressed.is_connected(_close_guide):  back2_p9.pressed.connect(_close_guide)
	if back2_p10 and not back2_p10.pressed.is_connected(_close_guide): back2_p10.pressed.connect(_close_guide)

# ─────────────────────────────────────────────────────────────
# เมนูหลัก
func _on_Start_pressed() -> void:
	get_tree().change_scene_to_file("res://board.tscn")

func _on_setting_pressed() -> void:
	main_button.visible = false
	option.visible = true

func _on_exit_pressed() -> void:
	# ปุ่ม “ออก” ในเมนูหลัก — ปิดเกมทั้งหมด
	get_tree().quit()

func _on_back_option_pressed() -> void:
	option.visible = false
	_close_guide()

# ─────────────────────────────────────────────────────────────
# เปิดคู่มือ
func _on_guide_pressed() -> void:
	main_button.visible = false
	option.visible = false
	_show_panel(panel2)

# Next
func _go_p3()  -> void: _show_panel(panel_3)
func _go_p4()  -> void: _show_panel(panel_4)
func _go_p5()  -> void: _show_panel(panel_5)
func _go_p6()  -> void: _show_panel(panel_6)
func _go_p7()  -> void: _show_panel(panel_7)
func _go_p8()  -> void: _show_panel(panel_8)
func _go_p9()  -> void: _show_panel(panel_9)
func _go_p10() -> void: _show_panel(panel_10)

# Back เล็กซ้ายล่าง (ย้อนหน้า)
func _back_to_p2() -> void: _show_panel(panel2)
func _back_to_p3() -> void: _show_panel(panel_3)
func _back_to_p4() -> void: _show_panel(panel_4)
func _back_to_p5() -> void: _show_panel(panel_5)
func _back_to_p6() -> void: _show_panel(panel_6)
func _back_to_p7() -> void: _show_panel(panel_7)
func _back_to_p8() -> void: _show_panel(panel_8)
func _back_to_p9() -> void: _show_panel(panel_9)

# ไม่มีหน้าก่อนหน้า (ใช้กับ Back เล็กของหน้าแรก)
func _noop() -> void: pass

# ปิดคู่มือ → เมนูหลัก
func _close_guide() -> void:
	for p in _panels:
		if p:
			p.visible = false
	main_button.visible = true
	option.visible = false

# helper: แสดง panel เป้าหมาย
func _show_panel(target: Panel) -> void:
	for i in _panels.size():
		var show := (_panels[i] == target)
		if _panels[i]:
			_panels[i].visible = show
		if show:
			_current_idx = i

	# จัด z และเปิด/ปิด Back เล็กของหน้าแรก
	if target and target is Control:
		target.move_to_front()
	if back_button:
		back_button.disabled = (_current_idx == 0) # หน้าแรกกดไม่ได้

# ─────────────────────────────────────────────────────────────
# เสียงคลิก
func _wire_click_sounds() -> void:
	for b in get_tree().get_nodes_in_group("ui_click"):
		if b is Button and not b.pressed.is_connected(_on_any_button_pressed):
			b.pressed.connect(_on_any_button_pressed.bind(b))

func _on_any_button_pressed(_btn: Button) -> void:
	if click_sfx and click_sfx.stream:
		if click_sfx.playing: click_sfx.stop()
		click_sfx.play()
