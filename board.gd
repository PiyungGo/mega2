# board.gd — รวมแสดงหมาก + เลือก + ไฮไลต์ + คำนวณช่อง + เดินทีละช่อง
extends Sprite2D

# ===== CONFIG =====
@export var BOARD_SIZE: int = 8
@export var CELL_SIZE: int = 800
@export var MAX_STEPS: int = 6                 # เดินได้กี่ช่อง (แมนฮัตตัน)

# แหล่งไฟล์ (ถ้าใช้ texture_holder เป็น Sprite2D root)
@export var texture_holder: PackedScene         # res://texture_holder.tscn
@export var tex_good:  Texture2D                # ใส่รูปตัว 1
@export var tex_call:  Texture2D                # ใส่รูปตัว 2
@export var tex_hack:  Texture2D                # ใส่รูปตัว 3
@export var tex_pol:   Texture2D                # ใส่รูปตัว 4

# แนบสคริปต์ท่าทาง (Piece.gd) อัตโนมัติ (ถ้าต้องการให้เปลี่ยนท่าเดิน)
@export var piece_script: Script                # res://Piece.gd (ไม่บังคับ)
@export var piece_scale_factor: float = 1.0     # ขยาย/ย่อหมากเพิ่มเติม
@export var piece_y_offset: float = -2.0        # ยกขึ้นกันเท้าตกขอบ

@onready var pieces: Node = $Pieces

# ===== STATE =====
var BOARD_OFFSET: Vector2 = Vector2.ZERO

# ค่าตาราง (ตัวเลข 0..4) และโหนด Sprite2D ที่วางจริง
var board_vals: Array = []                      # Array<Array<int>>
var board_nodes: Array = []                     # Array<Array<Sprite2D or null>>

var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_piece: Sprite2D = null
var reachable: Array[Vector2i] = []
var parent_map: Dictionary = {}                 # key: Vector2i, val: Vector2i

func _ready() -> void:
	_calc_board_offset()
	_place_four_corners_by_name()     # ← วางมุมก่อน
	_snap_and_fit_existing_pieces()   # ← ฟิตขนาด + สแนปกลางช่อง (ยังคงอยู่)
	_rebuild_nodes_map()
	queue_redraw()


# ฟิตสไปรต์ให้พอดีช่องด้วย padding (เช่น 10%)
func _fit_sprite_to_cell(s: Sprite2D, padding: float = 0.10) -> void:
	if s == null or s.texture == null:
		return
	var tex_size: Vector2 = s.texture.get_size()
	var target: float = float(CELL_SIZE) * (1.0 - padding)
	var k: float = min(target / tex_size.x, target / tex_size.y)
	s.scale = Vector2(k, k)

# สแกนลูกใต้ Pieces → ฟิตขนาด + สแนปให้อยู่กึ่งกลางช่อง
func _snap_and_fit_existing_pieces() -> void:
	for n in pieces.get_children():
		if n is Sprite2D:
			var s: Sprite2D = n
			# ให้ตำแหน่งอ้างจากจุดกึ่งกลางเสมอ
			s.centered = true

			# ฟิตขนาดให้พอดีช่อง (ยังคงสเกลไว้แม้เปลี่ยน texture ระหว่างเดิน)
			_fit_sprite_to_cell(s, 0.10)

			# ถ้าตัวละครมีการยกเท้าด้วย y_offset ใน Piece.gd ให้ใช้ offset ไม่ใช่ position
			# (ถ้าไม่ได้ใช้ก็ไม่ต้องทำอะไรเพิ่ม)

			# สแนปให้เข้ากลางช่องที่อยู่ใกล้ที่สุดตอนนี้
			var cell: Vector2i = _pixel_to_cell(s.global_position)
			cell.x = clamp(cell.x, 0, BOARD_SIZE - 1)
			cell.y = clamp(cell.y, 0, BOARD_SIZE - 1)
			s.global_position = _cell_center(cell)


