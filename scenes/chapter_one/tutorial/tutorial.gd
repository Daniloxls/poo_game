extends Node2D
## Sala de testes do tutorial: cada sala abre a próxima quando seu item do checklist marca.

signal battle_tutorial_end

@onready var player = $Player
@onready var up_arrow = $DesenhosParede/UpArrow
@onready var left_arrow = $DesenhosParede/LeftArrow
@onready var right_arrow = $DesenhosParede/RightArrow
@onready var down_arrow = $DesenhosParede/DownArrow

var hud: ChecklistHud
var _rachadura := Rachadura.new()
var direcoes := {}   # direções já apertadas na sala 1
var alavanca_puxada := false
var bau_aberto := false
var chegou_na_saida := false


func _ready():
	PlayerState.set_on_interface(false)
	var turin = Party.get_node("Turin")
	turin.hp = turin.get_max_hp()
	player.modulate.a = 0.0
	create_tween().tween_property(player, "modulate:a", 1.0, 0.8)   # Turin rabiscado no lugar
	hud = ChecklistHud.new()
	add_child(hud)
	add_child(_rachadura)
	$Alavanca.puxada.connect(_on_alavanca_puxada)
	$Bau.aberto.connect(_on_bau_aberto)
	$PortaoTemporizado.atravessou.connect(hud.marcar.bind("correr"))
	$Saida/Gatilho.body_entered.connect(_chegou_na_saida)
	Battle.connect("battle_won", _on_tutorial_battle_end)


func _process(_delta):
	hud.visible = not Battle.visible
	for acao in ["up", "down", "left", "right"]:
		if Input.is_action_just_pressed(acao):
			direcoes[acao] = true
	if direcoes.size() == 4 and not hud.marcado("andar"):
		hud.marcar("andar")
		$Saidas/Sala1.abrir()
	if Input.is_action_just_pressed("up"):
		up_arrow.set_frame(1)
	if Input.is_action_just_pressed("down"):
		down_arrow.set_frame(1)
	if Input.is_action_just_pressed("left"):
		left_arrow.set_frame(1)
	if Input.is_action_just_pressed("right"):
		right_arrow.set_frame(1)
	if Input.is_action_just_released("up"):
		up_arrow.set_frame(0)
	if Input.is_action_just_released("down"):
		down_arrow.set_frame(0)
	if Input.is_action_just_released("left"):
		left_arrow.set_frame(0)
	if Input.is_action_just_released("right"):
		right_arrow.set_frame(0)


func _on_alavanca_puxada():
	alavanca_puxada = true
	_checar_interagir()


func _on_bau_aberto():
	bau_aberto = true
	_checar_interagir()


# interagir() pede as duas coisas, em qualquer ordem.
func _checar_interagir():
	if alavanca_puxada and bau_aberto:
		hud.marcar("interagir")
		$Saidas/Sala2.abrir()


func _on_tutorial_battle_end():
	battle_tutorial_end.emit()
	hud.marcar("lutar")
	hud.marcar("usarItem")
	$Saidas/Sala4.abrir()
	_rachadura.agitar(hud)


func _chegou_na_saida(corpo):
	if chegou_na_saida or not corpo.is_in_group("Player"):
		return
	chegou_na_saida = true
	_rachadura.iniciar(hud, player)
