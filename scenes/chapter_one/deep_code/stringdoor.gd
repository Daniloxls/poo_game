extends "res://scenes/main/scripts/interact.gd"

@onready var sprite = $AnimatedSprite2D
@onready var porta = $Porta
@onready var broken_keyboard: CanvasLayer = $BrokenKeyboard
@onready var broken_keyboard_line_edit: LineEdit = $BrokenKeyboard/LineEdit

var good_password = false
var dialogue = true
var interacted = false

# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "Teclado Numerico"
	texto = ["Esse teclado deve ser para colocar a senha.", "Estão faltando as teclas 'a' e 's'."]
	codigo = {"1String senha" : "senha123"}
	ready_drop_menu()
	Codebox.connect("codebox_open", _on_codebox_code_open)
	Codebox.connect("codebox_close", _on_codebox_code_closed)
	broken_keyboard.connect("text_submit", on_keyboard_text_submit)
	broken_keyboard.connect("close", on_keyboard_close)
	
func interaction():
	interacted = true
	#if good_password:
		#sprite.set_frame_and_progress(1, 0)
		#porta.unlock()
	Textbox.queue_text(texto)
	PlayerState.set_on_interface(true)
	broken_keyboard.show()
	
func _on_codebox_code_open(name):
	if dialogue and (name == self.get_name()):
		dialogue = false
		Textbox.queue_char_text(["Parece que o tolo que projetou essa sala deixou a senha da porta salva em uma string.",
		"Uma que podemos editar ainda por cima.",
		"Variáveis String são formadas por conjuntos de caracteres",
		"Para editar essa string basta seleciona-la.",
		"A partir daí você pode digitar o que quiser para ser a String.",
		"Tente editar a senha dessa porta para alguma coisa que você consiga digitar sem 'a' nem 's' e depois tente interagir com esse teclado novamente."],
		["res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png"])
				



func _on_codebox_code_closed(name):
	if !("a" in codigo["1String senha"]) and !("s" in codigo["1String senha"]):
		#set_texto(["Parece que a senha funcionou!"])
		good_password = true
	elif interacted:
		set_texto(["Não consigo digitar essa senha, o teclado não tem as teclas 'a' nem 's'."])
		good_password = false

func on_keyboard_text_submit(password):
	if password == codigo["1String senha"]:
		sprite.set_frame_and_progress(1, 0)
		porta.unlock()
		broken_keyboard.hide()
		PlayerState.set_on_interface(false)
	else:
		Textbox.queue_text(["Senha Incorreta"])
		broken_keyboard_line_edit.release_focus()

func on_keyboard_close():
	broken_keyboard.hide()
	PlayerState.set_on_interface(false)
