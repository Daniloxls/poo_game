extends Node2D

@onready var player = $Player
@onready var cutscene = $Cutscene

# Called when the node enters the scene tree for the first time.
func _ready():
	Textbox.queue_text(["Turin!", "Você está bem? Acho que você bateu a cabeça quando aquele esquisitão atacou a gente.", "Esse senhor aqui me ajudou a te tirar da vila. Ele falou algo sobre você ser capaz de enfrentar o mal.", "Mas tudo o que eu vi foi você parado que nem um bobalhão enquanto aquele cara de cabelo verde falava sem parar.", "Enfim, levanta aí que o senhor MacAlistair quer falar com você."])
