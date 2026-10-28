extends SceneTree
## Classes jogáveis: bônus nos atributos, troca de classe e ações de batalha.

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
	var t = root.get_node("Party/Turin")
	var nomes := RPG_CLASS.jogaveis().map(func(c): return c.CLASS_NAME)
	checar("quatro classes jogáveis", nomes == ["BlackHat", "Functioneer", "Protector", "WhiteHat"], nomes)
	checar("Turin começa como Personagem", t.get_class_name() == "Personagem", t.get_class_name())

	var black_hat: RPG_CLASS = load("res://rpg_classes/black_hat.tres")
	var protector: RPG_CLASS = load("res://rpg_classes/protector.tres")
	var functioneer: RPG_CLASS = load("res://rpg_classes/functioneer.tres")
	var ferro: EQUIP_ITEM = load("res://scenes/items/repo/armadura_ferro.tres")
	var atk0: int = t.get_atk()
	var nivel: int = t.get_level()
	t.set_equip("body_slot", ferro)
	t.mudar_classe(black_hat)
	checar("bônus de ataque da classe", t.get_atk() == atk0 + 4 + ferro.ATTACK, t.get_atk())
	checar("continua Turin, mesmo nível", t.get_nome() == "Turin" and t.get_level() == nivel)
	checar("equipamento fica", t.get_equip("body_slot") == ferro)

	for c in RPG_CLASS.jogaveis():
		var metodos := c.SKILLS.map(func(s): return BattleContext.method_name(s))
		checar(c.CLASS_NAME + " luta com atacar e usarItem", metodos == ["atacar", "usarItem"], metodos)
	var habs := protector.HABILIDADES.map(func(s): return s.get_skill_name())
	checar("habilidades do Protector", habs == ["Proteger", "Provocar"], habs)

	t.mudar_classe(protector)
	t.hp = t.get_max_hp()
	t.mudar_classe(functioneer)
	checar("hp não passa do novo máximo", t.hp == t.get_max_hp(), [t.hp, t.get_max_hp()])
	t.pp = 999
	t.mudar_classe(protector)
	checar("pp não passa do novo máximo", t.pp <= t.get_max_pp(), [t.pp, t.get_max_pp()])

	t.mudar_classe(load("res://rpg_classes/commoner.tres"))
	t.set_equip("body_slot", null)
	t.hp = t.get_max_hp()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
