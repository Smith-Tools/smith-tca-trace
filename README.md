# 🚀 smith-tca-trace

**TCA performance profiling and analysis tool** - The Composable Architecture performance profiler for Apple Instruments traces with multi-instrument enrichment.

## 📋 Overview

`smith-tca-trace` is a command-line tool that analyzes The Composable Architecture (TCA) applications using Instruments traces to identify performance bottlenecks, complexity issues, and provide actionable recommendations. It extracts TCA-specific signposts and generates comprehensive performance reports with multi-instrument data enrichment.

### ✨ Key Features

- **🔍 Generic TCA Detection**: Works with any TCA app using Point-Free's signpost instrumentation patterns
- **📊 Multi-Format Output**: JSON (compact/user/agent), Markdown, and HTML visualization support
- **🏗️ TCA-Focused Insights**: State mutations, actions, side effects, and dependencies analysis
- **⚡ Performance Metrics**: Action distribution, effect-to-action ratios, complexity scoring
- **🎯 Smart Recommendations**: TCA-specific optimization advice (@Dependency, debouncing, caching)
- **🔬 Multi-Instrument Enrichment**: CPU profiling, system call analysis, and memory tracking with automatic correlation to TCA actions/effects
- **💾 Analysis Management**: Save, compare, and manage multiple trace analyses
- **🎯 Progressive Disclosure**: Token-optimized outputs for AI agents with detailed expansion options

## 🛠️ Installation

### Homebrew Installation (Recommended)

```bash
brew tap Smith-Tools/smith
brew install smith-tca-trace
```

### Manual Installation

```bash
# Build from source
cd smith-tca-trace
swift build -c release

# Install to PATH
mkdir -p ~/.local/bin
cp .build/arm64-apple-macosx/release/smith-tca-trace ~/.local/bin/
chmod +x ~/.local/bin/smith-tca-trace

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Prerequisites

- **macOS 14+** (for Instruments integration)
- **Xcode** (for xctrace tool)
- **Swift 6.0+**

## 🚀 Quick Start

### Basic Usage

```bash
# Analyze a trace file (compact JSON output - optimized for AI agents)
smith-tca-trace analyze /path/to/trace.trace

# Generate human-friendly report
smith-tca-trace analyze /path/to/trace.trace --mode user

# Generate HTML visualization
smith-tca-trace visualize /path/to/trace.trace --open

# Compare two traces
smith-tca-trace compare before.trace after.trace

# Save analysis for later comparison
smith-tca-trace analyze /path/to/trace.trace --save --name "baseline"
```

### Example Workflow

```bash
# 1. Record Instruments trace with TCA signposts
xctrace record --template "Time Profiler" --launch appname.app

# 2. Quick analysis (compact output for AI agents)
smith-tca-trace analyze trace.trace

# 3. Detailed human-readable analysis
smith-tca-trace analyze trace.trace --mode user --format markdown

# 4. Interactive HTML visualization
smith-tca-trace visualize trace.trace --open

# 5. Compare against baseline
smith-tca-trace compare baseline.trace current.trace
```

## 📖 Usage Workflows

### Workflow 1: Quick Terminal Analysis (Default)

**Scenario**: You have a trace file and want a quick performance summary.

```bash
# Default compact mode (~30-40% token reduction for AI agents)
smith-tca-trace analyze MyApp.trace

# Output format:
{
  "slowActions": [
    {"feature": "ReadingLibrary", "action": "reader(.task)", "duration": 7462.2}
  ],
  "summary": {
    "totalActions": 128,
    "complexityScore": 33.1,
    "avgDuration": 97.9
  }
}
```

### Workflow 2: Human-Friendly Analysis

**Scenario**: You need a readable report for documentation or team sharing.

```bash
# Human-friendly markdown output
smith-tca-trace analyze MyApp.trace --mode user --format markdown > analysis.md

