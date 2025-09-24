# res://SFX.gd
extends Node

# === ใส่ไฟล์เสียงใน Inspector ได้เลย (ลากหลายไฟล์เพื่อสุ่มได้) ===
@export var attack_hit   : Array[AudioStream] = []   # โจมตี/โดนโจมตี
@export var block        : Array[AudioStream] = []   # ป้องกันไว้ได้
@export var shield_up    : Array[AudioStream] = []   # เสริมแต้มป้องกัน
@export var warp         : Array[AudioStream] = []   # วาร์ป
@export var card_root    : Array[AudioStream] = []   # การ์ด Root Access Heist
@export var card_freeze  : Array[AudioStream] = []   # การ์ด Process Freeze
@export var card_failure : Array[AudioStream] = []   # การ์ด System Failure
@export var dice         : Array[AudioStream] = []   # ทอยเต๋า
@export var move_step    : Array[AudioStream] = []   # เดินหนึ่งช่อง/ช่วง
@export var card_select  : Array[AudioStream] = []   # คลิกเลือกการ์ด
@export var ui_click     : Array[AudioStream] = []   # ปุ่มทั่วไป

@export_range(-40, 6, 0.1) var default_volume_db: float = -4.0
@export var sfx_bus := "SFX"
@export var ui_bus  := "UI"
@export var pitch_jitter: float = 0.04  # สุ่มโทนนิด ๆ กันซ้ำ

func _pick(arr: Array[AudioStream]) -> AudioStream:
	return null if arr.is_empty() else arr[randi() % arr.size()]

func _spawn_player(stream: AudioStream, bus: String, at: Node2D = null, vol_db: float = default_volume_db) -> void:
	if stream == null: return
	var p: Node = AudioStreamPlayer2D.new() if at != null else AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = vol_db
	if p is AudioStreamPlayer:
		(p as AudioStreamPlayer).pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	if p is AudioStreamPlayer2D:
		var pp := (p as AudioStreamPlayer2D)
		pp.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
		pp.global_position = at.global_position
	var parent := at if at != null else get_tree().current_scene
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

# --------- API เรียกง่าย ---------
func play_world(key: String, at: Node2D, vol_db: float = default_volume_db) -> void:
	match key:
		"attack_hit":   _spawn_player(_pick(attack_hit),   sfx_bus, at, vol_db)
		"block":        _spawn_player(_pick(block),        sfx_bus, at, vol_db)
		"shield_up":    _spawn_player(_pick(shield_up),    sfx_bus, at, vol_db)
		"warp":         _spawn_player(_pick(warp),         sfx_bus, at, vol_db)
		"move_step":    _spawn_player(_pick(move_step),    sfx_bus, at, vol_db)
		_: pass

func play_ui(key: String, vol_db: float = default_volume_db) -> void:
	match key:
		"card_root":    _spawn_player(_pick(card_root),    ui_bus, null, vol_db)
		"card_freeze":  _spawn_player(_pick(card_freeze),  ui_bus, null, vol_db)
		"card_failure": _spawn_player(_pick(card_failure), ui_bus, null, vol_db)
		"dice":         _spawn_player(_pick(dice),         ui_bus, null, vol_db)
		"card_select":  _spawn_player(_pick(card_select),  ui_bus, null, vol_db)
		"ui_click":     _spawn_player(_pick(ui_click),     ui_bus, null, vol_db)
		_: pass


func _on_audio_control_value_changed(value: float) -> void:
	pass # Replace with function body.
	
	# ========= SFX diagnostics =========
func _bus_info(name: String) -> String:
	var idx := AudioServer.get_bus_index(name)
	if idx == -1:
		return "%s: NOT FOUND" % name
	var db := AudioServer.get_bus_volume_db(idx)
	var muted := AudioServer.is_bus_mute(idx)
	return "%s: idx=%d vol_db=%.1f muted=%s" % [name, idx, db, str(muted)]

func _find_listeners2d() -> Array:
	var root := get_tree().current_scene
	if root == null:
		return []
	return root.find_children("", "AudioListener2D", true, false)

