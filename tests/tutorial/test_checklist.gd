extends "res://tests/battle/battle_test.gd"
## Checklist do tutorial: marca cada item uma vez, completa no 5º, erro no fim da linha.

var marcou := []
var completou := []


func _initialize() -> void:
	var hud := ChecklistHud.new()
	root.add_child(hud)
	await process_frame
	hud.marcou.connect(func(id): marcou.append(id))
	hud.completou.connect(func(): completou.append(true))

	hud.marcar("andar")
	check("andar marcado", hud.marcado("andar"))
	eq("um sinal", marcou.size(), 1)
	hud.marcar("andar")
	eq("repetido ignorado", marcou.size(), 1)
	hud.marcar("voar")
	eq("desconhecido ignorado", marcou.size(), 1)
	check("voar não marcado", not hud.marcado("voar"))
	check("ainda incompleto", not hud.completo())

	for id in ["interagir", "correr", "lutar", "usarItem"]:
		hud.marcar(id)
	check("completo", hud.completo())
	eq("completou uma vez", completou.size(), 1)
	eq("cinco sinais", marcou, ["andar", "interagir", "correr", "lutar", "usarItem"])
	eq("texto", hud.texto(), "[✓] andar()  [✓] interagir()  [✓] correr()  [✓] lutar()  [✓] usarItem()")

	hud.mostrar_erro()
	check("erro no fim", hud.texto().ends_with("  [!] turin.cair()"), hud.texto())
	hud.piscar_aviso()
	hud.mensagem("Teste concluído. Acordando...")
	finish()
