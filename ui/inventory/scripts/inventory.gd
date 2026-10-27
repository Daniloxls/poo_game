extends CanvasLayer
## Menu do jogo (E, Start ou o ícone do canto). Guarda a mochila e a pilha de telas;
## cada tela é uma cena em ui/inventory/telas com abrir_tela(personagem).

signal mudou  # algo do grupo ou da mochila mudou: as telas se atualizam

const MOEDA := "bits"
const TELAS := {
	"resumo": "res://ui/inventory/telas/Resumo.tscn",
	"status": "res://ui/inventory/telas/Status.tscn",
	"classe": "res://ui/inventory/telas/Classe.tscn",
	"itens": "res://ui/inventory/telas/Itens.tscn",
	"equipamento": "res://ui/inventory/telas/Equipamento.tscn",
	"documentacao": "res://ui/inventory/telas/Documentacao.tscn",
}
const ITENS_TESTE := ["res://scenes/items/repo/potion.tres", "res://scenes/items/repo/small_potion.tres",
		"res://scenes/items/repo/armadura_ferro.tres", "res://scenes/items/repo/armadura_couro.tres"]

@onready var menu: Control = $Menu
@onready var telas: Control = $Menu/Telas
@onready var audio_click: AudioStreamPlayer = $Audio_Click

var mochila := Mochila.new()
var dinheiro: int = 0
var tempo_jogo: float = 0.0

var _aberto := false
var _pilha: Array = []  # [nome, personagem]
var _cache := {}
var _tween: Tween


func _ready() -> void:
	mochila.mudou.connect(mudou.emit)
	_cache["opcoes"] = $Menu/Telas/Opcoes
	menu.hide()


func _process(delta: float) -> void:
	tempo_jogo += delta
	if PlayerState.is_on_dialogue():
		return
	var foco := get_viewport().gui_get_focus_owner()
	if foco is LineEdit or foco is TextEdit:   # "e" digitado num campo de texto
		return
	if Input.is_action_just_pressed("e") or Input.is_action_just_pressed("menu"):
		if _aberto:
			fechar()
		else:
			abrir()


func _unhandled_input(e: InputEvent) -> void:
	if _aberto and (e.is_action_pressed("Escape") or e.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		voltar()
	elif OS.is_debug_build() and e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_F10:
		liberar_tudo()


func esta_aberto() -> bool:
	return _aberto


func pode_abrir() -> bool:
	return Progresso.tem("inventario") and not PlayerState.is_on_dialogue() \
			and not PlayerState.is_on_scene() and process_mode != PROCESS_MODE_DISABLED


func abrir() -> void:
	if _aberto or not pode_abrir():
		return
	_aberto = true
	PlayerState.set_on_interface(true)
	menu.show()
	_animar(true)
	ir("resumo")


func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	_pilha.clear()
	PlayerState.set_on_interface(false)
	_animar(false)


func ir(tela: String, personagem = null) -> void:
	_pilha.append([tela, personagem])
	_mostrar_topo()


func voltar() -> void:
	_pilha.pop_back()
	if _pilha.is_empty():
		fechar()
	else:
		_mostrar_topo()


func tela_atual() -> Control:
	return _tela(_pilha[-1][0]) if not _pilha.is_empty() else null


func clique() -> void:
	audio_click.play()


func get_items() -> Array[ITEM]:
	return mochila.itens


func full_heal():
	for i in Party.get_children():
		i.set_hp(i.get_max_hp())
		i.default_state()   # sai de DEFEATED, senão não ganha turno na próxima luta


## F10 em modo de depuração: tudo desbloqueado e uma mochila de teste.
func liberar_tudo() -> void:
	Progresso.desbloquear_tudo()
	var qtd := {ITENS_TESTE[0]: 6, ITENS_TESTE[1]: 3}
	for caminho in ITENS_TESTE:
		mochila.adicionar(load(caminho), qtd.get(caminho, 1))
	dinheiro += 1250


func _mostrar_topo() -> void:
	var topo: Array = _pilha[-1]
	for t in telas.get_children():
		t.hide()
	var tela := _tela(topo[0])
	tela.show()
	if tela.has_method("abrir_tela"):
		tela.abrir_tela(topo[1])


func _tela(nome: String) -> Control:
	if not _cache.has(nome):
		var no: Control
		if TELAS.has(nome) and ResourceLoader.exists(TELAS[nome]):
			no = load(TELAS[nome]).instantiate()
		else:
			no = Control.new()  # tela ainda não feita
		no.name = nome.capitalize()
		no.set_anchors_preset(Control.PRESET_FULL_RECT)
		telas.add_child(no)
		_cache[nome] = no
	return _cache[nome]


func _animar(abrindo: bool) -> void:
	if _tween:
		_tween.kill()
	menu.pivot_offset = menu.size / 2
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(menu, "modulate:a", 1.0 if abrindo else 0.0, 0.15).from(0.0 if abrindo else 1.0)
	_tween.tween_property(menu, "scale", Vector2.ONE if abrindo else Vector2(0.96, 0.96), 0.15).from(Vector2(0.96, 0.96) if abrindo else Vector2.ONE)
	if not abrindo:
		_tween.chain().tween_callback(menu.hide)
