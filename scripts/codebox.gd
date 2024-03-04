extends CanvasLayer


const CHAR_READ_RATE = 0.03
@onready var textbox_container = $TextboxContainer
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
@onready var cursor = $Cursor
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")

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
var typing = false
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
	if nome == "":
		return
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
		else:
			next_text += p + " = "+ str(prop[p]) + "\n"
	text_queue.push_back(next_text)
	display_text()
	
	
func display_text():
	var next_text =  text_queue.pop_front()
	label.text = next_text
	change_state(State.FINISH)
	player.set_movement(false)
	show_textbox()
	

	
func change_state(next_state):
	current_state = next_state

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
	cursor.set_pos_y(67 + (cursor_pos* 36))


func _process(delta):
	match current_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.FINISH:
			if cursor_state == Cursor.SHOWING and !typing:
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
				if "boolean" in cursor_dict[cursor_pos]:
					if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("left"):
						if prop[cursor_dict[cursor_pos]]:
							update_text(cursor_dict[cursor_pos],false)
						else:
							update_text(cursor_dict[cursor_pos],true)
				if "int" in cursor_dict[cursor_pos]:
					if Input.is_action_just_pressed("right"):
						update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]]+1)
					if Input.is_action_just_pressed("left"):
						update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]]-1)
				if "String" in cursor_dict[cursor_pos]:
					if Input.is_action_just_pressed("enter"):
						typing = true;
				if Input.is_action_just_pressed("exit"):
					cursor_pos = 0
					update_cursor_pos()
					change_state(State.READY)
					if textbox.get_state() == "Ready":
						player.set_movement(true)
					hide_textbox()
			elif typing:
				if Input.is_action_just_pressed("backspace"):
					update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]].left(len(prop[cursor_dict[cursor_pos]]) - 1))
				if Input.is_action_just_pressed("a"):
					update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]] + "a")
				if Input.is_action_just_pressed("b"):
					update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]] + "b")
				
				if Input.is_action_just_pressed("c"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "c")

				if Input.is_action_just_pressed("d"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "d")

				if Input.is_action_just_pressed("e"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "e")

				if Input.is_action_just_pressed("f"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "f")

				if Input.is_action_just_pressed("g"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "g")

				if Input.is_action_just_pressed("h"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "h")

				if Input.is_action_just_pressed("i"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "i")

				if Input.is_action_just_pressed("j"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "j")

				if Input.is_action_just_pressed("k"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "k")

				if Input.is_action_just_pressed("l"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "l")

				if Input.is_action_just_pressed("m"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "m")

				if Input.is_action_just_pressed("n"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "n")

				if Input.is_action_just_pressed("o"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "o")

				if Input.is_action_just_pressed("p"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "p")

				if Input.is_action_just_pressed("q"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "q")

				if Input.is_action_just_pressed("r"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "r")

				if Input.is_action_just_pressed("s"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "s")

				if Input.is_action_just_pressed("t"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "t")

				if Input.is_action_just_pressed("u"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "u")

				if Input.is_action_just_pressed("v"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "v")

				if Input.is_action_just_pressed("w"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "w")

				if Input.is_action_just_pressed("x"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "x")

				if Input.is_action_just_pressed("y"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "y")

				if Input.is_action_just_pressed("z"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "z")
				
				if Input.is_action_just_pressed("espaço"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + " ")
					
				if Input.is_action_just_pressed("enter"):
					typing = false

			
