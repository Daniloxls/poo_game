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
	var elenco := root.get_node_or_null("Elenco")
	checar("Elenco existe", elenco != null)
	if elenco == null:
		_fim()
		return

	var kath = elenco.buscar("Kath")
	checar("Kath cor", kath.cor == Color("#2ec4d6"), kath.cor)
	checar("Kath tem retrato", kath.tem_retrato())

	var cmd = elenco.buscar("Cmdzinho")
	var surpreso = cmd.retrato("surpreso")
	checar("Cmdzinho surpreso", surpreso != null and surpreso.resource_path.ends_with("cmd_surpreso.png"))
	checar("Cmdzinho bravo cai em neutro", cmd.retrato("bravo") == cmd.retrato("neutro") and cmd.retrato("bravo") != null)
	checar("Cmdzinho sem expressão = padrão", cmd.retrato() == cmd.retrato("neutro"))

	var gm = elenco.buscar("Grande Montanha")
	checar("Montanha sem retrato", gm.tem_retrato() == false)
	checar("Montanha cor", gm.cor == Color("#e8463a"), gm.cor)
	checar("Montanha retrato nulo", gm.retrato("x") == null)

	checar("Anti-POO serio", elenco.buscar("Anti-POO").retrato("serio") != null)
	var vulto = elenco.buscar("Vulto")
	checar("Vulto mostra ???", vulto.nome_exibido() == "???", vulto.nome_exibido())
	checar("Vulto padrão = silhueta", vulto.retrato() != null and vulto.retrato().resource_path.ends_with("silhueta.png"))
	checar("Vulto serio = rosto do Anti-POO", vulto.retrato("serio") != null and vulto.retrato("serio").resource_path.ends_with("anti_poo_serio.png"))
	var terminal = elenco.buscar("Terminal")
	checar("Terminal mostra ???", terminal.nome_exibido() == "???", terminal.nome_exibido())
	checar("Terminal usa retratos do Cmdzinho", terminal.retrato("surpreso") == surpreso and terminal.cor == cmd.cor)
	checar("sem rótulo, nome_exibido = nome", kath.nome_exibido() == "Kath")

	var f = elenco.buscar("Fulano")
	checar("Fulano não nulo", f != null)
	checar("Fulano nome", f != null and f.nome == "Fulano")
	checar("Fulano cor padrão", f != null and f.cor == elenco.COR_PADRAO)
	checar("Fulano sem retrato", f != null and not f.tem_retrato())
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
