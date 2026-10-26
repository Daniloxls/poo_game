extends Node

const PASTA := "res://ui/dialogue/personagens/"
const COR_PADRAO := Color("#8a8f98")

var _por_nome: Dictionary = {}


func _carregar() -> void:
	for arquivo in ResourceLoader.list_directory(PASTA):
		if arquivo.ends_with(".tres"):
			var p: Personagem = load(PASTA + arquivo)
			if p:
				_por_nome[p.nome] = p


func buscar(nome: String) -> Personagem:
	if _por_nome.is_empty():  # carrega na primeira busca
		_carregar()
	if _por_nome.has(nome):
		return _por_nome[nome]
	var p := Personagem.new()
	p.nome = nome
	p.cor = COR_PADRAO
	return p
