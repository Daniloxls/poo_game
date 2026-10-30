class_name Rachadura
extends Node2D
## Fim do tutorial: o cenário treme, a rachadura abre da porta SAÍDA até o Turin e ele cai.

const QUEDA := "res://scenes/chapter_one/tutorial/Queda.tscn"

var _agitando := false


# Depois da vitória: a cada poucos segundos o aviso pisca e os desenhos da parede tremem.
func agitar(hud: ChecklistHud) -> void:
	_agitando = true
	var desenhos: Node2D = get_parent().get_node("DesenhosParede")
	while _agitando:
		await get_tree().create_timer(3.0).timeout
		if not _agitando:
			return
		hud.piscar_aviso()
		var t := create_tween()
		for i in 6:
			t.tween_property(desenhos, "position", Vector2(randf_range(-40, 40), randf_range(-40, 40)), 0.05)
		t.tween_property(desenhos, "position", Vector2.ZERO, 0.05)


func iniciar(hud: ChecklistHud, player) -> void:
	_agitando = false
	PlayerState.set_on_scene(true)
	var fala := "Teste concluído. Acord"   # cortada em "Acord"
	for i in fala.length():
		hud.mensagem(fala.substr(0, i + 1))
		await get_tree().create_timer(0.05).timeout

	# tremor de câmera (~1 s)
	var cam: Camera2D = player.get_node("Camera2D")
	var tremor := create_tween()
	for i in 20:
		tremor.tween_property(cam, "offset", Vector2(randf_range(-250, 250), randf_range(-250, 250)), 0.05)
	tremor.tween_property(cam, "offset", Vector2.ZERO, 0.05)

	# rachadura: linha preta irregular da porta até os pés do Turin, crescendo em 1,2 s
	var inicio: Vector2 = get_parent().get_node("Saida").global_position + Vector2(0, 450)
	var fim: Vector2 = player.global_position
	var linha := Line2D.new()
	linha.width = 70
	linha.default_color = Color.BLACK
	linha.z_index = 10
	add_child(linha)
	var pontos: Array[Vector2] = []
	for i in 13:
		var p := inicio.lerp(fim, i / 12.0)
		pontos.append(p if i in [0, 12] else p + Vector2(randf_range(-250, 250), 0))
	hud.mostrar_erro()
	var cresce := create_tween()
	cresce.tween_method(func(f: float):
		linha.points = PackedVector2Array(pontos.slice(0, 2 + int(f * 11))), 0.0, 1.0, 1.2)
	await cresce.finished

	# queda
	var queda := create_tween().set_parallel()
	queda.tween_property(player, "scale", Vector2.ONE * 0.6, 0.6)
	queda.tween_property(player, "modulate", Color.BLACK, 0.6)
	queda.tween_property(player, "position:y", player.position.y + 300, 0.6)
	await queda.finished
	LevelWarp.change_level(QUEDA)
