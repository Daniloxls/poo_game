class_name BalaoDialogo
extends CanvasLayer
## Caixa de diálogo: busto saindo por cima da caixa, etiqueta com o nome e escolhas.
## O Dialogue Manager instancia esta cena e chama start().

const ANIMACOES := ["hop", "shake", "slump"]
const TEXTO_COM_RETRATO := 300.0
const TEXTO_SEM_RETRATO := 52.0
const ETIQUETA_COM_RETRATO := 288.0
const ETIQUETA_SEM_RETRATO := 60.0
const FONTE_MINIMA := 14

var recurso: DialogueResource
var estados: Array = []
var linha: DialogueLine
var _personagem: Personagem
var _pronto := false  # fala terminada, esperando o jogador

@onready var _caixa: Panel = %Caixa
@onready var _etiqueta: PanelContainer = %Etiqueta
@onready var _nome: Label = %NomeTag
@onready var _faixa: ColorRect = %Faixa
@onready var _retrato: RetratoDialogo = %Retrato
@onready var _texto: RotuloDialogo = %Texto
@onready var _indicador: Label = %Indicador
@onready var _escolhas: DialogueResponsesMenu = %Escolhas


func _ready() -> void:
	_escolhas.response_selected.connect(_responder)
	# O container re-ordena (e zera rotação/escala) depois de cada mudança: remarca no fim do quadro.
	_escolhas.sort_children.connect(_marcar_escolha.call_deferred)
	_caixa.gui_input.connect(_clique_na_caixa)
	get_viewport().gui_focus_changed.connect(_marcar_escolha)
	var bob := create_tween().set_loops()
	bob.tween_property(_indicador, "position:y", 5.0, 0.4).as_relative().set_trans(Tween.TRANS_SINE)
	bob.tween_property(_indicador, "position:y", -5.0, 0.4).as_relative().set_trans(Tween.TRANS_SINE)


func start(r: DialogueResource, cue: String = "", estados_extras: Array = []) -> void:
	recurso = r
	estados = [self] + estados_extras
	_seguir(cue)


## Digitando: completa a fala. Fala pronta sem escolhas: próxima. Com escolhas: nada.
func avancar() -> void:
	if linha == null:
		return
	if _texto.is_typing:
		_texto.skip_typing()
	elif _pronto:
		_seguir(linha.next_id)


func escolher(indice: int) -> void:
	var itens: Array = _escolhas.get_menu_items()
	if _escolhas.visible and indice >= 0 and indice < itens.size():
		_responder(itens[indice].get_meta("response"))


## Chamável de dentro da fala: [do expressao("surpreso")]
func expressao(nome: String) -> void:
	if _personagem and _personagem.tem_retrato():
		_retrato.trocar_expressao(nome)


## Chamável de dentro da fala: [do animar("hop")]
func animar(nome: String) -> void:
	if _personagem and _personagem.tem_retrato():
		_retrato.animar(nome)


func _unhandled_input(e: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	var confirmar := e.is_action_pressed("interact") or e.is_action_pressed("ui_accept")
	if not _escolhas.visible:
		if confirmar:
			avancar()
		return
	var itens: Array = _escolhas.get_menu_items()
	if itens.is_empty():
		return
	var i: int = itens.find(get_viewport().gui_get_focus_owner())
	if e.is_action_pressed("up"):
		itens[maxi(i - 1, 0)].grab_focus()
	elif e.is_action_pressed("down"):
		itens[mini(i + 1, itens.size() - 1)].grab_focus()
	elif confirmar:
		escolher(maxi(i, 0))


func _seguir(id: String) -> void:
	_pronto = false
	_indicador.hide()
	_escolhas.hide()
	var proxima: DialogueLine = await recurso.get_next_dialogue_line(id, estados)
	if proxima == null:
		_terminar()
	else:
		_mostrar(proxima)


func _mostrar(l: DialogueLine) -> void:
	linha = l
	var p: Personagem = Elenco.buscar(l.character)
	_personagem = p
	_nome.text = p.nome_exibido()
	_etiqueta.visible = not p.nome_exibido().is_empty()
	_etiqueta.self_modulate = p.cor
	_etiqueta.position.x = ETIQUETA_COM_RETRATO if p.tem_retrato() else ETIQUETA_SEM_RETRATO
	_faixa.visible = not p.tem_retrato()
	_faixa.color = p.cor
	_texto.offset_left = TEXTO_COM_RETRATO if p.tem_retrato() else TEXTO_SEM_RETRATO
	if p.tem_retrato():
		var exp := p.expressao_padrao
		for t in l.tags:
			if p.retratos.has(t):
				exp = t
				break
		# Antes de mostrar(): depois mataria o "pop" da troca de expressão.
		_retrato.resetar_pose()
		_retrato.mostrar(p, exp)
		for a in ANIMACOES:
			if a in l.tags:
				_retrato.animar(a)
	else:
		_retrato.esconder()

	_texto.seconds_per_step = Opcoes.segundos_por_letra()
	_texto.dialogue_line = l
	_caber_texto()
	if not l.text.is_empty():
		_texto.type_out()
		await _texto.finished_typing
	if linha != l:
		return

	if not l.responses.is_empty():
		_escolhas.show()
		_escolhas.responses = l.responses
	elif Opcoes.avanco_automatico:
		_pronto = true
		await get_tree().create_timer(Opcoes.atraso_avanco(_texto.get_parsed_text().length())).timeout
		if linha == l and _pronto:
			avancar()
	else:
		_pronto = true
		_indicador.show()


## Fala longa demais: diminui a fonte até caber, em vez de rolar.
func _caber_texto() -> void:
	for tipo in ["normal_font_size", "mono_font_size"]:
		_texto.remove_theme_font_size_override(tipo)
	var tam := _texto.get_theme_font_size("normal_font_size")
	while _texto.get_content_height() > _texto.size.y and tam > FONTE_MINIMA:
		tam -= 1
		for tipo in ["normal_font_size", "mono_font_size"]:
			_texto.add_theme_font_size_override(tipo, tam)


func _responder(resposta: DialogueResponse) -> void:
	if _escolhas.visible:
		_seguir(resposta.next_id)


func _terminar() -> void:
	linha = null
	set_process_unhandled_input(false)
	_caixa.hide()
	_etiqueta.hide()
	_retrato.esconder()
	await get_tree().create_timer(0.25).timeout
	queue_free()


func _clique_na_caixa(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		avancar()


## Escolha focada: amarela (estilo de foco do tema), inclinada, maior e com ▶.
func _marcar_escolha(_foco: Control = null) -> void:
	for item: Button in _escolhas.get_menu_items():
		var sel := item.has_focus()
		item.text = ("▶ " if sel else "") + item.get_meta("response").text
		item.rotation_degrees = -1.5 if sel else 0.0
		item.scale = Vector2.ONE * (1.06 if sel else 1.0)
