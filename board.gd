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
@export var WALK_POINT_RATE: int = 12
@export var current_round: int = 1   # เริ่มนับรอบจาก 1

@export var SettingsScene: PackedScene

@onready var win_title: Label        = $CanvasLayer/WinPanel/TitleLabel
@onready var win_sub: Label          = $CanvasLayer/WinPanel/SubtitleLabel
@onready var win_icon: TextureRect   = $CanvasLayer/WinPanel/WinnerIcon
@onready var quit_btn: Button        = $CanvasLayer/WinPanel/QuitButton

# ===== Top bar / side label =====
@export var round_label_path: NodePath      # Label บน TopBar (มุมขวาบน)
@export var side_turn_label_path: NodePath  # Label ด้านขวากลางจอ "ตอนนี้เป็นเทิร์นของ: ..."

@onready var round_label: Label = get_node_or_null(round_label_path)
@onready var side_turn_label: Label = get_node_or_null(side_turn_label_path)


@export var attack_bar_path: NodePath
@onready var attack_bar: Control = get_node_or_null(attack_bar_path)
@onready var attack_btn: Button = attack_bar.get_node_or_null("AttackButton")
@onready var skip_btn: Button = attack_bar.get_node_or_null("SkipButton")

@export var card_hold_seconds: float = 5.0   # เวลาโผล่ค้างหลังโดนเมาส์
var _hold_timer: Timer
var all_def_turns: Dictionary[Sprite2D, int] = {}   # piece -> เทิร์นที่เหลือ

# แนบสคริปต์ท่าทาง (Piece.gd) อัตโนมัติ (ถ้าต้องการให้เปลี่ยนท่าเดิน)
@export var piece_script: Script                # res://Piece.gd (ไม่บังคับ)
@export var piece_scale_factor: float = 1.0     # ขยาย/ย่อหมากเพิ่มเติม
@export var piece_y_offset: float = -2.0        # ยกขึ้นกันเท้าตกขอบ

@export var hp_start: int = 1000
@export var WinPanelScene: PackedScene
@export var win_panel_path: NodePath
@onready var win_panel: Control = get_node_or_null(win_panel_path)
# ===== Top bar config =====
@export var MAX_TURNS: int = 15

@export var topbar_path: NodePath
@onready var topbar: Control = get_node_or_null(topbar_path)
@onready var turn_label: Label = topbar.get_node_or_null("TurnLabel") if topbar else null
@onready var settings_btn: Button = topbar.get_node_or_null("SettingsBtn") if topbar else null
@onready var quit_btn_top: Button = topbar.get_node_or_null("QuitBtn") if topbar else null

# ป๊อปอัปยืนยันออกเกม (ถ้าไม่มีในฉาก ให้เราสร้างเองได้)
@export var quit_confirm_path: NodePath
@onready var quit_confirm := get_node_or_null(quit_confirm_path)   # ควรเป็น ConfirmationDialog
# ===== Slide CardBar Config =====
@export var card_peek_px: int = 24            # โผล่พ้นจอไว้บอกว่ามีการ์ด
@export var card_slide_duration: float = 0.25 # ความเร็วเลื่อน
@export var card_hide_delay: float = 0.25     # หน่วงเวลาตอนเลื่อนลง เพื่อกันกะพริบ

@onready var hover_zone: Control = $CanvasLayer/CardBar/HoverZone
const PROCESS_FREEZE_TURNS := 4   # ← ถ้าอยากให้ 1 เทิร์น เปลี่ยนเป็น 1
const SYSTEM_FAILURE_PENALTY := 200
var frozen_turns: Dictionary = {}  # Sprite2D -> เทิร์นที่เหลือ
var _bar_shown_y: float
var _bar_hidden_y: float
var _bar_tween: Tween
var _hide_timer: Timer
# นับเทิร์น (1 เทิร์น = ครบทุกคน 1 รอบ)
var turn_cycles_done: int = 0      # แสดงผลใน UI เป็น x/MAX_TURNS

var is_game_over: bool = false
# เก็บเงินของแต่ละตัวละคร (key = Sprite2D, value = int)
var money_by_piece: Dictionary[Sprite2D, int] = {}
var shield_by_piece: Dictionary[Sprite2D, int] = {}   # NEW: เก็บแต้มป้องกัน


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

# วางไว้บนสุดของไฟล์ (โซน CONFIG)
const ATTACK_DIRS_4 := [
	Vector2i(1,0), Vector2i(-1,0),
	Vector2i(0,1), Vector2i(0,-1)
]

const ATTACK_DIRS_8 := [
	Vector2i(1,0),  Vector2i(-1,0),
	Vector2i(0,1),  Vector2i(0,-1),
	Vector2i(1,1),  Vector2i(1,-1),
	Vector2i(-1,1), Vector2i(-1,-1)
]

# เลือกว่าจะใช้โจมตี 4 หรือ 8 ทิศ
const ATTACK_DIRS := ATTACK_DIRS_8

# ===== CARD SYSTEM =====
enum CardType { ATTACK, DEFENSE, MYSTERY }

# โครงการ์ดแบบ Dictionary:
# { "id": "data_skimmer", "name": "Data Skimmer", "type": CardType.ATTACK, "desc": "...", "effect": "steal_100" }
var all_cards: Array[CardData] = []
# ===== CARD / HAND =====
@export var MAX_HAND: int = 8
var hand_by_piece: Dictionary = {}   # Dictionary[Sprite2D, Array]
var used_card_in_round: Dictionary[Sprite2D, bool] = {}   # ใช้การ์ดแล้วหรือยังในรอบนี้

var is_card_phase: bool = false
var selected_card_index: int = -1
var teleport_pending: bool = false    # โหมดเลือกจุดวาร์ป

# UI ของแถบการ์ด
@export var card_bar_path: NodePath
@onready var card_bar: Control = get_node_or_null(card_bar_path)
@onready var card_slots: Control = card_bar.get_node_or_null("Slots") if card_bar else null
@onready var use_card_btn: Button = card_bar.get_node_or_null("UseCardButton") if card_bar else null
@onready var end_turn_btn: Button = card_bar.get_node_or_null("EndTurnButton") if card_bar else null
@onready var slots_container: HBoxContainer = card_bar.get_node_or_null("Slots") if card_bar else null
@export var card_db_path: String = "res://data/cards/card_database.tres"
@export var card_db: CardDatabase
var slot_buttons: Array[Button] = []

func _cache_slot_buttons() -> void:
	slot_buttons.clear()
	if slots_container:
		for i in range(1, 6):
			var b := slots_container.get_node_or_null("Slot%d" % i) as Button
			if b:
				slot_buttons.append(b)


func _ready() -> void:
	_calc_board_offset()
	_place_four_corners_by_name()
	_snap_and_fit_existing_pieces()
	_rebuild_nodes_map()
	_setup_money()
	_setup_owners_by_name()
	_update_money_ui()
	_update_turn_ui()
	_start_turns()

	# ---- โหลด Card DB ให้เรียบร้อยก่อนแจกไพ่ ----
	card_db = load(card_db_path)
	if card_db:
		all_cards = card_db.cards.duplicate()
	else:
		push_warning("card_db is not set; no cards loaded")

	# แจกไพ่เริ่มต้น **หลังจาก** โหลดแล้ว
	_deal_initial_hands(5)

	await get_tree().process_frame
	_setup_card_bar_slide()


	# ----- WinPanel (เดิม) -----
	if win_panel == null and WinPanelScene:
		win_panel = WinPanelScene.instantiate()
		win_panel.name = "WinPanel"
		$CanvasLayer.add_child(win_panel)

	if win_panel:
		win_panel.visible = false
		var quit_btn := win_panel.get_node_or_null("QuitButton") as Button
		if quit_btn and not quit_btn.is_connected("pressed", Callable(self, "_on_quit_pressed")):
			quit_btn.pressed.connect(_on_quit_pressed)

	# ----- ปุ่ม/แถบอื่น ๆ (ย้ายออกมาจาก else) -----
	if attack_bar:
		attack_bar.visible = false
	if skip_btn and not skip_btn.is_connected("pressed", Callable(self, "_on_skip_pressed")):
		skip_btn.pressed.connect(_on_skip_pressed)

	if settings_btn and not settings_btn.is_connected("pressed", Callable(self, "_on_settings_pressed")):
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn_top and not quit_btn_top.is_connected("pressed", Callable(self, "_on_quit_top_pressed")):
		quit_btn_top.pressed.connect(_on_quit_top_pressed)

	if quit_confirm and not quit_confirm.is_connected("confirmed", Callable(self, "_on_quit_confirmed")):
		quit_confirm.confirmed.connect(_on_quit_confirmed)

	_update_round_label()
	_update_side_turn_label()
	_update_topbar_ui()

	# ----- โปรไฟล์ (ของเดิม) -----
	_setup_profiles([
		{"name": "Good",   "job": "คนดี",        "money": 1000, "icon": tex_good},
		{"name": "Call",   "job": "คอลเซนเตอร์","money": 1000, "icon": tex_call},
		{"name": "Hacker", "job": "แฮกเกอร์",   "money": 1000, "icon": tex_hack},
		{"name": "Police", "job": "ตำรวจ",       "money": 1000, "icon": tex_pol},
	])

	if not target_markers_root.get_parent():
		target_markers_root.name = "TargetMarkers"
		add_child(target_markers_root)
		target_markers_root.z_index = 9999  # ให้อยู่บนสุด

	# สร้างเท็กซ์เจอร์สี่เหลี่ยมแดงโปร่งแสง 64x64
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 0, 0.35))
	_marker_tex = ImageTexture.create_from_image(img)

