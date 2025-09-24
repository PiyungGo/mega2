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

<<<<<<< Updated upstream
=======
# ===== BUILDING CONFIG =====
enum Building { BANK, DARKWEB, CYBER_STATION, LAB, DATA_HUB, ARTANIA }

@export var BUILDING_MIN := 6
@export var BUILDING_MAX := 6      # จำนวนสุ่มต่อแผนที่ (ปรับได้)
@export var BUILDING_COOLDOWNS := { # คูลดาวน์เป็น “รอบ” (ครบทุกคน 1 รอบ = -1)
    Building.BANK:            6,
    Building.DARKWEB:         6,
    Building.CYBER_STATION:   5,
    Building.LAB:             4,
    Building.DATA_HUB:        3,
    Building.ARTANIA:         4,
}

# เท็กซ์เจอร์ของอาคาร (กิน 1 tile ทั้งหมด)
@export var tex_bank:           Texture2D     # เซิร์ฟเวอร์ธนาคาร
@export var tex_darkweb:        Texture2D     # ดาร์คเว็บ
@export var tex_cyber_station:  Texture2D     # สถานีไซเบอร์
@export var tex_lab:            Texture2D     # ห้องปฏิบัติการ
@export var tex_data_hub:       Texture2D     # จุดส่งข้อมูล
@export var tex_artania:        Texture2D     # บริษัทอาทาเนีย

# ไว้ใกล้ๆ โซน CONFIG
@export var buildings_root_path: NodePath        # ตั้งค่าใน Inspector ได้
@export var SPAWN_SAFE_RADIUS:int = 1   # 1 = ห้ามติดขอบรอบช่องเกิด (แมนฮัตตัน)


>>>>>>> Stashed changes
# ป๊อปอัปยืนยันออกเกม (ถ้าไม่มีในฉาก ให้เราสร้างเองได้)
@export var quit_confirm_path: NodePath
@onready var quit_confirm := get_node_or_null(quit_confirm_path)   # ควรเป็น ConfirmationDialog
# ===== Slide CardBar Config =====
@export var card_peek_px: int = 24            # โผล่พ้นจอไว้บอกว่ามีการ์ด
@export var card_slide_duration: float = 0.25 # ความเร็วเลื่อน
@export var card_hide_delay: float = 0.25     # หน่วงเวลาตอนเลื่อนลง เพื่อกันกะพริบ
# ===== OBSTACLE CONFIG =====
@export var OBSTACLE_MIN:int = 3
@export var OBSTACLE_MAX:int = 8
@export var OBSTACLE_SEEDS:int = 2                  # จำนวนจุดตั้งต้นของคลัสเตอร์
@export var OBSTACLE_CLUSTER_CHANCE:float = 0.72    # โอกาสขยายแบบจับกลุ่ม (0..1)
@export var obstacle_texture: Texture2D              # ← ลากรูปสิ่งกีดขวางมาใส่ใน Inspector

@onready var obstacles_root: Node2D = $Obstacles

# เก็บ cell ที่เป็นสิ่งกีดขวาง (ใช้เป็น set)
var obstacle_cells := {}   # Dictionary acting as set: key=Vector2i, value=true



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
var prev_player := active_piece
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


# ====== 1) จับคู่ผู้เล่นเข้ากับฝ่าย ======
func _assign_players_to_sides() -> void:
    # host id = 1 เสมอ
    var host_id := 1
    var peers: Array = multiplayer.get_peers()  # รายชื่อ client peer ids
    var sides := ["Good", "Call", "Hacker", "Police"]

    players_peer_map.clear()

    # โฮสต์ถือ Good เป็นค่าเริ่ม (ปรับได้)
    if sides.size() > 0:
        players_peer_map[sides[0]] = host_id

    var idx := 1
    for p in peers:
        if idx >= sides.size():
            break
        players_peer_map[sides[idx]] = int(p)
        idx += 1

    # ฝ่ายที่เหลือไม่มีผู้เล่น → 0
    while idx < sides.size():
        players_peer_map[sides[idx]] = 0
        idx += 1

func _broadcast_alive_set() -> void:
    # ตอนนี้ทำเป็น no-op กัน error ไปก่อน
    pass


func _ready() -> void:
<<<<<<< Updated upstream
	randomize()
	_calc_board_offset()
	_place_four_corners_by_name()
	_snap_and_fit_existing_pieces()
	_rebuild_nodes_map()
	_setup_money()
	_setup_owners_by_name()
	_update_money_ui()
	_update_turn_ui()
	_start_turns()
=======
    add_to_group("BoardRoot")
    _setup_card_bar()
    if texture:
        var tex_size = texture.get_size() * scale
        CELL_SIZE = int(tex_size.x / BOARD_SIZE)
        print("CALIBRATED CELL_SIZE = ", CELL_SIZE)
    randomize()
    _calc_board_geom()
    _calc_board_offset()
    _place_four_corners_by_name()
    _snap_and_fit_existing_pieces()
    _rebuild_nodes_map()
    generate_obstacles()
    if buildings_root == null:
        buildings_root = Node2D.new()
        buildings_root.name = "Buildings"
        add_child(buildings_root)   # ติดไว้ใต้ Board
    # จากนั้นค่อยสุ่มอาคาร
    generate_buildings()
    _setup_money()
    _setup_owners_by_name()
    _update_money_ui()
    _update_turn_ui()
    _start_turns()
    
>>>>>>> Stashed changes

    # ---- โหลด Card DB ให้เรียบร้อยก่อนแจกไพ่ ----
    card_db = load(card_db_path)
    if card_db:
        all_cards = card_db.cards.duplicate()
    else:
        push_warning("card_db is not set; no cards loaded")

<<<<<<< Updated upstream
	# แจกไพ่เริ่มต้น **หลังจาก** โหลดแล้ว
	_deal_initial_hands(5)
=======
    # แจกไพ่เริ่มต้น **หลังจาก** โหลดแล้ว
    # _ready()
    _deal_initial_hands(INITIAL_HAND)

>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
=======
func _apply_network_assignments() -> void:
    # ฆ่าตัวที่ไม่มีคนคุมตั้งแต่เริ่ม
    var assign := Net.get_assign_map()     # peer_id(string) -> piece(String)
    var alive := []
    for k in assign.keys():
        alive.append(assign[k])

    var all := ["Good","Call","Hacker","Police"]
    for p in all:
        if not alive.has(p):
            _kill_piece_immediately(p)     # ← ใช้ฟังก์ชันลัดฆ่าที่คุณมีอยู่ (เช่น _kill_piece)

    # จำกัดสิทธิ์ควบคุม: ไม่ใช่ชิ้นของเรา ⇒ ปิดปุ่มกด/การ์ดทั้งหมดไว้ก่อน
    if MY_PIECE != "":
        _lock_all_controls_except_mine()

func _kill_piece_immediately(piece_name: String) -> void:
    # TODO: เรียกฟังก์ชันฆ่าที่คุณมีอยู่ (อัปเดตเงิน/เอาออกจากบอร์ด/อัปเดต UI)
    # ตัวอย่าง: _remove_piece_from_board(piece_name) หรือ _kill_piece(piece_name)
    pass

func _lock_all_controls_except_mine() -> void:
    # ปิด UI ที่ลูกค้าไม่ควรแตะเมื่อไม่ใช่เทิร์น/ไม่ใช่ตัวเรา
    # ตัวอย่าง (แก้ path ให้ตรงโปรเจกต์):
    # $CanvasLayer/AttackBar.disabled = true
    # $CanvasLayer/DiceUI.hide()
    # และเวลาเป็นเทิร์นของ MY_PIECE ค่อยเปิด (ดูขั้น 5)
    pass

var current_turn_peer_id: int = 1
var _turn_order: Array[int] = []
var _turn_index: int = 0

func _rebuild_turn_order() -> void:
    _turn_order.clear()
    # เรียงตามฝั่ง Good -> Call -> Hacker -> Police
    var sides := ["Good", "Call", "Hacker", "Police"]
    for s in sides:
        var pid: int = players_peer_map.get(s, 0)
        if pid != 0:
            if not _turn_order.has(pid):
                _turn_order.append(pid)
    # กันล่ม ถ้าไม่มีใครเลย ให้ host เล่นไปก่อน
    if _turn_order.is_empty():
        _turn_order = [1]
    _turn_index = 0
    current_turn_peer_id = _turn_order[_turn_index]
    # แจ้งทุกเครื่องให้ sync ตาเริ่มต้น
    rpc("_set_turn_client", current_turn_peer_id)

func _calc_next_turn() -> int:
    if _turn_order.is_empty():
        _rebuild_turn_order()
    _turn_index = (_turn_index + 1) % _turn_order.size()
    return _turn_order[_turn_index]


func _cache_slot_buttons() -> void:
    slot_buttons.clear()
    if slots_container == null:
        return

    # รวบรวมปุ่มจาก Slot1..Slot8 (ปรับจำนวนได้)
    for i in range(1, 9):
        var slot := slots_container.get_node_or_null("Slot%d" % i)
        if slot == null:
            continue
        # รองรับทั้งกรณี Slot เป็นปุ่มเอง หรือมีลูกชื่อ Button
        var btn := slot as Button
        if btn == null:
            btn = slot.get_node_or_null("Button") as Button
        if btn != null:
            slot_buttons.append(btn)

# === ตัวอย่างจุดต่อ RPC ===
@rpc("any_peer","reliable")
func request_roll() -> void:
    if not IS_HOST: return
    var sender := multiplayer.get_remote_sender_id()
    # ตรวจสอบว่า sender คุมชิ้นที่เป็นเทิร์นอยู่จริงไหม
    # ถ้าถูกต้อง ให้รันโค้ดทอยเต๋าเดิมของคุณ แล้ว rpc ผลลัพธ์ให้ทุกเครื่อง
    # rpc("ev_dice_value", value)

@rpc("authority","reliable")
func ev_dice_value(value: int) -> void:
    # ทุกเครื่องอัปเดต UI แสดงค่าทอย
    # ถ้าเครื่องไหนไม่ใช่เทิร์น ก็ยังกดอะไรไม่ได้อยู่ดี
    pass


func _setup_card_bar() -> void:
    _cache_slot_buttons()
    for i in slot_buttons.size():
        var btn: Button = slot_buttons[i]
        var cb := Callable(self, "_on_card_slot_pressed").bind(i)
        # กันการเชื่อมซ้ำแบบ idempotent
        if btn.pressed.is_connected(cb):
            btn.pressed.disconnect(cb)
        btn.pressed.connect(cb)

@onready var grid_origin: Node2D = $GridOrigin  # ถ้าไม่มี node นี้ จะ fallback วิธี B



>>>>>>> Stashed changes
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

