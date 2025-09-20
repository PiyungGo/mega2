# board.gd — รวมแสดงหมาก + เลือก + ไฮไลต์ + คำนวณช่อง + เดินทีละช่อง
extends Sprite2D

@onready var pieces_root: Node = $Pieces

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
@export var dot_radius: float = 6.0
var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_piece: Sprite2D = null
var reachable: Array[Vector2i] = []
var parent_map: Dictionary = {}                 # key: Vector2i, val: Vector2i
var piece_owner: Dictionary = {}
var is_moving: bool = false
# === Turn system ===
var turn_order: Array[Sprite2D] = []
var turn_idx: int = 0
var active_piece: Sprite2D = null
  # ชิ้นที่ได้เล่นในรอบนี้

# ตำแหน่ง cell ของแต่ละชิ้น (อัปเดตทุกครั้งที่เดิน)
var piece_cells: Dictionary = {}         # {Sprite2D: Vector2i}

# ใช้ทำแสงกระพริบ
var _glow_t: float = 0.0

# สีกรอบตามผู้เล่น (Good, Call, Hacker, Police)
const TURN_COLORS := [
	Color(1, 1, 0, 0.45),
	Color(0.4, 1, 1, 0.45),
	Color(1, 0.6, 0.2, 0.45),
	Color(1, 0.3, 0.3, 0.45),
]

func _ready() -> void:
	_calc_board_offset()
	_place_four_corners_by_name()     # ← วางมุมก่อน
	_snap_and_fit_existing_pieces()   # ← ฟิตขนาด + สแนปกลางช่อง (ยังคงอยู่)
	_rebuild_nodes_map()
	queue_redraw()
	_update_turn_ui()
	_start_turns()
# เพิ่มด้านบน (โซนตัวแปร)



func _update_turn_label() -> void:
	if turn_label and active_piece:
		turn_label.text = "ตอนนี้เป็นเทิร์นของ: %s" % active_piece.name

func _active_player_index() -> int:
	if active_piece == null: return 0
	match active_piece.name:
		"Good": return 0
		"Call": return 1
		"Hacker": return 2
		"Police": return 3
		_:
			return 0


func _start_turns() -> void:
	var p = $Pieces
	# ดึงเฉพาะตัวที่ต้องการจริง ๆ จาก children
	var good  : Sprite2D = p.get_node("Good")
	var call  : Sprite2D = p.get_node("Call")
	var hack  : Sprite2D = p.get_node("Hacker")
	var police: Sprite2D = p.get_node("Police")

	turn_order = [good, call, hack, police]
	turn_order.shuffle()
	_update_turn_label()
	turn_idx = 0
	active_piece = turn_order[turn_idx]
	current_player = _active_player_index()
	_update_turn_ui()             # เดิมที่ใช้ข้อความ Turn:

	# กันพลาด
	if active_piece == null:
		push_error("active_piece is null (turn_order empty?)")
		return

	selected_piece = null
	selected_cell  = Vector2i(-1, -1)
	reachable.clear()

	print("TURN ORDER =", turn_order.map(func(n): return n.name))
	print("ACTIVE     =", active_piece.name)

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

# มุมซ้ายบนกระดาน (พิกัดโลก)
func _board_top_left_global() -> Vector2:
	if texture == null:
		return global_position
	var size_g := texture.get_size() * scale
	return global_position - size_g * 0.5

func _cell_rect(c: Vector2i) -> Rect2:
	var s := _cell_px()
	var tl := _board_top_left_global() + Vector2(c.x * s, c.y * s)
	return Rect2(tl, Vector2(s, s))

func _cell_center(c: Vector2i) -> Vector2:
	var s := _cell_px()
	return _board_top_left_global() + Vector2(
		(c.x + 0.5) * s,
		(c.y + 0.5) * s
	)



func _draw() -> void:
	_draw_selection()
	_draw_reachable_dots()
	
	# ไฮไลท์ชิ้นที่เลือก
	if selected_cell != Vector2i(-1, -1):
		var rect := _cell_rect(selected_cell)
		draw_rect(rect, TURN_COLORS[current_player], true)
		draw_rect(rect, Color(0, 0, 0, 0.55), false, 2)

	if piece_cells.has(active_piece):
		selected_cell = piece_cells[active_piece]
	else:
		selected_cell = _pixel_to_cell(active_piece.global_position)

