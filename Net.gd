# res://Net.gd
extends Node

signal lobby_updated(players: Dictionary)   # ยิงทุกครั้งที่รายชื่อเปลี่ยน
signal status_changed(text: String)         # ข้อความสถานะ เช่น "กำลังค้นหา..."
signal connected()
signal connection_failed()
signal disconnected()
signal begin_game(config: Dictionary)       # ส่งก่อนเปลี่ยนฉาก

const PORT := 24142
const MAX_CLIENTS := 3              # จำนวน client ไม่รวม server ⇒ รวมสูงสุด = 4
const PIECES := ["Good", "Call", "Hacker", "Police"]

var peer: ENetMultiplayerPeer
var is_host := false
var players := {}                   # peer_id -> {name:String, piece:String}
var my_id := 0
var my_piece := ""
var game_config := {}               # เก็บ assign เพื่อให้บอร์ดอ่านตอนเริ่ม

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ----------------- Host / Server -----------------
func host_server(host_name: String = "HOST") -> void:
	is_host = true
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	my_id = multiplayer.get_unique_id()
	# ลงทะเบียน host เป็นผู้เล่นคนแรก
	players.clear()
	players[my_id] = { "name": host_name, "piece": "" }
	emit_signal("lobby_updated", players)
	emit_signal("status_changed", "กำลังรอผู้เล่นคนอื่น (1/4)")

func can_start_game() -> bool:
	# ผู้เล่นที่อยู่ในห้อง (รวม host) ต้อง >= 2
	return players.size() >= 2

func server_start_game() -> void:
	if not is_host or not can_start_game():
		return
	# แจกตัวละครตามลำดับเข้าห้อง
	var ids := players.keys()
	ids.sort()  # peer_id ของ host มักเป็น 1
	var assign := {}
	for i in range(PIECES.size()):
		if i < ids.size():
			var pid = ids[i]
			assign[str(pid)] = PIECES[i]  # ใช้ key เป็น String เพื่อข้ามปัญหา serialization
			if pid == my_id:
				my_piece = PIECES[i]
	# เก็บ config
	game_config = { "assign": assign }
	# แจ้งทุกคนให้เริ่มพร้อมกัน
	rpc("rpc_begin_game", game_config)
	emit_signal("begin_game", game_config)   # เผื่อ host ฟังเองด้วย

# ----------------- Client / Join -----------------
func join_server(ip: String, player_name: String) -> void:
	is_host = false
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	emit_signal("status_changed", "กำลังค้นหา...")  # UI โชว์ระหว่าง connect
	my_id = 0
	my_piece = ""
	# เมื่อ connected แล้ว client จะส่งชื่อไปที่ server ใน _on_connected_to_server()

# ----------------- Common / Leave -----------------
func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null
	if peer:
		peer.close()
	peer = null
	is_host = false
	players.clear()
	my_id = 0
	my_piece = ""
	game_config = {}
	emit_signal("disconnected")

# ----------------- Signals -----------------
func _on_peer_connected(id: int) -> void:
	if is_host:
		# รอ client ส่งชื่อเข้ามา (rpc_register_player)
		emit_signal("status_changed", "กำลังรอผู้เล่นคนอื่น (%d/4)" % players.size())

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
		emit_signal("lobby_updated", players)
		emit_signal("status_changed", "กำลังรอผู้เล่นคนอื่น (%d/4)" % players.size())

func _on_connected_to_server() -> void:
	my_id = multiplayer.get_unique_id()
	emit_signal("connected")
	emit_signal("status_changed", "จับคู่สำเร็จแล้ว")
	# ส่งชื่อให้ server ลงทะเบียน
	var myname := OS.get_environment("USERNAME")
	if myname == "":
		myname = "Player"
	rpc_id(1, "rpc_register_player", myname)  # 1 = server

func _on_connection_failed() -> void:
	emit_signal("connection_failed")
	emit_signal("status_changed", "เชื่อมต่อไม่สำเร็จ")

func _on_server_disconnected() -> void:
	leave()

# ----------------- RPCs -----------------
@rpc("any_peer", "reliable")
func rpc_register_player(name: String) -> void:
	# เรียกบน SERVER เสมอ
	if not is_host:
		return
	var remote_id := multiplayer.get_remote_sender_id()
	if players.has(remote_id):
		players[remote_id].name = name
	else:
		players[remote_id] = { "name": name, "piece": "" }
	# ชิงจองชิ้นให้ทุกคน “ชมภาพรวม” ไว้ก่อน (แปะชื่อชิ้นแบบชั่วคราวตามลำดับปัจจุบัน)
	var ids := players.keys()
	ids.sort()
	for i in range(ids.size()):
		var pid = ids[i]
		players[pid].piece = PIECES[i] if i < PIECES.size() else ""
	rpc("rpc_sync_lobby", players)
	emit_signal("lobby_updated", players)
	emit_signal("status_changed", "กำลังรอผู้เล่นคนอื่น (%d/4)" % players.size())

@rpc("authority", "reliable")
func rpc_sync_lobby(new_players: Dictionary) -> void:
	players = new_players.duplicate(true)
	emit_signal("lobby_updated", players)

@rpc("authority", "reliable")
func rpc_begin_game(cfg: Dictionary) -> void:
	game_config = cfg.duplicate(true)
	var assign: Dictionary = game_config.get("assign", {}) as Dictionary
	var myid_s := str(multiplayer.get_unique_id())
	if assign.has(myid_s):
		my_piece = assign[myid_s]
	get_tree().change_scene_to_file("res://board.tscn")

# ----------------- Util API ให้ซีนอื่นเรียก -----------------
func is_networked() -> bool:
	return multiplayer.multiplayer_peer != null

func is_server() -> bool:
	return is_host

func get_my_piece() -> String:
	return my_piece

func get_assign_map() -> Dictionary:
	return game_config.get("assign", {})
