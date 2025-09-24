extends Control

signal rolled(value: int)
signal closed

@export var roll_duration: float = 3.0
@export var tick: float = 0.08
@export var title_text: String = "ทอยเต๋าสุ่มแต้มเดินทาง"

@onready var panel: Panel          = $Panel
@onready var title: Label          = $Panel/Title
@onready var result_label: Label   = $Panel/Result
@onready var roll_button: Button   = $Panel/Rollbutton
@onready var close_btn: Button     = $Panel/CloseBin


var _is_rolling := false
var _final_value := 0
var _has_result := false           # ← จะ true หลังสุ่มเสร็จ

# ตัวช่วยสำหรับเล่นเสียงครั้งเดียว
func _play_once(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.bus = "Master"               # หรือเปลี่ยนเป็นบัสอื่นถ้าคุณมี
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.stream = stream
	p.finished.connect(p.queue_free)
	p.play()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	hide()
	title.text = title_text
	result_label.text = ""
	if roll_button and not roll_button.pressed.is_connected(_on_roll_pressed):
		roll_button.pressed.connect(_on_roll_pressed)

	if close_btn:
		close_btn.visible = false
		close_btn.disabled = false  # ✅ เปิดให้ใช้งาน
		if not close_btn.pressed.is_connected(_on_close_pressed):
			close_btn.pressed.connect(_on_close_pressed)

func open() -> void:
	_is_rolling = false
	_has_result = false
	_final_value = 0
	result_label.text = ""
	if roll_button:
		roll_button.disabled = false
		roll_button.grab_focus()
	if close_btn:
		close_btn.visible = false
	show()

func close() -> void:
	hide()
	emit_signal("closed")

func _on_close_pressed() -> void:
	# ปุ่ม X ใช้ได้เฉพาะหลังมีผลลัพธ์
	if _has_result:
		close()

func _on_roll_pressed() -> void:
	if _is_rolling: return
	_is_rolling = true
	if roll_button:
		roll_button.disabled = true
	randomize()
	SFX.play_ui("dice")

	var elapsed := 0.0
	while elapsed < roll_duration:
		var v := randi_range(1, 6)
		result_label.text = str(v)
		await get_tree().create_timer(tick).timeout
		elapsed += tick

	_final_value = randi_range(1, 6)
	result_label.text = str(_final_value)
	_is_rolling = false
	_has_result = true

	# โชว์ปุ่ม X เมื่อสุ่มเสร็จ
	if close_btn:
		close_btn.visible = true
		close_btn.grab_focus()

	emit_signal("rolled", _final_value)
const SFX_DICE_START := preload("res://Asset_UWU/Sound/dice-142528.mp3")
func play_dice_start(vol := -2.0): _play_once(SFX_DICE_START, vol)


# (ออปชัน) กด Esc เพื่อปิดเมื่อมีผลลัพธ์แล้ว
func _unhandled_input(e: InputEvent) -> void:
	if _has_result and e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		close()

# (ออปชัน) คลิกนอก Panel เพื่อปิด หลังมีผลลัพธ์แล้ว
func _gui_input(event: InputEvent) -> void:
	if not _has_result:
		return
	if event is InputEventMouseButton and event.pressed:
		var gp: Vector2 = (event as InputEventMouseButton).global_position
		var rect: Rect2 = panel.get_global_rect()
		if not rect.has_point(gp):
			close()
