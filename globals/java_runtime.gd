extends Node
## Autoload "JavaRuntime": liga o interpretador Java aos objetos do jogo.
##
## - Guarda um único JavaInterpreter para o jogo todo.
## - Mostra o painel de código (JavaCodePanel) quando o jogador depura um
##   objeto que estende java_interact.gd.
## - Compila e executa o código de cada objeto, mostrando os erros no painel.
##
## Classes que o jogo oferece ao código Java dos objetos:
##   Personagem: getNome(), getHp(), getMaxHp(), getForca(), getAtaque(), getDefesa()
## E todo método declarado como `native` no Java chama o método de mesmo nome
## no script GDScript do objeto (ex.: `private native void causarDano(int dano);`).

var java := JavaInterpreter.new()
var painel: JavaCodePanel

var _camada: CanvasLayer
var _objeto_atual: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camada = CanvasLayer.new()
	_camada.layer = 20
	add_child(_camada)
	painel = JavaCodePanel.new()
	painel.comecar_aberto = false
	_camada.add_child(painel)
	_camada.hide()
	painel.run_requested.connect(_on_executar)
	painel.toggled.connect(_on_painel_toggled)
	java.output.connect(painel.print_output)
	_definir_classes_do_jogo()


func _exit_tree() -> void:
	java.dispose()


# ---------------------------------------------------------------- API

## Abre o painel de código para o jogador editar o objeto.
func editar(objeto: Node) -> void:
	if _objeto_atual != null and _objeto_atual != objeto:
		_guardar_estado(_objeto_atual)
	_objeto_atual = objeto
	_camada.show()
	painel.open_code(objeto.codigo_java, objeto.nome, objeto.dica_java)
	if not objeto.estado_editor.is_empty():
		painel.editor.set_state(objeto.estado_editor)
	PlayerState.set_on_interface(true)
	objeto.ao_abrir_codigo()


## Fecha o painel (o código editado fica guardado no objeto).
func fechar() -> void:
	painel.collapse()


## Executa um método do objeto Java ligado a `objeto`.
## Devolve o valor de retorno, ou null se o código tiver erro (o erro vai para
## o console do painel e fica em `java.last_error`).
func executar(objeto: Node, metodo: String, args: Array = []):
	if not compilar(objeto):
		return null
	if objeto.instancia_java == null:
		objeto.instancia_java = java.create_object(objeto.classe_java, [], objeto)
		if java.has_error():
			_reportar_erro(objeto)
			return null
	var r = java.call_method(objeto.instancia_java, metodo, args)
	if java.has_error():
		_reportar_erro(objeto)
		return null
	return r


## Compila o código atual do objeto, se ele mudou desde a última vez.
func compilar(objeto: Node) -> bool:
	var codigo: String = objeto.get_codigo_java_atual()
	if codigo == objeto.codigo_compilado and java.classes.has(objeto.classe_java):
		return true
	if not java.load_source(codigo, str(objeto.get_path())):
		_reportar_erro(objeto)
		return false
	if not java.classes.has(objeto.classe_java):
		java.throw_error("O código precisa ter a classe %s" % objeto.classe_java)
		_reportar_erro(objeto)
		return false
	objeto.codigo_compilado = codigo
	objeto.instancia_java = null   # código novo = objeto novo
	return true


## Cria o objeto Java Personagem a partir de um personagem do jogo
## (nó de batalha, Dictionary, ou qualquer objeto com hp/atk/def/nome).
func personagem(dados) -> JObject:
	var obj := JObject.new()
	obj.cls = java.classes["Personagem"]
	obj.host = dados
	return obj


# ---------------------------------------------------------------- interno

func _definir_classes_do_jogo() -> void:
	var p := java.define_native_class("Personagem")
	p.add_method("getNome", func(t, _a): return str(_ler(t.host, ["nome"], "")), [], "String")
	p.add_method("getHp", func(t, _a): return int(_ler(t.host, ["hp"], 0)), [], "int")
	p.add_method("getMaxHp", func(t, _a): return int(_ler(t.host, ["max_hp", "hp"], 0)), [], "int")
	p.add_method("getForca", func(t, _a): return int(_ler(t.host, ["forca", "atk"], 0)), [], "int")
	p.add_method("getAtaque", func(t, _a): return int(_ler(t.host, ["atk", "forca"], 0)), [], "int")
	p.add_method("getDefesa", func(t, _a): return int(_ler(t.host, ["def"], 0)), [], "int")


func _ler(fonte, nomes: Array, padrao):
	for n in nomes:
		if fonte is Dictionary and fonte.has(n):
			return fonte[n]
		if fonte is Object and is_instance_valid(fonte) and n in fonte:
			return fonte.get(n)
	return padrao


func _on_executar(_codigo: String) -> void:
	var objeto := _objeto_atual
	if objeto == null:
		return
	_guardar_estado(objeto)
	painel.clear_output()
	if not compilar(objeto):
		return
	painel.print_success("Código compilado sem erros.")
	objeto.ao_executar_codigo()


func _on_painel_toggled(aberto: bool) -> void:
	if aberto:
		return
	if _objeto_atual != null:
		_guardar_estado(_objeto_atual)
		_objeto_atual.ao_fechar_codigo()
	_objeto_atual = null
	_camada.hide()
	PlayerState.set_on_interface(false)


func _guardar_estado(objeto: Node) -> void:
	if objeto == _objeto_atual:
		objeto.estado_editor = painel.editor.get_state()
		objeto.codigo_editado = painel.get_code()


func _reportar_erro(objeto: Node) -> void:
	push_warning("[%s] %s" % [objeto.nome, java.get_error_text()])
	if objeto == _objeto_atual:
		painel.show_error(java.get_error_text(), java.last_error.get("line", 0))
	objeto.ultimo_erro = java.get_error_text()
