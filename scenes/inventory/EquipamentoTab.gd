extends MarginContainer

@onready var old_stats = $VBoxContainer/CharInfoContainer/OldStats
@onready var character_sprite = $VBoxContainer/CharInfoContainer/CharacterSprite
@onready var new_stats = $VBoxContainer/CharInfoContainer/NewStats
@onready var arrow_stats = $VBoxContainer/CharInfoContainer/ArrowStats

@onready var equip_container = $VBoxContainer/EquipmentContainer/EquipContainer

@onready var body_container = $VBoxContainer/EquipmentContainer/EquipContainer/BodyContainer
@onready var head_container = $VBoxContainer/EquipmentContainer/EquipContainer/HeadContainer
@onready var feet_container = $VBoxContainer/EquipmentContainer/EquipContainer/FeetContainer
@onready var hand_container = $VBoxContainer/EquipmentContainer/EquipContainer/HandContainer
@onready var acessory_container = $VBoxContainer/EquipmentContainer/EquipContainer/AcessoryContainer

enum Slot{
	HAND,
	TWO_HAND,
	FEET,
	BODY,
	HEAD,
	ACESSORY
}
var personagem_shown
var items : Array[EQUIP_ITEM] = [load("res://scenes/itens/repo/armadura_couro.tres"),
								load("res://scenes/itens/repo/armadura_ferro.tres")]
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
	if increase < 0:
		label.push_color(Color(0.5882, 0.1547, 0.1333, 1))
	elif increase == 0:
		label.push_color(Color("#228096"))
	else:
		label.push_color(Color(0.2009, 0.5882, 0.1333, 1))
		
	label.append_text(str(value + increase))
	label.push_color("#ffffff")
	label.append_text(";\n")
	
	
func _on_equip_click(equip: EQUIP_ITEM):
	match equip.get_slot():
		EquipItem.Slot.ACESSORY:
			pass
		EquipItem.Slot.HEAD:
			pass
		EquipItem.Slot.BODY:
			pass
		EquipItem.Slot.HAND:
			pass
		EquipItem.Slot.TWO_HAND:
			pass
		EquipItem.Slot.FEET:
			pass

func _on_equip_hover(equip : EQUIP_ITEM):
	new_stats.clear()
	new_stats.append_text("\n")
	add_text(new_stats, "hp", personagem_shown.get_max_hp(), equip.HP)
	add_text(new_stats, "pp", personagem_shown.get_max_mp(), equip.PP)
	add_text(new_stats, "atk", personagem_shown.get_atk(), equip.ATTACK)
	add_text(new_stats, "def", personagem_shown.get_def(), equip.DEFENSE)
	add_text(new_stats, "vel", personagem_shown.get_vel(), equip.VELOCITY)
	arrow_stats.show()
	new_stats.show()
	

func add_item_buttons(equip_list : Array[EQUIP_ITEM]):
	for container in equip_container.get_children():
		for n in container.get_children():
			container.call_deferred("remove_child", n)
			n.queue_free()
	for equip in equip_list:
		var item_button = load("res://scenes/inventory/ItemButton.tscn")
		var item_slot = item_button.instantiate()
		item_slot.connect("on_hover", _on_equip_hover)
		match equip.get_slot():
			EquipItem.Slot.ACESSORY:
				acessory_container.call_deferred("add_child", item_slot)
			EquipItem.Slot.HEAD:
				head_container.call_deferred("add_child", item_slot)
			EquipItem.Slot.BODY:
				body_container.call_deferred("add_child", item_slot)
			EquipItem.Slot.HAND:
				hand_container.call_deferred("add_child", item_slot)
			EquipItem.Slot.TWO_HAND:
				hand_container.call_deferred("add_child", item_slot)
			EquipItem.Slot.FEET:
				feet_container.call_deferred("add_child", item_slot)
		item_slot.call_deferred("set_item", equip)


func _on_head_slot_pressed():
	for container in equip_container.get_children():
		container.hide()
	head_container.show()


func _on_body_slot_pressed():
	for container in equip_container.get_children():
		container.hide()
	body_container.show()


func _on_feet_slot_pressed():
	for container in equip_container.get_children():
		container.hide()
	feet_container.show()


func _on_l_hand_slot_pressed():
	for container in equip_container.get_children():
		container.hide()
	hand_container.show()


func _on_r_hand_slot_pressed():
	for container in equip_container.get_children():
		container.hide()
	hand_container.show()


func _on_acessory_slot_pressed():
	for container in equip_container.get_children():
		container.hide()
	acessory_container.show()
