class_name ChecklistHud
extends CanvasLayer
## Checklist do tutorial no canto: os testes do log de abertura, marcados um a um.

signal marcou(id: String)
signal completou

const ITENS_TESTE := ["andar", "interagir", "correr", "lutar", "usarItem"]
const FONTE := preload("res://assets/fonts/JetBrainsMono.ttf")
const SOM := preload("res://assets/sounds/interface/kenney/confirmar.ogg")
const CORES := {"m": "#60a5fa", "ok": "#4ade80", "av": "#f87171", "d": "#9ca3af"}  # as da abertura

var _marcados: Array[String] = []
var _erro := false
var _lista: RichTextLabel
var _aviso: Label
var _msg: Label
var _som: AudioStreamPlayer


func _init() -> void:
	layer = 5
	var painel := PanelContainer.new()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("#05070d", 0.85)
	fundo.set_content_margin_all(8)
	painel.add_theme_stylebox_override("panel", fundo)
	painel.position = Vector2(16, 16)
	add_child(painel)
	var caixa := VBoxContainer.new()
	painel.add_child(caixa)

	_lista = RichTextLabel.new()
	_lista.bbcode_enabled = true
	_lista.fit_content = true
	_lista.autowrap_mode = TextServer.AUTOWRAP_OFF
	_lista.scroll_active = false
	_lista.add_theme_font_override("normal_font", FONTE)
	_lista.add_theme_font_size_override("normal_font_size", 16)
	_lista.add_theme_color_override("default_color", Color(CORES.d))
	caixa.add_child(_lista)
	_aviso = _rotulo(CORES.av)
	_aviso.text = "aviso: acesso desconhecido em 0x00DEEP"
	caixa.add_child(_aviso)
	_msg = _rotulo(CORES.d)
	caixa.add_child(_msg)

	_som = AudioStreamPlayer.new()
	_som.stream = SOM
	add_child(_som)
	_atualizar()


func marcar(id: String) -> void:
	if not id in ITENS_TESTE or marcado(id):
		return
	_marcados.append(id)
	_atualizar()
	_som.play()
	_lista.modulate = Color(2, 2, 2)  # flash curto
	create_tween().tween_property(_lista, "modulate", Color.WHITE, 0.3)
	marcou.emit(id)
	if completo():
		completou.emit()


func marcado(id: String) -> bool:
	return id in _marcados


func completo() -> bool:
	return _marcados.size() == ITENS_TESTE.size()


func texto() -> String:
	return _linha(false)


func mostrar_erro() -> void:
	_erro = true
	_atualizar()


func piscar_aviso() -> void:
	_aviso.visible = true
	create_tween().tween_callback(_aviso.hide).set_delay(0.6)


func mensagem(texto: String) -> void:
	_msg.text = "> " + texto
	_msg.visible = true


func _atualizar() -> void:
	_lista.text = _linha(true)


# Linha em texto puro ou com cores (bbcode).
func _linha(bb: bool) -> String:
	var lb := "[lb]" if bb else "["
	var partes := []
	for id in ITENS_TESTE:
		var nome: String = "[color=%s]%s[/color]()" % [CORES.m, id] if bb else id + "()"
		if marcado(id):
			var ok := "%s✓]" % lb
			partes.append(("[color=%s]%s[/color] " % [CORES.ok, ok] if bb else ok + " ") + nome)
		else:
			partes.append(lb + " ] " + nome)
	var s := "  ".join(partes)
	if _erro:
		s += "  [color=%s]%s!] turin.cair()[/color]" % [CORES.av, lb] if bb else "  [!] turin.cair()"
	return s


func _rotulo(cor: String) -> Label:
	var l := Label.new()
	l.visible = false
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(cor))
	return l
