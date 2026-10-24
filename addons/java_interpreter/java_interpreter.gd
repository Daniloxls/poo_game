class_name JavaInterpreter
extends RefCounted
## Etapa 3: interpretador "tree-walking" de um subconjunto de Java.
##
## Uso básico:
##     var java := JavaInterpreter.new()
##     java.output.connect(func(t): print(t))
##     if not java.load_source(codigo):
##         print(java.get_error_text())
##     var obj := java.create_object("Porta", [], $Porta)
##     var r = java.call_method(obj, "abrir", [1234])
##     if java.has_error(): print(java.get_error_text())
##
## O jogo expõe funcionalidades ao código do aluno com classes nativas
## (veja define_native_class e JClass.add_method).

## Emitido por System.out.print/println.
signal output(text: String)
## Emitido quando acontece um erro (de sintaxe, de semântica ou de execução).
signal error_raised(error: Dictionary)

## Máximo de comandos executados por chamada vinda do jogo (evita loop infinito).
var max_steps := 50000
## Máximo de chamadas de método aninhadas (evita recursão infinita).
var max_depth := 256
## Tempo máximo (ms) de uma chamada vinda do jogo. 0 = sem limite.
var max_time_ms := 1000

## Todas as classes carregadas: nome -> JClass
var classes := {}
## Variáveis globais expostas pelo jogo: nome -> [tipo, valor, final]
var globals := {}
## Último erro: { kind, message, line, class, method, trace }
var last_error := {}
## Tudo que foi impresso com System.out desde o último clear_output().
var output_log := ""

const NORMAL := 0
const BREAK := 1
const CONTINUE := 2
const RETURN := 3
const ERROR := 4


class Frame:
	var this_obj = null       # JObject (null em métodos static)
	var cls: JClass        # classe onde o método foi declarado
	var method = null         # Dictionary do método (null em inicializadores)
	var label := ""           # "Classe.metodo" para o rastro de erro
	var scopes: Array = []    # pilha de Dictionary nome -> [tipo, valor, final]
	var line := 0


var _frames: Array = []
var _has_err := false
var _ret_val = null
var _steps := 0
var _start_ms := 0
var _external_depth := 0
var _unset := RefCounted.new()  # marca de "variável sem valor"
var _source_classes := {}       # nome -> nome da fonte carregada


func _init() -> void:
	_install_builtins()


# =====================================================================
# API pública
# =====================================================================

## Compila (analisa) o código e registra as classes. Devolve false em caso de
## erro (veja last_error / get_error_text). Pode ser chamado várias vezes: cada
## chamada adiciona ou substitui classes. Se houver erro, nada é alterado.
## Com `source_name` (ex.: "porta_3"), as classes carregadas antes com o mesmo
## nome de fonte são removidas, então renomear a classe no editor não deixa
## a versão antiga para trás.
func load_source(src: String, source_name := "") -> bool:
	_reset_error()
	var parser := JavaParser.new()
	var decls := parser.parse(src)
	if not parser.error.is_empty():
		_raise_static("sintaxe", parser.error.message, parser.error.line, "")
		return false

	var new_classes := {}
	for d in decls:
		if new_classes.has(d.name):
			_raise_static("semântico", "A classe '%s' foi declarada duas vezes" % d.name, d.line, d.name)
			return false
		if classes.has(d.name) and classes[d.name].is_native:
			_raise_static("semântico", "Já existe uma classe do jogo chamada '%s'. Escolha outro nome." % d.name, d.line, d.name)
			return false
		new_classes[d.name] = _class_from_decl(d)

	var backup := classes.duplicate()
	if source_name != "":
		for n in _source_classes:
			if _source_classes[n] == source_name and classes.has(n) and not new_classes.has(n):
				classes.erase(n)
	for n in new_classes:
		classes[n] = new_classes[n]
	if not _link_all() or not _check_classes(new_classes):
		classes = backup
		_link_all()
		return false
	for n in new_classes:
		_source_classes[n] = source_name
	# inicializa os campos static na ordem em que as classes aparecem
	_begin_external()
	for d in decls:
		_init_statics(new_classes[d.name])
		if _has_err:
			break
	_end_external()
	if _has_err:
		classes = backup
		_link_all()
		return false
	return true


## Remove uma classe carregada (por exemplo, antes de recarregar o código editado).
func unload_class(name: String) -> void:
	if classes.has(name) and not classes[name].is_native:
		classes.erase(name)
		_link_all()


## Cria uma classe nativa (implementada em GDScript pelo jogo).
## As classes do aluno podem herdar dela: class Robo extends ObjetoDoJogo { ... }
func define_native_class(name: String, super_name := "", is_interface := false) -> JClass:
	var c := JClass.new()
	c.name = name
	c.is_native = true
	c.is_interface = is_interface
	c.is_abstract = is_interface
	c.super_name = super_name
	classes[name] = c
	_link_all()
	return c


## Atalho: cria um método nativo que chama um método do objeto host (o Node do jogo).
## Ex.: bind_host_method(robo_cls, "andar", "mover_uma_casa", ["int"])
func bind_host_method(cls: JClass, java_name: String, host_method: String, param_types: Array = [], return_type := "void") -> void:
	var interp := self
	cls.add_method(java_name, func(this, args):
		if this == null or this.host == null or not is_instance_valid(this.host):
			interp.throw_error("O objeto '%s' não está ligado a nada no jogo" % java_name)
			return null
		return this.host.callv(host_method, args)
	, param_types, return_type)


## Expõe um valor como variável global para o código do aluno (ex.: "porta").
func expose(var_name: String, value, type_name := "Object", is_final := true) -> void:
	globals[var_name] = [type_name, value, is_final]


## Cria um objeto (chamando o construtor) e o liga ao objeto `host` do Godot.
func create_object(class_name_: String, args: Array = [], host = null) -> JObject:
	_begin_external()
	var cls = classes.get(class_name_)
	var obj = null
	if cls == null:
		_raise("A classe '%s' não existe" % class_name_)
	elif cls.is_interface or cls.is_abstract:
		_raise("A classe '%s' é abstrata (ou interface) e não pode ser instanciada" % class_name_)
	else:
		obj = _instantiate(cls, args, host)
	_end_external()
	return null if _has_err else obj


## Chama um método de um objeto. Devolve o valor de retorno (null se void ou erro).
func call_method(obj: JObject, method_name: String, args: Array = []) -> Variant:
	_begin_external()
	var r = null
	if obj == null:
		_raise("call_method: objeto null")
	else:
		var m = _find_method(obj.cls, method_name, args)
		if m == null:
			_raise(_method_not_found_msg(obj.cls, method_name, args))
		else:
			r = _invoke(m, obj, args)
	_end_external()
	return null if _has_err else r


## Chama um método static. Ex.: call_static("Main", "main")
func call_static(class_name_: String, method_name: String, args: Array = []) -> Variant:
	_begin_external()
	var r = null
	var cls = classes.get(class_name_)
	if cls == null:
		_raise("A classe '%s' não existe" % class_name_)
	else:
		var m = _find_method(cls, method_name, args)
		if m == null:
			_raise(_method_not_found_msg(cls, method_name, args))
		elif not m.static:
			_raise("O método %s() não é static" % method_name)
		else:
			r = _invoke(m, null, args)
	_end_external()
	return null if _has_err else r


## Executa public static void main(String[] args) de uma classe.
func run_main(class_name_: String) -> bool:
	var cls = classes.get(class_name_)
	if cls != null and cls.methods.has("main"):
		for m in cls.methods.main:
			if m.params.size() == 1:
				call_static(class_name_, "main", [JArray.new("String[]", [])])
				return not _has_err
	call_static(class_name_, "main", [])
	return not _has_err


## Nomes das classes (não abstratas) do aluno que herdam de `base_name`.
## Útil quando o jogador pode dar qualquer nome à classe dele.
func find_subclasses_of(base_name: String) -> Array:
	var out := []
	for c in classes.values():
		if not c.is_native and not c.is_abstract and c.name != base_name and _is_subtype(c, base_name):
			out.append(c.name)
	return out


## Verdadeiro se o objeto (ou a classe) possui o método.
func object_has_method(obj_or_class, method_name: String) -> bool:
	var cls = obj_or_class.cls if obj_or_class is JObject else obj_or_class
	if cls is String:
		cls = classes.get(cls)
	return cls != null and cls.has_java_method(method_name)


func get_field(obj: JObject, field_name: String) -> Variant:
	return obj.fields.get(field_name)


func set_field(obj: JObject, field_name: String, value) -> void:
	obj.fields[field_name] = value


func get_static(class_name_: String, field_name: String) -> Variant:
	var c = classes.get(class_name_)
	return c.static_values.get(field_name) if c else null


func has_error() -> bool:
	return not last_error.is_empty()


## Mensagem de erro amigável, pronta para mostrar ao jogador.
func get_error_text() -> String:
	if last_error.is_empty():
		return ""
	var s := "Erro semântico" if last_error.kind == "semântico" else "Erro de %s" % last_error.kind
	if last_error.get("line", 0) > 0:
		s += " (linha %d)" % last_error.line
	s += ": " + last_error.message
	return s


