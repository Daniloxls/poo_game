extends SceneTree

var passou := 0
var falhou := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	await process_frame  # autoloads só ficam prontos após o primeiro frame
	await process_frame
	var inv := root.get_node_or_null("Inventory")
	var opcoes := root.get_node_or_null("Opcoes")
	var vel: OptionButton = inv.get_node("Menu/Telas/Opcoes").velocidade if inv else null
	var auto: CheckButton = inv.get_node("Menu/Telas/Opcoes").avanco if inv else null
	checar("%Velocidade existe", vel != null)
	checar("%AvancoAutomatico existe", auto != null)
	if vel == null or auto == null or opcoes == null:
		_fim()
		return
	checar("4 itens", vel.item_count == 4, vel.item_count)
	checar("começa em NORMAL", vel.selected == opcoes.Velocidade.NORMAL, vel.selected)
	vel.select(3)
	vel.item_selected.emit(3)
	checar("seleciona instantânea", opcoes.velocidade_texto == opcoes.Velocidade.INSTANTANEA)
	auto.button_pressed = true
	checar("liga avanço automático", opcoes.avanco_automatico == true)
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
