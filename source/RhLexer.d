/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module RhLexer;
import std.ascii: isHexDigit, isWhite, isAlphaNum, isAlpha, isDigit;
import std.conv : text, parse;
import std.string: indexOf;
import std.algorithm: count;

class RhLexer{
	private static const auto tokencount = lx.max + 1;
	private Token[] tokens;
	public char[] codes;
	private char* size;
	static private enum chars = ['n': '\n', 't': '\t', 'r': '\r', 'a': '\a','f': '\f', 'b': '\b', 'v': '\v', '\"': '\"','?': '?', '\\': '\\', '\'': '\''];
	private LexMap[char] lexmap;

	private static enum lx : ushort {
		NOP= 0, NUMBER , WORD, SWORD,STRING, NEWLINE,
		
		PRINT,
		
		// Keywords
		DO, END,

		// COMMANDS
		BREAK, CONTINUE,
		
		// Operators (+,-,*,/,%,|,&,~,^,<<,>>, ||, &&, !, <, <=, >, >=, ==, !=, in)
		PLUS, MINUS, TIMES, DIVIDE, MOD,
		OR, AND, NOT, XOR, LSHIFT, RSHIFT,
		LOR, LAND, LNOT,
		LT, LE, GT, GE, EQ, NE, K_IN,

		// Assignment (=, *=, /=, %=, +=, -=, <<=, >>=, &=, ^=, |=)
		EQUALS, TIMESEQUAL, DIVEQUAL, MODEQUAL, PLUSEQUAL, MINUSEQUAL,
		LSHIFTEQUAL,RSHIFTEQUAL, ANDEQUAL, XOREQUAL, OREQUAL,

		// Increment/decrement (++,--)
		PLUSPLUS, MINUSMINUS,

		// Mapping parameter (->)
		ARROW,

		// Ternary operator (?)
		TERNARY,

		// Delimeters ( ) [ ] { } , . ; :
		LPAREN, RPAREN,
		LBRACKET, RBRACKET,
		LBRACE, RBRACE,
		COMMA, PERIOD, SEMI, COLON,

		// Ellipsis (...)
		ELLIPSIS,

		// COMMENT /* */
		COMMENT,

		RESERVED
	}

