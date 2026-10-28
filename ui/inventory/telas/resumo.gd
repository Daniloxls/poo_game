extends HBoxContainer
## Resumo (o que o E abre): grupo à esquerda, comandos à direita, dinheiro e lugar embaixo.

# comando -> [texto, tela, precisa escolher personagem]
const COMANDOS := {
	"Itens": ["Itens", "itens", false],
	"Status": ["Status", "status", true],
	"Equipamento": ["Equipamento", "equipamento", true],
	"Classe": ["Classe", "classe", true],
	"Documentacao": ["Documentação", "documentacao", false],
	"Opcoes": ["Opções", "opcoes", false],
}

var _linhas: VBoxContainer
var _trilha: TrilhaConceitos
var _comandos: VBoxContainer
var _dinheiro: Label
var _lugar: Label
var _tempo: Label
var _escolhendo := ""  # tela esperando o jogador escolher um personagem
var _ultimo_comando: Button


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var grupo := UiInv.painel()
	grupo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var g := UiInv.caixa(true, 12)
	_linhas = UiInv.caixa(true, 10)
	_linhas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_trilha = TrilhaConceitos.new()
	g.add_child(_linhas)
	g.add_child(UiInv.divisor())
	g.add_child(_trilha)
	grupo.add_child(g)
	add_child(grupo)

	var lado := UiInv.caixa(true, 14)
	lado.custom_minimum_size.x = 230
	var p_cmd := UiInv.painel()
	_comandos = UiInv.caixa(true, 2)
	for nome in COMANDOS:
		var b := UiInv.comando(nome, COMANDOS[nome][0])
		b.pressed.connect(_on_comando.bind(b))
		_comandos.add_child(b)
	p_cmd.add_child(_comandos)
	lado.add_child(p_cmd)
	var espaco := Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lado.add_child(espaco)
	var rodape := UiInv.painel()
	var r := UiInv.caixa(true, 4)
	_dinheiro = UiInv.rotulo("", 16)
	_lugar = UiInv.rotulo("", 16)
	_tempo = UiInv.rotulo("", 16)
	for l in [_dinheiro, _lugar, _tempo]:
		r.add_child(l)
	rodape.add_child(r)
	lado.add_child(rodape)
	add_child(lado)
	Inventory.mudou.connect(_atualizar)


func abrir_tela(_p) -> void:
	_escolhendo = ""
	_atualizar()
	(_ultimo_comando if _ultimo_comando and _ultimo_comando.visible else comando("Itens")).grab_focus()


func linhas() -> Array:
	return _linhas.get_children()


func comando(nome: String) -> Button:
	return _comandos.get_node(nome)


func texto_dinheiro() -> String:
	return _dinheiro.text


func _process(_d: float) -> void:
	if is_visible_in_tree():
		var s := int(Inventory.tempo_jogo)
		_tempo.text = "Tempo  %02d:%02d" % [s / 3600, (s / 60) % 60]


func _atualizar() -> void:
	if _linhas == null:
		return
	UiInv.limpar(_linhas)
	for p in Party.get_children():
		_linhas.add_child(_linha(p))
	_trilha.atualizar()
	var classe := comando("Classe")
	classe.visible = Progresso.tem("classes")
	classe.get_node("Badge").visible = Progresso.novo("classes")
	var doc_nova := Progresso.novo("basico")
	for id in Progresso.CONCEITOS:
		doc_nova = doc_nova or Progresso.novo(id)
	comando("Documentacao").get_node("Badge").visible = doc_nova
	_dinheiro.text = "%d %s" % [Inventory.dinheiro, Inventory.MOEDA]
	var cena := get_tree().current_scene
	var lugar = cena.get("nome_local") if cena else null
	_lugar.text = lugar if lugar is String else (str(cena.name) if cena else "")


func _linha(p) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"InvComando"
	b.custom_minimum_size.y = 104
	b.pressed.connect(_on_personagem.bind(p))
	var h := UiInv.caixa(false, 16)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.offset_right = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(UiInv.retrato(p))
	var nome := UiInv.caixa(true, 4)
	nome.custom_minimum_size.x = 160
	nome.alignment = BoxContainer.ALIGNMENT_CENTER
	nome.add_child(UiInv.rotulo(p.get_nome(), 24))
	var tag := UiInv.chip(p.get_class_name())
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	nome.add_child(tag)
	nome.add_child(UiInv.rotulo("Nv %d" % p.get_level(), 14))
	h.add_child(nome)
	h.add_child(UiInv.medidor("HP", p.get_hp(), p.get_max_hp(), UiInv.VERDE))
	h.add_child(UiInv.medidor("PP", p.get_pp(), p.get_max_pp(), UiInv.AZUL))
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	return b


func _on_comando(b: Button) -> void:
	Inventory.clique()
	_ultimo_comando = b
	var c: Array = COMANDOS[b.name]
	if not c[2]:
		Inventory.ir(c[1])
	elif Party.get_child_count() == 1:
		Inventory.ir(c[1], Party.get_child(0))
	else:
		_escolhendo = c[1]
		linhas()[0].grab_focus()


func _on_personagem(p) -> void:
	Inventory.clique()
	var tela := _escolhendo if _escolhendo else "status"
	_escolhendo = ""
	Inventory.ir(tela, p)


func _unhandled_input(e: InputEvent) -> void:
	if _escolhendo and is_visible_in_tree() and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_escolhendo = ""
		_ultimo_comando.grab_focus()
