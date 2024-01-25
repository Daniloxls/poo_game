extends Node2D

@onready var monster_stats = $MonsterStatus
@onready var actions = $Actions
@onready var cursor = $Actions/Cursor
@onready var player_stats = $PlayerStatus
@onready var player_mana = $PlayerMana
@onready var player_health = $PlayerHealth
const CURSOR_INITIAL_Y = -50


var cursor_pos = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_cursor_pos():
	cursor.set_pos_y(CURSOR_INITIAL_Y + (40 * cursor_pos))
	
func move_cursor_up():
	if cursor_pos == 0:
		cursor_pos = 3
		update_cursor_pos()
	else:
		cursor_pos -= 1
		update_cursor_pos()

func move_cursor_down():
	if cursor_pos == 3:
		cursor_pos = 0
		update_cursor_pos()
	else:
		cursor_pos += 1
		update_cursor_pos()


func get_cursor_pos():
	return cursor_pos


func hide_cursor():
	cursor.hide()
