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
