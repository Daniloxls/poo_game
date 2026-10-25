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

	# play_action instantÃ¢neo
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

	# biblioteca vazia
	var lib := DamageFxLibrary.new()
	check("effect_for vazio", lib.effect_for(DamageType.Kind.FOGO) == null)
	check("sound_for vazio", lib.sound_for(DamageType.Kind.FOGO) == null)

	# painÃ©is de fim
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