## Para usar dentro de métodos nativos: interrompe o código do aluno com um erro.
func throw_error(message: String) -> void:
	_raise(message)


## Converte qualquer valor para texto como o Java faria (chama toString()).
func to_java_string(v) -> String:
	return _to_str(v)


func clear_output() -> void:
	output_log = ""


## Libera referências (chame quando não for mais usar o interpretador).
func dispose() -> void:
	for c in classes.values():
		c.static_values.clear()
	globals.clear()
	classes.clear()
	_frames.clear()


# =====================================================================
# Carregamento e verificação de classes
# =====================================================================

func _class_from_decl(d: Dictionary) -> JClass:
	var c := JClass.new()
	c.name = d.name
	c.line = d.line
	c.super_name = d.super
	c.interfaces = d.interfaces
	c.is_interface = d.is_interface
	c.is_abstract = d.is_abstract
	for f in d.fields:
		c.field_decls[f.name] = f
		if not f.static:
			c.fields.append(f)
	for m in d.methods:
		if not c.methods.has(m.name):
			c.methods[m.name] = []
		c.methods[m.name].append(m)
	c.ctors = d.ctors
	return c


func _link_all() -> bool:
	for c in classes.values():
		c.superclass = null
		if c.super_name != "" and c.super_name != "Object":
			c.superclass = classes.get(c.super_name)
	return true


func _check_classes(new_classes: Dictionary) -> bool:
	for c in new_classes.values():
		# superclasse e interfaces existem?
		if c.super_name != "" and c.super_name != "Object":
			var s = classes.get(c.super_name)
			if s == null:
				return _raise_static("semântico", "A classe '%s' herda de '%s', que não existe" % [c.name, c.super_name], c.line, c.name)
			if s.is_interface:
				return _raise_static("semântico", "'%s' é uma interface: use 'implements %s' em vez de 'extends'" % [s.name, s.name], c.line, c.name)
		for iname in c.interfaces:
			var ic = classes.get(iname)
			if ic == null:
				return _raise_static("semântico", "A interface '%s' não existe" % iname, c.line, c.name)
			if not ic.is_interface:
				return _raise_static("semântico", "'%s' é uma classe, não uma interface: use 'extends %s'" % [iname, iname], c.line, c.name)
		# herança circular
		var seen := {}
		var k = c
		while k != null:
			if seen.has(k.name):
				return _raise_static("semântico", "Herança circular envolvendo a classe '%s'" % c.name, c.line, c.name)
			seen[k.name] = true
			k = k.superclass
	for c in new_classes.values():
		# campos repetidos na hierarquia
		var sup = c.superclass
		while sup != null:
			for fname in c.field_decls:
				if sup.field_decls.has(fname) and not c.field_decls[fname].static:
					return _raise_static("semântico", "O campo '%s' já existe na superclasse '%s'. Use o campo herdado em vez de declarar de novo." % [fname, sup.name], c.field_decls[fname].line, c.name)
			sup = sup.superclass
		# métodos repetidos
		for mname in c.methods:
			var list: Array = c.methods[mname]
			for i in list.size():
				for j in range(i + 1, list.size()):
					if _same_params(list[i].params, list[j].params):
						return _raise_static("semântico", "O método '%s(%s)' foi declarado duas vezes na classe %s" % [mname, _param_types_str(list[i].params), c.name], list[j].line, c.name)
				# sobrescrita precisa manter o tipo de retorno
				var over = _find_declared_in_supers(c, mname, list[i].params)
				if over != null and over.ret != list[i].ret and not _ret_compatible(list[i].ret, over.ret):
					return _raise_static("semântico", "O método '%s' sobrescreve o de '%s' mas muda o tipo de retorno (%s em vez de %s)" % [mname, over.owner, list[i].ret, over.ret], list[i].line, c.name)
				if over != null and over.access == "public" and list[i].access == "private":
					return _raise_static("semântico", "O método '%s' sobrescreve um método public e não pode ser private" % mname, list[i].line, c.name)
		for i in c.ctors.size():
			for j in range(i + 1, c.ctors.size()):
				if _same_params(c.ctors[i].params, c.ctors[j].params):
					return _raise_static("semântico", "Construtor de %s com os mesmos parâmetros declarado duas vezes" % c.name, c.ctors[j].line, c.name)
		# classe concreta precisa implementar os métodos abstratos
		if not c.is_abstract:
			for am in _collect_abstract(c):
				var impl = _find_method_exact(c, am.name, am.params)
				if impl == null or impl.abstract:
					return _raise_static("semântico", "A classe %s precisa implementar o método %s %s(%s) de %s" % [c.name, am.ret, am.name, _param_types_str(am.params), am.owner], c.line, c.name)
		# tipos usados existem?
		for fd in c.field_decls.values():
			if not _check_type_exists(fd.type, fd.line, c.name):
				return false
			if fd.init != null and not _check_types_in(fd.init, c.name):
				return false
		for mlist in c.methods.values():
			for m in mlist:
				if not _check_type_exists(m.ret, m.line, c.name):
					return false
				for p in m.params:
					if not _check_type_exists(p.type, m.line, c.name):
						return false
				if m.body != null and not _check_types_in(m.body, c.name):
					return false
		for ct in c.ctors:
			for p in ct.params:
				if not _check_type_exists(p.type, ct.line, c.name):
					return false
			if not _check_types_in(ct.body, c.name):
				return false
			if ct.explicit != null and not _check_types_in(ct.explicit, c.name):
				return false
	return true


func _ret_compatible(sub_ret: String, super_ret: String) -> bool:
	var sc = classes.get(sub_ret)
	return sc != null and _is_subtype(sc, super_ret)


func _same_params(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i].type != b[i].type:
			return false
	return true


func _param_types_str(params: Array) -> String:
	var parts := []
	for p in params:
		parts.append(p.type)
	return ", ".join(parts)


func _find_method_exact(cls: JClass, name: String, params: Array) -> Variant:
	var c = cls
	while c != null:
		if c.methods.has(name):
			for m in c.methods[name]:
				if not m.abstract and _same_params(m.params, params):
					return m
		c = c.superclass
	return null


func _find_declared_in_supers(cls: JClass, name: String, params: Array) -> Variant:
	var c = cls.superclass
	while c != null:
		if c.methods.has(name):
			for m in c.methods[name]:
				if _same_params(m.params, params):
					return m
		c = c.superclass
	return null


func _collect_abstract(cls: JClass) -> Array:
	var out := []
	var visited := {}
	var c = cls
	while c != null:
		for mlist in c.methods.values():
			for m in mlist:
				if m.abstract:
					out.append(m)
		for iname in c.interfaces:
			_collect_interface_abstract(iname, out, visited)
		c = c.superclass
	return out


func _collect_interface_abstract(iname: String, out: Array, visited: Dictionary) -> void:
	if visited.has(iname):
		return
	visited[iname] = true
	var ic = classes.get(iname)
	if ic == null:
		return
	for mlist in ic.methods.values():
		for m in mlist:
			if m.abstract:
				out.append(m)
	for s in ic.interfaces:
		_collect_interface_abstract(s, out, visited)


func _check_type_exists(t: String, line: int, cname: String) -> bool:
	var base := t
	while base.ends_with("[]"):
		base = base.substr(0, base.length() - 2)
	if base in ["int", "long", "double", "boolean", "char", "void", "String", "Object"]:
		return true
	if classes.has(base):
		return true
	return _raise_static("semântico", "O tipo '%s' não existe. Verifique se o nome está escrito certo (maiúsculas e minúsculas fazem diferença)." % base, line, cname)


## Percorre a AST procurando tipos usados em declarações, new, casts e instanceof.
func _check_types_in(node, cname: String) -> bool:
	if node is Dictionary:
		var k = node.get("k", "")
		if k == "var":
			for d in node.decls:
				if not _check_type_exists(d.type, d.line, cname):
					return false
		elif k == "foreach" or k == "cast" or k == "instanceof" or k == "arrlit" or k == "newarr":
			if not _check_type_exists(node.type, node.line, cname):
				return false
		elif k == "new":
			if node.cls != "String" and not classes.has(node.cls):
				return _raise_static("semântico", "A classe '%s' não existe" % node.cls, node.line, cname)
		for v in node.values():
			if (v is Dictionary or v is Array) and not _check_types_in(v, cname):
				return false
	elif node is Array:
		for v in node:
			if (v is Dictionary or v is Array) and not _check_types_in(v, cname):
				return false
	return true


func _init_statics(cls: JClass) -> void:
	for fd in cls.field_decls.values():
		if fd.static:
			cls.static_values[fd.name] = _default_value(fd.type)
	var f := _push_frame(null, cls, null, cls.name + ".<static>")
	for fd in cls.field_decls.values():
		if fd.static and fd.init != null:
			f.line = fd.line
			var v = _eval_init(fd.init, fd.type)
			if _has_err:
				break
			v = _coerce(v, fd.type, ["campo static '%s'", fd.name])
			if _has_err:
				break
			cls.static_values[fd.name] = v
	_pop_frame()


