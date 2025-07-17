cmake_minimum_required(VERSION 3.15)
project(AppleSiliconDemo VERSION 1.0)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable Apple Silicon optimizations when available
if(APPLE)
    # Check if we're on Apple Silicon
    execute_process(
        COMMAND sysctl -n machdep.cpu.brand_string
        OUTPUT_VARIABLE CPU_BRAND
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if(CPU_BRAND MATCHES "Apple")
        message(STATUS "Building for Apple Silicon")
        # Add Apple Silicon specific flags if needed
        add_compile_options(-mcpu=apple-m1)
    else()
        message(STATUS "Building for Intel Mac")
    endif()
endif()

# Add executable
add_executable(AppleSiliconDemo src/main.cpp)

# Install target
install(TARGETS AppleSiliconDemo DESTINATION bin)