@onready var player_profiles := $CanvasLayer/PlayerProfiles
var profile_cards := {}   # name -> card (Control)
# เก็บ reference ของโปรไฟล์แต่ละอัน

func _update_topbar_ui() -> void:
	if turn_label:
		turn_label.text = "เทิร์น: %d/%d" % [turn_cycles_done, MAX_TURNS]


# หา TextureRect ของการ์ดโปรไฟล์ (รองรับมี/ไม่มี AspectRatioContainer)
func _find_profile_pic(card: Node) -> TextureRect:
	var pic := card.get_node_or_null("AspectRatioContain/ProfilePic") as TextureRect
	if pic == null:
		pic = card.get_node_or_null("ProfilePic") as TextureRect
	return pic

# ดึง Texture จากตัวหมากจริงให้ได้แน่ ๆ



# ตั้งค่าการ์ดโปรไฟล์ และดึงรูปจากตัวหมากถ้าไม่มี icon ใน data
func _setup_profiles(players: Array[Dictionary]) -> void:
	if player_profiles == null:
		return

	var profile_nodes := player_profiles.get_children()
	var count: int = min(players.size(), profile_nodes.size())

	for i in range(count):
		var data: Dictionary = players[i]
		var card = profile_nodes[i]

		var info = card.get_node_or_null("Info")
		if info == null:
			continue

		var name_label = info.get_node_or_null("NameLabel") as Label
		var money_label = info.get_node_or_null("MoneyLabel") as Label
		var job_label = info.get_node_or_null("JobLabel") as Label

		if name_label:  name_label.text = str(data.get("name", ""))
		if money_label: money_label.text = "เงิน: %d (0)" % data.get("money", 0)

		if job_label:   job_label.text = "อาชีพ:\n%s" % data.get("job", "")
		
		profile_cards[data["name"]] = card

func add_shield(p: Sprite2D, delta: int) -> void:
	if p == null: return
	var cur: int = int(shield_by_piece.get(p, 0))
	shield_by_piece[p] = max(0, cur + delta)
	_update_money_ui()

func set_shield(p: Sprite2D, value: int) -> void:
	if p == null: return
	shield_by_piece[p] = max(0, value)
	_update_money_ui()


# ถ้า pic ยัง null อยู่ ให้ข้ามไปเฉย ๆ (จะไม่เซ็ตอะไร)


func update_money(player_name: String, amount: int) -> void:
	if not profile_cards.has(player_name):
		return
	var card = profile_cards[player_name]
	var money_label = card.get_node("Info/MoneyLabel") as Label

	# หา piece เพื่ออ่านค่า shield ปัจจุบัน
	var piece := $Pieces.get_node_or_null(player_name) as Sprite2D
	var shield_amt: int = 0
	if piece:
		shield_amt = int(shield_by_piece.get(piece, 0))

	money_label.text = "เงิน: %d (%d)" % [max(0, amount), max(0, shield_amt)]



func _init_money_defaults() -> void:
	var p := $Pieces
	var good  : Sprite2D = p.get_node_or_null("Good")
	var call  : Sprite2D = p.get_node_or_null("Call")
	var hack  : Sprite2D = p.get_node_or_null("Hacker")
	var pol   : Sprite2D = p.get_node_or_null("Police")
	for s in [good, call, hack, pol]:
		if s and not money_by_piece.has(s):
			money_by_piece[s] = hp_start


func _update_round_label() -> void:
	if round_label:
		var shown: int = clamp(turn_cycles_done + 1, 1, MAX_TURNS)
		round_label.text = "รอบ: %d / %d" % [shown, MAX_TURNS]



func _update_round_label_ui() -> void:
	if round_label:
		round_label.text = "รอบ: %d / %d" % [current_round, MAX_TURNS]


func _update_side_turn_label() -> void:
	if side_turn_label and active_piece:
		side_turn_label.text = "ตอนนี้เป็นเทิร์นของ: %s" % active_piece.name


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
	_update_side_turn_label()
	turn_idx = 0
	active_piece = turn_order[turn_idx]
	current_player = _active_player_index()
	_update_turn_ui()             # เดิมที่ใช้ข้อความ Turn:
	_update_money_ui()  
	# กันพลาด
	if active_piece == null:
		push_error("active_piece is null (turn_order empty?)")
		return

	selected_piece = null
	selected_cell  = Vector2i(-1, -1)
	reachable.clear()

	print("TURN ORDER =", turn_order.map(func(n): return n.name))
	print("ACTIVE     =", active_piece.name)

@export var INITIAL_HAND: int = 3


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
	# --- โหมดวาร์ปจาก Trace Jump ---
	if teleport_pending and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var cell := _pixel_to_cell(get_global_mouse_position())
		if not _in_bounds(cell): return
		if _is_occupied(cell): return
		if active_piece == null: return

		# ย้ายตัวไป cell ที่เลือกทันที (ไม่หักแต้ม)
		var cur: Vector2i = piece_cells.get(active_piece, _pixel_to_cell(active_piece.global_position))
		board_nodes[cur.y][cur.x] = null
		board_nodes[cell.y][cell.x] = active_piece
		piece_cells[active_piece] = cell
		active_piece.global_position = _cell_center(cell)
		_tick_counter_hack_all() 
		queue_redraw()
		
		teleport_pending = false
		_end_card_phase()
		_end_turn()
		return

	if is_game_over:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var gpos: Vector2 = get_global_mouse_position()
		var cell: Vector2i = _pixel_to_cell(gpos)   # ← ประกาศที่นี่ก่อนใช้ทุกที่

		if not _in_bounds(cell):
			return

		# คลิกปลายทางที่ไปได้ → เดิน
		if selected_piece != null and steps_left > 0 and _has_cell(reachable, cell):
			var start_cell: Vector2i = piece_cells.get(selected_piece, selected_cell)
			var path: Array[Vector2i] = _build_path(parent_map, cell)
			if path.is_empty():
				return

			await _move_piece_step_by_step(selected_piece, start_cell, path)
			var used: int = path.size()
			steps_left = max(steps_left - used, 0)
			_set_roll_label(steps_for_current_piece, steps_left)


			# sync ตำแหน่งเลือกให้ตรงกับตำแหน่งใหม่ที่เพิ่งเดินถึง
			selected_cell = piece_cells[selected_piece]   # ใช้ข้อมูลจริงจาก map


			#

			if steps_left > 0:
				# ยังมีแต้มเหลือ → เดินต่อจากตำแหน่งปัจจุบัน
				_compute_reachable(selected_cell, steps_left)
				queue_redraw()  
				_show_move_skip_bar()     
				return
			else:
				if attack_bar: attack_bar.visible = false
				_start_card_phase()
				return



		# ไม่ใช่ปลายทาง → ลองเลือกตัวละครช่องนั้น
		_select_piece_at(cell)


		
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
					if active_piece != null:
						add_money(active_piece, -100)
					return
					
		if _is_targeting:
			if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
				_notify_center("ยกเลิกการเลือกเป้าหมาย")
				_exit_select_mode()
				get_tree().set_input_as_handled()
				return

			elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
				_notify_center("ยกเลิกการเลือกเป้าหมาย")
				_exit_select_mode()
				get_tree().set_input_as_handled()
				return
# หาตัวหมาก (Sprite2D) ที่อยู่ใน cell ที่กำหนด
func _get_piece_at(cell: Vector2i) -> Sprite2D:
	if cell.y < 0 or cell.y >= board_nodes.size():
		return null
	var row: Array = board_nodes[cell.y]
	if cell.x < 0 or cell.x >= row.size():
		return null
	return row[cell.x] as Sprite2D

func _update_skip_btn_text() -> void:
	if skip_btn == null:
		return
	var refund: int = max(steps_left, 0) * WALK_POINT_RATE  # 1 แต้ม = 12
	if refund > 0:
		skip_btn.text = "ข้าม (+%d)" % refund
	else:
		skip_btn.text = "ข้าม"


# === Turn system ===
@export var turn_label_path: NodePath  # ลาก Label ที่ไว้โชว์เทิร์นมาใส่ได้ เช่น /root/Board/Turn
@onready var Round_label: Label = get_node_or_null(turn_label_path)

# ลำดับผู้เล่นตามชื่อโหนดใต้ $Pieces
@export var turn_order_names: PackedStringArray = [
	"Good", "Call", "Hacker", "Police"
]


var players := ["Good", "Call", "Hacker", "Police"]   # ชื่อตรงกับชื่อ Node ใต้ Pieces
var current_player: int = 0                            # เริ่มคนที่ 0 = Good

					 # Sprite2D -> player_index


func _process(delta: float) -> void:
	if active_piece == null:
		return

	# เงิน (ตัวเก่า)
	if Input.is_action_just_pressed("ui_up"):
		_give(active_piece, 100)
	elif Input.is_action_just_pressed("ui_down"):
		_pay(active_piece, 100)

	# โล่ (ตัวใหม่)
	if Input.is_action_just_pressed("shield_up"):
		add_shield(active_piece, 50)   # +50 โล่
	elif Input.is_action_just_pressed("shield_down"):
		add_shield(active_piece, -50)  # -50 โล่



func _give(p: Sprite2D, amount: int) -> void:
	money_by_piece[p] = money_by_piece.get(p, 0) + amount
	_update_money_ui()          # ← เปลี่ยนมาเรียกอันนี้

