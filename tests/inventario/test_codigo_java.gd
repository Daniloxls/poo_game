extends SceneTree
## CodigoJava: o Java exato de cada ação do menu, em cada estágio.

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
	const OBJ := 0
	const MET := 1
	const ENC := 2
	var turin = root.get_node("Party/Turin")
	var pocao: ITEM = load("res://scenes/items/repo/potion.tres")
	var ferro: EQUIP_ITEM = load("res://scenes/items/repo/armadura_ferro.tres")
	var black_hat: RPG_CLASS = load("res://rpg_classes/black_hat.tres")
	turin.hp = 18

	checar("nome com acento e espaço", CodigoJava.nome_variavel("Poção Pequena") == "pocaoPequena", CodigoJava.nome_variavel("Poção Pequena"))
	checar("nome simples", CodigoJava.nome_variavel("Turin") == "turin")
	checar("nome com várias palavras", CodigoJava.nome_variavel("Armadura de Ferro") == "armaduraDeFerro", CodigoJava.nome_variavel("Armadura de Ferro"))
	checar("nome com sublinhado", CodigoJava.nome_variavel("Poção_Pequena") == "pocaoPequena")

	var l = CodigoJava.linha_usar(pocao, turin, OBJ)
	checar("usar em OBJETO", l == ["turin.hp = turin.hp + pocao.cura;"], l)
	l = CodigoJava.linha_usar(pocao, turin, MET)
	checar("usar em METODOS", l == ["pocao.usar(turin);"], l)
	l = CodigoJava.linha_usar(pocao, turin, ENC)
	checar("usar em ENCAPSULAMENTO", l == ["✗ turin.hp = turin.hp + pocao.cura;  // hp é private", "pocao.usar(turin);"], l)
	checar("descartar", CodigoJava.linha_descartar(pocao) == "mochila.remove(pocao);")
	checar("equipar", CodigoJava.linha_equipar(turin, "corpo", ferro) == "turin.corpo = armaduraDeFerro;")
	checar("tirar", CodigoJava.linha_equipar(turin, "corpo", null) == "turin.corpo = null;")
	checar("classe", CodigoJava.linha_classe(turin, black_hat) == "turin = new BlackHat(turin);")

	var v = CodigoJava.verso(turin, OBJ, false)
	checar("verso começa com a declaração", v.slice(0, 3) == ["Personagem turin = new Personagem(\"Turin\");", "turin.nome = \"Turin\";", "turin.hp = 18;"], v.slice(0, 3))
	checar("verso soma o ataque", v.has("turin.atk = atkBase + classe.atk;  // %d" % turin.get_atk()), v)
	checar("métodos trancados sem o nome", v[-1] == "// ??? 🔒", v[-1])
	turin.set_equip("body_slot", ferro)
	v = CodigoJava.verso(turin, OBJ, false)
	checar("equipamento entra na soma", v.has("turin.atk = atkBase + classe.atk + corpo.atk;  // %d" % turin.get_atk()), v)
	checar("só os slots que mudam o atributo", v.has("turin.def = defBase + classe.def + corpo.def;  // %d" % turin.get_def()), v)
	turin.set_equip("body_slot", null)

	turin.mudar_classe(black_hat)
	v = CodigoJava.verso(turin, OBJ, false)
	checar("verso depois da troca: turin já existe antes do new BlackHat(turin)", v.slice(0, 2) == ["Personagem turin = new Personagem(\"Turin\");", "turin = new BlackHat(turin);"], v.slice(0, 2))
	v = CodigoJava.verso(turin, ENC, true)
	checar("encapsulamento usa setter", v.has("turin.setHp(18);") and not v.any(func(l): return l.begins_with("turin.hp =")), v)
	v = CodigoJava.verso(turin, MET, true)
	checar("getter com métodos", v.has("int getAtk() { return atkBase + classe.atk; }  // %d" % turin.get_atk()), v)
	checar("métodos da classe", v.slice(-2) == ["void invadir(Inimigo alvo) {}", "void roubar(Inimigo alvo) {}"], v.slice(-2))

	checar("comentário cinza", CodigoJava.colorir("// x").contains("#7d8597"))
	var r := CodigoJava.colorir("✗ a;")
	checar("linha riscada", r.contains("[s]") and not r.contains("✗"), r)
	checar("colchete escapado", not CodigoJava.colorir("int[] a;").contains("[]"))

	turin.mudar_classe(load("res://rpg_classes/commoner.tres"))
	turin.hp = turin.get_max_hp()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
