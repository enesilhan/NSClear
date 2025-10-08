#!/bin/bash
#
# NSClear Installation Script
# This script installs NSClear to your system
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="nsclear"
REPO_URL="https://github.com/yourusername/NSClear.git"
TEMP_DIR="/tmp/nsclear-install-$$"

# Helper functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}              NSClear Installation Script              ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script only works on macOS"
        exit 1
    fi
    print_success "macOS detected"
}

# Check if Swift is installed
check_swift() {
    if ! command -v swift &> /dev/null; then
        print_error "Swift is not installed"
        print_info "Please install Xcode or Swift toolchain from https://swift.org"
        exit 1
    fi
    
    local swift_version=$(swift --version | head -n 1)
    print_success "Swift found: $swift_version"
}

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed"
        print_info "Please install Git from https://git-scm.com"
        exit 1
    fi
    print_success "Git found"
}

# Build NSClear
build_nsclear() {
    print_info "Building NSClear..."
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Clone or use local source
    if [ -d "$1" ]; then
        print_info "Using local source from: $1"
        cp -r "$1" .
        cd NSClear
    else
        print_info "Cloning from repository..."
        git clone "$REPO_URL" NSClear
        cd NSClear
    fi
    
    # Build in release mode
    print_info "Compiling (this may take a few minutes)..."
    swift build -c release > /dev/null 2>&1
    
    print_success "Build complete"
}

# Install binary
install_binary() {
    print_info "Installing to $INSTALL_DIR..."
    
    local binary_path=".build/release/$BINARY_NAME"
    
    if [ ! -f "$binary_path" ]; then
        print_error "Binary not found at $binary_path"
        exit 1
    fi
    
    # Check if we need sudo
    if [ ! -w "$INSTALL_DIR" ]; then
        print_warning "Need sudo privileges to install to $INSTALL_DIR"
        sudo cp "$binary_path" "$INSTALL_DIR/$BINARY_NAME"
        sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
    else
        cp "$binary_path" "$INSTALL_DIR/$BINARY_NAME"
        chmod +x "$INSTALL_DIR/$BINARY_NAME"
    fi
    
    print_success "Installed to $INSTALL_DIR/$BINARY_NAME"
}

# Cleanup
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_info "Cleaning up..."
        rm -rf "$TEMP_DIR"
        print_success "Cleanup complete"
    fi
}

# Verify installation
verify_installation() {
    if command -v $BINARY_NAME &> /dev/null; then
        local version=$($BINARY_NAME --version 2>&1 || echo "unknown")
        print_success "NSClear installed successfully!"
        echo ""
        print_info "Version: $version"
        print_info "Location: $(which $BINARY_NAME)"
        echo ""
        print_info "Get started with: $BINARY_NAME --help"
        echo ""
        return 0
    else
        print_error "Installation verification failed"
        print_info "Binary not found in PATH"
        return 1
    fi
}

# Uninstall function
uninstall() {
    print_header
    print_info "Uninstalling NSClear..."
    
    if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
        if [ ! -w "$INSTALL_DIR" ]; then
            sudo rm "$INSTALL_DIR/$BINARY_NAME"
        else
            rm "$INSTALL_DIR/$BINARY_NAME"
        fi
        print_success "NSClear uninstalled successfully"
    else
        print_warning "NSClear not found at $INSTALL_DIR/$BINARY_NAME"
    fi
    
    exit 0
}

# Main installation flow
main() {
    # Parse arguments
    local source_dir=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --uninstall)
                uninstall
                ;;
            --source)
                source_dir="$2"
                shift 2
                ;;
            --help)
                echo "NSClear Installation Script"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --help              Show this help message"
                echo "  --uninstall         Uninstall NSClear"
                echo "  --source DIR        Install from local source directory"
                echo ""
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_info "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Show header
    print_header
    
    # Pre-flight checks
    print_info "Running pre-flight checks..."
    check_macos
    check_swift
    check_git
    echo ""
    
    # Build and install
    print_info "Starting installation..."
    echo ""
    
    # Trap to ensure cleanup on exit
    trap cleanup EXIT
    
    build_nsclear "$source_dir"
    install_binary
    
    echo ""
    verify_installation
}

# Run main function
main "$@"

