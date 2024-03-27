extends CanvasLayer

signal animation_end
signal battle_end

@onready var party = get_node("../Inventory/Party")
@onready var char_list = get_node("../Inventory/Party").get_children()
@onready var inventory = get_node("../Inventory/BattleItemMenu")
@onready var player = get_node("../Level").get_child(0).get_child(2)
@onready var menu = $BattleMenu
@onready var cursor = $Cursor
@onready var turn_cursor = $TurnCursor
@onready var debug = $Debug
 
const ENEMY_POS_OFFSET = Vector2(128, 0)
const CHARACTER_POS_OFFSET = Vector2(300,0)
enum Selecting{
	ITEM_ALLIE,
	ITEM_ENEMY,
	ITEM_ALL_ALLIES,
	ITEM_ALL_ENEMIES,
	ITEM_ALL,
	NONE,
	STARTING,
	ACTION,
	ENEMY,
	ALLIE,
	ALL_ALLIES,
	ALL_ENEMIES,
	MENU,
	ANIMATION,
	ENEMY_PHASE,
	VICTORY,
	DEFEAT,
	OTHER
}
var current_selection = Selecting.STARTING
var character_coords = []
var character_back_coords = []
var char_index = 0
var char_turn = -1
var in_battle = false
var enemy_coords = []
var enemy_names = []
var enemy_index = 0
var enemies 
var enemy_list

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	read_input()
	debug.text = str(Selecting.keys()[current_selection]) + "\n" + str(inventory.get_item_index())
	if current_selection == Selecting.ACTION and char_turn >= len(char_list):
		set_selection(Selecting.ENEMY_PHASE)
		char_turn = -1
		char_turn = update_char_turn()
		enemy_turn()
func reset_variables():
	current_selection = Selecting.ANIMATION
	character_coords = []
	character_back_coords = []
	char_index = 0
	char_turn =  -1
	enemy_coords = []
	enemy_names = []
	enemy_index = 0
	
func select_enemy():
	current_selection = Selecting.ENEMY

