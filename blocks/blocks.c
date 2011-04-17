#include <stdio.h>

void EvalFuncOnGrid( double(^block)(float) ) {
    int i;
    for ( i = 0; i < 5 ; ++i ) {
        float x = i * 0.1;
        printf("%f %f\n", x, block(x));
    }
}

void Caller(void) {
    float forceConst = 3.445;
    EvalFuncOnGrid(^(float x){ return 0.5 * forceConst * x * x; });
}

int main(void) {
   Caller();
}
