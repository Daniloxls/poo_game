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

	icone.pressed.emit()
	checar("ícone abre o menu", inv.esta_aberto())
	inv.fechar()
	checar("fechar fecha", not inv.esta_aberto())
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
