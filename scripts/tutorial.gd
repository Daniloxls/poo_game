extends Node2D

@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var placa = $Placa/Area2D
@onready var arbusto = $Arbusto/Area2D
var depure_turorial = true
var depure_text = true

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Agora queue_texto opera com listas de string, para evitar chamar a função varias vezes
	textbox.queue_text(["Arg, onde eu estou?! oOo\nNão sei por quê mas acho que eu deveria dizer [Press Z] ... @~@",
	"... Ah, ei você!\nParado aí, você está perdido também? ò_ô",
	"Bem, me chamo Textos Boxilianos Doisdê, mas você pode me chamar de Textinho ^u^\nSou um objeto como você!",
	"E o seu nome?",
	"...",
	"Player? Eu suponho. Vou te chamar de P.",
	"COMO?! Não sabe o que é um objeto? Ops. Falei de mais. Agora não tem mais volta. Rompemos os véu binário da quarta p... Acho que não chegamos nesse ponto ainda. Então tudo bem!",
	"Tente usar essas setas que você tem aí para andar um pouco e ver se você pode encontrar alguma coisa",
	"Como estamos perdidos, o que posso fazer é te ajudar a lidar com isso no caminho. Na verdade não sou nenhum piscólogo, ou coach, então: Boa Sorte!"])

	#set_texto coloca o dialogo que um objeto vai ter quando interagir com ele
	placa.set_texto(["Oi eu sou uma plaquinha", "Eu gosto de ficar parada aqui"])
	
	#set_codigo coloca o codigo que vai aparecer quando o jogador apertar c para depurar o objeto
	placa.set_codigo("Placa",{"String nome": "Plaquinha", "bool fala": true, "int tamanho":5})
	
	arbusto.set_texto(["Oi eu sou uma plaquinha", "Eu gosto de ficar parada aqui"])
	arbusto.set_codigo("Arbusto",{"int x": 160, "int y": 280, "bool contem_frutas":true, "Fruta amora": "", "String  local": "Floresta das sombras"})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.position > Vector2(160,0):
		if depure_turorial:
			depure_turorial = false
			textbox.queue_text(["Olhe, aquele arbusto, vai ser uma boa oportunidade para eu te mostar o que é um objeto!",
								"Todas as coisas nesse mundo são objetos e esses objetos possuem classes",
								"Parece que você tem uma ferramenta de depurar aí, tente usar ela naquela planta, basta chegar perto dele e apertar C"])
		elif codebox.get_state() != "Ready":
			if depure_text:
				depure_text = false
				textbox.queue_text(["Como você pode ver essas são as propiedades dessa planta",
				"Dá pra ver que ela é uma amoreira só pela classe dela",
				"Esses x e y devem ser a posição dela no mundo",
				"E é verdade que ela tem frutas, dá pra ver olhando pra ela",
				"E olhe só a amora é um objeto separado com a classe fruta que fica guardada no codigo da amoreira",
				"E parece que essa amoreira tambem guarda o nome do lugar onde ela fica, mas pera aí...",
				"Floresta das sombras !? O-O",
				"Essa é a floresta mais perigosa do reino, cheia de insetos gigante e outras criaturas!",
				"Eu acho melhor a gente dar o fora daqui o quanto antes!",
				"Aperte X para sair da depuração e vamos correr daqui"])
		
	pass
