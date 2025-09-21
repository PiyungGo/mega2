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

var is_attack_phase: bool = false
var _attack_targets: Array[Sprite2D] = []


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

# นับเทิร์น (1 เทิร์น = ครบทุกคน 1 รอบ)
var turn_cycles_done: int = 0      # แสดงผลใน UI เป็น x/MAX_TURNS

var is_game_over: bool = false
# เก็บเงินของแต่ละตัวละคร (key = Sprite2D, value = int)
var money_by_piece: Dictionary = {}     # { Sprite2D: int }

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



func _ready() -> void:
<<<<<<< HEAD
	_calc_board_offset()
	_place_four_corners_by_name()     # ← วางมุมก่อน
	_snap_and_fit_existing_pieces()   # ← ฟิตขนาด + สแนปกลางช่อง (ยังคงอยู่)
	_rebuild_nodes_map()
	_setup_money()       
	_setup_owners_by_name()         # ← NEW
	_update_money_ui()
	queue_redraw()
	_update_turn_ui()
	_start_turns()
# เพิ่มด้านบน (โซนตัวแปร)

	money_panel = get_node_or_null("CanvasLayer/MoneyPanel")
	if money_panel == null:
		money_panel = MoneyPanelScene.instantiate()
		money_panel.name = "MoneyPanel"        # ชื่อคงที่
		$CanvasLayer.add_child(money_panel)    # เพิ่มครั้งเดียวเท่านั้น
	if money_panel:
			money_panel.visible = true
			money_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ไม่บังคลิกกระดาน
			
	if attack_bar:
		attack_bar.visible = false
		if attack_btn and not attack_btn.is_connected("pressed", Callable(self, "_on_attack_pressed")):
			attack_btn.pressed.connect(_on_attack_pressed)
		if skip_btn and not skip_btn.is_connected("pressed", Callable(self, "_on_skip_pressed")):
			skip_btn.pressed.connect(_on_skip_pressed)
=======
    _calc_board_offset()
    _place_four_corners_by_name()     # ← วางมุมก่อน
    _snap_and_fit_existing_pieces()   # ← ฟิตขนาด + สแนปกลางช่อง (ยังคงอยู่)
    _rebuild_nodes_map()
    _setup_money()       
    _setup_owners_by_name()         # ← NEW
    _update_money_ui()
    queue_redraw()
    _update_turn_ui()
    _start_turns()
# เพิ่มด้านบน (โซนตัวแปร)ฃ

    _setup_profiles([
            {"name": "Good", "job": "คนดี", "money": 1000, "icon": tex_good},
            {"name": "Call", "job": "คอลเซนเตอร์", "money": 1000, "icon": tex_call},
            {"name": "Hacker", "job": "แฮกเกอร์", "money": 1000, "icon": tex_hack},
            {"name": "Police", "job": "ตำรวจ", "money": 1000, "icon": tex_pol}
        ])
    # -- WinPanel setup --
    # -- WinPanel setup --
    if win_panel == null:
        if WinPanelScene:
            win_panel = WinPanelScene.instantiate()
            win_panel.name = "WinPanel"
            $CanvasLayer.add_child(win_panel)

    if win_panel:
        win_panel.visible = false
        var quit_btn := win_panel.get_node_or_null("QuitButton") as Button
        if quit_btn and not quit_btn.is_connected("pressed", Callable(self, "_on_quit_pressed")):
            quit_btn.pressed.connect(_on_quit_pressed)



    if attack_bar:
        attack_bar.visible = false
        if attack_btn and not attack_btn.is_connected("pressed", Callable(self, "_on_attack_pressed")):
            attack_btn.pressed.connect(_on_attack_pressed)
        if skip_btn and not skip_btn.is_connected("pressed", Callable(self, "_on_skip_pressed")):
            skip_btn.pressed.connect(_on_skip_pressed)
        if settings_btn and not settings_btn.is_connected("pressed", Callable(self, "_on_settings_pressed")):
            settings_btn.pressed.connect(_on_settings_pressed)

        if quit_btn_top and not quit_btn_top.is_connected("pressed", Callable(self, "_on_quit_top_pressed")):
            quit_btn_top.pressed.connect(_on_quit_top_pressed)
        _start_turns()
        _update_round_label()        # แสดง 0/15 ตั้งแต่เริ่ม
        _update_side_turn_label()    # บอกว่าตาใครตอนเริ่ม

    # ---- TopBar wiring ----
        


    if quit_confirm and not quit_confirm.is_connected("confirmed", Callable(self, "_on_quit_confirmed")):
        quit_confirm.confirmed.connect(_on_quit_confirmed)
    _update_topbar_ui()



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
        if money_label: money_label.text = "เงิน: %d" % data.get("money", 0)
        if job_label:   job_label.text = "อาชีพ:\n%s" % data.get("job", "")
        
        profile_cards[data["name"]] = card




