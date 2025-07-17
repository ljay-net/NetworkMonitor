#!/bin/bash

# Exit on error
set -e

echo "Compiling Swift program..."
swiftc -o AppleSiliconDemoSwift src/main.swift

echo "Running Swift program..."
./AppleSiliconDemoSwift