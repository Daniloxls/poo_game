extends SceneTree
## Progresso: o que já foi desbloqueado, o que é novo e o estágio do código.

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
	var p := root.get_node_or_null("Progresso")
	checar("autoload existe", p != null)
	if p == null:
		_fim()
		return
	checar("padrão desbloqueado", p.tem("inventario") and p.tem("basico") and p.tem("classe") and p.tem("objeto"))
	checar("métodos e classes trancados", not p.tem("metodos") and not p.tem("classes"))
	checar("nada novo no começo", not p.algum_novo())
	checar("estágio OBJETO", p.estagio() == p.Estagio.OBJETO, p.estagio())

	var sinais := []
	p.desbloqueado.connect(func(id): sinais.append(id))
	p.desbloquear("metodos")
	p.desbloquear("metodos")
	checar("sinal uma vez só", sinais == ["metodos"], sinais)
	checar("métodos é novo", p.novo("metodos") and p.algum_novo())
	checar("estágio METODOS", p.estagio() == p.Estagio.METODOS, p.estagio())
	p.marcar_visto("metodos")
	checar("visto não é mais novo", not p.novo("metodos"))
	p.desbloquear("encapsulamento")
	checar("estágio ENCAPSULAMENTO", p.estagio() == p.Estagio.ENCAPSULAMENTO, p.estagio())

	p.desbloquear_tudo()
	var todos := true
	for id in p.CONCEITOS + ["classes"]:
		todos = todos and p.tem(id)
	checar("desbloquear_tudo", todos)

	p.resetar()
	checar("resetar volta ao padrão", p.tem("classe") and p.tem("objeto") and not p.tem("metodos") and not p.algum_novo())
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
