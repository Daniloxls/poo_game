extends SceneTree
## Gera scenes/battle/ui/battle_theme.tres. Rodar:
## godot --headless --path . --script res://tools/build_battle_theme.gd

const SAIDA := "res://scenes/battle/ui/battle_theme.tres"

func _caixa(bg: Color, borda := 4, sombra := Vector2(5, 5), borda_cor := Color("#1b1b1b")) -> HardShadowStyleBox:
	var b := HardShadowStyleBox.new()
	b.bg_color = bg
	b.border_width = borda
	b.shadow_offset = sombra
	b.border_color = borda_cor
	return b

func _painel(t: Theme, tipo: String, bg: Color) -> void:
	t.set_type_variation(tipo, "PanelContainer")
	t.set_stylebox("panel", tipo, _caixa(bg))

func _init() -> void:
	var t := Theme.new()
	t.default_font = load("res://assets/fonts/ChakraPetch-Bold.ttf")
	t.default_font_size = 18

	_painel(t, "BattlePanel", Color("#fff8e7"))
	_painel(t, "StackContainer", Color("#2b2f3a"))
	_painel(t, "StackFrame", Color("#fff8e7"))
	_painel(t, "StackFrameTop", Color("#ffd23f"))
	_painel(t, "StackFrameEnemy", Color("#ffd6d2"))

	# botões de método: vermelho por padrão; cada botão troca a cor em runtime
	var v := Color("#e8463a")
	t.set_type_variation("MethodButton", "Button")
	t.set_stylebox("normal", "MethodButton", _caixa(v))
	t.set_stylebox("hover", "MethodButton", _caixa(v.lightened(0.2)))
	t.set_stylebox("pressed", "MethodButton", _caixa(v.darkened(0.1), 4, Vector2(2, 2)))
	t.set_stylebox("focus", "MethodButton", _caixa(v, 6))
	t.set_stylebox("disabled", "MethodButton", _caixa(Color("#b8b8b8"), 4, Vector2(3, 3), Color("#6b6b6b")))
	t.set_color("font_color", "MethodButton", Color.WHITE)
	t.set_color("font_outline_color", "MethodButton", Color("#1b1b1b"))
	t.set_constant("outline_size", "MethodButton", 4)

	t.set_type_variation("ClassTag", "Label")
	t.set_color("font_color", "ClassTag", Color("#1b1b1b"))
	t.set_font_size("font_size", "ClassTag", 14)

	t.set_type_variation("MonoLabel", "Label")
	t.set_font("font", "MonoLabel", BattleFonts.mono())

	var err := ResourceSaver.save(t, SAIDA)
	print("tema salvo: ", error_string(err))
	quit(0 if err == OK else 1)
