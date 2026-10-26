class_name EfeitoPop
extends RichTextEffect

var bbcode := "pop"
## indice da letra -> segundo (Time) em que foi revelada; compartilhado com o RotuloDialogo.
var tempos := {}


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.color = Color("#e8463a")
	var s := 1.25
	var t0: float = tempos.get(char_fx.range.x, -1.0)
	if t0 >= 0.0:
		var k := (Time.get_ticks_msec() / 1000.0 - t0) / 0.25
		if k < 1.0:
			s += 0.35 * (1.0 - k) * cos(k * TAU)
	char_fx.transform = char_fx.transform.scaled_local(Vector2(s, s))
	return true
