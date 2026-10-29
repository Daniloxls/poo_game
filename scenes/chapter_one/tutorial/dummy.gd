extends "res://scenes/main/scripts/interact.gd"


@onready var porta_colision = $Porta/PortaShape
@onready var porta_sprite = $Porta/PortaSprite
@onready var sprite = $DummySprite

const UP_POSITION = 0
const DOWN_POSITION = 1

func _ready():
	ready_drop_menu()
	area = $Area2D/CollisionShape2D
	colision = $StaticBody2D/Collision

func interaction():
	var turin = Party.get_node("Turin")
	turin.hp = turin.get_max_hp()  # o tutorial começa com Turin inteiro
	Battle.start_battle("res://scenes/encounters/tutorial_dummy.tscn", false)

func _on_tutorial_battle_tutorial_end():
	sprite.hide()
	colision.set_deferred("disabled", true)
	area.set_deferred("disabled", true)
	porta_colision.set_disabled(true)
	porta_sprite.set_frame(DOWN_POSITION)
