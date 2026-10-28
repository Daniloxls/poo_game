extends Node
## Conceitos e recursos que a história já desbloqueou, e quais o jogador ainda não viu.

signal desbloqueado(id: String)

const CONCEITOS := ["classe", "objeto", "metodos", "encapsulamento", "abstracao", "polimorfismo", "heranca"]
const NOMES := {"classe": "Classe", "objeto": "Objeto", "metodos": "Métodos", "encapsulamento": "Encapsulamento",
		"abstracao": "Abstração", "polimorfismo": "Polimorfismo", "heranca": "Herança"}
const OUTROS := ["inventario", "basico", "classes"]
const PADRAO := ["inventario", "basico", "classe", "objeto"]

enum Estagio { OBJETO, METODOS, ENCAPSULAMENTO }

var _tem := {}
var _visto := {}


func _ready() -> void:
	resetar()


func tem(id: String) -> bool:
	return _tem.has(id)


func desbloquear(id: String) -> void:
	if tem(id):
		return
	_tem[id] = true
	desbloqueado.emit(id)


func novo(id: String) -> bool:
	return tem(id) and not _visto.has(id)


func marcar_visto(id: String) -> void:
	if tem(id):
		_visto[id] = true


func algum_novo() -> bool:
	for id in _tem:
		if not _visto.has(id):
			return true
	return false


## Como o Java das ações é escrito: muda conforme o jogador aprende.
func estagio() -> Estagio:
	if tem("encapsulamento"):
		return Estagio.ENCAPSULAMENTO
	if tem("metodos"):
		return Estagio.METODOS
	return Estagio.OBJETO


func desbloquear_tudo() -> void:
	for id in CONCEITOS + OUTROS:
		desbloquear(id)


func resetar() -> void:
	_tem.clear()
	_visto.clear()
	for id in PADRAO:
		_tem[id] = true
		_visto[id] = true
