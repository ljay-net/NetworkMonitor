#!/bin/bash

# Exit on error
set -e

# Create build directory if it doesn't exist
mkdir -p build

# Build using make
make

echo ""
echo "Build completed successfully!"
echo "Run the application with: ./build/NetworkMonitor"
