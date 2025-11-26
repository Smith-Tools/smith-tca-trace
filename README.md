# 🚀 smith-tca-trace

**TCA performance profiling and analysis tool** - The Composable Architecture performance profiler for Apple Instruments traces.

## 📋 Overview

`smith-tca-trace` is a command-line tool that analyzes The Composable Architecture (TCA) applications using Instruments traces to identify performance bottlenecks, complexity issues, and provide actionable recommendations. It extracts TCA-specific signposts and generates comprehensive performance reports.

### ✨ Key Features

- **🔍 Generic TCA Detection**: Works with any TCA app using Point-Free's signpost instrumentation patterns
- **📊 Interactive Visualizations**: Modern web dashboard with Chart.js visualizations
- **🏗️ TCA-Focused Insights**: State mutations, actions, side effects, and dependencies analysis
- **⚡ Performance Metrics**: Action distribution, effect-to-action ratios, complexity scoring
- **🎯 Smart Recommendations**: TCA-specific optimization advice (@Dependency, debouncing, caching)
- **📱 Responsive Design**: Mobile-friendly interface for tablet debugging
- **🌊 Modern Dashboard**: Dark theme with glassmorphism effects and rich infographics
- **🔬 Multi-Instrument Enrichment**: CPU profiling, system call analysis, and memory tracking with automatic correlation to TCA actions/effects

## 🛠️ Installation

### Prerequisites

- **macOS 14+** (for Instruments integration)
- **Xcode** (for xctrace tool)
- **Swift 5.9+**

### Quick Install

```bash
cd smith-tca-trace
./Scripts/install.sh
```

This will:
1. Build the Swift CLI tool in release mode
2. Install the executable to `~/.local/bin/tca-trace`
3. Create the storage directory `~/.tca-trace/analyses`
4. Optionally deploy the Claude Code skill

### Manual Install (If Script Fails)

```bash
# Build from source
cd smith-tca-trace
swift build -c release

# Install to PATH
mkdir -p ~/.local/bin
cp .build/arm64-apple-macosx/release/smith-tca-trace ~/.local/bin/tca-trace
chmod +x ~/.local/bin/tca-trace

# Create storage directory
mkdir -p ~/.tca-trace/analyses

# Verify installation
tca-trace --version
```

### Add to PATH (If Not Using Script)

Add this to your shell profile (`~/.zshrc`, `~/.bash_profile`, etc.):
```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:
```bash
source ~/.zshrc  # or ~/.bash_profile
```

## 🚀 Quick Start

### Basic Usage

```bash
# Analyze a trace file
smith-tca-trace analyze /path/to/trace.trace

# Generate interactive HTML visualization
smith-tca-trace visualize /path/to/trace.trace --output report.html

# Compare two traces
smith-tca-trace compare before.trace after.trace

# List available traces
smith-tca-trace list
```

### Example Workflow

```bash
# 1. Record Instruments trace with TCA signposts
xctrace record --template "Time Profiler" --launch appname.app

# 2. Analyze performance
tca-trace analyze ~/Library/Developer/Xcode/DerivedData/appname/Build/Products/Debug/appname.app/trace.trace

# 3. Generate interactive dashboard
tca-trace visualize trace.trace --output performance-report.html

# 4. Open in browser
open performance-report.html
```

## 📖 Usage Workflows

### Workflow 1: Quick Terminal Analysis (Compact Output)

**Scenario**: You have a trace file and want a quick performance summary in your terminal.

```bash
# Get quick performance summary (default compact mode - ~200 tokens)
tca-trace analyze MyApp.trace