func _pay(p: Sprite2D, amount: int) -> void:
	money_by_piece[p] = max(0, money_by_piece.get(p, 0) - amount)
	if money_by_piece[p] <= 0:
		_kill_piece(p)
	_update_money_ui()          # ← เปลี่ยนมาเรียกอันนี้
	hand_by_piece.erase(p)
	used_card_in_round.erase(p)
	counter_hack_turns.erase(p)
	_clear_all_def(p)

func _check_win_condition() -> void:
	# ชนะเมื่อเหลือผู้เล่นเพียง 1 คนใน turn_order
	if is_game_over:
		return
	if turn_order.size() <= 1:
		var winner: Sprite2D = turn_order[0] if turn_order.size() == 1 else null

		_show_win_screen(winner)

func _winner_texture_for(piece: Sprite2D) -> Texture2D:
	if piece == null:
		return null
	match piece.name:
		"Good":   return tex_good
		"Call":   return tex_call
		"Hacker": return tex_hack
		"Police": return tex_pol
		_:
			return null


func _show_win_screen(winner: Sprite2D) -> void:
	is_game_over = true

	if attack_bar:
		attack_bar.visible = false

	if win_panel:
		win_panel.visible = true

	if win_title:
		win_title.text = "ชัยชนะ!"

	if win_sub and winner:
		win_sub.text = "%s ชนะเกม!" % winner.name

	if win_icon:
		var tex := _winner_texture_for(winner)
		if tex != null:
			win_icon.texture = tex
			win_icon.visible = true
		else:
			win_icon.visible = false

	if quit_btn and not quit_btn.is_connected("pressed", Callable(get_tree(), "quit")):
		quit_btn.pressed.connect(get_tree().quit)


	# โชว์หน้าต่างชนะ
	win_panel.visible = true
	win_title.text = "ชัยชนะ!"
	win_sub.text = "%s ชนะเกม!" % winner.name

func flash_red(target: Sprite2D) -> void:
	if target == null:
		return
	var tw := create_tween()
	tw.tween_property(target, "modulate", Color(1, 0, 0, 1), 0.1) # เปลี่ยนเป็นแดง
	tw.tween_property(target, "modulate", Color(1, 1, 1, 1), 0.2) # กลับเป็นปกติ

func shake(target: Node2D, intensity: float = 60.0, duration: float = 0.3) -> void:
	if target == null:
		return
	var original_pos := target.position
	var tw := create_tween()
	var steps := int(duration / 0.05)
	for i in steps:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(target, "position", original_pos + offset, 0.05)
	tw.tween_property(target, "position", original_pos, 0.05)

func _show_move_skip_bar() -> void:
	if attack_bar == null or skip_btn == null:
		return
	attack_bar.visible = true         # โชว์คอนเทนเนอร์ที่มีปุ่มข้าม
	skip_btn.disabled = false
	_update_skip_btn_text()
	if not skip_btn.is_connected("pressed", Callable(self, "_on_skip_pressed")):
		skip_btn.pressed.connect(_on_skip_pressed)

	# ❌ ลบบรรทัดนี้ทิ้ง (มันทำให้หายทันที)
	# if attack_bar:
	#     attack_bar.visible = false


func _on_restart_pressed() -> void:
	# รีสตาร์ทซีนปัจจุบัน
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()


@export var settings_scene: PackedScene   # ตั้งค่าใน Inspector ได้or


func _on_settings_pressed() -> void:
	if settings_scene == null:
		return

	var overlay := settings_scene.instantiate()
	overlay.name = "SettingsOverlay"

	# ให้ overlay ทำงานตอน pause
	overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	$CanvasLayer.add_child(overlay)

	# หยุดเกมไว้ (แต่ overlay ยังทำงานอยู่)
	get_tree().paused = true

	# ถ้า overlay มีสัญญาณ 'closed' ก็ผูกแล้วคืนค่าเมื่อปิด
	if overlay.has_signal("closed"):
		overlay.connect("closed", Callable(self, "_on_settings_closed").bind(overlay))




func _adjacent_enemies_of(p: Sprite2D) -> Array[Sprite2D]:
	var res: Array[Sprite2D] = []
	if p == null or not piece_cells.has(p):
		return res

	var my_owner: int = piece_owner.get(p, _owner_from_name(p.name))
	var c: Vector2i = piece_cells[p]

	for d: Vector2i in ATTACK_DIRS:
		var v: Vector2i = c + d
		if not _in_bounds(v):
			continue
		var q: Sprite2D = _get_piece_at(v)
		if q == null or q == p:
			continue
		var q_owner: int = piece_owner.get(q, _owner_from_name(q.name))
		if q_owner != my_owner:
			res.append(q)

	return res
	
@export var MainMenuScene: PackedScene   # ชี้ไปหน้าเมนูของคุณ

func _on_quit_top_pressed() -> void:
	if quit_confirm:
		quit_confirm.dialog_text = "คุณต้องการออกจากเกมใช่หรือไม่"
		quit_confirm.ok_button_text = "ใช่"
		quit_confirm.cancel_button_text = "ไม่"
		quit_confirm.popup_centered()
	else:
		# ถ้าไม่ได้วาง dialog ไว้, ออกจากเกมเลย (ชั่วคราว)
		_on_quit_confirmed()

func _on_quit_confirmed() -> void:
	if MainMenuScene:
		get_tree().paused = false
		get_tree().change_scene_to_packed(MainMenuScene)
	else:
		get_tree().quit()

	

func _on_settings_closed(overlay: Node) -> void:
	get_tree().paused = false
	if is_instance_valid(overlay):
		overlay.queue_free()


func _refresh_card_bar_ui() -> void:
	if card_bar == null: return
	if active_piece == null: return

	if selected_card_index >= hand_by_piece.get(active_piece, []).size():
		selected_card_index = -1

	var hand: Array = hand_by_piece.get(active_piece, [])

	if slot_buttons.is_empty():
		_cache_slot_buttons()

	for i in range(slot_buttons.size()):
		var btn := slot_buttons[i]
		if btn == null: continue

		# กันผูกซ้ำ
		for c in btn.get_signal_connection_list("pressed"):
			btn.disconnect("pressed", c.callable)

		if i < hand.size():
			var info := _card_info(hand[i])
			btn.disabled = false
			btn.text = "%s\n(%s)" % [info.name, info.effect]
			btn.tooltip_text = info.desc
			btn.pressed.connect(_on_card_slot_pressed.bind(i))

			if selected_card_index == i:
				btn.add_theme_color_override("font_color", Color.WHITE)
			else:
				btn.add_theme_color_override("font_color", Color(0.9,0.9,0.9))
		else:
			btn.disabled = true
			btn.text = "-"
			btn.tooltip_text = ""
			btn.add_theme_color_override("font_color", Color(0.9,0.9,0.9))

	var used := bool(used_card_in_round.get(active_piece, false))
	if use_card_btn:
		use_card_btn.text = "ใช้การ์ด"
		use_card_btn.disabled = (selected_card_index < 0) or used
		if not use_card_btn.is_connected("pressed", Callable(self, "_on_use_card_pressed")):
			use_card_btn.pressed.connect(_on_use_card_pressed)

	if end_turn_btn:
		end_turn_btn.text = "จบเทิร์น"
		end_turn_btn.disabled = false
		if not end_turn_btn.is_connected("pressed", Callable(self, "_on_end_turn_pressed")):
			end_turn_btn.pressed.connect(_on_end_turn_pressed)



func _on_card_slot_pressed(i: int) -> void:
	selected_card_index = i
	_refresh_card_bar_ui()

func _on_use_card_pressed() -> void:
	if active_piece == null: return
	if selected_card_index < 0: return
	if bool(used_card_in_round.get(active_piece, false)): return

	var hand: Array = hand_by_piece.get(active_piece, [])
	if selected_card_index >= hand.size(): return
	var card: Variant = hand[selected_card_index]

	var info := _card_info(card)
	print("[UI] UseCard pressed. slot:", selected_card_index, " name:", info.name, " eff:", info.effect)

	var ok := _apply_card_effect(active_piece, card)
	if not ok:
		print("[UI] effect returned false")
		return

	# เอาการ์ดออก + mark used
	hand.remove_at(selected_card_index)
	hand_by_piece[active_piece] = hand
	used_card_in_round[active_piece] = true
	selected_card_index = -1
	_refresh_card_bar_ui()

	# ถ้ายังอยู่โหมดเลือก (teleport/เลือกผู้เล่น) → ห้ามจบเทิร์น
	if teleport_pending or _is_targeting:
		print("[UI] waiting for target click…")
		return

	_end_card_phase()
	_end_turn()



	for p in turn_order:
		print("HAND[", p.name, "] = ", hand_by_piece.get(p, []).size())

func _on_end_turn_pressed() -> void:
	_end_card_phase()
	_end_turn()

func apply_damage(p: Sprite2D, dmg: int) -> void:
	if p == null or dmg <= 0:
		return

	# 1) หักจากเกราะก่อน
	var shield_cur: int = int(shield_by_piece.get(p, 0))
	var after_shield: int = int(max(0, shield_cur - dmg))   # <- ระบุเป็น int
	var overflow: int = int(max(0, dmg - shield_cur))

	shield_by_piece[p] = after_shield
	_update_money_ui()  # อัปเดตโชว์เกราะที่ลดลงก่อน

	# 2) ถ้ายังเหลือดาเมจ → หักเงิน
	if overflow > 0:
		add_money(p, -overflow)   # ฟังก์ชันนี้ของคุณจะ clamp เป็น 0 + เช็ก kill ให้เรียบร้อย
	else:
		_check_win_condition()

