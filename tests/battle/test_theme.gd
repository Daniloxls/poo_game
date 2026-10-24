extends "res://tests/battle/battle_test.gd"

func _initialize() -> void:
	var t := load("res://scenes/battle/ui/battle_theme.tres") as Theme
	check("tema carrega", t != null)
	if t == null:
		finish()
		return
	check("BattlePanel tem panel", t.has_stylebox("panel", "BattlePanel"))
	var p = t.get_stylebox("panel", "BattlePanel")
	check("BattlePanel é HardShadowStyleBox", p is HardShadowStyleBox)
	if p is HardShadowStyleBox:
		eq("cor do painel", p.bg_color, Color("#fff8e7"))
		eq("borda", p.border_width, 4)
		eq("sombra", p.shadow_offset, Vector2(5, 5))
		eq("margem horizontal", p.get_margin(SIDE_LEFT), 10.0)
		eq("margem vertical", p.get_margin(SIDE_TOP), 6.0)
	eq("quadro do topo", t.get_stylebox("panel", "StackFrameTop").bg_color, Color("#ffd23f"))
	eq("quadro inimigo", t.get_stylebox("panel", "StackFrameEnemy").bg_color, Color("#ffd6d2"))
	eq("pilha", t.get_stylebox("panel", "StackContainer").bg_color, Color("#2b2f3a"))
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		check("MethodButton " + s, t.has_stylebox(s, "MethodButton"))
	check("ClassTag", t.get_type_list().has("ClassTag"))
	check("fonte padrão", t.default_font.resource_path.ends_with("ChakraPetch-Bold.ttf"))
	check("MonoLabel fonte", t.get_font("font", "MonoLabel") is FontVariation)
	check("BattleFonts", BattleFonts.display() != null and BattleFonts.mono() != null)
	finish()
