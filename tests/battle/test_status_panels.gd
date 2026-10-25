extends "res://tests/battle/battle_test.gd"
const Fake = preload("res://tests/battle/fake_combatant.gd")


func _find_label(n: Node, text: String) -> Label:
	if n is Label and n.text == text:
		return n
	for c in n.get_children():
		var r := _find_label(c, text)
		if r:
			return r
	return null


func _initialize() -> void:
	var bar := HpBar.new()
	root.add_child.call_deferred(bar)
	await process_frame
	bar.setup(32, 32, Color("#e8463a"))
	bar.set_value(16)
	bar.set_value(16)  # refresh redundante não cancela o dreno
	eq("fantasma segura", bar.ghost_value, 32.0)
	await create_timer(0.7).timeout
	eq("fantasma drenou", bar.ghost_value, 16.0)

	var es: EnemyStatus = load("res://scenes/battle/ui/enemy_status.tscn").instantiate()
	var ps: PartyStatus = load("res://scenes/battle/ui/party_status.tscn").instantiate()
	root.add_child.call_deferred(es)
	root.add_child.call_deferred(ps)
	await process_frame
	var m := Fake.new("Montanha", 3, false)
	m.classe = "Lutador"
	es.add_enemy(m)
	check("tag Lutador", _find_label(es, "Lutador") != null)
	check("nome", _find_label(es, "Montanha") != null)
	m.hp = 4
	es.refresh(m)
	es.remove_enemy(m)
	await create_timer(0.6).timeout
	check("linha removida", _find_label(es, "Montanha") == null)

	var t := Fake.new("Turin", 6, true)
	var k := Fake.new("Kath", 9, true)
	ps.set_party([t, k])
	ps.set_active(k)
	ps.refresh(t)
	check("party nomes", _find_label(ps, "Turin") != null and _find_label(ps, "Kath") != null)

	var o := ActionOutcome.make(m, ActionOutcome.Kind.DAMAGE, 27, DamageType.Kind.CORTE, true)
	DamageNumber.spawn(root, Vector2(100, 100), o)
	check("numero crit", _find_label(root, "27!") != null)
	await create_timer(1.0).timeout
	check("numero liberado", _find_label(root, "27!") == null)
	finish()