func _start_card_phase() -> void:
	is_card_phase = true
	selected_card_index = -1
	teleport_pending = false

	# เคลียร์จุดเดิน + ป้ายแต้ม
	selected_piece = null
	reachable.clear()
	parent_map.clear()
	queue_redraw()
	_hide_roll_label()

	if attack_bar:
		attack_bar.visible = false

	if card_bar:
		card_bar.visible = true
	_refresh_card_bar_ui()

	if use_card_btn and not use_card_btn.is_connected("pressed", Callable(self, "_on_use_card_pressed")):
		use_card_btn.pressed.connect(_on_use_card_pressed)

	if end_turn_btn and not end_turn_btn.is_connected("pressed", Callable(self, "_on_end_turn_pressed")):
		end_turn_btn.pressed.connect(_on_end_turn_pressed)
	if card_bar:
		# โชว์แบบซ่อนอยู่ (เห็นขอบ) แล้วให้ผู้เล่นเลื่อนไปหาเอง
		card_bar.visible = true
		_slide_card_bar(false)


func _end_card_phase() -> void:
	is_card_phase = false
	teleport_pending = false
	if card_bar:
		card_bar.visible = false
		_cache_slot_buttons()

func _on_skip_pressed() -> void:
	var refund: int = max(steps_left, 0) * WALK_POINT_RATE
	if active_piece and refund > 0:
		add_money(active_piece, refund)

	steps_left = 0
	_hide_roll_label()

	# เดิมมี is_attack_phase → ไม่ใช้แล้ว
	# เข้าสู่ Card Phase เพื่อให้เลือกใช้การ์ด/หรือกดข้ามการ์ด
	_start_card_phase()




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

func _owner_from_name(n: String) -> int:
	match n:
		"Good": return 0
		"Call": return 1
		"Hacker": return 2
		"Police": return 3
		_: return -1

func _setup_owners_by_name() -> void:
	piece_owner.clear()
	for n in $Pieces.get_children():
		if n is Sprite2D:
			var s := n as Sprite2D
			piece_owner[s] = _owner_from_name(s.name)

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
		var s := c as Sprite2D
		if s != null:
			if not money_by_piece.has(s):
				money_by_piece[s] = hp_start
			if not shield_by_piece.has(s):
				shield_by_piece[s] = 0


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
# กำหนดเงินเริ่มต้นให้ทุกตัว
	for child in pieces.get_children():
		var s := child as Sprite2D
		if s != null:
			if not money_by_piece.has(s):
				money_by_piece[s] = hp_start
			if not shield_by_piece.has(s):
				shield_by_piece[s] = 0

	_update_money_ui()
	_setup_money()
func _update_money_ui() -> void:
	if player_profiles == null:
		return

	var profile_nodes = player_profiles.get_children()
	for p in profile_nodes:
		var info = p.get_node_or_null("Info")
		if info == null:
			continue

		var money_label = info.get_node("MoneyLabel") as Label
		var name_label  = info.get_node("NameLabel") as Label

		var piece := $Pieces.get_node_or_null(name_label.text) as Sprite2D
		var money_amt: int = 0
		var shield_amt: int = 0
		if piece:
			money_amt  = int(money_by_piece.get(piece, 0))
			shield_amt = int(shield_by_piece.get(piece, 0))
		money_label.text = "เงิน: %d (%d)" % [max(0, money_amt), max(0, shield_amt)]






func add_money(p: Sprite2D, delta: int) -> void:
	if p == null:
		return
	var cur: int = int(money_by_piece.get(p, hp_start))  # <- cast เป็น int
	var newv: int = max(0, cur + delta)                  # <- ระบุชนิด
	money_by_piece[p] = newv
	_update_money_ui()
	if newv <= 0:
		_kill_piece(p)
		return
	_check_win_condition()




func _kill_piece(p: Sprite2D) -> void:
	# ลบจากบอร์ด & ข้อมูล
	if piece_cells.has(p):
		var c: Vector2i = piece_cells[p]
		board_nodes[c.y][c.x] = null
		piece_cells.erase(p)
	money_by_piece.erase(p)
	if turn_order.has(p):
		turn_order.erase(p)
		if turn_order.is_empty():
			active_piece = null
		else:
			turn_idx %= turn_order.size()
			active_piece = turn_order[turn_idx]
	p.queue_free()
	queue_redraw()
	shield_by_piece.erase(p)         # NEW
	update_money(p.name, 0)   
	_update_money_ui()
	frozen_turns.erase(p)

	# ถ้าคนเล่นหมด → จบเกม (ตามที่อยากทำ)
	if turn_order.size() == 0:
		print("Game Over")


func set_money(piece: Sprite2D, value: int) -> void:
	if piece == null:
		return
	money_by_piece[piece] = clamp(value, 0, 999999)
	_update_money_ui()
	if money_by_piece[piece] <= 0:
		_remove_piece_from_board(piece)
		all_def_turns.erase(piece)
		frozen_turns.erase(piece)
func _setup_money() -> void:
	for child in pieces.get_children():
		var s := child as Sprite2D
		if s != null:
			if not money_by_piece.has(s):
				money_by_piece[s] = hp_start
			if not shield_by_piece.has(s):
				shield_by_piece[s] = 0

# ตั้งมือเริ่มต้น + ธงรอบ
	for child in pieces.get_children():
		var s := child as Sprite2D
		if s != null:
			if not hand_by_piece.has(s):
				hand_by_piece[s] = []        # เริ่มมือว่าง
			if not used_card_in_round.has(s):
				used_card_in_round[s] = false


func _ensure_hand_maps() -> void:
	for child in pieces.get_children():
		var s := child as Sprite2D
		if s == null: continue
		if not hand_by_piece.has(s):
			hand_by_piece[s] = []          # มือเปล่า
		if not used_card_in_round.has(s):
			used_card_in_round[s] = false  # ยังไม่ได้ใช้การ์ดในรอบ


func _remove_piece_from_board(piece: Sprite2D) -> void:
	# เอาออกจากตาราง
	if piece_cells.has(piece):
		var c: Vector2i = piece_cells[piece]
		if _in_bounds(c) and c.y < board_nodes.size():
			var row: Array = board_nodes[c.y]
			if c.x < row.size():
				row[c.x] = null
		piece_cells.erase(piece)
		shield_by_piece.erase(piece)     # NEW
		_update_money_ui()
		counter_hack_turns.erase(piece)

	# เอาออกจากลิสต์เงินและเลือก/จุดแสดง
	money_by_piece.erase(piece)
	if selected_piece == piece:
		selected_piece = null
		selected_cell  = Vector2i(-1, -1)
		reachable.clear()
		parent_map.clear()

	# เอาออกจากคิวเทิร์น
	if turn_order.has(piece):
		var was_active := (active_piece == piece)
		turn_order.erase(piece)
		# ถ้าเป็นตัวที่กำลังเล่นอยู่ → กระโดดไปตัวถัดไป (ถ้ามี)
		if was_active:
			if turn_order.size() > 0:
				turn_idx = turn_idx % turn_order.size()
				active_piece = turn_order[turn_idx]
			else:
				active_piece = null  # เกมจบได้ในอนาคตถ้าต้องการ

	# ลบ node ออกจากซีน
	piece.queue_free()

	# อัปเดตหน้าจอ/ข้อความ
	_update_money_ui()
	if active_piece != null and has_method("_update_turn_label"):
		_update_side_turn_label()
	queue_redraw()



# ตอนเปิดเต๋า
func _open_dice_panel_for_selected() -> void:
	# ห้ามเปิดถ้าอยู่ใน Card phase หรือกำลังเดิน หรือมีหน้าทอยค้างอยู่
	if is_card_phase or is_moving or dice_open:
		return

	# ถ้าเทิร์นนี้ทอยไปแล้ว (steps_for_current_piece > 0) ไม่ให้ทอยใหม่
	if steps_for_current_piece > 0:
		return

	if dice_ui == null:
		# fallback ก็ต้องเคารพกติกาเดียวกัน: ไม่ออโต้ใส่แต้มถ้าไม่ใช่จังหวะเริ่มเดิน
		return

	# เปิดเต๋าตามปกติ
	if not dice_ui.is_connected("rolled", Callable(self, "_on_dice_rolled")):
		dice_ui.connect("rolled", Callable(self, "_on_dice_rolled"))
	if not dice_ui.is_connected("closed", Callable(self, "_on_dice_closed")):
		dice_ui.connect("closed", Callable(self, "_on_dice_closed"))

	dice_open = true
	dice_has_result = false
	steps_for_current_piece = 0
	dice_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	dice_ui.open()




