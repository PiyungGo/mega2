extends Resource
class_name CardData

# ประกาศ enum → Inspector จะโชว์เป็น dropdown
enum CardType { ATTACK, DEFENSE, MYSTERY }

@export var id: String
@export var name: String
@export var type: CardType = CardType.ATTACK   # จะโชว์เป็น dropdown
@export var desc: String
@export var effect: String
@export var icon: Texture2D
