#if !macro
private typedef Import = haxe.macro.MacroType<[SplitoutModule.build()]>; 
#else

class SplitoutModule {

	static var json = {
		var cc = sys.io.File.getBytes("./webidl.json");
		var obj = haxe.Json.parse(cc.toString());
		obj;
	}

	static var config : webidl.Options = json;
	
	public static function build() {
		return webidl.Module.build(config);
	}

	public static function buildLibCpp() {
		webidl.Generate.generateCpp(config);
	}
	
	public static function buildLibJS() {
		var sourceFiles = ["point.cpp"];
		webidl.Generate.generateJs(config, sourceFiles);
	}
}

#end

//static var config : webidl.Options = {
//	idlFile : "point.idl",
//	nativeLib : "libpoint",
//	includeCode : "#include \"point.h\"",
//	autoGC : false,
//};