# สมมุติว่าคุณมีรายชื่อผู้เล่น 4 ฝ่าย: Good, Call, Hacker, Police
var players_peer_map: Dictionary = {}   # เช่น { "Good": 1, "Call": 2, "Hacker": 3, "Police": 0 }
var owner_by_piece: Dictionary = {}   # { NodePath or piece_name : int peer_id }

func assign_piece_authority() -> void:
    if not multiplayer.is_server():
        return
    owner_by_piece.clear()
    for piece in $Pieces.get_children():
    # เดิม: var peer_id := resolve_owner_peer_for_piece(piece)
        var peer_id := resolve_owner_peer_for_piece(piece.name)
        if peer_id == 0:
            peer_id = 1  # ถ้าไม่มีเจ้าของ ให้เซิร์ฟเวอร์ถือครองไว้ (หรือจะปล่อย 0 ก็ได้)
        piece.set_multiplayer_authority(peer_id)
        owner_by_piece[piece.get_path()] = peer_id

func resolve_owner_peer_for_piece(piece_name: String) -> int:
    # TODO: ใส่กติกาจริงของคุณ เช่น map Good→peer A, Call→peer B …
    # ถ้าไม่รู้ ให้คืน 0 (ไม่มีเจ้าของ)
    return players_peer_map.get(piece_name, 0)



func _on_board_click(piece: Node, target_cell: Vector2i) -> void:
    if not piece.is_multiplayer_authority():
        return
    # แล้วค่อยส่งคำขอไปเซิร์ฟเวอร์ด้วย RPC แบบ server-authoritative
    request_move_rpc(piece.get_instance_id(), target_cell)

# Client → Server
@rpc("any_peer", "reliable")
func request_move_rpc(piece_id: int, target_cell: Vector2i) -> void:
    if not multiplayer.is_server():
        return
    var piece := instance_from_id(piece_id)
    if piece == null:
        return
    # ตรวจสอบว่า peer ผู้ส่งเป็นเจ้าของ
    if not _is_sender_author_of(piece):
        return
    # ตรวจสอบเงื่อนไขเกม: เป็นเทิร์นของเขาไหม, เดินได้ไหม, ช่องว่างไหม ฯลฯ
    if not _validate_move(piece, target_cell):
        return
    # ทำการย้ายจริงบนเซิร์ฟเวอร์
    _apply_move_server(piece, target_cell)
    # Broadcast state ให้ทุกเครื่อง (รวมโฮสต์เอง)
    rpc("_apply_move_client", piece.get_path(), target_cell)

func _is_sender_author_of(piece: Node) -> bool:
    var sender := multiplayer.get_remote_sender_id()
    return piece.get_multiplayer_authority() == sender

# Server → ทุกคน (รวม call_local)
@rpc("authority", "reliable", "call_local")
func _apply_move_client(piece_path: NodePath, target_cell: Vector2i) -> void:
    var piece := get_node(piece_path)
    if piece:
        # เรียกฟังก์ชันเดิมที่ "วาด"/animate การย้าย แต่ห้ามทำเกมลอจิกซ้ำ
        _move_piece_visual_only(piece, target_cell)

func _next_turn_server() -> void:
    if not multiplayer.is_server():
        return
    current_turn_peer_id = _calc_next_turn()
    rpc("_set_turn_client", current_turn_peer_id)


# --- SERVER-SIDE MOVE CHECKS & APPLY ---

func _validate_move(piece: Node, target_cell: Vector2i) -> bool:
    # TODO: ตรงนี้ไว้ตรวจจริง เช่น:
    # 1) เป็นตาของเจ้าของชิ้นนี้หรือไม่
    # 2) ช่อง target อยู่ในกระดานและเดินได้
    # 3) อยู่ในระยะแต้มเดินที่เหลือ ฯลฯ
    # ตอนนี้ให้ผ่านไปก่อนเพื่อทดสอบ flow รวม (กันเกมค้าง)
    return true


func _apply_move_server(piece: Node, target_cell: Vector2i) -> void:
    # TODO: อัปเดต state ฝั่งเซิร์ฟเวอร์จริง ๆ ที่นี่
    # - อัปเดตตำแหน่งกริดของ piece
    # - อัปเดต mapping piece_cells/board_nodes/เงิน/เทิร์น ฯลฯ
    # ตอนนี้ทำแบบมินิมอล ไม่เปลี่ยน state เพื่อให้ flow RPC ทำงานก่อน
    pass

@rpc("authority", "reliable", "call_local")
func _set_turn_client(peer_id: int) -> void:
    current_turn_peer_id = peer_id
    _update_turn_labels_safely()

func can_control_piece(piece: Node) -> bool:
    return piece.is_multiplayer_authority() and multiplayer.get_unique_id() == current_turn_peer_id


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
<<<<<<< Updated upstream
	if p == null: return
	var cur: int = int(shield_by_piece.get(p, 0))
	shield_by_piece[p] = max(0, cur + delta)
	_update_money_ui()
=======
    if p == null: return
    var cur: int = int(shield_by_piece.get(p, 0))
    shield_by_piece[p] = max(0, cur + delta)
    _update_money_ui()
    SFX.play_world("shield_up", pieces)  # piece = Sprite2D/Node2D ของตัวนั้น
>>>>>>> Stashed changes

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

func _start_server_side_rules() -> void:
    if not multiplayer.is_server():
        return
    _assign_players_to_sides()
    assign_piece_authority()
    _kick_unassigned_pieces()
    _broadcast_alive_set()
    _rebuild_turn_order() 
    print("Server-side rules applied")

func _kick_unassigned_pieces() -> void:
    for piece in $Pieces.get_children():
        var owner := piece.get_multiplayer_authority()
        if owner == 1 and not _is_npc_allowed(piece):
            # ไม่มีเจ้าของและไม่ใช่ NPC ที่ตั้งใจให้มี → ลบ/ฆ่า
            _remove_piece_server(piece)

func _is_npc_allowed(piece: Node) -> bool:
    # ถ้าคุณมี NPC จริง ๆ คงต้องมีแท็ก/ชื่อบอกไว้
    return piece.name.begins_with("NPC_")

func _remove_piece_server(piece: Node) -> void:
    var path := piece.get_path()
    piece.queue_free()
    # ให้ทุกคนลบเหมือนกัน
    rpc("_remove_piece_client", path)

@rpc("authority", "reliable", "call_local")
func _remove_piece_client(path: NodePath) -> void:
    var n := get_node_or_null(path)
    if n:
        n.queue_free()



func _start_turns() -> void:
    var p = $Pieces
    # ดึงเฉพาะตัวที่ต้องการจริง ๆ จาก children
    var good  : Sprite2D = p.get_node("Good")
    var call  : Sprite2D = p.get_node("Call")
    var hack  : Sprite2D = p.get_node("Hacker")
    var police: Sprite2D = p.get_node("Police")

<<<<<<< Updated upstream
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
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
	_draw_selection()
	_draw_reachable_dots()
	
	# ไฮไลท์ชิ้นที่เลือก
	if selected_cell != Vector2i(-1, -1):
		var rect := _cell_rect(selected_cell)
		draw_rect(rect, TURN_COLORS[current_player], true)
		draw_rect(rect, Color(0, 0, 0, 0.55), false, 2)
=======
    _draw_selection()
    _draw_reachable_dots()
    _highlight_walkable(reachable)
    
    # ไฮไลท์ชิ้นที่เลือก
    if selected_cell != Vector2i(-1, -1):
        var rect := _cell_rect(selected_cell)
        draw_rect(rect, TURN_COLORS[current_player], true)
        draw_rect(rect, Color(0, 0, 0, 0.55), false, 2)
>>>>>>> Stashed changes

    if piece_cells.has(active_piece):
        selected_cell = piece_cells[active_piece]
    else:
        selected_cell = _pixel_to_cell(active_piece.global_position)

# จุดขาวตำแหน่งที่เดินได้
    # จุดขาวตำแหน่งที่เดินได้
    for c in reachable:
        draw_circle(_cell_center(c), dot_radius, Color(1, 1, 1, 0.9))


    
func _unhandled_input(e: InputEvent) -> void:
<<<<<<< Updated upstream
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
=======
    # --- โหมดวาร์ปจาก Trace Jump ---
    if teleport_pending and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
        # ใน _unhandled_input() บล็อก teleport_pending
        var cell := _pixel_to_cell(get_global_mouse_position())
        if not _in_bounds(cell): return
        if not _is_walkable_cell(cell): return        # << กันวาร์ปลงสิ่งกีดขวาง
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
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
			await _move_piece_step_by_step(selected_piece, start_cell, path)
			var used: int = path.size()
			steps_left = max(steps_left - used, 0)
			_set_roll_label(steps_for_current_piece, steps_left)

=======
            await _move_piece_step_by_step(selected_piece, path)
            var used: int = path.size()
            steps_left = max(steps_left - used, 0)
            _set_roll_label(steps_for_current_piece, steps_left)
            
            var piece_node: Sprite2D = get_node_or_null("Pieces/%s/Sprite" % selected_piece)
            if piece_node:
                SFX.play_world("move_step", piece_node)
>>>>>>> Stashed changes

            # sync ตำแหน่งเลือกให้ตรงกับตำแหน่งใหม่ที่เพิ่งเดินถึง
            selected_cell = piece_cells[selected_piece]   # ใช้ข้อมูลจริงจาก map


            #

<<<<<<< Updated upstream
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
=======
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
>>>>>>> Stashed changes



        # ไม่ใช่ปลายทาง → ลองเลือกตัวละครช่องนั้น
        _select_piece_at(cell)


<<<<<<< Updated upstream
		
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
=======
        
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
>>>>>>> Stashed changes

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

# Board.gd


func start_match_host() -> void:
    if multiplayer.is_server():
        _start_match_local()
        rpc("_start_match_remote")  # กระจายไปทุก client


@rpc("any_peer", "reliable", "call_local")
func _start_match_remote() -> void:
    _start_match_local()


func _start_match_local() -> void:
    # TODO: รีเซ็ต UI, สุ่มลำดับเทิร์น, แจกการ์ด ฯลฯ
    if multiplayer.is_server():
        _start_server_side_rules()


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

<<<<<<< Updated upstream
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
=======
# ========== FX (ไม่ชน tween เดิน) ==========
func flash_red(target: Sprite2D, times: int = 2, one: float = 0.08) -> void:
    if target == null: return
    var tw := create_tween()
    for i in range(times):
        tw.tween_property(target, "self_modulate", Color(1, 0.3, 0.3, 1), one)
        tw.tween_property(target, "self_modulate", Color(1, 1, 1, 1), one)

