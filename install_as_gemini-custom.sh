#!/usr/bin/env bash

#==============================================================================
# install_as_gemini-custom.sh
#
# Description:
#   Install gemini-cli fork as 'gemini-custom' command using npm link.
#   This script installs the custom version while preserving the existing
#   'gemini' command.
#
# Usage:
#   ./install_as_gemini-custom.sh [install|uninstall|status]
#
# Options:
#   install     Install gemini-custom command (default)
#   uninstall   Uninstall gemini-custom command
#   status      Check installation status
#   -h, --help  Show this help message
#
# Requirements:
#   - Node.js version 20 or higher
#   - npm
#
# Environment:
#   Supports both macOS and Linux
#==============================================================================

set -e

# Color output functions
print_red() {
    echo -e "\033[31m$*\033[0m"
}

print_green() {
    echo -e "\033[32m$*\033[0m"
}

print_yellow() {
    echo -e "\033[33m$*\033[0m"
}

print_blue() {
    echo -e "\033[34m$*\033[0m"
}

print_info() {
    print_blue "[INFO] $*"
}

print_success() {
    print_green "[SUCCESS] $*"
}

print_warning() {
    print_yellow "[WARNING] $*"
}

print_error() {
    print_red "[ERROR] $*"
}

# Show help
show_help() {
    cat << EOF
Install gemini-cli fork as 'gemini-custom' command

Usage:
  $0 [install|uninstall|status]

Commands:
  install     Install gemini-custom command (default)
  uninstall   Uninstall gemini-custom command
  status      Check installation status

Options:
  -h, --help  Show this help message

Requirements:
  - Node.js version 20 or higher
  - npm

Examples:
  # Install gemini-custom
  $0 install

  # Check installation status
  $0 status

  # Uninstall gemini-custom
  $0 uninstall
EOF
}

# Check Node.js version
check_node_version() {
    print_info "Checking Node.js version..."

    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        print_error "Please install Node.js version 20 or higher"
        print_error "Visit: https://nodejs.org/"
        exit 1
    fi

    local node_version=$(node --version | sed 's/v//')
    local major_version=$(echo "$node_version" | cut -d. -f1)

    print_info "Node.js version: $node_version"

    if [ "$major_version" -lt 20 ]; then
        print_error "Node.js version 20 or higher is required"
        print_error "Current version: $node_version"
        exit 1
    fi

    print_success "Node.js version check passed"
}

# Check npm availability
check_npm() {
    print_info "Checking npm availability..."

    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
        exit 1
    fi

    print_success "npm is available"
}

# Check if bundle exists
check_bundle() {
    print_info "Checking bundle file..."

    local bundle_path="$SCRIPT_DIR/bundle/gemini-custom.js"

    if [ ! -f "$bundle_path" ]; then
        print_error "Bundle file not found: $bundle_path"
        print_error "Please build the project first with: npm run bundle"
        exit 1
    fi

    local file_size=$(du -h "$bundle_path" | cut -f1)
    print_info "Bundle file size: $file_size"
    print_success "Bundle file exists"
}

# Check if gemini-custom is already installed
check_existing_installation() {
    if command -v gemini-custom &> /dev/null; then
        local existing_path=$(which gemini-custom)
        print_warning "gemini-custom is already installed at: $existing_path"

        # Try to get version
        local version=$(gemini-custom --version 2>/dev/null || echo "unknown")
        print_warning "Current version: $version"

        return 0
    else
        print_info "No existing gemini-custom installation found"
        return 1
    fi
}

# Install gemini-custom
install_gemini_custom() {
    print_info "Starting installation..."

    # Check dependencies
    check_node_version
    check_npm
    check_bundle

    # Check existing installation
    if check_existing_installation; then
        print_warning "Found existing gemini-custom installation"
        read -p "Do you want to overwrite it? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
        print_info "Proceeding with overwrite..."
    fi

    # Change to script directory
    cd "$SCRIPT_DIR"

    # Run npm link
    print_info "Running npm link..."
    if npm link; then
        print_success "npm link completed successfully"
    else
        print_error "npm link failed"
        exit 1
    fi

    # Verify installation
    print_info "Verifying installation..."
    if command -v gemini-custom &> /dev/null; then
        local installed_path=$(which gemini-custom)
        print_success "gemini-custom installed at: $installed_path"

        # Check version
        print_info "Checking gemini-custom version..."
        if gemini-custom --version &> /dev/null; then
            local version=$(gemini-custom --version 2>&1 | head -1)
            print_success "Version: $version"
        else
            print_warning "Could not retrieve version (this may be normal)"
        fi

        print_success "Installation completed successfully!"
        print_info ""
        print_info "You can now use: gemini-custom"
        print_info "Your existing 'gemini' command is preserved"
    else
        print_error "Installation verification failed"
        print_error "gemini-custom command is not available"
        exit 1
    fi
}

# Uninstall gemini-custom
uninstall_gemini_custom() {
    print_info "Starting uninstallation..."

    # Check if installed
    if ! check_existing_installation; then
        print_warning "gemini-custom is not installed"
        print_info "Nothing to uninstall"
        exit 0
    fi

    # Change to script directory
    cd "$SCRIPT_DIR"

    # Run npm unlink
    print_info "Running npm unlink..."
    if npm unlink -g @google/gemini-cli 2>/dev/null || true; then
        print_success "npm unlink completed"
    fi

    # Verify uninstallation
    print_info "Verifying uninstallation..."
    if command -v gemini-custom &> /dev/null; then
        print_warning "gemini-custom command still exists"
        local path=$(which gemini-custom)
        print_warning "Located at: $path"
        print_warning "You may need to remove it manually"
    else
        print_success "gemini-custom has been removed"
        print_success "Uninstallation completed successfully!"
    fi
}

# Check installation status
check_status() {
    print_info "Checking gemini-custom installation status..."
    print_info ""

    # Check Node.js
    if command -v node &> /dev/null; then
        print_success "Node.js: $(node --version)"
    else
        print_error "Node.js: Not installed"
    fi

    # Check npm
    if command -v npm &> /dev/null; then
        print_success "npm: $(npm --version)"
    else
        print_error "npm: Not installed"
    fi

    print_info ""

    # Check gemini-custom
    if command -v gemini-custom &> /dev/null; then
        print_success "gemini-custom: Installed"
        print_info "  Path: $(which gemini-custom)"

        if gemini-custom --version &> /dev/null; then
            local version=$(gemini-custom --version 2>&1 | head -1)
            print_info "  Version: $version"
        fi
    else
        print_warning "gemini-custom: Not installed"
    fi

    # Check original gemini
    if command -v gemini &> /dev/null; then
        print_success "gemini (original): Installed"
        print_info "  Path: $(which gemini)"
    else
        print_warning "gemini (original): Not installed"
    fi

    # Check bundle
    print_info ""
    local bundle_path="$SCRIPT_DIR/bundle/gemini-custom.js"
    if [ -f "$bundle_path" ]; then
        local file_size=$(du -h "$bundle_path" | cut -f1)
        print_success "Bundle file: Exists ($file_size)"
        print_info "  Path: $bundle_path"
    else
        print_error "Bundle file: Not found"
        print_info "  Expected path: $bundle_path"
    fi
}

# Main
main() {
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Parse command
    local command="${1:-install}"

    case "$command" in
        install)
            install_gemini_custom
            ;;
        uninstall)
            uninstall_gemini_custom
            ;;
        status)
            check_status
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown command: $command"
            print_error "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
