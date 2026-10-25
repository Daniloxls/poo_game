extends "res://tests/battle/battle_test.gd"
const Fake = preload("res://tests/battle/fake_combatant.gd")

func _initialize() -> void:
	var kath := Fake.new("Kath", 9, true)
	var turin := Fake.new("Turin", 6, true)
	var montanha := Fake.new("Montanha", 3, false)
	var boneco := Fake.new("Boneco", 6, false)   # empata com Turin
	var morto := Fake.new("Morto", 1, false); morto.alive = false

	# ordem de push: mais lento primeiro; empate: inimigo antes do grupo; mortos ficam de fora
	var ordem := CallStack.push_order([turin, kath, montanha, boneco, morto])
	eq("push_order", ordem.map(func(c): return c.get_nome()), ["Montanha", "Boneco", "Turin", "Kath"])

	var s := CallStack.new()
	var interrompidos := []
	s.pushed.connect(func(f, i): interrompidos.append(i.entity.get_nome() if i else ""))
	for c in ordem: s.push(c)
	eq("topo é o mais rápido", s.peek().entity, kath)
	eq("quem foi interrompido", interrompidos, ["", "Montanha", "Boneco", "Turin"])
	eq("topo ativo", s.peek().state, TurnFrame.State.ACTIVE)
	eq("abaixo pausado", s.frames()[2].state, TurnFrame.State.PAUSED)
	eq("label", s.peek().label(), "Kath.turno()")

	var retomado = [null]
	s.popped.connect(func(f, r): retomado[0] = r)
	s.pop()
	eq("pop retoma Turin", retomado[0].entity, turin)
	eq("Turin ativo de novo", s.peek().state, TurnFrame.State.ACTIVE)

	s.remove(boneco)                       # inimigo destruído com o frame pausado
	eq("remove tira do meio", s.frames().map(func(f): return f.entity.get_nome()), ["Montanha", "Turin"])
	var kos := []
	s.knocked_out.connect(func(f): kos.append(f.entity))
	s.mark_knocked_out(turin)
	s.mark_knocked_out(turin)
	eq("knocked_out emitido uma vez", kos, [turin])
	eq("KO marcado", s.peek().state, TurnFrame.State.KO)
	s.pop(); s.pop()
	check("vazia", s.is_empty())
	eq("pop vazio devolve null", s.pop(), null)
	finish()
