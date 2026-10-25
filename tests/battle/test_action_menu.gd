extends "res://tests/battle/battle_test.gd"
const Fake = preload("res://tests/battle/fake_combatant.gd")


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = ev.duplicate()
	ev.pressed = false  # botões disparam ao soltar
	Input.parse_input_event(ev)
	await process_frame


func _initialize() -> void:
	var menu: ActionMenu = load("res://scenes/battle/ui/action_menu.tscn").instantiate()
	var sel := TargetSelector.new()
	var picker: ItemPicker = load("res://scenes/battle/ui/item_picker.tscn").instantiate()
	for n in [menu, sel, picker]:
		root.add_child.call_deferred(n)
	await process_frame
	var turin := Fake.new("Turin", 6, true)
	var attack: SKILL = load("res://rpg_classes/skills/attack.tres")
	var use_item: SKILL = load("res://rpg_classes/skills/use_item.tres")
	var chosen := []
	menu.skill_chosen.connect(func(s): chosen.append(s))
	menu.open_for(turin, [attack, use_item], Vector2(600, 300))
	await process_frame
	var btns := menu.buttons()
	eq("2 botões", btns.size(), 2)
	eq("texto 1", btns[0].text, "atacar()")
	eq("texto 2", btns[1].text, "usarItem()")
	check("foco no primeiro", btns[0].has_focus())
	await create_timer(0.5).timeout
	check("foco escala 1.1", absf(btns[0].scale.x - 1.1) < 0.02, btns[0].scale)
	await press("ui_down")
	check("ui_down move foco", btns[1].has_focus())
	btns[0].pressed.emit()
	eq("skill_chosen", chosen, [attack])
	menu.close()
	eq("fechado", menu.buttons().size(), 0)

	# seleção de alvo
	var a := Node2D.new()
	var b := Node2D.new()
	var c := Node2D.new()
	for n in [a, b, c]:
		root.add_child(n)
	b.modulate = Color(1, 0.5, 0.5, 1)
	var m := {"a": a, "b": b, "c": c}
	var ents := [Fake.new("a"), Fake.new("b"), Fake.new("c")]
	var of := func(e): return m[e.get_nome()]
	var res := []
	var run := func(): res.append(await sel.choose([ents[0], ents[1]], of))
	run.call()
	await process_frame
	await create_timer(0.1).timeout
	eq("não candidato escurece", c.modulate.a, 0.5)
	await press("ui_right")
	await press("ui_accept")
	eq("ui_accept escolhe o segundo", res[0], [ents[1]])
	eq("restaura c", c.modulate, Color.WHITE)
	eq("restaura b", b.modulate, Color(1, 0.5, 0.5, 1))
	run.call()
	await process_frame
	await press("ui_cancel")
	eq("cancel", res[1], [])
	eq("restaura após cancel", c.modulate, Color.WHITE)

	# mochila
	var potion: ITEM = load("res://scenes/items/repo/potion.tres")
	var got := []
	var runp := func(): got.append(await picker.choose([potion]))
	runp.call()
	await process_frame
	await process_frame
	await press("ui_accept")
	eq("item escolhido", got[0], potion)
	runp.call()
	await process_frame
	await press("ui_cancel")
	eq("mochila cancel", got[1], null)
	finish()
