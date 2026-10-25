class_name BattleField
extends Node2D
## Campo da batalha (o nó que o FX balança). Põe inimigos e grupo no mesmo espaço
## de tela, com escala 1 e origem no centro do sprite: o FX e o seletor de alvo contam
## seus offsets em pixels de tela. No fim, devolve o grupo como estava.

const ENEMY_SLIDE := Vector2(512, 0)   # inimigos entram pela esquerda
const PARTY_SLIDE := Vector2(-300, 0)  # o grupo entra pela direita

var _party_offset := Vector2.ZERO
var _party_rest: Array = []  # [nó, posição, escala, rotação, modulate]


func place(group: Node2D, enemies: Array, party: Array) -> void:
	add_child(group)
	var t := group.transform
	group.transform = Transform2D.IDENTITY
	for e in enemies:
		for old in ["Healthbar", "DamageText"]:  # UI antiga por inimigo
			if e.has_node(old):
				e.get_node(old).queue_free()
		_flatten(e, t, e.sprite_2d)
	# o Party é outra camada: sem offset, as posições globais batem com as do campo
	_party_offset = Party.offset
	Party.offset = Vector2.ZERO
	_party_rest.clear()
	for m in party:
		for n in [m] + m.get_children():
			if n is Node2D or n is Control:
				_party_rest.append([n, n.position, n.scale, n.rotation, n.modulate])
		_flatten(m, Transform2D(0.0, _party_offset), m.sprite)
		if m.has_node("BattleOptions"):  # menu antigo do personagem
			m.get_node("BattleOptions").hide()


## Escala do nó (e do pai) vai para os filhos; a origem vai para o centro do sprite.
func _flatten(n: Node2D, parent_xform: Transform2D, sprite: Node2D) -> void:
	var k: Vector2 = parent_xform.get_scale() * n.scale
	var center: Vector2 = sprite.position * k
	n.position = parent_xform * n.position + center
	n.scale = Vector2.ONE
	for c in n.get_children():
		if c is Node2D or c is Control:
			c.position = c.position * k - center
			c.scale *= k


## Combatentes deslizam para dentro e os painéis aparecem.
func slide_in(party: Array, enemies: Array, panels: Array, instant: bool) -> void:
	var homes := {}
	for m in party:
		homes[m] = m.position + PARTY_SLIDE
	for e in enemies:
		homes[e] = e.position + ENEMY_SLIDE
	if instant:
		for c in homes:
			c.position = homes[c]
		return
	await get_tree().process_frame  # deixa os painéis medirem as linhas novas
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for c in homes:
		tw.tween_property(c, "position", homes[c], 0.35)
	for p: Control in panels:
		var home := p.position
		p.position.x += -80.0 if home.x < 576.0 else 80.0  # vem do lado onde fica
		p.modulate.a = 0.0
		tw.tween_property(p, "position", home, 0.3)
		tw.tween_property(p, "modulate:a", 1.0, 0.2)
	await tw.finished


## Grupo de volta à camada dele, como estava; sobras do FX saem do Party.
func release() -> void:
	for r in _party_rest:
		r[0].position = r[1]
		r[0].scale = r[2]
		r[0].rotation = r[3]
		r[0].modulate = r[4]
	_party_rest.clear()
	Party.offset = _party_offset
	for n in Party.get_children():  # números de dano soltos pelo FX
		if not n.has_method("is_party_member"):
			Party.remove_child(n)
			n.queue_free()