# ====================================================================
# SELECT / REACH
# ====================================================================
func _select_piece_at(cell: Vector2i) -> void:
	# ห้ามเลือก/เปิดเต๋า ระหว่าง card phase, ระหว่างกำลังเดิน หรือขณะหน้าทอยเปิดอยู่
	if is_card_phase or is_moving or dice_open:
		return

	# ถ้าเทิร์นนี้ทอยแล้วและแต้มถูกใช้จนหมด (steps_for_current_piece > 0 แต่ steps_left == 0)
	# ไม่ให้เปิดเต๋าใหม่
	if steps_for_current_piece > 0 and steps_left == 0:
		return

	# ของเดิมต่อ…
	var piece := _get_piece_at(cell)
	if piece == null: return
	if active_piece == null or piece != active_piece: return

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
	steps_left = steps_for_current_piece   # เริ่มต้นแต้มเดิน
	dice_has_result = true
	_set_roll_label(steps_for_current_piece, steps_left)


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
	piece_cells[piece] = cur
		 # <- สำคัญมาก ใช้กับไฮไลท์เทิร์น

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
	if is_game_over:
		return
	selected_piece = null
	selected_cell  = Vector2i(-1, -1)
	reachable.clear()
	parent_map.clear()
	_hide_roll_label()
	steps_left = 0
	steps_for_current_piece = 0
	dice_has_result = false
	dice_open = false
	if dice_ui:
		dice_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# ไปคนถัดไป (วน)
	if turn_order.is_empty():
		active_piece = null
		return

	# --- เดินไปคนถัดไป (จำค่าเก่าก่อน incre) ---
	var prev_idx := turn_idx
	turn_idx = (turn_idx + 1) % turn_order.size()
	active_piece = turn_order[turn_idx]
	current_player = _active_player_index()

	# ถ้า wrap กลับมาที่ index 0 = ครบ 1 รอบ
	if turn_idx == 0:
		turn_cycles_done += 1
		draw_card_for_all()
		_decay_all_def_one_round()    
		_update_round_label()
		if turn_cycles_done >= MAX_TURNS:
			_end_game_by_turn_limit()
			return

	# ข้ามผู้เล่นที่ถูก Freeze (ลดค่านับทุกครั้งที่ถึงคิวเขา)
	var safety := 0
	while active_piece != null and _is_frozen(active_piece) and safety < 16 and not turn_order.is_empty():
		var left := int(frozen_turns.get(active_piece, 0)) - 1
		if left <= 0:
			_clear_freeze(active_piece)
			_notify_center("%s หลุด Freeze แล้ว" % active_piece.name)
		else:
			frozen_turns[active_piece] = left
			_notify_center("%s ถูก Freeze — ข้ามเทิร์น (เหลือ %d)" % [active_piece.name, left])

		# ไปคนถัดไปเหมือนเดิม
		turn_idx = (turn_idx + 1) % turn_order.size()
		active_piece = turn_order[turn_idx]
		current_player = _active_player_index()

		if turn_idx == 0:
			turn_cycles_done += 1
			draw_card_for_all()
			_update_round_label()
			if turn_cycles_done >= MAX_TURNS:
				_end_game_by_turn_limit()
				return
		safety += 1


	_update_side_turn_label()
	_update_turn_ui()     # ถ้ายังต้องแสดงที่อื่นอยู่
	_update_money_ui()
	queue_redraw()
	_check_win_condition()
	
func _end_game_by_turn_limit() -> void:
	# หาเงินสูงสุดจากผู้เล่นที่ยังอยู่บนบอร์ด
	var winner: Sprite2D = null
	var best: int = -1
	for p in turn_order:
		var m: int = money_by_piece.get(p, 0)
		if m > best:
			best = m
			winner = p

	# ถ้าจะรองรับเสมอ: เช็กว่ามีหลายคนเงินเท่ากัน best แล้วทำ Popup แจ้ง "เสมอ"
	# ตอนนี้ให้ประกาศผู้ชนะคนแรกที่คะแนนสูงสุดก่อน
	_show_win_screen(winner)


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


# ตั้งค่าใน Inspector แล้ว: Card dB = res://data/cards/card_database.tres

func _get_card_db() -> Object:
	return card_db if card_db != null else null

func _draw_random_card() -> Resource:
	var db := _get_card_db()
	if db == null:
		push_warning("Card DB is not set on Board (Card dB).")
		return null

	var picked: Resource = null

	if db.has_method("draw_any"):
		picked = db.call("draw_any") as Resource

	elif db.has_method("draw_random"):
		picked = db.call("draw_random") as Resource

	else:
		# fallback: ดึง property 'cards' แล้ว cast เป็น Array ให้ชัด
		var cards_var: Variant = db.get("cards")
		if cards_var is Array:
			var cards: Array = cards_var as Array
			if cards.size() > 0:
				var idx := randi() % cards.size()
				picked = cards[idx] as Resource

	return picked






func draw_card_for(piece: Sprite2D) -> void:
	if piece == null: return
	var hand: Array = hand_by_piece.get(piece, [])
	var c: Resource = _draw_random_card()
	if c != null:
		# ถ้าเป็นการ์ดแบบ on-draw (เช่น System Failure) จะถูกใช้/ทิ้งทันที
		if not _on_card_drawn(piece, c):
			hand.append(c)
	hand_by_piece[piece] = hand





func draw_card_for_all() -> void:
	for p in turn_order:
		draw_card_for(p)
		used_card_in_round[p] = false
	# ถ้าคุณมี UI แสดงมือของ “ผู้เล่นปัจจุบัน” ให้รีเฟรชด้วย
	_refresh_card_bar_ui()

func _deal_initial_hands(card_count: int = 5) -> void:
	_ensure_hand_maps()
	if turn_order.is_empty():
		for child in $Pieces.get_children():
			if child is Sprite2D:
				turn_order.append(child as Sprite2D)

	for p in turn_order:
		var hand: Array = []

		# (ถ้ามีของเดิมในมือก็กรอง on-draw ด้วย — ปกติเริ่มเกมจะว่าง)
		var raw = hand_by_piece.get(p, [])
		if raw is Array:
			for c in raw:
				if c != null and not _on_card_drawn(p, c):
					hand.append(c)

		# แจกไพ่เปิดเกม พร้อมบังคับใช้ใบที่เป็น on-draw ทันที
		for _i in range(card_count):
			var c: Resource = _draw_random_card()
			if c != null and not _on_card_drawn(p, c):
				hand.append(c)

		hand_by_piece[p] = hand
		used_card_in_round[p] = false

	if card_bar and active_piece:
		_refresh_card_bar_ui()



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
var steps_left: int = 0
var dice_open: bool = false
var dice_has_result: bool = false
var _pending_show_moves: bool = false   # ← ใหม่: รอแสดงจุดหลังปิดหน้าต่าง

func _on_dice_closed() -> void:
	dice_open = false
	if active_piece == null: return
	if not dice_has_result: return

	if piece_cells.has(active_piece):
		selected_cell = piece_cells[active_piece]
	else:
		selected_cell = _pixel_to_cell(active_piece.global_position)

	steps_left = steps_for_current_piece            # ← ใช้ตัวนี้เป็นตัวจริง
	_compute_reachable(selected_cell, steps_left)   # ← คิดจากจุดปัจจุบันกับแต้มที่เหลือ
	queue_redraw()
	_set_roll_label(steps_for_current_piece, steps_left)
	_update_money_ui()
	_update_skip_btn_text()
	_show_move_skip_bar()
	if dice_ui:
		dice_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE





	print("dice closed, cell=", selected_cell, " steps=", steps_for_current_piece)
	print("reachable=", reachable)

@export var dice_roll_label_path: NodePath
@onready var dice_roll_label: Label = get_node_or_null(dice_roll_label_path)

func _set_roll_label(total: int, left: int) -> void:
	if dice_roll_label:
		dice_roll_label.visible = true
		dice_roll_label.text = "แต้มเดิน: %d  (เหลือ %d)" % [total, left]

func _hide_roll_label() -> void:
	if dice_roll_label:
		dice_roll_label.visible = false
		dice_roll_label.text = ""



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

