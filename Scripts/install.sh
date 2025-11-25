#!/bin/bash
set -e

echo "🚀 Installing tca-trace..."

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ tca-trace requires macOS"
    exit 1
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
REQUIRED_VERSION="14.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$MACOS_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ tca-trace requires macOS $REQUIRED_VERSION or later (found $MACOS_VERSION)"
    exit 1
fi

# Check for xcrace/xctrace availability
if ! command -v xcrun >/dev/null 2>&1; then
    echo "❌ Xcode command line tools not found"
    echo "Please install with: xcode-select --install"
    exit 1
fi

if ! xcrun xctrace --version >/dev/null 2>&1; then
    echo "❌ xctrace not available - please install Xcode"
    exit 1
fi

# 1. Build Swift CLI
echo "📦 Building tca-trace..."
swift build -c release

# 2. Install CLI to ~/.local/bin
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"
cp .build/release/tca-trace "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/tca-trace"

# 3. Create storage directory
STORAGE_DIR="$HOME/.tca-trace"
mkdir -p "$STORAGE_DIR/analyses"

# 4. Check if installation succeeded
if command -v tca-trace >/dev/null 2>&1; then
    echo "✅ tca-trace installed successfully!"
    echo ""
    echo "📍 Location: $INSTALL_DIR/tca-trace"
    echo "💾 Storage: $STORAGE_DIR"
    echo ""
    echo "Try it out:"
    echo "  tca-trace --help"
    echo "  tca-trace analyze /path/to/trace.trace"
    echo ""
    echo "📖 Documentation: https://github.com/smith-tools/tca-trace"
else
    echo "⚠️  Installation complete, but tca-trace not in PATH"
    echo "Add ~/.local/bin to your PATH:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Or run directly:"
    echo "  $INSTALL_DIR/tca-trace --help"
fi

# 5. Offer Claude Code skill installation
echo ""
read -p "📦 Install Claude Code skill? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔧 Deploying Claude Code skill..."
    ./deploy-skill.sh
fi

# 6. Verify installation
echo ""
echo "🔍 Verifying installation..."

# Test basic functionality
if tca-trace --version >/dev/null 2>&1; then
    echo "✅ CLI tool working"
else
    echo "❌ CLI tool failed"
    exit 1
fi

# Test storage
if [ -w "$STORAGE_DIR" ]; then
    echo "✅ Storage directory accessible"
else
    echo "❌ Storage directory not writable"
    exit 1
fi

# Test xctrace integration
if xcrun xctrace --version >/dev/null 2>&1; then
    echo "✅ xctrace integration working"
else
    echo "⚠️  xctrace integration not working - check Xcode installation"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Next steps:"
echo "1. Record a trace with Instruments using os_signpost instrument"
echo "2. Analyze it: tca-trace analyze your-trace.trace"
echo "3. View results in browser: tca-trace visualize your-trace.trace --open"
echo ""
echo "🔗 Learn more:"
echo "  • Recording guide: https://github.com/smith-tools/tca-trace/docs/RECORDING_GUIDE.md"
echo "  • Usage examples: https://github.com/smith-tools/tca-trace/docs/EXAMPLES.md"