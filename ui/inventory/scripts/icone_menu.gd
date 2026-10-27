extends Button
## Ícone no canto que abre o menu; a bolinha amarela avisa que algo foi desbloqueado.

@onready var inventario: Node = get_parent()
@onready var badge: Control = $Badge


func _ready() -> void:
	pressed.connect(func(): inventario.abrir())


# PROCESS_MODE_ALWAYS: roda mesmo com o inventário desligado pela batalha, para se esconder
func _process(_delta: float) -> void:
	visible = inventario.pode_abrir() and not inventario.esta_aberto() and not PlayerState.is_on_interface()
	badge.visible = Progresso.algum_novo()
