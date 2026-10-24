class_name ActionOutcome
extends RefCounted
## Resultado de uma habilidade sobre um alvo (a UI anima a partir disso).

enum Kind { DAMAGE, HEAL, MISS }

var target
var kind: Kind = Kind.DAMAGE
var amount: int = 0
var crit: bool = false
var damage_type: DamageType.Kind = DamageType.Kind.CORTE


static func make(p_target, p_kind: Kind, p_amount := 0, p_type := DamageType.Kind.CORTE, p_crit := false) -> ActionOutcome:
	var o := ActionOutcome.new()
	o.target = p_target
	o.kind = p_kind
	o.amount = p_amount
	o.damage_type = p_type
	o.crit = p_crit
	return o
