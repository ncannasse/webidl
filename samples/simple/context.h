#include "stdio.h"

#include "emscripten.h"
#include <GLES3/gl3.h>
#include <emscripten/html5.h>

class Context {
    public:
        Context(){
            printf("%s\n", "Context Initialized");
        }
        void test();
};