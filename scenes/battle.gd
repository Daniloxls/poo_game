extends Node2D
@onready var player = $Player
@onready var enemies = $Enemies
@onready var enemy_list = $Enemies.get_children()
@onready var menu = $BattleMenu
@onready var enemy_cursor = $EnemyCursor

const ENEMY_POS_OFFSET = Vector2(128, 0)

enum Selecting{
	ACTION,
	ENEMY,
	ALLIE,
	ALL,
	ANIMATION,
	VICTORY,
	OTHER
}

var current_selection = Selecting.ACTION
var enemy_names = []
var enemy_coords = []
var enemy_index = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	menu.hide()
	tween.set_parallel()
	tween.tween_property(player, "position", Vector2(1058,201), 0.1).set_trans(Tween.TRANS_LINEAR)
	for enemy in enemy_list:
		tween.tween_property(enemy, "position", enemy.position + ENEMY_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		enemy_names.append(enemy.get_nome())
	tween.set_parallel(false)
	menu.set_monster_names(enemy_names)
	tween.tween_callback(menu.show)
	tween.tween_callback(get_enemy_positions)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	read_input()
	pass

func select_enemy():
	current_selection = Selecting.ENEMY


func read_input():
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
						enemy_cursor.show()
						enemy_cursor.set_position(enemy_coords[0])
					1:
						pass
					2:
						pass
					3:
						pass
	elif current_selection == Selecting.ENEMY:
		if Input.is_action_just_pressed("up"):
			if enemy_index == 0:
				enemy_index = len(enemy_coords) - 1
			else:
				enemy_index -= 1
			enemy_cursor.set_position(enemy_coords[enemy_index])
		elif Input.is_action_just_pressed("down"):
			if enemy_index == (len(enemy_coords) - 1):
				enemy_index = 0
			else:
				enemy_index += 1
			enemy_cursor.set_position(enemy_coords[enemy_index])
		elif Input.is_action_just_pressed("interact"):
			enemy_list[enemy_index].lose_health(10)
			current_selection = Selecting.ANIMATION
			enemy_cursor.hide()

func get_enemy_positions():
	for enemy in enemy_list:
		enemy_coords.append(enemy.get_cursor_pos()*4 + Vector2(enemies.get_position().x*1.4,enemies.get_position().y*0.8))


func _on_enemy_death():
	for enemy in enemy_list:
		if enemy.get_hp() <= 0:
			var id = enemy_list.find(enemy)
			enemy_list.pop_at(id)
			enemy_names.pop_at(id)
			enemy_coords.pop_at(id)
			menu.set_monster_names(enemy_names)
	pass # Replace with function body.


func _on_enemy_animation_end():
	enemy_cursor.hide()
	if len(enemy_list) > 0:
		current_selection = Selecting.ACTION
		enemy_index = 0
		menu.show_cursor()
		enemy_cursor.set_position(enemy_coords[0])
	else:
		current_selection = Selecting.VICTORY
		menu.hide()