# ถ้า pic ยัง null อยู่ ให้ข้ามไปเฉย ๆ (จะไม่เซ็ตอะไร)


func update_money(player_name: String, amount: int):
    if not profile_cards.has(player_name):
        return
    var card = profile_cards[player_name]
    var money_label = card.get_node("Info/MoneyLabel") as Label
    money_label.text = "เงิน: %d" % amount
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677


func _init_money_defaults() -> void:
	var p := $Pieces
	var good  : Sprite2D = p.get_node_or_null("Good")
	var call  : Sprite2D = p.get_node_or_null("Call")
	var hack  : Sprite2D = p.get_node_or_null("Hacker")
	var pol   : Sprite2D = p.get_node_or_null("Police")
	for s in [good, call, hack, pol]:
		if s and not money_by_piece.has(s):
			money_by_piece[s] = hp_start


<<<<<<< HEAD
func _update_turn_label() -> void:
	if turn_label and active_piece:
		turn_label.text = "ตอนนี้เป็นเทิร์นของ: %s" % active_piece.name
=======
func _update_round_label() -> void:
    if round_label:
        var shown: int = clamp(turn_cycles_done + 1, 1, MAX_TURNS)
        round_label.text = "รอบ: %d / %d" % [shown, MAX_TURNS]


func _update_side_turn_label() -> void:
    if side_turn_label and active_piece:
        side_turn_label.text = "ตอนนี้เป็นเทิร์นของ: %s" % active_piece.name

>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677

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

<<<<<<< HEAD
	turn_order = [good, call, hack, police]
	turn_order.shuffle()
	_update_turn_label()
	turn_idx = 0
	active_piece = turn_order[turn_idx]
	current_player = _active_player_index()
	_update_turn_ui()             # เดิมที่ใช้ข้อความ Turn:
	_update_money_ui()  
	# กันพลาด
	if active_piece == null:
		push_error("active_piece is null (turn_order empty?)")
		return
=======
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
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677

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
<<<<<<< HEAD
	# ---------- หน้าต่างทอยเต๋า 'ปิด' อยู่ (โหมดปกติ) ----------
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var gpos: Vector2 = get_global_mouse_position()
		var cell: Vector2i = _pixel_to_cell(gpos)   # ← ประกาศที่นี่ก่อนใช้ทุกที่
=======
    if is_game_over:
        return
    if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
        var gpos: Vector2 = get_global_mouse_position()
        var cell: Vector2i = _pixel_to_cell(gpos)   # ← ประกาศที่นี่ก่อนใช้ทุกที่
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677

		if not _in_bounds(cell):
			return

		# คลิกปลายทางที่ไปได้ → เดิน
		if selected_piece != null and steps_left > 0 and _has_cell(reachable, cell):
			var start_cell: Vector2i = piece_cells.get(selected_piece, selected_cell)
			var path: Array[Vector2i] = _build_path(parent_map, cell)
			if path.is_empty():
				return

<<<<<<< HEAD
			await _move_piece_step_by_step(selected_piece, start_cell, path)