# Human-friendly JSON output
smith-tca-trace analyze MyApp.trace --mode user --format json > analysis.json
```

### Workflow 3: Complete Analysis (Agent Mode)

**Scenario**: You need all data for automation or detailed investigation.

```bash
# Complete structured data for automation
smith-tca-trace analyze MyApp.trace --mode agent --format json > complete-analysis.json

# Complete analysis with all details (~3000 tokens)
smith-tca-trace analyze MyApp.trace --mode agent
```

### Workflow 4: Interactive HTML Visualization

**Scenario**: You want to understand TCA performance visually.

```bash
# Generate interactive HTML dashboard
smith-tca-trace visualize MyApp.trace --output dashboard.html --open

# Generate comparison dashboard
smith-tca-trace visualize baseline.trace current.trace --type comparison --open
```

### Workflow 5: Multi-Instrument Enrichment Analysis

**Scenario**: You want deep performance insights with CPU, memory, and I/O data.

```bash
# Analysis automatically includes multi-instrument enrichment when available
smith-tca-trace analyze MyApp.trace --mode user

# Example enriched output:
# - ReadingLibrary.reader(.task): 7462.2ms | CPU: Timer Fired(42%), Wait: kevent | Alloc: +32.0 KB
```

### Workflow 6: Baseline Management and Regression Detection

**Scenario**: You want to track performance over time and detect regressions.

```bash
# Save baseline
smith-tca-trace analyze v1.0.trace --save --name "v1.0-baseline" --tags "production,baseline"

# Save current version
smith-tca-trace analyze v2.0.trace --save --name "v2.0-current" --tags "current"

# Compare for regressions
smith-tca-trace compare v1.0-baseline v2.0-current

# List saved analyses
smith-tca-trace history

# Search for specific analyses
smith-tca-trace history --tag production
```

### Workflow 7: Feature-Specific Analysis

**Scenario**: Your app has multiple features and you want to profile just one.

```bash
# Analyze only ReadingLibrary feature
smith-tca-trace analyze MyApp.trace --feature ReadingLibrary

# Filter by specific action name
smith-tca-trace analyze MyApp.trace --filter "loadArticle" --slow-only

# Filter by minimum duration
smith-tca-trace analyze MyApp.trace --min-duration 0.1  # 100ms minimum
```

## 🧠 Claude Code Integration

smith-tca-trace is available as a Claude Code skill for TCA performance analysis.

### Activation Triggers

The skill automatically activates when you ask about:
- "Analyze my TCA trace"
- "Why is my reducer slow?"
- "What's the performance bottleneck?"
- "Profile my TCA app"
- "Show me the complexity score"
- "Detect performance regressions"

### Usage Examples in Claude Code

```
You: "Analyze this TCA trace for me: /path/to/MyApp.trace"

Claude: [Activates smith-tca-trace skill]
smith-tca-trace analyze /path/to/MyApp.trace

🔍 Analysis Results:
━━━━━━━━━━━━━━━━━━
📊 Overview:
   • Total Actions: 128
   • Slow Actions: 10 (>16ms)
   • Complexity Score: 33/100 (🟡 Good)
   • Avg Duration: 97.9ms

⚠️ Performance Issues:
   • ReadingLibrary.reader(.task): 7462.2ms | CPU: Timer Fired(42%), Wait: kevent | Alloc: +32.0 KB
   • ReadingLibrary.reader(.cacheLoaded): 3023.1ms | CPU: Running(85%), Wait: cpu | Alloc: +64.5 KB

✅ Recommendations:
   • Investigate timer-heavy code in ReadingLibrary.reader(.task)
   • Consider caching for ReadingLibrary.reader(.cacheLoaded)
```

## 📊 Output Formats

### JSON Formats

**Compact (Default)**: Token-optimized for AI agents (30-40% reduction)
- Only slow actions (>16ms) and long effects (>500ms)
- Top features by action count
- Essential metrics and recommendations

**User**: Human-friendly with enrichment summaries
- Slow actions with enrichment details
- Top features with performance metrics
- Formatted durations and readable summaries

**Agent**: Complete structured data
- All actions, effects, and state changes
- Full enrichment data
- Detailed metrics and analysis

### Markdown Format

Human-readable reports with enrichment:
```markdown
# TCA Analysis: MyApp
Score: 33/100 | Actions: 128 (10 slow) | Avg: 97.9ms

