# NSClear 🧹

**NSClear** is an interactive CLI tool that finds, reviews, and safely removes unused Swift code.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[🇹🇷 Türkçe Döküman](README_TR.md)

## ✨ Features

- 🔍 **Smart Analysis**: Analyzes declarations and references using SwiftSyntax and IndexStoreDB
- 🎯 **Entry Point Detection**: Automatically detects `@main`, SwiftUI.App, UIApplicationMain, public API, and more
- 🔗 **Reachability Analysis**: Identifies code unreachable from entry points
- 📊 **Risk Scoring**: Calculates risk scores (0-100) for each finding
- 🛡️ **Safety Guards**: Automatically protects `@objc`, `dynamic`, `@IBAction`, `@IBOutlet`, and other special attributes
- 🎨 **Interactive TUI**: Terminal-based UI to review findings
- 🔧 **Safe Deletion**: Syntax-aware deletion using SwiftSyntax
- 🧪 **Test Integration**: Automatically runs tests after changes
- 🌲 **Git Integration**: Automatic branch creation, commit, and revert
- 📝 **Multiple Report Formats**: JSON, Text, Markdown, Xcode Diagnostics

## 📦 Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/NSClear/main/install.sh | sh
```

### Using Make

```bash
git clone https://github.com/yourusername/NSClear.git
cd NSClear
make install
```

### Manual Installation

```bash
git clone https://github.com/yourusername/NSClear.git
cd NSClear
swift build -c release
cp .build/release/nsclear /usr/local/bin/
```

### Requirements

- macOS 13.0+
- Xcode 15.0+
- Swift 6.0+

## 🚀 Quick Start

### For Xcode Projects

```bash
# 1. Build your project first (to generate index store)
xcodebuild -workspace MyApp.xcworkspace -scheme MyApp build

# 2. Run NSClear
nsclear scan --workspace MyApp.xcworkspace --scheme MyApp --interactive
```

### For SwiftPM Projects

```bash
# 1. Build with index store
swift build -Xswiftc -index-store-path -Xswiftc .build/index/store

# 2. Run NSClear
nsclear scan --package-path . --index-store-path .build/index/store --interactive
```

## 📖 Usage

### Basic Commands

#### `scan` - Analyze Code

```bash
# Scan only (no changes)
nsclear scan

# Interactive mode
nsclear scan --interactive

# Generate JSON report
nsclear scan --format json --write-report report.json

# Xcode diagnostics format
nsclear scan --format xcode

# Markdown report
nsclear scan --format markdown --write-report report.md
```

#### `apply` - Apply Changes

```bash
# Interactive mode with apply (recommended)
nsclear scan --interactive --apply

# Auto-apply (max risk 20)
nsclear apply --max-risk 20

# For specific workspace
nsclear apply --workspace MyApp.xcworkspace --scheme MyApp --max-risk 15
```

#### `report` - Generate Reports

```bash
# Generate text report from JSON
nsclear report report.json --format text

# Generate markdown report
nsclear report report.json --format markdown --output report.md
```

### Configuration

Create a `.nsclear.yml` file in your project root:

```yaml
# Excluded files
exclude:
  - "**/Tests/**"
  - "**/.build/**"

# Risk scoring
riskScoring:
  publicAPIWeight: 90
  objcDynamicWeight: 95
  privateHelperWeight: 10

# Protection rules
protections:
  protectObjC: true
  protectDynamic: true
  protectIB: true

# Auto-selection max risk
maxAutoSelectRisk: 20

# Testing
testing:
  runTests: true
  swiftTestCommand: "swift test"

# Git
git:
  autoCommit: true
  branchPrefix: "nsclear"
