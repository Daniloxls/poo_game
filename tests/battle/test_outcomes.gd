extends "res://tests/battle/battle_test.gd"
const Fake = preload("res://tests/battle/fake_combatant.gd")
const Attack = preload("res://rpg_classes/skills/attack.gd")
const UseItem = preload("res://rpg_classes/skills/use_item.gd")


func _initialize() -> void:
	var user := Fake.new("Turin", 13, true)
	user.atk = 12
	var alvo := Fake.new("Boneco", -1000, false)   # nunca erra
	alvo.def = 5

	seed(1)
	var r1: Array = Attack.new().resolve(user, [alvo], 1.0)
	eq("um outcome", r1.size(), 1)
	eq("tipo DAMAGE", r1[0].kind, ActionOutcome.Kind.DAMAGE)
	check("amount > 0", r1[0].amount > 0, r1[0].amount)
	eq("tipo de dano", r1[0].damage_type, DamageType.Kind.CORTE)
	eq("alvo", r1[0].target, alvo)

	# mesma sequência de RNG, calculada à mão (mesma fórmula do attack.gd)
	seed(1)
	randi_range(user.vel, user.vel + 256)
	var dano: float = user.atk * randf_range(1.17, 1.56)
	dano = dano * (1 - (alvo.def / 512))
	if randi_range(0, 853) <= user.vel:
		dano = dano * 2
	seed(1)
	var r2: Array = Attack.new().resolve(user, [alvo], 1.25)
	eq("multiplicador", r2[0].amount, int(dano * 1.25))

	var rápido := Fake.new("Rápido", 100000, false)
	var r3: Array = Attack.new().resolve(user, [rápido], 1.0)
	eq("MISS", r3[0].kind, ActionOutcome.Kind.MISS)
	eq("MISS amount", r3[0].amount, 0)

	var pocao := HEALTH_ITEM.new()
	pocao.HEALTH_RESTORE = 10
	var r4: Array = UseItem.new().resolve(user, [pocao, alvo], 1.1)
	eq("HEAL", r4[0].kind, ActionOutcome.Kind.HEAL)
	eq("HEAL 11", r4[0].amount, 11)
	eq("HEAL tipo", r4[0].damage_type, DamageType.Kind.CURA)

	var grupo = load("res://scenes/encounters/testdummy.tscn").instantiate()
	root.add_child(grupo)
	await process_frame   # deixa o _ready do boneco rodar
	var dummy = grupo.get_child(0)
	eq("apply_damage aplicado", dummy.apply_damage(999), 27)
	eq("hp 0", dummy.get_hp(), 0)
	eq("morto", dummy.is_alive(), false)
	dummy.hp = 20
	eq("apply_heal clamp", dummy.apply_heal(50), 7)
	eq("hp max", dummy.get_hp(), dummy.get_max_hp())
	eq("classe", dummy.get_class_name(), "Boneco")
	eq("skills", dummy.get_skills(), [])
	finish()
