extends Control
signal closed
func _on_CloseButton_pressed():
	emit_signal("closed")
	queue_free()  # ปิดตัวเอง