# =====================================================================
# Erros
# =====================================================================

func _reset_error() -> void:
	last_error = {}
	_has_err = false


func _raise_static(kind: String, msg: String, line: int, cname: String) -> bool:
	if _has_err:
		return false
	_has_err = true
	last_error = {"kind": kind, "message": msg, "line": line, "class": cname, "method": "", "trace": []}
	error_raised.emit(last_error)
	return false


## Erro de execução. Usa a linha atual do método em execução.
func _raise(msg: String, line := -1) -> void:
	if _has_err:
		return
	_has_err = true
	var trace := []
	for i in range(_frames.size() - 1, -1, -1):
		var f: Frame = _frames[i]
		trace.append("%s (linha %d)" % [f.label, f.line])
	var cur: Frame = _frames.back() if not _frames.is_empty() else null
	if line < 0:
		line = cur.line if cur else 0
	last_error = {
		"kind": "execução", "message": msg, "line": line,
		"class": cur.cls.name if cur and cur.cls else "",
		"method": cur.label if cur else "", "trace": trace,
	}
	error_raised.emit(last_error)


func _begin_external() -> void:
	if _external_depth == 0:
		_reset_error()
		_steps = 0
		_start_ms = Time.get_ticks_msec()
		_frames.clear()
	_external_depth += 1


func _end_external() -> void:
	_external_depth -= 1
	if _external_depth == 0:
		_frames.clear()
		_ret_val = null


func _tick() -> bool:
	_steps += 1
	if _steps > max_steps:
		_raise("O código executou passos demais (limite: %d). Existe um loop infinito?" % max_steps)
		return false
	if max_time_ms > 0 and _steps % 1000 == 0 and Time.get_ticks_msec() - _start_ms > max_time_ms:
		_raise("O código demorou demais para terminar (limite: %d ms). Existe um loop infinito?" % max_time_ms)
		return false
	return true


# =====================================================================
# Frames e variáveis
# =====================================================================

func _push_frame(this_obj, cls: JClass, method, label: String) -> Frame:
	var f := Frame.new()
	f.this_obj = this_obj
	f.cls = cls
	f.method = method
	f.label = label
	f.scopes = [{}]
	if method != null:
		f.line = method.line
	_frames.push_back(f)
	return f


func _pop_frame() -> void:
	_frames.pop_back()


func _frame() -> Frame:
	return _frames.back()


func _lookup_local(name: String) -> Variant:
	if _frames.is_empty():
		return null
	var scopes: Array = _frame().scopes
	for i in range(scopes.size() - 1, -1, -1):
		if scopes[i].has(name):
			return scopes[i][name]
	return null


## Procura a declaração de um campo subindo pela hierarquia. Devolve [classe_dona, decl] ou null.
func _find_field(cls: JClass, name: String) -> Variant:
	var c = cls
	while c != null:
		if c.field_decls.has(name):
			return [c, c.field_decls[name]]
		for iname in c.interfaces:
			var r = _find_interface_field(iname, name)
			if r != null:
				return r
		c = c.superclass
	return null


func _find_interface_field(iname: String, name: String) -> Variant:
	var ic = classes.get(iname)
	if ic == null:
		return null
	if ic.field_decls.has(name):
		return [ic, ic.field_decls[name]]
	for s in ic.interfaces:
		var r = _find_interface_field(s, name)
		if r != null:
			return r
	return null


func _can_access(decl: Dictionary, owner: JClass) -> bool:
	if decl.access != "private" or _frames.is_empty():
		return true
	var cur: JClass = _frame().cls
	return cur != null and cur.name == owner.name


# =====================================================================
# Tipos e conversões
# =====================================================================

func _default_value(t: String) -> Variant:
	if t == "int" or t == "long":
		return 0
	elif t == "double":
		return 0.0
	elif t == "boolean":
		return false
	elif t == "char":
		return JChar.new(0)
	return null


func _type_of(v) -> String:
	var vtype: int = typeof(v)
	if vtype == TYPE_NIL:
		return "null"
	elif vtype == TYPE_BOOL:
		return "boolean"
	elif vtype == TYPE_INT:
		return "int"
	elif vtype == TYPE_FLOAT:
		return "double"
	elif vtype == TYPE_STRING:
		return "String"
	if v is JChar:
		return "char"
	if v is JObject:
		return v.cls.name
	if v is JArray:
		return v.type
	if v is JClass:
		return "classe " + v.name
	return type_string(typeof(v))


static func _wrap32(x: int) -> int:
	x = x & 0xFFFFFFFF
	if x >= 0x80000000:
		x -= 0x100000000
	return x


func _is_subtype(cls: JClass, type_name: String) -> bool:
	if type_name == "Object":
		return true
	var c = cls
	while c != null:
		if c.name == type_name:
			return true
		for iname in c.interfaces:
			if _interface_extends(iname, type_name):
				return true
		c = c.superclass
	return false


func _interface_extends(iname: String, target: String) -> bool:
	if iname == target:
		return true
	var ic = classes.get(iname)
	if ic == null:
		return false
	for s in ic.interfaces:
		if _interface_extends(s, target):
			return true
	return false


## Valor v pode ser guardado em uma variável do tipo t?
## Devolve 2 = tipo exato, 1 = conversão permitida, -1 = incompatível.
func _match_score(v, t: String) -> int:
	if t == "Object":
		return 1
	elif t == "int" or t == "long":
		if typeof(v) == TYPE_INT:
			return 2
		if v is JChar:
			return 1
		return -1
	elif t == "double":
		if typeof(v) == TYPE_FLOAT:
			return 2
		if typeof(v) == TYPE_INT or v is JChar:
			return 1
		return -1
	elif t == "boolean":
		return 2 if typeof(v) == TYPE_BOOL else -1
	elif t == "char":
		return 2 if v is JChar else -1
	elif t == "String":
		if typeof(v) == TYPE_STRING:
			return 2
		return 1 if typeof(v) == TYPE_NIL else -1
	if typeof(v) == TYPE_NIL:
		return 1
	if t.ends_with("[]"):
		if v is JArray:
			if v.type == t:
				return 2
			return 1 if _array_assignable(v.type, t) else -1
		return -1
	if v is JObject:
		if v.cls.name == t:
			return 2
		return 1 if _is_subtype(v.cls, t) else -1
	return -1


func _array_assignable(from_t: String, to_t: String) -> bool:
	if from_t == to_t:
		return true
	if not (from_t.ends_with("[]") and to_t.ends_with("[]")):
		return false
	var fe := from_t.substr(0, from_t.length() - 2)
	var te := to_t.substr(0, to_t.length() - 2)
	if te == "Object":
		return not (fe in ["int", "long", "double", "boolean", "char"])
	if fe.ends_with("[]") or te.ends_with("[]"):
		return _array_assignable(fe, te)
	var fc = classes.get(fe)
	return fc != null and _is_subtype(fc, te)


## Converte v para o tipo t (int -> double, etc.) ou gera erro de tipo.
func _coerce(v, t: String, what) -> Variant:
	if t == "Object" or t == "void":
		return v
	elif t == "int":
		if typeof(v) == TYPE_INT:
			return _wrap32(v)
		if v is JChar:
			return v.code
	elif t == "long":
		if typeof(v) == TYPE_INT:
			return v
		if v is JChar:
			return v.code
	elif t == "double":
		if typeof(v) == TYPE_FLOAT:
			return v
		if typeof(v) == TYPE_INT:
			return float(v)
		if v is JChar:
			return float(v.code)
	else:
		if _match_score(v, t) > 0:
			return v
	if what is Array:
		what = what[0] % what[1]
	var got := _type_of(v)
	var msg := "Tipo incompatível em %s: esperado %s mas recebeu %s" % [what, t, got]
	if (t == "int" or t == "long") and got == "double":
		msg = "Não dá para guardar um double em %s (%s) sem perder a parte decimal. Use um cast: (int) valor" % [t, what]
	elif t == "String" and got != "null":
		msg += ". Para converter em texto use \"\" + valor"
	elif typeof(v) == TYPE_NIL:
		msg = "Não dá para guardar null em %s, que é do tipo primitivo %s" % [what, t]
	_raise(msg)
	return null


# =====================================================================
# Objetos e chamadas
# =====================================================================

func _instantiate(cls: JClass, args: Array, host = null) -> JObject:
	var obj := JObject.new()
	obj.cls = cls
	obj.host = host
	var c = cls
	while c != null:
		for fd in c.fields:
			obj.fields[fd.name] = fd.value if typeof(fd.value) != TYPE_NIL else _default_value(fd.type)
		c = c.superclass
	_construct(obj, cls, args)
	return null if _has_err else obj


