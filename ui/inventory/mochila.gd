class_name Mochila
extends RefCounted
## Itens do grupo. Guarda cópias dos .tres para a quantidade não mexer no arquivo.

signal mudou

var itens: Array[ITEM] = []


func adicionar(item: ITEM, qtd: int = 1) -> void:
	for it in itens:
		if _mesmo(it, item):
			it.QUANTITY += qtd
			mudou.emit()
			return
	var copia: ITEM = item.duplicate()
	copia.QUANTITY = qtd
	copia.set_meta("origem", item.get_meta("origem", item.resource_path))  # cópia de cópia mantém a origem
	itens.append(copia)
	mudou.emit()


func gastar(item: ITEM) -> void:
	item.QUANTITY -= 1
	if item.QUANTITY <= 0:
		itens.erase(item)
	mudou.emit()


func descartar(item: ITEM) -> bool:
	if item.CHAVE:
		return false
	gastar(item)
	return true


func comuns() -> Array[ITEM]:
	return itens.filter(func(i): return not i.CHAVE)


func chave() -> Array[ITEM]:
	return itens.filter(func(i): return i.CHAVE)


func de_slot(slots: Array) -> Array[EQUIP_ITEM]:
	var out: Array[EQUIP_ITEM] = []
	for i in itens:
		if i is EQUIP_ITEM and i.SLOT in slots:
			out.append(i)
	return out


func _mesmo(a: ITEM, b: ITEM) -> bool:
	var origem: String = b.get_meta("origem", b.resource_path)
	if origem != "":
		return a.get_meta("origem", a.resource_path) == origem
	return a.ITEM_NAME == b.ITEM_NAME
