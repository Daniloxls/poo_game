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


const ESPADA = preload("res://scenes/chapter_one/festival_city/dialogos/espada.dialogue")


func _cena(n: int) -> void:
	await Dialogo.iniciar(ESPADA, "cena_%d" % n)


# Não bloqueia quem chama (excalibur_npc não dá await).
func play():
	PlayerState.set_on_scene(true)
	camera_fade_out()
	await get_tree().create_timer(2.5).timeout
	player.set_position(Vector2(-7, -38213))
	camera_fade_in()
	MusicPlayer.set_stream(load("res://assets/bgm/qubodup-yd-DarkShrineLoop-OpenGameArt.mp3"))
	await _cena(1)

	var npc_spin = create_tween()
	npc_spin.pause()
	npc_spin.set_loops()
	npc_spin.tween_property(npc, "rotation", 360, 1)
	npc_spin.tween_property(npc, "rotation", 0, 0)
	fire.show()
	fire.play("default")
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(fire, "position", fire.get_position() + Vector2(-750, 0), 0.2)
	tween.tween_callback(fire.hide)
	tween.tween_callback(npc_spin.play)
	tween.tween_property(npc, "position", npc.get_position() + Vector2(-5800, 0), 1)
	tween.tween_callback(MusicPlayer.play)
	tween.tween_callback(anti_poo.play.bind("walk_down"))
	tween.tween_property(anti_poo, "position", anti_poo.get_position() + Vector2(0, 1530), 3)
	tween.tween_callback(anti_poo.play.bind("default"))
	await tween.finished
	await _cena(2)

	anti_poo.z_index = 3
	anti_poo.play("grabbing_sword")
	await _cena(3)

	await get_tree().create_timer(1.0).timeout
	anti_poo.z_index = 0
	camera_flash()
	anti_poo.play("holding_sword")
	stone.play("broken")
	espada.hide()
	await _cena(4)

	camera_flash()
	anti_poo.play("default")
	await get_tree().create_timer(1.0).timeout
	await _cena(5)

	var tween_a = create_tween()
	var tween_b = create_tween()
	magic.show()
	magic.play("default")
	kath.play("run_left")
	tween_a.set_parallel(true)
	tween_a.tween_property(magic, "scale", Vector2(4, 4), 1.5)
	tween_a.tween_property(magic, "position", magic.get_position() + Vector2(0, 2000), 3).set_ease(Tween.EASE_OUT)
	tween_a.tween_property(black_screen, "color", Color("#ffffff"), 1.8)
	tween_b.tween_property(kath, "position", kath.get_position() + Vector2(-900, 0), 0.65).set_ease(Tween.EASE_OUT)
	tween_b.tween_callback(kath.play.bind("jump"))
	tween_b.tween_property(kath, "position", kath.get_position() + Vector2(-1800, 0), 1.25).set_ease(Tween.EASE_OUT)
	await tween_a.finished
	await _cena(6)

	await get_tree().create_timer(2.0).timeout
	black_screen.color = Color("#000000")
	await _cena(7)
	continua.show()


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
