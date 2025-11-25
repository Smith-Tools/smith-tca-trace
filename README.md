# tca-trace

> Modern Swift 6+ CLI tool for TCA performance profiling, regression detection, and AI-agent analysis

`tca-trace` analyzes The Composable Architecture (TCA) applications using Instruments traces to identify performance bottlenecks, complexity issues, and provide actionable recommendations.

![Build Status](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2014+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

- **🔍 Comprehensive Analysis**: Extracts TCA actions, effects, and shared state changes from Instruments traces
- **📊 Complexity Scoring**: 0-100 scale scoring algorithm based on slow actions, state churn, and rendering
- **🤖 AI-Optimized**: Token-efficient output modes (30-40% reduction vs full trace data)
- **📈 Regression Detection**: Compare traces to identify performance regressions and improvements
- **🎨 Interactive Visualizations**: HTML timeline and music-sequencer style views
- **💾 File-Based Storage**: JSON storage for historical analysis and trending
- **⚡ Swift 6+**: Modern Swift concurrency, strict memory safety, and optimal performance

## 🚀 Quick Start

### Installation

```bash
# Clone and install
git clone https://github.com/smith-tools/tca-trace
cd tca-trace
./Scripts/install.sh

# Or install with Homebrew (coming soon)
brew install smith-tools/tca-trace
```

### Basic Usage

```bash
# Analyze a trace file
tca-trace analyze my-app.trace

# Generate interactive visualization
tca-trace visualize my-app.trace --open

# Compare for regressions
tca-trace compare baseline.trace current.trace

# View analysis history
tca-trace history --detailed
```

## 📊 Output Modes

`tca-trace` provides three output modes optimized for different use cases:

### Compact Mode (Default for AI)
```bash
tca-trace analyze trace.trace
# Returns: ~200-500 tokens (70-85% reduction)
{
  "summary": {
    "totalActions": 47,
    "slowActionsCount": 3,
    "complexityScore": 32.5,
    "avgDuration": 8.2,
    "maxDuration": 67.4
  },
  "slowActions": [
    {"feature": "ReadingLibrary", "action": "loadArticles", "duration": 67.4}
  ],
  "recommendations": ["🐌 ReadingLibrary.loadArticles takes 67.4ms..."]
}
```

### Agent Mode (Complete Data)
```bash
tca-trace analyze trace.trace --mode agent
# Returns: ~2000-5000 tokens (full trace data)
```

### User Mode (Human-Friendly)
```bash
tca-trace analyze trace.trace --mode user
# Returns: Formatted markdown with emojis and sections
```

## 🎯 Claude Code Integration

`tca-trace` includes a Claude Code skill for seamless AI-powered analysis:

```bash
# Deploy the skill
./Scripts/deploy-skill.sh

# Now in Claude Code:
User: "Analyze this TCA trace"
Claude: [Activates tca-trace skill] Analyzing trace...
```

## 📈 Typical Workflow

1. **Record a Trace**
   ```bash
   # Using Instruments with os_signpost instrument
   # Or use the helper command:
   tca-trace record --app MyApp --duration 30
   ```

2. **Analyze Performance**
   ```bash
   tca-trace analyze my-app.trace --save baseline
   ```

3. **Identify Issues**
   ```bash
   tca-trace visualize my-app.trace --open
   ```

4. **Compare After Changes**
   ```bash
   tca-trace compare baseline.trace my-app-v2.trace
   ```

## 🔧 Configuration

### Environment Variables

```bash
# Default output mode for skill usage
export TCA_TRACE_MODE="compact"

# Custom storage location
export TCA_TRACE_STORAGE_DIR="~/.tca-trace"
```

### Signpost Integration

Add TCA signposts to your app:

```swift
import os.log

let tcaLog = OSLog(subsystem: "com.myapp", category: "TCA")

// In your reducers
os_signpost(.begin, log: tcaLog, name: "%{public}s", "\(FeatureName).\(actionName)")
// ... reducer logic ...
os_signpost(.end, log: tcaLog, name: "%{public}s", "\(FeatureName).\(actionName)")
```

## 📊 Advanced Features

### Progressive Disclosure

`tca-trace` supports efficient progressive disclosure for AI agents:

```bash
# Step 1: Get overview
tca-trace analyze trace.trace

# Step 2: Drill down if needed
tca-trace analyze trace.trace --filter "FeatureName" --mode agent

# Step 3: Get full trace only when necessary
tca-trace analyze trace.trace --mode agent
```

### Custom Filtering

```bash
# Filter by feature
tca-trace analyze trace.trace --feature ReadingLibrary

# Filter slow actions only
tca-trace analyze trace.trace --slow-only

# Filter by duration threshold
tca-trace analyze trace.trace --min-duration 0.1  # 100ms+
```

### Storage and History

```bash
# Save analysis for later comparison
tca-trace analyze trace.trace --save "feature-xyz" --tags feature,performance

# Search saved analyses
tca-trace history --tag performance
tca-trace history --name feature-xyz

# Storage statistics
tca-trace stats --detailed
```

## 📚 Documentation

- [📖 Recording Guide](docs/RECORDING_GUIDE.md) - How to record TCA traces
- [🔧 API Reference](docs/API.md) - Complete API documentation
- [💡 Examples](docs/EXAMPLES.md) - Real-world usage examples
- [🏗️ Architecture](docs/ARCHITECTURE.md) - Technical architecture
- [🤝 Contributing](CONTRIBUTING.md) - Development guidelines

## 🏗️ Architecture

`tca-trace` follows a modular architecture:

```
tca-trace/
├── Sources/TCATrace/
│   ├── Commands/          # CLI commands
│   ├── Models/           # Data structures
│   ├── Parsing/          # Trace parsing
│   ├── Analysis/         # Analysis engines
│   ├── Comparison/       # Regression detection
│   ├── Output/           # Formatting modes
│   ├── Storage/          # File-based storage
│   └── Visualization/    # HTML generation
├── Skill/                # Claude Code integration
├── Resources/            # HTML templates
└── Scripts/              # Installation scripts
```

## 🎯 Performance

### Token Efficiency
- **Compact mode**: 30-40% token reduction vs full trace
- **Progressive disclosure**: Load details on-demand
- **AI-optimized defaults**: Compact mode for skill usage

### Processing Speed
- **Fast parsing**: Native Swift 6+ with async/await
- **Memory efficient**: Streaming parsing for large traces
- **Parallel processing**: Concurrent analysis where possible

## 🛠️ Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/smith-tools/tca-trace
cd tca-trace

# Build
swift build -c release

# Run tests
swift test

# Install
swift build -c release
cp .build/release/tca-trace ~/.local/bin/
```

### Requirements

- **macOS 14.0+** (for modern Swift 6 features)
- **Xcode 15.0+** (for xctrace integration)
- **Swift 6.0+** (for strict concurrency)

### Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure Swift 6 compliance
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Acknowledgments

- **Apple Instruments** for trace export functionality
- **The Composable Architecture** community for use cases and feedback
- **Swift Argument Parser** for CLI framework
- **Smith Tools** ecosystem integration

## 📞 Support

- **Documentation**: [https://github.com/smith-tools/tca-trace](https://github.com/smith-tools/tca-trace)
- **Issues**: [GitHub Issues](https://github.com/smith-tools/tca-trace/issues)
- **Discussions**: [GitHub Discussions](https://github.com/smith-tools/tca-trace/discussions)

---

**Built with ❤️ by the Smith Tools team**