func _construct(obj: JObject, cls: JClass, args: Array) -> void:
	if not _tick():
		return
	if cls.is_native:
		if cls.superclass != null:
			_construct(obj, cls.superclass, [])
			if _has_err:
				return
		if cls.native_ctor.is_valid():
			cls.native_ctor.call(obj, args)
		elif args.size() > 0:
			_raise("A classe %s não tem construtor que recebe argumentos" % cls.name)
		return
	if _frames.size() >= max_depth:
		_raise("StackOverflowError: construtores chamando uns aos outros sem parar")
		return
	var ctor = null
	if cls.ctors.is_empty():
		if args.size() > 0:
			_raise("A classe %s não tem construtor que recebe %d argumento(s)" % [cls.name, args.size()])
			return
	else:
		ctor = _best_overload(cls.ctors, args)
		if ctor == null:
			_raise("Nenhum construtor de %s aceita (%s). Construtores disponíveis: %s" % [cls.name, _arg_types_str(args), _signatures_str(cls.name, cls.ctors)])
			return
		if not _can_access(ctor, cls):
			_raise("O construtor de %s é private" % cls.name)
			return
	var f := _push_frame(obj, cls, ctor, cls.name + ".<construtor>")
	if ctor != null:
		_bind_params(f, ctor, args)
	var explicit = ctor.explicit if ctor != null else null
	if not _has_err and explicit != null and not explicit.sup:
		# this(...): delega para outro construtor da mesma classe
		var a2 := _eval_args(explicit.args)
		if not _has_err:
			_construct(obj, cls, a2)
	elif not _has_err:
		if cls.superclass != null:
			var sargs := []
			if explicit != null:
				sargs = _eval_args(explicit.args)
			if not _has_err:
				_construct(obj, cls.superclass, sargs)
		elif explicit != null and explicit.args.size() > 0:
			_raise("A classe %s não tem superclasse, então super(...) não recebe argumentos" % cls.name)
		if not _has_err:
			_init_fields(obj, cls)
	if not _has_err and ctor != null:
		f.line = ctor.line
		_exec_list(ctor.body.body)
	_pop_frame()


func _init_fields(obj: JObject, cls: JClass) -> void:
	var has_init := false
	for fd in cls.fields:
		if fd.init != null:
			has_init = true
			break
	if not has_init:
		return
	var f := _push_frame(obj, cls, null, cls.name + ".<campos>")
	for fd in cls.fields:
		if fd.init != null:
			f.line = fd.line
			var v = _eval_init(fd.init, fd.type)
			if _has_err:
				break
			v = _coerce(v, fd.type, ["campo '%s'", fd.name])
			if _has_err:
				break
			obj.fields[fd.name] = v
	_pop_frame()


func _bind_params(f: Frame, m: Dictionary, args: Array) -> void:
	var scope: Dictionary = f.scopes[0]
	for i in m.params.size():
		var p = m.params[i]
		var v = _coerce(args[i], p.type, ["argumento '%s' de %s()", [p.n, m.name]])
		if _has_err:
			return
		scope[p.n] = [p.type, v, false]


func _eval_args(nodes: Array) -> Array:
	var args := []
	for a in nodes:
		var v = _eval(a)
		if _has_err:
			return []
		args.append(v)
	return args


func _best_overload(list: Array, args: Array) -> Variant:
	var best = null
	var best_score := -1
	for m in list:
		if m.abstract or m.params.size() != args.size():
			continue
		var score := 0
		var ok := true
		for i in args.size():
			var s := _match_score(args[i], m.params[i].type)
			if s < 0:
				ok = false
				break
			score += s
		if ok and score > best_score:
			best = m
			best_score = score
	return best


## Busca dinâmica (polimorfismo): começa na classe do objeto e sobe na hierarquia.
func _find_method(cls: JClass, name: String, args: Array) -> Variant:
	var c = cls
	while c != null:
		if c.methods.has(name):
			var m = _best_overload(c.methods[name], args)
			if m != null:
				return m
		c = c.superclass
	return null


func _method_not_found_msg(cls: JClass, name: String, args: Array) -> String:
	var candidates := []
	var c = cls
	while c != null:
		if c.methods.has(name):
			candidates.append_array(c.methods[name])
		c = c.superclass
	if candidates.is_empty():
		return "A classe %s não tem o método '%s'" % [cls.name, name]
	return "O método %s() de %s não aceita (%s). Opções: %s" % [name, cls.name, _arg_types_str(args), _signatures_str(name, candidates)]


func _arg_types_str(args: Array) -> String:
	var parts := []
	for a in args:
		parts.append(_type_of(a))
	return ", ".join(parts)


func _signatures_str(name: String, list: Array) -> String:
	var parts := []
	for m in list:
		parts.append("%s(%s)" % [name, _param_types_str(m.params)])
	return ", ".join(parts)


func _owner_class(m: Dictionary, this_obj) -> JClass:
	# procura pela hierarquia do objeto (funciona mesmo após recarregar classes)
	if this_obj is JObject:
		var c = this_obj.cls
		while c != null:
			if c.name == m.owner:
				return c
			c = c.superclass
	return classes.get(m.owner)


func _invoke(m: Dictionary, this_obj, args: Array) -> Variant:
	if not _tick():
		return null
	if m.get("host_call", false):
		return _invoke_host(m, this_obj, args)
	if m.get("native") != null:
		var cargs := []
		for i in args.size():
			var v = _coerce(args[i], m.params[i].type, ["argumento %d de %s()", [i + 1, m.name]])
			if _has_err:
				return null
			cargs.append(v)
		var r = m.native.call(this_obj, cargs)
		if _has_err:
			return null
		if m.ret == "void":
			return null
		return _coerce(r, m.ret, ["retorno de %s()", m.name])
	if _frames.size() >= max_depth:
		_raise("StackOverflowError: chamadas demais uma dentro da outra. Existe uma recursão sem fim em %s()?" % m.name)
		return null
	var owner := _owner_class(m, this_obj)
	var f := _push_frame(null if m.static else this_obj, owner, m, "%s.%s" % [m.owner, m.name])
	_bind_params(f, m, args)
	if _has_err:
		_pop_frame()
		return null
	_ret_val = null
	var st := _exec_list(m.body.body)
	var rv = _ret_val
	_ret_val = null
	if st == ERROR:
		_pop_frame()
		return null
	if m.ret != "void":
		if st != RETURN:
			_raise("O método %s() precisa retornar um valor do tipo %s (faltou um return)" % [m.name, m.ret])
			_pop_frame()
			return null
		rv = _coerce(rv, m.ret, ["retorno de %s()", m.name])
	_pop_frame()
	return rv


## Método declarado como `native` no Java: chama o método de mesmo nome no host
## (o Node do jogo ligado ao objeto). Ex.: `private native void causarDano(int dano);`
## chama host.causarDano(dano).
func _invoke_host(m: Dictionary, this_obj, args: Array):
	var host = this_obj.host if this_obj is JObject else null
	if host == null or not is_instance_valid(host) or not host.has_method(m.name):
		_raise("O método native %s() não está ligado a nada no jogo" % m.name)
		return null
	var cargs := []
	for i in args.size():
		var v = _coerce(args[i], m.params[i].type, ["argumento %d de %s()", [i + 1, m.name]])
		if _has_err:
			return null
		cargs.append(v)
	var r = host.callv(m.name, cargs)
	if _has_err or m.ret == "void":
		return null
	return _coerce(r, m.ret, ["retorno de %s()", m.name])


# =====================================================================
# Comandos
# =====================================================================

func _exec_list(stmts: Array) -> int:
	for s in stmts:
		var st := _exec(s)
		if st != NORMAL:
			return st
	return NORMAL


func _exec(s: Dictionary) -> int:
	if not _tick():
		return ERROR
	var f := _frame()
	f.line = s.line
	var kind: String = s.k
	if kind == "block":
		f.scopes.push_back({})
		var st := _exec_list(s.body)
		f.scopes.pop_back()
		return st
	elif kind == "var":
		return _exec_var(s)
	elif kind == "expr":
		_eval(s.e)
		return ERROR if _has_err else NORMAL
	elif kind == "if":
		var c = _eval_cond(s.cond, "if")
		if _has_err:
			return ERROR
		if c:
			return _exec(s.then)
		elif s["else"] != null:
			return _exec(s["else"])
		return NORMAL
	elif kind == "while":
		while true:
			var c = _eval_cond(s.cond, "while")
			if _has_err:
				return ERROR
			if not c:
				break
			var st := _exec(s.body)
			if st == BREAK:
				break
			if st == RETURN or st == ERROR:
				return st
		return NORMAL
	elif kind == "dowhile":
		while true:
			var st := _exec(s.body)
			if st == BREAK:
				break
			if st == RETURN or st == ERROR:
				return st
			var c = _eval_cond(s.cond, "do-while")
			if _has_err:
				return ERROR
			if not c:
				break
		return NORMAL
	elif kind == "for":
		return _exec_for(s)
	elif kind == "foreach":
		return _exec_foreach(s)
	elif kind == "return":
		var v = null
		var m = f.method
		if s.e != null:
			if m == null or m.ret == "void":
				_raise("Um método void não pode retornar um valor")
				return ERROR
			v = _eval(s.e)
			if _has_err:
				return ERROR
		elif m != null and m.ret != "void":
			_raise("O método %s() precisa retornar um valor do tipo %s" % [m.name, m.ret])
			return ERROR
		_ret_val = v
		return RETURN
	elif kind == "break":
		return BREAK
	elif kind == "continue":
		return CONTINUE
	elif kind == "empty":
		return NORMAL
	_raise("Comando desconhecido: " + str(s.k))
	return ERROR


