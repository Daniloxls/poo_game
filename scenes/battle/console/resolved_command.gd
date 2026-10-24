class_name ResolvedCommand
extends RefCounted

var ok := false
var error: ConsoleError = null
var actor = null
var skill: SKILL = null
var targets: Array = []   # na ordem dos parâmetros: ITEM e combatentes
