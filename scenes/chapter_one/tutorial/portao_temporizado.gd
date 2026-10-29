extends "res://scenes/main/scripts/interact.gd"
## Alavanca que abre um portão por pouco tempo: só dá para passar correndo.

signal atravessou

# Menor que o tempo de andar até o portão, maior que o de correr (com folga).
@export var tempo_aberto := 0.9

const ABERTO := 1
const FECHADO := 0

var passou := false
var aberto := false
var fechar_ao_sair := false   # o tempo acabou mas o jogador ainda está no vão

@onready var sprite = $Sprite
@onready var portao_sprite = $Portao/Sprite
@onready var shape = $Portao/Shape
@onready var ocupado = $Ocupado
@onready var passagem = $Passagem
var timer: Timer


func _ready():
	ready_drop_menu()
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_acabou_tempo)
	add_child(timer)
	passagem.body_entered.connect(_entrou_passagem)
	ocupado.body_exited.connect(_saiu_do_vao)


func interaction():
	if aberto or passou:
		return
	_definir_aberto(true)
	timer.start(tempo_aberto)


func _definir_aberto(valor: bool):
	aberto = valor
	shape.disabled = valor
	portao_sprite.set_frame(ABERTO if valor else FECHADO)
	sprite.set_frame(ABERTO if valor else FECHADO)


func _jogador_no_vao(ignorar = null) -> bool:
	return ocupado.get_overlapping_bodies().any(func(b): return b != ignorar and b.is_in_group("Player"))


func _acabou_tempo():
	if passou:
		return
	if _jogador_no_vao():
		fechar_ao_sair = true
	else:
		_definir_aberto(false)


func _saiu_do_vao(corpo):
	if fechar_ao_sair and not passou and not _jogador_no_vao(corpo):
		fechar_ao_sair = false
		_definir_aberto.call_deferred(false)   # não dá para ligar colisão durante a física


func _entrou_passagem(corpo):
	if passou or not corpo.is_in_group("Player"):
		return
	passou = true
	timer.stop()
	atravessou.emit()
