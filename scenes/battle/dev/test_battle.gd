extends Node
## Batalha de teste (só dev, F6): grupo de 2 para um membro interromper o outro na pilha,
## e uma habilidade por tipo de dano. O Party volta ao normal ao sair.

const NOMES := {
	DamageType.Kind.CORTE: "Cortar",
	DamageType.Kind.SOCO: "Socar",
	DamageType.Kind.FOGO: "Queimar",
	DamageType.Kind.MAGIA: "Enfeitiçar",
}

var _turin2: Node
var _classe_original


func _ready() -> void:
	var turin = Party.get_child(0)
	_classe_original = turin.rpg_class
	var classe := RPG_CLASS.new()
	classe.CLASS_NAME = "Teste"
	for tipo in NOMES:
		classe.SKILLS.append(_skill(NOMES[tipo], tipo))
	var cura := _skill("Curar", DamageType.Kind.CURA)
	cura.TARGET = [SKILL.Targets.ALLY]
	cura.SKILL_SCRIPT = load("res://scenes/battle/dev/dev_heal.gd")
	classe.SKILLS.append(cura)

	_turin2 = load("res://scenes/party/BattleTurin.tscn").instantiate()
	_turin2.set_script(load("res://scenes/party/scripts/battle_turin.gd"))
	_turin2.name = "Turin2"
	_turin2.position = Vector2(-40, 110)
	_turin2.scale = Vector2(4, 4)
	Party.add_child(_turin2)  # o _ready do Turin roda aqui; o que muda vem depois
	_turin2.nome = "Turin2"
	_turin2.vel = 5
	for m in [turin, _turin2]:
		m.rpg_class = classe

	await get_tree().process_frame
	Battle.start_battle("res://scenes/encounters/dev_test_enemies.tscn")


func _skill(nome: String, tipo: int) -> SKILL:
	var s: SKILL = load("res://rpg_classes/skills/attack.tres").duplicate()
	s.SKLL_NAME = nome
	s.DAMAGE_TYPE = tipo
	return s


func _exit_tree() -> void:
	if is_instance_valid(_turin2):
		Party.remove_child(_turin2)
		_turin2.free()
	if is_instance_valid(Party) and Party.get_child_count() > 0:
		Party.get_child(0).rpg_class = _classe_original
