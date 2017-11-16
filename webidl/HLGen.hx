package webidl;
import webidl.Data;

typedef GenerationOpts = {
	var idl : String;
	var libName : String;
	@:optional var outputFile : String;
	@:optional var includeCode : String;
	@:optional var autoGC : Bool;
}

class HLGen {

	static var HEADER_NO_GC = "

#define alloc_ref(r, _) r
#define alloc_ref_const(r,_) r
#define _ref(t)			t
#define _unref(v)		v

	";

	static var HEADER_GC = "

template <typename T> struct pref {
	void *finalize;
	T *value;
};

#define _ref(t) pref<t>
#define _unref(v) v->value
#define alloc_ref_const(r, _) _alloc_const(r)
#define free_ref(v) delete _unref(v)

template<typename T> pref<T> *alloc_ref( T *value, void (*finalize)( pref<T> * ) ) {
	pref<T> *r = (pref<T>*)hl_gc_alloc_finalizer(sizeof(r));
	r->finalize = finalize;
	r->value = value;
	return r;
}

template<typename T> pref<T> *_alloc_const( const T *value ) {
	pref<T> *r = (pref<T>*)hl_gc_alloc_noptr(sizeof(r));
	r->finalize = NULL;
	r->value = (T*)value;
	return r;
}

";

