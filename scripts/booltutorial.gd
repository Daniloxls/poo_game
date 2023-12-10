extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var porta = $Porta/Area2D

var porta_trancada = true
var porta_codigo = true
# Called when the node enters the scene tree for the first time.
func _ready():
	textbox.queue_text(["Muito bem, agora que você tem as permissões de desenvolvedor preciso que você chegue até mim.",
						"Deve haver alguma porta nessa sala entre por ela e você estará mais próximo de mim"])
	porta.set_texto(["Está trancada."])
	porta.set_codigo("Porta", {"1boolean trancado": true, "1int tabuas" : 5,  "1String lugar" :"Codigo_fonte"} )
	


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
	pass
