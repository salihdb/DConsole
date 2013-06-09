import std.stdio;
import std.parallelism;
import std.range;
import RhParser;
RhParser parser;
void main() {
	parser = new RhParser();
	string buf;
	write("=: ");
	while (stdin.readln(buf)){
		string ret = execute(buf[0..$-1]);
		if(ret!="") writeln(ret);
		write("=: ");
	}
}

string execute(string code){
	try{
		parser.load(code);
		parser.tokens = parser.lexy();
		auto parsed = parser.execParser();
		if(parsed.length>0){
			return to!string(parser.HLProcess(parsed[0]));
		}
	}catch(Throwable msg){
		return "Hata oluştu: " ~ msg.msg;
	}
	return "";
}