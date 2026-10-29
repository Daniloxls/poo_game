extends "res://scenes/main/scripts/interact.gd"


@onready var sprite = $DummySprite

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
