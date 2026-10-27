extends CenterContainer
## Carta de status: frente no estilo JRPG, verso com o personagem em Java.
## O { } vira a carta; o verso acompanha o jogo mesmo quando está escondido.

const TAMANHO := Vector2(460, 500)

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
	carta.custom_minimum_size = TAMANHO
	carta.pivot_offset = TAMANHO / 2
	frente = UiInv.painel()
	verso = UiInv.codigo()
	codigo = verso.get_node("Codigo")
	codigo.add_theme_font_size_override("normal_font_size", 14)
	for face in [frente, verso]:
		face.set_anchors_preset(Control.PRESET_FULL_RECT)
		carta.add_child(face)
	verso.hide()
	botao_virar = Button.new()
	botao_virar.text = "{ }"
	botao_virar.add_theme_font_override("font", BattleFonts.mono())
	botao_virar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	botao_virar.position = Vector2(TAMANHO.x - 64, 12)
	botao_virar.pressed.connect(virar)
	carta.add_child(botao_virar)
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
	Inventory.clique()
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
	preencher_frente(frente, _p)
	var linhas := CodigoJava.verso(_p, Progresso.estagio(), Progresso.tem("metodos"))
	var bb := linhas.map(CodigoJava.colorir)
	if not Progresso.tem("heranca"):  # Personagem fica apagado até a Herança
		bb[0] = bb[0].replace(CodigoJava.C_TIPO, CodigoJava.C_COMENTARIO)
	codigo.text = "\n".join(bb)


## A frente da carta; a troca de classe usa a mesma.
static func preencher_frente(painel: Control, p) -> void:
	UiInv.limpar(painel)
	var v := UiInv.caixa(true, 12)
	var topo := UiInv.caixa(false, 14)
	topo.add_child(UiInv.retrato(p, 110))
	var nome := UiInv.caixa(true, 6)
	nome.alignment = BoxContainer.ALIGNMENT_CENTER
	nome.add_child(UiInv.rotulo(p.get_nome(), 30))
	var tag := UiInv.chip(p.get_class_name())
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	nome.add_child(tag)
	nome.add_child(UiInv.rotulo("Nível %d" % p.get_level(), 14))
	topo.add_child(nome)
	v.add_child(topo)
	v.add_child(UiInv.medidor("HP", p.get_hp(), p.get_max_hp(), UiInv.VERDE))
	v.add_child(UiInv.medidor("PP", p.get_pp(), p.get_max_pp(), UiInv.AZUL))
	for par in [["Ataque", p.get_atk()], ["Defesa", p.get_def()], ["Velocidade", p.get_vel()]]:
		var linha := UiInv.caixa(false, 0)
		linha.add_child(UiInv.rotulo(par[0], 16))
		var n := UiInv.rotulo(str(par[1]), 16)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		linha.add_child(n)
		v.add_child(linha)
	v.add_child(UiInv.rotulo("Habilidades", 14))
	var habs := HFlowContainer.new()
	habs.add_theme_constant_override("h_separation", 6)
	for h in p.get_habilidades():
		habs.add_child(UiInv.chip(h.get_skill_name()))
	if habs.get_child_count() == 0:
		habs.add_child(UiInv.rotulo("—", 14))
	v.add_child(habs)
	painel.add_child(v)