=======
            await _move_piece_step_by_step(selected_piece, start_cell, path)
            var used: int = path.size()
            steps_left = max(steps_left - used, 0)
            _set_roll_label(steps_for_current_piece, steps_left)

>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677

			# sync ตำแหน่งเลือกให้ตรงกับตำแหน่งใหม่ที่เพิ่งเดินถึง
			selected_cell = piece_cells[selected_piece]   # ใช้ข้อมูลจริงจาก map


<<<<<<< HEAD
			# หักแต้มที่ใช้จริง
			var used: int = path.size()
			steps_left = max(steps_left - used, 0)
=======
            #
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677

			if steps_left > 0:
				# ยังมีแต้มเหลือ → เดินต่อจากตำแหน่งปัจจุบัน
				_compute_reachable(selected_cell, steps_left)
				queue_redraw()
				_refresh_attack_bar()
				return
			else:
				# แต้มหมดแล้ว → เข้าสู่เฟสโจมตี/ข้าม
				_start_attack_phase()
				return



		# ไม่ใช่ปลายทาง → ลองเลือกตัวละครช่องนั้น
		_select_piece_at(cell)


		
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
					if active_piece != null:
						add_money(active_piece, -100)
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

var players := ["Good", "Call", "Hacker", "Police"]   # ชื่อตรงกับชื่อ Node ใต้ Pieces
var current_player: int = 0                            # เริ่มคนที่ 0 = Good

					 # Sprite2D -> player_index


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_up") and active_piece != null:
		_give(active_piece, 100)
	elif Input.is_action_just_pressed("ui_down") and active_piece != null:
		_pay(active_piece, 100)


func _give(p: Sprite2D, amount: int) -> void:
	money_by_piece[p] = money_by_piece.get(p, 0) + amount
	_update_money_ui()          # ← เปลี่ยนมาเรียกอันนี้

func _pay(p: Sprite2D, amount: int) -> void:
	money_by_piece[p] = max(0, money_by_piece.get(p, 0) - amount)
	if money_by_piece[p] <= 0:
		_kill_piece(p)
	_update_money_ui()          # ← เปลี่ยนมาเรียกอันนี้

func _start_attack_phase() -> void:
	is_attack_phase = true
	reachable.clear()
	parent_map.clear()
	queue_redraw()

	_attack_targets = _adjacent_enemies_of(active_piece)
	if attack_bar: attack_bar.visible = true
	if attack_btn: attack_btn.disabled = _attack_targets.is_empty()
	if skip_btn:   skip_btn.disabled = false
	_update_skip_btn_text()


func _end_attack_phase() -> void:
	is_attack_phase = false
	_attack_targets.clear()
	if attack_bar:
		attack_bar.visible = false
	_end_turn()    # ส่งเทิร์นต่อ

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

<<<<<<< HEAD
	return res
=======
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
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677


func _refresh_attack_bar():
	if attack_bar == null:
		return

	# หาศัตรูที่อยู่รอบตัว active_piece
	_attack_targets = _adjacent_enemies_of(active_piece)

	if attack_btn:
		attack_btn.disabled = _attack_targets.is_empty()
		_update_skip_btn_text() 

	# คำนวณเงินคืนจากแต้มเหลือ
	var refund: int = max(steps_left, 0) * 12

	if skip_btn:
		if refund > 0:
			skip_btn.text = "ข้าม (+%d)" % refund
		else:
			skip_btn.text = "ข้าม"


func _on_attack_pressed() -> void:
<<<<<<< HEAD
	if _attack_targets.is_empty():
		_end_attack_phase()
		return
	var target: Sprite2D = _attack_targets[0]   # TODO: ทำตัวเลือกเป้าในอนาคต
	add_money(target, -250)                    # หัก 100 (ของคุณจัดการ kill เองอยู่แล้ว)
	_end_attack_phase()
