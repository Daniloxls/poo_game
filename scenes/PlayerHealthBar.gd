extends Node2D
@onready var hp_a = $Life1
@onready var hp_b = $Life2
@onready var hp_c = $Life3
@onready var hp_d = $Life4

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_health_instant(id, percentage):
	var tween = create_tween()
	match(id):
		0:
			hp_a.set_scale(Vector2(percentage, 1))
		1:
			hp_b.set_scale(Vector2(percentage, 1))
		2:
			hp_c.set_scale(Vector2(percentage, 1))
		3:
			hp_d.set_scale(Vector2(percentage, 1))

func update_health_slow(id, percentage):
	var tween = create_tween()
	match(id):
		0:
			tween.tween_property(hp_a, "scale", Vector2(percentage, 1), 0.8)
		1:
			tween.tween_property(hp_b, "scale", Vector2(percentage, 1), 0.8)
		2:
			tween.tween_property(hp_c, "scale", Vector2(percentage, 1), 0.8)
		3:
			tween.tween_property(hp_d, "scale", Vector2(percentage, 1), 0.8)
