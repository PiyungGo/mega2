extends Sprite2D

const BOARD_SIZE = 8

const good_bishop = "res://Asset_UWU/S__5128198.png"
const center_bishop = "res://Asset_UWU/S__5128204.png"
const hacker_ishop = "res://Asset_UWU/S__5128209.png"



@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn =$Turn

var board : Array
var good : bool
var state : bool
var move = {}
var selected_piece : Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