func _apply_card_effect(user: Sprite2D, card: Variant) -> bool:
	var info := _card_info(card)
	var eff  := String(info.effect)
	var key  := eff.strip_edges().to_lower()
	var norm := key.replace("_","").replace("-","").replace(" ","").replace("%","")
	print("[CARD] use:", info.name, " effect:", eff, " -> key:", key, " norm:", norm)

	# ====== ✅ เพิ่มเคส Teleport / Trace Jump ======
	if norm == "teleport" \
	or norm.begins_with("teleport") \
	or norm == "tracejump" \
	or norm.begins_with("tracejump") \
	or norm == "jump" \
	or norm == "warp":
		teleport_pending = true
		_begin_teleport_targeting()     # โชว์จุดวาร์ป (cells ว่างทั้งหมด)
		print("[CARD] enter targeting: TELEPORT")
		return true
	# ===============================================

	# == Root Access Heist (50% เลือกผู้เล่นคนใดก็ได้) ==
	if norm == "rootaccessheist" or norm == "steal50" or norm.begins_with("steal50"):
		var enemies := _get_alive_enemy_pieces_of_current_player()
		if enemies.is_empty():
			_notify_center("ไม่มีผู้เล่นอื่นให้เลือก")
			return false
		print("[CARD] enter targeting: Root Access Heist")
		play_card_steal_50Per()
		return true

	# == Cryptoworm Drain (20% ระยะประชิด) ==
	if norm == "cryptowormdrain" or norm == "steal20" or norm.begins_with("steal20"):
		var user_piece := _get_current_player_piece()
		if user_piece == null: return false
		var adj := _adjacent_enemies_of(user_piece)
		if adj.is_empty():
			_notify_center("ไม่มีศัตรูระยะประชิด")
			return false
		if adj.size() == 1:
			_resolve_card_steal_20_per(adj[0].name)
			return true
		print("[CARD] enter targeting: Cryptoworm Drain")
		play_card_steal_20Per()
		return true
		
		# == Counter Hack: ให้บัพ 5 เทิร์น สะท้อนการโจมตีครั้งถัดไป ==
	if norm == "countershield" or norm == "countersheild" or norm == "counterhack" or norm.begins_with("counter"):
		_give_counter_hack(user, 5)   # อายุ 5 เทิร์น
		print("[CARD] Counter Hack applied to", user.name)
		return true
	if norm == "alldef" or norm == "reflectivesurge" or norm.begins_with("alldef"):
		_give_all_def(user, 5)      # อายุ 5 เทิร์น
		return true
	# == Process Freeze ==
	if norm == "processfreeze" or norm == "pfreeze" or norm.begins_with("freeze"):
		var enemies := _get_alive_enemy_pieces_of_current_player()
		if enemies.is_empty():
			_notify_center("ไม่มีผู้เล่นอื่นให้เลือก")
			return false
		print("[CARD] enter targeting: Process Freeze")
		_enter_select_mode(CardTargetMode.SELECT_PLAYER_FREEZE, enemies)
		return true

	
	match norm:
		"steal100":
			var targets := _adjacent_enemies_of(user)
			if targets.is_empty():
				print("[CARD] steal100: no adjacent target")
				return false
			var t: Sprite2D = targets[0]
			var stolen := _steal_from(t, user, 100)
			print("[CARD] steal100: stolen =", stolen)
			return true

		"shield50":
			add_shield(user, 50)
			print("[CARD] shield +50 to", user.name)
			return true

		# ✅ Security Protocol (โล่ +125)
		"shield125", "securityprotocol":
			add_shield(user, 125)
			_notify_center("Security Protocol! โล่ +125 ให้ %s" % user.name)
			print("[CARD] shield +125 to", user.name)
			return true


		"pirsteal100":
			var user_piece := user
			# เลือกเป้าหมายตามเงื่อนไขเดิมของคุณ (ตัวอย่างใช้ศัตรูติดตัวถ้ามี)
			var targets := _adjacent_enemies_of(user_piece)
			if targets.is_empty():
				print("[CARD] pir_steal_100: no target")
				return false
			var t: Sprite2D = targets[0]

			# ✅ ถ้าเหยื่อมี Counter Hack → สะท้อนกลับใส่ผู้โจมตี (ทะลุโล่)
			if _has_counter_hack(t):
				var have := int(money_by_piece.get(user_piece, 0))
				var take: int = int(min(100, have))
				if take > 0:
					add_money(user_piece, -take)  # bypass shield
					add_money(t,          +take)
				_notify_center("Counter Hack! สะท้อนกลับ %d จาก %s" % [take, user_piece.name])
				_clear_counter_hack(t)
				return true

			# ปกติ: ทะลุโล่ 100 จากเหยื่อ → โอนไปให้ผู้ใช้
			var have_amt: int = int(money_by_piece.get(t, 0))
			var take_amt: int = min(100, have_amt)
			if take_amt > 0:
				add_money(t,         -take_amt)   # bypass shield
				add_money(user_piece, take_amt)
			return true

		_:
			print("[CARD] no handler for effect:", eff)
			return false





func _setup_card_bar_slide() -> void:
	if card_bar == null:
		return

	# คำนวนตำแหน่งเป้าหมาย
	var screen_h := get_viewport_rect().size.y
	var bar_h := card_bar.size.y
	_bar_shown_y = screen_h - bar_h            # โชว์เต็ม
	_bar_hidden_y = screen_h - card_peek_px    # ซ่อน เหลือให้เห็นแค่ขอบบน

	# ตั้งค่าเริ่มต้น (ซ่อนหลบลงไว้ก่อน)
	card_bar.position.y = _bar_hidden_y
	card_bar.visible = true
	# ให้ซ้อนบน UI อื่น
	card_bar.z_index = 1000

	# ตัวจับเวลาไว้ดีเลย์ตอนซ่อน
	if _hold_timer == null:
		_hold_timer = Timer.new()
		_hold_timer.one_shot = true
		add_child(_hold_timer)
		_hold_timer.timeout.connect(func():
			_slide_card_bar(false)   # ครบเวลาแล้วค่อยหุบ
		)


	# ต่อสัญญาณ hover ทั้งแถบการ์ด และ hover zone
	if hover_zone:
		# ให้ hover แล้วคลิกทะลุ ถ้าต้องการ
		hover_zone.mouse_filter = Control.MOUSE_FILTER_PASS
		if not hover_zone.is_connected("mouse_entered", Callable(self, "_keep_bar_open")):
			hover_zone.mouse_entered.connect(_keep_bar_open)

	# เวลาเลื่อนไปอยู่บนตัว CardBar เองก็ให้รีสตาร์ทเหมือนกัน
	card_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	if not card_bar.is_connected("mouse_entered", Callable(self, "_keep_bar_open")):
		card_bar.mouse_entered.connect(_keep_bar_open)

	# ถ้าจะให้ขยับบนปุ่ม/สล็อตก็รีสตาร์ทด้วย
	_cache_slot_buttons()
	for b in slot_buttons:
		if b and not b.is_connected("mouse_entered", Callable(self, "_keep_bar_open")):
			b.mouse_entered.connect(_keep_bar_open)

	# เริ่มต้นให้หุบ (เห็นแค่ขอบ)
	_slide_card_bar(false)

func _slide_card_bar(show: bool) -> void:
	if card_bar == null:
		return
	if _bar_tween and _bar_tween.is_running():
		_bar_tween.kill()

	var target_y = _bar_shown_y if show else _bar_hidden_y
	_bar_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bar_tween.tween_property(
		card_bar, "position",
		Vector2(card_bar.position.x, target_y),
		card_slide_duration
	)

func _keep_bar_open() -> void:
	_slide_card_bar(true)     # โชว์ขึ้น
	if _hold_timer:
		_hold_timer.start(card_hold_seconds)  # รีสตาร์ทเป็น 5s ทุกครั้งที่โดนเมาส์


func _on_card_hover_enter() -> void:
	if _hide_timer and _hide_timer.time_left > 0.0:
		_hide_timer.stop()
	_slide_card_bar(true)

func _on_card_hover_exit() -> void:
	# ไม่ทำอะไร ปล่อยให้หุบเองเมื่อครบเวลา
	pass

func _card_info(card: Variant) -> Dictionary:
	# คืนค่า {name, effect, desc} เสมอ
	if card == null:
		return {"name":"(card)","effect":"","desc":""}
	if card is CardData:
		var c: CardData = card
		return {"name": c.name, "effect": c.effect, "desc": c.desc}
	if card is Dictionary:
		return {
			"name": String(card.get("name","(card)")),
			"effect": String(card.get("effect","")),
			"desc": String(card.get("desc",""))
		}
	# fallback
	return {"name":"(card)","effect":"","desc":""}

# helper: steal amount จาก target ให้ thief
# - shield จะถูกลดก่อน (แต่ไม่ถูกย้าย)
# - เงิน (money_by_piece) ถูกลดตามส่วนที่เหลือ และโอนให้ thief
func _steal_from(target: Sprite2D, thief: Sprite2D, amount: int, bypass_all_def: bool=false) -> int:
	if target == null or thief == null or amount <= 0:
		return 0
	if _has_all_def(target) and not bypass_all_def:
		_notify_center("Reflective Surge ของ %s ป้องกันการโจมตีไว้" % target.name)
		_clear_all_def(target)     # ใช้แล้วหาย
		_update_money_ui()
		return 0

	# …ส่วนลดโล่/โอนเงินเหมือนเดิม…
	var shield_cur: int = int(shield_by_piece.get(target, 0))
	var shield_used: int = min(shield_cur, amount)
	if shield_used > 0:
		shield_by_piece[target] = max(0, shield_cur - shield_used)
		_update_money_ui()

	var remain_to_steal: int = amount - shield_used
	var money_taken: int = 0
	if remain_to_steal > 0:
		var money_cur: int = int(money_by_piece.get(target, 0))
		money_taken = min(remain_to_steal, money_cur)
		if money_taken > 0:
			add_money(target, -money_taken)
			add_money(thief, money_taken)
	return money_taken



# ใน _apply_card_effect ให้เปลี่ยน "steal_100" เป็นเรียก helper
# คืนลิสต์ทุก cell ว่างบนกระดาน
func _all_empty_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var c := Vector2i(x, y)
			if not _is_occupied(c):
				cells.append(c)
	return cells

# เข้าโหมดเลือกเป้าหมายวาร์ป: ซ่อนแถบการ์ด, โชว์จุดทั่วแมพ
func _begin_teleport_targeting() -> void:
	# ไม่ต้องอยู่ใน CardBar แล้ว ให้คลิกบนบอร์ดได้เลย
	is_card_phase = false
	if card_bar: 
		card_bar.visible = false

	# ให้กรอบไฮไลต์อยู่รอบตัวผู้เล่นตอนนี้ก็ได้ (ไม่บังคับ)
	if piece_cells.has(active_piece):
		selected_cell = piece_cells[active_piece]
	else:
		selected_cell = _pixel_to_cell(active_piece.global_position)

	# จุดขาว = ทุก cell ว่าง
	reachable = _all_empty_cells()
	parent_map.clear()  # ไม่ใช้ BFS ในโหมดนี้
	queue_redraw()

# หา enemy ที่ใกล้ที่สุดภายใน Manhattan range (exclude user)
func _find_nearest_enemy_in_range(user: Sprite2D, max_range: int) -> Sprite2D:
	if user == null: return null
	if not piece_cells.has(user): return null
	var start: Vector2i = piece_cells[user]
	var best: Sprite2D = null
	var best_d: int = 9999
	for p in turn_order:
		if p == user: continue
		if not piece_cells.has(p): continue
		var c: Vector2i = piece_cells[p]
		var d: int = abs(c.x - start.x) + abs(c.y - start.y)
		if d <= max_range and d < best_d:
			best_d = d
			best = p
	return best