func shake(target: Node2D, intensity: float = 32.0, duration: float = 0.22, step_time: float = 0.03, damping: float = 0.7) -> void:
    #แรงขึ้น → เพิ่ม intensity (เช่น 20–30)(สั่นถี่) →  ลด step_time (เช่น 0.02)เร็วขึ้น สั้นและดุ → ลด duration (เช่น 0.16–0.22) ฟีลกระแทกกวาดเดียว → ลด damping (เช่น 0.7) ให้แรงตกไว
    if target == null: return
    var tw := create_tween()
    var steps := int(ceil(duration / step_time))

    if target is Sprite2D:
        var s: Sprite2D = target
        var base := s.offset
        for i in range(steps):
            var amp := intensity * pow(damping, i)                 # ลดแรงทีละสเต็ป
            var off := Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
            tw.tween_property(s, "offset", base + off, step_time)
        tw.tween_property(s, "offset", base, 0.06)
    else:
        var basep := target.position
        for i in range(steps):
            var amp2 := intensity * pow(damping, i)
            var off2 := Vector2(randf_range(-amp2, amp2), randf_range(-amp2, amp2))
            tw.tween_property(target, "position", basep + off2, step_time)
        tw.tween_property(target, "position", basep, 0.06)


>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
	if card_bar == null: return
	if active_piece == null: return
=======
    # อย่าไปทำอะไรถ้า card_bar ยังไม่พร้อม
    if card_bar == null or not is_instance_valid(card_bar):
        return

    # ถ้าคุณมี NUM_SLOTS ตายตัว:
    for i in range(NUM_SLOTS):
        var slot := card_bar.get_node_or_null("Slot%d" % i)
        if slot == null:
            continue
        var btn: Button = slot.get_node_or_null("Button")
        if btn == null:
            continue

        var cb := Callable(self, "_on_card_slot_pressed").bind(i)
        if not btn.pressed.is_connected(cb):
            btn.pressed.connect(cb)

    # จากนี้ค่อยไปอัปเดต UI อื่น ๆ
    if active_piece == null:
        return

    # ... ส่วนอัปเดตไอคอน/ข้อความ/enable ของช่องการ์ด ...

>>>>>>> Stashed changes

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

<<<<<<< Updated upstream


func _on_card_slot_pressed(i: int) -> void:
	selected_card_index = i
	_refresh_card_bar_ui()
=======
    for i in range(slot_buttons.size()):
        var btn := slot_buttons[i]
        if btn == null: continue

        # ... โค้ดเดิมล้าง signal / ตั้ง disabled ...

        if i < hand.size():
            var info := _card_info(hand[i])

            btn.disabled = false
            btn.text = "%s\n(%s)" % [info.name, info.effect]  # ข้อความด้านหน้าเหมือนเดิม
            btn.tooltip_text = info.desc
            btn.pressed.connect(_on_card_slot_pressed.bind(i))
            btn.add_theme_color_override("shadow_color", Color(0,0,0,0.7))
            btn.add_theme_constant_override("shadow_offset_x", 1)
            btn.add_theme_constant_override("shadow_offset_y", 1)
            # ตอนสร้าง stylebox ของการ์ด (normal/hover/pressed/disabled)


        if i < hand.size():
            var info := _card_info(hand[i])

            # ✅ ประกาศข้อความที่ต้องการโชว์บนไพ่
            var final_text := "%s\n(%s)" % [info.name, info.effect]
            _apply_card_skin(btn, info)
            _apply_card_box_size(btn)              
            _fit_button_text(btn, final_text)
            

            if selected_card_index == i:
                btn.add_theme_color_override("font_color", Color.WHITE)
            else:
                btn.add_theme_color_override("font_color", Color(0.9,0.9,0.9))
        else:
            btn.disabled = true
            btn.text = "-"
            btn.tooltip_text = ""


func _on_card_slot_pressed(i: int) -> void:
    selected_card_index = i
    SFX.play_ui("card_select")
    _refresh_card_bar_ui()
>>>>>>> Stashed changes

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
    ChatBus.log_event("status", "ผู้เล่น %s ใช้การ์ด \"%s\"", [active_piece.name, info.name])

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

<<<<<<< Updated upstream
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
=======
    # 🔔 เอฟเฟกต์ไม่ชน tween เดิน
    play_hit_fx(p)

    # ------ ลอจิกดาเมจเดิมของคุณ ------
    var shield_cur: int = shield_by_piece.get(p, 0)
    var after_shield: int = max(0, shield_cur - dmg)
    var overflow: int = max(0, dmg - shield_cur)
    shield_by_piece[p] = after_shield
    _update_money_ui()
    if overflow > 0:
        add_money(p, -overflow)
    else:
        _check_win_condition()
>>>>>>> Stashed changes

func _start_card_phase() -> void:
<<<<<<< Updated upstream
	is_card_phase = true
	selected_card_index = -1
	teleport_pending = false
=======
        # ===== ใช้อาคารถ้าพึ่งเดินลงบนมันตานี้ =====
    if active_piece and _pending_building_cell_by_piece.has(active_piece):
        var cell := _pending_building_cell_by_piece[active_piece]
        _pending_building_cell_by_piece.erase(active_piece)
        _trigger_building_if_ready(active_piece, cell)

    is_card_phase = true
    selected_card_index = -1
    teleport_pending = false
>>>>>>> Stashed changes

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
    ChatBus.log_event("system", "%s เลือกข้ามการเดิน (+เงินคืน %d)", [active_piece.name, refund])





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
<<<<<<< Updated upstream
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
=======
    if delta < 0 and p != null:
        SFX.play_world("attack_hit", p)
        _broadcast_hit_fx(p)
        flash_red(p)
        shake(p)
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
>>>>>>> Stashed changes




func _kill_piece(p: Sprite2D) -> void:
<<<<<<< Updated upstream
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
=======
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
>>>>>>> Stashed changes

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
    ChatBus.log_event("system", "%s ทอยได้ %d แต้ม", [active_piece.name, value])

# BFS แบบแมนฮัตตัน
func _compute_reachable(start: Vector2i, steps: int) -> void:
    reachable.clear()
    parent_map.clear()

    var q: Array[Vector2i] = [start]
    var dist := { start: 0 }

    while not q.is_empty():
        var u: Vector2i = q.pop_front()
        if dist[u] == steps: continue

<<<<<<< Updated upstream
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var v: Vector2i = u + d
			if not _in_bounds(v): continue
			if _is_occupied(v) and v != start: continue
			if v in dist: continue
			dist[v] = dist[u] + 1
			parent_map[v] = u
			reachable.append(v)
			q.append(v)
=======
        for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
            var v: Vector2i = u + d
            if not _in_bounds(v): continue
            if not _is_walkable_cell(v) and v != start: continue 
            if v in dist: continue
            dist[v] = dist[u] + 1
            parent_map[v] = u
            reachable.append(v)
            q.append(v)
>>>>>>> Stashed changes



