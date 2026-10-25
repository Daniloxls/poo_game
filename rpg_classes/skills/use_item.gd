extends RefCounted


func resolve(user, targets: Array, multiplier: float) -> Array[ActionOutcome]:
	var item = targets[0]
	var target = targets[1]
	var out: Array[ActionOutcome] = []
	match(item.get_type()):
		ITEM.Item_type.HEALTH:
			out.append(ActionOutcome.make(target, ActionOutcome.Kind.HEAL, int(item.get_health_restore() * multiplier), DamageType.Kind.CURA))
	return out
