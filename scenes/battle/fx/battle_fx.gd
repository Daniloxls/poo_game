class_name BattleFx
extends Node
## Sequências de golpe, destruição e nocaute. Os painéis de HP são do orquestrador:
## no beat 5 só emitimos hp_changed.

signal hp_changed(target)

const THEME := preload("res://scenes/battle/ui/battle_theme.tres")

var pacing := BattlePacing.new()
var library: DamageFxLibrary = preload("res://scenes/battle/fx/damage_fx.tres")
## Nó balançado no tremor e ampliado no zoom (sem Camera2D). Padrão: o pai.
var shake_target: CanvasItem
## Camada de cima (acima do grupo) para números, efeitos e balões. Padrão: a camada de quem age.
var overlay: Node
var _rest_node: CanvasItem
var _rest_pos := Vector2.ZERO
var _rest_scale := Vector2.ONE
var _field_tween: Tween


## Anel + 6 riscos na cor do tipo (efeito provisório).
class Ring extends Node2D:
	var color := Color.WHITE
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _draw() -> void:
		var c := Color(color, 1.0 - t)
		draw_arc(Vector2.ZERO, 12.0 + 40.0 * t, 0, TAU, 32, c, 4.0)
		for i in 6:
			var d := Vector2.from_angle(i * TAU / 6.0)
			draw_line(d * (16.0 + 40.0 * t), d * (28.0 + 50.0 * t), c, 4.0)


func _ready() -> void:
	if pacing.get_parent() == null:
		add_child(pacing)


func _instant() -> bool:
	return pacing.instant


## Anima uma propriedade; termina junto com a espera (pular = valor final).
func _to(obj: Object, prop: String, value, dur: float) -> void:
	if _instant():
		obj.set_indexed(prop, value)
		return
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.set_speed_scale(pacing.speed)
	tw.tween_property(obj, prop, value, dur)
	await pacing.wait(dur)
	if tw.is_running():
		tw.custom_step(100.0)
	tw.kill()


## Campo (shake_target ou pai); guarda a transformação de repouso na primeira vez.
func _field() -> CanvasItem:
	var n: CanvasItem = shake_target if shake_target else get_parent() as CanvasItem
	if n != _rest_node:
		_rest_node = n
		if n:
			_rest_pos = n.position
			_rest_scale = n.scale
	return n


func _snap_field() -> void:
	if _field_tween:
		_field_tween.kill()
		_field_tween = null
	var n := _field()
	if n:
		n.position = _rest_pos
		n.scale = _rest_scale


func _shake(px: float) -> void:
	var n := _field()
	if n == null or px <= 0.0 or _instant():
		return
	_snap_field()
	for i in 4:
		n.position = _rest_pos + Vector2.from_angle(randf() * TAU) * px * (1.0 - i / 4.0)
		await pacing.wait(0.025)
	_snap_field()


func _spawn_effect(at: Vector2, parent: Node, o: ActionOutcome) -> void:
	if _instant():
		return
	var frames := library.effect_for(o.damage_type)
	if frames:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = frames
		parent.add_child(a)
		a.global_position = at
		a.play()
		a.animation_finished.connect(a.queue_free)
	else:
		var r := Ring.new()
		r.color = DamageType.color(o.damage_type)
		parent.add_child(r)
		r.global_position = at
		var tw := r.create_tween()
		tw.tween_property(r, "t", 1.0, 0.25)
		tw.tween_callback(r.queue_free)
	var snd := library.sound_for(o.damage_type)
	if snd:
		var p := AudioStreamPlayer.new()
		p.stream = snd
		parent.add_child(p)
		p.play()
		p.finished.connect(p.queue_free)


## Onde soltar números, efeitos e balões: a camada de cima, ou a do próprio sprite.
func _layer(sprite: Node) -> Node:
	return overlay if overlay else sprite.get_parent()


func _pop_label(parent: Node, at: Vector2, text: String) -> Label:
	var l := Label.new()
	l.theme = THEME
	l.theme_type_variation = &"MonoLabel"
	l.text = text
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color("#1b1b1b"))
	l.add_theme_constant_override("outline_size", 8)
	parent.add_child(l)
	l.global_position = at - l.get_minimum_size() / 2.0
	return l