# จุดขาวตำแหน่งที่เดินได้
	# จุดขาวตำแหน่งที่เดินได้
	for c in reachable:
		draw_circle(_cell_center(c), dot_radius, Color(1, 1, 1, 0.9))


	
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var gpos: Vector2 = get_global_mouse_position()
		var cell: Vector2i = _pixel_to_cell(gpos)

		# ---------- เมื่อหน้าต่างทอยเต๋าเปิดอยู่ ----------
		if dice_open:
			var clicked_cell := _pixel_to_cell(get_global_mouse_position())
			if not _in_bounds(cell) or (selected_cell != Vector2i(-1,-1) and cell == selected_cell):
				if dice_ui and dice_ui.visible:
					return
				if is_moving:
					return

			# 2) ยกเว้นพิเศษ: คลิกที่ "ช่องของตัวที่กำลังถูกเลือก" → ปิดหน้าต่างเหมือนกัน
			if selected_cell != Vector2i(-1,-1) and cell == selected_cell:
				if dice_ui: dice_ui.call("close")
				dice_open = false
				if dice_has_result:
					_compute_reachable(selected_cell, steps_for_current_piece)
					queue_redraw()
				return

			# 3) กรณีคลิกที่อื่นบนกระดาน ขณะหน้าต่างยังเปิด → ไม่ทำอะไร
			return

		# ---------- หน้าต่างทอยเต๋า 'ปิด' อยู่ (โหมดปกติ) ----------
		if not _in_bounds(cell):
			return

		# คลิกช่องปลายทางที่ไปได้ → เดิน
		# คลิกช่องปลายทางที่ไปได้ → เดิน
		if selected_piece != null and _has_cell(reachable, cell):
			# จุดเริ่มที่เชื่อถือได้
			var start_cell: Vector2i = piece_cells.get(selected_piece, selected_cell)

			var path: Array[Vector2i] = _build_path(parent_map, cell)
			if path.is_empty():
				return

			await _move_piece_step_by_step(selected_piece, start_cell, path)
			selected_cell = cell   # sync การเลือกกับตำแหน่งใหม่
			_end_turn()
			return



		# ไม่ใช่ปลายทาง → ลองเลือกตัวละครช่องนั้น
		_select_piece_at(cell)
		print("dice_ui=", dice_ui)

# หาตัวหมาก (Sprite2D) ที่อยู่ใน cell ที่กำหนด
func _get_piece_at(cell: Vector2i) -> Sprite2D:
	if cell.y < 0 or cell.y >= board_nodes.size():
		return null
	var row: Array = board_nodes[cell.y]
	if cell.x < 0 or cell.x >= row.size():
		return null
	return row[cell.x] as Sprite2D


# === Turn system ===
@export var turn_label_path: NodePath  # ลาก Label ที่ไว้โชว์เทิร์นมาใส่ได้ เช่น /root/Board/Turn
@onready var turn_label: Label = get_node_or_null(turn_label_path)

var players := ["Good", "Call", "Hacker", "Police"]   # ชื่อตรงกับชื่อ Node ใต้ Pieces
var current_player: int = 0                            # เริ่มคนที่ 0 = Good

					 # Sprite2D -> player_index


func _process(_delta: float) -> void:
	if not dice_open and _pending_show_moves and selected_cell != Vector2i(-1,-1):
		_compute_reachable(selected_cell, steps_for_current_piece)
		queue_redraw()
		_pending_show_moves = false


# ====================================================================
# SETUP
# ====================================================================
func _calc_board_offset() -> void:
	# รองรับ centered = true (ค่าเริ่มของ Sprite2D)
	var tex_size: Vector2 = texture.get_size() * scale
	BOARD_OFFSET = global_position - tex_size * 0.5

func _init_board_vals() -> void:
	_bind_piece_owners_from_corners()

	var mapping := {
	"Good": 0, "Call": 1, "Hacker": 2, "Police": 3,
}
	for name in mapping.keys():
		var n: Node = pieces_root.get_node_or_null(name)
		if n is Sprite2D:
			piece_owner[n as Sprite2D] = int(mapping[name])


# เติมเจ้าของจากตำแหน่งเกิด 4 มุม
func _bind_piece_owners_from_corners() -> void:
	piece_owner.clear()
	var start_owners := {
	Vector2i(0, 0): 0,   # Good
	Vector2i(7, 0): 1,   # Call
	Vector2i(0, 7): 2,   # Hacker
	Vector2i(7, 7): 3    # Police
}

	for cell in start_owners.keys():
		if cell.y >= 0 and cell.y < board_nodes.size():
			var row: Array = board_nodes[cell.y]
			if cell.x >= 0 and cell.x < row.size():
				var p: Sprite2D = row[cell.x] as Sprite2D
				if p != null:
					piece_owner[p] = int(start_owners[cell])



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
	piece_cells.clear()
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var s: Sprite2D = board_nodes[y][x]
			if s != null:
				piece_cells[s] = Vector2i(x, y)



