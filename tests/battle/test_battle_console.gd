extends "res://tests/battle/battle_test.gd"
const Fake = preload("res://tests/battle/fake_combatant.gd")


class Probe:
	extends Node
	var got := 0
	func _unhandled_input(_e: InputEvent) -> void:
		got += 1


func key(code: int, uni := 0) -> void:
	for p in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.unicode = uni
		ev.pressed = p
		Input.parse_input_event(ev)
		await process_frame


func act(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame


func _initialize() -> void:
	var atk: SKILL = load("res://rpg_classes/skills/attack.tres")
	var uso: SKILL = load("res://rpg_classes/skills/use_item.tres")
	var turin = Fake.new("Turin", 5, true)
	turin.skills = [atk, uso]
	turin.classe = "Nada"
	var kath = Fake.new("Kath", 4, true)
	var montanha = Fake.new("Montanha", 3, false)
	var ctx := BattleContext.new()
	ctx.combatants = [turin, kath, montanha]
	ctx.active = turin

	var console: BattleConsole = load("res://scenes/battle/ui/battle_console.tscn").instantiate()
	var probe := Probe.new()
	var btn := Button.new()
	btn.position = Vector2(20, 20)
	btn.size = Vector2(120, 40)
	var pressed := []
	btn.pressed.connect(func(): pressed.append(1))
	for n in [console, probe, btn]:
		root.add_child.call_deferred(n)
	await process_frame
	await process_frame
	console.set_context(ctx)
	var ready_cmds := []
	console.command_ready.connect(func(c): ready_cmds.append(c))
	console.open()
	await process_frame
	check("foco ao abrir", console.is_typing())

	# digitação real atualiza texto e sugestões
	await key(KEY_T, 116)
	eq("digitou", console.text, "t")
	check("sugestão Turin", console.suggestion_labels().has("Turin"), console.suggestion_labels())

	# Tab aceita a sugestão destacada
	await key(KEY_TAB)
	eq("tab aceita", console.text, "Turin.")

	# erro: texto fica, mensagem aparece, nada roda
	console.text = "Turin.curar(Kath)"
	await key(KEY_ENTER)
	eq("sem command_ready", ready_cmds.size(), 0)
	eq("mensagem", console.error_label().text, "A classe Nada não tem o método 'curar'")
	eq("texto permanece", console.text, "Turin.curar(Kath)")
	check("foco permanece", console.is_typing())
	await key(KEY_X, 120)
	check("editar limpa o erro", not console.error_label().is_visible_in_tree())

	# sucesso
	console.text = "Turin.atacar(Montanha)"
	await key(KEY_ENTER)
	eq("command_ready 1x", ready_cmds.size(), 1)
	eq("alvo", ready_cmds[0].targets, [montanha])
	eq("linha limpa", console.text, "")
	check("status compilado", console.status_label().text.begins_with("✓ compilado"))

	# Review Focus 2: nada vaza para _unhandled_input
	probe.got = 0
	await key(KEY_Z, 122)
	await act("ui_accept")
	await act("ui_down")
	await key(KEY_F2)
	eq("probe não recebeu nada", probe.got, 0)

	# Escape solta o foco e mantém o texto
	console.text = "Tur"
	await key(KEY_ESCAPE)
	check("escape solta foco", not console.is_typing())
	eq("texto mantido", console.text, "Tur")

	# Review Focus 3: clique fora
	console.open()
	await process_frame
	check("refocou", console.is_typing())
	Input.warp_mouse(Vector2.ZERO)
	for p in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = btn.global_position + btn.size / 2
		ev.global_position = ev.position
		ev.pressed = p
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if p else 0
		Input.parse_input_event(ev)
		await process_frame
	eq("botão não disparou", pressed.size(), 0)
	eq("texto mantido após clique", console.text, "Tur")
	check("sem foco após clique fora", not console.is_typing())
	finish()