func play_action(actor_sprite: Node2D, method_label: String, outcomes: Array, sprite_of: Callable, max_hp_of: Callable) -> void:
	pacing.latched = false
	var home := actor_sprite.position
	var home_scale := actor_sprite.scale
	var layer := _layer(actor_sprite)
	var first := true
	for o: ActionOutcome in outcomes:
		var ts: Node2D = sprite_of.call(o.target)
		var dir := (ts.global_position - actor_sprite.global_position).normalized()
		# 1. antecipação (só no primeiro alvo)
		if first:
			first = false
			var lab: Label = null
			if not _instant():
				lab = _pop_label(layer, actor_sprite.global_position + Vector2(0, -70), method_label)
			actor_sprite.scale = home_scale * Vector2(1.1, 0.9)
			await _to(actor_sprite, "position", home + dir * 40.0, 0.2)
			actor_sprite.scale = home_scale
			if lab:
				lab.queue_free()
		if o.kind == ActionOutcome.Kind.MISS:
			DamageNumber.spawn(layer, ts.global_position + Vector2(0, -40), o)
			await pacing.wait(0.3)
			continue
		var imp := 0.0
		if o.kind == ActionOutcome.Kind.DAMAGE:
			imp = HitImpact.impact(o.amount, max_hp_of.call(o.target))
		# 2. impacto
		_spawn_effect(ts.global_position, layer, o)
		var ts_home := ts.position
		var mod := ts.modulate
		ts.modulate = Color(3, 3, 3, mod.a)
		if o.kind == ActionOutcome.Kind.DAMAGE:
			# 3. hit-stop, tremor e quadro de impacto
			if HitImpact.impact_frame(imp, o.crit):
				ts.modulate = Color(0, 0, 0, mod.a)
				await pacing.wait(0.04)
				ts.modulate = Color(3, 3, 3, mod.a)
			_shake(HitImpact.shake_pixels(imp, o.crit))
			await pacing.hitstop(HitImpact.hitstop_seconds(imp, o.crit))
			# 4. reação
			ts.modulate = mod
			DamageNumber.spawn(layer, ts.global_position + Vector2(0, -40), o)
			await _to(ts, "position", ts_home + dir * 16.0, 0.1)
			await _to(ts, "position", ts_home, 0.15)
		else:
			ts.modulate = mod
			DamageNumber.spawn(layer, ts.global_position + Vector2(0, -40), o)
			await pacing.wait(0.2)
		# 5. barra de HP
		hp_changed.emit(o.target)
	await _to(actor_sprite, "position", home, 0.1)
	actor_sprite.scale = home_scale
	pacing.latched = false


func play_enemy_destroyed(enemy_sprite: Node2D, enemy_name: String, last: bool) -> void:
	pacing.latched = false
	var orig := enemy_sprite.modulate
	if not _instant():
		var layer := _layer(enemy_sprite)
		var at := enemy_sprite.global_position
		var field := _field()
		_snap_field()
		if field:
			var s := 1.05  # zoom na direção do inimigo
			field.scale = _rest_scale * s
			field.position = _rest_pos + (1.0 - s) * (at - _rest_pos)
		pacing.slow_motion(HitImpact.LAST_KILL_SLOWMO_SECONDS if last else HitImpact.KILL_SLOWMO_SECONDS, HitImpact.KILL_SLOWMO_SCALE)
		enemy_sprite.modulate = Color(3, 3, 3, 1)
		await pacing.wait(0.08)  # o flash precisa aparecer
		GlyphBurst.spawn(layer, at)
		var l := _pop_label(layer, at + Vector2(0, -30), "%s = null" % enemy_name)
		if field:
			_field_tween = create_tween().set_parallel().set_ignore_time_scale(true)
			_field_tween.tween_property(field, "scale", _rest_scale, 0.3)
			_field_tween.tween_property(field, "position", _rest_pos, 0.3)
		var fade := create_tween().set_ignore_time_scale(true)
		fade.tween_property(enemy_sprite, "modulate:a", 0.0, 0.3)
		await pacing.wait(1.0)
		fade.kill()
		l.queue_free()
		_snap_field()
	enemy_sprite.hide()
	enemy_sprite.modulate = orig
	pacing.latched = false


func play_party_knocked_out(sprite: Node2D) -> void:
	pacing.latched = false
	if not sprite.has_meta("ko_orig"):
		sprite.set_meta("ko_orig", [sprite.scale, sprite.modulate, sprite.rotation_degrees])
	var o: Array = sprite.get_meta("ko_orig")
	await _to(sprite, "rotation_degrees", o[2] + 8.0, 0.25)
	sprite.scale = o[0] * Vector2(1, 0.8)
	sprite.modulate = Color(0.5, 0.5, 0.5, o[1].a)
	pacing.latched = false


func play_error(actor_sprite: Node2D, text: String) -> void:
	pacing.latched = false
	if _instant():
		return
	var bubble := PanelContainer.new()
	bubble.theme = THEME
	bubble.theme_type_variation = &"BattlePanel"
	bubble.modulate = Color("#ff8a80")
	var l := Label.new()
	l.theme_type_variation = &"MonoLabel"
	l.text = text
	bubble.add_child(l)
	_layer(actor_sprite).add_child(bubble)
	bubble.global_position = actor_sprite.global_position + Vector2(-bubble.get_minimum_size().x / 2.0, -100)
	await pacing.wait(1.2)
	if is_instance_valid(bubble):  # o fim da batalha já pode ter limpado a camada
		bubble.queue_free()
	pacing.latched = false
