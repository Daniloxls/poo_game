extends Control
## Tela de título: cena principal. Novo Jogo leva à abertura; Continuar e Créditos ainda não existem.

const ABERTURA := "res://scenes/chapter_one/opening/Abertura.tscn"
const MUSICA := preload("res://assets/bgm/Dream Eliot Corley.mp3")
const SONS := {
	"clique": preload("res://assets/sounds/interface/kenney/clique.ogg"),
	"confirmar": preload("res://assets/sounds/interface/kenney/confirmar.ogg"),
	"voltar": preload("res://assets/sounds/interface/kenney/voltar.ogg"),
}
const AMARELO := Color("#ffd23f")
const CINZA := Color(0.5, 0.5, 0.5)
const SETA := "▶ "
# texto, habilitado
const ITENS := [["Novo Jogo", true], ["Continuar", false], ["Opções", true], ["Créditos", false]]

var trocar: Callable = LevelWarp.change_level
var _saindo := false
var _botoes: Array[Button] = []
var _silencio := true  # o foco inicial não toca som

@onready var menu: VBoxContainer = %Menu
@onready var opcoes: Control = %Opcoes
@onready var som: AudioStreamPlayer = $Som


func _ready() -> void:
	PlayerState.set_on_interface(true)
	MusicPlayer.stream = MUSICA
	MusicPlayer.play()
	for item in ITENS:
		var b := Button.new()
		b.text = item[0]
		b.flat = true
		b.disabled = not item[1]
		b.focus_mode = Control.FOCUS_ALL if item[1] else Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 30)
		for cor in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(cor, AMARELO)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_disabled_color", CINZA)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.focus_entered.connect(_ao_focar.bind(b))
		b.focus_exited.connect(func() -> void: b.text = b.text.trim_prefix(SETA))
		b.mouse_entered.connect(func() -> void: if not b.disabled and not opcoes.visible: b.grab_focus())
		menu.add_child(b)
		_botoes.append(b)
	_botoes[0].pressed.connect(novo_jogo)
	_botoes[2].pressed.connect(_abrir_opcoes)
	_botoes[0].grab_focus()
	_silencio = false


func botoes() -> Array[Button]:
	return _botoes


func novo_jogo() -> void:
	if _saindo:
		return
	_saindo = true
	_tocar("confirmar")
	trocar.call(ABERTURA)


func _ao_focar(b: Button) -> void:
	b.text = SETA + b.text.trim_prefix(SETA)
	if not _silencio:
		_tocar("clique")


func _abrir_opcoes() -> void:
	_tocar("confirmar")
	menu.hide()
	opcoes.show()
	opcoes.abrir_tela(null)


func _unhandled_input(e: InputEvent) -> void:
	if opcoes.visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_tocar("voltar")
		opcoes.hide()
		menu.show()
		_silencio = true
		_botoes[2].grab_focus()
		_silencio = false


func _tocar(nome: String) -> void:
	som.stream = SONS[nome]
	som.play()
