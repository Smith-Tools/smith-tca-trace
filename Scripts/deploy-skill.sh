#!/bin/bash
set -e

echo "📦 Deploying Claude Code skill..."

# Check if Claude Code is installed
if ! command -v claude >/dev/null 2>&1; then
    echo "❌ Claude Code not found"
    echo "Please install Claude Code first: https://claude.ai/code"
    exit 1
fi

# Check if Claude Code skill directory exists
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
if [ ! -d "$CLAUDE_SKILLS_DIR" ]; then
    echo "📁 Creating Claude skills directory..."
    mkdir -p "$CLAUDE_SKILLS_DIR"
fi

SKILL_DIR="$CLAUDE_SKILLS_DIR/tca-trace"

# 1. Build release binary
echo "🔨 Building tca-trace..."
swift build -c release

# 2. Create skill directory structure
echo "📁 Creating skill directory..."
rm -rf "$SKILL_DIR"
mkdir -p "$SKILL_DIR/scripts"

# 3. Copy executable and wrapper
echo "📋 Installing skill files..."
cp .build/release/tca-trace "$SKILL_DIR/scripts/"
cp Skill/tca-trace.sh "$SKILL_DIR/scripts/tca-trace"
chmod +x "$SKILL_DIR/scripts/tca-trace"

# 4. Copy skill manifest
cp Skill/SKILL.md "$SKILL_DIR/"

# 5. Create a simple test script
cat > "$SKILL_DIR/test-skill.sh" << 'EOF'
#!/bin/bash
echo "Testing tca-trace skill..."

# Test basic help
if ./scripts/tca-trace --help >/dev/null 2>&1; then
    echo "✅ Skill basic functionality working"
else
    echo "❌ Skill not working"
    exit 1
fi

echo "✅ tca-trace skill deployed successfully!"
echo ""
echo "You can now use tca-trace from Claude Code:"
echo "- 'Analyze this Instruments trace'"
echo '- "Profile my TCA app"'
echo '- "Find performance bottlenecks in TCA"'
EOF

chmod +x "$SKILL_DIR/test-skill.sh"

# 6. Test the skill
echo "🧪 Testing skill installation..."
"$SKILL_DIR/test-skill.sh"

# 7. Success message
echo ""
echo "🎉 Claude Code skill deployed successfully!"
echo ""
echo "Skill location: $SKILL_DIR"
echo ""
echo "Usage in Claude Code:"
echo "  • 'Analyze this TCA trace'"
echo "  • 'Why is my reducer slow?'"
echo "  • 'Profile my TCA app performance'"
echo "  • 'Find TCA bottlenecks'"
echo ""
echo "The skill will automatically activate for TCA-related questions."

# 8. Show integration examples
echo ""
echo "📚 Integration Examples:"
echo ""
echo "1. Performance Analysis:"
echo "   User: 'My app feels sluggish, can you help?'"
echo "   Claude: [Activates tca-trace] Analyzes your trace file"
echo ""
echo "2. Regression Detection:"
echo "   User: 'After the update, scrolling is slower'"
echo "   Claude: Compares before/after traces"
echo ""
echo "3. Architecture Review:"
echo "   User: 'Is this TCA implementation efficient?'"
echo "   Claude: Analyzes action flow and provides recommendations"