Slow Actions:
• ReadingLibrary.reader(.task): 7462.2ms | CPU: Timer Fired(42%), Wait: kevent | Alloc: +32.0 KB
• ReadingLibrary.reader(.cacheLoaded): 3023.1ms | CPU: Running(85%), Wait: cpu | Alloc: +64.5 KB
```

### HTML Visualization

Interactive dashboards with:
- Performance metrics overview
- Action and effect analysis
- Enrichment data visualization
- Timeline and distribution charts

## 🔬 Multi-Instrument Data Enrichment

smith-tca-trace automatically extracts and correlates data from multiple Instruments when available:

### Time Profiler → CPU Thread States
- Extracts thread states (Running, Blocked, etc.) for each TCA action/effect
- Shows CPU vs I/O-bound operations
- Identifies dominant thread states

### System Call Trace → I/O Wait States
- Identifies blocking system calls (kevent, futex, read, write, mach_msg)
- Classifies dominant wait types per action
- Helps identify I/O vs CPU bottlenecks

### Allocations → Memory Impact
- Tracks memory allocated/freed during actions
- Computes delta per time window
- Shows memory pressure correlation with slow actions

### Enrichment Example Output

```json
{
  "slowActions": [{
    "feature": "ReadingLibrary",
    "action": "reader(.task)",
    "duration": "7462.2",
    "enrichment": {
      "topSymbols": [
        {"symbol": "Timer Fired", "percent": 42.1},
        {"symbol": "Running", "percent": 35.8}
      ],
      "waitState": "kevent",
      "allocationDelta": 32768,
      "summary": "CPU: Timer Fired(42%), Wait: kevent | Alloc: +32.0 KB"
    }
  }]
}
```

### Using Enrichment Data

**CPU-bound actions** (waitState: "cpu"):
- Optimize algorithms and data structures
- Consider @Dependency for mock testing
- Profile with Instruments Time Profiler for callstacks

**I/O-bound actions** (waitState: "kevent", "read", "write"):
- Move to background threads
- Implement timeouts and cancellation
- Consider caching strategies

**High allocation actions** (allocationDelta > 10MB):
- Review data structure sizes
- Implement object pooling
- Check for memory leaks

## 🔧 Commands

### `analyze` (default)
Analyze trace and generate performance report
```bash
smith-tca-trace analyze [<trace-path>] [options]
  -f, --format <format>     Output format: json, markdown, html
  -m, --mode <mode>         Output mode: user, agent, compact
  --feature <feature>       Filter by feature name
  --filter <filter>         Filter by action name
  --subsystem <subsystem>   App subsystem filter
  --slow-only              Show only slow actions (>16ms)
  --min-duration <time>    Minimum duration filter (seconds)
  -s, --save               Save analysis for later comparison
  --name <name>            Name for saved analysis
  --tags <tags>            Tags for saved analysis
  --output <file>          Output file path
  --open                   Open HTML output in browser
  -v, --verbose            Verbose output
  --summary-only           Ultra-compact summary (~50 tokens)
  --no-summary             Suppress summary section
```

### `visualize`
Generate HTML visualizations
```bash
smith-tca-trace visualize <input> [--type <type>] [--output <file>] [--open]
  --type <type>            Visualization type: interactive, comparison
  --output <file>          Output HTML file path
  --open                   Open HTML in browser automatically
