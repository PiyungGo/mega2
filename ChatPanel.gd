extends Control

@onready var log      : RichTextLabel = $"VBoxContainer/LogScroll/Log"
@onready var input    : LineEdit      = $"VBoxContainer/Input/ChatInput"
@onready var send_btn : Button        = $"VBoxContainer/Input/SendBtn"         # ถ้า SendBtn อยู่ใต้ Input ให้เปลี่ยนเป็น $"Input/SendBtn"

func _ready() -> void:
	if log:
		log.bbcode_enabled = true

	if send_btn and not send_btn.is_connected("pressed", Callable(self, "_on_send")):
		send_btn.pressed.connect(_on_send)

	if input and not input.is_connected("text_submitted", Callable(self, "_on_submit")):
		input.text_submitted.connect(_on_submit)

	# ฟังเหตุการณ์จากบัส
	ChatBus.chat.connect(_on_chat)
	ChatBus.event.connect(_on_event)

func _on_send() -> void:
	_on_submit(input.text)

func _on_submit(t: String) -> void:
	var msg := t.strip_edges()
	if msg == "": return
	ChatBus.chat.emit(msg)   # กระจายข้อความแชท
	input.text = ""

func _on_chat(text: String) -> void:
	_append("[color=white]• [/color]" + text)

func _on_event(kind: String, text: String, args := []) -> void:
	# ✅ GDScript ใช้รูปแบบ  a if cond else b  (ไม่ใช่ ? :)
	var line := (text % args) if args.size() > 0 else text
	match kind:
		"status":  _append("[color=#dddddd]" + line + "[/color]")
		"buff":    _append("[color=orange]"  + line + "[/color]")
		"blocked": _append("[color=cyan]"    + line + "[/color]")
		"steal":   _append("[color=yellow]"  + line + "[/color]")
		"penalty": _append("[color=salmon]"  + line + "[/color]")
		"system":  _append("[color=#cccccc]" + line + "[/color]")
		_:         _append(line)

func _append(text: String) -> void:
	if log == null: return
	log.append_text(text + "\n")
	log.scroll_to_line(log.get_line_count() - 1)
