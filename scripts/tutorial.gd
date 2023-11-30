extends Node2D

@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
var depure_turorial = true
var depure_text = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.position > Vector2(160,0):
		if depure_turorial:
			depure_turorial = false
			textbox.queue_text("Olhe, aquele arbusto, vai ser uma boa oportunidade para eu te mostar o que é um objeto!")
			textbox.queue_text("Todas as coisas nesse mundo são objetos e esses objetos possuem classes")
			textbox.queue_text("Parece que você tem uma ferramenta de depurar aí, tente usar ela naquela planta, basta chegar perto dele e apertar C")
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