=======
    _hide_roll_label()
    if _attack_targets.is_empty():
        _end_attack_phase()
        return

    var target: Sprite2D = _attack_targets[0]

    # 🔥 เพิ่มอนิเมชัน
    flash_red(target)
    shake(target)

    add_money(target, -900)
    _end_attack_phase()
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677



func _on_skip_pressed() -> void:
<<<<<<< HEAD
	# คิดเงินแลกแต้ม (1 แต้ม = 12)
	var refund: int = max(steps_left, 0) * 12
	if active_piece and refund > 0:
		add_money(active_piece, refund)

	# รีเซ็ตแต้มที่เหลือ
	steps_left = 0

	# ปิดแถบปุ่มแล้วจบเทิร์น
	if is_attack_phase:
		_end_attack_phase()   # ถ้าฟังก์ชันนี้ซ่อนแถบ + _end_turn() อยู่แล้ว ใช้อันนี้เลย
	else:
		if attack_bar:
			attack_bar.visible = false
		_end_turn()
=======
    var refund: int = max(steps_left, 0) * WALK_POINT_RATE
    if active_piece and refund > 0:
        add_money(active_piece, refund)

    steps_left = 0
    _hide_roll_label()   # ← ซ่อนทันทีเมื่อกดข้าม

    if is_attack_phase:
        _end_attack_phase()
    else:
        if attack_bar:
            attack_bar.visible = false
        _end_turn()
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677

        _hide_roll_label()




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
	for n in pieces.get_children():
		if n is Sprite2D:
			money_by_piece[n] = hp_start
	_update_money_ui()
	_setup_money()
func _update_money_ui() -> void:
<<<<<<< HEAD
	if money_panel == null:
		return

	var get_label := func(name: String) -> Label:
			return money_panel.get_node_or_null(name) as Label

	var good  := $Pieces.get_node_or_null("Good")   as Sprite2D
	var call  := $Pieces.get_node_or_null("Call")   as Sprite2D
	var hack  := $Pieces.get_node_or_null("Hacker") as Sprite2D
	var pol   := $Pieces.get_node_or_null("Police") as Sprite2D

	var Lg := money_panel.get_node_or_null("MoneyGood")   as Label
	var Lc := money_panel.get_node_or_null("MoneyCall")   as Label
	var Lh := money_panel.get_node_or_null("MoneyHacker") as Label
	var Lp := money_panel.get_node_or_null("MoneyPolice") as Label

	if Lg and good: Lg.text = "Good : %d"   % money_by_piece.get(good, 0)
	if Lc and call: Lc.text = "Call : %d"   % money_by_piece.get(call, 0)
	if Lh and hack: Lh.text = "Hacker : %d" % money_by_piece.get(hack, 0)
	if Lp and pol:  Lp.text = "Police : %d" % money_by_piece.get(pol, 0)


func add_money(p: Sprite2D, delta: int) -> void:
	if not money_by_piece.has(p):
		money_by_piece[p] = hp_start
	money_by_piece[p] += delta
	if money_by_piece[p] <= 0:
		_kill_piece(p)
	_update_money_ui()

=======
    if player_profiles == null:
        return

    var profile_nodes = player_profiles.get_children()
    for p in profile_nodes:
        var info = p.get_node_or_null("Info")
        if info == null:
            continue  # ข้ามอันที่ไม่ใช่ ProfileCard

        var money_label = info.get_node("MoneyLabel") as Label
        var name_label = info.get_node("NameLabel") as Label

        var piece = $Pieces.get_node_or_null(name_label.text)
        if piece and money_by_piece.has(piece):
            money_label.text = str(money_by_piece[piece])




func add_money(p: Sprite2D, delta: int) -> void:
    if not money_by_piece.has(p):
        money_by_piece[p] = hp_start
    money_by_piece[p] += delta
    if money_by_piece[p] <= 0:
        _kill_piece(p)
    _update_money_ui()
    _check_win_condition()
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677



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
	_update_money_ui()


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