```

See [.nsclear.yml](.nsclear.yml) for a complete configuration example.

## 🎯 How It Works

1. **Syntax Analysis**: Parses all Swift files using SwiftSyntax and collects declarations
2. **Index Store Analysis**: Extracts symbol references and relationships using IndexStoreDB
3. **Entry Point Detection**: Identifies entry points like `@main`, SwiftUI.App, public API
4. **Reachability Analysis**: Determines reachable code starting from entry points
5. **Risk Scoring**: Calculates risk scores for each unused declaration
6. **Interactive Review**: User reviews and selects findings
7. **Safe Deletion**: Deletes selected declarations using SwiftSyntax
8. **Test & Commit**: Runs tests and commits if successful

## 🛡️ Safety Features

NSClear includes multiple safety mechanisms to protect critical code:

### Automatically Protected

- `@objc` and `dynamic` - Objective-C runtime access
- `@IBAction`, `@IBOutlet` - Interface Builder connections
- `@NSManaged` - Core Data properties
- `@inlinable`, `@usableFromInline` - ABI stability
- `@_cdecl` - C function exports
- `@_spi` - System Programming Interface
- SwiftUI Previews - Structs ending with `_Previews`
- Public/Open API (by default)

### Safe Operation Flow

1. **Dry-run by Default**: No changes without `--apply` flag
2. **Backup**: Automatic backup before changes
3. **Test Gate**: Changes reverted if tests fail
4. **Git Branch**: Changes made on new branch
5. **Interactive Confirmation**: Manual review of all changes

## 📊 Risk Scoring

Each finding receives a risk score from 0-100:

| Risk Level | Score | Description |
|-----------|-------|-------------|
| 🟢 Low | 0-19 | Private helpers, safe to delete |
| 🟡 Medium | 20-49 | Internal code, test code |
| 🟠 High | 50-79 | Public API, protocol implementations |
| 🔴 Very High | 80-100 | ObjC/dynamic, critical attributes |

Risk factors:
- Access level (private → open)
- Attributes (@objc, @IBAction, etc.)
- Modifiers (dynamic)
- Protocol requirement/witness status
- Reference count

## 🎨 Interactive TUI Commands

```
[t <num>]    - Toggle selection (e.g., 't 1' or 't 1-5' or 't all')
[v <num>]    - View details (e.g., 'v 1')
[d <num>]    - View diff (e.g., 'd 1')
[n]          - Next page
[p]          - Previous page
[a]          - Apply deletions
[q]          - Quit without applying
```

## 📝 Example Output

### Text Report

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                        NSClear - Analysis Report                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

📊 SUMMARY
────────────────────────────────────────────────────────────────────────────────
Date: Oct 8, 2025 at 10:30 AM
Total Declarations: 542
Unused: 47
Usage Rate: 91.3%
Analyzed Files: 23
Entry Points: 12

🎯 RISK DISTRIBUTION
────────────────────────────────────────────────────────────────────────────────
🟢 Low         : 32 items (68.1%)
🟡 Medium      : 10 items (21.3%)
🟠 High        : 4 items (8.5%)
🔴 Very High   : 1 item (2.1%)
```

### Interactive TUI

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                  NSClear - Unused Code Finder                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

📊 Total: 47 unused declarations found
✅ Selected: 32 declarations

1. [✓] 🟢 Function: unusedHelper
   📁 Sources/Utils/Helpers.swift:42
   💡 Not an entry point, no references
   🎯 Risk: 15/100 (Low)

2. [ ] 🟠 Class: LegacyViewController
   📁 Sources/UI/Legacy/LegacyViewController.swift:10
   💡 Not an entry point, 0 references
   🎯 Risk: 65/100 (High)

────────────────────────────────────────────────────────────────────────────────

🔧 Commands:
  [t <num>]    - Toggle selection
  [v <num>]    - View details
  [d <num>]    - View diff
  [a]          - Apply deletions
  [q]          - Quit
```

## 🧪 Testing

```bash
# Run unit tests
swift test

# Run with verbose output
swift test --verbose

# Or use Make
make test
```

## 🛠️ Development

### Using Make

```bash
# Build
make build

# Run tests
make test

# Install locally
make install

# Clean
make clean

# Show all commands
make help
```

### Manual Commands

```bash
# Build release
swift build -c release

# Build debug
swift build -c debug

# Run tests
swift test

# Format code (requires swiftformat)
swiftformat Sources/ Tests/

# Lint (requires swiftlint)
swiftlint
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code improvement
- `docs:` - Documentation
- `test:` - Adding/fixing tests
- `chore:` - Build, CI/CD, etc.

## 🐛 Known Issues and Limitations

1. **IndexStore Requirement**: Best results require index store
2. **SwiftUI Property Wrappers**: May produce false positives for @State, @Binding, etc.
3. **Objective-C Interop**: Swift code used from Objective-C may not be fully detected
4. **Reflection/Mirrors**: Code accessed via runtime reflection cannot be detected
5. **String-based Selectors**: Selector strings are not fully detected by static analysis

## 🗺️ Roadmap

See [ROADMAP.md](ROADMAP.md) for the detailed roadmap.

**Coming Soon:**
- Homebrew formula
- GitHub Action integration
- Xcode Source Editor Extension
- Web-based report viewer
- Incremental analysis
- ML-based false positive reduction

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [swift-syntax](https://github.com/apple/swift-syntax) - Swift parser and syntax tree
- [IndexStoreDB](https://github.com/apple/indexstore-db) - Index store access
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - CLI argument parsing
- [Yams](https://github.com/jpsim/Yams) - YAML parsing

## 📧 Contact

- Issues: [GitHub Issues](https://github.com/yourusername/NSClear/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/NSClear/discussions)

---

**Keep your Swift code clean with NSClear! 🧹✨**
