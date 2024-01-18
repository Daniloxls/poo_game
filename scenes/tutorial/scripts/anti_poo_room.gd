extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var brilho = $Brilho

var dialogo = ["Muito bem, você conseguiu chegar até mim",
				"O tolo que projetou essa prisão para mim designou ela de forma patetica",
				"Até alguem que nunca utilizou programação conseguiu me alcançar",
				"Quase tão tolo quanto você...",
				"Agora que estou livre vou fazer quem me prendeu aqui pagar",
				"Ele e toda sua forma de programar pacata!",
				"Adeus NPC patetico"]
var portraits = ["res://assets/portraits/feliz.png",
				"res://assets/portraits/neutro.png",
				"res://assets/portraits/neutro.png",
				"res://assets/portraits/feliz.png",
				"res://assets/portraits/raiva.png",
				"res://assets/portraits/raiva.png",
				"res://assets/portraits/feliz.png"]
func _ready():
	var tween = create_tween()
	brilho.hide()
	player.set_in_scene(true)
	tween.tween_callback(player.set_animation.bind("walk", "up"))
	tween.tween_property(player, "position", Vector2(310,322), 3).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(player.set_animation.bind("idle", "up"))
	tween.tween_callback(textbox.queue_char_text.bind(dialogo, portraits))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_textbox_text_finish():
	var tween = create_tween()
	tween.tween_callback(brilho.show)
	tween.tween_property(brilho, "scale", Vector2(60,30), 3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(get_tree().change_scene_to_file.bind("res://scenes/player_room.tscn"))
	pass # Replace with function body.