func diag() -> void:
	print("\n=== SFX.diag ===")
	print("Autoload present at /root/SFX:", get_node_or_null("/root/SFX") == self)
	print(_bus_info(sfx_bus))
	print(_bus_info(ui_bus))
	print("arrays:",
		"attack_hit=", attack_hit.size(),
		"block=",      block.size(),
		"shield_up=",  shield_up.size(),
		"warp=",       warp.size(),
		"card_root=",  card_root.size(),
		"card_freeze=",card_freeze.size(),
		"card_failure=",card_failure.size(),
		"dice=",       dice.size(),
		"move_step=",  move_step.size(),
		"card_select=",card_select.size(),
		"ui_click=",   ui_click.size()
	)
	var listeners := _find_listeners2d()
	print("AudioListener2D count:", listeners.size())
	for l in listeners:
		print("  -", l.get_path(), "current=", (l as AudioListener2D).current)
	print("default_volume_db=", default_volume_db, " sfx_bus=", sfx_bus, " ui_bus=", ui_bus)
	print("=================\n")

# ทดลองยิงเสียงที่ควรได้ยินเสมอ (ไม่พึ่ง listener)
func test_ui_click() -> void:
	print("SFX.test_ui_click()")
	var st := _pick(ui_click)
	if st == null:
		print("  !! ui_click array is empty -> add 1+ files in SFX autoload")
	else:
		_spawn_player(st, ui_bus, null, default_volume_db)

# ทดลองยิงเสียงแบบ 2D (ต้องมี AudioListener2D)
func test_world(at: Node2D) -> void:
	print("SFX.test_world() at:", at)
	var st := _pick(move_step)
	if st == null:
		print("  !! move_step array is empty -> add files")
	else:
		_spawn_player(st, sfx_bus, at, default_volume_db)

# เปิด/ปิดการตรวจตอนเริ่มเกม
@export var debug_sound_on_start := false

func _ready() -> void:
	if debug_sound_on_start:
			call_deferred("_run_sound_diag_once")

func _run_sound_diag_once() -> void:
	print("\n=== SFX quick diag ===")
	_print_bus("Master")
	_print_bus(ui_bus)
	_print_bus(sfx_bus)

	# นับไฟล์ในช่องสำคัญ ๆ
	print("arrays: ui_click=", ui_click.size(),
		  " move_step=", move_step.size(),
		  " attack_hit=", attack_hit.size(),
		  " block=", block.size())

	# หา AudioListener2D ในซีน (สำหรับเสียง 2D)
	var listeners := []
	var root := get_tree().current_scene
	if root:
		listeners = root.find_children("", "AudioListener2D", true, false)
	print("AudioListener2D count:", listeners.size())
	for l in listeners:
		print("  -", l.get_path(), "current=", (l as AudioListener2D).current)

	print("default_volume_db=", default_volume_db, " sfx_bus=", sfx_bus, " ui_bus=", ui_bus)
	print("======================\n")

	# ยิงเสียงทดสอบ (UI: ไม่ต้องมี Listener)
	_test_ui_click()

	# ยิงเสียง 2D (ต้องมี AudioListener2D) — ยิงจาก root กลางฉาก
	if root and root is Node2D:
		_test_world(root)

func _print_bus(name: String) -> void:
	var idx := AudioServer.get_bus_index(name)
	if idx == -1:
		print(name, ": NOT FOUND")
		return
	print(name, ": idx=", idx, " db=", AudioServer.get_bus_volume_db(idx),
		  " muted=", AudioServer.is_bus_mute(idx))

func _test_ui_click() -> void:
	print("play test: ui_click")
	var st := _pick(ui_click)
	if st == null:
		print("  !! ui_click array empty (ใส่ไฟล์ใน Autoload SFX ช่อง UI Click)")
		return
	_spawn_player(st, ui_bus, null, default_volume_db)

func _test_world(at: Node2D) -> void:
	print("play test: move_step @", at.get_path())
	var st := _pick(move_step)
	if st == null:
		print("  !! move_step array empty (ใส่ไฟล์ใน Autoload SFX ช่อง Move Step)")
		return
	# กันกรณีระยะ/การลดทอนทำให้เงียบระหว่างเทส
	var old := default_volume_db
	_spawn_player(st, sfx_bus, at, old)
	# utils/sfx_once.gd (แนบกับโหนดไหนก็ได้ หรือวางไว้ในซีนหลัก)

func play(path_or_stream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.bus = "Master"               # ไม่ยุ่งกับ Bus
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.stream = (path_or_stream if typeof(path_or_stream) != TYPE_STRING
		else load(path_or_stream))
	p.finished.connect(p.queue_free)
	p.play()
