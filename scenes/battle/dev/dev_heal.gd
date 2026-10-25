extends RefCounted
## Cura de teste (só dev): devolve vida ao aliado alvo.


func resolve(_user, targets: Array, multiplier: float) -> Array[ActionOutcome]:
	var out: Array[ActionOutcome] = []
	out.append(ActionOutcome.make(targets[0], ActionOutcome.Kind.HEAL, int(8 * multiplier), DamageType.Kind.CURA))
	return out
