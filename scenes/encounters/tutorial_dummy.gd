extends "res://scenes/encounters/test_dummy.gd"
## Boneco do tutorial: não cai antes da Poção, dá um golpe "com glitch" e nunca derruba Turin.

const LIMIAR := 13  # piso de HP do boneco até a Poção ser usada
const VIDA_APOS_GLITCH := 3
const POCAO := preload("res://scenes/items/repo/potion.tres")
const ATTACK := preload("res://rpg_classes/skills/attack.tres")

var pocao_usada := false
var glitch_feito := false


static func dano_limitado(hp: int, dano: int, piso: int) -> int:
	return clampi(dano, 0, maxi(hp - piso, 0))


func _ready():
	super()
	var tem: bool = Inventory.mochila.itens.any(func(i): return i.ITEM_NAME == POCAO.ITEM_NAME and i.QUANTITY > 0)
	if not tem:
		Inventory.mochila.adicionar(POCAO)  # antes de ouvir mudou: senão contaria como usada
	Inventory.mochila.mudou.connect(_on_mochila_mudou)
	Battle.turn_started.connect(_on_turn_started)


func _exit_tree() -> void:
	Inventory.mochila.mudou.disconnect(_on_mochila_mudou)
	Battle.turn_started.disconnect(_on_turn_started)


# Na batalha a mochila só muda quando alguém usa um item.
func _on_mochila_mudou() -> void:
	pocao_usada = true


func _on_turn_started(who) -> void:
	if not who.is_party_member():
		Battle.hide_hint()
		return
	var travado := glitch_feito and not pocao_usada
	Battle.locked_skills = [ATTACK] if travado else []
	if travado:
		Battle.show_hint("Atacar está fora do ar! Use usarItem() → Poção")
	elif hp == max_hp:
		Battle.show_hint("Escolha atacar()")
	else:
		Battle.hide_hint()


func apply_damage(amount: int) -> int:
	if not pocao_usada:
		amount = dano_limitado(hp, amount, LIMIAR)
	return super(amount)


func choose_action(party: Array, enemies: Array) -> EnemyAction:
	var action := EnemyAction.new()
	var vivos := party.filter(func(c): return c.is_alive())
	if vivos.is_empty():
		return action
	var alvo = vivos.pick_random()
	var dano: int
	if hp <= LIMIAR and not glitch_feito and not pocao_usada:
		glitch_feito = true
		_glitch()
		dano = maxi(alvo.hp - VIDA_APOS_GLITCH, 0)
	else:
		dano = dano_limitado(alvo.hp, randi_range(2, 5), 1)
	action.outcomes.append(ActionOutcome.make(alvo, ActionOutcome.Kind.DAMAGE, dano, DamageType.Kind.SOCO))
	return action


# Tremida com cor estourada (~0.4 s): a interferência que ninguém explica.
func _glitch() -> void:
	var t := create_tween()
	for i in 8:
		t.tween_callback(func():
			sprite_2d.offset = Vector2(randf_range(-6, 6), randf_range(-3, 3))
			modulate = [Color(1.6, 0.4, 0.6), Color(0.4, 1.4, 1.6), Color.WHITE].pick_random())
		t.tween_interval(0.05)
	t.tween_callback(func():
		sprite_2d.offset = Vector2.ZERO
		modulate = Color.WHITE)
