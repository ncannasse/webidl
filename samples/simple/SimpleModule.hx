#if !macro
private typedef Import = haxe.macro.MacroType<[SimpleModule.build()]>; 
#else

class SimpleModule {

	static var json = {
		var cc = sys.io.File.getBytes("./webidl.json");
		var obj = haxe.Json.parse(cc.toString());
		obj;
	}

	static var config: webidl.Options = json;
	
	public static function build() {
		return webidl.Module.build(config);
	}

	public static function buildLibCpp() {
		webidl.Generate.generateCpp(config);
	}
	
	public static function buildLibJS() {
		webidl.Generate.generateJs(config);
	}
}

#end