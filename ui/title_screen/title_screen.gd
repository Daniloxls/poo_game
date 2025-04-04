extends Node2D

@onready var tela = $CanvasLayer
# Called when the node enters the scene tree for the first time.
func _ready():
	PlayerState.set_on_interface(true)
	#music.set_stream(load("res://assets/bgm/Dream Eliot Corley.mp3"))
	#music.play()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	
	PlayerState.set_on_interface(false)
	tela.hide()
	AudioPlayer.play()
	#music.set_stream(load("res://assets/bgm/TremLoadingloopl.mp3"))
	#music.set_volume_db(-24)
	#music.play()
	pass # Replace with function body.