# Output:
# 🔍 TCA Trace Analysis
# ━━━━━━━━━━━━━━━━━━━━━━
# 📊 Overview:
#    • Total Actions: 24
#    • Total Effects: 7
#    • Complexity Score: 54/100 (Fair)
#    • Time Range: 3.2s
#
# ⚠️ Performance Issues (2):
#    1. ArticleList.loadArticles: 2341ms (very slow)
#    2. ArticleDetail.fetchMetadata: 890ms (slow)
```

**Command**:
```bash
tca-trace analyze path/to/trace.trace
```

### Workflow 2: Detailed Investigation (Full Data)

**Scenario**: You found a performance issue and need detailed information for analysis.

```bash
# Get complete analysis with all details (full JSON - ~3000 tokens)
tca-trace analyze MyApp.trace --mode agent --format json > analysis.json

# Or get human-readable detailed report
tca-trace analyze MyApp.trace --mode user --format markdown > analysis.md
```

**When to use**: When you need all the details—every action, effect, state change.

### Workflow 3: Interactive Visual Dashboard

**Scenario**: You want to understand TCA performance visually with charts and timeline.

```bash
# Generate interactive HTML dashboard
tca-trace visualize MyApp.trace --output dashboard.html

# Open in browser
open dashboard.html
```

**Dashboard includes**:
- Action distribution doughnut chart
- Effect duration timeline
- Complexity gauge
- TCA-specific recommendations
- Feature performance breakdown

### Workflow 4: Performance Regression Detection

**Scenario**: You've optimized your code and want to verify improvements.

```bash
# Record before optimization
xctrace record --template "Time Profiler" --launch MyApp.app
# → saves to: /path/to/before.trace

# Make optimization changes...

# Record after optimization
xctrace record --template "Time Profiler" --launch MyApp.app
# → saves to: /path/to/after.trace

# Compare traces
tca-trace compare before.trace after.trace --output comparison.html
open comparison.html
```

**Results show**:
- Regressions (new slow actions)
- Improvements (faster actions)
- Overall complexity change
- Severity classification

### Workflow 5: Feature-Specific Analysis

**Scenario**: Your app has multiple features and you want to profile just one.

```bash
# Analyze only ArticleDetailFeature
tca-trace analyze MyApp.trace \
  --feature ArticleDetailFeature \
  --output detail-feature-analysis.json

# Or filter by specific action
tca-trace analyze MyApp.trace \
  --filter "loadArticle" \
  --slow-only \
  --mode user
```

### Workflow 6: Save Baseline for Regression Testing

**Scenario**: You want to establish a performance baseline and track regressions.

```bash
# Analyze and save with a name
tca-trace analyze v1.0-baseline.trace \
  --save \
  --name "v1.0-baseline" \
  --tags "production,baseline"

# Later, compare current against baseline
tca-trace analyze v2.0-current.trace --compare
# → automatically compares against last saved baseline
```

---

## 🧠 Claude Code Integration

### Using smith-tca-trace in Claude Code Sessions

smith-tca-trace is available as a Claude Code skill for TCA performance analysis.

#### Activation Triggers

The skill automatically activates when you ask about:
- "Analyze my TCA trace"
- "Why is my reducer slow?"
- "What's the performance bottleneck?"
- "Profile my TCA app"
- "Show me the complexity score"
- "Detect performance regressions"

#### Example 1: Direct Analysis in Claude Code

```
You: "Analyze this TCA trace for me: /path/to/MyApp.trace"

Claude:
[Activates smith-tca-trace skill]

I'll analyze your TCA trace to identify performance issues.

🔍 Analysis Results:
━━━━━━━━━━━━━━━━━━
📊 Overview:
   • Total Actions: 32
   • Total Effects: 9
   • Complexity Score: 67/100 (Fair)
   • Time Range: 4.8s

⚠️ Performance Issues (3):
   1. ArticleList.loadArticles: 3456ms (very slow)
   2. ArticleDetail.downloadMetadata: 1200ms (slow)
   3. ArticleCache.processImages: 890ms (slow)

✅ Recommendations (2):
   • Use @Dependency for network client injection (enables mocking)
   • Add debouncing to searchArticles (currently 45 calls/sec)
