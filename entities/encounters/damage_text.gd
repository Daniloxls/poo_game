extends Node2D


@onready var damage_text = $DamageText
@onready var path = $Path2D
@onready var follow = $Path2D/PathFollow2D
const FONT_POSITION = Vector2(-42,-15)

func display_damage(damage):
	var tween = create_tween()
	damage_text.set_text(str(damage))
	var start = FONT_POSITION
	var middle
	var end
	match(randi_range(1,2)):
		1:
			middle = Vector2 (randi_range(10, 16), randi_range(-8, -16))
			end = Vector2(randi_range(20, 28), 8)
		2:
			middle = Vector2 (randi_range(-10, -16), randi_range(-8, -16))
			end = Vector2(randi_range(-20, -28), 8)
			
	middle += FONT_POSITION
	end += FONT_POSITION
	tween.tween_method(_quadratic_bezier.bind(start, middle, end), 0, 100, 0.4)
	tween.tween_callback(hide)

func _quadratic_bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2):
	t = t/100
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	damage_text.set_position(r)
