class_name BattlePacing
extends Node
## Ritmo da batalha: único lugar que mexe em Engine.time_scale.
## Segurar confirmar = 2x; um toque pula a espera atual.

signal skipped

var speed := 1.0
var instant := false  # testes: toda espera retorna na hora


class Gate extends RefCounted:
	signal fired


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action("ui_accept") or event.is_echo():
		return
	if event.is_pressed():
		speed = 2.0
		Engine.time_scale = 1.0  # pular durante câmera lenta/hit-stop
		skipped.emit()
	else:
		speed = 1.0


## Espera ignorando o time_scale; termina antes se houver skip.
func wait(seconds: float) -> void:
	if instant or seconds <= 0.0:
		return
	var g := Gate.new()
	var t := get_tree().create_timer(seconds / speed, true, false, true)
	t.timeout.connect(g.fired.emit, CONNECT_ONE_SHOT)
	skipped.connect(g.fired.emit, CONNECT_ONE_SHOT)
	await g.fired


func slow_motion(seconds: float, scale: float) -> void:
	if instant:
		return
	Engine.time_scale = scale
	await wait(seconds)
	Engine.time_scale = 1.0


func hitstop(seconds: float) -> void:
	await slow_motion(seconds, 0.02)


func restore() -> void:
	Engine.time_scale = 1.0
	speed = 1.0
