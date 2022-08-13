#include <stdio.h>
#include <stdlib.h>
#include <float.h>

int length = 20;

void test_ffwd() {
    float ffwd = 0.0;
    for (int y = 0; y < length; y++) {
        for (int x = 0; x < length; x++) {
            ffwd += 5.0 * 3.0;  // weights[y][x] * inputs[y][x]
        }
    }
    printf("%f\n", ffwd);  // 6000
}

int main() {
    test_ffwd();
    return 0;
}

// gcc scratch.c -o scratch; ./scratch