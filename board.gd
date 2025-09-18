extends Sprite2D

const BOARD_SIZE = 8
const cell_width = 18

const texture_holder = preload("res://texture_holder.tscn")

const good_bishop = preload("res://Asset_UWU/S__5128198.png")
const call_bishop = preload("res://Asset_UWU/S__5128204.png")
const hacker_bishop = preload("res://Asset_UWU/S__5128209.png")
const police_bishop = preload("res://Asset_UWU/character/S__5128217_0.png")


@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn =$Turn

var board : Array
var good : bool
var state : bool
var move = []
var selected_piece : Vector2
# Called when the node enters the scene tree for the first time.
func _ready() :
	board.append([1,0,0,0,0,0,0,2])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([3,0,0,0,0,0,0,4])
	
	display_board()

func display_board():
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = texture_holder.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2 (j * cell_width + (cell_width / 2), -i * cell_width - (cell_width / 2))
			
			match board[i][j]:
				0: holder.texture = null
				1: holder.texture = good_bishop
				2: holder.texture = call_bishop
				3: holder.texture = hacker_bishop
				4: holder.texture = police_bishop
