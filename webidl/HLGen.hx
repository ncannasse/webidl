package webidl;
import webidl.Data;

typedef GenerationOpts = {
	@:optional var libName : String;
	@:optional var outputFile : String;
	@:optional var includeCode : String;
}

class HLGen {

	static var HEADER = "

template <typename T> struct pref {
	void *finalize;
	T *value;
};

template<typename T> pref<T> *alloc_ref( T *value, void (*finalize)( pref<T> * ) ) {
	pref<T> *r = (pref<T>*)hl_gc_alloc_finalizer(sizeof(r));
	r->finalize = finalize;
	r->value = value;
	return r;
}

";

	public static function generate( file : String, ?opts : GenerationOpts ) {
		if( opts == null ) opts = {};
		var content = sys.io.File.getBytes(file);
		var parse = new webidl.Parser();
		var decls = null;
		try {
			decls = parse.parseFile(new haxe.io.BytesInput(content));
		} catch( msg : String ) {
			throw msg + "(" + file+" line " + parse.line+")";
		}
		if( opts.outputFile == null ) {
			var parts = file.split(".");
			parts.pop();
			parts.push("cpp");
			opts.outputFile = parts.join(".");
		}
		var output = new StringBuf();
		function add(str:String) {
			output.add(str.split("\r\n").join("\n") + "\n");
		}
		if( opts.libName != null )
			add('#define HL_NAME(x) ${opts.libName}_##x');
		add('#include <hl.h>');
		if( opts.includeCode != null )
			add(opts.includeCode);
		add(StringTools.trim(HEADER));
		add("");
		var typeNames = new Map();
		for( d in decls ) {
			switch( d ) {
			case DInterface(name, attrs, _):
				var prefix = "";
				var suffix = "*";
				for( a in attrs )
					switch( a ) {
					case APrefix(name): prefix = name;
					default:
					}
				typeNames.set(name, prefix + name + suffix);
			case DEnum(name, _):
				typeNames.set(name, name);
			case DImplements(_):
			}
		}

		function makeType( t : webidl.Data.Type ) {
			return switch( t ) {
			case TFloat: "float";
			case TDouble: "double";
			case TShort: "short";
			case TInt: "int";
			case TVoid: "void";
			case TAny, TVoidPtr: "void*";
			case TArray(t): makeType(t) + "[]";
			case TBool: "bool";
			case TLong: "long";
			case TCustom(id): typeNames.get(id);
			}
		}

		function makeTypeDecl( td : TypeAttr ) {
			var prefix = "";
			for( a in td.attr ) {
				switch( a ) {
				case AConst: prefix += "const ";
				default:
				}
			}
			return prefix + makeType(td.t);
		}

		for( d in decls ) {
			switch( d ) {
			case DInterface(name, attrs, fields):

				var ignore = false;
				for( a in attrs )
					switch( a ) {
					case AJSImplementation(_): ignore = true;
					default:
					}
				if( ignore ) continue;

				for( f in fields ) {
					switch( f.kind ) {
					case FMethod(margs, ret):

						var suffix = f.name == name ? "_" + margs.length : "";
						var args = f.name == name ? margs : [{ name : "_this", t : { t : TCustom(name), attr : [] }, opt : false }].concat(margs);
						var tret = f.name == name ? { t : TCustom(name), attr : [] } : ret;
						output.add('HL_PRIM ${makeTypeDecl(tret)} HL_NAME(${name}_${f.name}$suffix)(');
						var first = true;
						for( a in args ) {
							if( first ) first = false else output.add(", ");
							switch( a.t.t ) {
							case TArray(t):
								output.add(makeType(t)+"*");
							default:
								output.add(makeType(a.t.t));
							}
							if( a.opt && !a.t.t.match(TCustom(_)) ) output.add("*");
							output.add(" " + a.name);
						}
						add(') {');


						function addCall(margs : Array<{ name : String, opt : Bool, t : TypeAttr }> ) {
							var isRefRet = false;
							if( f.name == name ) {
								output.add("return new " + typeNames.get(name).substr(0,-1) + "(");
							} else {
								if( tret.t != TVoid ) output.add("return ");
								for( a in ret.attr ) {
									switch( a ) {
									case ARef, AValue:
										output.add("new " + makeType(tret.t).substr(0, -1) + "(");
										isRefRet = true;
									default:
									}
								}
								switch( f.name ) {
								case "op_mul":
									output.add("*_this * (");
								case "op_add":
									output.add("*_this + (");
								case "op_sub":
									output.add("*_this - (");
								case "op_div":
									output.add("*_this / (");
								case "op_mulq":
									output.add("*_this *= (");
								default:
									output.add("_this->" + f.name+"(");
								}
							}

							var first = true;
							for( a in margs ) {
								if( first ) first = false else output.add(", ");
								if( a.opt && !a.t.t.match(TCustom(_)) ) output.add("*");
								for( a in a.t.attr ) {
									switch( a ) {
									case ARef: output.add("*"); // unref
									default:
									}
								}
								output.add(a.name);
							}

							if( isRefRet ) output.add(")");
							add(");");
						}

						var hasOpt = false;
						for( i in 0...margs.length )
							if( margs[i].opt ) {
								hasOpt = true;
								break;
							}
						if( hasOpt ) {

							for( i in 0...margs.length )
								if( margs[i].opt ) {
									add("\tif( !" + margs[i].name+" )");
									output.add("\t\t");
									addCall(margs.slice(0, i));
									add("\telse");
								}
							output.add("\t\t");
							addCall(margs);

						} else {
							output.add("\t");
							addCall(margs);
						}
						add('}');
						add("");
					case FAttribute(_):
						//trace("TODO");
					}
				}

			case DEnum(_), DImplements(_):
			}
		}
		sys.io.File.saveContent(opts.outputFile, output.toString());
	}

	public static function main() {
		var args = Sys.args();
		var file = args[0];
		if( args == null ) {
			Sys.println("Usage: hlgen <file>");
			Sys.exit(1);
		}
		generate(file);
	}

}