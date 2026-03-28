# Root Makefile for rquickshare
# Consolidated commands from core_lib and app/main

.PHONY: all setup build release-build dev clean test check lint

# Default target
all: build

# Setup dependencies
setup:
	@echo "Installing (p)npm dependencies in app/main..."
	cd app/main && pnpm install

# Build debug version
debug-build:
	@echo "Building core_lib (debug)..."
	cd core_lib && cargo build
	@echo "Building app/main (debug)..."
	cd app/main && pnpm build:debug

# Build release version
build:
	@echo "Building core_lib (release)..."
	cd core_lib && cargo build --release
	@echo "Building app/main (release)..."
	cd app/main && pnpm build

# Run development mode
dev:
	cd app/main && pnpm dev

# Run tests for both components
test:
	@echo "Running core_lib tests..."
	cd core_lib && cargo test
	@echo "Running app/main tests..."
	cd app/main && pnpm test

# Check everything
check:
	@echo "Checking core_lib..."
	cd core_lib && cargo check
	@echo "Checking app/main (Rust)..."
	cd app/main && pnpm check
	@echo "Checking app/main (TypeScript)..."
	cd app/main && pnpm ts-check
	@echo "Linting app/main..."
	cd app/main && pnpm lint

# Clean all artifacts
clean:
	@echo "Cleaning core_lib..."
	cd core_lib && cargo clean
	@echo "Cleaning app/main..."
	rm -rf app/main/dist app/main/src-tauri/target
