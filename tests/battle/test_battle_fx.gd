extends "res://tests/battle/battle_test.gd"


func press(action: String, hold := false) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	if hold:
		return
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await process_frame


func _initialize() -> void:
	var pacing := BattlePacing.new()
	var fx := BattleFx.new()
	fx.pacing = pacing
	root.add_child.call_deferred(pacing)
	root.add_child.call_deferred(fx)
	await process_frame
	await process_frame

	# slow motion + restore
	pacing.slow_motion(0.4, 0.3)
	await process_frame
	check("time_scale 0.3", absf(Engine.time_scale - 0.3) < 0.01, Engine.time_scale)
	pacing.restore()
	eq("restore", Engine.time_scale, 1.0)
	await create_timer(0.6, true, false, true).timeout

	# skip durante slow motion deixa 1.0
	var done := [false]
	var run := func():
		await pacing.slow_motion(5.0, 0.3)
		done[0] = true
	run.call()
	await process_frame
	check("slowmo ativo", absf(Engine.time_scale - 0.3) < 0.01)
	await press("ui_accept")
	await process_frame
	check("slowmo terminou no skip", done[0])
	eq("skip restaura time_scale", Engine.time_scale, 1.0)

	# hold = 2x
	await press("ui_accept", true)
	eq("hold 2x", pacing.speed, 2.0)
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = false
	Input.parse_input_event(ev)
	await process_frame
	eq("solta 1x", pacing.speed, 1.0)

	# play_action instantâneo
	pacing.instant = true
	var actor := Node2D.new()
	var enemy := Node2D.new()
	enemy.position = Vector2(200, 0)
	for n in [actor, enemy]:
		root.add_child(n)
	var target := Object.new()
	var oc := ActionOutcome.make(target, ActionOutcome.Kind.DAMAGE, 5, DamageType.Kind.FOGO, true)
	var hp := []
	fx.hp_changed.connect(func(t): hp.append(t))
	await fx.play_action(actor, "atacar()", [oc], func(_t): return enemy, func(_t): return 10)
	eq("play_action time_scale", Engine.time_scale, 1.0)
	eq("hp_changed", hp, [target])
	eq("ator volta", actor.position, Vector2.ZERO)
	await fx.play_action(actor, "atacar()", [ActionOutcome.make(target, ActionOutcome.Kind.MISS)], func(_t): return enemy, func(_t): return 10)
	await fx.play_enemy_destroyed(enemy, "Montanha", true)
	check("inimigo escondido", not enemy.visible)
	await fx.play_party_knocked_out(actor)
	check("KO cinza", actor.modulate.r < 0.9)
	await fx.play_error(actor, "erro")
	eq("time_scale final", Engine.time_scale, 1.0)

	# caminho visual (não instantâneo) termina rápido e restaura time_scale
	pacing.instant = false
	enemy.show()
	var t0 := Time.get_ticks_msec()
	await fx.play_action(actor, "atacar()", [oc], func(_t): return enemy, func(_t): return 10)
	await fx.play_enemy_destroyed(enemy, "Montanha", false)
	await fx.play_error(actor, "erro")
	check("visual < 4s", Time.get_ticks_msec() - t0 < 4000, Time.get_ticks_msec() - t0)
	eq("visual time_scale", Engine.time_scale, 1.0)
	pacing.instant = true

	# sem deriva: 3 ações seguidas (uma pulada), skip da sequência e duas destruições
	pacing.instant = false
	var field := Node2D.new()
	field.position = Vector2(5, 7)
	root.add_child(field)
	var a2 := Node2D.new()
	var e2 := Node2D.new()
	e2.position = Vector2(150, 0)
	field.add_child(a2)
	field.add_child(e2)
	fx.shake_target = field
	var snap := func(n: Node2D): return [n.position, n.scale, n.rotation, n.modulate]
	var s0 := [snap.call(a2), snap.call(e2), snap.call(field)]
	var big := ActionOutcome.make(target, ActionOutcome.Kind.DAMAGE, 9, DamageType.Kind.SOCO, true)
	for i in 3:
		var run2 := func(): await fx.play_action(a2, "atacar()", [big], func(_t): return e2, func(_t): return 10)
		if i == 1:
			run2.call()
			await create_timer(0.1, true, false, true).timeout
			await press("ui_accept")
			await process_frame
			await process_frame
		else:
			await run2.call()
		eq("sem deriva ação %d" % i, [snap.call(a2), snap.call(e2), snap.call(field)], s0)
	# o skip vale para o resto da sequência (2 alvos)
	var fin := [false]
	var run3 := func():
		await fx.play_action(a2, "atacar()", [big, big], func(_t): return e2, func(_t): return 10)
		fin[0] = true
	run3.call()
	await create_timer(0.05, true, false, true).timeout
	await press("ui_accept")
	await process_frame
	await process_frame
	check("skip pula o resto da sequência", fin[0])
	eq("time_scale após skip", Engine.time_scale, 1.0)
	for i in 2:
		e2.show()
		var rund := func(): await fx.play_enemy_destroyed(e2, "M", false)
		if i == 0:
			rund.call()
			await create_timer(0.1, true, false, true).timeout
			await press("ui_accept")
			await process_frame
			await process_frame
		else:
			await rund.call()
		eq("campo em repouso %d" % i, [field.position, field.scale], [s0[2][0], s0[2][1]])
		eq("modulate do inimigo restaurado %d" % i, e2.modulate, s0[1][3])
	# pacing liberado em slow motion volta a 1.0; sobreposição só restaura no fim
	var p2 := BattlePacing.new()
	root.add_child(p2)
	p2.slow_motion(5.0, 0.3)
	await process_frame
	p2.free()
	eq("free restaura", Engine.time_scale, 1.0)
	var p3 := BattlePacing.new()
	root.add_child(p3)
	p3.slow_motion(0.2, 0.3)
	p3.slow_motion(0.6, 0.3)
	await create_timer(0.4, true, false, true).timeout
	check("sobreposto ainda lento", absf(Engine.time_scale - 0.3) < 0.01, Engine.time_scale)
	await create_timer(0.5, true, false, true).timeout
	eq("sobreposto termina", Engine.time_scale, 1.0)
	p3.free()
	# KO repetido não acumula
	var k := Node2D.new()
	root.add_child(k)
	await fx.play_party_knocked_out(k)
	var ks: Vector2 = k.scale
	await fx.play_party_knocked_out(k)
	eq("KO idempotente", k.scale, ks)
	pacing.instant = true

	# biblioteca vazia
	var lib := DamageFxLibrary.new()
	check("effect_for vazio", lib.effect_for(DamageType.Kind.FOGO) == null)
	check("sound_for vazio", lib.sound_for(DamageType.Kind.FOGO) == null)

	# painéis de fim
	for scn in ["victory_panel", "defeat_panel"]:
		var p = load("res://scenes/battle/ui/%s.tscn" % scn).instantiate()
		root.add_child(p)
		await process_frame
		var closed := [false]
		var go := func():
			if scn == "victory_panel":
				var ls: Array[String] = ["a", "b"]
				await p.show_result(ls)
			else:
				await p.show_result("dica")
			closed[0] = true
		go.call()
		await create_timer(0.6, true, false, true).timeout
		check(scn + " aberto", not closed[0])
		await press("ui_accept")
		await create_timer(0.6, true, false, true).timeout
		check(scn + " fecha", closed[0])
	finish()