func _build_path(parents: Dictionary, dest: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = []
    var cur: Vector2i = dest
    while parents.has(cur):
        path.push_front(cur)
        cur = parents[cur]
    return path

func _grid_to_world(cell: Vector2i) -> Vector2:
    # ปรับตามระบบบอร์ดของคุณถ้าจุดกำเนิด/ออฟเซ็ตต่างกัน
    return Vector2(
        cell.x * CELL_SIZE + CELL_SIZE * 0.5,
        cell.y * CELL_SIZE + CELL_SIZE * 0.5
    )

func _move_piece_visual_only(piece: Node, target_cell: Vector2i) -> void:
    # TODO: เปลี่ยนเป็นการเดินจริง (เช่นเรียก _move_piece_step_by_step())
    # ตอนนี้ให้ขยับตำแหน่งไปยัง target_cell แบบทันที
    if piece is Node2D:
        var pos := _grid_to_world(target_cell)
        piece.global_position = pos
        
        

# ====================================================================
# MOVE
# ====================================================================
<<<<<<< Updated upstream
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
=======
# เดินตามเส้นทางที่คำนวณไว้ ทีละช่อง
func _move_piece_step_by_step(piece: Sprite2D, path: Array[Vector2i]) -> void:
    if path.is_empty():
        return

    # กัน path ชนสิ่งกีดขวาง (เผื่อกรณีมีจุดใดพลาดการกรองมาก่อน)
    var safe_path: Array[Vector2i] = []
    for c in path:
        if not _is_walkable_cell(c):
            break
        safe_path.append(c)
    if safe_path.is_empty():
        return

    # จุดเริ่มต้น: ใช้ cell ปัจจุบันของหมากจาก piece_cells
    var cur: Vector2i = piece_cells.get(piece, Vector2i(0, 0))
    var orig_start: Vector2i = cur

    is_moving = true
    for step_cell in safe_path:
        var dir: Vector2i = step_cell - cur
        if piece.has_method("set_move_dir"):
            piece.set_move_dir(dir)
        await _tween_move_one_cell(piece, cur, step_cell)  # tween ของคุณเดิม
        cur = step_cell

    # อัปเดตสถานะกระดาน
    if board_nodes.size() > 0:
        board_nodes[orig_start.y][orig_start.x] = null
        board_nodes[cur.y][cur.x] = piece

    piece_cells[piece] = cur
    piece.set_meta("cell", cur)
    if piece.has_method("set_idle"):
        piece.set_idle()
    elif piece.has_method("set_move_dir"):
        piece.set_move_dir(Vector2i.ZERO)  # เผื่อสคริปต์คุณใช้ทิศ 0 = idle
    if building_at.has(cur) and int(building_cd.get(cur, 0)) <= 0:
        _pending_building_cell_by_piece[piece] = cur
    else:
        _pending_building_cell_by_piece.erase(piece)
    is_moving = false
>>>>>>> Stashed changes

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
    if prev_player:
        ChatBus.log_event("system", "จบเทิร์นของ %s", [turn_order[prev_idx].name])
        ChatBus.log_event("system", "เริ่มเทิร์นของ %s", [active_piece.name])


<<<<<<< Updated upstream
	# ถ้า wrap กลับมาที่ index 0 = ครบ 1 รอบ
	if turn_idx == 0:
		turn_cycles_done += 1
		draw_card_for_all()
		_tick_counter_hack_all() 
		_decay_all_def_one_round()    
		_update_round_label()
		if turn_cycles_done >= MAX_TURNS:
			_end_game_by_turn_limit()
			return
=======
    # ถ้า wrap กลับมาที่ index 0 = ครบ 1 รอบ
    if turn_idx == 0:
        turn_cycles_done += 1
        draw_card_for_all()
        _tick_counter_hack_all()
        _decay_all_def_one_round()
        _decay_building_cd_one_round()
        _tick_building_cooldowns() 
        _update_round_label()
        if turn_cycles_done >= MAX_TURNS:
            _end_game_by_turn_limit()
            return
>>>>>>> Stashed changes

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


<<<<<<< Updated upstream
	_update_side_turn_label()
	_update_turn_ui()     # ถ้ายังต้องแสดงที่อื่นอยู่
	_update_money_ui()
	queue_redraw()
	_check_win_condition()
	
=======
    _update_side_turn_label()
    _update_turn_ui()     # ถ้ายังต้องแสดงที่อื่นอยู่
    _update_money_ui()
    queue_redraw()
    _check_win_condition()



>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
func _deal_initial_hands(card_count: int = 5) -> void:
	_ensure_hand_maps()
	if turn_order.is_empty():
		for child in $Pieces.get_children():
			if child is Sprite2D:
				turn_order.append(child as Sprite2D)
=======
func _deal_initial_hands(card_count: int = 8) -> void:
    _ensure_hand_maps()
    if turn_order.is_empty():
        for child in $Pieces.get_children():
            if child is Sprite2D:
                turn_order.append(child as Sprite2D)
>>>>>>> Stashed changes

    for p in turn_order:
        var hand: Array = []
        var raw = hand_by_piece.get(p, [])
        if raw is Array:
            for c in raw:
                hand.append(c)

        for _i in range(card_count):
            # เดิม: var c: Resource = _draw_random_card()
            # ใหม่: ยกเว้น System Failure เฉพาะตอนเริ่มเกม
            var c: Resource = _draw_random_card_excluding_system_failure()
            if c != null:
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
<<<<<<< Updated upstream
	if turn_label:
		turn_label.text = "Turn: %s" % players[current_player]
=======
    if turn_label:
        turn_label.text = "Turn: %s" % players[current_player]

func _update_turn_labels_safely() -> void:
    # ถ้าคุณมีฟังก์ชัน/เลเบลของตัวเองอยู่แล้ว ให้เรียกของเดิมแทน
    if has_node("CanvasLayer/SideTurnLabel"):
        var lbl := $"CanvasLayer/SideTurnLabel"
        if lbl is Label:
            lbl.text = "ตอนนี้เป็นตาของ Peer %d" % current_turn_peer_id
>>>>>>> Stashed changes

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
        ChatBus.log_event("status", "%s กำลังเลือกตำแหน่งวาร์ป", [user.name])
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
        var turns := 5
        _give_counter_hack(user, turns)
        ChatBus.log_event(
            "buff",
            "%s เปิดใช้งาน Counter Hack (อายุ %d เทิร์น)",
            [user.name, int(counter_hack_turns.get(user, 0))]
        )

        return true
    if norm == "alldef" or norm == "reflectivesurge" or norm.begins_with("alldef"):
        var turns := 5
        _give_all_def(user, turns)
        ChatBus.log_event(
            "buff",
            "%s เปิดใช้งาน Reflective Surge (%d เทิร์น)",
            [user.name, turns]  # หรือใช้ int(all_def_turns.get(user, 0)) ก็ได้
        )
        return true
    # == Process Freeze ==
    if norm == "processfreeze" or norm == "pfreeze" or norm.begins_with("freeze"):
        var enemies := _get_alive_enemy_pieces_of_current_player()
        if enemies.is_empty():
            _notify_center("ไม่มีผู้เล่นอื่นให้เลือก")
            return false
        print("[CARD] enter targeting: Process Freeze")
        _enter_select_mode(CardTargetMode.SELECT_PLAYER_FREEZE, enemies)
        ChatBus.log_event("status", "%s กำลังเลือกเป้าหมาย Process Freeze", [user.name])
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
            ChatBus.log_event("buff", "%s ได้รับโล่ +125 (Security Protocol)", [user.name])
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
<<<<<<< Updated upstream
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
=======
    if card_bar == null:
        return
    
    
    
    # คำนวนตำแหน่งเป้าหมาย
    var screen_h := get_viewport_rect().size.y
    var bar_h := card_bar.size.y
    _bar_shown_y = screen_h - bar_h            # โชว์เต็ม
    _bar_hidden_y = screen_h - card_peek_px    # ซ่อน เหลือให้เห็นแค่ขอบบน

    # ตั้งค่าเริ่มต้น (ซ่อนหลบลงไว้ก่อน)
    card_bar.position.y = _bar_hidden_y
    card_bar.visible = false
    # ให้ซ้อนบน UI อื่น
    card_bar.z_index = 1000
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
	# ถ้าจะให้ขยับบนปุ่ม/สล็อตก็รีสตาร์ทด้วย
	_cache_slot_buttons()
	for b in slot_buttons:
		if b and not b.is_connected("mouse_entered", Callable(self, "_keep_bar_open")):
			b.mouse_entered.connect(_keep_bar_open)

	# เริ่มต้นให้หุบ (เห็นแค่ขอบ)
	_slide_card_bar(false)
=======
    # ถ้าจะให้ขยับบนปุ่ม/สล็อตก็รีสตาร์ทด้วย
    _cache_slot_buttons()
    for b in slot_buttons:
        if b and not b.is_connected("mouse_entered", Callable(self, "_keep_bar_open")):
            b.mouse_entered.connect(_keep_bar_open)
    
    for i in range(NUM_SLOTS):
        var slot := card_bar.get_node_or_null("Slot%d" % i)
        if slot == null:
            continue
        var btn: Button = slot.get_node_or_null("Button")
        if btn == null:
            continue

        var cb := Callable(self, "_on_card_slot_pressed").bind(i)
        if not btn.pressed.is_connected(cb):
            btn.pressed.connect(cb)
    # เริ่มต้นให้หุบ (เห็นแค่ขอบ)
    _slide_card_bar(false)
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
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
=======
    if card == null:
        return {"name":"(card)","effect":"","desc":"","type":CardType.MYSTERY}

    if card is CardData:
        var c := card as CardData
        return {
            "name": c.name,
            "effect": c.effect,
            "desc": c.desc,
            "type": int(c.type)   # <<== สำคัญ
        }

    if card is Dictionary:
        return {
            "name":  String(card.get("name","(card)")),
            "effect":String(card.get("effect","")),
            "desc":  String(card.get("desc","")),
            "type":  int(card.get("type", CardType.MYSTERY))
        }

    return {"name":"(card)","effect":"","desc":"","type":CardType.MYSTERY}

>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
# เข้าโหมดเลือกเป้าหมายวาร์ป: ซ่อนแถบการ์ด, โชว์จุดทั่วแมพ
func _begin_teleport_targeting() -> void:
	# ไม่ต้องอยู่ใน CardBar แล้ว ให้คลิกบนบอร์ดได้เลย
	is_card_phase = false
	if card_bar: 
		card_bar.visible = false
=======
func _all_walkable_empty_cells() -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            var c := Vector2i(x, y)
            if _is_walkable_cell(c) and not _is_occupied(c):
                cells.append(c)
    return cells

# เข้าโหมดเลือกเป้าหมายวาร์ป: ซ่อนแถบการ์ด, โชว์จุดทั่วแมพ
func _begin_teleport_targeting() -> void:
    # ไม่ต้องอยู่ใน CardBar แล้ว ให้คลิกบนบอร์ดได้เลย
    is_card_phase = false
    if card_bar:
        card_bar.visible = false
>>>>>>> Stashed changes

    # ให้กรอบไฮไลต์อยู่รอบตัวผู้เล่นตอนนี้ก็ได้ (ไม่บังคับ)
    if piece_cells.has(active_piece):
        selected_cell = piece_cells[active_piece]
    else:
        selected_cell = _pixel_to_cell(active_piece.global_position)

<<<<<<< Updated upstream
	# จุดขาว = ทุก cell ว่าง
	reachable = _all_empty_cells()
	parent_map.clear()  # ไม่ใช้ BFS ในโหมดนี้
	queue_redraw()
=======
    # จุดขาว = ทุก cell ว่าง
    reachable = _all_walkable_empty_cells()
    parent_map.clear()  # ไม่ใช้ BFS ในโหมดนี้
    queue_redraw()
    var node: Sprite2D = get_node_or_null("Pieces/%s/Sprite" % active_piece)
    if node:
        SFX.play_world("warp", node)


>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
	# ✅ ถ้ามี Counter Hack บนเหยื่อ → สะท้อนกลับใส่ผู้โจมตี
	if _has_counter_hack(victim):
		var attacker_money := int(money_by_piece.get(thief, 0))
		var want := int(floor(max(0.0, percent) * float(attacker_money)))
		var got := _steal_from(thief, victim, want)  # เคารพโล่ของผู้โจมตีตามปกติ
		_notify_center("Counter Hack! สะท้อนกลับ %d จาก %s" % [got, thief.name])
		_clear_counter_hack(victim)
		ChatBus.log_event("blocked", "Counter Hack! %s สะท้อนกลับใส่ %s (+%d)",
	[victim.name, thief.name, got])


		return got

	# ปกติ: ขโมยตามเปอร์เซ็นต์ของเหยื่อ
	var victim_money := int(money_by_piece.get(victim, 0))
	var want := int(floor(max(0.0, percent) * float(victim_money)))
	if want <= 0: return 0
	ChatBus.log_event("blocked", "Reflective Surge! %s ป้องกันการโจมตีจาก %s", [victim.name, thief.name])
=======
    # Counter Hack (สะท้อนกลับผู้โจมตี) — อันนี้คุณทำไว้ถูกแล้ว
    if _has_counter_hack(victim):
        var attacker_money := int(money_by_piece.get(thief, 0))
        var want := int(floor(max(0.0, percent) * float(attacker_money)))
        var got := _steal_from(thief, victim, want)  # เคารพโล่ตามปกติ
        _notify_center("Counter Hack! สะท้อนกลับ %d จาก %s" % [got, thief.name])
        _clear_counter_hack(victim)
        ChatBus.log_event("blocked", "Counter Hack! %s สะท้อนกลับใส่ %s (+%d)",
            [victim.name, thief.name, got])
        return got

    # ปกติ: ขโมยตามเปอร์เซ็นต์ของเหยื่อ
    var victim_money := int(money_by_piece.get(victim, 0))
    var want := int(floor(max(0.0, percent) * float(victim_money)))
    if want <= 0: return 0

    # *** อย่า log Reflective Surge ตรงนี้ ***
    # ให้ _steal_from() จัดการเอง (ถ้ามี Reflective Surge จะคืน 0)
>>>>>>> Stashed changes

    return _steal_from(victim, thief, want)



func _spawn_markers_for_pieces(pieces: Array) -> void:
<<<<<<< Updated upstream
	for piece in pieces:
		if not piece is Node2D: 
			continue
		var area := Area2D.new()
		area.input_pickable = true         # สำคัญ
		area.z_index = 10000
		area.set_meta("target_piece_name", piece.name)
=======
    for piece in pieces:
        if not piece is Node2D:
            continue
        var area := Area2D.new()
        area.input_pickable = true         # สำคัญ
        area.z_index = 2000
        area.set_meta("target_piece_name", piece.name)
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
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
=======
        match _card_target_mode:
            CardTargetMode.SELECT_PLAYER_STEAL50:
                _resolve_card_steal_50_per(target_piece_name)
                SFX.play_ui("card_root")
            CardTargetMode.SELECT_ADJ_STEAL20:
                _resolve_card_steal_20_per(target_piece_name)
                
            CardTargetMode.SELECT_PLAYER_FREEZE:
                _resolve_card_freeze(target_piece_name)
                SFX.play_ui("card_freeze")
        _exit_select_mode()
        get_viewport().set_input_as_handled()
        
func _flash_piece_node(p: Sprite2D) -> void:
    if p == null: return

    # ถ้ามี tween เก่าค้างอยู่ ให้ฆ่าทิ้งและรีเซ็ตสี
    if _flash_tw_by_piece.has(p) and _flash_tw_by_piece[p] and _flash_tw_by_piece[p].is_running():
        _flash_tw_by_piece[p].kill()
    p.modulate = Color(1,1,1,1)  # reset ก่อนเริ่มใหม่

    var t := create_tween()
    _flash_tw_by_piece[p] = t
    t.tween_property(p, "modulate", Color(1, 0.5, 0.5, 1), 0.08).set_trans(Tween.TRANS_SINE)
    t.tween_property(p, "modulate", Color(1, 1, 1, 1), 0.16).set_trans(Tween.TRANS_SINE)

    # กันหลุด: จบแล้วลบ mapping และรีเซ็ตสีอีกครั้งเพื่อความชัวร์
    t.finished.connect(func():
        if is_instance_valid(p):
            p.modulate = Color(1,1,1,1)
        if _flash_tw_by_piece.get(p) == t:
            _flash_tw_by_piece.erase(p)
    )

>>>>>>> Stashed changes


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

    # --- log ให้ตรง case + จำนวนอาร์กิวเมนต์พอดี ---
    var cat := ("steal" if got > 0 else "blocked")
    var msg : String
    var args: Array
    if got > 0:
        msg  = "ผู้เล่น %s ปล้นเงิน %s เป็นจำนวน %d หน่วย ด้วยไพ่ \"Root Access Heist\""
        args = [attacker.name, victim.name, got]
    else:
        msg  = "การปล้นของ %s ถูกป้องกันโดย %s"
        args = [attacker.name, victim.name]
    ChatBus.log_event(
        "steal" if got > 0 else "blocked",
        ("ผู้เล่น %s ปล้นเงิน %s เป็นจำนวน %d หน่วย ด้วยไพ่ \"Root Access Heist\"" if got > 0
        else "การปล้นของ %s ถูกป้องกันโดย %s"),
        [attacker.name, victim.name, got] if got > 0 else [attacker.name, victim.name]
)


    # UI แจ้งกลางจอ
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
    ChatBus.log_event("status", "%s ใช้ Process Freeze ใส่ %s — จะหยุดเล่น %d เทิร์น",
        [attacker.name, victim.name, PROCESS_FREEZE_TURNS])


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

<<<<<<< Updated upstream
		drawn += 1           # นับว่า “จั่วแล้ว” แม้เป็นใบลงโทษ
		if _on_card_drawn(piece, card):
			continue         # ใช้/ทิ้งทันที ไม่ใส่มือ
		hand.append(card)
	hand_by_piece[piece] = hand
	_refresh_hand_ui_for(piece)
	ChatBus.log_event("penalty", "ผู้เล่น %s ได้รับการ์ด \"System Failure\" (-200)", [piece.name])
	return drawn
=======
        drawn += 1           # นับว่า “จั่วแล้ว” แม้เป็นใบลงโทษ
        if _on_card_drawn(piece, card):
            continue         # ใช้/ทิ้งทันที ไม่ใส่มือ
        hand.append(card)
    hand_by_piece[piece] = hand
    _refresh_hand_ui_for(piece)
    return drawn
>>>>>>> Stashed changes


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

<<<<<<< Updated upstream
	# 5) ถ้า wrap แปลว่าครบหนึ่งรอบ → เพิ่มเลขรอบ + แจกการ์ด
	if wrapped:
		current_round += 1
	if has_method("_update_round_label_ui"):
		_update_round_label_ui()
		_on_new_round_started() 
=======
    # 5) ถ้า wrap แปลว่าครบหนึ่งรอบ → เพิ่มเลขรอบ + แจกการ์ด
    if wrapped:
        current_round += 1
    if has_method("_update_round_label_ui"):
        _update_round_label_ui()
        _on_new_round_started()
>>>>>>> Stashed changes

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

    var cat := ("steal" if got > 0 else "blocked")
    var msg : String
    var args: Array
    if got > 0:
        msg  = "ผู้เล่น %s ขโมยเงิน %s 20%% (%d) ด้วยไพ่ \"Cryptoworm Drain\""
        args = [attacker.name, victim.name, got]
    else:
        msg  = "การขโมยของ %s ถูกป้องกันโดย %s"
        args = [attacker.name, victim.name]
    ChatBus.log_event(
        "steal" if got > 0 else "blocked",
        ("ผู้เล่น %s ขโมยเงิน %s 20%% (%d) ด้วยไพ่ \"Cryptoworm Drain\"" if got > 0
        else "การขโมยของ %s ถูกป้องกันโดย %s"),
        [attacker.name, victim.name, got] if got > 0 else [attacker.name, victim.name]
)


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
<<<<<<< Updated upstream
	if victim == null or dmg <= 0: return
	if _has_all_def(victim) and not bypass_all_def:
		_notify_center("Reflective Surge ของ %s ป้องกันดาเมจ" % victim.name)
		_clear_all_def(victim)
		_update_money_ui()
		ChatBus.log_event("blocked", "Reflective Surge! %s ป้องกันดาเมจจาก %s",
	[victim.name, attacker.name])

		return
	apply_damage(victim, dmg)  # ของเดิม
=======
    if victim == null or dmg <= 0: return
    if _has_all_def(victim) and not bypass_all_def:
        _notify_center("Reflective Surge ของ %s ป้องกันดาเมจ" % victim.name)
        _clear_all_def(victim)
        _update_money_ui()
        ChatBus.log_event("blocked", "Reflective Surge! %s ป้องกันดาเมจจาก %s",
    [victim.name, attacker.name])
    

        
    apply_damage(victim, dmg)  # ของเดิม
    var shield_cur: int = int(shield_by_piece.get(victim, 0))
    var overflow: int   = int(max(0, dmg - shield_cur))
    if overflow == 0:
        SFX.play_world("block", victim)
    else:
        SFX.play_world("attack_hit", victim)
        return
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
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
=======
    var is_sysfail := (
        name_key.contains("systemfailure")
        or norm.contains("systemfailure")
        or norm == "gones200" or norm == "gone200"
        or norm.begins_with("gones") or norm.begins_with("gones200")
        or norm == "lose200"
    )
    if is_sysfail:
        add_money(piece, -SYSTEM_FAILURE_PENALTY)
        _notify_center("System Failure! %s เสียเงิน %d" % [piece.name, SYSTEM_FAILURE_PENALTY])
        ChatBus.log_event("penalty", "System Failure! %s เสียเงิน %d", [piece.name, SYSTEM_FAILURE_PENALTY])
        _flash_piece_node(piece)
        _shake_camera_light()
        return true   # ← ใช้/ทิ้งทันที เฉพาะกรณีนี้เท่านั้น

    return false      # ← การ์ดปกติ: ไม่ได้ใช้ทันที ให้เข้ามือ
>>>>>>> Stashed changes

	return false

func _norm(s: String) -> String:
    return s.strip_edges().to_lower().replace("_","").replace("-","").replace(" ","")
    
func _is_system_failure(card: Variant) -> bool:
    var info := _card_info(card)
    var eff := String(info.effect)
    var norm := _norm(eff)
    # กันพลาด ถ้าเผื่อใช้ ID ก็เช็คเพิ่มได้
    var cid := ""
    if card is CardData:
        cid = String((card as CardData).id)
    elif card is Dictionary:
        cid = String(card.get("id",""))

    return norm == "gones200" or cid == "system_failure"

func _draw_random_card_excluding_system_failure() -> Resource:
    var db := _get_card_db()
    if db == null: return null

    var pool: Array = []
    var cards_var: Variant = db.get("cards")
    if cards_var is Array:
        for c in (cards_var as Array):
            if _is_system_failure(c):
                continue
            pool.append(c)

    if pool.is_empty():
        return null
    return pool[randi() % pool.size()]

<<<<<<< Updated upstream
func cell_to_pos(cell: Vector2i) -> Vector2:
	# วางกึ่งกลางช่อง (ถ้า sprite คุณอิงมุมซ้ายบน ให้เอา +CELL_SIZE/2 ออก)
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2, cell.y * CELL_SIZE + CELL_SIZE / 2)
=======
# ==== Auto-calibrate board geometry from Sprite2D ====
var _board_px_size: Vector2 = Vector2.ZERO
var _board_top_left: Vector2 = Vector2.ZERO  # local-space

