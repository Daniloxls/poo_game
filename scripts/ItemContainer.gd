extends MarginContainer
# ItemContainer é uma celula do inventario que mostra um item

@onready var icon = $ItemContainer/ItemIcon
@onready var item_name = $ItemContainer/ItemName
@onready var quantity = $ItemContainer/ItemQuantity

var description
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Função que apenas coloca as informações do item na celula
func set_item(item : ITEM):
	icon.set_texture(item.get_icon())
	item_name.set_text(item.get_item_name())
	quantity.set_text(str(item.get_quantity()))
	description = item.get_item_text()
	pass
