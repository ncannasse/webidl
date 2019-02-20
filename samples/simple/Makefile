all:

OUT = "./webRoot/"

clean:
	if [ -f $(OUT)lib_simple.bc ]; then rm $(OUT)lib_simple.bc; fi;
	if [ -f $(OUT)lib_simple.cpp ]; then rm $(OUT)lib_simple.cpp; fi;
	if [ -f $(OUT)lib_simple.js ]; then rm $(OUT)lib_simple.js; fi;
	if [ -f $(OUT)lib_simple.wasm ]; then rm $(OUT)lib_simple.wasm; fi;

	if [ -f $(OUT)simple.js ]; then rm $(OUT)simple.js; fi;

	if [ -f $(OUT)point.bc ]; then rm $(OUT)point.bc; fi;
	if [ -f $(OUT)context.bc ]; then rm $(OUT)context.bc; fi;

lib_simple.cpp:
	haxe -lib webidl --macro "SimpleModule.buildLibCpp()"

lib_simple.js: lib_simple.cpp
	haxe -lib webidl --macro "SimpleModule.buildLibJS()"

js: lib_simple.js
	haxe -js $(OUT)simple.js -lib webidl -main Simple -dce full

# ---- HL PART

ifndef HLPATH
HLPATH = /path/to/hl
endif

lib_simple.hdll: lib_simple.cpp
	$(CC) -o lib_simple.hdll -shared -Wall -O0 -I . -I $(HLPATH) lib_simple.cpp -lstdc++ -lhl

lib_simple: lib_simple.cpp
	cl /olib_simple.hdll /LD /EHsc /I $(HLPATH) /DYNAMICBASE libhl.lib lib_simple.cpp
	
hl:	lib_simple.hdll
	haxe -hl simple.hl -lib webidl -main Simple
	
.PHONY: lib_simple.cpp lib_simple.js

.SUFFIXES : .cpp .o

.cpp.o:
	$CC 