class_name HitImpact
extends RefCounted
## Intensidade do impacto de um golpe: hit-stop, tremor e quadro de impacto.

const KILL_SLOWMO_SECONDS := 0.4
const KILL_SLOWMO_SCALE := 0.3
const LAST_KILL_SLOWMO_SECONDS := 0.8


## Dano relativo ao HP máximo, entre 0 e 1.
static func impact(damage: int, max_hp: int) -> float:
	return clampf(damage / float(max_hp), 0.0, 1.0)


static func hitstop_seconds(impact: float, crit: bool) -> float:
	return minf(lerpf(0.03, 0.12, impact) + (0.03 if crit else 0.0), 0.12)


static func shake_pixels(impact: float, crit: bool) -> float:
	return lerpf(0.0, 14.0, impact) + (6.0 if crit else 0.0)


static func impact_frame(impact: float, crit: bool) -> bool:
	return impact >= 0.25 or crit
