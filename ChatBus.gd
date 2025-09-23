# ChatBus.gd
extends Node

signal chat(from: String, text: String)   # ข้อความผู้เล่นพิมพ์
signal event(cat: String, text: String)   # เหตุการณ์ในเกม (บอท/ระบบ)

func send_chat(from: String, text: String) -> void:
	text = text.strip_edges()
	if text == "": return
	emit_signal("chat", from, text)

func log_event(cat: String, fmt: String, args: Array = []) -> void:
	# ใช้ format แบบ "ข้อความ %s %d" แล้วส่ง args ตามลำดับ
	var msg := fmt % args if not args.is_empty() else fmt
	emit_signal("event", cat, msg)
