# res://LanDiscovery.gd
extends Node

const DISCOVERY_PORT := 23232
const MAGIC := "MONEYHUNT_DISCOVERY"

var udp := PacketPeerUDP.new()
var listening := false

func start_host_beacon() -> void:
	if listening: return
	listening = true
	udp = PacketPeerUDP.new()
	udp.bind(DISCOVERY_PORT, "*")
	set_process(true)

func stop_host_beacon() -> void:
	if not listening: return
	listening = false
	udp.close()
	set_process(false)

func _process(_dt):
	if not listening: return
	if udp.get_available_packet_count() > 0:
		var pkt := udp.get_packet().get_string_from_utf8()
		var from := udp.get_packet_ip()
		if pkt == MAGIC:
			# ส่งตอบกลับบอก IP/PORT ให้ client
			var reply := ("%s:%d" % [str(OS.get_environment("COMPUTERNAME")), Net.PORT]).to_utf8_buffer()
			udp.put_packet(reply)  # ส่งกลับไปยังผู้ส่งเดิม

static func find_host(timeout_sec := 1.5) -> String:
	var u := PacketPeerUDP.new()
	u.set_broadcast_enabled(true)
	u.bind(0)
	u.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	u.put_packet(MAGIC.to_utf8_buffer())

	var t := 0.0
	while t < timeout_sec:
		OS.delay_msec(100)
		t += 0.1
		if u.get_available_packet_count() > 0:
			var resp := u.get_packet().get_string_from_utf8()  # "COMPUTERNAME:24142"
			var ip := u.get_packet_ip()
			return ip  # แค่ ip พอ
	return ""  # ไม่พบ
