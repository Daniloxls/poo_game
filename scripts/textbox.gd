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
	queue_text("Arg, onde eu estou?! oOo\nNão sei por quê mas acho que eu deveria dizer [Press Z] ... @~@")
	queue_text("... Ah, ei você!\nParado aí, você está perdido também? ò_ô")
	queue_text("Bem, me chamo Textos Boxilianos Doisdê, mas você pode me chamar de Textinho ^u^\nSou um objeto como você!")
	queue_text("E o seu nome?")
	queue_text("...")
	queue_text("Player? Eu suponho. Vou te chamar de P.")
	queue_text("COMO?! Não sabe o que é um objeto? Ops. Falei de mais. Agora não tem mais volta. Rompemos os véu binário da quarta p... Acho que não chegamos nesse ponto ainda. Então tudo bem!")
	queue_text("Como estamos perdidos, o que posso fazer é te ajudar a lidar com isso no caminho. Na verdade não sou nenhum piscólogo, ou coach, então: Boa Sorte!")

func hide_textbox():
	label.text = ""
	textbox_container.hide()
	
func show_textbox():
	textbox_container.show()
	
func on_tween_finished():
	change_state(State.FINISH)
	
func queue_text(next_text):
	text_queue.push_back(next_text)
	
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
