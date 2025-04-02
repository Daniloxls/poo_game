extends Node2D

@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var player = $Player
@onready var cutscene = $Cutscene

# Called when the node enters the scene tree for the first time.
func _ready():
	textbox.queue_text(["Turin!", "Você está bem? Acho que você bateu a cabeça quando aquele esquisitão atacou a gente.", "Esse senhor aqui me ajudou a te tirar da vila. Ele falou algo sobre você ser capaz de enfrentar o mal.", "Mas tudo o que eu vi foi você parado que nem um bobalhão enquanto aquele cara de cabelo verde falava sem parar.", "Enfim, levanta aí que o senhor MacAlistair quer falar com você."])
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_cutscene_scene_start():
	player.set_in_scene(true)
	pass # Replace with function body.


func _on_cutscene_scene_end():
	player.set_in_scene(false)
	pass # Replace with function body.
