class_name BattlePacing
extends Node
## Ritmo da batalha: único lugar que mexe em Engine.time_scale.
## Segurar confirmar = 2x; um toque pula a espera atual.

signal skipped

var speed := 1.0
var instant := false  # testes: toda espera retorna na hora
## Um toque pula o RESTO da sequência: trava até BattleFx limpar no início/fim.
var latched := false
var _slow_id := 0


class Gate extends RefCounted:
	signal fired


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	restore()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action("ui_accept") or event.is_echo():
		return
	if event.is_pressed():
		speed = 2.0
		latched = true
		Engine.time_scale = 1.0  # pular durante câmera lenta/hit-stop
		skipped.emit()
	else:
		speed = 1.0


## Espera ignorando o time_scale; termina antes se houver skip.
func wait(seconds: float) -> void:
	if instant or latched or seconds <= 0.0 or not is_inside_tree():
		return
	var g := Gate.new()
	var t := get_tree().create_timer(seconds / speed, true, false, true)
	t.timeout.connect(g.fired.emit, CONNECT_ONE_SHOT)
	skipped.connect(g.fired.emit, CONNECT_ONE_SHOT)
	await g.fired


func slow_motion(seconds: float, scale: float) -> void:
	if instant:
		return
	_slow_id += 1
	var id := _slow_id
	Engine.time_scale = scale
	await wait(seconds)
	if id == _slow_id:  # sobreposição: só a última restaura
		Engine.time_scale = 1.0


func hitstop(seconds: float) -> void:
	await slow_motion(seconds, 0.02)


func restore() -> void:
	_slow_id += 1
	Engine.time_scale = 1.0
	speed = 1.0
