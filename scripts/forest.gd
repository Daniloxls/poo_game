extends Node2D

@onready var player:CharacterBody2D = get_node("Player")
@onready var battle:CanvasLayer = get_node("Battle")
@onready var campones:CharacterBody2D = get_node("Campones")

func _ready() -> void:
	player.connect("BattleStart", battle_phase)
	

func battle_phase()->void:
	battle.start_battle()
	battle.enemy_sprite.texture = campones.sprite.texture
