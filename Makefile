# --- Configuration ---
PROGRAM_NAME := msw
SOURCE_DIR   := .
BUILD_DIR    := build
OUT_FILE     := $(BUILD_DIR)/$(PROGRAM_NAME)
LIB_PATH     := ./lib

# Odin collections - external dependencies only
# Example: -collection:shared=./shared
COLLECTIONS  :=

# --- Compiler Flags ---
COMMON_FLAGS  := -vet -strict-style
DEBUG_FLAGS   := -use-single-module -debug -o:none
RELEASE_FLAGS := -o:speed -no-bounds-check

# --- Targets ---

.PHONY: all debug release clean

# Default target
all: debug

# Debug Target
debug: setup
	@echo "Building (Debug)..."
	odin build $(SOURCE_DIR) $(COMMON_FLAGS) $(DEBUG_FLAGS) $(COLLECTIONS) -out:$(OUT_FILE)-debug -extra-linker-flags="-L$(LIB_PATH) -framework Cocoa -framework IOKit -framework CoreVideo"

# Release Target
release: setup
	@echo "Building (Release)..."
	odin build $(SOURCE_DIR) $(COMMON_FLAGS) $(RELEASE_FLAGS) $(COLLECTIONS) -out:$(OUT_FILE)-release -extra-linker-flags="-L$(LIB_PATH) -framework Cocoa -framework IOKit -framework CoreVideo"

# Create build directory
setup:
	@mkdir -p $(BUILD_DIR)

# Clean build artifacts
clean:
	@echo "Cleaning up..."
	rm -rf $(BUILD_DIR)
