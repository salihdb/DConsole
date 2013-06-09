/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module RhParser;

import RhLexer;
import std.conv : to;
import std.stdio;

class RhParser : RhLexer{
private:
	int i;
	ushort[int] opLevels;
	Token delegate (Token) [int] getItFunctions;
public:
	Token[] tokens;
	enum px : int{
		RESERVERD = lx.max,
		CALC, EQUAL_IT, ARRAY, WHILE, LOOP, FOR, FUNCTION, LAYER, CLASS, BOOL, NONE,
		DICT, IF,
		CODEAREA
	}
	this(){
		super();
		with(lx){
			opLevels = [
				TIMES:10, DIVIDE:10, PLUS: 8, MINUS: 8, MOD: 6,
				K_IN: 4,
				EQ: 3, NE: 3, LT: 3, LE: 3, GT: 3, GE: 3,
				LAND: 2, LOR: 2,
			];
//			this.getItFunctions = [];
		}
	}
	Token p_bool(){
		void* z = cast(void*) (tokens[i].value=="true" ? true : false);
		i++;
		return Token(px.BOOL, "",  z);
	}
	Token p_none(){
		i++;
		return Token(px.NONE);
	}

	struct RhIfS{
		Token cond;
		Token[] codes;
	}

	Token g_or(Token token){
		i++;
		if(!(i<tokens.length))
			throw new Exception("| den sonra WORD bekleniyordu!");
		else if(tokens[i].typ!=lx.WORD)
			throw new Exception("| den sonra WORD bekleniyordu!");
		else{
			token = tokens[i];
			token.typ=lx.SWORD;
			i++;
		}
		if(!(i<tokens.length))
			throw new Exception("| bekleniyordu!");
		else if(tokens[i].typ!=lx.OR)
			throw new Exception("| bekleniyordu!");
		i++;
		return token;
	}

	string toString(Token tok, bool gv=false){
		if(tok.value is null){
			return tok.value;
		}else{
			with(lx){
			auto calc = (*cast(calc*) tok.value);
			string result;
			if(gv || calc.op!=PLUS && calc.op!=MINUS) result~="("~text(toString(calc.t1, calc.op!=PLUS && calc.op!=MINUS)) ~ text(calc.op) ~ text(toString(calc.t2, calc.op!=PLUS && calc.op!=MINUS)) ~ ")";
			else result~=text(toString(calc.t1, calc.op!=PLUS && calc.op!=MINUS)) ~ text(calc.op) ~ text(toString(calc.t2, calc.op!=PLUS && calc.op!=MINUS)); 
			return result;
			}
		}
	}
	Token[] execParser(){
		Token[] result;
		for(i=0;i<tokens.length;){
			result ~= calcIt(getIt(tokens[i]));
		}
		return result;
	}

	float HLProcess(Token input){
		if(input.typ!=lx.NUMBER && input.typ!=px.CALC)
			return 0;
			
		if(input.val is null){
			return to!float(input.value);
		}else{
			with(lx){
			auto calc = cast(calc*) input.val;
			float result;
			switch(calc.op){
				case PLUS: result = HLProcess(calc.t1) + HLProcess(calc.t2); break;
				case LAND:
					auto t1 = HLProcess(calc.t1);
					result = t1 == 0 ? 0 : HLProcess(calc.t2); break;
				case DIVIDE: result = HLProcess(calc.t1) / HLProcess(calc.t2); break;
				case TIMES: result = HLProcess(calc.t1) * HLProcess(calc.t2); break;
				case MINUS: result = HLProcess(calc.t1) - HLProcess(calc.t2); break;
				default:
					
			}
			return result;
			}
		}
	}
	calc[] calcd;
/*
	HumanLook Algorithm
	Talha Zekeriya Durmuş

	//Speed Test 1
	Test: 2 * 4 / 2 * 4  + 10 * 2
	Computer: Intel i7 2630QM, 8 gb ddr3 ram, Windows 8 PRO
	Date: 15.02.2013 12:56 - 19.02.2013
	100.000 tane Parse + Executue 2.2 saniye
	100.000 tane Parse 1.5 saniye
	100.000 tane Execute 0.3 saniye

*/
	Token calcItS(Token t2){
		with(lx){
			if(t2.typ==LPAREN){
				i++;
				t2 = tokens[i];
				if(t2.typ == LPAREN){
					t2 = calcItS(t2);
				}else{
					t2 = getIt(t2);
					switch(t2.typ){
						case STRING,NUMBER, px.CALC, WORD, px.BOOL: break;
						default: throw new Exception(text(t2.typ)~" beklenmiyordu");
					}
				}
				bool wRParen = true;
				t2 = calcIt(t2, 0, &wRParen);
				if(wRParen) throw new Exception("Parantezi kapatmanız bekleniyordu");
				return t2;
			}else{
				t2 = getIt(t2);
				switch(t2.typ){
					case STRING,WORD,NUMBER, px.CALC, px.BOOL: break;
					default: throw new Exception(text(t2.typ)~" beklenmiyordu");
				}
				return t2;
			}
		}
	}
	Token calcIt(Token t1, int pOpLevel = 0, bool* wRParen = null){
		with(lx){
			if(t1.typ==LPAREN && i<tokens.length){
				i--;
				t1 = calcItS(t1);
			}else if(t1.typ==NEWLINE){
				throw new Exception("Yeni satır beklenmiyordu!");
			}
			int operator;
			int cOpLevel;
		strp:
			if(i<tokens.length){
				Token token = tokens[i];
				if(wRParen !is null && token.typ == RPAREN){
					i++;
					*wRParen=false;
					return t1;
				}else{
					auto z = token.typ in opLevels;
					if(z){
						cOpLevel = *z;
						operator = token.typ;
					}else return t1;
				}
			}else{
				return t1;
			}
			if(cOpLevel > pOpLevel){
				while(1){
					i++;
					if(!(i < tokens.length)) throw new Exception("Bir ifade bekleniyordu!");
					Token t2 = calcItS(tokens[i]);
					void* zz;
					if(wRParen is null){
						zz = new calc(operator, t1, calcIt(t2, cOpLevel, null));
						t1 = Token(px.CALC, "", zz);
					}else{
						auto wRParen2 = *wRParen;
						zz = new calc(operator, t1, calcIt(t2, cOpLevel, &wRParen2));
						t1 = Token(px.CALC, "", zz);
						if(*wRParen!=wRParen2){
							*wRParen=wRParen2;
							return t1;
						}
					}
					if(i<tokens.length){
						Token token = tokens[i];
						auto z = token.typ in opLevels;
						if(z){
							if(*z < cOpLevel) goto strp;
							else goto strp;
						}else return t1;
					}else{
						return t1;
					}
				}
			}else{
				return t1;
			}
		}
		assert(0);
	}

	Token getIt(Token token){
		if(token.typ in getItFunctions) return getItFunctions[token.typ](token);
		i++;
		return token;
	}
	struct calc{
		int op;
		Token t1, t2;
	}
}