class_name EfeitoSussurro
extends RichTextEffect

var bbcode := "whisper"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.color = Color("#8a8a8a")
	char_fx.transform = char_fx.transform.scaled_local(Vector2(0.85, 0.85))
	return true
