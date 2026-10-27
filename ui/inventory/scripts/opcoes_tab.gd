extends PanelContainer
## Opções de diálogo: velocidade do texto e avanço automático.

@onready var velocidade: OptionButton = %Velocidade
@onready var avanco: CheckButton = %AvancoAutomatico


func _ready() -> void:
	# Opcoes é autoload posterior ao Inventory: não existe como identificador nem no _ready.
	_sincronizar.call_deferred()
	velocidade.item_selected.connect(func(i: int) -> void: opcoes().velocidade_texto = velocidade.get_item_id(i))
	avanco.toggled.connect(func(on: bool) -> void: opcoes().avanco_automatico = on)


func abrir_tela(_p) -> void:
	_sincronizar()
	velocidade.grab_focus()


func _sincronizar() -> void:
	velocidade.select(opcoes().velocidade_texto)
	avanco.set_pressed_no_signal(opcoes().avanco_automatico)


func opcoes() -> Node:
	return get_node("/root/Opcoes")
