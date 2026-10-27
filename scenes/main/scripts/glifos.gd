extends Control
## Glifos de código ({ } ; 01 </>) subindo de um objeto depurável.
## A cor vem de 'cor_glifos' no objeto (interact.gd), editável no Inspetor.

const GLIFOS := ["{ }", ";", "01", "</>", "()", "=>", "if", "10"]
const MAXIMO := 7          # glifos ao mesmo tempo num objeto grande (a tenda)
const AREA_POR_GLIFO := 150000.0   # objetos menores ganham menos glifos (mínimo 3)
const VIDA := 1.6          # segundos de cada glifo
const SUBIDA := 450.0      # quanto sobe, em pixels do mundo
const TAMANHO := 190       # tamanho da letra, em pixels do mundo (~20 px com o zoom da cidade)
const CONTORNO := Color("#1b1b1b")

var _fonte := FontVariation.new()
var _glifos: Array = []    # {pos, texto, idade}
var _espera := 0.0


func _ready() -> void:
	_fonte.base_font = preload("res://assets/fonts/JetBrainsMono.ttf")
	_fonte.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}


func cor() -> Color:
	var c = get_parent().get("cor_glifos")
	return c if c is Color else Color("#bff6ff")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var escala := get_global_transform().get_scale()
	var maximo := clampi(int(size.x * escala.x * size.y * escala.y / AREA_POR_GLIFO), 3, MAXIMO)
	_espera -= delta
	if _espera <= 0.0 and _glifos.size() < maximo:
		_espera = VIDA / maximo
		_glifos.append({"pos": _lugar_livre(), "texto": GLIFOS.pick_random(), "idade": 0.0})
	for g in _glifos:
		g.idade += delta
	_glifos = _glifos.filter(func(g): return g.idade < VIDA)
	queue_redraw()


# Melhor de 4 sorteios: o ponto mais longe dos glifos que já estão subindo.
func _lugar_livre() -> Vector2:
	var melhor := Vector2.ZERO
	var folga := -1.0
	for i in 4:
		var p := Vector2(randf_range(0.15, 0.85) * size.x, randf_range(0.45, 0.9) * size.y)
		var d := INF
		for g in _glifos:
			d = minf(d, p.distance_to(g.pos))
		if d > folga:
			melhor = p
			folga = d
	return melhor


func _draw() -> void:
	# O objeto pode estar esticado (a tenda é 6.5 x 3.7): desfaz a escala para a letra não deformar.
	var escala := get_global_transform().get_scale()
	var c := cor()
	for g in _glifos:
		var t: float = g.idade / VIDA
		var a := sin(t * PI)
		draw_set_transform(g.pos - Vector2(0, SUBIDA * t / escala.y), 0.0, Vector2.ONE / escala)
		var x := -_fonte.get_string_size(g.texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANHO).x / 2
		draw_string_outline(_fonte, Vector2(x, 0), g.texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANHO, TAMANHO / 5, Color(CONTORNO, a))
		draw_string(_fonte, Vector2(x, 0), g.texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANHO, Color(c, c.a * a))
	draw_set_transform(Vector2.ZERO)
