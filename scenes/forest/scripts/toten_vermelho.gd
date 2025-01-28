extends "res://scripts/interact.gd"

@onready var forest_scene:Node2D = get_parent()

var can_click:bool = false
var ativado:bool = true

func _ready():
	nome = "Class Totem Vermelho"
	codigo = {"boolean ativado": ativado}
	metodos = {
	"2" : [""],
	"3": ["Ativação(){"] ,
	"4" : ["\tif(TotemVerde.ativo)"],
	"5" : ["\t\tativado = true;"],
	"6" : ["\t}else{"],
	"7" : ["\t\tTotemAzul.ativo = false;"],
	"8" : ["\t\tTotemAmarelo.ativo = false;"],
	"9" : ["\t\tTotemVerde.ativo = false;\n}"]
	}

func interaction()->void:
	if !forest_scene.totens_ativos:
		if ativado:
			ativado = false
		else:
			ativado = true
		forest_scene.check_totem(name)
		animation_totem()

func animation_totem()->void:
	if ativado:
		var tween:Tween = create_tween()
		tween.tween_property(self,"modulate:r",0.83,0.2)
		ativado = true
		codigo = {"boolean ativado": ativado}
		
	else:
		var tween:Tween = create_tween()
		tween.tween_property(self,"modulate:r",0.35,0.2)
		ativado = false
		codigo = {"boolean ativado": ativado}

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("c") and can_click:
		codebox.depure(self)

func _on_area_2d_area_entered(_area: Area2D) -> void:
	can_click = true

func _on_area_2d_area_exited(_area: Area2D) -> void:
	can_click = false
