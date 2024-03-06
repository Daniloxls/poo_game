extends Node2D
@onready var level = $Level

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func change_level(instance):
	for node in level.get_children():
		node.queue_free()
	level.call_deferred("add_child", instance)
