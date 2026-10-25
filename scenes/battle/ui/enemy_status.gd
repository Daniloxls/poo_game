class_name EnemyStatus
extends VBoxContainer
## Lista de inimigos no canto superior esquerdo: retrato, nome, classe e HP.

const THEME := preload("res://scenes/battle/ui/battle_theme.tres")

var _rows := {}  # inimigo -> {row, bar}


func _ready() -> void:
	theme = THEME
	add_theme_constant_override("separation", 8)


func add_enemy(enemy) -> void:
	var row := PanelContainer.new()
	row.theme_type_variation = &"BattlePanel"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	row.add_child(h)
	var portrait = enemy.get("portrait")
	if portrait is Texture2D:
		var tr := TextureRect.new()
		tr.texture = portrait
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(38, 38)
		h.add_child(tr)
	else:
		var cr := ColorRect.new()  # espaço reservado
		cr.color = Color("#b9b2a0")
		cr.custom_minimum_size = Vector2(38, 38)
		h.add_child(cr)
	var v := VBoxContainer.new()
	h.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var name_l := Label.new()
	name_l.text = enemy.get_nome()
	name_l.theme_type_variation = &"MonoLabel"
	name_l.add_theme_color_override("font_color", Color("#1b1b1b"))
	top.add_child(name_l)
	var tag := Label.new()
	tag.text = enemy.get_class_name()
	tag.theme_type_variation = &"ClassTag"
	top.add_child(tag)
	var bar := HpBar.new()
	bar.setup(enemy.get_max_hp(), enemy.get_hp(), Color("#e8463a"))
	v.add_child(bar)
	add_child(row)
	_rows[enemy] = {"row": row, "bar": bar}


func refresh(enemy) -> void:
	if _rows.has(enemy):
		_rows[enemy].bar.set_value(enemy.get_hp())


func remove_enemy(enemy) -> void:
	if not _rows.has(enemy):
		return
	var row: Control = _rows[enemy].row
	_rows.erase(enemy)
	var tw := row.create_tween()  # só modulate: o container manda na posição
	tw.tween_property(row, "modulate:a", 0.0, 0.3)
	tw.tween_callback(row.queue_free)


## Fim da batalha: some com todas as linhas na hora.
func clear() -> void:
	for c in get_children():
		c.queue_free()
	_rows.clear()
