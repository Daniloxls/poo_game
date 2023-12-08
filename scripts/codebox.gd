extends CanvasLayer


const CHAR_READ_RATE = 0.03
@onready var textbox_container = $TextboxContainer
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2


enum State{
	READY,
	FINISH
}

var current_state = State.READY
var text_queue = []
func _ready():
	hide_textbox()

func hide_textbox():
	label.text = ""
	textbox_container.hide()
	
func show_textbox():
	textbox_container.show()

func queue_text(nome, props):
	var next_text = ""
	next_text += nome+"\n"
	for p in props.keys():
		next_text += p + " = "+ str(props[p]) + "\n"
	text_queue.push_back(next_text)
	
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

func get_state():
	if current_state == State.READY:
		return "Ready"
	else:
		return ""

func _process(delta):
	match current_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.FINISH:
			if Input.is_action_just_pressed("exit"):
				change_state(State.READY)
				textbox_container.hide()
