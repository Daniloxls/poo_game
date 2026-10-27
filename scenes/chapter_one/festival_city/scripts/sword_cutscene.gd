extends Node2D

# Cutscene do roubo da espada. A cena toda está no AnimationPlayer "Animacao"
# (animação "roubo", em roubo_espada.tres): posições, sprites, câmera e clarões.
# Este script só tem o que a linha do tempo chama pelas trilhas de método.

@onready var player = get_node("../Player")
@onready var camera: Camera2D = get_node("../Player/Camera2D")
@onready var animacao: AnimationPlayer = $Animacao
@onready var magic = $Magic
@onready var continua = $BlackScreen/Label

const ESPADA = preload("res://scenes/chapter_one/festival_city/dialogos/espada.dialogue")
const MUSICA = "res://assets/bgm/qubodup-yd-DarkShrineLoop-OpenGameArt.mp3"

var _falando := false   # conversa iniciada por _falar_junto ainda em andamento
var _tremor: Tween


# Não bloqueia quem chama (excalibur_npc não dá await).
func play():
	PlayerState.set_on_scene(true)
	animacao.play("roubo")


func _preparar() -> void:
	player.set_position(Vector2(-7, -38213))
	player.set_sprite("idle_up")
	MusicPlayer.set_stream(load(MUSICA))


func _musica() -> void:
	MusicPlayer.play()


func _fim() -> void:
	continua.show()


func _cena(n: int) -> void:
	if not await Dialogo.iniciar(ESPADA, "cena_%d" % n):
		push_warning("sword_cutscene: cena_%d recusada (já há diálogo ativo)" % n)


# A linha do tempo para enquanto a conversa n acontece.
func _falar(n: int) -> void:
	animacao.pause()
	await _cena(n)
	animacao.play()


# A conversa n acontece junto com a animação ("Turin, cuidado!" com a magia).
func _falar_junto(n: int) -> void:
	_falando = true
	await _cena(n)
	_falando = false


# Segura a linha do tempo até a conversa de _falar_junto terminar.
func _esperar_falas() -> void:
	if not _falando:
		return
	animacao.pause()
	while _falando:
		await get_tree().process_frame
	animacao.play()


# Turin dá um pulinho para trás, de susto.
func _recuar(distancia: float) -> void:
	var p: Vector2 = player.position
	var t := create_tween()
	t.tween_property(player, "position", p + Vector2(0, distancia * 1.25), 0.15).set_ease(Tween.EASE_OUT)
	t.tween_property(player, "position", p + Vector2(0, distancia), 0.2).set_ease(Tween.EASE_IN)


# Tremor de tela que diminui até parar. Usa a posição da câmera: o offset é da linha do tempo.
func tremer(duracao: float, forca: float) -> void:
	if _tremor:
		_tremor.kill()
	var base := Vector2(101, 55)   # posição da câmera no Player (City.tscn)
	_tremor = create_tween()
	var passos := int(duracao / 0.04)
	for i in passos:
		var f := forca * (1.0 - float(i) / passos)
		_tremor.tween_property(camera, "position", base + Vector2(randf_range(-f, f), randf_range(-f, f)), 0.04)
	_tremor.tween_property(camera, "position", base, 0.04)

