class_name DamageType
## Tipos de dano: cada um tem cor e nome para os números e a UI.

enum Kind { CORTE, SOCO, FOGO, MAGIA, CURA }

static func color(kind: Kind) -> Color:
	match kind:
		Kind.CORTE: return Color("#e8463a")
		Kind.SOCO: return Color("#ffb347")
		Kind.FOGO: return Color("#ff7a1a")
		Kind.MAGIA: return Color("#9b5de5")
		_: return Color("#7ee787")

static func label(kind: Kind) -> String:
	return ["corte", "soco", "fogo", "magia", "cura"][kind]