func _calc_board_geom() -> void:
    # ใช้ได้กับ Sprite2D ที่ centered = true (ค่าเริ่มต้นของ Board)
    if texture == null:
        return
    _board_px_size = texture.get_size() * scale      # ขนาดกระดานหลังสเกล (หน่วย: พิกเซล local)
    _board_top_left = -_board_px_size * 0.5          # มุมซ้ายบนใน local space

    # ปรับ CELL_SIZE ให้ตรงกับกระดานจริงอัตโนมัติ (กันคลาด)
    var ideal := _board_px_size.x / float(BOARD_SIZE)
    if abs(float(CELL_SIZE) - ideal) > 1.0:
        CELL_SIZE = int(round(ideal))                 # อัปเดตให้พอดีช่อง

func cell_to_pos(cell: Vector2i) -> Vector2:
    var tl := _board_top_left   # จาก _calc_board_geom()
    return tl + Vector2((cell.x + 0.5) * CELL_SIZE, (cell.y + 0.5) * CELL_SIZE)


>>>>>>> Stashed changes

func in_bounds(c: Vector2i) -> bool:
    return c.x >= 0 and c.y >= 0 and c.x < BOARD_SIZE and c.y < BOARD_SIZE

func generate_obstacles() -> void:
    randomize()
    _clear_obstacles_visual()

<<<<<<< Updated upstream
	var total_target := randi_range(OBSTACLE_MIN, OBSTACLE_MAX)

	# ห้ามเกิดบนช่องเกิดผู้เล่น + ช่องที่มีหมากอยู่
	var forbidden := _collect_forbidden_cells()

	var added := 0
	var tried := 0
	var max_try := 500
=======
    var total_target := randi_range(OBSTACLE_MIN, OBSTACLE_MAX)
    var forbidden := _collect_forbidden_cells()

    # รวม candidate ทุกช่องที่อยู่ในบอร์ดและไม่ต้องห้าม
    var candidates: Array[Vector2i] = []
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            var c := Vector2i(x, y)
            if forbidden.has(c): continue
            candidates.append(c)
