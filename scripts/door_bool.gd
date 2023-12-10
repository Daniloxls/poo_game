extends Node2D

@onready var area = $Area2D
@onready var colision = $StaticBody2D
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")

func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("exit"):
		colision.set_collision_layer_value(1, area.depure()["1boolean trancado"])
		map.set_layer_enabled(2, area.depure()["1boolean trancado"] )
			
		
	pass