```

#### Example 2: Comparing Traces in Claude Code

```
You: "I optimized my TCA app. Compare before and after."

Claude: "I'll compare your traces to detect improvements and regressions."

tca-trace compare before.trace after.trace --mode agent

Results:
✅ Improvements (2):
   • ArticleList.loadArticles: 3456ms → 1200ms (-65%)
   • ArticleCache.processImages: 890ms → 340ms (-62%)

🔴 Regressions (1):
   • ArticleDetail.fetchMetadata: 456ms → 780ms (+71%)

Summary:
   • Complexity Score: 67 → 42 (-37%)
   • Overall: Good improvements with one regression to investigate
```

#### Example 3: Detailed Investigation

```
You: "The ArticleList feature is slow. Help me understand why."

Claude:
[Uses smith-tca-trace with feature filtering]

tca-trace analyze trace.trace \
  --feature ArticleListFeature \
  --mode agent \
  --format json

I found the bottleneck! Here's what's happening:

📊 ArticleListFeature Performance:
   • Total Actions: 12
   • Heavy Effect: loadArticles (3.4 seconds)
     - Effect-to-action ratio: 45% (high - should be 20-35%)
     - Long duration suggests blocking operations

💡 Recommendations:
   1. The loadArticles effect is blocking - consider async operations
   2. State mutations happening too frequently (12 changes for 12 actions)
   3. Add @Dependency for API client to enable better testing
```

#### Example 4: Architecture Review

```
You: "Is my TCA implementation well-structured?"

Claude:
[Analyzes trace for architecture patterns]

Based on your trace analysis:

✅ Good Patterns:
   • Effect-to-action ratio of 28% (within healthy range 20-35%)
   • State changes properly batched
   • Good separation of concerns between features

⚠️ Areas for Improvement:
   • Some features have overlapping effects (state coupling)
   • High variance in action duration (suggests inconsistent patterns)
   • Three effects running in parallel (potential race conditions)

🎯 Next Steps:
   Ask @maxwell about TCA patterns for:
   • Shared state management best practices
   • Proper effect cancellation patterns
   • Dependency injection strategies
```

### Progressive Disclosure with Claude Code

smith-tca-trace implements smart token usage:

**Step 1**: Get Summary (Compact - ~200 tokens)
```
Claude analyzes and shows: Top 5 slow actions, complexity score, key metrics
```

**Step 2**: Request Details (Agent Mode - ~2000 tokens)
```
You: "Show me all the details for ArticleList feature"
Claude: Full JSON with every action, effect, and recommendation
```

**Step 3**: Generate Visual Report (HTML)
```
You: "Create an interactive dashboard"
Claude: Generates HTML with charts, timeline, and recommendations
```

---

## 🔗 Smith Tools Integration

smith-tca-trace is a **performance measurement tool** - it's separate from Maxwell's pattern teaching domain.

### Proper Domain Usage

```
Scenario: "My app is slow"

Step 1: User invokes smith-tca-trace (directly or in Claude Code)
$ tca-trace analyze trace.trace
→ Returns: complexity score, slow actions, performance data

Step 2: User asks Maxwell for pattern guidance
You: "@maxwell how do I optimize these slow effects?"
Maxwell: "Here are TCA patterns for..."

Step 3: (Optional) User asks Smith for architecture validation
You: "@smith validate my architecture"
Smith: "Checking performance against guidelines..."
```

### With Smith Agent (for validation)

```
Smith can invoke smith-tca-trace when validating architecture:
$ tca-trace analyze trace.trace --mode agent --format json
[Smith uses metrics: complexity, effect-to-action ratio, state mutations]
[Smith validates against composition guidelines]
"Guideline 1.2: dependency management needs improvement"
```

### Direct Usage via CLI/Automation

```bash
# Extract complexity score for monitoring
tca-trace analyze trace.trace --mode agent --format json | jq '.metadata.complexityScore'

