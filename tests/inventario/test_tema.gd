extends SceneTree
## Tema do inventário: variações usadas pelas telas e a aba que encaixa no painel.

var passou := 0
var falhou := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	await process_frame
	var t: Theme = load("res://ui/inventory/tema_inventario.tres")
	checar("tema existe", t != null)
	if t == null:
		_fim()
		return
	for par in [["panel", "InvPainel"], ["panel", "InvPainelAba"], ["panel", "InvChip"], ["panel", "InvChipBloqueado"],
			["panel", "InvCodigo"], ["panel", "InvBadge"], ["hover", "InvComando"], ["focus", "InvComando"], ["normal", "InvComando"]]:
		checar("%s tem %s" % [par[1], par[0]], t.has_stylebox(par[0], par[1]))
	checar("InvCodigoTexto usa fonte mono", t.has_font("normal_font", "InvCodigoTexto"))
	var painel = t.get_stylebox("panel", "TabContainer")
	checar("painel das abas tem canto quadrado", painel is HardShadowStyleBox and painel.square_top_left)
	var aba = t.get_stylebox("tab_selected", "TabContainer")
	checar("aba selecionada sem borda de baixo", aba is StyleBoxFlat and aba.border_width_bottom == 0 and aba.bg_color.is_equal_approx(Color("#fff8e7")), [aba, aba.border_width_bottom, aba.bg_color])
	checar("aba cobre a borda do painel", aba.expand_margin_bottom >= painel.border_width)
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
