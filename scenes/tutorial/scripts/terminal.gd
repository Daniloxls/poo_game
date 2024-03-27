extends Node2D

@onready var area = $Area2D
@onready var colision = $StaticBody2D
@onready var textbox = get_node("../Textbox")
@onready var player = get_node("../Player")
@onready var player_sprite = get_node("../Player/AnimatedSprite2D")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")
var nome = ""
var texto
var codigo = {}
var portraits
var sudo = false
var anim = false
var depuring = false
var active = false
func _ready():
	pass
	
func _process(delta):
	pass


func interaction():
	if !active:
		active = true
		textbox.queue_char_text(["Certo, tente digitar 'sudo' nesse teclado e apertar enter",
		"tec tec tec...",
		"Digite a senha para ativar o sudo:",
		"...",
		"...",
		"Pelo que eu me lembro a senha era senha123",
		"Digite a senha para ativar o sudo: senha123",
		"Acesso garantido",
		"Ativando permissões de sudo"],
		
		["res://assets/portraits/silhueta.png",
		"",
		"",
		"",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"",
		"",
		 "",])
	else:
		textbox.queue_char_text(["Modo sudo ativado"], [""])

func set_texto(new_texto):
	texto = new_texto
	
	
func set_portraits(new_portraits):
	portraits = new_portraits
	
func set_codigo(new_nome, new_codigo):
	nome = new_nome
	codigo = new_codigo

func update_codigo(new_codigo):
	codigo = new_codigo
	
func depure():
	depuring = true
	return codigo
	
func name():
	return nome

func sudo_scene():
	player.set_movement(false)
	var tween = create_tween()
	tween.tween_property(player_sprite, "modulate", Color.GREEN, 1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(player_sprite, "scale", Vector2(3, 1), 1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(player_sprite, "scale", Vector2(1, 3), 1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(player_sprite, "scale", Vector2(1, 1), 1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(player_sprite, "rotation", 360, 2).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(player_sprite, "rotation", 0, 1).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(player_sprite, "modulate", Color.WHITE, 1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(player.set_movement.bind(true))
	tween.tween_callback(player.set_sudo.bind(true))
	tween.tween_callback(set_sudo.bind(true))
	
func _on_textbox_text_finish():
	if active and !sudo:
		sudo_scene()

func set_sudo(mode):
	sudo = mode