func _draw() -> void:
	_draw_selection()
	_draw_reachable_dots()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var cell: Vector2i = _pixel_to_cell(get_global_mouse_position())  # <-- ใช้ global
		if not _in_bounds(cell): return
		if selected_piece != null and _has_cell(reachable, cell):
			var path: Array[Vector2i] = _build_path(parent_map, cell)
			await _move_piece_step_by_step(selected_piece, selected_cell, path)
			selected_cell = cell
			_end_move_phase()
			return
		_select_piece_at(cell)


# ====================================================================
# SETUP
# ====================================================================
func _calc_board_offset() -> void:
	# รองรับ centered = true (ค่าเริ่มของ Sprite2D)
	var tex_size: Vector2 = texture.get_size() * scale
	BOARD_OFFSET = global_position - tex_size * 0.5

func _init_board_vals() -> void:
	# เริ่มค่า 0 ทั้งกระดาน
	board_vals.clear()
	for y in BOARD_SIZE:
		var row: Array = []
		row.resize(BOARD_SIZE)
		for x in BOARD_SIZE:
			row[x] = 0
		board_vals.append(row)
	# จุดเกิด 4 มุม: 1,2,3,4
	board_vals[0][0] = 1
	board_vals[0][BOARD_SIZE-1] = 2
	board_vals[BOARD_SIZE-1][0] = 3
	board_vals[BOARD_SIZE-1][BOARD_SIZE-1] = 4

func _spawn_from_vals() -> void:
	# เคลียร์ลูกเก่า
	for c in pieces.get_children():
		c.queue_free()

	# สร้างชิ้นใหม่ตามตัวเลขในตาราง
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			var v: int = int(board_vals[y][x])
			if v == 0:
				continue
			var s: Sprite2D = _make_piece_sprite(v)
			pieces.add_child(s)
			s.global_position = _cell_center(Vector2i(x, y))
			_fit_sprite_to_cell(s, 0.10)
			if piece_script != null:
				if s.has_method("set_idle"):
					s.call_deferred("set_idle")

# แทนที่จะขยับ position ให้ขยับ offset
			if piece_y_offset != 0.0:
				s.offset.y += piece_y_offset

# วางตัวละครตามชื่อไปยัง 4 มุมฉาก
func _place_four_corners_by_name() -> void:
	var corner: Dictionary = {
		"Good":   Vector2i(0, 0),
		"Call":   Vector2i(BOARD_SIZE - 1, 0),
		"Hacker": Vector2i(0, BOARD_SIZE - 1),
		"Police": Vector2i(BOARD_SIZE - 1, BOARD_SIZE - 1),
	}
	for n in pieces.get_children():
		if n is Sprite2D and corner.has(n.name):
			(n as Sprite2D).global_position = _cell_center(corner[n.name])


func _make_piece_sprite(v: int) -> Sprite2D:
	var s: Sprite2D = null
	if texture_holder != null:
		s = texture_holder.instantiate() as Sprite2D
	else:
		s = Sprite2D.new()

	s.centered = true
	# อย่าตั้ง s.texture ที่นี่ ให้ Piece.gd จัดการจาก tex_idle
	return s


func _rebuild_nodes_map() -> void:
	board_nodes.clear()
	for y in BOARD_SIZE:
		var row: Array = []
		row.resize(BOARD_SIZE)
		for x in BOARD_SIZE: row[x] = null
		board_nodes.append(row)
	# map โหนดจริงลงตำแหน่ง cell
	for n in pieces.get_children():
		if n is Sprite2D:
			var s: Sprite2D = n
			var c: Vector2i = _pixel_to_cell(s.global_position)
			if _in_bounds(c):
				board_nodes[c.y][c.x] = s

# ====================================================================
# SELECT / REACH
# ====================================================================
func _select_piece_at(cell: Vector2i) -> void:
	_rebuild_nodes_map()
	var node: Variant = board_nodes[cell.y][cell.x]
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

