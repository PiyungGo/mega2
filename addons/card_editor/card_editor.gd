@tool
extends Control

@onready var id_edit: LineEdit = $IdEdit
@onready var name_edit: LineEdit = $NameEdit
@onready var type_option: OptionButton = $TypeOption
@onready var desc_edit: TextEdit = $DescEdit
@onready var effect_edit: LineEdit = $EffectEdit
@onready var add_btn: Button = $AddBtn
@onready var save_btn: Button = $SaveBtn

const DB_PATH := "res://data/cards/card_database.tres"
var db: CardDatabase

func _ready() -> void:
	# โหลด DB ถ้าไม่มีให้สร้างใหม่
	if ResourceLoader.exists(DB_PATH):
		db = load(DB_PATH)
	else:
		db = CardDatabase.new()
		ResourceSaver.save(db, DB_PATH)

	add_btn.pressed.connect(_on_add_card)
	save_btn.pressed.connect(_on_save_db)

func _on_add_card() -> void:
	var card := CardData.new()
	card.id = id_edit.text
	card.name = name_edit.text
	card.type = type_option.selected
	card.desc = desc_edit.text
	card.effect = effect_edit.text
	db.cards.append(card)

func _on_save_db() -> void:
	ResourceSaver.save(db, DB_PATH)
	print("บันทึกการ์ดลง Database แล้ว")
