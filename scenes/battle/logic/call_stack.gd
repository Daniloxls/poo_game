class_name CallStack
extends RefCounted
## Pilha de chamadas da batalha: o topo é quem age agora.

signal pushed(frame: TurnFrame, interrupted: TurnFrame)
signal popped(frame: TurnFrame, resumed: TurnFrame)
signal frame_removed(frame: TurnFrame)

var _frames: Array = []


## Ordem de push: vivos, do mais lento ao mais rápido; empate: inimigo antes do grupo.
static func push_order(combatants: Array) -> Array:
	var vivos := combatants.filter(func(c): return c.is_alive())
	var idx := {}
	for i in vivos.size():
		idx[vivos[i]] = i
	vivos.sort_custom(func(a, b):
		if a.get_vel() != b.get_vel():
			return a.get_vel() < b.get_vel()
		if a.is_party_member() != b.is_party_member():
			return not a.is_party_member()
		return idx[a] < idx[b])  # estável: sort_custom não garante
	return vivos


func push(entity) -> TurnFrame:
	var antigo := peek()
	if antigo and antigo.state == TurnFrame.State.ACTIVE:
		antigo.state = TurnFrame.State.PAUSED
	var f := TurnFrame.new()
	f.entity = entity
	f.state = TurnFrame.State.ACTIVE
	_frames.append(f)
	pushed.emit(f, antigo)
	return f


func pop() -> TurnFrame:
	if _frames.is_empty():
		return null
	var f: TurnFrame = _frames.pop_back()
	var retomado := peek()
	if retomado and retomado.state != TurnFrame.State.KO:
		retomado.state = TurnFrame.State.ACTIVE
	popped.emit(f, retomado)
	return f


func peek() -> TurnFrame:
	return _frames.back() if not _frames.is_empty() else null


func size() -> int:
	return _frames.size()


func is_empty() -> bool:
	return _frames.is_empty()


## Frames de baixo para cima.
func frames() -> Array:
	return _frames.duplicate()


func remove(entity) -> void:
	for f in _frames:
		if f.entity == entity:
			_frames.erase(f)
			frame_removed.emit(f)
			return


func mark_knocked_out(entity) -> void:
	for f in _frames:
		if f.entity == entity:
			f.state = TurnFrame.State.KO


func clear() -> void:
	_frames.clear()
