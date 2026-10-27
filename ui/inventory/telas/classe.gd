extends HBoxContainer
## Troca de classe: a carta do personagem à esquerda, as classes à direita.
## Trocar é reconstruir o objeto com o antigo como argumento: kath = new BlackHat(kath);

const StatusTela := preload("res://ui/inventory/telas/status.gd")

var frente: PanelContainer
var linha: RichTextLabel
var _lista: VBoxContainer
var _p


func _ready() -> void:
	add_theme_constant_override("separation", 18)
	alignment = BoxContainer.ALIGNMENT_CENTER
	frente = UiInv.painel()
	frente.custom_minimum_size = StatusTela.TAMANHO
	frente.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(frente)
	var lado := UiInv.caixa(true, 12)
	lado.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lado.custom_minimum_size.x = 380
	var p := UiInv.painel()
	_lista = UiInv.caixa(true, 4)
	_lista.add_child(UiInv.rotulo("Mudar classe", 22))
	for c in RPG_CLASS.jogaveis():
		var b := UiInv.comando(c.CLASS_NAME, c.CLASS_NAME)
		b.toggle_mode = true
		if not c.HABILIDADES.is_empty():
			b.tooltip_text = c.HABILIDADES[0].get_description()
		b.pressed.connect(escolher.bind(c))
		_lista.add_child(b)
	p.add_child(_lista)
	lado.add_child(p)
	var cod := UiInv.codigo()
	linha = cod.get_node("Codigo")
	lado.add_child(cod)
	add_child(lado)


func abrir_tela(p) -> void:
	_p = p
	Progresso.marcar_visto("classes")
	linha.text = CodigoJava.colorir("// escolha uma classe")
	_atualizar()
	var atual := botao(_p.get_class_name())
	(atual if atual else botoes()[0]).grab_focus()


func botoes() -> Array:
	return _lista.get_children().filter(func(n): return n is Button)


func botao(nome: String) -> Button:
	return _lista.get_node_or_null(nome)


func escolher(c: RPG_CLASS) -> void:
	Inventory.clique()
	_p.mudar_classe(c)
	linha.text = CodigoJava.colorir(CodigoJava.linha_classe(_p, c))
	Inventory.mudou.emit()
	_atualizar()


func _atualizar() -> void:
	StatusTela.preencher_frente(frente, _p)
	for b in botoes():
		b.set_pressed_no_signal(b.name == _p.get_class_name())