>>>>>>> Stashed changes

	# เลือก seed จำนวน OBSTACLE_SEEDS ก่อน
	var seeds: Array[Vector2i] = []

<<<<<<< Updated upstream
	while seeds.size() < OBSTACLE_SEEDS and tried < max_try:
		tried += 1
		var c := Vector2i(randi_range(0, BOARD_SIZE - 1), randi_range(0, BOARD_SIZE - 1))
		if not in_bounds(c): 
			continue
		if forbidden.has(c): 
			continue
		if obstacle_cells.has(c): 
			continue
		obstacle_cells[c] = true
		seeds.append(c)
		added += 1
		_spawn_obstacle_sprite(c)

	# ขยายจากแต่ละ seed แบบคลัสเตอร์
	var frontier: Array[Vector2i] = seeds.duplicate()

	while added < total_target and frontier.size() > 0 and tried < max_try:
		tried += 1
		# หยิบจุดสุ่มจากแนวหน้า
		var base_idx := randi_range(0, frontier.size() - 1)
		var base := frontier[base_idx]

		# เพื่อนบ้าน 4 ทิศ (จะใช้ 8 ทิศก็ได้ถ้าต้องการคลัสเตอร์แน่นขึ้น)
		var neighbors := [
			Vector2i(base.x + 1, base.y),
			Vector2i(base.x - 1, base.y),
			Vector2i(base.x, base.y + 1),
			Vector2i(base.x, base.y - 1)
		]

		# สุ่มเรียงลำดับเล็กน้อย
		neighbors.shuffle()

		var grew := false
		for n in neighbors:
			if added >= total_target:
				break
			if not in_bounds(n): 
				continue
			if forbidden.has(n): 
				continue
			if obstacle_cells.has(n): 
				continue

			# ความน่าจะเป็นในการ “โต” ต่อเนื่อง เพื่อให้จับกลุ่ม
			if randf() <= OBSTACLE_CLUSTER_CHANCE or randf() <= 0.18:
				obstacle_cells[n] = true
				added += 1
				frontier.append(n)
				_spawn_obstacle_sprite(n)
				grew = true

		# ถ้าจุดนี้ไม่โตต่อ ให้ดึงออกจากแนวหน้าเพื่อลดลูปค้าง
		if not grew:
			frontier.remove_at(base_idx)
=======
    var placed: Array[Vector2i] = []
    var tries := 0
    var max_try := 2000

    for c in candidates:
        if placed.size() >= total_target: break
        if tries >= max_try: break
        tries += 1

        # บังคับให้กระจาย: ต้องห่างจากที่วางไว้แล้วอย่างน้อย OBSTACLE_MIN_DIST (Manhattan)
        var ok := true
        if OBSTACLE_MIN_DIST > 0:
            for p in placed:
                var d: int = abs(p.x - c.x) + abs(p.y - c.y)
                if d < OBSTACLE_MIN_DIST:
                    ok = false
                    break
        if not ok: continue

        obstacle_cells[c] = true
        placed.append(c)
        _spawn_obstacle_sprite(c)
    # จบ — ไม่มี seed/frontier แล้ว
>>>>>>> Stashed changes

    # (ออปชัน) ถ้ากังวลว่าจะอุดทางทั้งหมด สามารถทำ connectivity check แล้ว regenerate ใหม่ได้
    # ตัวอย่าง: if not _has_any_path_left(): _reset_and_retry()

<<<<<<< Updated upstream
=======
# ====== รายการชนิดอาคารทั้งหมด (6 ชนิด) ======

func _all_building_types() -> Array[int]:
    return [
        Building.BANK,
        Building.DARKWEB,
        Building.CYBER_STATION,
        Building.LAB,
        Building.DATA_HUB,
        Building.ARTANIA,
    ]

# เลือกเฉพาะช่องว่างที่เดินได้จริง ๆ และยังไม่มีอาคาร
func _empty_walkable_cells_for_building() -> Array[Vector2i]:
    var out: Array[Vector2i] = []
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            var c := Vector2i(x, y)
            if not _is_walkable_cell(c):      # กันสิ่งกีดขวาง
                continue
            if _is_occupied(c):               # กันตัวละครยืนอยู่
                continue
            if building_at.has(c):            # กันอาคารเดิม (กันถูกเรียกซ้ำ)
                continue
            out.append(c)
    return out

# เรียกจาก _ready() หรือหลัง generate_obstacles() เสร็จ
func generate_buildings() -> void:
    if buildings_root == null:
        push_warning("buildings_root is null")
        return

    # 1) ล้างของเก่าเสมอ
    for n in buildings_root.get_children():
        n.queue_free()
    building_at.clear()
    building_cd.clear()
    building_spr.clear()

    # 2) เตรียมชนิดอาคาร (6 ชนิด) และช่องว่าง
    var types: Array = _all_building_types()
    types.shuffle()                               # สุ่มลำดับชนิด
    var cells: Array[Vector2i] = _empty_walkable_cells_for_building()
    cells.shuffle()

    # 3) บังคับจำนวน = 6 (หรือเท่าที่มีช่องพอ)
    var want: int = min(types.size(), cells.size())

    # 4) จับคู่ 1:1 → ไม่ซ้ำชนิด + ไม่ซ้อนตำแหน่ง
    for i in range(want):
        _spawn_building(types[i], cells[i])

    # Debug เช็ค
    print("[BUILD] placed=", building_at.size(),
          " unique types=", types.size(), " want=", want)


>>>>>>> Stashed changes
func _collect_forbidden_cells() -> Dictionary:
    var f := {}

<<<<<<< Updated upstream
	# จุดเกิด 4 มุม (ถ้าคุณใช้ตำแหน่งเกิดอื่น ให้แทนค่าใหม่)
	var spawns := [
		Vector2i(0, 0),
		Vector2i(0, BOARD_SIZE - 1),
		Vector2i(BOARD_SIZE - 1, 0),
		Vector2i(BOARD_SIZE - 1, BOARD_SIZE - 1),
	]
	for s in spawns:
		f[s] = true
=======
    # จุดเกิด 4 มุม (ถ้าคุณใช้ตำแหน่งเกิดอื่น ให้แทนค่าใหม่)
    var spawns := [
        Vector2i(0, 0),
        Vector2i(0, BOARD_SIZE - 1),
        Vector2i(BOARD_SIZE - 1, 0),
        Vector2i(BOARD_SIZE - 1, BOARD_SIZE - 1),
    ]
    for s in spawns:
        _mark_safe_zone(f, s, SPAWN_SAFE_RADIUS)
>>>>>>> Stashed changes

    # ตำแหน่งหมากปัจจุบัน (ถ้าคุณมี map piece_cells อยู่แล้ว ให้ใช้มัน)
    if typeof(pieces_root) != TYPE_NIL:
        for piece in pieces_root.get_children():
            if not piece.has_meta("cell"):
                continue
            var c: Vector2i = piece.get_meta("cell")
            f[c] = true

<<<<<<< Updated upstream
	return f

func _spawn_obstacle_sprite(cell: Vector2i) -> void:
	if obstacle_texture == null:
		return
	var s := Sprite2D.new()
	s.texture = obstacle_texture
	s.centered = true
	s.position = cell_to_pos(cell)
	# ถ้ารูปคุณพอดีช่องอยู่แล้ว ไม่ต้อง scale; ถ้าใหญ่/เล็กเกินไป ปรับที่นี่
	# s.scale = Vector2(CELL_SIZE / obstacle_texture.get_width(), CELL_SIZE / obstacle_texture.get_height())
	# เก็บ cell ไว้ที่ meta เผื่อดีบัก
	s.set_meta("cell", cell)
	obstacles_root.add_child(s)
=======
    return f
    
func _mark_safe_zone(f: Dictionary, center: Vector2i, r: int) -> void:
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            # ใช้ระยะแมนฮัตตัน (จะได้เป็นรูปกากบาท/เพชร)
            if abs(dx) + abs(dy) > r:
                continue
            var c := Vector2i(center.x + dx, center.y + dy)
            if in_bounds(c):
                f[c] = true


func _spawn_obstacle_sprite(cell: Vector2i) -> void:
    var s := Sprite2D.new()
    s.texture = obstacle_texture
    s.centered = true
    s.global_position = _cell_center(cell)
    obstacles_root.add_child(s)
>>>>>>> Stashed changes

func _clear_obstacles_visual() -> void:
<<<<<<< Updated upstream
	for c in obstacles_root.get_children():
		c.queue_free()
	obstacle_cells.clear()
=======
    for c in obstacles_root.get_children():
        c.queue_free()
    obstacle_cells.clear()

func _is_walkable_cell(c: Vector2i) -> bool:
    if not in_bounds(c): return false
    if obstacle_cells.has(c): return false
    # ถ้ามีเช็คว่ามีหมากยืนอยู่ ให้คงไว้ที่นี่
    # if _is_occupied_by_piece(c): return false
    return true


# หาเซลล์ที่เดินถึงได้จาก start ภายในจำนวนก้าว max_steps
# - จะไม่รวม start เองในผลลัพธ์
# - บันทึก parent_map สำหรับสร้าง path ย้อนกลับด้วย _build_path(parent_map, goal)
func compute_reachable_from(start: Vector2i, max_steps: int) -> Array[Vector2i]:
    var reachable: Array[Vector2i] = []
    parent_map.clear()                       # ใช้ตัวแปร global ของคุณ (Dictionary)
    var dist: Dictionary = {}                # key: Vector2i, val: int (ระยะทางจาก start)
    var q: Array[Vector2i] = []

    # เริ่มจากจุดตั้งต้น
    dist[start] = 0
    q.append(start)

    while not q.is_empty():
        var cur: Vector2i = q.pop_front()
        var dcur: int = dist[cur]

        # หมดก้าวแล้วก็ไม่ขยายต่อ
        if dcur >= max_steps:
            continue

        for n in _get_neighbors(cur):        # _get_neighbors() ใช้ _is_walkable_cell() อยู่แล้ว
            if dist.has(n):
                continue
            # จำกัดก้าว
            dist[n] = dcur + 1
            parent_map[n] = cur              # บันทึกพ่อของโหนดเพื่อสร้างเส้นทางทีหลัง
            reachable.append(n)
            q.append(n)

    return reachable


func _get_neighbors(c: Vector2i) -> Array[Vector2i]:
    var out: Array[Vector2i] = []
    var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
    for d in dirs:
        var n: Vector2i = c + d
        if _is_walkable_cell(n):
            out.append(n)
    return out


func is_obstacle_cell(c: Vector2i) -> bool:
    return obstacle_cells.has(c)
    
