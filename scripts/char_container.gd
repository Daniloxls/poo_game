extends MarginContainer
signal pressed

@onready var char_pic = $CharContainer/CharPic

@onready var level = $CharContainer/CharInfo/Level
@onready var char_name = $CharContainer/CharInfo/Name
@onready var pv_green_bar  = $CharContainer/CharPv/PvBar/GreenBar
@onready var pv_red_bar  = $CharContainer/CharPv/PvBar/RedBar
@onready var pv_num = $CharContainer/CharPv/PvContainer/PvNumber
@onready var pp_blue_bar = $CharContainer/CharPp/PpBar/BlueBar
@onready var pp_red_bar  = $CharContainer/CharPp/PpBar/RedBar
@onready var pp_num = $CharContainer/CharPp/PpContainer/PpNumber
@onready var animated_sprite_2d = $CharContainer/CharPic/AnimatedSprite2D

var personagem_name
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_char_name():
	return personagem_name
# Atualiza todas as informações mostradas para as atuais do personagem
# Controla as barras de pp e hp para terem as porcentagem certa
func set_char(character):
	personagem_name = character.get_name()
	var char_hp = character.get_hp()
	var char_max_hp = character.get_max_hp()
	var char_pp = character.get_pp()
	var char_max_pp = character.get_max_pp()
	var hp_ratio = float(char_hp)/char_max_hp
	
	char_pic.set_texture(character.get_pic())
	char_name.set_text(personagem_name)
	pv_green_bar.set_stretch_ratio(hp_ratio)
	pv_red_bar.set_stretch_ratio(1 - hp_ratio)
	if char_hp > 9:
		pv_num.set_text(str(char_hp) + "/" + str(char_max_hp))
	else:
		pv_num.set_text("0" + str(char_hp) + "/" + str(char_max_hp))
	var pp_ratio = float(char_pp)/char_max_pp
	pp_blue_bar.set_stretch_ratio(pp_ratio)
	pp_red_bar.set_stretch_ratio(1 - pp_ratio)
	if char_pp > 9:
		pp_num.set_text(str(char_pp) + "/" + str(char_max_pp))
	else:
		pp_num.set_text("0" + str(char_pp) + "/" + str(char_max_pp))
	level.set_text("Level " + str(character.get_level()))


func _on_button_pressed():
	pressed.emit(self)
	
	
func heal_char(heal_amount : int, personagem):
	var tween = create_tween()
	tween.set_parallel(true)
	var old_hp = personagem.get_hp()
	var max_hp = personagem.get_max_hp()
	var hp = min(old_hp + heal_amount, max_hp)
	var hp_ratio = float(hp)/max_hp
	tween.tween_callback(animated_sprite_2d.play.bind("healing"))
	tween.tween_property(pv_green_bar, "size_flags_stretch_ratio", hp_ratio, (max_hp/heal_amount) * 1.8)
	tween.tween_property(pv_red_bar, "size_flags_stretch_ratio", 1 - hp_ratio , (max_hp/heal_amount)* 1.8)
	tween.tween_method(set_char_health_number.bind(max_hp), old_hp, hp, (max_hp/heal_amount) * 1.8)
	
	tween.set_parallel(false)
	tween.tween_callback(animated_sprite_2d.play.bind("default"))
	
func set_char_health_number(hp, max_hp):
	if hp > 9:
		pv_num.set_text(str(hp) + "/" + str(max_hp))
	else:
		pv_num.set_text("0" + str(hp) + "/" + str(max_hp))
