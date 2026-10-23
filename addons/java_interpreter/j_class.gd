class_name JClass
extends RefCounted
## Uma classe ou interface carregada no interpretador.
## Pode vir do código do aluno ou ser nativa (definida pelo jogo em GDScript).

var name: String
var super_name := ""            ## nome da superclasse ("" = Object)
var superclass: JClass = null
var interfaces: Array = []      ## nomes das interfaces implementadas (ou estendidas, se for interface)
var is_interface := false
var is_abstract := false
var is_native := false
var line := 0

var fields: Array = []          ## declarações dos campos de instância (na ordem do código)
var field_decls := {}           ## nome -> declaração (instância e static)
var static_values := {}         ## nome -> valor dos campos static
var methods := {}               ## nome -> Array de métodos (sobrecargas)
var ctors: Array = []           ## construtores
var native_ctor := Callable()   ## func(this: JObject, args: Array) para classes nativas


## Registra um método nativo. O Callable recebe (this: JObject, args: Array)
## e devolve o valor de retorno (ou null para void). Em métodos static, this é null.
## param_types usa nomes Java: "int", "double", "boolean", "String", "char",
## nomes de classes, ou "Object" para aceitar qualquer valor.
func add_method(method_name: String, callable: Callable, param_types: Array = [], return_type := "void", is_static := false) -> RefCounted:
	var params := []
	for i in param_types.size():
		params.append({"type": param_types[i], "n": "arg%d" % i})
	var m := {
		"name": method_name, "params": params, "ret": return_type, "static": is_static,
		"abstract": false, "access": "public", "body": null, "line": 0,
		"native": callable, "owner": name, "is_ctor": false,
	}
	if not methods.has(method_name):
		methods[method_name] = []
	methods[method_name].append(m)
	return self


## Registra um método nativo static (ex.: Math.abs).
func add_static_method(method_name: String, callable: Callable, param_types: Array = [], return_type := "void") -> RefCounted:
	return add_method(method_name, callable, param_types, return_type, true)


## Registra um campo. Campos static guardam o valor na própria classe;
## campos de instância recebem `value` como valor inicial em cada objeto.
func add_field(field_name: String, type: String, value = null, is_static := false, is_final := false, access := "public") -> RefCounted:
	var d := {
		"name": field_name, "type": type, "init": null, "value": value, "static": is_static,
		"final": is_final, "access": access, "line": 0, "owner": name,
	}
	field_decls[field_name] = d
	if is_static:
		static_values[field_name] = value
	else:
		fields.append(d)
	return self


func has_java_method(method_name: String) -> bool:
	var c = self
	while c != null:
		if c.methods.has(method_name):
			return true
		c = c.superclass
	return false