func _filter_out_obstacles(cells: Array[Vector2i]) -> Array[Vector2i]:
    var out: Array[Vector2i] = []
    for c in cells:
        if not obstacle_cells.has(c):
            out.append(c)
    return out

func _highlight_walkable(cells: Array[Vector2i]) -> void:
    for c in cells:
        if obstacle_cells.has(c):
            continue

func _on_board_clicked(world_pos: Vector2) -> void:
    var target: Vector2i = _cell_from_global(world_pos)
    if obstacle_cells.has(target):
        return  # ไม่ต้องเดิน/ไม่ต้องไฮไลต์ต่อ
    # ... โค้ดตรวจว่าอยู่ใน reachable set แล้วค่อยสั่งเดิน ...

func _show_reachable_cells(selected_cell: Vector2i, steps: int) -> void:
    var reachable: Array[Vector2i] = compute_reachable_from(selected_cell, steps)
    reachable = _filter_out_obstacles(reachable)   # ✅ ทำตรงนี้
    _highlight_walkable(reachable)                 # ฟังก์ชันวาดจุดเดิมของคุณ

func _cell_from_global(world_pos: Vector2) -> Vector2i:
    # หา offset มุมซ้ายบนของกระดาน
    var tl := _board_top_left   # ถ้าคุณใช้ฟังก์ชัน _calc_board_geom() อยู่แล้ว
    # คำนวณตำแหน่งในกริด
    var local := world_pos - global_position - tl
    var cx := int(floor(local.x / CELL_SIZE))
    var cy := int(floor(local.y / CELL_SIZE))
    return Vector2i(cx, cy)

func _card_bg_for_type(t: int) -> Texture2D:
    match t:
        CardType.ATTACK:  return card_bg_attack
        CardType.DEFENSE: return card_bg_defense
        CardType.MYSTERY: return card_bg_mystery
        _:                return card_bg_mystery

func _stylebox_from_tex(tex: Texture2D) -> StyleBoxTexture:
    var sb := StyleBoxTexture.new()
    sb.texture = tex
    # ถ้ารูปเป็น 9-patch ให้ตั้ง margin ต่อไปนี้ได้
    sb.content_margin_left   = 8
    sb.content_margin_right  = 8
    sb.content_margin_top    = 6
    sb.content_margin_bottom = 6
    return sb

func _apply_card_skin(btn: Button, info: Dictionary) -> void:
    var tex := _card_bg_for_type(int(info.get("type", CardType.MYSTERY)))
    if tex:
        var sb := _stylebox_from_tex(tex)
        # ใช้สไตล์เดียวกันในทุก state เพื่อให้ภาพคงที่
        btn.add_theme_stylebox_override("normal",  sb)
        btn.add_theme_stylebox_override("hover",   sb)
        btn.add_theme_stylebox_override("pressed", sb)
        btn.add_theme_stylebox_override("disabled", sb)

    # อ่านง่ายบนพื้นหลัง: ทำตัวหนังสือขาว + มีเส้นขอบดำ
    btn.add_theme_color_override("font_color", Color(1,1,1,1))
    btn.add_theme_color_override("font_hover_color", Color(1,1,1,1))
    btn.add_theme_color_override("font_pressed_color", Color(1,1,1,1))
    btn.add_theme_color_override("font_focus_color", Color(1,1,1,1))
    btn.add_theme_color_override("font_outline_color", Color(0,0,0,0.85))
    btn.add_theme_constant_override("outline_size", 2)

    # จัดกลาง + ระยะขอบในปุ่ม
    btn.add_theme_constant_override("h_alignment", HORIZONTAL_ALIGNMENT_CENTER)
    btn.add_theme_constant_override("v_alignment", VERTICAL_ALIGNMENT_CENTER)

# ===== CONFIG บนสุดของ board.gd =====
@export var CARD_SIZE := Vector2i(140, 260)   # กำหนดเองได้
@export var CARD_TEXT_PADDING := Vector2(16, 16)

# เรียกใน _refresh_card_bar_ui() ตอนวน set ปุ่มแต่ละช่อง
func _tex_for_card(info: Dictionary) -> Texture2D:
    var t := int(info.get("type", CardType.ATTACK))
    match t:
        CardType.ATTACK:  return card_tex_attack
        CardType.DEFENSE: return card_tex_defense
        CardType.MYSTERY: return card_tex_mystery
        _:                return card_tex_attack

func _apply_card_box_size(btn: Button) -> void:
    btn.custom_minimum_size = CARD_SIZE
    btn.size = CARD_SIZE
    btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    btn.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

func _fit_button_text(btn: Button, text: String) -> void:
    var font := btn.get_theme_font("font")
    if font == null: font = ThemeDB.fallback_font

    var avail := btn.size - CARD_TEXT_PADDING * 2.0
    var size := 16
    while size > 10:
        var m := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, avail.x, size)
        if m.x <= avail.x and m.y <= avail.y:
            break
        size -= 1
    btn.add_theme_font_size_override("font_size", size)
    btn.text = text

    # กันล้น (ถ้ายังล้นจริง ๆ)
    btn.clip_text = true
    btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

# ===== Board.gd (โซน CONFIG) =====
@export var card_tex_attack: Texture2D
@export var card_tex_defense: Texture2D
@export var card_tex_mystery: Texture2D


@onready var buildings_root: Node2D = $Buildings    # ทำ Node2D ชื่อ Buildings ใต้ Board ไว้ก่อน

var building_at: Dictionary = {}        # Vector2i -> int (Building enum)
var building_cd: Dictionary = {}        # Vector2i -> int (รอบที่เหลือ)
var building_spr: Dictionary = {}       # Vector2i -> Sprite2D

# ไว้จำว่า “ตานี้” ผู้เล่นเพิ่งเดิน “ลงบน” อาคารไหน (จะกดตอนเข้า Card Phase)
var _pending_building_cell_by_piece: Dictionary[Sprite2D, Vector2i] = {}

func _tex_for_building(t: int) -> Texture2D:
    match t:
        Building.BANK:           return tex_bank
        Building.DARKWEB:        return tex_darkweb
        Building.CYBER_STATION:  return tex_cyber_station
        Building.LAB:            return tex_lab
        Building.DATA_HUB:       return tex_data_hub
        Building.ARTANIA:        return tex_artania
        _:                       return tex_bank

func _update_building_visual(cell: Vector2i) -> void:
    var spr := building_spr.get(cell) as Sprite2D
    if spr == null: return
    var cd := _get_building_cd(cell)
    var m: Color = spr.modulate
    if cd > 0:
        m.a = 0.40   # อาคารติดคูลดาวน์ → จางลง
    else:
        m.a = 1.0    # อาคารพร้อมใช้งาน → ชัดเต็ม
    spr.modulate = m



func _trigger_building_if_ready(p: Sprite2D, cell: Vector2i) -> void:
    if p == null: return
    if not building_at.has(cell): return
    if int(building_cd.get(cell, 0)) > 0: return

    var t := int(building_at[cell])
    var cd := int(BUILDING_COOLDOWNS.get(t, 0))

    # ให้ผลลัพธ์ตามชนิด
    match t:
        Building.BANK:
            add_money(p, +300)
            _notify_center("%s ได้รับ +300 จากเซิร์ฟเวอร์ธนาคาร" % p.name)
            ChatBus.log_event("bonus", "%s รับเงิน +300 จาก Bank", [p.name])

        Building.DARKWEB:
            _give_darkweb_cards(p, 0)    # ✅ จั่วเฉพาะ p ผู้ที่เหยียบ
            _set_building_cd(cell, 6)
            _notify_center("%s ได้รับไพ่เพิ่ม +2 จากดาร์คเว็บ" % p.name)
            ChatBus.log_event("bonus", "%s จั่วเพิ่ม +2 (Dark Web)", [p.name])

        Building.CYBER_STATION:
            add_shield(p, 200)
            SFX.play_world("shield_up", pieces)
            _notify_center("%s ได้โล่ +200 จากสถานีไซเบอร์" % p.name)
            ChatBus.log_event("buff", "%s โล่ +200 (Cyber Station)", [p.name])

        Building.LAB:
            _give_specific_card(p, "root_access_heist", "Root Access Heist")
            _notify_center("%s ได้ไพ่ Root Access Heist +1 (ห้องปฏิบัติการ)" % p.name)
            ChatBus.log_event("bonus", "%s ได้การ์ด RAH +1 (Lab)", [p.name])

        Building.DATA_HUB:
            add_money(p, +150)
            _notify_center("%s ได้รับ +150 จากจุดส่งข้อมูล" % p.name)
            ChatBus.log_event("bonus", "%s รับเงิน +150 (Data Hub)", [p.name])

        Building.ARTANIA:
            add_money(p, +200)
            add_shield(p, 50)
            _notify_center("%s ได้ +200 เงิน และ +50 โล่ (บริษัทอาทาเนีย)" % p.name)
            ChatBus.log_event("bonus", "%s +200 เงิน +50 โล่ (Artania)", [p.name])

    # เข้าสู่คูลดาวน์
    building_cd[cell] = cd
    _update_building_visual(cell)
    _update_money_ui()
    if card_bar and active_piece == p:
        _refresh_card_bar_ui()

func _give_specific_card(p: Sprite2D, id_key: String, name_fallback: String) -> void:
    if p == null: return
    _ensure_hand_slot(p)

    if hand_by_piece[p].size() >= MAX_HAND:
        _notify_center("มือเต็ม (ไม่ได้รับการ์ดเพิ่ม)")
        return

    var c: Resource = null
    if card_db:
        # หาจาก id ก่อน (ถ้าการ์ดคุณมี field id)
        for r in card_db.cards:
            if r is CardData and String(r.id).strip_edges().to_lower() == id_key:
                c = r; break
        # ถ้าไม่เจอ id ลองด้วยชื่อ
        if c == null:
            var key := name_fallback.strip_edges().to_lower()
            for r in card_db.cards:
                if r is CardData and String(r.name).strip_edges().to_lower() == key:
                    c = r; break
    if c == null:
        # fallback: ดึงการ์ดแบบ dictionary (ถ้าไม่มีใน DB จริง ๆ)
        c = CardData.new()
        c.name = name_fallback
        c.effect = "steal_50"   # ให้พฤติกรรมใกล้เคียง RAH
        c.desc = "จากอาคาร"

    hand_by_piece[p].append(c)

func _tick_building_cooldowns() -> void:
    for cell in building_cd.keys():
        var v := int(building_cd[cell])
        if v > 0:
            building_cd[cell] = v - 1
            if building_cd[cell] <= 0:
                building_cd[cell] = 0
                _update_building_visual(cell)
                # แจ้งเบา ๆ ว่ากลับมาใช้ได้ (ถ้าชอบ)
                # _notify_right("อาคารพร้อมใช้งานอีกครั้งที่ %s" % str(cell))
