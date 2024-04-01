extends CanvasLayer

signal text_finish
signal choise_closed

const CHAR_READ_RATE = 0.03
const CURSOR_POSITION = Vector2(946,340)

@onready var textbox_container = $TextboxContainer
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
@onready var choice_container = $ChoiceContainer
@onready var choice_label = $ChoiceContainer/MarginContainer/HBoxContainer/Label2
@onready var portrait = $Portrait
@onready var cursor = $Cursor
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")
@onready var tween = create_tween()

enum State{
	READY,
	READING,
	FINISH,
	CHOICE
}

var current_state = State.READY
var f = load("res://assets/fonts/CONSOLA.TTF")
var text_queue = []
var sprite_queue = []
var choice_id = 0
var choices = []
func _ready():
	label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", 80)
	choice_label.add_theme_font_override("font", f)
	choice_label.add_theme_font_size_override("font_size", 160)
	hide_textbox()

func hide_textbox():
	label.text = ""
	textbox_container.hide()
	choice_container.hide()
	cursor.hide()
	
func get_state():
	if current_state == State.READY:
		return "Ready"
	else:
		return ""
	
func show_textbox():
	textbox_container.show()
	
func on_tween_finished():
	change_state(State.FINISH)

func on_choice_tween_finished():
	change_state(State.CHOICE)
	choice_container.show()
	cursor.show()
	
func queue_text(next_text):
	for i in next_text:
		text_queue.push_back(i)
		sprite_queue.push_back("")
	
func queue_char_text(next_text, next_sprite):
	for i in next_text:
		text_queue.push_back(i)
	for i in next_sprite:
		sprite_queue.push_back(i)

func display_choice(text, choices):
	var next_text =  text
	tween = create_tween()
	tween.tween_property(label, "visible_ratio",1.0, len(next_text) * CHAR_READ_RATE)
	label.text = next_text
	change_state(State.READING)
	player.set_movement(false)
	show_textbox()
	portrait.hide()
	label.visible_ratio = 0.0
	tween.play()
	tween.tween_callback(on_choice_tween_finished)
	set_choices(choices)

	
func display_text():
	var next_text =  text_queue.pop_front()
	var next_sprite = sprite_queue.pop_front()
	tween = create_tween()
	tween.tween_property(label, "visible_ratio",1.0, len(next_text) * CHAR_READ_RATE)
	label.text = next_text
	if next_sprite == "":
		portrait.hide()
	else:
		portrait.texture = load(next_sprite)
		portrait.show()
	change_state(State.READING)
	player.set_movement(false)
	show_textbox()
	label.visible_ratio = 0.0
	tween.play()
	tween.tween_callback(on_tween_finished)
	
func change_state(next_state):
	current_state = next_state

func set_choices(choice_list):
	choices = choice_list
	var escolhas = ""
	for i in choices:
		escolhas += i + "\n"
	choice_label.text = escolhas

func set_cursor_pos(pos):
	cursor.set_position(pos)
	
func get_choice():
	var id = choice_id
	choice_id = 0
	return id
	
func _process(delta):
	match current_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.READING:
			if Input.is_action_just_pressed("interact"):
				if len(choices) == 0:
					label.visible_ratio = 1.0
					tween.stop()
					change_state(State.FINISH)
				else:
					label.visible_ratio = 1.0
					tween.stop()
					choice_container.show()
					cursor.show()
					change_state(State.CHOICE)
		State.FINISH:
			if Input.is_action_just_pressed("interact"):
				if !text_queue.is_empty():
					display_text()
				else:
					change_state(State.READY)
					if codebox.get_state() == "Ready":
						player.set_movement(true)
					textbox_container.hide()
					portrait.hide()
					text_finish.emit()
		State.CHOICE:
			if Input.is_action_just_pressed("down"):
				choice_id += 1
				if choice_id >= len(choices):
					choice_id = 0
				set_cursor_pos(CURSOR_POSITION + Vector2(0, 36) * choice_id)
			if Input.is_action_just_pressed("up"):
				choice_id -= 1
				if choice_id < 0:
					choice_id = len(choices) - 1
				set_cursor_pos(CURSOR_POSITION + Vector2(0, 36) * choice_id)
			if Input.is_action_just_pressed("interact"):
				change_state(State.READY)
				if codebox.get_state() == "Ready":
					player.set_movement(true)
				textbox_container.hide()
				choice_container.hide()
				set_cursor_pos(CURSOR_POSITION)
				cursor.hide()
				portrait.hide()
				choise_closed.emit()
				choices = []
