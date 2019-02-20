package webidl;

typedef Options = {
	var idlFile : String;
	var nativeLib : String;
	var sourceFiles: Array<String>;
	@:optional var chopPrefix : String;
	@:optional var autoGC : Bool;
	@:optional var out: String;
}