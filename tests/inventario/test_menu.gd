extends SceneTree
## Menu novo: abrir e fechar, pilha de telas, ícone do canto e quando não pode abrir.

var passou := 0
var falhou := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func apertar_e() -> void:
	Input.action_press("e")
	await process_frame
	await process_frame
	Input.action_release("e")
	await process_frame


func _initialize() -> void:
	await process_frame  # autoloads só ficam prontos após o primeiro frame
	await process_frame
	var inv: Node = root.get_node("Inventory")
	var prog: Node = root.get_node("Progresso")
	var ps: Node = root.get_node("PlayerState")
	var icone: Button = inv.get_node("IconeMenu")
	var badge: Control = icone.get_node("Badge")
	checar("começa fechado", not inv.esta_aberto() and not inv.get_node("Menu").visible)
	checar("Opções continua no inventário", inv.get_node_or_null("%Velocidade") != null)
	ps.set_on_interface(true)  # tela de título, Tritomos...
	await process_frame
	checar("ícone some com outra interface aberta", not icone.visible)
	await apertar_e()
	checar("e não abre sobre outra interface", not inv.esta_aberto())
	checar("outra interface continua travando o jogador", ps.is_on_interface())
	ps.set_on_interface(false)
	await process_frame
	checar("ícone aparece com o inventário liberado", icone.visible)

	await apertar_e()
	checar("e abre", inv.esta_aberto() and inv.get_node("Menu").visible)
	checar("abre no resumo", inv.tela_atual() != null and inv.tela_atual().name.to_lower().begins_with("resumo"), inv.tela_atual())
	checar("jogador para enquanto o menu está aberto", ps.is_on_interface())
	await process_frame
	checar("ícone some com o menu aberto", not icone.visible)
	inv.ir("itens")
	checar("ir empilha a tela", inv.tela_atual().name.to_lower().begins_with("itens"), inv.tela_atual())
	inv.voltar()
	checar("voltar volta para o resumo", inv.esta_aberto() and inv.tela_atual().name.to_lower().begins_with("resumo"))
	inv.voltar()
	checar("voltar no resumo fecha", not inv.esta_aberto() and not ps.is_on_interface())

	prog._tem.erase("inventario")
	await apertar_e()
	await process_frame
	checar("trancado: e não abre", not inv.esta_aberto())
	checar("trancado: sem ícone", not icone.visible)
	prog.resetar()

	ps.set_on_scene(true)
	await apertar_e()
	await process_frame
	checar("em cena: e não abre", not inv.esta_aberto())
	checar("em cena: sem ícone", not icone.visible)
	ps.set_on_scene(false)

	inv.process_mode = Node.PROCESS_MODE_DISABLED
	checar("desligado pela batalha: não pode abrir", not inv.pode_abrir())
	await process_frame
	checar("desligado pela batalha: sem ícone", not icone.visible)
	inv.process_mode = Node.PROCESS_MODE_INHERIT

	await process_frame
	checar("sem novidade, sem badge", not badge.visible)
	prog.desbloquear("metodos")
	await process_frame
	checar("desbloqueio mostra badge", badge.visible)
	prog.marcar_visto("metodos")
	await process_frame
	checar("visto apaga o badge", not badge.visible)
	prog.resetar()

	checar("ícone escuro no botão creme", icone.get_theme_color("icon_normal_color").is_equal_approx(Color("#1b1b1b")), icone.get_theme_color("icon_normal_color"))
	icone.pressed.emit()
	checar("ícone abre o menu", inv.esta_aberto())

	# barra de navegação: de uma seção direto para outra, e um botão de fechar
	var barra: Control = inv.get_node("Menu/Barra")
	await process_frame
	checar("barra também no resumo", barra.visible)
	inv.ir("itens")
	await process_frame
	checar("barra aparece nas seções", barra.visible)
	checar("seção atual marcada", barra.find_child("Itens", true, false).button_pressed)
	barra.find_child("Equipamento", true, false).pressed.emit()
	await process_frame
	checar("barra troca direto de seção", inv.tela_atual().name == "Equipamento", inv.tela_atual().name)
	inv.voltar()
	checar("voltar depois da barra vai ao resumo", inv.esta_aberto() and inv.tela_atual().name == "Resumo", inv.tela_atual().name)
	inv.ir("itens")
	barra.find_child("Fechar", true, false).pressed.emit()
	checar("botão fechar fecha", not inv.esta_aberto())

	inv.liberar_tudo()
	var slots := []
	for i in inv.mochila.itens:
		if i is EQUIP_ITEM and not i.SLOT in slots:
			slots.append(i.SLOT)
	checar("F10 traz equipamento de todo tipo", slots.size() == EQUIP_ITEM.Slot.size(), slots)
	var sem_icone: Array = inv.mochila.itens.filter(func(i): return i.ITEM_ICON == null or not i.ITEM_ICON.resource_path.begins_with("res://assets/gui/icones/itens/"))
	checar("todo item com ícone próprio", sem_icone.is_empty(), sem_icone.map(func(i): return i.ITEM_NAME))
	inv.mochila.itens.clear()
	inv.dinheiro = 0
	prog.resetar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
