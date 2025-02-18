extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var kath = $Kath
@onready var music =  $"../../AudioPlayer"
var entrances = [Vector2(11156, -4642)]
# Called when the node enters the scene tree for the first time.
func _ready():
	starting_cutscene()
	music.set_stream(load("res://assets/bgm/Fame Town Marcelo Fernandez.mp3"))
	music.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func starting_cutscene():
	player.set_in_scene(true)
	var tween = create_tween()
	tween.tween_callback(player.set_sprite.bind("idle_left"))
	tween.tween_callback(kath.set_sprite.bind("idle_right"))
	tween.tween_callback(kath.play_animation.bind("jump"))
	tween.tween_callback(textbox.queue_text.bind(["Turin seu boboca!",
	 "Você dormiu demais de novo ?",
	 "A gente tinha combinado de ir pro festival da colheita hoje.",
	 "Vamos, ainda dá tempo de ver a atração principal.",
	 "O último que chegar compra uma fatia de torta pro vencedor!"]))


func _on_textbox_text_finish():
	var tween = create_tween()
	if kath.get_seq() == 0:
		tween.tween_callback(kath.set_sprite.bind("walk_left"))
		tween.tween_property(kath, "position", Vector2(6000,-4500), 1.6).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(kath.set_sprite.bind("walk_up"))
		tween.tween_property(kath, "position", Vector2(6000,-8000), 1.6).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(player.set_in_scene.bind(false))
		tween.tween_callback(kath.set_position.bind(Vector2(5200, -10300)))
		tween.tween_callback(kath.set_sprite.bind("idle_down"))
		kath.set_seq(1)

func enter_stage(entrance : int):
	player.set_position(entrances[entrance])
	
