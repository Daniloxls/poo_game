extends TabContainer
## Equipamento: uma aba por membro. Slots (as variáveis do personagem), peças da mochila
## e os atributos com a prévia ▲▼. Só uma linha de Java: a atribuição que vai rodar.

const SLOTS := ["head_slot", "body_slot", "feet_slot", "rhand_slot", "lhand_slot", "acessory_slot"]
const NOMES := {"head_slot": "Cabeça", "body_slot": "Corpo", "feet_slot": "Pés",
		"rhand_slot": "Mão dir.", "lhand_slot": "Mão esq.", "acessory_slot": "Acessório"}
const CABE := {"head_slot": [EQUIP_ITEM.Slot.HEAD], "body_slot": [EQUIP_ITEM.Slot.BODY],
		"feet_slot": [EQUIP_ITEM.Slot.FEET], "rhand_slot": [EQUIP_ITEM.Slot.HAND, EQUIP_ITEM.Slot.TWO_HAND],
		"lhand_slot": [EQUIP_ITEM.Slot.HAND], "acessory_slot": [EQUIP_ITEM.Slot.ACESSORY]}
# atributo -> [rótulo, getter, campo do equipamento]
const ATRIBUTOS := {"atk": ["Ataque", "get_atk", "ATTACK"], "def": ["Defesa", "get_def", "DEFENSE"],
		"vel": ["Velocidade", "get_vel", "VELOCITY"], "hp": ["HP máx.", "get_max_hp", "HP"],
		"pp": ["PP máx.", "get_max_pp", "PP"]}
const C_SOBE := "#2f9e4f"
const C_DESCE := "#c9372c"

var abas: TabContainer = self
var valores := {}  # atributo -> RichTextLabel
var linha: RichTextLabel
var _p
var _slot := "body_slot"
var _slots: VBoxContainer
var _pecas: VBoxContainer
var _linhas_atr := {}


func _ready() -> void:
	tab_changed.connect(_on_aba)
	Inventory.mudou.connect(func(): if _p: _montar())


func abrir_tela(p) -> void:
	_p = p
	UiInv.limpar(self)
	for m in Party.get_children():
		var conteudo := UiInv.caixa(false, 18)
		conteudo.name = m.get_nome()
		add_child(conteudo)
	current_tab = maxi(Party.get_children().find(p), 0)
	_p = p
	_montar()
	_slots.get_child(1).grab_focus()


func escolher_slot(slot: String) -> void:
	_slot = slot
	_montar()
	_focar_slot()


## Mostra como os atributos ficariam com 'item' no slot escolhido (null = tirar).
func prever(item) -> void:
	var antes := {}
	for atr in ATRIBUTOS:
		antes[atr] = _p.call(ATRIBUTOS[atr][1])
	var depois := previsao(_p, _slot, item)
	for atr in ATRIBUTOS:
		var a: int = depois[atr][0]
		var b: int = depois[atr][1]
		var d := b - a
		valores[atr].text = str(a) if d == 0 else "%d → %d [color=%s]%s%d[/color]" % [a, b, C_SOBE if d > 0 else C_DESCE, "▲" if d > 0 else "▼", absi(d)]
	_mostrar_hp_pp(item)
	linha.text = CodigoJava.colorir(CodigoJava.linha_equipar(_p, CodigoJava.SLOTS[_slot], item))


func previsao(p, slot: String, item) -> Dictionary:
	var guardado := {}
	for s in SLOTS:
		guardado[s] = p.get_equip(s)
	var out := {}
	for atr in ATRIBUTOS:
		out[atr] = [p.call(ATRIBUTOS[atr][1])]
	_por(p, slot, item)
	for atr in ATRIBUTOS:
		out[atr].append(p.call(ATRIBUTOS[atr][1]))
	for s in SLOTS:
		p.set_equip(s, guardado[s])
	return out


func equipar(p, slot: String, item) -> void:
	Inventory.clique()
	var saiu := _por(p, slot, item)
	for e in saiu:
		Inventory.mochila.adicionar(e)
	if item:
		Inventory.mochila.gastar(item)
	p.ajustar_limites()  # tirar um bônus de HP não deixa o hp acima do máximo
	Inventory.mudou.emit()
	_focar_slot()


# _montar recria os botões: o foco volta para o slot escolhido
func _focar_slot() -> void:
	if is_visible_in_tree() and _slots:
		_slots.get_node(_slot).grab_focus()