func generate_buildings_fair(want: int) -> void:
    if buildings_root == null: return

    for c in buildings_root.get_children():
        c.queue_free()
    building_at.clear()
    building_cd.clear()
    building_spr.clear()

    var candidates : Array[Vector2i] = _all_walkable_empty_cells()
    candidates = candidates.filter(func(c): return not building_at.has(c))
    candidates.shuffle()

    var base_types := [
        Building.BANK,
        Building.DARKWEB,
        Building.CYBER_STATION,
        Building.LAB,
        Building.DATA_HUB,
        Building.ARTANIA,
    ]

    var bag : Array = []
    var placed := 0
    var idx := 0

    while placed < want and idx < candidates.size():
        if bag.is_empty():
            bag = base_types.duplicate()
            bag.shuffle()
        var t = bag.pop_back()
        var cell := candidates[idx]
        _spawn_building(t, cell)
        placed += 1
        idx += 1

func _spawn_building(t: int, cell: Vector2i) -> void:
    # กันซ้อน cell (เผื่อถูกเรียกซ้ำ)
    if building_at.has(cell):
        return

    var spr := Sprite2D.new()
    spr.texture = _tex_for_building(t)  # เขียนฟังก์ชัน map ชนิด -> texture แล้ว
    spr.centered = true
    spr.global_position = _cell_center(cell)
    buildings_root.add_child(spr)

    building_at[cell] = t
    building_cd[cell] = 0
    building_spr[cell] = spr


func generate_buildings_unique_once() -> void:
    if buildings_root == null:
        return

    # เคลียร์ของเก่า
    for c in buildings_root.get_children():
        c.queue_free()
    building_at.clear()
    building_cd.clear()
    building_spr.clear()

    # ชนิดอาคารครบชุด (อย่างละ 1)
    var types := [
        Building.BANK,
        Building.DARKWEB,
        Building.CYBER_STATION,
        Building.LAB,
        Building.DATA_HUB,
        Building.ARTANIA,
    ]
    types.shuffle()

    # หาเซลล์ว่าง/เดินได้ ไม่ชนสิ่งกีดขวาง/ตัวละคร/อาคารเดิม
    var candidates : Array[Vector2i] = _all_walkable_empty_cells()
    # ตัดเซลล์ที่มีอาคารอยู่แล้ว (กันพลาด)
    candidates = candidates.filter(func(c): return not building_at.has(c))
    candidates.shuffle()

    if candidates.size() < types.size():
        push_warning("มีเซลล์ว่างไม่พอสำหรับอาคารทั้งหมด")
        return

    # จับคู่ 1:1 → ไม่มีซ้ำชนิดและไม่ซ้อนตำแหน่ง
    for i in types.size():
        var cell := candidates[i]
        _spawn_building(types[i], cell)

# แนะนำวางใกล้ ๆ ฟังก์ชันไพ่ (แถว ๆ draw_card_for_piece)
func _give_darkweb_cards(p: Sprite2D, count: int) -> void:
    if p == null: return
    _ensure_hand_slot(p)

    var hand: Array = hand_by_piece.get(p, [])
    var target: int = min(count, MAX_HAND - hand.size())
    if target <= 0:
        return

    var drawn := 0
    var safety := 30                      # กันลูปค้าง

    while drawn < target and safety > 0:
        safety -= 1

        # ใช้อันที่ “ไม่น่าจะได้ null” ถ้ามี
        var card: Resource = _draw_random_card_excluding_system_failure()
        if card == null:
            continue                      # ข้ามของเสีย

        # ถ้าเป็น on-draw (เช่น System Failure) แล้วถูกใช้ทันที ให้ข้ามไม่ใส่มือ
        if _on_card_drawn(p, card):
            continue

        # ✅ ปลอดภัยก่อน push: ต้องเป็น CardData หรือ Dictionary ที่มีชื่อ
        if not (card is CardData):

            continue

        hand.append(card)
        drawn += 1
    hand_by_piece[p] = hand

    # อัปเดต UI เฉพาะถ้าเป็นผู้เล่นที่กำลังแสดงมืออยู่
    if p == active_piece:
        _refresh_card_bar_ui()

func _sanitize_hand(p: Sprite2D) -> void:
    if p == null: return
    var hand: Array = hand_by_piece.get(p, [])
    var clean: Array = []
    for c in hand:
        if c is CardData:
            clean.append(c)
        elif c is Dictionary and c.has("name"):
            clean.append(c)
    hand_by_piece[p] = clean


func _set_building_cd(cell: Vector2i, turns: int) -> void:
    building_cd[cell] = max(0, turns)
    _update_building_visual(cell)   # ทำให้ไอคอนจาง/กลับมาปกติ

func _get_building_cd(cell: Vector2i) -> int:
    return int(building_cd.get(cell, 0))

func _decay_building_cd_one_round() -> void:
    var to_update: Array[Vector2i] = []
    for c in building_cd.keys():
        var left := int(building_cd[c]) - 1
        if left <= 0:
            building_cd.erase(c)
        else:
            building_cd[c] = left
        to_update.append(c)
    for c in to_update:
        _update_building_visual(c)

# --- FX: แวบแดง ---
func _flash_red(target: CanvasItem, times: int = 2, one: float = 0.06) -> void:
    var t := create_tween()
    for i in range(times):
        t.tween_property(target, "self_modulate", Color(1, 0.4, 0.4, 1), one)
        t.tween_property(target, "self_modulate", Color(1, 1, 1, 1), one)

# --- FX: เขย่า (ปลอดภัยกับการเดิน) ---
func _shake_any(target: Node, amplitude: float = 8.0, duration: float = 0.25, vibrato: int = 12) -> void:
    var step_time: float = duration / float(max(1, vibrato))
    var amp: float = amplitude

    if target is Sprite2D:
        var s: Sprite2D = target
        var base_off := s.offset
        var tw := create_tween()
        for i in range(vibrato):
            var dir := Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized()
            tw.tween_property(s, "offset", base_off + dir * amp, step_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            amp *= 0.85
        tw.tween_property(s, "offset", base_off, 0.06)
    elif target is Node2D:
        var n: Node2D = target
        var base_pos := n.position
        var tw2 := create_tween()
        for i in range(vibrato):
            var dir2 := Vector2(randf()*2-1, randf()*2-1).normalized()
            tw2.tween_property(n, "position", base_pos + dir2 * amp, step_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            amp *= 0.85
        tw2.tween_property(n, "position", base_pos, 0.06)

# --- เรียก FX ตอนโดนโจมตี แล้วค่อยคำนวณดาเมจ ---


    # ====== ด้านล่างแทนที่ด้วยลอจิกเดิมของคุณ ======
    # ตัวอย่าง: หักเกราะก่อน แล้วค่อยหักเงิน
# ========= HIT FX (ไม่ชนกับการ Tween เดิน) =========

# สั่นด้วยการแกว่ง 'rotation' + 'scale' (ไม่ยุ่งกับ position)
func _hit_shake_rot_scale(target: Node2D, duration: float = 0.22, rot_amp_deg: float = 7.0, scale_amp: float = 0.05, vibrato: int = 10) -> void:
    if target == null: return
    var base_rot: float = target.rotation_degrees
    var base_scale: Vector2 = target.scale
    var tw: Tween = create_tween()
    var step: float = duration / float(max(1, vibrato))
    var amp_rot: float = rot_amp_deg
    var amp_s: float = scale_amp
    for i in range(vibrato):
        var sign: float = 1.0 if (i % 2) == 0 else -1.0
        tw.tween_property(target, "rotation_degrees", base_rot + sign * amp_rot, step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(target, "scale", base_scale * (1.0 + sign * amp_s), step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        amp_rot *= 0.85
        amp_s   *= 0.85
    # รีเซ็ตคืนค่าเดิม
    tw.tween_property(target, "rotation_degrees", base_rot, 0.06)
    tw.tween_property(target, "scale", base_scale, 0.06)

# สร้าง/คืน ShaderMaterial สำหรับแวบแดง (ใช้ซ้ำได้)
var _hit_flash_shader: Shader = null
# -- แทนที่ฟังก์ชัน ensure material เดิม --
func _ensure_flash_material(spr: Sprite2D) -> ShaderMaterial:
    if spr == null: 
        return null
    var sh := _get_hit_flash_shader()
    var mat := spr.material as ShaderMaterial
    if mat == null or mat.shader != sh:
        mat = ShaderMaterial.new()
        mat.shader = sh
        spr.material = mat
    return mat


# ทำแวบแดงสั้น ๆ ด้วย shader (ไม่ชน modulate ภายนอก)
func _hit_flash_red(spr: Sprite2D, times: int = 2, one: float = 0.06) -> void:
    var mat := _ensure_flash_material(spr)
    if mat == null: return
    var tw: Tween = create_tween()
    for i in range(times):
        tw.tween_property(mat, "shader_parameter/flash", 1.0, one)
        tw.tween_property(mat, "shader_parameter/flash", 0.0, one)

# สะดวกไว้เรียกที่เดียว
func play_hit_fx(piece: Sprite2D) -> void:
    _hit_flash_red(piece)
    _hit_shake_rot_scale(piece)

func _get_hit_flash_shader() -> Shader:
    if _hit_flash_shader != null:
        return _hit_flash_shader
    # พยายามโหลดจากไฟล์ (ถ้ามี)
    if ResourceLoader.exists(HIT_FLASH_SHADER_PATH):
        var res := load(HIT_FLASH_SHADER_PATH)
        if res is Shader:
            _hit_flash_shader = res
            return _hit_flash_shader
    # ไม่เจอไฟล์ → สร้าง shader ในหน่วยความจำ
    var sh := Shader.new()
    sh.code = """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0, 0.3, 0.3, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec4 base = texture(TEXTURE, UV) * COLOR;
    vec4 fcol = vec4(flash_color.rgb, base.a);
    COLOR = mix(base, fcol, clamp(flash, 0.0, 1.0));
}
"""
    _hit_flash_shader = sh
    return _hit_flash_shader


func _play_hit_fx_local(victim: Sprite2D) -> void:
    if victim == null: return
    flash_red(victim)
    shake(victim)

@rpc("authority", "unreliable")
func ev_hit_fx_path(path_str: String) -> void:
    var node := get_node_or_null(path_str)
    if node is Sprite2D:
        _play_hit_fx_local(node)


func _broadcast_hit_fx(victim: Sprite2D) -> void:
    if victim == null: return
    # เล่นที่เครื่องนี้ก่อน
    _play_hit_fx_local(victim)
    # กระจายไปทุกเครื่อง (เฉพาะโฮสต์)
    if Net != null and Net.is_networked() and Net.is_server():
        var p: NodePath = victim.get_path()
        rpc("ev_hit_fx_path", String(p))


func _on_settings_btn_pressed() -> void:
    pass # Replace with function body.
>>>>>>> Stashed changes
