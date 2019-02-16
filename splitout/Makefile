all:

OUT = "./webRoot/"

clean:
	if [ -f $(OUT)libpoint.cpp ]; then rm $(OUT)libpoint.cpp; fi;
	if [ -f $(OUT)libpoint.bc ]; then rm $(OUT)libpoint.bc; fi;
	if [ -f $(OUT)libpoint.js ]; then rm $(OUT)libpoint.js; fi;
	if [ -f $(OUT)libpoint.wasm ]; then rm $(OUT)libpoint.wasm; fi;
	if [ -f $(OUT)splitout.js ]; then rm $(OUT)splitout.js; fi;
	if [ -f $(OUT)point.bc ]; then rm $(OUT)point.bc; fi;
	if [ -f $(OUT)context.bc ]; then rm $(OUT)context.bc; fi;

libpoint.cpp:
	haxe -lib webidl --macro "SplitoutModule.buildLibCpp()"

libpoint.js: libpoint.cpp
	haxe -lib webidl --macro "SplitoutModule.buildLibJS()"

js: libpoint.js
	haxe -js $(OUT)splitout.js -lib webidl -main Splitout -dce full

# ---- HL PART

ifndef HLPATH
HLPATH = /path/to/hl
endif

libpoint.hdll: libpoint.cpp
	$(CC) -o libpoint.hdll -shared -Wall -O3 -I . -I $(HLPATH) libpoint.cpp point.cpp context.cpp -lstdc++ -lhl

libpoint_win: libpoint.cpp
	cl /olibpoint.hdll /LD /EHsc /I $(HLPATH) /DYNAMICBASE libhl.lib libpoint.cpp point.cpp context.cpp
	
hl:	libpoint.hdll
	haxe -hl splitout.hl -lib webidl -main Splitout
	
.PHONY: libpoint.cpp libpoint.js

.SUFFIXES : .cpp .o

.cpp.o:
	$CC 