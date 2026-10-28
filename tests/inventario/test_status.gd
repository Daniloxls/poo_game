extends SceneTree
## Carta de status: um botão { } que vira a carta, verso com o Java sempre atualizado.

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
	var inv: Node = root.get_node("Inventory")
	root.get_node("PlayerState").set_on_interface(false)  # já passou da tela de título
	var turin = root.get_node("Party/Turin")
	inv.abrir()
	inv.ir("status", turin)
	await process_frame
	var s: Control = inv.tela_atual()
	checar("cena de status", s.has_method("virar"), s)
	if not s.has_method("virar"):
		_fim()
		return
	checar("começa pela frente", s.frente.visible and not s.verso.visible)
	var botoes := s.find_children("*", "Button", true, false).filter(func(b): return b.text == "{ }")
	checar("um botão { } só", botoes.size() == 1, botoes.size())
	await process_frame
	checar("{ } fica dentro da carta", Rect2(Vector2.ZERO, s.carta.size).encloses(Rect2(s.botao_virar.position, s.botao_virar.size)), [s.botao_virar.position, s.carta.size])
	checar("frente mostra o nome", s.frente.find_children("*", "Label", true, false).any(func(l): return l.text == "Turin"))
	checar("carta do tamanho das outras telas", s.carta.size.is_equal_approx(s.size) and s.size.x > 900, [s.carta.size, s.size])
	var borda = s.verso.get_theme_stylebox("panel")
	checar("verso com borda clara", borda is HardShadowStyleBox and borda.border_color.v > 0.9 and borda.border_width >= 4, borda)

	s.virar()
	await create_timer(0.6).timeout
	checar("virou para o verso", s.verso.visible and not s.frente.visible and s.virada)
	var texto: String = s.codigo.get_parsed_text()
	checar("verso tem o hp", texto.contains("turin.hp = %d;" % turin.hp), texto)

	s.virar()
	await create_timer(0.6).timeout
	turin.hp -= 1
	inv.mudou.emit()
	checar("verso escondido também se atualiza", s.codigo.get_parsed_text().contains("turin.hp = %d;" % turin.hp))
	turin.mudar_classe(load("res://rpg_classes/black_hat.tres"))
	inv.mudou.emit()
	checar("verso mostra a troca de classe", s.codigo.get_parsed_text().contains("turin = new BlackHat(turin);"))
	checar("frente mostra a classe nova", s.frente.find_children("*", "Label", true, false).any(func(l): return l.text == "BlackHat"))
	var metodos: Array = s.frente.find_children("*", "Button", true, false).filter(func(b): return b.text == "invadir(Inimigo alvo)")
	checar("habilidade escrita como método", metodos.size() == 1, s.frente.find_children("*", "Button", true, false).map(func(b): return b.text))
	if metodos.size() == 1:
		checar("descrição ao passar o mouse", metodos[0].tooltip_text == "Entra no código do inimigo", metodos[0].tooltip_text)
		checar("botão grande", metodos[0].custom_minimum_size.y >= 40)

	turin.mudar_classe(load("res://rpg_classes/commoner.tres"))
	turin.hp = turin.get_max_hp()
	inv.fechar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
