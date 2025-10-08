# Makefile for NSClear
# Simplifies common development and deployment tasks

# Configuration
BINARY_NAME := nsclear
INSTALL_PATH := /usr/local/bin
BUILD_DIR := .build
RELEASE_DIR := $(BUILD_DIR)/release
DEBUG_DIR := $(BUILD_DIR)/debug

# Swift compiler flags
SWIFT_BUILD_FLAGS := --configuration release
SWIFT_TEST_FLAGS := --parallel

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: all build release debug test clean install uninstall run help format lint

# Default target
all: build

## build: Build the project in release mode
build: release

## release: Build optimized release binary
release:
	@echo "$(BLUE)Building release binary...$(NC)"
	@swift build -c release
	@echo "$(GREEN)✓ Release build complete$(NC)"
	@echo "$(BLUE)Binary location: $(RELEASE_DIR)/$(BINARY_NAME)$(NC)"

## debug: Build debug binary
debug:
	@echo "$(BLUE)Building debug binary...$(NC)"
	@swift build -c debug
	@echo "$(GREEN)✓ Debug build complete$(NC)"

## test: Run all tests
test:
	@echo "$(BLUE)Running tests...$(NC)"
	@swift test $(SWIFT_TEST_FLAGS)
	@echo "$(GREEN)✓ All tests passed$(NC)"

## test-verbose: Run tests with verbose output
test-verbose:
	@echo "$(BLUE)Running tests (verbose)...$(NC)"
	@swift test --verbose

## clean: Remove build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@swift package clean
	@rm -rf $(BUILD_DIR)
	@echo "$(GREEN)✓ Clean complete$(NC)"

## install: Install nsclear to system
install: release
	@echo "$(BLUE)Installing $(BINARY_NAME) to $(INSTALL_PATH)...$(NC)"
	@if [ ! -w "$(INSTALL_PATH)" ]; then \
		echo "$(YELLOW)⚠ Need sudo privileges$(NC)"; \
		sudo cp $(RELEASE_DIR)/$(BINARY_NAME) $(INSTALL_PATH)/$(BINARY_NAME); \
		sudo chmod +x $(INSTALL_PATH)/$(BINARY_NAME); \
	else \
		cp $(RELEASE_DIR)/$(BINARY_NAME) $(INSTALL_PATH)/$(BINARY_NAME); \
		chmod +x $(INSTALL_PATH)/$(BINARY_NAME); \
	fi
	@echo "$(GREEN)✓ Installed successfully$(NC)"
	@echo "$(BLUE)Run 'nsclear --help' to get started$(NC)"

## uninstall: Remove nsclear from system
uninstall:
	@echo "$(YELLOW)Uninstalling $(BINARY_NAME)...$(NC)"
	@if [ -f "$(INSTALL_PATH)/$(BINARY_NAME)" ]; then \
		if [ ! -w "$(INSTALL_PATH)" ]; then \
			sudo rm $(INSTALL_PATH)/$(BINARY_NAME); \
		else \
			rm $(INSTALL_PATH)/$(BINARY_NAME); \
		fi; \
		echo "$(GREEN)✓ Uninstalled successfully$(NC)"; \
	else \
		echo "$(YELLOW)⚠ $(BINARY_NAME) not found at $(INSTALL_PATH)$(NC)"; \
	fi

## run: Build and run nsclear with arguments (use ARGS="...")
run: debug
	@echo "$(BLUE)Running $(BINARY_NAME)...$(NC)"
	@$(DEBUG_DIR)/$(BINARY_NAME) $(ARGS)

## format: Format Swift code
format:
	@echo "$(BLUE)Formatting Swift code...$(NC)"
	@if command -v swiftformat > /dev/null; then \
		swiftformat Sources/ Tests/; \
		echo "$(GREEN)✓ Code formatted$(NC)"; \
	else \
		echo "$(YELLOW)⚠ swiftformat not installed$(NC)"; \
		echo "$(BLUE)Install with: brew install swiftformat$(NC)"; \
	fi

