extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var pit = $Pit
@onready var ponte_interact = $PonteInt
@onready var ponte_colision =  $PonteInt/StaticBody2D
@onready var porta = $PortaBool
@onready var stringdoor = $PortaString
var porta_trancada = true
var porta_codigo = true
# Called when the node enters the scene tree for the first time.
func _ready():
	textbox.queue_text(["Vejo que você estava explorando e acabou caindo aqui por aquela rachadura",
						"Deixe me ver, eu acho que posso te ajudar a sair daqui, siga para
						a direita minha sala não deve ser muito distante de onde você está."])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.position >= Vector2(212,200):
		if porta_trancada:
			porta_trancada = false
			textbox.queue_text(["Olhe lá, aquela porta parece estar trancada, vamos usar essas habilidades que você ganhou para resolver isso...",
								"Aperte C para ver o codigo dessa porta, talvez nós consigamos destranca-la dessa forma"])
		else: 
			if Input.is_action_just_pressed("depure"):
				if porta_codigo:
					porta_codigo = false
					textbox.queue_text(["Muito bem... Parece que a tranca dessa porta é uma variável booleana, isso quer dizer que ela só pode ser verdadeira ou falsa (True ou False).",
										"Mova o cursor com as setas para cima e para baixo e edite ela com esquerda e direita, torne a propiedade trancada falsa, isso deve resolver."])
	if Input.is_action_just_pressed("exit"):
		if !("a" in stringdoor.depure()["1String senha"]) and !("s" in stringdoor.depure()["1String senha"]):
			stringdoor.set_texto(["Parece que a senha funcionou!"])
	pass
