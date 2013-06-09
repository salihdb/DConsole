import std.stdio;
import std.parallelism;
import std.range;
import RhLexer;
void main() {
	auto lexer = new RhLexer();
	string buf;
	write("=: ");
	while (stdin.readln(buf)){
		lexer.load(buf[0..$-1]);
		auto tokens = lexer.lexy();
		writeln(tokens);
		write("=: ");
	}
}