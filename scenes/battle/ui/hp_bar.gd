class_name HpBar
extends Control
## Barra de vida/PP que se desenha sozinha, com um trecho "fantasma" pálido
## que mostra o dano recém-sofrido e depois drena.

const GHOST := Color("#fff3b0")
const OUTLINE := Color("#1b1b1b")
const SKEW := -12.0

var max_value := 1
var value := 1.0
var ghost_value := 1.0
var fill := Color("#3fae5a")
var _tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(120, 16)


func setup(p_max: int, p_value: int, p_fill: Color) -> void:
	max_value = maxi(p_max, 1)
	value = p_value
	ghost_value = p_value
	fill = p_fill
	queue_redraw()


func set_value(new_value: int) -> void:
	var old := value
	value = new_value
	if _tween:
		_tween.kill()
	if new_value < old:
		_tween = create_tween()
		_tween.tween_interval(0.25)
		_tween.tween_method(_set_ghost, maxf(ghost_value, old), float(new_value), 0.35)
	else:
		ghost_value = new_value
	queue_redraw()


func _set_ghost(v: float) -> void:
	ghost_value = v
	queue_redraw()


## Paralelogramo entre x0 e x1 (0..largura), inclinado SKEW graus.
func _quad(x0: float, x1: float) -> PackedVector2Array:
	var h := size.y - 6.0
	var sk := tan(deg_to_rad(SKEW))
	var p := PackedVector2Array()
	for c in [Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, h), Vector2(x0, h)]:
		p.append(Vector2(3.0 + c.x + sk * (c.y - h / 2.0), 3.0 + c.y))
	return p


func _draw() -> void:
	var w := size.x - 6.0
	draw_colored_polygon(_quad(0.0, w), Color("#3a3f4a"))
	if ghost_value > value:
		draw_colored_polygon(_quad(0.0, w * ghost_value / max_value), GHOST)
	if value > 0:
		draw_colored_polygon(_quad(0.0, w * value / max_value), fill)
	var step := maxi(max_value / 8, 1)
	var v := step
	while v < max_value:
		var x := w * v / max_value
		draw_line(_quad(x, x)[0], _quad(x, x)[3], OUTLINE, 1.0)
		v += step
	var o := _quad(0.0, w)
	o.append(o[0])
	draw_polyline(o, OUTLINE, 3.0)
