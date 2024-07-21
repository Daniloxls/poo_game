extends HBoxContainer

@onready var level = $CharInfo/Level
@onready var char_name = $CharInfo/Name
@onready var pv_green_bar  = $CharPv/PvBar/GreenBar
@onready var pv_red_bar  = $CharPv/PvBar/RedBar
@onready var pv_num = $CharPv/PvContainer/PvNumber
@onready var pp_blue_bar = $CharPp/PpBar/BlueBar
@onready var pp_red_bar  = $CharPp/PpBar/RedBar
@onready var pp_num = $CharPp/PpContainer/PpNumber

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Atualiza todas as informações mostradas para as atuais do personagem
# Controla as barras de pp e hp para terem as porcentagem certa
func update_char(character):
	var char_hp = character.get_hp()
	var char_max_hp = character.get_max_hp()
	var char_pp = character.get_mp()
	var char_max_pp = character.get_max_mp()
	var hp_ratio = float(char_hp)/char_max_hp
	char_name.set_text(character.get_name())
	pv_green_bar.set_stretch_ratio(hp_ratio)
	pv_red_bar.set_stretch_ratio(1 - hp_ratio)
	pv_num.set_text(str(char_hp) + "/" + str(char_max_hp))
	var pp_ratio = float(char_pp)/char_max_pp
	pp_blue_bar.set_stretch_ratio(pp_ratio)
	pp_red_bar.set_stretch_ratio(1 - pp_ratio)
	pp_num.set_text(str(char_pp) + "/" + str(char_max_pp))
	level.set_text("Level " + str(character.get_level()))
