extends Node2D

@onready var audio: AudioStreamPlayer = get_node("Audio_Start")
@onready var player = get_node("../Level").get_child(0).find_child("Player")
@onready var music = get_node("../AudioPlayer")
@onready var tela = $CanvasLayer
# Called when the node enters the scene tree for the first time.
func _ready():
	#music.set_stream(load("res://assets/bgm/Dream Eliot Corley.mp3"))
	#music.play()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	
	player.set_state(States.Player_State.FREE)
	tela.hide()
	audio.play()
	#music.set_stream(load("res://assets/bgm/TremLoadingloopl.mp3"))
	#music.set_volume_db(-24)
	#music.play()
	pass # Replace with function body.
