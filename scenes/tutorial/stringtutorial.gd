extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var stringdoor = $Stringdoor/Area2D
@onready var map = $TileMap

var dialogue_sequence = [true, true, false, false]
var current_dialogue = 0
var senha_certa = false
# Called when the node enters the scene tree for the first time.
func _ready():
	stringdoor.set_texto(["Eesse teclado deve ser para colocar a senha"])
	stringdoor.set_codigo("Teclado Numerico", {"1String senha" : "senha123"})
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("exit"):
		if !("a" in stringdoor.depure()["1String senha"]) and !("s" in stringdoor.depure()["1String senha"]):
			stringdoor.set_texto(["Parece que a senha funcionou!"])
			senha_certa = true
	if senha_certa:
		if player.position.x > 275 and player.position.y > 123:
			if Input.is_action_just_pressed("interact"):
				map.set_layer_enabled(2, false)
	if player.position.x > 260 and player.position.y > 105 and current_dialogue < 4:
		match(current_dialogue):
			0:
				current_dialogue = 1
				textbox.queue_text(["Mais uma porta trancada, veja se você consegue abrir ela,
				 e se apresse se não você vai ficar preso aqui que nem eu"])
			1:
				if player.position.x > 275 and player.position.y > 123:
					if Input.is_action_just_pressed("depure"):
						textbox.queue_text(["Parece que alguem foi idiota o suficiente para deixar a senha da porta nas propiedades do teclado,
						 digite ela e venha logo para cá, já sinto sua presença."])
						stringdoor.set_texto(["Está faltando o 's' e o 'a' desse teclado"])
					if Input.is_action_just_pressed("exit"):
						current_dialogue = 2
			2:
				if Input.is_action_just_pressed("interact"):
					textbox.queue_text(["Maldição esse teclado deve estar quebrado de tão velho que é,
					abra o codigo da caixa e vamos tentar mudar a senha para algo que você consiga digitar"])
					current_dialogue = 3
			3:
				if Input.is_action_just_pressed("depure"):
					textbox.queue_text(["Para editar uma variável String, basta usar as setas para cima e para baixo e apertar Enter quando escolher a String que você quer editar",
					"Quando você aperta enter você entra no modo de edição da string, basta escrever uma senha que não tenha as letras quebradas e isso deve resolver",
					"E mais uma coisa, para sair do modo de edição da String basta apertar Enter novamente"])
					current_dialogue = 4
	pass
