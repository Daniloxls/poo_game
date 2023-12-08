extends CanvasLayer


const CHAR_READ_RATE = 0.03
@onready var textbox_container = $TextboxContainer
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2

@onready var tween = create_tween()

enum State{
	READY,
	READING,
	FINISH
}

var current_state = State.READY
var text_queue = []

func _ready():
	hide_textbox()

func hide_textbox():
	label.text = ""
	textbox_container.hide()
	
func get_state():
	if current_state == State.READY:
		return "Ready"
	else:
		return ""
	
func show_textbox():
	textbox_container.show()
	
func on_tween_finished():
	change_state(State.FINISH)
	
func queue_text(next_text):
	for i in next_text:
		text_queue.push_back(i)
	
func display_text():
	var next_text =  text_queue.pop_front()
	tween = create_tween()
	tween.tween_property(label, "visible_ratio",1.0, len(next_text) * CHAR_READ_RATE)
	label.text = next_text
	change_state(State.READING)
	show_textbox()
	label.visible_ratio = 0.0
	tween.play()
	tween.tween_callback(on_tween_finished)
	

	
func change_state(next_state):
	current_state = next_state
	match current_state:
		State.READY:
			print("Ready")
		State.READING:
			print("READING")
		State.FINISH:
			print("FINISH")


func _process(delta):
	match current_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.READING:
			if Input.is_action_just_pressed("interact"):
				label.visible_ratio = 1.0
				tween.stop()
				change_state(State.FINISH)
		State.FINISH:
			if Input.is_action_just_pressed("interact"):
				if !text_queue.is_empty():
					display_text()
				else:
					change_state(State.READY)
					textbox_container.hide()
