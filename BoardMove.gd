# BoardMove.gd — ติดที่ Sprite2D ของกระดาน
extends Sprite2D

@export var BOARD_SIZE: int = 8
@export var CELL_SIZE: int = 64
@export var MAX_STEPS: int = 6

var BOARD_OFFSET: Vector2 = Vector2.ZERO
var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_piece: Sprite2D = null
var reachable: Array[Vector2i] = []
var parent_map: Dictionary = {}                   # Dictionary<Vector2i, Vector2i> (GDScript ไม่รองรับ generic ตรงๆ)
var board: Array = []                              # Array<Array> ของ Sprite2D หรือ null

@onready var pieces: Node = $Pieces

func _ready() -> void:
	_calc_board_offset()
	_init_board()
	_scan_pieces()
	queue_redraw()

func _draw() -> void:
	_draw_selection()
	_draw_reachable_dots()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var cell: Vector2i = _pixel_to_cell(e.position)
		if not _in_bounds(cell):
			return
		if selected_piece != null and _has_cell(reachable, cell):
			var path: Array[Vector2i] = _build_path(parent_map, cell)
			await _move_piece_step_by_step(selected_piece, selected_cell, path)
			selected_cell = cell
			_end_move_phase()
			return
		_select_piece_at(cell)

# ---------- Setup ----------
func _calc_board_offset() -> void:
	var tex_size: Vector2 = texture.get_size() * scale
	BOARD_OFFSET = global_position - tex_size * 0.5

func _init_board() -> void:
	board.clear()
	for _y in BOARD_SIZE:
		var row: Array = []
		row.resize(BOARD_SIZE)
		for x in BOARD_SIZE:
			row[x] = null
		board.append(row)

func _scan_pieces() -> void:
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			board[y][x] = null
	for n in pieces.get_children():
		if n is Sprite2D:
			var s: Sprite2D = n
			var c: Vector2i = _pixel_to_cell(s.global_position)
			if _in_bounds(c):
				board[c.y][c.x] = s

# ---------- Select / Reach ----------
func _select_piece_at(cell: Vector2i) -> void:
	_scan_pieces()
	var node: Variant = board[cell.y][cell.x]    # Sprite2D หรือ null
	if node == null:
		selected_piece = null
		selected_cell = Vector2i(-1, -1)
		reachable.clear()
		parent_map.clear()
		queue_redraw()
		return
	selected_piece = node as Sprite2D
	selected_cell = cell
	_compute_reachable(selected_cell, MAX_STEPS)
	queue_redraw()

func _compute_reachable(start: Vector2i, steps: int) -> void:
	reachable.clear()
	parent_map.clear()

	var q: Array = []                 # จะเก็บ [Vector2i, int]
	var visited: Dictionary = {}      # key: Vector2i, value: bool
	q.append([start, 0])
	visited[start] = true

	while q.size() > 0:
		var item: Array = q.pop_front()
		var c: Vector2i = item[0]
		var d: int = item[1]
		if d > steps:
			continue
		if c != start:
			reachable.append(c)
		if d == steps:
			continue
		for nb in _neighbors4(c):
			if not _in_bounds(nb): continue
			if board[nb.y][nb.x] != null and nb != start: continue
			if visited.has(nb): continue
			visited[nb] = true
			parent_map[nb] = c
			q.append([nb, d + 1])

func _build_path(parents: Dictionary, dest: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var cur: Vector2i = dest
	while parents.has(cur):
		path.push_front(cur)
		cur = parents[cur]
	return path

# ---------- Move ----------
func _move_piece_step_by_step(piece: Sprite2D, start_cell: Vector2i, path: Array[Vector2i]) -> void:
	if path.is_empty():
		return
	var cur: Vector2i = start_cell
	for step_cell in path:
		var dir: Vector2i = Vector2i(step_cell.x - cur.x, step_cell.y - cur.y)
		if "set_move_dir" in piece:
			piece.set_move_dir(dir)
		board[cur.y][cur.x] = null
		board[step_cell.y][step_cell.x] = piece
		cur = step_cell

		var t: Tween = create_tween()
		t.tween_property(piece, "global_position", _cell_center(step_cell), 0.14)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t.finished

	if "set_idle" in piece:
		piece.set_idle()

func _end_move_phase() -> void:
	reachable.clear()
	parent_map.clear()
	queue_redraw()

# ---------- Draw ----------
func _draw_selection() -> void:
	if selected_cell == Vector2i(-1, -1):
		return
	var r: Rect2 = Rect2(
		BOARD_OFFSET + Vector2(selected_cell.x, selected_cell.y) * float(CELL_SIZE),
		Vector2(CELL_SIZE, CELL_SIZE)
	)
	draw_rect(r, Color(1, 1, 0, 0.15), true)
	draw_rect(r, Color(1, 1, 0, 0.9), false, 2.0)

func _draw_reachable_dots() -> void:
	var radius: float = min(float(CELL_SIZE) * 0.12, 10.0)
	for c in reachable:
		var p: Vector2 = _cell_center(c)
		draw_circle(p, radius, Color(1, 1, 1, 0.9))

# ---------- Math / Helpers ----------
func _pixel_to_cell(p: Vector2) -> Vector2i:
	var local: Vector2 = (p - BOARD_OFFSET) / float(CELL_SIZE)
	return Vector2i(int(floor(local.x)), int(floor(local.y)))

func _cell_center(c: Vector2i) -> Vector2:
	return BOARD_OFFSET + Vector2(
		c.x * CELL_SIZE + CELL_SIZE * 0.5,
		c.y * CELL_SIZE + CELL_SIZE * 0.5
	)

func _neighbors4(c: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(c.x + 1, c.y),
		Vector2i(c.x - 1, c.y),
		Vector2i(c.x, c.y + 1),
		Vector2i(c.x, c.y - 1)
	]

func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < BOARD_SIZE and c.y >= 0 and c.y < BOARD_SIZE

func _has_cell(arr: Array[Vector2i], c: Vector2i) -> bool:
	for it in arr:
		if it == c:
			return true
	return false
