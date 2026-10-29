extends Control
## Abertura: log de inicialização digitado, depois fade pro papel e vai pro tutorial.

const FONTE := preload("res://assets/fonts/JetBrainsMono.ttf")
const CORES := {"k": "#c084fc", "m": "#60a5fa", "ok": "#4ade80", "av": "#f87171", "d": "#9ca3af"}
const SEG_POR_CHAR := 0.02
const TUTORIAL := "res://scenes/chapter_one/tutorial/Tutorial.tscn"

# [bbcode, pausa_depois]
# ponytail: os 5 nomes ficam inline; a Task 4 troca por ChecklistHud.ITENS_TESTE.
const LINHAS: Array = [
	["[color=#9ca3af]>[/color] SalaDeTestes v0.1 — iniciando sonho...", 0.3],
	["[color=#9ca3af]>[/color] carregando NPC \"Turin\" ........ [color=#4ade80]OK[/color]", 0.3],
	["[color=#9ca3af]>[/color] [color=#c084fc]new[/color] [color=#60a5fa]Teste[/color](turin) {", 0.1],
	["    [ ] turin.[color=#60a5fa]andar[/color]()", 0.1],
	["    [ ] turin.[color=#60a5fa]interagir[/color]()", 0.1],
	["    [ ] turin.[color=#60a5fa]correr[/color]()", 0.1],
	["    [ ] turin.[color=#60a5fa]lutar[/color]()", 0.1],
	["    [ ] turin.[color=#60a5fa]usarItem[/color]()", 0.1],
	["  }", 0.2],
	["[color=#f87171]> aviso: acesso desconhecido em 0x00DEEP[/color]   [color=#9ca3af](ignorado)[/color]", 0.3],
	["[color=#9ca3af]>[/color] transportando para a sala de testes...", 0.2],
]


func _ready() -> void:
	PlayerState.set_on_scene(true)
	var fundo := ColorRect.new()
	fundo.color = Color("#05070d")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var rotulo := RichTextLabel.new()
	rotulo.bbcode_enabled = true
	rotulo.scroll_active = false
	rotulo.add_theme_font_override("normal_font", FONTE)
	rotulo.add_theme_font_size_override("normal_font_size", 22)
	rotulo.add_theme_color_override("default_color", Color(CORES.d))
	rotulo.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotulo.offset_left = 60
	rotulo.offset_top = 60
	rotulo.offset_right = -60
	add_child(rotulo)

	var papel := ColorRect.new()
	papel.color = Color("#f4f1ea")
	papel.modulate.a = 0.0
	papel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(papel)

	rotulo.visible_characters = 0
	var antes := 0
	for linha in LINHAS:
		rotulo.append_text(linha[0] + "\n")
		var total := rotulo.get_total_character_count()
		var tp := create_tween()
		tp.tween_property(rotulo, "visible_characters", total, (total - antes) * SEG_POR_CHAR)
		await tp.finished
		antes = total
		await get_tree().create_timer(linha[1]).timeout

	var tw := create_tween()
	tw.tween_property(papel, "modulate:a", 1.0, 0.6)
	await tw.finished
	PlayerState.set_on_interface(false)
	PlayerState.set_on_scene(false)
	LevelWarp.change_level(TUTORIAL)
