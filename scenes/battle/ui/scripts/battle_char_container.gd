extends HBoxContainer

signal animation_end

@onready var char_name = $CharName
@onready var hp_bar = $HPBar
@onready var hp_label = $HPLabel
@onready var pp_bar = $PPBar
@onready var pp_label = $PPLabel


var char_hp
var char_pp
var char_max_hp
var char_max_pp

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_values(character):
	char_name.set_text(character.get_name())
	char_hp = character.get_hp()
	char_pp = character.get_pp()
	char_max_hp = character.get_max_hp()
	char_max_pp = character.get_max_pp()
	hp_bar.set_value((float(char_hp)/char_max_hp) * 100 )
	var hp_string = str(char_hp) if (char_hp>9) else ("0" + str(char_hp))
	hp_label.set_text(str(hp_string) + "/" + str(char_max_hp))
	pp_bar.set_value((float(char_pp)/char_max_pp) * 100 )
	var pp_string = str(char_pp) if (char_pp>9) else ("0" + str(char_pp))
	pp_label.set_text(str(pp_string))
	
func update_hp(value):
	hp_bar.set_value((float(value)/char_max_hp) * 100 )
	var value_string = str(value) if (value>9) else ("0" + str(value))
	hp_label.set_text(value_string + "/" + str(char_max_hp))

func update_pp(value):
	pp_bar.set_value((float(value)/char_max_pp) * 100 )
	var value_string = str(value) if (value>9) else ("0" + str(value))
	pp_label.set_text(str(value_string))

func change_hp(value):
	var tween = create_tween()
	tween.tween_method(self.update_hp, char_hp, char_hp + value, 0.9)
	char_hp += value
	tween.tween_callback(animation_end.emit)
