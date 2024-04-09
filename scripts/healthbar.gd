extends Node2D

# healthbar é o script que mosta a vida dos inimigos quando eles tomam dano
# tambem é responsavel por mostrar o numero do dano da mesma forma que DamageText
# Esse scrip junta os dois em uma animação só e é usado para os inimigos apenas
signal animation_end

@onready var green_bar = $Green 
@onready var damage_text = $DamageText
@onready var path = $Path2D
@onready var follow = $Path2D/PathFollow2D
const FONT_POSITION = Vector2(-23,-9)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func change_hp_percent(percentage, damage):
	var tween = create_tween()
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
	damage_text.set_text(str(damage))
	tween.set_parallel()
	tween.tween_property(green_bar, "scale", Vector2(percentage, 1), 0.8)
	tween.tween_method(_quadratic_bezier.bind(start, middle, end)
	,0, 100, 0.4)
	tween.set_parallel(false)
	tween.tween_property(green_bar, "scale", Vector2(percentage, 1), 0.3)
	tween.tween_callback(hide)
	tween.tween_callback(end_animation)

func end_animation():
	animation_end.emit()

func _quadratic_bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2):
	t = t/100
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	damage_text.set_position(r)
