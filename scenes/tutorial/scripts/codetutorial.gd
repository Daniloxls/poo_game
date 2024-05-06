extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var pit = $Pit
@onready var ponte_interact = $PonteInt
@onready var ponte_colision =  $PonteInt/StaticBody2D
@onready var porta = $PortaBool
@onready var stringdoor = $PortaString

var entrances  = [Vector2(-12575,6356)]
# Called when the node enters the scene tree for the first time.
func _ready():
	textbox.queue_char_text(["Vejo que você estava explorando e acabou caindo aqui por aquela rachadura",
						"Deixe me ver, eu acho que posso te ajudar a sair daqui, siga para a direita minha sala não deve ser muito distante de onde você está."],
						["res://assets/portraits/silhueta.png",
						"res://assets/portraits/silhueta.png"])
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	pass

func enter_stage(entrance : int):
	player.set_position(entrances[entrance])
	
