@tool
extends Resource
class_name CardDatabase

@export var cards: Array[CardData] = []   # <- ใส่การ์ดได้จาก Inspector เลย

func get_by_id(card_id: String) -> CardData:
	for c in cards:
		if c and c.id == card_id:
			return c
	return null
