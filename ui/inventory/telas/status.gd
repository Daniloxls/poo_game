extends MarginContainer
## Carta de status: frente no estilo JRPG, verso com o personagem em Java.
## O { } vira a carta; o verso acompanha o jogo mesmo quando está escondido.
## Ocupa a área toda do menu, como as outras seções.

const TAMANHO := Vector2(460, 500)  # carta compacta (a troca de classe usa)

var carta: Control
var frente: PanelContainer
var verso: PanelContainer
var codigo: RichTextLabel
var botao_virar: Button
var virada := false
var _p
var _tween: Tween


func _ready() -> void:
	carta = Control.new()
	frente = UiInv.painel()
	verso = UiInv.codigo()
	verso.theme_type_variation = &"InvVerso"  # borda clara, combina com o creme
	codigo = verso.get_node("Codigo")
	codigo.add_theme_font_size_override("normal_font_size", 17)
	for face in [frente, verso]:
		face.set_anchors_preset(Control.PRESET_FULL_RECT)
		carta.add_child(face)
	verso.hide()
	botao_virar = Button.new()
	botao_virar.text = "{ }"
	botao_virar.theme_type_variation = &"InvCelula"
	botao_virar.add_theme_font_override("font", BattleFonts.mono())
	botao_virar.pressed.connect(virar)
	carta.add_child(botao_virar)
	carta.resized.connect(func():
		carta.pivot_offset = carta.size / 2
		botao_virar.position = Vector2(carta.size.x - botao_virar.size.x - 18, 16))
	add_child(carta)
	Inventory.mudou.connect(_atualizar)


func abrir_tela(p) -> void:
	_p = p
	if virada:
		virada = false
		frente.show()
		verso.hide()
	_atualizar()
	botao_virar.grab_focus()


func virar() -> void:
	Inventory.tocar("virar")
	virada = not virada
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(carta, "scale:x", 0.0, 0.25).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func():
		frente.visible = not virada
		verso.visible = virada)
	_tween.tween_property(carta, "scale:x", 1.0, 0.25).set_ease(Tween.EASE_OUT)


func _atualizar() -> void:
	if _p == null or not is_instance_valid(_p):
		return
	preencher_frente(frente, _p, true)
	var linhas := CodigoJava.verso(_p, Progresso.estagio(), Progresso.tem("metodos"))
	var bb := linhas.map(CodigoJava.colorir)
	if not Progresso.tem("heranca"):  # Personagem fica apagado até a Herança
		bb[0] = bb[0].replace(CodigoJava.C_TIPO, CodigoJava.C_COMENTARIO)
	codigo.text = "\n".join(bb)


## Habilidade escrita como método: invadir(Inimigo alvo); a descrição aparece no mouse.
static func _metodo(h: SKILL) -> Button:
	var params := PackedStringArray()
	for tipo in h.get_target_argument():
		params.append(tipo + " alvo")
	var b := Button.new()
	b.text = "%s(%s)" % [BattleContext.method_name(h), ", ".join(params)]
	b.tooltip_text = h.get_description()
	b.theme_type_variation = &"InvCelula"
	b.custom_minimum_size.y = 44
	b.add_theme_font_override("font", BattleFonts.mono())
	b.add_theme_font_size_override("font_size", 16)
	return b


## A frente da carta; a troca de classe usa a compacta, o Status a larga (duas colunas).
static func preencher_frente(painel: Control, p, larga := false) -> void:
	UiInv.limpar(painel)
	var esq := UiInv.caixa(true, 12)
	var dir := UiInv.caixa(true, 12) if larga else esq
	var topo := UiInv.caixa(false, 14)
	topo.add_child(UiInv.retrato(p, 150 if larga else 110))
	var nome := UiInv.caixa(true, 6)
	nome.alignment = BoxContainer.ALIGNMENT_CENTER
	nome.add_child(UiInv.rotulo(p.get_nome(), 36 if larga else 30))
	var tag := UiInv.chip(p.get_class_name())
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	nome.add_child(tag)
	nome.add_child(UiInv.rotulo("Nível %d" % p.get_level(), 16 if larga else 14))
	topo.add_child(nome)
	esq.add_child(topo)
	esq.add_child(UiInv.medidor("HP", p.get_hp(), p.get_max_hp(), UiInv.VERDE))
	esq.add_child(UiInv.medidor("PP", p.get_pp(), p.get_max_pp(), UiInv.AZUL))
	var fonte := 20 if larga else 16
	if larga:
		dir.add_child(UiInv.rotulo("Atributos", 14))
	for par in [["Ataque", p.get_atk()], ["Defesa", p.get_def()], ["Velocidade", p.get_vel()]]:
		var linha := UiInv.caixa(false, 0)
		linha.add_child(UiInv.rotulo(par[0], fonte))
		var n := UiInv.rotulo(str(par[1]), fonte)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		linha.add_child(n)
		dir.add_child(linha)
	dir.add_child(UiInv.rotulo("Habilidades", 14))
	var habs := HFlowContainer.new()
	habs.add_theme_constant_override("h_separation", 8)
	habs.add_theme_constant_override("v_separation", 8)
	for h in p.get_habilidades():
		habs.add_child(_metodo(h))
	if habs.get_child_count() == 0:
		habs.add_child(UiInv.rotulo("—", 14))
	dir.add_child(habs)
	if not larga:
		painel.add_child(esq)
		return
	var h := UiInv.caixa(false, 48)
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir.add_theme_constant_override("separation", 14)
	h.add_child(esq)
	h.add_child(dir)
	var m := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 24)
	m.add_theme_constant_override("margin_right", 96)  # espaço do { }
	m.add_child(h)
	painel.add_child(m)
