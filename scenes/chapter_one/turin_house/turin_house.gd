extends Node2D
@onready var player = $Player
@onready var brilho = $Brilho
var entrances = [Vector2(-116, -94), Vector2(3157, 3635)]
# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	PlayerState.set_on_scene(true)
	tween.tween_property(brilho, "modulate",Color(255, 255, 255, 0), 3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Textbox.queue_char_text.bind(["Que sonho esquisito"], [""]))
	MusicPlayer.set_stream(load("res://assets/bgm/little_cafe.mp3"))
	#tween.tween_callback(music.play)
	tween.tween_callback(PlayerState.set_on_scene.bind(false))

func enter_stage(entrance : int):
	player.set_position(entrances[entrance])
	if entrance == 1:
		brilho.hide()