	public static function generate( opts : GenerationOpts ) {
		var file = opts.idl;
		var content = sys.io.File.getBytes(file);
		var parse = new webidl.Parser();
		var decls = null;
		var gc = opts.autoGC;
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
		add('#define HL_NAME(x) ${opts.libName}_##x');
		add('#include <hl.h>');
		add('#define _IDL _BYTES');
		add(StringTools.trim(gc ? HEADER_GC : HEADER_NO_GC));
		if( opts.includeCode != null ) {
			add("");
			add(StringTools.trim(opts.includeCode));
		}
		add("");
		var typeNames = new Map();
		var enumNames = new Map();

		// ignore "JSImplementation" interfaces (?)
		for( d in decls.copy() )
			switch( d ) {
			case DInterface(_, attrs, _):
				for( a in attrs )
					switch( a ) {
					case AJSImplementation(_):
						decls.remove(d);
						break;
					default:
					}
			default:
			}

		for( d in decls ) {
			switch( d ) {
			case DInterface(name, attrs, _):
				var prefix = "";
				for( a in attrs )
					switch( a ) {
					case APrefix(name): prefix = name;
					default:
					}
				var fullName = "_ref(" + prefix + name+")*";
				typeNames.set(name, { full : fullName, constructor : prefix + name });
				if( attrs.indexOf(ANoDelete) >= 0 )
					continue;
				if( gc ) {
					add('static void finalize_$name( $fullName _this ) { free_ref(_this); }');
				} else {
					add('HL_PRIM void HL_NAME(${name}_delete)( $fullName _this ) {\n\tdelete _this;\n}');
					add('DEFINE_PRIM(_VOID, ${name}_delete, _IDL);');
				}
			case DEnum(name, values):
				enumNames.set(name, true);
				typeNames.set(name, { full : "int", constructor : null });
				add('static $name ${name}__values[] = { ${values.join(",")} };');
			case DImplements(_):
			}
		}

		function getEnumName( t : webidl.Data.Type ) {
			return switch( t ) {
			case TCustom(id): enumNames.exists(id) ? id : null;
			default: null;
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
			case TCustom(id): typeNames.get(id).full;
			}
		}

		function defType( t ) {
			return switch( t ) {
			case TFloat: "_F32";
			case TDouble: "_F64";
			case TShort: "_I16";
			case TInt: "_I32";
			case TVoid: "_VOID";
			case TAny, TVoidPtr: "_BYTES";
			case TArray(t): "_BYTES";
			case TBool: "_BOOL";
			case TCustom(name): enumNames.exists(name) ? "_I32" : "_IDL";
			}
		}

		function dynamicAccess(t) {
			return "->v."+switch( t ) {
			case TFloat: "f";
			case TDouble: "d";
			case TShort: "ui16";
			case TInt: "i";
			case TBool: "b";
			default: throw "assert";
			}
		}

		function makeTypeDecl( td : TypeAttr ) {
			var prefix = "";
			for( a in td.attr ) {
				switch( a ) {
				case AConst: if( !gc ) prefix += "const ";
				default:
				}
			}
			return prefix + makeType(td.t);
		}

		function isDyn( arg : { opt : Bool, t : TypeAttr } ) {
			return arg.opt && !arg.t.t.match(TCustom(_));
		}

		for( d in decls ) {
			switch( d ) {
			case DInterface(name, attrs, fields):
				for( f in fields ) {
					switch( f.kind ) {
					case FMethod(margs, ret):
						var isConstr = f.name == name;
						var args = isConstr ? margs : [{ name : "_this", t : { t : TCustom(name), attr : [] }, opt : false }].concat(margs);
						var tret = isConstr ? { t : TCustom(name), attr : [] } : ret;
						var funName = isConstr ? name + "_new" + args.length : name + "_" + f.name;
						output.add('HL_PRIM ${makeTypeDecl(tret)} HL_NAME($funName)(');
						var first = true;
						for( a in args ) {
							if( first ) first = false else output.add(", ");
							switch( a.t.t ) {
							case TArray(t):
								output.add(makeType(t) + "*");
							default:
								if( isDyn(a) )
									output.add("vdynamic*");
								else
									output.add(makeType(a.t.t));
							}
							output.add(" " + a.name);
						}
						add(') {');


						function addCall(margs : Array<{ name : String, opt : Bool, t : TypeAttr }> ) {
							var refRet = null;
							var enumName = getEnumName(tret.t);
							if( isConstr ) {
								refRet = name;
								output.add('return alloc_ref((new ${typeNames.get(refRet).constructor}(');
							} else {
								if( tret.t != TVoid ) output.add("return ");
								for( a in ret.attr ) {
									switch( a ) {
									case ARef, AValue:
										refRet = switch(tret.t) {
										case TCustom(id): id;
										default: throw "assert";
										}
										output.add('alloc_ref(new ${typeNames.get(refRet).constructor}(');
									default:
									}
								}
								if( enumName != null )
									output.add('make__$enumName(');
								else if( refRet == null && ret.t.match(TCustom(_)) ) {
									refRet = switch(tret.t) {
									case TCustom(id): id;
									default: throw "assert";
									}
									if( tret.attr.indexOf(AConst) >= 0 )
										output.add('alloc_ref_const((');
									else
										output.add('alloc_ref((');
								}

								switch( f.name ) {
								case "op_mul":
									output.add("*_unref(_this) * (");
								case "op_add":
									output.add("*_unref(_this) + (");
								case "op_sub":
									output.add("*_unref(_this) - (");
								case "op_div":
									output.add("*_unref(_this) / (");
								case "op_mulq":
									output.add("*_unref(_this) *= (");
								default:
									output.add("_unref(_this)->" + f.name+"(");
								}
							}

							var first = true;
							for( a in margs ) {
								if( first ) first = false else output.add(", ");
								for( a in a.t.attr ) {
									switch( a ) {
									case ARef: output.add("*"); // unref
									default:
									}
								}
								var e = getEnumName(a.t.t);
								if( e != null )
									output.add('${e}__values[${a.name}]');
								else switch( a.t.t ) {
								case TCustom(_):
									output.add('_unref(${a.name})');
								default:
									output.add(a.name);
									if( isDyn(a) ) output.add(dynamicAccess(a.t.t));
								}
							}

							if( enumName != null ) output.add(')');
							if( refRet != null ) output.add(')),finalize_$refRet');
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
						output.add('DEFINE_PRIM(${defType(tret.t)}, $funName,');
						for( a in args )
							output.add(' ' + (isDyn(a) ? "_NULL(" + defType(a.t.t)+")" : defType(a.t.t)));
						add(');');
						add('');


					case FAttribute(t):
						var isVal = t.attr.indexOf(AValue) >= 0;
						var tname = switch( t.t ) { case TCustom(id): id; default: null; };
						var isRef = tname != null;
						var enumName = getEnumName(t.t);
						var isConst = t.attr.indexOf(AConst) >= 0;

						if( enumName != null ) throw "TODO : enum attribute";

						add('HL_PRIM ${makeTypeDecl(t)} HL_NAME(${name}_get_${f.name})( ${typeNames.get(name).full} _this ) {');
						if( isVal ) {
							var fname = typeNames.get(tname).constructor;
							add('\treturn alloc_ref(new $fname(_unref(_this)->${f.name}),finalize_$tname);');
						} else if( isRef )
							add('\treturn alloc_ref${isConst?'_const':''}(_unref(_this)->${f.name},finalize_$tname);');
						else
							add('\treturn _unref(_this)->${f.name};');
						add('}');

						add('HL_PRIM void HL_NAME(${name}_set_${f.name})( ${typeNames.get(name).full} _this, ${makeTypeDecl(t)} value ) {');
						add('\t_unref(_this)->${f.name} = ${isVal?"*":""}${isRef?"_unref":""}(value);');
						add('}');
						add('');
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
		generate({ idl : file, libName : file.split(".").shift() });
	}

}