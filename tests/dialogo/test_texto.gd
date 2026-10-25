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
	checar("intervalos whisper", DialogoBBCode.intervalos("ab[whisper]cd[/whisper]e", "whisper") == [Vector2i(2, 4)], DialogoBBCode.intervalos("ab[whisper]cd[/whisper]e", "whisper"))
	checar("intervalos com outras tags", DialogoBBCode.intervalos("[b]x[/b][whisper]yz[/whisper][whisper]w[/whisper]", "whisper") == [Vector2i(1, 3), Vector2i(3, 4)])
	checar("intervalos sem a tag", DialogoBBCode.intervalos("[shake rate=20]a[/shake]b", "whisper").is_empty())
	checar("expandir_code", DialogoBBCode.expandir_code("tem [code]métodos[/code]") == "tem [bgcolor=#1b1b1b][color=#ffd23f][code]métodos[/code][/color][/bgcolor]")

	await process_frame
	var dm := root.get_node("DialogueManager")
	var r = dm.create_resource_from_text("~ a\nX: ab[whisper]cd[/whisper]\n=> END")
	var linha = await r.get_next_dialogue_line("a")
	var rotulo := RotuloDialogo.new()
	root.add_child(rotulo)
	rotulo.dialogue_line = linha
	checar("_get_speed(1) == 1", is_equal_approx(rotulo._get_speed(1), 1.0))
	checar("_get_speed(3) == 0.5", is_equal_approx(rotulo._get_speed(3), 0.5))
	checar("_get_speed(5) == 1", is_equal_approx(rotulo._get_speed(5), 1.0))
	var tem := [false, false, false]
	for e in rotulo.custom_effects:
		tem[0] = tem[0] or e is EfeitoPop
		tem[1] = tem[1] or e is EfeitoSussurro
		tem[2] = tem[2] or e is EfeitoGlitch
	checar("tres efeitos instalados", tem == [true, true, true], tem)
	rotulo.skip_typing()
	checar("skip_typing revela tudo", rotulo.visible_characters == rotulo.get_total_character_count() and rotulo.visible_characters == 4, rotulo.visible_characters)
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