func _setup_money() -> void:
	for n in pieces.get_children():
		if n is Sprite2D and not money_by_piece.has(n):
			money_by_piece[n] = hp_start


func _remove_piece_from_board(piece: Sprite2D) -> void:
	# เอาออกจากตาราง
	if piece_cells.has(piece):
		var c: Vector2i = piece_cells[piece]
		if _in_bounds(c) and c.y < board_nodes.size():
			var row: Array = board_nodes[c.y]
			if c.x < row.size():
				row[c.x] = null
		piece_cells.erase(piece)

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

<<<<<<< HEAD
	# อัปเดตหน้าจอ/ข้อความ
	_update_money_ui()
	if active_piece != null and has_method("_update_turn_label"):
		_update_turn_label()
	queue_redraw()
=======
    # อัปเดตหน้าจอ/ข้อความ
    _update_money_ui()
    if active_piece != null and has_method("_update_turn_label"):
        _update_side_turn_label()
    queue_redraw()
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677



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
	# ยังมีแต้มเหลือและไม่ได้เปิดเต๋า → ห้ามเลือกใหม่ (กันรีเซ็ต)
	if steps_left > 0 and not dice_open:
		return

	var piece := _get_piece_at(cell)
	if piece == null:
		return
	if active_piece == null or piece != active_piece:
		return

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
<<<<<<< HEAD
	steps_for_current_piece = clamp(value, 1, MAX_STEPS)
	steps_left = steps_for_current_piece   # เริ่มต้นแต้มเดิน
	dice_has_result = true
=======
    steps_for_current_piece = clamp(value, 1, MAX_STEPS)
    steps_left = steps_for_current_piece   # เริ่มต้นแต้มเดิน
    dice_has_result = true
    _set_roll_label(steps_for_current_piece, steps_left)
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677


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
<<<<<<< HEAD
	# เคลียร์สถานะเทิร์น
	selected_piece = null
	selected_cell  = Vector2i(-1, -1)
	reachable.clear()
	parent_map.clear()

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
	turn_idx = (turn_idx + 1) % turn_order.size()
	active_piece = turn_order[turn_idx]
	current_player = _active_player_index()

	# อัปเดต UI
	_update_turn_label()
	_update_turn_ui()
	_update_money_ui()
	queue_redraw()
=======
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
        _update_round_label()
        if turn_cycles_done >= MAX_TURNS:
            _end_game_by_turn_limit()
            return

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
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677

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

<<<<<<< HEAD
	steps_left = steps_for_current_piece            # ← ใช้ตัวนี้เป็นตัวจริง
	_compute_reachable(selected_cell, steps_left)   # ← คิดจากจุดปัจจุบันกับแต้มที่เหลือ
	queue_redraw()
	_update_money_ui()
	_update_skip_btn_text()
	_refresh_attack_bar() 
	if dice_ui:
		dice_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
=======
    steps_left = steps_for_current_piece            # ← ใช้ตัวนี้เป็นตัวจริง
    _compute_reachable(selected_cell, steps_left)   # ← คิดจากจุดปัจจุบันกับแต้มที่เหลือ
    queue_redraw()
    _set_roll_label(steps_for_current_piece, steps_left)
    _update_money_ui()
    _update_skip_btn_text()
    _refresh_attack_bar() 
    if dice_ui:
        dice_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
>>>>>>> ad8c5738f9a821db7c154e06cf643ef12368e677

	_show_attack_bar_preview()   # ถ้าคุณทำให้ปุ่มแสดงพร้อมจุด




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



func _show_attack_bar_preview() -> void:
	if attack_bar == null: return
	attack_bar.visible = true
	# ใช้เป้าหมายจากตำแหน่งปัจจุบันก่อนเดิน
	_attack_targets = _adjacent_enemies_of(active_piece)
	if attack_btn:
		attack_btn.disabled = _attack_targets.is_empty()  # มีศัตรูติดอยู่ กดได้เลย
	if skip_btn:
		skip_btn.disabled = false



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
