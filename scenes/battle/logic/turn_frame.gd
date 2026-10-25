class_name TurnFrame
extends RefCounted
## Um frame da pilha de chamadas: o turno de um combatente.

enum State { ACTIVE, PAUSED, KO }

var entity
var state: State = State.PAUSED


func label() -> String:
	return "%s.turno()" % entity.get_nome()
