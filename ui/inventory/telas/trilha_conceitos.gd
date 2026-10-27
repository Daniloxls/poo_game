class_name TrilhaConceitos
extends HFlowContainer
## Um chip por conceito de POO: o nome quando já visto, "???" enquanto trancado ou ainda não revelado.


func _init() -> void:
	name = "TrilhaConceitos"
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("v_separation", 6)


func atualizar() -> void:
	UiInv.limpar(self)
	for id in Progresso.CONCEITOS:
		var aberto: bool = Progresso.tem(id) and not Progresso.novo(id)
		var c := UiInv.chip(Progresso.NOMES[id] if aberto else "???", aberto)
		c.name = id
		add_child(c)


func chip_texto(id: String) -> String:
	return get_node(id).get_node("Texto").text


## Primeira vez na Documentação: o chip novo troca "???" pelo nome com um pulo.
func revelar(id: String) -> void:
	var c: PanelContainer = get_node_or_null(id)
	if c == null:
		return
	var novo := UiInv.chip(Progresso.NOMES[id])
	novo.name = id
	add_child(novo)
	move_child(novo, c.get_index())
	remove_child(c)
	c.queue_free()
	novo.pivot_offset = novo.get_combined_minimum_size() / 2
	var t := novo.create_tween()
	t.tween_property(novo, "scale", Vector2(1.15, 1.15), 0.15)
	t.tween_property(novo, "scale", Vector2.ONE, 0.15)
