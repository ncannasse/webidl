package webidl;
import haxe.macro.Context;
import webidl.Data;

typedef BuildOptions = {
	var file : String;
	@:optional var chopPrefix : String;
	@:optional var jsNative : String;
}

class Module {

	public static function build( opts : BuildOptions ) {
		var p = Context.currentPos();

		// load IDL
		var file = opts.file;
		var content = try {
			file = Context.resolvePath(opts.file);
			sys.io.File.getBytes(file);
		} catch( e : Dynamic ) {
			Context.error("" + e, p);
			return macro : Void;
		}

		// parse IDL
		var parse = new webidl.Parser();
		var decls = null;
		try {
			decls = parse.parseFile(new haxe.io.BytesInput(content));
		} catch( msg : String ) {
			var lines = content.toString().split("\n");
			var start = lines.slice(0, parse.line-1).join("\n").length + 1;
			Context.error(msg, Context.makePosition({ min : start, max : start + lines[parse.line-1].length, file : file }));
			return macro : Void;
		}

		// Build Haxe definitions
		var module = Context.getLocalModule();
		var pack = module.split(".");
		pack.pop();
		var types : Array<haxe.macro.Expr.TypeDefinition> = [];

		function makeName( name : String ) {
			if( StringTools.startsWith(name, opts.chopPrefix) ) name = name.substr(opts.chopPrefix.length);
			return name;
		}

		function makeType( t : TypeAttr ) : haxe.macro.Expr.ComplexType {
			return switch( t.t ) {
			case TVoid: macro : Void;
			case TInt, TLong, TShort: macro : Int;
			case TFloat, TDouble: macro : Float;
			case TBool: macro : Bool;
			case TAny: macro : webidl.Types.Any;
			case TArray(t): macro : Dynamic; /* TODO */
			case TVoidPtr: macro : webidl.Types.VoidPtr;
			case TCustom(id): TPath({ pack : [], name : makeName(id) });
			}
		}

		for( d in decls ) {
			switch( d ) {
			case DInterface(iname, attrs, fields):
				var dfields : Array<haxe.macro.Expr.Field> = [];
				var hasConstructor = false;
				for( f in fields ) {
					switch( f.kind ) {
					case FMethod(args, ret):

						if( f.name == iname ) {
							if( args.length == 0 ) {
								var otherConstructorFound = false;
								for( f2 in fields )
									if( f != f2 && f2.name == f.name ) {
										switch( f.kind ) {
										case FMethod(args, _):
											// make all args optional for other constructor
											for( a in args )
												a.opt = true;
											if( fields.indexOf(f2) < fields.indexOf(f) )
												Context.warning("Generic constructor should be declared before specific one for "+iname, p);
											otherConstructorFound = true;
											break;
										default:
										}
									}
								if( otherConstructorFound )
									continue;
							}
							if( !hasConstructor )
								hasConstructor = true;
							else {
								Context.warning("Ignoring duplicate constructor for " + iname, p);
								continue;
							}
						}

						dfields.push({
							pos : p,
							name : f.name == iname ? "new" : f.name,
							kind : FFun({
								ret : makeType(ret),
								expr : null,
								args : [for( a in args ) { name : a.name, opt : a.opt, type : makeType(a.t) }],
							}),
						});
					case FAttribute(t):
						dfields.push({
							pos : p,
							name : f.name,
							kind : FProp("get", "set", makeType(t)),
						});
					}
				}
				var td : haxe.macro.Expr.TypeDefinition = {
					pos : p,
					pack : pack,
					name : makeName(iname),
					meta : [],
					kind : TDClass(),
					fields : dfields,
					isExtern : true,
				};
				if( opts.jsNative != null )
					td.meta.push({ name : ":native", params:[{expr:EConst(CString(opts.jsNative+iname)), pos:p}], pos:p});
				types.push(td);
			case DImplements(name,intf):
				var name = makeName(name);
				var intf = makeName(intf);
				var found = false;
				for( t in types )
					if( t.name == name ) {
						found = true;
						switch( t.kind ) {
						case TDClass(null, intfs, isInt):
							t.kind = TDClass({ pack : [], name : intf }, isInt);
						default:
							Context.warning("Cannot have " + name+" extends " + intf, p);
						}
						break;
					}
				if( !found )
					Context.warning("Class " + name+" not found for implements " + intf, p);
			case DEnum(name, values):
				types.push({
					pos : p,
					pack : pack,
					name : makeName(name),
					meta : [{ name : ":enum", pos : p }],
					kind : TDAbstract(macro : String),
					fields : [for( v in values ) { pos : p, name : v, kind : FVar(null,{ expr : EConst(CString(v)), pos : p }) }],
				});
			}
		}
		Context.defineModule(Context.getLocalModule(), types);

		return macro : Void;
	}

}