# ทำชื่อ sprite ให้หาได้แน่นอน
const MARKER_SPRITE_NAME := "MarkerSprite"

func _set_marker_alpha(area: Area2D, alpha: float) -> void:
	var spr := area.get_node_or_null(MARKER_SPRITE_NAME) as Sprite2D
	if spr:
		var m := spr.modulate
		m.a = alpha
		spr.modulate = m

func _marker_hover_entered(area: Area2D) -> void:
	_set_marker_alpha(area, 1.0)

func _marker_hover_exited(area: Area2D) -> void:
	_set_marker_alpha(area, 0.8)


# ===== เพิ่มบนสุดของ Board.gd =====
enum CardTargetMode { NONE, SELECT_PLAYER_STEAL50, SELECT_ADJ_STEAL20, SELECT_PLAYER_FREEZE }



var _card_target_mode: int = CardTargetMode.NONE
var _is_targeting: bool = false
var _marker_tex: Texture2D           # เท็กซ์เจอร์สี่เหลี่ยมแดงโปร่ง
var _active_markers: Array[Node] = [] # เก็บ Area2D ที่สปาวน์ไว้ตอนเลือกเป้าหมาย

@onready var target_markers_root: Node2D = Node2D.new()

# ===== เรียกใช้จากระบบการ์ดของคุณเมื่อกดใช้ Root Access Heist =====
func play_card_steal_50Per() -> void:
	# ตรวจว่ามีศัตรูให้เลือกไหม
	var enemies := _get_alive_enemy_pieces_of_current_player()
	if enemies.is_empty():
		_notify_center("ไม่มีผู้เล่นอื่นให้เลือก")
		return

	_enter_select_mode(CardTargetMode.SELECT_PLAYER_STEAL50, enemies)
	print("enter targeting")
func _enter_select_mode(mode: int, target_pieces: Array) -> void:
	_clear_target_markers()
	_card_target_mode = mode
	_is_targeting = true
	_spawn_markers_for_pieces(target_pieces)
	_notify_right("เลือกผู้เล่นเป้าหมาย (คลิกสี่เหลี่ยมแดง) • กดยกเลิก: ESC/คลิกขวา")
	
func _exit_select_mode() -> void:
	_clear_target_markers()
	_card_target_mode = CardTargetMode.NONE
	_is_targeting = false

func _steal_percent_respecting_shield(victim: Sprite2D, thief: Sprite2D, percent: float) -> int:
	if victim == null or thief == null: return 0

	# ✅ ถ้ามี Counter Hack บนเหยื่อ → สะท้อนกลับใส่ผู้โจมตี
	if _has_counter_hack(victim):
		var attacker_money := int(money_by_piece.get(thief, 0))
		var want := int(floor(max(0.0, percent) * float(attacker_money)))
		var got := _steal_from(thief, victim, want)  # เคารพโล่ของผู้โจมตีตามปกติ
		_notify_center("Counter Hack! สะท้อนกลับ %d จาก %s" % [got, thief.name])
		_clear_counter_hack(victim)
		return got

	# ปกติ: ขโมยตามเปอร์เซ็นต์ของเหยื่อ
	var victim_money := int(money_by_piece.get(victim, 0))
	var want := int(floor(max(0.0, percent) * float(victim_money)))
	if want <= 0: return 0
	return _steal_from(victim, thief, want)



func _spawn_markers_for_pieces(pieces: Array) -> void:
	for piece in pieces:
		if not piece is Node2D: 
			continue
		var area := Area2D.new()
		area.input_pickable = true         # สำคัญ
		area.z_index = 10000
		area.set_meta("target_piece_name", piece.name)

		var sprite := Sprite2D.new()
		sprite.texture = _marker_tex
		sprite.centered = true
		sprite.modulate = Color(1, 0, 0, 0.8)
		sprite.name = MARKER_SPRITE_NAME
		sprite.scale = Vector2(float(CELL_SIZE)/64.0, float(CELL_SIZE)/64.0)

		area.global_position = piece.global_position   # ให้อยู่ทับชิ้นหมากจริง

		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(CELL_SIZE, CELL_SIZE)
		cs.shape = shape

		area.input_event.connect(Callable(self, "_on_target_marker_input").bind(area))
		area.mouse_entered.connect(Callable(self, "_marker_hover_entered").bind(area))
		area.mouse_exited.connect(Callable(self, "_marker_hover_exited").bind(area))

		area.add_child(cs)
		area.add_child(sprite)
		target_markers_root.add_child(area)
		_active_markers.append(area)



func _clear_target_markers() -> void:
	for n in _active_markers:
		if is_instance_valid(n):
			n.queue_free()
	_active_markers.clear()

# ลายเซ็นใหม่ ต้องมี area: Area2D เข้ามา (เราส่ง bind ไว้แล้วตอน connect)
func _on_target_marker_input(viewport: Viewport, event: InputEvent, _shape_idx: int, area: Area2D) -> void:
	if not _is_targeting:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target_piece_name := area.get_meta("target_piece_name") as String
		if target_piece_name == "":
			return

		match _card_target_mode:
			CardTargetMode.SELECT_PLAYER_STEAL50:
				_resolve_card_steal_50_per(target_piece_name)
			CardTargetMode.SELECT_ADJ_STEAL20:
				_resolve_card_steal_20_per(target_piece_name)
			CardTargetMode.SELECT_PLAYER_FREEZE:
				_resolve_card_freeze(target_piece_name)
				
		_exit_select_mode()
		get_viewport().set_input_as_handled()
		
func _flash_piece_node(p: Sprite2D) -> void:
	if p:
		var old_color := p.modulate
		p.modulate = Color(1, 0.5, 0.5)   # เปลี่ยนเป็นสีแดงอ่อน
		await get_tree().create_timer(0.18).timeout
		p.modulate = old_color


func _resolve_card_steal_50_per(target_piece_name: String) -> void:
	var attacker := active_piece as Sprite2D
	if attacker == null:
		_notify_center("ไม่พบผู้เล่นที่ใช้การ์ด")
		return
	var victim := pieces_root.get_node_or_null(target_piece_name) as Sprite2D
	if victim == null:
		_notify_center("ไม่พบเป้าหมาย")
		return
	if attacker == victim:
		_notify_center("ห้ามเลือกตัวเอง")
		return

	var got := _steal_percent_respecting_shield(victim, attacker, 0.5)  # 50%
	if got <= 0 and int(shield_by_piece.get(victim, 0)) > 0:
		_notify_center("โล่ของ %s ป้องกันไว้" % victim.name)
	else:
		_notify_center("Root Access Heist! ขโมย %d จาก %s" % [got, victim.name])

	_flash_piece_node(victim)
	_shake_camera_light()
	if int(money_by_piece.get(victim, 0)) <= 0:
		_kill_piece(victim)
	_on_card_resolved()


func _resolve_card_freeze(target_piece_name: String) -> void:
	var attacker := active_piece as Sprite2D
	if attacker == null:
		_notify_center("ไม่พบผู้เล่นที่ใช้การ์ด")
		return
	var victim := pieces_root.get_node_or_null(target_piece_name) as Sprite2D
	if victim == null:
		_notify_center("ไม่พบเป้าหมาย")
		return
	if attacker == victim:
		_notify_center("ห้ามเลือกตัวเอง")
		return

	_freeze_player(victim, PROCESS_FREEZE_TURNS)
	_notify_center("Process Freeze! %s ข้าม %d เทิร์น" % [victim.name, int(frozen_turns.get(victim,0))])
	_flash_piece_node(victim)
	_shake_camera_light()
	_on_card_resolved()


func _get_current_player_piece() -> Sprite2D:
	return active_piece as Sprite2D


func _get_current_player_name() -> String:
	# แทนด้วยตัวแปร/ระบบเทิร์นของคุณ
	# เช่น current_turn_name หรือ players_order[current_turn_index]
	return _get_current_player_piece().name

func _get_alive_enemy_pieces_of_current_player() -> Array:
	var res: Array = []
	var me := _get_current_player_piece()
	if me == null:
		return res

	for c in pieces_root.get_children():
		var p := c as Sprite2D
		if p == null:
			continue
		if p == me:
			continue
		# ถ้ายังไม่มีระบบ owner ให้ถือว่าคนอื่นทั้งหมดคือศัตรู
		if _is_piece_alive_node(p):
			res.append(p)
	return res

func _is_piece_alive_node(p: Sprite2D) -> bool:
	return p != null and money_by_piece.has(p) and int(money_by_piece[p]) > 0

# ป้ายข้อความแบบย่อ (คุณจะมีระบบ UI ของคุณอยู่แล้ว)
func _notify_center(text: String) -> void:
	if has_node("CanvasLayer/DiceRollLabel"):
		$"CanvasLayer/DiceRollLabel".text = text

func _notify_right(text: String) -> void:
	if has_node("CanvasLayer/SideTurnLabel"):
		$"CanvasLayer/SideTurnLabel".text = text

func _flash_piece(piece_name: String) -> void:
	# ถ้ามีเอฟเฟกต์อยู่แล้วให้เรียกของเดิม; นี่เป็น placeholder
	var p := pieces_root.get_node_or_null(piece_name)
	if p and p is CanvasItem:
		(p as CanvasItem).modulate = Color(1,0.6,0.6)
		await get_tree().create_timer(0.18).timeout
		(p as CanvasItem).modulate = Color(1,1,1)

