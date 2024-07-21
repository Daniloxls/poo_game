extends MarginContainer

@onready var old_stats = $VBoxContainer/CharInfoContainer/OldStats
@onready var character_sprite = $VBoxContainer/CharInfoContainer/CharacterSprite
@onready var new_stats = $VBoxContainer/CharInfoContainer/NewStats
@onready var arrow_stats = $VBoxContainer/CharInfoContainer/ArrowStats

enum Slot{
	HAND,
	TWO_HAND,
	FEET,
	BODY,
	HEAD,
	ACESSORY
}
var personagem_shown
var items : Array[EQUIP_ITEM] = [load("res://scenes/itens/repo/armadura_ferro.tres"),
								load("res://scenes/itens/repo/armadura_couro.tres")]
# Called when the node enters the scene tree for the first time.
func _ready():
	add_item_buttons(items)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_character(personagem):
	personagem_shown = personagem
	character_sprite.set_texture(personagem.get_sprite())
	old_stats.clear()
	old_stats.append_text("\n")
	add_text(old_stats, "hp", personagem.get_max_hp())
	add_text(old_stats, "pp", personagem.get_max_mp())
	add_text(old_stats, "atk", personagem.get_atk())
	add_text(old_stats, "def", personagem.get_def())
	add_text(old_stats, "vel", personagem.get_vel())

func add_text(label, status, value, increase = 0):
	label.push_color(Color("#cf6d1d"))
	label.append_text("int ")
	label.push_color(Color("#66e1f8"))
	label.append_text(status)
	label.push_color("#ffffff")
	label.append_text(" = ")
	match increase:
		-1:
			label.push_color(Color(0.5882, 0.1547, 0.1333, 1))
		0:
			label.push_color(Color("#228096"))
		1:
			label.push_color(Color(0.2009, 0.5882, 0.1333, 1))
	label.append_text(str(value))
	label.push_color("#ffffff")
	label.append_text(";\n")
	
	
func _on_equip_hover(equip : EQUIP_ITEM):
	new_stats.clear()
	arrow_stats.show()
	new_stats.show()
	

func add_item_buttons(equip_list : Array[EQUIP_ITEM]):
	for equip in equip_list:
		print(equip.get_slot())
