extends "res://scripts/interact.gd"
@onready var interface = $VidenteInterface
@onready var pensamento_field = $VidenteInterface/Pensamento
@onready var medium = $VidenteInterface/MediumPanel
@onready var styleBox: StyleBoxTexture = medium.get_theme_stylebox("panel")
@onready var think_button = $VidenteInterface/Button
@onready var error_label = $VidenteInterface/BackPanel/ErrorLabel
@onready var tickets = $"../Tickets"
@onready var left_label = $VidenteInterface/LeftLabel
var first_interaction = true
var correct_answer = false
var triggered = false
var retorno
enum State{
	FIRST,
	OPEN,
	GUESSING,
	ERROR,
	BEATEN,
	FINISHED,
	CLOSED
}
var current_state = State.FIRST
# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "LeitorDePensamento"
	codigo = {}
	texto =[["Seja bem vindo ao meu jogo jovem.", "As regras são bem simples.",
	"Pense em uma palavra e escreva ela aí embaixo, se eu conseguir advinhar a palavra que você pensou eu ganho.",
	"Se eu errar você ganha, e de bonûs você leva 10 tickets."]]
	metodos = {
	"1" : ["String leitor_de_pensamento(Personagem jogador){"],
	"2" : ["\tString resposta"] ,
	"3" : ["\tresposta = jogador.get_pensamento()"],
	"0":  ["\treturn resposta;", 8, 8],
	"4" : ["}"]
	}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("x") and !pensamento_field.has_focus():
		close_window()

func interaction():
	player.set_movement(false)
	triggered = true
	open_window()
	if current_state == State.FINISHED:
		return
	if first_interaction:
		textbox.queue_text(texto[0])
	else:
		current_state = State.OPEN

func open_window():
	interface.show()
	if current_state == State.FINISHED:
		return
	retorno = metodos["0"][0].substr(metodos["0"][1], metodos["0"][2])
	retorno = retorno.lstrip(" ").rstrip(" ")
	if retorno[0] == ("'") and retorno.ends_with("'"):
		correct_answer = true
	elif retorno.is_valid_float():
		show_error("Tipos incompatíveis: não se pode converter de int para String")
	elif retorno != "resposta":
		show_error("Referência a variável " + retorno + "  não pôde ser resolvida")
	
func close_window():
	medium.show()
	triggered = false
	error_label.hide()
	interface.hide()
	player.set_movement(true)
	if current_state != State.FINISHED:
		think_button.show()
		pensamento_field.show()
		current_state = State.CLOSED
	
func show_error(error : String) -> void:
	medium.hide()
	think_button.hide()
	pensamento_field.hide()
	error_label.show()
	error_label.set_text(error)
	current_state = State.ERROR
	
func _on_button_pressed():
	var pensamento = pensamento_field.get_text()
	retorno = retorno.lstrip("'").rstrip("'")
	pensamento_field.clear()
	if !correct_answer or retorno == pensamento:
		textbox.queue_text(["Vejamos...", "Eu vejo que a palavra que você pensou foi " + pensamento + ".",
		 "Mais uma vez o grande Tritomos adivinha", "Tente a sorte da próxima vez garoto."])
	else:
		textbox.queue_text(["Vejamos...", "Eu vejo que a palavra que você pensou foi " + retorno + ".",
		 "...", "Parece que eu me enganei dessa vez.", "Deve ter uma mancha na minha bola de cristal.",
		"Pegue seus tickets e suma daqui, isso foi sorte de principiante!"])
		current_state = State.BEATEN

func _on_textbox_text_finish():
	if triggered:
		if first_interaction:
			first_interaction = false
			player.set_movement(false)
			current_state = State.OPEN
		elif current_state == State.OPEN:
			close_window()
		elif current_state == State.BEATEN:
			tickets.show()
			tickets.recieve_tickets(10)
			styleBox.set_texture(load("res://assets/props/city/vidente_left.png"))
			left_label.show()
			current_state = State.FINISHED
			pensamento_field.hide()
			think_button.hide()
			close_window()