# ตอนเปิดเต๋า
func _open_dice_panel_for_selected() -> void:
	if dice_ui == null:
		steps_for_current_piece = MAX_STEPS
		_compute_reachable(selected_cell, steps_for_current_piece)
		queue_redraw()
		return

	if not dice_ui.is_connected("rolled", Callable(self, "_on_dice_rolled")):
		dice_ui.connect("rolled", Callable(self, "_on_dice_rolled"))
	if not dice_ui.is_connected("closed", Callable(self, "_on_dice_closed")):
		dice_ui.connect("closed", Callable(self, "_on_dice_closed"))

	dice_open = true
	dice_has_result = false
	steps_for_current_piece = 0

	dice_ui.mouse_filter = Control.MOUSE_FILTER_STOP  # << บังเมาส์เฉพาะตอนเปิด
	dice_ui.open()



# ====================================================================
# SELECT / REACH
# ====================================================================
func _select_piece_at(cell: Vector2i) -> void:
	var piece := _get_piece_at(cell)
	if piece == null:
		return

	# DEBUG: พิมพ์ชื่อไว้ดูว่ามันคลิกตัวไหน
	print("click piece =", piece.name, "  active =", active_piece and active_piece.name)

	# เลือกได้เฉพาะตัวที่เป็นคิว
	if active_piece == null or piece != active_piece:
		return

	# ผ่านแล้ว -> เปิดหน้าเต๋า
	selected_piece = piece
	selected_cell  = cell
	_open_dice_panel_for_selected()

# (ถ้ายังไม่ได้ bind owner จะไม่บล็อก — แต่ในเกมจริงควร bind แล้ว)


	# (ถ้าบล็อกตามเจ้าของ ให้เช็ก owner ที่นี่ แล้ว return ถ้าไม่ใช่ current_player)

	selected_piece = piece
	selected_cell = cell
	reachable.clear()
	parent_map.clear()
	queue_redraw()                 # <<< ให้กรอบเหลืองโผล่ทันที

	# เปิด UI ทอยเต๋า (เหมือนที่คุณทำอยู่)
	if dice_ui:
		if not dice_ui.is_connected("rolled", Callable(self, "_on_dice_rolled")):
			dice_ui.connect("rolled", Callable(self, "_on_dice_rolled"))
		if not dice_ui.is_connected("closed", Callable(self, "_on_dice_closed")):
			dice_ui.connect("closed", Callable(self, "_on_dice_closed"))
		_pending_show_moves = false
		steps_for_current_piece = 0
		dice_ui.call("open")




		
func _on_dice_rolled(value: int) -> void:
	steps_for_current_piece = clamp(value, 1, MAX_STEPS)
	dice_has_result = true

# BFS แบบแมนฮัตตัน
func _compute_reachable(start: Vector2i, steps: int) -> void:
	reachable.clear()
	parent_map.clear()

	var q: Array[Vector2i] = [start]
	var dist := { start: 0 }

	while not q.is_empty():
		var u: Vector2i = q.pop_front()
		if dist[u] == steps: continue

		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var v: Vector2i = u + d
			if not _in_bounds(v): continue
			if _is_occupied(v) and v != start: continue
			if v in dist: continue
			dist[v] = dist[u] + 1
			parent_map[v] = u
			reachable.append(v)
			q.append(v)



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
	is_moving = true

	var cur: Vector2i = start_cell
	for step_cell in path:
		var dir: Vector2i = step_cell - cur
		if "set_move_dir" in piece:
			piece.set_move_dir(dir)
		await _tween_move_one_cell(piece, cur, step_cell)  # <- ของคุณ

		cur = step_cell

	board_nodes[start_cell.y][start_cell.x] = null
	board_nodes[cur.y][cur.x] = piece
	piece_cells[piece] = cur          # <- สำคัญมาก ใช้กับไฮไลท์เทิร์น

	if "set_idle" in piece:
		piece.set_idle()

	is_moving = false

func _tween_move_one_cell(piece: Sprite2D, from: Vector2i, to: Vector2i) -> void:
	var to_pos := _cell_center(to)
	var tw := create_tween()
	tw.tween_property(piece, "global_position", to_pos, 0.25) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	await tw.finished