## lint: Run SwiftLint
lint:
	@echo "$(BLUE)Running SwiftLint...$(NC)"
	@if command -v swiftlint > /dev/null; then \
		swiftlint; \
		echo "$(GREEN)✓ Linting complete$(NC)"; \
	else \
		echo "$(YELLOW)⚠ swiftlint not installed$(NC)"; \
		echo "$(BLUE)Install with: brew install swiftlint$(NC)"; \
	fi

## resolve: Resolve package dependencies
resolve:
	@echo "$(BLUE)Resolving package dependencies...$(NC)"
	@swift package resolve
	@echo "$(GREEN)✓ Dependencies resolved$(NC)"

## update: Update package dependencies
update:
	@echo "$(BLUE)Updating package dependencies...$(NC)"
	@swift package update
	@echo "$(GREEN)✓ Dependencies updated$(NC)"

## version: Show version information
version:
	@echo "$(BLUE)NSClear Build Information$(NC)"
	@echo "Swift version: $$(swift --version | head -n 1)"
	@echo "Xcode version: $$(xcodebuild -version 2>/dev/null | head -n 1 || echo 'N/A')"
	@echo "macOS version: $$(sw_vers -productVersion)"

## benchmark: Run performance benchmarks
benchmark: release
	@echo "$(BLUE)Running benchmarks...$(NC)"
	@echo "$(YELLOW)⚠ Benchmarks not yet implemented$(NC)"

## package: Create distributable package
package: release
	@echo "$(BLUE)Creating package...$(NC)"
	@mkdir -p dist
	@cp $(RELEASE_DIR)/$(BINARY_NAME) dist/
	@tar -czf dist/$(BINARY_NAME)-macos.tar.gz -C dist $(BINARY_NAME)
	@rm dist/$(BINARY_NAME)
	@echo "$(GREEN)✓ Package created: dist/$(BINARY_NAME)-macos.tar.gz$(NC)"

## docs: Generate documentation
docs:
	@echo "$(BLUE)Generating documentation...$(NC)"
	@swift package generate-documentation
	@echo "$(GREEN)✓ Documentation generated$(NC)"

## dev: Set up development environment
dev: resolve
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@if ! command -v swiftformat > /dev/null; then \
		echo "$(YELLOW)⚠ Consider installing swiftformat: brew install swiftformat$(NC)"; \
	fi
	@if ! command -v swiftlint > /dev/null; then \
		echo "$(YELLOW)⚠ Consider installing swiftlint: brew install swiftlint$(NC)"; \
	fi
	@echo "$(GREEN)✓ Development environment ready$(NC)"

## help: Show this help message
help:
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)              NSClear - Makefile Help                 $(BLUE)║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Common Commands:$(NC)"
	@echo "  $(YELLOW)make build$(NC)        - Build release binary"
	@echo "  $(YELLOW)make test$(NC)         - Run tests"
	@echo "  $(YELLOW)make install$(NC)      - Install to system"
	@echo "  $(YELLOW)make uninstall$(NC)    - Remove from system"
	@echo "  $(YELLOW)make clean$(NC)        - Clean build artifacts"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@echo "  $(YELLOW)make dev$(NC)          - Set up dev environment"
	@echo "  $(YELLOW)make debug$(NC)        - Build debug binary"
	@echo "  $(YELLOW)make run ARGS='...'$(NC) - Run with arguments"
	@echo "  $(YELLOW)make format$(NC)       - Format code"
	@echo "  $(YELLOW)make lint$(NC)         - Run linter"
	@echo ""
	@echo "$(GREEN)Package Management:$(NC)"
	@echo "  $(YELLOW)make resolve$(NC)      - Resolve dependencies"
	@echo "  $(YELLOW)make update$(NC)       - Update dependencies"
	@echo "  $(YELLOW)make package$(NC)      - Create distributable"
	@echo ""
	@echo "$(GREEN)Other:$(NC)"
	@echo "  $(YELLOW)make version$(NC)      - Show version info"
	@echo "  $(YELLOW)make docs$(NC)         - Generate docs"
	@echo "  $(YELLOW)make help$(NC)         - Show this help"
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make run ARGS='scan --help'"
	@echo "  make run ARGS='scan --interactive'"
	@echo ""

