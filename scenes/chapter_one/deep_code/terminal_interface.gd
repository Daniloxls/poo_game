extends CanvasLayer

signal sudo_typed
signal sudo_activated
signal command_missed
signal password_missed
signal window_closed

@onready var v_box_container = $ScrollContainer/VBoxContainer
@onready var command_line = $CommandLine
@onready var close_button: Button = $CloseButton

var style

enum State{
	BEFORE_SUDO,
	SUDO,
	AFTER_SUDO
}
var current_state = State.BEFORE_SUDO

# Called when the node enters the scene tree for the first time.
func _ready():
	style = load("res://scenes/tutorial/terminal_line_style.tres")
	close_button.connect("pressed", close_screen)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_line_edit_text_submitted(new_text):
	var line = LineEdit.new()
	line.add_theme_stylebox_override("read_only", style)
	line.add_theme_stylebox_override("focus", style)
	line.add_theme_color_override("font_uneditable_color", Color("#FFFFFF"))
	line.set_editable(false)
	line.set_text("comando '" + new_text + "' não reconhecido")
	command_line.set_text("")
	match(current_state):
		State.BEFORE_SUDO:
			if new_text == "sudo":
				line.set_text("digite a senha para ativar sudo:")
				command_line.release_focus()
				current_state = State.SUDO
				sudo_typed.emit()
			else:
				command_missed.emit()
		State.SUDO:
			if new_text == "senha123":
				line.set_text("senha correta, ativando sudo")
				current_state = State.AFTER_SUDO
				sudo_activated.emit()
			else:
				line.set_text("senha incorreta, tente novamente")
				password_missed.emit()
				
	v_box_container.add_child(line)

func close_screen():
	hide()
	window_closed.emit()