# BFS แบบแมนฮัตตัน
func _compute_reachable(start: Vector2i, steps: int) -> void:
	reachable.clear()
	parent_map.clear()

	var q: Array = []                 # items: [Vector2i, int]
	var visited: Dictionary = {}      # key: Vector2i, val: bool
	q.append([start, 0])
	visited[start] = true

	while q.size() > 0:
		var item: Array = q.pop_front()
		var c: Vector2i = item[0]
		var d: int = item[1]
		if d > steps: continue
		if c != start: reachable.append(c)
		if d == steps: continue

		for nb in _neighbors4(c):
			if not _in_bounds(nb): continue
			# ห้ามผ่านช่องที่มีตัวอื่น (ยกเว้นจุดเริ่ม)
			if board_nodes[nb.y][nb.x] != null and nb != start: continue
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

# ====================================================================
# MOVE
# ====================================================================
func _move_piece_step_by_step(piece: Sprite2D, start_cell: Vector2i, path: Array[Vector2i]) -> void:
	if path.is_empty():
		return

	var cur: Vector2i = start_cell
	var prev_dir: Vector2i = Vector2i(0, 0)
	var first_step: bool = true

	for step_cell in path:
		var dir: Vector2i = step_cell - cur

		# เปลี่ยนเป็น "ท่าเดิน" เฉพาะตอนเริ่มเดิน หรือเมื่อทิศเปลี่ยน
		if first_step or dir != prev_dir:
			if "set_move_dir" in piece:
				piece.set_move_dir(dir)
			prev_dir = dir
			first_step = false

		# อัปเดตการครอบครองตาราง
		board_nodes[cur.y][cur.x] = null
		board_nodes[step_cell.y][step_cell.x] = piece
		cur = step_cell

		# เดินทีละช่อง
		var t: Tween = create_tween()
		t.tween_property(piece, "global_position", _cell_center(step_cell), 0.14)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t.finished

	# เดินเสร็จจริง ๆ แล้วค่อยกลับท่ายืน
	if "set_idle" in piece:
		piece.set_idle()


func _end_move_phase() -> void:
	reachable.clear()
	parent_map.clear()
	queue_redraw()

# ====================================================================
# DRAW
# ====================================================================
func _draw_selection() -> void:
	if selected_cell == Vector2i(-1,-1):
		return
	# ตำแหน่งมุมซ้ายบนของช่อง (GLOBAL)
	var top_left_g: Vector2 = BOARD_OFFSET + Vector2(selected_cell.x, selected_cell.y) * float(CELL_SIZE)
	# แปลงเป็น LOCAL ของกระดาน
	var top_left_l: Vector2 = to_local(top_left_g)
	# ขนาดช่องในหน่วย LOCAL (ชดเชย scale ของกระดาน)
	var cell_size_l: Vector2 = Vector2(CELL_SIZE / max(0.0001, scale.x),
									   CELL_SIZE / max(0.0001, scale.y))
	var r := Rect2(top_left_l, cell_size_l)

	draw_rect(r, Color(1,1,0,0.15), true)      # พื้นเหลืองอ่อน
	draw_rect(r, Color(1,1,0,0.9),  false, 2)  # เส้นขอบเหลือง


func _draw_reachable_dots() -> void:
	# รัศมีในหน่วย LOCAL (ชดเชย scale)
	var radius_l: float = min(float(CELL_SIZE) * 0.12, 45.0) / max(scale.x, scale.y)

	for c in reachable:
		# จุดกึ่งกลางช่อง (GLOBAL) → LOCAL
		var p_g: Vector2 = _cell_center(c)
		var p_l: Vector2 = to_local(p_g)
		draw_circle(p_l, radius_l, Color(1,1,1,0.9))


# ====================================================================
# HELPERS
# ====================================================================
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
		if it == c: return true
	return false