# Coloca a peça no slot e devolve o que saiu (a de duas mãos ocupa as duas).
func _por(p, slot: String, item) -> Array:
	var saiu := []
	var livrar := [slot]
	if item and item.SLOT == EQUIP_ITEM.Slot.TWO_HAND:
		livrar.append("lhand_slot")
	var direita = p.get_equip("rhand_slot")
	if slot == "lhand_slot" and direita and direita.SLOT == EQUIP_ITEM.Slot.TWO_HAND:
		livrar.append("rhand_slot")
	for s in livrar:
		if p.get_equip(s):
			saiu.append(p.get_equip(s))
		p.set_equip(s, null)
	p.set_equip(slot, item)
	return saiu


func _on_aba(i: int) -> void:
	if i < 0 or i >= Party.get_child_count():
		return
	_p = Party.get_child(i)
	_montar()


func _montar() -> void:
	var conteudo: HBoxContainer = get_current_tab_control()
	if conteudo == null or _p == null:
		return
	UiInv.limpar(conteudo)
	_slots = UiInv.caixa(true, 4)
	_slots.custom_minimum_size.x = 210
	_slots.add_child(UiInv.rotulo("Equipado", 14))
	for s in SLOTS:
		var e = _p.get_equip(s)
		var b := UiInv.comando(s, "%s\n%s" % [NOMES[s], e.ITEM_NAME if e else "vazio"])
		b.add_theme_font_size_override("font_size", 15)
		b.toggle_mode = true
		b.set_pressed_no_signal(s == _slot)
		b.pressed.connect(escolher_slot.bind(s))
		_slots.add_child(b)
	conteudo.add_child(_slots)

	_pecas = UiInv.caixa(true, 4)
	_pecas.custom_minimum_size.x = 230
	_pecas.add_child(UiInv.rotulo("Trocar " + NOMES[_slot].to_lower(), 14))
	for e in Inventory.mochila.de_slot(CABE[_slot]):
		_pecas.add_child(_peca(e.ITEM_NAME, e))
	if _p.get_equip(_slot):
		_pecas.add_child(_peca("Tirar", null))
	if _pecas.get_child_count() == 1:
		_pecas.add_child(UiInv.rotulo("nada na mochila", 14, &"InvTextoBloqueado"))
	conteudo.add_child(_pecas)

	var atr_col := UiInv.caixa(true, 6)
	atr_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atr_col.add_child(UiInv.rotulo("Atributos", 14))
	valores.clear()
	_linhas_atr.clear()
	for atr in ATRIBUTOS:
		var l := UiInv.caixa(false, 0)
		var nome_atr := UiInv.rotulo(ATRIBUTOS[atr][0], 17)
		nome_atr.custom_minimum_size.x = 150
		l.add_child(nome_atr)
		var v := RichTextLabel.new()
		v.bbcode_enabled = true
		v.fit_content = true
		v.scroll_active = false
		v.autowrap_mode = TextServer.AUTOWRAP_OFF
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_color_override("default_color", UiInv.TINTA)
		v.add_theme_font_size_override("normal_font_size", 17)
		v.add_theme_font_override("normal_font", BattleFonts.display())
		l.add_child(v)
		valores[atr] = v
		_linhas_atr[atr] = l
		atr_col.add_child(l)
	var cod := UiInv.codigo()
	linha = cod.get_node("Codigo")
	atr_col.add_child(cod)
	conteudo.add_child(atr_col)
	_sem_previa()


func _peca(texto: String, e) -> Button:
	var b := UiInv.comando(texto.replace(" ", "_") if e else "Tirar", texto)
	b.add_theme_font_size_override("font_size", 16)
	b.mouse_entered.connect(prever.bind(e))
	b.focus_entered.connect(prever.bind(e))
	b.mouse_exited.connect(_sem_previa)
	b.pressed.connect(func(): equipar(_p, _slot, e))
	return b


func _sem_previa() -> void:
	for atr in ATRIBUTOS:
		valores[atr].text = str(_p.call(ATRIBUTOS[atr][1]))
	_mostrar_hp_pp(null)
	linha.text = CodigoJava.colorir("// passe o mouse numa peça")


# HP e PP só aparecem quando alguma peça mexe neles
func _mostrar_hp_pp(previa) -> void:
	for atr in ["hp", "pp"]:
		var campo: String = ATRIBUTOS[atr][2]
		var mexe: bool = previa != null and previa.get(campo) != 0
		for s in SLOTS:
			var e = _p.get_equip(s)
			mexe = mexe or (e != null and e.get(campo) != 0)
		_linhas_atr[atr].visible = mexe
