extends MarginContainer
# ItemContainer é uma celula do inventario que mostra um item

signal mouseover
signal mouseout
@onready var item_icon = $ItemContainer/ItemIcon

@onready var item_name = $ItemContainer/ItemName
@onready var quantity = $ItemContainer/ItemQuantity
@onready var button = $Button

var description
# Called when the node enters the scene tree for the first time.
func _ready():
	button.connect("mouse_entered", _on_mouse_entered)
	button.connect("mouse_exited", _on_mouse_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Função que apenas coloca as informações do item na celula
func set_item(item : ITEM):
	item_icon.set_texture(item.get_icon())
	item_name.set_text(item.get_item_name())
	quantity.set_text(str(item.get_quantity()))
	description = item.get_item_text()


func _on_mouse_entered():
	mouseover.emit(description)
	
func _on_mouse_exited():
	mouseout.emit()
