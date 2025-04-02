extends Node2D

var totens_ativos:bool = false

@onready var porta:StaticBody2D = get_node("Porta")
@onready var porteiro:CharacterBody2D = get_node("Porteiro")
@onready var player:CharacterBody2D = get_node("Player")
@onready var totem_red:StaticBody2D = get_node("TotemVermelho")
@onready var totem_yellow:StaticBody2D = get_node("TotemAmarelo")
@onready var totem_blue:StaticBody2D = get_node("TotemAzul")
@onready var totem_green:StaticBody2D = get_node("TotemVerde")

func _ready() -> void:
	player.current_state = States.Player_State.FREE
	player.get_state()

func check_totem(nome:String)->void:
	match nome:
		"TotemVerde":
			if totem_green.ativado:
				if !totem_yellow.ativado and !totem_red.ativado and !totem_blue.ativado:
					return
				else:
					totem_yellow.ativado = false
					totem_blue.ativado = false
					totem_red.ativado = false
					
					totem_red.animation_totem()
					totem_blue.animation_totem()
					totem_yellow.animation_totem()
				
		"TotemAmarelo":
			if totem_yellow.ativado:
				if totem_green.ativado and totem_red.ativado:
					return
				else :
					totem_blue.ativado = false
					totem_green.ativado = false
					totem_red.ativado = false
					
					totem_red.animation_totem()
					totem_green.animation_totem()
					totem_blue.animation_totem()
			
		"TotemAzul":
			if totem_blue.ativado:
				if totem_green.ativado and totem_red.ativado and totem_yellow.ativado:
					return
				else:
					totem_yellow.ativado = false
					totem_green.ativado = false
					totem_red.ativado = false
					
					totem_red.animation_totem()
					totem_yellow.animation_totem()
					totem_green.animation_totem()
				
		"TotemVermelho":
			if totem_red.ativado:
				if totem_green.ativado:
					return
				else:
					totem_yellow.ativado = false
					totem_green.ativado = false
					totem_blue.ativado = false
					
					totem_blue.animation_totem()
					totem_yellow.animation_totem()
					totem_green.animation_totem()

func finish_puzzle()->void:
	if totem_red.ativado and totem_blue.ativado and totem_yellow.ativado and totem_green.ativado:
		totens_ativos = true
		porteiro.scene = true
		porta.get_child(0).disabled = true
