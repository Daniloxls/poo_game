extends Node2D
## Queda: fundo preto, Turin à deriva e código subindo rápido. Dura 3 s e abre o Deep Code.

const FONTE := preload("res://assets/fonts/JetBrainsMono.ttf")
const CORES := ["#c084fc", "#60a5fa", "#4ade80", "#f87171", "#9ca3af"]
const LINHAS := ["public void andar(Direcao d) {", "turin.cair();", "0x00DEEP", "if (chao == null) {",
	"return null;", "int hp = -1;", "throw new Queda();", "}", "segfault em 0x00DEEP", "this.mundo = ???;"]

@onready var turin: AnimatedSprite2D = $Turin


func _ready() -> void:
	var p: Node = load("res://entities/player/Player.tscn").instantiate()
	turin.sprite_frames = p.get_node("AnimatedSprite2D").sprite_frames
	p.free()
	turin.play("idle_down")
	var tela := get_viewport_rect().size
	turin.position = tela / 2
	turin.scale = Vector2.ONE * 0.4
	var deriva := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	deriva.tween_property(turin, "position:x", tela.x / 2 + 20, 0.8)
	deriva.tween_property(turin, "position:x", tela.x / 2 - 20, 0.8)
	for i in 30:
		var l := Label.new()
		l.text = LINHAS.pick_random()
		l.add_theme_font_override("font", FONTE)
		l.add_theme_font_size_override("font_size", 18)
		var cor := Color(CORES.pick_random())
		cor.a = randf_range(0.4, 0.7)
		l.add_theme_color_override("font_color", cor)
		l.position = Vector2(randf() * tela.x, tela.y + randf() * 1500)
		add_child(l)
		create_tween().tween_property(l, "position:y", -2000.0, randf_range(1.0, 1.6) * 3.0)
	await get_tree().create_timer(3.0).timeout
	PlayerState.set_on_scene(false)
	LevelWarp.change_level("res://scenes/chapter_one/deep_code/DeepCode.tscn")
