extends RefCounted


func resolve(user, targets: Array, multiplier: float) -> Array[ActionOutcome]:
	var target = targets[0]
	var char_atk = user.get_atk()
	var char_vel = user.get_vel()
	var target_def = target.get_def()
	var target_vel = target.get_vel()
	var out: Array[ActionOutcome] = []

	if target_vel >= randi_range(char_vel + 0, char_vel + 256):
		out.append(ActionOutcome.make(target, ActionOutcome.Kind.MISS))
		return out
	var damage = char_atk * randf_range(1.17 , 1.56)
	damage = damage * (1 - (target_def/ 512))
	var crit := false
	if randi_range(0, 853) <= char_vel:
		damage = damage * 2
		crit = true
	out.append(ActionOutcome.make(target, ActionOutcome.Kind.DAMAGE, int(damage * multiplier), DamageType.Kind.CORTE, crit))
	return out
