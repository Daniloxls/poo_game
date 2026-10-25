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

static var _icons := {}


# Glifo branco 20x20 com contorno escuro de 2 px (provisório até haver arte).
static func icon(kind: Kind) -> Texture2D:
	if _icons.has(kind):
		return _icons[kind]
	const N := 20
	var shape := Image.create(N, N, false, Image.FORMAT_L8)
	var c := Vector2(9.5, 9.5)
	for y in N:
		for x in N:
			var p := Vector2(x, y) - c
			var on := false
			match kind:
				Kind.CORTE: on = absf(p.x + p.y) < 2.2 and p.length() < 9
				Kind.SOCO: on = p.length() < 6.5
				Kind.FOGO: on = Vector2(p.x, p.y - 3).length() < 6.0 or (p.y <= 3 and p.y > -9 and absf(p.x) < (p.y + 9) / 12.0 * 6.0)
				Kind.MAGIA: on = absf(p.x) + absf(p.y) < 3.0 or (absf(p.x) < 1.5 and absf(p.y) < 9) or (absf(p.y) < 1.5 and absf(p.x) < 9)
				_: on = (absf(p.x) < 2.5 and absf(p.y) < 8) or (absf(p.y) < 2.5 and absf(p.x) < 8)
			shape.set_pixel(x, y, Color.WHITE if on else Color.BLACK)
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in N:
		for x in N:
			if shape.get_pixel(x, y).r > 0.5:
				img.set_pixel(x, y, Color.WHITE)
				continue
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var xx := x + dx
					var yy := y + dy
					if xx >= 0 and yy >= 0 and xx < N and yy < N and shape.get_pixel(xx, yy).r > 0.5:
						img.set_pixel(x, y, Color("#1b1b1b"))
	var tex := ImageTexture.create_from_image(img)
	_icons[kind] = tex
	return tex
