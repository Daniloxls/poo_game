extends MarginContainer

@onready var audio_click:AudioStreamPlayer

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

@onready var head_slot = $VBoxContainer/CharInfoContainer/HBFContainer/HeadSlot
@onready var body_slot = $VBoxContainer/CharInfoContainer/HBFContainer/BodySlot
@onready var feet_slot = $VBoxContainer/CharInfoContainer/HBFContainer/FeetSlot
@onready var l_hand_slot = $VBoxContainer/CharInfoContainer/HHAContainer/LHandSlot
@onready var r_hand_slot = $VBoxContainer/CharInfoContainer/HHAContainer/RHandSlot
@onready var acessory_slot = $VBoxContainer/CharInfoContainer/HHAContainer/AcessorySlot

enum Slot{
	HAND,
	TWO_HAND,
	FEET,
	BODY,
	HEAD,
	ACESSORY
}
var left_hand = false
var personagem_shown
var items : Array[EQUIP_ITEM] = [load("res://scenes/itens/repo/armadura_couro.tres"),
								load("res://scenes/itens/repo/armadura_ferro.tres")]
# Called when the node enters the scene tree for the first time.
func _ready():
	add_item_buttons(items)
	audio_click = get_tree().root.get_node("Inventory/Audio_Click")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_character(personagem, equip_name = ""):
	personagem_shown = personagem
	character_sprite.set_texture(personagem.get_sprite())
	old_stats.clear()
	old_stats.push_font_size(24)
	old_stats.append_text(equip_name)
	old_stats.append_text("\n\n")
	old_stats.push_font_size(37)
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
	
	
func _on_equip_click(equip_button: Control):
	var equip = equip_button.get_item()
	match equip.get_slot():
		EquipItem.Slot.ACESSORY:
			if personagem_shown.get_equip("acessory_slot") != null :
				add_item_button(personagem_shown.get_equip("acessory_slot"))
				items.append(personagem_shown.get_equip("acessory_slot"))
			personagem_shown.set_equip("acessory_slot", equip)
			acessory_container.remove_child(equip_button)
			acessory_slot.set_button_icon(equip.get_icon())
		EquipItem.Slot.HEAD:
			if personagem_shown.get_equip("head_slot") != null :
				add_item_button(personagem_shown.get_equip("head_slot"))
				items.append(personagem_shown.get_equip("head_slot"))
			personagem_shown.set_equip("head_slot", equip)
			head_container.remove_child(equip_button)
			head_slot.set_button_icon(equip.get_icon())
		EquipItem.Slot.BODY:
			if personagem_shown.get_equip("body_slot") != null :
				add_item_button(personagem_shown.get_equip("body_slot"))
				items.append(personagem_shown.get_equip("body_slot"))
			personagem_shown.set_equip("body_slot", equip)
			body_container.remove_child(equip_button)
			body_slot.set_button_icon(equip.get_icon())
			
		EquipItem.Slot.HAND:
			if left_hand:
				if personagem_shown.get_equip("lhand_slot") != null :
					add_item_button(personagem_shown.get_equip("lhand_slot"))
					items.append(personagem_shown.get_equip("lhand_slot"))
				personagem_shown.set_equip("lhand_slot", equip)
				l_hand_slot.set_button_icon(equip.get_icon())
			else:
				if personagem_shown.get_equip("rhand_slot") != null :
					add_item_button(personagem_shown.get_equip("rhand_slot"))
					items.append(personagem_shown.get_equip("rhand_slot"))
				personagem_shown.set_equip("rhand_slot", equip)
				r_hand_slot.set_button_icon(equip.get_icon())
			hand_container.remove_child(equip_button)
		EquipItem.Slot.TWO_HAND:
			if personagem_shown.get_equip("rhand_slot") != null :
				items.append(personagem_shown.get_equip("rhand_slot"))
				personagem_shown.set_equip("rhand_slot", null)
			if personagem_shown.get_equip("lhand_slot") != null :
				add_item_button(personagem_shown.get_equip("lhand_slot"))
				items.append(personagem_shown.get_equip("lhand_slot"))
			personagem_shown.set_equip("lhand_slot", equip)
			hand_container.remove_child(equip_button)
			l_hand_slot.set_button_icon(equip.get_icon())
		EquipItem.Slot.FEET:
			if personagem_shown.get_equip("feet_slot") != null :
				add_item_button(personagem_shown.get_equip("feet_slot"))
				items.append(personagem_shown.get_equip("feet_slot"))
			personagem_shown.set_equip("feet_slot", equip)
			feet_container.remove_child(equip_button)
			feet_slot.set_button_icon(equip.get_icon())
	arrow_stats.hide()
	new_stats.hide()
	set_character(personagem_shown, equip.get_item_name())

func _on_equip_hover(equip : EQUIP_ITEM):
	new_stats.clear()
	new_stats.push_font_size(24)
	new_stats.append_text(equip.get_item_name())
	new_stats.append_text("\n\n")
	new_stats.push_font_size(37)
	add_text(new_stats, "hp", personagem_shown.get_max_hp(),
	(equip.HP + personagem_shown.get_strict_max_hp()) - personagem_shown.get_max_hp())
	add_text(new_stats, "pp", personagem_shown.get_max_mp(),
	(equip.PP + personagem_shown.get_strict_max_mp()) - personagem_shown.get_max_mp())
	add_text(new_stats, "atk", personagem_shown.get_atk(),
	(equip.ATTACK + personagem_shown.get_strict_atk()) - personagem_shown.get_atk())
	add_text(new_stats, "def", personagem_shown.get_def(),
	(equip.DEFENSE + personagem_shown.get_strict_def()) - personagem_shown.get_def())
	add_text(new_stats, "vel", personagem_shown.get_vel(),
	(equip.VELOCITY + personagem_shown.get_strict_vel()) - personagem_shown.get_vel())
	arrow_stats.show()
	new_stats.show()
	

func add_item_button(equip: EQUIP_ITEM):
	var item_button = load("res://scenes/inventory/ItemButton.tscn")
	var item_slot = item_button.instantiate()
	item_slot.connect("on_hover", _on_equip_hover)
	item_slot.connect("on_click", _on_equip_click)
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
	
func add_item_buttons(equip_list : Array[EQUIP_ITEM]):
	for container in equip_container.get_children():
		for n in container.get_children():
			container.call_deferred("remove_child", n)
			n.queue_free()
	for equip in equip_list:
		var item_button = load("res://scenes/inventory/ItemButton.tscn")
		var item_slot = item_button.instantiate()
		item_slot.connect("on_hover", _on_equip_hover)
		item_slot.connect("on_click", _on_equip_click)
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
	audio_click.play()
	for container in equip_container.get_children():
		container.hide()
	head_container.show()


func _on_body_slot_pressed():
	audio_click.play()
	for container in equip_container.get_children():
		container.hide()
	body_container.show()


func _on_feet_slot_pressed():
	audio_click.play()
	for container in equip_container.get_children():
		container.hide()
	feet_container.show()


func _on_l_hand_slot_pressed():
	audio_click.play()
	left_hand = true
	for container in equip_container.get_children():
		container.hide()
	hand_container.show()


func _on_r_hand_slot_pressed():
	audio_click.play()
	left_hand = false
	for container in equip_container.get_children():
		container.hide()
	hand_container.show()


func _on_acessory_slot_pressed():
	audio_click.play()
	for container in equip_container.get_children():
		container.hide()
	acessory_container.show()