func _exec_var(s: Dictionary) -> int:
	var f := _frame()
	var scope: Dictionary = f.scopes.back()
	for d in s.decls:
		if _lookup_local(d.n) != null:
			_raise("A variável '%s' já foi declarada neste método" % d.n)
			return ERROR
		var v = _unset
		if d.init != null:
			v = _eval_init(d.init, d.type)
			if _has_err:
				return ERROR
			v = _coerce(v, d.type, ["variável '%s'", d.n])
			if _has_err:
				return ERROR
		scope[d.n] = [d.type, v, s.final]
	return NORMAL


func _exec_for(s: Dictionary) -> int:
	var f := _frame()
	f.scopes.push_back({})
	var result := NORMAL
	for st in s.init:
		if _exec(st) == ERROR:
			f.scopes.pop_back()
			return ERROR
	while true:
		if s.cond != null:
			var c = _eval_cond(s.cond, "for")
			if _has_err:
				result = ERROR
				break
			if not c:
				break
		var st := _exec(s.body)
		if st == BREAK:
			break
		if st == RETURN or st == ERROR:
			result = st
			break
		for u in s.update:
			_eval(u)
			if _has_err:
				break
		if _has_err:
			result = ERROR
			break
		if not _tick():
			result = ERROR
			break
	f.scopes.pop_back()
	return result


func _exec_foreach(s: Dictionary) -> int:
	var coll = _eval(s.iter)
	if _has_err:
		return ERROR
	var items: Array
	if coll is JArray:
		items = coll.data.duplicate()
	elif coll is JObject and coll.host is Array:
		items = coll.host.duplicate()
	elif typeof(coll) == TYPE_NIL:
		_raise("NullPointerException: o for-each recebeu null em vez de um array ou lista")
		return ERROR
	else:
		_raise("O for-each só funciona com arrays e listas, não com %s" % _type_of(coll))
		return ERROR
	var f := _frame()
	for item in items:
		var v = _coerce(item, s.type, ["variável '%s' do for-each", s.n])
		if _has_err:
			return ERROR
		f.scopes.push_back({s.n: [s.type, v, false]})
		var st := _exec(s.body)
		f.scopes.pop_back()
		if st == BREAK:
			break
		if st == RETURN or st == ERROR:
			return st
	return NORMAL


func _eval_cond(n: Dictionary, where: String) -> Variant:
	var c = _eval(n)
	if _has_err:
		return false
	if typeof(c) != TYPE_BOOL:
		var hint := ""
		if n.k == "assign" and n.op == "=":
			hint = " Para comparar use == em vez de ="
		_raise("A condição do %s precisa ser boolean (true/false), mas é %s.%s" % [where, _type_of(c), hint])
		return false
	return c


# =====================================================================
# Expressões
# =====================================================================

func _eval_init(n, type: String) -> Variant:
	if n is Dictionary and n.k == "arrlit":
		return _eval_arrlit(n, type)
	return _eval(n)


func _eval(n: Dictionary) -> Variant:
	var kind: String = n.k
	if kind == "lit":
		return n.v
	elif kind == "name":
		return _eval_name(n)
	elif kind == "this":
		var t = _frame().this_obj
		if t == null:
			_raise("'this' não pode ser usado dentro de um método static")
		return t
	elif kind == "field":
		return _eval_field(n)
	elif kind == "index":
		var ref := _resolve_ref(n)
		return null if _has_err else _ref_get(ref)
	elif kind == "call":
		return _eval_call(n)
	elif kind == "new":
		return _eval_new(n)
	elif kind == "newarr":
		return _eval_newarr(n)
	elif kind == "arrlit":
		return _eval_arrlit(n, n.type)
	elif kind == "bin":
		return _eval_bin(n)
	elif kind == "un":
		return _eval_unary(n)
	elif kind == "incdec":
		return _eval_incdec(n)
	elif kind == "assign":
		return _eval_assign(n)
	elif kind == "ternary":
		var c = _eval_cond(n.cond, "operador ?:")
		if _has_err:
			return null
		return _eval(n.a) if c else _eval(n.b)
	elif kind == "cast":
		return _eval_cast(n)
	elif kind == "instanceof":
		var v = _eval(n.e)
		if _has_err:
			return null
		if typeof(v) == TYPE_NIL:
			return false
		return _match_score(v, n.type) > 0
	elif kind == "ctorcall":
		_raise("this(...) e super(...) só podem ser usados como primeira linha de um construtor")
		return null
	elif kind == "super":
		_raise("'super' sozinho não é um valor. Use super.metodo() ou super(...)")
		return null
	_raise("Expressão desconhecida: " + str(n.k))
	return null


func _eval_name(n: Dictionary) -> Variant:
	var rec = _lookup_local(n.n)
	if rec != null:
		if is_same(rec[1], _unset):
			_raise("A variável '%s' foi declarada mas ainda não recebeu um valor" % n.n)
			return null
		return rec[1]
	var f := _frame()
	if f.cls != null:
		var fi = _find_field(f.cls, n.n)
		if fi != null:
			var ref := _field_ref(fi, f.this_obj, n.n)
			return null if _has_err else _ref_get(ref)
	if globals.has(n.n):
		return globals[n.n][1]
	if classes.has(n.n):
		return classes[n.n]
	_raise("A variável '%s' não existe. Ela foi declarada? (maiúsculas e minúsculas fazem diferença)" % n.n)
	return null


func _eval_field(n: Dictionary) -> Variant:
	var o = _eval(n.obj)
	if _has_err:
		return null
	if o is JArray:
		if n.n == "length":
			return o.data.size()
		_raise("Arrays só têm o campo 'length'")
		return null
	if typeof(o) == TYPE_STRING and n.n == "length":
		_raise("Em String, length é um método: use texto.length()")
		return null
	var ref := _member_ref(o, n.n)
	return null if _has_err else _ref_get(ref)


# ---- referências (lugares onde se pode ler e escrever) ----

func _field_ref(fi: Array, this_obj, name: String) -> Dictionary:
	var owner: JClass = fi[0]
	var decl: Dictionary = fi[1]
	if not _can_access(decl, owner):
		_raise("O campo '%s' é private em %s e não pode ser acessado de fora dessa classe. Use um método (getter/setter)." % [name, owner.name])
		return {}
	if decl.static:
		return {"kind": "static", "cls": owner, "name": name, "decl": decl}
	if this_obj == null:
		_raise("O campo '%s' é de instância e não pode ser usado em um método static" % name)
		return {}
	return {"kind": "field", "obj": this_obj, "name": name, "decl": decl, "owner": owner}


func _member_ref(o, name: String) -> Dictionary:
	if o is JClass:
		var fi = _find_field(o, name)
		if fi == null or not fi[1].static:
			_raise("A classe %s não tem o campo static '%s'" % [o.name, name])
			return {}
		return _field_ref(fi, null, name)
	if typeof(o) == TYPE_NIL:
		_raise("NullPointerException: tentou acessar '%s' de uma referência que é null" % name)
		return {}
	if o is JObject:
		var fi = _find_field(o.cls, name)
		if fi == null:
			_raise("A classe %s não tem o campo '%s'" % [o.cls.name, name])
			return {}
		return _field_ref(fi, o, name)
	_raise("Valores do tipo %s não têm o campo '%s'" % [_type_of(o), name])
	return {}


func _resolve_ref(n: Dictionary) -> Dictionary:
	var kind: String = n.k
	if kind == "name":
		var rec = _lookup_local(n.n)
		if rec != null:
			return {"kind": "local", "rec": rec, "name": n.n}
		var f := _frame()
		if f.cls != null:
			var fi = _find_field(f.cls, n.n)
			if fi != null:
				return _field_ref(fi, f.this_obj, n.n)
		if globals.has(n.n):
			return {"kind": "local", "rec": globals[n.n], "name": n.n}
		_raise("A variável '%s' não existe. Ela foi declarada?" % n.n)
		return {}
	elif kind == "field":
		var o = _eval(n.obj)
		if _has_err:
			return {}
		if o is JArray and n.n == "length":
			_raise("O tamanho de um array (length) não pode ser alterado")
			return {}
		return _member_ref(o, n.n)
	elif kind == "index":
		var a = _eval(n.arr)
		if _has_err:
			return {}
		var i = _eval(n.idx)
		if _has_err:
			return {}
		if i is JChar:
			i = i.code
		if typeof(i) != TYPE_INT:
			_raise("O índice de um array precisa ser int, mas é %s" % _type_of(i))
			return {}
		if typeof(a) == TYPE_NIL:
			_raise("NullPointerException: o array é null")
			return {}
		if not (a is JArray):
			if typeof(a) == TYPE_STRING:
				_raise("Para pegar um caractere de uma String use texto.charAt(i)")
			elif a is JObject and a.host is Array:
				_raise("Para acessar um item da lista use lista.get(i)")
			else:
				_raise("Só arrays podem ser acessados com [ ], mas isto é %s" % _type_of(a))
			return {}
		if i < 0 or i >= a.data.size():
			_raise("ArrayIndexOutOfBoundsException: índice %d fora do array de tamanho %d (os índices vão de 0 a %d)" % [i, a.data.size(), a.data.size() - 1])
			return {}
		return {"kind": "array", "arr": a, "i": i}
	_raise("Não é possível atribuir a isso")
	return {}