# Save daily analysis
tca-trace analyze trace.trace --save --name "daily-$(date +%Y%m%d)"

# Batch reporting
for trace in traces/*.trace; do
  tca-trace analyze "$trace" --output "reports/$(basename $trace .trace).html"
done
```

---

## 💡 Best Practices

### Recording TCA Traces

**Do**:
- Use **Time Profiler** template (includes signpost data)
- Record for 30-60 seconds of typical app usage
- Record both success and error cases
- Use meaningful app names in trace metadata

**Don't**:
- Use **System Trace** template (different data format)
- Record very short sessions (<5 seconds)
- Record idle app time (no meaningful signposts)
- Use generic filenames like "trace" or "test"

### Analyzing Results

**For Performance Investigation**:
1. Start with compact mode (get the summary)
2. Filter to slow actions if >5 found
3. Use agent mode only if needed for details
4. Generate HTML dashboard for visual confirmation

**For Regression Detection**:
1. Compare against known baseline
2. Look for >20% regression threshold
3. Investigate new slow actions first
4. Check if improvements came with regressions

**For Architecture Review**:
1. Check effect-to-action ratio (optimal: 20-35%)
2. Look for state mutation patterns
3. Review complexity score (0-100 scale)
4. Consider @maxwell for pattern guidance

## 📊 Output Formats

### Interactive HTML Dashboard (Default)

- **TCA Core Principles Analysis**: State mutations, actions, side effects, dependencies
- **Effect Duration Comparison**: Visual chart showing effect performance
- **Action Distribution**: Doughnut chart of TCA action types
- **Timeline Analysis**: Scatter plot of action density over time
- **Performance Metrics**: Effect-to-action ratios, complexity scoring
- **TCA-Specific Recommendations**: Actionable optimization advice

### Other Formats

- **JSON** (`--mode agent`): Complete structured data for automation
- **Markdown** (`--format markdown`): Human-readable reports
- **Compact JSON**: Optimized for AI agents (30-40% token reduction)

## 🔬 Multi-Instrument Data Enrichment

### Automatic Correlation

smith-tca-trace automatically extracts and correlates data from multiple Instruments:

**Time Profiler** → CPU Thread States
- Extracts thread states (Running, Blocked, etc.) for each TCA action/effect
- Shows CPU vs I/O-bound operations
- Displays as "CPU: Running(100%)" in reports

**System Call Trace** → I/O Wait States
- Identifies blocking system calls (kevent, futex, read, write, mach_msg)
- Classifies dominant wait types per action
- Helps identify I/O vs CPU bottlenecks

**Allocations** → Memory Impact
- Tracks memory allocated/freed during actions
- Computes delta per time window
- Shows memory pressure correlation with slow actions

### Example Output

```
## 🐌 Slow Actions (>16ms)

- **ReadingLibrary.onAppear**: 7462.2ms | CPU: Running(100%)
- **ReadingLibrary.reader(.task)**: 3023.1ms | CPU: Running(100%)
- **ReadingLibrary.reader(.cacheLoaded)**: 617.7ms | CPU: Running(100%)
```

The enrichment fields include:
- **topSymbols**: Top CPU thread states with percentages
- **waitState**: Classification of I/O blocks (cpu, kevent, read, write, etc.)
- **allocationDelta**: Net memory change during execution

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

## 🎯 TCA Insights

### State Analysis
- **State Mutations**: Track and categorize state changes
- **Effect Monitoring**: Identify long-running and heavy effects
- **Dependency Analysis**: Effect-to-action ratios and patterns

### Performance Metrics
- **Action Distribution**: UI Events, Data Loading, State Mutations, Navigation
- **Effect Performance**: Duration comparison and bottleneck identification
- **Complexity Scoring**: Architecture health assessment
- **Frame Budget**: Animation and UI responsiveness analysis
- **CPU/Wait Classification**: Understanding bottleneck type (CPU vs I/O)
- **Memory Tracking**: Correlation between actions and allocations

### Recommendations
- **@Dependency Usage**: Heavy effect optimization suggestions
- **Debouncing**: Frequent state change optimization
- **Caching**: Data loading and computation optimization
- **Cancellation**: Proper effect lifecycle management
- **Threading**: Offload I/O-bound operations to background
- **Memory**: Optimize allocations in hot paths

## 🔧 Commands

### `analyze`
Analyze trace and generate performance report
```bash
smith-tca-trace analyze <trace-file> [options]
  --mode <user|agent>       Output format
  --format <json|html|md>   Output format
  --output <file>          Output file path
  --no-recommendations     Skip recommendations
```

### `visualize`
Generate interactive HTML dashboard
```bash
smith-tca-trace visualize <trace-file> --output <report.html>
```

### `compare`
Compare two traces side-by-side
```bash
smith-tca-trace compare <before-trace> <after-trace> --output comparison.html
```

### `list`
List available traces
```bash
smith-tca-trace list [--recent] [--count <number>]
```

### `stats`
Show trace statistics
```bash
smith-tca-trace stats <trace-file>
```

## 🏗️ Architecture

### Core Components

- **SignpostExtractor**: Extract TCA signposts from Instruments traces
- **TraceParser**: Parse and validate trace data
- **ComplexityScorer**: Calculate architecture complexity metrics
- **RecommendationEngine**: Generate TCA-specific optimization advice
- **HTMLFormatter**: Create interactive web visualizations

### Generic TCA Detection

The tool uses pattern-based detection to work with any TCA application:

```swift
// Extract action names from signpost patterns
let bracketPattern = #"\[([^\]]+)\].*?(\w+Feature)\.Action\.([\w.()]+)"#
let effectPattern = #"(?:Output from|Started from)\s+.*?(\w+Feature)\.Action\.([\w.()]+)"#
```

### UI Technology Stack

- **Svelte**: Reactive component framework
- **Chart.js**: Advanced data visualization
- **Vite**: Fast build tool
- **CSS Grid/Flexbox**: Modern responsive layouts

## 📈 Performance Features

### Action Classification
- **UI Events**: User interactions (tapped, selected, changed)
- **Data Loading**: Effects, fetch operations, background tasks
- **State Mutations**: Direct state updates and changes
- **Navigation**: Route and view management actions

### Effect Analysis
- **Duration Tracking**: Microsecond precision timing
- **Long-Running Detection**: >500ms threshold alerts
- **Performance Bottlenecks**: Critical effect identification
- **Cancellation Issues**: Missing .cancellable() detection

### Architecture Insights
- **Effect-to-Action Ratio**: Balance assessment
- **Complexity Scoring**: 0-100 health metric
- **State Change Patterns**: Shared state tracking
- **Dependency Analysis**: @Dependency optimization opportunities

## 🎨 Dashboard Features

### Visual Elements
- **Dark Theme**: Optimized for long debugging sessions
- **Glassmorphism**: Modern blur and transparency effects
- **Color Coding**: Performance severity indicators
- **Interactive Charts**: Hover effects and tooltips

### Responsive Design
- **Mobile Friendly**: Works on tablets during development
- **Touch Optimized**: Mobile interaction patterns
- **Adaptive Layout**: Flexible grid system

### Data Visualization
- **Doughnut Charts**: Action distribution breakdown
- **Scatter Plots**: Timeline density analysis
- **Bar Charts**: Effect duration comparison
- **Progress Metrics**: Real-time performance indicators

## 🔄 Workflow Integration

### Development
```bash
# Integrate into CI/CD
smith-tca-trace analyze build.trace --mode agent --output metrics.json

# Performance regression testing
smith-tca-trace compare baseline.trace current.trace --threshold 0.1
```

### Monitoring
```bash
# Continuous performance monitoring
smith-tca-trace stats production.trace --format json | jq '.complexityScore'

# Automated reporting
smith-tca-trace visualize daily.trace --output reports/daily-$(date +%Y%m%d).html
```

## 🐛 Troubleshooting

### Common Issues

**No TCA signposts found:**
- Ensure TCA application has signpost instrumentation
- Check that signposts follow Point-Free's naming conventions
- Verify trace contains `[FeatureName] Feature.Action.actionName` patterns

**Empty visualization:**
- Check trace file path and permissions
- Ensure trace was recorded with Time Profiler template
- Verify xctrace tool is accessible

**Performance issues:**
- Large traces (>1GB) may require additional processing time
- Use `--no-recommendations` for faster analysis
- Consider filtering specific time ranges

### Debug Mode

```bash
# Enable verbose logging
RUST_LOG=debug smith-tca-trace analyze trace.trace

# Check trace contents
smith-tca-trace list --details trace.trace
```

## 📚 Examples

### Real-World Analysis

```bash
# Reading Library TCA App Analysis
smith-tca-trace visualize ReadingLibrary.trace \
  --output reading-library-perf.html

# Results:
# - 107 total actions, 17 effects
# - Critical bottleneck: inspector(.loadData) - 3298ms
# - Effect-to-action ratio: 33.6% (healthy)
# - Health score: 87/100 (good architecture)
# - Recommendation: Implement caching for heavy effects
```

### Performance Regression

```bash
# Compare before/after optimization
smith-tca-trace compare before-optimization.trace after-optimization.trace \
  --output optimization-results.html

# Typical improvements:
# - Effect duration reduced by 60%
# - Complexity score improved from 45 to 32
# - Effect-to-action ratio optimized to 28%
```

## 🔮 Future Roadmap

### Planned Features
- [ ] Real-time monitoring integration
- [ ] Performance alerting system
- [ ] Baseline management
- [ ] Team sharing and collaboration
- [ ] Integration with CI/CD pipelines

### Technical Improvements
- [ ] Swift Package Manager distribution
- [ ] macOS app wrapper
- [ ] Plug-in architecture for custom analyzers
- [ ] Export to additional formats (CSV, PDF)

## 🤝 Contributing

### Development Setup
```bash
git clone <repository-url>
cd smith-tca-trace
swift build
swift test
```

### Code Style
- Follow Swift API Design Guidelines
- Use comprehensive unit tests
- Document all public APIs
- Ensure cross-platform compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Point-Free**: TCA signpost instrumentation patterns
- **Apple Instruments**: Trace data extraction capabilities
- **Swift ArgumentParser**: CLI framework
- **Svelte**: Reactive UI framework
- **Chart.js**: Data visualization library

---

## 📞 Support

For issues, feature requests, or questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
- Review the examples and documentation

**Built with ❤️ for The Composable Architecture community**

---

## 📚 Documentation Index

| Document | Purpose |
|----------|---------|
| **[QUICK_START.md](QUICK_START.md)** | Command cheat sheet, quick reference |
| **[README.md](README.md)** | Complete guide, all usage patterns |
| **[AGENT_INTEGRATION.md](AGENT_INTEGRATION.md)** | How Maxwell/Smith invoke smith-tca-trace |
| **[Skill/SKILL.md](Skill/SKILL.md)** | Claude Code skill activation |

Quick links:
- **Just installed?** → [QUICK_START.md](QUICK_START.md)
- **Need a command?** → [QUICK_START.md](QUICK_START.md) → Quick Commands
- **Want examples?** → README.md → Usage Workflows
- **In Claude Code?** → README.md → Claude Code Integration
- **Agent developer?** → [AGENT_INTEGRATION.md](AGENT_INTEGRATION.md)

---

## ✅ Installation Status

After installation, verify everything works:

```bash
# Check version
tca-trace --version
# → Should output: 1.0.0

# Check storage directory
ls -la ~/.tca-trace/analyses
# → Should exist and be writable

# Try a test command
tca-trace --help
# → Should show all available commands
```