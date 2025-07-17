#include <iostream>
#include <string>

#ifdef __arm64__
    #define ARCHITECTURE "ARM64 (Apple Silicon)"
#elif defined(__x86_64__)
    #define ARCHITECTURE "x86_64 (Intel)"
#else
    #define ARCHITECTURE "Unknown"
#endif

int main() {
    std::cout << "Hello from macOS on " << ARCHITECTURE << "!" << std::endl;
    
    // Demonstrate platform-specific code
    #ifdef __arm64__
        std::cout << "Running optimized code for Apple Silicon" << std::endl;
    #else
        std::cout << "Running on Intel architecture" << std::endl;
    #endif
    
    return 0;
}