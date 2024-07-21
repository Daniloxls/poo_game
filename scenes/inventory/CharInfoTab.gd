extends TabContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	var texture = load("res://assets/gui/icons/person.png")
	set_tab_icon(0, texture)
	set_tab_title(0,"")
	texture = load("res://assets/gui/icons/breastplate.png")
	set_tab_icon(2, texture)
	set_tab_title(2,"")
	texture = load("res://assets/gui/icons/computing.png")
	set_tab_icon(4, texture)
	set_tab_title(4,"")
	texture = load("res://assets/gui/icons/monk-face.png")
	set_tab_icon(6, texture)
	set_tab_title(6,"")
	
	set_tab_disabled(1, true)
	set_tab_disabled(3, true)
	set_tab_disabled(5, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
