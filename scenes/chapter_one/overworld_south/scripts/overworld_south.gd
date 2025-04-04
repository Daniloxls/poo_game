extends Node2D
@onready var player = $Player
@onready var kath: CharacterBody2D = $Path2D/PathFollow2D/Kath
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D

var entrances = [Vector2(11167, -12595)]
# Called when the node enters the scene tree for the first time.
func _ready():
	starting_cutscene()
	Textbox.connect("text_finish", _on_textbox_text_finish)
	MusicPlayer.set_stream(load("res://assets/bgm/Fame Town Marcelo Fernandez.mp3"))
	#MusicPlayer.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func starting_cutscene():
	PlayerState.set_on_scene(true)
	var tween = create_tween()
	tween.tween_callback(player.set_sprite.bind("idle_left"))
	tween.tween_callback(kath.set_sprite.bind("idle_right"))
	tween.tween_callback(kath.play_animation.bind("jump"))
	tween.tween_callback(Textbox.queue_text.bind(["Turin seu boboca!",
	 "Você dormiu demais de novo ?",
	 "A gente tinha combinado de ir pro festival da colheita hoje.",
	 "Vamos, ainda dá tempo de ver a atração principal.",
	 "O último que chegar compra uma fatia de torta pro vencedor!"]))


func _on_textbox_text_finish():
	var tween = create_tween()
	if kath.get_seq() == 0:
		tween.tween_callback(kath.set_sprite.bind("walk_left"))
		tween.tween_property(path_follow_2d, "progress_ratio", 0.104, 0.8).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(kath.set_sprite.bind("walk_up"))
		tween.tween_property(path_follow_2d, "progress_ratio", 0.361, 1.6).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(PlayerState.set_on_scene.bind(false))
		tween.tween_callback(kath.set_sprite.bind("idle_down"))
		kath.set_seq(1)

func enter_stage(entrance : int):
	player.set_position(entrances[entrance])
	