func start_battle(enemy_group_path):
	var enemy_group = load(enemy_group_path)
	var instance = enemy_group.instantiate()
	player.set_on_battle(true)
	add_child(instance)
	enemies = $Enemies
	enemy_list = $Enemies.get_children()
	for enemy in enemy_list:
		enemy.connect("animation_end", _on_enemy_animation_end)
		enemy.connect("death", _on_enemy_death)
	show()
	var tween = create_tween()
	in_battle = true
	menu.hide()
	tween.set_parallel()
	for char in char_list:
		tween.tween_property(char, "position", char.position - CHARACTER_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		menu.set_character_name(char_index, char.get_nome())
		menu.update_health_instant(char_index, char.get_health_percentage())
		menu.update_mana_slow(char_index, char.get_mp())
		menu.show_char_status(char_index)
		char_index +=1
	for enemy in enemy_list:
		tween.tween_property(enemy, "position", enemy.position + ENEMY_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		enemy_names.append(enemy.get_nome())
	tween.set_parallel(false)
	menu.set_monster_names(enemy_names)
	tween.tween_callback(menu.show)
	tween.tween_callback(get_entity_positions)
	char_index = -1
	char_index = update_char_index_down()
	char_turn = update_char_turn()
	tween.tween_callback(update_turn_cursor_position)
	
	
func read_input():
	if Input.is_action_just_pressed("a"):
		debug.show()
	if in_battle:
		if current_selection == Selecting.ACTION:
			if Input.is_action_just_pressed("up"):
				menu.move_cursor_up()
			elif Input.is_action_just_pressed("down"):
				menu.move_cursor_down()
			elif Input.is_action_just_pressed("interact"):
					match(menu.get_cursor_pos()):
						0:
							menu.hide_cursor()
							current_selection = Selecting.ENEMY
							cursor.set_flip_h(true)
							cursor.show()
							cursor.set_position(enemy_coords[0])
						1:
							menu.hide_cursor()
							current_selection = Selecting.ALLIE
							cursor.set_flip_h(false)
							cursor.show()
							cursor.set_position(character_coords[char_index])
						2:
							menu.hide_cursor()
							current_selection = Selecting.MENU
							inventory.aparecer()
		
		
		
		elif current_selection == Selecting.ENEMY:
			if Input.is_action_just_pressed("up"):
				if enemy_index == 0:
					enemy_index = len(enemy_coords) - 1
				else:
					enemy_index -= 1
				cursor.set_position(enemy_coords[enemy_index])
			elif Input.is_action_just_pressed("down"):
				if enemy_index == (len(enemy_coords) - 1):
					enemy_index = 0
				else:
					enemy_index += 1
				cursor.set_position(enemy_coords[enemy_index])
			elif Input.is_action_just_pressed("interact"):
				enemy_list[enemy_index].lose_health(randi_range(8, 12))
				current_selection = Selecting.ANIMATION
				cursor.hide()
				char_turn = update_char_turn()
				update_turn_cursor_position()
			elif Input.is_action_just_pressed("exit"):
				current_selection = Selecting.ACTION
				cursor.hide()
				menu.show_cursor()
		
		
		
		elif current_selection == Selecting.ALLIE:
			if Input.is_action_just_pressed("up"):
				char_index = update_char_index_up()
				cursor.set_position(character_coords[char_index])
			elif Input.is_action_just_pressed("down"):
				char_index = update_char_index_down()
				cursor.set_position(character_coords[char_index])
			elif Input.is_action_just_pressed("interact"):
				menu.update_health_slow(char_index, char_list[char_index].lose_health(randi_range(8, 12)))
				current_selection = Selecting.ANIMATION
			elif Input.is_action_just_pressed("exit"):
				current_selection = Selecting.ACTION
				cursor.hide()
				menu.show_cursor()
				
		elif current_selection == Selecting.MENU:
			if Input.is_action_just_pressed("exit"):
				current_selection = Selecting.ACTION
				inventory.esconder()
				menu.show_cursor()
			elif Input.is_action_just_pressed("interact"):
				current_selection = inventory.get_item_selected()
				inventory.esconder()
				if current_selection == Selecting.NONE:
					current_selection =Selecting.MENU
					inventory.aparecer()
					#Tocar som de não pode
		
		elif current_selection == Selecting.ITEM_ALLIE:
			if Input.is_action_just_pressed("up"):
				char_index = update_char_index_up()
				cursor.set_position(character_coords[char_index])
			elif Input.is_action_just_pressed("down"):
				char_index = update_char_index_down()
				cursor.set_position(character_coords[char_index])
			elif Input.is_action_just_pressed("interact"):
				pass
			elif Input.is_action_just_pressed("exit"):
				current_selection = Selecting.MENU
				inventory.aparecer()
				cursor.hide()
				
func get_entity_positions():
	for enemy in enemy_list:
		enemy_coords.append(enemy.get_cursor_pos()*4 + Vector2(enemies.get_position().x*1.4,enemies.get_position().y*0.8))
	for char in char_list:
		character_coords.append(Vector2(party.get_position().x*0.94,party.get_position().y) + char.get_cursor_pos())
		character_back_coords.append(Vector2(party.get_position().x*1.01,party.get_position().y) + char.get_turn_cursor_pos())


func _on_enemy_death():
	for enemy in enemy_list:
		if enemy.get_hp() <= 0:
			var id = enemy_list.find(enemy)
			enemy_list.pop_at(id)
			enemy_names.pop_at(id)
			enemy_coords.pop_at(id)
			menu.set_monster_names(enemy_names)
			if len(enemy_list) == 0:
				in_battle = false
				for char in char_list:
					char.reset_position()
				enemies.queue_free()
				player.set_on_battle(false)
				battle_end.emit()
				reset_variables()
				hide()


func _on_enemy_animation_end():
	cursor.hide()
	if len(enemy_list) > 0:
		current_selection = Selecting.ACTION
		enemy_index = 0
		menu.show_cursor()
		cursor.set_position(enemy_coords[0])
	else:
		current_selection = Selecting.VICTORY
		menu.hide()


func _on_battle_menu_animation_end():
	for char in char_list:
		if char.get_hp() > 0:
			cursor.hide()
			current_selection = Selecting.ACTION
			menu.show_cursor()
			animation_end
			return
	
	current_selection = Selecting.DEFEAT
	menu.hide()
	animation_end

func update_char_index_up():
	var id = char_index - 1
	if id == -1:
		id = len(char_list)-1
	for i in range(4):
		if char_list[id].is_alive():
			break
		else:
			id -= 1
			if id == -1:
				id = len(char_list)-1
	return id
	
func update_char_index_down():
	var id = char_index + 1
	if id == len(char_list):
		id = 0
	for i in range(4):
		if char_list[id].is_alive():
			break
		else:
			id += 1
			if id == len(char_list):
				id = 0
	return id

func update_char_turn():
	if !in_battle:
		return -1
	var id = char_turn + 1
	if id == len(char_list):
		return id
	for i in range(4):
		if char_list[id].is_alive():
			break
		else:
			id += 1
			if id == len(char_list):
				return id
	return id
	
func enemy_turn():
	var tween = create_tween()
	for enemy in enemy_list:
		tween.tween_callback(enemy.logic.bind(char_list, menu))
		tween.tween_interval(0.9)
		tween.tween_callback(set_selection.bind(Selecting.ACTION))

func set_selection(select):
	current_selection = select

func update_turn_cursor_position():
	if !in_battle:
		return
	if char_turn == len(char_list):
		return
	turn_cursor.set_position(character_back_coords[char_turn])
