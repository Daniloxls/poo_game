extends CanvasLayer


const CHAR_READ_RATE = 0.03
@onready var textbox_container = $TextboxContainer
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
@onready var cursor = $Cursor


enum State{
	READY,
	FINISH
}
enum Cursor{
	SHOWING,
	HIDDEN
}
var cursor_state = Cursor.HIDDEN
var cursor_pos
var positions = []
var current_state = State.READY
var prop = {}
var cursor_dict = {}
var classname
var text_queue = []
func _ready():
	hide_textbox()

func hide_textbox():
	label.text = ""
	textbox_container.hide()
	cursor.hide()
	prop = {}
	cursor_dict = {}
	positions = []
	
func show_textbox():
	textbox_container.show()

func queue_text(nome, props):
	var next_text = ""
	classname = nome
	next_text += classname+"\n"
	prop = props
	for p in prop.keys():
		if "1" in p:
			show_cursor()
			next_text += p.right(len(p) - 1) + " = "+ str(prop[p]) + "\n"
			positions.append(prop.keys().find(p))
			cursor_dict[prop.keys().find(p)] = p
		else:
			next_text += p + " = "+ str(prop[p]) + "\n"
	text_queue.push_back(next_text)
	if cursor_state == Cursor.SHOWING:
		cursor_pos = positions[0]
	
func update_text(chave, valor):
	var next_text = ""
	next_text += classname+"\n"
	prop[chave] = valor
	for p in prop.keys():
		if "1" in p:
			next_text += p.right(len(p) - 1) + " = "+ str(prop[p]) + "\n"
	text_queue.push_back(next_text)
	display_text()
	
	
func display_text():
	var next_text =  text_queue.pop_front()
	label.text = next_text
	change_state(State.FINISH)
	show_textbox()
	

	
func change_state(next_state):
	current_state = next_state
	match current_state:
		State.READY:
			print("Ready")
		State.FINISH:
			print("FINISH")

func show_cursor():
	cursor_state = Cursor.SHOWING
	cursor.show()
	pass

func get_props():
	return prop
	

func get_state():
	if current_state == State.READY:
		return "Ready"
	else:
		return ""

func update_cursor_pos():
	cursor.set_pos_y(82 + (cursor_pos* 42))
	
func _process(delta):
	match current_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.FINISH:
			if cursor_state == Cursor.SHOWING:
				if Input.is_action_just_pressed("down"):
					cursor_pos += 1
					if cursor_pos == len(positions):
						cursor_pos = 0
					update_cursor_pos()
				if Input.is_action_just_pressed("up"):
					cursor_pos -= 1
					if cursor_pos == -1:
						cursor_pos = len(positions)-1
					update_cursor_pos()
				if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("left"):
					if prop[cursor_dict[cursor_pos]]:
						update_text(cursor_dict[cursor_pos],false)
					else:
						update_text(cursor_dict[cursor_pos],true)
					
			if Input.is_action_just_pressed("exit"):
				change_state(State.READY)
				hide_textbox()
