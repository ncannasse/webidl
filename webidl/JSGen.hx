package webidl;

class JSGen {

	static function command( cmd, args : Array<String> ) {
		Sys.println("> " + cmd + " " + args.join(" "));
		var ret = Sys.command(cmd, args);
		if( ret != 0 ) throw "Command '" + cmd + "' has exit with error code " + ret;
	}

	public static function compile( opts : HLGen.GenerationOpts, sources : Array<String>, ?params : Array<String> ) {
		if( params == null )
			params = [];

		if( params.indexOf("-O1") < 0 && params.indexOf("-O2") < 0 )
			params.push("-O2");

		// generate bindings
		command("python", [Sys.getEnv("EMSDK") + "/tools/webidl_binder.py", opts.idl, opts.libName+"_js"]);
		var glueCpp = opts.libName+"_js.cpp";
		if( opts.includeCode != null ) {
			sys.io.File.saveContent(opts.libName+"_wrap.cpp", opts.includeCode+'\n#include "$glueCpp"');
			sources.push(opts.libName+"_wrap.cpp");
		} else
			sources.push(opts.libName+"_js.cpp");

		// delete tmp wrapper files
		try {
			sys.FileSystem.deleteFile("parser.out");
			sys.FileSystem.deleteFile("WebIDLGrammar.pkl");
		} catch( e : Dynamic ) {
		}

		// build sources BC files
		var outFiles = [];
		for( cfile in sources ) {
			var out = cfile.substr(0, -4) + ".bc";
			var args = params.concat(["-c", cfile, "-o", out]);
			args.unshift(Sys.getEnv("EMSDK") + "/emcc.py");
			command("python", args);
			outFiles.push(out);
		}

		// link : because too many files, generate Makefile
		var tmp = "Makefile.tmp";
		var args = params.concat([
			"-s", "EXPORT_NAME="+opts.libName,
			"--post-js", opts.libName+"_js.js",
			"-o", opts.libName+".js"
		]);
		var output = "SOURCES = " + outFiles.join(" ") + "\n";
		output += "all:\n";
		output += "\tpython \"$(EMSDK)/emcc.py\" $(SOURCES) " + args.join(" ");
		sys.io.File.saveContent(tmp, output);
		command("make", ["-f", tmp]);
		sys.FileSystem.deleteFile(tmp);

		sys.FileSystem.deleteFile(opts.libName+"_js.js");
		sys.FileSystem.deleteFile(opts.libName+"_js.cpp");
		sys.FileSystem.deleteFile(opts.libName+".js.mem");
		try {
			sys.FileSystem.deleteFile(opts.libName+"_wrap.cpp");
		} catch( e : Dynamic ) {};


	}

}