func _end_turn() -> void:
	# เคลียร์สถานะของเทิร์น
	selected_piece = null
	selected_cell  = Vector2i(-1, -1)
	reachable.clear()
	parent_map.clear()
	active_piece = turn_order[turn_idx]
	_update_turn_label()
	queue_redraw()
	dice_has_result = false
	steps_for_current_piece = 0
	dice_open = false
	if dice_ui:
		dice_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ไปคนถัดไป (วน)
	turn_idx = (turn_idx + 1) % turn_order.size()
	active_piece = turn_order[turn_idx]
	active_piece = turn_order[turn_idx]
	current_player = _active_player_index()
	_update_turn_ui()
	queue_redraw()




# ====================================================================
# DRAW
# ====================================================================
func _draw_selection() -> void:
	if selected_cell == Vector2i(-1, -1):
		return
	var r_g := _cell_rect(selected_cell)     # rect พิกัดจอ
	var tl := to_local(r_g.position)         # แปลงเป็น local ของบอร์ด
	var br := to_local(r_g.position + r_g.size)
	var r  := Rect2(tl, br - tl)
	draw_rect(r, Color(1,1,0,0.15), true)
	draw_rect(r, Color(1,1,0,0.90), false, 2)



func _draw_reachable_dots() -> void:
	var radius_l: float = min(float(CELL_SIZE) * 0.12, 45.0) / max(scale.x, scale.y)

	for c in reachable:
		var p_g: Vector2 = _cell_center(c)   # global
		var p_l: Vector2 = to_local(p_g)     # แปลงเป็น local ของบอร์ด
		draw_circle(p_l, radius_l, Color(1,1,1,0.9))

# ขนาดช่องในพิกัดจอ (global pixels)
func _cell_px() -> float:
	if texture == null:
		return float(CELL_SIZE)  # เผื่อกรณีไม่มี texture
	var size_g := texture.get_size() * scale     # ขนาดกระดานจริงบนจอ
	return size_g.x / float(BOARD_SIZE)          # กว้าง/ช่อง


# ====================================================================
# HELPERS
# ====================================================================
func _pixel_to_cell(p: Vector2) -> Vector2i:
	var s := _cell_px()
	var top_left := _board_top_left_global()
	var local := (p - top_left) / s
	return Vector2i(int(floor(local.x)), int(floor(local.y)))


func _neighbors4(c: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(c.x + 1, c.y),
		Vector2i(c.x - 1, c.y),
		Vector2i(c.x, c.y + 1),
		Vector2i(c.x, c.y - 1)
	]

func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < BOARD_SIZE and c.y >= 0 and c.y < BOARD_SIZE



func _is_occupied(c: Vector2i) -> bool:
	if c.y < 0 or c.y >= board_nodes.size(): return false
	var row: Array = board_nodes[c.y]
	if c.x < 0 or c.x >= row.size(): return false
	return row[c.x] != null


func _has_cell(arr: Array[Vector2i], c: Vector2i) -> bool:
	for it in arr:
		if it == c: return true
	return false

@export var dice_ui_path: NodePath    # ลาก DiceUI (Control) ใต้ CanvasLayer มาใส่ใน Inspector
@onready var dice_ui: Control = get_node_or_null(dice_ui_path)

var steps_for_current_piece: int = 0
var dice_open: bool = false
var dice_has_result: bool = false
var _pending_show_moves: bool = false   # ← ใหม่: รอแสดงจุดหลังปิดหน้าต่าง

func _on_dice_closed() -> void:
	dice_open = false

	if active_piece == null:
		return
	if not dice_has_result:
		return

	# จุดเริ่มสำหรับคำนวณทางเดิน: เอาจาก piece_cells ถ้ามี
	if piece_cells.has(active_piece):
		selected_cell = piece_cells[active_piece]
	else:
		selected_cell = _pixel_to_cell(active_piece.global_position)

	_compute_reachable(selected_cell, steps_for_current_piece)
	queue_redraw()

	if dice_ui:
		dice_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE


	print("dice closed, cell=", selected_cell, " steps=", steps_for_current_piece)
	print("reachable=", reachable)





# เปิด
func _update_turn_ui() -> void:
	if turn_label:
		turn_label.text = "Turn: %s" % players[current_player]

func _next_turn() -> void:
	# เคลียร์สถานะเลือก / จุดเดิน / แต้
	reachable.clear()
	parent_map.clear()
	steps_for_current_piece = 0
	_pending_show_moves = false
	queue_redraw()

	# วนผู้เล่น
	current_player = (current_player + 1) % players.size()
	_update_turn_ui()
