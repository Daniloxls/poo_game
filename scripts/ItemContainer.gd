extends HBoxContainer
# ItemContainer é uma celula do inventario que mostra um item

@onready var icon = $ItemIcon
@onready var item_name = $ItemName
@onready var quantity = $ItemQuantity
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
	pass
