extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var brilho = $Brilho
@onready var music =  $"../../AudioPlayer"
var dialogo = ["Muito bem, você conseguiu chegar até mim.",
				"O tolo que projetou essa prisão para mim, designou ela de forma patética.",
				"Até alguem que nunca utilizou programação conseguiu me alcançar.",
				"Quase tão tolo quanto você...",
				"Agora que estou livre vou fazer quem me prendeu aqui pagar...",
				"Ele e toda sua forma de programar pacata!",
				"Adeus NPC patetico!"]
var portraits = ["res://assets/portraits/anti_poo_neutro.png",
				"res://assets/portraits/anti_poo_neutro.png",
				"res://assets/portraits/anti_poo_neutro.png",
				"res://assets/portraits/anti_poo_neutro.png",
				"res://assets/portraits/anti_poo_serio.png",
				"res://assets/portraits/anti_poo_serio.png",
				"res://assets/portraits/anti_poo_serio.png"]
func _ready():
	var tween = create_tween()
	brilho.hide()
	player.set_in_scene(true)
	tween.tween_callback(player.set_animation.bind("walk", "up"))
	tween.tween_property(player, "position", Vector2(9422,9313), 3).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(player.set_animation.bind("idle", "up"))
	tween.tween_callback(textbox.queue_char_text.bind(dialogo, portraits))
	
	music.set_stream(load("res://assets/bgm/qubodup-yd-DarkShrineLoop-OpenGameArt.mp3"))
	music.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_textbox_text_finish():
	var tween = create_tween()
	var root = get_node("../..")
	var next_level = load("res://scenes/interiors/player_room/player_room.tscn")
	var instance = next_level.instantiate()
	tween.tween_callback(brilho.show)
	tween.tween_property(brilho, "scale", Vector2(1200,800), 3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(root.change_level.bind(instance))

func enter_stage(entrance : int):
	pass
