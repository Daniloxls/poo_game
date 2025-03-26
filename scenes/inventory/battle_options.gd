extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_button_functions(skill_list : Array[SKILL]):
	var buttons =  get_children()
	for i in range(len(skill_list)):
		buttons[i].set_text(skill_list[i].SKLL_NAME)
		var nodeId = buttons[i].get_instance_id()
		buttons[i].set_script((skill_list[i].SKILL_SCRIPT))
		buttons[i] = instance_from_id(nodeId);
		buttons[i].call_deferred("connect_signals")
		buttons[i].call_deferred("set_skill", skill_list[i])
