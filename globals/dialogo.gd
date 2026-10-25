extends Node
## Ponto único para abrir o balão de diálogo e travar o jogador enquanto ele existe.

const BALAO := "res://ui/dialogue/Balao.tscn"

var ativo := false


func pode_iniciar() -> bool:
	return not ativo and not PlayerState.is_on_dialogue() and Textbox.get_state() == "Ready"


func iniciar(recurso: DialogueResource, cue: String = "", contexto: Array = []) -> void:
	if not pode_iniciar():
		return
	ativo = true
	PlayerState.set_on_dialogue(true)
	# Space/Enter não podem chegar a um botão do jogo com foco atrás da caixa.
	get_viewport().gui_release_focus()
	var balao: Node = DialogueManager.show_dialogue_balloon_scene(BALAO, recurso, cue, contexto)
	var r = await DialogueManager.dialogue_ended
	while r != recurso:
		r = await DialogueManager.dialogue_ended
	# Só libera quando o balão saiu da árvore (a saída do retrato leva ~0,25s).
	if is_instance_valid(balao) and balao.is_inside_tree():
		await balao.tree_exited
	await get_tree().process_frame
	ativo = false
	PlayerState.set_on_dialogue(false)
