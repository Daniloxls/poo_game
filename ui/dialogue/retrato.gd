class_name RetratoDialogo
extends Control
## Busto do personagem na caixa de diálogo. Só se move quando chamado.

const DESLOCAMENTO := 80.0

var personagem: Personagem
var expressao: String = ""
var em_animacao: bool:
	get:
		for t in [_t_pos, _t_escala, _t_flash]:
			if t and t.is_running():
				return true
		return false

var _repouso := Vector2.ZERO
var _afundado := false
var _escondendo := false
var _t_pos: Tween
var _t_escala: Tween
var _t_flash: Tween

@onready var _imagem: TextureRect = %Imagem


func _ready() -> void:
	visible = false
	resized.connect(func():
		pivot_offset = Vector2(size.x / 2.0, size.y)
		_usar(_imagem.texture))
	pivot_offset = Vector2(size.x / 2.0, size.y)


func mostrar(p: Personagem, exp: String) -> void:
	if p == personagem and visible and not _escondendo:
		trocar_expressao(exp)
		return
	var tinha := personagem != null and visible and not _escondendo
	_parar()
	personagem = p
	expressao = exp
	if not tinha:
		_usar(p.retrato(exp) if p else null)
	visible = p != null
	if not visible:
		return
	if tinha:
		_t_pos = create_tween()
		_t_pos.tween_property(self, "position:x", _repouso.x - DESLOCAMENTO, 0.1)
		_t_pos.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
		_t_pos.tween_callback(func(): _usar(p.retrato(exp)))
		_t_pos.tween_callback(func(): position.x = _repouso.x - DESLOCAMENTO)
	else:
		position.x = _repouso.x - DESLOCAMENTO
		modulate.a = 0.0
		_t_pos = create_tween()
	_t_pos.tween_property(self, "position:x", _repouso.x, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_t_pos.parallel().tween_property(self, "modulate:a", 1.0, 0.2)


func esconder() -> void:
	if personagem == null:
		return
	_parar()
	_escondendo = true
	_t_pos = create_tween()
	_t_pos.tween_property(self, "position:x", _repouso.x - DESLOCAMENTO, 0.2).set_ease(Tween.EASE_IN)
	_t_pos.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	_t_pos.tween_callback(func():
		_escondendo = false
		personagem = null
		visible = false
		position = _repouso)


func trocar_expressao(exp: String) -> void:
	if personagem == null:
		return
	expressao = exp
	var nova := personagem.retrato(exp)
	if nova == _imagem.texture:
		return
	_usar(nova)
	if _t_escala:
		_t_escala.kill()
	_t_escala = create_tween()
	_t_escala.tween_property(self, "scale", Vector2(1.12, 0.88), 0.07)
	_t_escala.tween_property(self, "scale", Vector2(0.96, 1.05), 0.1)
	_t_escala.tween_property(self, "scale", Vector2.ONE, 0.13)
	if _t_flash:
		_t_flash.kill()
	_imagem.material.set_shader_parameter("brilho", 0.7)
	_t_flash = create_tween()
	_t_flash.tween_property(_imagem.material, "shader_parameter/brilho", 0.0, 0.25)


func animar(nome: String) -> void:
	if not nome in ["hop", "shake", "slump"]:
		push_warning("Animação de retrato desconhecida: " + nome)
		return
	if personagem == null:
		return
	_parar()
	_t_pos = create_tween()
	match nome:
		"hop":
			_t_pos.tween_property(self, "position:y", _repouso.y - 40.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_t_pos.tween_property(self, "position:y", _repouso.y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_t_pos.tween_property(self, "scale", Vector2(1.15, 0.85), 0.05)
			_t_pos.tween_property(self, "scale", Vector2.ONE, 0.05)
		"shake":
			for i in 4:
				var s := 1.0 if i % 2 == 0 else -1.0
				_t_pos.tween_property(self, "position:x", _repouso.x + 10.0 * s, 0.05)
				_t_pos.parallel().tween_property(self, "rotation", 0.05 * s, 0.05)
				_t_pos.tween_property(self, "position:x", _repouso.x - 10.0 * s, 0.05)
				_t_pos.parallel().tween_property(self, "rotation", -0.05 * s, 0.05)
			_t_pos.tween_property(self, "position:x", _repouso.x, 0.05)
			_t_pos.parallel().tween_property(self, "rotation", 0.0, 0.05)
		"slump":
			_afundado = true
			_t_pos.tween_property(self, "position:y", _repouso.y + 30.0, 0.5)
			_t_pos.parallel().tween_property(self, "rotation", 0.12, 0.5)
			_t_pos.parallel().tween_property(_imagem.material, "shader_parameter/saturacao", 0.2, 0.5)


func resetar_pose() -> void:
	if not _afundado:
		return
	_parar()
	_t_pos = create_tween()
	_t_pos.tween_property(self, "position", _repouso, 0.4)
	_t_pos.parallel().tween_property(self, "rotation", 0.0, 0.4)
	_t_pos.parallel().tween_property(_imagem.material, "shader_parameter/saturacao", 1.0, 0.4)


## Mata animações em curso e volta ao repouso (guardado quando parado).
func _parar() -> void:
	if not em_animacao and not _afundado:
		_repouso = position
	for t in [_t_pos, _t_escala, _t_flash]:
		if t:
			t.kill()
	_afundado = false
	_escondendo = false
	position = _repouso
	rotation = 0.0
	scale = Vector2.ONE
	modulate.a = 1.0
	_imagem.material.set_shader_parameter("brilho", 0.0)
	_imagem.material.set_shader_parameter("saturacao", 1.0)
	# Uma troca de personagem interrompida (ex.: animar() logo após mostrar())
	# não pode deixar a arte do anterior na tela.
	if personagem:
		_usar(personagem.retrato(expressao))


## Troca a arte e apoia a imagem no pé do busto: a altura da área desenhada
## segue a proporção da textura, então toda arte fica na mesma linha de base.
func _usar(t: Texture2D) -> void:
	_imagem.texture = t
	var h := size.y
	if t:
		h = minf(size.y, size.x * t.get_height() / t.get_width())
	_imagem.offset_top = size.y - h
