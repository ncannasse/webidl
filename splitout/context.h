#include "stdio.h"

class Context {
public:
    Context(){
        printf("%s\n", "This is Context!");
    }
    void test();
};