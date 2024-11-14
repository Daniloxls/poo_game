extends CharacterBody2D
class_name Enemy

@onready var sprite:Sprite2D = get_node("Sprite")

@export var name_enemy:String
@export var level:int
@export var max_attack:int
@export var min_attack:int

func _on_detection_body_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.battle_started()
