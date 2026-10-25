class_name PartyStatus
extends PanelContainer
## Painel do grupo (canto inferior direito): nome, HP e PP; o ativo fica destacado.

const THEME := preload("res://scenes/battle/ui/battle_theme.tres")

var _rows := {}  # membro -> {sb, hp, pp}
var _box: VBoxContainer


func _init() -> void:
	theme = THEME
	theme_type_variation = &"BattlePanel"
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)


func set_party(members: Array) -> void:
	for c in _box.get_children():
		c.queue_free()
	_rows.clear()
	for m in members:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		_box.add_child(h)
		var chip := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		chip.add_theme_stylebox_override("panel", sb)
		var l := Label.new()
		l.text = m.get_nome()
		l.theme_type_variation = &"MonoLabel"
		l.add_theme_color_override("font_color", Color("#1b1b1b"))
		chip.custom_minimum_size = Vector2(90, 0)
		chip.add_child(l)
		h.add_child(chip)
		var bars := VBoxContainer.new()
		bars.add_theme_constant_override("separation", 2)
		h.add_child(bars)
		var hp := HpBar.new()
		hp.setup(m.get_max_hp(), m.get_hp(), Color("#3fae5a"))
		bars.add_child(hp)
		var pp := HpBar.new()
		pp.setup(m.get_max_pp(), m.get_pp(), Color("#3a7be8"))
		pp.custom_minimum_size = Vector2(120, 10)
		bars.add_child(pp)
		_rows[m] = {"sb": sb, "hp": hp, "pp": pp}


func refresh(member) -> void:
	if _rows.has(member):
		_rows[member].hp.set_value(member.get_hp())
		_rows[member].pp.set_value(member.get_pp())


func set_active(member) -> void:
	for m in _rows:
		_rows[m].sb.bg_color = Color("#ffd23f") if m == member else Color(0, 0, 0, 0)
