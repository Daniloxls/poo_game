extends RefCounted
## Combatente falso, só para testes. Define o contrato que toda entidade
## da batalha implementa.

var nome := ""
var vel := 0
var alive := true
var party := false
var hp := 10
var max_hp := 10
var classe := ""
var skills := []
var atk := 0
var def := 0
var pp := 5
var max_pp := 5


func _init(p_nome := "", p_vel := 0, p_party := false) -> void:
	nome = p_nome
	vel = p_vel
	party = p_party


func get_nome() -> String: return nome
func get_vel() -> int: return vel
func is_alive() -> bool: return alive
func is_party_member() -> bool: return party
func get_hp() -> int: return hp
func get_max_hp() -> int: return max_hp
func get_class_name() -> String: return classe
func get_skills() -> Array: return skills
func get_atk() -> int: return atk
func get_def() -> int: return def
func get_pp() -> int: return pp
func get_max_pp() -> int: return max_pp
