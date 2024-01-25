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
	OTHER
}

var current_selection = Selecting.ACTION
var enemy_coords = []
# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	print(enemy_list[0].position)
	menu.hide()
	tween.set_parallel()
	tween.tween_property(player, "position", Vector2(1058,201), 0.1).set_trans(Tween.TRANS_LINEAR)
	for enemy in enemy_list:
		tween.tween_property(enemy, "position", enemy.position + ENEMY_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.set_parallel(false)
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
	if Input.is_action_just_pressed("up"):
		menu.move_cursor_up()
	elif Input.is_action_just_pressed("down"):
		menu.move_cursor_down()
	elif Input.is_action_just_pressed("interact"):
		if current_selection == Selecting.ACTION:
			match(menu.get_cursor_pos()):
				0:
					menu.hide_cursor()
					current_selection = Selecting.ENEMY
					enemy_cursor.set_position(enemy_coords[0])
				1:
					pass
				2:
					pass
				3:
					pass


func get_enemy_positions():
	for enemy in enemy_list:
		print(enemy.get_cursor_pos())
		print( Vector2(0, enemies.get_position().y))
		enemy_coords.append(enemy.get_cursor_pos() + Vector2(0, enemies.get_position().y) + ENEMY_POS_OFFSET)
