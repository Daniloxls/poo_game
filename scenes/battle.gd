extends Node2D
@onready var player = $Player
@onready var enemy = $Enemy

# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(player, "position", Vector2(1058,201), 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(enemy, "position", Vector2(112,299), 0.1).set_trans(Tween.TRANS_LINEAR)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
