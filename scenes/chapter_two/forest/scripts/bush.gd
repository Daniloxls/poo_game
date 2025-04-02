extends "res://scripts/interact.gd"

@onready var animation:AnimationPlayer = get_node("Animation")

func burn()->void:
	animation.play("burn")

func delete()->void:
	var tween:Tween = create_tween()
	await tween.tween_property(self,"modulate:A",0.3,1)
	queue_free()