	this(){
		with(lx){
		lexmap = [
			'+': LexMap(PLUS, [
				'+': LexMap(PLUSPLUS),
				'=': LexMap(PLUSEQUAL)
			]),
			'-': LexMap(MINUS, [
				'-': LexMap(MINUSMINUS),
				'>': LexMap(ARROW),
				'=': LexMap(MINUSEQUAL)
			]),
			'*': LexMap(TIMES,[
				'=': LexMap(TIMESEQUAL)
			]),
			'/': LexMap(DIVIDE,[
				'=': LexMap(DIVEQUAL),
				'*': LexMap(NOP,"*/"),
				'/': LexMap(NOP,"\n")
			]),
			'%': LexMap(MOD,[
				'=': LexMap(MODEQUAL)
			]),
			'<': LexMap(LT,[
				'=': LexMap(LE),
				'<': LexMap(LSHIFT, [
					'=': LexMap(LSHIFTEQUAL)
				]),
			]),
			'>': LexMap(GT,[
				'=': LexMap(GE),
				'>': LexMap(RSHIFT,[
					'=': LexMap(RSHIFTEQUAL)
				]),
			]),
			'=': LexMap(EQUALS,[
				'=': LexMap(EQ),
			]),
			'!': LexMap(LNOT,[
				'=': LexMap(NE),
			]),
			'|': LexMap(OR,[
				'|': LexMap(LOR),
				'=': LexMap(OREQUAL)
			]),
			'&': LexMap(AND,[
				'&': LexMap(LAND),
				'=': LexMap(ANDEQUAL)
			]),
			'~': LexMap(NOT),
			'^': LexMap(XOR, [
				'=': LexMap(XOREQUAL)
			]),
			'?': LexMap(TERNARY),
			'(': LexMap(LPAREN),
			')': LexMap(RPAREN),
			'[': LexMap(LBRACKET),
			']': LexMap(RBRACKET),
			'{': LexMap(LBRACE),
			'}': LexMap(RBRACE),
			',': LexMap(COMMA),
			'.': LexMap(PERIOD),
			';': LexMap(SEMI),
			':': LexMap(COLON),
		];
		}

	}
	void load(string S){
		tokens = null;
		codes = cast(char[]) S;
		size = codes.ptr + codes.length;
	}
	Token[] lexy(bool html = false){
		auto mustclose = false;
		bool htmlstat;
		auto c = codes.ptr;
		auto cpos(){
			return (c-codes.ptr);
		}
		int im;
		string tmp;
		
		if(html){
			rhstag:
			im = indexOf(codes[cpos()..$], "<|");
			if (im==-1){
				addToken(lx.PRINT, cast(string) codes[cpos()..$]);
				return tokens;
			}else{
				string mx = text(codes[cpos()..cpos()+im]);
				addToken(lx.PRINT, mx);
				c+=im+2;
				mustclose = true;
			}
		}
		
		
		while (c<size) with(lx){
			if (*c=='\r'){
				addToken(NEWLINE,text(*c));
			}else if(*c=='\n'){
				if(c + 1<size && *(c+1)=='\r') {
					addToken(NEWLINE,text("\n\r"));
					c++;
				}else{
					addToken(NEWLINE,text(*c));
				}
			}else if(isWhite(*c)){
			}else if (*c == '\"' || *c == '\''){
				tmp = "";
				int tmpf = 0;
				char wait = *c;
				c++;
			stringStart:
				while (c < size){
					if (*c == wait){
						c++;
						goto stringEnd;
					}
					else if (*c == '\\') {c++; goto stringSlash;}
					else tmp ~= *c;
					c++;
				}
				goto stringError;

			stringSlash:
				if (c < size){
					int ii = 0, iim = 3;
					if (*c == 'u'){
						iim = 4;
						c++;
					}else if (*c == 'x'){
						iim = 2;
						c++;
					}else if (*c == 'U') { iim = 8; c++; }
					else if (*c in chars){
						tmp ~= chars[*c];
						c++;
						goto stringStart;
					}else{
						tmpf = 0;
						c++;
						tmp ~= *c;
						goto stringStart;
					}
					string tmp2 = "";
					while (c < size && ii < iim){
						if (!isHexDigit(*c)) goto stringStart;
						tmp2 ~= *c;
						c++;
						ii++;
					}
					if (ii != iim) throw new Exception(text(iim-ii)~" adet karakter bekleniyordu!");
					if (iim == 3) tmp ~= parse!int(tmp2, 8);
					else tmp ~= parse!int(tmp2, 16);
					goto stringStart;
				}

			stringError:
				throw new Exception("Beklenen karakter: \"");
			stringEnd:
				addToken(STRING, tmp);
				continue;
 			}else if (html && *c == '|' && c+1<size && *(c+1) == '>'){
				mustclose=false;
				c+=2;
				goto rhstag;
    		}else if (isAlpha(*c) || (*c>127 && *c<255) || *c=='_'){
				tmp = "";
				/*				if (c=='r' && c+1<size && (*c=='\'' || *(c+1)=='"' ) ){
				c++;
				StringR();
				return;
				}
				*/
				while (c < size){
					if (isAlphaNum(*c) || (*c>127 && *c<255) || *c=='_'){
						tmp ~= *c;
						c++;
					}else
						break;
				}
				switch(tmp){
					case "in":
						addToken(K_IN, tmp);
						break;
					case "continue":
						addToken(CONTINUE, tmp);
						break;
					case "break":
						addToken(BREAK, tmp);
						break;
					default:
						addToken(WORD, tmp);
						break;
				}
				continue;
			}else if (isDigit(*c)){
				tmp = "";
				if ((c+1 < size) && *(c+1) == 'x'){
					c+=2;
					goto HexD;
				}else if(*c=='-'){
					tmp ~= "-";
					c++;
				}
				bool dot, e;
				while (c < size){
					if (isDigit(*c)){
						tmp ~= *c;
						c++;
					}else if ('.' == *c && !dot && isDigit(*(c+1))){
						dot = true;
						tmp ~= *c;
						c++;
					}else if (*c == 'e' && !e){
						c++;
						e = true;
						tmp ~= *c;
						if(*c=='-'){
							tmp ~= *c;
							c++;
						}
					}
					else break;
				}
				addToken(NUMBER,tmp);
				continue;
			}else{
				tmp = "";
				LexMap* z = *c in lexmap;
				if(z is null){
					throw new Exception("Beklenmeyn karakter:"~*c);
				}else{
				sl:
					if((*z).finish !is null){
						tmp = "";
						c++;
						atla:
						while(c < size){
							foreach(i,l;(*z).finish){
								if(*(c+i) != l) {tmp ~= *c;c++; goto atla;}
							}
							c+=(*z).finish.length-1;
							goto atla2;
						}
						atla2:
						if((*z).name !=NOP)
						addToken((*z).name, tmp);
					}else{
						tmp ~= *c;
						LexMap* b= *(c+1) in (*z).map;
						if(b is null) addToken((*z).name,tmp);
						else{
							z = b;
							c++;
							goto sl;
						}
					}
				}
			}
			c++;
			continue;
		HexD:
			tmp = "";
			while (c < size){
				if (isHexDigit(*c)){
					tmp ~= *c;
					c++;
				}else break;
			}
			try{
				addToken(NUMBER, text(parse!int(tmp, 16)));
			}catch(Throwable x){
				throw new Exception("Hata: " ~x.msg);
			}
			c++;
		}
		if(mustclose)
			throw new Exception("|> kapatılması bekleniyordu!");
		return tokens;
	}
	void addToken(lx type, string val){
		this.tokens ~= Token(type, val);
	}

	static protected struct Token{
		int typ;
		string value;
		void* val;
		void*[] subs;
	}

	static protected struct LexMap{
		lx name;
		LexMap[char] map;
		string finish;
		this(lx name,  LexMap[char] map = null){
			this.name = name;
			this.map = map;
		}
		this(lx name, string finish){
			this.name = name;
			this.finish = finish;
		}
	}
}