func _shake_camera_light() -> void:
	# ถ้ามีกล้อง ใส่เอฟเฟกต์เบา ๆ ได้; เว้นว่างได้เช่นกัน
	pass

func _on_card_resolved() -> void:
	_end_card_phase()
	_end_turn()
	pass

func _ensure_hand_slot(piece: Sprite2D) -> void:
	if piece == null: return
	if not hand_by_piece.has(piece):
		hand_by_piece[piece] = []

func draw_card_for_piece(piece: Sprite2D, count: int = 1) -> int:
	if piece == null: return 0
	_ensure_hand_slot(piece)

	var hand: Array = hand_by_piece[piece]
	var drawn := 0

	for i in count:
		if hand.size() >= MAX_HAND:
			break
		var card := _draw_random_card()
		if card == null:
			break

		drawn += 1           # นับว่า “จั่วแล้ว” แม้เป็นใบลงโทษ
		if _on_card_drawn(piece, card):
			continue         # ใช้/ทิ้งทันที ไม่ใส่มือ
		hand.append(card)
	hand_by_piece[piece] = hand
	_refresh_hand_ui_for(piece)
	return drawn


func _refresh_hand_ui_for(piece: Sprite2D) -> void:
	# TODO: ผูกกับ UI จริงของคุณ เช่นอัปเดต CardBar/Slots
	# ตัวอย่าง: card_bar.update_for(piece, hand_by_piece[piece])
	pass

func _on_new_round_started() -> void:
	# จั่วให้ทุกคนที่ยังไม่ตาย
	for c in pieces_root.get_children():
		var p := c as Sprite2D
		if p == null: continue
		if _is_piece_alive_node(p):
			draw_card_for_piece(p, 1)
	_notify_right("เริ่มรอบใหม่: แจกการ์ดทุกคน +1 (ลิมิต %d ใบ)" % MAX_HAND)

func _goto_next_turn() -> void:
	# 1) รวบรวมลำดับผู้เล่นที่ยังไม่ตาย
	var order := _get_alive_turn_order()
	if order.is_empty():
		_notify_center("ไม่มีผู้เล่นเหลืออยู่")
		return

	# 2) หา index ของผู้เล่นปัจจุบันจาก active_piece
	var cur_piece := _get_current_player_piece()   # = active_piece เป็น Sprite2D
	var cur_idx := order.find(cur_piece)           # -1 ถ้าหาไม่เจอ (เช่น เพิ่งเริ่มหรือเพิ่งตาย)

	# 3) ไปคนถัดไป
	var next_idx := (cur_idx + 1) % order.size()
	var wrapped := (cur_idx != -1 and next_idx == 0)  # wrap เฉพาะกรณีเลื่อนไปจากคนสุดท้ายจริง ๆ

	active_piece = order[next_idx]

	# 4) อัปเดต UI ที่คุณมี (ถ้าไม่มีเมธอดเหล่านี้ ก็ข้ามได้)
	if has_method("_update_topbar_ui"):
		_update_topbar_ui()
	if has_node("CanvasLayer/SideTurnLabel"):
		$"CanvasLayer/SideTurnLabel".text = "ตอนนี้เป็นเทิร์นของ: %s" % active_piece.name

	# 5) ถ้า wrap แปลว่าครบหนึ่งรอบ → เพิ่มเลขรอบ + แจกการ์ด
	if wrapped:
		current_round += 1
	if has_method("_update_round_label_ui"):
		_update_round_label_ui()
		_on_new_round_started() 

func _get_alive_turn_order() -> Array:
	var order: Array = []
	for name in turn_order_names:
		var p := pieces_root.get_node_or_null(name) as Sprite2D
		if p and _is_piece_alive_node(p):
			order.append(p)
	return order

func _resolve_card_steal_20_per(target_piece_name: String) -> void:
	var attacker := active_piece as Sprite2D
	if attacker == null:
		_notify_center("ไม่พบผู้เล่นที่ใช้การ์ด")
		return
	var victim := pieces_root.get_node_or_null(target_piece_name) as Sprite2D
	if victim == null:
		_notify_center("ไม่พบเป้าหมาย")
		return
	if attacker == victim:
		_notify_center("ห้ามเลือกตัวเอง")
		return

	var got := _steal_percent_respecting_shield(victim, attacker, 0.2)  # 20%
	if got <= 0 and int(shield_by_piece.get(victim, 0)) > 0:
		_notify_center("โล่ของ %s ป้องกันไว้" % victim.name)
	else:
		_notify_center("Cryptoworm Drain! ขโมย %d จาก %s" % [got, victim.name])

	_flash_piece_node(victim)
	_shake_camera_light()
	if int(money_by_piece.get(victim, 0)) <= 0:
		_kill_piece(victim)
	_on_card_resolved()



func play_card_steal_20Per() -> void:
	var user := _get_current_player_piece()
	if user == null:
		return
	var adj := _adjacent_enemies_of(user)
	if adj.is_empty():
		_notify_center("ไม่มีศัตรูระยะประชิด")
		return
	if adj.size() == 1:
		_resolve_card_steal_20_per(adj[0].name)
		return
	_enter_select_mode(CardTargetMode.SELECT_ADJ_STEAL20, adj)
	if card_bar:
		card_bar.visible = false

# ——— Counter Hack state ———
var counter_hack_turns: Dictionary[Sprite2D, int] = {}  # ผู้เล่น -> เทิร์นที่เหลือ

func _has_counter_hack(p: Sprite2D) -> bool:
	return p != null and int(counter_hack_turns.get(p, 0)) > 0

func _give_counter_hack(p: Sprite2D, turns: int = 5) -> void:
	if p == null: return
	counter_hack_turns[p] = max(0, turns)
	_notify_center("Counter Hack เปิดใช้งาน (%d เทิร์น)" % turns)

func _clear_counter_hack(p: Sprite2D) -> void:
	if p == null: return
	counter_hack_turns.erase(p)

func _tick_counter_hack_all() -> void:
	var to_remove: Array = []
	for p in counter_hack_turns.keys():
		var left := int(counter_hack_turns[p]) - 1
		if left <= 0:
			to_remove.append(p)
		else:
			counter_hack_turns[p] = left
	for p in to_remove:
		counter_hack_turns.erase(p)
		if p:
			_notify_center("Counter Hack ของ %s หมดอายุ" % p.name)


func _give_all_def(p: Sprite2D, turns: int) -> void:
	if p == null: return
	all_def_turns[p] = max(1, turns)
	_notify_right("%s เปิด Reflective Surge (%d เทิร์น)" % [p.name, all_def_turns[p]])
	_update_money_ui() # ถ้าคุณแสดงไอคอน/ตัวเลขบนโปรไฟล์ อยากให้เรียกอัปเดตที่นี่

func _has_all_def(p: Sprite2D) -> bool:
	return p != null and int(all_def_turns.get(p, 0)) > 0

func _clear_all_def(p: Sprite2D) -> void:
	if p: all_def_turns.erase(p)

func _decay_all_def_one_round() -> void:
	var to_clear: Array = []
	for p in all_def_turns.keys():
		var left := int(all_def_turns[p]) - 1
		all_def_turns[p] = left
		if left <= 0:
			to_clear.append(p)
	for p in to_clear:
		all_def_turns.erase(p)
		if p:
			_notify_right("%s: Reflective Surge หมดอายุ" % p.name)

# ใช้กับการขโมยเงิน

	# …โค้ดลดโล่/โอนเงินเดิม…

# ถ้ามีดาเมจให้ใช้ฟังก์ชันนี้
func apply_damage_from(attacker: Sprite2D, victim: Sprite2D, dmg: int, bypass_all_def: bool=false) -> void:
	if victim == null or dmg <= 0: return
	if _has_all_def(victim) and not bypass_all_def:
		_notify_center("Reflective Surge ของ %s ป้องกันดาเมจ" % victim.name)
		_clear_all_def(victim)
		_update_money_ui()
		return
	apply_damage(victim, dmg)  # ของเดิม

func _is_frozen(p: Sprite2D) -> bool:
	return int(frozen_turns.get(p, 0)) > 0

func _freeze_player(p: Sprite2D, turns: int = PROCESS_FREEZE_TURNS) -> void:
	if p:
		frozen_turns[p] = max(1, int(turns))

func _clear_freeze(p: Sprite2D) -> void:
	frozen_turns.erase(p)

# ถูกเรียกทุกครั้งที่ "จั่วได้" การ์ดใบหนึ่ง
# คืนค่า true = การ์ดถูกใช้/ทิ้งทันที (อย่าใส่เข้ามือ)
func _on_card_drawn(piece: Sprite2D, card: Variant) -> bool:
	if piece == null or card == null:
		return false
	var info := _card_info(card)
	var eff  := String(info.effect)
	var norm := eff.strip_edges().to_lower().replace("_","").replace("-","")
	var name_key := String(info.name).strip_edges().to_lower().replace(" ","")

	# ---- System Failure: apply & discard immediately ----
	var is_sysfail := (
		name_key.contains("systemfailure")
		or norm.contains("systemfailure")
		or norm == "gones200" or norm == "gone200"
		or norm.begins_with("gones") or norm.begins_with("gones200")
		or norm == "lose200"
	)
	if is_sysfail:
		add_money(piece, -SYSTEM_FAILURE_PENALTY)  # 200
		_notify_center("System Failure! %s เสียเงิน %d" % [piece.name, SYSTEM_FAILURE_PENALTY])
		_flash_piece_node(piece)
		_shake_camera_light()
		return true   # ใช้แล้วทิ้ง ไม่ต้องใส่มือ

	return false