func _ref_type(ref: Dictionary) -> String:
	var kind: String = ref.kind
	if kind == "local":
		return ref.rec[0]
	elif kind == "field" or kind == "static":
		return ref.decl.type
	elif kind == "array":
		return ref.arr.element_type()
	return "Object"


func _ref_get(ref: Dictionary) -> Variant:
	var kind: String = ref.kind
	if kind == "local":
		if is_same(ref.rec[1], _unset):
			_raise("A variável '%s' foi declarada mas ainda não recebeu um valor" % ref.name)
			return null
		return ref.rec[1]
	elif kind == "field":
		return ref.obj.fields.get(ref.name)
	elif kind == "static":
		return ref.cls.static_values.get(ref.name)
	elif kind == "array":
		return ref.arr.data[ref.i]
	return null


func _ref_set(ref: Dictionary, v, cast := false) -> void:
	var t := _ref_type(ref)
	if cast:
		v = _cast_value(v, t)
	else:
		var what = ["a posição %d do array", ref.i] if ref.kind == "array" else ["'%s'", ref.name]
		v = _coerce(v, t, what)
	if _has_err:
		return
	var kind: String = ref.kind
	if kind == "local":
		if ref.rec[2] and not is_same(ref.rec[1], _unset):
			_raise("'%s' é final e não pode ser alterada" % ref.name)
			return
		ref.rec[1] = v
	elif kind == "field":
		if ref.decl.final and not _in_ctor_of(ref.owner):
			_raise("O campo '%s' é final e só pode receber valor no construtor" % ref.name)
			return
		ref.obj.fields[ref.name] = v
	elif kind == "static":
		if ref.decl.final and not _frame().label.ends_with(".<static>"):
			_raise("O campo '%s' é final (constante) e não pode ser alterado" % ref.name)
			return
		ref.cls.static_values[ref.name] = v
	elif kind == "array":
		ref.arr.data[ref.i] = v


func _in_ctor_of(owner: JClass) -> bool:
	var f := _frame()
	if f.cls == null or f.cls.name != owner.name:
		return false
	return f.method == null or f.method.get("is_ctor", false)


# ---- atribuição, ++ e -- ----

func _eval_assign(n: Dictionary) -> Variant:
	var ref := _resolve_ref(n.target)
	if _has_err:
		return null
	var v = _eval(n.value)
	if _has_err:
		return null
	if n.op == "=":
		if n.value.k == "arrlit":
			v = _eval_arrlit(n.value, _ref_type(ref))
		_ref_set(ref, v)
		return null if _has_err else _ref_get(ref)
	var cur = _ref_get(ref)
	if _has_err:
		return null
	var r = _binary_op(n.op.substr(0, 1), cur, v)
	if _has_err:
		return null
	# operadores compostos (+=, -=...) fazem cast implícito, como no Java
	_ref_set(ref, r, typeof(cur) != TYPE_STRING)
	return null if _has_err else _ref_get(ref)


func _eval_incdec(n: Dictionary) -> Variant:
	var ref := _resolve_ref(n.target)
	if _has_err:
		return null
	var cur = _ref_get(ref)
	if _has_err:
		return null
	var nv
	var delta := 1 if n.op == "++" else -1
	if typeof(cur) == TYPE_INT or typeof(cur) == TYPE_FLOAT:
		nv = cur + delta
	elif cur is JChar:
		nv = JChar.new(cur.code + delta)
	else:
		_raise("'%s' só funciona com números, não com %s" % [n.op, _type_of(cur)])
		return null
	_ref_set(ref, nv, true)
	if _has_err:
		return null
	return _ref_get(ref) if n.prefix else cur


# ---- operadores ----

func _eval_bin(n: Dictionary) -> Variant:
	var op: String = n.op
	if op == "&&" or op == "||":
		var l = _eval(n.l)
		if _has_err:
			return null
		if typeof(l) != TYPE_BOOL:
			_raise("O operador %s precisa de valores boolean, mas recebeu %s" % [op, _type_of(l)])
			return null
		if op == "&&" and not l:
			return false
		if op == "||" and l:
			return true
		var r = _eval(n.r)
		if _has_err:
			return null
		if typeof(r) != TYPE_BOOL:
			_raise("O operador %s precisa de valores boolean, mas recebeu %s" % [op, _type_of(r)])
			return null
		return r
	var a = _eval(n.l)
	if _has_err:
		return null
	var b = _eval(n.r)
	if _has_err:
		return null
	return _binary_op(op, a, b)


func _num(v) -> Variant:
	if v is JChar:
		return v.code
	return v


