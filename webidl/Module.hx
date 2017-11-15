package webidl;
import haxe.macro.Context;
import webidl.Data;

typedef BuildOptions = {
	var file : String;
	@:optional var chopPrefix : String;
	@:optional var nativeLib : String;
	@:optional var autoGC : Bool;
}

class Module {

	public static function build( opts : BuildOptions ) {
		var p = Context.currentPos();
		var hl = Context.defined("hl");

		if( hl && opts.nativeLib == null ) {
			Context.error("Missing nativeLib option for HL", p);
			return macro : Void;
		}

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
			case TInt: macro : Int;
			case TShort: hl ? macro : hl.UI16 : macro : Int;
			case TFloat: hl ? macro : Single : macro : Float;
			case TDouble: macro : Float;
			case TBool: macro : Bool;
			case TAny: macro : webidl.Types.Any;
			case TArray(t):
				var tt = makeType({ t : t, attr : [] });
				macro : webidl.Types.NativePtr<$tt>;
			case TVoidPtr: macro : webidl.Types.VoidPtr;
			case TCustom(id): TPath({ pack : [], name : makeName(id) });
			}
		}

		function defVal( t : TypeAttr ) : haxe.macro.Expr {
			return switch( t.t ) {
			case TVoid: throw "assert";
			case TInt, TShort: { expr : EConst(CInt("0")), pos : p };
			case TFloat, TDouble: { expr : EConst(CFloat("0.")), pos : p };
			case TBool: { expr : EConst(CIdent("false")), pos : p };
			default: { expr : EConst(CIdent("null")), pos : p };
			}
		}

		function makeNative( name : String ) : haxe.macro.Expr.MetadataEntry {
			return { name : ":hlNative", params : [{ expr : EConst(CString(opts.nativeLib)), pos : p },{ expr : EConst(CString(name)), pos : p }], pos : p };
		}

		for( d in decls ) {
			switch( d ) {
			case DInterface(iname, attrs, fields):
				var dfields : Array<haxe.macro.Expr.Field> = [];
				var hasConstructor = false;
				for( f in fields ) {
					switch( f.kind ) {
					case FMethod(args, ret):
						var isConstr = f.name == iname;

						if( isConstr ) {
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

						var expr : haxe.macro.Expr = null;
						if( hl ) {
							if( isConstr ) {
								var constr = "new_" + args.length;
								var eargs : Array<haxe.macro.Expr> = [for( a in args ) { expr : EConst(CIdent(a.name)), pos : p }];
								expr = { expr : EBinop(OpAssign, macro this, { expr : ECall({ expr : EConst(CIdent(constr)), pos:p}, eargs), pos:p}), pos : p};

								dfields.push({
									pos : p,
									name : constr,
									access : [AStatic],
									meta : [makeNative(iname+"_new"+args.length)],
									kind : FFun({
										ret : TPath({ pack : [], name : makeName(iname) }),
										args : [for( a in args ) { name : a.name, opt : a.opt, type : makeType(a.t) }],
										expr : macro return null,
									}),
								});

							} else if( ret.t == TVoid )
								expr = { expr : EBlock([]), pos : p };
							else
								expr = { expr : EReturn(defVal(ret)), pos : p };
						}

						var f : haxe.macro.Expr.Field = {
							pos : p,
							name : isConstr ? "new" : f.name,
							meta : [],
							access : [APublic],
							kind : FFun({
								ret : makeType(ret),
								expr : expr,
								args : [for( a in args ) { name : a.name, opt : a.opt, type : makeType(a.t) }],
							}),
						};
						dfields.push(f);

						if( hl && !isConstr )
							f.meta.push(makeNative(iname+"_" + f.name));

					case FAttribute(t):
						var tt = makeType(t);
						dfields.push({
							pos : p,
							name : f.name,
							kind : FProp("get", "set", tt),
							access : [APublic],
						});
						if( hl ) {
							dfields.push({
								pos : p,
								name : "get_" + f.name,
								kind : FFun({
									ret : tt,
									expr : macro { throw "TODO"; return cast null; },
									args : [],
								}),
							});
							dfields.push({
								pos : p,
								name : "set_" + f.name,
								kind : FFun({
									ret : tt,
									expr : macro { throw "TODO"; return _v; },
									args : [{ name : "_v", type : tt }],
								}),
							});
						}
					}
				}
				var td : haxe.macro.Expr.TypeDefinition = {
					pos : p,
					pack : pack,
					name : makeName(iname),
					meta : [],
					kind : hl ? TDAbstract(macro : webidl.Types.Ref, [], [macro : webidl.Types.Ref]) : TDClass(),
					fields : dfields,
					isExtern : !hl,
				};
				if( !hl )
					td.meta.push({ name : ":native", params:[{expr:EConst(CString(opts.nativeLib+"."+iname)), pos:p}], pos :p });
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
						case TDAbstract(a, _):
							t.fields.push({
								pos : p,
								name : "_to" + intf,
								meta : [{ name : ":to", pos : p }],
								access : [AInline],
								kind : FFun({
									args : [],
									expr : macro return cast this,
									ret : TPath({ pack : [], name : intf }),
								}),
							});
							// TODO : all fields needs to be inherited too !
						default:
							Context.warning("Cannot have " + name+" extends " + intf, p);
						}
						break;
					}
				if( !found )
					Context.warning("Class " + name+" not found for implements " + intf, p);
			case DEnum(name, values):
				var index = 0;
				types.push({
					pos : p,
					pack : pack,
					name : makeName(name),
					meta : [{ name : ":enum", pos : p }],
					kind : TDAbstract(hl ? macro : Int : macro : String),
					fields : [for( v in values ) { pos : p, name : v, kind : FVar(null,{ expr : EConst(hl?CInt(""+(index++)):CString(v)), pos : p }) }],
				});
			}
		}

		var local = Context.getLocalModule();
		Context.defineModule(local, types);
		Context.registerModuleDependency(local, file);

		return macro : Void;
	}

}
