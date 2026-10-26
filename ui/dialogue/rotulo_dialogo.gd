class_name RotuloDialogo
extends DialogueLabel

const LENTIDAO_SUSSURRO := 0.5

var _sussurros: Array[Vector2i] = []
var _pop := EfeitoPop.new()


func _init() -> void:
	bbcode_enabled = true
	custom_effects = [_pop, EfeitoSussurro.new(), EfeitoGlitch.new()]
	spoke.connect(func(_letra, indice, _vel): _pop.tempos[indice] = Time.get_ticks_msec() / 1000.0)


func _update_text() -> void:
	_pop.tempos.clear()
	if is_instance_valid(dialogue_line):
		text = DialogoBBCode.expandir_code(dialogue_line.text)
		_sussurros = DialogoBBCode.intervalos(dialogue_line.text, "whisper")
	else:
		text = ""
		_sussurros = []


func _get_speed(at_index: int) -> float:
	var vel := super(at_index)
	for r in _sussurros:
		if r.x <= at_index - 1 and at_index - 1 < r.y:
			return vel * LENTIDAO_SUSSURRO
	return vel


func skip_typing() -> void:
	var agora := Time.get_ticks_msec() / 1000.0
	for i in range(visible_characters, get_total_character_count()):
		_pop.tempos[i] = agora
	super()
