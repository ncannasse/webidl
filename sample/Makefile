all: hl js

libpoint.cpp:
	haxe -lib webidl --macro "SampleModule.buildLibCpp()"

libpoint.js: libpoint.cpp
	haxe -lib webidl --macro "SampleModule.buildLibJS()"

js: libpoint.js
	haxe -js sample.js -lib webidl -main Sample -dce full

# ---- HL PART

ifndef HLPATH
HLPATH = /path/to/hl
endif

libpoint.hdll: libpoint.cpp
	$(CC) -o libpoint.hdll -shared -fPIC -Wall -O3 -I . -I $(HLPATH) libpoint.cpp point.cpp -lstdc++ -lhl

libpoint_win: libpoint.cpp
	cl /olibpoint.hdll /LD /EHsc /I $(HLPATH) /DYNAMICBASE libhl.lib libpoint.cpp point.cpp

hl:	libpoint.hdll
	haxe sample.hxml

.PHONY: libpoint.cpp libpoint.js

.SUFFIXES : .cpp .o

.cpp.o:
	$CC
