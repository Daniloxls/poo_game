extends Node2D

@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var placa = $Placa/Area2D
var depure_turorial = true
var depure_text = true

# Called when the node enters the scene tree for the first time.
func _ready():
	"""textbox.queue_text("Arg, onde eu estou?! oOo\nNão sei por quê mas acho que eu deveria dizer [Press Z] ... @~@")
	textbox.queue_text("... Ah, ei você!\nParado aí, você está perdido também? ò_ô")
	textbox.queue_text("Bem, me chamo Textos Boxilianos Doisdê, mas você pode me chamar de Textinho ^u^\nSou um objeto como você!")
	textbox.queue_text("E o seu nome?")
	textbox.queue_text("...")
	textbox.queue_text("Player? Eu suponho. Vou te chamar de P.")
	textbox.queue_text("COMO?! Não sabe o que é um objeto? Ops. Falei de mais. Agora não tem mais volta. Rompemos os véu binário da quarta p... Acho que não chegamos nesse ponto ainda. Então tudo bem!")
	textbox.queue_text("Tente usar essas setas que você tem aí para andar um pouco e ver se você pode encontrar alguma coisa")
	textbox.queue_text("Como estamos perdidos, o que posso fazer é te ajudar a lidar com isso no caminho. Na verdade não sou nenhum piscólogo, ou coach, então: Boa Sorte!")
	"""
	#Agora set_texto opera com listas de string, para evitar chamar a função varias vezes
	placa.set_texto(["Oi eu sou uma plaquinha", "Eu gosto de ficar parada aqui"])
	placa.set_codigo("Placa",{"String nome": "Plaquinha", "bool fala": true, "int tamanho":5})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.position > Vector2(160,0):
		if depure_turorial:
			depure_turorial = false
			textbox.queue_text(["Olhe, aquele arbusto, vai ser uma boa oportunidade para eu te mostar o que é um objeto!",
								"Todas as coisas nesse mundo são objetos e esses objetos possuem classes",
								"Parece que você tem uma ferramenta de depurar aí, tente usar ela naquela planta, basta chegar perto dele e apertar C"])
		elif Input.is_action_pressed("depure"):
			if depure_text:
				depure_text = false
				textbox.queue_text("Como você pode ver essas são as propiedades dessa planta")
				textbox.queue_text("Dá pra ver que ela é uma amoreira só pela classe dela")
				textbox.queue_text("Esses x e y devem ser a posição dela no mundo")
				textbox.queue_text("E é verdade que ela tem frutas, dá pra ver olhando pra ela")
				textbox.queue_text("E olhe só a amora é um objeto separado com a classe fruta que fica guardada no codigo da amoreira")
				textbox.queue_text("E parece que essa amoreira tambem guarda o nome do lugar onde ela fica, mas pera aí...")
				textbox.queue_text("Floresta das sombras !? O-O")
				textbox.queue_text("Essa é a floresta mais perigosa do reino, cheia de insetos gigante e outras criaturas!")
				textbox.queue_text("Eu acho melhor a gente dar o fora daqui o quanto antes!")
				textbox.queue_text("Aperte X para sair da depuração e vamos correr daqui")
		
	pass
