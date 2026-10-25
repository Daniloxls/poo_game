extends "res://tests/battle/battle_test.gd"
const Fake = preload("res://tests/battle/fake_combatant.gd")

func montanha_f(s: CallStack, e) -> TurnFrame:
	return s.frames().filter(func(f): return f.entity == e)[0]


func _initialize() -> void:
	var panel: StackPanel = load("res://scenes/battle/ui/stack_panel.tscn").instantiate()
	root.add_child.call_deferred(panel)
	await process_frame
	var s := CallStack.new()
	panel.bind(s, func(_e): return Vector2(50, 300))
	var montanha := Fake.new("Montanha", 3, false)
	var turin := Fake.new("Turin", 6, true)
	var kath := Fake.new("Kath", 9, true)
	for c in [montanha, turin, kath]: s.push(c)
	await panel.animation_finished
	eq("3 views", panel.frames_box.get_child_count(), 3)
	eq("topo", panel.view_for(s.peek()).theme_type_variation, &"StackFrameTop")
	eq("inimigo", panel.view_for(s.frames()[0]).theme_type_variation, &"StackFrameEnemy")
	eq("party", panel.view_for(s.frames()[1]).theme_type_variation, &"StackFrame")
	eq("contagem", panel.count_label.text, "3")
	await create_timer(0.2).timeout
	var vm := panel.view_for(s.frames()[1])
	check("interrompido escurece", absf(vm.modulate.a - 0.6) < 0.05, vm.modulate.a)
	eq("pausado", vm.status.text, "⏸ pausado")
	var vd := panel.view_for(montanha_f(s, montanha))
	vd.mark_destroyed()
	check("risco fino", vd.label.visible and vd.destroyed)
	vd.destroyed = false
	s.remove(montanha)
	await panel.animation_finished
	eq("2 views", panel.frames_box.get_child_count(), 2)
	eq("contagem 2", panel.count_label.text, "2")
	s.pop()
	await panel.animation_finished
	eq("1 view", panel.frames_box.get_child_count(), 1)
	eq("retoma", panel.view_for(s.peek()).status.text, "▶ retoma")
	s.mark_knocked_out(turin)
	await panel.animation_finished
	eq("KO", panel.view_for(s.peek()).status.text, "⏸ HP 0")
	# ritmo da batalha: com um toque travado, o push termina em um ou dois quadros
	var pacing := BattlePacing.new()
	root.add_child(pacing)
	panel.pacing = pacing
	pacing.latched = true
	var done := [false]
	panel.animation_finished.connect(func(): done[0] = true, CONNECT_ONE_SHOT)
	s.push(Fake.new("Rato", 1, false))
	var quadros := 0
	while not done[0] and quadros < 60:
		await process_frame
		quadros += 1
	check("pulo: push em até 2 quadros", done[0] and quadros <= 2, quadros)
	eq("pulo: view no lugar", panel.frames_box.get_child_count(), 2)
	finish()
