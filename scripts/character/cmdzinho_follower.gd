extends "res://scripts/npc_script.gd"

@onready var player_target:CharacterBody2D = get_parent().find_child("Player")
@onready var animation_cmdzinho:AnimationPlayer = get_node("Animation")
@onready var texture:Sprite2D = get_node("Sprite")

var speed:float = 500.0

func _physics_process(_delta: float) -> void:
	animation()
	calculate_velocity()
	move_and_slide()

func calculate_velocity()->void:
	var distance_to_target:int = 600
	var target_position = player_target.position - Vector2(0,-9)
	if position.distance_to(target_position) > distance_to_target:
		var direction_player = (target_position - position).normalized()
		velocity = direction_player * (speed * 7)
	else:
		velocity = Vector2(0,0)

func animation()->void:
	if velocity.x != 0:
		animation_cmdzinho.play("side")
		if velocity.x > 0:
			texture.flip_h = false
		elif velocity.x < 0:
			texture.flip_h = true
	
	