```

### `compare`
Compare two traces side-by-side
```bash
smith-tca-trace compare <before-trace> <after-trace>
```

### `history` / `list`
List and search saved analyses
```bash
smith-tca-trace history [--tag <tag>] [--name <name>]
```

### `delete`
Delete saved analyses
```bash
smith-tca-trace delete [--all] [--tag <tag>] [--name <name>]
```

### `stats`
Show storage statistics
```bash
smith-tca-trace stats
```

## 🎯 TCA Insights

### Performance Metrics
- **Action Analysis**: Duration distribution, slow action identification
- **Effect Analysis**: Long-running effects (>500ms), effect-to-action ratios
- **Complexity Scoring**: Architecture health assessment (0-100 scale)
- **Multi-Instrument Correlation**: CPU, memory, and I/O profiling data
- **Feature Performance**: Per-feature analysis and comparison

### Recommendations
- **@Dependency Usage**: Heavy effect optimization suggestions
- **Debouncing**: Frequent state change optimization
- **Caching**: Data loading and computation optimization
- **Cancellation**: Proper effect lifecycle management
- **Threading**: Offload I/O-bound operations to background
- **Memory**: Optimize allocations in hot paths

## 🏗️ Architecture

### Core Components
- **SignpostExtractor**: Extract TCA signposts from Instruments traces
- **TraceParser**: Parse and validate trace data with multi-instrument support
- **MultiInstrumentParser**: Robust XMLParser-based parsing for profiler, syscall, and allocation data
- **InstrumentEnrichmentService**: Correlate multi-instrument data with TCA actions/effects
- **ComplexityScorer**: Calculate architecture complexity metrics
- **RecommendationEngine**: Generate TCA-specific optimization advice
- **OutputFormatters**: JSON, Markdown, and HTML output generation

### Multi-Instrument Integration
- **XCTraceRunner**: Export data from Instruments using xctrace tool
- **Robust Parsing**: XMLParser-based extraction for Time Profiler, System Calls, and Allocations
- **Time Window Correlation**: Match multi-instrument data to TCA actions/effects
- **Smart Filtering**: Only enrich slow actions (>16ms) and long effects (>500ms)

## 🔄 Workflow Integration

### Development Workflow
```bash
# Performance regression testing
smith-tca-trace compare baseline.trace current.trace

# Feature-specific analysis
smith-tca-trace analyze trace.trace --feature MyFeature

# Save analysis for tracking
smith-tca-trace analyze trace.trace --save --name "daily-$(date +%Y%m%d)"
```

### CI/CD Integration
```bash
# Automated performance analysis
smith-tca-trace analyze build.trace --mode agent --output metrics.json

# Complexity score monitoring
smith-tca-trace stats | jq '.totalAnalyses'
```

## 🐛 Troubleshooting

### Common Issues

**No TCA signposts found:**
- Ensure TCA application has signpost instrumentation
- Check that signposts follow Point-Free's naming conventions
- Verify trace contains `[FeatureName] Feature.Action.actionName` patterns

**No multi-instrument data:**
- Ensure trace was recorded with multiple instruments (Time Profiler + System Calls + Allocations)
- Check that instruments were enabled during recording
- Verify trace file contains the required data schemas

**Empty analysis:**
- Check trace file path and permissions
- Ensure trace was recorded with Time Profiler template
- Verify xctrace tool is accessible

**Performance issues:**
- Large traces (>1GB) may require additional processing time
- Use `--slow-only` for faster analysis of large traces
- Consider filtering specific features or time ranges

### Debug Mode

```bash
# Verbose output
smith-tca-trace analyze trace.trace --verbose

# Check what instruments are available
xctrace export --input trace.trace --toc
```

## 🔮 Current Features

✅ **Implemented:**
- Multi-instrument enrichment (CPU, syscalls, allocations)
- Compact, user, and agent output modes
- HTML visualization with interactive charts
- Analysis management (save, compare, history)
- Feature-specific filtering
- Progressive disclosure for AI agents
- Subsystem filtering
- Performance regression detection

🔧 **Installation:**
- Homebrew tap available
- Manual build from source
- macOS 14+ support

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Point-Free**: TCA signpost instrumentation patterns
- **Apple Instruments**: Trace data extraction capabilities
- **Swift ArgumentParser**: CLI framework
- **Multi-instrument enrichment**: Built on Apple's Instruments data schemas

---

**Built with ❤️ for The Composable Architecture community**

## 📞 Support

For issues, feature requests, or questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
- Review the examples and documentation