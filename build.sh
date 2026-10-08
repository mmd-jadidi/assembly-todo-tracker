#!/bin/bash

# 1. Create the necessary directories if they don't exist
mkdir -p logs
mkdir -p data

# 2. Assemble the code (telling NASM where to find the included folders)
echo "🔨 Assembling..."
nasm -F dwarf -g -f elf64 main.asm -o logs/main.o -I./lib/ -I./commands/

# Check if assembly was successful
if [ $? -eq 0 ]; then
    # 3. Link the object file into an executable
    echo "🔗 Linking..."
    ld -o logs/main logs/main.o

    # 4. Run the program!
    echo "🚀 Running To-Do Tracker..."
    echo "------------------------------------------------"
    ./logs/main
else
    echo "❌ Assembly failed. Check the errors above."
fi