class_name PaginaDoc
extends Resource
## Uma página da Documentação. O texto fica aqui para ser editado no Inspetor.

## Id do Progresso que libera a página ("basico" para bool/int/String).
@export var REQUER: String
@export var ORDEM: int
@export var TITULO: String
## Pode ter BBCode.
@export_multiline var TEXTO: String
## Java de exemplo, uma instrução por linha.
@export_multiline var EXEMPLO: String
