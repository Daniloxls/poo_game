extends SceneTree
## Testes automáticos do interpretador.
## Rode com:  godot --headless --path . --script res://tests/run_tests.gd

var passed := 0
var failed := 0


func _init() -> void:
	_run_all()
	print("\n%d testes passaram, %d falharam" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Executa Main.main() e compara a saída impressa.
func expect_output(title: String, src: String, expected: String) -> void:
	var j := JavaInterpreter.new()
	var ok := j.load_source(src)
	if ok:
		j.run_main("Main")
	var got := j.output_log
	if j.has_error():
		got += "<<" + j.get_error_text() + ">>"
	_report(title, got.strip_edges() == expected.strip_edges(), expected, got)
	j.dispose()


## Espera um erro cuja mensagem contém `fragment`.
func expect_error(title: String, src: String, fragment: String, line := -1) -> void:
	var j := JavaInterpreter.new()
	if j.load_source(src):
		j.run_main("Main")
	var ok := j.has_error() and j.get_error_text().contains(fragment)
	if ok and line >= 0:
		ok = j.last_error.line == line
	_report(title, ok, fragment + (" (linha %d)" % line if line >= 0 else ""), j.get_error_text() + " | saída: " + j.output_log)
	j.dispose()


func _report(title: String, ok: bool, expected: String, got: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", title)
	else:
		failed += 1
		print("  FALHOU ", title, "\n     esperado: ", expected.c_escape(), "\n     obtido:   ", got.c_escape())


func _run_all() -> void:
	print("== básico ==")
	expect_output("variáveis e aritmética", """
class Main {
	public static void main(String[] args) {
		int a = 7;
		int b = 2;
		double d = a / 2;
		System.out.println(a + b);
		System.out.println(a / b);
		System.out.println(a % b);
		System.out.println(a / 2.0);
		System.out.println(d);
		System.out.println("a=" + a + b);
		System.out.println(a + b + "=soma");
		long grande = 3000000000L;
		System.out.println(grande);
		int estouro = 2147483647;
		estouro++;
		System.out.println(estouro);
	}
}""", "9\n3\n1\n3.5\n3.0\na=72\n9=soma\n3000000000\n-2147483648")

	expect_output("char e String", """
class Main {
	public static void main(String[] args) {
		char c = 'a';
		System.out.println(c);
		System.out.println(c + 1);
		c++;
		System.out.println("" + c);
		String s = "Olá Mundo";
		System.out.println(s.length());
		System.out.println(s.toUpperCase());
		System.out.println(s.charAt(0) == 'O');
		System.out.println(s.substring(4));
		System.out.println(s.indexOf("Mundo"));
		System.out.println(s.equals("Olá Mundo"));
		System.out.println((int) 'A');
		System.out.println((char) 66);
	}
}""", "a\n98\nb\n9\nOLÁ MUNDO\ntrue\nMundo\n4\ntrue\n65\nB")

	expect_output("if / while / for / do-while / break / continue", """
class Main {
	public static void main(String[] args) {
		int soma = 0;
		for (int i = 1; i <= 10; i++) {
			if (i % 2 == 0) continue;
			soma += i;
		}
		System.out.println(soma);
		int n = 0;
		while (true) {
			n++;
			if (n >= 5) break;
		}
		System.out.println(n);
		int k = 10;
		do { k--; } while (k > 7);
		System.out.println(k);
		String r = n > 3 ? "grande" : "pequeno";
		System.out.println(r);
		if (n == 1) System.out.println("um");
		else if (n == 5) System.out.println("cinco");
		else System.out.println("outro");
	}
}""", "25\n5\n7\ngrande\ncinco")

	expect_output("arrays", """
class Main {
	public static void main(String[] args) {
		int[] v = new int[3];
		v[0] = 10; v[1] = 20; v[2] = v[0] + v[1];
		System.out.println(v[2] + " " + v.length);
		int[] w = {5, 3, 8};
		int maior = w[0];
		for (int x : w) { if (x > maior) maior = x; }
		System.out.println(maior);
		int[][] m = new int[2][3];
		m[1][2] = 7;
		System.out.println(m[1][2] + m[0][0]);
		String[] nomes = {"Ana", "Bia"};
		for (String nome : nomes) System.out.print(nome + ";");
		System.out.println();
		double[] ds = new double[2];
		ds[0] += 1.5;
		System.out.println(ds[0]);
	}
}""", "30 3\n8\n7\nAna;Bia;\n1.5")

	expect_output("métodos static, recursão e sobrecarga", """
class Main {
	static int fat(int n) {
		if (n <= 1) return 1;
		return n * fat(n - 1);
	}
	static String descreve(int x) { return "int " + x; }
	static String descreve(double x) { return "double " + x; }
	static String descreve(String x) { return "texto " + x; }
	public static void main(String[] args) {
		System.out.println(fat(5));
		System.out.println(descreve(3));
		System.out.println(descreve(3.5));
		System.out.println(descreve("oi"));
		System.out.println(Math.max(3, 9) + " " + Math.abs(-2.5) + " " + Math.sqrt(16));
		System.out.println(Integer.parseInt("42") + 1);
	}
}""", "120\nint 3\ndouble 3.5\ntexto oi\n9 2.5 4.0\n43")

	print("== orientação a objetos ==")
	expect_output("classe, campos, construtor, this, getters", """
class Conta {
	private String dono;
	private double saldo;
	private static int total = 0;

	public Conta(String dono) {
		this(dono, 0);
	}
	public Conta(String dono, double saldoInicial) {
		this.dono = dono;
		saldo = saldoInicial;
		total++;
	}
	public void depositar(double valor) {
		if (valor > 0) saldo += valor;
	}
	public double getSaldo() { return saldo; }
	public String getDono() { return dono; }
	public static int getTotal() { return total; }
	public String toString() { return dono + ": " + saldo; }
}
class Main {
	public static void main(String[] args) {
		Conta a = new Conta("Ana");
		Conta b = new Conta("Bia", 100);
		a.depositar(50);
		a.depositar(-10);
		System.out.println(a.getSaldo());
		System.out.println(b);
		System.out.println(Conta.getTotal());
		Conta c = a;
		c.depositar(1);
		System.out.println(a.getSaldo());
		System.out.println(a == c);
		System.out.println(a == b);
	}
}""", "50.0\nBia: 100.0\n2\n51.0\ntrue\nfalse")

	expect_output("herança, super, sobrescrita e polimorfismo", """
abstract class Animal {
	protected String nome;
	public Animal(String nome) { this.nome = nome; }
	public abstract String som();
	public String falar() { return nome + " faz " + som(); }
}
class Cachorro extends Animal {
	public Cachorro(String nome) { super(nome); }
	@Override
	public String som() { return "au"; }
}
class Filhote extends Cachorro {
	public Filhote() { super("Rex Jr"); }
	public String som() { return super.som() + "zinho"; }
}
class Gato extends Animal {
	public Gato() { super("Mimi"); }
	public String som() { return "miau"; }
	public String falar() { return "O gato diz: " + super.falar(); }
}
class Main {
	public static void main(String[] args) {
		Animal[] bichos = { new Cachorro("Rex"), new Filhote(), new Gato() };
		for (Animal a : bichos) System.out.println(a.falar());
		Animal x = bichos[1];
		System.out.println(x instanceof Cachorro);
		System.out.println(x instanceof Gato);
		Cachorro c = (Cachorro) x;
		System.out.println(c.som());
	}
}""", "Rex faz au\nRex Jr faz auzinho\nO gato diz: Mimi faz miau\ntrue\nfalse\nauzinho")

	expect_output("interfaces", """
interface Forma {
	double area();
	String NOME = "forma";
}
interface Desenhavel { String desenhar(); }
class Quadrado implements Forma, Desenhavel {
	private double lado;
	Quadrado(double lado) { this.lado = lado; }
	public double area() { return lado * lado; }
	public String desenhar() { return "[]"; }
}
class Main {
	static double somaAreas(Forma[] formas) {
		double s = 0;
		for (Forma f : formas) s += f.area();
		return s;
	}
	public static void main(String[] args) {
		Forma[] fs = { new Quadrado(2), new Quadrado(3) };
		System.out.println(somaAreas(fs));
		Desenhavel d = new Quadrado(1);
		System.out.println(d.desenhar() + " " + Forma.NOME + " " + (d instanceof Forma));
	}
}""", "13.0\n[] forma true")

	expect_output("ordem de inicialização e campos com valor inicial", """
class Base {
	protected int x = 1;
	Base() { System.out.println("Base x=" + x); x = 2; }
}
class Filha extends Base {
	int y = 10;
	Filha() { System.out.println("Filha x=" + x + " y=" + y); }
}
class Main {
	public static void main(String[] args) { new Filha(); }
}""", "Base x=1\nFilha x=2 y=10")

	expect_output("ArrayList e objetos se referenciando", """
import java.util.ArrayList;
import java.util.List;
class No {
	int valor;
	No proximo;
	No(int v) { valor = v; }
}
class Main {
	public static void main(String[] args) {
		List<String> l = new ArrayList<>();
		l.add("a"); l.add("b"); l.add(0, "z");
		System.out.println(l + " " + l.size() + " " + l.get(1) + " " + l.contains("b"));
		l.remove("a");
		for (String s : l) System.out.print(s);
		System.out.println();
		ArrayList<Integer> nums = new ArrayList<>();
		for (int i = 0; i < 5; i++) nums.add(i * i);
		int t = 0;
		for (int n : nums) t += n;
		System.out.println(t);
		No a = new No(1); a.proximo = new No(2); a.proximo.proximo = new No(3);
		int s = 0;
		for (No n = a; n != null; n = n.proximo) s += n.valor;
		System.out.println(s);
	}
}""", "[z, a, b] 3 a true\nzb\n30\n6")

	expect_output("equals personalizado", """
class Ponto {
	int x; int y;
	Ponto(int x, int y) { this.x = x; this.y = y; }
	public boolean equals(Object o) {
		if (!(o instanceof Ponto)) return false;
		Ponto p = (Ponto) o;
		return p.x == x && p.y == y;
	}
}
class Main {
	public static void main(String[] args) {
		java.util.ArrayList<Ponto> ps = new java.util.ArrayList<>();
		ps.add(new Ponto(1, 2));
		System.out.println(ps.contains(new Ponto(1, 2)) + " " + new Ponto(0,0).equals(new Ponto(0,1)));
	}
}""", "true false")

	print("== erros de compilação ==")
	expect_error("falta ponto e vírgula", "class Main {\n void f() {\n  int x = 1\n  x++;\n }\n}", "Faltou ';' no fim da linha 3", 3)
	expect_error("chave não fechada", "class Main {\n void f() {\n }\n", "Faltou '}'")
	expect_error("tipo inexistente", "class Main {\n void f() {\n  Prota p = null;\n }\n}", "O tipo 'Prota' não existe", 3)
	expect_error("superclasse inexistente", "class A extends B {}", "herda de 'B', que não existe")
	expect_error("não implementa interface", "interface I { void f(); }\nclass A implements I {}", "precisa implementar o método void f()")
	expect_error("método abstrato não implementado", "abstract class F { abstract int g(int x); }\nclass A extends F {}", "precisa implementar o método int g(int)")
	expect_error("comando inválido", "class Main { void f() { int x = 0; x + 1; } }", "não é um comando válido")
	expect_error("construtor com nome errado", "class Porta {\n public Port() {}\n}", "precisa ter o mesmo nome da classe", 2)
	expect_error("método duplicado", "class A { void f(int a) {} void f(int b) {} }", "declarado duas vezes")
	expect_error("extends em interface", "interface I {}\nclass A extends I {}", "use 'implements I'")
	expect_error("switch não suportado", "class Main { void f() { switch (1) {} } }", "switch ainda não é suportado")
	expect_error("palavra reservada como nome", "class Main { void f() { int class = 1; } }", "palavra reservada")
	expect_error("string sem fechar", "class Main { String s = \"abc; }", "não foi fechado")

	print("== erros de execução ==")
	expect_error("loop infinito", "class Main { public static void main(String[] a) { while (true) { } } }", "loop infinito")
	expect_error("loop infinito vazio", "class Main { public static void main(String[] a) { int i = 0; for (;;); } }", "loop infinito")
	expect_error("recursão infinita", "class Main { static int f(int n) { return f(n + 1); } public static void main(String[] a) { f(0); } }", "StackOverflowError")
	expect_error("divisão por zero", "class Main {\n public static void main(String[] a) {\n  int z = 0;\n  int r = 10 / z;\n }\n}", "divisão por zero", 4)
	expect_error("índice fora do array", "class Main { public static void main(String[] a) { int[] v = new int[3]; v[3] = 1; } }", "ArrayIndexOutOfBoundsException")
	expect_error("null pointer", "class P { int x; }\nclass Main {\n public static void main(String[] a) {\n  P p = null;\n  System.out.println(p.x);\n }\n}", "NullPointerException", 5)
	expect_error("double em int", "class Main { public static void main(String[] a) { int x = 2.5; } }", "Use um cast")
	expect_error("String em int", "class Main { public static void main(String[] a) { int x = \"5\"; } }", "esperado int mas recebeu String")
	expect_error("condição não boolean", "class Main { public static void main(String[] a) { int x = 1; if (x = 2) {} } }", "use == em vez de =")
	expect_error("campo private", "class C { private int segredo = 1; }\nclass Main { public static void main(String[] a) { C c = new C(); c.segredo = 2; } }", "é private em C")
	expect_error("método private", "class C { private void f() {} }\nclass Main { public static void main(String[] a) { new C().f(); } }", "é private em C")
	expect_error("instanciar abstrata", "abstract class A {}\nclass Main { public static void main(String[] a) { A x = new A(); } }", "abstrata")
	expect_error("variável não declarada", "class Main { public static void main(String[] a) { y = 3; } }", "'y' não existe")
	expect_error("variável sem valor", "class Main { public static void main(String[] a) { int y; y++; } }", "ainda não recebeu um valor")
	expect_error("falta return", "class Main { static int f(int x) { if (x > 0) return 1; } public static void main(String[] a) { f(-1); } }", "faltou um return")
	expect_error("método inexistente", "class C {}\nclass Main { public static void main(String[] a) { new C().voar(); } }", "não tem o método 'voar'")
	expect_error("argumentos errados", "class C { void f(int x) {} }\nclass Main { public static void main(String[] a) { new C().f(\"oi\"); } }", "não aceita (String)")
	expect_error("ClassCastException", "class A {} class B extends A {} class D extends A {}\nclass Main { public static void main(String[] a) { A x = new B(); D d = (D) x; } }", "ClassCastException")
	expect_error("tipo errado no polimorfismo", "class A {} class B {}\nclass Main { public static void main(String[] a) { A x = new B(); } }", "esperado A mas recebeu B")
	expect_error("final", "class Main { static final int MAX = 3; public static void main(String[] a) { MAX = 4; } }", "final")
	expect_error("this em static", "class Main { int x; public static void main(String[] a) { x = 1; } }", "método static")

	print("== integração com o jogo ==")
	_test_game_api()


func _test_game_api() -> void:
	var j := JavaInterpreter.new()
	# simula um nó do jogo
	var porta_node := FakeDoor.new()
	var base := j.define_native_class("ObjetoDoJogo")
	base.add_method("dizer", func(this, args): this.host.falas.append(args[0]), ["String"])
	j.bind_host_method(base, "abrirPorta", "abrir")
	j.bind_host_method(base, "getPosicaoX", "get_x", [], "int")

	var ok := j.load_source("""
public class Porta extends ObjetoDoJogo {
	private String senha;
	private int tentativas = 0;
	public Porta(String senha) { this.senha = senha; }
	public boolean tentarAbrir(String chute) {
		tentativas++;
		if (chute.equals(senha)) {
			abrirPorta();
			dizer("Abriu na tentativa " + tentativas + " em x=" + getPosicaoX());
			return true;
		}
		dizer("Senha errada");
		return false;
	}
}""")
	_report("carrega classe que herda de classe nativa", ok, "true", j.get_error_text())
	var porta := j.create_object("Porta", ["1234"], porta_node)
	var r1 = j.call_method(porta, "tentarAbrir", ["0000"])
	var r2 = j.call_method(porta, "tentarAbrir", ["1234"])
	_report("métodos nativos e retorno para o jogo", r1 == false and r2 == true and porta_node.aberta,
		"false, true, aberta", "%s, %s, %s %s" % [r1, r2, porta_node.aberta, j.get_error_text()])
	_report("falas do objeto", porta_node.falas == ["Senha errada", "Abriu na tentativa 2 em x=7"],
		"[Senha errada, Abriu na tentativa 2 em x=7]", str(porta_node.falas))
	_report("ler campo do objeto", j.get_field(porta, "tentativas") == 2, "2", str(j.get_field(porta, "tentativas")))

	# variável global exposta
	var robo_cls := j.define_native_class("Robo")
	var log := []
	robo_cls.add_method("andar", func(_this, args): log.append("andar %d" % args[0]), ["int"])
	robo_cls.add_method("virar", func(_this, _args): log.append("virar"))
	var robo := JObject.new()
	robo.cls = robo_cls
	j.expose("robo", robo, "Robo")
	ok = j.load_source("""
class Solucao {
	public static void resolver() {
		for (int i = 0; i < 4; i++) { robo.andar(2); robo.virar(); }
	}
}""")
	j.call_static("Solucao", "resolver")
	_report("objeto global exposto (robo)", ok and log.size() == 8 and log[0] == "andar 2", "8 ações", str(log) + j.get_error_text())

	# erro lançado pelo jogo
	robo_cls.add_method("pular", func(_this, _args): j.throw_error("O robô não sabe pular!"))
	j.load_source("class S2 { static void f() { robo.pular(); robo.andar(1); } }")
	log.clear()
	j.call_static("S2", "f")
	_report("throw_error dentro de método nativo", j.get_error_text().contains("não sabe pular") and log.is_empty(), "erro", j.get_error_text())

	# recarregar código com erro não estraga a versão anterior
	var ok2 := j.load_source("public class Porta extends ObjetoDoJogo { void quebrado( { } }")
	_report("código com erro não substitui a classe antiga", not ok2 and j.classes.has("Porta") and j.classes.Porta.methods.has("tentarAbrir"), "classe antiga mantida", j.get_error_text())

	# limite de passos de uma chamada do jogo
	j.load_source("class Loop { static void f() { int i = 0; while (i >= 0) { i = 1; } } }")
	j.max_steps = 5000
	j.call_static("Loop", "f")
	_report("limite de passos em chamada do jogo", j.get_error_text().contains("loop infinito"), "loop infinito", j.get_error_text())
	j.dispose()


class FakeDoor:
	extends RefCounted
	var aberta := false
	var falas := []
	func abrir() -> void:
		aberta = true
	func get_x() -> int:
		return 7
