#if !macro
private typedef Import = haxe.macro.MacroType<[SampleModule.build()]>; 
#else

class SampleModule {

	static var config : webidl.Options = {
		idlFile : "point.idl",
		nativeLib : "libpoint",
		includeCode : "#include \"point.h\"",
		autoGC : false,
	};
	
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