func _is_num(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT or v is JChar


func _binary_op(op: String, a, b) -> Variant:
	if op == "+" and (typeof(a) == TYPE_STRING or typeof(b) == TYPE_STRING):
		var sa := _to_str(a)
		if _has_err:
			return null
		var sb := _to_str(b)
		return sa + sb
	if op == "==":
		return _equals_op(a, b)
	if op == "!=":
		var e = _equals_op(a, b)
		return null if _has_err else not e
	if (op == "&" or op == "|" or op == "^") and typeof(a) == TYPE_BOOL and typeof(b) == TYPE_BOOL:
		if op == "&": return a and b
		elif op == "|": return a or b
		elif op == "^": return a != b
	if not (_is_num(a) and _is_num(b)):
		_raise("O operador '%s' não pode ser usado entre %s e %s" % [op, _type_of(a), _type_of(b)])
		return null
	var x = _num(a)
	var y = _num(b)
	var is_float := typeof(x) == TYPE_FLOAT or typeof(y) == TYPE_FLOAT
	if op == "+": return x + y
	elif op == "-": return x - y
	elif op == "*": return x * y
	elif op == "/":
		if is_float:
			if y == 0:
				if x == 0 or is_nan(x):
					return NAN
				return INF if x > 0 else -INF
			return float(x) / float(y)
		if y == 0:
			_raise("ArithmeticException: divisão por zero")
			return null
		return x / y
	elif op == "%":
		if is_float:
			return fmod(x, y)
		if y == 0:
			_raise("ArithmeticException: divisão por zero (resto %)")
			return null
		return x % y
	elif op == "<": return x < y
	elif op == ">": return x > y
	elif op == "<=": return x <= y
	elif op == ">=": return x >= y
	elif op == "&" or op == "|" or op == "^":
		if is_float:
			_raise("O operador '%s' não funciona com double" % op)
			return null
		if op == "&": return x & y
		elif op == "|": return x | y
		elif op == "^": return x ^ y
	_raise("Operador desconhecido '%s'" % op)
	return null


func _equals_op(a, b) -> bool:
	if _is_num(a) and _is_num(b):
		return _num(a) == _num(b)
	if typeof(a) == TYPE_NIL or typeof(b) == TYPE_NIL:
		return typeof(a) == typeof(b)
	if typeof(a) == TYPE_BOOL and typeof(b) == TYPE_BOOL:
		return a == b
	if typeof(a) == TYPE_STRING and typeof(b) == TYPE_STRING:
		# Simplificação: em Java o == compara referências de String;
		# aqui compara o conteúdo (o correto em Java é usar .equals()).
		return a == b
	if typeof(a) == TYPE_OBJECT and typeof(b) == TYPE_OBJECT:
		return is_same(a, b)
	if typeof(a) != typeof(b):
		_raise("Não dá para comparar %s com %s usando ==" % [_type_of(a), _type_of(b)])
	return false


func _eval_unary(n: Dictionary) -> Variant:
	var v = _eval(n.e)
	if _has_err:
		return null
	var op: String = n.op
	if op == "!":
		if typeof(v) != TYPE_BOOL:
			_raise("O operador ! só funciona com boolean, não com %s" % _type_of(v))
			return null
		return not v
	elif op == "-":
		if not _is_num(v):
			_raise("O operador - só funciona com números, não com %s" % _type_of(v))
			return null
		return -_num(v)
	elif op == "+":
		if not _is_num(v):
			_raise("O operador + só funciona com números, não com %s" % _type_of(v))
			return null
		return _num(v)
	elif op == "~":
		if typeof(_num(v)) != TYPE_INT:
			_raise("O operador ~ só funciona com int")
			return null
		return ~_num(v)
	return null


func _eval_cast(n: Dictionary) -> Variant:
	var v = _eval(n.e)
	if _has_err:
		return null
	return _cast_value(v, n.type)


func _cast_value(v, t: String) -> Variant:
	if t == "int" or t == "long":
		if typeof(v) == TYPE_FLOAT:
			if is_nan(v):
				return 0
			var r := int(v)
			return _wrap32(r) if t == "int" else r
		if typeof(v) == TYPE_INT:
			return _wrap32(v) if t == "int" else v
		if v is JChar:
			return v.code
	elif t == "double":
		if _is_num(v):
			return float(_num(v))
	elif t == "char":
		if v is JChar:
			return v
		if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			return JChar.new(int(v) & 0xFFFF)
	elif t == "boolean":
		if typeof(v) == TYPE_BOOL:
			return v
	else:
		if typeof(v) == TYPE_NIL or _match_score(v, t) > 0:
			return v
		if v is JObject or v is JArray or typeof(v) == TYPE_STRING:
			_raise("ClassCastException: um %s não pode ser convertido para %s" % [_type_of(v), t])
			return null
	_raise("Não é possível converter %s para %s" % [_type_of(v), t])
	return null


# ---- new e arrays ----

func _eval_new(n: Dictionary) -> Variant:
	var args := _eval_args(n.args)
	if _has_err:
		return null
	if n.cls == "String":
		if args.is_empty():
			return ""
		return _to_str(args[0])
	var cls = classes.get(n.cls)
	if cls == null:
		_raise("A classe '%s' não existe" % n.cls)
		return null
	if cls.is_interface:
		_raise("%s é uma interface e não pode ser instanciada com new. Crie uma classe que a implemente." % n.cls)
		return null
	if cls.is_abstract:
		_raise("%s é uma classe abstrata e não pode ser instanciada com new. Use uma subclasse." % n.cls)
		return null
	return _instantiate(cls, args)


func _eval_newarr(n: Dictionary) -> Variant:
	var sizes := []
	for s in n.sizes:
		var v = _eval(s)
		if _has_err:
			return null
		v = _num(v)
		if typeof(v) != TYPE_INT:
			_raise("O tamanho de um array precisa ser int, não %s" % _type_of(v))
			return null
		if v < 0:
			_raise("NegativeArraySizeException: tamanho de array negativo (%d)" % v)
			return null
		if v > 1000000:
			_raise("Array grande demais (%d posições)" % v)
			return null
		sizes.append(v)
	return _make_array(n.type, sizes, 0)


func _make_array(type: String, sizes: Array, idx: int) -> JArray:
	var arr := JArray.new(type, [])
	var elem := arr.element_type()
	var size: int = sizes[idx]
	arr.data.resize(size)
	for i in size:
		if idx + 1 < sizes.size():
			arr.data[i] = _make_array(elem, sizes, idx + 1)
		else:
			arr.data[i] = _default_value(elem)
	return arr


func _eval_arrlit(n: Dictionary, type: String) -> Variant:
	if not type.ends_with("[]"):
		_raise("Chaves { } só podem ser usadas para criar arrays")
		return null
	var arr := JArray.new(type, [])
	var elem := arr.element_type()
	for item in n.items:
		var v = _eval_init(item, elem)
		if _has_err:
			return null
		v = _coerce(v, elem, "item do array")
		if _has_err:
			return null
		arr.data.append(v)
	return arr


# ---- chamadas de método ----

func _eval_call(n: Dictionary) -> Variant:
	var f := _frame()
	var name: String = n.n
	if n.obj == null:
		var args := _eval_args(n.args)
		if _has_err:
			return null
		if f.cls == null:
			_raise("O método '%s' não existe" % name)
			return null
		var start: JClass = f.this_obj.cls if f.this_obj != null else f.cls
		var m = _find_method(start, name, args)
		if m != null and m.access == "private" and m.owner != f.cls.name:
			m = _find_method(f.cls, name, args)
		if m == null:
			m = _find_method(f.cls, name, args)
		if m == null:
			if start.has_java_method(name) or f.cls.has_java_method(name):
				_raise(_method_not_found_msg(start, name, args))
			else:
				_raise("O método '%s' não existe na classe %s" % [name, f.cls.name])
			return null
		if m.static:
			return _invoke(m, null, args)
		if f.this_obj == null:
			_raise("O método %s() não é static e não pode ser chamado de dentro de um método static" % name)
			return null
		return _invoke(m, f.this_obj, args)

	if n.obj.k == "super":
		var args := _eval_args(n.args)
		if _has_err:
			return null
		if f.this_obj == null:
			_raise("'super' não pode ser usado em método static")
			return null
		var sup = f.cls.superclass
		var m = _find_method(sup, name, args) if sup != null else null
		if m == null:
			if args.is_empty() and name in ["toString", "hashCode", "equals"]:
				return _object_builtin(f.this_obj, name, args)
			_raise("A superclasse de %s não tem o método %s(%s)" % [f.cls.name, name, _arg_types_str(args)])
			return null
		return _invoke(m, f.this_obj, args)

	var o = _eval(n.obj)
	if _has_err:
		return null
	var args := _eval_args(n.args)
	if _has_err:
		return null
	if o is JClass:
		var m = _find_method(o, name, args)
		if m == null:
			_raise(_method_not_found_msg(o, name, args))
			return null
		if not m.static:
			_raise("O método %s() não é static: chame-o em um objeto, não na classe %s" % [name, o.name])
			return null
		if not _can_access(m, _owner_class(m, null)):
			_raise("O método %s() é private em %s" % [name, o.name])
			return null
		return _invoke(m, null, args)
	if typeof(o) == TYPE_NIL:
		_raise("NullPointerException: tentou chamar %s() em uma referência que é null" % name)
		return null
	if typeof(o) == TYPE_STRING:
		return _string_method(o, name, args)
	if o is JObject:
		var m = _find_method(o.cls, name, args)
		if m == null:
			if name in ["toString", "equals", "hashCode", "getClass"]:
				return _object_builtin(o, name, args)
			_raise(_method_not_found_msg(o.cls, name, args))
			return null
		if not _can_access(m, _owner_class(m, o)):
			_raise("O método %s() é private em %s e não pode ser chamado de fora dessa classe" % [name, m.owner])
			return null
		return _invoke(m, o, args)
	if o is JArray:
		if name == "length":
			_raise("Em arrays, length é um campo, sem parênteses: array.length")
		else:
			_raise("Arrays não têm o método %s()" % name)
		return null
	_raise("Valores do tipo %s não têm métodos (tentou chamar %s())" % [_type_of(o), name])
	return null


func _object_builtin(o: JObject, name: String, args: Array) -> Variant:
	if name == "toString":
		if args.is_empty():
			return "%s@%x" % [o.cls.name, o.get_instance_id() & 0xFFFFFF]
	elif name == "equals":
		if args.size() == 1:
			return is_same(o, args[0])
	elif name == "hashCode":
		if args.is_empty():
			return o.get_instance_id() & 0x7FFFFFFF
	elif name == "getClass":
		if args.is_empty():
			return classes.get(o.cls.name)
	_raise("O método %s() não aceita esses argumentos" % name)
	return null


## Chama equals() do aluno se existir (usado por ArrayList.contains etc.)
func java_equals(a, b) -> bool:
	if a is JObject:
		var m = _find_method(a.cls, "equals", [b])
		if m != null:
			var r = _invoke(m, a, [b])
			return r == true
		return is_same(a, b)
	if typeof(a) == TYPE_STRING or typeof(b) == TYPE_STRING:
		return typeof(a) == typeof(b) and a == b
	if typeof(a) == TYPE_OBJECT or typeof(b) == TYPE_OBJECT:
		return is_same(a, b)
	if _is_num(a) and _is_num(b):
		return _num(a) == _num(b)
	return typeof(a) == typeof(b) and a == b


# =====================================================================
# Texto
# =====================================================================

func _double_str(x: float) -> String:
	if is_nan(x):
		return "NaN"
	if is_inf(x):
		return "Infinity" if x > 0 else "-Infinity"
	if x == floorf(x) and absf(x) < 1e7:
		return "%d.0" % int(x)
	return str(x)


func _to_str(v) -> String:
	var vtype: int = typeof(v)
	if vtype == TYPE_NIL:
		return "null"
	elif vtype == TYPE_BOOL:
		return "true" if v else "false"
	elif vtype == TYPE_INT:
		return str(v)
	elif vtype == TYPE_FLOAT:
		return _double_str(v)
	elif vtype == TYPE_STRING:
		return v
	if v is JChar:
		return char(v.code)
	if v is JObject:
		var m = _find_method(v.cls, "toString", [])
		if m != null:
			var r = _invoke(m, v, [])
			return "" if _has_err else _to_str(r)
		return _object_builtin(v, "toString", [])
	if v is JArray:
		return "%s@%x" % [v.type, v.get_instance_id() & 0xFFFFFF]
	if v is JClass:
		return "class " + v.name
	return str(v)


func _string_method(s: String, name: String, args: Array) -> Variant:
	var argc := args.size()
	if name == "length":
		if argc == 0:
			return s.length()
	elif name == "isEmpty":
		if argc == 0:
			return s.is_empty()
	elif name == "charAt":
		if argc == 1 and typeof(args[0]) == TYPE_INT:
			var i: int = args[0]
			if i < 0 or i >= s.length():
				_raise("StringIndexOutOfBoundsException: índice %d fora do texto de tamanho %d" % [i, s.length()])
				return null
			return JChar.new(s.unicode_at(i))
	elif name == "equals":
		if argc == 1:
			return typeof(args[0]) == TYPE_STRING and args[0] == s
	elif name == "equalsIgnoreCase":
		if argc == 1:
			return typeof(args[0]) == TYPE_STRING and args[0].to_lower() == s.to_lower()
	elif name == "compareTo":
		if argc == 1 and typeof(args[0]) == TYPE_STRING:
			return _compare_str(s, args[0])
	elif name == "substring":
		if argc >= 1 and typeof(args[0]) == TYPE_INT:
			var a: int = args[0]
			var b: int = args[1] if argc == 2 else s.length()
			if argc == 2 and typeof(args[1]) != TYPE_INT:
				pass
			elif a < 0 or b > s.length() or a > b:
				_raise("StringIndexOutOfBoundsException: substring(%d, %d) em texto de tamanho %d" % [a, b, s.length()])
				return null
			else:
				return s.substr(a, b - a)
	elif name == "indexOf":
		if argc == 1:
			return s.find(_to_str(args[0]))
	elif name == "lastIndexOf":
		if argc == 1:
			return s.rfind(_to_str(args[0]))
	elif name == "contains":
		if argc == 1:
			return s.contains(_to_str(args[0]))
	elif name == "startsWith":
		if argc == 1:
			return s.begins_with(_to_str(args[0]))
	elif name == "endsWith":
		if argc == 1:
			return s.ends_with(_to_str(args[0]))
	elif name == "toUpperCase":
		if argc == 0:
			return s.to_upper()
	elif name == "toLowerCase":
		if argc == 0:
			return s.to_lower()
	elif name == "trim" or name == "strip":
		if argc == 0:
			return s.strip_edges()
	elif name == "replace":
		if argc == 2:
			return s.replace(_to_str(args[0]), _to_str(args[1]))
	elif name == "concat":
		if argc == 1:
			return s + _to_str(args[0])
	elif name == "repeat":
		if argc == 1 and typeof(args[0]) == TYPE_INT:
			return s.repeat(maxi(args[0], 0))
	elif name == "split":
		if argc == 1 and typeof(args[0]) == TYPE_STRING:
			var parts := Array(s.split(args[0]))
			return JArray.new("String[]", parts)
	elif name == "toCharArray":
		if argc == 0:
			var chars := []
			for i in s.length():
				chars.append(JChar.new(s.unicode_at(i)))
			return JArray.new("char[]", chars)
	elif name == "toString":
		if argc == 0:
			return s
	elif name == "hashCode":
		if argc == 0:
			return _wrap32(s.hash())
	_raise("String não tem o método %s(%s)" % [name, _arg_types_str(args)])
	return null


func _compare_str(a: String, b: String) -> int:
	var n := mini(a.length(), b.length())
	for i in n:
		var d := a.unicode_at(i) - b.unicode_at(i)
		if d != 0:
			return d
	return a.length() - b.length()


# =====================================================================
# Biblioteca padrão mínima: System.out, Math, Integer, Double, String, ArrayList
# =====================================================================

func _print(text: String) -> void:
	output_log += text
	output.emit(text)


func _install_builtins() -> void:
	var interp := self

	var ps := define_native_class("PrintStream")
	ps.add_method("println", func(_t, _a): interp._print("\n"))
	ps.add_method("println", func(_t, a): interp._print(interp._to_str(a[0]) + "\n"), ["Object"])
	ps.add_method("print", func(_t, a): interp._print(interp._to_str(a[0])), ["Object"])
	var out := JObject.new()
	out.cls = ps
	var system := define_native_class("System")
	system.add_field("out", "PrintStream", out, true, true)
	system.add_static_method("currentTimeMillis", func(_t, _a): return Time.get_ticks_msec(), [], "long")

	var math := define_native_class("Math")
	math.add_field("PI", "double", PI, true, true)
	math.add_field("E", "double", exp(1.0), true, true)
	math.add_static_method("abs", func(_t, a): return absi(a[0]), ["int"], "int")
	math.add_static_method("abs", func(_t, a): return absf(a[0]), ["double"], "double")
	math.add_static_method("max", func(_t, a): return maxi(a[0], a[1]), ["int", "int"], "int")
	math.add_static_method("max", func(_t, a): return maxf(a[0], a[1]), ["double", "double"], "double")
	math.add_static_method("min", func(_t, a): return mini(a[0], a[1]), ["int", "int"], "int")
	math.add_static_method("min", func(_t, a): return minf(a[0], a[1]), ["double", "double"], "double")
	math.add_static_method("pow", func(_t, a): return pow(a[0], a[1]), ["double", "double"], "double")
	math.add_static_method("sqrt", func(_t, a): return sqrt(a[0]) if a[0] >= 0 else NAN, ["double"], "double")
	math.add_static_method("floor", func(_t, a): return floorf(a[0]), ["double"], "double")
	math.add_static_method("ceil", func(_t, a): return ceilf(a[0]), ["double"], "double")
	math.add_static_method("round", func(_t, a): return int(floor(a[0] + 0.5)), ["double"], "long")
	math.add_static_method("random", func(_t, _a): return randf(), [], "double")
	math.add_static_method("sin", func(_t, a): return sin(a[0]), ["double"], "double")
	math.add_static_method("cos", func(_t, a): return cos(a[0]), ["double"], "double")

	var integer := define_native_class("Integer")
	integer.add_field("MAX_VALUE", "int", 2147483647, true, true)
	integer.add_field("MIN_VALUE", "int", -2147483648, true, true)
	integer.add_static_method("parseInt", func(_t, a):
		var s: String = a[0].strip_edges()
		if not s.is_valid_int():
			interp.throw_error("NumberFormatException: \"%s\" não é um número inteiro" % s)
			return 0
		return s.to_int()
	, ["String"], "int")
	integer.add_static_method("toString", func(_t, a): return str(a[0]), ["int"], "String")
	var dbl := define_native_class("Double")
	dbl.add_static_method("parseDouble", func(_t, a):
		var s: String = a[0].strip_edges()
		if not s.is_valid_float():
			interp.throw_error("NumberFormatException: \"%s\" não é um número" % s)
			return 0.0
		return s.to_float()
	, ["String"], "double")
	var string_cls := define_native_class("String")
	string_cls.add_static_method("valueOf", func(_t, a): return interp._to_str(a[0]), ["Object"], "String")

	# Listas: List (interface) e ArrayList (guarda os itens em um Array do Godot no host)
	define_native_class("List", "", true)
	var al := define_native_class("ArrayList")
	al.interfaces = ["List"]
	al.native_ctor = func(this, _a): this.host = []
	var check := func(list: Array, i: int) -> bool:
		if i < 0 or i >= list.size():
			interp.throw_error("IndexOutOfBoundsException: índice %d fora da lista de tamanho %d" % [i, list.size()])
			return false
		return true
	al.add_method("add", func(t, a):
		t.host.append(a[0])
		return true
	, ["Object"], "boolean")
	al.add_method("add", func(t, a):
		if a[0] < 0 or a[0] > t.host.size():
			interp.throw_error("IndexOutOfBoundsException: índice %d fora da lista de tamanho %d" % [a[0], t.host.size()])
			return null
		t.host.insert(a[0], a[1])
	, ["int", "Object"])
	al.add_method("get", func(t, a): return t.host[a[0]] if check.call(t.host, a[0]) else null, ["int"], "Object")
	al.add_method("set", func(t, a):
		if not check.call(t.host, a[0]):
			return null
		var old = t.host[a[0]]
		t.host[a[0]] = a[1]
		return old
	, ["int", "Object"], "Object")
	al.add_method("remove", func(t, a):
		if not check.call(t.host, a[0]):
			return null
		return t.host.pop_at(a[0])
	, ["int"], "Object")
	al.add_method("remove", func(t, a):
		for i in t.host.size():
			if interp.java_equals(t.host[i], a[0]):
				t.host.remove_at(i)
				return true
		return false
	, ["Object"], "boolean")
	al.add_method("size", func(t, _a): return t.host.size(), [], "int")
	al.add_method("isEmpty", func(t, _a): return t.host.is_empty(), [], "boolean")
	al.add_method("clear", func(t, _a): t.host.clear())
	al.add_method("indexOf", func(t, a):
		for i in t.host.size():
			if interp.java_equals(t.host[i], a[0]):
				return i
		return -1
	, ["Object"], "int")
	al.add_method("contains", func(t, a):
		for item in t.host:
			if interp.java_equals(item, a[0]):
				return true
		return false
	, ["Object"], "boolean")
	al.add_method("toString", func(t, _a):
		var parts := []
		for item in t.host:
			parts.append(interp._to_str(item))
		return "[" + ", ".join(parts) + "]"
	, [], "String")
