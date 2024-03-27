extends Node2D

signal animation_end

@onready var monster_stats = $MonsterStatus
@onready var actions = $Actions
@onready var cursor = $Actions/Cursor
@onready var characters = $PlayerStatus/MarginContainer/HBoxContainer.get_children()
@onready var monster_list = $MonsterStatus/MarginContainer/HBoxContainer/Label2

const CURSOR_INITIAL_Y = -43


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
		cursor_pos = 2
		update_cursor_pos()
	else:
		cursor_pos -= 1
		update_cursor_pos()

func move_cursor_down():
	if cursor_pos == 2:
		cursor_pos = 0
		update_cursor_pos()
	else:
		cursor_pos += 1
		update_cursor_pos()


func get_cursor_pos():
	return cursor_pos


func hide_cursor():
	cursor.hide()
	
func show_cursor():
	cursor.show()
	
func set_monster_names(list):
	var names = ''
	for monstro in list:
		names += monstro + '\n'
	monster_list.set_text(names)
	
func hide_char_status(id):
	characters[id].hide()
	
func show_char_status(id):
	characters[id].show()
	
func set_character_name(id, nome):
	characters[id].set_nome(nome)

func update_health_instant(id, percentage):
	characters[id].set_health_instant(percentage)
	
func update_health_slow(id, percentage):
	characters[id].set_health_slow(percentage)
	
func update_mana_instant(id, value):
	characters[id].set_mana_instant(value)
	
func update_mana_slow(id, value):
	characters[id].set_mana_slow(value)


func _on_char_1_animation_end():
	animation_end.emit()



func _on_char_2_animation_end():
	animation_end.emit()


func _on_char_3_animation_end():
	animation_end.emit()


func _on_char_4_animation_end():
	animation_end.emit()
