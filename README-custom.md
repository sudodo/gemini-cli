# gemini-custom Installation Guide

This directory contains a fork of [Gemini CLI](https://github.com/google-gemini/gemini-cli) that can be installed as `gemini-custom` command, allowing you to use both the official `gemini` and this custom version simultaneously.

## Quick Start

```bash
# Install gemini-custom
./install_as_gemini-custom.sh install

# Check installation status
./install_as_gemini-custom.sh status

# Uninstall gemini-custom
./install_as_gemini-custom.sh uninstall
```

## Installation Script: install_as_gemini-custom.sh

### Purpose

Install the gemini-cli fork as `gemini-custom` command while preserving the existing `gemini` command. This script uses npm link to create a global command that coexists with the official Gemini CLI.

### Requirements

- **Node.js**: Version 20 or higher
- **npm**: Included with Node.js
- **Pre-built bundle**: `bundle/gemini-custom.js` (already included)

### Features

- ✅ Install/uninstall gemini-custom command
- ✅ Check installation status
- ✅ Verify Node.js version (requires v20+)
- ✅ Detect and handle existing installations
- ✅ Interactive overwrite confirmation
- ✅ Cross-platform support (macOS and Linux)
- ✅ Colored output for better user experience
- ✅ Comprehensive error messages

### Usage

#### Install

```bash
./install_as_gemini-custom.sh install
```

**Example Output:**
```
[INFO] Starting installation...
[INFO] Checking Node.js version...
[INFO] Node.js version: 20.19.5
[SUCCESS] Node.js version check passed
[INFO] Checking npm availability...
[SUCCESS] npm is available
[INFO] Checking bundle file...
[INFO] Bundle file size: 12M
[SUCCESS] Bundle file exists
[INFO] No existing gemini-custom installation found
[INFO] Running npm link...
[SUCCESS] npm link completed successfully
[INFO] Verifying installation...
[SUCCESS] gemini-custom installed at: /usr/local/bin/gemini-custom
[INFO] Checking gemini-custom version...
[SUCCESS] Version: 0.1.16-PR3315
[SUCCESS] Installation completed successfully!

[INFO]
[INFO] You can now use: gemini-custom
[INFO] Your existing 'gemini' command is preserved
```

#### Check Status

```bash
./install_as_gemini-custom.sh status
```

**Example Output:**
```
[INFO] Checking gemini-custom installation status...

[SUCCESS] Node.js: v20.19.5
[SUCCESS] npm: 10.9.2

[SUCCESS] gemini-custom: Installed
  Path: /usr/local/bin/gemini-custom
  Version: 0.1.16-PR3315
[SUCCESS] gemini (original): Installed
  Path: /usr/local/bin/gemini

[SUCCESS] Bundle file: Exists (12M)
  Path: /workspace/script/gemini-cli-sudodo/bundle/gemini-custom.js
```

#### Uninstall

```bash
./install_as_gemini-custom.sh uninstall
```

**Example Output:**
```
[INFO] Starting uninstallation...
[WARNING] gemini-custom is already installed at: /usr/local/bin/gemini-custom
[WARNING] Current version: 0.1.16-PR3315
[INFO] Running npm unlink...
[SUCCESS] npm unlink completed
[INFO] Verifying uninstallation...
[SUCCESS] gemini-custom has been removed
[SUCCESS] Uninstallation completed successfully!
```

#### Show Help

```bash
./install_as_gemini-custom.sh --help
```

### Installation Method

This script uses **npm link**, which creates a symbolic link from the global npm binaries directory to your local project's bundle file.

**Advantages:**
- Preserves the existing `gemini` command
- Allows updates by rebuilding the bundle
- Can be easily uninstalled with `npm unlink`
- Standard Node.js package management approach

**Requirements:**
- The project directory must remain in place
- Bundle file (`bundle/gemini-custom.js`) must exist

### Options

| Command | Description |
|---------|-------------|
| `install` | Install gemini-custom command (default) |
| `uninstall` | Uninstall gemini-custom command |
| `status` | Check installation status |
| `-h, --help` | Show help message |

## Troubleshooting

### Problem: `gemini-custom: command not found` after installation

**Solution**: Check that npm's global bin directory is in your PATH:

```bash
# Check npm global bin directory
npm config get prefix

# Add to PATH if needed (add to ~/.bashrc or ~/.zshrc)
export PATH="$(npm config get prefix)/bin:$PATH"
```

### Problem: Permission denied during npm link

**Solution**: Configure npm to use a user-writable directory (recommended):

```bash
# Create a directory for global packages
mkdir -p ~/.npm-global

# Configure npm to use the new directory
npm config set prefix '~/.npm-global'

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.npm-global/bin:$PATH"

# Reload your shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

**Alternative** (not recommended): Use sudo

```bash
sudo ./install_as_gemini-custom.sh install
```

### Problem: Installation succeeds but version check fails

**Solution**: This may be normal. The `--version` flag behavior depends on the gemini-cli implementation. Check if the command is available:

```bash
which gemini-custom
# Should output: /usr/local/bin/gemini-custom (or similar)

# Try running the command directly
gemini-custom
```

### Problem: Bundle file not found

**Error Message:**
```
[ERROR] Bundle file not found: /path/to/bundle/gemini-custom.js
[ERROR] Please build the project first with: npm run bundle
```

**Solution**: The bundle file needs to be built first. Run:

```bash
# Install dependencies
npm install

# Build the bundle
npm run bundle

# Then retry installation
./install_as_gemini-custom.sh install
```

### Problem: Node.js version too old

**Error Message:**
```
[ERROR] Node.js version 20 or higher is required
[ERROR] Current version: 18.x.x
```

**Solution**: Upgrade Node.js to version 20 or higher:

```bash
# Using nvm (recommended)
nvm install 20
nvm use 20

# Or download from https://nodejs.org/
```

## Testing

A comprehensive test suite is available to verify the installation script functionality.

### Test Location

```
script/test/test_install_as_gemini_custom/run_tests.sh
```

### Running Tests

```bash
# From the repository root
script/test/test_install_as_gemini_custom/run_tests.sh
```

### Test Coverage

The test suite verifies:
1. Script exists and is executable
2. Help message displays correctly
3. Status check functionality works
4. Bundle file exists with correct format
5. Invalid command handling
6. Node.js version detection
7. Package.json configuration

**Example Test Output:**
```
========================================
install_as_gemini-custom.sh Test Suite
========================================

[INFO] Running: Script file exists and is executable
✓ PASS: Script file exists
✓ PASS: Script is executable

[INFO] Running: Help message display
✓ PASS: Help message displays without error
✓ PASS: Help contains 'Usage:' section
✓ PASS: Help contains 'install' command

...

========================================
Test Summary
========================================
Tests run:    7
Tests passed: 17
Tests failed: 0

ALL TESTS PASSED
```

## Technical Details

### Files Modified for Custom Command

The following files have been configured to use `gemini-custom` instead of `gemini`:

1. **package.json** - bin field:
   ```json
   "bin": {
     "gemini-custom": "bundle/gemini-custom.js"
   }
   ```

2. **Bundle output** - Already built as:
   ```
   bundle/gemini-custom.js
   ```

### How npm link Works

When you run `npm link`:
1. Creates a symlink in the global npm bin directory
2. Points to the local `bundle/gemini-custom.js` file
3. Makes `gemini-custom` available system-wide
4. Does not affect existing `gemini` command

### Verification Steps Performed

The installation script performs these checks:
1. ✅ Node.js version ≥ 20
2. ✅ npm is available
3. ✅ Bundle file exists and is valid
4. ✅ Detects existing installations
5. ✅ Confirms before overwriting
6. ✅ Verifies command availability after install
7. ✅ Attempts to run `--version` for validation

## Development

### Building from Source

If you need to rebuild the bundle:

```bash
# Install dependencies
npm install

# Build packages
npm run build

# Create bundle
npm run bundle

# Install the custom command
./install_as_gemini-custom.sh install
```

### Updating the Custom Version

To update after making changes:

```bash
# Rebuild the bundle
npm run bundle

# The npm link will automatically use the new bundle
# No need to reinstall
```

### Uninstalling Before Cleanup

If you plan to delete this directory:

```bash
# Uninstall first to remove the symlink
./install_as_gemini-custom.sh uninstall

# Then you can safely delete the directory
```

## Related Files

- **Installation script**: `install_as_gemini-custom.sh`
- **Bundle file**: `bundle/gemini-custom.js`
- **Package config**: `package.json`
- **Test suite**: `../test/test_install_as_gemini_custom/run_tests.sh`
- **Original README**: `README.md`

## Links

- **Original Gemini CLI**: https://github.com/google-gemini/gemini-cli
- **Official Documentation**: https://github.com/google-gemini/gemini-cli/tree/main/docs
- **Issue Tracker**: https://github.com/sudodo/Obsidian2/issues

## License

This fork maintains the same license as the original Gemini CLI project. See `LICENSE` file for details.
