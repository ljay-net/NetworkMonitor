#include <stdio.h>

int main() {
    #ifdef __arm64__
        printf("Hello from macOS on ARM64 (Apple Silicon)!\n");
        printf("Running optimized code for Apple Silicon\n");
    #elif defined(__x86_64__)
        printf("Hello from macOS on x86_64 (Intel)!\n");
        printf("Running on Intel architecture\n");
    #else
        printf("Hello from macOS on unknown architecture!\n");
    #endif
    
    return 0;
}