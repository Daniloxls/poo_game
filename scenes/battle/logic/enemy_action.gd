class_name EnemyAction
extends RefCounted
## O que o inimigo decidiu fazer no turno.

var method_name := "atacar"
var outcomes: Array[ActionOutcome] = []
# não vazio = o código do inimigo falhou: mostrar o texto, sem outcomes
var error_text := ""
