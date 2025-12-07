# Makefile for SwiftScreenShot
# Provides convenient commands to build, run, and manage the project

.PHONY: all build run clean test release help

# Default target
all: build

# Build the project in debug mode
build:
	@echo "🔨 Building SwiftScreenShot..."
	swift build

# Build and run the project
run: build
	@echo "🚀 Running SwiftScreenShot..."
	@echo "📝 Note: You may need to grant Screen Recording permission in System Settings"
	swift run

# Build in release mode
release:
	@echo "🔨 Building SwiftScreenShot in release mode..."
	swift build -c release
	@echo "✅ Release build complete!"
	@echo "📦 Binary location: .build/release/SwiftScreenShot"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	swift package clean
	rm -rf .build

# Reset and rebuild
rebuild: clean build

# Install the release binary to /usr/local/bin
install: release
	@echo "📥 Installing SwiftScreenShot to /usr/local/bin..."
	@mkdir -p /usr/local/bin
	@cp .build/release/SwiftScreenShot /usr/local/bin/
	@echo "✅ Installation complete! You can now run 'SwiftScreenShot' from anywhere"

# Uninstall the binary
uninstall:
	@echo "🗑️  Uninstalling SwiftScreenShot..."
	@rm -f /usr/local/bin/SwiftScreenShot
	@echo "✅ Uninstallation complete"

# Show help
help:
	@echo "SwiftScreenShot - macOS Screenshot Tool"
	@echo ""
	@echo "Available targets:"
	@echo "  make build    - Build the project in debug mode"
	@echo "  make run      - Build and run the project"
	@echo "  make release  - Build in release mode (optimized)"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make rebuild  - Clean and rebuild"
	@echo "  make install  - Install release binary to /usr/local/bin"
	@echo "  make uninstall- Uninstall the binary"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Quick start:"
	@echo "  1. Run 'make run' to build and launch the app"
	@echo "  2. Grant Screen Recording permission when prompted"
	@echo "  3. Use Control+Command+A to take a screenshot"
