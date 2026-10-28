extends "res://scenes/main/scripts/interact.gd"

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var battle = Battle
@onready var inventory = Inventory
@onready var tickets = $"../Tickets"

const DIALOGO = preload("res://scenes/chapter_one/festival_city/dialogos/tatame.dialogue")

enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}
var current_state = State.DOWN
var ganhou := false
var quer_lutar := false   # escrito por tatame.dialogue


# O nó do tatame é um NPC.tscn, sem o MenuButton/Glifos que o _ready de interact.gd espera.
# Não chamar super(): sem esta sobrescrita o jogo para com erro de script ao abrir a cidade.
func _ready():
	pass


func set_sprite(sprite):
	_animated_sprite.play(sprite)

func play_animation(animation):
	animation_player.play(animation)

func get_portraits():
	return portraits

func set_portraits(new_portraits):
	portraits = new_portraits

func update_codigo(new_codigo):
	codigo = new_codigo

func interaction():
	if ganhou:
		await Dialogo.iniciar(DIALOGO, "descansando", [self])
		return
	quer_lutar = false
	await Dialogo.iniciar(DIALOGO, "desafio", [self])
	if quer_lutar:
		tickets.hide()
		battle.start_battle("res://scenes/encounters/muscleguy.tscn")

func name():
	return nome


# A batalha não mostra mais caixa de texto ao terminar: o NPC reage na hora.
func _on_city_battle_won():
	ganhou = true
	tickets.show()
	tickets.recieve_tickets(10)
	await Dialogo.iniciar(DIALOGO, "vitoria", [self])


func _on_city_battle_lost():
	tickets.show()
	inventory.full_heal()
	await Dialogo.iniciar(DIALOGO, "derrota", [self])
