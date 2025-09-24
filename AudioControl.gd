# res://ui/BusVolumeSlider.gd
extends HSlider

@export var audio_bus_name := "SFX"   # ตั้งเป็น "SFX" / "UI" / "Master" ตามต้องการ
var _bus_id: int = -1

func _ready() -> void:
	# หา bus
	_bus_id = AudioServer.get_bus_index(audio_bus_name)
	if _bus_id == -1:
		push_error("Bus '%s' not found" % audio_bus_name)
		return

	# ตั้งช่วงสไลเดอร์เป็น 0..100 (ปรับได้)
	min_value = 0
	max_value = 100
	step = 1

	# อ่านค่าปัจจุบันของ bus แล้วอัปเดตสไลเดอร์
	var db := AudioServer.get_bus_volume_db(_bus_id)
	var lin := db_to_linear(db)              # 0..1
	set_value_no_signal(round(lin * 100.0))  # map -> 0..100

	if not value_changed.is_connected(_on_value_changed):
		value_changed.connect(_on_value_changed)

func _on_value_changed(v: float) -> void:
	if _bus_id == -1: return
	# map 0..100 -> 0..1 แล้วแปลงเป็น dB
	# 0% ให้เท่ากับ -80 dB (เงียบ) เพื่อเลี่ยง -INF
	var db := -80.0 if v <= 0.0 else linear_to_db(v / 100.0)
	AudioServer.set_bus_volume_db(_bus_id, db)
