extends "res://tests/battle/battle_test.gd"


func _initialize() -> void:
	var combo := ComboMeter.new()
	var emitidos := []
	combo.changed.connect(func(n): emitidos.append(n))

	var esperado := [1.0, 1.05, 1.10, 1.15, 1.20, 1.25, 1.25]
	for i in esperado.size():
		check("multiplicador de combo %d" % i, is_equal_approx(combo.on_console_action(), esperado[i]))
	eq("nível satura em 5", combo.level, 5)
	eq("changed emitido por nível novo", emitidos, [1, 2, 3, 4, 5])

	check("ação de botão dá 1.0", is_equal_approx(combo.on_button_action(), 1.0))
	eq("botão zera o combo", combo.level, 0)

	combo.reset()
	eq("reset zera", combo.level, 0)

	check("impacto 16/32", is_equal_approx(HitImpact.impact(16, 32), 0.5))
	check("impacto satura em 1", is_equal_approx(HitImpact.impact(100, 32), 1.0))
	check("hitstop mínimo", is_equal_approx(HitImpact.hitstop_seconds(0, false), 0.03))
	check("hitstop crítico máximo capado", is_equal_approx(HitImpact.hitstop_seconds(1, true), 0.12))
	check("tremor meio crítico", is_equal_approx(HitImpact.shake_pixels(0.5, true), 13.0))
	eq("frame de impacto fraco", HitImpact.impact_frame(0.1, false), false)
	eq("frame de impacto crítico", HitImpact.impact_frame(0.1, true), true)
	finish()
