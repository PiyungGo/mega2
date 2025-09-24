# Piece.gd — ติดกับ Sprite2D ของหมากแต่ละตัว
extends Sprite2D

@export var tex_idle: Texture2D
@export var tex_walk_up: Texture2D
@export var tex_walk_down: Texture2D
@export var tex_walk_left: Texture2D
@export var tex_walk_right: Texture2D

@export var extra_scale: float = 1.0
@export var y_offset: float = -2.0

func _ready() -> void:
	centered = true
	if tex_idle: texture = tex_idle
	offset.y += y_offset
	if extra_scale != 1.0:
		scale *= Vector2(extra_scale, extra_scale)

func set_move_dir(dir: Vector2i) -> void:
	if dir == Vector2i(0,-1) and tex_walk_up:    texture = tex_walk_up
	elif dir == Vector2i(0,1) and tex_walk_down: texture = tex_walk_down
	elif dir == Vector2i(-1,0) and tex_walk_left: texture = tex_walk_left
	elif dir == Vector2i(1,0) and tex_walk_right: texture = tex_walk_right
	elif tex_idle:
		texture = tex_idle

func set_idle() -> void:
	if tex_idle:
		texture = tex_idle

var _shake_tween: Tween
var _is_shaking := false
var _base_pos := Vector2.ZERO

func play_hit_shake(duration: float = 0.28, amplitude: float = 8.0, vibrato: int = 12) -> void:
	# ยกเลิกเอฟเฟกต์เดิมถ้ามี และรีเซ็ตตำแหน่ง
	if _is_shaking and _shake_tween:
		_shake_tween.kill()
		global_position = _base_pos

	_is_shaking = true
	_base_pos = global_position

	var step_time: float = duration / float(max(vibrato, 1))
	var amp := amplitude
	var tw := create_tween()
	_shake_tween = tw

	# ส่ายแบบสุ่มทิศ และค่อย ๆ เบาลง
	for i in range(vibrato):
		var dir := Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized()
		tw.tween_property(self, "global_position", _base_pos + dir * amp, step_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		amp *= 0.85

	# คืนตำแหน่งเดิม
	tw.tween_property(self, "global_position", _base_pos, 0.06)
	await tw.finished
	_is_shaking = false
