class_name EfeitoGlitch
extends RichTextEffect

var bbcode := "glitch"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var fase := fposmod(char_fx.elapsed_time + char_fx.range.x * 0.13, 2.4)
	if fase < 0.1:
		var par := int(fase / 0.025) % 2 == 0
		char_fx.offset += Vector2(2, 0) if par else Vector2(-2, 0)
		char_fx.color = Color("#e8463a") if par else Color("#2ec4d6")
	return true
