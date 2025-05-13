extends Node2D

@onready var player = get_node("../Player")
@onready var anti_poo = $AntiPOO
@onready var espada = $Espada
@onready var black_screen = $BlackScreen/ColorRect
@onready var fire = $Fire
@onready var stone = $Stone
@onready var npc = $NpcChutado
@onready var magic = $Magic
@onready var kath = $Kath
@onready var continua = $BlackScreen/Label

var dialogue = [["Certo Turin depois do Nicolas é a sua vez!", "Permitam-me pular na frente."],
["O rei realmente ficou desleixado, deixando uma arma tão importante nas mãos de pessoas insignificantes."],
["Vamos ao primeiro passo da minha vingança!"],
["Essa espada me trás lembranças nada agradáveis.", "Vamos garantir que ela não caia nas mãos de mais ninguém."],
["Hm...", "Enquanto a você...", "Devo estar perdendo meu jeito.", "Vou garantir que você não se recupere dessa!"],
["Turin, cuidado!"],
["Turin! Turin!", "Acorda, a gente precisa sair daqui!"]]
var portraits = [["","res://assets/portraits/silhueta.png"],
["res://assets/portraits/anti_poo_neutro.png"],
["res://assets/portraits/anti_poo_serio.png"],
["res://assets/portraits/anti_poo_neutro.png", "res://assets/portraits/anti_poo_serio.png"],
["res://assets/portraits/anti_poo_neutro.png","res://assets/portraits/anti_poo_neutro.png","res://assets/portraits/anti_poo_neutro.png", "res://assets/portraits/anti_poo_serio.png"],
[""],
["", ""]]
var event_seq = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_seq(num):
	event_seq = num
	
func play():
	var tween = create_tween()
	PlayerState.set_on_scene(true)
	event_seq = -1
	camera_fade_out()
	tween.tween_interval(2.5)
	tween.tween_callback(player.set_position.bind(Vector2(-7,-38213)))
	tween.tween_callback(camera_fade_in)
	tween.tween_callback(Textbox.queue_char_text.bind(dialogue[0], portraits[0]))
	MusicPlayer.set_stream(load("res://assets/bgm/qubodup-yd-DarkShrineLoop-OpenGameArt.mp3"))
	tween.tween_callback(set_seq.bind(1))
func camera_fade_out():
	var tween = create_tween()
	tween.tween_property(black_screen,"color" , Color("#000000"), 2)
	
func camera_fade_in():
	var tween = create_tween()
	tween.tween_property(black_screen, "color", Color("#00000000"), 2)

func camera_flash():
	var tween = create_tween()
	tween.tween_property(black_screen, "color", Color("#ffffff00"), 0)
	tween.tween_property(black_screen, "color", Color("#ffffff"), 0.2)
	tween.tween_property(black_screen, "color", Color("#ffffff00"), 0.1)
	
func _on_textbox_text_finish():
	if event_seq == 1:
		event_seq = -1
		var tween = create_tween()
		var npc_spin = create_tween()
		npc_spin.pause()
		npc_spin.set_loops()
		npc_spin.tween_property(npc, "rotation", 360, 1)
		npc_spin.tween_property(npc, "rotation", 0, 0)
		fire.show()
		fire.play("default")
		tween.tween_interval(0.5)
		tween.tween_property(fire, "position", fire.get_position() + Vector2(-750, 0), 0.2)
		tween.tween_callback(fire.hide)
		tween.tween_callback(npc_spin.play)
		tween.tween_property(npc, "position", npc.get_position() + Vector2(-5800, 0), 1)
		tween.tween_callback(MusicPlayer.play)
		tween.tween_callback(anti_poo.play.bind("walk_down"))
		tween.tween_property(anti_poo, "position", anti_poo.get_position() + Vector2(0,1530),3)
		tween.tween_callback(anti_poo.play.bind("default"))
		tween.tween_callback(Textbox.queue_char_text.bind(dialogue[1], portraits[1]))
		tween.tween_callback(set_seq.bind(2))
	elif event_seq == 2:
		var tween = create_tween()
		event_seq = -1
		tween.tween_property(anti_poo, "z_index", 3, 0)
		tween.tween_callback(anti_poo.play.bind("grabbing_sword"))
		tween.tween_callback(Textbox.queue_char_text.bind(dialogue[2], portraits[2]))
		tween.tween_callback(set_seq.bind(3))
	elif event_seq == 3:
		var tween = create_tween()
		event_seq = -1
		tween.tween_interval(1)
		tween.tween_property(anti_poo, "z_index", 0, 0)
		tween.tween_callback(camera_flash)
		tween.tween_callback(anti_poo.play.bind("holding_sword"))
		tween.tween_callback(stone.play.bind("broken"))
		tween.tween_callback(espada.hide)
		tween.tween_callback(Textbox.queue_char_text.bind(dialogue[3], portraits[3]))
		tween.tween_callback(set_seq.bind(4))
	elif event_seq == 4:
		event_seq = -1
		var tween = create_tween()
		tween.tween_callback(camera_flash)
		tween.tween_callback(anti_poo.play.bind("default"))
		tween.tween_interval(1)
		tween.tween_callback(Textbox.queue_char_text.bind(dialogue[4], portraits[4]))
		tween.tween_callback(set_seq.bind(5))
	elif event_seq == 5:
		event_seq = -1
		var tween_a = create_tween()
		var tween_b = create_tween()
		tween_a.tween_callback(magic.show)
		tween_a.tween_callback(magic.play.bind("default"))
		tween_a.tween_property(magic, "scale", Vector2(4, 4), 1.5)
		tween_b.tween_callback(kath.play.bind("run_left"))
		tween_a.set_parallel(true)
		tween_a.tween_property(magic, "position", magic.get_position() + Vector2(0,2000), 3).set_ease(Tween.EASE_OUT)
		tween_b.tween_property(kath, "position", kath.get_position() + Vector2(-900, 0), 0.65).set_ease(Tween.EASE_OUT)
		tween_b.tween_callback(kath.play.bind("jump"))
		tween_b.tween_property(kath, "position", kath.get_position() + Vector2(-1800, 0), 1.25).set_ease(Tween.EASE_OUT)
		tween_a.tween_property(black_screen, "color", Color("#ffffff"), 1.8)
		tween_a.tween_callback(Textbox.queue_char_text.bind(dialogue[5], portraits[5]))
		tween_a.tween_callback(tween_a.set_parallel.bind(false))
		tween_a.tween_callback(set_seq.bind(6))
	elif event_seq == 6:
		event_seq = -1
		var tween = create_tween()
		tween.tween_interval(2)
		tween.tween_property(black_screen, "color", Color("#000000"), 0)
		tween.tween_callback(Textbox.queue_char_text.bind(dialogue[6], portraits[6]))
		tween.tween_callback(set_seq.bind(7))
	elif event_seq == 7:
		continua.show()
